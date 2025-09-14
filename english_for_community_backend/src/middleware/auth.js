import { verifyToken, extractToken } from '../lib/jwt_token.js';
import User from '../models/User.js';

export const authenticate = async (req, res, next) => {
    const token = extractToken(req);
    
    if (!token) {
        return res.status(401).json({ message: 'Authentication required' });
    }
    
    const { valid, expired, userId } = verifyToken(token);
    
    if (expired) {
        return res.status(401).json({ message: 'Token expired' });
    }
    
    if (!valid) {
        return res.status(401).json({ message: 'Invalid token' });
    }
    
    try {
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(401).json({ message: 'User not found' });
        }
        
        // Add user to request object
        req.user = user;
        next();
    } catch (error) {
        return res.status(500).json({ message: 'Server error' });
    }
};
