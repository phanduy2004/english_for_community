import { Router } from 'express';
import {authenticate, requireAdmin} from '../middleware/auth.js';
import reportController from '../controllers/reportController.js';
import uploadCloud from "../config/cloudinary.js";

const router = Router();

router.use(authenticate);

// User gửi báo cáo
router.post('/', uploadCloud.array('images', 5), reportController.createReport);
// 1. Lấy danh sách (Có query ?status=pending&page=1)
router.get('/', requireAdmin, reportController.getReports);

// 2. Lấy chi tiết
router.get('/:id', requireAdmin, reportController.getReportDetail);

// 3. Cập nhật trạng thái (Body: { status: 'resolved', adminResponse: 'Done' })
router.patch('/:id/status', requireAdmin, reportController.updateReportStatus);
export default router;