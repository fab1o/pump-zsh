#!/bin/zsh
# This script is used to update the pump-zsh plugin using npm

# set -e # exit immediately if any command returns a non-zero (error) status

SRC_DIR="./lib"
THEMES_SRC_DIR="./lib/themes"
DEST_DIR="$ZSH/custom/plugins/pump"
DEST_THEMES_DIR="$ZSH/custom/themes"

if [[ -d "$DEST_THEMES_DIR" ]]; then
  rm -rf $DEST_THEMES_DIR/pump*.zsh-theme &>/dev/null
fi
if [[ -d "$DEST_DIR" ]]; then
  rm -rf $DEST_DIR/*.omp.json &>/dev/null
fi

if ! mkdir -p "$DEST_DIR"; then
  print " fatal: could not create destination directory $DEST_DIR" >&2
  exit 1
fi

if ! cp -Rf $THEMES_SRC_DIR/*.zsh-theme "$DEST_THEMES_DIR"; then
  print " warning: could not copy themes to $DEST_THEMES_DIR" >&2
fi

if ! cp -Rf $THEMES_SRC_DIR/*.omp.json "$DEST_DIR"; then
  print " warning: could not copy omp.json themes to $DEST_DIR" >&2
fi

if ! cp -Rf $SRC_DIR/pump.plugin.zsh "$DEST_DIR"; then
  print " warning: could not copy pump.plugin.zsh to $DEST_DIR" >&2
fi

cp -Rf README.md "$DEST_DIR" &>/dev/null

# jq require brew install jq
# VERSION=$(jq -r '.version' package.json)
VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')

echo "$VERSION" > "$DEST_DIR/.version"
