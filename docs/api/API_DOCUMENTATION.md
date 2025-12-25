# Navi API Documentation

## Base URL
**Production**: `https://lovely-vibrancy-production-2c30.up.railway.app`

## Authentication
All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <jwt-token>
```

## Rate Limiting
- **100 requests per minute** per IP address
- Rate limit headers included in responses:
  - `X-RateLimit-Limit`: Request limit
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp

---

## 📋 Endpoints

### Health Check

#### `GET /health`
Check API status and database connection.

**Request:**
```bash
curl https://lovely-vibrancy-production-2c30.up.railway.app/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-08-08T12:00:00.000Z"
}
```

---

## 🔐 Authentication

### Register User

#### `POST /api/auth/register`
Register a new anonymous user with device token.

**Request:**
```bash
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/auth/register \\
  -H "Content-Type: application/json" \\
  -d '{
    "deviceToken": "apns-device-token-here"
  }'
```

**Request Body:**
```json
{
  "deviceToken": "string" // APNS device token (required)
}
```

**Response (200):**
```json
{
  "userId": "97c2a6a0-646a-4646-bcf2-7a3f1034907f",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "User created successfully"
}
```

**Error Responses:**
- `400`: Missing deviceToken
- `500`: Server error

### Update Device Token

#### `PUT /api/auth/device-token`
Update the APNS device token for push notifications.

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceToken": "new-apns-device-token"
}
```

**Response (200):**
```json
{
  "message": "Device token updated successfully"
}
```

---

## 👫 Pairing

### Get Pairing Status

#### `GET /api/pairing/status`
Check current pairing status.

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Request:**
```bash
curl https://lovely-vibrancy-production-2c30.up.railway.app/api/pairing/status \\
  -H "Authorization: Bearer <jwt-token>"
```

**Response (200) - Not Paired:**
```json
{
  "paired": false,
  "partnerId": null,
  "pairedAt": null
}
```

**Response (200) - Paired:**
```json
{
  "paired": true,
  "partnerId": "b8c3d4e5-f6g7-h8i9-j0k1-l2m3n4o5p6q7",
  "pairedAt": "2025-08-08T12:00:00.000Z"
}
```

### Create Pairing Code

#### `POST /api/pairing/create`
Generate a 6-digit pairing code (expires in 5 minutes).

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request:**
```bash
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/pairing/create \\
  -H "Authorization: Bearer <jwt-token>" \\
  -H "Content-Type: application/json"
```

**Response (200):**
```json
{
  "pairingCode": "749967",
  "expiresIn": 300
}
```

**Error Responses:**
- `400`: User already paired
- `401`: Invalid/expired token
- `500`: Server error

### Join with Pairing Code

#### `POST /api/pairing/join`
Join using a 6-digit pairing code.

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "pairingCode": "749967"
}
```

**Request:**
```bash
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/pairing/join \\
  -H "Authorization: Bearer <jwt-token>" \\
  -H "Content-Type: application/json" \\
  -d '{"pairingCode": "749967"}'
```

**Response (200):**
```json
{
  "message": "Paired successfully",
  "partnerId": "b8c3d4e5-f6g7-h8i9-j0k1-l2m3n4o5p6q7"
}
```

**Error Responses:**
- `400`: Missing/invalid pairing code
- `404`: Pairing code not found/expired
- `409`: User already paired
- `410`: Cannot pair with yourself

### Unpair

#### `DELETE /api/pairing/unpair`
Remove current pairing.

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Request:**
```bash
curl -X DELETE https://lovely-vibrancy-production-2c30.up.railway.app/api/pairing/unpair \\
  -H "Authorization: Bearer <jwt-token>"
```

**Response (200):**
```json
{
  "message": "Unpaired successfully"
}
```

**Error Responses:**
- `400`: User not currently paired
- `401`: Invalid/expired token

---

## 📳 Tap Sending

### Send Tap

#### `POST /api/tap/send`
Send a tap notification to paired partner.

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request:**
```bash
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/tap/send \\
  -H "Authorization: Bearer <jwt-token>" \\
  -H "Content-Type: application/json"
