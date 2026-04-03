#!/bin/bash
set -e

# ===== CONFIG =====
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI ('gh') is not installed."
  echo "Install it with: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

GITHUB_USER=$(gh api user --jq .login)
REPO_NAME=$(basename "$PWD")
COMMIT_MESSAGE="Going live"

echo "🚀 Deploying '$REPO_NAME' to GitHub Pages..."

# ===== INIT REPO IF NEEDED =====
if [ ! -d ".git" ]; then
  git init -b main
fi

git branch -M main

# ===== PREPARE DOCS FOLDER =====
mkdir -p docs

# Copy ALL relevant files
cp *.html docs/ 2>/dev/null || true
cp *.css docs/ 2>/dev/null || true
cp *.js docs/ 2>/dev/null || true

# Copy assets folder if exists
if [ -d "assets" ]; then
  rsync -av assets/ docs/assets/ >/dev/null 2>&1
fi

# ===== COMMIT LOCAL CHANGES =====
git add .

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "📝 Creating initial commit..."
  git commit -m "$COMMIT_MESSAGE"
elif ! git diff --cached --quiet; then
  echo "📝 Committing latest changes..."
  git commit -m "$COMMIT_MESSAGE"
else
  echo "📝 No local changes to commit."
fi

# ===== CREATE REPO IF IT DOESN'T EXIST =====
if ! gh repo view "$GITHUB_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "📦 Creating GitHub repo..."
  gh repo create "$REPO_NAME" --public --source=. --remote=origin
else
  echo "🔗 Repo already exists, linking..."
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
fi

# ===== PUSH =====
git push -u origin main

# ===== ENABLE GITHUB PAGES =====
echo "🌐 Enabling GitHub Pages..."
gh api \
  -X POST \
  "repos/$GITHUB_USER/$REPO_NAME/pages" \
  -f source[branch]=main \
  -f source[path]="/docs" >/dev/null 2>&1 || true

# ===== OUTPUT URL =====
URL="https://$GITHUB_USER.github.io/$REPO_NAME/"

echo ""
echo "✅ Live URL:"
echo "$URL"
echo ""
echo "⚠️ First deploy can take ~10–30 seconds to go live."
