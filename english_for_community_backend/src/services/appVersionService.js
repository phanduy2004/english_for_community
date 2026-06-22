import { z } from 'zod';
import AppRelease from '../models/AppRelease.js';
import { writeAdminAudit } from './adminAuditService.js';
import { assertTransition, ReleaseStatus } from './releaseStateMachine.js';

const platformSchema = z.enum(['android', 'ios']);
const environmentSchema = z.enum(['production', 'staging']);

const versionCheckSchema = z.object({
  platform: platformSchema,
  environment: environmentSchema.default('production'),
  versionCode: z.coerce.number().int().min(1),
});

const ciCandidateSchema = z.object({
  platform: platformSchema,
  environment: environmentSchema.default('production'),
  versionName: z.string().min(1),
  versionCode: z.number().int().min(1),
  minSupportedVersionCode: z.number().int().min(1).optional(),
  forceUpdate: z.boolean().optional().default(false),
  updateType: z.enum(['soft', 'force']).optional().default('soft'),
  buildSource: z.string().optional().default('main'),
  gitSha: z.string().optional().default(''),
  gitBranch: z.string().optional().default('main'),
  ciRunId: z.string().optional().default(''),
  artifactUrlApk: z.string().url().nullable().optional(),
  artifactUrlAab: z.string().url().nullable().optional(),
  storeUrl: z.string().url().nullable().optional(),
  downloadUrl: z.string().url().nullable().optional(),
  changelog: z.string().max(4000).optional().default(''),
  releaseNotes: z.string().max(4000).optional().default(''),
});

const listReleasesSchema = z.object({
  status: z.enum(['pending_approval', 'approved', 'scheduled', 'published', 'rejected', 'archived']).optional(),
  platform: platformSchema.optional(),
  environment: environmentSchema.optional(),
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

const rejectSchema = z.object({
  reason: z.string().min(3).max(500),
});

const scheduleSchema = z.object({
  scheduledPublishAt: z.coerce.date(),
});

async function writeReleaseAudit({ context, action, release, metadata = {}, afterStatus }) {
  await writeAdminAudit({
    actorId: context.actorId,
    actorRole: context.actorRole,
    action,
    targetType: 'app_release',
    targetId: release._id?.toString() || 'unknown',
    metadata: {
      releaseId: release._id?.toString(),
      platform: release.platform,
      environment: release.environment,
      versionCode: release.versionCode,
      beforeStatus: release.status,
      afterStatus,
      ...metadata,
    },
    ip: context.ip || '',
    userAgent: context.userAgent || '',
  });
}

async function createReleaseCandidate(rawBody, context = {}) {
  const payload = ciCandidateSchema.parse(rawBody);
  const normalizedForce = payload.updateType === 'force' || payload.forceUpdate === true;
  const minSupportedVersionCode = payload.minSupportedVersionCode ?? payload.versionCode;

  if (minSupportedVersionCode > payload.versionCode) {
    const error = new Error('minSupportedVersionCode must be <= versionCode');
    error.statusCode = 400;
    throw error;
  }

  const candidate = await AppRelease.findOneAndUpdate(
    {
      platform: payload.platform,
      environment: payload.environment,
      versionCode: payload.versionCode,
    },
    {
      $set: {
        platform: payload.platform,
        environment: payload.environment,
        versionName: payload.versionName,
        versionCode: payload.versionCode,
        minSupportedVersionCode,
        forceUpdate: normalizedForce,
        updateType: normalizedForce ? 'force' : 'soft',
        status: ReleaseStatus.pendingApproval,
        buildSource: payload.buildSource,
        gitSha: payload.gitSha,
        gitBranch: payload.gitBranch,
        ciRunId: payload.ciRunId,
        artifactUrlApk: payload.artifactUrlApk ?? null,
        artifactUrlAab: payload.artifactUrlAab ?? null,
        storeUrl: payload.storeUrl ?? null,
        downloadUrl: payload.downloadUrl ?? null,
        changelog: payload.changelog,
        releaseNotes: payload.releaseNotes,
        isActive: false,
      },
      $setOnInsert: { createdBy: context.actorId || null },
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_CANDIDATE_CREATED',
    release: candidate,
    metadata: { source: 'ci' },
    afterStatus: ReleaseStatus.pendingApproval,
  });

  return candidate;
}

async function listReleases(rawQuery) {
  const parsed = listReleasesSchema.parse(rawQuery);
  const filter = {};
  if (parsed.status) filter.status = parsed.status;
  if (parsed.platform) filter.platform = parsed.platform;
  if (parsed.environment) filter.environment = parsed.environment;

  const [data, total] = await Promise.all([
    AppRelease.find(filter)
      .sort({ createdAt: -1 })
      .skip((parsed.page - 1) * parsed.limit)
      .limit(parsed.limit)
      .lean(),
    AppRelease.countDocuments(filter),
  ]);

  return {
    data,
    pagination: {
      page: parsed.page,
      limit: parsed.limit,
      total,
      totalPages: Math.ceil(total / parsed.limit),
    },
  };
}

async function getReleaseById(id) {
  const release = await AppRelease.findById(id).lean();
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  return release;
}

async function approveRelease(id, context = {}) {
  const release = await AppRelease.findById(id);
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  assertTransition(release.status, ReleaseStatus.approved);

  release.status = ReleaseStatus.approved;
  release.approvedBy = context.actorId || null;
  release.approvedAt = new Date();
  release.rejectedBy = null;
  release.rejectedAt = null;
  release.rejectReason = '';
  await release.save();

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_APPROVED',
    release,
    afterStatus: ReleaseStatus.approved,
  });

  return release;
}

