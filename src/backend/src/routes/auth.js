import express from 'express';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key';

// In-memory user storage (for simplicity tonight)
const users = new Map();

router.post('/register', async (req, res) => {
    try {
        const userId = uuidv4();
        const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '24h' });
        
        // Store user in memory
        users.set(userId, {
            id: userId,
            createdAt: new Date(),
            deviceToken: req.body.deviceToken || null
        });
        
        res.json({
            userId,
            token,
            message: 'User registered successfully'
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

router.get('/users/:userId', (req, res) => {
    const user = users.get(req.params.userId);
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
});

// Export users for other routes to access
export { users };
export default router;