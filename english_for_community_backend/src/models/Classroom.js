import mongoose from 'mongoose';
import { toJsonIdPlugin, softDeletePlugin } from '../lib/mongoosePlugins.js';

const classroomSchema = new mongoose.Schema(
  {
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    coverImageUrl: { type: String, default: '' },
    inviteCode: { type: String, required: true, unique: true, index: true },
    inviteToken: { type: String, required: true, unique: true, index: true },
    joinPolicy: { type: String, enum: ['open', 'approval_required'], default: 'open' },
    /** Tin nhắn ghim trong nhóm chat (chỉ GV chủ lớp). */
    pinnedMessageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassroomMessage',
      default: null,
    },
    archived: { type: Boolean, default: false, index: true },
    settings: {
      type: new mongoose.Schema(
        { allowStudentInvite: { type: Boolean, default: false } },
        { _id: false }
      ),
      default: () => ({}),
    },
    integrations: {
      type: new mongoose.Schema(
        {
          googleClassroom: {
            type: new mongoose.Schema(
              {
                courseId: String,
                courseName: String,
                linkedAt: String,
              },
              { _id: false }
            ),
            default: null,
          },
          lti: {
            type: new mongoose.Schema(
              { contextId: String, platformIssuer: String, linkedAt: String },
              { _id: false }
            ),
            default: null,
          },
        },
        { _id: false }
      ),
      default: () => ({}),
    },
  },
  { timestamps: true }
);

classroomSchema.index({ teacherId: 1, archived: 1, updatedAt: -1 });

toJsonIdPlugin(classroomSchema);
softDeletePlugin(classroomSchema, { useDestroyFlag: false });

classroomSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

const Classroom = mongoose.model('Classroom', classroomSchema);
export default Classroom;
