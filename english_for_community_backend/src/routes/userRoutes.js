import express from 'express';
import { 
    getProfile, 
    updateProfile, 
    deleteAccount 
} from '../controllers/userController.js';
import {authenticate} from '../middleware/auth.js';

const router = express.Router();

// Apply auth middleware to all routes
router.use(authenticate);

// GET /api/users/profile - Get user profile
router.get('/profile', getProfile);

// PUT /api/users/profile - Update user profile
router.put('/profile', updateProfile);

// DELETE /api/users/profile - Delete user account
router.delete('/profile', deleteAccount);

export default router;