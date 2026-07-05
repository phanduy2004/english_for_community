import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { pathToFileURL } from 'url';
import SpeakingScenario from '../models/SpeakingScenario.js';
import { getMongoUri, getMongoUriForLog } from '../lib/mongoUri.js';

dotenv.config();

const scenarios = [
  {
    slug: 'daily-small-talk-neighbor',
    title: 'Small talk with a neighbor',
    description: 'Practice greeting, asking simple follow-up questions, and closing politely.',
    group: 'daily',
    levelSuggested: 'Beginner',
    goals: ['Greet naturally', 'Ask at least two follow-up questions', 'Close the chat politely'],
    roleForAI: 'You are a friendly neighbor meeting the learner near the elevator. Keep turns short and natural.',
    firstMessage: 'Hi! I think I have seen you around the building. How is your day going?',
    successCriteria: ['Learner answers with complete sentences', 'Learner asks questions back', 'Learner uses polite closing'],
    starterHints: ['I just moved here.', 'What do you usually do on weekends?', 'It was nice talking to you.'],
    sortOrder: 10,
  },
  {
    slug: 'daily-order-coffee',
    title: 'Order coffee',
    description: 'Order a drink, ask about options, and handle a simple follow-up question.',
    group: 'service',
    levelSuggested: 'Beginner',
    goals: ['Order clearly', 'Ask one question about size or milk', 'Confirm the price or pickup time'],
    roleForAI: 'You are a barista at a busy cafe. Ask one clarification question before confirming the order.',
    firstMessage: 'Good morning! What can I get for you today?',
    successCriteria: ['Learner specifies drink and size', 'Learner answers clarification', 'Learner confirms order'],
    starterHints: ['Can I have a latte, please?', 'Do you have oat milk?', 'How much is it?'],
    sortOrder: 20,
  },
  {
    slug: 'travel-hotel-checkin',
    title: 'Hotel check-in',
    description: 'Check in, confirm booking details, and ask about hotel facilities.',
    group: 'travel',
    levelSuggested: 'Beginner',
    goals: ['Give booking information', 'Answer passport/payment questions', 'Ask about breakfast or Wi-Fi'],
    roleForAI: 'You are a hotel receptionist. Help the guest check in and ask for missing details.',
    firstMessage: 'Welcome to Green Lake Hotel. Do you have a reservation with us?',
    successCriteria: ['Learner gives name/reservation', 'Learner asks facility question', 'Learner confirms check-in details'],
    starterHints: ['The booking is under my name.', 'Is breakfast included?', 'What is the Wi-Fi password?'],
    sortOrder: 30,
  },
  {
    slug: 'travel-ask-directions',
    title: 'Ask for directions',
    description: 'Ask how to get somewhere and clarify turns, time, and transport.',
    group: 'travel',
    levelSuggested: 'Beginner',
    goals: ['Ask for directions', 'Clarify one detail', 'Thank the helper'],
    roleForAI: 'You are a local person giving simple directions. Use clear landmarks.',
    firstMessage: 'Hi, you look a little lost. Where are you trying to go?',
    successCriteria: ['Learner names destination', 'Learner clarifies time or route', 'Learner thanks politely'],
    starterHints: ['How can I get to the museum?', 'Is it far from here?', 'Thank you for your help.'],
    sortOrder: 40,
  },
  {
    slug: 'study-class-project',
    title: 'Discuss a class project',
    description: 'Plan tasks, share opinions, and agree on next steps.',
    group: 'study',
    levelSuggested: 'Intermediate',
    goals: ['Suggest a plan', 'Give a reason for an idea', 'Agree on next action'],
    roleForAI: 'You are a classmate working on a group presentation. Negotiate tasks with the learner.',
    firstMessage: 'We need to prepare our presentation for Friday. Which part do you want to work on?',
    successCriteria: ['Learner suggests task split', 'Learner gives reasons', 'Learner agrees on timeline'],
    starterHints: ['I can prepare the introduction.', 'Maybe we should use three examples.', 'Let us finish the slides by Wednesday.'],
    sortOrder: 50,
  },
  {
    slug: 'work-standup-update',
    title: 'Team stand-up update',
    description: 'Give progress, blockers, and next steps in a work meeting.',
    group: 'work',
    levelSuggested: 'Intermediate',
    goals: ['Summarize yesterday', 'Mention one blocker', 'State today’s plan'],
    roleForAI: 'You are a team lead running a short daily stand-up. Ask concise follow-up questions.',
    firstMessage: 'Good morning. Could you give a quick update on your work?',
    successCriteria: ['Learner uses past/current/future structure', 'Learner explains blocker clearly', 'Learner states next step'],
    starterHints: ['Yesterday I finished...', 'I am blocked by...', 'Today I will focus on...'],
    sortOrder: 60,
  },
  {
    slug: 'work-job-interview-intro',
    title: 'Job interview introduction',
    description: 'Introduce yourself and answer a follow-up about strengths.',
    group: 'work',
    levelSuggested: 'Intermediate',
    goals: ['Give a concise self-introduction', 'Connect experience to the role', 'Answer one strength question'],
    roleForAI: 'You are an interviewer. Ask about background, strengths, and one concrete example.',
    firstMessage: 'Thanks for joining today. Could you start by telling me about yourself?',
    successCriteria: ['Learner gives structured intro', 'Learner includes relevant experience', 'Learner gives an example'],
    starterHints: ['I have experience in...', 'One of my strengths is...', 'For example, I once...'],
    sortOrder: 70,
  },
  {
    slug: 'service-return-item',
    title: 'Return an item',
    description: 'Explain a problem with a product and request a solution.',
    group: 'service',
    levelSuggested: 'Intermediate',
    goals: ['Explain the issue clearly', 'Ask for refund or exchange', 'Respond to store policy'],
    roleForAI: 'You are a customer service staff member. Ask for receipt and explain one policy condition.',
    firstMessage: 'Hello. How can I help you with this item today?',
    successCriteria: ['Learner explains defect', 'Learner makes a request', 'Learner negotiates politely'],
    starterHints: ['I bought this yesterday.', 'It does not work properly.', 'Could I exchange it?'],
    sortOrder: 80,
  },
  {
    slug: 'ielts-part2-memorable-trip',
    title: 'IELTS Part 2: memorable trip',
    description: 'Speak for an extended turn about a past travel experience.',
    group: 'ielts',
    levelSuggested: 'Intermediate',
    goals: ['Describe when and where', 'Explain what happened', 'Say why it was memorable'],
    roleForAI: 'You are an IELTS examiner. Give the cue card, let the learner answer, then ask one follow-up.',
    firstMessage: 'Describe a memorable trip you had. You should say where you went, who you went with, what you did, and why it was memorable.',
    successCriteria: ['Learner gives a multi-sentence answer', 'Learner uses past tense', 'Learner explains feelings/reasons'],
    starterHints: ['I went to...', 'The most memorable part was...', 'I still remember it because...'],
    sortOrder: 90,
  },
  {
    slug: 'ielts-part3-online-learning',
    title: 'IELTS Part 3: online learning',
    description: 'Discuss opinions, comparisons, and reasons about online learning.',
    group: 'ielts',
    levelSuggested: 'Advanced',
    goals: ['Give an opinion', 'Compare online and classroom learning', 'Support with reasons/examples'],
    roleForAI: 'You are an IELTS examiner asking abstract follow-up questions. Keep a formal examiner tone.',
    firstMessage: 'Do you think online learning is as effective as studying in a classroom?',
    successCriteria: ['Learner develops opinions', 'Learner compares two sides', 'Learner gives examples'],
    starterHints: ['In my view...', 'Compared with classroom learning...', 'A good example is...'],
    sortOrder: 100,
  },
  {
    slug: 'work-negotiate-deadline',
    title: 'Negotiate a deadline',
    description: 'Explain workload and ask for a realistic extension.',
    group: 'work',
    levelSuggested: 'Advanced',
    goals: ['Explain the reason professionally', 'Propose a new deadline', 'Offer a compromise'],
    roleForAI: 'You are a manager who needs the work soon but is open to a reasonable compromise.',
    firstMessage: 'I saw your message about the deadline. What is the situation?',
    successCriteria: ['Learner gives clear reason', 'Learner proposes specific date', 'Learner offers mitigation'],
    starterHints: ['The main issue is...', 'Could we move it to Friday?', 'I can send a partial draft today.'],
    sortOrder: 110,
  },
  {
    slug: 'daily-give-recommendation',
    title: 'Recommend a place to eat',
    description: 'Recommend a restaurant and justify the choice.',
    group: 'daily',
    levelSuggested: 'Intermediate',
    goals: ['Recommend one place', 'Describe food/price/location', 'Respond to preferences'],
    roleForAI: 'You are a friend asking for a restaurant recommendation. Mention one preference.',
    firstMessage: 'I want to try somewhere new for dinner. Do you know any good places?',
    successCriteria: ['Learner recommends clearly', 'Learner gives reasons', 'Learner responds to preference'],
    starterHints: ['You should try...', 'It is famous for...', 'If you like quiet places...'],
    sortOrder: 120,
  },
];

export async function seedSpeakingScenarios() {
  for (const scenario of scenarios) {
    await SpeakingScenario.updateOne(
      { slug: scenario.slug },
      { $set: { ...scenario, isActive: true, _destroy: false } },
      { upsert: true },
    );
  }
  console.log(`Seeded ${scenarios.length} speaking scenarios.`);
}

const run = async () => {
  const mongoUri = getMongoUri();
  if (!mongoUri) {
    throw new Error('Missing MONGO_URI');
  }
  await mongoose.connect(mongoUri);
  console.log(`Connected to DB (${getMongoUriForLog(mongoUri)})`);
  await seedSpeakingScenarios();
  await mongoose.connection.close();
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  run().catch(async (error) => {
    console.error('seedSpeakingScenarios failed:', error);
    await mongoose.connection.close().catch(() => {});
    process.exit(1);
  });
}
