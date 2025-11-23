import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { sendTapToUser } from '../services/websocket.js';
import { getDb } from '../db/init.js';

const router = express.Router();

// Send a tap to paired partner
router.post('/send', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;
        const { intensity = 'medium', pattern = 'single' } = req.body;

        // Check if user is paired
        const pairing = await db.get(
            'SELECT partner_id FROM pairings WHERE user_id = ?',
            [userId]
        );

        if (!pairing) {
            return res.status(400).json({ error: 'Not paired with anyone' });
        }

        // Validate tap parameters
        const validIntensities = ['light', 'medium', 'strong'];
        const validPatterns = ['single', 'double', 'triple', 'heartbeat'];

        if (!validIntensities.includes(intensity)) {
            return res.status(400).json({ error: 'Invalid intensity. Use: light, medium, strong' });
        }

        if (!validPatterns.includes(pattern)) {
            return res.status(400).json({ error: 'Invalid pattern. Use: single, double, triple, heartbeat' });
        }

        const tapId = Date.now().toString();
        const timestamp = new Date().toISOString();

        const tapMessage = {
            fromUserId: userId,
            toUserId: pairing.partner_id,
            intensity,
            pattern,
            timestamp,
            id: tapId
        };

        // Store tap in database
        await db.run(
            'INSERT INTO taps (id, from_user_id, to_user_id, intensity, pattern) VALUES (?, ?, ?, ?, ?)',
            [tapId, userId, pairing.partner_id, intensity, pattern]
        );

        // Send via WebSocket
        const delivered = await sendTapToUser(pairing.partner_id, tapMessage);

        res.json({
            message: 'Tap sent successfully',
            delivered,
            tapId,
            sentAt: timestamp
        });

    } catch (error) {
        console.error('Send tap error:', error);
        res.status(500).json({ error: 'Failed to send tap' });
    }
});

// Get recent tap history (last 10 taps)
router.get('/history', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;

        // Get taps sent to or from this user
        const taps = await db.all(
            `SELECT id, from_user_id as fromUserId, to_user_id as toUserId,
                    intensity, pattern, created_at as timestamp
             FROM taps
             WHERE from_user_id = ? OR to_user_id = ?
             ORDER BY created_at DESC
             LIMIT 10`,
            [userId, userId]
        );

        const totalCount = await db.get(
            'SELECT COUNT(*) as count FROM taps WHERE from_user_id = ? OR to_user_id = ?',
            [userId, userId]
        );

        res.json({
            taps,
            count: totalCount.count
        });
    } catch (error) {
        console.error('Get history error:', error);
        res.status(500).json({ error: 'Failed to get tap history' });
    }
});

// Store tap in history when received (now handled by /send endpoint)
export function storeTapInHistory(userId, tapMessage) {
    // This function is no longer needed as taps are stored in the database
    // Kept for backwards compatibility but does nothing
}

export default router;