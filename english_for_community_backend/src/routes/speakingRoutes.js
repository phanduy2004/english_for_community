import { authenticate, requireAdmin } from '../middleware/auth.js';
import express from "express"; // (Middleware check JWT)
const router = express.Router();
import {speakingController} from '../controllers/speakingController.js';

router.get('/vapi-config', authenticate, speakingController.getVapiConfig);
router.get('/progress/summary', authenticate, speakingController.getProgressSummary);
router.get('/scenarios', authenticate, speakingController.getScenarios);
router.get('/notebook', authenticate, speakingController.getNotebook);
router.post('/conversation/evaluate', authenticate, speakingController.evaluateConversation);
router.get('/conversation/history', authenticate, speakingController.getConversationHistory);
router.get('/conversation/:id', authenticate, speakingController.getConversationById);
router.get('/sets', authenticate, speakingController.getSpeakingSetsWithProgress);
router.get('/sets/:setId', authenticate, speakingController.getSpeakingSetDetails);
router.post('/submit', authenticate, speakingController.submitAttempt);
// 👇 Admin Routes (Mới)
router.get('/admin/list', authenticate, requireAdmin, speakingController.admin.getList);
router.get('/admin/deleted', authenticate, requireAdmin, speakingController.admin.getDeleted);
router.get('/admin/:id', authenticate, requireAdmin, speakingController.admin.getDetail);
router.post('/admin/:id/restore', authenticate, requireAdmin, speakingController.admin.restore);
router.post('/admin', authenticate, requireAdmin, speakingController.admin.create);
router.put('/admin/:id', authenticate, requireAdmin, speakingController.admin.update);
router.delete('/admin/:id', authenticate, requireAdmin, speakingController.admin.delete);
export default router;
