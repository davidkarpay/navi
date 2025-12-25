import jwt from 'jsonwebtoken';
import { storeTapInHistory } from '../routes/tap.js';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-key';

// Store active WebSocket connections
const activeConnections = new Map(); // userId -> WebSocket

export function initWebSocketManager(wss) {
    wss.on('connection', (ws, request) => {
        console.log('New WebSocket connection');
        
        let userId = null;
        
        // Handle authentication
        ws.on('message', async (message) => {
            try {
                const data = JSON.parse(message.toString());
                
                if (data.type === 'auth') {
                    // Authenticate the connection
                    const token = data.token;
                    if (!token) {
                        ws.send(JSON.stringify({ type: 'error', message: 'No token provided' }));
                        return ws.close();
                    }
                    
                    try {
                        const decoded = jwt.verify(token, JWT_SECRET);
                        userId = decoded.userId;
                        
                        // Store the connection
                        activeConnections.set(userId, ws);
                        
                        ws.send(JSON.stringify({ 
                            type: 'auth_success', 
                            message: 'WebSocket authenticated successfully',
                            userId 
                        }));
                        
                        console.log(`User ${userId} connected via WebSocket`);
                        
                    } catch (err) {
                        ws.send(JSON.stringify({ type: 'error', message: 'Invalid token' }));
                        return ws.close();
                    }
                }
                
                if (data.type === 'ping') {
                    ws.send(JSON.stringify({ type: 'pong', timestamp: new Date().toISOString() }));
                }
                
            } catch (err) {
                console.error('WebSocket message error:', err);
                ws.send(JSON.stringify({ type: 'error', message: 'Invalid message format' }));
            }
        });
        
        ws.on('close', () => {
            if (userId) {
                activeConnections.delete(userId);
                console.log(`User ${userId} disconnected from WebSocket`);
            }
        });
        
        ws.on('error', (error) => {
            console.error('WebSocket error:', error);
            if (userId) {
                activeConnections.delete(userId);
            }
        });
    });
    
    // Cleanup inactive connections
    setInterval(() => {
        for (const [userId, ws] of activeConnections.entries()) {
            if (ws.readyState !== ws.OPEN) {
                activeConnections.delete(userId);
            }
        }
    }, 30000); // Check every 30 seconds
    
    return { activeConnections };
}

// Send tap message to a specific user
export async function sendTapToUser(userId, tapMessage) {
    const ws = activeConnections.get(userId);
    
    if (!ws || ws.readyState !== ws.OPEN) {
        console.log(`User ${userId} not connected via WebSocket`);
        return false;
    }
    
    try {
        const message = {
            type: 'tap_received',
            ...tapMessage
        };
        
        ws.send(JSON.stringify(message));
        
        // Store in history
        storeTapInHistory(userId, tapMessage);
        
        console.log(`Tap sent to user ${userId}`);
        return true;
    } catch (error) {
        console.error('Error sending tap:', error);
        return false;
    }
}

// Get connection status for a user
export function isUserConnected(userId) {
    const ws = activeConnections.get(userId);
    return ws && ws.readyState === ws.OPEN;
}

// Send message to all connected users (for future features)
export function broadcastMessage(message) {
    for (const [userId, ws] of activeConnections.entries()) {
        if (ws.readyState === ws.OPEN) {
            try {
                ws.send(JSON.stringify(message));
            } catch (error) {
                console.error(`Error broadcasting to user ${userId}:`, error);
                activeConnections.delete(userId);
            }
        }
    }
}