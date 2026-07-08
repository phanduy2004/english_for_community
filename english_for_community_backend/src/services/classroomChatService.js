/**
 * classroomChatService.js
 * Business logic cho Group Chat lớp học.
 *
 * Nghiệp vụ:
 *  - Chỉ thành viên (student, co_teacher) + chủ lớp (teacher) mới được chat.
 *  - Soft-delete: chỉ người gửi hoặc teacher mới xóa được.
 *  - Reaction: mỗi user chỉ toggle 1 lần trên mỗi emoji.
 *  - Upload ảnh/video/file qua Cloudinary trước khi lưu DB.
 *  - Pagination cursor-based (createdAt + _id) cho hiệu năng tốt với chat lớn.
 */
import ClassroomMessage from '../models/ClassroomMessage.js';
import ClassroomMember from '../models/ClassroomMember.js';
import Classroom from '../models/Classroom.js';
import ClassroomChatReadState from '../models/ClassroomChatReadState.js';
import User from '../models/User.js';
import { uploadMulterFileToCloudinary } from '../config/cloudinary.js';
import mongoose from 'mongoose';
import { getIO } from '../socket/socketManager.js';

const PAGE_SIZE = 30;
const MAX_CONTENT_LENGTH = 4000;
const ALLOWED_EMOJIS = ['❤️', '👍', '😂', '😮', '😢', '😡', '🎉', '👏'];

// ─── Helpers ────────────────────────────────────────────────────────────────

function httpErr(code, msg) {
  const e = new Error(msg);
  e.statusCode = code;
  return e;
}

async function assertMember(classroomId, userId) {
  const room = await Classroom.findById(classroomId).lean();
  if (!room) throw httpErr(404, 'Classroom not found');

  // Teacher (owner) is always allowed
  if (String(room.teacherId) === String(userId)) return { room, role: 'teacher' };

  const member = await ClassroomMember.findOne({
    classroomId,
    userId,
    status: 'active',
  }).lean();
  if (!member) throw httpErr(403, 'Bạn không phải thành viên lớp này');
  return { room, role: member.roleInClass };
}

async function assertClassOwner(classroomId, userId) {
  const { room } = await assertMember(classroomId, userId);
  if (String(room.teacherId) !== String(userId)) {
    throw httpErr(403, 'Chỉ giáo viên chủ lớp mới được thực hiện thao tác này');
  }
  return room;
}

async function fetchPinnedMessage(classroomId) {
  const room = await Classroom.findById(classroomId).select('pinnedMessageId').lean();
  if (!room?.pinnedMessageId) return null;
  const msg = await ClassroomMessage.findById(room.pinnedMessageId)
    .populate('senderId', 'fullName username avatarUrl')
    .lean();
  if (!msg || msg.deletedAt) return null;
  return messagePublicView(msg);
}

function messagePublicView(doc) {
  const m = typeof doc.toJSON === 'function' ? doc.toJSON() : doc;
  if (m.deletedAt) {
    return {
      id: m.id,
      classroomId: m.classroomId,
      senderId: m.senderId,
      type: m.type,
      deletedAt: m.deletedAt,
      content: '',
      media: null,
      replyTo: m.replyTo,
      reactions: m.reactions,
      mentions: m.mentions,
      createdAt: m.createdAt,
    };
  }
  return m;
}

function roomName(classroomId) {
  return `classroom_chat_${classroomId}`;
}

function emitToUser(userId, event, payload) {
  try {
    getIO().to(String(userId)).emit(event, payload);
  } catch (_) {}
}

function senderDisplayName(sender) {
  if (!sender) return 'Thành viên';
  if (typeof sender === 'object') {
    return sender.fullName || sender.username || 'Thành viên';
  }
  return 'Thành viên';
}

function buildMessagePreview(msg) {
  if (!msg) return '';
  if (msg.deletedAt) return '[Tin nhắn đã bị xóa]';
  switch (msg.type) {
    case 'image':
      return '📷 Ảnh';
    case 'video':
      return '🎬 Video';
    case 'file':
      return msg.media?.name ? `📎 ${msg.media.name}` : '📎 Tệp đính kèm';
    default:
      return (msg.content || '').trim().slice(0, 120) || 'Tin nhắn';
  }
}

