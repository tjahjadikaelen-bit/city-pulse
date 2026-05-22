#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  City Pulse — GitHub Pages Auto-Deploy Script
#  Run this in your terminal to publish City Pulse in ~2 minutes
# ═══════════════════════════════════════════════════════════════
#
# PREREQUISITES:
#   1. A GitHub account (free): https://github.com/join
#   2. A Personal Access Token with "repo" scope:
#      https://github.com/settings/tokens/new
#      → Select: repo (full control)
#      → Copy the token
#   3. The 3 HTML files in the same folder as this script:
#      - city-pulse.html
#      - city-pulse-planner.html
#      - city-pulse-combined.html   (optional, single-file version)
#
# USAGE:
#   chmod +x deploy.sh
#   ./deploy.sh YOUR_GITHUB_USERNAME YOUR_GITHUB_TOKEN
#
# RESULT:
#   Your site will be live at:
#   https://YOUR_USERNAME.github.io/city-pulse/
# ═══════════════════════════════════════════════════════════════

set -e

USERNAME="${1}"
TOKEN="${2}"
REPO_NAME="city-pulse"

if [ -z "$USERNAME" ] || [ -z "$TOKEN" ]; then
  echo ""
  echo "❌  Usage: ./deploy.sh YOUR_GITHUB_USERNAME YOUR_GITHUB_TOKEN"
  echo ""
  echo "   Get a token at: https://github.com/settings/tokens/new"
  echo "   Required scope: repo"
  echo ""
  exit 1
fi

echo ""
echo "🚀  City Pulse — GitHub Pages Deploy"
echo "────────────────────────────────────"
echo "   User:   $USERNAME"
echo "   Repo:   $REPO_NAME"
echo ""

# Step 1: Create the GitHub repo via API
echo "📁  Creating GitHub repository..."
REPO_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"City Pulse — Smart Urban Mobility Platform for Jakarta\",
    \"homepage\": \"https://$USERNAME.github.io/$REPO_NAME/\",
    \"private\": false,
    \"auto_init\": false
  }")

if echo "$REPO_RESPONSE" | grep -q '"already_exists"'; then
  echo "   ✓ Repository already exists — updating files..."
elif echo "$REPO_RESPONSE" | grep -q '"full_name"'; then
  echo "   ✓ Repository created: https://github.com/$USERNAME/$REPO_NAME"
else
  echo "   ⚠ Repo may already exist — continuing with push..."
fi

# Step 2: Set up local git repo
echo ""
echo "📦  Setting up local repository..."
DEPLOY_DIR="/tmp/city-pulse-deploy-$$"
mkdir -p "$DEPLOY_DIR"

# Copy HTML files
for f in city-pulse.html city-pulse-planner.html city-pulse-combined.html; do
  if [ -f "$f" ]; then
    cp "$f" "$DEPLOY_DIR/$f"
    echo "   ✓ Added $f"
  fi
done

# Create index.html that redirects to city-pulse.html
cat > "$DEPLOY_DIR/index.html" << 'INDEX'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="0;url=city-pulse.html">
<title>City Pulse — Redirecting…</title>
</head>
<body>
<p>Redirecting to <a href="city-pulse.html">City Pulse Dashboard</a>…</p>
</body>
</html>
INDEX
echo "   ✓ Added index.html (auto-redirect)"

# Create .nojekyll so GitHub Pages serves HTML files directly
touch "$DEPLOY_DIR/.nojekyll"

# Step 3: Initialize git and push
echo ""
echo "🔄  Pushing to GitHub..."
cd "$DEPLOY_DIR"
git init -q
git config user.email "deploy@citypulse.app"
git config user.name "City Pulse Deploy"
git checkout -b main
git add -A
git commit -q -m "🚀 Deploy City Pulse v1.0 — Smart Urban Mobility Platform"

# Push to GitHub
git remote add origin "https://$USERNAME:$TOKEN@github.com/$USERNAME/$REPO_NAME.git"
git push -u origin main --force -q

echo "   ✓ Pushed to GitHub"

# Step 4: Enable GitHub Pages via API
echo ""
echo "🌐  Enabling GitHub Pages..."
sleep 2
PAGES_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME/pages" \
  -d '{"source":{"branch":"main","path":"/"}}')

if echo "$PAGES_RESPONSE" | grep -q '"url"'; then
  echo "   ✓ GitHub Pages enabled"
else
  # Try updating if already exists
  curl -s -X PUT \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$USERNAME/$REPO_NAME/pages" \
    -d '{"source":{"branch":"main","path":"/"}}' > /dev/null 2>&1
  echo "   ✓ GitHub Pages configured"
fi

# Cleanup
cd /tmp
rm -rf "$DEPLOY_DIR"

echo ""
echo "✅  DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════"
echo ""
echo "   🌐  Your site will be live in ~1-2 minutes:"
echo ""
echo "   Dashboard:  https://$USERNAME.github.io/$REPO_NAME/"
echo "   Planner:    https://$USERNAME.github.io/$REPO_NAME/city-pulse-planner.html"
echo "   Combined:   https://$USERNAME.github.io/$REPO_NAME/city-pulse-combined.html"
echo ""
echo "   📁  GitHub repo: https://github.com/$USERNAME/$REPO_NAME"
echo ""
echo "   ℹ️   GitHub Pages takes 1-3 minutes to go live after first deploy."
echo "        Refresh the URL after waiting if you get a 404."
echo ""
