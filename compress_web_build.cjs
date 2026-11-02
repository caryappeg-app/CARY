/**
 * CARY Flutter Web Build Compressor
 * Compresses production Flutter web files using Brotli (level 11) and Gzip (level 9)
 * for lightning-fast server transfers and minimal main-thread parsing latency.
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const WEB_DIR = path.join(__dirname, 'build', 'web');

const COMPRESSIBLE_EXTENSIONS = new Set([
  '.js',
  '.wasm',
  '.html',
  '.css',
  '.json',
  '.svg',
  '.map'
]);

function compressFile(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (!COMPRESSIBLE_EXTENSIONS.has(ext)) return;

  const content = fs.readFileSync(filePath);
  const relPath = path.relative(WEB_DIR, filePath);

  // Gzip (level 9 - maximum compression)
  const gzipPath = filePath + '.gz';
  const gzipped = zlib.gzipSync(content, { level: 9 });
  fs.writeFileSync(gzipPath, gzipped);

  // Brotli (quality 11 - maximum compression)
  const brPath = filePath + '.br';
  const brotli = zlib.brotliCompressSync(content, {
    params: {
      [zlib.constants.BROTLI_PARAM_QUALITY]: zlib.constants.BROTLI_MAX_QUALITY,
      [zlib.constants.BROTLI_PARAM_MODE]: ext === '.wasm' ? zlib.constants.BROTLI_MODE_GENERIC : zlib.constants.BROTLI_MODE_TEXT,
    }
  });
  fs.writeFileSync(brPath, brotli);

  const origKb = (content.length / 1024).toFixed(1);
  const gzKb = (gzipped.length / 1024).toFixed(1);
  const brKb = (brotli.length / 1024).toFixed(1);
  const saved = (100 - (brotli.length / content.length) * 100).toFixed(0);

  console.log(`[OK] ${relPath.padEnd(35)} ${origKb}KB -> gz: ${gzKb}KB | br: ${brKb}KB (${saved}% saved)`);
}

function walkDir(dir) {
  if (!fs.existsSync(dir)) {
    console.error(`Directory not found: ${dir}`);
    return;
  }
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkDir(fullPath);
    } else if (entry.isFile()) {
      compressFile(fullPath);
    }
  }
}

console.log('=== Compressing CARY Web Production Assets (Brotli + Gzip) ===');
walkDir(WEB_DIR);
console.log('=== Compression finished successfully! ===');