async function getClassroomMemberUserIds(classroomId) {
  const room = await Classroom.findById(classroomId).select('teacherId').lean();
  if (!room) return [];
  const ids = new Set([String(room.teacherId)]);
  const members = await ClassroomMember.find({
    classroomId,
    status: 'active',
  })
    .select('userId')
    .lean();
  for (const m of members) {
    if (m.userId) ids.add(String(m.userId));
  }
  return [...ids];
}

async function countActiveMembers(classroomId) {
  const room = await Classroom.findById(classroomId).select('teacherId').lean();
  if (!room) return 0;
  const memberCount = await ClassroomMember.countDocuments({
    classroomId,
    status: 'active',
  });
  return memberCount + 1;
}

function emitToRoom(classroomId, event, payload) {
  try {
    getIO().to(roomName(classroomId)).emit(event, payload);
  } catch (_) {
    // socket not initialized during tests
  }
}

async function emitInboxCoverUpdate(classroomId, coverImageUrl) {
  const memberIds = await getClassroomMemberUserIds(classroomId);
  const payload = {
    classroomId: String(classroomId),
    coverImageUrl: coverImageUrl ?? '',
  };
  for (const uid of memberIds) {
    emitToUser(uid, 'classroom_chat_inbox_updated', payload);
  }
}

async function emitInboxUpdates(classroomId, messageView, senderId) {
  const memberIds = await getClassroomMemberUserIds(classroomId);
  const senderName = senderDisplayName(messageView.senderId);
  const base = {
    classroomId: String(classroomId),
    lastMessage: {
      preview: buildMessagePreview(messageView),
      senderName,
      senderId: String(senderId),
      type: messageView.type || 'text',
      createdAt: messageView.createdAt,
    },
  };
  for (const uid of memberIds) {
    if (String(uid) === String(senderId)) {
      emitToUser(uid, 'classroom_chat_inbox_updated', { ...base, unreadCount: 0 });
    } else {
      emitToUser(uid, 'classroom_chat_inbox_updated', { ...base, unreadDelta: 1 });
    }
  }
}

// Báo cho CHỦ tin nhắn khi có người thả reaction mới: badge danh sách chat +1
// và card hội thoại hiện preview "X đã thả <emoji> vào tin nhắn của bạn".
// Chỉ đẩy tới đúng chủ tin nhắn (không phải cả lớp) và chỉ khi là reaction mới.
async function emitReactionInboxUpdate(classroomId, ownerId, reactorId, emoji) {
  const reactor = await User.findById(reactorId).select('fullName username').lean();
  const reactorName = reactor?.fullName || reactor?.username || 'Thành viên';
  emitToUser(String(ownerId), 'classroom_chat_inbox_updated', {
    classroomId: String(classroomId),
    lastMessage: {
      // Cả câu nằm trong preview + senderName rỗng: client ghép "{firstWord(senderName)}: {preview}",
      // để rỗng để không lặp tên và giữ đúng câu đầy đủ.
      preview: `${reactorName} đã thả ${emoji} vào tin nhắn của bạn`,
      senderName: '',
      senderId: String(reactorId),
      type: 'reaction',
      createdAt: new Date().toISOString(),
    },
    unreadDelta: 1,
  });
}

// ─── Send message ────────────────────────────────────────────────────────────

