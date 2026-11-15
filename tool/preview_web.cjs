// Vista local de una compilación de Flutter. No expone archivos del proyecto
// fuera de build/web o build/web-preview ni se conecta directamente a la BD.
const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');
const name = process.argv[2] || 'web';
if (!['web', 'web-preview'].includes(name)) throw Error('Compilación no permitida.');
const root = path.resolve(__dirname, '..', 'build', name);
const port = Number(process.argv[3] || 62604);
if (!Number.isInteger(port) || port < 1 || port > 65535) throw Error('Puerto inválido.');
const types = {'.html':'text/html; charset=utf-8','.js':'application/javascript',
  '.json':'application/json','.wasm':'application/wasm','.png':'image/png',
  '.jpg':'image/jpeg','.svg':'image/svg+xml','.css':'text/css'};
const server = http.createServer(async (request, response) => {
  try {
    const url = new URL(request.url, 'http://127.0.0.1');
    const file = path.resolve(root, '.' + decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname));
    const relative = path.relative(root, file);
    if (relative.startsWith('..') || path.isAbsolute(relative)) {
      response.writeHead(403).end(); return;
    }
    const data = await fs.readFile(file);
    response.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream',
      'Cache-Control':'no-store'}).end(data);
  } catch { response.writeHead(404).end(); }
});
server.listen(port, '127.0.0.1', () => console.log(`Vista local: http://127.0.0.1:${port}`));
function stop() { server.close(); process.stdin.pause(); }
process.stdin.resume();
process.stdin.once('data', stop);
process.once('SIGINT', stop);
process.once('SIGTERM', stop);
