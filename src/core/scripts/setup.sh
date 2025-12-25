#!/bin/bash

# Get project root (3 levels up from scripts directory)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

echo "Setting up Navi project..."

# Backend setup
echo "Setting up backend..."
cd "$PROJECT_ROOT/src/backend"
npm install
cp .env.example .env
echo "Please update src/backend/.env with your API keys and configuration"

# Create data directory
mkdir -p data

# Initialize database
npm run db:init

cd "$PROJECT_ROOT"

# iOS/watchOS setup
echo "Setting up iOS/watchOS..."
echo "Swift Package Manager is configured."
echo "To build without Xcode, you can use: swift build"
echo "However, for iOS/watchOS deployment, Xcode is recommended."

# Create certificates directory
mkdir -p src/backend/certs
echo "Please add your APNs certificate (AuthKey.p8) to src/backend/certs/"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update src/backend/.env with your configuration"
echo "2. Add APNs certificate to src/backend/certs/"
echo "3. Deploy backend to Railway: cd src/backend && railway login && railway link && railway up"
echo "4. Update API_URL in iOS/watchOS code with your Railway URL"
echo "5. Open project in Xcode for iOS/watchOS development"