export async function sendMessage(classroomId, senderId, body) {
  await assertMember(classroomId, senderId);

  const { type = 'text', content = '', media, replyToId, mentions = [], clientId } = body;

  // Idempotency guard
  if (clientId) {
    const existing = await ClassroomMessage.findOne({ clientId }).lean();
    if (existing) return messagePublicView(existing);
  }

  if (type === 'text' && content.trim().length === 0) throw httpErr(400, 'Tin nhắn không được rỗng');
  if (content.length > MAX_CONTENT_LENGTH)
    throw httpErr(400, `Nội dung quá dài (tối đa ${MAX_CONTENT_LENGTH} ký tự)`);

  // Validate media for non-text types
  if (['image', 'video', 'file'].includes(type) && (!media || !media.url)) {
    throw httpErr(400, 'Media URL is required for this message type');
  }

  // Build reply snapshot
  let replyTo = null;
  if (replyToId) {
    const orig = await ClassroomMessage.findById(replyToId)
      .populate('senderId', 'fullName username')
      .lean();
    if (orig && String(orig.classroomId) === String(classroomId)) {
      const senderName =
        orig.senderId?.fullName || orig.senderId?.username || 'Ẩn danh';
      replyTo = {
        messageId: orig._id,
        senderId: orig.senderId?._id ?? orig.senderId,
        senderName,
        contentPreview: orig.deletedAt
          ? '[Tin nhắn đã bị xóa]'
          : orig.type === 'text'
          ? (orig.content || '').slice(0, 120)
          : orig.media?.name || orig.type,
        messageType: orig.type,
      };
    }
  }

  const msg = await ClassroomMessage.create({
    classroomId,
    senderId,
    type,
    content: type === 'text' ? content.trim() : '',
    media: media ?? null,
    replyTo,
    mentions: Array.isArray(mentions) ? mentions : [],
    clientId: clientId ?? null,
  });

  const populated = await ClassroomMessage.findById(msg._id)
    .populate('senderId', 'fullName username avatarUrl')
    .lean();

  const view = messagePublicView(populated);
  emitToRoom(classroomId, 'classroom_message_new', view);
  await emitInboxUpdates(classroomId, view, senderId);

  return view;
}

// ─── Upload media before send ────────────────────────────────────────────────

export async function uploadChatMedia(classroomId, userId, file) {
  await assertMember(classroomId, userId);
  if (!file) throw httpErr(400, 'No file provided');

  const mimeType = file.mimetype || '';
  let resourceType = 'raw';
  let messageType = 'file';
  let folder = 'e4c_classroom_files';

  if (mimeType.startsWith('image/')) {
    resourceType = 'image';
    messageType = 'image';
    folder = 'e4c_classroom_images';
  } else if (mimeType.startsWith('video/')) {
    resourceType = 'video';
    messageType = 'video';
    folder = 'e4c_classroom_videos';
  }

  const result = await uploadMulterFileToCloudinary(file, {
    resource_type: resourceType,
    folder,
    use_filename: true,
    unique_filename: true,
    ...(resourceType === 'video'
      ? {
          eager: [{ format: 'jpg', transformation: [{ width: 440, height: 280, crop: 'fill', quality: 'auto', start_offset: '0' }] }],
        }
      : {}),
  });

  return {
    messageType,
    media: {
      url: result.secure_url,
      name: file.originalname || file.filename || '',
      size: result.bytes ?? 0,
      mimeType,
      thumbnailUrl:
        messageType === 'image'
          ? result.secure_url
          : messageType === 'video'
            ? (result.eager?.[0]?.secure_url ?? '')
            : '',
      width: result.width ?? null,
      height: result.height ?? null,
      durationSeconds: result.duration ?? null,
    },
  };
}

// ─── Get messages (cursor pagination) ───────────────────────────────────────

export async function getMessages(classroomId, userId, query) {
  await assertMember(classroomId, userId);

  const { before, limit = PAGE_SIZE } = query;
  const cap = Math.min(Number(limit) || PAGE_SIZE, 100);

  const filter = { classroomId };
  if (before) {
    const ref = await ClassroomMessage.findById(before).lean();
    if (ref) {
      filter.$or = [
        { createdAt: { $lt: ref.createdAt } },
        { createdAt: ref.createdAt, _id: { $lt: ref._id } },
      ];
    }
  }

  const messages = await ClassroomMessage.find(filter)
    .sort({ createdAt: -1, _id: -1 })
    .limit(cap + 1)
    .populate('senderId', 'fullName username avatarUrl')
    .lean();

  const hasMore = messages.length > cap;
  if (hasMore) messages.pop();

  // Return oldest-first for rendering convenience
  messages.reverse();

  return {
    messages: messages.map(messagePublicView),
    hasMore,
    nextCursor: hasMore ? String(messages[0]?._id ?? '') : null,
  };
}

// ─── React to message ────────────────────────────────────────────────────────

