import { generateToken, clearToken } from '../lib/jwt_token.js';
import  User from '../models/User.js';
import bcrypt from 'bcrypt';

const register = async (req, res) => {
  try {
    const { username, email, password, fullName } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: 'User already exists' });

    const salt = await bcrypt.genSalt(10);
    const hashed = await bcrypt.hash(password, salt);
    const user = await User.create({ username, email, password: hashed, fullName });

    const token = generateToken(user._id);
    return res.status(201).json({ token, user});
  } catch (e) {
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(400).json({ message: 'Invalid credentials' });

    const token = generateToken(user._id);
    return res.status(200).json({ token, user });
  } catch (e) {
    return res.status(500).json({ message: 'Server error', error: e.message });
  }
};

const logout = async (_req, res) => {
  // Không còn cookie để xoá. Tuỳ ý làm gì thêm phía server nếu muốn (revoke list...)
  return res.status(200).json({ message: 'Logged out successfully' });
};

export default { register, login, logout };