// src/routes/userRoutes.js
import express from 'express';
import { getProfile, updateProfile, deleteAccount } from '../controllers/userController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.delete('/profile', deleteAccount);
export default router;
