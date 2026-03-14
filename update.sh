#!/bin/bash

# --- Hero Farm VPS Update Script ---
echo "🚀 Starting Hero Farm update process..."

# 1. Navigate to project root
cd "$(dirname "$0")"

# 2. Pull latest code from GitHub (Reset hard to ensure no conflicts on VPS)
echo "📥 Fetching and resetting to latest code..."
git fetch origin main
git reset --hard origin/main

# 3. Cleanup old Docker images to save disk space
echo "🧹 Cleaning up old Docker images..."
docker image prune -f

# 4. Enter deployment directory
cd vps-deploy

# 5. Rebuild and restart containers
echo "🛠️ Rebuilding and restarting Docker containers..."
sudo docker compose up -d --build

echo ""
echo "✅ Update Complete! Your app is now running the latest version."
echo "🔗 App: http://43.133.137.52"
echo "🔗 WAHA: http://43.133.137.52:3000"
echo ""
echo "⚠️  REMINDER: Please ensure you have applied the latest SQL migrations in Supabase Dashboard!"
echo "📍 Migration: web-app/migrations/20260315_fix_financial_integrity.sql"
echo ""
echo "🧩 NGINX PROXY SETUP (WhatsApp Terminal HTTPS Fix):"
echo "   Make sure your /etc/nginx/sites-available/herofarm.web.id has this block:"
echo "   location /waha-api/ {"
echo "       proxy_pass http://127.0.0.1:3000/;"
echo "       proxy_http_version 1.1;"
echo "       proxy_set_header Host \$host;"
echo "       proxy_set_header X-Real-IP \$remote_addr;"
echo "       add_header Access-Control-Allow-Origin \"*\" always;"
echo "       add_header Access-Control-Allow-Methods \"GET,POST,PUT,DELETE,OPTIONS\" always;"
echo "       add_header Access-Control-Allow-Headers \"authorization,content-type,apikey,x-api-key\" always;"
echo "       if (\$request_method = OPTIONS) { return 204; }"
echo "   }"
echo "   Then run: sudo nginx -t && sudo systemctl reload nginx"
echo ""

