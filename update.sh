#!/bin/bash

# --- Hero Farm VPS Update Script ---
echo "🚀 Starting Hero Farm update process..."

# 1. Navigate to project root (assuming script is run from there)
cd "$(dirname "$0")"

# 2. Pull latest code from GitHub
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# 3. Enter deployment directory
cd vps-deploy

# 4. Rebuild and restart containers
echo "🛠️ Rebuilding and restarting Docker containers..."
sudo docker compose up -d --build

echo "✅ Update Complete! Your app is now running the latest version."
echo "🔗 App: http://43.133.137.52"
echo "🔗 WAHA: http://43.133.137.52:3000"
