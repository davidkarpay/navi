import express from 'express';
import { authenticateToken } from '../middleware/auth.js';
import {
    createPairingCode as dbCreatePairingCode,
    getPairingCode as dbGetPairingCode,
    deletePairingCode as dbDeletePairingCode,
    createPairing as dbCreatePairing,
    getPairing as dbGetPairing,
    deletePairing as dbDeletePairing,
    getPool
} from '../db/init.js';

const router = express.Router();

// In-memory fallback storage
const activePairingsMemory = new Map(); // userId -> pairingInfo
const pairingCodesMemory = new Map(); // code -> creatorUserId

// Generate 6-digit pairing code
function generatePairingCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Create pairing code
router.post('/create', authenticateToken, async (req, res) => {
    try {
        const { userId } = req.user;
        const pairingCode = generatePairingCode();
        const pool = getPool();

        if (pool) {
            // Use PostgreSQL
            await dbCreatePairingCode(pairingCode, userId);
            console.log(`✅ Pairing code ${pairingCode} created (PostgreSQL)`);
        } else {
            // Fallback to memory
            // Remove any existing pairing for this user
            for (const [code, creatorId] of pairingCodesMemory.entries()) {
                if (creatorId === userId) {
                    pairingCodesMemory.delete(code);
                }
            }

            pairingCodesMemory.set(pairingCode, userId);

            // Clean up code after 10 minutes
            setTimeout(() => {
                pairingCodesMemory.delete(pairingCode);
            }, 10 * 60 * 1000);

            console.log(`⚠️  Pairing code ${pairingCode} created (in-memory)`);
        }

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
        const { userId } = req.user;
        const { pairingCode } = req.body;

        if (!pairingCode || pairingCode.length !== 6) {
            return res.status(400).json({ error: 'Invalid pairing code format' });
        }

        const pool = getPool();
        let creatorUserId;

        if (pool) {
            // Use PostgreSQL
            const codeRecord = await dbGetPairingCode(pairingCode);
            if (!codeRecord) {
                return res.status(404).json({ error: 'Pairing code not found or expired' });
            }
            creatorUserId = codeRecord.creator_user_id;
        } else {
            // Fallback to memory
            creatorUserId = pairingCodesMemory.get(pairingCode);
            if (!creatorUserId) {
                return res.status(404).json({ error: 'Pairing code not found or expired' });
            }
        }

        if (creatorUserId === userId) {
            return res.status(400).json({ error: 'Cannot pair with yourself' });
        }

        const pairedAt = new Date();

        if (pool) {
            // Create pairing in database
            await dbCreatePairing(userId, creatorUserId);
            await dbDeletePairingCode(pairingCode);
            console.log(`✅ Users ${userId.slice(0, 8)}... and ${creatorUserId.slice(0, 8)}... paired (PostgreSQL)`);
        } else {
            // Create pairing in memory
            const pairingInfo = {
                partnerId: creatorUserId,
                pairedAt,
                pairingCode
            };

            const creatorPairingInfo = {
                partnerId: userId,
                pairedAt,
                pairingCode
            };

            activePairingsMemory.set(userId, pairingInfo);
            activePairingsMemory.set(creatorUserId, creatorPairingInfo);
            pairingCodesMemory.delete(pairingCode);

            console.log(`⚠️  Users paired (in-memory)`);
        }

        res.json({
            message: 'Successfully paired',
            partnerId: creatorUserId,
            pairedAt
        });
    } catch (error) {
        console.error('Join pairing error:', error);
        res.status(500).json({ error: 'Failed to join pairing' });
    }
});

// Get pairing status
router.get('/status', authenticateToken, async (req, res) => {
    try {
        const { userId } = req.user;
        const pool = getPool();
        let pairing;

        if (pool) {
            pairing = await dbGetPairing(userId);
            if (pairing) {
                return res.json({
                    paired: true,
                    partnerId: pairing.partner_id,
                    pairedAt: pairing.paired_at
                });
            }
        } else {
            pairing = activePairingsMemory.get(userId);
            if (pairing) {
                return res.json({
                    paired: true,
                    partnerId: pairing.partnerId,
                    pairedAt: pairing.pairedAt
                });
            }
        }

        res.json({
            paired: false,
            partnerId: null,
            pairedAt: null
        });
    } catch (error) {
        console.error('Status check error:', error);
        res.status(500).json({ error: 'Failed to check pairing status' });
    }
});

// Unpair
router.delete('/unpair', authenticateToken, async (req, res) => {
    try {
        const { userId } = req.user;
        const pool = getPool();

        if (pool) {
            await dbDeletePairing(userId);
            console.log(`✅ User ${userId.slice(0, 8)}... unpaired (PostgreSQL)`);
        } else {
            const pairing = activePairingsMemory.get(userId);
            if (pairing) {
                activePairingsMemory.delete(userId);
                activePairingsMemory.delete(pairing.partnerId);
            }
            console.log(`⚠️  User unpaired (in-memory)`);
        }

        res.json({ message: 'Successfully unpaired' });
    } catch (error) {
        console.error('Unpair error:', error);
        res.status(500).json({ error: 'Failed to unpair' });
    }
});

// Export for other modules (memory fallback)
export { activePairingsMemory as activePairings };
export default router;
