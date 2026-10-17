import http from 'node:http';
import https from 'node:https';
import { createReadStream } from 'node:fs';
import { readFile, realpath, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import zlib from 'node:zlib';

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

// The engine (.wasm) shrinks ~4x compressed, which matters over phone Wi-Fi. Compressed copies
// are cached per file version; the .pck is mostly already-compressed images, so it goes as-is.
const compressible = new Set(['.html', '.js', '.wasm', '.json', '.svg']);
const brotli = promisify(zlib.brotliCompress);
const gzip = promisify(zlib.gzip);
const compressedCache = new Map();
const compressed = (file, etag, encoding) => {
  const key = `${file}|${etag}|${encoding}`;
  if (!compressedCache.has(key)) {
    for (const k of compressedCache.keys()) if (k.startsWith(`${file}|`) && !k.startsWith(`${file}|${etag}|`)) compressedCache.delete(k);
    const pending = readFile(file).then((data) => encoding === 'br'
      ? brotli(data, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 5 } })
      : gzip(data));
    pending.catch(() => compressedCache.delete(key));
    compressedCache.set(key, pending);
  }
  return compressedCache.get(key);
};

const certificate = process.argv[5];
const privateKey = process.argv[6];
const tls = certificate && privateKey ? { cert: await readFile(certificate), key: await readFile(privateKey) } : null;
const handleRequest = async (req, res) => {
  // no-cache, not no-store: the phone keeps its copy but asks on every load, so an unchanged
  // file costs a 304 and a rebuilt one is fetched fresh.
  res.setHeader('Cache-Control', 'no-cache');
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
    const etag = `"${info.size.toString(16)}-${Math.floor(info.mtimeMs).toString(16)}"`;
    res.setHeader('ETag', etag);
    if (req.headers['if-none-match'] === etag) {
      res.writeHead(304).end();
      return;
    }
    const ext = path.extname(file).toLowerCase();
    const headers = { 'Content-Type': types[ext] ?? 'application/octet-stream', Vary: 'Accept-Encoding' };
    const accepts = req.headers['accept-encoding'] ?? '';
    const encoding = !compressible.has(ext) ? null : /\bbr\b/.test(accepts) ? 'br' : /\bgzip\b/.test(accepts) ? 'gzip' : null;
    if (encoding) {
      const body = await compressed(file, etag, encoding);
      res.writeHead(200, { ...headers, 'Content-Encoding': encoding, 'Content-Length': body.length });
      res.end(req.method === 'HEAD' ? undefined : body);
      return;
    }
    res.writeHead(200, { ...headers, 'Content-Length': info.size });
    if (req.method === 'HEAD') res.end();
    else createReadStream(file).on('error', () => res.destroy()).pipe(res);
  } catch (error) {
    res.writeHead(error instanceof URIError ? 400 : 404).end();
  }
};
const server = tls ? https.createServer(tls, handleRequest) : http.createServer(handleRequest);
server.on('error', (error) => { console.error(error.message); process.exitCode = 1; });
server.listen(port, address, () => console.log(`MythCards Wi-Fi test: ${tls ? 'https' : 'http'}://${address}:${port}/\nServing ${root}`));
