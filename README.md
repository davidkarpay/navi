# Navi - Apple Watch Pager App

[![Tests](https://github.com/yourusername/navi/actions/workflows/tests.yml/badge.svg)](https://github.com/yourusername/navi/actions/workflows/tests.yml)
[![Deploy](https://github.com/yourusername/navi/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/navi/actions/workflows/deploy.yml)

A minimalist two-person pager app for Apple Watch that lets partners send haptic taps to each other.

## Features

- **One-to-one pairing**: Exclusive connection between two Apple Watches
- **Simple tap interface**: Tap the watch face complication to send a buzz
- **6-digit pairing codes**: Easy setup process
- **Real-time communication**: WebSocket support for instant delivery
- **Privacy-focused**: Anonymous user system, no personal data required

## Project Structure

```
navi/
├── backend/          # Node.js/Express server
├── ios/             # iPhone companion app
├── watchos/         # Apple Watch app
├── shared/          # Shared Swift code
└── scripts/         # Build and deployment scripts
```

## Setup

### Prerequisites

- MacBook with Terminal access
- Node.js 18+ installed
- Swift 5.9+ (comes with macOS)
- Railway account for backend hosting
- Apple Developer account for APNs

### Quick Start

1. Clone and setup:
```bash
cd navi
./scripts/setup.sh
```

2. Configure backend:
- Edit `backend/.env` with your configuration
- Add APNs certificate to `backend/certs/AuthKey.p8`

3. Deploy backend to Railway:
```bash
./scripts/deploy-backend.sh
```

4. Update iOS/watchOS code with your Railway URL

## Backend Development

The backend can be fully developed and tested from terminal:

```bash
cd backend
npm install
npm run dev  # Start development server
```

### API Endpoints

- `POST /api/auth/register` - Register anonymous user
- `POST /api/pairing/create` - Generate pairing code
- `POST /api/pairing/join` - Join with pairing code
- `GET /api/pairing/status` - Check pairing status
- `DELETE /api/pairing/unpair` - Remove pairing
- `POST /api/tap/send` - Send tap to partner

### Database Schema

- `users` - Anonymous user records with device tokens
- `pairings` - Active and historical pairings
- `taps` - Tap history for analytics

## iOS/watchOS Development

### Without Xcode

Build using Swift Package Manager:
```bash
./scripts/build-swift.sh
```

Note: This only validates code structure. For actual app deployment, Xcode is required.

### Alternative Testing Methods

1. **Swift Playgrounds** (iPad): Import and test Swift logic
2. **Online Swift Compilers**: Test individual components
3. **Simulator** (requires Xcode): Full app testing
4. **TestFlight**: Beta testing on real devices

## Deployment

### Backend (Railway)

1. Login to Railway CLI
2. Link to your project
3. Run deployment script:
```bash
./scripts/deploy-backend.sh
```

### iOS/watchOS

1. Open project in Xcode (when available)
2. Configure signing & capabilities
3. Add APNs entitlement
4. Archive and upload to App Store Connect

## Configuration

### Environment Variables

Create `backend/.env`:
```
PORT=3000
JWT_SECRET=your-secret-key
APNS_KEY_ID=your-key-id
APNS_TEAM_ID=your-team-id
APNS_BUNDLE_ID=com.yourcompany.navi
```

### APNs Setup

1. Create APNs key in Apple Developer portal
2. Download `AuthKey_XXXXXX.p8`
3. Place in `backend/certs/`
4. Update `.env` with key details

## Testing

Run all tests:
```bash
./scripts/test.sh
```

Backend tests use Node.js built-in test runner.
Swift tests use XCTest framework.

## Architecture

- **Backend**: Node.js with Express, SQLite, WebSockets
- **iOS**: SwiftUI, WatchConnectivity framework
- **watchOS**: SwiftUI, complications, haptic feedback
- **Communication**: REST API + WebSockets + APNs

## Security

- JWT authentication
- Rate limiting on API endpoints
- Anonymous user system
- No personal data storage
- HTTPS/WSS encryption

## Next Steps

1. Set up APNs certificates
2. Deploy backend to Railway
3. Import into Xcode for final build
4. Test on real devices
5. Submit to App Store

## License

MIT