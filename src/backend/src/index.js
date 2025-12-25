import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import rateLimit from 'express-rate-limit';

import authRoutes from './routes/auth.js';
import pairingRoutes from './routes/pairing.js';
import tapRoutes from './routes/tap.js';
import { authenticateToken } from './middleware/auth.js';
import { initDatabase } from './db/init.js';
import { initWebSocketManager } from './services/websocket.js';
import { initAPNs } from './services/apns.js';

dotenv.config();

const app = express();
const server = createServer(app);
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Initialize WebSocket
const wss = new WebSocketServer({ server });
const wsManager = initWebSocketManager(wss);

// Initialize APNs
initAPNs();

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/pairing', pairingRoutes);
app.use('/api/tap', tapRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Initialize database and start server
initDatabase().then(() => {
  server.listen(PORT, () => {
    console.log(`Navi backend running on port ${PORT}`);
  });
}).catch(err => {
  console.error('Failed to initialize database:', err);
  process.exit(1);
});