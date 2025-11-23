import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import { getDb } from '../db/init.js';

const router = express.Router();

// Generate 6-digit pairing code
function generatePairingCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Create pairing code
router.post('/create', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;

        // Remove any existing pairing codes for this user
        await db.run('DELETE FROM pairing_codes WHERE creator_user_id = ?', [userId]);

        const pairingCode = generatePairingCode();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

        await db.run(
            'INSERT INTO pairing_codes (code, creator_user_id, expires_at) VALUES (?, ?, ?)',
            [pairingCode, userId, expiresAt.toISOString()]
        );

        res.json({
            pairingCode,
            expiresIn: 600 // 10 minutes in seconds
        });
    } catch (error) {
        console.error('Create pairing error:', error);
        res.status(500).json({ error: 'Failed to create pairing code' });
    }
});

// Join with pairing code
router.post('/join', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;
        const { pairingCode } = req.body;

        if (!pairingCode || pairingCode.length !== 6) {
            return res.status(400).json({ error: 'Invalid pairing code format' });
        }

        // Look up the pairing code
        const codeRecord = await db.get(
            'SELECT creator_user_id, expires_at FROM pairing_codes WHERE code = ?',
            [pairingCode]
        );

        if (!codeRecord) {
            return res.status(404).json({ error: 'Pairing code not found or expired' });
        }

        // Check if code has expired
        if (new Date(codeRecord.expires_at) < new Date()) {
            await db.run('DELETE FROM pairing_codes WHERE code = ?', [pairingCode]);
            return res.status(404).json({ error: 'Pairing code not found or expired' });
        }

        const creatorUserId = codeRecord.creator_user_id;

        if (creatorUserId === userId) {
            return res.status(400).json({ error: 'Cannot pair with yourself' });
        }

        // Create pairing for both users (delete existing first)
        await db.run('DELETE FROM pairings WHERE user_id IN (?, ?)', [userId, creatorUserId]);

        await db.run(
            'INSERT INTO pairings (user_id, partner_id) VALUES (?, ?), (?, ?)',
            [userId, creatorUserId, creatorUserId, userId]
        );

        // Remove the used pairing code
        await db.run('DELETE FROM pairing_codes WHERE code = ?', [pairingCode]);

        res.json({
            message: 'Successfully paired',
            partnerId: creatorUserId,
            pairedAt: new Date()
        });
    } catch (error) {
        console.error('Join pairing error:', error);
        res.status(500).json({ error: 'Failed to join pairing' });
    }
});

// Get pairing status
router.get('/status', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;

        const pairing = await db.get(
            'SELECT partner_id, created_at FROM pairings WHERE user_id = ?',
            [userId]
        );

        if (!pairing) {
            return res.json({
                paired: false,
                partnerId: null,
                pairedAt: null
            });
        }

        res.json({
            paired: true,
            partnerId: pairing.partner_id,
            pairedAt: pairing.created_at
        });
    } catch (error) {
        console.error('Status check error:', error);
        res.status(500).json({ error: 'Failed to check pairing status' });
    }
});

// Unpair
router.delete('/unpair', authenticateToken, async (req, res) => {
    try {
        const db = getDb();
        const { userId } = req.user;

        const pairing = await db.get(
            'SELECT partner_id FROM pairings WHERE user_id = ?',
            [userId]
        );

        if (pairing) {
            // Remove pairing for both users
            await db.run(
                'DELETE FROM pairings WHERE user_id IN (?, ?)',
                [userId, pairing.partner_id]
            );
        }

        res.json({ message: 'Successfully unpaired' });
    } catch (error) {
        console.error('Unpair error:', error);
        res.status(500).json({ error: 'Failed to unpair' });
    }
});

export default router;