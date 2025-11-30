import express from 'express';
import { authenticate } from '../middleware/auth.js';
import {progressController} from "../controllers/progressController.js";

const router = express.Router();
router.use(authenticate);

router.get('/summary', progressController.getProgressSummary);
router.get('/detail', progressController.getStatDetail);
router.get('/leaderboard', progressController.getLeaderboard);
export default router;