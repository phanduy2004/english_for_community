/**
 * classroomChatController.js — thin layer, delegates to classroomChatService.
 */
import * as svc from '../services/classroomChatService.js';

function getStatusCode(err) {
  return err.statusCode ?? 500;
}

export const getMessages = async (req, res) => {
  try {
    const result = await svc.getMessages(
      req.params.classroomId,
      req.user._id,
      req.query
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const sendMessage = async (req, res) => {
  try {
    const msg = await svc.sendMessage(
      req.params.classroomId,
      req.user._id,
      req.body
    );
    res.status(201).json(msg);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const uploadMedia = async (req, res) => {
  try {
    const result = await svc.uploadChatMedia(
      req.params.classroomId,
      req.user._id,
      req.file
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const reactMessage = async (req, res) => {
  try {
    const result = await svc.reactMessage(
      req.params.classroomId,
      req.user._id,
      req.params.messageId,
      req.body.emoji
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const deleteMessage = async (req, res) => {
  try {
    await svc.deleteMessage(
      req.params.classroomId,
      req.user._id,
      req.params.messageId
    );
    res.json({ ok: true });
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const editMessage = async (req, res) => {
  try {
    const msg = await svc.editMessage(
      req.params.classroomId,
      req.user._id,
      req.params.messageId,
      req.body.content
    );
    res.json(msg);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const getChatMembers = async (req, res) => {
  try {
    const members = await svc.getChatMembers(
      req.params.classroomId,
      req.user._id
    );
    res.json(members);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const getChatSettings = async (req, res) => {
  try {
    const result = await svc.getChatSettings(req.params.classroomId, req.user._id);
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const updateChatSettings = async (req, res) => {
  try {
    const result = await svc.updateChatSettings(
      req.params.classroomId,
      req.user._id,
      req.body
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const uploadChatAvatar = async (req, res) => {
  try {
    const result = await svc.uploadChatAvatar(
      req.params.classroomId,
      req.user._id,
      req.file
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const pinMessage = async (req, res) => {
  try {
    const result = await svc.pinMessage(
      req.params.classroomId,
      req.user._id,
      req.params.messageId
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const unpinMessage = async (req, res) => {
  try {
    const result = await svc.unpinMessage(req.params.classroomId, req.user._id);
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const getChatInbox = async (req, res) => {
  try {
    const result = await svc.getChatInbox(req.user._id);
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const markChatRead = async (req, res) => {
  try {
    const result = await svc.markChatRead(req.params.classroomId, req.user._id);
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const setChatMuted = async (req, res) => {
  try {
    const result = await svc.setChatMuted(
      req.params.classroomId,
      req.user._id,
      req.body.muted
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};

export const setChatPinned = async (req, res) => {
  try {
    const result = await svc.setChatPinned(
      req.params.classroomId,
      req.user._id,
      req.body.pinned
    );
    res.json(result);
  } catch (e) {
    res.status(getStatusCode(e)).json({ message: e.message });
  }
};