async function rejectRelease(id, rawBody, context = {}) {
  const payload = rejectSchema.parse(rawBody);
  const release = await AppRelease.findById(id);
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  if (
    ![
      ReleaseStatus.pendingApproval,
      ReleaseStatus.approved,
      ReleaseStatus.scheduled,
    ].includes(release.status)
  ) {
    const error = new Error(`Invalid transition from status: ${release.status} -> ${ReleaseStatus.rejected}`);
    error.statusCode = 400;
    throw error;
  }

  release.status = ReleaseStatus.rejected;
  release.rejectedBy = context.actorId || null;
  release.rejectedAt = new Date();
  release.rejectReason = payload.reason;
  release.isActive = false;
  await release.save();

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_REJECTED',
    release,
    metadata: { reason: payload.reason },
    afterStatus: ReleaseStatus.rejected,
  });

  return release;
}

async function scheduleRelease(id, rawBody, context = {}) {
  const payload = scheduleSchema.parse(rawBody);
  const release = await AppRelease.findById(id);
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  assertTransition(release.status, ReleaseStatus.scheduled);

  release.status = ReleaseStatus.scheduled;
  release.scheduledPublishAt = payload.scheduledPublishAt;
  await release.save();

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_SCHEDULED',
    release,
    metadata: { scheduledPublishAt: payload.scheduledPublishAt.toISOString() },
    afterStatus: ReleaseStatus.scheduled,
  });

  return release;
}

async function publishRelease(id, context = {}) {
  const release = await AppRelease.findById(id);
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  if (![ReleaseStatus.approved, ReleaseStatus.scheduled].includes(release.status)) {
    const error = new Error(`Invalid transition from status: ${release.status} -> ${ReleaseStatus.published}`);
    error.statusCode = 400;
    throw error;
  }

  await AppRelease.updateMany(
    {
      platform: release.platform,
      environment: release.environment,
      status: ReleaseStatus.published,
      isActive: true,
      _id: { $ne: release._id },
    },
    { $set: { isActive: false, status: ReleaseStatus.archived } },
  );

  release.status = ReleaseStatus.published;
  release.isActive = true;
  release.publishedBy = context.actorId || null;
  release.publishedAt = new Date();
  await release.save();

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_PUBLISHED',
    release,
    afterStatus: ReleaseStatus.published,
  });

  return release;
}

