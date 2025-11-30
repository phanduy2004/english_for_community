import { Server } from 'socket.io';
import User from '../models/User.js';

let io;

export const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: { origin: "*", methods: ["GET", "POST"] }
  });

  // Hàm phụ: Cập nhật trạng thái User (Tránh viết lặp lại)
  const updateUserStatus = async (userId, isOnline) => {
    try {
      await User.findByIdAndUpdate(userId, {
        isOnline: isOnline,
        lastActivityDate: new Date()
      });
      // Báo Admin
      io.to('admin_room').emit('user_status_change', { userId, isOnline });
    } catch (error) {
      console.error(`Error updating status for ${userId}:`, error);
    }
  };

  io.on('connection', (socket) => {
    console.log(`⚡ Client connected: ${socket.id}`);

    // 1. User Login
    socket.on('user_login', async (userId) => {
      console.log(`👤 User Login: ${userId} (Socket: ${socket.id})`);
      socket.userId = userId; // Gắn thẻ
      socket.join(userId);
      await updateUserStatus(userId, true); // Set Online
    });

    // 2. User Logout (Chủ động báo thoát) -> QUAN TRỌNG
    socket.on('user_logout', async () => {
      console.log(`👋 User Logout Explicitly: ${socket.userId}`);
      if (socket.userId) {
        await updateUserStatus(socket.userId, false); // Set Offline ngay
        socket.userId = null; // Xóa thẻ để tránh sự kiện disconnect xử lý lại (nếu muốn)
      }
    });

    // 3. Admin Join
    socket.on('admin_join', () => {
      console.log(`🛡️ Admin joined: ${socket.id}`);
      socket.join('admin_room');
    });

    // 4. Disconnect (Mất mạng / Kill App)
    socket.on('disconnect', async (reason) => {
      console.log(`❌ Disconnected: ${socket.id} | Reason: ${reason}`);

      // Nếu socket này có userId (và chưa logout chủ động)
      if (socket.userId) {
        console.log(`📉 Setting Offline (Connection lost): ${socket.userId}`);
        await updateUserStatus(socket.userId, false);
      }
    });
  });
};

export const getIO = () => {
  if (!io) throw new Error("Socket.io not initialized!");
  return io;
};