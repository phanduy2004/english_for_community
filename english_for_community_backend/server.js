import 'dotenv/config';
import mongoose from 'mongoose';
import app from './app.js';

const MONGO_URI = process.env.MONGO_URI ?? process.env.MONGODB_URI;
if (!MONGO_URI) {
  console.error('❌ Missing MONGO_URI / MONGODB_URI in .env');
  process.exit(1);
}

await mongoose.connect(MONGO_URI); // Mongoose v8 không cần options cũ
console.log('✅ Connected to MongoDB');

const PORT = Number(process.env.PORT ?? 3000);
app.listen(PORT, () => console.log(`🚀 Server: http://localhost:${PORT}`));
