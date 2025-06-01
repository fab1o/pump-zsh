#!/bin/bash
# This script is used to automatically install the dependencies for Pump-zsh
# shellcheck disable=SC1091
# shellcheck disable=SC2010

set -e

echo " 🚀 Checking for dependencies..."

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo " 🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo " ✅ Homebrew already installed."
fi

# Install Oh My Zsh
if ! command -v zsh &>/dev/null; then
  echo " 🔧 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo " ✅ Oh My Zsh already installed."
fi

# Install jq
if ! command -v jq &>/dev/null; then
  echo " 🛠️ Installing JQ..."
  brew install jq
else
  echo " ✅ jq already installed."
fi

# Install gum
if ! command -v gum &>/dev/null; then
  echo " 🌿 Installing gum..."
  brew install gum
else
  echo " ✅ gum already installed."
fi

# Install glow
if ! command -v glow &>/dev/null; then
  echo " 🌿 Installing glow..."
  brew install glow
else
  echo " ✅ glow already installed."
fi

# Install GitHub CLI
if ! command -v gh &>/dev/null; then
  echo " 🐙 Installing GitHub CLI..."
  brew install gh
else
  echo " ✅ GitHub CLI already installed."
fi

echo " Successfully installed dependencies for Pump-zsh!"
echo ""
echo " Restart your terminal if anything was installed."
