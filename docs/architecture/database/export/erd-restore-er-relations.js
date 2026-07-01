const fs = require('fs');
const path = require('path');

const dir = __dirname;
const names = ['erd-hinh-1a-user-lop', 'erd-hinh-1b-de-thi', 'erd-hinh-2-hoc-tap'];

// Restore erDiagram-style connectors (crow's foot) from snapshot
const REL_FILES = {
  'erd-hinh-1a-user-lop': '_snapshot-1a.er.txt',
  'erd-hinh-1b-de-thi': '_snapshot-1b.er.txt',
  'erd-hinh-2-hoc-tap': '_snapshot-2.er.txt',
};

function extractErRelations(body) {
  return body
    .split(/\r?\n/)
    .filter((l) => /^\s+\w+\s+\|\|?--[o|][{|]|/.test(l))
    .map((l) => l.trim());
}

for (const n of names) {
  const file = path.join(dir, `${n}.mmd`);
  let raw = fs.readFileSync(file, 'utf8');
  const body = raw.replace(/^---[\s\S]*?---\n?/, '');
  const classPart = body.replace(/\n\s+\w[\w\s]*"[^"]*"\s+-->\s+"[^"]*"\s+\w+[\s\S]*/m, '').trimEnd();
  const snap = fs.readFileSync(path.join(dir, REL_FILES[n]), 'utf8');
  const rels = extractErRelations(snap);
  const out = raw.replace(/^---[\s\S]*?---\n?/, '');
  const classesOnly = out.split(/\n\s+\w[\w\s]*"/)[0].trimEnd();
  // classesOnly: everything before first rel line with quotes
  const lines = body.split(/\r?\n/);
  const classLines = [];
  for (const line of lines) {
    if (/^\s+\w+\s+"[^"]*"\s+-->/.test(line)) break;
    classLines.push(line);
  }
  const newBody = [...classLines, '', ...rels.map((r) => `    ${r}`), ''].join('\n');
  const frontmatter = fs.readFileSync(path.join(dir, 'erd-frontmatter.yaml'), 'utf8').trimEnd() + '\n';
  fs.writeFileSync(file, frontmatter + newBody, 'utf8');
  console.log('OK', n, rels.length, 'relations');
}
