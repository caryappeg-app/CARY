const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const dirs = [
  path.join(__dirname, 'assets', 'images'),
  path.join(__dirname, 'web', 'splash', 'img'),
  path.join(__dirname, 'web', 'icons')
];

for (const dir of dirs) {
  if (!fs.existsSync(dir)) continue;
  const files = fs.readdirSync(dir);
  for (const file of files) {
    if (file.endsWith('.jpg') || file.endsWith('.png')) {
      const input = path.join(dir, file);
      const output = path.join(dir, file.replace(/\.(jpg|png)$/, '.webp'));
      try {
        console.log(`Converting ${file} -> ${path.basename(output)}`);
        execSync(`npx -y sharp-cli -i "${input}" -o "${output}" -q 85`, { stdio: 'inherit' });
      } catch (err) {
        console.error(`Failed to convert ${file}:`, err.message);
      }
    }
  }
}
console.log('Conversion complete!');
