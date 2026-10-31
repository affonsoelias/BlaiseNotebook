const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const CHROME_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const SERVER_EXE = path.resolve(__dirname, '..', 'frontend', 'server', 'bin', 'server.exe');
const DIST_DIR = path.resolve(__dirname, '..', 'frontend', 'dist');
const CDP_PORT = 9230;

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

class CDPClient {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.id = 1;
    this.callbacks = new Map();
  }

  connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.wsUrl);
      this.ws.onopen = () => resolve();
      this.ws.onerror = (err) => reject(err);
      this.ws.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.id && this.callbacks.has(msg.id)) {
          const cb = this.callbacks.get(msg.id);
          this.callbacks.delete(msg.id);
          if (msg.error) cb.reject(new Error(msg.error.message));
          else cb.resolve(msg.result);
        }
      };
    });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = this.id++;
      this.callbacks.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async eval(expression) {
    const res = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    return res && res.result ? res.result.value : null;
  }

  async screenshot(filePath) {
    const res = await this.send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(filePath, Buffer.from(res.data, 'base64'));
    console.log('[+] Saved screenshot:', filePath);
  }

  close() {
    if (this.ws) this.ws.close();
  }
}

async function startServer() {
  return new Promise((resolve, reject) => {
    console.log('[1] Spawning mORMot 2 native server...');
    const proc = spawn(SERVER_EXE, ['--port', '8090', '--dist', DIST_DIR], {
      cwd: path.dirname(SERVER_EXE),
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let resolved = false;
    let stdoutBuf = '';

    proc.stdout.on('data', (data) => {
      stdoutBuf += data.toString();
      const m = stdoutBuf.match(/Port:\s+(\d+)/);
      if (m && stdoutBuf.includes('Press [Enter]') && !resolved) {
        resolved = true;
        const port = m[1];
        const url = `http://127.0.0.1:${port}/`;
        console.log('[+] Server confirmed ready and listening at:', url);
        resolve({ proc, url });
      }
    });

    proc.stderr.on('data', (data) => {
      console.error('[Server STDERR]', data.toString());
    });

    proc.on('exit', (code) => {
      if (!resolved) reject(new Error('Server exited prematurely with code: ' + code));
    });

    setTimeout(() => {
      if (!resolved) {
        resolved = true;
        const m = stdoutBuf.match(/Port:\s+(\d+)/);
        const port = m ? m[1] : '8090';
        const url = `http://127.0.0.1:${port}/`;
        console.log('[*] Timeout fallback URL:', url);
        resolve({ proc, url });
      }
    }, 5000);
  });
}

async function main() {
  const { proc: serverProc, url: appUrl } = await startServer();

  console.log('[2] Starting Chrome in headless CDP mode...');
  const tmpDir = path.resolve(__dirname, '..', '.chrome_tmp_capture');
  const chromeProc = spawn(CHROME_PATH, [
    '--headless=new',
    '--disable-gpu',
    `--remote-debugging-port=${CDP_PORT}`,
    '--window-size=1440,960',
    '--no-first-run',
    '--no-default-browser-check',
    '--user-data-dir=' + tmpDir,
    'about:blank'
  ], { stdio: 'ignore' });

  let cdp;
  try {
    let targets = null;
    for (let i = 0; i < 20; i++) {
      await sleep(500);
      try {
        targets = await fetchJson(`http://127.0.0.1:${CDP_PORT}/json/list`);
        if (targets && targets.length > 0) break;
      } catch (e) {}
    }

    if (!targets || targets.length === 0) {
      throw new Error('Failed to connect to Chrome CDP endpoint');
    }

    const pageTarget = targets.find(t => t.type === 'page') || targets[0];
    console.log('[3] Connecting to CDP WebSocket:', pageTarget.webSocketDebuggerUrl);

    cdp = new CDPClient(pageTarget.webSocketDebuggerUrl);
    await cdp.connect();
    await cdp.send('Page.enable');
    await cdp.send('Runtime.enable');

    console.log(`[4] Navigating to ${appUrl} ...`);
    await cdp.send('Page.navigate', { url: appUrl });

    console.log('[5] Waiting for notebook DOM and Chart.js to render...');
    for (let i = 0; i < 30; i++) {
      await sleep(600);
      const state = await cdp.eval(`({
        title: document.title,
        cellsCount: document.querySelectorAll('.bv-cell').length,
        hasWorkspace: document.querySelector('.bv-notebook-workspace') !== null
      })`);
      if (state && state.cellsCount > 0) {
        console.log('    DOM ready with', state.cellsCount, 'cells mounted.');
        break;
      }
    }

    await sleep(2500);

    const outDir = path.resolve(__dirname, '..', 'docs', 'images');
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

    // Frame 1: Initial state (Light theme, top view)
    const frame1 = path.join(outDir, 'frame1.png');
    await cdp.screenshot(frame1);

    // Frame 2: Click "Run All" and wait for outputs
    console.log('[6] Running all cells in notebook...');
    await cdp.eval(`
      const btn = Array.from(document.querySelectorAll('button')).find(b => b.textContent.includes('Run All'));
      if (btn) btn.click();
    `);
    await sleep(4000);

    const frame2 = path.join(outDir, 'frame2.png');
    await cdp.screenshot(frame2);

    // Frame 3: Scroll down to show Python Bridge and Chart.js
    console.log('[7] Scrolling to Python Bridge and Chart.js output...');
    await cdp.eval('window.scrollTo({ top: 580, behavior: "instant" })');
    await sleep(2000);

    const frame3 = path.join(outDir, 'frame3.png');
    await cdp.screenshot(frame3);

    // Frame 4: Scroll down to DataGrid and convergence curve
    console.log('[8] Scrolling to DataGrid and convergence curve...');
    await cdp.eval('window.scrollTo({ top: 1100, behavior: "instant" })');
    await sleep(2000);

    const frame4 = path.join(outDir, 'frame4.png');
    await cdp.screenshot(frame4);

    // Frame 5: Switch to Dark Theme
    console.log('[9] Switching to Dark theme...');
    await cdp.eval(`
      const themeBtn = document.querySelector('.theme-toggle-btn');
      if (themeBtn) themeBtn.click();
      window.scrollTo({ top: 0, behavior: "instant" });
    `);
    await sleep(2500);

    const frame5 = path.join(outDir, 'frame5.png');
    await cdp.screenshot(frame5);

    // Frame 6: Dark theme with charts visible
    console.log('[10] Scrolling Dark theme to charts...');
    await cdp.eval('window.scrollTo({ top: 580, behavior: "instant" })');
    await sleep(2000);

    const frame6 = path.join(outDir, 'frame6.png');
    await cdp.screenshot(frame6);

    // Copy frame2 as primary static preview screenshot for README
    const previewPng = path.join(outDir, 'blaisenotebook_preview.png');
    fs.copyFileSync(frame2, previewPng);
    console.log('[+] blaisenotebook_preview.png successfully generated!');

  } finally {
    if (cdp) cdp.close();
    try { chromeProc.kill(); } catch (e) {}
    try { serverProc.kill(); } catch (e) {}
    try {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

main().catch(err => {
  console.error('[!] Error during capture:', err);
  process.exit(1);
});