```

**Response (200):**
```json
{
  "message": "Tap sent successfully"
}
```

**Error Responses:**
- `400`: User not paired
- `401`: Invalid/expired token
- `404`: Partner not found
- `500`: Push notification failed

---

## 🔌 WebSocket Connection

### Connect

**URL:** `wss://lovely-vibrancy-production-2c30.up.railway.app`

**Query Parameters:**
- `token`: JWT authentication token

**Connection:**
```javascript
const ws = new WebSocket('wss://lovely-vibrancy-production-2c30.up.railway.app?token=YOUR_JWT_TOKEN');
```

### Events Received

#### Pairing Updates
```json
{
  "type": "paired",
  "timestamp": "2025-08-08T12:00:00.000Z"
}
```

```json
{
  "type": "unpaired", 
  "timestamp": "2025-08-08T12:00:00.000Z"
}
```

#### Tap Notifications
```json
{
  "type": "tap_received",
  "timestamp": "2025-08-08T12:00:00.000Z",
  "fromUserId": "partner-user-id"
}
```

### Connection States
- **Connecting**: Initial connection attempt
- **Open**: Connected and authenticated
- **Closing**: Connection being terminated
- **Closed**: Connection terminated

### Error Handling
The WebSocket will automatically attempt to reconnect on connection loss with exponential backoff (5s, 10s, 20s, max 60s).

---

## 📊 Response Formats

### Success Response
```json
{
  "data": {},
  "message": "Success message",
  "timestamp": "2025-08-08T12:00:00.000Z"
}
```

### Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message"
  },
  "timestamp": "2025-08-08T12:00:00.000Z"
}
```

### Common Error Codes
- `INVALID_TOKEN`: JWT token is invalid or expired
- `MISSING_TOKEN`: Authorization header missing
- `USER_NOT_FOUND`: User ID not found in database
- `INVALID_PAIRING_CODE`: Pairing code format invalid
- `PAIRING_CODE_EXPIRED`: Pairing code has expired
- `ALREADY_PAIRED`: User is already paired
- `NOT_PAIRED`: User is not currently paired
- `SELF_PAIRING_DENIED`: Cannot pair with yourself
- `RATE_LIMITED`: Too many requests
- `SERVER_ERROR`: Internal server error

---

## 🧪 Testing Examples

### Complete Flow Test

```bash
#!/bin/bash

API_BASE="https://lovely-vibrancy-production-2c30.up.railway.app"

echo "1. Register User A"
USER_A=$(curl -s -X POST "$API_BASE/api/auth/register" \\
  -H "Content-Type: application/json" \\
  -d '{"deviceToken": "test-token-a"}')
  
TOKEN_A=$(echo $USER_A | jq -r '.token')
echo "User A Token: $TOKEN_A"

echo "\\n2. Register User B"
USER_B=$(curl -s -X POST "$API_BASE/api/auth/register" \\
  -H "Content-Type: application/json" \\
  -d '{"deviceToken": "test-token-b"}')
  
TOKEN_B=$(echo $USER_B | jq -r '.token')
echo "User B Token: $TOKEN_B"

echo "\\n3. User A creates pairing code"
PAIRING=$(curl -s -X POST "$API_BASE/api/pairing/create" \\
  -H "Authorization: Bearer $TOKEN_A" \\
  -H "Content-Type: application/json")
  
CODE=$(echo $PAIRING | jq -r '.pairingCode')
echo "Pairing Code: $CODE"

echo "\\n4. User B joins with code"
JOIN=$(curl -s -X POST "$API_BASE/api/pairing/join" \\
  -H "Authorization: Bearer $TOKEN_B" \\
  -H "Content-Type: application/json" \\
  -d "{\"pairingCode\": \"$CODE\"}")
  
