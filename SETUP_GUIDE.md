# Navi - Apple Watch Pager App

A simple yet powerful pager app that allows paired users to send tap notifications to each other's Apple Watches with haptic feedback.

## 🎯 Features

- **Anonymous Registration**: No personal data required
- **6-Digit Pairing Codes**: Secure, time-limited pairing system
- **Real-time Notifications**: Instant tap delivery via WebSocket
- **Haptic Feedback**: Rich tactile responses on Apple Watch
- **Cross-Platform**: iOS companion app + watchOS main app
- **Production Ready**: Deployed backend with Railway

## 🏗️ Architecture

- **Backend**: Node.js/Express with SQLite database
- **iOS App**: SwiftUI companion for pairing and management
- **watchOS App**: Main interface for sending/receiving taps
- **Communication**: WebSocket + APNS push notifications
- **Deployment**: Railway cloud platform

## 🚀 Quick Setup

### Prerequisites

- Xcode 15.0+
- Apple Developer Account (for device testing)
- macOS 14.0+
- iPhone/Apple Watch for testing

### 1. Clone & Setup

```bash
git clone <your-repo-url>
cd navi
```

### 2. Open in Xcode

1. Open `Navi_app/Navi_app.xcodeproj`
2. **Add Watch App Target**:
   - Select project → Click "+" → watchOS → Watch App
   - Name: `Navi_app Watch App`
   - Interface: SwiftUI
   - ✅ Include Notification Scene
   - ✅ Include Complication

### 3. Configure Watch App Files

1. **Delete default files** in Watch App target
2. **Add existing files**:
   - Right-click Watch App folder → Add Files
   - Select all files from `Navi_app/Navi_app Watch App/`
   - ✅ Copy items if needed
3. **Add Shared files**:
   - Select `Shared` folder → File Inspector
   - ✅ Check both targets

### 4. Build & Run

```bash
# Build iOS app
xcodebuild -project Navi_app.xcodeproj -scheme Navi_app -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run iOS app in simulator
# Run Watch app in paired Watch simulator
```

## 🔧 Configuration

### Backend URLs

The app is pre-configured for production:
- **Production API**: `https://lovely-vibrancy-production-2c30.up.railway.app`
- **Health Check**: `https://lovely-vibrancy-production-2c30.up.railway.app/health`

### Environment Variables (Optional)

Set `API_URL` environment variable to override default backend:

```bash
export API_URL="https://your-custom-backend.com"
```

## 📱 How to Use

### iOS App (Companion)
1. **Launch app** → Automatic registration
2. **Grant notification permissions** when prompted
3. **Create pairing code** (6 digits, expires in 5 minutes)
4. **Share code** with your partner

### Apple Watch App (Main)
1. **Launch Navi** on your Apple Watch
2. **Enter pairing code** received from partner
3. **Tap the main button** to send notifications
4. **Feel haptic feedback** when receiving taps

### Pairing Process
```
User A (iOS)    User B (Watch)
    |               |
    |-- Create Code |
    |   (749967)    |
    |               |-- Enter Code
    |               |   (749967)
    |<-- Paired! -->|
    |               |
    |<-- Tap! ------|-- Tap Button
    |   (Haptic)    |
```

## 🔒 Security & Privacy

- **Anonymous Users**: No personal data collected
- **Temporary Codes**: 5-minute expiration on pairing codes
- **JWT Authentication**: Secure API access
- **HTTPS Only**: All communications encrypted
- **No Data Storage**: No conversation history

## 🧪 Testing

### API Endpoints Testing

```bash
# Test user registration
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/auth/register \\
  -H "Content-Type: application/json" \\
  -d '{"deviceToken": "test-token-123"}'

# Test pairing code creation (requires auth token)
curl -X POST https://lovely-vibrancy-production-2c30.up.railway.app/api/pairing/create \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json"

# Test health endpoint
curl https://lovely-vibrancy-production-2c30.up.railway.app/health
```

### Manual Testing Checklist

- [ ] iOS app launches and registers user
- [ ] Push notification permission requested
- [ ] Pairing code generation works (6 digits)
- [ ] Watch app launches and shows pairing screen
- [ ] Pairing completes successfully
- [ ] Taps send from Watch to paired device
- [ ] Haptic feedback triggers on receiving device
- [ ] WebSocket connection remains stable
- [ ] App works on physical devices

## 📚 API Documentation

### Authentication

```javascript
POST /api/auth/register
Body: { "deviceToken": "apns-device-token" }
Response: { "userId": "uuid", "token": "jwt-token", "message": "success" }
```

### Pairing

```javascript
// Create pairing code
POST /api/pairing/create
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "pairingCode": "123456", "expiresIn": 300 }

// Join with code
POST /api/pairing/join
Headers: { "Authorization": "Bearer jwt-token" }
Body: { "pairingCode": "123456" }
Response: { "message": "Paired successfully", "partnerId": "uuid" }

// Check pairing status
GET /api/pairing/status
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "paired": true, "partnerId": "uuid", "pairedAt": "iso-date" }

// Unpair
DELETE /api/pairing/unpair
Headers: { "Authorization": "Bearer jwt-token" }
```

### Tap Sending

```javascript
POST /api/tap/send
Headers: { "Authorization": "Bearer jwt-token" }
Response: { "message": "Tap sent successfully" }
```

### WebSocket Events

```javascript
// Connection
ws://api-url?token=jwt-token

// Events received:
{ "type": "paired", "timestamp": "iso-date" }
{ "type": "unpaired", "timestamp": "iso-date" }
{ "type": "tap_received", "timestamp": "iso-date" }
```

## 🚀 Deployment

### Backend (Already Deployed)

The backend is live on Railway:
- **URL**: https://lovely-vibrancy-production-2c30.up.railway.app
- **Status**: Production ready
- **Database**: SQLite with automatic backups
- **Monitoring**: Health checks every 10 seconds

### iOS App Store (Future)

1. **Configure signing** in Xcode
2. **Set up APNS certificates** in Apple Developer Portal
3. **Archive and upload** to App Store Connect
4. **Submit for review**

## 🛠️ Troubleshooting

### Common Issues

**Watch App not appearing in Xcode**
- Ensure watchOS target is added correctly
- Check scheme configuration
- Verify target dependencies

**Build errors**
- Clean build folder (⌘+Shift+K)
- Delete derived data
- Check file target memberships

**Pairing not working**
- Verify backend is running (check health endpoint)
- Check device token generation
- Ensure WebSocket connection is established

**Push notifications not received**
- Verify APNS certificates are uploaded
- Check notification permissions
- Test with device (not simulator)

### Debug Commands

```bash
# Check backend status
curl https://lovely-vibrancy-production-2c30.up.railway.app/health

# View Railway logs
railway logs

# Test WebSocket connection
wscat -c "wss://lovely-vibrancy-production-2c30.up.railway.app?token=YOUR_TOKEN"
```

## 📞 Support

- **Issues**: Create GitHub issue with logs
- **Feature Requests**: Open GitHub discussion
- **Security**: Email security@yourcompany.com

## 📄 License

MIT License - see LICENSE file for details

---

**Built with ❤️ using SwiftUI, Node.js, and Railway**