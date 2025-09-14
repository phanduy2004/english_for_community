// src/routes/authRoutes.js
import { Router } from 'express';
import authController from '../controllers/authController.js'; // đi lên 1 cấp

const router = Router();

router.post('/register', authController.register);
router.post('/login', authController.login);

export default router;
