#!/bin/bash

echo "Deploying Navi backend to Railway..."

cd backend

# Check if logged in to Railway
if ! railway whoami > /dev/null 2>&1; then
    echo "Please login to Railway first:"
    railway login
fi

# Check if project is linked
if ! railway status > /dev/null 2>&1; then
    echo "Please link to a Railway project:"
    railway link
fi

# Deploy
echo "Deploying to Railway..."
railway up

echo ""
echo "Deployment complete!"
echo "Your backend URL: $(railway status | grep 'URL' | awk '{print $2}')"
echo ""
echo "Don't forget to:"
echo "1. Set environment variables in Railway dashboard"
echo "2. Update iOS/watchOS code with your Railway URL"