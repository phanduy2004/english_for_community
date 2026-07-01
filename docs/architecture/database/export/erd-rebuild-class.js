const fs = require('fs');
const path = require('path');

const dir = __dirname;

const TYPE_MAP = {
  objectId: 'ObjectId', string: 'String', number: 'Number', date: 'Date',
  boolean: 'Boolean', object: 'Object', string_array: 'String[]',
  object_array: 'Object[]', objectId_array: 'ObjectId[]',
};
const VIS_MAP = { '＋': '+', '－': '-', '＃': '#' };
const REL_MAP = {
  '||--o{': { from: '"1"', to: '"0..*"', arrow: '-->' },
  '|o--o{': { from: '"0..1"', to: '"0..*"', arrow: '..>' },
  '|o--o|': { from: '"0..1"', to: '"0..1"', arrow: '..>' },
};

function capType(t) { return TYPE_MAP[t] || t; }

function parseField(line) {
  const m = line.match(/^\s+(\S+)\s+(\S+?)(\s+PK)?\s*$/);
  if (!m) return null;
  const [, type, rawName] = m;
  let vis = '+', name = rawName;
  if (VIS_MAP[rawName[0]]) { vis = VIS_MAP[rawName[0]]; name = rawName.slice(1); }
  return `        ${vis}${capType(type)} ${name}`;
}

function parseRelation(line) {
  const m = line.match(/^\s+(\w+)\s+(\S+)\s+(\w+)\s+:/);
  if (!m) return null;
  const [, from, sym, to] = m;
  const card = REL_MAP[sym];
  if (!card) return null;
  return `    ${from} ${card.from} ${card.arrow} ${card.to} ${to}`;
}

function convertErToClass(body) {
  const lines = body.split(/\r?\n/);
  const classes = [];
  const relSet = new Set();
  const rels = [];
  let i = 0;
  while (i < lines.length) {
    const em = lines[i].match(/^\s+(\w+)\s*\{\s*$/);
    if (em) {
      const block = [`    class ${em[1]} {`];
      i++;
      while (i < lines.length && !/^\s*\}\s*$/.test(lines[i])) {
        const f = parseField(lines[i]);
        if (f) block.push(f);
        i++;
      }
      block.push('    }');
      classes.push(block.join('\n'));
      i++;
      continue;
    }
    const r = parseRelation(lines[i]);
    if (r && !relSet.has(r)) {
      relSet.add(r);
      rels.push(r);
    }
    i++;
  }
  return ['classDiagram', '    direction TB', '', ...classes, '', ...rels, ''].join('\n');
}

const frontmatter = fs.readFileSync(path.join(dir, 'erd-frontmatter.yaml'), 'utf8').trimEnd() + '\n';

// Recover from last good erDiagram snapshot (pre broken double-convert)
const sources = {
  'erd-hinh-1a-user-lop': fs.readFileSync(path.join(dir, '_snapshot-1a.er.txt'), 'utf8'),
  'erd-hinh-1b-de-thi': fs.readFileSync(path.join(dir, '_snapshot-1b.er.txt'), 'utf8'),
  'erd-hinh-2-hoc-tap': fs.readFileSync(path.join(dir, '_snapshot-2.er.txt'), 'utf8'),
};

for (const [name, body] of Object.entries(sources)) {
  fs.writeFileSync(path.join(dir, `${name}.mmd`), frontmatter + convertErToClass(body), 'utf8');
  console.log('OK', name);
}
