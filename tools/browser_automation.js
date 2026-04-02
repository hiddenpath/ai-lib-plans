/**
 * Playwright 浏览器自动化工具
 * 
 * 用途: 动态网页访问、表单交互、截图、内容提取
 * 
 * 安装:
 *   npm install playwright
 *   npx playwright install chromium
 * 
 * 示例用法:
 *   node browser_automation.js
 */

const { chromium } = require('playwright');
const fs = require('fs');

/**
 * 浏览器自动化工具类
 */
class BrowserAutomation {
  constructor(options = {}) {
    this.options = {
      headless: true,
      timeout: 30000,
      viewport: { width: 1280, height: 720 },
      ...options
    };
    this.browser = null;
    this.context = null;
  }

  /**
   * 启动浏览器
   */
  async launch() {
    this.browser = await chromium.launch({
      headless: this.options.headless,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    this.context = await this.browser.newContext({
      viewport: this.options.viewport
    });
    return this;
  }

  /**
   * 创建新页面
   */
  async newPage() {
    return await this.context.newPage();
  }

  /**
   * 访问网页
   * @param {Page} page - Playwright 页面对象
   * @param {string} url - 目标 URL
   * @param {string} waitUntil - 等待策略: 'load' | 'domcontentloaded' | 'networkidle'
   */
  async goto(page, url, waitUntil = 'domcontentloaded') {
    await page.goto(url, { waitUntil, timeout: this.options.timeout });
  }

  /**
   * 提取页面文本内容
   * @param {Page} page - Playwright 页面对象
   * @param {string} selector - CSS 选择器（可选）
   */
  async getText(page, selector = 'body') {
    const element = await page.locator(selector);
    return await element.textContent();
  }

  /**
   * 提取多个元素文本
   * @param {Page} page - Playwright 页面对象
   * @param {string} selector - CSS 选择器
   */
  async getAllText(page, selector) {
    const elements = await page.locator(selector);
    return await elements.allTextContents();
  }

  /**
   * 提取 HTML 内容
   * @param {Page} page - Playwright 页面对象
   */
  async getHTML(page) {
    return await page.content();
  }

  /**
   * 填写表单输入框
   * @param {Page} page - Playwright 页面对象
   * @param {string} selector - 输入框选择器
   * @param {string} value - 要填入的值
   */
  async fillInput(page, selector, value) {
    await page.locator(selector).fill(value);
  }

  /**
   * 点击元素
   * @param {Page} page - Playwright 页面对象
   * @param {string} selector - 元素选择器
   */
  async click(page, selector) {
    await page.locator(selector).click();
  }

  /**
   * 等待元素出现
   * @param {Page} page - Playwright 页面对象
   * @param {string} selector - 元素选择器
   * @param {number} timeout - 超时时间（毫秒）
   */
  async waitFor(page, selector, timeout = this.options.timeout) {
    await page.locator(selector).waitFor({ timeout });
  }

  /**
   * 截图
   * @param {Page} page - Playwright 页面对象
   * @param {string} path - 保存路径
   * @param {boolean} fullPage - 是否全页面截图
   */
  async screenshot(page, path, fullPage = false) {
    await page.screenshot({ path, fullPage });
  }

  /**
   * 执行 JavaScript
   * @param {Page} page - Playwright 页面对象
   * @param {Function|string} script - 要执行的 JS 代码
   */
  async evaluate(page, script) {
    return await page.evaluate(script);
  }

  /**
   * 监控网络请求
   * @param {Page} page - Playwright 页面对象
   * @param {Function} callback - 回调函数
   */
  monitorRequests(page, callback) {
    page.on('request', req => callback('request', req));
    page.on('response', res => callback('response', res));
  }

  /**
   * 获取 Cookie
   */
  async getCookies() {
    return await this.context.cookies();
  }

  /**
   * 设置 Cookie
   * @param {Array} cookies - Cookie 数组
   */
  async setCookies(cookies) {
    await this.context.addCookies(cookies);
  }

  /**
   * 关闭浏览器
   */
  async close() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// 导出类和便捷函数
module.exports = {
  BrowserAutomation,
  chromium,
  
  // 便捷函数：快速截图
  async quickScreenshot(url, outputPath) {
    const browser = new BrowserAutomation();
    await browser.launch();
    const page = await browser.newPage();
    await browser.goto(page, url);
    await browser.screenshot(page, outputPath, true);
    await browser.close();
    return outputPath;
  },

  // 便捷函数：快速提取文本
  async quickScrape(url, selector = 'body') {
    const browser = new BrowserAutomation();
    await browser.launch();
    const page = await browser.newPage();
    await browser.goto(page, url);
    const text = await browser.getText(page, selector);
    await browser.close();
    return text;
  }
};
