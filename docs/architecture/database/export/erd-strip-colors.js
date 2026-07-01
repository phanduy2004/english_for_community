const fs = require('fs');
const path = require('path');

const dir = __dirname;
const frontmatter = fs.readFileSync(path.join(dir, 'erd-frontmatter.yaml'), 'utf8').trimEnd();
const names = ['erd-hinh-1a-user-lop', 'erd-hinh-1b-de-thi', 'erd-hinh-2-hoc-tap'];

function stripDecorations(body) {
  return body
    .split(/\r?\n/)
    .filter((line) => {
      const t = line.trim();
      if (t.startsWith('style ')) return false;
      if (t.startsWith('classDef ')) return false;
      if (t.startsWith('class ')) return false;
      return true;
    })
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function stripFrontmatter(raw) {
  const idx = raw.search(/^erDiagram/m);
  if (idx >= 0) return raw.slice(idx);
  return raw.replace(/^(\s*---[\s\S]*?---\s*)+/, '').trimStart();
}

for (const n of names) {
  const file = path.join(dir, `${n}.mmd`);
  const body = stripDecorations(stripFrontmatter(fs.readFileSync(file, 'utf8')));
  fs.writeFileSync(file, `${frontmatter}\n${body}\n`, 'utf8');
  console.log('OK', n);
}
