import http from 'node:http';
import https from 'node:https';
import { createReadStream } from 'node:fs';
import { readFile, realpath, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const address = process.argv[2];
const port = Number(process.argv[3] ?? 8060);
if (!address || !Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('Usage: node tools/serve_web_lan.mjs <local-IP> [port] [export-directory]');
}
const root = await realpath(process.argv[4] ?? fileURLToPath(new URL('../build/web/', import.meta.url)));
const types = {
  '.html': 'text/html; charset=utf-8', '.js': 'application/javascript',
  '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
  '.json': 'application/json', '.webp': 'image/webp',
};

const certificate = process.argv[5];
const privateKey = process.argv[6];
const tls = certificate && privateKey ? { cert: await readFile(certificate), key: await readFile(privateKey) } : null;
const handleRequest = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (!['GET', 'HEAD'].includes(req.method)) {
    res.writeHead(405, { Allow: 'GET, HEAD' }).end();
    return;
  }
  try {
    const requested = decodeURIComponent(new URL(req.url, 'http://local').pathname);
    const candidate = path.resolve(root, '.' + (requested === '/' ? '/index.html' : requested));
    const relative = path.relative(root, candidate);
    if (relative.startsWith('..') || path.isAbsolute(relative)) {
      res.writeHead(403).end();
      return;
    }
    const file = await realpath(candidate);
    const resolvedRelative = path.relative(root, file);
    if (resolvedRelative.startsWith('..') || path.isAbsolute(resolvedRelative)) {
      res.writeHead(403).end();
      return;
    }
    const info = await stat(file);
    if (!info.isFile()) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, {
      'Content-Type': types[path.extname(file).toLowerCase()] ?? 'application/octet-stream',
      'Content-Length': info.size,
    });
    if (req.method === 'HEAD') res.end();
    else createReadStream(file).on('error', () => res.destroy()).pipe(res);
  } catch (error) {
    res.writeHead(error instanceof URIError ? 400 : 404).end();
  }
};
const server = tls ? https.createServer(tls, handleRequest) : http.createServer(handleRequest);
server.on('error', (error) => { console.error(error.message); process.exitCode = 1; });
server.listen(port, address, () => console.log(`MythCards Wi-Fi test: ${tls ? 'https' : 'http'}://${address}:${port}/\nServing ${root}`));
