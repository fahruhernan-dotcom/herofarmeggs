#!/bin/bash

# --- Hero Farm VPS Professional Update Script ---
# Version: 2.1 (Auto-Sync Edition)
echo "🚀 [SYSTEM] Starting Hero Farm Elite update process..."

# 1. Navigate to project root
cd "$(dirname "$0")"

# 2. Pull latest code from GitHub
echo "📥 [GIT] Fetching and resetting to latest code from GitHub..."
git fetch origin main
git reset --hard origin/main

# 3. Cleanup to prevent conflicts
echo "🧹 [CLEANUP] Stopping old/conflicting containers if any..."
# Silently stop telur-web if it exists
sudo docker stop telur-web 2>/dev/null || true
# Cleanup old images to save disk space
sudo docker image prune -f

# 4. Enter deployment directory
cd vps-deploy

# 5. Rebuild and restart containers
echo "🛠️ [DOCKER] Rebuilding (Clean Build) and restarting containers..."
# Using --no-cache to ensure all recent code changes are captured
sudo docker compose build --no-cache web-app
sudo docker compose up -d

# 6. Synchronize Host Nginx
echo "🔄 [NGINX] Reloading host reverse proxy..."
if [ -f "/etc/nginx/sites-enabled/herofarm.web.id" ]; then
    sudo nginx -t && sudo systemctl reload nginx
    echo "✅ [NGINX] Proxy synchronized with new build."
else
    echo "⚠️ [NGINX] Config not found in sites-enabled. Skipping reload."
fi

echo ""
echo "✅ [SUCCESS] Update Complete! Hero Farm is now running the latest version."
echo "🔗 Domain: https://herofarm.web.id"
echo "🔗 Local IP: http://43.133.137.52:8080"
echo ""
echo "🧩 WAHA Terminal status: Active"
echo "🧩 Database: Connected (Supabase)"
echo ""