async function rollbackRelease(id, context = {}) {
  const release = await AppRelease.findById(id);
  if (!release) {
    const error = new Error('Release not found');
    error.statusCode = 404;
    throw error;
  }
  assertTransition(release.status, ReleaseStatus.archived);

  const previous = await AppRelease.findOne({
    platform: release.platform,
    environment: release.environment,
    status: ReleaseStatus.archived,
    _id: { $ne: release._id },
  }).sort({ publishedAt: -1, createdAt: -1 });

  if (!previous) {
    const error = new Error('No previous archived release to rollback');
    error.statusCode = 400;
    throw error;
  }

  release.status = ReleaseStatus.archived;
  release.isActive = false;
  await release.save();

  previous.status = ReleaseStatus.published;
  previous.isActive = true;
  previous.publishedBy = context.actorId || null;
  previous.publishedAt = new Date();
  await previous.save();

  await writeReleaseAudit({
    context,
    action: 'APP_RELEASE_ROLLBACK',
    release,
    metadata: { rollbackToReleaseId: previous._id.toString() },
    afterStatus: ReleaseStatus.archived,
  });

  return { rolledBackRelease: release, activeRelease: previous };
}

async function publishDueScheduledReleases(context = {}) {
  const now = new Date();
  const dueReleases = await AppRelease.find({
    status: ReleaseStatus.scheduled,
    scheduledPublishAt: { $ne: null, $lte: now },
  }).sort({ scheduledPublishAt: 1 });

  const results = [];
  for (const release of dueReleases) {
    const published = await publishRelease(release._id.toString(), context);
    results.push({
      id: published._id.toString(),
      platform: published.platform,
      environment: published.environment,
      versionCode: published.versionCode,
      status: published.status,
      publishedAt: published.publishedAt,
    });
  }
  return { count: results.length, data: results };
}

function resolveStatus({ currentVersionCode, minSupportedVersionCode, latestVersionCode, forceUpdate }) {
  if (currentVersionCode < minSupportedVersionCode) return 'force_update';
  if (forceUpdate && currentVersionCode < latestVersionCode) return 'force_update';
  if (currentVersionCode < latestVersionCode) return 'soft_update';
  return 'up_to_date';
}

async function checkVersion(rawQuery) {
  const parsed = versionCheckSchema.parse(rawQuery);

  const latestRelease = await AppRelease.findOne({
    platform: parsed.platform,
    environment: parsed.environment,
    status: ReleaseStatus.published,
    isActive: true,
  })
    .sort({ versionCode: -1, publishedAt: -1 })
    .lean();

  if (!latestRelease) {
    // Không có release published+active khớp platform/environment → client sẽ thấy
    // 'up_to_date'. Log để ops phát hiện (vd release còn pending_approval, env lệch,
    // hoặc row mồ côi ở DB cũ) thay vì im lặng.
    console.warn(
      `[version-check] no published+active release for platform=${parsed.platform} environment=${parsed.environment}`
    );
    return {
      status: 'up_to_date',
      latestVersionName: null,
      latestVersionCode: parsed.versionCode,
      minSupportedVersionCode: parsed.versionCode,
      forceUpdate: false,
      storeUrl: null,
      downloadUrl: null,
      changelog: '',
      publishedAt: null,
    };
  }

  const status = resolveStatus({
    currentVersionCode: parsed.versionCode,
    minSupportedVersionCode: latestRelease.minSupportedVersionCode,
    latestVersionCode: latestRelease.versionCode,
    forceUpdate: latestRelease.forceUpdate,
  });

  return {
    status,
    latestVersionName: latestRelease.versionName,
    latestVersionCode: latestRelease.versionCode,
    minSupportedVersionCode: latestRelease.minSupportedVersionCode,
    forceUpdate: status === 'force_update',
    storeUrl: latestRelease.storeUrl ?? null,
    downloadUrl: latestRelease.downloadUrl ?? null,
    changelog: latestRelease.changelog ?? '',
    publishedAt: latestRelease.publishedAt ?? latestRelease.createdAt ?? null,
  };
}

export const appVersionService = {
  checkVersion,
  createReleaseCandidate,
  listReleases,
  getReleaseById,
  approveRelease,
  rejectRelease,
  scheduleRelease,
  publishRelease,
  rollbackRelease,
  publishDueScheduledReleases,
};
