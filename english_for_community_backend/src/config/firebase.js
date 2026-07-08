import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Lấy chuỗi Base64 từ biến môi trường
const serviceAccountBase64 = process.env.FIREBASE_CONFIG_BASE64;

let serviceAccount;

try {
  if (!serviceAccountBase64) {
    console.warn('⚠️ MISSING FIREBASE_CONFIG_BASE64 in environment variables. FCM will not work.');
  } else {
    // Giải mã Base64 -> JSON String -> Object
    const jsonString = Buffer.from(serviceAccountBase64, 'base64').toString('utf-8');
    serviceAccount = JSON.parse(jsonString);

    // Khởi tạo Firebase Admin nếu chưa có instance nào
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      console.log('🔥 Firebase Admin Initialized successfully from Base64');
    }
  }
} catch (error) {
  console.error('❌ Firebase Admin Init Error:', error.message);
}

// Export messaging service để dùng ở chỗ khác
export const messaging = admin.apps.length ? admin.messaging() : null;

/**
 * ID kênh thông báo mặc định — PHẢI khớp:
 *  - meta-data `default_notification_channel_id` trong AndroidManifest
 *  - channel tạo ở Flutter (LocalNotificationService.init)
 */
export const FCM_CHANNEL_ID = 'e4c_reminders';

/**
 * Tuỳ chọn giao nhận high-priority + channel (Android) + APNs (iOS) để push
 * đánh thức máy và hiển thị cả khi app đã bị kill (chống battery-optimization).
 * Spread vào message object bên cạnh notification/data/tokens.
 */
export const fcmDeliveryOptions = {
  android: {
    priority: 'high',
    notification: {
      channelId: FCM_CHANNEL_ID,
      sound: 'default',
      defaultSound: true,
      priority: 'high',
    },
  },
  apns: {
    headers: { 'apns-priority': '10' },
    payload: { aps: { sound: 'default' } },
  },
};

export default admin;