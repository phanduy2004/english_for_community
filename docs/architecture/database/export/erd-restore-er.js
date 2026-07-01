const fs = require('fs');
const path = require('path');

const dir = __dirname;
const frontmatter = fs.readFileSync(path.join(dir, 'erd-frontmatter.yaml'), 'utf8').trimEnd() + '\n';

const files = [
  ['erd-hinh-1a-user-lop', '_snapshot-1a.er.txt'],
  ['erd-hinh-1b-de-thi', '_snapshot-1b.er.txt'],
  ['erd-hinh-2-hoc-tap', '_snapshot-2.er.txt'],
];

for (const [name, snap] of files) {
  const body = fs.readFileSync(path.join(dir, snap), 'utf8').trimEnd() + '\n';
  fs.writeFileSync(path.join(dir, `${name}.mmd`), frontmatter + body, 'utf8');
  console.log('OK', name);
}
