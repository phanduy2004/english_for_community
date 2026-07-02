import cron from 'node-cron';
import { examSessionService } from '../services/examSessionService.js';

/**
 * Auto-closes live exam sessions whose scheduled end (time limit / hardEndAt) has passed.
 * Complements the lazy auto-end that only fires when someone reads the realtime payload.
 */
export function initExamSessionExpireJob() {
  cron.schedule('* * * * *', async () => {
    try {
      const n = await examSessionService.bulkAutoEndDueLiveSessions();
      if (n > 0) console.log(`[examSessionExpire] auto-ended ${n} live session(s)`);
    } catch (e) {
      console.error('[examSessionExpire]', e);
    }
  });
}
