#!/bin/bash

echo "Setting up Navi project..."

# Backend setup
echo "Setting up backend..."
cd backend
npm install
cp .env.example .env
echo "Please update backend/.env with your API keys and configuration"

# Create data directory
mkdir -p data

# Initialize database
npm run db:init

cd ..

# iOS/watchOS setup
echo "Setting up iOS/watchOS..."
echo "Swift Package Manager is configured."
echo "To build without Xcode, you can use: swift build"
echo "However, for iOS/watchOS deployment, Xcode is recommended."

# Create certificates directory
mkdir -p backend/certs
echo "Please add your APNs certificate (AuthKey.p8) to backend/certs/"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update backend/.env with your configuration"
echo "2. Add APNs certificate to backend/certs/"
echo "3. Deploy backend to Railway: cd backend && railway login && railway link && railway up"
echo "4. Update API_URL in iOS/watchOS code with your Railway URL"
echo "5. Open project in Xcode for iOS/watchOS development"