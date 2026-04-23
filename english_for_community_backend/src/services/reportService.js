import Report from '../models/Report.js';

export async function createReportFromRequest({ userId, body, files }) {
  let { type, title, description, deviceInfo } = body;

  if (deviceInfo && typeof deviceInfo === 'string') {
    try {
      deviceInfo = JSON.parse(deviceInfo);
    } catch {
      deviceInfo = {};
    }
  }

  const images = files ? files.map(f => f.path) : [];

  const newReport = new Report({
    user: userId,
    type,
    title,
    description,
    deviceInfo,
    images,
  });

  await newReport.save();
  return newReport;
}

export async function listReports({ page = 1, limit = 20, status, search }) {
  const filter = {};
  if (status && status !== 'all') {
    filter.status = status;
  }
  if (search && search.trim()) {
    const q = search.trim();
    filter.$or = [
      { title: { $regex: q, $options: 'i' } },
      { description: { $regex: q, $options: 'i' } },
    ];
  }

  const p = parseInt(page, 10);
  const l = parseInt(limit, 10);

  const reports = await Report.find(filter)
    .populate('user', 'fullName email avatarUrl')
    .sort({ createdAt: -1 })
    .skip((p - 1) * l)
    .limit(l);

  const total = await Report.countDocuments(filter);

  return {
    data: reports,
    pagination: {
      page: p,
      limit: l,
      total,
      totalPages: Math.ceil(total / l),
    },
  };
}

export async function getReportById(id) {
  return Report.findById(id).populate('user', 'fullName email avatarUrl phone role');
}

export async function updateReportStatus(id, { status, adminResponse }) {
  const validStatuses = ['pending', 'reviewed', 'resolved', 'rejected'];
  if (status && !validStatuses.includes(status)) {
    return { error: { status: 400, message: 'Trạng thái không hợp lệ' } };
  }

  const updatedReport = await Report.findByIdAndUpdate(
    id,
    { status, adminResponse },
    { new: true },
  ).populate('user', 'fullName email');

  if (!updatedReport) {
    return { error: { status: 404, message: 'Không tìm thấy báo cáo' } };
  }

  return { data: updatedReport };
}
