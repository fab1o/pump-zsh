#!/bin/zsh
# This script is used to install the pump plugin for Oh My Zsh for the 1st time

print " installing pump-zsh..."

if ! command -v jq &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install jq
  else
    print ""
    print " please install jq:"
    print "  https://jqlang.org/"
  fi
fi

if ! command -v gum &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install gum
  else
    print ""
    print " please install gum:"
    print "  https://github.com/charmbracelet/gum/"
  fi
fi

if ! command -v glow &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install glow
  else
    print ""
    print " please install glow:"
    print "  https://github.com/charmbracelet/glow/"
  fi
fi

if ! command -v gh &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install gh
  else
    print ""
    print " please install gh:"
    print "  https://cli.github.com/"
  fi
fi

print " done installing dependencies, now installing pump..."

RELEASE_API="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
TAG=$(curl -H "Cache-Control: no-cache" -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$TAG" ]; then
  print " failed to fetch the latest release version, try again later" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/fab1o/pump-zsh/archive/refs/tags/${TAG}.zip"
if ! curl -H "Cache-Control: no-cache" -fsSL -o pump-zsh.zip "$DOWNLOAD_URL"; then
  print " failed to download the latest release, try again later" >&2
  exit 1
fi

rm -rf temp
mkdir -p temp

if ! unzip -q -o pump-zsh.zip -d temp; then
  print " failed to unzip the downloaded file, try again later" >&2
  rm pump-zsh.zip
  rm -rf temp
  exit 1
fi

rm pump-zsh.zip

if ! pushd "temp/pump-zsh-$TAG" 1>/dev/null; then
  print " failed to change directory to temp/pump-zsh-$TAG, try running: " >&2
  print "  sudo unzip -q -o pump-zsh.zip -d temp && cd temp/pump-zsh-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh" >&2
else
  zsh ./scripts/npm_update.zsh
  zsh ./scripts/update_configs.zsh
  zsh ./scripts/edit_zshrc.zsh
  zsh ./scripts/check_zshrc.zsh
  
  popd 1>/dev/null || exit
fi

rm -rf temp >/dev/null
