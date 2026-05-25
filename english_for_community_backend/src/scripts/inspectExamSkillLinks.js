/**
 * Inspect skill sections on an exam (Speaking/Writing resource links).
 * Usage: node src/scripts/inspectExamSkillLinks.js "Kiểm tra cuối kì"
 */
import mongoose from 'mongoose';
import Exam from '../models/Exam.js';
import { getMongoUri } from '../lib/mongoUri.js';
import { primaryResourceIdFromSection, resourcesFromSkillSection } from '../services/examSkillSectionResources.js';

const titleQuery = process.argv[2] || 'Kiểm tra cuối kì';

async function main() {
  await mongoose.connect(getMongoUri());
  const exams = await Exam.find({ title: { $regex: titleQuery, $options: 'i' } })
    .select('title status sections settings.examFormat')
    .lean();
  if (!exams.length) {
    console.log(`No exam matching "${titleQuery}"`);
    process.exit(0);
  }
  for (const exam of exams) {
    console.log('\n---', exam.title, `(${exam.status})`, '---');
    for (const sec of exam.sections || []) {
      if (!sec?.skill) continue;
      const resources = resourcesFromSkillSection(sec);
      const rid = primaryResourceIdFromSection(sec);
      const fp = sec.fixedWritingPrompt?.text ? '(has fixedWritingPrompt)' : '';
      console.log(
        `  ${sec.skill}: resourceId=${rid || '(empty)'} resources=${resources.length} ${fp}`
      );
      if (resources.length) console.log('    ', resources[0]);
    }
  }
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
