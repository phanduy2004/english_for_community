import User from '../models/User.js';

// Get user profile
export const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update user profile
export const updateProfile = async (req, res) => {
    try {
        const updates = {
            fullName: req.body.fullName,
            username: req.body.username,
            bio: req.body.bio,
            dateOfBirth: req.body.dateOfBirth,
            avatarUrl: req.body.avatarUrl,
            goal: req.body.goal,
            cefr: req.body.cefr,
            dailyMinutes: req.body.dailyMinutes,
            reminder: req.body.reminder,
            strictCorrection: req.body.strictCorrection,
            language: req.body.language,
            timezone: req.body.timezone
        };

        const updatedUser = await User.findByIdAndUpdate(
            req.user._id,
            updates,
            { new: true, runValidators: true }
        );

        res.status(200).json(updatedUser);
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Delete user account
export const deleteAccount = async (req, res) => {
    try {
        await User.findByIdAndDelete(req.user._id);
        res.status(200).json({ message: 'Account deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};