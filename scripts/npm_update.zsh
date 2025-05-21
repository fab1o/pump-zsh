#!/bin/zsh
# This script is used to update the pump-zsh plugin using npm

set -e

SRC_DIR="./lib"
DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"

mkdir -p "$DEST_DIR"
cp -Rf $SRC_DIR/pump.omp.json "$DEST_DIR"
cp -Rf $SRC_DIR/pump.plugin.zsh "$DEST_DIR"
cp -Rf README.md "$DEST_DIR"

# jq require brew install jq
# VERSION=$(jq -r '.version' package.json)
VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
echo "$VERSION" > "$DEST_DIR"/.version

print " pump in version $VERSION!"
