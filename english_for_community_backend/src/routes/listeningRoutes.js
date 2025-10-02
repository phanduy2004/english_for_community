import express from 'express';
import {listeningController} from '../controllers/listeningController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();
router.use(authenticate);

router.get('/:id', listeningController.getListeningById);
router.get('/', listeningController.listListenings);   // GET /api/listenings

export default router;