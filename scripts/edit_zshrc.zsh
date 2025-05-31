#!/bin/zsh
# This script is used to edit the .zshrc file to add the pump plugin and its config

set -e

zshrc_file="$HOME/.zshrc"

if [[ ! -f "$zshrc_file" ]]; then
  print " error: '$zshrc_file' file not found, did not configure zsh to use pump" >&2
  exit 1;
fi

# update theme
# if ! grep -q 'pump.omp.json' "$zshrc_file"; then
#   if [[ "$(uname)" != "Darwin" ]]; then
# CONFIG_SNIPPET=$(cat << 'EOF'
# # pump-zsh config
# eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"
# # pump-zsh config
# EOF
# )
#   else
# CONFIG_SNIPPET=$(cat << 'EOF'
# # pump-zsh config
# if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
#   eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"
# fi
# # pump-zsh config
# EOF
# )
#   fi
#   echo "$CONFIG_SNIPPET" >> "$zshrc_file"
#   echo " updated '$zshrc_file' with pump-zsh"
# fi

found_pump_plugin=0
plugins_line=$(grep -E '\s*plugins=\(.*\)' "$zshrc_file")

if [[ -n "$plugins_line" ]]; then
  # Extract the content between the parentheses using parameter expansion safely
  plugins_contents=${plugins_line##*\(}
  plugins_contents=${plugins_contents%\)*}

  # Convert the content into an array (respects Zsh word splitting)
  plugins_array=(${(z)plugins_contents})

  # Check if "pump" is in the array
  for plugin in "${plugins_array[@]}"; do
    if [[ "$plugin" == "pump" ]]; then
      found_pump_plugin=1
    fi
  done
fi

if [[ $found_pump_plugin -eq 0 ]]; then
  tmp_file="$(mktemp "${zshrc_file}.XXXX")" || exit 1

  if sed -E 's/^[[:space:]]*#?[[:space:]]*plugins=\(([^)]*)\)/plugins=(\1 pump)/' "$zshrc_file" > "$tmp_file"; then
    mv "$tmp_file" "$zshrc_file"
  else
    print " error: failed to update $zshrc_file" >&2
    rm -f "$tmp_file"
    exit 1
  fi

  print " added pump to your plugins=(...)"
fi

if ! grep -q '^ZSH_THEME="pump"$' "$zshrc_file"; then

  read -qs "?"$'\e[38;5;99m'confirm:$'\e[0m'" update theme to pump? (y/n) "
  if [[ $REPLY == [yY] ]]; then
    print "y"
  elif [[ $REPLY == [nN] ]]; then
    print "n"
    exit 0;
  fi

  if grep -q '^ZSH_THEME=' "$zshrc_file"; then
    # If ZSH_THEME is found, update it to ZSH_THEME="pump"
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS (BSD sed) requires correct handling of patterns
      sed -i '' 's/^ZSH_THEME=.*$/ZSH_THEME="pump"/' "$zshrc_file"
    else
      # Linux (GNU sed)
      sed -i 's/^ZSH_THEME=.*$/ZSH_THEME="pump"/' "$zshrc_file"
    fi
  else
    # If ZSH_THEME is not found, append it to the file
    echo 'ZSH_THEME="pump"' >> "$zshrc_file"
  fi
fi
