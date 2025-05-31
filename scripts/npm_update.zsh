#!/bin/zsh
# This script is used to update the pump-zsh plugin using npm

set -e # exit immediately if any command returns a non-zero (error) status

SRC_DIR="./lib"
DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"
THEMES_SRC_DIR="./lib/themes"
THEMES_DIR="$HOME/.oh-my-zsh/themes"

cp -Rf $THEMES_SRC_DIR/pump.zsh-theme "$THEMES_DIR"

mkdir -p "$DEST_DIR"
cp -Rf $THEMES_SRC_DIR/pump.omp.json "$DEST_DIR"
cp -Rf $SRC_DIR/pump.plugin.zsh "$DEST_DIR"
cp -Rf README.md "$DEST_DIR"

# jq require brew install jq
# VERSION=$(jq -r '.version' package.json)
VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
echo "$VERSION" > "$DEST_DIR"/.version

print " pump in version $VERSION!"
