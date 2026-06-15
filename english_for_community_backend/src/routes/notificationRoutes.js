import express from 'express';
import { notificationController } from '../controllers/notificationController.js';
import {authenticate} from "../middleware/auth.js";

const router = express.Router();
router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.patch('/read-all', notificationController.markAllAsRead);
router.post('/:id/respond', notificationController.respond);
router.patch('/:id/read', notificationController.markAsRead);
export default router;