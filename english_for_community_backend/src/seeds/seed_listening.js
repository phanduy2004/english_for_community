/* eslint-disable no-console */
// src/seeds/seed_listening.js
import dotenv from 'dotenv'; dotenv.config();
import mongoose from 'mongoose';

import Unit from '../models/Unit.js';
import Lesson from '../models/Lesson.js';
import Listening from '../models/Listening.js';
import Cue from '../models/Cue.js';

const MONGO = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/english_community';

// ——— helpers ———
const toMs = (ts) => {
  const p = ts.split(':'); // "mm:ss.mmm" or "hh:mm:ss.mmm"
  if (p.length === 3) return (+p[0] * 3600 + +p[1] * 60 + +p[2]) * 1000;
  if (p.length === 2) return (+p[0] * 60 + +p[1]) * 1000;
  return 0;
};
const normalize = (s = '') =>
  String(s)
  .toLowerCase()
  .replace(/[’'`]/g, "'")
  .replace(/[^a-z0-9'\s]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();
const splitSpeaker = (line) => {
  const m = String(line).match(/^([^:\n]{1,30})\s*:\s*(.+)$/);
  return m
    ? { spk: m[1].trim(), text: m[2].trim() }
    : { spk: 'Speaker', text: String(line).trim() };
};

// ——— raw cues (A/B) ———
const rawCues = [
  { start: '00:00.000', end: '00:03.000', text: "A: Wake up, it's time for school." },
  { start: '00:03.000', end: '00:07.000', text: "B: I'm so tired. Let me sleep for five more minutes." },
  { start: '00:07.000', end: '00:10.000', text: "A: You have to get up and get ready for school." },
  { start: '00:10.000', end: '00:13.000', text: "B: I know. But just five more minutes." },
  { start: '00:13.000', end: '00:19.000', text: "A: I can't let you go back to sleep because you won't wake back up." },
  { start: '00:19.000', end: '00:22.000', text: "B: I promise I'll wake up in 5 minutes." },
  { start: '00:22.000', end: '00:26.000', text: "A: You still need to eat breakfast, take a shower, and get dressed." },
  { start: '00:26.000', end: '00:32.000', text: "B: I realize that I can do all that when I wake up in 5 minutes." },
  { start: '00:32.000', end: '00:35.000', text: "A: I don't want you to be late for school today." },
  { start: '00:35.000', end: '00:37.000', text: "B: I'm not going to be late today." },
  { start: '00:37.000', end: '00:39.000', text: 'A: Fine, 5 more minutes.' },
  { start: '00:39.000', end: '00:41.000', text: 'B: Thank you.' },
];

async function run() {
  await mongoose.connect(MONGO);
  console.log('Mongo:', MONGO);

  // 1) Unit (upsert)
  const unit = await Unit.findOneAndUpdate(
    { name: 'Default Unit' },
    { $setOnInsert: { name: 'Default Unit', order: 1, isActive: true } },
    { new: true, upsert: true }
  );

  // 2) Lesson (upsert) — type "listening"
  await Lesson.deleteMany({ name: 'Dictation – Wake-up Call', unitId: unit._id, type: 'listening' });
  const lesson = await Lesson.create({
    unitId: unit._id,
    name: 'Dictation – Wake-up Call',
    description: 'Nghe từng câu và gõ lại để luyện chính tả.',
    order: 1,
    type: 'listening',
    content: { listeningCode: 'p1_wakeup' }, // để client tra cứu nhanh nếu cần
    isActive: true,
  });

  // 3) Listening (không nhúng cues)
  await Listening.deleteMany({ code: 'p1_wakeup' });
  const listening = await Listening.create({
    lessonId: lesson._id,
    code: 'p1_wakeup',
    title: 'Wake-up Call',
    audioUrl: '/assets/audio/p1_wakeup.mp3', // asset nội bộ app hoặc CDN
    playbackPad: { before: 200, after: 200 },
    difficulty: 'easy',
    cefr: 'A2',
    tags: ['dialog', 'home', 'morning'],
    totalCues: 0,
    transcript: '',
  });

  // 4) Cues (insertMany) — (listeningId, idx) unique
  await Cue.deleteMany({ listeningId: listening._id });

  const cueDocs = rawCues.map((c, i) => {
    const { spk, text } = splitSpeaker(c.text);
    return {
      listeningId: listening._id,
      idx: i,
      startMs: toMs(c.start),
      endMs: toMs(c.end),
      spk,
      text,
      textNorm: normalize(text),
    };
  });

  await Cue.insertMany(cueDocs);

  // 5) Cập nhật summary: totalCues + transcript
  const transcript = cueDocs.map((c) => c.text).join(' ');
  await Listening.updateOne(
    { _id: listening._id },
    { $set: { totalCues: cueDocs.length, transcript } }
  );

  console.log('✅ Seed done:', {
    unitId: unit._id.toString(),
    lessonId: lesson._id.toString(),
    listeningId: listening._id.toString(),
    totalCues: cueDocs.length,
  });

  await mongoose.disconnect();
}

run().catch(async (e) => {
  console.error(e);
  await mongoose.disconnect();
  process.exit(1);
});
