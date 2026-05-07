import mongoose from 'mongoose';

const appReleaseSchema = new mongoose.Schema(
  {
    platform: {
      type: String,
      enum: ['android', 'ios'],
      required: true,
      index: true,
    },
    environment: {
      type: String,
      enum: ['production', 'staging'],
      required: true,
      default: 'production',
      index: true,
    },
    versionName: { type: String, required: true },
    versionCode: { type: Number, required: true, min: 1, index: true },
    minSupportedVersionCode: { type: Number, required: true, min: 1 },
    forceUpdate: { type: Boolean, default: false },
    updateType: {
      type: String,
      enum: ['soft', 'force'],
      default: 'soft',
    },
    status: {
      type: String,
      enum: ['pending_approval', 'approved', 'scheduled', 'published', 'rejected', 'archived'],
      default: 'pending_approval',
      index: true,
    },
    buildSource: { type: String, default: 'main' },
    gitSha: { type: String, default: '' },
    gitBranch: { type: String, default: 'main' },
    ciRunId: { type: String, default: '' },
    artifactUrlApk: { type: String, default: null },
    artifactUrlAab: { type: String, default: null },
    qaNotes: { type: String, default: '' },
    releaseNotes: { type: String, default: '' },
    storeUrl: { type: String, default: null },
    downloadUrl: { type: String, default: null },
    changelog: { type: String, default: '' },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    approvedAt: { type: Date, default: null },
    rejectedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    rejectedAt: { type: Date, default: null },
    rejectReason: { type: String, default: '' },
    scheduledPublishAt: { type: Date, default: null },
    publishedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    publishedAt: { type: Date, default: null, index: true },
    isActive: { type: Boolean, default: false, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  },
  {
    timestamps: true,
  },
);

appReleaseSchema.index(
  { platform: 1, environment: 1, versionCode: 1 },
  { unique: true, name: 'uniq_platform_env_version_code' },
);

const AppRelease = mongoose.model('AppRelease', appReleaseSchema);
export default AppRelease;