export async function reactMessage(classroomId, userId, messageId, emoji) {
  await assertMember(classroomId, userId);

  if (!ALLOWED_EMOJIS.includes(emoji)) throw httpErr(400, 'Emoji không hợp lệ');

  const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId });
  if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại');
  if (msg.deletedAt) throw httpErr(400, 'Không thể react tin nhắn đã bị xóa');

  const uid = new mongoose.Types.ObjectId(userId);
  let reactionGroup = msg.reactions.find((r) => r.emoji === emoji);
  let isNewReaction = false;

  if (!reactionGroup) {
    msg.reactions.push({ emoji, userIds: [uid] });
    isNewReaction = true;
  } else {
    const idx = reactionGroup.userIds.findIndex((id) => id.equals(uid));
    if (idx >= 0) {
      reactionGroup.userIds.splice(idx, 1);
      if (reactionGroup.userIds.length === 0) {
        msg.reactions = msg.reactions.filter((r) => r.emoji !== emoji);
      }
    } else {
      reactionGroup.userIds.push(uid);
      isNewReaction = true;
    }
  }

  await msg.save();

  const payload = {
    messageId: String(messageId),
    classroomId: String(classroomId),
    reactions: msg.reactions.map((r) => ({
      emoji: r.emoji,
      count: r.userIds.length,
      userIds: r.userIds.map(String),
    })),
  };
  emitToRoom(classroomId, 'classroom_message_react_update', payload);

  // Reaction MỚI (không phải bỏ react) và không tự-react → báo chủ tin nhắn qua chat inbox
  // (badge danh sách chat + card preview). KHÔNG dùng notification chuông (đó chỉ cho thông báo hệ thống).
  if (isNewReaction && String(msg.senderId) !== String(userId)) {
    await emitReactionInboxUpdate(classroomId, msg.senderId, userId, emoji);
  }

  return payload;
}

// ─── Delete message ──────────────────────────────────────────────────────────

export async function deleteMessage(classroomId, userId, messageId) {
  const { role } = await assertMember(classroomId, userId);

  const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId });
  if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại');

  if (String(msg.senderId) !== String(userId) && role !== 'teacher') {
    throw httpErr(403, 'Bạn không thể xóa tin nhắn này');
  }
  if (msg.deletedAt) return { ok: true };

  msg.deletedAt = new Date();
  await msg.save();

  const room = await Classroom.findById(classroomId).select('pinnedMessageId').lean();
  if (room?.pinnedMessageId && String(room.pinnedMessageId) === String(messageId)) {
    await Classroom.findByIdAndUpdate(classroomId, { pinnedMessageId: null });
    emitToRoom(classroomId, 'classroom_chat_pinned_updated', {
      classroomId: String(classroomId),
      pinnedMessage: null,
    });
  }

  emitToRoom(classroomId, 'classroom_message_deleted', {
    messageId: String(messageId),
    classroomId: String(classroomId),
  });

  return { ok: true };
}

// ─── Edit message text ───────────────────────────────────────────────────────

export async function editMessage(classroomId, userId, messageId, newContent) {
  await assertMember(classroomId, userId);

  if (!newContent || newContent.trim().length === 0) throw httpErr(400, 'Nội dung không được rỗng');
  if (newContent.length > MAX_CONTENT_LENGTH) throw httpErr(400, 'Nội dung quá dài');

  const msg = await ClassroomMessage.findOne({ _id: messageId, classroomId, senderId: userId });
  if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại hoặc bạn không có quyền sửa');
  if (msg.deletedAt) throw httpErr(400, 'Không thể sửa tin nhắn đã bị xóa');
  if (msg.type !== 'text') throw httpErr(400, 'Chỉ sửa được tin nhắn văn bản');

  msg.content = newContent.trim();
  msg.editedAt = new Date();
  await msg.save();

  const view = messagePublicView(msg.toJSON());
  emitToRoom(classroomId, 'classroom_message_edited', view);
  return view;
}

// ─── Get classroom members for @mention autocomplete ─────────────────────────

export async function getChatMembers(classroomId, userId) {
  await assertMember(classroomId, userId);

  const room = await Classroom.findById(classroomId).lean();
  const members = await ClassroomMember.find({
    classroomId,
    status: 'active',
  })
    .populate('userId', 'fullName username avatarUrl')
    .lean();

  const teacher = await User.findById(room.teacherId).select('fullName username avatarUrl').lean();

  const result = [];
  if (teacher) {
    result.push({
      id: String(teacher._id),
      fullName: teacher.fullName,
      username: teacher.username,
      avatarUrl: teacher.avatarUrl ?? null,
      role: 'teacher',
    });
  }
  for (const m of members) {
    if (!m.userId || String(m.userId._id) === String(room.teacherId)) continue;
    result.push({
      id: String(m.userId._id),
      fullName: m.userId.fullName,
      username: m.userId.username,
      avatarUrl: m.userId.avatarUrl ?? null,
      role: m.roleInClass,
    });
  }

  return result;
}

