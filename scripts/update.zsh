#!/bin/zsh
# This script is used to update the pump plugin for Oh My Zsh running on bash from curl

echo " updating pump-zsh..."

RELEASE_API="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
TAG=$(curl -H "Cache-Control: no-cache" -s $RELEASE_API | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$TAG" ]; then
  print " failed to fetch the latest release version, try again later"
  exit 1
fi

DOWNLOAD_URL="https://github.com/fab1o/pump-zsh/archive/refs/tags/${TAG}.zip"
if ! curl -H "Cache-Control: no-cache" -fsSL -o pump-zsh.zip "$DOWNLOAD_URL"; then
  print " failed to download the latest release, try again later"
  exit 1
fi

rm -rf temp &>/dev/null
if ! mkdir -p temp; then
  print " fatal: could not create temp directory, try running: " >&2
  print "  sudo mkdir -p temp && sudo unzip -q -o pump-zsh.zip -d temp && cd temp/pump-zsh-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh" >&2
  rm pump-zsh.zip &>/dev/null
  exit 1
fi

if ! unzip -q -o pump-zsh.zip -d temp; then
  print " failed to unzip the downloaded file, try again later"
  rm pump-zsh.zip &>/dev/null
  rm -rf temp &>/dev/null
  exit 1
fi

if ! pushd "temp/pump-zsh-$TAG" 1>/dev/null; then
  print " failed to change directory to temp/pump-zsh-$TAG, try running: " >&2
  print "  sudo unzip -q -o pump-zsh.zip -d temp && cd temp/pump-zsh-$TAG && zsh ./scripts/update.zsh && zsh ./scripts/edit_zshrc.zsh" >&2
else
  zsh ./scripts/update_configs.zsh
  zsh ./scripts/npm_update.zsh
  zsh ./scripts/check_zshrc.zsh
  
  popd 1>/dev/null || exit
fi

rm pump-zsh.zip &>/dev/null
rm -rf temp &>/dev/null
