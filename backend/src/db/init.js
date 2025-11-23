// Database initialization
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let db = null;

export async function initDatabase() {
    const dbPath = process.env.DATABASE_URL || path.join(__dirname, '../../data/navi.db');
    const schemaPath = path.join(__dirname, 'schema.sql');

    // Ensure data directory exists
    const dataDir = path.dirname(dbPath);
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
    }

    // Open database connection
    db = await open({
        filename: dbPath,
        driver: sqlite3.Database
    });

    // Enable foreign keys
    await db.exec('PRAGMA foreign_keys = ON');

    // Read and execute schema
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await db.exec(schema);

    console.log(`Database initialized: ${dbPath}`);

    // Schedule cleanup of expired pairing codes
    scheduleCleanup();

    return db;
}

export function getDb() {
    if (!db) {
        throw new Error('Database not initialized. Call initDatabase() first.');
    }
    return db;
}

export async function closeDatabase() {
    if (db) {
        await db.close();
        db = null;
        console.log('Database connection closed');
    }
}

// Cleanup expired pairing codes every 5 minutes
function scheduleCleanup() {
    setInterval(async () => {
        try {
            const result = await db.run(
                'DELETE FROM pairing_codes WHERE expires_at < datetime("now")'
            );
            if (result.changes > 0) {
                console.log(`Cleaned up ${result.changes} expired pairing codes`);
            }
        } catch (error) {
            console.error('Error cleaning up expired pairing codes:', error);
        }
    }, 5 * 60 * 1000); // 5 minutes
}