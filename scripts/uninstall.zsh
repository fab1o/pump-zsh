#!/bin/zsh
# This script is used to uninstall pump-zsh

DEST_DIR="$HOME/.oh-my-zsh/plugins/pump"
THEMES_DIR="$HOME/.oh-my-zsh/themes"

rm -f "$THEMES_DIR/pump.zsh-theme"
rm -rf "$DEST_DIR"
