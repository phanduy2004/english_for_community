import _cloudinary from 'cloudinary';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';
import dotenv from 'dotenv';

dotenv.config();

const cloudinary = _cloudinary.v2; // 🔥 Biến này cần được export

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

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

const uploadCloud = multer({ storage });

// 🔥 THÊM DÒNG NÀY ĐỂ EXPORT BIẾN CLOUDINARY
export { cloudinary };

export default uploadCloud;