echo "Join Result: $JOIN"

echo "\\n5. User B sends tap to User A"
TAP=$(curl -s -X POST "$API_BASE/api/tap/send" \\
  -H "Authorization: Bearer $TOKEN_B" \\
  -H "Content-Type: application/json")
  
echo "Tap Result: $TAP"

echo "\\n6. Check pairing status"
STATUS=$(curl -s "$API_BASE/api/pairing/status" \\
  -H "Authorization: Bearer $TOKEN_A")
  
echo "Pairing Status: $STATUS"
```

### Load Testing

```bash
# Test rate limiting
for i in {1..110}; do
  curl -s -w "%{http_code}\\n" https://lovely-vibrancy-production-2c30.up.railway.app/health > /dev/null
done
```

---

## 🔧 Client Implementation

### Swift (iOS/watchOS)

```swift
class NaviAPI {
    private let baseURL = "https://lovely-vibrancy-production-2c30.up.railway.app"
    private var authToken: String?
    
    func register(deviceToken: String) async throws -> AuthResponse {
        let url = URL(string: "\\(baseURL)/api/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["deviceToken": deviceToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func createPairingCode() async throws -> PairingCodeResponse {
        let url = URL(string: "\\(baseURL)/api/pairing/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \\(authToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PairingCodeResponse.self, from: data)
    }
    
    func sendTap() async throws {
        let url = URL(string: "\\(baseURL)/api/tap/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \\(authToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
```

### JavaScript (Web Client)

```javascript
class NaviAPI {
    constructor(baseURL = 'https://lovely-vibrancy-production-2c30.up.railway.app') {
        this.baseURL = baseURL;
        this.authToken = null;
        this.ws = null;
    }
    
    async register(deviceToken) {
        const response = await fetch(`${this.baseURL}/api/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ deviceToken })
        });
        
        const data = await response.json();
        this.authToken = data.token;
        return data;
    }
    
    async createPairingCode() {
        const response = await fetch(`${this.baseURL}/api/pairing/create`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${this.authToken}`,
                'Content-Type': 'application/json'
            }
        });
        
        return await response.json();
    }
    
    connectWebSocket() {
        const wsURL = this.baseURL.replace('https://', 'wss://');
        this.ws = new WebSocket(`${wsURL}?token=${this.authToken}`);
        
        this.ws.onmessage = (event) => {
            const message = JSON.parse(event.data);
            this.handleWebSocketMessage(message);
        };
    }
    
    handleWebSocketMessage(message) {
        switch (message.type) {
            case 'paired':
                console.log('Successfully paired!');
                break;
            case 'tap_received':
                console.log('Tap received from partner');
                break;
        }
    }
}
```

---

## 📈 Monitoring & Analytics

### Health Checks
- **Endpoint**: `/health`
- **Frequency**: Every 10 seconds
- **Timeout**: 5 seconds
- **Expected**: HTTP 200 with JSON response

### Metrics Tracked
- Request count by endpoint
- Response times (p50, p95, p99)
- Error rates by endpoint
- WebSocket connections (active, total)
- Pairing success rate
- Push notification delivery rate

### Database Monitoring
- Connection pool status
- Query execution times
- Database file size
- Active transactions

---

## 🔒 Security Considerations

### Authentication
- JWT tokens expire after 30 days
- Device tokens encrypted at rest
- HTTPS enforced for all endpoints

### Rate Limiting
- 100 requests/minute per IP
- Pairing code attempts limited
- WebSocket connections throttled

### Data Privacy
- No personal information stored
- User IDs are UUIDs
- Pairing codes expire in 5 minutes
- No message content stored

### Infrastructure
- CORS enabled for web clients
- Security headers enforced
- Regular security updates
- Automated backups

---

**Last Updated**: August 8, 2025  
**API Version**: 1.0  
**Contact**: support@navi-app.com