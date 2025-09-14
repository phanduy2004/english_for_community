import { generateToken, clearToken } from '../lib/jwt_token.js';
import  User from '../models/User.js';
import bcrypt from 'bcrypt';

const register = async (req, res) => {
    try {
        const { username, email, password, fullName } = req.body;
        
        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: 'User already exists' });
        }
        
        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // Create new user
        const user = await User.create({
            username,
            email,
            password: hashedPassword,
            fullName
        });
        
        // Generate token
        const token = generateToken(user._id, res);
        
        res.status(201).json({
            user
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Invalid credentials' });
        }
        
        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials' });
        }
        
        // Generate token
        const token = generateToken(user._id, res);
        
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const logout = (req, res) => {
    clearToken(res);
    res.status(200).json({ message: 'Logged out successfully' });
};
export default { register, login, logout };