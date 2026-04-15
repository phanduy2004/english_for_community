// src/routes/userRoutes.js
import express from 'express';
import {
  getProfile,
  updateProfile,
  deleteAccount,
  getPublicProfile,
  getUserDetailsForAdmin, changePassword, updateFcmToken
} from '../controllers/userController.js';
import { getMyActivities, getMyActivityDetail } from '../controllers/userActivityController.js';
import { authenticate, requirePermissions } from '../middleware/auth.js';
import { Permission } from '../constants/permissions.js';
import uploadCloud from "../config/cloudinary.js";

const router = express.Router();
router.use(authenticate);

// Lịch sử bài tập (user) — đặt trước các route /:id/... để không nhầm "me" với id
router.get('/me/activities', getMyActivities);
router.get('/me/activities/:activityId', getMyActivityDetail);

router.get('/profile', getProfile);
router.put('/profile', uploadCloud.single('avatar'), updateProfile);
router.delete('/profile', deleteAccount);
router.get('/:id/public', getPublicProfile);
router.get('/:id/admin-details', requirePermissions(Permission.USERS_READ), getUserDetailsForAdmin);
router.post('/change-password', changePassword);
router.post('/fcm-token', updateFcmToken);
export default router;
