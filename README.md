# Navi - Apple Watch Pager App

[![Tests](https://github.com/davidkarpay/navi/actions/workflows/tests.yml/badge.svg)](https://github.com/davidkarpay/navi/actions/workflows/tests.yml)
[![Deploy](https://github.com/davidkarpay/navi/actions/workflows/deploy.yml/badge.svg)](https://github.com/davidkarpay/navi/actions/workflows/deploy.yml)

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
├── src/
│   ├── backend/              # Node.js/Express server
│   ├── frontend/
│   │   └── ios/              # iOS + watchOS Xcode project
│   ├── shared/
│   │   └── swift/            # Shared Swift models
│   └── core/
│       └── scripts/          # Build and deployment scripts
├── docs/
│   ├── action-plans/         # Team action plans
│   ├── api/                  # API documentation
│   └── guides/               # Setup guides
├── tests/
│   └── integration/          # Cross-platform tests
├── config/                   # Configuration files
├── security/                 # Security policies
└── .github/
    ├── agents/               # AI agent profiles
    └── workflows/            # CI/CD pipelines
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
./src/core/scripts/setup.sh
```

2. Configure backend:
- Edit `src/backend/.env` with your configuration
- Add APNs certificate to `src/backend/certs/AuthKey.p8`

3. Deploy backend to Railway:
```bash
./src/core/scripts/deploy-backend.sh
```

4. Update iOS/watchOS code with your Railway URL

## Backend Development

The backend can be fully developed and tested from terminal:

```bash
cd src/backend
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

See [API Documentation](docs/api/API_DOCUMENTATION.md) for details.

## iOS/watchOS Development

The Xcode project is located at `src/frontend/ios/Navi_app.xcodeproj`.

### Build using Swift Package Manager:
```bash
./src/core/scripts/build-swift.sh
```

Note: This only validates code structure. For actual app deployment, Xcode is required.

## Deployment

### Backend (Railway)

1. Login to Railway CLI
2. Link to your project
3. Run deployment script:
```bash
./src/core/scripts/deploy-backend.sh
```

### iOS/watchOS

1. Open `src/frontend/ios/Navi_app.xcodeproj` in Xcode
2. Configure signing & capabilities
3. Add APNs entitlement
4. Archive and upload to App Store Connect

## Configuration

### Environment Variables

Create `src/backend/.env`:
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
3. Place in `src/backend/certs/`
4. Update `.env` with key details

## Testing

Run all tests:
```bash
./src/core/scripts/test.sh
```

Backend tests use Node.js built-in test runner.
Swift tests use XCTest framework.

## Documentation

- [Setup Guide](docs/guides/SETUP_GUIDE.md)
- [API Documentation](docs/api/API_DOCUMENTATION.md)
- [Action Plans](docs/action-plans/README.md)
- [Security Policy](security/SECURITY.md)

## Architecture

- **Backend**: Node.js with Express, SQLite, WebSockets
- **iOS**: SwiftUI, WatchConnectivity framework
- **watchOS**: SwiftUI, complications, haptic feedback
- **Communication**: REST API + WebSockets + APNs

## Agent Development Framework

This repository uses an AI Agent Development Framework for coordinated development. Agent profiles are defined in `.github/agents/`:

- `backend-agent` - Backend development
- `ios-agent` - iOS development
- `watchos-agent` - watchOS development
- `devops-agent` - DevOps and infrastructure
- `qa-agent` - Testing and quality
- `integration-agent` - Cross-platform integration

## Security

See [Security Policy](security/SECURITY.md) for:
- Vulnerability reporting
- Security measures
- Data handling policies

## License

MIT
