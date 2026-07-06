/**
 * Classroom Group Chat routes
 * Base: /api/classroom-chat/:classroomId
 */
import express from 'express';
import multer from 'multer';
import { authenticate } from '../middleware/auth.js';
import * as ctrl from '../controllers/classroomChatController.js';

const router = express.Router({ mergeParams: true });

// Multer: memory storage — classroomChatService uploads to Cloudinary
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB
});

// ── Messages ────────────────────────────────────────────────────────────────
// GET  /api/classroom-chat/:classroomId/messages?before=<cursor>&limit=30
router.get('/messages', authenticate, ctrl.getMessages);

// POST /api/classroom-chat/:classroomId/messages
router.post('/messages', authenticate, ctrl.sendMessage);

// PATCH /api/classroom-chat/:classroomId/messages/:messageId
router.patch('/messages/:messageId', authenticate, ctrl.editMessage);

// DELETE /api/classroom-chat/:classroomId/messages/:messageId
router.delete('/messages/:messageId', authenticate, ctrl.deleteMessage);

// ── Reactions ───────────────────────────────────────────────────────────────
// POST /api/classroom-chat/:classroomId/messages/:messageId/react
router.post('/messages/:messageId/react', authenticate, ctrl.reactMessage);

// ── Media upload ─────────────────────────────────────────────────────────────
// POST /api/classroom-chat/:classroomId/upload
router.post('/upload', authenticate, (req, res, next) => {
  upload.single('file')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ message: 'Tệp quá lớn (tối đa 50MB)' });
      }
      return res.status(400).json({ message: err.message || 'Upload thất bại' });
    }
    return ctrl.uploadMedia(req, res);
  });
});

// ── Members (for @mention) ────────────────────────────────────────────────────
// GET  /api/classroom-chat/:classroomId/members
router.get('/members', authenticate, ctrl.getChatMembers);

// ── Settings & pin ───────────────────────────────────────────────────────────
router.get('/settings', authenticate, ctrl.getChatSettings);
router.patch('/settings', authenticate, ctrl.updateChatSettings);
router.post('/avatar', authenticate, (req, res, next) => {
  upload.single('file')(req, res, (err) => {
    if (err) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ message: 'Ảnh quá lớn (tối đa 50MB)' });
      }
      return res.status(400).json({ message: err.message || 'Upload thất bại' });
    }
    return ctrl.uploadChatAvatar(req, res);
  });
});
router.post('/messages/:messageId/pin', authenticate, ctrl.pinMessage);
router.delete('/pin', authenticate, ctrl.unpinMessage);
router.post('/read', authenticate, ctrl.markChatRead);

// ── Per-user conversation settings (mute / pin hội thoại) ─────────────────────
router.post('/mute', authenticate, ctrl.setChatMuted);
router.post('/pin-conversation', authenticate, ctrl.setChatPinned);

export default router;
