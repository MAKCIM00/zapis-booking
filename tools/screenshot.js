// Снимает скриншот Flutter Web через Chrome DevTools Protocol.
// Запуск: node tools/screenshot.js <url> <out.png> [width] [height] [waitMs]
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const chromePath = process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const [url, outPath, widthArg = '390', heightArg = '844', waitArg = '9000', ...clickArgs] = process.argv.slice(2);
const width = Number(widthArg);
const height = Number(heightArg);
const waitMs = Number(waitArg);
const clicks = clickArgs.map((value) => value.split(',').map(Number));
const port = 9333 + Math.floor(Math.random() * 200);
const profile = path.join(os.tmpdir(), `zapis-shot-${Date.now()}`);

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const chrome = spawn(
  chromePath,
  [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-crash-reporter',
    '--no-first-run',
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${profile}`,
    '--hide-scrollbars',
    'about:blank',
  ],
  { stdio: 'ignore' },
);

async function findTarget() {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json/list`);
      if (response.ok) {
        const targets = await response.json();
        const page = targets.find((target) => target.type === 'page');
        if (page) {
          return page;
        }
      }
    } catch {
      // Chrome ещё поднимается.
    }
    await sleep(200);
  }
  throw new Error('Chrome DevTools не ответил');
}

async function main() {
  const target = await findTarget();
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  const pending = new Map();
  let nextId = 1;

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      socket.send(JSON.stringify({ id, method, params }));
    });

  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });

  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const { resolve, reject } = pending.get(message.id);
      pending.delete(message.id);
      message.error ? reject(new Error(message.error.message)) : resolve(message.result);
    }
  });

  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width,
    height,
    deviceScaleFactor: 2,
    mobile: true,
  });
  await send('Page.navigate', { url });
  await sleep(waitMs);

  for (const [x, y] of clicks) {
    for (const type of ['mousePressed', 'mouseReleased']) {
      await send('Input.dispatchMouseEvent', {
        type,
        x,
        y,
        button: 'left',
        clickCount: 1,
      });
    }
    await sleep(3000);
  }

  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, Buffer.from(data, 'base64'));
  console.log(`saved ${outPath} (${width}x${height}@2x)`);
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(() => {
    chrome.kill();
  });
