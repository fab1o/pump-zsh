#!/bin/zsh

zshrc_file="$HOME/.zshrc"

if [ ! -f "$zshrc_file" ] || ! grep -q '^plugins=' "$zshrc_file"; then
  print " plugins not found in your '$zshrc_file' file, please add it manually:" >&2
  print "" >&2
  print "  plugins=(pump)" >&2
  print "" >&2
  print " or run: omz plugin load pump" >&2
  print "" >&2
  print " also, make sure the snippet below is at the bottom of your '$zshrc_file' file:" >&2
  print "" >&2
  print "# pump-zsh config" >&2

  if [[ "$(uname)" == "Darwin" ]]; then
    print 'if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then"' >&2
  fi
  print '  eval "$(oh-my-posh init zsh --config $ZSH/plugins/pump/pump.omp.json)"' >&2
  if [[ "$(uname)" == "Darwin" ]]; then
    print "fi" >&2
  fi
  print "# pump-zsh config" >&2
  print "" >&2

  exit 1
fi
