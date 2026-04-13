"""
邮件发送 Skill - OpenCode 项目可重用组件

用途：在其他任务中发送邮件到指定收件人
支持：通过 HTTP 代理发送，支持附件

示例：
    from email_skill import send_email, send_quick, send_with_attachment

    # 发送简单邮件
    send_quick('任务完成', '任务已成功执行')

    # 发送带附件的邮件
    send_with_attachment(
        subject='报告',
        body='详见附件',
        attachment='/path/to/file.pdf'
    )
"""
import sys
import os
import subprocess
from datetime import datetime

# 默认配置
DEFAULT_RECIPIENT = 'wang.luqiang@gmail.com'
SMTP_USERNAME = 'wang.luqiang@gmail.com'
SMTP_PASSWORD = 'ciif uqks pugf uuvr'
EMAIL_SCRIPT = '/home/alex/send_mail_simple.py'

def send_email(recipient, subject, body, attachment=None):
    """
    发送邮件

    参数:
        recipient: 收件人邮箱
        subject: 邮件主题
        body: 邮件正文
        attachment: 附件路径（可选）

    返回:
        bool: 发送成功返回 True，失败返回 False
    """
    cmd = ['python3', EMAIL_SCRIPT,
           '--to', recipient,
           '--subject', subject,
           '--body', body]

    if attachment:
        cmd.extend(['--attach', attachment])

    env = os.environ.copy()
    env['SMTP_USERNAME'] = SMTP_USERNAME
    env['SMTP_PASSWORD'] = SMTP_PASSWORD

    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=90)
        if result.returncode == 0:
            print(f"[邮件] 发送成功: {subject}")
            return True
        else:
            print(f"[邮件] 发送失败: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print(f"[邮件] 发送超时: {subject}")
        return False
    except Exception as e:
        print(f"[邮件] 发送错误: {e}")
        return False

def send_quick(subject, body, recipient=None):
    """
    快速发送简单邮件（默认发给自己）

    参数:
        subject: 邮件主题
        body: 邮件正文
        recipient: 收件人（可选，默认为 DEFAULT_RECIPIENT）

    返回:
        bool: 发送成功返回 True，失败返回 False
    """
    to = recipient or DEFAULT_RECIPIENT
    return send_email(to, subject, body)

def send_with_attachment(subject, body, file_path, recipient=None):
    """
    发送带附件的邮件

    参数:
        subject: 邮件主题
        body: 邮件正文
        file_path: 附件文件路径
        recipient: 收件人（可选，默认为 DEFAULT_RECIPIENT）

    返回:
        bool: 发送成功返回 True，失败返回 False
    """
    to = recipient or DEFAULT_RECIPIENT
    if not os.path.exists(file_path):
        print(f"[邮件] 文件不存在: {file_path}")
        return False
    return send_email(to, subject, body, file_path)

def send_task_report(category, task_name, status, summary, recipient=None):
    """
    发送任务报告邮件

    参数:
        category: 任务类别
        task_name: 任务名称
        status: 状态 (✅ 成功 ❌ 失败 ⏳ 进行中)
        summary: 简要描述
        recipient: 收件人（可选，默认为 DEFAULT_RECIPIENT）

    返回:
        bool: 发送成功返回 True，失败返回 False
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    subject = f"{status} {category}/{task_name}"
    body = f'''任务报告

类别: {category}
任务: {task_name}
状态: {status}
时间: {timestamp}

详细描述:
{summary}

---
发送自 AI Protocol 系统
'''

    return send_quick(subject, body, recipient)

# 测试函数
def test_email_skill():
    """测试邮件发送 Skill"""
    print("=== 测试邮件发送 Skill ===\n")

    # 测试 1: 发送简单邮件
    print("测试 1: 简单邮件...")
    result1 = send_quick('Email Skill 测试', '这是来自 email_skill.py 的测试邮件')
    print(f"结果: {'成功' if result1 else '失败'}\n")

    # 测试 2: 发送任务报告
    print("测试 2: 任务报告...")
    result2 = send_task_report(
        category='test',
        task_name='email_skill',
        status='✅ 成功',
        summary='邮件发送 Skill 测试通过'
    )
    print(f"结果: {'成功' if result2 else '失败'}\n")

    return result1 and result2

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'test':
        test_email_skill()
    else:
        print("邮件发送 Skill")
        print("")
        print("使用方法:")
        print("  from email_skill import send_quick, send_with_attachment, send_task_report")
        print("")
        print("快速发送:")
        print("  send_quick('主题', '内容')")
        print("")
        print("带附件:")
        print("  send_with_attachment('主题', '内容', '/path/to/file')")
        print("")
        print("任务报告:")
        print("  send_task_report('类别', '任务', '状态', '描述')")
        print("")
        print("测试:")
        print("  python3 email_skill.py test")
