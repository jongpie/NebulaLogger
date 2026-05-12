const fs = require('fs');
const path = require('path');
const esbuild = require('esbuild');

// ─── Configure Prism build here ───────────────────────────────────────────────
const OUTPUT_DIR = './nebula-logger/core/main/log-management/staticresources/LoggerResources/';

const THEME = 'prism-tomorrow';

const LANGUAGES = ['apex', 'clike', 'css', 'http', 'javadoclike', 'javascript', 'json', 'json5', 'jsonp', 'jsstacktrace', 'markup', 'sql', 'typescript'];

// NOTE: plugin order matters — `toolbar` must come before `copy-to-clipboard`, `download-button`, and `show-language`,
// because they each call into `Prism.plugins.toolbar` at load time.
const PLUGINS = ['line-highlight', 'line-numbers', 'toolbar', 'copy-to-clipboard', 'download-button', 'show-language'];

// ──── Prism processing ────────────────────────────────────────────────────────

const PRISM_ROOT = path.dirname(require.resolve('prismjs'));
const version = require('prismjs/package.json').version;

fs.mkdirSync(OUTPUT_DIR, { recursive: true });

function readFile(filePath) {
  if (!fs.existsSync(filePath)) {
    console.warn(`  WARNING: Not found — ${filePath}`);
    return '';
  }
  return fs.readFileSync(filePath, 'utf8');
}

async function run() {
  console.log(`Retrieving Prism assets`);
  console.log(`  + Theme: ${THEME}`);

  // ── Build JS ────────────────────────────────────────────────────────────────
  const jsParts = [
    readFile(path.join(PRISM_ROOT, 'prism.js')),
    ...LANGUAGES.map(lang => {
      console.log(`  + Language: ${lang}`);
      return readFile(path.join(PRISM_ROOT, 'components', `prism-${lang}.js`));
    }),
    ...PLUGINS.map(plugin => {
      console.log(`  + Plugin: ${plugin}`);
      return readFile(path.join(PRISM_ROOT, 'plugins', plugin, `prism-${plugin}.js`));
    })
  ];

  const jsOutput = path.join(OUTPUT_DIR, 'prism.js');
  const jsMinOutput = path.join(OUTPUT_DIR, 'prism.min.js');

  const bundledJS = jsParts.join('\n');
  fs.writeFileSync(jsOutput, bundledJS);
  const minifiedJS = await esbuild.transform(bundledJS, { loader: 'js', minify: true, legalComments: 'none' });
  fs.writeFileSync(jsMinOutput, minifiedJS.code);

  // ── Build CSS ───────────────────────────────────────────────────────────────
  const cssParts = [
    readFile(path.join(PRISM_ROOT, 'themes', `${THEME}.css`)),
    ...PLUGINS.map(plugin => {
      const cssPath = path.join(PRISM_ROOT, 'plugins', plugin, `prism-${plugin}.css`);
      return fs.existsSync(cssPath) ? readFile(cssPath) : '';
    })
  ];

  const cssOutput = path.join(OUTPUT_DIR, 'prism.css');
  const cssMinOutput = path.join(OUTPUT_DIR, 'prism.min.css');

  const bundledCSS = cssParts.join('\n');
  fs.writeFileSync(cssOutput, bundledCSS);
  const minifiedCSS = await esbuild.transform(bundledCSS, { loader: 'css', minify: true, legalComments: 'none' });
  fs.writeFileSync(cssMinOutput, minifiedCSS.code);

  // ── Summary ─────────────────────────────────────────────────────────────────
  const stats = file => (fs.statSync(file).size / 1024).toFixed(1) + ' KB';
  console.log(`\n✓ Built Prism v${version} → ${OUTPUT_DIR}`);
  console.log(`  prism.js      ${stats(jsOutput)}`);
  console.log(`  prism.min.js  ${stats(jsMinOutput)}`);
  console.log(`  prism.css     ${stats(cssOutput)}`);
  console.log(`  prism.min.css ${stats(cssMinOutput)}`);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