// ─── Chat settings (tên nhóm, ảnh, ghim) ─────────────────────────────────────

export async function getChatSettings(classroomId, userId) {
  const { room } = await assertMember(classroomId, userId);
  const pinnedMessage = await fetchPinnedMessage(classroomId);
  return {
    name: room.name,
    coverImageUrl: room.coverImageUrl ?? '',
    pinnedMessage,
  };
}

export async function updateChatSettings(classroomId, userId, patch) {
  await assertClassOwner(classroomId, userId);
  const classroom = await Classroom.findById(classroomId);
  if (!classroom) throw httpErr(404, 'Classroom not found');

  if (patch.name != null) {
    const name = String(patch.name).trim();
    if (!name) throw httpErr(400, 'Tên nhóm không được rỗng');
    classroom.name = name;
  }
  if (patch.coverImageUrl != null) {
    classroom.coverImageUrl = String(patch.coverImageUrl);
  }
  await classroom.save();

  const payload = {
    classroomId: String(classroomId),
    name: classroom.name,
    coverImageUrl: classroom.coverImageUrl ?? '',
  };
  emitToRoom(classroomId, 'classroom_chat_settings_updated', payload);
  if (patch.coverImageUrl != null) {
    await emitInboxCoverUpdate(classroomId, classroom.coverImageUrl);
  }
  return payload;
}

export async function uploadChatAvatar(classroomId, userId, file) {
  await assertClassOwner(classroomId, userId);
  if (!file) throw httpErr(400, 'No file provided');
  const mimeType = file.mimetype || '';
  if (!mimeType.startsWith('image/')) throw httpErr(400, 'Chỉ upload được ảnh');

  const result = await uploadMulterFileToCloudinary(file, {
    resource_type: 'image',
    folder: 'e4c_classroom_avatars',
    use_filename: true,
    unique_filename: true,
  });

  const classroom = await Classroom.findById(classroomId);
  classroom.coverImageUrl = result.secure_url;
  await classroom.save();

  const payload = {
    classroomId: String(classroomId),
    name: classroom.name,
    coverImageUrl: classroom.coverImageUrl,
  };
  emitToRoom(classroomId, 'classroom_chat_settings_updated', payload);
  await emitInboxCoverUpdate(classroomId, classroom.coverImageUrl);
  return payload;
}

export async function pinMessage(classroomId, userId, messageId) {
  await assertClassOwner(classroomId, userId);
  const msg = await ClassroomMessage.findOne({
    _id: messageId,
    classroomId,
    deletedAt: null,
  });
  if (!msg) throw httpErr(404, 'Tin nhắn không tồn tại');

  await Classroom.findByIdAndUpdate(classroomId, { pinnedMessageId: messageId });
  const pinnedMessage = await fetchPinnedMessage(classroomId);
  const payload = { classroomId: String(classroomId), pinnedMessage };
  emitToRoom(classroomId, 'classroom_chat_pinned_updated', payload);
  return payload;
}

export async function unpinMessage(classroomId, userId) {
  await assertClassOwner(classroomId, userId);
  await Classroom.findByIdAndUpdate(classroomId, { pinnedMessageId: null });
  const payload = { classroomId: String(classroomId), pinnedMessage: null };
  emitToRoom(classroomId, 'classroom_chat_pinned_updated', payload);
  return payload;
}

// ─── Typing indicator (socket-only, no DB) ───────────────────────────────────

export function broadcastTyping(classroomId, userId, isTyping) {
  emitToRoom(classroomId, 'classroom_typing', {
    classroomId: String(classroomId),
    userId: String(userId),
    isTyping,
  });
}

