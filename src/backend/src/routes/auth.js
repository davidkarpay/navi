import express from 'express';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { createUser, getUser, updateDeviceToken, getPool } from '../db/init.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key';

// In-memory fallback when database is not available
const usersMemory = new Map();

router.post('/register', async (req, res) => {
    try {
        const userId = uuidv4();
        // Longer expiry now that we have persistent storage (30 days)
        const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
        const deviceToken = req.body.deviceToken || null;

        // Try database first, fall back to memory
        const pool = getPool();
        if (pool) {
            await createUser(userId, deviceToken);
            console.log(`✅ User ${userId.slice(0, 8)}... registered (PostgreSQL)`);
        } else {
            usersMemory.set(userId, {
                id: userId,
                createdAt: new Date(),
                deviceToken
            });
            console.log(`⚠️  User ${userId.slice(0, 8)}... registered (in-memory)`);
        }

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

router.get('/users/:userId', async (req, res) => {
    try {
        const pool = getPool();
        let user;

        if (pool) {
            user = await getUser(req.params.userId);
        } else {
            user = usersMemory.get(req.params.userId);
        }

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(user);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to get user' });
    }
});

router.put('/device-token', async (req, res) => {
    try {
        const { userId, deviceToken } = req.body;

        const pool = getPool();
        if (pool) {
            await updateDeviceToken(userId, deviceToken);
        } else {
            const user = usersMemory.get(userId);
            if (user) {
                user.deviceToken = deviceToken;
            }
        }

        res.json({ message: 'Device token updated' });
    } catch (error) {
        console.error('Device token update error:', error);
        res.status(500).json({ error: 'Failed to update device token' });
    }
});

// Export for other routes to access (memory fallback)
export { usersMemory };
export default router;
