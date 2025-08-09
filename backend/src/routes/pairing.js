import express from 'express';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// In-memory pairing storage
const activePairings = new Map(); // userId -> pairingInfo
const pairingCodes = new Map(); // code -> creatorUserId

// Generate 6-digit pairing code
function generatePairingCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Create pairing code
router.post('/create', authenticateToken, (req, res) => {
    try {
        const { userId } = req.user;
        
        // Remove any existing pairing for this user
        for (const [code, creatorId] of pairingCodes.entries()) {
            if (creatorId === userId) {
                pairingCodes.delete(code);
            }
        }
        
        const pairingCode = generatePairingCode();
        pairingCodes.set(pairingCode, userId);
        
        // Clean up code after 10 minutes
        setTimeout(() => {
            pairingCodes.delete(pairingCode);
        }, 10 * 60 * 1000);
        
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
router.post('/join', authenticateToken, (req, res) => {
    try {
        const { userId } = req.user;
        const { pairingCode } = req.body;
        
        if (!pairingCode || pairingCode.length !== 6) {
            return res.status(400).json({ error: 'Invalid pairing code format' });
        }
        
        const creatorUserId = pairingCodes.get(pairingCode);
        if (!creatorUserId) {
            return res.status(404).json({ error: 'Pairing code not found or expired' });
        }
        
        if (creatorUserId === userId) {
            return res.status(400).json({ error: 'Cannot pair with yourself' });
        }
        
        // Create pairing for both users
        const pairingInfo = {
            partnerId: creatorUserId,
            pairedAt: new Date(),
            pairingCode
        };
        
        const creatorPairingInfo = {
            partnerId: userId,
            pairedAt: new Date(),
            pairingCode
        };
        
        activePairings.set(userId, pairingInfo);
        activePairings.set(creatorUserId, creatorPairingInfo);
        
        // Remove the used pairing code
        pairingCodes.delete(pairingCode);
        
        res.json({
            message: 'Successfully paired',
            partnerId: creatorUserId,
            pairedAt: pairingInfo.pairedAt
        });
    } catch (error) {
        console.error('Join pairing error:', error);
        res.status(500).json({ error: 'Failed to join pairing' });
    }
});

// Get pairing status
router.get('/status', authenticateToken, (req, res) => {
    try {
        const { userId } = req.user;
        const pairing = activePairings.get(userId);
        
        if (!pairing) {
            return res.json({
                paired: false,
                partnerId: null,
                pairedAt: null
            });
        }
        
        res.json({
            paired: true,
            partnerId: pairing.partnerId,
            pairedAt: pairing.pairedAt
        });
    } catch (error) {
        console.error('Status check error:', error);
        res.status(500).json({ error: 'Failed to check pairing status' });
    }
});

// Unpair
router.delete('/unpair', authenticateToken, (req, res) => {
    try {
        const { userId } = req.user;
        const pairing = activePairings.get(userId);
        
        if (pairing) {
            // Remove pairing for both users
            activePairings.delete(userId);
            activePairings.delete(pairing.partnerId);
        }
        
        res.json({ message: 'Successfully unpaired' });
    } catch (error) {
        console.error('Unpair error:', error);
        res.status(500).json({ error: 'Failed to unpair' });
    }
});

// Export for other modules
export { activePairings };
export default router;