import express from 'express';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getDb } from '../db/init.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key';

router.post('/register', async (req, res) => {
    try {
        const db = getDb();
        const userId = uuidv4();
        const token = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '24h' });
        const deviceToken = req.body.deviceToken || null;

        // Store user in database
        await db.run(
            'INSERT INTO users (id, device_token) VALUES (?, ?)',
            [userId, deviceToken]
        );

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
        const db = getDb();
        const user = await db.get(
            'SELECT * FROM users WHERE id = ?',
            [req.params.userId]
        );

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json(user);
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to retrieve user' });
    }
});

export default router;