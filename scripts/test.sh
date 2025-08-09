#!/bin/bash

echo "Running Navi tests..."

# Backend tests
echo ""
echo "Running backend tests..."
cd backend
npm test

# Swift tests (requires Swift toolchain)
echo ""
echo "Running Swift tests..."
cd ..
swift test

echo ""
echo "All tests complete!"