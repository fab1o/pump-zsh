#!/bin/zsh
# This script is used to update the pump-zsh plugin using npm

set -e

SRC_DIR="./lib"
DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"

mkdir -p "$DEST_DIR"
cp -Rf $SRC_DIR/pump.omp.json "$DEST_DIR/pump.omp.json"
cp -Rf $SRC_DIR/pump.plugin.zsh "$DEST_DIR/pump.plugin.zsh"

# jq require brew install jq
# VERSION=$(jq -r '.version' package.json)
VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
echo "$VERSION" > "$DEST_DIR"/.version

# DEST_DIR_CONFIG="$HOME/.oh-my-zsh/plugins/pump/config"
# DEST_CONFIG="$DEST_DIR_CONFIG/pump.zshenv"
# SRC_CONFIG="./config/pump.zshenv"

# if [ ! -f "$DEST_CONFIG" ]; then
#   mkdir -p "$DEST_DIR_CONFIG"
#   cp "$SRC_CONFIG" "$DEST_CONFIG"
# fi

print " pump in version $VERSION!"
