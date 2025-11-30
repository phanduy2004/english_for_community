// src/routes/userRoutes.js
import express from 'express';
import { getProfile, updateProfile, deleteAccount } from '../controllers/userController.js';
import { authenticate } from '../middleware/auth.js';
import uploadCloud from "../config/cloudinary.js";

const router = express.Router();
router.use(authenticate);
router.get('/profile', getProfile);
router.put('/profile', uploadCloud.single('avatar'), updateProfile);
router.delete('/profile', deleteAccount);
export default router;
