#!/bin/bash

echo ""
echo "╔════════════════════════════════════════╗"
echo "║        DYP — Deploy to GitHub          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check git is installed
if ! command -v git &> /dev/null; then
  echo "❌  Git not found. Install from https://git-scm.com and re-run."
  exit 1
fi

# Ask for GitHub username if not set
echo "Enter your GitHub username:"
read GITHUB_USER

echo "Enter your repo name (default: dyp-site):"
read REPO_NAME
REPO_NAME=${REPO_NAME:-dyp-site}

REMOTE="https://github.com/$GITHUB_USER/$REPO_NAME.git"

echo ""
echo "→ Initialising git..."
git init

echo "→ Staging all files..."
git add .

echo "→ Creating first commit..."
git commit -m "🚀 Initial DYP deployment"

echo "→ Setting branch to main..."
git branch -M main

echo "→ Adding remote: $REMOTE"
git remote remove origin 2>/dev/null
git remote add origin "$REMOTE"

echo "→ Pushing to GitHub..."
git push -u origin main

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║  ✅  Files pushed to GitHub!                       ║"
echo "║                                                    ║"
echo "║  Now go to:                                        ║"
echo "║  https://pages.cloudflare.com                      ║"
echo "║                                                    ║"
echo "║  → Workers & Pages → Create → Pages → Connect Git ║"
echo "║  → Select: $REPO_NAME"
echo "║  → Build command: (leave empty)                    ║"
echo "║  → Output directory: /                             ║"
echo "║  → Save and Deploy                                 ║"
echo "║                                                    ║"
echo "║  Your live URL will be:                            ║"
echo "║  https://$REPO_NAME.pages.dev                      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
