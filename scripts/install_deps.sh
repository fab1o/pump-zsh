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

  echo ""
  echo " Follow Homebrew's suggestions after installation!"
else
  echo " ✅ Homebrew already installed."
fi
echo ""
# Install Oh My Zsh
if ! command -v zsh &>/dev/null; then
  echo " 🔧 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo " ✅ Oh My Zsh already installed."
fi
echo ""
# Install jq
if ! command -v jq &>/dev/null; then
  echo " 🛠️ Installing JQ..."
  brew install jq
else
  echo " ✅ jq already installed."
fi
echo ""
# Install gum
if ! command -v gum &>/dev/null; then
  echo " 🌿 Installing gum..."
  curl -L https://github.com/charmbracelet/gum/releases/download/v0.16.2/gum_0.16.2_Darwin_arm64.tar.gz -o gum.tar.gz
  tar -xzf gum.tar.gz
  sudo mv gum_0.16.2_Darwin_arm64/gum /usr/local/bin/
  rm -rf gum_0.16.2_Darwin_arm64
  rm -rf gum.tar.gz
  # alternatively, if you have Homebrew installed, you can run:
  # brew install gum
else
  echo " ✅ gum already installed."
fi
echo ""
# Install glow
if ! command -v glow &>/dev/null; then
  echo " 🌿 Installing glow..."
  brew install glow
else
  echo " ✅ glow already installed."
fi
echo ""
# Install GitHub CLI
if ! command -v gh &>/dev/null; then
  echo " 🐙 Installing GitHub CLI..."
  brew install gh
else
  echo " ✅ GitHub CLI already installed."
fi
echo ""
echo " Successfully installed dependencies for Pump-zsh!"
echo ""
echo " Restart your terminal if anything was installed."
