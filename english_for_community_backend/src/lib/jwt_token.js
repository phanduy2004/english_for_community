import jsonwebtoken from 'jsonwebtoken'
import dotenv from 'dotenv'

dotenv.config()


export const generateToken = (userId, res) => {
    const token = jsonwebtoken.sign({ userId }, process.env.JWT_SECRET, {
        expiresIn: '1h'
    });
    res.cookie('token', token, {
        httpOnly: true,
        secure: process.env.NODE_ENV !== 'development',
        sameSite: 'strict',
        maxAge: 3600000 // 1 hour
    });
    return token;
}

// Verify JWT token
export const verifyToken = (token) => {
    try {
        const decoded = jsonwebtoken.verify(token, process.env.JWT_SECRET);
        return { valid: true, expired: false, userId: decoded.userId };
    } catch (error) {
        return { 
            valid: false, 
            expired: error.name === 'TokenExpiredError', 
            userId: null 
        };
    }
}

// Extract token from request (checks both cookies and Authorization header)
export const extractToken = (req) => {
    // First check for token in cookies
    if (req.cookies && req.cookies.token) {
        return req.cookies.token;
    }
    
    // Then check for token in Authorization header
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
        return authHeader.split(' ')[1];
    }
    
    return null;
}

// Clear token on logout
export const clearToken = (res) => {
    res.cookie('token', '', {
        httpOnly: true,
        secure: process.env.NODE_ENV !== 'development',
        sameSite: 'strict',
        expires: new Date(0)
    });
}