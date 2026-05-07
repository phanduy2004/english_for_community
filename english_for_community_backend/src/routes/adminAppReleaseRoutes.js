import express from 'express';
import { appVersionController } from '../controllers/appVersionController.js';
import { authenticate, requireAdmin } from '../middleware/auth.js';

const router = express.Router();

router.use(authenticate, requireAdmin);

router.get('/', appVersionController.listReleases);
router.get('/:id', appVersionController.getReleaseById);
router.post('/:id/approve', appVersionController.approveRelease);
router.post('/:id/reject', appVersionController.rejectRelease);
router.post('/:id/schedule', appVersionController.scheduleRelease);
router.post('/:id/publish', appVersionController.publishRelease);
router.post('/:id/rollback', appVersionController.rollbackRelease);
router.post('/publish-due/run', appVersionController.publishDueScheduledReleases);

export default router;
