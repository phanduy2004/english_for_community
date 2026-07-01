const fs = require('fs');
const path = require('path');

const PLUS = '\uFF0B';
const MINUS = '\uFF0D';
const HASH = '\uFF03';

const privateNames = new Set([
  'password', 'refreshToken', 'resetOtp', 'resetOtpExpiresAt', 'resetOtpAttempts',
  'resetLastSentAt', 'otpPurpose', 'otpCreatedAt',
]);
const protectedNames = new Set(['_destroy']);

function prefix(name) {
  if (protectedNames.has(name)) return HASH + name;
  if (privateNames.has(name)) return MINUS + name;
  return PLUS + name;
}

function stripFrontmatter(raw) {
  const idx = raw.search(/^erDiagram/m);
  if (idx >= 0) return raw.slice(idx);
  return raw.replace(/^(\s*---[\s\S]*?---\s*)+/, '').trimStart();
}

function transformBody(body) {
  const lines = body.split(/\r?\n/);
  let inEntity = false;
  return lines.map((line) => {
    if (/^\s*\w[\w]*\s*\{\s*$/.test(line)) {
      inEntity = true;
      return line;
    }
    if (inEntity && /^\s*\}\s*$/.test(line)) {
      inEntity = false;
      return line;
    }
    if (inEntity) {
      const m = line.match(/^(\s+)(\S+)\s+(\S+)(.*)$/);
      if (m) {
        const [, indent, type, rawName, suffix] = m;
        const name = rawName.replace(/^[^\w*]+/, '');
        return `${indent}${type} ${prefix(name)}${suffix}`;
      }
    }
    return line;
  }).join('\n');
}

const userFullBlock = `    User {
        objectId ${PLUS}_id PK
        string ${PLUS}phone
        string ${PLUS}email
        string ${MINUS}password
        string ${PLUS}avatarUrl
        string ${PLUS}fullName
        string ${PLUS}username
        string ${PLUS}role
        date ${PLUS}dateOfBirth
        string ${PLUS}bio
        string ${PLUS}gender
        boolean ${PLUS}isVerified
        string ${PLUS}goal
        string ${PLUS}cefr
        number ${PLUS}dailyMinutes
        object ${PLUS}reminder
        number ${PLUS}dailyLessonGoal
        number ${PLUS}dailyActivityProgress
        string ${PLUS}dailyProgressDate
        number ${PLUS}totalPoints
        number ${PLUS}level
        number ${PLUS}currentStreak
        boolean ${PLUS}strictCorrection
        string ${PLUS}language
        string ${PLUS}timezone
        boolean ${PLUS}isOnline
        date ${PLUS}lastActivityDate
        boolean ${PLUS}isBanned
        date ${PLUS}banExpiresAt
        string ${PLUS}banReason
        boolean ${HASH}_destroy
        string ${MINUS}refreshToken
        string_array ${PLUS}fcmTokens
        string ${MINUS}resetOtp
        date ${MINUS}resetOtpExpiresAt
        number ${MINUS}resetOtpAttempts
        date ${MINUS}resetLastSentAt
        string ${MINUS}otpPurpose
        date ${MINUS}otpCreatedAt
        date ${PLUS}createdAt
        date ${PLUS}updatedAt
    }`;

const userRefBlock = `    User {
        objectId ${PLUS}_id PK
        string ${PLUS}fullName
        string ${PLUS}role
    }`;

const dir = __dirname;
const frontmatter = fs.readFileSync(path.join(dir, 'erd-frontmatter.yaml'), 'utf8').trimEnd();
const files = [
  { name: 'erd-hinh-1a-user-lop', userBlock: userFullBlock },
  { name: 'erd-hinh-1b-de-thi', userBlock: userRefBlock },
  { name: 'erd-hinh-2-hoc-tap', userBlock: userRefBlock },
];

for (const { name, userBlock } of files) {
  const file = path.join(dir, `${name}.mmd`);
  let body = stripFrontmatter(fs.readFileSync(file, 'utf8'));
  body = transformBody(body);
  body = body.replace(/    User \{[\s\S]*?    \}/, userBlock);
  const fixed = `${frontmatter}\n${body}\n`;
  fs.writeFileSync(file, fixed, 'utf8');
  console.log('Fixed', name);
}
