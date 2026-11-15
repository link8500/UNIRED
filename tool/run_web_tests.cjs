// El servidor de `flutter test --platform chrome` 3.44.2 no encuentra
// /canvaskit/ en Windows. Servimos una copia temporal desde test/, sin cambiar
// el SDK ni depender de una CDN. Nunca se reemplazan carpetas existentes.
const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawn, spawnSync } = require('node:child_process');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const assets = path.join(root, 'test', 'canvaskit');
const owner = crypto.randomUUID();
const marker = path.join(assets, '.unired-web-test-assets');
const quote = (value) => "'" + value.replace(/'/g, "''") + "'";

async function main() {
  let copied = false;
  try {
    if (process.platform === 'win32') {
      const located = spawnSync('where.exe', ['flutter'], { encoding: 'utf8', windowsHide: true });
      const executable = located.stdout?.split(/\r?\n/).find((s) => /flutter\.bat$/i.test(s.trim()));
      assert.ok(executable, 'No se encontró Flutter en PATH.');
      const source = path.resolve(path.dirname(executable.trim()), '../bin/cache/flutter_web_sdk/canvaskit');
      await fs.mkdir(assets); // Falla si ya existe: puede pertenecer al usuario u otra prueba.
      copied = true;
      await fs.writeFile(marker, owner);
      for (const entry of await fs.readdir(source)) {
        await fs.cp(path.join(source, entry), path.join(assets, entry), { recursive: true });
      }
    }
    const args = ['test', 'test/app_feedback_test.dart', 'test/image_upload_web_test.dart', '--platform', 'chrome', '--reporter', 'expanded', ...process.argv.slice(2)];
    const child = process.platform === 'win32'
      ? spawn('powershell', ['-NoProfile', '-NonInteractive', '-Command', '& flutter ' + args.map(quote).join(' ') + '; exit $LASTEXITCODE'], { cwd: root, windowsHide: true, stdio: 'inherit' })
      : spawn('flutter', args, { cwd: root, stdio: 'inherit' });
    process.exitCode = await new Promise((resolve, reject) => {
      child.once('error', reject);
      child.once('exit', (code) => resolve(code ?? 1));
    });
  } finally {
    if (copied) {
      assert.equal(path.dirname(assets), path.join(root, 'test'));
      assert.equal((await fs.lstat(assets)).isSymbolicLink(), false);
      assert.equal(await fs.readFile(marker, 'utf8'), owner, 'No se borrarán archivos ajenos.');
      await fs.rm(assets, { recursive: true });
    }
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
