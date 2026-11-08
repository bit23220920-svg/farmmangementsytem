/**
 * Zero-dependency static file server for local development.
 * No npm install required — uses only Node's built-in modules.
 * Run with: npm run dev   (or: node server.js)
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const PORT = process.env.PORT || 5500;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'text/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg':  'image/svg+xml',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.ico':  'image/x-icon',
};

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/login.html';

  const filePath = path.normalize(path.join(ROOT, urlPath));
  // Prevent escaping the project directory.
  if (!filePath.startsWith(ROOT)){
    res.writeHead(403);
    return res.end('Forbidden');
  }

  fs.readFile(filePath, (err, data) => {
    if (err){
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      return res.end(`Not found: ${urlPath}`);
    }
    const ext = path.extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`\n  John Dhiri Intelligent Farm System is running:\n`);
  console.log(`  \u2192  http://localhost:${PORT}/login.html\n`);
  console.log(`  Press Ctrl+C to stop.\n`);
});
