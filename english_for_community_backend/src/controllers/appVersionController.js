import { ZodError } from 'zod';
import { appVersionService } from '../services/appVersionService.js';

function getRequestContext(req) {
  return {
    actorId: req.user?._id?.toString(),
    actorRole: req.user?.role,
    ip: req.ip,
    userAgent: req.get('user-agent') || '',
  };
}

const checkVersion = async (req, res) => {
  try {
    const result = await appVersionService.checkVersion(req.query);
    return res.status(200).json(result);
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({ message: 'Invalid request', errors: error.issues });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const createReleaseCandidate = async (req, res) => {
  try {
    const created = await appVersionService.createReleaseCandidate(req.body, getRequestContext(req));
    return res.status(201).json(created);
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({ message: 'Invalid request', errors: error.issues });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const listReleases = async (req, res) => {
  try {
    const result = await appVersionService.listReleases(req.query);
    return res.status(200).json(result);
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({ message: 'Invalid request', errors: error.issues });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const getReleaseById = async (req, res) => {
  try {
    const result = await appVersionService.getReleaseById(req.params.id);
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const approveRelease = async (req, res) => {
  try {
    const result = await appVersionService.approveRelease(req.params.id, getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const rejectRelease = async (req, res) => {
  try {
    const result = await appVersionService.rejectRelease(req.params.id, req.body, getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({ message: 'Invalid request', errors: error.issues });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const scheduleRelease = async (req, res) => {
  try {
    const result = await appVersionService.scheduleRelease(req.params.id, req.body, getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({ message: 'Invalid request', errors: error.issues });
    }
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const publishRelease = async (req, res) => {
  try {
    const result = await appVersionService.publishRelease(req.params.id, getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const rollbackRelease = async (req, res) => {
  try {
    const result = await appVersionService.rollbackRelease(req.params.id, getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

const publishDueScheduledReleases = async (req, res) => {
  try {
    const result = await appVersionService.publishDueScheduledReleases(getRequestContext(req));
    return res.status(200).json(result);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ message: error.message || 'Server error' });
  }
};

export const appVersionController = {
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
