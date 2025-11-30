import { authenticate } from '../middleware/auth.js';
import express from "express"; // (Middleware check JWT)
const router = express.Router();
import {speakingController} from '../controllers/speakingController.js';

router.get('/sets', authenticate, speakingController.getSpeakingSetsWithProgress);
router.get('/sets/:setId', authenticate, speakingController.getSpeakingSetDetails);
router.post('/submit', authenticate, speakingController.submitAttempt);
// 👇 Admin Routes (Mới)
router.get('/admin/list', authenticate, speakingController.admin.getList);
router.get('/admin/:id', authenticate, speakingController.admin.getDetail);
router.post('/admin', authenticate, speakingController.admin.create);
router.put('/admin/:id', authenticate, speakingController.admin.update);
router.delete('/admin/:id', authenticate, speakingController.admin.delete);
export default router;
