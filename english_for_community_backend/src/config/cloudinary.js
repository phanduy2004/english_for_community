// src/config/cloudinary.js
import _cloudinary from 'cloudinary'; // 1. Import default package
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import multer from 'multer';
import dotenv from 'dotenv';

dotenv.config();

// 2. Lấy v2 từ default package (Cách fix cho bản 1.x chạy trên ES Module)
const cloudinary = _cloudinary.v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'english_community_avatars',
    allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
    // transformation: [{ width: 500, height: 500, crop: 'limit' }]
  },
});

const uploadCloud = multer({ storage });

export default uploadCloud;