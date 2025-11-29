#!/bin/bash
#
# CORE Linux - GitHub Repository Setup
# Automatically creates and pushes to GitHub
#

set -euo pipefail

RED='\033[0;31m'
GREY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}C O R E   L I N U X   -   G I T H U B   S E T U P${NC}  ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    if command -v brew >/dev/null 2>&1; then
        brew install gh
    else
        echo -e "${RED}Error: Homebrew not found. Please install GitHub CLI manually.${NC}"
        echo "Visit: https://cli.github.com/"
        exit 1
    fi
fi

# Check if authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub authentication required..."
    gh auth login
fi

# Get repository name
REPO_NAME="${1:-core-linux-industrial}"
REPO_DESC="CORE Linux - Industrial Edition: A custom Linux distribution built for industrial applications"

echo "Creating GitHub repository: $REPO_NAME"
echo "Description: $REPO_DESC"
echo ""

# Check if remote already exists
if git remote get-url origin >/dev/null 2>&1; then
    echo "Remote 'origin' already exists:"
    git remote -v
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing remote."
        exit 0
    fi
    git remote remove origin
fi

# Create repository (private by default, add --public for public)
echo "Creating repository on GitHub..."
gh repo create "$REPO_NAME" \
    --description "$REPO_DESC" \
    --private \
    --source=. \
    --remote=origin \
    --push || {
    echo -e "${RED}Error: Failed to create repository${NC}"
    echo "Trying to add existing remote..."
    gh repo view "$REPO_NAME" >/dev/null 2>&1 && {
        git remote add origin "https://github.com/$(gh api user --jq .login)/$REPO_NAME.git" || true
    }
}

# Push to GitHub
echo ""
echo "Pushing to GitHub..."
git push -u origin master || git push -u origin main

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREY}GitHub Setup Complete!${NC}                          ${RED}║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Repository URL:"
gh repo view --web 2>/dev/null || echo "  https://github.com/$(gh api user --jq .login)/$REPO_NAME"
echo ""

