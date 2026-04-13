#!/usr/bin/env python3
"""
获取最新邮件的附件
使用 IMAP 协议连接 Gmail
"""

import imaplib
import email
import os
import base64
from email.header import decode_header

# Gmail IMAP 配置
IMAP_HOST = 'imap.gmail.com'
IMAP_PORT = 993
USERNAME = 'wang.luqiang@gmail.com'
PASSWORD = 'ciif uqks pugf uuvr'

DOWNLOAD_DIR = '/home/alex/Downloads/'

def decode_str(s):
    """解码邮件头字符串"""
    if s is None:
        return ''
    decoded = decode_header(s)
    result = []
    for part, charset in decoded:
        if isinstance(part, bytes):
            result.append(part.decode(charset or 'utf-8', errors='replace'))
        else:
            result.append(part)
    return ''.join(result)

def get_latest_emails(limit=5):
    """获取最新的邮件"""
    print(f"Connecting to {IMAP_HOST}...")
    
    # 连接 IMAP 服务器
    mail = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT)
    mail.login(USERNAME, PASSWORD)
    mail.select('INBOX')
    
    # 搜索最新邮件
    status, messages = mail.search(None, 'ALL')
    if status != 'OK':
        print("Failed to search emails")
        return []
    
    email_ids = messages[0].split()
    latest_ids = email_ids[-limit:]  # 获取最新的 limit 封邮件
    
    emails = []
    for email_id in latest_ids:
        status, msg_data = mail.fetch(email_id, '(RFC822)')
        if status != 'OK':
            continue
        
        for response_part in msg_data:
            if isinstance(response_part, tuple):
                msg = email.message_from_bytes(response_part[1])
                
                # 获取基本信息
                subject = decode_str(msg['Subject'])
                sender = decode_str(msg['From'])
                date = msg['Date']
                
                # 检查附件
                attachments = []
                for part in msg.walk():
                    if part.get_content_maintype() == 'multipart':
                        continue
                    if part.get('Content-Disposition') is None:
                        continue
                    
                    filename = part.get_filename()
                    if filename:
                        filename = decode_str(filename)
                        attachments.append(filename)
                
                emails.append({
                    'id': email_id,
                    'subject': subject,
                    'sender': sender,
                    'date': date,
                    'attachments': attachments
                })
    
    mail.close()
    mail.logout()
    
    return emails

def download_attachment(email_id, filename, output_dir=DOWNLOAD_DIR):
    """下载指定邮件的附件"""
    mail = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT)
    mail.login(USERNAME, PASSWORD)
    mail.select('INBOX')
    
    status, msg_data = mail.fetch(email_id, '(RFC822)')
    if status != 'OK':
        print(f"Failed to fetch email {email_id}")
        return None
    
    for response_part in msg_data:
        if isinstance(response_part, tuple):
            msg = email.message_from_bytes(response_part[1])
            
            for part in msg.walk():
                if part.get_content_maintype() == 'multipart':
                    continue
                if part.get('Content-Disposition') is None:
                    continue
                
                att_filename = part.get_filename()
                if att_filename:
                    att_filename = decode_str(att_filename)
                    if att_filename == filename or filename in att_filename:
                        filepath = os.path.join(output_dir, att_filename)
                        with open(filepath, 'wb') as f:
                            f.write(part.get_payload(decode=True))
                        print(f"Downloaded: {filepath}")
                        mail.close()
                        mail.logout()
                        return filepath
    
    mail.close()
    mail.logout()
    return None

if __name__ == '__main__':
    import sys
    
    print("=== 获取最新邮件 ===\n")
    emails = get_latest_emails(limit=10)
    
    print(f"找到 {len(emails)} 封邮件:\n")
    
    for i, e in enumerate(emails, 1):
        print(f"{i}. {e['subject']}")
        print(f"   发件人: {e['sender']}")
        print(f"   日期: {e['date']}")
        if e['attachments']:
            print(f"   附件: {', '.join(e['attachments'])}")
        print()
    
    # 查找包含 PDF 附件的邮件
    for e in emails:
        for att in e['attachments']:
            if att.lower().endswith('.pdf'):
                print(f"\n发现 PDF 附件: {att}")
                print(f"邮件主题: {e['subject']}")
                print(f"正在下载...")
                downloaded = download_attachment(e['id'], att)
                if downloaded:
                    print(f"下载成功: {downloaded}")