/// "Đang nhập…" cho danh sách inbox — fanout tới user-room của mọi thành viên
/// (kể cả người không mở phòng chat). Trả về sớm nếu không có thành viên.
export async function emitInboxTyping(classroomId, typerUserId, isTyping) {
  const memberIds = await getClassroomMemberUserIds(classroomId);
  if (memberIds.length === 0) return;
  let userName = 'Thành viên';
  if (isTyping) {
    const u = await User.findById(typerUserId).select('fullName username').lean();
    userName = u?.fullName || u?.username || 'Thành viên';
  }
  const payload = {
    classroomId: String(classroomId),
    userId: String(typerUserId),
    userName,
    isTyping: isTyping === true,
  };
  for (const uid of memberIds) {
    if (String(uid) === String(typerUserId)) continue;
    emitToUser(uid, 'classroom_chat_inbox_typing', payload);
  }
}

// ─── Inbox & read state ──────────────────────────────────────────────────────

async function listUserClassroomIds(userId) {
  const uid = String(userId);
  const teacherRooms = await Classroom.find({ teacherId: userId, archived: { $ne: true } })
    .select('_id')
    .lean();
  const memberRows = await ClassroomMember.find({ userId, status: 'active' })
    .select('classroomId')
    .lean();
  const ids = new Set(teacherRooms.map((r) => String(r._id)));
  for (const m of memberRows) {
    if (m.classroomId) ids.add(String(m.classroomId));
  }
  return [...ids];
}

export async function getChatInbox(userId) {
  const classroomIds = await listUserClassroomIds(userId);
  if (classroomIds.length === 0) {
    return { rooms: [], unreadConversations: 0 };
  }

  const objectIds = classroomIds.map((id) => new mongoose.Types.ObjectId(id));
  const uid = new mongoose.Types.ObjectId(userId);

  const [roomsData, lastMsgRows, unreadAgg, memberAgg, readStateRows, memberUserRows] =
    await Promise.all([
    Classroom.find({ _id: { $in: objectIds }, archived: { $ne: true } }).lean(),
    ClassroomMessage.aggregate([
      { $match: { classroomId: { $in: objectIds }, deletedAt: null } },
      { $sort: { createdAt: -1 } },
      { $group: { _id: '$classroomId', doc: { $first: '$$ROOT' } } },
    ]),
    ClassroomMessage.aggregate([
      {
        $match: {
          classroomId: { $in: objectIds },
          deletedAt: null,
          senderId: { $ne: uid },
        },
      },
      {
        $lookup: {
          from: 'classroomchatreadstates',
          let: { cid: '$classroomId' },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ['$classroomId', '$$cid'] },
                    { $eq: ['$userId', uid] },
                  ],
                },
              },
            },
            { $project: { lastReadAt: 1 } },
          ],
          as: 'readState',
        },
      },
      {
        $addFields: {
          lastReadAt: { $arrayElemAt: ['$readState.lastReadAt', 0] },
        },
      },
      {
        $match: {
          $expr: {
            $or: [
              { $eq: ['$lastReadAt', null] },
              { $gt: ['$createdAt', '$lastReadAt'] },
            ],
          },
        },
      },
      { $group: { _id: '$classroomId', unreadCount: { $sum: 1 } } },
    ]),
    ClassroomMember.aggregate([
      { $match: { classroomId: { $in: objectIds }, status: 'active' } },
      { $group: { _id: '$classroomId', n: { $sum: 1 } } },
    ]),
    ClassroomChatReadState.find({ userId: uid, classroomId: { $in: objectIds } })
      .select('classroomId muted pinnedAt')
      .lean(),
    ClassroomMember.find({ classroomId: { $in: objectIds }, status: 'active' })
      .select('classroomId userId')
      .lean(),
  ]);

  const lastMsgMap = new Map(lastMsgRows.map((r) => [String(r._id), r.doc]));
  const unreadMap = new Map(unreadAgg.map((r) => [String(r._id), r.unreadCount]));
  const memberMap = new Map(memberAgg.map((r) => [String(r._id), r.n]));
  const settingsMap = new Map(readStateRows.map((r) => [String(r.classroomId), r]));

  // Presence (load-time): thành viên nào khác đang online trong mỗi lớp.
  const roomMemberIds = new Map();
  for (const room of roomsData) {
    const s = new Set();
    if (room.teacherId) s.add(String(room.teacherId));
    roomMemberIds.set(String(room._id), s);
  }
  for (const m of memberUserRows) {
    const s = roomMemberIds.get(String(m.classroomId));
    if (s && m.userId) s.add(String(m.userId));
  }
  const candidateIds = new Set();
  for (const s of roomMemberIds.values()) {
    for (const id of s) if (id !== String(uid)) candidateIds.add(id);
  }
  const onlineRows = candidateIds.size
    ? await User.find({ _id: { $in: [...candidateIds] }, isOnline: true })
        .select('_id')
        .lean()
    : [];
  const onlineSet = new Set(onlineRows.map((u) => String(u._id)));

  const senderIds = [
    ...new Set(
      lastMsgRows
        .map((r) => r.doc?.senderId)
        .filter(Boolean)
        .map((id) => String(id)),
    ),
  ];
  const senders =
    senderIds.length > 0
      ? await User.find({ _id: { $in: senderIds } }).select('fullName username').lean()
      : [];
  const senderMap = new Map(senders.map((s) => [String(s._id), s]));

  const rooms = [];
  for (const room of roomsData) {
    const cid = String(room._id);
    const lastMsg = lastMsgMap.get(cid);
    let lastMessage = null;
    if (lastMsg) {
      const senderId = String(lastMsg.senderId);
      const sender = senderMap.get(senderId) ?? lastMsg.senderId;
      lastMessage = {
        preview: buildMessagePreview({ ...lastMsg, senderId: sender }),
        senderName: senderDisplayName(sender),
        senderId,
        type: lastMsg.type || 'text',
        createdAt: lastMsg.createdAt,
      };
    }

    const settings = settingsMap.get(cid);
    const members = roomMemberIds.get(cid);
    const online = members
      ? [...members].some((id) => id !== String(uid) && onlineSet.has(id))
      : false;
    rooms.push({
      id: cid,
      name: room.name,
      coverImageUrl: room.coverImageUrl ?? '',
      memberCount: (memberMap.get(cid) || 0) + 1,
      unreadCount: unreadMap.get(cid) || 0,
      muted: settings?.muted === true,
      pinnedAt: settings?.pinnedAt ?? null,
      online,
      lastMessage,
    });
  }

  rooms.sort((a, b) => {
    // Pinned lên đầu (theo pinnedAt mới nhất), rồi tới recency.
    if (!!a.pinnedAt !== !!b.pinnedAt) return a.pinnedAt ? -1 : 1;
    if (a.pinnedAt && b.pinnedAt) {
      const diff = new Date(b.pinnedAt).getTime() - new Date(a.pinnedAt).getTime();
      if (diff !== 0) return diff;
    }
    const ta = a.lastMessage?.createdAt ? new Date(a.lastMessage.createdAt).getTime() : 0;
    const tb = b.lastMessage?.createdAt ? new Date(b.lastMessage.createdAt).getTime() : 0;
    return tb - ta;
  });

  // Badge header không tính hội thoại đã tắt tiếng.
  const unreadConversations = rooms.filter((r) => r.unreadCount > 0 && !r.muted).length;
  return { rooms, unreadConversations };
}

