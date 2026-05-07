import express from 'express';
import { appVersionController } from '../controllers/appVersionController.js';

const router = express.Router();

function verifyCiToken(req, res, next) {
  const expected = process.env.CI_RELEASE_TOKEN;
  if (!expected) {
    return res.status(500).json({ message: 'CI_RELEASE_TOKEN is not configured on server.' });
  }
  const received = req.get('x-ci-token') || req.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!received || received !== expected) {
    return res.status(401).json({ message: 'Invalid CI token' });
  }
  return next();
}

router.get('/version-check', appVersionController.checkVersion);
router.post('/releases/ci-candidates', verifyCiToken, appVersionController.createReleaseCandidate);

export default router;
