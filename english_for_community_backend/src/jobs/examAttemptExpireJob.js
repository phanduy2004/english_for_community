import cron from 'node-cron';
import { examAttemptService } from '../services/examAttemptService.js';

/**
 * Marks in_progress exam attempts as expired when attemptDeadlineAt has passed.
 * Complements lazy expiry on read (getAttempt / patch).
 */
export function initExamAttemptExpireJob() {
  cron.schedule('*/2 * * * *', async () => {
    try {
      const n = await examAttemptService.bulkExpirePastDeadline();
      if (n > 0) console.log(`[examAttemptExpire] expired ${n} attempt(s)`);
    } catch (e) {
      console.error('[examAttemptExpire]', e);
    }
  });
}
