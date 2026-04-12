import { generateChatReply } from '../services/chatService.js';

export const chatWithAI = async (req, res) => {
  const startT = Date.now();
  try {
    console.log(`\n--- 🟢 [CHAT START - GROQ] ${new Date().toLocaleTimeString()} ---`);
    const { message, history } = req.body;
    const userId = req.user.id;

    if (!message) return res.status(400).json({ message: 'Message required' });

    console.log(`💬 User: "${message}"`);
    const reply = await generateChatReply(userId, message, history);

    const duration = Date.now() - startT;
    console.log(`✅ Response time: ${duration}ms`);

    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    return res.json({ reply });
  } catch (error) {
    console.error('❌ CHAT ERROR:', error);
    res.status(500).json({ message: 'Lỗi hệ thống AI', error: error.message });
  }
};
