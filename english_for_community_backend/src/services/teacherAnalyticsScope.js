import mongoose from 'mongoose';
import Classroom from '../models/Classroom.js';
import ClassroomMember from '../models/ClassroomMember.js';
import ExamAssignment from '../models/ExamAssignment.js';

const DAY_MS = 24 * 60 * 60 * 1000;
const VN_OFFSET_MS = 7 * 60 * 60 * 1000; // Asia/Ho_Chi_Minh, khớp adminService.getVnDateRange

/**
 * Định nghĩa "cần chấm" CHUẨN — dùng chung cho inbox action-items, analytics summary
 * và analytics charts để 3 nơi không lệch nhau (finding #6). Chỉ bài ĐÃ NỘP và:
 *  - đang chờ chấm tay/AI, HOẶC
 *  - đã finalized nhưng CHƯA phát hành kết quả.
 */
export const gradingAttentionMatch = {
  status: 'submitted',
  $or: [
    { gradingState: { $in: ['pending_manual', 'pending_ai'] } },
    { gradingState: 'finalized', resultsReleased: { $ne: true } },
  ],
};

/** Các lớp giáo viên SỞ HỮU (chưa archive) HOẶC đang dạy-cùng (co_teacher active). */
export async function classroomIdsForTeacher(teacherId) {
  const [owned, co] = await Promise.all([
    Classroom.find({ teacherId, archived: false }).select('_id').lean(),
    ClassroomMember.find({ userId: teacherId, roleInClass: 'co_teacher', status: 'active' })
      .select('classroomId')
      .lean(),
  ]);
  const ids = new Set(owned.map((c) => c._id.toString()));
  for (const m of co) ids.add(m.classroomId.toString());
  return [...ids].map((id) => new mongoose.Types.ObjectId(id));
}

/**
 * Phạm vi analytics của 1 giáo viên (finding #8 — GỒM cả lớp dạy-cùng):
 * assignments = do chính teacher tạo (bất kỳ) ∪ assignment thuộc lớp trong classIds
 * (owner + co-taught). Trả { classIds, assignments, assignmentIds }.
 */
export async function teacherAnalyticsScope(
  teacherId,
  projection = '_id examId mode status classroomId config audience',
  { classroomId = null } = {}
) {
  let classIds = await classroomIdsForTeacher(teacherId);

  let filter;
  if (classroomId) {
    // Lọc theo 1 lớp: chỉ khi GV có quyền lớp đó (owner / co-teacher active), và chỉ
    // lấy assignment THUỘC lớp đó. Không có quyền → phạm vi rỗng (không rò rỉ lớp khác).
    const cid = String(classroomId);
    if (!classIds.some((id) => id.toString() === cid)) {
      return { classIds: [], assignments: [], assignmentIds: [] };
    }
    const cidObj = new mongoose.Types.ObjectId(cid);
    classIds = [cidObj];
    filter = { classroomId: cidObj };
  } else {
    filter = {
      $or: [
        { teacherId },
        { teacherId: new mongoose.Types.ObjectId(String(teacherId)) },
        { classroomId: { $in: classIds } },
      ],
    };
  }

  const assignments = await ExamAssignment.find(filter).select(projection).lean();
  return { classIds, assignments, assignmentIds: assignments.map((a) => a._id) };
}

/**
 * Cửa sổ N ngày theo LỊCH VN, kết thúc HÔM NAY (finding #1/#2). Trả về Date (UTC):
 *  - since     = 00:00 VN của ngày (today − (nDays−1))  → window [since, now] = N ngày VN, GỒM hôm nay
 *  - prevSince = since − nDays ngày                      → kỳ trước [prevSince, since)
 * `nowMs` truyền vào để test tất định (không gọi Date.now bên trong).
 */
export function resolveWindow(nowMs, nDays) {
  const vn = new Date(nowMs + VN_OFFSET_MS);
  vn.setUTCHours(0, 0, 0, 0);
  const todayStart = new Date(vn.getTime() - VN_OFFSET_MS); // 00:00 VN hôm nay, dạng UTC
  const since = new Date(todayStart.getTime() - (nDays - 1) * DAY_MS);
  const prevSince = new Date(since.getTime() - nDays * DAY_MS);
  return { since, prevSince };
}
