const tool = (name, description, properties = {}, required = []) => ({
  type: 'function',
  function: {
    name,
    description,
    parameters: {
      type: 'object',
      properties,
      required,
    },
  },
});

export const chatTools = [
  tool(
    'get_learning_history',
    'Summarize UserDailyProgress between exact YYYY-MM-DD startDate and endDate. Use only when exact dates are known; otherwise use get_learning_history_period or get_daily_activity.',
    {
      startDate: { type: 'string', description: 'Start date YYYY-MM-DD' },
      endDate: { type: 'string', description: 'End date YYYY-MM-DD' },
    },
    ['startDate', 'endDate']
  ),
  tool(
    'get_learning_history_period',
    'Server computes the date range in the user timezone: today, week, last_week, or month.',
    {
      range: {
        type: 'string',
        enum: ['today', 'week', 'last_week', 'month'],
        description: 'today = user local today; week = rolling 7 days; last_week = previous calendar week; month = current month to today',
      },
    }
  ),
  tool(
    'get_daily_activity',
    'List completed activities for one calendar day in the user timezone. Use for questions about today or a specific day.',
    {
      date: { type: 'string', description: 'Optional YYYY-MM-DD. Empty means today in user timezone.' },
    }
  ),
  tool(
    'get_speaking_details',
    'List completed Speaking exercises. Can filter by date range and mode.',
    {
      limit: { type: 'number', description: 'Number of recent exercises, default 5' },
      mode: {
        type: 'string',
        enum: ['Read-aloud', 'Shadowing', 'all'],
        description: 'Optional speaking mode filter',
      },
      startDate: { type: 'string', description: 'Optional YYYY-MM-DD with endDate' },
      endDate: { type: 'string', description: 'Optional YYYY-MM-DD with startDate' },
    }
  ),
  tool(
    'get_reading_details',
    'List completed Reading exercises. Can filter by date range and difficulty.',
    {
      limit: { type: 'number', description: 'Number of recent exercises, default 5' },
      difficulty: {
        type: 'string',
        enum: ['easy', 'medium', 'hard', 'all'],
        description: 'Optional difficulty filter',
      },
      startDate: { type: 'string', description: 'Optional YYYY-MM-DD with endDate' },
      endDate: { type: 'string', description: 'Optional YYYY-MM-DD with startDate' },
    }
  ),
  tool(
    'get_writing_details',
    'List submitted Writing tasks. Can filter by topicId or submittedAt date range.',
    {
      limit: { type: 'number', description: 'Number of recent submissions, default 5' },
      topicId: { type: 'string', description: 'Optional topic ObjectId' },
      startDate: { type: 'string', description: 'Optional YYYY-MM-DD with endDate' },
      endDate: { type: 'string', description: 'Optional YYYY-MM-DD with startDate' },
    }
  ),
  tool(
    'get_listening_details',
    'List completed Dictation/Listening exercises. Can filter by lastAccessedAt date range.',
    {
      limit: { type: 'number', description: 'Number of recent exercises, default 5' },
      startDate: { type: 'string', description: 'Optional YYYY-MM-DD with endDate' },
      endDate: { type: 'string', description: 'Optional YYYY-MM-DD with startDate' },
    }
  ),
  tool(
    'get_vocab_list',
    'Get vocabulary by status: learning, saved, or recent.',
    {
      status: {
        type: 'string',
        enum: ['learning', 'saved', 'recent'],
        description: 'Vocabulary status',
      },
      limit: { type: 'number', description: 'Number of words, default 10' },
    }
  ),
  tool(
    'get_vocab_review',
    'Get words due for review today.',
    {
      limit: { type: 'number', description: 'Number of words, default 20' },
    }
  ),
  tool(
    'get_skill_statistics',
    'Get statistics for a specific skill over a period.',
    {
      skill: {
        type: 'string',
        enum: ['reading', 'writing', 'speaking', 'listening', 'vocab'],
        description: 'Skill to inspect',
      },
      range: {
        type: 'string',
        enum: ['today', 'day', 'week', 'last_week', 'month'],
        description: 'Period, default week',
      },
    },
    ['skill']
  ),
  tool(
    'get_leaderboard',
    'Get public top users by XP and the current user rank if present.',
    {}
  ),
  tool(
    'get_exercises_by_difficulty',
    'Find exercises matching a skill and difficulty that the user has not completed yet.',
    {
      skill: {
        type: 'string',
        enum: ['reading', 'speaking', 'listening'],
        description: 'Exercise skill',
      },
      difficulty: {
        type: 'string',
        enum: ['easy', 'medium', 'hard', 'Beginner', 'Intermediate', 'Advanced'],
        description: 'Exercise difficulty',
      },
      limit: { type: 'number', description: 'Number of exercises, default 5' },
    },
    ['skill', 'difficulty']
  ),
  tool(
    'analyze_weaknesses',
    'Analyze weak or neglected skills from recent learning history.',
    {
      range: {
        type: 'string',
        enum: ['today', 'day', 'week', 'last_week', 'month'],
        description: 'Period, default week',
      },
    }
  ),
  tool(
    'get_lesson_detail',
    'Get one Reading, Listening, or Speaking lesson and the user history for that lesson.',
    {
      lessonType: {
        type: 'string',
        enum: ['reading', 'listening', 'speaking'],
        description: 'Lesson type',
      },
      lessonId: { type: 'string', description: 'Lesson ObjectId' },
    },
    ['lessonType', 'lessonId']
  ),
  tool(
    'get_profile',
    'Get safe profile and learning-goal information for the authenticated user only.',
    {}
  ),
  tool(
    'get_classrooms',
    'Get active classrooms for the authenticated user, including teacher name and active member count.',
    {}
  ),
  tool(
    'get_exam_results',
    'Get recent exam attempts for the authenticated user only.',
    {
      limit: { type: 'number', description: 'Number of attempts, default 10, max 30' },
      status: {
        type: 'string',
        enum: ['submitted', 'graded', 'expired', 'all'],
        description: 'Filter by attempt status/result state. all means no status filter.',
      },
    }
  ),
  tool(
    'get_progress_trend',
    'Get daily progress trend for the authenticated user over today, week, last_week, or month.',
    {
      range: {
        type: 'string',
        enum: ['today', 'week', 'last_week', 'month'],
        description: 'Trend range, default week',
      },
    }
  ),
];
