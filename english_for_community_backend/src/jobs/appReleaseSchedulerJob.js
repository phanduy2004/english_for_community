import cron from 'node-cron';
import { appVersionService } from '../services/appVersionService.js';

export const initAppReleaseSchedulerJob = () => {
  console.log('⏱️ App Release Scheduler Job started (every minute)');

  cron.schedule('* * * * *', async () => {
    try {
      const result = await appVersionService.publishDueScheduledReleases({
        actorRole: 'system',
        actorId: null,
        ip: 'cron',
        userAgent: 'app-release-scheduler',
      });
      if (result.count > 0) {
        console.log(`✅ Auto-published ${result.count} scheduled release(s).`);
      }
    } catch (error) {
      console.error('❌ App Release Scheduler error:', error?.message || error);
    }
  });
};
