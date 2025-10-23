// src/seeds/seedWritingTopics.js

import WritingTopic from "../models/WritingTopics.js";
import WritingTopics from "../models/WritingTopics.js";

const TASK_TYPES = [
  'Opinion',
  'Discussion',
  'Advantages-Disadvantages',
  'Problem-Solution',
  'Discuss both views and give your own opinion',
  'Two-part question'
];

const RAW_TOPICS = [
  { name: 'Art',               slug: 'art',               icon: 'brush',      color: '#8E44AD' },
  { name: 'Technology',        slug: 'technology',        icon: 'memory',     color: '#2E86C1' },
  { name: 'Education',         slug: 'education',         icon: 'school',     color: '#1ABC9C' },
  { name: 'Environment',       slug: 'environment',       icon: 'public',     color: '#27AE60' },
  { name: 'Health',            slug: 'health',            icon: 'favorite',   color: '#E74C3C' },
  { name: 'Science & Innovation', slug: 'science',        icon: 'science',    color: '#16A085' },
  { name: 'Society & Culture', slug: 'society-culture',   icon: 'diversity_3',color: '#D35400' },
  { name: 'Government & Policy', slug: 'government',      icon: 'gavel',      color: '#34495E' },
  { name: 'Economy & Business', slug: 'economy-business', icon: 'business',   color: '#2C3E50' },
  { name: 'Media & Communication', slug: 'media',         icon: 'campaign',   color: '#9B59B6' },
  { name: 'Travel & Tourism',  slug: 'travel',            icon: 'flight',     color: '#2980B9' },
  { name: 'Urbanization & Housing', slug: 'urbanization', icon: 'location_city', color: '#7F8C8D' },
  { name: 'Work & Careers',    slug: 'work-careers',      icon: 'work',       color: '#16A085' },
  { name: 'Family & Relationships', slug: 'family',       icon: 'family_restroom', color: '#E67E22' },
  { name: 'Food & Lifestyle',  slug: 'food-lifestyle',    icon: 'restaurant', color: '#C0392B' },
];

export async function seedWritingTopics() {
  // Nếu đã có dữ liệu thì thôi (tránh trùng lặp)
  const count = await WritingTopics.countDocuments();
  if (count > 0) {
    console.log('writing_topics already has data — skip seeding.');
    return;
  }

  const docs = RAW_TOPICS.map((it, i) => ({
    ...it,
    order: i,
    isActive: true,
    aiConfig: {
      language: 'vi-VN',
      taskTypes: TASK_TYPES,
      defaultTaskType: 'Discuss both views and give your own opinion',
      level: 'Intermediate',
      targetWordCount: '250–320',
      generationTemplate: null,
    },
    stats: { submissionsCount: 0, avgScore: null },
  }));

  await WritingTopic.insertMany(docs);
  console.log(`Seeded writing_topics: ${docs.length} items ✅`);
}
