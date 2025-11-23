-- Navi Database Schema
-- SQLite database for production persistence

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    device_token TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Pairings table (many-to-many relationship via user pairs)
CREATE TABLE IF NOT EXISTS pairings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id_a TEXT NOT NULL,
    user_id_b TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id_a) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id_b) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id_a, user_id_b)
);

-- Pairing codes table (temporary codes for pairing)
CREATE TABLE IF NOT EXISTS pairing_codes (
    code TEXT PRIMARY KEY,
    creator_id TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Taps table (tap history)
CREATE TABLE IF NOT EXISTS taps (
    id TEXT PRIMARY KEY,
    from_user_id TEXT NOT NULL,
    to_user_id TEXT NOT NULL,
    intensity TEXT NOT NULL CHECK(intensity IN ('light', 'medium', 'strong')),
    pattern TEXT NOT NULL CHECK(pattern IN ('single', 'double', 'triple', 'heartbeat')),
    timestamp DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_pairings_user_a ON pairings(user_id_a);
CREATE INDEX IF NOT EXISTS idx_pairings_user_b ON pairings(user_id_b);
CREATE INDEX IF NOT EXISTS idx_taps_to_user ON taps(to_user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_taps_from_user ON taps(from_user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_pairing_codes_expires ON pairing_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_users_device_token ON users(device_token);
