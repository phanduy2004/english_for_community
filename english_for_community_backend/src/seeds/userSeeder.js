import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import User from '../models/User.js';
import dotenv from 'dotenv';

dotenv.config();

const seedUsers = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect('mongodb://localhost:27017/english_community');
        
        // Clear existing users
        await User.deleteMany({});
        
        // Create test user
        const passwordHash = await bcrypt.hash('Test@123', 10);
        
        const testUser = new User({
            email: 'test@example.com',
            password: passwordHash,
            fullName: 'Test User',
            role: 'user',
            isActive: true,
            emailVerified: true,
            lastLogin: new Date()
        });
        
        await testUser.save();
        
        console.log('✅ Test user created successfully');
        console.log('Email: test@example.com');
        console.log('Password: Test@123');
        
        await mongoose.connection.close();
    } catch (error) {
        console.error('❌ Error seeding users:', error);
        process.exit(1);
    }
};

seedUsers();