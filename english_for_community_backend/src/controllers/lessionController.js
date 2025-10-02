import Lesson from '../models/Lesson.js';
import Listening from '../models/Listening.js';

// GET /api/lessons/:id
export const getLesson = async (req, res) => {
  try {
    const lesson = await Lesson.findById(req.params.id).lean();
    if (!lesson) return res.status(404).json({ message: 'Lesson not found' });

    let listening = null;
    if (lesson.type === 'listening') {
      const code = lesson.content?.listeningCode;
      if (code) {
        listening = await Listening.findOne(
          { code },
          { transcript: 0 } // hide transcript
        ).lean();
      }
    }

    return res.status(200).json({ lesson, listening });
  } catch (error) {
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
};