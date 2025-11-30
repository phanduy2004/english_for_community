import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';
import User from '../models/User.js';

dotenv.config();

// Danh sách user test với điểm số (XP) đa dạng để test Leaderboard
const normalUsers = [
  {
    fullName: 'Nguyen Van A',
    username: 'nguyenvana',
    email: 'user1@gmail.com',
    goal: 'IELTS 7.0',
    totalPoints: 1250 // Rank trung bình
  },
  {
    fullName: 'Tran Thi B',
    username: 'tranthib',
    email: 'user2@gmail.com',
    goal: 'Communication',
    totalPoints: 3400 // Rank cao
  },
  {
    fullName: 'Le Van C',
    username: 'levanc',
    email: 'user3@gmail.com',
    goal: 'TOEIC 800',
    totalPoints: 850 // Rank thấp
  },
  {
    fullName: 'Pham Thi D',
    username: 'phamthid',
    email: 'user4@gmail.com',
    goal: 'IELTS 8.0',
    totalPoints: 5100 // Top 1 dự kiến
  },
  {
    fullName: 'Hoang Van E',
    username: 'hoangvane',
    email: 'user5@gmail.com',
    goal: 'Basic English',
    totalPoints: 150 // Newbie
  },
  {
    fullName: 'Vu Thi F',
    username: 'vuthif',
    email: 'user6@gmail.com',
    goal: 'Communication',
    totalPoints: 2800 // Rank khá
  },
  {
    fullName: 'Dang Van G',
    username: 'dangvang',
    email: 'user7@gmail.com',
    goal: 'TOEIC 600',
    totalPoints: 2100 // Rank trung bình
  },
  {
    fullName: 'Bui Thi H',
    username: 'buithih',
    email: 'user8@gmail.com',
    goal: 'IELTS 6.5',
    totalPoints: 4200 // Top 2 dự kiến
  }
];

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    console.log('🔌 Connected to DB');

    // --- PHẦN 1: TẠO ADMIN ---
    const adminEmail = 'admin@englishapp.com';
    const adminPassword = 'adminpassword123';

    const adminExists = await User.findOne({ email: adminEmail });
    if (!adminExists) {
      const salt = await bcrypt.genSalt(10);
      const hashedAdminPassword = await bcrypt.hash(adminPassword, salt);

      await User.create({
        fullName: 'Super Admin',
        username: 'admin',
        email: adminEmail,
        password: hashedAdminPassword,
        role: 'admin',
        goal: 'Manage System',
        totalPoints: 99999 // Admin điểm cao nhất (tùy chọn)
      });
      console.log('✅ Admin account created successfully');
    } else {
      console.log('⚠️  Admin account already exists');
    }

    // --- PHẦN 2: TẠO USER THƯỜNG ---
    console.log('🌱 Starting to seed normal users...');
    const commonPassword = '123456'; // Mật khẩu chung

    for (const user of normalUsers) {
      const userExists = await User.findOne({ email: user.email });

      if (!userExists) {
        // TẠO MỚI
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(commonPassword, salt);

        await User.create({
          fullName: user.fullName,
          username: user.username,
          email: user.email,
          password: hashedPassword,
          role: 'user',
          goal: user.goal,
          totalPoints: user.totalPoints // 🔥 Thêm XP
        });
        console.log(`✅ Created user: ${user.username} (${user.totalPoints} XP)`);
      } else {
        // CẬP NHẬT XP (Nếu user đã có thì update điểm mới luôn để test)
        userExists.totalPoints = user.totalPoints;
        await userExists.save();
        console.log(`🔄 Updated XP for existing user: ${user.username} -> ${user.totalPoints} XP`);
      }
    }

    console.log('🎉 Seeding process completed!');
    process.exit();
  })
  .catch(e => {
    console.error('❌ Error seeding data:', e);
    process.exit(1);
  });