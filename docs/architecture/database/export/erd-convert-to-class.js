const fs = require('fs');
const path = require('path');

const dir = __dirname;

const TYPE_MAP = {
  objectId: 'ObjectId',
  string: 'String',
  number: 'Number',
  date: 'Date',
  boolean: 'Boolean',
  object: 'Object',
  string_array: 'String[]',
  object_array: 'Object[]',
  objectId_array: 'ObjectId[]',
};

const VIS_MAP = { '＋': '+', '－': '-', '＃': '#' };

const REL_MAP = {
  '||--o{': ['"1"', '"0..*"'],
  '|o--o{': ['"0..1"', '"0..*"'],
  '|o--o|': ['"0..1"', '"0..1"'],
  '||--||': ['"1"', '"1"'],
  '||--|{': ['"1"', '"1..*"'],
};

function capType(type) {
  return TYPE_MAP[type] || type.charAt(0).toUpperCase() + type.slice(1);
}

function parseField(line) {
  const m = line.match(/^\s+(\S+)\s+(\S+?)(\s+PK)?\s*$/);
  if (!m) return null;
  const [, type, rawName] = m;
  let vis = '+';
  let name = rawName;
  const ch = rawName[0];
  if (VIS_MAP[ch]) {
    vis = VIS_MAP[ch];
    name = rawName.slice(1);
  }
  return `        ${vis}${capType(type)} ${name}`;
}

function parseRelation(line) {
  const m = line.match(/^\s+(\w+)\s+(\|\|?--[o\|][\{\|])\s+(\w+)\s+:/);
  if (!m) return null;
  const [, from, sym, to] = m;
  const card = REL_MAP[sym];
  if (!card) throw new Error(`Unknown relation ${sym} in: ${line.trim()}`);
  return `    ${from} ${card[0]} --> ${card[1]} ${to}`;
}

function convertBody(body) {
  const lines = body.split(/\r?\n/);
  const out = ['classDiagram', '    direction TB', ''];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const entity = line.match(/^(\w+)\s*\{\s*$/);
    if (entity) {
      const name = entity[1];
      out.push(`    class ${name} {`);
      i += 1;
      while (i < lines.length && !/^\s*\}\s*$/.test(lines[i])) {
        const field = parseField(lines[i]);
        if (field) out.push(field);
        i += 1;
      }
      out.push('    }', '');
      i += 1;
      continue;
    }
    const rel = parseRelation(line);
    if (rel) {
      out.push(rel);
      i += 1;
      continue;
    }
    if (line.trim() === '' || line.trim().startsWith('erDiagram')) {
      i += 1;
      continue;
    }
    i += 1;
  }
  return out.join('\n').replace(/\n{3,}/g, '\n\n').trim() + '\n';
}

const frontmatter = `---
config:
  theme: base
  look: classic
  themeVariables:
    darkMode: false
    background: "#ffffff"
    lineColor: "#000000"
    fontSize: 16px
---
`;

const names = ['erd-hinh-1a-user-lop', 'erd-hinh-1b-de-thi', 'erd-hinh-2-hoc-tap'];

for (const n of names) {
  const file = path.join(dir, `${n}.mmd`);
  let raw = fs.readFileSync(file, 'utf8');
  const body = raw.replace(/^---[\s\S]*?---\n?/, '').trimStart();
  const converted = convertBody(body);
  fs.writeFileSync(file, frontmatter + converted, 'utf8');
  console.log('Converted', n);
}
