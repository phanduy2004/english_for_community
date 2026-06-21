import _cloudinary from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';
import dotenv from 'dotenv';
import { Readable } from 'node:stream';

dotenv.config();

const cloudinary = _cloudinary.v2; // 🔥 Biến này cần được export

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

/**
 * Upload file từ multer — hỗ trợ disk path hoặc memory buffer (web multipart).
 * cloudinary.uploader.upload() chỉ nhận string path/URL, không nhận Buffer trực tiếp.
 */
export function uploadMulterFileToCloudinary(file, options = {}) {
  if (file?.path && typeof file.path === 'string') {
    return cloudinary.uploader.upload(file.path, options);
  }
  if (file?.buffer && Buffer.isBuffer(file.buffer)) {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(options, (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
      Readable.from(file.buffer).pipe(stream);
    });
  }
  return Promise.reject(new Error('No file data to upload'));
}

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    let folderName = 'english_community_avatars';
    let resourceType = 'image';
    let format = undefined;

    if (file.mimetype.startsWith('audio')) {
      folderName = 'english_community_audio';
      resourceType = 'video';
      format = 'mp3';
    }

    return {
      folder: folderName,
      resource_type: resourceType,
      allowed_formats: ['jpg', 'png', 'jpeg', 'webp', 'mp3', 'wav', 'm4a'],
    };
  },
});

const ALLOWED_MIME = new Set([
  'image/jpeg', 'image/png', 'image/jpg', 'image/webp',
  'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/m4a', 'audio/mp4',
]);

const uploadCloud = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (ALLOWED_MIME.has(file.mimetype)) return cb(null, true);
    cb(new Error('Unsupported file type'));
  },
});

// 🔥 THÊM DÒNG NÀY ĐỂ EXPORT BIẾN CLOUDINARY
export { cloudinary };

export default uploadCloud;