export async function markChatRead(classroomId, userId) {
  await assertMember(classroomId, userId);
  const now = new Date();
  await ClassroomChatReadState.findOneAndUpdate(
    { classroomId, userId },
    { lastReadAt: now },
    { upsert: true, new: true }
  );
  emitToUser(userId, 'classroom_chat_inbox_updated', {
    classroomId: String(classroomId),
    unreadCount: 0,
    markRead: true,
  });
  // Báo phòng chat: user này đã đọc tới `now` → dùng cho ✓✓ "Đã xem".
  emitToRoom(classroomId, 'classroom_chat_read', {
    classroomId: String(classroomId),
    userId: String(userId),
    lastReadAt: now,
  });
  return { ok: true, lastReadAt: now };
}

// ─── Per-user conversation settings (mute / pin) ─────────────────────────────

export async function setChatMuted(classroomId, userId, muted) {
  await assertMember(classroomId, userId);
  await ClassroomChatReadState.findOneAndUpdate(
    { classroomId, userId },
    { muted: muted === true },
    { upsert: true, new: true }
  );
  return { ok: true, muted: muted === true };
}

export async function setChatPinned(classroomId, userId, pinned) {
  await assertMember(classroomId, userId);
  await ClassroomChatReadState.findOneAndUpdate(
    { classroomId, userId },
    { pinnedAt: pinned === true ? new Date() : null },
    { upsert: true, new: true }
  );
  return { ok: true, pinned: pinned === true };
}

export const CLASSROOM_CHAT_ROOM = roomName;
