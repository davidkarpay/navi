// Database initialization with PostgreSQL
import pg from 'pg';

const { Pool } = pg;

let pool = null;

export async function initDatabase() {
    // Use DATABASE_URL from Railway, or fall back to local
    const connectionString = process.env.DATABASE_URL;

    if (!connectionString) {
        console.warn('⚠️  DATABASE_URL not set - using in-memory fallback');
        console.warn('   Set DATABASE_URL to enable persistent storage');
        return null;
    }

    try {
        pool = new Pool({
            connectionString,
            ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
        });

        // Test connection
        await pool.query('SELECT NOW()');
        console.log('✅ PostgreSQL connected');

        // Create tables
        await pool.query(`
            CREATE TABLE IF NOT EXISTS users (
                id UUID PRIMARY KEY,
                device_token TEXT,
                created_at TIMESTAMP DEFAULT NOW()
            )
        `);

        await pool.query(`
            CREATE TABLE IF NOT EXISTS pairings (
                user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
                partner_id UUID REFERENCES users(id) ON DELETE CASCADE,
                paired_at TIMESTAMP DEFAULT NOW()
            )
        `);

        await pool.query(`
            CREATE TABLE IF NOT EXISTS pairing_codes (
                code VARCHAR(6) PRIMARY KEY,
                creator_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT NOW(),
                expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '10 minutes'
            )
        `);

        // Create index for expired codes cleanup
        await pool.query(`
            CREATE INDEX IF NOT EXISTS idx_pairing_codes_expires
            ON pairing_codes(expires_at)
        `);

        console.log('✅ Database tables ready');
        return pool;
    } catch (error) {
        console.error('❌ Database connection failed:', error.message);
        return null;
    }
}

export function getPool() {
    return pool;
}

// User operations
export async function createUser(userId, deviceToken) {
    if (!pool) return { inMemory: true };

    const result = await pool.query(
        `INSERT INTO users (id, device_token)
         VALUES ($1, $2)
         ON CONFLICT (id) DO UPDATE SET device_token = $2
         RETURNING *`,
        [userId, deviceToken]
    );
    return result.rows[0];
}

export async function getUser(userId) {
    if (!pool) return null;

    const result = await pool.query(
        'SELECT * FROM users WHERE id = $1',
        [userId]
    );
    return result.rows[0] || null;
}

export async function updateDeviceToken(userId, deviceToken) {
    if (!pool) return null;

    const result = await pool.query(
        'UPDATE users SET device_token = $1 WHERE id = $2 RETURNING *',
        [deviceToken, userId]
    );
    return result.rows[0] || null;
}

// Pairing operations
export async function createPairingCode(code, creatorUserId) {
    if (!pool) return { inMemory: true };

    // First, delete any existing codes from this user
    await pool.query(
        'DELETE FROM pairing_codes WHERE creator_user_id = $1',
        [creatorUserId]
    );

    const result = await pool.query(
        `INSERT INTO pairing_codes (code, creator_user_id)
         VALUES ($1, $2)
         RETURNING *`,
        [code, creatorUserId]
    );
    return result.rows[0];
}

export async function getPairingCode(code) {
    if (!pool) return null;

    // Get code if not expired
    const result = await pool.query(
        `SELECT * FROM pairing_codes
         WHERE code = $1 AND expires_at > NOW()`,
        [code]
    );
    return result.rows[0] || null;
}

export async function deletePairingCode(code) {
    if (!pool) return;

    await pool.query('DELETE FROM pairing_codes WHERE code = $1', [code]);
}

export async function createPairing(userId, partnerId) {
    if (!pool) return { inMemory: true };

    // Create pairing for both users (upsert)
    await pool.query(
        `INSERT INTO pairings (user_id, partner_id)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE SET partner_id = $2, paired_at = NOW()`,
        [userId, partnerId]
    );

    await pool.query(
        `INSERT INTO pairings (user_id, partner_id)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE SET partner_id = $2, paired_at = NOW()`,
        [partnerId, userId]
    );

    return { userId, partnerId, pairedAt: new Date() };
}

export async function getPairing(userId) {
    if (!pool) return null;

    const result = await pool.query(
        'SELECT * FROM pairings WHERE user_id = $1',
        [userId]
    );
    return result.rows[0] || null;
}

export async function deletePairing(userId) {
    if (!pool) return;

    // Get partner first
    const pairing = await getPairing(userId);
    if (pairing) {
        // Delete both sides
        await pool.query('DELETE FROM pairings WHERE user_id = $1', [userId]);
        await pool.query('DELETE FROM pairings WHERE user_id = $1', [pairing.partner_id]);
    }
}

// Cleanup expired pairing codes (call periodically)
export async function cleanupExpiredCodes() {
    if (!pool) return;

    await pool.query('DELETE FROM pairing_codes WHERE expires_at < NOW()');
}
