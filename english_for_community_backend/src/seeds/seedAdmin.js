import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';
import User from '../models/User.js';

dotenv.config();

// Danh sách user test với điểm số (XP), ngày sinh và giới tính đa dạng
const normalUsers = [
  {
    fullName: 'Nguyen Van A',
    username: 'nguyenvana',
    email: 'user1@gmail.com',
    goal: 'IELTS 7.0',
    totalPoints: 1250,
    gender: 'male',
    dateOfBirth: new Date('1998-05-15')
  },
  {
    fullName: 'Tran Thi B',
    username: 'tranthib',
    email: 'user2@gmail.com',
    goal: 'Communication',
    totalPoints: 3400,
    gender: 'female',
    dateOfBirth: new Date('2000-10-20')
  },
  {
    fullName: 'Le Van C',
    username: 'levanc',
    email: 'user3@gmail.com',
    goal: 'TOEIC 800',
    totalPoints: 850,
    gender: 'male',
    dateOfBirth: new Date('1995-03-12')
  },
  {
    fullName: 'Pham Thi D',
    username: 'phamthid',
    email: 'user4@gmail.com',
    goal: 'IELTS 8.0',
    totalPoints: 5100,
    gender: 'female',
    dateOfBirth: new Date('2002-01-30')
  },
  {
    fullName: 'Hoang Van E',
    username: 'hoangvane',
    email: 'user5@gmail.com',
    goal: 'Basic English',
    totalPoints: 150,
    gender: 'male',
    dateOfBirth: new Date('2005-07-07')
  },
  {
    fullName: 'Vu Thi F',
    username: 'vuthif',
    email: 'user6@gmail.com',
    goal: 'Communication',
    totalPoints: 2800,
    gender: 'female',
    dateOfBirth: new Date('1999-12-25')
  },
  {
    fullName: 'Dang Van G',
    username: 'dangvang',
    email: 'user7@gmail.com',
    goal: 'TOEIC 600',
    totalPoints: 2100,
    gender: 'male',
    dateOfBirth: new Date('1990-09-09')
  },
  {
    fullName: 'Bui Thi H',
    username: 'buithih',
    email: 'user8@gmail.com',
    goal: 'IELTS 6.5',
    totalPoints: 4200,
    gender: 'female',
    dateOfBirth: new Date('2001-04-18')
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
        totalPoints: 99999,
        gender: 'male', // Mặc định cho admin
        dateOfBirth: new Date('1990-01-01')
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
          totalPoints: user.totalPoints,
          gender: user.gender,           // 🔥 Thêm gender
          dateOfBirth: user.dateOfBirth  // 🔥 Thêm DOB
        });
        console.log(`✅ Created user: ${user.username} (${user.gender}, Born: ${user.dateOfBirth.getFullYear()})`);
      } else {
        // CẬP NHẬT XP, DOB và GENDER (Nếu user đã có thì update luôn để test tính năng mới)
        userExists.totalPoints = user.totalPoints;
        userExists.gender = user.gender;          // 🔥 Update gender
        userExists.dateOfBirth = user.dateOfBirth; // 🔥 Update DOB

        await userExists.save();
        console.log(`🔄 Updated info for existing user: ${user.username}`);
      }
    }

    console.log('🎉 Seeding process completed!');
    process.exit();
  })
  .catch(e => {
    console.error('❌ Error seeding data:', e);
    process.exit(1);
  });