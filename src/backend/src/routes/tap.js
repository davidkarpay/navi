import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { activePairings } from './pairing.js';
import { getPairing, getPool } from '../db/init.js';
import { sendTapToUser } from '../services/websocket.js';

const router = express.Router();

// Send a tap to paired partner
router.post('/send', authenticateToken, async (req, res) => {
    try {
        const { userId } = req.user;
        const { intensity = 'medium', pattern = 'single' } = req.body;
        
        // Check if user is paired (database first, then memory fallback)
        const pool = getPool();
        let pairing;

        if (pool) {
            const dbPairing = await getPairing(userId);
            if (dbPairing) {
                pairing = { partnerId: dbPairing.partner_id };
            }
        } else {
            pairing = activePairings.get(userId);
        }

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
        
        const tapMessage = {
            fromUserId: userId,
            toUserId: pairing.partnerId,
            intensity,
            pattern,
            timestamp: new Date().toISOString(),
            id: Date.now().toString()
        };
        
        // Send via WebSocket
        const delivered = await sendTapToUser(pairing.partnerId, tapMessage);
        
        res.json({
            message: 'Tap sent successfully',
            delivered,
            tapId: tapMessage.id,
            sentAt: tapMessage.timestamp
        });
        
    } catch (error) {
        console.error('Send tap error:', error);
        res.status(500).json({ error: 'Failed to send tap' });
    }
});

// Get recent tap history (last 10 taps)
const tapHistory = new Map(); // userId -> [taps]

router.get('/history', authenticateToken, (req, res) => {
    try {
        const { userId } = req.user;
        const userTaps = tapHistory.get(userId) || [];
        
        res.json({
            taps: userTaps.slice(-10), // Last 10 taps
            count: userTaps.length
        });
    } catch (error) {
        console.error('Get history error:', error);
        res.status(500).json({ error: 'Failed to get tap history' });
    }
});

// Store tap in history when received
export function storeTapInHistory(userId, tapMessage) {
    if (!tapHistory.has(userId)) {
        tapHistory.set(userId, []);
    }
    const userTaps = tapHistory.get(userId);
    userTaps.push(tapMessage);
    
    // Keep only last 50 taps per user
    if (userTaps.length > 50) {
        userTaps.splice(0, userTaps.length - 50);
    }
}

export default router;