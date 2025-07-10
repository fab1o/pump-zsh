# regular colors
typeset -g black_cor=$'\e[0;30m'
typeset -g blue_cor=$'\e[0;34m'
typeset -g cyan_cor=$'\e[0;36m'
typeset -g green_cor=$'\e[0;32m'
typeset -g yellow_cor=$'\e[0;33m'
typeset -g magenta_cor=$'\e[0;35m'
typeset -g orange_cor=$'\e[38;5;208m'
typeset -g red_cor=$'\e[0;31m'
typeset -g white_cor=$'\e[0;37m'

# special colors
typeset -g purple_cor=$'\e[38;5;99m'
typeset -g pink_cor=$'\e[38;5;212m'
typeset -g bold_pink_cor=$'\e[1;38;5;212m'
typeset -g gray_cor=$'\e[38;5;240m'

# bold (bright) colors
typeset -g bold_black_cor=$'\e[1;30m'
typeset -g bold_red_cor=$'\e[1;31m'
typeset -g bold_green_cor=$'\e[1;32m'
typeset -g bold_yellow_cor=$'\e[1;33m'
typeset -g bold_blue_cor=$'\e[1;34m'
typeset -g bold_magenta_cor=$'\e[1;35m'
typeset -g bold_cyan_cor=$'\e[1;36m'
typeset -g bold_white_cor=$'\e[1;37m'

# high-intensity colors (90–97)
typeset -g hi_black_cor=$'\e[0;90m'
typeset -g hi_red_cor=$'\e[0;91m'
typeset -g hi_green_cor=$'\e[0;92m'
typeset -g hi_yellow_cor=$'\e[0;93m' # same as yellow_cor
typeset -g hi_blue_cor=$'\e[0;94m'
typeset -g hi_magenta_cor=$'\e[0;95m'
typeset -g hi_cyan_cor=$'\e[0;96m'
typeset -g hi_white_cor=$'\e[0;97m'
typeset -g hi_gray_cor=$'\e[38;5;244m'

# text attributes
typeset -g bold_cor=$'\e[1m'
typeset -g reset_cor=$'\e[0m'

# function colors
typeset -g script_cor=$pink_cor

typeset -g PUMP_VERSION="0.0.0"
typeset -g PUMP_VERSION_FILE="$(dirname -- "$0")/.version"
typeset -g PUMP_CONFIG_FILE="$(dirname -- "$0")/config/pump.zshenv"
typeset -g PUMP_SETTINGS_FILE="$(dirname -- "$0")/config/pump.set.zshenv"

if [[ -f "$PUMP_VERSION_FILE" ]]; then
  PUMP_VERSION=$(<"$PUMP_VERSION_FILE")
fi

function parse_flags_exclusive_() {
  if [[ -n "$4" && $4 != -* ]]; then    
    parse_flags__ "$1" "$2$3" "$3" "${@:4}"
  else
    parse_flags__ "$1" "$2" "$3" "${@:4}"
  fi
}

function parse_no_flags_() {
  parse_flags__ "$1" "" "" "${@:2}"
}

function parse_flags_() {
  parse_flags__ "$1" "$2$3" "$3" "${@:4}"
}

function parse_flags__() {
  set +x

  if [[ -z "$1" ]]; then
    print " ${red_cor}internal error: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags="h$2"
  local valid_flags_pass_along="$3"

  shift 3

  typeset -g invalid_opts is_debug is_invalid
  local internal_func=0

  if [[ "$prefix" =~ _$ ]]; then
    internal_func=1
  else
    invalid_opts=()
    prefix="${prefix}_"
  fi

  local double_flags=()
  local flags=()
  local non_flags=()
  local flags_double_dash=()

  echo "${prefix}is_debug=0"

  if (( is_debug )); then
    echo "is_debug=1"
    echo "${prefix}is_debug=1"
  fi

  local opt=""
  for opt in {a..z}; do
    echo "${prefix}is_$opt=0"
    echo "${prefix}is_$opt_$opt=0"
  done

  # getopts is not ideal because it doesn't support flags after the arguments, only before them
  # example: `mycommand arg1 arg2 -a -b` does not work with getopts
  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"

      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        echo "${prefix}is_$opt=1"

        # check if $opt exists in double_flags
        if [[ " ${double_flags[@]} " =~ " $opt " ]]; then
          echo "${prefix}is_${opt}_${opt}=1"
        fi

        double_flags+=("$opt")

        if [[ $valid_flags != *$opt* ]]; then
          flags+=("-$opt")

          if [[ ! " ${invalid_opts[@]} " =~ " $opt " ]]; then
            invalid_opts+=("-$opt")
            echo "invalid_option+=(\"-$opt\")"
            if (( ! internal_func || ! is_invalid )); then
              print "  ${red_cor}fatal: invalid option: $opt${reset_cor}" >&2
              print "  --" >&2
              echo "is_invalid=1"
            else
              echo "is_invalid=0"
            fi
          fi

          echo "${prefix}is_h=1"
        elif [[ $valid_flags_pass_along == *$opt* ]]; then
          flags+=("-$opt")
        fi
      done
    elif [[ "$arg" == --* ]]; then
      if [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}is_debug=1"
      else
        flags_double_dash+=("$arg")
      fi
    else
      non_flags+=("$arg")
    fi
  done

  if [[ ${#non_flags} -gt 0 ]]; then
    print -r -- "set -- ${(q)non_flags[@]} ${(q)flags[@]} ${(q)flags_double_dash[@]}"
  else
    print -r -- "set -- ${(q)flags[@]} ${(q)flags_double_dash[@]}"
  fi
}

function parse_single_flags_() {
  set +x

  if [[ -z "$1" ]]; then
    print " ${red_cor}internal error: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags=""

  if [[ -n "$2" ]]; then
    valid_flags="h$2"
  fi

  shift 2

  typeset -g is_debug


  if [[ ! "$prefix" =~ _$ ]]; then
    prefix="${prefix}_"
  fi

  local non_flags=()

  echo "${prefix}is_debug=0"

  if (( is_debug )); then
    echo "is_debug=1"
    echo "${prefix}is_debug=1"
  fi

  local opt=""
  for opt in {a..z}; do
    echo "${prefix}is_$opt=0"
  done

  # getopts is not ideal because it doesn't support flags after the arguments, only before them
  # example: `mycommand arg1 arg2 -a -b` does not work with getopts
  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == -[a-zA-Z] ]]; then
      local opt="${arg#-}"

      echo "${prefix}is_$opt=1"

      if [[ -n "$valid_flags" ]]; then
        if [[ $valid_flags != *$opt* ]]; then
          print "  ${red_cor}fatal: invalid option: -$opt${reset_cor}" >&2
          print "  --" >&2
          echo "${prefix}is_h=1"
        fi
      else
        non_flags+=("$arg")
      fi
    elif [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}is_debug=1"
    else
      non_flags+=("$arg")
    fi
  done

  print -r -- "set -- ${(q)non_flags[@]}"
}

function clear_last_line_1_() {
  print -n "\033[1A\033[2K" >&1
}

function clear_last_line_2_() {
  print -n "\033[1A\033[2K" >&2
}

function clear_last_line_tty_() {
  print -n "\033[1A\033[2K" 2>/dev/tty
}

function confirm_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( confirm_is_debug )) && set -x

  local question="$1"
  local option1="${2-yes}"
  local option2="${3-no}"
  local default="$4"

  local opt1="${option1[1]}"
  local opt2="${option2[1]}"

  local RET=0

  if command -v gum &>/dev/null; then
    local flags=()

    if (( confirm_is_a )); then
      flags+=("--timeout=3s")
      flags+=("--default=$option1")
    else
      if [[ -n "$default" && "$default" == "$option2" ]]; then
        flags+=("--default=no")
      fi
    fi

    # VERY IMPORTANT: 2>/dev/tty to display on VSCode Terminal and on refresh
    gum confirm "confirm:${reset_cor} $question" \
      --no-show-help \
      --affirmative="$option1" \
      ${flags[@]} \
      --negative="$option2" 2>/dev/tty
    RET=$?
    # print "RET $RET" >&2
    if (( RET == 130 || RET == 2 || RET == 124 )); then return 130; fi

    return $RET;
  fi

  while true; do
    echo -n " ${purple_cor}confirm:${reset_cor} $question [${opt1:l}/${opt2:l}]: "
    stty -echo       # turn off input echo
    read -k 1 mode   # read one character
    stty echo  
    echo ""
    case "${mode:l}" in
      ${opt1:l}|${opt2:l}) break ;;
      *) clear_last_line_1_ ;;
    esac
  done

  clear_last_line_1_

  if [[ "${mode:l}" == "${opt1:l}" ]]; then
    return 0
  fi
  
  if [[ "${mode:l}" == "${opt2:l}" ]]; then
    return 1
  fi

  return 130;
}

function update_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( update_is_debug )) && set -x

  local release_tag="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
  local latest_version=$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest_version" && "$PUMP_VERSION" != "$latest_version" ]]; then
    print " new version available for pump-zsh: ${magenta_cor}${PUMP_VERSION}${reset_cor} -> ${purple_cor}${latest_version}${reset_cor}"
    
    if (( ! update_is_f )); then
      if ! confirm_ "install new version?" "install" "do nothing"; then
        return 0;
      fi
    fi
    # print " if you encounter an error after installation, don't worry — simply restart your terminal"
    if command -v gum &>/dev/null; then
      gum spin --title="updating pump-zsh..." -- \
        zsh -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/update.zsh)"
    else
      print " updating pump-zsh..."
      zsh -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/update.zsh)"
    fi

    PUMP_VERSION=$(<"$PUMP_VERSION_FILE")
    print " pump version: ${purple_cor}${PUMP_VERSION}${reset_cor}"
    zsh

    return 0;
  else
    if (( update_is_f )); then
      print " no update available for pump-zsh: ${purple_cor}${PUMP_VERSION}${reset_cor}"
    fi
  fi
}

update_

function input_from_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-255}"
  local value="$4"

  local _input=""

  # >&2 needs to display because this is called from a subshell
  print " ${purple_cor}$header:${reset_cor}" >&2

  if command -v gum &>/dev/null; then
    _input=$(gum input --placeholder="$placeholder" --char-limit="$max" --value="$value")
    if (( $? == 130 )); then return 130; fi
  else
    trap 'print ""; return 130' INT # for some reason it returns 2
    stty -echoctl
    read "?> " _input
    stty echoctl
    trap - INT
  fi

  _input=$(printf '%s' "$_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  clear_last_line_2_

  if [[ -n "$_input" ]]; then
    echo "$_input"
    return 0;
  fi

  return 1;
}

function filter_one_() {
  local header="$1"

  if command -v gum &>/dev/null; then
    print " ${purple_cor}choose $header: ${reset_cor}" >&2
    
    local choice=""
    choice="$(gum filter --height="20" --limit=1 --indicator=">" --placeholder=" type to filter" -- ${@:2})"
    local RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    clear_last_line_2_

    echo "$choice"
    return 0;
  fi

  choose_one_ $@
}

function choose_one_() {
  set +x
  eval "$(parse_flags_ "$0" "i" "" "$@")"
  (( choose_one_is_debug )) && set -x

  local header="$1"

  if command -v gum &>/dev/null; then
    local choice=""
    
    if (( choose_one_is_i )); then # immediate return if only one option
      choice="$(gum choose --select-if-one --height="20" --limit=1 --header=" choose $header:${reset_cor}" -- ${@:2} 2>/dev/tty)"
    else
      choice="$(gum choose --height="20" --limit=1 --header=" choose $header:${reset_cor}" -- ${@:2} 2>/dev/tty)"
    fi
    local RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choice"
    return 0;
  fi
  
  trap 'print ""; return 130' INT # for some reason it returns 2

  PS3="${purple_cor}choose $header: ${reset_cor}"

  select choice in "${@:2}" "quit"; do
    case $choice in
      "quit")
        return 1;
        ;;
      *)
        echo "$choice"
        return 0;
        ;;
    esac
  done

  trap - INT
}

function choose_multiple_() {
  set +x
  eval "$(parse_flags_ "$0" "i" "" "$@")"
  (( choose_multiple_is_debug )) && set -x

  local header="$1"

  local choices

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_multiple_is_i )); then # immediate return if only one option
      choices="$(gum choose --select-if-one --height="20" --limit=1 --header=" choose multiple $header ${purple_cor}(use spacebar to select)${purple_cor}:${reset_cor}" -- ${@:2})"
    else
      choices="$(gum choose --height="20" --no-limit --header=" choose multiple $header ${purple_cor}(use spacebar to select)${purple_cor}:${reset_cor}" -- ${@:2})"
    fi
    local RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choices"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  choices=()
  PS3="${purple_cor}choose multiple $header, then choose \"done\" to finish ${choices[*]}${reset_cor}"

  select choice in "${@:2}" "done"; do
    case $choice in
      "done")
        echo "${choices[@]}"
        return 0;
        ;;
      *)
        choices+=("$choice")
        # clear_last_line_1_
        # clear_last_line_2_
        print "${choices[*]}" >&2
        ;;
    esac
  done

  trap - INT
}

function check_settings_file_() {
  local settings_dir="$(dirname -- "$PUMP_SETTINGS_FILE")"
  local settings_name="$(basename -- "$PUMP_SETTINGS_FILE")"

  if [[ ! -d "$settings_dir" ]]; then
    mkdir -p -- "$settings_dir"
  fi

  if [[ ! -f "$PUMP_SETTINGS_FILE" ]]; then
    touch "$PUMP_SETTINGS_FILE"
    # give read & write permissions to the user, read permissions to the group and others
    chmod 644 "$PUMP_SETTINGS_FILE"
  fi
}

function check_config_file_() {
  local config_dir="$(dirname -- "$PUMP_CONFIG_FILE")"
  local config_name="$(basename -- "$PUMP_CONFIG_FILE")"

  if [[ ! -d "$config_dir" ]]; then
    mkdir -p -- "$config_dir"
  fi

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    touch "$PUMP_CONFIG_FILE"
    chmod 644 "$PUMP_CONFIG_FILE"
  fi
}

function update_config_short_name_() {
  local i="$1"
  local key="$2"
  local value="$3"

  # set and unset proj_handler function
  if [[ "$key" == "PUMP_SHORT_NAME" ]]; then
    if (( i > 0 )); then
      if [[ "$value" == "${PUMP_SHORT_NAME[$i]}" ]]; then
        return 0; # no change
      fi

      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        unset -f "${PUMP_SHORT_NAME[$i]}" &>/dev/null
      fi
    else
      if [[ "$value" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
        return 0; # no change
      fi

      if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
        unset -f "$CURRENT_PUMP_SHORT_NAME" &>/dev/null
      fi
    fi
    functions[$value]="proj_handler $i \"\$@\";"
  fi
}

function update_file_() {
  local key="$1"
  local value="$2"
  local file="$3"

  value=$(echo $value | xargs 2>/dev/null)
  if [[ -z "$value" ]]; then value=$(echo $value | xargs -0 2>/dev/null); fi

  if grep -q "^${key}=" "$file"; then
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS (BSD sed) requires correct handling of patterns
      sed -i '' "s|^$key=.*|$key=$value|" "$file"
    else
      # Linux (GNU sed)
      sed -i "s|^$key=.*|$key=$value|" "$file"
    fi
  else
    echo "$key=$value" >> "$file"
  fi

  if (( $? != 0 )); then
    print "  ${hi_yellow_cor}warning: failed to update ${key} in file${reset_cor}" >&2
    print "   • check if you have write permissions to: $file" >&2
    print "   • re-install pump-zsh" >&2
  else
    print " ${gray_cor}updated: ${key}=${value}${reset_cor}"
  fi
}

function update_setting_() {
  if ! check_settings_file_; then
    print " ${red_cor}fatal: settings file is invalid, cannot update config: $PUMP_SETTINGS_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local key="$1"
  local value="$2"
  local disclaimer="${3:1}"

  update_file_ "$key" "$value" "$PUMP_SETTINGS_FILE"

  eval "${key}=\"$value\""

  if (( disclaimer )) && [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print " ${gray_cor}run ${hi_gray_cor}${CURRENT_PUMP_SHORT_NAME} -u${reset_cor}${gray_cor} to reset settings${reset_cor}"
  fi

}

function update_config_() {
  if ! check_config_file_; then
    print " ${red_cor}fatal: config file is invalid, cannot update config: $PUMP_CONFIG_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local i="$1"
  local key="$2"
  local value="$3"

  value=$(echo $value | xargs 2>/dev/null)
  if [[ -z "$value" ]]; then value=$(echo $value | xargs -0 2>/dev/null); fi

  if [[ "$key" == "PUMP_SHORT_NAME" ]]; then
    update_config_short_name_ $i "$key" "$value"
  fi

  if (( i == 0 )); then
    return 0;
  fi

  # set the key variable
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" && -n "${PUMP_SHORT_NAME[$i]}" && "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
    if [[ -z "$value" ]]; then
      eval "CURRENT_${key}=\${${key}[0]}"
    else
      eval "CURRENT_${key}=\"$value\""
    fi
  fi

  eval "${key}[$i]=\"$value\""

  # set the config file
  local key_i="${key}_${i}"

  update_file_ "$key_i" "$value" "$PUMP_CONFIG_FILE" ${@:4}

  if (( disclaimer )) && [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
    print " ${gray_cor}run ${hi_gray_cor}${PUMP_SHORT_NAME[$i]} -u${reset_cor}${gray_cor} to reset config${reset_cor}"
  fi
}

function input_branch_name_() {
  local header="$1"
  local placeholder="$2"
  local git_proj_folder="$3"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder" 199)
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -n "$typed_value" ]] && git -C "$git_proj_folder" check-ref-format --branch "$typed_value" &>/dev/null; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function input_text_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-255}"
  local value="$4"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder" "$max" "$value")
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -z "$typed_value" && -n "$placeholder" ]] && command -v gum &>/dev/null; then
      typed_value="$placeholder"
    fi

    if [[ -n "$typed_value" ]]; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function input_number_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-3}"
  local value="$4"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder" "$max" "$value")
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -z "$typed_value" && -n "$placeholder" ]] && command -v gum &>/dev/null; then
      typed_value="$placeholder"
    fi

    if [[ -n "$typed_value" && $typed_value == <-> ]]; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function find_proj_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "e" "" "$@")"
  (( find_proj_folder_is_debug )) && set -x

  local i="$1"
  local header="$2"
  local folder_name="$3"

  ######################################################
  # VERY IMPORTANT: Cannot use 'path' as variable name
  #####################################################
  local folder_path="" 

  if ! command -v gum &>/dev/null; then
    folder_path=$(input_path_ "type the folder path")
    if (( $? != 0 )); then return 1; fi

    echo "$folder_path"
    return 0;
  fi

  # >&2 needs to display because this is called from a subshell
  # print " ${header}:" >&2
  print " ${purple_cor}${header}:${reset_cor}" >&2
  print "" >&2

  add-zsh-hook -d chpwd pump_chpwd_
  cd "${HOME:-/}" # start from home

  local RET=0
  local chosen_folder=""

  while true; do
    if [[ -n "$folder_path" ]]; then
      local new_folder=""

      if (( find_proj_folder_is_e )); then
        new_folder="$folder_path"
      else
        new_folder="${folder_path}/${folder_name}"
      fi

      local new_folder_a="${new_folder:A}"

      if [[ ! -d "$folder_path" ]]; then
        print "  ${red_cor}not a folder, please select a folder${reset_cor}" >&2
        cd "$HOME"
      else
        if (( find_proj_folder_is_e )); then
          if is_folder_pkg_ "$new_folder_a" &>/dev/null || is_folder_git_ "$new_folder_a" &>/dev/null; then
            RET=0
          else
            RET=1
          fi
        else
          confirm_ "set project folder to: ${blue_cor}${new_folder_a}${reset_cor} or continue to browse further?" "set folder" "browse"
          RET=$?
        fi
        
        if (( RET == 130 || RET == 2 )); then return 130; fi

        if (( RET == 1 )); then
          cd "$folder_path"
        else

          local j=0 found=0
          for j in {1..10}; do
            if [[ $j -ne $i && -n "$PUMP_FOLDER[$j]" && -n "${PUMP_SHORT_NAME[$j]}" ]]; then
              local folder_a="${PUMP_FOLDER[$j]:A}"

              if [[ "$new_folder_a" == "$folder_a" ]]; then
                found=$j
                print "  ${hi_yellow_cor}folder in use by another project, select another folder${reset_cor}" >&2
                cd "$HOME"
              fi
            fi
          done

          if (( found == 0 )); then
            chosen_folder="$folder_path"
            break;
          fi
        fi
      fi
    fi
    
    if [[ -z "$(get_folders_ "$proj_folder")" ]]; then
      cd "${HOME:-/}"
    fi

    local chose_folder=""
    chose_folder="$(gum file --directory --height 14)"
    RET=$?
    if (( RET == 130 || RET == 2 )); then break; fi

    if [[ -n "$chose_folder" ]]; then
      folder_path="$chose_folder"
    else
      break;
    fi
  done

  add-zsh-hook chpwd pump_chpwd_

  if [[ -n "$chosen_folder" ]]; then
    clear_last_line_2_
    clear_last_line_2_
    echo "$chosen_folder"
    return 0;
  fi


  clear_last_line_2_
  clear_last_line_2_
  return 1;
}

function input_path_() {
  local header="$1"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$typed_value" ]]; then
      typed_value="${typed_value:A}" # convert to absolute path

      if [[ "$typed_value" =~ ^[a-zA-Z0-9/,_.-]+$ ]]; then
        echo "$typed_value"
        break;
      fi
    fi
  done
}

function validate_repo_() {
  local repo="$1"

  if [[ "$repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
    return 0;
  fi

  print "  repository must be a valid ssh or https uri" >&2
  return 1;
}

function find_repo_() {
  local header="$1"
  local placeholder="$2"

  if command -v gh &>/dev/null; then
    ############################################
    # VERY IMPORTANT to display the prompt: >&2
    ############################################
    confirm_ "is there a git repository for this project somewhere?"
    local RET=$?
    if (( RET == 1 )); then return 1; fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      local gh_owner=""
      gh_owner=$(input_from_ "type the Github owner account (username or organization) skip if not on Github" "" 50)
      # if (( $? == 130 || $? == 2 )); then return 130; fi
      if [[ -n "$gh_owner" ]]; then
        local list_repos=$(gh repo list $gh_owner --limit 100 --json nameWithOwner -q '.[].nameWithOwner' | sort -f 2>/dev/null)
        local repos=("${(@f)list_repos}")
        
        if (( $? == 0 && ${#repos[@]} > 1 )); then
          local selected_repo=""
          selected_repo=$(choose_one_ "repository" "${repos[@]}")
          # if (( $? != 0 )); then return 1; fi
          if [[ -n "$selected_repo" ]]; then            
            confirm_ "ssh or https?" "ssh" "https"
            RET=$?
            # if (( $? == 130 || $? == 2 )); then return 130; fi
            if (( RET == 0 )); then
              echo "git@github.com:${selected_repo}.git"
              return 0;
            elif (( RET == 1 )); then
              echo "https://github.com/${selected_repo}.git"
              return 0;
            fi
          fi
        else
          print "  no repositories found for: $gh_owner" >&2
        fi
      fi
    fi
  fi

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder")
    if (( $? != 0 )); then return 1; fi
    
    if [[ -z "$typed_value" ]]; then
      if [[ -n "$placeholder" ]] && command -v gum &>/dev/null; then
        typed_value="$placeholder"
      fi
    fi

    if [[ -n "$typed_value" ]]; then
      if validate_repo_ "$typed_value"; then
        echo "$typed_value"
        return 0;
      else
      fi
    else
      # it's okay if repository is left empty because the project may not have a git repository yet
      echo "$typed_value"
      return 0;
    fi
  done

  # return 1;
}

function pause_output_() {
  printf ""
  stty -echo

  IFS= read -r -k1 input

  if [[ $input == $'\e' ]]; then
      # read the rest of the escape sequence (e.g. for arrow keys)
      IFS= read -r -k2 rest
      input+="$rest"
      
      # discard any remaining junk from the input buffer
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  elif [[ $input != $'\n' ]]; then
      # discard remaining characters if non-enter, non-escape key
      while IFS= read -r -t 0.01 -k1 junk; do :; done
  fi

  stty echo

  # if [[ $input == "q" ]]; then
  #   clear
  #   return 0;
  # fi
}

function display_double_line_() {
  local word1="$1"
  local color="${2:-$gray_cor}"
  local word2="$3"
  local color2="${4:-$color}"
  local total_width=${5:-70}

  local total_width1=$(( total_width / 2 - 2 ))

  local padding=$(( total_width1 - 2 ))
  local word_length1=${#word1}

  local padding1=$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - 2 : word_length1 - total_width1 - 2 ) / 2 ))
  local line1="$(printf '%*s' "$padding1" '' | tr ' ' '─') $word1 $(printf '%*s' "$padding1" '' | tr ' ' '─')"

  if (( ${#line1} < total_width1 )); then
    local pad_len1=$(( total_width1 - ${#line1} ))

    padding1=$(printf '%*s' $pad_len1 '' | tr ' ' '-')
    line1="${line1}${padding1}"
  fi

  local total_width2=$(( total_width / 2 - 2 ))
  local word_length2=${#word2}

  local padding2=$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))
  local line2="$(printf '%*s' "$padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$padding2" '' | tr ' ' '─')"

  local total_lines=$( (( ${#line1} + ${#line2} )) )

  if (( total_lines < total_width )); then
    local pad_len2=$( (( total_width - total_lines )) )

    padding2=$(printf '%*s' $pad_len2 '' | tr ' ' '-')
    line2="${line2}${padding2}"
  fi

  local line="$line1 | ${color2}$line2"

  print "${color} $line ${reset_cor}" >&1
}

function display_line_() {
  local word1="$1"
  local color="${2:-$gray_cor}"
  local total_width=${3:-72}
  local word_color="${4:-$color}"

  local factor=2

  if [[ -z "$word1" ]]; then
    factor=0
  fi

  local padding=$(( total_width - factor ))
  local line="$(printf '%*s' "$padding" '' | tr ' ' '─')"

  if [[ -n "$word1" ]]; then
    local word_length1=${#word1}

    local padding1=$(( ( total_width > word_length1 ? total_width - word_length1 - factor : word_length1 - total_width - factor ) / 2 ))
    local line1="$(printf '%*s' "$padding1" '' | tr ' ' '─') ${word_color}$word1 ${color}$(printf '%*s' "$padding1" '' | tr ' ' '─')"

    local count=$(( ${#line1} - ${#color} - ${#word_color} ))
    if (( count < total_width )); then
      local pad_len1=$(( total_width - count ))
      padding1=$(printf '%*s' $pad_len1 '' | tr ' ' '-')
      line1="${line1}${padding1}"
    fi
    
    line="$line1"
  fi

  print "${color} $line ${reset_cor}" >&1
}

function sanitize_pkg_name_() {
  local pkg_name="$1"

  if [[ -z "$pkg_name" ]]; then
    echo ""
    return 0;
  fi

  # Convert to lowercase
  local sanitized="${pkg_name:l}"

  # Remove all characters before the first slash
  sanitized="${sanitized#*/}"

  # Remove all characters except lowercase letters, digits, and dashes
  sanitized="${sanitized//[^a-z0-9-]/}"

  # Remove invalid leading characters until it starts with a-z or 0-9
  while [[ -n "$sanitized" && ! "$sanitized" =~ ^[a-z0-9] ]]; do
    sanitized="${sanitized:1}"
  done

  # Remove trailing characters that aren't a-z or 0-9
  while [[ -n "$sanitized" && ! "$sanitized" =~ [a-z0-9]$ ]]; do
    sanitized="${sanitized%?}"
  done

  echo "$sanitized"
}

# data checkers =========================================================
function check_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "rfmp" "qv" "$@")"
  (( check_proj_is_debug )) && set -x
  
  local i="$1"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: check_proj_ index is invalid: $i" >&2
    return 1;
  fi

  # if (( check_proj_is_c )); then
  #   if ! check_proj_cmd_ -q $i "${PUMP_SHORT_NAME[$i]}" "${PUMP_SHORT_NAME[$i]}" ${@:2}; then return 1; fi
  # fi

  if (( check_proj_is_r )); then
    if ! check_proj_repo_ -sq $i "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_REPO[$i]}" ]]; then
      print " ${red_cor}missing repository uri for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_f )); then
    if ! check_proj_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "${PUMP_REPO[$i]}" ${@:2}; then return 1; fi

    if [[ -z "${PUMP_FOLDER[$i]}" || ! -d "${PUMP_FOLDER[$i]}" ]]; then
      if (( ! check_proj_is_q )); then
        print " ${red_cor}project folder is missing for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
        print " run ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      fi
      return 1;
    fi
  fi

  if (( check_proj_is_m )); then
    if save_proj_mode_ -q $i "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}" ${@:2}; then return 0; fi
  fi

  if (( check_proj_is_p )); then
    if ! check_proj_pkg_manager_ -q $i "${PUMP_PKG_MANAGER[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_REPO[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PKG_MANAGER[$i]}" ]]; then
      print " ${red_cor}missing package manager for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      return 1;
    fi
  fi
}

function check_proj_cmd_() {
  set +x
  eval "$(parse_flags_ "$0" "sv" "q" "$@")"
  (( check_proj_cmd_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local old_proj_cmd="$3"

  if validate_proj_cmd_strict_ $i "$proj_cmd" "$old_proj_cmd"; then
    return 0;
  fi

  if (( check_proj_cmd_is_s )); then
    if save_proj_cmd_ $i "${old_proj_cmd:-$proj_cmd}" "$old_proj_cmd" ${@:4}; then
      return 0;
    fi
  fi

  return 1;
}

function check_proj_repo_() {
  set +x
  eval "$(parse_flags_ "$0" "sv" "q" "$@")"
  (( check_proj_repo_is_debug )) && set -x

  local i="$1"
  local proj_repo="$2"
  local proj_folder="$3"
  local pkg_name="$4"

  local error_msg=""

  if [[ -z "$proj_repo" ]]; then
    if [[ -n "$pkg_name" ]]; then
      error_msg="project repository uri is missing for $pkg_name"
    else
      error_msg="project repository uri is missing"
    fi
  else
    # check for duplicates across other indices
    if ! [[ "$proj_repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
      error_msg="project repository uri is invalid: $proj_repo"
    else
      if (( check_proj_repo_is_v )); then
        if [[ -z "$PWD" || "$PWD" == "."  ]]; then cd ~; fi
        if command -v gum &>/dev/null; then
          # so that the spinner can display, add to the end: 2>/dev/tty
          gum spin --timeout=12s --title="checking repository uri..." -- git ls-remote "${proj_repo}" --quiet --exit-code 2>/dev/tty
        else
          print " checking repository uri..." >&2
          git ls-remote "${proj_repo}" --quiet --exit-code
        fi

        if (( $? != 0 )); then
          error_msg="projet repository uri is invalid or no access rights: $proj_repo"
          error_msg+="\n  - check if the uri is valid"
          error_msg+="\n  - check if you have access rights to the repository"
          error_msg+="\n  - check if the repository is private and you have set up SSH keys or access tokens"
          error_msg+="\n  - wait a moment and try again"
        fi
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    if (( ! check_proj_repo_is_q )); then
      print "  ${red_cor}${error_msg}${reset_cor}" >&2
    fi

    if (( check_proj_repo_is_s )); then
      if save_proj_repo_ $i "$proj_folder" "$pkg_name" "" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "qs" "v" "$@")"
  (( check_proj_folder_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local pkg_name="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$pkg_name" ]]; then
      error_msg="project folder is missing for $pkg_name"
    else
      error_msg="project folder is missing"
    fi
  fi

  if [[ -z "$error_msg" ]]; then
    local proj_folder_a="${proj_folder:A}"
    local real_proj_folder="$(realpath -- "$proj_folder" 2>/dev/null)"

    local j=0
    for j in {1..10}; do
      if [[ $j -ne $i && -n "$PUMP_FOLDER[$j]" && -n "${PUMP_SHORT_NAME[$j]}" ]]; then
        local pump_folder_a="${PUMP_FOLDER[$j]:A}"
        local real_pump_folder="$(realpath -- "${PUMP_FOLDER[$j]}" 2>/dev/null)"

        if [[ "$proj_folder_a" == "$pump_folder_a" ]] || [[ -n "$real_proj_folder" && "$real_proj_folder" == "$real_pump_folder" ]]; then
          error_msg="in use, please select another folder" >&2
          break;
        fi
      fi
    done
  fi

  if [[ -z "$error_msg" ]]; then
    local real_proj_folder=$(realpath -- "$proj_folder" 2>/dev/null)
    
    if [[ -z "$real_proj_folder" ]]; then
      if (( check_proj_folder_is_v )); then
        mkdir -p -- "$proj_folder" &>/dev/null
        real_proj_folder=$(realpath -- "$proj_folder" 2>/dev/null)

        if [[ -z "$real_proj_folder" ]]; then
          error_msg="project folder is invalid: $proj_folder"
        fi
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    if (( ! check_proj_folder_is_q )); then
      print "  ${red_cor}${error_msg}${reset_cor}" >&2
    fi

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ $i "$pkg_name" "$proj_repo" "" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "sv" "q" "$@")"
  (( check_proj_pkg_manager_is_debug )) && set -x

  local i="$1"
  local pkg_manager="$2"
  local proj_folder="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$pkg_manager" ]]; then
    error_msg="package manager is missing"
  else
    local valid_pkg_managers=("npm" "yarn" "pnpm" "bun")

    if ! [[ " ${valid_pkg_managers[@]} " =~ " $pkg_manager " ]]; then
      error_msg="package manager is invalid: $pkg_manager"
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print "  ${red_cor}${error_msg}${reset_cor}" >&2

    if (( check_proj_pkg_manager_is_s )); then
      if save_pkg_manager_ $i "$proj_folder" "$proj_repo" ${@:5}; then return 0; fi
    fi
    return 1;
  fi

  return 0;
}
# end of data checkers

function choose_mode_() {
  local current_mode="$1"
  local proj_folder="$2"

  if [[ -n "$proj_folder" ]]; then
    local parent_folder_name="$(basename -- "$(dirname -- "$proj_folder")")"
    parent_folder_name="${parent_folder_name[1,46]}"
    local folder_name="$(basename -- "$proj_folder")"
    folder_name="${folder_name[1,46]}"

    local multiple_title=$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 212 "multiple mode")
    local single_title=$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 99 "single mode")

    local titles=$(gum join --align=center --horizontal "$multiple_title" "$single_title")

    local multiple=$'  '/"$parent_folder_name"'
   └─ '/"$folder_name"'
      ├─ /main
      ├─ /feature-1
      └─ /feature-2'

    local single=$'  '/"$parent_folder_name"'
   └─ '/"$folder_name"'


    '

    multiple=$(gum style --align=left --margin="0" --padding="0" --border=normal --width=30 --border-foreground 212 "$multiple")
    single=$(gum style --align=left --margin="0" --padding="0" --border=normal --width=30 --border-foreground 99 "$single")

    local examples=$(gum join  --align=center --horizontal "$multiple" "$single")
    
    print "" >&2
    gum join --align=center --vertical "$titles" "$examples" >&2
  fi

  print " ${pink_cor}multiple mode:${reset_cor}" >&2
  print "  • manages branches in separate folders" >&2
  print "  • designed for engineers with extensive branching workflows" >&2
  print " ${purple_cor}single mode:${reset_cor}" >&2
  print "  • manages branches within a single folder" >&2
  print "  • ideal for small projects with a limited number of branches" >&2
  print "" >&2

  local default=""

  if [[ "$current_mode" -eq "0" ]]; then
    default="multiple"
  elif [[ "$current_mode" -eq "1" ]]; then
    default="single"
  fi

  confirm_ "manage the project as ${pink_cor}multiple${reset_cor} or ${purple_cor}single${reset_cor} mode?" "multiple" "single" "$default"
  local RET=$?

  local i=0
  if [[ -n "$proj_folder" ]]; then
    for i in {1..16}; do
      clear_last_line_2_
    done
  else
    for i in {1..7}; do
      clear_last_line_2_
    done
  fi

  if (( RET == 130 || RET == 2 )); then
    return 130;
  fi

  echo $RET
}

function get_proj_special_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "brc" "" "$@")"
  (( get_proj_special_folder_is_debug )) && set -x

  local proj_cmd="$1"
  local proj_folder="$2"
  local single_mode="$3"

  local category=""

  if (( get_proj_special_folder_is_r )); then
    category=".revs"
  elif (( get_proj_special_folder_is_b )); then
    category=".backups"
  elif (( get_proj_special_folder_is_c )); then
    category=".cov"
  else
    print "  ${red_cor}invalid category, use -b, -r or -c${reset_cor}" >&2
    return 1;
  fi

  local parent_folder="$(dirname -- "$proj_folder")"

  if (( single_mode )); then
    echo "${parent_folder}/${category}/${proj_cmd}"
  else
    echo "${parent_folder}/${category}/${proj_cmd}"
  fi
}

function get_pkg_field_online_() {
  local field="$1"
  local repo="$2"
  
  if [[ -z "$repo" ]]; then return 1; fi

  local owner_repo=""

  if [[ "$repo" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    owner_repo="${match[1]}"
  else
    return 1;
  fi

  local pkg_name=""

  if command -v gh &>/dev/null; then
    local url="repos/${owner_repo}/contents"
    local package_json=$(gh api "${url}/package.json" --jq .download_url // empty 2>/dev/null)

    if [[ -n "$package_json" ]]; then
      if command -v jq &>/dev/null; then
        pkg_name=$(curl -fs "$package_json" | jq -r --arg key "$field" '.[$key] // empty')
      else
        pkg_name=$(curl -fs "$package_json" | grep -E '"'$field'"\s*:\s*"' | head -1 | sed -E "s/.*\"$field\": *\"([^\"]+)\".*/\1/")
      fi

      if [[ -n "$pkg_name" ]]; then
        echo "$pkg_name"
        return 0;
      fi
    fi
  fi

  local urls=()
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/main")
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/master")
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/dev")

  if command -v jq &>/dev/null; then
    for url in "${urls[@]}"; do
      pkg_name=$(curl -fs "${url}/package.json" | jq -r --arg key "$field" '.[$key] // empty')
      if [[ -n "$pkg_name" ]]; then break; fi
    done
  else
    for url in "${urls[@]}"; do
      pkg_name=$(curl -fs "${url}/package.json" | grep -E '"'$field'"\s*:\s*"' | head -1 | sed -E "s/.*\"$field\": *\"([^\"]+)\".*/\1/")
      if [[ -n "$pkg_name" ]]; then break; fi
    done
  fi

  if [[ -n "$pkg_name" ]]; then
    echo "$pkg_name"
    return 0;
  fi

  return 1;
}

function detect_pkg_manager_online_() {
  local repo="$1"
  
  if [[ -z "$repo" ]]; then return 1; fi

  local owner_repo=""

  if [[ "$repo" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    owner_repo="${match[1]}"
  else
    return 1;
  fi

  local manager=""

  if command -v gh &>/dev/null; then
    local url="repos/${owner_repo}/contents"
    local package_json=$(gh api "${url}/package.json" --jq .download_url // empty 2>/dev/null)

    if [[ -n "$package_json" ]]; then
      if command -v jq &>/dev/null; then
        manager=$(curl -fs "$package_json" | jq -r '.packageManager // empty')
      else
        manager=$(curl -fs "$package_json" | grep -E '"'packageManager'"\s*:\s*"' | head -1 | sed -E "s/.*\"packageManager\": *\"([^\"]+)\".*/\1/")
      fi

      if [[ -n "$manager" ]]; then
        manager="${manager%%@*}"
        echo "$manager"
        return 0;
      fi

      if gh api "${url}/package-lock.json" --silent &>/dev/null; then
        manager="npm"
      elif gh api "${url}/yarn.lock" --silent &>/dev/null; then
        manager="yarn"
      elif gh api "${url}/pnpm-lock.yaml" --silent &>/dev/null; then
        manager="pnpm"
      elif gh api "${url}/bun.lockb" --silent &>/dev/null; then
        manager="bun"
      fi
    fi
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  local urls=()
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/main")
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/master")
  urls+=("https://raw.githubusercontent.com/${owner_repo}/refs/heads/dev")

  if command -v jq &>/dev/null; then
    for url in "${urls[@]}"; do
      manager=$(curl -fs "${url}/package.json" | jq -r '.packageManager // empty')
      if [[ -n "$manager" ]]; then
        manager="${manager%%@*}"
        break;
      fi
    done
  else
    for url in "${urls[@]}"; do
      manager=$(curl -fs "${url}/package.json" | grep -E '"'packageManager'"\s*:\s*"' | head -1 | sed -E "s/.*\"packageManager\": *\"([^\"]+)\".*/\1/")
      if [[ -n "$manager" ]]; then
        manager="${manager%%@*}"
        break;
      fi
    done
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  # 1. Lockfile-based detection (most reliable)
  for url in "${urls[@]}"; do
    if curl -fs "${url}/package-lock.json" -o /dev/null; then
      manager="npm"
    elif curl -fs "${url}/yarn.lock" -o /dev/null; then
      manager="yarn"
    elif curl -fs "${url}/pnpm-lock.yaml" -o /dev/null; then
      manager="pnpm"
    elif curl -fs "${url}/bun.lockb" -o /dev/null; then
      manager="bun"
    fi
  done

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  # local pyproject="pyproject.toml"

  # for url in "${urls[@]}"; do
  #   if curl -fs "${url}/${pyproject}" | grep -qE '^\s*\[tool\.poe\.tasks\]'; then
  #     manager="poe"
  #   fi
  # done

  # if [[ -n "$manager" ]]; then
  #   echo "$manager"
  #   return 0;
  # fi

  return 1;
}

function detect_pkg_manager_() {
  local folder="${1:-$PWD}"

  if (( ! CHPWD_SILENT )) && command -v gum &>/dev/null; then
    setopt NO_NOTIFY
    {
      gum spin --title="detecting package manager..." -- bash -c 'sleep 2'
    } 2>/dev/tty
  fi

  local manager=""

  local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json" 2>/dev/null)
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if [[ -f "${proj_folder}/package.json" ]]; then
    local line="$(get_from_pkg_json_ "packageManager" "$proj_folder")"
    
    if [[ $line =~ ([^\"]+) ]]; then
      manager="${match[1]%%@*}"
      echo "$manager"
      return 0;
    fi
  fi

  # 1. Lockfile-based detection (most reliable)
  if [[ -f "${proj_folder}/bun.lockb" ]]; then
    manager="bun"
  elif [[ -f "${proj_folder}/pnpm-lock.yaml" ]]; then
    manager="pnpm"
  elif [[ -f "${proj_folder}/yarn.lock" ]]; then
    manager="yarn"
  elif [[ -f "${proj_folder}/package-lock.json" ]]; then
    manager="npm"
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  # local pyproject_file="${proj_folder}/pyproject.toml"

  # if [[ -f "$pyproject_file" ]] && grep -qE '^\s*\[tool\.poe\.tasks\]' "$pyproject_file"; then
  #   manager="poe"
  # fi

  # if [[ -n "$manager" ]]; then
  #   echo "$manager"
  #   return 0;
  # fi

  return 1;
}

function save_proj_cmd_() {
  set +x
  eval "$(parse_flags_ "$0" "fae" "" "$@")"
  (( save_proj_cmd_is_debug )) && set -x

  local i="$1"
  local pkg_name="$2"
  local old_proj_cmd="$3"

  local typed_proj_cmd=""
  typed_proj_cmd=$(input_text_ "type your project name" "$pkg_name" 13 "$pkg_name" 2>/dev/tty)
  local RET=$?

  if (( RET == 130 || RET == 2 )); then return 130; fi
  if [[ -z "$typed_proj_cmd" ]]; then return 1; fi
  
  if ! check_proj_cmd_ -s $i "$typed_proj_cmd" "$old_proj_cmd"; then
    return 1;
  fi

  if [[ -z "$TEMP_PUMP_SHORT_NAME" ]]; then    
    TEMP_PUMP_SHORT_NAME="$typed_proj_cmd"

    if (( save_proj_cmd_is_x )); then
      print "  ${hi_gray_cor}project name: ${TEMP_PUMP_SHORT_NAME}${reset_cor}" >&1
    else
      print "  ${SAVE_COR}project name:${reset_cor} ${TEMP_PUMP_SHORT_NAME}${reset_cor}" >&1
    fi
  fi
}

function get_proj_mode_from_folder_() {
  local proj_folder="$1"
  local single_mode="$2"

  if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
    return $single_mode;
  fi
  
  if is_folder_git_ "$proj_folder" &>/dev/null || is_folder_pkg_ "$proj_folder" &>/dev/null; then
    single_mode=1
  elif get_proj_for_git_ "$proj_folder" &>/dev/null || get_proj_for_pkg_ "$proj_folder" &>/dev/null; then
    single_mode=0
  fi

  echo $single_mode
}

function save_proj_mode_() {
  set +x
  eval "$(parse_flags_ "$0" "aeqv" "" "$@")"
  (( save_proj_mode_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local single_mode="$3"

  local current_single_mode=$(get_proj_mode_from_folder_ "$proj_folder" "$single_mode")

  if (( save_proj_mode_is_e || save_proj_mode_is_a )); then
    single_mode=$(choose_mode_ "$current_single_mode" "$proj_folder")

    if [[ -z "$single_mode" ]]; then return 1; fi
  
  elif [[ -n "$current_single_mode" ]]; then
    single_mode=$current_single_mode
  fi

  if (( save_proj_mode_is_q )); then
    if [[ "$single_mode" != "${PUMP_SINGLE_MODE[$i]}" ]]; then
      update_config_ $i "PUMP_SINGLE_MODE" "$single_mode" &>/dev/null
    fi
    return 0;
  fi

  TEMP_SINGLE_MODE="$single_mode"
  
  local mode_label=$( (( single_mode )) && echo "single" || echo "multiple" )

  if (( save_proj_mode_is_x )); then
    print "  ${hi_gray_cor}project mode: ${mode_label}${reset_cor}" >&1
  else
    print "  ${SAVE_COR}project mode:${reset_cor} ${mode_label}${reset_cor}" >&1
  fi
}

function save_proj_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "aefscv" "q" "$@")"
  (( save_proj_folder_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local proj_repo="$3"
  local proj_folder="$4"
  local count="${5:-0}"

  local folder_exists=0

  if (( save_proj_folder_is_a )); then
    if [[ -n "$proj_folder" && "$proj_folder" == "${PUMP_FOLDER[$i]}" ]]; then
      return 0;
    fi

    if ( is_folder_pkg_ "$(pwd)" &>/dev/null || is_folder_git_ "$(pwd)" &>/dev/null ) && ! find_proj_by_folder_ "$(pwd)" &>/dev/null; then
      # ask to use pwd
      confirm_ "set project folder to: ${blue_cor}${PWD}${reset_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        proj_folder="$PWD"
        folder_exists=1
      fi
    fi
  fi

  local header=""
  local RET=0

  if (( save_proj_folder_is_e )) && [[ -n "$proj_folder" ]]; then
    confirm_ "keep using project folder: ${blue_cor}${proj_folder}${reset_cor} ?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      proj_folder=""
      folder_exists=1
    fi
  fi

  if (( count == 0 )) && [[ -z "$proj_folder" ]]; then
    confirm_ "would you like to create a new folder or use an existing folder?" "create new folder" "use existing folder"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      return 0;
    fi
    if (( RET == 1 )); then
      header="select an existing project folder"
      folder_exists=1
    fi
  fi

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$proj_repo" ]]; then
      local repo_name=$(get_repo_name_ "$proj_repo")
      proj_cmd=$(sanitize_pkg_name_ "${repo_name:t}")
    fi

    if (( RET == 0 )); then
      if [[ -z "$proj_cmd" ]]; then
        if ! save_proj_cmd_ $i "$proj_cmd" "${PUMP_SHORT_NAME[$i]}"; then return 1; fi
        proj_cmd="$TEMP_PUMP_SHORT_NAME"
      fi

      folder_exists=0
      header="choose the parent folder where the project folder will exist"
    fi

    if (( folder_exists )); then
      proj_folder=$(find_proj_folder_ -e $i "$header" "$proj_cmd")
    else
      proj_folder=$(find_proj_folder_ $i "$header" "$proj_cmd")
    fi

    if [[ -z "$proj_folder" ]]; then return 1; fi

    if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then return 1; fi

    if (( folder_exists == 0 )); then
      proj_folder="${proj_folder}/${proj_cmd}"
    fi
  else
    if ! check_proj_folder_ -s $i "$proj_folder" "$proj_cmd" "$proj_repo" ${@:5}; then return 1; fi
  fi

  if [[ -z "$proj_folder" ]]; then return 1; fi

  if (( save_proj_folder_is_v )); then
    mkdir -p -- "$proj_folder" &>/dev/null
  fi

  if (( save_proj_folder_is_q || save_proj_folder_is_v )); then
    update_config_ $i "PUMP_FOLDER" "$proj_folder" &>/dev/null
    return 0;
  fi

  TEMP_PUMP_FOLDER="$proj_folder"

  print "  ${SAVE_COR}project folder:${reset_cor} ${TEMP_PUMP_FOLDER}${reset_cor}" >&1
}

function save_proj_repo_() {
  set +x
  eval "$(parse_flags_ "$0" "afe" "q" "$@")"
  (( save_proj_repo_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_cmd="$3"
  local proj_repo="$4"
  local count="${5:-0}"

  if (( count )); then
    return 0;
  fi

  local RET=0

  if [[ -z "$proj_repo" ]]; then
    if [[ -n "$proj_folder" ]]; then
      proj_repo=$(get_repo_ "$proj_folder" 2>/dev/null)
    fi

    if (( ! save_proj_repo_is_f )); then
      if [[ -z "$proj_repo" ]]; then
        proj_repo=$(find_repo_ "type the git repository uri (ssh or https)" "$proj_repo")
        # if proj_repo is not typed, it's fine to skip
        if [[ -z "$proj_repo" ]]; then return 0; fi
      fi

      if [[ "$proj_repo" == "." ]]; then
        proj_repo=""
      else
        # don't pass $proj_folder to check_proj_repo_ so it doesn't ask again if we want to use the same repo
        if ! check_proj_repo_ -sv $i "$proj_repo" "$proj_folder" "$proj_cmd" ${@:5};  then return 1; fi
      fi
    fi

    # if proj_repo is empty, it's fine to skip
    if [[ -z "$proj_repo" ]]; then return 0; fi
  fi

  if (( save_proj_repo_is_q )); then
    update_config_ $i "PUMP_REPO" "$proj_repo" &>/dev/null
    return 0;
  fi

  TEMP_PUMP_REPO="$proj_repo"

  print "  ${SAVE_COR}project repository:${reset_cor} ${TEMP_PUMP_REPO}${reset_cor}" >&1
}

function save_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "q" "$@")"
  (( save_pkg_manager_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  local pkg_manager=$(detect_pkg_manager_ "$proj_folder")

  if [[ -z "$pkg_manager" && -n "$proj_repo" ]]; then
    pkg_manager=$(detect_pkg_manager_online_ "$proj_repo")
  fi

  local RET=0

  if [[ -n "$pkg_manager" ]] && (( ! save_pkg_manager_is_f )); then
    confirm_ "set package manager: ${pink_cor}${pkg_manager}${reset_cor}?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      pkg_manager=""
    fi
  fi

  if [[ -z "$pkg_manager" ]]; then
    pkg_manager=$(choose_one_ "package manager" "npm" "yarn" "pnpm" "bun")
    if [[ -z "$pkg_manager" ]]; then return 1; fi

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder" "$proj_repo" ${@:4}; then return 1; fi
  fi
  
  if [[ -z "$pkg_manager" ]]; then return 1; fi

  TEMP_PUMP_PKG_MANAGER="$pkg_manager"

  if (( save_pkg_manager_is_q )); then
    return 0;
  fi

  print "  ${SAVE_COR}package manager:${reset_cor} ${TEMP_PUMP_PKG_MANAGER}${reset_cor}" >&1
}

function save_proj_f_() {
  set +x
  eval "$(parse_flags_ "$0" "ae" "" "$@")"
  (( save_proj_f_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local pkg_name="$3"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_f_ index is invalid: $i" >&2
    return 1;
  fi

  if (( save_proj_f_is_a )); then
    SAVE_COR="${hi_blue_cor}"
    display_line_ "add new project" "${SAVE_COR}"
  else
    SAVE_COR="${bold_yellow_cor}"
  fi

  local proj_repo=$(get_repo_ "$PWD" 2>/dev/null)

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  # all the config setting comes from $PWD
  if (( save_proj_f_is_e )); then
    if ! save_pkg_manager_ -fq $i "$PWD" "$proj_repo"; then return 1; fi
  else
    remove_proj_ $i

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo"; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -fa $i "$PWD" "$proj_repo"; then return 1; fi
    if ! save_proj_cmd_ -f $i "$proj_cmd"; then return 1; fi
  fi
  
  remove_proj_ -u $i  
  
  if ! update_config_ $i "PUMP_FOLDER" "$PWD" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_PKG_MANAGER" "$TEMP_PUMP_PKG_MANAGER" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_SINGLE_MODE" 1 &>/dev/null; then return 1; fi

  if (( save_proj_f_is_e )); then
    if ! update_config_ $i "PUMP_SHORT_NAME" "$proj_cmd" &>/dev/null; then return 1; fi
  else
    if ! update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null; then return 1; fi
    
    print "" >&1
    print "  ${SAVE_COR}project saved!${reset_cor}" >&1
    display_line_ "" "${SAVE_COR}"
  fi

  load_config_entry_ $i

  pro -f "${PUMP_SHORT_NAME[$i]}"
  # rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
}

function save_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "ae" "" "$@")"
  (( save_proj_is_debug )) && set -x

  local i="$1"
  local proj_name="$2"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_ index is invalid: $i" >&2
    return 1;
  fi

  # display header
  if (( save_proj_is_e )); then
    SAVE_COR="${hi_yellow_cor}"
    display_line_ "edit project: ${proj_name}" "${SAVE_COR}"
  else
    SAVE_COR="${hi_cyan_cor}"
    display_line_ "add new project" "${SAVE_COR}"
  fi
  
  local old_single_mode=$(get_proj_mode_from_folder_ "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}")
  local refresh=0

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  if (( save_proj_is_e )); then
    # editing a project
    if [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      refresh=1
    fi

    if ! save_proj_cmd_ -e $i "$proj_name" "${PUMP_SHORT_NAME[$i]}"; then return 1; fi

    if ! save_proj_folder_ -e $i "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}"; then return 1; fi
    if ! save_proj_repo_ -e $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}"; then return 1; fi
    
    if ! save_proj_mode_ -e $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
  else
    # adding a new project
    remove_proj_ $i

    if ! save_proj_cmd_ -a $i "$proj_name"; then return 1; fi

    local count=0
    while [[ -z "$TEMP_PUMP_FOLDER" ]]; do
      if ! save_proj_folder_ -a $i "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO" "$TEMP_PUMP_FOLDER" "$count"; then return 1; fi
      if ! save_proj_repo_ -a $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO" "$count"; then return 1; fi
      (( count++ ))
    done
    
    if ! save_proj_mode_ -a $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
  fi

  if ! save_pkg_manager_ $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO"; then return 1; fi

  local pkg_name=$(get_pkg_name_ "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO")
  
  remove_proj_ -u $i

  if [[ -n "$pkg_name" ]]; then
    update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  fi

  if ! update_config_ $i "PUMP_SINGLE_MODE" "$TEMP_SINGLE_MODE" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_FOLDER" "$TEMP_PUMP_FOLDER" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_PKG_MANAGER" "$TEMP_PUMP_PKG_MANAGER" &>/dev/null; then return 1; fi

  print "" >&1
  print "  ${SAVE_COR}project saved!${reset_cor}" >&1
  display_line_ "" "${SAVE_COR}"

  load_config_entry_ $i

  if [[ ! -d "${PUMP_FOLDER[$i]}" ]]; then
    mkdir -p -- "${PUMP_FOLDER[$i]}"
  fi

  local display_msg=1

  if [[ -n "$old_single_mode" ]] && (( old_single_mode != ${PUMP_SINGLE_MODE[$i]} )); then
    local git_proj_folder=$(get_proj_for_git_ "${PUMP_FOLDER[$i]}" 2>/dev/null)
    local pkg_proj_folder=$(get_proj_for_pkg_ "${PUMP_FOLDER[$i]}" 2>/dev/null)
    
    if [[ -n "$git_proj_folder" || -n "$pkg_proj_folder" ]]; then
      if create_backup_ -sd $i "${PUMP_FOLDER[$i]}"; then
        print " project must be cloned again as mode has changed" >&1
        print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} clone${reset_cor}" >&1
        display_msg=0
      fi
    fi
  fi

  if (( refresh )) || [[ "$PWD" == "${PUMP_FOLDER[$i]}" ]]; then
    set_current_proj_ $i
    display_msg=0
  fi
  
  if (( display_msg )); then
    print " now run command: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}" >&1
  fi
}
# end of save project data to config file =========================================

function unset_aliases_() {
  unalias ncov &>/dev/null
  unalias ntest &>/dev/null
  unalias ne2e &>/dev/null
  unalias ne2eui &>/dev/null
  unalias ntestw &>/dev/null

  unalias ycov &>/dev/null
  unalias ytest &>/dev/null
  unalias ye2e &>/dev/null
  unalias ye2eui &>/dev/null
  unalias ytestw &>/dev/null

  unalias pcov &>/dev/null
  unalias ptest &>/dev/null
  unalias pe2e &>/dev/null
  unalias pe2eui &>/dev/null
  unalias ptestw &>/dev/null

  unalias bcov &>/dev/null
  unalias btest &>/dev/null
  unalias be2e &>/dev/null
  unalias be2eui &>/dev/null
  unalias btestw &>/dev/null 

  unset -f build &>/dev/null
  unset -f deploy &>/dev/null
  unset -f format &>/dev/null
  unset -f lint &>/dev/null
  unset -f rdev &>/dev/null
  unset -f rstart &>/dev/null
  unset -f sb &>/dev/null
  unset -f sbb &>/dev/null
  unset -f tsc &>/dev/null
  unset -f watch &>/dev/null
}

function set_aliases_() {
  local i="$1"

  local pkg_manager=""
  local pump_cov=""
  local pump_test=""
  local pump_e2e=""
  local pump_e2eui=""
  local pump_test_watch=""
  
  if (( i > 0 )); then
    pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    pump_cov="${PUMP_COV[$i]}"
    pump_test="${PUMP_TEST[$i]}"
    pump_e2e="${PUMP_E2E[$i]}"
    pump_e2eui="${PUMP_E2EUI[$i]}"
    pump_test_watch="${PUMP_TEST_WATCH[$i]}"
  else
    pkg_manager="$CURRENT_PUMP_PKG_MANAGER"
    pump_cov="$CURRENT_PUMP_COV"
    pump_test="$CURRENT_PUMP_TEST"
    pump_e2e="$CURRENT_PUMP_E2E"
    pump_e2eui="$CURRENT_PUMP_E2EUI"
    pump_test_watch="$CURRENT_PUMP_TEST_WATCH"
  fi

  if [[ -z "$pkg_manager" ]]; then return 1; fi

  # Reset all aliases
  #unalias -a &>/dev/null
  # Package manager aliases =========================================================
  alias build="$pkg_manager run build"
  alias deploy="$pkg_manager run deploy"
  alias format="$pkg_manager run format"
  alias lint="$pkg_manager run lint"
  alias rdev="$pkg_manager run dev"
  alias rstart="$pkg_manager run start"
  alias sb="$pkg_manager run storybook"
  alias sbb="$pkg_manager run storybook:build"
  alias start="$pkg_manager run start"
  alias tsc="$pkg_manager run tsc"
  alias watch="$pkg_manager run watch"

  if [[ "$pump_test" != "$pkg_manager test" ]]; then
    alias ${pkg_manager:0:1}test="$pkg_manager run test"
  fi
  if [[ "$pump_cov" != "$pkg_manager run test:coverage" ]]; then
    alias ${pkg_manager:0:1}cov="$pkg_manager run test:coverage"
  fi
  if [[ "$pump_e2e" != "$pkg_manager run test:e2e" ]]; then
    alias ${pkg_manager:0:1}e2e="$pkg_manager run test:e2e"
  fi
  if [[ "$pump_e2eui" != "$pkg_manager run test:e2e-ui" ]]; then
    alias ${pkg_manager:0:1}e2eui="$pkg_manager run test:e2e-ui"
  fi
  if [[ "$pump_test_watch" != "$pkg_manager run test:watch" ]]; then
    alias ${pkg_manager:0:1}testw="$pkg_manager run test:watch"
  fi
}

function remove_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "ru" "" "$@")"
  (( remove_proj_is_debug )) && set -x

  local i="$1"

  if (( remove_proj_is_r )); then
    local proj_cmd="${PUMP_SHORT_NAME[$i]}"
    local proj_folder="${PUMP_FOLDER[$i]}"
    local single_mode="${PUMP_SINGLE_MODE[$i]:-0}"

    if [[ -n "$proj_folder" ]]; then
      local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder" "$single_mode")"
      local cov_folder="$(get_proj_special_folder_ -c "$proj_cmd" "$proj_folder" "$single_mode")"

      if command -v gum &>/dev/null; then
        gum spin --title="removing project folders..." -- rm -rf -- "$revs_folder" "$cov_folder"
      else
        print "removing project folders..."
        rm -rf -- "$revs_folder" "$cov_folder"
        clear_last_line_1_
      fi
    fi
  fi

  unset_aliases_

  if (( remove_proj_is_u )); then
    update_config_ $i "PUMP_SHORT_NAME" "" 1>/dev/null # let this one
    update_config_ $i "PUMP_FOLDER" "" &>/dev/null
    update_config_ $i "PUMP_REPO" "" &>/dev/null
    update_config_ $i "PUMP_SINGLE_MODE" "" &>/dev/null
    update_config_ $i "PUMP_PKG_MANAGER" "" &>/dev/null
    update_config_ $i "PUMP_CODE_EDITOR" "" &>/dev/null
    update_config_ $i "PUMP_CLONE" "" &>/dev/null
    update_config_ $i "PUMP_SETUP" "" &>/dev/null
    update_config_ $i "PUMP_FIX" "" &>/dev/null
    update_config_ $i "PUMP_RUN" "" &>/dev/null
    update_config_ $i "PUMP_RUN_STAGE" "" &>/dev/null
    update_config_ $i "PUMP_RUN_PROD" "" &>/dev/null
    update_config_ $i "PUMP_PRO" "" &>/dev/null
    update_config_ $i "PUMP_USE" "" &>/dev/null
    update_config_ $i "PUMP_TEST" "" &>/dev/null
    update_config_ $i "PUMP_RETRY_TEST" "" &>/dev/null
    update_config_ $i "PUMP_COV" "" &>/dev/null
    update_config_ $i "PUMP_OPEN_COV" "" &>/dev/null
    update_config_ $i "PUMP_TEST_WATCH" "" &>/dev/null
    update_config_ $i "PUMP_E2E" "" &>/dev/null
    update_config_ $i "PUMP_E2EUI" "" &>/dev/null
    update_config_ $i "PUMP_PR_TEMPLATE_FILE" "" &>/dev/null
    update_config_ $i "PUMP_PR_REPLACE" "" &>/dev/null
    update_config_ $i "PUMP_PR_APPEND" "" &>/dev/null
    update_config_ $i "PUMP_PR_APPROVAL_MIN" "" &>/dev/null
    update_config_ $i "PUMP_INTERVAL" "" &>/dev/null
    update_config_ $i "PUMP_COMMIT_ADD" "" &>/dev/null
    update_config_ $i "PUMP_COMMIT_SIGNOFF" "" &>/dev/null
    update_config_ $i "PUMP_PRINT_README" "" &>/dev/null
    update_config_ $i "PUMP_PKG_NAME" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_IN_PROGRESS" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_IN_REVIEW" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_DONE" "" &>/dev/null
    update_config_ $i "PUMP_NVM_SKIP_LOOKUP" "" &>/dev/null
    update_config_ $i "PUMP_NVM_USE_V" "" &>/dev/null
  else
    PUMP_SHORT_NAME[$i]=""
    PUMP_FOLDER[$i]=""
    PUMP_REPO[$i]=""
    PUMP_SINGLE_MODE[$i]=""
    PUMP_PKG_MANAGER[$i]=""
    PUMP_CODE_EDITOR[$i]=""
    PUMP_CLONE[$i]=""
    PUMP_SETUP[$i]=""
    PUMP_FIX[$i]=""
    PUMP_RUN[$i]=""
    PUMP_RUN_STAGE[$i]=""
    PUMP_RUN_PROD[$i]=""
    PUMP_PRO[$i]=""
    PUMP_USE[$i]=""
    PUMP_TEST[$i]=""
    PUMP_RETRY_TEST[$i]=""
    PUMP_COV[$i]=""
    PUMP_OPEN_COV[$i]=""
    PUMP_TEST_WATCH[$i]=""
    PUMP_E2E[$i]=""
    PUMP_E2EUI[$i]=""
    PUMP_PR_TEMPLATE_FILE[$i]=""
    PUMP_PR_REPLACE[$i]=""
    PUMP_PR_APPEND[$i]=""
    PUMP_PR_APPROVAL_MIN[$i]=""
    PUMP_INTERVAL[$i]=""
    PUMP_COMMIT_ADD[$i]=""
    PUMP_COMMIT_SIGNOFF[$i]=""
    PUMP_PRINT_README[$i]=""
    PUMP_PKG_NAME[$i]=""
    PUMP_JIRA_IN_PROGRESS[$i]=""
    PUMP_JIRA_IN_REVIEW[$i]=""
    PUMP_JIRA_DONE[$i]=""
    PUMP_NVM_SKIP_LOOKUP[$i]=""
    PUMP_NVM_USE_V[$i]=""
  fi
}

function set_current_proj_() {
  local i="$1"

  if [[ -z "$i" || $i -lt 0 || $i -gt 9 ]]; then
    print " fatal: set_current_proj_ index is invalid: $i" >&2
    return 1;
  fi

  unset_aliases_

  # when i=0, it means we are setting the current project to the default values

  CURRENT_PUMP_SHORT_NAME="${PUMP_SHORT_NAME[$i]}"
  CURRENT_PUMP_FOLDER="${PUMP_FOLDER[$i]}"
  CURRENT_PUMP_REPO="${PUMP_REPO[$i]}"
  CURRENT_PUMP_SINGLE_MODE="${PUMP_SINGLE_MODE[$i]}"
  CURRENT_PUMP_PKG_MANAGER="${PUMP_PKG_MANAGER[$i]}"
  CURRENT_PUMP_CODE_EDITOR="${PUMP_CODE_EDITOR[$i]}"
  CURRENT_PUMP_CLONE="${PUMP_CLONE[$i]}"
  CURRENT_PUMP_SETUP="${PUMP_SETUP[$i]}"
  CURRENT_PUMP_FIX="${PUMP_FIX[$i]}"
  CURRENT_PUMP_RUN="${PUMP_RUN[$i]}"
  CURRENT_PUMP_RUN_STAGE="${PUMP_RUN_STAGE[$i]}"
  CURRENT_PUMP_RUN_PROD="${PUMP_RUN_PROD[$i]}"
  CURRENT_PUMP_PRO="${PUMP_PRO[$i]}"
  CURRENT_PUMP_USE="${PUMP_USE[$i]}"
  CURRENT_PUMP_TEST="${PUMP_TEST[$i]}"
  CURRENT_PUMP_RETRY_TEST="${PUMP_RETRY_TEST[$i]}"
  CURRENT_PUMP_COV="${PUMP_COV[$i]}"
  CURRENT_PUMP_OPEN_COV="${PUMP_OPEN_COV[$i]}"
  CURRENT_PUMP_TEST_WATCH="${PUMP_TEST_WATCH[$i]}"
  CURRENT_PUMP_E2E="${PUMP_E2E[$i]}"
  CURRENT_PUMP_E2EUI="${PUMP_E2EUI[$i]}"
  CURRENT_PUMP_PR_TEMPLATE_FILE="${PUMP_PR_TEMPLATE_FILE[$i]}"
  CURRENT_PUMP_PR_REPLACE="${PUMP_PR_REPLACE[$i]}"
  CURRENT_PUMP_PR_APPEND="${PUMP_PR_APPEND[$i]}"
  CURRENT_PUMP_PR_APPROVAL_MIN="${PUMP_PR_APPROVAL_MIN[$i]}"
  CURRENT_PUMP_INTERVAL="${PUMP_INTERVAL[$i]}"
  CURRENT_PUMP_COMMIT_ADD="${PUMP_COMMIT_ADD[$i]}"
  CURRENT_PUMP_COMMIT_SIGNOFF="${PUMP_COMMIT_SIGNOFF[$i]}"
  CURRENT_PUMP_PRINT_README="${PUMP_PRINT_README[$i]}"
  CURRENT_PUMP_PKG_NAME="${PUMP_PKG_NAME[$i]}"
  CURRENT_PUMP_JIRA_IN_PROGRESS="${PUMP_JIRA_IN_PROGRESS[$i]}"
  CURRENT_PUMP_JIRA_IN_REVIEW="${PUMP_JIRA_IN_REVIEW[$i]}"
  CURRENT_PUMP_JIRA_DONE="${PUMP_JIRA_DONE[$i]}"
  CURRENT_PUMP_NVM_SKIP_LOOKUP="${PUMP_NVM_SKIP_LOOKUP[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"

  set_aliases_ $i

  # do not need to refresh because themes were fixed
  # if [[ -n "$ZSH_THEME" ]]; then
  #   source "$ZSH/themes/${ZSH_THEME}.zsh-theme"
  # fi
}

function get_node_engine_() {
  local folder="${1:-$PWD}"

  local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json" 2>/dev/null)
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local package_json="${proj_folder}/package.json"
  if [[ ! -f $package_json ]]; then return 1; fi

  local node_engine=""

  if command -v jq &>/dev/null; then
    node_engine=$(jq -r '.engines.node // empty' "$package_json")
  else
    node_engine=$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_json" | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
  fi

  if [[ -z "$node_engine" ]]; then return 1; fi

  echo "$node_engine"
}

function get_major_version_() {
  local version="$1"

  local major_version="$version"

  if [[ -n "$version" ]] && command -v semver &>/dev/null; then
    major_version=$(semver -v "$version" | cut -d. -f1 2>/dev/null)
  fi

  echo "$major_version"
}

# function get_unpadded_version_() {
#   local version="$1"

#   local parts=("${(s:.:)version}")
#   local result=()

#   for part in $parts; do
#     [[ "$part" == "x" ]] && break
#     result+=("$part")
#   done

#   echo "${(j:.:)result}"
# }

# function get_display_version_() {
#   local version="$1"
   
#   local padded_version=$(get_padded_version_ "$version" 0)
#   local major_version=$(get_major_version_ "$padded_version")

#   echo $(get_padded_version_ "$major_version")
# }

# function get_padded_version_() {
#   local version="$1"
#   local replacer="${2:-x}"
  
#   local parts=("${(s:.:)version}")
  
#   echo "${parts[1]:-$replacer}.${parts[2]:-$replacer}.${parts[3]:-$replacer}"
# }

function is_node_version_valid_() {
  local node_engine="$1"
  local version="$2"

  # require 'semver' CLI tool to do semver comparisons
  if ! command -v semver &>/dev/null; then
    if command -v npm &>/dev/null; then
      npm install -g semver --yes &>/dev/null
    else
      return 1;
    fi
  fi

  if ! command -v semver &>/dev/null; then return 1; fi

  semver -r "$node_engine" "$version" &>/dev/null
}

function get_node_versions_() {
  local folder="${1:-$PWD}"
  local node_engine="$2"

  if ! command -v nvm &>/dev/null; then return 1; fi

  if [[ -z "$node_engine" ]]; then
    local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json" 2>/dev/null)
    if [[ -z "$proj_folder" ]]; then return 1; fi

    local package_json="${proj_folder}/package.json"
    if [[ ! -f $package_json ]]; then return 1; fi

    if command -v jq &>/dev/null; then
      node_engine=$(jq -r '.engines.node // empty' "$package_json")
    else
      node_engine=$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_json" | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    fi
    
    if [[ -z "$node_engine" ]]; then return 1; fi
  fi

  # get list of installed versions from nvm
  local installed_versions=($(nvm ls --no-colors | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^[-> ]*//' | sed 's/ *\*$//' | sort -V)) # | sed 's/^v//'

  # find matching versions
  local version=""
  for version in "${installed_versions[@]}"; do
    if is_node_version_valid_ "$node_engine" "$version"; then
      echo "$version"
    fi
  done
}

function get_node_version_() {
  local folder="${1:-$PWD}"
  local sort_by="${2:-latest}"
  local node_engine="$3"

  if ! command -v nvm &>/dev/null; then return 1; fi

  if [[ -z "$node_engine" ]]; then
    local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json" 2>/dev/null)
    if [[ -z "$proj_folder" ]]; then return 1; fi

    local package_json="${proj_folder}/package.json"
    if [[ ! -f $package_json ]]; then return 1; fi

    if ! command -v nvm &>/dev/null; then return 1; fi

    if command -v jq &>/dev/null; then
      node_engine=$(jq -r '.engines.node // empty' "$package_json")
    else
      node_engine=$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_json" | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
    fi
    
    if [[ -z "$node_engine" ]]; then return 1; fi
  fi

  # setopt shwordsplit
  # get list of installed versions from nvm
  local installed_versions=()
  installed_versions=($(
    nvm ls --no-colors \
      | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' \
      | sed 's/^[-> ]*//' \
      | sed 's/^v//' \
      | sed 's/ *\*$//'
  ))
  # unsetopt shwordsplit

  if (( ${#installed_versions[@]} == 0 )); then return 1; fi

  # require 'semver' CLI tool to do semver comparisons
  if ! command -v semver &>/dev/null; then
    if command -v npm &>/dev/null; then
      npm install -g semver --yes &>/dev/null
    else
      return 1;
    fi
  fi

  if ! command -v semver &>/dev/null; then return 1; fi

  local matching_versions=()

  # find matching versions
  for version in "${installed_versions[@]}"; do
    if semver -r "$node_engine" "$version" &>/dev/null; then
      matching_versions+=("$version")
    fi
  done

  if (( ${#matching_versions[@]} == 0 )); then return 1; fi

  # sort versions and pick the latest
  local best_version=""
  
  if [[ "$sort_by" == "latest" ]]; then
    best_version=$(printf "%s\n" "${matching_versions[@]}" | sort -V | tail -n 1)
  else
    best_version=$(printf "%s\n" "${matching_versions[@]}" | sort -V | head -n 1)
  fi

  echo "$best_version"
}

function print_current_proj_() {
  local i="$1"
  
  display_line_ "" "${hi_gray_cor}"

  if (( i > 0 )); then
    print " [${hi_magenta_cor}PUMP_SHORT_NAME_$i=${reset_cor}${hi_gray_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_FOLDER_$i=${reset_cor}${hi_gray_cor}${PUMP_FOLDER[${hi_magenta_cor}$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_REPO_$i=${reset_cor}${hi_gray_cor}${PUMP_REPO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SINGLE_MODE_$i=${reset_cor}${hi_gray_cor}${PUMP_SINGLE_MODE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_MANAGER_$i=${reset_cor}${hi_gray_cor}${PUMP_PKG_MANAGER[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_$i=${reset_cor}${hi_gray_cor}${PUMP_RUN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_STAGE_$i=${reset_cor}${hi_gray_cor}${PUMP_RUN_STAGE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_PROD_$i=${reset_cor}${hi_gray_cor}${PUMP_RUN_PROD[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SETUP_$i=${reset_cor}${hi_gray_cor}${PUMP_SETUP[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_FIX_$i=${reset_cor}${hi_gray_cor}${PUMP_FIX[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_CLONE_$i=${reset_cor}${hi_gray_cor}${PUMP_CLONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PRO_$i=${reset_cor}${hi_gray_cor}${PUMP_PRO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_USE_$i=${reset_cor}${hi_gray_cor}${PUMP_USE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_CODE_EDITOR_$i=${reset_cor}${hi_gray_cor}${PUMP_CODE_EDITOR[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COV_$i=${reset_cor}${hi_gray_cor}${PUMP_COV[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_OPEN_COV_$i=${reset_cor}${hi_gray_cor}${PUMP_OPEN_COV_[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RETRY_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_RETRY_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_WATCH_$i=${reset_cor}${hi_gray_cor}${PUMP_TEST_WATCH[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2E_$i=${reset_cor}${hi_gray_cor}${PUMP_E2E[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2EUI_$i=${reset_cor}${hi_gray_cor}${PUMP_E2EUI[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_TEMPLATE_FILE_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_TEMPLATE_FILE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_REPLACE_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_REPLACE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPEND_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_APPEND[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPROVAL_MIN$i=${reset_cor}${hi_gray_cor}${PUMP_PR_APPROVAL_MIN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COMMIT_ADD_$i=${reset_cor}${hi_gray_cor}${PUMP_COMMIT_ADD[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COMMIT_SIGNOFF_$i=${reset_cor}${hi_gray_cor}${PUMP_COMMIT_SIGNOFF[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_INTERVAL_$i=${reset_cor}${hi_gray_cor}${PUMP_INTERVAL[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PRINT_README_$i=${reset_cor}${hi_gray_cor}${PUMP_PRINT_README[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_NAME_$i=${reset_cor}${hi_gray_cor}${PUMP_PKG_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_PROGRESS_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_PROGRESS[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_REVIEW_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_REVIEW[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_DONE_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SKIP_NVM_LOOKUP_$i=${reset_cor}${hi_gray_cor}${PUMP_NVM_SKIP_LOOKUP[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_NVM_USE_V$i=${reset_cor}${hi_gray_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}]"

    return 0;
  fi

  print " [${hi_magenta_cor}CURRENT_PUMP_SHORT_NAME=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_FOLDER=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_FOLDER}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_REPO=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_REPO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SINGLE_MODE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_SINGLE_MODE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_MANAGER=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_RUN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN_STAGE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_RUN_STAGE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN_PROD=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_RUN_PROD}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SETUP=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_SETUP}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_FIX=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_FIX}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_CLONE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_CLONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PRO=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PRO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_USE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_USE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_CODE_EDITOR=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_CODE_EDITOR}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COV=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_OPEN_COV=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_OPEN_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RETRY_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_RETRY_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST_WATCH=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_TEST_WATCH}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2E=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_E2E}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2EUI=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_E2EUI}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_TEMPLATE_FILE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_TEMPLATE_FILE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_REPLACE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_REPLACE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPEND=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_APPEND}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPROVAL_MIN=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_APPROVAL_MIN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COMMIT_ADD=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_COMMIT_ADD}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_INTERVAL=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_INTERVAL}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PRINT_README=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PRINT_README}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_NAME=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PKG_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_PROGRESS=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_PROGRESS}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_REVIEW=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_REVIEW}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_DONE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_SKIP_LOOKUP=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NVM_SKIP_LOOKUP}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_USE_V=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NVM_USE_V}${reset_cor}]"
}

function which_pro_index_pwd_() {
  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_SHORT_NAME[$i]}" && -n "${PUMP_FOLDER[$i]}" ]]; then
      if [[ $PWD == $PUMP_FOLDER[$i]* ]]; then
        echo "$i"
        return 0;
      fi
    fi
  done

  echo "0"
  return 1;
}

function is_project_() {
  set +x
  local proj_arg="$1"

  if [[ -z "$proj_arg" ]]; then return 1; fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_SHORT_NAME[$i]}" ]]; then
      return 0;
    fi
  done

  return 1;
}

function get_projects_() {
  if [[ -n "${PUMP_SHORT_NAME[*]}" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        echo "${PUMP_SHORT_NAME[$i]}"
      fi
    done
  fi
}

# when project is known, it's a proj_cmd
function get_proj_index_() {
  local proj_cmd="$1"

  local i=0
  for i in {1..9}; do
    if [[ "$proj_cmd" == "${PUMP_SHORT_NAME[$i]}" ]]; then
      echo "$i"
      break;
    fi
  done

  if (( i > 9 )); then
    print " ${red_cor}fatal: not a valid project command: $proj_cmd${reset_cor}" >&2
    return 1;
  fi
}

# when project is unknown, it's a proj_arg
function find_proj_index_() {
  set +x
  eval "$(parse_flags_ "$0" "zoex" "" "$@")"
  (( find_proj_index_is_debug )) && set -x

  local proj_arg="$1"
  local header="${2:-project}"
  local default_index="${3:-0}"

  if [[ -z "$proj_arg" ]]; then
    if (( find_proj_index_is_x )); then
      echo "$default_index"
      return 0;
    fi

    if (( find_proj_index_is_o )); then
      local projects=($(get_projects_))
      if [[ -z "$projects" ]]; then
        print " no projects found"
        print " run ${hi_yellow_cor}pump -a${reset_cor} to add a project"
        return 0;
      fi

      proj_arg=$(choose_one_ "$header" "${projects[@]}")
      if [[ -z "$proj_arg" ]]; then return 130; fi
    else
      print " missing project argument" >&2
      return 1;
    fi
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_SHORT_NAME[$i]}" ]]; then
      echo "$i"
      return 0;
    fi
  done

  print " not a valid project argument: $proj_arg" >&2

  if (( find_proj_index_is_o && find_proj_index_is_e )); then
    local projects=($(get_projects_))
    if [[ -z "$projects" ]]; then
      print " fatal: no projects found" >&2
      print " run ${hi_yellow_cor}pump -a${reset_cor} to add a project" >&2
      return 1;
    fi

    proj_arg=$(choose_one_ "$header" "${projects[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi

    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_SHORT_NAME[$i]}" ]]; then
        echo "$i"
        return 0;
      fi
    done
  fi

  return 1;
}

function find_proj_by_folder_() {
  local folder="${1:-$PWD}"

  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_SHORT_NAME[$i]}" && -n "${PUMP_FOLDER[$i]}" ]]; then

      if [[ "${folder:A}" == "${PUMP_FOLDER[$i]:A}" ]]; then
        echo "${PUMP_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  for i in {1..9}; do
    if [[ -n "${PUMP_SHORT_NAME[$i]}" && -n "${PUMP_FOLDER[$i]}" ]]; then

      if [[ "${folder:A}/" == "${PUMP_FOLDER[$i]:A}/"* ]]; then
        echo "${PUMP_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  local parent_folder="$(dirname -- "$folder")"
  local parent_folder_name="$(basename -- "$parent_folder")"

  for i in {1..9}; do
    if [[ "${PUMP_SHORT_NAME[$i]}" == "$parent_folder_name" ]]; then
      echo "${PUMP_SHORT_NAME[$i]}"
      return 0;
    fi
  done

  # cannot determine project based on pwd
  return 1;
}

function is_folder_pkg_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  local files=("package.json")
  
  local file=""
  for file in "${files[@]}"; do
    if [[ -e "${folder}/${file}" ]]; then
      return 0;
    fi

    local pattern="$(printf "%q" "$file")"
    local found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}" \) -prune -o -maxdepth 1 -iname "${pattern}*" -print -quit 2>/dev/null)"
    
    if [[ -n "$found_file" ]]; then
      return 0;
    fi
  done

  print " fatal: not a project folder: $folder" >&2
  return 1;
}

function get_proj_for_pkg_() {
  local folder="${1:-$PWD}"
  local file="${2:-"package.json"}"

  folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  local proj_folder=""

  if [[ -e "${folder}/${file}" ]]; then
    proj_folder="${folder}"
  fi

  if [[ -z "$proj_folder" ]]; then
    local dirs=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop" "trunk" "mainline" "default" "stable")
    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ -f "${folder}/${dir}/${file}" ]]; then
        proj_folder="${folder}/${dir}"
        break;
      fi
    done
  fi

  if [[ -z "$proj_folder" && -n "$file" ]]; then
    local pattern="$(printf "%q" "$file")"
    local found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}*" \) -prune -o -maxdepth 2 -type f -iname "${pattern}*" -print -quit 2>/dev/null)"
    if [[ -z "$found_file" ]]; then
      found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}*" \) -prune -o -type f -iname "${pattern}*" -print -quit 2>/dev/null)"
    fi

    if [[ -n "$found_file" ]]; then
      proj_folder="$(dirname -- "$found_file")"
    fi
  fi

  if [[ -z "$proj_folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  # if is_folder_git_ "$proj_folder" &>/dev/null; then
  #   pull --quiet "$proj_folder" &>/dev/null
  # fi

  echo "$proj_folder"
}

function get_proj_for_git_() {
  local folder="${1:-$PWD}"
  local proj_cmd="$2"

  local real_folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$real_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    if [[ -n "$proj_cmd" ]]; then
      print " run ${hi_yellow_cor}$proj_cmd -e${reset_cor} to edit project" >&2
    fi
    return 1;
  fi

  folder="$real_folder"

  if is_folder_git_ "$folder" &>/dev/null; then
    echo "$folder"
    return 0;
  fi

  local dirs=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop" "trunk" "mainline" "default" "stable")
  local dir=""
  for dir in "${dirs[@]}"; do
    if is_folder_git_ "${folder}/${dir}" &>/dev/null; then
      echo "${folder}/${dir}"
      return 0;
    fi
  done

  local found_git="$(find "$folder" \( -path "*/.*" -a ! -name ".git" \) -prune -o -maxdepth 2 -type d -name ".git" -print -quit 2>/dev/null)"

  if [[ -n "$found_git" ]]; then
    local dir="$(dirname -- "$found_git")"
    if is_folder_git_ "$dir" &>/dev/null; then
      echo "$dir"
      return 0;
    fi
  fi
  
  print " fatal: not a git repository: $folder" >&2

  if [[ -n "$proj_cmd" ]]; then
    print " run ${hi_yellow_cor}$proj_cmd clone${reset_cor} to clone project" >&2
  fi

  return 1;
}

function is_folder_git_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository (or any of the parent directories): .git" >&2 
    return 1;
  fi

  if ! git -C "$folder" rev-parse --is-inside-work-tree &>/dev/null; then
    print " fatal: not a git repository (or any of the parent directories): .git" >&2 
    return 1;
  fi
}

function get_local_branch_() {
  set +x
  eval "$(parse_no_flags_ "$0" "$@")"
  # (( get_local_branch_is_debug )) && set -x

  local branch="$1"
  local proj_folder="${2-$PWD}"

  local local_branch=$(git -C "$proj_folder" branch --list "$branch" | head -n 1)

  if [[ -n "$local_branch" ]]; then
    echo "$local_branch"
    return 0;
  fi
  
  return 1;
}

function get_remote_origin_() {
  set +x
  eval "$(parse_no_flags_ "$0" "$@")"
  # (( get_remote_origin_is_debug )) && set -x

  local folder="${1-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then
     echo "origin"
     return 0;
  fi

  local ref
  for ref in refs/remotes/{origin,upstream}/{main,master,stage,staging,prod,production,release,dev,develop,trunk,mainline,default,stable}; do
    if git -C "$git_folder" show-ref -q --verify $ref; then
      echo "${${ref:h}:t}"
      return 0
    fi
  done

  echo "origin"
}

function get_local_branch_head_() {
  set +x
  eval "$(parse_no_flags_ "$0" "$@")"
  # (( get_local_branch_head_is_debug )) && set -x

  local branch="$1"
  local folder="${2-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then return 1; fi

  if [[ -z "$branch" ]]; then
    branch=$(get_my_branch_ "$git_folder" 2>/dev/null)
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local remote_name=$(get_remote_origin_ "$git_folder")
  local branch_head=$(git -C "$git_folder" ls-remote --heads $remote_name $branch | awk '{print $2}' 2>/dev/null)
  
  if [[ -n "$branch_head" ]]; then
    echo "$branch_head"
    return 0;
  fi
  
  return 1;
}

function determine_target_branch_() {
  local folder="$1"
  local branch_arg="$2"
  
  local default_branch=""
  local base_branch=""
  local my_branch=""

  if ! is_folder_git_ "$folder" &>/dev/null; then
    return 1;
  else
    default_branch=$(get_default_branch_ "$folder" 2>/dev/null)
    base_branch=$(find_base_branch_ "$folder" 2>/dev/null)
    my_branch=$(git -C "$folder" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  fi

  if [[ -z "$base_branch" && -z "$default_branch" ]]; then return 1; fi

  local branches=("${(@f)$(printf "%s\n" "$default_branch" "$base_branch" "${my_branch:t}" | sort -ru)}")

  # add local branches to the list
  # local local_branches=($(git -C "$folder" for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null))

  local selected_branch=""
  selected_branch=$(choose_one_ -i "target branch for $branch_arg" "${branches[@]}")
  if (( $? == 130 )); then return 130; fi

  if [[ -z "$selected_branch" ]]; then return 1; fi

  echo "$selected_branch"
}

function get_remote_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "fo" "" "$@")"
  # (( get_remote_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then return 1; fi

  if [[ -z "$branch" ]]; then
    branch=$(get_my_branch_ "$git_folder" 2>/dev/null)
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local ref=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

  if [[ -z "$ref" ]]; then
    for ref in refs/remotes/{origin,upstream}/$branch; do
      if git -C "$git_folder" show-ref -q --verify $ref; then
        break;
      fi
    done
  fi

  if [[ -n "$ref" ]]; then
    if (( get_remote_branch_is_f )); then
      echo "$ref"
    elif (( get_remote_branch_is_o )); then
      echo "${ref:h:t}/${ref:t}"
    else
      echo "${ref:t}"
    fi
  fi
  
  return 1;
}

function get_main_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "fo" "" "$@")"
  # (( get_main_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  
  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local ref=""
  for ref in refs/remotes/{origin,upstream}/{main,master,trunk,mainline,default,stable}; do
    if git -C "$git_folder" show-ref -q --verify $ref; then
      if (( get_main_branch_is_f )); then
        echo "$ref"
      elif (( get_main_branch_is_o )); then
        echo "${ref:h:t}/${ref:t}"
      else
        echo "${ref:t}"
      fi
      return 0;
    fi
  done

  print " fatal: could not determine main branch" >&2
  return 1;
}

function get_my_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "e" "" "$@")"
  # (( get_my_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  local my_branch=$(git -C "$folder" branch --show-current 2>/dev/null)
  if [[ -z "$my_branch" ]] && (( get_my_branch_is_e )); then
    my_branch=$(git -C "$folder" rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi

  if [[ -z "$my_branch" ]]; then
    print " fatal: current branch is detached or not tracking an upstream branch" >&2
    return 1;
  fi

  echo "$my_branch"
}

function find_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( find_base_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local my_branch="$2"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local candidate_bases=("dev" "develop" "stage" "staging" "main" "master" "prod" "production" "release" "trunk" "mainline" "default" "stable")
  
  if [[ -z "$my_branch" ]]; then
    my_branch=$(get_default_branch_ "$folder" 2>/dev/null)
    if [[ -z "$my_branch" ]]; then return 1; fi
  fi

  local best_base=""
  local most_recent_time=0

  local base=""
  for base in "${candidate_bases[@]}"; do
    # Skip if base doesn't exist
    if ! git -C "$git_folder" show-ref --quiet "refs/heads/$base" && ! git show-ref --quiet "refs/remotes/$base"; then
      continue
    fi

    # Find the common ancestor
    ancestor_commit=$(git -C "$git_folder" merge-base "$my_branch" "$base" 2>/dev/null)
    if [[ -z "$ancestor_commit" ]]; then
      continue
    fi

    # Get commit timestamp
    commit_time=$(git -C "$git_folder" show -s --format=%ct "$ancestor_commit")

    # Track the most recent ancestor
    if (( commit_time > most_recent_time )); then
      most_recent_time=$commit_time
      best_base="$base"
    fi
  done

  echo "$best_base"
}

function get_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "fo" "" "$@")"
  (( get_base_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local my_branch="$2"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  if [[ -z "$my_branch" ]]; then
    my_branch=$(get_my_branch_ "$git_folder" 2>/dev/null)
  fi

  if [[ -n "$my_branch" ]]; then
    local base_branch=$(git -C "$git_folder" config --get branch.$my_branch.gh-merge-base)

    if [[ -z "$base_branch" || "${my_branch:t}" == "${base_branch:t}" ]]; then
      base_branch=$(git -C "$git_folder" config --get branch.$my_branch.vscode-merge-base)

      if [[ -z "$base_branch" || "${my_branch:t}" == "${base_branch:t}" ]]; then
        base_branch=$(git -C "$git_folder" config --get branch.$my_branch.gk-merge-target)

        if [[ -z "$base_branch" || "${my_branch:t}" == "${base_branch:t}" ]]; then
          base_branch=$(find_base_branch_ "$git_folder" "$my_branch" 2>/dev/null)
          
          if [[ -z "$base_branch" || "${my_branch:t}" == "${base_branch:t}" ]]; then
            base_branch=$(git -C "$git_folder" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
          fi
        fi
      fi
    fi
  else
    base_branch=$(git -C "$git_folder" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  fi
  
  if [[ -z "$base_branch" ]]; then
    print " fatal: could not determine base branch" >&2
    return 1;
  fi

  if [[ -n "$base_branch" ]]; then
    if (( get_base_branch_is_f )); then
      echo $(get_remote_branch_ -f "${base_branch:t}" "$git_folder")
    elif (( get_base_branch_is_o )); then
      echo $(get_remote_branch_ -o "${base_branch:t}" "$git_folder")
    else
      echo "${base_branch:t}"
    fi
    return 0;
  fi

  print " fatal: could not determine base branch" >&2
  return 1;
}

function get_default_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "fo" "" "$@")"
  # (( get_default_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local default_branch=$(git -C "$git_folder" config --get init.defaultBranch 2>/dev/null)
  if [[ -n "$default_branch" ]]; then
    default_branch=$(get_remote_branch_ -f "$default_branch" "$git_folder")
  fi
  
  if [[ -z "$default_branch" ]]; then
    default_branch=$(git -C "$git_folder" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    
    if [[ -z "$default_branch" ]]; then
      default_branch=$(get_main_branch_ -f "$git_folder")
    fi
  fi

  if [[ -n "$default_branch" ]]; then
    if (( get_default_branch_is_f )); then
      echo "$default_branch"
    elif (( get_default_branch_is_o )); then
      echo "${default_branch:h:t}/${default_branch:t}"
    else
      echo "${default_branch:t}"
    fi
    return 0;
  fi

  print " fatal: could not determine default branch" >&2
  return 1;
}

function get_repo_() {
  local folder="${1-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$git_folder")
  local remote_repo=$(git -C "$git_folder" remote get-url "$remote_name" 2>/dev/null)

  if [[ -n "$remote_repo" ]]; then
    echo "$remote_repo"
    return 0;
  fi

  print " fatal: could not determine upstream repository" >&2
  return 1;
}

function get_repo_name_() {
  local uri="$1"

  local repo=""

  uri="${uri%.git}"

  if [[ "$uri" == git@*:* ]]; then
    repo="${uri##*:}"
  elif [[ "$uri" == http*://* ]]; then
    repo="${uri#*://*/}"
  fi

  echo "$repo"
}

function select_branches_() {
  set +x
  eval "$(parse_flags_ "$0" "alrix" "" "$@")"
  (( select_branches_is_debug )) && set -x

  local search_arg="$1"
  local folder="${2:-$PWD}"
  local exclude_branches=(${@:3})

  local remote_name=$(get_remote_origin_ "$folder")

  local branch_results=()

  local search_text="*$search_arg*"

  if [[ -n "$search_arg" ]] && (( select_branches_is_x )); then
    search_text="$search_arg"
  fi

  if (( select_branches_is_a_a )); then
    branch_results=("${(@f)$(git -C "$folder" branch --all --list "$search_text" -i --no-column --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  elif (( select_branches_is_r )); then
    branch_results=("${(@f)$(git -C "$folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | grep -i "$search_text" \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$folder" branch --list "$search_text" -i --no-column --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  fi

  local branches_excluded=("$exclude_branches")

  if (( ! select_branches_is_a )); then
    branches_excluded+=("main" "master" "dev" "develop" "stage" "staging" "prod" "production" "release")
    if (( select_branches_is_r )); then
      branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
    fi
  fi

  local filtered_branches=()

  if [[ -n "$branches_excluded" && -n "$branch_results" ]]; then
    local branch=""
    for branch in "${branch_results[@]}"; do
      if [[ ! " ${branches_excluded[*]} " == *" $branch "* ]]; then
        filtered_branches+=("$branch")
      fi
    done
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    if (( ! select_branches_is_q )); then
      if (( ! select_branches_is_a )); then
        print -n " fatal: not including all branches," >&2
      else
        print -n " fatal:" >&2
      fi

      if [[ -n "$search_arg" ]]; then
        if (( select_branches_is_x )); then
          print -n " did not match any branch known to git: $search_arg" >&2
        else
          print -n " did not match any branch known to git matching: $search_arg" >&2
        fi
      else
        print -n " did not find any branch known to git" >&2
      fi
      print "" >&2
    fi
    return 1;
  fi

  local branch_choices=""
  if (( select_branches_is_i || ${#filtered_branches[@]} == 1 )); then
    branch_choices=$(choose_multiple_ -i "branches" $filtered_branches)
  else
    branch_choices=$(choose_multiple_ "branches" $filtered_branches)
  fi
  if (( $? == 130 )); then return 130; fi

  echo "${branch_choices[@]}"
}

function select_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "alriexscm" "" "$@")"
  (( select_branch_is_debug )) && set -x

  local search_arg="$1"
  local header="${2-branch}"
  local folder="${3:-$PWD}"

  local git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
  if [[ -z "$git_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$git_folder")
  local branch_results=()

  local search_text="*$search_arg*"

  if [[ -n "$search_arg" ]] && (( select_branch_is_x )); then
    search_text="$search_arg"
  fi

  if (( select_branch_is_a )); then
    branch_results=("${(@f)$(git -C "$git_folder" branch --all --list "$search_text" -i --no-column --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  elif (( select_branch_is_r )); then
    branch_results=("${(@f)$(git -C "$git_folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | sed "s#^$remote_name/##" \
      | grep -i "$search_arg" \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$git_folder" branch --list "$search_text" -i --no-column --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  fi

  local branches_excluded=()

  if (( select_branch_is_m )); then
    local my_branch=$(get_my_branch_ "$git_folder" 2>/dev/null)
    if [[ -n "$my_branch" ]]; then
      branches_excluded+=("$my_branch")
    fi
  fi

  if (( select_branch_is_s )); then
    branches_excluded+=("main" "master" "dev" "develop" "stage" "staging" "prod" "production" "release")
    if (( select_branch_is_r )); then
      branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
    fi
  fi

  local filtered_branches=()

  if [[ -n "$branches_excluded" && -n "$branch_results" ]]; then
    local branch=""
    for branch in "${branch_results[@]}"; do
      if [[ ! " ${branches_excluded[*]} " == *" $branch "* ]]; then
        filtered_branches+=("$branch")
      fi
    done
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    if (( select_branch_is_s )); then
      print -n " fatal: excluding special branches, " >&2
    else
      print -n " fatal: " >&2
    fi

    print -n "did not find " >&2

    if (( select_branch_is_a )); then
      print -n "any branch " >&2
    elif (( select_branch_is_r )); then
      print -n "an upstream branch " >&2
    else
      print -n "a local branch " >&2
    fi

    print -n "known to git " >&2

    if [[ -n "$search_arg" ]]; then
      if (( select_branch_is_x )); then
        print -n ": $search_arg" >&2
      else
        print -n "matching: $search_arg" >&2
      fi
    fi
    print "" >&2
    return 1;
  fi

  # return current branch if found and it's the only one
  if (( select_branch_is_c )); then
    local current_branch=$(get_my_branch_ "$git_folder" 2>/dev/null)
    if (( ${#filtered_branches[@]} == 1 )) && [[ -n "$current_branch" && "${filtered_branches[1]}" == "$current_branch" ]]; then
      echo "$current_branch"
      return 0;
    fi
  fi

  # return exact one branch if found, if not, return 1
  if (( select_branch_is_e )); then
    if (( ${#filtered_branches[@]} == 1 )); then
      echo "${filtered_branches[1]}"
      return 0;
    fi
    return 1;
  fi

  local branch_choice=""

  if (( ${#filtered_branches[@]} > 20 )); then
    branch_choice=$(filter_one_ "$header" $filtered_branches)
  else
    if (( select_branch_is_i )); then
      branch_choice=$(choose_one_ -i "$header" $filtered_branches)
    else
      branch_choice=$(choose_one_ "$header" $filtered_branches)
    fi
  fi
  if (( $? == 130 )); then return 130; fi

  echo "$branch_choice"
}

function select_pr_() {
  local search_text="$1"
  local repo="$2"
  local header="${3:-"pull request"}"

  if ! command -v gh &>/dev/null; then return 1; fi

  local pr_list
  # local pr_list=$(gh pr list --repo "$repo" | grep -i "$search_text" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}' 2>/dev/null)
  if command -v gum &>/dev/null; then
    pr_list=$(gum spin --title="fetching pull requests..." -- gh pr list --repo "$repo" --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)
  else
    pr_list=$(gh pr list --repo "$repo" --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)
  fi

  if [[ -z "$pr_list" ]]; then return 1; fi

  local count=$(echo "$pr_list" | wc -l)
  local titles=("${(@f)$(echo "$pr_list" | cut -f2)}")

  local select_pr_title=""
  select_pr_title=$(choose_one_ "$header" "${titles[@]}")
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$select_pr_title" ]]; then return 1; fi

  local select_pr_choice=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}' | xargs 2>/dev/null)
  local select_pr_branch=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}' | xargs 2>/dev/null)

  echo "${select_pr_choice}|${select_pr_branch}|${select_pr_title}"
}

function select_prs_() {
  local search_text="$1"
  local repo="$2"
  local header="${3:-"pull requests"}"

  if ! command -v gh &>/dev/null; then return 1; fi

  local pr_list
  if command -v gum &>/dev/null; then
    pr_list=$(gum spin --title="fetching pull requests..." -- gh pr list --repo "$repo" --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)
  else
    pr_list=$(gh pr list --repo "$repo" --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)
  fi

  if [[ -z "$pr_list" ]]; then
    print " no pull requests for repo: $repo" >&2
    return 1;
  fi

  # local count=$(echo "$pr_list" | wc -l)
  local titles=("${(@f)$(echo "$pr_list" | cut -f2)}")

  local select_pr_titles=""
  select_pr_titles=("${(@f)$(choose_multiple_ "$header" "${titles[@]}")}")
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$select_pr_titles" ]]; then return 1; fi

  local select_pr_title=""
  for select_pr_title in "${select_pr_titles[@]}"; do
    local select_pr_choice=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}' | xargs 2>/dev/null)
    local select_pr_branch=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}' | xargs 2>/dev/null)

    echo "${select_pr_choice}|${select_pr_branch}|${select_pr_title}"
  done
}

function get_from_pkg_json_() {
  local key_name="${1:-"name"}"
  local folder="${2:-$PWD}"

  local real_folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$real_folder" ]]; then
    print " fatal: not a valid folder: $folder" >&2
    return 1;
  fi
  
  local value="";
  local file="${real_folder}/package.json"

  if [[ -f "$file" ]]; then
    if command -v jq &>/dev/null; then
      value=$(jq -r --arg key "$key_name" '.[$key] // empty' "$file")
    else
      # Escape the key for safe regex matching
      local escaped_key=$(printf '%s\n' "$key_name" | sed 's/[][\.*^$/]/\\&/g')

      # Use grep with improved quoting and fallback to sed
      value=$(grep -E "\"$escaped_key\"[[:space:]]*:[[:space:]]*\"" "$file" | \
              head -1 | \
              sed -E "s/.*\"$escaped_key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/")
    fi
    echo "$value"
    return 0;
  fi

  return 1;
}

function get_script_from_pkg_json_() {
  local key_name="$1"
  local folder="${2:-$PWD}"

  local pkg_json="package.json"
  local section="scripts"

  local real_file="$(realpath -- "${folder}/${pkg_json}" 2>/dev/null)"

  if [[ -z "$real_file" ]]; then return 1; fi

  local value=""

  if command -v jq &>/dev/null; then
    if [[ -n "$section" ]]; then
      value=$(jq -r --arg section "$section" --arg key "$key_name" '.[$section][$key] // empty' "$real_file")
    else
      value=$(jq -r --arg key "$key_name" '.[$key] // empty' "$real_file")
    fi
  else
    # Escape the key for safe regex matching
    local escaped_key=$(printf '%s\n' "$key_name" | sed 's/[][\.*^$/]/\\&/g')

    # Use grep with improved quoting and fallback to sed
    value=$(grep -E "\"$escaped_key\"[[:space:]]*:[[:space:]]*\"" "$real_file" | \
            head -1 | \
            sed -E "s/.*\"$escaped_key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/")
  fi

  echo "$value"
}

function load_config_entry_() {
  set +x

  local i="$1"

  if [[ -z "$i" ]]; then
    print " fatal: load_config_entry_ missing index" >&2
    return 1;
  fi

  local keys=(
    PUMP_SINGLE_MODE
    PUMP_PKG_MANAGER
    PUMP_CODE_EDITOR
    PUMP_CLONE
    PUMP_SETUP
    PUMP_FIX
    PUMP_RUN
    PUMP_RUN_STAGE
    PUMP_RUN_PROD
    PUMP_PRO
    PUMP_USE
    PUMP_TEST
    PUMP_RETRY_TEST
    PUMP_COV
    PUMP_OPEN_COV
    PUMP_TEST_WATCH
    PUMP_E2E
    PUMP_E2EUI
    PUMP_PR_TEMPLATE_FILE
    PUMP_PR_REPLACE
    PUMP_PR_APPEND
    PUMP_PR_APPROVAL_MIN
    PUMP_INTERVAL
    PUMP_COMMIT_ADD
    PUMP_COMMIT_SIGNOFF
    PUMP_PRINT_README
    PUMP_PKG_NAME
    PUMP_JIRA_IN_PROGRESS
    PUMP_JIRA_IN_REVIEW
    PUMP_JIRA_DONE
    PUMP_NVM_SKIP_LOOKUP
    PUMP_NVM_USE_V
  )

  local key=""
  for key in "${keys[@]}"; do
    value=$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)

    # If the value is not set, provide default values for specific keys
    if [[ -z "$value" ]]; then
      case "$key" in
        PUMP_PKG_MANAGER)
          value="npm"
          ;;
        PUMP_USE)
          value="node"
          ;;
        PUMP_TEST)
          value="${PUMP_PKG_MANAGER[$i]} test"
          ;;
        PUMP_RETRY_TEST)
          value=0
          ;;
        PUMP_COV)
          value="${PUMP_PKG_MANAGER[$i]} run test:coverage"
          ;;
        PUMP_TEST_WATCH)
          value="${PUMP_PKG_MANAGER[$i]} run test:watch"
          ;;
        PUMP_E2E)
          value="${PUMP_PKG_MANAGER[$i]} run test:e2e"
          ;;
        PUMP_E2EUI)
          value="${PUMP_PKG_MANAGER[$i]} run test:e2e-ui"
          ;;
        PUMP_PR_APPEND)
          value=0
          ;;
        PUMP_INTERVAL)
          value=10
          ;;
        PUMP_PR_TEMPLATE_FILE)
          value=".github/pull_request_template.md"
          ;;
        *)
          continue
          ;;
      esac
    fi

    # store the value
    case "$key" in
      PUMP_SINGLE_MODE)
        PUMP_SINGLE_MODE[$i]="$value"
        ;;
      PUMP_PKG_MANAGER)
        if [[ -z "$value" ]]; then
          value="npm"
        fi
        PUMP_PKG_MANAGER[$i]="$value"
        ;;
      PUMP_CODE_EDITOR)
        PUMP_CODE_EDITOR[$i]="$value"
        ;;
      PUMP_CLONE)
        PUMP_CLONE[$i]="$value"
        ;;
      PUMP_SETUP)
        PUMP_SETUP[$i]="$value"
        ;;
      PUMP_FIX)
        PUMP_FIX[$i]="$value"
        ;;
      PUMP_RUN)
        PUMP_RUN[$i]="$value"
        ;;
      PUMP_RUN_STAGE)
        PUMP_RUN_STAGE[$i]="$value"
        ;;
      PUMP_RUN_PROD)
        PUMP_RUN_PROD[$i]="$value"
        ;;
      PUMP_PRO)
        PUMP_PRO[$i]="$value"
        ;;
      PUMP_USE)
        PUMP_USE[$i]="$value"
        ;;
      PUMP_TEST)
        PUMP_TEST[$i]="$value"
        ;;
      PUMP_RETRY_TEST)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_RETRY_TEST[$i]="$value"
        ;;
      PUMP_COV)
        PUMP_COV[$i]="$value"
        ;;
      PUMP_OPEN_COV)
        PUMP_OPEN_COV[$i]="$value"
        ;;
      PUMP_TEST_WATCH)
        PUMP_TEST_WATCH[$i]="$value"
        ;;
      PUMP_E2E)
        PUMP_E2E[$i]="$value"
        ;;
      PUMP_E2EUI)
        PUMP_E2EUI[$i]="$value"
        ;;
      PUMP_PR_TEMPLATE_FILE)
        PUMP_PR_TEMPLATE_FILE[$i]="$value"
        ;;
      PUMP_PR_REPLACE)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_PR_REPLACE[$i]="$value"
        ;;
      PUMP_PR_APPEND)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_PR_APPEND[$i]="$value"
        ;;
      PUMP_PR_APPROVAL_MIN)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_PR_APPROVAL_MIN[$i]="$value"
        ;;
      PUMP_INTERVAL)
        if [[ "$value" != <-> ]]; then
          value=10
        fi
        PUMP_INTERVAL[$i]="$value"
        ;;
      PUMP_COMMIT_ADD)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_COMMIT_ADD[$i]="$value"
        ;;
      PUMP_COMMIT_SIGNOFF)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_COMMIT_SIGNOFF[$i]="$value"
        ;;
      PUMP_PRINT_README)
        if [[ "$value" != <-> ]]; then
          value=0
        fi
        PUMP_PRINT_README[$i]="$value"
        ;;
      PUMP_PKG_NAME)
        PUMP_PKG_NAME[$i]="$value"
        ;;
      PUMP_JIRA_IN_PROGRESS)
        PUMP_JIRA_IN_PROGRESS[$i]="$value"
        ;;
      PUMP_JIRA_IN_REVIEW)
        PUMP_JIRA_IN_REVIEW[$i]="$value"
        ;;
      PUMP_JIRA_DONE)
        PUMP_JIRA_DONE[$i]="$value"
        ;;
      PUMP_NVM_SKIP_LOOKUP)
        PUMP_NVM_SKIP_LOOKUP[$i]="$value"
        ;;
      PUMP_NVM_USE_V)
        PUMP_NVM_USE_V[$i]="$value"
        ;;
    esac
    # print "$i - key: [$key], value: [$value]"
  done
}

function load_settings_() {
  check_settings_file_

  PUMP_PUSH_NO_VERIFY=$(sed -n "s/^PUMP_PUSH_NO_VERIFY${i}=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)
  if [[ "$PUMP_PUSH_NO_VERIFY" -ne 0 && "$PUMP_PUSH_NO_VERIFY" -ne 1 ]]; then
    PUMP_PUSH_NO_VERIFY=""
  fi

  PUMP_PUSH_SET_UPSTREAM=$(sed -n "s/^PUMP_PUSH_SET_UPSTREAM${i}=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)
  if [[ "$PUMP_PUSH_SET_UPSTREAM" -ne 0 && "$PUMP_PUSH_SET_UPSTREAM" -ne 1 ]]; then
    PUMP_PUSH_SET_UPSTREAM=""
  fi

  PUMP_RUN_OPEN_COV=$(sed -n "s/^PUMP_RUN_OPEN_COV${i}=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)
  if [[ "$PUMP_RUN_OPEN_COV" -ne 0 && "$PUMP_RUN_OPEN_COV" -ne 1 ]]; then
    PUMP_RUN_OPEN_COV=""
  fi

  PUMP_USE_MONOGRAM=$(sed -n "s/^PUMP_USE_MONOGRAM${i}=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)
  if [[ "$PUMP_USE_MONOGRAM" -ne 0 && "$PUMP_USE_MONOGRAM" -ne 1 ]]; then
    PUMP_USE_MONOGRAM=""
  fi

  PUMP_PR_TITLE_FORMAT=$(sed -n 's/^PUMP_PR_TITLE_FORMAT[[:space:]]*="\(.*\)"/\1/p' "$PUMP_SETTINGS_FILE" 2>/dev/null)
  if [[ -z "$PUMP_PR_TITLE_FORMAT" ]]; then
    PUMP_PR_TITLE_FORMAT="{jira_key} {commit_message}"
  fi
}

function load_config_() {
  load_config_entry_ 0
  # Iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    proj_cmd=$(sed -n "s/^PUMP_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    [[ -z "$proj_cmd" ]] && continue;  # skip if not defined

    if ! validate_proj_cmd_strict_ $i "$proj_cmd"; then
      print "  ${red_cor}in config: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print "  edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project repo
    local proj_repo=""
    proj_repo=$(sed -n "s/^PUMP_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_REPO_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project folder path
    local proj_folder=""
    proj_folder=$(sed -n "s/^PUMP_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_FOLDER_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    [[ -z "$proj_folder" ]] && continue;  # skip if not defined

    # if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then
    #   print "  ${red_cor}in config: PUMP_FOLDER_${i}${reset_cor}" 2>/dev/tty
    #   print "  edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
    # fi

    PUMP_REPO[$i]="$proj_repo"
    PUMP_SHORT_NAME[$i]="$proj_cmd"
    PUMP_FOLDER[$i]="$proj_folder"

    load_config_entry_ $i
  done
}

function get_branch_status_() {
  local my_branch="$1"
  local base_branch="$2"
  local folder="${3:-$PWD}"
  
  read behind ahead < <(git -C "$folder" rev-list --left-right --count ${base_branch}...HEAD)

  echo "${behind}|${ahead}"
}

function del_file_() {
  local file="$1"
  local count="$2"

  if [[ -z "$file" ]]; then
    return 0;
  fi

  local type=""
  if [[ -L "$file" ]]; then
    type="symlink"
  elif [[ -d "$file" ]]; then
    type="folder"
  else
    type="file"
  fi

  local RET=0

  if (( count <= 3 )) && [[ "${file:t}" != ".DS_Store" ]]; then;
    confirm_ "delete $type: ${blue_cor}$file${reset_cor}?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET != 0 )); then
      print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
      return 0;
    fi
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $file" -- rm -rf -- "$file"
    RET=$?
  else
    print "deleting... $file"
    rm -rf -- "$file"
    RET=$?
  fi

  if (( RET == 0 )); then
    if [[ "$file" == "$PWD" ]]; then
      print -l -- " ${yellow_cor}deleted${reset_cor} $file"
      cd ..
    else
      print -l -- " ${green_cor}deleted${reset_cor} $file"
    fi
    return 0;
  fi

  print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  return 1;
}

function del_file_s_() {
  local file="$1"

  if [[ -z "$file" ]]; then
    return 0;
  fi

  local type=""
  if [[ -L "$file" ]]; then
    type="symlink"
  elif [[ -d "$file" ]]; then
    type="folder"
  else
    type="file"
  fi

  local RET=0

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $file" -- rm -rf -- "$file"
    RET=$?
  else
    print "deleting... $file"
    rm -rf -- "$file"
    RET=$?
  fi

  if (( RET == 0 )); then
    if [[ "$file" == "$PWD" ]]; then
      print -l -- " ${yellow_cor}deleted${reset_cor} $file"
      cd ..
    else
      print -l -- " ${green_cor}deleted${reset_cor} $file"
    fi
    return 0;
  fi

  print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  return 1;
}

function del_files_() {
  local dont_ask=0
  local count=0
  local files=("$@")

  local RET=0
  local delete_all=0

  local file=""
  for file in "${files[@]}"; do
    ((count++))

    local a_file="" # abolute file path

    if [[ -L "$file" ]]; then
      a_file=$(realpath -- "$file" 2>/dev/null)
    else
      file=$(realpath -- "$file" 2>/dev/null)
    fi

    if (( count > 3 )); then
      if (( dont_ask == 0 && ${#files[@]} != count )); then
        dont_ask=1;
        confirm_ "delete all: ${blue_cor}${(j:, :)files[$count,-1]}${reset_cor}?"
        RET=$?
        if (( RET == 130 )); then
          break;
        elif (( RET == 1 )); then
          count=0
        else
          delete_all=1
        fi
      else
        count=0
      fi
    fi

    if [[ -n "$file" ]]; then
      if (( delete_all )); then
        del_file_s_ "$file" $count
      else
        del_file_ "$file" $count
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi

    if [[ -n "$a_file" ]]; then
      if (( delete_all )); then
        del_file_s_ "$file" $count
      else
        del_file_ "$file" $count
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi
  done

  return $RET;
}

function del_files_s_() {
  local files=("$@")

  local RET=0

  local file=""
  for file in "${files[@]}"; do
    local a_file="" # abolute file path

    if [[ -L "$file" ]]; then
      a_file=$(realpath -- "$file" 2>/dev/null)
    else
      file=$(realpath -- "$file" 2>/dev/null)
    fi

    if [[ -n "$file" ]]; then
      del_file_s_ "$file"
      RET=$?
    fi

    if [[ -n "$a_file" ]]; then
      del_file_s_ -s "$file"
      RET=$?
    fi
  done

  return $RET;
}


function del() {
  set +x
  if [[ -n "$1" ]]; then
    local is_folder=0
    local arg=""
    for arg in "$@"; do
      if [[ "$arg" == -[a-zA-Z] && -d "$arg" ]]; then
        is_folder=1
        break;
      fi
    done

    if (( is_folder )); then
      eval "$(parse_single_flags_ "$0" "" "$@")"
    else
      eval "$(parse_single_flags_ "$0" "s" "$@")"
    fi
  fi

  (( del_is_debug )) && set -x

  if (( del_is_h )); then
    print "  ${hi_yellow_cor}del ${yellow_cor}[<glob>]${reset_cor} : delete files"
    print "  --"
    print "  ${hi_yellow_cor}del -s${reset_cor} : skip confirmation"
    return 0;
  fi

  rm -rf -- ".DS_Store"

  local files=()

  if [[ -z "$1" ]]; then
    setopt null_glob
    setopt dot_glob
    # setopt no_dot_glob

    # capture all files in current folder
    files=(*)

    # unsetopt null_glob
    # unsetopt dot_glob
    # unsetopt no_dot_glob

    if (( ${#files[@]} > 1 )); then
      files=("${(@f)$(choose_multiple_ "files to delete" "${files[@]}")}")
    fi
  else
    # capture all arguments (quoted or not) as a single pattern
    local pattern="$*"
    # expand the pattern — if it's a glob, this expands to matches
    files=(${(z)~pattern})
  fi

  # print "files[1] = ${files[1]}"
  # print "pattern $pattern"
  # print "qty ${#files[@]}"
  # print "files @ ${files[@]}"
  # print "files * ${files[*]}"
  # return 0;

  if (( ${#files[@]} == 0 )); then return 0; fi

  if (( del_is_s )); then
    del_files_s_ "${files[@]}"
  else
    del_files_ "${files[@]}"
  fi
}

function macdown() {
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( macdown_is_debug )) && set -x

  if (( macdown_is_h )); then
    print "  ${hi_yellow_cor}macdown${reset_cor} : download full installers of macos"
    return 0;
  fi

  if [[ "$(uname)" == "Darwin" ]]; then
    if ! command -v softwareupdate &>/dev/null; then
      print " fatal: softwareupdate command not found" >&2
      return 1;
    fi
  else
    print " fatal: macdown is only available on macOS" >&2
    return 1;
  fi

  local options=$(softwareupdate --list-full-installers 2>/dev/null | grep -E '^\* Title:' | sed -E 's/^\* Title: (.*), Size:.*/\1/' 2>/dev/null)

  if [[ -z "$options" ]]; then
    options=$(sudo softwareupdate --list-full-installers 2>/dev/null | grep -E '^\* Title:' | sed -E 's/^\* Title: (.*), Size:.*/\1/' 2>/dev/null)
    
    if [[ -z "$options" ]]; then
      print " fatal: no macOS updates available, try again later" >&2
      return 1;
    fi
  fi

  local choice=$(choose_one_ "macOS version to install" "${(@f)options}")
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$choice" ]]; then return 1; fi

  local version=""

  if [[ $choice =~ 'Version: ([0-9]+(\.[0-9]+){0,2})' ]]; then
    version="${match[1]}"
  fi

  if [[ -z "$version" ]]; then
    print " fatal: could not determine version from choice: $choice" >&2
    return 1;
  fi

  sudo softwareupdate --fetch-full-installer --full-installer-version $version
}

function upgrade() {
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( upgrade_is_debug )) && set -x

  if (( upgrade_is_h )); then
    print "  ${hi_yellow_cor}upgrade${reset_cor} : upgrade pump and Oh My Zsh!"
    return 0;
  fi

  update_ -f
  omz update
}

function fix() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( fix_is_debug )) && set -x

  if (( fix_is_h )); then
    print "  ${hi_yellow_cor}fix ${yellow_cor}[<folder>]${reset_cor} : run fix script or format + lint"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}fix -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_pkg_ "$folder"; then return 1; fi

  local _pwd="$(pwd)"

  add-zsh-hook -d chpwd pump_chpwd_
  cd "$folder"

  local pump_fix="$CURRENT_PUMP_FIX"
  local RET=0

  if [[ -n "$pump_fix" ]]; then
    eval "$pump_fix"
    RET=$?
  else
    local pkg_manager="$CURRENT_PUMP_PKG_MANAGER$([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo " run")"

    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      local _fix=$(get_script_from_pkg_json_ "fix" "$folder")
      local _lintfix=$(get_script_from_pkg_json_ "lint:fix" "$folder")
      local _formatfix=$(get_script_from_pkg_json_ "format:fix" "$folder")

      local _prettier="${_formatfix:-$(get_script_from_pkg_json_ "prettier" "$folder")}"
      local _eslint="${_lintfix:-$(get_script_from_pkg_json_ "eslint" "$folder")}"
      local _lint="${_eslint:-$(get_script_from_pkg_json_ "lint" "$folder")}"
      local _format="${_prettier:-$(get_script_from_pkg_json_ "format" "$folder")}"

      if [[ -n "$_fix" ]]; then
        eval "$pkg_manager fix"
        RET=$?
      elif [[ -n "$_format" && -n "$_lint" ]]; then
        if eval "$pkg_manager format"; then
          if eval "$pkg_manager lint"; then
            if eval "$pkg_manager format"; then
              RET=0
            fi
          fi
        fi
      elif [[ -n "$_format" ]]; then
        eval "$pkg_manager format"
        RET=$?
      elif [[ -n "$_lint" ]]; then
        eval "$pkg_manager lint"
        RET=$?
      else
        print " fatal: missing \"fix\", \"format\" and \"lint\" scripts in package.json" >&2
        RET=1
      fi
    fi
  fi

  cd "$_pwd"
  add-zsh-hook chpwd pump_chpwd_

  return $RET;
}

# muti-task functions =========================================================
function refix() {
  set +x
  eval "$(parse_flags_ "$0" "np" "q" "$@")"
  (( refix_is_debug )) && set -x

  if (( refix_is_h )); then
    print "  ${hi_yellow_cor}refix ${yellow_cor}[<folder>]${reset_cor} : run fix lint and format on last commit"
    print "  --"
    print "  ${hi_yellow_cor}refix -n${reset_cor} : create a new commit instead of amending"
    print "  ${hi_yellow_cor}refix -p${reset_cor} : push after commit"
    print "  ${hi_yellow_cor}refix -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}refix -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  if ! is_folder_pkg_ "$folder"; then return 1; fi

  local amend=0
  local cannot_amend=0
  local commit_msg="style: lint and format"

  if (( ! refix_is_n )); then
    amend=1
  fi

  if (( amend )); then
    local last_commit_msg=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs 2>/dev/null)
    if [[ -z "$last_commit_msg" ]]; then last_commit_msg=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs -0 2>/dev/null); fi

    if [[ -z "$last_commit_msg" ]]; then
      print " ${red_cor}fatal: last commit message is empty, cannot amend${reset_cor}" >&2
      return 1;
    fi

    if [[ $last_commit_msg == Merge* ]]; then
      cannot_amend=1
      amend=0
    else
      commit_msg="$last_commit_msg"
    fi
  fi

  local RET=0

  if (( refix_is_q )); then
    if command -v gum &>/dev/null; then
      unsetopt monitor
      unsetopt notify
      local pipe_name=$(mktemp -u)
      mkfifo "$pipe_name" &>/dev/null
      gum spin --title="refixing... \"$commit_msg\"" -- sh -c "read < $pipe_name" &
      local spin_pid=$!

      fix "$folder" &>/dev/null
      RET=$?
      
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null
      setopt notify
      setopt monitor
    else
      fix "$folder" &>/dev/null
      RET=$?
    fi
  else
    fix "$folder"
    RET=$?
  fi

  if (( RET != 0 )); then
    print "" >&2
    print " ${red_cor}fatal: refix encountered an issue${reset_cor}" >&2

    return $RET;
  fi

  if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( ! refix_is_q )); then
      print "" >&2
      print " nothing to commit, working tree clean" >&2
    fi
    return 0
  fi

  if (( cannot_amend && ! refix_is_q )); then
    print " ${yellow_cor}warning: last commit is a merge commit, refix must create a new commit${reset_cor}" >&2
  fi

  if ! git -C "$folder" add .; then return 1; fi

  if (( amend )); then
    if ! git -C "$folder" commit --no-verify --amend --message="$commit_msg" $@; then return 1; fi
  else
    if ! git -C "$folder" commit --no-verify --message="$commit_msg" $@; then return 1; fi
  fi

  if (( refix_is_p )); then
    pushf "$folder" $@
  fi
}

function covc_() {
  eval "$(parse_flags_ "$0" "x" "" "$@")"

  if ! command -v gum &>/dev/null; then
    print " fatal: command requires gum" >&2
    print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
    return 1;
  fi

  if ! is_folder_pkg_ "$PWD"; then return 1; fi
  if ! is_folder_git_ "$PWD"; then return 1; fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")
  (( i )) || return 1;

  if ! check_proj_ -frvmp $i; then return 1; fi 

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local pump_cov="${PUMP_COV[$i]}"
  local pump_setup="${PUMP_SETUP[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " ${red_cor}PUMP_REPO_$i is missing${reset_cor}" >&2
    print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  if [[ -z "$pump_cov" ]]; then
    print " ${red_cor}PUMP_COV_$i is missing${reset_cor}" >&2
    print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch_arg="$1"

  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$PWD" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}cov -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local remote_branch_arg=$(get_remote_branch_ "$branch_arg" "$PWD")

  if [[ -z "$remote_branch_arg" ]]; then
    print " fatal: not a valid branch argument" >&2
    print " run ${hi_yellow_cor}cov -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local my_branch=$(get_my_branch_ "$PWD")
  if [[ -z "$my_branch" ]]; then return 1; fi

  if [[ "$branch_arg" == "$my_branch" ]]; then
    print " branch argument is current branch: $my_branch" >&2
    return 1;
  fi

  local branch_status=(${(s:|:)$(get_branch_status_ "$my_branch" "$branch_arg" "$PWD" 2>/dev/null)})
  local branch_behind="${branch_status[1]:-0}"

  if (( branch_behind )); then
    print " ${yellow_cor}warning: your branch is behind $branch_arg by $branch_behind commits commits${reset_cor}" >&2
    if ! confirm_ "continue anyway?" "continue" "abort"; then
      return 1;
    fi
  fi

  local cov_folder="$(get_proj_special_folder_ -c "$proj_cmd" "$proj_folder" "$single_mode")"

  unsetopt monitor
  unsetopt notify

  local pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${my_branch}" -- sh -c "read < $pipe_name" &
  local spin_pid=$!

  if ! eval "$pump_setup" &>/dev/null; then
    echo "done" > "$pipe_name" &>/dev/null
    rm "$pipe_name"
    wait $spin_pid &>/dev/null

    print " ${red_cor}fatal: could not run setup script: $pump_setup ${reset_cor}" >&2
    return 1;
  fi

  if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
    # run twice just in case the first run fails
    if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null

      print " ${red_cor}fatal: could not run coverage script PUMP_COV_$i ${reset_cor}" >&2
      return 1;
    fi
  fi

  print "   running test coverage... ${my_branch}"

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  local summary2=$(grep -A 4 "Coverage summary" "coverage-summary.txt")

  # extract each coverage percentage
  local statements2=$(echo "$summary2" | grep "Statements" | awk '{print $3}' | tr -d '%')
  local branches2=$(echo "$summary2" | grep "Branches" | awk '{print $3}' | tr -d '%')
  local funcs2=$(echo "$summary2" | grep "Functions" | awk '{print $3}' | tr -d '%')
  local lines2=$(echo "$summary2" | grep "Lines" | awk '{print $3}' | tr -d '%')

  rm -f -- "coverage-summary.txt" &>/dev/null

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${branch_arg}" -- sh -c "read < $pipe_name" &
  spin_pid=$!

  if is_folder_git_ "$cov_folder" &>/dev/null; then
    reseta -o "$cov_folder" --quiet &>/dev/null
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: could not clone project repo: $proj_repo" >&2
      return 1;
    fi
  fi

  if git -C "$cov_folder" switch "$branch_arg" --quiet &>/dev/null; then
    if ! pullr "$cov_folder" --quiet &>/dev/null; then
      rm -rf -- "$cov_folder" &>/dev/null
      git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
      if (( $? != 0 )); then
        print " fatal: could not clone project repo: $proj_repo" >&2
        return 1;
      fi
    fi
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: could not clone project repo: $proj_repo" >&2
      return 1;
    fi
  fi

  add-zsh-hook -d chpwd pump_chpwd_
  pushd "$cov_folder" &>/dev/null
  
  if [[ -n "$pump_clone" ]]; then
    eval "$pump_clone" &>/dev/null;
  fi

  if [[ -z "$pump_setup" ]]; then
    pump_setup=$(get_script_from_pkg_json_ "setup" "$cov_folder")
    if [[ -n "$pump_setup" ]]; then
      pump_setup="$pkg_manager run setup"
    else
      pump_setup="$pkg_manager install"
    fi
  fi

  if ! eval "$pump_setup" &>/dev/null; then
    echo "done" > "$pipe_name" &>/dev/null
    rm "$pipe_name"
    wait $spin_pid &>/dev/null

    print " ${red_cor}fatal: could not run setup script: $pump_setup ${reset_cor}" >&2
    popd &>/dev/null
    add-zsh-hook chpwd pump_chpwd_
    return 1;
  fi

  if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
    # run twice just in case the first run fails
    if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null

      print " ${red_cor}fatal: could not run coverage script: $pump_cov ${reset_cor}" >&2
      popd &>/dev/null
      add-zsh-hook chpwd pump_chpwd_
      return 1;
    fi
  fi

  print "   running test coverage... ${branch_arg}"

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  local summary1=$(grep -A 4 "Coverage summary" "coverage-summary.txt")

  # extract each coverage percentage
  local statements1=$(echo "$summary1" | grep "Statements" | awk '{print $3}' | tr -d '%')
  local branches1=$(echo "$summary1" | grep "Branches" | awk '{print $3}' | tr -d '%')
  local funcs1=$(echo "$summary1" | grep "Functions" | awk '{print $3}' | tr -d '%')
  local lines1=$(echo "$summary1" | grep "Lines" | awk '{print $3}' | tr -d '%')

  rm -f -- "coverage-summary.txt" &>/dev/null

  popd &>/dev/null
  add-zsh-hook chpwd pump_chpwd_

  if ! git switch "$my_branch" --quiet &>/dev/null; then
    print " did not match any branch known to git: $branch_arg" >&2
    return 1;
  fi

  print ""
  display_line_ "coverage" "${hi_gray_cor}" 68
  display_double_line_ "${1:0:22}" "${hi_gray_cor}" "${my_branch:0:22}" "${hi_gray_cor}" 70
  print ""
  
  local spaces1="24s"
  local spaces2="23s"
  local color=""

  if [[ $statements1 -gt $statements2 ]]; then color="${red_cor}"; elif [[ $statements1 -lt $statements2 ]]; then color="${green_cor}"; else color=""; fi
  printf "  %-$spaces1 %s" "Statements" "$(printf "%.2f" $statements1)%"
  printf "  | "
  printf " %-$spaces2 ${color}%s${reset_cor}\n" "Statements" "$(printf "%.2f" $statements2)%"

  if [[ $branches1 -gt $branches2 ]]; then color="${red_cor}"; elif [[ $branches1 -lt $branches2 ]]; then color="${green_cor}"; else color=""; fi
  printf "  %-$spaces1 %s" "Branches" "$(printf "%.2f" $branches1)%"
  printf "  | "
  printf " %-$spaces2 ${color}%s${reset_cor}\n" "Branches" "$(printf "%.2f" $branches2)%"
  
  if [[ $funcs1 -gt $funcs2 ]]; then color="${red_cor}"; elif [[ $funcs1 -lt $funcs2 ]]; then color="${green_cor}"; else color=""; fi
  printf "  %-$spaces1 %s" "Functions" "$(printf "%.2f" $branches1)%"
  printf "  | "
  printf " %-$spaces2 ${color}%s${reset_cor}\n" "Functions" "$(printf "%.2f" $branches2)%"

  if [[ $lines1 -gt $lines2 ]]; then color="${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then color="${green_cor}"; else color=""; fi
  printf "  %-$spaces1 %s" "Lines" "$(printf "%.2f" $lines1)%"
  printf "  | "
  printf " %-$spaces2 ${color}%s${reset_cor}\n" "Lines" "$(printf "%.2f" $lines2)%"

  local markdown=(
    "#### Coverage"
    "| \`${branch_arg}\` | \`${my_branch}\` |"
    "| --- | --- |"
    "| Statements: $(printf "%.2f" $statements1)% | Statements: $(printf "%.2f" $statements2)% |"
    "| Branches: $(printf "%.2f" $branches1)% | Branches: $(printf "%.2f" $branches2)% |"
    "| Functions: $(printf "%.2f" $funcs1)% | Functions: $(printf "%.2f" $funcs2)% |"
    "| Lines: $(printf "%.2f" $lines1)% | Lines: $(printf "%.2f" $lines2)% |"
  )

  print ""
  printf "%s\n" "${markdown[@]}"
  print ""

  setopt monitor
  setopt notify
}

# test functions =========================================================
function test() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( test_is_debug )) && set -x

  if (( test_is_h )); then
    print "  ${hi_yellow_cor}test${reset_cor} : run PUMP_TEST"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$CURRENT_PUMP_TEST" && "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER test" ]]; then
    test_script="$CURRENT_PUMP_TEST"
  else
    test_script=$(get_script_from_pkg_json_ "test")
  fi

  (eval "$CURRENT_PUMP_TEST" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test passed on first run${reset_cor}"
    return 0
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_TEST" $@)
    RET=$?

    if (( RET == 0 )); then
      print " ${green_cor}✓ test passed on second run${reset_cor}"
      return 0;
    fi
  fi
    
  print " ${red_cor}✗ test failed${reset_cor}" >&2
  
  trap - INT
  
  return 1;
}

function cov() {
  set +x
  eval "$(parse_flags_ "$0" "o" "" "$@")"
  (( cov_is_debug )) && set -x

  if [[ -z "$PUMP_RUN_OPEN_COV" ]]; then
    confirm_ "run PUMP_OPEN_COV script after coverage is done?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_RUN_OPEN_COV" 1
    else
      update_setting_ "PUMP_RUN_OPEN_COV" 0
    fi
  fi

  if (( cov_is_h )); then
    print "  ${hi_yellow_cor}cov <branch>${reset_cor} : compare test coverage with another branch"
    print "  ${hi_yellow_cor}cov${reset_cor} : run PUMP_COV"
    print "  --"
    (( PUMP_RUN_OPEN_COV )) && print "  ${hi_yellow_cor}cov -o${reset_cor} : do not run PUMP_OPEN_COV script after coverage is done"
    (( ! PUMP_RUN_OPEN_COV )) && print "  ${hi_yellow_cor}cov -o${reset_cor} : to run PUMP_OPEN_COV script after coverage is done"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    covc_ $@
    return $?;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  if ! is_folder_pkg_; then return 1; fi

  (eval "$CURRENT_PUMP_COV" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test coverage passed on first run${reset_cor}"

    if (( PUMP_RUN_OPEN_COV && ! cov_is_o )) || (( ! PUMP_RUN_OPEN_COV && cov_is_o )); then
      if [[ -z "$CURRENT_PUMP_OPEN_COV" ]]; then
        print " PUMP_OPEN_COV is not set" >&2
        print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
        return 1;
      fi
      eval "$CURRENT_PUMP_OPEN_COV"
    fi
    return 0;
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_COV" $@)
    RET=$?

    if (( RET == 0 )); then
      print " ${green_cor}✓ test coverage passed on second run${reset_cor}"
      
      if (( PUMP_RUN_OPEN_COV && ! cov_is_o )) || (( ! PUMP_RUN_OPEN_COV && cov_is_o )); then
        if [[ -z "$CURRENT_PUMP_OPEN_COV" ]]; then
          print " PUMP_OPEN_COV is not set" >&2
          print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
          return 1;
        fi
        eval "$CURRENT_PUMP_OPEN_COV"
      fi
      return 0;
    fi
  fi
    
  print " ${red_cor}✗ test coverage failed${reset_cor}" >&2
  
  trap - INT

  return 1;
}

function testw() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( testw_is_debug )) && set -x

  if (( testw_is_h )); then
    print "  ${hi_yellow_cor}testw${reset_cor} : run PUMP_TEST_WATCH"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  eval "$CURRENT_PUMP_TEST_WATCH" $@
}

function e2e() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( e2e_is_debug )) && set -x

  if (( e2e_is_h )); then
    print "  ${hi_yellow_cor}e2e${reset_cor} : run PUMP_E2E"
    print "  ${hi_yellow_cor}e2e <e2e_project>${reset_cor} : run PUMP_E2E --project <e2e_project>"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2E" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2E" $@
  fi
}

function e2eui() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( e2eui_is_debug )) && set -x

  if (( e2eui_is_h )); then
    print "  ${hi_yellow_cor}e2eui${reset_cor} : run PUMP_E2EUI"
    print "  ${hi_yellow_cor}e2eui ${yellow_cor}[<test_project>]${reset_cor} : run PUMP_E2EUI --project"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2EUI" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2EUI" $@
  fi
}

# github functions =========================================================
function add() {
  set +x
  eval "$(parse_flags_ "$0" "taqsb" "" "$@")"
  (( add_is_debug )) && set -x

  if (( add_is_h )); then
    print "  ${hi_yellow_cor}add ${yellow_cor}[<glob>]${reset_cor} : add files to index"
    print "  --"
    print "  ${hi_yellow_cor}add -a${reset_cor} : add all tracked and untracked files"
    print "  ${hi_yellow_cor}add -t${reset_cor} : add only tracked files"
    print "  ${hi_yellow_cor}add -ta${reset_cor} : add all tracked files (not untracked)"
    print "  ${hi_yellow_cor}add -q${reset_cor} : --quiet"
    print "  ${hi_yellow_cor}add -sb${reset_cor} : show git status in short-format"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  local files=()

  if [[ -z "$1" ]]; then
    setopt null_glob
    setopt dot_glob

    # add -t
    if (( add_is_t )); then
      files=("${(@f)$(git diff --name-only)}")
    else
      files=("${(@f)$(git status --porcelain | awk '$1 == "??" || $1 == "M" { print $2 }')}")
    fi

    if (( ! add_is_a && ${#files[@]} > 1 )); then
      files=("${(@f)$(choose_multiple_ "files to add" "${files[@]}")}")
    fi
  else
    local pattern="$*"
    files=(${(z)~pattern})
  fi

  if [[ -z "$files" ]]; then
    if (( ! add_is_q )); then
      print " no files to add" >&2
    fi
    return 0;
  fi

  git add -- "${files[@]}"

  if (( ! add_is_q )); then
    if (( add_is_s && add_is_b )); then
      st -sb
    else
      st
    fi
  fi
}

# remove files from index
function rem() {
  set +x
  eval "$(parse_flags_ "$0" "taqsb" "" "$@")"
  (( rem_is_debug )) && set -x

  if (( rem_is_h )); then
    print "  ${hi_yellow_cor}rem ${yellow_cor}[<glob>]${reset_cor} : remove files from index"
    print "  --"
    print "  ${hi_yellow_cor}rem -a${reset_cor} : remove all tracked and untracked files"
    print "  ${hi_yellow_cor}rem -t${reset_cor} : remove only tracked files"
    print "  ${hi_yellow_cor}rem -ta${reset_cor} : remove all tracked files (not untracked)"
    print "  ${hi_yellow_cor}rem -q${reset_cor} : --quiet"
    print "  ${hi_yellow_cor}rem -sb${reset_cor} : show git status in short-format"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  local files=()

  if [[ -z "$1" ]]; then
    setopt null_glob
    setopt dot_glob

    # rem -t
    if (( rem_is_t )); then
      files=("${(@f)$(git diff --name-only)}")
    else
      files=("${(@f)$(git diff --name-only --cached)}")
    fi

    if (( ! rem_is_a && ${#files[@]} > 1 )); then
      files=("${(@f)$(choose_multiple_ "files to remove" "${files[@]}")}")
      if [[ -z "$files" ]]; then return 0; fi;
    fi
  else
    local pattern="$*"
    files=(${(z)~pattern})
  fi

  if [[ -z "$files" ]]; then
    if (( ! rem_is_q )); then
      print " no files to remove" >&2
    fi
    return 0;
  fi

  local file=""
  for file in "${files[@]}"; do
    if git ls-files --error-unmatch -- "$file" &>/dev/null; then
      git rm --cached -- "$file"
    else
      git restore --staged -- "$file"
    fi
  done

  if (( ! rem_is_q )); then
    if (( rem_is_s && rem_is_b )); then
      st -sb
    else
      st
    fi
  fi
}

function reset1() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset1_is_debug )) && set -x

  if (( reset1_is_h )); then
    print "  ${hi_yellow_cor}reset1 ${yellow_cor}[<folder>]${reset_cor} : reset last commit"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reset1 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -1
  git -C "$folder" reset --quiet --soft HEAD~1 $@
}

function reset2() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset2_is_debug )) && set -x

  if (( reset2_is_h )); then
    print "  ${hi_yellow_cor}reset2 ${yellow_cor}[<folder>]${reset_cor} : reset 2 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reset2 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -2
  git -C "$folder" reset --quiet --soft HEAD~2 $@
}

function reset3() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset3_is_debug )) && set -x

  if (( reset3_is_h )); then
    print "  ${hi_yellow_cor}reset3 ${yellow_cor}[<folder>]${reset_cor} : reset 3 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reset3 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -3
  git -C "$folder" reset --quiet --soft HEAD~3 $@
}

function reset4() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset4_is_debug )) && set -x

  if (( reset4_is_h )); then
    print "  ${hi_yellow_cor}reset4 ${yellow_cor}[<folder>]${reset_cor} : reset 4 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reset4 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -4
  git -C "$folder" reset --quiet --soft HEAD~4 $@
}

function reset5() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset5_is_debug )) && set -x

  if (( reset5_is_h )); then
    print "  ${hi_yellow_cor}reset5 ${yellow_cor}[<folder>]${reset_cor} : reset 5 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reset5 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -5
  git -C "$folder" reset --quiet --soft HEAD~5 $@
}

function read_commits_() {
  set +x
  eval "$(parse_flags_ "$0" "tc" "" "$@")"
  (( read_commits_is_debug )) && set -x
  
  local my_branch="$1"
  local base_branch="$2"
  local folder="${3:-$PWD}"

  if [[ -z "$my_branch" ]]; then
    my_branch="HEAD"
  fi

  if [[ "${my_branch:t}" == "${base_branch:t}" ]]; then return 1; fi

  local pr_title_jira_key="-"
  local pr_title_rest=""

  git -C "$folder" --no-pager log --no-graph --oneline --no-merges --pretty=format:'%H%x1F%s%x00' \
    "${base_branch}..${my_branch}" | while IFS= read -r -d '' line; do
    
    local commit_hash="${line%%$'\x1F'*}"
    commit_hash="${commit_hash//$'\n'/}"
    
    local commit_message="${line#*$'\x1F'}"

    # print "commit_hash=[$commit_hash]"
    # print "commit_message=[$commit_message]"

    if [[ -z "$commit_hash" || -z "$commit_message" ]]; then
      continue;
    fi

    local commit_message_rest="$commit_message"
    local commit_jira_key=$(extract_jira_key_ "$commit_message")
    
    if [[ -n "$commit_jira_key" ]]; then
      commit_message_rest="${commit_message//$commit_jira_key/}"

      local rest="$commit_message_rest"

      local types="fix|feat|docs|refactor|test|chore|style|revert"
      if [[ $commit_message_rest =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}}):[[:space:]]*(.*)" ]]; then
        rest="${match[2]}"
      fi
      
      # we want the last jira key found to be the pr title
      pr_title_jira_key="$commit_jira_key"
      pr_title_rest=$(echo "$rest" | xargs 2>/dev/null)
      if [[ -z "$pr_title_rest" ]]; then
        pr_title_rest=$(echo "$rest" | xargs -0 2>/dev/null);
      fi
    fi

    if (( read_commits_is_c )); then
      echo "- $commit_hash - $commit_message_rest"
    fi
  done

  if (( read_commits_is_t )); then
    if [[ -z "$pr_title_rest" ]]; then
      pr_title_rest=$(echo "$commit_message" | xargs 2>/dev/null)
      if [[ -z "$pr_title_rest" ]]; then
        pr_title_rest=$(echo "$commit_message" | xargs -0 2>/dev/null);
      fi
    fi

    echo "$pr_title_jira_key|$pr_title_rest"
    return 0;
  fi

  if [[ -z "$commit_message" ]]; then
    print " fatal: no commits found, cannot create pull request" >&2
    return 1;
  fi
}

function extract_jira_key_() {
  local text="$1"
  local folder="$2"

  if [[ -n "$text" && $text =~ ([A-Z]+-[0-9]+) ]]; then
    local jira_key=$(echo "${match[1]}" | xargs 2>/dev/null)
    if [[ -z "$jira_key" ]]; then jira_key=$(echo "${match[1]}" | xargs -0 2>/dev/null); fi

    echo "$jira_key"
    return 0;
  fi

  if [[ -n "$folder" ]]; then
    local folder_name="$(basename "$folder")"
    if [[ -n "$folder_name" && $folder_name =~ ([A-Z]+-[0-9]+) ]]; then
      local jira_key=$(echo "${match[1]}" | xargs 2>/dev/null)
      if [[ -z "$jira_key" ]]; then jira_key=$(echo "${match[1]}" | xargs -0 2>/dev/null); fi
      
      echo "$jira_key"
      return 0;
    fi
  fi

  return 1;
}

function pr() {
  set +x
  eval "$(parse_flags_ "$0" "tslbfdec" "" "$@")"
  (( pr_is_debug )) && set -x

  if (( pr_is_h )); then
    print "  ${hi_yellow_cor}pr${reset_cor} : create pull request"
    print "  --"
    print "  ${hi_yellow_cor}pr -t${reset_cor} : run tests before creating pull request"
    print "  ${hi_yellow_cor}pr -s${reset_cor} : skip confirmation"
    print "  --"
    print "  ${hi_yellow_cor}pr -l${reset_cor} : set labels"
    print "  ${hi_yellow_cor}pr -lb${reset_cor} : set label type: bug"
    print "  ${hi_yellow_cor}pr -lf${reset_cor} : set label type: feature"
    print "  ${hi_yellow_cor}pr -ld${reset_cor} : set label type: documentation"
    print "  ${hi_yellow_cor}pr -le${reset_cor} : set label type: enhancement"
    print "  ${hi_yellow_cor}pr -lc${reset_cor} : set label type: devops or ci"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! command -v perl &>/dev/null; then
    print " fatal: command requires perl" >&2
    print " install perl: ${blue_cor}https://learn.perl.org/installing/${reset_cor}" >&2
    return 1;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  local my_branch=$(get_my_branch_ "$folder")
  if [[ -z "$my_branch" ]]; then return 1; fi

  local pr_link=$(gh pr view "$my_branch" --json url -q .url 2>/dev/null)

  if [[ -n "$pr_link" ]]; then
    gh pr view --web &>/dev/null
    print " pull request is up: ${blue_cor}$pr_link${reset_cor}" >&2
    return 0;
  fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")

  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    if (( pr_is_t )); then
      print " fatal: uncommitted changes detected, cannot create pull request" >&2
      return 1;
    fi

    if (( ! pr_is_s )); then
      confirm_ "uncommitted changes detected, abort or continue anyway?" "abort" "continue"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then return 0; fi
    fi
  fi

  local base_branch=$(get_base_branch_ -f "$folder" 2>/dev/null)
  if [[ -z "$base_branch" ]]; then
    base_branch=$(get_base_branch_ "$folder" 2>/dev/null)
    if [[ -n "$base_branch" ]]; then
      base_branch=$(get_base_branch_ -f "$folder" "$base_branch" 2>/dev/null)
    fi
    if [[ -z "$base_branch" ]]; then
      base_branch=$(get_main_branch_ -f "$folder" 2>/dev/null)
      if [[ -z "$base_branch" ]]; then
        print " fatal: could not determine base branch for pull request" >&2
        return 1;
      fi
    fi
  fi

  local pr_commit_msgs=("${(@f)$(read_commits_ -c "$my_branch" "$base_branch" "$folder")}")
  if [[ -z "$pr_commit_msgs" ]]; then return 1; fi

  local pr_field=(${(s:|:)$(read_commits_ -t "$my_branch" "$base_branch" "$folder")})
  local jira_key="${pr_field[1]}"
  local commit_message="${pr_field[2]}"
  if [[ -z "$commit_message" ]]; then return 1; fi

  if [[ "$jira_key" == "-" ]]; then jira_key=""; fi

  local pr_title=""

  # replace pr_title with PUMP_PR_TITLE_FORMAT's {jira_key} {commit_message} variables
  if [[ -n "$PUMP_PR_TITLE_FORMAT" ]]; then
    pr_title="${PUMP_PR_TITLE_FORMAT//\<jira_key\>/$jira_key}"
    pr_title="${pr_title//\<commit_message\>/$commit_message}"
  else
    if [[ -n "$jira_key" ]]; then
      pr_title="$jira_key $commit_message"
    else
      pr_title="$commit_message"
    fi
  fi

  local pr_labels=""

  if (( ! pr_is_s )); then
    pr_title=$(input_text_ "pull request title" "$pr_title" 255 "$pr_title")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -z "$pr_title" ]]; then return 1; fi
    print " ${purple_cor}pull request title:${reset_cor} $pr_title" >&2

    jira_key=$(extract_jira_key_ "$pr_title" "$PWD")
    if (( $? == 1 )) && [[ -n "$jira_key" ]]; then
      if [[ -n "$PUMP_PR_TITLE_FORMAT" ]]; then
        pr_title="${PUMP_PR_TITLE_FORMAT//\{jira_key\}/$jira_key}"
        pr_title="${pr_title//\{commit_message\}/$commit_message}"
      else
        pr_title="$jira_key $commit_message"
      fi
    fi
  fi

  local all_labels=()

  # pr -l
  if (( pr_is_l && ! pr_is_s )); then
    all_labels=("${(@f)$(gh label list --limit 30 | awk '{print $1}')}")
  fi
  
  if [[ -n "$all_labels" ]]; then
    local choose_labels=()
    for label in "${all_labels[@]}"; do
      # pr -lb
      if (( pr_is_b )) && [[ "$label" == "bug" || "$label" == "bugfix" || "$label" == "bug_fix" ]]; then
        choose_labels+=("$label")
      fi
      # pr -lf
      if (( pr_is_f )) && [[ "$label" == "feature" || "$label" == "feat" ]]; then
        choose_labels+=("$label")
      fi
      # pr -ld
      if (( pr_is_d )) && [[ "$label" == "documentation" || "$label" == "docs" ]]; then
        choose_labels+=("$label")
      fi
      # pr -lt
      if (( pr_is_t )) && [[ "$label" == "test" || "$label" == "tests" ]]; then
        choose_labels+=("$label")
      fi
      # pr -lc
      if (( pr_is_c )) && [[ "$label" == "devops" || "$label" == "ci" ]]; then
        choose_labels+=("$label")
      fi
      # pr -le
      if (( pr_is_e )) && [[ "$label" == "enhancement" || "$label" == "enhance" ]]; then
        choose_labels+=("$label")
      fi
    done
    
    if (( ! pr_is_s )) && [[ -z "$choose_labels" ]]; then
      choose_labels=("${(@f)$(choose_multiple_ "labels" "${all_labels[@]}")}")
      if (( $? == 130 )); then return 130; fi
    fi

    if [[ -n "$choose_labels" ]]; then
      pr_labels="${(j:,:)choose_labels}"
      print " ${purple_cor}labels:${reset_cor} $choose_labels" >&2
    fi
  fi

  local pr_body="${(F)pr_commit_msgs}"
  local updated_config=1

  if [[ -n "$CURRENT_PUMP_PR_TEMPLATE_FILE" && -f "$CURRENT_PUMP_PR_TEMPLATE_FILE" ]]; then
    local pr_template="$(cat "$CURRENT_PUMP_PR_TEMPLATE_FILE" 2>/dev/null)"

    if (( ! pr_is_s )) && [[ -z "$CURRENT_PUMP_PR_REPLACE" ]]; then
      if command -v gum &>/dev/null; then
        gum style --align=left --margin="0" --padding="0" --border=normal --width=72 --border-foreground 99 "$pr_template"
      else
        print ""
        print " ${purple_cor}pull request template:${reset_cor}"
        print " ${cyan_cor}${pr_template}${reset_cor}"
      fi

      local pr_replace=""
      pr_replace=$(input_text_ "placeholder text in the template where you want the body to be inserted")
      if (( $? == 130 || $? == 2 )); then return 130; fi
      
      if [[ -n "$pr_replace" ]] && (( i )); then
        confirm_ "replace it or append after it?" "replace" "append"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi

        update_config_ $i "PUMP_PR_REPLACE" "$pr_replace"
        update_config_ $i "PUMP_PR_APPEND" $RET
        updated_config=0
      fi
    fi

    if [[ -n "$pr_template" && -n "$CURRENT_PUMP_PR_REPLACE" ]]; then
      if (( CURRENT_PUMP_PR_APPEND )); then
        pr_body=$(env MARKER="$CURRENT_PUMP_PR_REPLACE" BODY="$pr_body" perl -pe '
          BEGIN {
            $marker = $ENV{"MARKER"};
            $insert = $ENV{"BODY"};
          }
          s/\Q$marker\E/$marker\n\n$insert\n/;
        ' <<< "$pr_template")
      else
        pr_body=$(env MARKER="$CURRENT_PUMP_PR_REPLACE" BODY="$pr_body" perl -pe '
          BEGIN {
            $marker = $ENV{"MARKER"};
            $insert = $ENV{"BODY"};
          }
          s/^\Q$marker\E\s*$/$insert/;
        ' <<< "$pr_template")
      fi
    fi

  fi

  if (( pr_is_t )); then
    local test_script=""

    if [[ -n "$CURRENT_PUMP_TEST" && "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER test" ]]; then
      test_script="$CURRENT_PUMP_TEST"
    else
      test_script=$(get_script_from_pkg_json_ "test")
    fi

    if [[ -n "$test_script" ]]; then
      test || return 1;
    fi
  fi

  # print -- "debugging purposes:"
  # print -- "${magenta_cor}jira_key:${reset_cor} $jira_key"
  # print -- "${magenta_cor}Title:${reset_cor} $pr_title"
  # print -- "${magenta_cor}Body:${reset_cor}"
  # print -- "$pr_body"

  # return 1;

  pushf || return 1;

  if gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --base="${base_branch:t}" --label="$pr_labels"; then
    if [[ -n "$jira_key" && -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      proj_jira_ -r "$CURRENT_PUMP_SHORT_NAME" "$jira_key"
    fi
    return 0;
  fi

  return 1;
}

function run() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( run_is_debug )) && set -x

  if (( run_is_h )); then
    print "  ${hi_yellow_cor}run${reset_cor} : run dev in current folder"
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${hi_yellow_cor}run dev${reset_cor} : run dev in current folder"
      print "  ${hi_yellow_cor}run stage${reset_cor} : run stage in current folder"
      print "  ${hi_yellow_cor}run prod${reset_cor} : run prod in current folder"
      print "  --"
      print "  ${hi_yellow_cor}run <folder>${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s folder on dev environment"
      print "  ${hi_yellow_cor}run <folder> ${yellow_cor}[<env>]${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s folder on given environment"
    else
      print "  ${hi_yellow_cor}run <folder>${reset_cor} : run dev in a folder"
    fi
    print "  --"
    print "  ${hi_yellow_cor}run <project>${reset_cor} : run a project's on dev environment if single mode"
    print "  ${hi_yellow_cor}run <project> [<env>]${reset_cor} : run a project's on an environment if single mode"
    print "  ${hi_yellow_cor}run <project> <folder> ${yellow_cor}[<env>]${reset_cor} : run a project's folder on an environment"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""
  local env_mode="dev"

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    folder_arg="$2"
    if [[ "$3" == "dev" || "$3" == "stage" || "$3" == "prod" ]]; then
      env_mode="$3"
    else
      print " fatal: not a valid environment argument: $3" >&2
      print " run ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
      return 1;
    fi
  elif [[ -n "$2" ]]; then
    # second argument could be a folder or an environment, figure out later
    proj_arg="$1"

  elif [[ -n "$1" ]]; then
    if [[ -d "$1" ]]; then
      folder_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      env_mode="$1"
    else
      proj_arg="$1"
    fi
  fi

  local proj_cmd=""
  local proj_folder=""
  local single_mode=""
  local i=0
  
  if [[ -n "$proj_arg" ]]; then
    i=$(find_proj_index_ -o "$proj_arg" "project to run")
    if (( ! i )); then
      print " run ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"

    if ! check_proj_ -fvmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"

  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    proj_folder="$CURRENT_PUMP_FOLDER"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"
    
    i=$(find_proj_index_ -x "$proj_cmd")
  fi

  local folder_to_execute=""

  if [[ -n "$proj_arg" ]]; then
    if (( ! single_mode )); then
      if [[ -n "$2" && -z "$folder_arg" ]]; then
        if [[ -d "$proj_folder/$2" ]]; then
          folder_arg="$2"
        elif [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
          env_mode="$2"
        else
          folder_arg="$2"
        fi
      fi

      local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder_arg")}")
      if [[ -z "$dirs" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder_arg" >&2
        print " run ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder=$(choose_one_ -i "folder to run for $proj_cmd" "${dirs[@]}")
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    else
      folder_to_execute="$proj_folder"
    fi
  else
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  folder_to_execute=$(realpath -- "$folder_to_execute")

  if ! is_folder_pkg_ "$folder_to_execute"; then return 1; fi

  cd "$folder_to_execute"

  local pkg_manager="${PUMP_PKG_MANAGER[$i]:-$CURRENT_PUMP_PKG_MANAGER:-npm}"
  local pump_run="${PUMP_RUN[$i]:-$CURRENT_PUMP_RUN}"

  if [[ "$env_mode" == "stage" ]]; then
    pump_run="${CURRENT_PUMP_RUN_STAGE[$i]:-$CURRENT_PUMP_RUN_STAGE}"
  elif [[ "$env_mode" == "prod" ]]; then
    pump_run="${CURRENT_PUMP_RUN_PROD[$i]:-$CURRENT_PUMP_RUN_PROD}"
  fi

  print " running $env_mode on ${cyan_cor}${folder_to_execute}${reset_cor}"

  if [[ -z "$pump_run" ]]; then
    local pump_run_env=$(get_script_from_pkg_json_ "$env_mode" "$folder_to_execute")
    if [[ -n "$pump_run_env" ]]; then
      pump_run="$pkg_manager run $env_mode"
    else
      local pump_run_start=$(get_script_from_pkg_json_ "start" "$folder_to_execute")
      if [[ -n "$pump_run_start" ]]; then
        pump_run="$pkg_manager start"
      else
        print " fatal: no '$env_mode' or 'start' script in package.json"
        return 1;
      fi
    fi
    print " ${script_cor}${pump_run}${reset_cor}"
    
    eval "$pump_run"
  else
    print " ${script_cor}${pump_run}${reset_cor}"
    
    if ! eval "$pump_run"; then
      if [[ "$env_mode" == "stage" || "$env_mode" == "prod" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_${env_mode:U}_$i ${reset_cor}" >&2
      else
        print " ${red_cor}failed to run PUMP_RUN_$i ${reset_cor}" >&2
      fi
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi
}

function setup() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( setup_is_debug )) && set -x

  if (( setup_is_h )); then
    print "  ${hi_yellow_cor}setup${reset_cor} : run setup script in current folder"
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${hi_yellow_cor}setup <folder>${reset_cor} : run setup script in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
    else
      print "  ${hi_yellow_cor}setup <folder>${reset_cor} : run setup script in a folder"
    fi
    print "  --"
    print "  ${hi_yellow_cor}setup <project>${reset_cor} : run setup script in a project's folder if single mode"
    print "  ${hi_yellow_cor}setup <project> <folder>${reset_cor} : run setup script in a project's folder"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    if [[ -d "$2" ]]; then
      folder_arg="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  elif [[ -n "$1" ]]; then
    if [[ -d "$1" ]]; then
      folder_arg="$1"
    elif is_project_ "$1"; then
      proj_arg="$1"
    else
      print " fatal: not a valid argument: $1" >&2
      print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local proj_cmd=""
  local proj_folder=""
  local single_mode=""
  
  local i=0

  if [[ -n "$proj_arg" ]]; then
    i=$(find_proj_index_ -o "$proj_arg" "project to setup")
    if (( ! i )); then
      print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"
    
    if ! check_proj_ -fvmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"

  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    proj_folder="$CURRENT_PUMP_FOLDER"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"

    i=$(find_proj_index_ -x "$proj_cmd")
  fi

  local folder_to_execute=""

  if [[ -n "$proj_arg" ]]; then
    if (( ! single_mode )); then
      local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder_arg")}")
      if [[ -z "$dirs" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder_arg" >&2
        print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder=$(choose_one_ -i "folder to setup" "${dirs[@]}")
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    else
      folder_to_execute="$proj_folder"
    fi
  else
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  folder_to_execute=$(realpath -- "$folder_to_execute")

  if ! is_folder_pkg_ "$folder_to_execute"; then
    print " run ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
    return 1;
  fi

  print " setting up... ${cyan_cor}${folder_to_execute}${reset_cor}"

  cd "$folder_to_execute"

  local pkg_manager="${PUMP_PKG_MANAGER[$i]:-$CURRENT_PUMP_PKG_MANAGER:-npm}"
  local pump_setup="${PUMP_SETUP[$i]:-$CURRENT_PUMP_SETUP}"

  if [[ -z "$pump_setup" ]]; then
    pump_setup=$(get_script_from_pkg_json_ "setup" "$folder_to_execute")
    if [[ -n "$pump_setup" ]]; then
      pump_setup="$pkg_manager run setup"
    else
      pump_setup="$pkg_manager install"
    fi
    print " ${script_cor}${pump_setup}${reset_cor}"

    eval "$pump_setup"
  else
    print " ${script_cor}${pump_setup}${reset_cor}"

    if ! eval "$pump_setup"; then
      print " ${red_cor}failed to run PUMP_SETUP_$i ${reset_cor}" >&2
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi

  print ""
  print " next thing to do:"

  local run_dev=$(get_script_from_pkg_json_ "dev" "$folder_to_execute")
  local run_start=$(get_script_from_pkg_json_ "start" "$folder_to_execute")

  if [[ -n "$run_dev" ]]; then
    print "  • ${hi_yellow_cor}run${reset_cor} (alias for \"$pkg_manager run dev\")"
  elif [[ -n "$run_start" ]]; then
    print "  • ${hi_yellow_cor}run${reset_cor} (alias for \"$pkg_manager start\")"
  fi

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    local scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' "$pkg_json")

    local entry=""
    for entry in "${(f)scripts}"; do
      local name="${entry%%=*}"
      local cmd="${entry#*=}"

      if [[ "$name" == "build" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}build${reset_cor} (alias for \"$pkg_manager run build\")"; fi
      if [[ "$name" == "deploy" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}deploy${reset_cor} (alias for \"$pkg_manager run deploy\")"; fi
      if [[ "$name" == "fix" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}fix${reset_cor} (alias for \"$pkg_manager run fix\")"; fi
      if [[ "$name" == "format" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}format${reset_cor} (alias for \"$pkg_manager run format\")"; fi
      if [[ "$name" == "lint" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}lint${reset_cor} (alias for \"$pkg_manager run lint\")"; fi
      if [[ "$name" == "prod" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}run prod${reset_cor} (alias for \"$pkg_manager run prod\")"; fi
      if [[ "$name" == "stage" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}run stage${reset_cor} (alias for \"$pkg_manager run stage\")"; fi
      if [[ "$name" == "start" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}start${reset_cor} (alias for \"$pkg_manager run start\")"; fi
      if [[ "$name" == "test" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}test${reset_cor} (alias for \"$pkg_manager test\")"; fi
      if [[ "$name" == "tsc" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}tsc${reset_cor} (alias for \"$pkg_manager run tsc\")"; fi
    done
    print "  --"
  fi

  print "  • ${hi_yellow_cor}pro -h${reset_cor} for project management options"
  if [[ -n "$proj_cmd" ]]; then
    print "  • ${hi_yellow_cor}${proj_cmd} -h${reset_cor} for project specific options"
  fi
  print "  • ${hi_yellow_cor}help${reset_cor} for more help"
  print ""
}

function proj_revs_() {
  set +x
  eval "$(parse_flags_ "$0" "dl" "" "$@")"
  (( proj_revs_is_debug )) && set -x

  local proj_cmd="$1"

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument" >&2
    print " run ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # this is not an accessible command anymore
  # if (( proj_revs_is_h )); then
  #   $proj_cmd -h | grep -w --color=never -E '\brevs\b'
  #   return 0;
  # fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fvm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder" "$single_mode")"
  local rev_options=(${~revs_folder}/rev.*(N/))

  if (( ${#rev_options[@]} == 0 )); then
    print " no reviews for $proj_cmd" >&2
    return 0;
  fi

  # proj_revs_ -dd
  if (( proj_revs_is_d_d )); then
    confirm_ "delete all reviews?" "abort" "delete"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then return 0; fi

    local empty_folder="${revs_folder}/.empty"
    mkdir -p "$empty_folder"

    if command -v gum &>/dev/null; then
      gum spin --title="deleting... $revs_folder" -- rsync -a --delete -- "$empty_folder/" "$revs_folder/"
    else
      print "deleting... $revs_folder"
      rsync -a --delete -- "$empty_folder/" "$revs_folder/"
    fi

    if (( $? == 0 )); then
      if [[ "$revs_folder" == "$PWD" ]]; then
        print -l -- " ${yellow_cor}deleted${reset_cor} $revs_folder"
        cd ..
      else
        print -l -- " ${green_cor}deleted${reset_cor} $revs_folder"
      fi
    else
      print -l -- " ${red_cor}not deleted${reset_cor} $revs_folder" >&2
    fi

    rm -rf -- "$revs_folder"
    rm -rf -- "$empty_folder"

    return $?;
  fi

  local rev_choices=()

  # proj_revs_ -d
  if (( proj_revs_is_d )); then
    rev_choices=("${(@f)$(choose_multiple_ "reviews to delete" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}"))}")
    if [[ -z "$rev_choices" ]]; then return 1; fi

    local empty_folder="${revs_folder}/.empty"
    mkdir -p "$empty_folder"

    local rev=""
    for rev in "${rev_choices[@]}"; do
      local rev_folder="${revs_folder}/${rev}"
  
      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $rev" -- rsync -a --delete -- "$empty_folder/" "$rev_folder/"
      else
        print "deleting... $rev"
        rsync -a --delete -- "$empty_folder/" "$rev_folder/"
      fi

      if (( $? == 0 )); then
        if [[ "$rev_folder" == "$PWD" ]]; then
          print -l -- " ${yellow_cor}deleted${reset_cor} $rev"
          cd ..
        else
          print -l -- " ${green_cor}deleted${reset_cor} $rev"
        fi
      else
        print -l -- " ${red_cor}not deleted${reset_cor} $rev" >&2
      fi

      rm -rf -- "$rev_folder"
    done

    rm -rf -- "$empty_folder"

    return 0;
  fi

  # find rev_choice in rev_options
  # if [[ -n "$rev_choice" ]]; then
  #   if [[ ! -d "${revs_folder}/${rev_choice}" ]]; then
  #     print " fatal: not a valid review folder: $rev_choice" >&2
  #     print " run ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
  #     return 1;
  #   fi

  #   proj_rev_ -x "$proj_cmd" "${rev_choice/rev./}"
  #   return $?;
  # fi

  if (( proj_revs_is_l )); then
    local rev=""
    for rev in "${rev_options[@]}"; do
      rev="${rev##*/}"
      print "$rev"
    done
    return 0;
  fi

  local rev_choice=$(choose_one_ "review to open" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}")
  if [[ -z "$rev_choice" ]]; then return 1; fi

  proj_rev_ -x "$proj_cmd" "${rev_choice/rev./}"
}

function proj_rev_() {
  set +x
  eval "$(parse_flags_ "$0" "ebjdx" "" "$@")"
  (( proj_rev_is_debug )) && set -x

  local proj_cmd="$1"
  local branch_arg="$2"

  if (( proj_rev_is_h )); then
    $proj_cmd -h | grep -w --color=never -E '\brev\b'
    return 0;
  fi

  if (( proj_rev_is_l )); then
    proj_revs_ -l $@
    return $?;
  fi

  if (( proj_rev_is_d_d )); then
    proj_revs_ -dd $@
    return $?;
  fi

  if (( proj_rev_is_d )); then
    proj_revs_ -d $@
    return $?;
  fi

  if (( proj_rev_is_e )); then
    proj_revs_ $@
    return $?;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -rfm $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local code_editor="${PUMP_CODE_EDITOR[$i]}"

  local revs_folder=$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder" "$single_mode")

  local branch=""
  local pr_title=""

  # proj_rev_ -x exact branch or rev folder
  if (( proj_rev_is_x )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: not a valid argument" >&2
      print " run ${hi_yellow_cor}${proj_cmd} rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -d "${revs_folder}/rev.${branch_arg}" ]]; then
      branch="$branch_arg"
    fi

    if [[ -z "$branch" ]]; then
      branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")

      if [[ -z "$branch" ]]; then
        print " fatal: did not match any branch known to git: $branch_arg" >&2
        print " run ${hi_yellow_cor}${proj_cmd} rev -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

  # proj_rev_ -j select branch
  elif (( proj_rev_is_j )); then
    local jira_key="$branch_arg"
    
    if [[ -z "$jira_key" ]]; then
      jira_key=$(select_jira_key_ -r $i)
      if [[ -z "$jira_key" ]]; then return 1; fi
    fi

    branch=$(select_branch_ -aes "$jira_key" "" "$proj_folder")
    if [[ -z "$branch" ]]; then return 1; fi

  # proj_rev_ -b select branch
  elif (( proj_rev_is_b )); then
    if [[ -n "$branch_arg" ]]; then
      branch=$(select_branch_ -ris "$branch_arg" "branch to review" "$proj_folder")
    else
      branch=$(select_branch_ -rs "$branch_arg" "branch to review" "$proj_folder")
    fi

    if [[ -z "$branch" ]]; then return 1; fi

  else
    # check if branch arg was given and it's a branch
    if [[ -n "$branch_arg" ]]; then
      local trimmed="${branch_arg## }"
      trimmed="${trimmed%% }"

      if [[ "$trimmed" != *" "* ]]; then
        branch=$(select_branch_ -ris "$branch_arg" "branch to review" "$proj_folder" 2>/dev/null)
      fi
    fi
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$branch" ]]; then
      local pr
      pr=(${(s:|:)$(select_pr_ "$branch_arg" "$proj_repo" "pull request to review")})
      if (( $? == 130 )); then return 130; fi

      branch="${pr[2]}"
      pr_title="${pr[3]}"

      if [[ -z "$pr" || -z "$branch" ]]; then
        $proj_cmd rev -b $branch_arg
        return $?;
      fi
    fi
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local full_rev_folder="${revs_folder}/rev.${branch_folder}"

  if ! check_proj_ -rv $i; then return 1; fi
  
  proj_repo="${PUMP_REPO[$i]}"

  if [[ -n "$pr_title" ]]; then
    print " preparing review... ${cyan_cor}${pr_title}${reset_cor}"
    print " branch: ${cyan_cor}${branch}${reset_cor}"
  else
    print " preparing review... ${cyan_cor}${branch}${reset_cor}"
  fi

  local skip_setup=0
  local already_merged=0;

  if is_folder_git_ "$full_rev_folder" &>/dev/null; then
    local rev_branch="$(git -C "$full_rev_folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ "$branch" != "$rev_branch" ]]; then
      print " ${yellow_cor}warning: folder branch does not match pr branch: ${hi_yellow_cor}${rev_branch}${yellow_cor}"
      confirm_ "switch to ${branch} ?" "switch" "do nothing"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        if ! git -C "$full_rev_folder" switch "$branch" --discard-changes --quiet; then
          if reseta -o "$full_rev_folder" --quiet &>/dev/null; then
            git -C "$full_rev_folder" switch "$branch" --quiet
          else
            skip_setup=1
          fi
        fi
      else
        skip_setup=1
      fi
    fi

    if (( ! skip_setup )); then
      if [[ -n "$(git -C "$full_rev_folder" status --porcelain 2>/dev/null)" ]]; then
        skip_setup=1
        
        confirm_ "branch does not reflect pull request, erase changes and reset branch?" "reset" "do nothing"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 0 )); then
          if reseta -o "$full_rev_folder" --quiet &>/dev/null; then
            if ! pull -r "$full_rev_folder" --quiet; then
              skip_setup=1
              already_merged=1
            fi
          else
            skip_setup=1
            print " ${yellow_cor}warning: failed to clean branch${reset_cor}"
          fi
        else
          cd "$full_rev_folder"
          return 0;
        fi
      else
        if ! pull -r "$full_rev_folder" --quiet; then
          skip_setup=1
          already_merged=1
        fi
      fi
    fi

  else
    if command -v gum &>/dev/null; then
      gum spin --title="cloning... $proj_repo" -- rm -rf -- "$full_rev_folder"
      if ! gum spin --title="cloning... $proj_repo" -- git clone --filter=blob:none "$proj_repo" "$full_rev_folder"; then
        print " ${red_cor}fatal: failed to clone ${proj_repo}${reset_cor}" >&2
        return 1;
      fi
    else
      print " cloning... $proj_repo"
      rm -rf -- "$full_rev_folder"
      if ! git clone --filter=blob:none "$proj_repo" "$full_rev_folder"; then return 1; fi
    fi

    if ! git -C "$full_rev_folder" switch "$branch" &>/dev/null; then
      print " ${yellow_cor}warning: failed to switch to branch: ${branch}${reset_cor}"
      already_merged=1
    else
      if ! pull "$full_rev_folder" --quiet; then
        already_merged=1
      fi
    fi

    cd "$full_rev_folder"

    if [[ -n "$pump_clone" ]]; then
      print " ${script_cor}${pump_clone}${reset_cor}"
      if ! eval "$pump_clone"; then
        print " ${yellow_cor}warning: failed to run PUMP_CLONE_$i ${reset_cor}"
        print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}"
      fi
    fi
  fi

  local pr_link=""

  if command -v gh &>/dev/null; then
    pr_link=$(gh pr view "$branch" --repo "$proj_repo" --json url -q .url 2>/dev/null)
  fi

  if (( already_merged )); then
    print ""
    print -n " ${yellow_cor}warning: pull request may be already merged"
    if [[ -n "$pr_link" ]]; then
      print -n ", check out: ${blue_cor}$pr_link"
    fi
    print "${reset_cor}"

    cd "$full_rev_folder"
    return 0;
  fi
  
  if (( skip_setup )); then
    print " ${yellow_cor}warning: setup was skipped${reset_cor}"

    if [[ -n "$pr_link" ]]; then
      print ""
      print " check out pull request: ${blue_cor}$pr_link${reset_cor}"
    fi
    
    cd "$full_rev_folder"
    return 0;
  fi

  setup "$full_rev_folder"

  print "  --"
  print "  • ${hi_yellow_cor}$proj_cmd rev -e${reset_cor} to open an existing code review"

  if [[ -n "$pr_link" ]]; then
    print "  • check out pull request: ${blue_cor}$pr_link${reset_cor}"
  fi

  if [[ -z "$code_editor" ]]; then
    code_editor=$(input_text_ "type the command of your code editor" "code" 255 "code")

    if [[ -n "$code_editor" ]] && $code_editor -- "$full_rev_folder"; then
      update_config_ $i "PUMP_CODE_EDITOR" "$code_editor"
      return 0;
    fi
  fi

  if confirm_ "open code editor?" "open" "do nothing"; then
    $code_editor -- "$full_rev_folder"
  fi
  
  cd "$full_rev_folder"
}

function proj_clone_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_clone_is_debug )) && set -x

  local proj_cmd="$1"
  local branch_arg="$2"
  local base_branch_arg="$3"

  if (( proj_clone_is_h )); then
    $proj_cmd -h | grep --color=never -E '\bclone\b'
    return 0;
  fi

  if ! command -v git &>/dev/null; then
    print " fatal: command requires git" >&2
    print " install git: ${blue_cor}https://git-scm.com/downloads/${reset_cor}" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -rfvm $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local print_readme="${PUMP_PRINT_README[$i]}"

  if (( single_mode )) && [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)

  local folder_to_clone=""

  local skip_clone=0
  local create_backup=0

  if (( single_mode )); then
    rm -rf -- "${proj_folder}/.DS_Store" &>/dev/null
    if command -v gum &>/dev/null; then
      gum spin --title="cleaning folder..." -- rm -rf -- "${proj_folder}/.revs"
    else
      print " cleaning folder..."
      rm -rf -- "${proj_folder}/.revs" &>/dev/null
    fi
    if [[ -n "$(ls -A -- "$proj_folder" 2>/dev/null)" ]]; then
      confirm_ "project folder is not empty, create backup and re-clone?" "re-clone" "do nothing"; 
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 1 )); then
        print " cannot clone $proj_cmd because it's set to ${purple_cor}single mode${reset_cor}" >&2
        print " run ${hi_yellow_cor}$proj_cmd -e${reset_cor} to switch to ${pink_cor}multiple mode${reset_cor}" >&2
        return 0;
      fi
      create_backup=1
    fi

    folder_to_clone="$proj_folder"
  else
    if [[ -n "$git_proj_folder" ]]; then
      if [[ -z "$branch_arg" ]]; then
        branch_arg=$(input_branch_name_ "feature branch name" "" "$git_proj_folder")
        if [[ -z "$branch_arg" ]]; then return 1; fi
      fi

      local branch_folder="${branch_arg//\\/-}"
      branch_folder="${branch_folder//\//-}"

      folder_to_clone="${proj_folder}/${branch_folder}"

      rm -rf -- "${folder_to_clone}/.DS_Store" &>/dev/null

      if is_folder_git_ "$folder_to_clone" &>/dev/null; then
        skip_clone=1
      fi
    fi
  fi

  local default_branch=""

  if (( ! skip_clone )); then
    default_branch="$base_branch_arg"

    if [[ -z "$default_branch" ]]; then
      default_branch=$(determine_target_branch_ "$git_proj_folder" "$branch_arg")
      if (( $? == 130 )); then return 130; fi
      # if [[ -z "$default_branch" ]]; then return 1; fi

      if [[ -z "$default_branch" ]]; then
        local placeholder=$(get_default_branch_ "$git_proj_folder" 2>/dev/null)
        default_branch=$(input_branch_name_ "type the target branch" "${placeholder:-main}" "$git_proj_folder")
        if [[ -z "$default_branch" ]]; then return 1; fi
      fi
    fi
    
    if [[ -z "$branch_arg" ]]; then
      branch_arg="$default_branch"
    fi

    if [[ -z "$folder_to_clone" ]]; then
      local branch_folder="$branch_arg"
      
      if [[ -z "$branch_folder" ]]; then
        branch_folder="$default_branch"
      fi

      branch_folder="${branch_folder//\\/-}"
      branch_folder="${branch_folder//\//-}"

      folder_to_clone="${proj_folder}/${branch_folder}"
    fi

  fi # end if (( ! skip_clone ))

  if [[ -n "$branch_arg" && "$branch_arg" != "$default_branch" ]]; then
    local jira_key=$(extract_jira_key_ "$branch_arg" "$folder_to_clone")
    if [[ -n "$jira_key" ]]; then
      branch_arg=$(get_branch_with_monogram_ "$branch_arg")
    fi
  fi

  if (( ! skip_clone )); then
    if [[ -n "$branch_arg" ]]; then
      print " cloning... ${purple_cor}${branch_arg}${reset_cor}"
    else
      print " cloning... "
    fi

    if (( create_backup )); then
      if ! create_backup_ -s $i "$proj_folder"; then
        return 1;
      fi
    fi

    rm -rf -- "${folder_to_clone}/.DS_Store"
    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo" -- git clone --filter=blob:none "$proj_repo" "$folder_to_clone"; then
        print " ${red_cor}fatal: failed to clone $proj_repo ${reset_cor}" >&2
        return 1;
      fi
    else
      print " cloning... $proj_repo"
      if ! git clone --filter=blob:none "$proj_repo" "$folder_to_clone"; then return 1; fi
    fi
  fi

  local RET=0

  local my_branch=$(get_my_branch_ "$folder_to_clone")
  if [[ -z "$my_branch" ]]; then return 1; fi
  
  if [[ -n "$branch_arg" && "$branch_arg" != "$my_branch" ]]; then
    # if [[ -n "$default_branch" && "$branch_arg" != "$default_branch" ]]; then
    #   local remote_branch=$(get_remote_branch_ "$branch_arg" "$folder_to_clone")
      
    #   if [[ -n "$remote_branch" ]]; then
    #     git -C "$folder_to_clone" switch "$remote_branch" &>/dev/null
    #   fi      
    # fi
    if ! git -C "$folder_to_clone" switch -c "$branch_arg" &>/dev/null; then
      if ! git -C "$folder_to_clone" switch "$branch_arg" &>/dev/null; then
        print " ${red_cor}fatal: failed to switch branch: $branch_arg" >&2
        RET=1
      fi
    fi
  fi

  if (( skip_clone )); then
    cd "$folder_to_clone"
    return $RET;
  fi

  if [[ "$default_branch" != "$branch_arg" ]]; then
    local existing_default_branch=$(get_remote_branch_ "$default_branch" "$folder_to_clone")
    
    if [[ -z "$existing_default_branch" ]] && [[ "$default_branch" == "$base_branch_arg" ]]; then
      print " ${yellow_cor}warning: default branch does not exist in upstream repository: $default_branch${reset_cor}" >&2
    else
      # print " ${script_cor}git config init.defaultBranch $default_branch${reset_cor}"
      # print " ${script_cor}git config branch.$branch_arg.gh-merge-base $default_branch${reset_cor}"
      # print " ${script_cor}git config branch.$branch_arg.vscode-merge-base $default_branch${reset_cor}"

      # git -C "$folder_to_clone" config init.defaultBranch $default_branch
      git -C "$folder_to_clone" config branch.$branch_arg.gh-merge-base $default_branch
      git -C "$folder_to_clone" config branch.$branch_arg.vscode-merge-base $default_branch
    fi
  fi

  if [[ -n "$pump_clone" ]]; then
    print " ${script_cor}${pump_clone}${reset_cor}"
    
    cd "$folder_to_clone"

    if ! eval "$pump_clone"; then
      print " ${yellow_cor}warning: failed to run PUMP_CLONE_$i ${reset_cor}"
      print " edit config: $PUMP_CONFIG_FILE then run ${hi_yellow_cor}refresh${reset_cor}"
    fi
  fi

  local d_branch=$(get_default_branch_ "$folder_to_clone")
  local b_branch=$(get_base_branch_ "$folder_to_clone")

  if [[ -n "$d_branch" || -n "$d_branch" ]]; then
    print ""
  fi

  if [[ -n "$d_branch" ]]; then
    print -n " default branch: ${hi_cyan_cor}${d_branch}${reset_cor}"
    if [[ -n "$b_branch" ]]; then
       if  [[ "$b_branch" != "$d_branch" ]]; then
        print -n " - base branch: ${hi_cyan_cor}${b_branch}${reset_cor}"
      else
        print -n " - base branch are the same"
      fi
    fi
    print ""
  else
    if [[ -n "$b_branch" ]]; then
      print " base branch: ${hi_cyan_cor}${b_branch}${reset_cor}"
    fi
  fi

  print ""
  print " next thing to do:"

  if [[ -n "${PUMP_SETUP[$i]}" ]]; then
    print "  • ${hi_yellow_cor}setup${reset_cor} (runs PUMP_SETUP_$i)"
  else
    local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    local setup_script=$(get_script_from_pkg_json_ "setup" "$folder_to_clone")

    if [[ -n "$setup_script" ]]; then
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager run setup\")"
    else
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager install\")"
    fi
    print "    ${white_cor}edit PUMP_SETUP_$i in your pump.zshenv file to customize the setup script${reset_cor}"
  fi
  print "  --"
  if [[ -n "$d_branch" ]]; then
    print "  • ${hi_yellow_cor}main${reset_cor} (alias for \"git switch $d_branch\")"
  fi
  if [[ -n "$b_branch" ]]; then
    print "  • ${hi_yellow_cor}base${reset_cor} (alias for \"git switch $b_branch\")"
  fi

  print "  --"
  print "  • ${hi_yellow_cor}${proj_cmd} -h${reset_cor} for project options"
  print "  • ${hi_yellow_cor}pro -h${reset_cor} for other project management options"
  print "  • ${hi_yellow_cor}help${reset_cor} for more help"
  print ""

  cd "$folder_to_clone"

  return $RET;
}

function proj_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "askr" "" "$@")"
  (( proj_prs_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_prs_is_h )); then
    $proj_cmd -h | grep --color=never -E '\bprs\b'
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -r $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local pr_approval_min="${PUMP_PR_APPROVAL_MIN[$i]}"
  local _interval="${PUMP_INTERVAL[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " fatal: no repository configured for project: $proj_cmd" >&2
    print " run ${hi_yellow_cor}$proj_cmd -e${reset_cor} to set the repository" >&2
    return 1;
  fi

  if (( proj_prs_is_a && proj_prs_is_s )); then
    print "  ${red_cor}fatal: invalid option${reset_cor}" >&2
    print "  --"
    $proj_cmd -h | grep -w --color=never -E '\bprs\b'
    return 1;
  fi

  if (( proj_prs_is_a && proj_prs_is_s )); then # auto mode
    local RET=0

    while true; do
      if (( ! proj_prs_is_k )); then
        proj_prs_s_ "$proj_repo"
        RET=$?
        if (( RET != 0 )); then break; fi
      fi

      print "sleeping for $_interval minutes..."
      sleep $(( 60 * _interval ))
      proj_prs_is_k=0
    done

    return $RET;
  fi

  if (( proj_prs_is_s )); then
    proj_prs_s_ "$proj_repo"
    print ""

    if confirm_ -a "set assignee for all prs every $_interval min?"; then
      proj_prs_ -sak "$proj_cmd"
    fi

    return $?;
  fi

  if (( proj_prs_is_a_a )); then
    local search_term="$2"

    if [[ -z "$pr_approval_min" ]]; then
      pr_approval_min=$(input_number_ "minimum number of approvals" "2" 1)
      if (( $? == 130 || $? == 2 )); then return 130; fi

      update_config_ $i "PUMP_PR_APPROVAL_MIN" $pr_approval_min
    fi

    proj_prs_aa_ "$proj_repo" "$pr_approval_min" "$search_term"
    local RET=$?
    print ""

    if (( RET == 0 )) && confirm_ -a "approve prs every $_interval min?"; then
      while true; do
        print "sleeping for $_interval minutes..."
        sleep $(( 60 * _interval ))

        proj_prs_aa_ -a "$proj_repo" "$pr_approval_min" "$search_term"
      done
    fi

    return $?;
  fi

  if (( proj_prs_is_a )); then
    local search_term="$2"

    local prs=("${(@f)$(select_prs_ "$search_term" "$proj_repo" "pull requests to approve")}")
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$prs" ]]; then return 1; fi

    local pr
    for pr in "${prs[@]}"; do
      local pr_field=(${(s:|:)pr})
      local pr_number="${pr_field[1]}"
      local pr_title="${pr_field[3]}"

      if [[ -z "$pr_number" || -z "$pr_title" ]]; then return 1; fi

      confirm_ "approve pull request ${cyan_cor}${pr_title}${reset_cor} ?" "approve" "do nothing";
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi

      if (( RET == 0 )); then
        gh pr review $pr_number --approve --repo "$proj_repo"
      fi
    done

    return $?;
  fi

  if (( proj_prs_is_r )); then
    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
    if [[ -z "$git_proj_folder" ]]; then
      print " fatal: cannot find a git folder for project: $proj_cmd" >&2
      return 1;
    fi

    proj_prs_r_ "$proj_repo" "$git_proj_folder"

    return $?;
  fi

  gh pr list --repo "$proj_repo" --web
}

function proj_prs_r_() {
  local proj_repo="$1"
  local folder="$2"

  local repo_name=$(get_repo_name_ "$proj_repo")

  local current_user=$(gh api user -q .login 2>/dev/null)
  if [[ -z "$current_user" ]]; then
    print " fatal: failed to fetch current github username" >&2
    return 1
  fi

  # get a list of all open PRs for the current user
  local prs=()
  if command -v gum &>/dev/null; then
    prs=$(gh pr list --repo "$proj_repo" \
      --author $current_user \
      --json number,title,isDraft,headRefName,baseRefName \
      --jq '.[] | {number, title, isDraft, headRefName, baseRefName} // empty')
  else
    prs=$(gh pr list --repo "$proj_repo" \
      --author $current_user \
      --json number,title,isDraft,headRefName,baseRefName \
      --jq '.[] | {number, title, isDraft, headRefName, baseRefName} // empty')
  fi

  if [[ -z "$prs" ]]; then
    print " you have no open pull requests for repo: $proj_repo" >&2
    return 1;
  fi

  local my_branch=$(get_my_branch_ "$folder")

  if [[ -n "$(git -C "$folder" status --porcelain)" ]]; then
    print " fatal: uncommitted changes detected" >&2
    print " commit or stash your changes before proceeding" >&2
    return 1;
  fi

  local _merged=()
  local _rebased=()
  local _not_merged=()

  # for pr in "${pr_list[@]}"; do
  echo $prs | jq -c '.' | while read -r pr; do
    local pr_number=$(echo $pr | jq -r '.number')
    local pr_title=$(echo $pr | jq -r '.title')
    local pr_is_draft=$(echo $pr | jq -r '.isDraft')
    local pr_branch=$(echo $pr | jq -r '.headRefName')
    local pr_base_branch=$(echo $pr | jq -r '.baseRefName')

    # if [[ "$pr_is_draft" == "true" ]]; then
    #   confirm_ "pull request ${cyan_cor}${pr_title}${reset_cor} is on draft, confirm rebase?" "rebase" "skip"
    #   local RET=$?
    #   if (( RET == 130 || RET == 2 )); then return 130; fi
    #   if (( RET == 1 )); then
    #     continue
    #   fi
    # fi
    
    # for each pr, check if the last commit message contains "Merge" if so, merge, otherwise, reabse

    local pr_commits=("${(@f)$(gh pr view $pr_number --repo "$proj_repo" --json commits --jq '.commits[].oid' 2>/dev/null)}")
    if [[ -z "$pr_commits" ]]; then
      print " warning: failed to fetch commits for pr $pr_number" >&2
      continue
    fi

    local is_merge_commit=0

    # check if any commit in $pr_commits is a Merge commit
    for commit in "${pr_commits[@]}"; do
      local commit_message=$(gh api repos/$repo_name/commits/$commit --jq '.commit.message' 2>/dev/null)
      if [[ -n "$commit_message" && "$commit_message" == Merge* ]]; then
        is_merge_commit=1
      fi
    done

    if ! git -C "$folder" switch "$pr_branch" --quiet; then
      print " ${red_cor}failed to switch branch: $pr_branch${reset_cor}" >&2
      _not_merged+=("$pr_branch")
      continue;
    fi

    local pr_link=$(gh pr view $pr_number --repo "$proj_repo" --json url -q .url 2>/dev/null)
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

    local pr_desc="$pr_number_link | $pr_title"

    if (( is_merge_commit )); then
      # this has double space on purpose

      if merge -p "$pr_base_branch" "$folder" --quiet; then
        _merged+=("$pr_desc")
      else
        merge -a "$folder" --quiet
        _not_merged+=("$pr_desc")
        continue;
      fi
    else
      if rebase -p "$pr_base_branch" "$folder" --quiet; then
        _rebased+=("$pr_desc")
      else
        rebase -a "$folder" --quiet
        _not_merged+=("$pr_desc")
        continue;
      fi
    fi
  done

  git -C "$folder" switch "$my_branch" --quiet

  local branch=""
  # display summary
  print "" >&2
  print " summary:" >&2
  if [[ -n "$_merged" ]]; then
    print "  • merged branches:"
    for branch in "${_merged[@]}"; do
      print "    ◦ ${cyan_cor}$branch${reset_cor}"
    done
  fi
  if [[ -n "$_rebased" ]]; then
    print "  • rebased branches:"
    for branch in "${_rebased[@]}"; do
      print "    ◦ ${cyan_cor}$branch${reset_cor}"
    done
  fi
  if [[ -n "$_not_merged" ]]; then
    print "  • errors:" >&2
    for branch in "${_not_merged[@]}"; do
      print "    ◦ ${red_cor}$branch${reset_cor}" >&2
    done
  fi
}

function proj_prs_aa_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( proj_prs_aa_is_debug )) && set -x

  local proj_repo="$1"
  local pr_approval_min="$2"
  local search_term="$3"

  local current_user=$(gh api user -q .login 2>/dev/null)
  if [[ -z "$current_user" ]]; then
    print " fatal: failed to fetch current github username" >&2
    return 1
  fi

  local pr_list=()
  if command -v gum &>/dev/null; then
    pr_list=("${(@f)$(gum spin --title="fetching pull requests..." -- gh pr list --repo "$proj_repo" --json number,title --jq '.[] | "\(.number)\t\(.title)"' | grep -i "$search_term"  2>/dev/null)}")
  else
    pr_list=("${(@f)$(gh pr list --repo "$proj_repo" --json number,title --jq '.[] | "\(.number)\t\(.title)"' | grep -i "$search_term"  2>/dev/null)}")
  fi

  if [[ -z "$pr_list" ]]; then
    print " no pull requests for repo: $proj_repo" >&2
    return 1;
  fi

  local pr
  for pr in "${pr_list[@]}"; do
    local pr_number="${pr%%$'\t'*}"
    local pr_title="${pr#*$'\t'}"

    local pr_link=$(gh pr view $pr_number --repo "$proj_repo" --json url -q .url 2>/dev/null)
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

    # check if title. has words wip, draft, do not merge
    if [[ "$pr_title" =~ (WIP|Wip|wip|DRAFT|Draft|draft|DO NOT MERGE|Do Not Merge|do not merge) ]]; then
      print " ${hi_gray_cor}pr $pr_number_link has 0 ✓ and is drafted, skipping${reset_cor}"
      continue
    fi

    # check if labels has "do not merge" (case insensitive)
    local pr_labels=$(gh pr view "$pr_number" --repo "$proj_repo" --json labels --jq '.labels[].name' 2>/dev/null)
    if [[ "$pr_labels" =~ (DO NOT MERGE|Do Not Merge|do not merge) ]]; then
      print " ${hi_gray_cor}pr $pr_number_link has label do not merge, skipping${reset_cor}"
      continue
    fi

    # fetch full PR info including draft status and reviews
    local pr_data=$(gh pr view $pr_number --repo "$proj_repo" --json isDraft,reviews -q '.' 2>/dev/null)
    if [[ -z "$pr_data" ]]; then
      print " warning: failed to fetch full data for pr $pr_number" >&2
      continue
    fi

    # Check if PR is draft
    local is_draft=$(echo "$pr_data" | jq -r '.isDraft')
    if [[ "$is_draft" == "true" ]]; then
      print " ${hi_gray_cor}pr $pr_number_link has 0 ✓ and is drafted, skipping${reset_cor}"
      continue
    fi

    # extract reviews from the PR data
    local reviews=$(echo "$pr_data" | jq '.reviews' 2>/dev/null)

    # count valid approvals (not dismissed), using latest review per user
    local approval_count=$(echo "$reviews" | jq 'reverse
      | unique_by(.author.login)
      | map(select(.state == "APPROVED" and (.dismissed == false or .dismissed == null)))
      | length' 2>/dev/null)

    # check if current user has already approved
    local user_has_approved=$(echo "$reviews" | jq --arg user "$current_user" 'reverse
      | unique_by(.author.login)
      | map(select(.author.login == $user and .state == "APPROVED" and (.dismissed == false or .dismissed == null)))
      | length' 2>/dev/null)

    if (( approval_count < pr_approval_min )); then
      if (( user_has_approved )); then
        print " ${green_cor}pr $pr_number_link has $pr_approval_min ✓ and you also approved it${reset_cor}"
      else
        if (( ! proj_prs_aa_is_a )); then
          confirm_ "pr $pr_number_link has $approval_count ✓, approve it?" "approve" "skip"
          local RET=$?
          if (( RET == 130 || RET == 2 )); then return 130; fi
          if (( RET == 0 )); then proj_prs_aa_is_a=1; fi
        fi
        if (( proj_prs_aa_is_a )); then
          if gh pr review $pr_number --approve --repo "$proj_repo" &>/dev/null; then
            print " ${cyan_cor}pr $pr_number_link has $pr_approval_min ✓ and you just approved it${reset_cor}"
          fi
        else
          print " ${red_cor}pr $pr_number_link has $approval_count ✓ but you did not approve!${reset_cor}"
        fi
      fi
    else
      if (( user_has_approved )); then
        print " ${green_cor}pr $pr_number_link has $approval_count ✓ and you also approved it${reset_cor}"
      else
        print " ${yellow_cor}pr $pr_number_link has $approval_count ✓ but you did not approve!${reset_cor}"
      fi
    fi
  done
}

function proj_prs_s_() {
  local proj_repo="$1"

  local prs=""
  if command -v gum &>/dev/null; then
    prs=$(gum spin --title="fetching pull requests..." -- gh pr list --repo "$proj_repo" --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')
  else
    prs=$(gh pr list --repo "$proj_repo" --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')
  fi

  if (( $? != 0 )); then return 1; fi

  echo $prs | jq -c '.' | while read -r pr; do
    local pr_number=$(echo $pr | jq -r '.number')
    local author=$(echo $pr | jq -r '.author')
    local assignees=$(echo "$pr" | jq -r '[.assignees[]? | (if .name != "" and .name != null then .name else .login end)] | join(", ")')

    if [[ "$author" == "app/dependabot" ]]; then
      # print " ${yellow_cor}PR #$pr_number is from Dependabot, skipping${reset_cor}"
      continue;
    fi

    local pr_link=$(gh pr view $pr_number --repo "$proj_repo" --json url -q .url 2>/dev/null)
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

    if [[ -z "$assignees" ]]; then
      if gh pr edit $pr_number --add-assignee "$author" --repo "$proj_repo" &>/dev/null; then
        print " pr $pr_number_link is assigned to $author"
      else
        print " pr $pr_number_link is not assigned"
      fi
    else
      print " pr $pr_number_link is assigned to $assignees"
    fi
  done
}

function proj_bkp_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "" "$@")"
  (( proj_bkp_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_bkp_is_h )); then
    $proj_cmd -h | grep --color=never -E '\bbkp\b'
    return 0;
  fi

  if (( proj_bkp_is_d )); then
    proj_dbkp_ $@
    return $?;
  fi

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run ${hi_yellow_cor}$proj_cmd bkp -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fvm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local folder_to_backup="$proj_folder"

  if (( ! single_mode )); then
    local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
    if [[ -z "$dirs" ]]; then
      print " there is no folder to backup" >&2
      return 0;
    fi

    local folder=($(choose_one_ "folder" "${dirs[@]}"))
    if [[ -z "$folder" ]]; then return 1; fi

    folder_to_backup="${proj_folder}/${folder}"
  fi

  if [[ -z "$(ls "$folder_to_backup")" ]]; then
    print " project folder is empty" >&2
    return 0;
  fi

  local node_modules=0

  if [[ -d "$folder_to_backup/node_modules" ]]; then
    node_modules=1
  fi

  create_backup_ $i "$folder_to_backup"

  if (( node_modules )); then
    print " ${yellow_cor}warning: node_modules is deleted on backup to reduce size${reset_cor}" >&2
  fi
}

function proj_dbkp_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "" "$@")"
  (( proj_dbkp_is_debug )) && set -x

  local proj_cmd="$1"
  local folder_arg=""

  if [[ -n "$2" && -d "$2" ]]; then
    folder_arg="$2"
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fvm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local backups_folder="$(get_proj_special_folder_ -b "$proj_cmd" "$proj_folder" "$single_mode")"
  
  if [[ -n "$folder_arg" ]]; then
    if [[ "$folder_arg" == "$backups_folder"* ]]; then
      del -s "$folder_arg"
      return $?;
    fi
    print " fatal: not a valid backup folder for: $proj_cmd" >&2
    return 1;
  fi

  if [[ ! -d "$backups_folder" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  local dirs=("${(@f)$(get_folders_ "$backups_folder")}")

  if [[ -z "$dirs" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  local folders=("${(@f)$(choose_multiple_ "folders" "${dirs[@]}")}")
  if [[ -z "$folders" ]]; then return 1; fi

  local RET=0

  local folder=""
  for folder in "${folders[@]}"; do
    del -s "$backups_folder/$folder"
    RET=$?
  done

  if [[ -z "$(ls "$backups_folder")" ]]; then
    rm -rf -- "$backups_folder"
  fi

  local parent_folder="$(dirname -- "$backups_folder")"
  if [[ -z "$(ls "$parent_folder")" ]]; then
    rm -rf -- "$backups_folder"
  fi

  return $RET;
}

function create_backup_() {
  set +x
  eval "$(parse_flags_ "$0" "sd" "" "$@")"
  (( create_backup_is_debug )) && set -x

  local i="$1"
  local folder_to_backup="$2"

  if [[ ! -d "$folder_to_backup" ]]; then
    print " fatal: not a valid folder to backup: $folder_to_backup" >&2
    return 1;
  fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local backups_folder="$(get_proj_special_folder_ -b "$proj_cmd" "$proj_folder" "$single_mode")"

  local folder_name="$(basename -- "$folder_to_backup")"
  local proj_backup_folder="${backups_folder}/$folder_name-$(date +%H%M%S)"

  rm -rf -- "$proj_backup_folder"
  mkdir -p -- "$proj_backup_folder"

  if (( create_backup_is_d )); then
    local realfolder="$(realpath -- "$folder_to_backup" 2>/dev/null)"

    while [[ "${PWD:A}/" == "$realfolder/"* ]]; do
      cd ..
    done
  fi

  local RET=0
  
  if command -v gum &>/dev/null; then
    gum spin --title="cleaning ${folder_name}..." -- \
      find "$folder_to_backup" -type d -name "node_modules" -prune -exec rm -rf '{}' +

    if (( create_backup_is_d || create_backup_is_s )); then
      gum spin --title="creating backup and deleting folder ${folder_name}..." -- \
        rsync -a --remove-source-files -- "$folder_to_backup/" "$proj_backup_folder/"
    else
      gum spin --title="creating backup of ${folder_name}..." -- \
        rsync -a -- "$folder_to_backup/" "$proj_backup_folder/"
    fi
    RET=$?

  else
    print " cleaning ${folder_name}..."
    find "$folder_to_backup" -type d -name "node_modules" -prune -exec rm -rf '{}' +
    clear_last_line_1_

    if (( create_backup_is_d || create_backup_is_s )); then
      print " creating backup and deleting folder ${folder_name}..."
      rsync -a --remove-source-files -- "$folder_to_backup/" "$proj_backup_folder/"
      clear_last_line_1_
    else
      print " creating backup of ${folder_name}..."
      rsync -a -- "$folder_to_backup/" "$proj_backup_folder/"
      clear_last_line_1_
    fi
    RET=$?

  fi

  if (( create_backup_is_d )); then
    rm -rf -- "$folder_to_backup"
  elif (( create_backup_is_s )); then
    find "$folder_to_backup" -mindepth 1 -type d -exec rm -rf {} +
  fi

  if (( RET == 0 )); then
    if (( create_backup_is_d || create_backup_is_s )); then
      print " ${hi_gray_cor}backup created: ${gray_cor}${proj_backup_folder}${reset_cor}" >&1
    else
      print " ${hi_gray_cor}backup created: ${proj_backup_folder}${reset_cor}" >&1
    fi
    return 0;
  fi

  print " ${red_cor}failed to backup${reset_cor}" >&2
  return 1;
}

function proj_dtag_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_dtag_is_debug )) && set -x

  local proj_cmd="$1"

  local tag=""

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$proj_folder")

  if [[ -z "$tag" ]]; then
    local tags=("${(@f)$(git -C "$proj_folder" tag)}")
    
    if [[ -z "$tags" ]]; then
      print " no tag found for $proj_cmd"
      return 0;
    fi

    local selected_tags=("${(@f)$(choose_multiple_ "tags to delete" "${tags[@]}")}")
    if [[ -z "$selected_tags" ]]; then return 1; fi

    for tag in "${selected_tags[@]}"; do
      git -C "$proj_folder" tag $remote_name --delete "$tag"  2>/dev/null
      git -C "$proj_folder" push $remote_name --no-verify --delete "$tag" 2>/dev/null
    done

    return 0;
  fi

  git -C "$proj_folder" tag $remote_name --delete "$tag" 2>/dev/null
  git -C "$proj_folder" push $remote_name --no-verify --delete "$tag" 2>/dev/null

  return 0; # don't care if it fails to delete, consider success
}

function proj_tag_() {
  set +x
  eval "$(parse_flags_ "$0" "sd" "" "$@")"
  (( proj_tag_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_tag_is_h )); then
    $proj_cmd -h | grep --color=never -E '\btag'
    return 0;
  fi

  if (( proj_tag_is_d )); then
    proj_dtag_ $@
    return $?;
  fi

  local tag=""

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if ! is_folder_pkg_ "$proj_folder"; then return 1; fi
  
  prune "$proj_folder" &>/dev/null

  if [[ -z "$tag" ]]; then
    tag=$(get_from_pkg_json_ "version" "$proj_folder")
    if [[ -n "$tag" ]]; then
      if (( ! proj_tag_is_s )); then
        confirm_ "create a tag for $proj_cmd: $tag ?"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 1 )); then
          tag=""
        fi
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    if (( ! proj_tag_is_s )); then
      tag=$(input_text_ "tag name")
      if [[ -z "$tag" ]]; then return 1; fi

      print " ${purple_cor}tag name:${reset_cor} $tag"
    else
      return 1;
    fi
  fi

  git -C "$proj_folder" tag --annotate "$tag" --message "$tag"
  
  if (( $? == 0 )); then
    git -C "$proj_folder" push --no-verify --tags
    return $?;
  fi

  return 1;
}

function proj_tags_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_tags_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_tags_is_h )); then
    $proj_cmd -h | grep --color=never -E '\btag'
    return 0;
  fi

  local n=20

  if [[ -n "$2" ]]; then
    if [[ $2 == <-> ]]; then
      n=$2
    else
      print " fatal: not a valid argument: $2" >&2
      print " run ${hi_yellow_cor}$proj_cmd tags -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  prune "$proj_folder" &>/dev/null

  git -C "$proj_folder" for-each-ref refs/tags --sort=-creatordate --format='%(creatordate:short) - %(refname:short)' --count="$n"
}

function proj_drelease_single_() {
  local proj_cmd="$1"
  local tag="$2"
  local type="$3"
  local proj_repo="$4"

  if ! gh release view "$tag" --repo "$proj_repo" &>/dev/null; then
    print " release not found: $tag" >&2
    return 1;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $tag $type" -- \
      gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
  else
    print " deleting... $tag $type"
    gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
  fi
  
  proj_dtag_ "$proj_cmd" "$tag" &>/dev/null

  print " ${magenta_cor}deleted${reset_cor} $tag $type"
}

# delete release
function proj_drelease_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_drelease_is_debug )) && set -x

  local proj_cmd="$1"

  local tag=""
  local type=""

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
    if [[ -n "$3" && $3 != -* ]]; then
      type="$3"
    fi
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fr $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if [[ -n "$tag" ]]; then
    proj_drelease_single_ "$proj_cmd" "$tag" "$type" "$proj_repo"
    return $?;
  fi

  local tags=("${(@f)$(gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}')}")
  if [[ -z "$tags" ]]; then
    print " no release found for $proj_cmd"
    return 0;
  fi

  local selected_tags=("${(@f)$(choose_multiple_ "tags to delete" "${tags[@]}")}")
  if [[ -z "$selected_tags" ]]; then return 1; fi

  local selected_tag
  for selected_tag in "${selected_tags[@]}"; do
    tag=$(echo -e "$selected_tag" | awk -F '\t' '{print $1}')
    local type=$(echo -e "$selected_tag" | awk -F '\t' '{print $2}')
    
    proj_drelease_single_ "$proj_cmd" "$tag" "$type" "$proj_repo"
  done
}

function proj_release_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "h" "$@")"
  (( proj_release_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_release_is_h )); then
    $proj_cmd -h | grep --color=never -E '\brelease'
    return 0;
  fi
  
  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if (( proj_release_is_d )); then
    proj_drelease_ $@
    return $?;
  fi

  local tag=""

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fr $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local my_branch=$(get_my_branch_ "$proj_folder")
  if [[ -z "$my_branch" ]]; then return 1; fi

  if [[ -n "$(git -C "$proj_folder" status --porcelain)" ]]; then
    print " fatal: uncommitted changes detected" >&2
    print " commit or stash your changes before creating a release" >&2
    return 1;
  fi

  # check if name is conventional
  if ! [[ "$my_branch" =~ ^(main|master|stage|staging|prod|production|release)$ || "$my_branch" == release* ]]; then
    print " ${yellow_cor}warning: unconventional branch to release: $my_branch${reset_cor}" >&2
  fi

  if [[ -z "$tag" ]]; then
    if ! is_folder_pkg_ "$proj_folder"; then return 1; fi

    if command -v npm &>/dev/null; then
      local release_type=""
      if (( proj_release_is_m )); then
        release_type="major"
      elif (( proj_release_is_n )); then
        release_type="minor"
      elif (( proj_release_is_p )); then
        release_type="patch"
      fi

      if ! pull "$proj_folder" --quiet; then return 1; fi

      if [[ -n "$release_type" ]]; then
        if ! npm --prefix "$proj_folder" version "$release_type" --no-commit-hooks --no-git-tag-version &>/dev/null; then
          print " fatal: not able to bump version: $release_type" >&2
          return 1;
        fi
      fi

      tag="$(npm --prefix "$proj_folder" pkg get version --workspaces=false | tr -d '"' 2>/dev/null)"
    fi

    if [[ -z "$tag" ]]; then
      local latest_tag=$(tags 1 2>/dev/null)
      local pkg_tag=""

      pkg_tag="$(get_from_pkg_json_ "version" "$proj_folder")"

      if [[ -n "$latest_tag" && "$latest_tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
        latest_tag=${latest_tag#v}
      fi
      if [[ -n "$pkg_tag" && "$pkg_tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
        pkg_tag=${pkg_tag#v}
      fi

      if [[ "$(printf '%s\n%s' "$latest_tag" "$pkg_tag" | sort -V | tail -n1)" == "$pkg_tag" ]]; then
        tag="$pkg_tag"
      else
        tag="$latest_tag"
      fi
    fi

    if [[ -z "$tag" ]]; then
      print " fatal: cannot determine version" >&2
      print " tag must have format: <major>.<minor>.<patch>" >&2
      return 1;
    fi
  else
    if [[ "$tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
      tag="${tag#v}"
    fi

    if [[ "$tag" =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
      IFS='.' read -r major_version minor_version patch_version <<< "$tag"

      if (( proj_release_is_is_m )); then
        ((major_version++))
        minor_version=0
        patch_version=0
      elif (( proj_release_is_is_n )); then
        ((minor_version++))
        patch_version=0
      else
        ((patch_version++))
      fi

      tag="${major_version}.${minor_version}.${patch_version}"
    fi
  fi

  if (( ! proj_release_is_s )); then
    if ! confirm_ "create a release for $proj_cmd: $tag ?"; then
      git restore -- "$proj_folder/package.json" &>/dev/null
      git restore -- "$proj_folder/package-lock.json" &>/dev/null
      git restore -- "$proj_folder/yarn.lock" &>/dev/null
      git restore -- "$proj_folder/bun.lock" &>/dev/null
      git restore -- "$proj_folder/bun.lockb" &>/dev/null
      git restore -- "$proj_folder/pnpm-lock.yaml" &>/dev/null

      return 0;
    fi
  fi

  # check of git status is dirty
  if [[ -n "$(git -C "$proj_folder" status --porcelain 2>/dev/null)" ]]; then
    if ! git -C "$proj_folder" add .; then return 1; fi
    if ! git -C "$proj_folder" commit --no-verify --message="chore: release version $tag"; then return 1; fi
  fi

  if gh release view "$tag" --repo "$proj_repo" &>/dev/null; then
    if (( ! proj_release_is_s )); then
      if ! confirm_ "release already exists: $tag - re-release it?"; then
        return 1;
      fi

      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $tag" -- \
          gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
      else
        gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
      fi
    fi
  fi

  proj_dtag_ "$proj_cmd" "$tag" &>/dev/null

  if ! proj_tag_ "$proj_cmd" "$tag"; then return 1; fi
  if ! push "$proj_folder" --tags --quiet; then return 1; fi

  if gh release create "$tag" --repo "$proj_repo" --title="$tag" --generate-notes; then
    push "$proj_folder"
  fi
}

function proj_releases_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_releases_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_releases_is_h )); then
    $proj_cmd -h | grep --color=never -E '\brelease'
    return 0;
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -r $i; then return 1; fi
  
  local proj_repo="${PUMP_REPO[$i]}"

  gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}'
}

function proj_jira_find_folder_() {
  local jira_key="$1"
  local proj_folder="$2"
  local proj_jira_is_c="$3"

  local dirs=("${(@f)$(get_folders_ -fj "$proj_folder" "$jira_key")}")

  if [[ -z "$dirs" ]]; then
    if (( proj_jira_is_c )); then
      print " no ticket folders found in $proj_cmd" >&2
      return 1;
    fi
    return 0;
  fi

  local folder=""
  if [[ -n "$jira_key" ]]; then
    folder=$(choose_one_ -i "folder" "${dirs[@]}")
  else
    folder=$(choose_one_ "folder" "${dirs[@]}")
  fi
  if [[ -z "$folder" ]]; then return 1; fi

  local folder_to_jira="${proj_folder}/${folder}"

  jira_key=$(extract_jira_key_ "$folder" "$folder_to_jira")

  if [[ -z "$jira_key" ]]; then
    if (( proj_jira_is_c )); then
      print " fatal: cannot extract jira key from folder: $folder_to_jira" >&2
      return 1;
    fi
    return 0;
  fi

  echo "$folder_to_jira"
}

function proj_jira_find_branch_() {
  local jira_key="$1"
  local proj_folder="$2"
  local proj_jira_is_c="$3"

  local branch_found=""
  if [[ -n "$jira_key" ]]; then
    if (( proj_jira_is_c )); then
      branch_found=$(select_branch_ -le "$jira_key" "" "$proj_folder")
    else
      branch_found=$(select_branch_ -le "$jira_key" "" "$proj_folder" 2>/dev/null)
    fi
  else
    if (( proj_jira_is_c )); then
      branch_found=$(select_branch_ -l "" "branch" "$proj_folder")
    else
      branch_found=$(select_branch_ -l "" "branch" "$proj_folder" 2>/dev/null)
    fi
  fi
  if [[ -z "$branch_found" ]]; then return 1; fi
  
  jira_key=$(extract_jira_key_ "$branch_found")

  if [[ -z "$jira_key" ]]; then
    if (( proj_jira_is_c )); then
      print " fatal: cannot extract jira key from branch: $branch_found" >&2
      return 1;
    fi
  fi

  echo "$branch_found"
}

function get_jira_key_() {
  local i="$1"
  local jira_proj_or_key="$2"

  local jira_key=""
  
  if [[ -n "$jira_proj_or_key" ]]; then
    jira_key=$(extract_jira_key_ "$jira_proj_or_key")
    if [[ -z "$jira_key" ]]; then
      local jira_proj=$(select_jira_proj_ $i "$jira_proj_or_key")
      if [[ -z "$jira_proj" ]]; then return 1; fi
      
      jira_key=$(select_jira_key_ -p $i "$jira_proj")
    fi
  else
    jira_key=$(select_jira_key_ $i)
  fi

  echo "$jira_key"
}

function proj_jira_() {
  set +x
  eval "$(parse_flags_ "$0" "csrpv" "" "$@")"
  (( proj_jira_is_debug )) && set -x

  local proj_cmd="$1"
  local jira_proj_or_key="$2"
  local jira_status="$3"

  if (( proj_jira_is_h )); then
    $proj_cmd -h | grep --color=never -E '\bjira\b'
    return 0;
  fi

  if ! command -v acli &>/dev/null; then
    print " fatal: command requires acli" >&2
    print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2
    return 1;
  fi
  
  if ! command -v gum &>/dev/null; then
    print " fatal: command requires gum" >&2
    print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  if (( proj_jira_is_v_v )); then
    if [[ -n "$2" && "$2" != -* ]]; then
      print " fatal: not a valid argument: $2" >&2
      print " run ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local maybe_jira_keys=()

    if (( single_mode )); then
      local branches=$(git -C "$proj_folder/stage" branch --list --format="%(refname:short)" \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | sort -fu
      )

      if [[ -z "$branches" ]]; then
        print " no branches of jira tickets found for $proj_cmd" >&2
        return 0;
      fi
      maybe_jira_keys=("${(@f)$(printf "%s\n" "$branches")}")
    else
      local folders=$(get_folders_ -fj "$proj_folder")

      if [[ -z "$folders" ]]; then
        print " no folders of jira tickets found for $proj_cmd" >&2
        return 0;
      fi
      maybe_jira_keys=("${(@f)$(printf "%s\n" "$folders")}")
    fi

    # for each branch, extract the jira key and save in jira_keys
    local jira_keys=()

    local maybe_jira_key=""
    for maybe_jira_key in "${maybe_jira_keys[@]}"; do
      local key=$(extract_jira_key_ "$maybe_jira_key")
      if [[ -n "$key" && ! " ${jira_keys[*]} " =~ " $key " ]]; then
        jira_keys+=($key)
      fi
    done

    #for each jira_key in jira_keys, view status
    local jira_key=""
    for jira_key in "${jira_keys[@]}"; do
      if update_jira_status_ -v $i "$jira_key"; then
        if [[ "$jira_key" != "${jira_keys[-1]}" ]]; then
          print "  --"
        fi
      fi
    done

    return 0;
  fi

  local jira_key=""

  # resolve jira_key from a branch or folder
  if (( proj_jira_is_c || proj_jira_is_p || proj_jira_is_r || proj_jira_is_s || proj_jira_is_v )); then

    if [[ -n "$jira_proj_or_key" ]]; then
      jira_key=$(extract_jira_key_ "$jira_proj_or_key")
    fi

    if [[ -z "$jira_key" ]] || (( proj_jira_is_c )); then
      if (( single_mode )); then
        local branch_found=$(proj_jira_find_branch_ "$jira_key" "$proj_folder" "$proj_jira_is_c")
        if (( proj_jira_is_c )); then
          if [[ -z "$branch_found" ]]; then return 1; fi

          main "$proj_folder"
          delb -e "$branch_found" "$proj_folder"
          if (( $? == 130 )); then return 130; fi
        fi

        jira_key=$(extract_jira_key_ "$branch_found")

      else
        local folder_to_jira=$(proj_jira_find_folder_ "$jira_key" "$proj_folder" "$proj_jira_is_c")
        if (( proj_jira_is_c )); then
          if [[ -z "$folder_to_jira" ]]; then return 1; fi
          
          del "$folder_to_jira"
          if (( $? == 130 )); then return 130; fi
        fi

        jira_key=$(extract_jira_key_ "$folder" "$folder_to_jira")
      fi

      if (( proj_jira_is_c )); then
        if confirm_ "close jira ticket: $jira_key ?"; then
          update_jira_status_ -c $i "$jira_key"
        fi

        return 0;
      fi
    fi

    if [[ -z "$jira_key" ]]; then
      jira_key=$(get_jira_key_ $i "$jira_proj_or_key")
      if [[ -z "$jira_key" ]]; then return 1; fi
    fi

    if (( proj_jira_is_p )); then
      update_jira_status_ -p $i "$jira_key"
    elif (( proj_jira_is_r )); then
      update_jira_status_ -r $i "$jira_key"
    elif (( proj_jira_is_s )); then
      update_jira_status_ -s $i "$jira_key" "$jira_status"
    elif (( proj_jira_is_v )); then
      update_jira_status_ -v $i "$jira_key"
    fi

    return $?;
  fi

  # jira - open a ticket

  if [[ -z "$jira_key" ]]; then
    jira_key=$(get_jira_key_ $i "$jira_proj_or_key")
    if [[ -z "$jira_key" ]]; then return 1; fi
  fi

  local folder_to_jira=""

  if (( single_mode )); then
    if ! is_folder_git_ "$proj_folder" &>/dev/null; then
      if ! proj_clone_ "$proj_cmd" "$jira_key"; then
        return 1;
      else
        proj_folder="${PUMP_FOLDER[$i]}"
      fi
    fi

    local branch_found=$(select_branch_ -le "$jira_key" "" "$proj_folder" 2>/dev/null)

    if [[ -n "$branch_found" ]]; then
      if ! co -e "$proj_folder" "$branch_found"; then
        return 1;
      fi
    else
      local default_branch=$(get_default_branch_ "$proj_folder")

      if ! co "$proj_folder" "$branch_found" "$default_branch"; then
        return 1;
      fi
    fi

    folder_to_jira="$proj_folder"
  else

    if ! is_folder_git_ "${proj_folder}/${jira_key}" &>/dev/null; then
      if ! proj_clone_ "$proj_cmd" "$jira_key"; then
        return 1;
      else
        proj_folder="${PUMP_FOLDER[$i]}"
      fi
    fi

    folder_to_jira="${proj_folder}/${jira_key}"
  fi

  local jira_status=$(acli jira workitem view "$jira_key" --fields="status" --json | jq -r '.fields.status.name // empty')

  if [[ "${jira_status:u}" == "TO DO" ]] && confirm_ "open jira ticket: ${pink_cor}$jira_key${reset_cor}?"; then
    update_jira_status_ -p $i "$jira_key"
  fi
  
  cd "$folder_to_jira"
}

function update_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "csrpv" "" "$@")"
  (( update_jira_status_is_debug )) && set -x

  local i="$1"
  local jira_key="$2"
  local jira_status="$3"

  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"In Progress"}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"In Review"}"
  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"

  gum spin --title="retrieving current jira status..." -- acli jira workitem view "$jira_key"
  if (( $? != 0 )); then
    print " cannot retrieve ticket: $jira_key" >&2
    return 1;
  fi

  local output=$(gum spin --title="retrieving current jira status..." -- acli jira workitem view "$jira_key")

  local current_status=$(echo "$output" | grep -i '^Status:' | cut -d':' -f2- | xargs 2>/dev/null)
  if [[ -z "$current_status" ]]; then current_status=$(echo "$output" | grep -i '^Status:' | cut -d':' -f2- | xargs -0 2>/dev/null); fi
  local assignee=$(echo "$output" | grep -i '^Assignee:' | cut -d':' -f2- | xargs 2>/dev/null)
  if [[ -z "$assignee" ]]; then assignee=$(echo "$output" | grep -i '^Assignee:' | cut -d':' -f2- | xargs -0 2>/dev/null); fi
  local summary=$(echo "$output" | grep -i '^Summary:' | cut -d':' -f2- | xargs 2>/dev/null)
  if [[ -z "$summary" ]]; then summary=$(echo "$output" | grep -i '^Summary:' | cut -d':' -f2- | xargs -0 2>/dev/null); fi

  if [[ -z "$current_status" ]]; then
    print " cannot retrieve status of ticket: $jira_key" >&1
    return 1;
  fi

  if (( update_jira_status_is_v )); then
    print " ${cyan_cor}ticket: ${reset_cor} $jira_key"
    print " ${cyan_cor}summary: ${reset_cor}$summary"
    print " ${cyan_cor}assign: ${reset_cor}$assignee"
    print " ${cyan_cor}status: ${reset_cor}$current_status"
    return 0;
  fi
  
  if (( update_jira_status_is_p )); then
    jira_status="$jira_in_progress"
  elif (( update_jira_status_is_r )); then
    jira_status="$jira_in_review"
  elif (( update_jira_status_is_c )); then
    jira_status="$jira_done"
  elif (( update_jira_status_is_s )); then
    if [[ -z "$jira_status" ]]; then
      jira_status=$(choose_one_ "jira status" "$jira_in_progress" "$jira_in_review" "$jira_done")
      if [[ -z "$jira_status" ]]; then
        jira_status=$(input_from_ "enter jira status (e.g. In Progress, In Review, Done)" "$current_status" 20)
      fi
      if [[ -z "$jira_status" ]]; then return 1; fi
    fi
  fi

  local current_jira_assignee=$(gum spin --title="retrieving jira assignee..." -- \
    acli jira workitem view "$jira_key" --fields="assignee" --json | jq -r '.fields.assignee.emailAddress // empty')
  local current_user=$(gum spin --title="retrieving jira user..." -- \
    acli jira auth status | awk -F': ' '/Email:/ { print $2 }' 2>/dev/null)

  if [[ -z "$current_user" ]]; then
    print " cannot retrieve current user" >&2
    print " run ${hi_yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2

    return 1;
  fi

  if (( update_jira_status_is_p )); then
    if [[ "$current_jira_assignee" != "$current_user" ]]; then
      local output=""
      if [[ -n "$current_jira_assignee" ]]; then
        confirm_ "jira ticket ${jira_key} is assigned to $current_jira_assignee - re-assign it to you?" "re-assign" "do nothing"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 0 )); then
          output=$(gum spin --title="re-assigning jira ticket..." -- \
            acli jira workitem assign --key="$jira_key" --assignee="@me" --yes)
        fi
      else
        output=$(gum spin --title="assigning jira ticket..." -- \
          acli jira workitem assign --key="$jira_key" --assignee="@me" --yes)
      fi
      print " $output" | grep -w "$jira_key" >&2
    fi
  fi
  
  if [[ "${current_status:u}" == "${jira_status:u}" ]]; then
    print " ✓ Work item $jira_key status: $current_status" | grep -w "$jira_key"
    return 0;
  fi

  if [[ -n "$current_jira_assignee" && "$current_jira_assignee" != "$current_user" && "$current_status" == "$jira_done" ]]; then
    print " ✓ Work item $jira_key status: $jira_done" | grep -w "$jira_key"
    print " cannot transition a closed ticket assigned to $current_jira_assignee" >&2
    return 1;
  fi

  if [[ -n "$current_jira_assignee" && "$current_jira_assignee" != "$current_user" ]]; then
    confirm_ "transition of ticket ${jira_key} (assigned to $current_jira_assignee) to status: ${cyan_cor}${jira_status}${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then return 0; fi
  fi

  local output=""
  output=$(gum spin --title="transitioning jira ticket..." -- \
    acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)

  if echo "$output" | grep -qE "Failure" && ! echo "$output" | grep -qE "Field Story Points is required"; then
    jira_status=$(input_from_ "enter jira status (e.g. In Progress, In Review, Done)" "$jira_status" 25)
    if (( $? == 130 || RET == 2 )); then return 130; fi
    
    if [[ -n "$jira_status" ]] && ; then
      output=$(gum spin --title="transitioning jira ticket..." -- \
          acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)
      if echo "$output" | grep -qE "Failure"; then
        print " cannot transition ticket: $jira_key" >&2
        print " $output" | grep -w "$jira_key" >&2
        return 1;
      fi
    fi
  fi

  print " $output" | grep -w "$jira_key"

  if (( update_jira_status_is_p )) && [[ "${jira_status:u}" != "${jira_in_progress:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_status"
  elif (( update_jira_status_is_r )) && [[ "${jira_status:u}" != "${jira_in_review:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_status"
  elif (( update_jira_status_is_c )) && [[ "${jira_status:u}" != "${jira_done:u}" ]]; then
    update_config_ $i "PUMP_JIRA_DONE" "$jira_status"
  fi

  return 0;
}

function select_jira_proj_() {
  local i="$1"
  local jira_proj="$2"
  
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  if ! command -v acli &>/dev/null; then
    print " fatal: command requires acli" >&2
    print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2

    return 1;
  fi

  local projects=""

  if command -v gum &>/dev/null; then
    projects=($(gum spin --title="retrieving jira projects..." -- \
      acli jira project list --recent --json | jq -r '.[].key' 2>/dev/null))
  else
    projects=($(acli jira project list --recent --json | jq -r '.[].key' 2>/dev/null))
  fi

  if [[ -z "$projects" ]]; then
    print " no jira projects found" >&2
    print " run ${hi_yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2
    return 1;
  fi

  #see if jira_proj is in projects
  if [[ -n "$jira_proj" ]]; then
    for proj in "${projects[@]}"; do
      if [[ "$proj" == "$jira_proj" ]]; then
        echo "$proj"
        return 0;
      fi
    done

    print " fatal: not a valid jira project: $jira_proj" >&2
    print " run ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

  jira_proj=$(choose_one_ "jira project for $proj_cmd" "${projects[@]}")
  if [[ -z "$jira_proj" ]]; then return 1; fi

  echo "$jira_proj"
}

function select_jira_key_() {
  set +x
  eval "$(parse_flags_ "$0" "arp" "" "$@")"
  (( select_jira_key_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"

  if ! command -v acli &>/dev/null; then
    print " fatal: command requires acli" >&2
    print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2

    return 1;
  fi

  if [[ -n "$jira_proj" ]]; then
    if (( ! select_jira_key_is_p )); then
      if command -v gum &>/dev/null; then
        gum spin --title="checking if jira project is valid..." -- acli jira project view --key "$jira_proj"
      else
        acli jira project view --key "$jira_proj" &>/dev/null
      fi
      if (( $? != 0 )); then
        print " fatal: not a valid jira project: $jira_proj" >&2
        print " run ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi
  else
    jira_proj=$(select_jira_proj_ $i)
    if [[ -z "$jira_proj" ]]; then return 1; fi
  fi

  local tickets=""

  if (( select_jira_key_is_a )); then
    # search for all tickets in the project
    if command -v gum &>/dev/null; then
      tickets=$(gum spin --title="retrieving jira tickets..." -- \
        acli jira workitem search \
        --jql "project='$jira_proj' AND status!='$jira_done' AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1'2>/dev/null)
    else
      print " retrieving jira tickets..." >&2
      tickets=$(acli jira workitem search \
        --jql "project='$jira_proj' AND status!='$jira_done' AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1' 2>/dev/null)
    fi

  elif (( select_jira_key_is_r)); then
    # search for tickets not assigned to current user
    if command -v gum &>/dev/null; then
      tickets=$(gum spin --title="retrieving jira tickets..." -- \
        acli jira workitem search \
        --jql "project='$jira_proj' AND assignee!=currentUser() AND status!='$jira_done' AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1' 2>/dev/null)
    else
      print " retrieving jira tickets..." >&2
      tickets=$(acli jira workitem search \
        --jql "project='$jira_proj' AND assignee!=currentUser() AND status!='$jira_done' AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1' 2>/dev/null)
    fi
  else
    # search for tickets assigned to current user or not assigned and in "To Do" status
    if command -v gum &>/dev/null; then
      tickets=$(gum spin --title="retrieving jira tickets..." -- \
        acli jira workitem search \
        --jql "project='$jira_proj' AND status!='$jira_done' AND (assignee=currentUser() OR (assignee IS EMPTY AND status='To Do')) AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1' 2>/dev/null)
    else
      print " retrieving jira tickets..." >&2
      tickets=$(acli jira workitem search \
        --jql "project='$jira_proj' AND status!='$jira_done' AND (assignee=currentUser() OR (assignee IS EMPTY AND status='To Do')) AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
        --fields="key,summary,status,assignee" \
        --limit 1000 \
      | awk 'NR > 1' 2>/dev/null)
    fi
  fi

  if [[ -z "$tickets" ]]; then
    print " no jira tickets found for $jira_proj" >&2
    return 0;
  fi

  local ticket=""
  if (( $(echo "$tickets" | wc -l) > 20 )); then
    ticket=$(filter_one_ "jira ticket" "${(@f)$(printf "%s\n" "$tickets")}")
  else
    ticket=$(choose_one_ "jira ticket" "${(@f)$(printf "%s\n" "$tickets")}")
  fi
  if [[ -z "$ticket" ]]; then return 1; fi

  local jira_key="${ticket%% *}"

  echo "$jira_key"
}

function get_branch_with_monogram_() {
  local branch_name="$1"
  local branch_name_monogram="${${USER:0:1}:l}-${branch_name}"

  if [[ -z "$PUMP_USE_MONOGRAM" ]]; then
    confirm_ "use initials for the branch name: ${cyan_cor}$branch_name_monogram${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_USE_MONOGRAM" 1
    else
      update_setting_ "PUMP_USE_MONOGRAM" 0
    fi
  fi

  if (( PUMP_USE_MONOGRAM )); then
    echo "$branch_name_monogram"
    return 0;
  fi

  echo "$branch_name"
}

function abort() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( abort_is_debug )) && set -x

  if (( abort_is_h )); then
    print "  ${hi_yellow_cor}abort ${yellow_cor}[<folder>]${reset_cor} : abort rebase, merge, revert and cherry-pick in progress"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}abort -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! GIT_EDITOR=true git -C "$folder" rebase --abort $@ &>/dev/null; then
    if ! GIT_EDITOR=true git -C "$folder" merge --abort $@ &>/dev/null; then
      if ! GIT_EDITOR=true git -C "$folder" revert --abort $@ &>/dev/null; then
        if ! GIT_EDITOR=true git -C "$folder" cherry-pick --abort $@ &>/dev/null; then
          return 1;
        fi
      fi
    fi
  fi
}

function renb() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
  (( renb_is_debug )) && set -x

  if (( renb_is_h )); then
    print "  ${hi_yellow_cor}renb <new_branch_name> ${yellow_cor}[<folder>]${reset_cor} : rename current local branch"
    print "  --"
    print "  ${hi_yellow_cor}renb -r${reset_cor} : rename current upstream branch"
    return 0;
  fi

  local new_name=""
  local folder="$PWD"

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 != -* ]]; then
        new_name="$1"
      fi
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}renb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  elif [[ -n "$1" && $1 != -* ]]; then
    new_name="$1"
  fi

  if [[ -z "$new_name" ]]; then
    print " fatal: not a valid branch argument" >&2
    print " run ${hi_yellow_cor}renb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! git -C "$folder" check-ref-format --branch "$new_name" &>/dev/null; then
    print " fatal: invalid branch name: $new_name" >&2
    print " run ${hi_yellow_cor}renb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( renb_is_r )); then
    local my_branch=$(get_my_branch_ "$folder")
    if [[ -z "$my_branch" ]]; then return 1; fi

    local remote_branch=$(get_remote_branch_ "$my_branch" "$folder")
    
    if [[ -z "$remote_branch" ]]; then
      print " fatal: current branch is not tracking an upstream branch: $my_branch" >&2
      return 1;
    fi

    local remote_name=$(get_remote_origin_ "$folder")
    
    if git -C "$folder" push $remote_name :$my_branch --no-verify --quiet; then
      git -C "$folder" push --no-verify --set-upstream $remote_name $new_name
    fi

    return $?;
  fi

  if [[ -n "$2" && $2 != -* ]]; then
    git -C "$folder" branch -m $new_name ${@:3}
  else
    git -C "$folder" branch -m $new_name ${@:2}
  fi
}

function chp() {
  set +x
  eval "$(parse_flags_ "$0" "ac" "s" "$@")"
  (( chp_is_debug )) && set -x

  if (( chp_is_h )); then
    print "  ${hi_yellow_cor}chp ${yellow_cor}[<commit_hash>] [<folder>]${reset_cor} : cherry-pick a commit"
    print "  --"
    print "  ${hi_yellow_cor}chp -a${reset_cor} : --abort"
    print "  ${hi_yellow_cor}chp -c${reset_cor} : --continue"
    return 0;
  fi

  local folder="$PWD"
  local hash_arg=""
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 != -* ]]; then
        hash_arg="$1"
      fi
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}chp -h${reset_cor} to see usage" >&2
      return 1;
    fi
    arg_count=2
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      hash_arg="$1"
    fi
    arg_count=1
  fi
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( chp_is_a )); then
    git -C "$folder" cherry-pick --abort $@ &>/dev/null
    return $?;
  fi

  if (( chp_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" cherry-pick --continue --no-commit $@ &>/dev/null
    return $?;
  fi

  local commit=""

  # get commit message by hash
  if [[ -z "$hash_arg" ]]; then
    # get a list of commits to revert
    local commits=("${(@f)$(git -C "$folder" --no-pager log --no-merges --oneline -100)}")

    #use choose_multiple so user can select mutliple commits to revert
    commit=($(filter_one_ "commit to revert" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    # get the hash of the commit to revert
    local hash_arg=$(echo "$commit" | awk '{print $1}')
  else
    commit=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' $hash_arg 2>/dev/null)
  fi

  if git -C "$folder" cherry-pick --no-commit $hash_arg $@; then
    print "commit reverted: $commit"
  fi
}

function revert() {
  set +x
  eval "$(parse_flags_ "$0" "acms" "" "$@")"
  (( revert_is_debug )) && set -x

  if (( revert_is_h )); then
    print "  ${hi_yellow_cor}revert ${yellow_cor}[<commit_hash>] [<folder>]${reset_cor} : revert a commit"
    print "  --"
    print "  ${hi_yellow_cor}revert -m <parent_number>${reset_cor} : to revert a merge commit"
    print "  ${hi_yellow_cor}revert -a${reset_cor} : --abort"
    print "  ${hi_yellow_cor}revert -c${reset_cor} : --continue"
    print "  ${hi_yellow_cor}revert -s${reset_cor} : --signoff"
    return 0;
  fi

  local folder="$PWD"
  local hash_arg=""
  local num=""

  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    if [[ -d "$3" ]]; then
      folder="$3"
      if [[ -n "$2" && $2 != -* ]]; then
        if [[ $2 =~ ^[0-9a-f]{7,40}$ ]]; then
          hash_arg="$2"
          if [[ -n "$1" && $1 =~ ^[0-9]+$ ]]; then
            num="$1"
          else
            print " fatal: not a valid number argument: $1" >&2
            print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
            return 1;
          fi
        elif [[ $2 =~ ^[0-9]+$ ]]; then
          num="$2"
          if [[ -n "$1" && $1 =~ ^[0-9a-f]{7,40}$ ]]; then
            hash_arg="$1"
          else
            print " fatal: not a valid commit hash argument: $1" >&2
            print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
            return 1;
          fi
        else
          print " fatal: not a valid commit hash or number argument: $2" >&2
          print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
          return 1;
        fi
      fi
    else
      print " fatal: not a valid folder argument: $3" >&2
      print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
      return 1;
    fi

    arg_count=3

  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 =~ ^[0-9a-f]{7,40}$ ]]; then
        hash_arg="$1"
      elif [[ -n "$1" && $1 =~ ^[0-9]+$ ]]; then
        num="$1"
      else
        print " fatal: not a valid commit hash or number argument: $1" >&2
        print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
        return 1;
      fi
    elif [[ $2 =~ ^[0-9a-f]{7,40}$ ]]; then
      hash_arg="$2"
      if [[ -n "$1" && $1 =~ ^[0-9]+$ ]]; then
        num="$1"
      else
        print " fatal: not a valid number argument: $1" >&2
        print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
        return 1;
      fi
    elif [[ $2 =~ ^[0-9]+$ ]]; then
      num="$2"
      if [[ -n "$1" && $1 =~ ^[0-9a-f]{7,40}$ ]]; then
        hash_arg="$1"
      else
        print " fatal: not a valid commit hash argument: $1" >&2
        print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
        return 1;
      fi 
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}chp -h${reset_cor} to see usage" >&2
      return 1;
    fi
    arg_count=2
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    elif [[ $1 =~ ^[0-9a-f]{7,40}$ ]]; then
      hash_arg="$1"
    elif [[ $1 =~ ^[0-9]+$ ]]; then
      num="$1"
    else
      print " fatal: not a valid commit hash or number argument: $1" >&2
      print " run ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
      return 1;
    fi
    arg_count=1
  fi
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( revert_is_a )); then
    git -C "$folder" revert --abort $@ &>/dev/null
    return $?;
  fi

  if (( revert_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" revert --continue $@ &>/dev/null
    return $?;
  fi

  if [[ -z "$hash_arg" ]]; then
    local commits=("${(@f)$(git -C "$folder" --no-pager log --no-merges --oneline -100)}")

    local commit=($(filter_one_ "commit to revert" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    hash_arg=$(echo "$commit" | awk '{print $1}')
  fi

  local flags=()

  if (( revert_is_m )); then
    flags+=(-m $num)
  fi

  if (( revert_is_s )); then
    flags+=(--signoff)
  fi

  git -C "$folder" revert --no-commit $hash_arg ${flags[@]} $@
}

function conti() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( conti_is_debug )) && set -x

  if (( conti_is_h )); then
    print "  ${hi_yellow_cor}conti ${yellow_cor}[<folder>]${reset_cor} : continue rebase, merge, revert or cherry-pick in progress"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}conti -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! git -C "$folder" add .; then return 1; fi

  if ! GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null; then
    if ! GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null; then
      if ! GIT_EDITOR=true git -C "$folder" revert --continue $@ &>/dev/null; then
        if ! GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null; then
          return 1;
        fi
      fi
    fi
  fi
}

function recommit() {
  set +x
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
  (( recommit_is_debug )) && set -x

  if (( recommit_is_h )); then
    print "  ${hi_yellow_cor}recommit ${yellow_cor}[<folder>]${reset_cor} : reset last commit then re-commit all changes with the same message"
    print "  --"
    print "  ${hi_yellow_cor}recommit -s${reset_cor} : only staged changes"
    print "  ${hi_yellow_cor}recommit -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}recommit -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( ! recommit_is_q )); then
      print " nothing to commit, working tree clean" >&2
    fi
    return 1;
  fi
  
  if (( ! recommit_is_s )); then
    if ! git -C "$folder" add .; then return 1; fi
  fi

  if git -C "$folder" commit --no-verify --amend --no-edit $@; then
    if (( ! ${argv[(Ie)--quiet]} && ! recommit_is_q )); then
      print ""
      git -C "$folder" --no-pager log --oneline --graph --decorate -1
      # no pbcopy
    fi
    return 0;
  fi

  return 1;
}

function fetch() {
  set +x
  eval "$(parse_flags_ "$0" "afpt" "qn" "$@")"
  (( fetch_is_debug )) && set -x

  if (( fetch_is_h )); then
    print "  ${hi_yellow_cor}fetch ${yellow_cor}[<branch>] [<folder>]${reset_cor} : fetch upstream changes"
    print "  --"
    print "  ${hi_yellow_cor}fetch -a${reset_cor} : --all"
    print "  ${hi_yellow_cor}fetch -f${reset_cor} : --force"
    print "  ${hi_yellow_cor}fetch -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor}fetch -t${reset_cor} : --tags"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* && $1 != <-> ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument: $1" >&2
      print " run ${hi_yellow_cor}fetch -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    elif [[ $1 != <-> ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid argument: $1" >&2
      print " run ${hi_yellow_cor}fetch -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}fetch -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local flags=()
  
  if (( fetch_is_a )); then
    flags+=("--all")
  fi

  if (( fetch_is_t )); then
    flags+=("--tags")
    if (( fetch_is_p )); then
      flags+=("--prune-tags")
    fi
  else
    if (( fetch_is_p )); then
      flags+=("--prune")
    fi
  fi

  if (( fetch_is_f )); then
    flags+=("--force")
  fi

  if (( fetch_is_a )); then
    git -C "$folder" fetch ${flags[@]} $@
    return $?;
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  # check if remote_name already is in branch_arg
  if [[ "$branch_arg" == "$remote_name/"* ]]; then
    branch_arg="${branch_arg#$remote_name/}"
  fi
  # base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")
  
  git -C "$folder" fetch $remote_name $branch_arg ${flags[@]} $@
}

function gconf() {
  set +x
  eval "$(parse_flags_ "$0" "ac" "" "$@")"
  (( gconf_is_debug )) && set -x

  if (( gconf_is_h )); then
    print "  ${hi_yellow_cor}gconf ${yellow_cor}[<scope>] [<folder>]${reset_cor} : display git configuration"
    return 0;
  fi

  local folder="$PWD"
  local scope_arg="local"

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      scope_arg="$1"
    fi
  
  elif [[ -n "$1" && $1 != -* ]] && [[ ! $1 =~ '^[0-9]+$' ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      scope_arg="$1"
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  echo "${hi_yellow_cor}== ${scope_arg} config ==${reset_cor}"

  git config --${scope_arg} --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
    printf "  ${cyan_cor}%-40s${reset_cor} = ${cyan_cor}%s${reset_cor}\n" "$key" "$value"
  done
  
  print ""
}

function glog() {
  set +x
  eval "$(parse_flags_ "$0" "abcmrfgt" "" "$@")"
  (( glog_is_debug )) && set -x

  if (( glog_is_h )); then
    print "  ${hi_yellow_cor}glog ${yellow_cor}[<branch>] [<folder>]${reset_cor} : see log commits of a given branch"
    print "  ${hi_yellow_cor}glog -<number>${reset_cor} : limit log commits e.g.: glog -10"
    print "  ${hi_yellow_cor}glog -c ${yellow_cor}<branch>${reset_cor} : see log commits after head of a given branch"
    print "  ${hi_yellow_cor}glog -b${reset_cor} : see log commits after head of base branch"
    print "  ${hi_yellow_cor}glog -m${reset_cor} : see log commits after head of main branch"
    print "  ${hi_yellow_cor}glog -t${reset_cor} : display comment details such as timestamp and author"
    print "  ${hi_yellow_cor}glog -a${reset_cor} : --all"
    print "  ${hi_yellow_cor}glog -g${reset_cor} : --graph"
    print "  ${hi_yellow_cor}glog -r${reset_cor} : --remotes"
    print "  ${hi_yellow_cor}glog -f <format>${reset_cor} : --pretty=format:'<format>' e.g.: glog -f %s"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""
  local format=""

  local base_branch=""
  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    if (( glog_is_f )); then
      if [[ -n "$1" ]]; then
        format="$1"
      else
        print " fatal: not a valid format argument: $1" >&2
        print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi

      if [[ -d "$3" ]]; then
        folder="$3"
      else
        print " fatal: not a valid folder argument: $2" >&2
        print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi

      if [[ -n "$2" && $2 != -* ]]; then
        branch_arg="$2"
      else
        print " fatal: not a valid branch argument: $2" >&2
        print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi

    else
      print " fatal: not a valid arguments: $@" >&2
      print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    arg_count=3
  
  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if (( glog_is_f )); then
        if [[ -n "$1" ]]; then
          format="$1"
        else
          print " fatal: not a valid format argument: $1" >&2
          print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
          return 1;
        fi
      else
        if [[ -n "$1" ]]; then
          branch_arg="$1"
        else
          print " fatal: not a valid argument: $1" >&2
          print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
          return 1;
        fi
      fi
    else
      branch_arg="$2"
      if (( glog_is_f )); then
        if [[ -n "$1" ]]; then
          format="$1"
        else
          print " fatal: not a valid format argument: $1" >&2
          print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
          return 1;
        fi
      else
        print " fatal: not a valid argument: $1" >&2
        print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi
    
    arg_count=2
  
  elif [[ -n "$1" ]]; then
    if (( glog_is_f )); then
      format="$1"
      arg_count=1
    else
      if [[ -d "$1" ]]; then
        folder="$1"
        arg_count=1
      elif [[ $1 != -* ]]; then
        branch_arg="$1"
        arg_count=1
      fi
    fi
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local flags=()

  if (( glog_is_a )); then
    flags+=("--all")
  fi

  if (( glog_is_g )); then
    flags+=("--graph")
  fi

  if (( glog_is_r )); then
    flags+=("--remotes")
  fi

  if (( ! glog_is_t )) && [[ -z "$format" ]]; then
    flags+=("--oneline")
  fi

  if (( glog_is_b || glog_is_c || glog_is_m )); then

    local my_branch=$(get_my_branch_ -e "$folder" 2>/dev/null)
    if [[ -z "$my_branch" ]]; then return 1; fi

    if (( glog_is_b && glog_is_c )) || (( glog_is_b && glog_is_m )) || (( glog_is_m && glog_is_c )); then
      print " fatal: cannot use -b, -c and -m cannot be used together" >&2
      print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( glog_is_b || glog_is_m )) && [[ -n "$branch_arg" ]]; then
      print " fatal: branch argument is not valid with -b or -m" >&2
      print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( glog_is_b )); then
      branch_arg=$(get_base_branch_ -o "$folder")
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if (( glog_is_m )); then
      branch_arg=$(get_main_branch_ -o "$folder")
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if (( glog_is_c )); then
      if [[ -z "$branch_arg" ]]; then
        print " fatal: branch argument is required" >&2
        print " run ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    print " showing commits of ${cyan_cor}${my_branch}${reset_cor} after head of ${hi_cyan_cor}${branch_arg}${reset_cor}" >&1
    print "" >&1

  if [[ -n "$format" ]]; then
      git -C "$folder" --no-pager log $branch_arg..$my_branch --no-merges --decorate --pretty=format:"$format" ${flags[@]} $@
    else
      git -C "$folder" --no-pager log $branch_arg..$my_branch --no-merges --decorate ${flags[@]} $@
    fi

    return $?;
  fi

  if [[ -n "$format" ]]; then
    git -C "$folder" --no-pager log $branch_arg --decorate --pretty=format:"$format" ${flags[@]} $@
  else
    git -C "$folder" --no-pager log $branch_arg --decorate ${flags[@]} $@
  fi
}

function push() {
  set +x

  if [[ -z "$PUMP_PUSH_SET_UPSTREAM" ]]; then
    confirm_ "create an upstream counterpart branch on ${hi_yellow_cor}push${reset_cor} and ${hi_yellow_cor}pushf${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_SET_UPSTREAM" 1
    else
      update_setting_ "PUMP_PUSH_SET_UPSTREAM" 0
    fi
  fi

  if [[ -z "$PUMP_PUSH_NO_VERIFY" ]]; then
    confirm_ "bypass the execution of git hooks on ${hi_yellow_cor}push${reset_cor} and ${hi_yellow_cor}pushf${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_NO_VERIFY" 1
    else
      update_setting_ "PUMP_PUSH_NO_VERIFY" 0
    fi
  fi

  if (( PUMP_PUSH_SET_UPSTREAM )); then
    eval "$(parse_flags_ "$0" "tfnv" "q" "$@")"
  else
    eval "$(parse_flags_ "$0" "tfnvu" "q" "$@")"
  fi

  (( push_is_debug )) && set -x

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY && PUMP_PUSH_SET_UPSTREAM )); then
    no_verify="--no-verify --set-upstream"
  elif (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( push_is_h )); then
    print "  ${hi_yellow_cor}push ${yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify"
    print "  --"
    print "  ${hi_yellow_cor}push -f${reset_cor} : --force-with-lease"
    print "  ${hi_yellow_cor}push -t${reset_cor} : --tags"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${hi_yellow_cor}push -v${reset_cor} : --verify"
    else
      print "  ${hi_yellow_cor}push -nv${reset_cor} : --no-verify"
    fi
    (( ! PUMP_PUSH_SET_UPSTREAM )) && print "  ${hi_yellow_cor}push -u${reset_cor} : --set-upstream"
    print "  ${hi_yellow_cor}push -q${reset_cor} : --quiet"

    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}push -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}push -h${reset_cor} to see usage" >&2
      return 1;
    fi  
  else
    branch_arg=$(get_my_branch_ "$folder")
    if [[ -z "$branch_arg" ]]; then return 1; fi
  fi

  # check if my branch is already upstreamed
  # local upstream_branch=$(git -C "$folder" config --get "branch.${branch_arg}.remote" 2>/dev/null)
  
  local flags=()

  if (( push_is_f )); then
    flags+=("--force-with-lease")
  fi

  if (( push_is_t )); then
    flags+=("--tags")
  fi

  if (( push_is_n && push_is_v )) || (( PUMP_PUSH_NO_VERIFY && ! push_is_v )); then
    flags+=("--no-verify")
  fi

  if (( push_is_u || PUMP_PUSH_SET_UPSTREAM )); then
    flags+=("--set-upstream")
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  git -C "$folder" push $remote_name $branch_arg ${flags[@]} $@
  local RET=$?

  local is_quiet=$( (( ${argv[(Ie)--quiet]} || push_is_q )) && echo 1 || echo 0)

  if (( RET != 0 && is_quiet == 0 )); then
    print ""
    if (( ! push_is_f )); then
      if confirm_ "push failed, try push --force-with-lease?"; then
        pushf "$branch_arg" "$folder" ${flags[@]} $@
        return $?;
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --graph --decorate -1
    # no pbcopy
  fi

  return $RET;
}

function pushf() {
  set +x

  if [[ -z "$PUMP_PUSH_SET_UPSTREAM" ]]; then
    confirm_ "create an upstream counterpart branch on ${hi_yellow_cor}pushf${reset_cor} and ${hi_yellow_cor}push${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_SET_UPSTREAM" 1
    else
      update_setting_ "PUMP_PUSH_SET_UPSTREAM" 0
    fi
  fi

  eval "$(parse_flags_ "$0" "tfnvu" "qs" "$@")"
  (( pushf_is_debug )) && set -x

  if [[ -z "$PUMP_PUSH_NO_VERIFY" ]]; then
    confirm_ "bypass the execution of git hooks on ${hi_yellow_cor}pushf${reset_cor} and ${hi_yellow_cor}push${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_NO_VERIFY" 1
    else
      update_setting_ "PUMP_PUSH_NO_VERIFY" 0
    fi
  fi

  if (( PUMP_PUSH_SET_UPSTREAM )); then
    eval "$(parse_flags_ "$0" "tfnv" "q" "$@")"
  else
    eval "$(parse_flags_ "$0" "tfnvu" "q" "$@")"
  fi

  (( pushf_is_debug )) && set -x

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY && PUMP_PUSH_SET_UPSTREAM )); then
    no_verify="--no-verify --set-upstream"
  elif (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( pushf_is_h )); then
    print "  ${hi_yellow_cor}pushf ${yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify --force-with-lease"
    print "  --"
    print "  ${hi_yellow_cor}pushf -f${reset_cor} : --force"
    print "  ${hi_yellow_cor}pushf -t${reset_cor} : --tags"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${hi_yellow_cor}pushf -v${reset_cor} : --verify"
    else
      print "  ${hi_yellow_cor}pushf -nv${reset_cor} : --no-verify"
    fi
    (( ! PUMP_PUSH_SET_UPSTREAM )) && print "  ${hi_yellow_cor}pushf -u${reset_cor} : --set-upstream"
    print "  ${hi_yellow_cor}pushf -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}pushf -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}pushf -h${reset_cor} to see usage" >&2
      return 1;
    fi    
  else
    branch_arg=$(get_my_branch_ "$folder")
    if [[ -z "$branch_arg" ]]; then return 1; fi
  fi

  local flags=()

  if (( pushf_is_f )); then
    flags+=("--force")
  else
    flags+=("--force-with-lease")
  fi

  if (( pushf_is_t )); then
    flags+=("--tags")
  fi

  if (( pushf_is_n && pushf_is_v )) || (( PUMP_PUSH_NO_VERIFY && ! pushf_is_v )); then
    flags+=("--no-verify")
  fi

  if (( pushf_is_u || PUMP_PUSH_SET_UPSTREAM )); then
    flags+=("--set-upstream")
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  git -C "$folder" push $remote_name $branch_arg ${flags[@]} $@
  local RET=$?

  local is_quiet=$( (( ${argv[(Ie)--quiet]} || pushf_is_q )) && echo 1 || echo 0)

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --graph --decorate -1
    # no pbcopy
  fi

  return $RET;
}

function repush() {
  set +x
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
  (( repush_is_debug )) && set -x

  if (( repush_is_h )); then
    print "  ${hi_yellow_cor}repush ${yellow_cor}[<folder>]${reset_cor} : reset last commit without losing your changes then re-push all changes using the same message"
    print "  --"
    print "  ${hi_yellow_cor}repush -s${reset_cor} : only staged changes"
    print "  ${hi_yellow_cor}repush -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}repush -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( repush_is_s )); then
    if ! recommit -s "$folder" $@; then return 1; fi
  else
    if ! recommit "$folder" $@; then return 1; fi
  fi

  pushf "$folder" $@
}

function pullr() {
  set +x
  eval "$(parse_flags_ "$0" "" "pfq" "$@")"
  (( pullr_is_debug )) && set -x

  if (( pullr_is_h )); then
    print "  ${hi_yellow_cor}pullr ${yellow_cor}[<branch>] [<folder>]${reset_cor} : pull --rebase"
    print "  --"
    print "  ${hi_yellow_cor}pullr -q${reset_cor} : --quiet"
    return 0;
  fi

  pull -r "$@"
}

function pull() {
  set +x
  eval "$(parse_flags_ "$0" "trm" "pfq" "$@")"
  (( pull_is_debug )) && set -x

  if (( pull_is_h )); then
    print "  ${hi_yellow_cor}pull ${yellow_cor}[<branch>] [<folder>]${reset_cor} : pull from upstream"
    print "  --"
    print "  ${hi_yellow_cor}pull -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}pull -r${reset_cor} : --rebase"
    print "  ${hi_yellow_cor}pull -rm${reset_cor} : --rebase=merges"
    print "  ${hi_yellow_cor}pull -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  if [[ -n "$branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
  else
    branch_arg=$(get_my_branch_ "$folder")
    if [[ -z "$branch_arg" ]]; then return 1; fi
  fi

  local flags=()

  if (( pull_is_r )); then
    if (( pull_is_m )); then
      flags+=("--rebase=merges")
    else
      flags+=("--rebase")
    fi
  fi

  if (( pull_is_t )); then
    flags+=("--tags")
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  # # it will still display error with --quiet, which is good
  # if ! git -C "$folder" fetch $remote_name $branch_arg --quiet; then
  #   return 1;
  # fi

  git -C "$folder" pull $remote_name $branch_arg ${flags[@]} $@
  local RET=$?
  
  local is_quiet=$( (( ${argv[(Ie)--quiet]} || pull_is_q )) && echo 1 || echo 0)

  if (( RET != 0 )); then
    if (( ! pull_is_r && ! is_quiet )); then
      print ""
      if confirm_ "pull failed, try pull --rebase?"; then
        git -C "$folder" pull $remote_name $branch_arg ${flags[@]} --rebase $@ 2>/dev/null
        RET=$?
        if (( RET != 0 )); then
          git -C "$folder" pull $remote_name $branch_arg ${flags[@]} --rebase --autostash $@
          RET=$?
        fi
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1
    # no pbcopy
  fi

  return $RET
}

function print_clean_() {
  local softer_color=$'\e[38;5;214m'
  local soft_color=$'\e[38;5;208m'
  local medium_color=$'\e[38;5;202m'
  local hard_color=$'\e[38;5;1m'
  local harder_color=$'\e[38;5;88m'

  print " more options:"
  print "  ${softer_color}softer${reset_cor} = $(clean -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/   :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${soft_color}soft${reset_cor}   = $(restore -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/ :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${medium_color}medium${reset_cor} = $(discard -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/ :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${hard_color}hard${reset_cor}   = $(reseta -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/  :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${harder_color}harder${reset_cor} = $(reseto -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/  :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
}

function restore() {
  set +x
  eval "$(parse_flags_ "$0" "a" "q" "$@")"
  (( restore_is_debug )) && set -x

  if (( restore_is_h )); then
    print "  ${hi_yellow_cor}restore ${yellow_cor}[<folder>]${reset_cor} : clean staged files only"
    print "  --"
    print "  ${hi_yellow_cor}restore -a${yellow_cor}[<folder>]${reset_cor} : include untracked files in working tree"
    print "  ${hi_yellow_cor}restore -q${reset_cor} : --quiet"
    if (( ! restore_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}restore -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local staged_files=("${(@f)$(git -C "$folder" diff --name-only --cached)}")

  if [[ -z "$staged_files" ]]; then
    print " no tracked files to restore"
    return 0;
  fi

  if git -C "$folder" restore --staged -- "${staged_files[@]}" $@; then
    if (( restore_is_a )); then
      git -C "$folder" restore --worktree -- "${staged_files[@]}" &>/dev/null
    fi
  fi
}

function clean() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( clean_is_debug )) && set -x

  if (( clean_is_h )); then
    print "  ${hi_yellow_cor}clean ${yellow_cor}[<folder>]${reset_cor} : clean untracked files"
    print "  --"
    print "  ${hi_yellow_cor}clean -q${reset_cor} : --quiet"
    if (( ! clean_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}clean -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  git -C "$folder" clean -fd $@
  git -C "$folder" restore --worktree . $@
}

function discard() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( discard_is_debug )) && set -x

  if (( discard_is_h )); then
    print "  ${hi_yellow_cor}discard ${yellow_cor}[<folder>]${reset_cor} : discard tracked and untracked files"
    print "  --"
    print "  ${hi_yellow_cor}discard -q${reset_cor} : --quiet"
    if (( ! discard_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}discard -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" reset HEAD . $@
  clean "$folder" $@
}

function reseta() {
  set +x
  eval "$(parse_flags_ "$0" "o" "q" "$@")"
  (( reseta_is_debug )) && set -x

  if (( reseta_is_h )); then
    print "  ${hi_yellow_cor}reseta ${yellow_cor}[<folder>]${reset_cor} : erase every change and match HEAD to latest commit of local branch"
    print "  --"
    print "  ${hi_yellow_cor}reseta -o${reset_cor} : erase every change and match HEAD to upstream branch"
    print "  ${hi_yellow_cor}reseta -q${reset_cor} : --quiet"
    if (( ! reseta_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reseta -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  clean --quiet "$folder" &>/dev/null

  if (( reseta_is_o )); then
    local remote_name=$(get_remote_origin_ "$folder")
    local my_branch=$(get_my_branch_ "$folder")
    if [[ -z "$my_branch" ]]; then return 1; fi
  
    fetch --quiet
    git -C "$folder" reset --hard $remote_name/$my_branch $@
  else
    git -C "$folder" reset --hard $@
  fi
}

function reseto() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( reseto_is_debug )) && set -x

  if (( reseto_is_h )); then
    print "  ${hi_yellow_cor}reseto ${yellow_cor}[<folder>]${reset_cor} : erase every change and match HEAD to upstream branch"
    print "  --"
    print "  ${hi_yellow_cor}reseto -q${reset_cor} : --quiet"
    if (( ! reseto_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ ! -d "$1" ]]; then
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}reseto -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  reseta -o "$@"
}

function glr() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( glr_is_debug )) && set -x

  if (( glr_is_h )); then
    print "  ${hi_yellow_cor}glr ${yellow_cor}[<folder>]${reset_cor} : list upstream branches"
    print "  ${hi_yellow_cor}glr <branch> ${yellow_cor}[<folder>]${reset_cor} : list upstream branches matching branch"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  fetch --quiet "$folder"

  local repo=$(get_repo_ "$folder" 2>/dev/null)
  local repo_name=$(get_repo_name_ "$repo")
  
  local link="https://github.com/$repo_name/tree/"

  if command -v gum &>/dev/null; then
    gum spin --title="loading..." -- git -C "$folder" branch -r --list "*$branch_arg*" --sort=authordate \
      --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' \
      | grep -v 'HEAD' \
      | sed \
      -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
      -e "s/\([^\ ]*\)$/\x1b[34m\x1b]8;;${link//\//\\/}\1\x1b\\\\\1\x1b]8;;\x1b\\\\\x1b[0m/"
  else
    git -C "$folder" branch -r --list "*$branch_arg*" --sort=authordate \
      --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' \
      | grep -v 'HEAD' \
      | sed \
      -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
      -e "s/\([^\ ]*\)$/\x1b[34m\x1b]8;;${link//\//\\/}\1\x1b\\\\\1\x1b]8;;\x1b\\\\\x1b[0m/"
  fi
}

function gll() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( gll_is_debug )) && set -x

  if (( gll_is_h )); then
    print "  ${hi_yellow_cor}gll ${yellow_cor}[<folder>]${reset_cor} : display local branches"
    print "  ${hi_yellow_cor}gll <branch> ${yellow_cor}[<folder>]${reset_cor} : display local branches matching branch"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" branch --list "*$branch_arg*" --sort=authordate \
    --format="%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=2)" \
    | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'
}

function workflow_run_() {
  local workflow="$1"
  local proj_repo="$2"

  local url=""
  local workflow_status=""

  if command -v gum &>/dev/null; then
    url="$(gum spin --title="checking workflow status..." -- gh run list --workflow="$workflow" --repo "$proj_repo" --limit 1 --json url --jq '.[0].url // empty')"
    
    if [[ -n "$url" ]]; then
      workflow_status="$(gum spin --title="checking workflow status..." -- gh run list --workflow="$workflow" --repo "$proj_repo" --limit 1 --json conclusion --jq '.[0].conclusion // empty')"
    fi
  else
    print " checking workflow status..."
    url="$(gh run list --workflow="$workflow" --repo "$proj_repo" --limit 1 --json url --jq '.[0].url // empty')"
    
    if [[ -n "$url" ]]; then
      workflow_status="$(gh run list --workflow="$workflow" --repo "$proj_repo" --limit 1 --json conclusion --jq '.[0].conclusion // empty')"
    fi
  fi

  if [[ -z "$url" ]]; then
    return 1;
  fi
  
  local RET=0

  if [[ -z "$workflow_status" ]]; then
    RET=0; # this nust be zero for auto mode
    print -n " . workflow is running: ${workflow}" >&2
  
  elif [[ "$workflow_status" == "success" ]]; then
    RET=0
    print -n " ${green_cor}✓ workflow passed: ${workflow}${reset_cor}"
  
  else
    RET=1
    print -n "\a ${red_cor}✗ workflow failed: ${workflow} (status: ${workflow_status})${reset_cor}" >&2
  fi

  print ": ${blue_cor}${url}${reset_cor}"

  return $RET;
}

function proj_gha_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( proj_gha_is_debug )) && set -x

  local proj_cmd="$1"
  local workflow_arg="$2"

  if (( proj_gha_is_h )); then
    $proj_cmd -h | grep --color=never -E '\bgha\b'
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -r $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local _interval="${PUMP_INTERVAL[$i]}"

  local gha_workflow=""
  local ask_save=0

  local RET=0

  if [[ -z "$workflow_arg" ]]; then
    local workflow_choices=""
    if command -v gum &>/dev/null; then
      workflow_choices=$(gum spin --title="loading workflows..." -- gh workflow list --repo "$proj_repo" | cut -f1)
    else
      workflow_choices=$(gh workflow list --repo "$proj_repo" | cut -f1)
    fi
    
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      print " no workflows found for $proj_cmd"
      return 0;
    fi
    
    workflow_arg=$(choose_one_ "workflow" "${(@f)$(printf "%s\n" "$workflow_choices" | sort -f)}")
    if [[ -z "$workflow_arg" ]]; then
      return 1;
    fi

    ask_save=1
  elif [[ -n "$workflow_arg" ]]; then
    ask_save=0 
  fi

  while true; do
    workflow_run_ "$workflow_arg" "$proj_repo"
    RET=$?

    if (( RET != 0 || proj_gha_is_a == 0 )); then
      break;
    fi
    
    print "sleeping for $_interval minutes..."
    sleep $(( 60 * _interval ))
  done

  return $RET;
}

function co() {
  set +x
  eval "$(parse_flags_ "$0" "bcelpru" "q" "$@")"
  (( co_is_debug )) && set -x

  if (( co_is_h )); then
    print "  ${hi_yellow_cor}co ${yellow_cor}[<branch>] [<folder>]${reset_cor} : switch to branch"
    print "  ${hi_yellow_cor}co <branch> <base_branch>${reset_cor} : create new branch off of base branch"
    print "  --"
    print "  ${hi_yellow_cor}co -l ${yellow_cor}[<branch>]${reset_cor} : switch to local branch"
    print "  ${hi_yellow_cor}co -pr ${yellow_cor}[<pr>]${reset_cor} : switch to pull request (detached branch)"
    print "  --"
    print "  ${hi_yellow_cor}co -e <branch> ${yellow_cor}[<base_branch>]${reset_cor} : switch to an exact branch, no lookup"
    print "  ${hi_yellow_cor}co -c <branch> ${yellow_cor}[<base_branch>]${reset_cor} : create new branch off of base branch, no lookup with base_branch"
    print "  ${hi_yellow_cor}co -u ${yellow_cor}[<branch>]${reset_cor} : --set-upstream-to (set up tracking information)"
    return 0;
  fi

  local folder_arg=""

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder_arg="$1"
      shift
    fi
  fi

  local folder="${folder_arg:-$PWD}"

  if ! is_folder_git_ "$folder"; then; return 1; fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")

  # co -pr switch by pull request
  if (( co_is_p && co_is_r )); then
    if [[ -n "$2" && $2 != -* ]]; then
      print " fatal: co -pr does not accept a second argument" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local repo=$(get_repo_ "$folder")
    if [[ -z "$repo" ]]; then return 1; fi

    local pr
    pr=(${(s:|:)$(select_pr_ "$1" "$repo" "pull request to detach")})
    if (( $? == 130 )); then return 130; fi
    
    local pr_number="${pr[1]}"
    local pr_branch="${pr[2]}"
    local pr_title="${pr[3]}"
    
    if [[ -z "$pr" || -z "$pr_number" ]]; then
      print " fatal: failed to fetch pull requests for repo: $repo" >&2
      return 0;
    fi

    local RET=0

    if command -v gum &>/dev/null; then
      gum spin --title="detaching pull request: ${cyan_cor}$pr_title${reset_cor}" -- \
        gh pr checkout --force --detach $pr_number
      RET=$?
      if (( RET == 0 )); then
        print "   detaching pull request: ${cyan_cor}$pr_title${reset_cor}"
      fi
    else
      print " detaching pull request: ${cyan_cor}$pr_title${reset_cor}"
      gh pr checkout --force --detach $pr_number &>/dev/null
      RET=$?
    fi

    if (( RET == 0 )); then
      print ""
      print " HEAD is now at $(git -C "$folder" --no-pager log -1 --pretty=format:'%h %s')"
      print ""
      print " your branch is detached, run:"
      if [[ -n "$folder_arg" ]]; then
        print "  • ${hi_yellow_cor}co -e \"$folder_arg\" $pr_branch${reset_cor} (alias for \"git switch\")"
        print "  • ${hi_yellow_cor}co -c \"$folder_arg\" ${${USER:0:1}:l}-${pr_branch}${reset_cor} (alias for \"git switch -c\")"
      else
        print "  • ${hi_yellow_cor}co -e $pr_branch${reset_cor} (alias for \"git switch\")"
        print "  • ${hi_yellow_cor}co -c ${${USER:0:1}:l}-${pr_branch}${reset_cor} (alias for \"git switch -c\")"
      fi
    fi

    return $RET;
  fi

  if (( co_is_p || co_is_r )); then
    if (( co_is_p )); then
      print "  ${red_cor}fatal: invalid option: -p${reset_cor}" >&2
    else
      print "  ${red_cor}fatal: invalid option: -r${reset_cor}" >&2
    fi
    print "  --"
    co -h
    return 1;
  fi

  # co -u set upstream branch
  if (( co_is_u )); then
    local branch_arg=""

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"

      if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
        print " fatal: invalid branch argument: $branch_arg" >&2
        print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      branch_arg=$(get_my_branch_ "$folder")
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if [[ -n "$2" && $2 != -* ]]; then
      print " fatal: co -u does not accept a second argument" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local remote_name=$(get_remote_origin_ "$folder")

    git -C "$folder" branch --set-upstream-to=$remote_name/$branch_arg $@

    return $?;
  fi

  # co -l local branches only
  if (( co_is_l )); then
    local branch_arg=""
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    if [[ -n "$2" && $2 != -* ]]; then
      print " fatal: co -l does not accept a second argument" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local branch_choice=""

    if [[ -n "$branch_arg" ]]; then
      branch_choice=$(select_branch_ -lic "$branch_arg" "local branch to switch" "$folder")
    else
      branch_choice=$(select_branch_ -lm "$branch_arg" "local branch to switch" "$folder")
    fi
    if (( $? == 130 )); then return 1; fi
    if [[ -z "$branch_choice" ]]; then return 1; fi

    if [[ -n "$1" ]]; then
      co -e "$folder" "$branch_choice" ${@:2}
    else
      co -e "$folder" "$branch_choice" $@
    fi

    return $?;
  fi

  # co -e branch just switch, do not create branch
  if (( co_is_e )) && [[ -z "$2" || $2 == -* ]]; then
    local branch_arg=""

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    if [[ -z "$branch_arg" ]]; then
      print " fatal: missing branch or commit argument" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    git -C "$folder" switch "$branch_arg" ${@:2}

    return $?;
  fi

  # co -c or co -b branch BASE_BRANCH
  if (( co_is_b || co_is_c )); then
    local branch_arg=""
    local base_branch=""

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    if [[ -n "$2" && $2 != -* ]]; then
      base_branch="$2"

      if ! git -C "$folder" check-ref-format --branch "$base_branch" &>/dev/null; then
        print " fatal: invalid base branch argument: $base_branch" >&2
        print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local my_branch=$(get_my_branch_ "$folder" 2>/dev/null)

    if [[ -n "$my_branch" && "$branch_arg" == "$my_branch" ]]; then
      print " fatal: a branch named '$branch_arg' already exists" >&2
      return 1;
    fi

    if [[ -z "$base_branch" ]]; then
      local default_branch=$(get_default_branch_ "$folder")
      if [[ -z "$default_branch" ]]; then return 1; fi
      
      local base_branch=$(get_base_branch_ "$folder")
      if [[ -z "$base_branch" ]]; then return 1; fi

      local branches=("${(@f)$(printf "%s\n" "$my_branch" "$default_branch" "$base_branch" | sort -ru)}")

      base_branch=$(choose_one_ -i "base branch" "${branches[@]}")
      if [[ -z "$base_branch" ]]; then return 1; fi
    fi

    if [[ -n "$2" && $2 != -* ]]; then
      co -e "$folder" "$branch_arg" "$base_branch" ${@:3}
    else
      co -e "$folder" "$branch_arg" "$base_branch" ${@:2}
    fi
    return $?;
  fi

  # co $1 or co (no arguments) look all branches
  if [[ -z "$2" || "$2" == -* ]] && (( ! co_is_e )); then
    local branch_arg=""

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    local branch_choice=""

    if [[ -n "$branch_arg" ]]; then
      branch_choice=$(select_branch_ -aic "$branch_arg" "branch to switch" "$folder")
    else
      branch_choice=$(select_branch_ -am "$branch_arg" "branch to switch" "$folder")
    fi
    if (( $? == 130 )); then return 1; fi
    if [[ -z "$branch_choice" ]]; then
      if confirm_ " create a new branch?"; then
        co -c "$folder" "$branch_arg" ${@:2}
        return $?;
      fi
      return 1;
    fi

    if [[ -n "$1" ]]; then
      co -e "$folder" "$branch_choice" ${@:2}
    else
      co -e "$folder" "$branch_choice" $@
    fi

    return $?;
  fi

  # co -e & co branch BASE_BRANCH (creating branch)
  local branch_arg=""
  local base_branch=""

  if [[ -n "$1" && $1 != -* ]]; then
    branch_arg="$1"
  fi

  if [[ -n "$2" && $2 != -* ]]; then
    base_branch="$2"
  fi

  if [[ -z "$branch_arg" ]]; then
    print " fatal: branch argument is required" >&2
    print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! git -C "$folder" check-ref-format --branch $branch_arg &>/dev/null; then
    print " fatal: invalid branch argument: $branch_arg" >&2
    print " run ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( co_is_e )); then # search an exact term
    base_branch=$(select_branch_ -aex "$base_branch" "" "$folder")
  else
    base_branch=$(select_branch_ -ai "$base_branch" "base branch" "$folder")
  fi
  if [[ -z "$base_branch" ]]; then return 1; fi

  if ! git -C "$folder" switch -c "$branch_arg" "$base_branch" ${@:3}; then
    return 1;
  fi

  git -C "$folder" config branch.$branch_arg.gh-merge-base $base_branch
  git -C "$folder" config branch.$branch_arg.vscode-merge-base $base_branch

  print " created branch ${hi_cyan_cor}${branch_arg}${reset_cor} off of ${cyan_cor}${base_branch}${reset_cor}"
}

function back() {
  # switch to previous branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( back_is_debug )) && set -x

  if (( back_is_h )); then
    print "  ${hi_yellow_cor}back ${yellow_cor}[<folder>]${reset_cor} : switch back to previous branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}back -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if git -C "$folder" switch - $@; then
    fetch --quiet "$folder"
    return $?;
  fi
}

function dev() {
  # switch to dev or develop branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( dev_is_debug )) && set -x

  if (( dev_is_h )); then
    print "  ${hi_yellow_cor}dev ${yellow_cor}[<folder>]${reset_cor} : switch to a dev branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}dev -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local ref=""
  for ref in refs/{heads,remotes/{origin,upstream}}/{dev,devel,develop,development}; do
    if git -C "$folder" show-ref -q --verify $ref; then
      if git -C "$folder" switch "${ref:t}"; then
        fetch --quiet "${ref:t}" "$folder"
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: dev, devel, develop or development" >&2
  return 1;
}

function base() {
  # switch to base branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( base_is_debug )) && set -x

  if (( main_is_h )); then
    print "  ${hi_yellow_cor}base ${yellow_cor}[<folder>]${reset_cor} : switch to base branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}base -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local base_branch=$(get_base_branch_ "$folder")
  if [[ -z "$base_branch" ]]; then return 1; fi

  if git -C "$folder" switch "$base_branch"; then
    fetch --quiet "$base_branch" "$folder"
  fi
}

function main() {
  # switch to main branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( main_is_debug )) && set -x

  if (( main_is_h )); then
    print "  ${hi_yellow_cor}main ${yellow_cor}[<folder>]${reset_cor} : switch to main branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}main -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local main_branch=$(get_main_branch_ "$folder")
  if [[ -z "$main_branch" ]]; then return 1; fi

  if git -C "$folder" switch "$main_branch"; then
    fetch --quiet "$main_branch" "$folder"
  fi
}

function prod() {
  # switch to prod branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( prod_is_debug )) && set -x

  if (( prod_is_h )); then
    print "  ${hi_yellow_cor}prod ${yellow_cor}[<folder>]${reset_cor} : switch to prod or production branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}prod -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local ref=""
  for ref in refs/{heads,remotes/{origin,upstream}}/{prod,production}; do
    if git -C "$folder" show-ref -q --verify $ref; then
      if git -C "$folder" switch "${ref:t}"; then
        fetch --quiet "${ref:t}" "$folder"
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: prod or production" >&2
  return 1;
}

function stage() {
  # switch stage branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( stage_is_debug )) && set -x

  if (( stage_is_h )); then
    print "  ${hi_yellow_cor}stage ${yellow_cor}[<folder>]${reset_cor} : switch to stage or staging branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}stage -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local ref=""
  for ref in refs/{heads,remotes/{origin,upstream}}/{stage,staging}; do
    if git -C "$folder" show-ref -q --verify $ref; then
      if git -C "$folder" switch "${ref:t}"; then
        fetch --quiet "${ref:t}" "$folder"
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: stage or staging" >&2
  return 1;
}

function rebase() {
  set +x
  eval "$(parse_flags_ "$0" "lacpqwd" "miq" "$@")"
  (( rebase_is_debug )) && set -x

  if (( rebase_is_h )); then
    print "  ${hi_yellow_cor}rebase ${yellow_cor}[<base_branch>] [<folder>]${reset_cor} : apply the commits from your branch on top of the HEAD of base branch"
    print "  --"
    print "  ${hi_yellow_cor}rebase -d${reset_cor} : apply the commits from your branch on top of the HEAD of default branch"
    print "  ${hi_yellow_cor}rebase -l${reset_cor} : rebase on top of local branch instead of base branch"
    print "  ${hi_yellow_cor}rebase -p${reset_cor} : push after rebase if succeeds with no conflicts"
    print "  ${hi_yellow_cor}rebase -w${reset_cor} : rebase multiple local branches"
    print "  ${hi_yellow_cor}rebase -a${reset_cor} : --abort"
    print "  ${hi_yellow_cor}rebase -c${reset_cor} : --continue"
    print "  ${hi_yellow_cor}rebase -m${reset_cor} : --merge"
    print "  ${hi_yellow_cor}rebase -i${reset_cor} : --interactive"
    return 0;
  fi

  local folder="$PWD"
  local base_branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      if [[ -n "$1" && $1 != -* ]]; then
        base_branch_arg="$1"
      fi
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi

    arg_count=2
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      base_branch_arg="$1"
    fi

    arg_count=1
  fi
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local base_branch=""

  if [[ -n "$base_branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$base_branch_arg" &>/dev/null; then
      print " fatal: invalid base branch argument: $base_branch_arg" >&2
      print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( rebase_is_d )); then
      print " fatal: base branch cannot be defined with -d option" >&2
      print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi
    base_branch="$base_branch_arg"
  fi

  if (( rebase_is_s )) && [[ -z "$strategy" ]]; then
    print " fatal: strategy argument is required" >&2
    print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( rebase_is_a )); then
    git -C "$folder" rebase --abort $@ &>/dev/null
    return $?;
  fi

  if (( rebase_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null
    return $?;
  fi

  local RET=0

  if (( rebase_is_w )); then
    local selected_branches=($(select_branches_ -l "$base_branch" "$folder"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if git -C "$folder" switch "$branch" --quiet; then
        if ! rebase "$base_branch" "$folder" $@; then
          RET=1
          break;
        fi
      else
        print " fatal: failed to switch to branch: $branch" >&2
        RET=1
        break;
      fi
    done

    return $RET;
  fi
  
  local remote_name=$(get_remote_origin_ "$folder")

  if [[ -z "$base_branch_arg" ]]; then
    if (( rebase_is_d )); then
      base_branch=$(get_default_branch_ "$folder" 2>/dev/null)
    else
      base_branch=$(get_base_branch_ "$folder" 2>/dev/null)
    fi
    if [[ -z "$base_branch" ]]; then return 1; fi
  fi

  if (( rebase_is_l )); then
    base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")
  else
    base_branch="${remote_name}/${base_branch}"
  fi

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi
  
  local my_branch=$(get_my_branch_ "$folder")
  if [[ -z "$my_branch" ]]; then return 1; fi

  if [[ "${my_branch:t}" == "${base_branch:t}" ]]; then
    print " fatal: your branch cannot be the same as base branch: $my_branch" >&2
    print " run ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local msg="rebasing "
  
  if (( rebase_is_p )); then
    msg+="then pushing "
  fi

  msg+="branch on top of ${hi_cyan_cor}${base_branch}${reset_cor}: ${cyan_cor}${my_branch}${reset_cor}"

  if [[ -z "$base_branch_arg" ]]; then
    if ! confirm_ "$msg ?"; then
      return 0;
    fi
  else
    print " $msg"
  fi

  fetch --quiet "$base_branch" "$folder"

  git -C "$folder" rebase "$base_branch" $@
  RET=$?

  if (( RET == 0 )); then
    if (( rebase_is_p )); then
      pushf "$my_branch" "$folder" $@
      RET=$?
    fi
  fi

  return $RET;
}

function merge() {
  set +x
  eval "$(parse_flags_ "$0" "lacpqwd" "sq" "$@")"
  (( merge_is_debug )) && set -x

  if (( merge_is_h )); then
    print "  ${hi_yellow_cor}merge ${yellow_cor}[<base_branch>] [<folder>]${reset_cor} : merge from base branch"
    print "  --"
    print "  ${hi_yellow_cor}merge -d${reset_cor} : merge from default branch"
    print "  ${hi_yellow_cor}merge -l${reset_cor} : merge from local branch instead of base branch"
    print "  ${hi_yellow_cor}merge -p${reset_cor} : push after merge succeeds with no conflicts"
    print "  ${hi_yellow_cor}merge -w${reset_cor} : merge multiple branches"
    print "  ${hi_yellow_cor}merge -a${reset_cor} : --abort"
    print "  ${hi_yellow_cor}merge -c${reset_cor} : --continue"
    print "  ${hi_yellow_cor}merge -s <strategy>${reset_cor} : --strategy"
    return 0;
  fi

  local folder="$PWD"
  local base_branch_arg=""
  local strategy=""

  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    if (( merge_is_s )); then
      if [[ -n "$1" && $1 != -* ]]; then
        strategy="$1"
      else
        print " fatal: not a valid strategy argument: $1" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
      if [[ -d "$2" ]]; then
        folder="$2"
      else
        print " fatal: not a valid folder argument: $2" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      if [[ -n "$1" && $1 != -* ]]; then
        base_branch_arg="$1"
      fi
      if [[ -d "$2" ]]; then
        folder="$2"
      else
        print " fatal: not a valid folder argument: $2" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    arg_count=3
  elif [[ -n "$2" && $2 != -* ]]; then
    if (( merge_is_s )); then
      if [[ -n "$1" && $1 != -* ]]; then
        strategy="$1"
      else
        print " fatal: not a valid strategy argument: $1" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
      if [[ -d "$2" ]]; then
        folder="$2"
      else
        if [[ -n "$2" && $2 != -* ]]; then
          base_branch_arg="$2"
        fi
      fi
    else
      if [[ -d "$2" ]]; then
        if [[ -n "$1" && $1 != -* ]]; then
          base_branch_arg="$1"
        fi
        folder="$2"
      else
        print " fatal: not a valid folder argument: $2" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    arg_count=2
  elif [[ -n "$1" && $1 != -* ]]; then
    if (( merge_is_s )); then
      if [[ -n "$1" && $1 != -* ]]; then
        strategy="$1"
      else
        print " fatal: not a valid strategy argument: $1" >&2
        print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
        return 1;
      fi
    elif [[ -d "$1" ]]; then
      folder="$1"
    else
      base_branch_arg="$1"
    fi

    arg_count=1
  fi
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local base_branch=""

  if [[ -n "$base_branch_arg" ]]; then
    if ! git -C "$folder" check-ref-format --branch "$base_branch_arg" &>/dev/null; then
      print " fatal: invalid base branch argument: $base_branch_arg" >&2
      print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( merge_is_d )); then
      print " fatal: base branch cannot be defined with -d option" >&2
      print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
    base_branch="$base_branch_arg"
  fi

  if (( merge_is_s )) && [[ -z "$strategy" ]]; then
    print " fatal: strategy argument is required" >&2
    print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( merge_is_a )); then
    git -C "$folder" merge --abort $@ &>/dev/null
    return $?;
  fi

  if (( merge_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null
    return $?;
  fi

  local RET=0

  if (( merge_is_w )); then
    local selected_branches=($(select_branches_ -l "$base_branch" "$folder"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if git -C "$folder" switch "$branch" --quiet; then
        if (( merge_is_s )); then
          if ! merge -s "$strategy" "$base_branch" "$folder" $@; then
            RET=1
            break;
          fi
        else
          if ! merge "$base_branch" "$folder" $@; then
            RET=1
            break;
          fi
        fi
      else
        print " fatal: failed to switch to branch: $branch" >&2
        RET=1
        break;
      fi
    done

    return $RET;
  fi
  
  local remote_name=$(get_remote_origin_ "$folder")

  if [[ -z "$base_branch_arg" ]]; then
    if (( rebase_is_d )); then
      base_branch=$(get_default_branch_ "$folder" 2>/dev/null)
    else
      base_branch=$(get_base_branch_ "$folder" 2>/dev/null)
    fi
    if [[ -z "$base_branch" ]]; then return 1; fi
  fi

  if (( merge_is_l )); then
    base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")
  else
    base_branch="${remote_name}/${base_branch}"
  fi

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local my_branch=$(get_my_branch_ "$folder")
  if [[ -z "$my_branch" ]]; then return 1; fi
  
  if [[ "${my_branch:t}" == "${base_branch:t}" ]]; then
    print " fatal: your branch cannot be the same as base branch: $my_branch" >&2
    print " run ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # this has double space on purpose
  local msg=" merging "
  
  if (( merge_is_p )); then
    msg+="then pushing "
  fi

  msg+="branch from base ${hi_cyan_cor}${base_branch}${reset_cor}: ${cyan_cor}${my_branch}${reset_cor}"

  if [[ -z "$base_branch_arg" ]]; then
    if ! confirm_ "$msg ?"; then
      return 0;
    fi
  else
    print " $msg"
  fi

  fetch --quiet "$base_branch" "$folder"

  if (( merge_is_s )); then
    git -C "$folder" merge --no-edit --strategy="$strategy" "$base_branch" $@
    return $?;
  fi

  git -C "$folder" merge "$base_branch" --no-edit $@
  RET=$?

  if (( RET == 0 )); then
    if (( merge_is_p )); then
      push "$my_branch" "$folder" $@
      RET=$?
    fi
  fi

  return $RET;
}

function prune() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( prune_is_debug )) && set -x

  if (( prune_is_h )); then
    print "  ${hi_yellow_cor}prune ${yellow_cor}[<folder>]${reset_cor} : clean up unreachable or orphaned git branches and tags"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}prune -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local remote_name=$(get_remote_origin_ "$folder")

  local local_tags=("${(@f)$(git -C "$folder" tag)}")
  local remote_tags=("${(@f)$(git -C "$folder" ls-remote --tags $remote_name)}")
  
  local remote_tag_names=()
  
  local rtag=""
  for rtag in "${remote_tags[@]}"; do
    if [[ $rtag =~ refs/tags/(.+)$ ]]; then
      remote_tag_names+=("${match[1]}")
    fi
  done

  local tag=""
  for tag in "${local_tags[@]}"; do
    if ! [[ " ${remote_tag_names[*]} " == *" $tag "* ]]; then
      git -C "$folder" tag -d "$tag"
    fi
  done

  # fetch tags that exist in the upstream
  fetch -t --quiet "$folder"
  
  local default_branch=$(get_default_branch_ "$folder")
  if [[ -z "$default_branch" ]]; then return 1; fi

  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches="$(git -C "$folder" branch --merged | grep -v "^\*\\|${default_branch}" | sed 's/^[ *]*//')"
  if [[ -n "$branches" ]]; then
    for branch in "$branches"; do
      git -C "$folder" branch -D $branch
      # git already does that
      # git -C "$folder" config --remove-section branch.$branch &>/dev/null
    done
  fi

  local current_branches=$(git -C "$folder" branch --format '%(refname:short)')
  if [[ -n "$current_branches" ]]; then
    # loop through all Git config sections to find old branches
    for config in $(git -C "$folder" config --get-regexp "^branch\." | awk '{print $1}'); do
      local branch_name="${config#branch.}"

      # check if the branch exists locally
      if ! echo "$current_branches" | grep -q "^$branch_name\$"; then
        git -C "$folder" config --remove-section branch.$branch_name &>/dev/null
      fi
    done
  fi

  git -C "$folder" prune --progress
}

function delb() {
  set +x
  eval "$(parse_flags_ "$0" "sera" "" "$@")"
  (( delb_is_debug )) && set -x

  if (( delb_is_h )); then
    print "  ${hi_yellow_cor}delb ${yellow_cor}[<branch>] [<folder>]${reset_cor} : delete local branches"
    print "  --"
    print "  ${hi_yellow_cor}delb -e <branch>${reset_cor} : delete an exact branch, no lookup"
    print "  ${hi_yellow_cor}delb -r${reset_cor} : also delete upstream branches"
    print "  ${hi_yellow_cor}delb -a${reset_cor} : include all branches"
    print "  ${hi_yellow_cor}delb -s${reset_cor} : skip confirmation (cannot use with -r)"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""
  
  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print " run ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
  fi

  if (( delb_is_e )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      print " run ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    if ! git -C "$folder" check-ref-format --branch "$branch_arg" &>/dev/null; then
      print " fatal: invalid branch argument: $branch_arg" >&2
      print " run ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( delb_is_s && delb_is_r )); then
    print " fatal: cannot use -s and -r together" >&2
    print " run ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( delb_is_r )); then
    if (( delb_is_e )); then
      selected_branches=($(select_branches_ -rixa "$branch_arg" "$folder"))
    else
      if (( delb_is_a )); then
        selected_branches=($(select_branches_ -ra "$branch_arg" "$folder"))
      else
        selected_branches=($(select_branches_ -r "$branch_arg" "$folder"))
      fi
    fi
  else
    if (( delb_is_e )); then
      selected_branches=($(select_branches_ -lixa "$branch_arg" "$folder"))
    else
      if (( delb_is_a )); then
        selected_branches=($(select_branches_ -la "$branch_arg" "$folder"))
      else
        selected_branches=($(select_branches_ -l "$branch_arg" "$folder"))
      fi
    fi
  fi
  if [[ -z "$selected_branches" ]]; then return 1; fi

  local RET=0
  local count=0
  local dont_ask=0

  local branch=""
  for branch in "${selected_branches[@]}"; do
    if (( ! delb_is_s && ! delb_is_r )); then
      (( count++ ))
    fi
    if (( dont_ask == 0 && count > 3 && ${#selected_branches[@]} != count )); then;
      dont_ask=1;
      confirm_ "delete all: ${blue_cor}${(j:, :)selected_branches[$count,-1]}${reset_cor} ?"
      RET=$?
      if (( RET == 130 )); then
        break;
      elif (( RET == 1 )); then
        count=0
      else
        delb_is_s=1
      fi
    fi
    if (( ! delb_is_s || delb_is_r )); then
      local upstream=$( (( delb_is_r )) && echo "upstream" || echo "local" )
      confirm_ "delete ${upstream} branch: ${magenta_cor}${branch}${reset_cor} ?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi
    # git already does that
    # git config --remove-section "branch.${branch}" &>/dev/null

    if (( delb_is_r )); then
      local remote_name=$(get_remote_origin_ "$folder")
      branch="${branch#$remote_name/}"

      git -C "$folder" push --no-verify --delete $remote_name $branch
    fi
    git -C "$folder" branch -D $branch
    RET=$?
  done

  return $RET;
}

function st() {
  set +x
  eval "$(parse_flags_ "$0" "sb" "sb" "$@")"
  (( st_is_debug )) && set -x

  if (( st_is_h )); then
    print "  ${hi_yellow_cor}st ${yellow_cor}[<folder>]${reset_cor} : display git status"
    print "  --"
    print "  ${hi_yellow_cor}st -sb${reset_cor} : display git status in short-format"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${hi_yellow_cor}st -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  # -sb is equivalent to git status -sb
  git -C "$folder" status $@
}
  
function get_pkg_name_() {
  local folder="$1"
  local repo="$2"

  if [[ -z "$repo" ]]; then
    local git_folder=""

    if [[ -n "$folder" ]]; then
      git_folder=$(get_proj_for_git_ "$folder" 2>/dev/null)
    else
      git_folder="$PWD"
    fi

    if [[ -n "$git_folder" ]] && is_folder_git_ "$git_folder" &>/dev/null; then
      repo=$(get_repo_ "$git_folder" 2>/dev/null)
    fi
  fi

  if [[ -z "$folder" ]]; then
    folder="$PWD"
  fi

  local folder=$(get_proj_for_pkg_ "$folder" 2>/dev/null)
  if [[ -n "$folder" ]]; then
    local pkg_name=$(get_from_pkg_json_ "name" "$folder")
  
    if [[ -z "$pkg_name" && -n "$repo" ]]; then
      pkg_name=$(get_pkg_field_online_ "name" "$repo")
    fi
  fi
  
  if [[ -z "$pkg_name" ]]; then
    pkg_name="$(basename -- "$folder")"
  fi

  pkg_name="${pkg_name//[[:space:]]/}"

  echo "$pkg_name"
}

function detect_node_version_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( detect_node_version_debug )) && set -x

  local folder="${1:-$PWD}"
  local node_v_arg="$2"

  if ! command -v nvm &>/dev/null; then return 1; fi
  if ! command -v node &>/dev/null; then return 1; fi

  local nvm_use_v=""

  # check for .nvmrc file
  if [[ -f "$folder/.nvmrc" ]]; then
    if (( ! CHPWD_SILENT )) && command -v gum &>/dev/null; then
      setopt NO_NOTIFY
      {
        gum spin --title="detecting node engines & versions..." -- bash -c 'sleep 2'
      } 2>/dev/tty
    fi

    local nvm_version=$(cat "$folder/.nvmrc" 2>/dev/null)
    
    nvm_use_v=$(nvm version $nvm_version 2>/dev/null)

    if [[ -z "$nvm_use_v" || "$nvm_use_v" == "N/A" ]]; then
      print " ${yellow_cor}warning: nvm version $nvm_version not found${reset_cor}" >&2
      nvm_use_v="$nvm_version"
    fi

    echo "$nvm_use_v"
    return 0;
  fi

  # gum spin --title="detecting node engines & versions..." -- sleep 2 2>/dev/tty &!
  if (( ! CHPWD_SILENT )) && command -v gum &>/dev/null; then
    setopt NO_NOTIFY
    {
      gum spin --title="detecting node engines & versions..." -- bash -c 'sleep 3'
    } 2>/dev/tty
  fi

  local node_engine=$(get_node_engine_ "$folder")

  if [[ -n "$node_engine" ]]; then
    local versions=($(get_node_versions_ "$folder" "$node_engine"))

    if [[ -z "$versions" ]]; then
      print " ${yellow_cor}warning: no matching node version found in nvm for engine: ${node_engine}${reset_cor}" >&2
      print " install node: ${hi_yellow_cor}nvm install <version>${reset_cor}" >&2
    else
      if [[ -n "$node_v_arg" && " ${versions[*]} " == *" $node_v_arg "* ]]; then
        nvm_use_v="$node_v_arg"
      elif (( detect_node_version_is_a )); then
        nvm_use_v="${versions[1]}"
      else
        nvm_use_v=$(choose_one_ -i "node version to use with engine $node_engine" "${versions[@]}")
      fi
    fi
  fi

  if [[ -n "$nvm_use_v" ]]; then
    echo "$nvm_use_v"
    return 0;
  fi

  return 1;
}

function pro() {
  set +x
  eval "$(parse_flags_ "$0" "aeruflnxdi" "" "$@")"
  (( pro_is_debug )) && set -x

  if (( pro_is_h )); then
    print "  ${hi_yellow_cor}pro ${yellow_cor}[<name>]${reset_cor} : set a project"
    print "  --"
    print "  ${hi_yellow_cor}pro -l${reset_cor} : display all projects"
    print "  ${hi_yellow_cor}pro -a ${yellow_cor}[<name>]${reset_cor} : add a new project"
    print "  ${hi_yellow_cor}pro -e ${yellow_cor}[<name>]${reset_cor} : edit a project"
    print "  ${hi_yellow_cor}pro -r ${yellow_cor}[<name>]${reset_cor} : remove projects"
    print "  --"
    print "  ${hi_yellow_cor}pro -i ${yellow_cor}[<name>]${reset_cor} : display project config settings"
    print "  ${hi_yellow_cor}pro -n ${yellow_cor}[<name>]${reset_cor} : set the project node version using nvm"
    print "  ${hi_yellow_cor}pro -u ${yellow_cor}[<name>] [<setting>]${reset_cor} : reset project config settings"
    return 0;
  fi

  if (( pro_is_l )); then
    # pro -l display projects
    local spaces="14s"

    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_FOLDER[$i]}" && -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        printf "  ${blue_cor}%-$spaces${reset_cor} %s \n" "${PUMP_SHORT_NAME[$i]}" "${hi_gray_cor}${PUMP_FOLDER[$i]}${reset_cor}"
      fi
    done

    return 0;
  fi

  local proj_arg="$1"

  # pro -i [<name>] display project's settings
  if (( pro_is_i )); then
    if [[ -z "$proj_arg" ]]; then
      proj_arg="${CURRENT_PUMP_SHORT_NAME}"
    fi

    local i=$(find_proj_index_ -oe "$proj_arg" "project to display settings for")
    (( i )) || return 1;

    local single_mode=""

    if [[ -n "${PUMP_SINGLE_MODE[$i]}" ]]; then
      single_mode=$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "single" || echo "multiple" )
    fi

    print " ${blue_cor}project name:${reset_cor} ${PUMP_SHORT_NAME[$i]}"
    print " ${blue_cor}project repository:${reset_cor} ${PUMP_REPO[$i]}"
    print " ${blue_cor}project folder:${reset_cor} ${PUMP_FOLDER[$i]}"
    print " ${blue_cor}project mode:${reset_cor} $single_mode"
    print " ${blue_cor}package manager:${reset_cor} ${PUMP_PKG_MANAGER[$i]}"
    print " ${blue_cor}node.js version:${reset_cor} ${PUMP_NVM_USE_V[$i]}"
    return $?;
  fi

  # pro -u [<name>] reset project settings
  if (( pro_is_u )); then
    local i=$(find_proj_index_ -oe "$proj_arg"  "project to reset settings for")
    (( i )) || return 1;
    
    proj_arg="${PUMP_SHORT_NAME[$i]}"

    local setting_arg="$2"

    local settings=(
      "PUMP_PUSH_NO_VERIFY"
      "PUMP_PUSH_SET_UPSTREAM"
      "PUMP_RUN_OPEN_COV"
      "PUMP_USE_MONOGRAM"
    )

    local config_settings=(
      "PUMP_CODE_EDITOR"
      "PUMP_COMMIT_ADD"
      "PUMP_COMMIT_SIGNOFF"
      "PUMP_NVM_SKIP_LOOKUP"
      "PUMP_NVM_USE_V"
      "PUMP_PR_APPEND"
      "PUMP_PR_APPROVAL_MIN"
      "PUMP_PR_REPLACE"
      "PUMP_PRINT_README"
    )

    if [[ -n "$setting_arg" && " ${settings[*]} " != *" $setting_arg "* && " ${config_settings[*]} " != *" $setting_arg "* ]]; then
      print " fatal: invalid setting argument" >&2
      return 1;
    fi

    if [[ -n "$setting_arg" && " ${config_settings[*]} " == *" $setting_arg "* ]]; then
      update_config_ $i "$setting_arg" "" 0 2>/dev/null
      return $?;
    fi

    if [[ -n "$setting_arg" && " ${settings[*]} " == *" $setting_arg "* ]]; then
      update_setting_ "$setting_arg" "" 0 2>/dev/null
      return $?;
    fi

    local selected_settings=("${(@f)$(choose_multiple_ "settings to reset" "${settings[@]}" "${config_settings[@]}")}")
    if [[ -z "$selected_settings" ]]; then return 1; fi

    local setting=""
    for setting in "${selected_settings[@]}"; do
      pro -u "$proj_arg" "$setting"
    done
    
    return $?;
  fi

  # pro -d [<name>] display project config
  if (( pro_is_d )); then
    local i=$(find_proj_index_ -x "$proj_arg")
    [[ -n "$i" ]] || return 1;
    
    print_current_proj_ $i
    return $?;
  fi

  # pro -e <name> edit project
  if (( pro_is_e )); then
    local i=$(find_proj_index_ -oe "$proj_arg" "project to edit")
    (( i )) || return 1;

    proj_arg="${PUMP_SHORT_NAME[$i]}"

    save_proj_ -e $i "$proj_arg"
    return $?;
  fi
  
  # pro -a <name> add project
  if (( pro_is_a )); then
    local i=0
    for i in {1..9}; do
      if [[ -z "${PUMP_SHORT_NAME[$i]}" ]]; then
        if [[ -n "$proj_arg" ]]; then
          if ! check_proj_cmd_ $i "$proj_arg" ""; then return 1; fi

          save_proj_ -a $i "$proj_arg"
          return $?;
        fi

        if ! is_folder_pkg_ &>/dev/null; then
          save_proj_ -a $i
          return $?;
        fi

        local pkg_name=$(get_pkg_name_)
        local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")

        local foundI=0 emptyI=0
        for i in {1..9}; do
          # give option to edit the project because it could have been moved to a different folder
          if (( foundI == 0 )); then
            if [[ "$proj_cmd" == "${PUMP_SHORT_NAME[$i]}" ]]; then
              foundI=$i
            elif [[ -n "${PUMP_SHORT_NAME[$i]}" && "$pkg_name" == "${PUMP_PKG_NAME[$i]}" ]]; then
              foundI=$i
              proj_cmd="${PUMP_SHORT_NAME[$i]}"
            fi
          fi
          if (( emptyI == 0 )) && [[ -z "${PUMP_SHORT_NAME[$i]}" ]]; then
            emptyI=$i
          fi
        done

        if (( foundI )); then
          if confirm_ "current project exists: ${blue_cor}${proj_cmd}${reset_cor} - do you want to edit it?" "edit" "add new"; then
            save_proj_ -e $foundI "$proj_cmd"
          else
            save_proj_ -a $emptyI
          fi
          return $?;
        else
          save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name"
        fi
        return $?;
      fi
    done

    print " no more slots available, remove a project to add a new one" >&2
    print " run ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 0;
  fi

  # pro -r <name> remove project
  if (( pro_is_r )); then
    if [[ -z "$proj_arg" ]]; then
      local projects=()
      for i in {1..9}; do
        if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
          projects+=("${PUMP_SHORT_NAME[$i]}")
        fi
      done
      if (( ${#projects[@]} == 0 )); then
        print " no projects to remove"
        return 0;
      fi
      
      local selected_projects=($(choose_multiple_ "projects to remove" "${projects[@]}"))
      if [[ -z "$selected_projects" ]]; then return 1; fi

      local proj=""
      for proj in "${selected_projects[@]}"; do
        pro -r "$proj"
      done
      return $?;
    fi

    local i=$(find_proj_index_ "$proj_arg"  "project to remove")
    (( i )) || return 1;

    local refresh=0;
    if [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      refresh=1;
    fi

    if ! remove_proj_ -ur $i; then
      print " failed to remove: ${proj_arg}" >&2
      return 1;
    fi

    print " ${magenta_cor}removed${reset_cor} $proj_arg"

    if (( refresh )); then
      set_current_proj_ 0
    fi

    return $?;
  fi

  # pro -n <name> set node version for a project
  if (( pro_is_n )); then
    local i=$(find_proj_index_ -oe "$proj_arg" "project to set node version for")
    (( i )) || return 1;

    local node_v_arg="$2"

    if ! check_proj_ -m $i; then return 1; fi

    proj_arg="${PUMP_SHORT_NAME[$i]}"

    if ! command -v nvm &>/dev/null; then
      return 1;
    fi

    # if (( pro_is_f )); then
    #   echo "$CURRENT_PUMP_SHORT_NAME" > "$PUMP_PRO_PWD_FILE"
    # else
    #   echo "$CURRENT_PUMP_SHORT_NAME" > "$PUMP_PRO_FILE"
    # fi

    local nvm_skip_lookup="${PUMP_NVM_SKIP_LOOKUP[$i]}"
    local old_nvm_use_v="${PUMP_NVM_USE_V[$i]}"
    local skip_lookup=0

    if (( pro_is_x && nvm_skip_lookup )); then
      skip_lookup=1

      if [[ -n "${PUMP_NVM_USE_V[$i]}" ]] && ! nvm use "${PUMP_NVM_USE_V[$i]}"; then
        skip_lookup=0
      fi
    fi
    
    local nvm_use_v=""

    if (( skip_lookup == 0 )); then
      if ! check_proj_ -f $i; then return 1; fi

      local proj_folder=$(get_proj_for_pkg_ "${PUMP_FOLDER[$i]}" 2>/dev/null)
      if [[ -z "$proj_folder" ]]; then return 1; fi

      nvm_use_v=$(detect_node_version_ "$proj_folder" "$node_v_arg")

      if [[ -n "$nvm_use_v" ]]; then
        if nvm use "$nvm_use_v"; then
          if [[ "$old_nvm_use_v" != "$nvm_use_v" ]]; then
            update_config_ $i "PUMP_NVM_USE_V" "$nvm_use_v"
            update_config_ $i "PUMP_NVM_SKIP_LOOKUP" 1
          else
            update_config_ $i "PUMP_NVM_SKIP_LOOKUP" 1 &>/dev/null
          fi
        fi
      else
        if [[ -n "$old_nvm_use_v" ]] && nvm use "$old_nvm_use_v"; then
          update_config_ $i "PUMP_NVM_SKIP_LOOKUP" 1
        elif [[ -z "$nvm_skip_lookup" ]]; then
          print " ${yellow_cor}warning: could not find \"engines.node\" to detect node version in package.json${reset_cor}" >&2
          print " visit: ${blue_cor}https://docs.npmjs.com/cli/v11/configuring-npm/package-json#engines${reset_cor} for more info" >&2
    
          if confirm_ "skip detection from now on?" "skip" "keep detecting"; then
            update_config_ $i "PUMP_NVM_SKIP_LOOKUP" 1
          fi
        fi
      fi
    fi

    return 0;
  fi # end of pro -n

  # pro pwd project based on current working directory
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(find_proj_by_folder_)

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      local folder_name="$(dirname -- "$PWD")"
      local parent_folder_name="$(basename -- "$folder_name")"

      if [[ "$parent_folder_name" == ".backups" || "$parent_folder_name" == ".revs" || "$parent_folder_name" == ".cov" ]]; then
        return 1;
      fi

      if ! is_folder_pkg_ &>/dev/null && ! is_folder_git_ &>/dev/null; then
        return 1;
      fi

      local pkg_name=$(get_pkg_name_)
      local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")
      # print " project not found, adding new project: ${blue_cor}${proj_cmd}${reset_cor}" 2>/dev/tty

      local i=0 foundI=0 emptyI=0
      for i in {1..9}; do
        # give option to edit the project because it could have been moved to a different folder
        if (( foundI == 0 )); then
          if [[ "$proj_cmd" == "${PUMP_SHORT_NAME[$i]}" ]]; then
            foundI=$i
          elif [[ -n "${PUMP_SHORT_NAME[$i]}" && "$pkg_name" == "${PUMP_PKG_NAME[$i]}" ]]; then
            foundI=$i
            proj_cmd="${PUMP_SHORT_NAME[$i]}"
          fi
        fi
        if (( emptyI == 0 )) && [[ -z "${PUMP_SHORT_NAME[$i]}" ]]; then
          emptyI=$i
        fi
      done

      # if foundI != 0, it's because a project with the same name already exists but the folder is different
      if (( foundI )); then
        if confirm_ "update project ${bold_pink_cor}${pkg_name}${reset_cor} to new folder: ${cyan_cor}$PWD${reset_cor} ?" "update" "no"; then
          save_proj_f_ -e $foundI "$proj_cmd" "$pkg_name" 2>/dev/tty
        fi
      else
        if confirm_ "add new project: ${bold_pink_cor}${pkg_name}${reset_cor} ?" "add" "no"; then
          save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name" 2>/dev/tty
        else
          pump_chpwd_pwd_ 2>/dev/tty
        fi
      fi

      return $?;
    fi
  fi

  # pro (no name)
  if [[ -z "$proj_arg" ]]; then
    local projects=()
    for i in {1..9}; do
      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        projects+=("${PUMP_SHORT_NAME[$i]}")
      fi
    done
    if (( ${#projects[@]} == 0 )); then
      print " no projects to set"
      print " run ${hi_yellow_cor}pro -a <name>${reset_cor} to add a new project"
      return 0;
    fi
    
    proj_arg=$(choose_one_ "project to set" "${projects[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi

    pro "$proj_arg"
    return $?;
  fi

  # pro <name>
  local i=$(find_proj_index_ -o "$proj_arg" "project to set")
  if (( ! i )); then return 1; fi

  proj_arg="${PUMP_SHORT_NAME[$i]}"

  # load the project config settings
  load_config_entry_ $i

  # if (( pro_is_f )); then
  #   if [[ -f "$PUMP_PRO_PWD_FILE" ]]; then
  #     CURRENT_PUMP_SHORT_NAME=$(<"$PUMP_PRO_PWD_FILE")
  #   fi
  # else
  #   if [[ -f "$PUMP_PRO_FILE" ]]; then
  #     CURRENT_PUMP_SHORT_NAME=$(<"$PUMP_PRO_FILE")
  #   fi
  # fi

  # print "hey $proj_arg - $CURRENT_PUMP_SHORT_NAME" >&2

  if (( ! pro_is_f )) && [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
    return 0;
  fi

  set_current_proj_ $i

  if (( ! CHPWD_SILENT )); then
    print -n " project set to: ${blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}" >/dev/tty
    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      print -n " with ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" >/dev/tty
    fi
    print "" >/dev/tty
  fi

  pro -nx "$proj_arg"

  if [[ -n "$CURRENT_PUMP_PRO" ]]; then
    eval "$CURRENT_PUMP_PRO"
  fi
}

# project handler =========================================================
# pump()
function proj_handler() {
  local i="$1"
  shift

  set +x
  eval "$(parse_flags_exclusive_ "$0" "mefinru" "cprvdsmnbjae" "$@")"
  (( proj_handler_is_debug )) && set -x

  if ! check_proj_ -m $i; then return 1; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local _interval="${PUMP_INTERVAL[$i]}"

  local sub_cmds=("bkp" "clone" "gha" "jira" "prs" "release" "releases" "rev" "revs" "tag" "tags")

  if [[ " ${sub_cmds[*]} " != *" $1 "* ]]; then
    if (( proj_handler_is_h )); then
      print "  ${hi_yellow_cor}${proj_cmd} ${yellow_cor}[<folder>]${reset_cor} : open project folder"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} -e${reset_cor} : edit project"
      (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} -f ${yellow_cor}[<folder>]${reset_cor} : open project folder"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} -f <folder>${reset_cor} : open project folder"
      print "  ${hi_yellow_cor}${proj_cmd} -i${reset_cor} : display project settings"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} -m${reset_cor} : open main folder"
      print "  ${hi_yellow_cor}${proj_cmd} -n${reset_cor} : set node version using nvm"
      print "  ${hi_yellow_cor}${proj_cmd} -r${reset_cor} : remove project"
      print "  ${hi_yellow_cor}${proj_cmd} -u ${yellow_cor}[<setting>]${reset_cor} : reset settings"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} bkp${reset_cor} : create backup of the project"
      print "  ${hi_yellow_cor}${proj_cmd} bkp -d ${yellow_cor}[<folder>]${reset_cor} : delete backup folders"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} clone${reset_cor} : clone project"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} clone <branch> [<base_branch>]${reset_cor} : clone branch"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} gha ${yellow_cor}[<workflow>]${reset_cor} : check status of workflow"
      print "  ${hi_yellow_cor}${proj_cmd} gha -a ${yellow_cor}[<workflow>]${reset_cor} : check status of workflow every $_interval min"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} jira ${yellow_cor}[<jira_proj_or_key>]${reset_cor} : open ticket"
      print "  ${hi_yellow_cor}${proj_cmd} jira -c ${yellow_cor}[<jira_proj_or_key>]${reset_cor} : close ticket"
      print "  ${hi_yellow_cor}${proj_cmd} jira -p ${yellow_cor}[<jira_proj_or_key>]${reset_cor} : move ticket to \"In Progress\" status"
      print "  ${hi_yellow_cor}${proj_cmd} jira -r ${yellow_cor}[<jira_proj_or_key>]${reset_cor} : move ticket to \"In Review\" status"
      print "  ${hi_yellow_cor}${proj_cmd} jira -s ${yellow_cor}[<jira_proj_or_key>] [<ticket_status>]${reset_cor} : move ticket to status"
      print "  ${hi_yellow_cor}${proj_cmd} jira -v ${yellow_cor}[<jira_proj_or_key>]${reset_cor} : view status of ticket"
      print "  ${hi_yellow_cor}${proj_cmd} jira -vv${reset_cor} : view ticket status of all your work"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} prs${reset_cor} : open pull requests in github"
      print "  ${hi_yellow_cor}${proj_cmd} prs -a ${yellow_cor}[<search_term>]${reset_cor} : approve pull requests"
      print "  ${hi_yellow_cor}${proj_cmd} prs -aa ${yellow_cor}[<search_term>]${reset_cor} : approve pull requests every $_interval min"
      print "  ${hi_yellow_cor}${proj_cmd} prs -r${reset_cor} : rebase/merge all your open pull requests"
      print "  ${hi_yellow_cor}${proj_cmd} prs -s${reset_cor} : set assignee for all pull requests"
      print "  ${hi_yellow_cor}${proj_cmd} prs -sa${reset_cor} : set assignee for all prs every $_interval min"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} release ${yellow_cor}[<version>]${reset_cor} : create release version"
      print "  ${hi_yellow_cor}${proj_cmd} release -d ${yellow_cor}[<version>]${reset_cor} : delete release versions"
      print "  ${hi_yellow_cor}${proj_cmd} release -m${reset_cor} : create major release version"
      print "  ${hi_yellow_cor}${proj_cmd} release -n${reset_cor} : create minor release version"
      print "  ${hi_yellow_cor}${proj_cmd} release -p${reset_cor} : create patch release version"
      print "  ${hi_yellow_cor}${proj_cmd} release -s${reset_cor} : skip confirmation"
      print "  ${hi_yellow_cor}${proj_cmd} releases${reset_cor} : display releases"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} rev ${yellow_cor}[<pr_or_branch>]${reset_cor} : open code review by pr or branch"
      print "  ${hi_yellow_cor}${proj_cmd} rev -b ${yellow_cor}[<branch>]${reset_cor} : open code review by branch only"
      print "  ${hi_yellow_cor}${proj_cmd} rev -j ${yellow_cor}[<jira_key>]${reset_cor} : open code review by ticket"
      print "  ${hi_yellow_cor}${proj_cmd} rev -e${reset_cor} : open existing code review"
      print "  ${hi_yellow_cor}${proj_cmd} rev -d${reset_cor} : delete code reviews"
      print "  ${hi_yellow_cor}${proj_cmd} rev -dd${reset_cor} : delete all code reviews"
      print "  ${hi_yellow_cor}${proj_cmd} revs${reset_cor} : display code reviews"
      print "  --"
      print "  ${hi_yellow_cor}${proj_cmd} tag ${yellow_cor}[<name>]${reset_cor} : create tag"
      print "  ${hi_yellow_cor}${proj_cmd} tag -d ${yellow_cor}[<name>]${reset_cor} : delete tags"
      print "  ${hi_yellow_cor}${proj_cmd} tag -s${reset_cor} : skip confirmation"
      print "  ${hi_yellow_cor}${proj_cmd} tags ${yellow_cor}[<n>]${reset_cor} : display n number of tags"

      return 0;
    fi

    # proj_handler -e 
    if (( proj_handler_is_e )); then
      pro -e "$proj_cmd"
      return $?
    fi

    # proj_handler -i 
    if (( proj_handler_is_i )); then
      pro -i "$proj_cmd"
      return $?
    fi

    # proj_handler -r 
    if (( proj_handler_is_r )); then
      pro -r "$proj_cmd"
      return $?
    fi

    # proj_handler -m 
    if (( proj_handler_is_m )); then
      if (( single_mode )); then
        print "  ${red_cor}fatal: invalid option: -m${reset_cor}" >&2
        print "  --"
        $proj_cmd -h
        return 0;
      fi

      if ! check_proj_ -fv $i; then return 1; fi
      local proj_folder="${PUMP_FOLDER[$i]}"
      
      local folder=""
      folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)

      if [[ -n "$folder" ]]; then
        folder="$(basename "$folder")"
      fi

      proj_handler_open_ $i "$proj_folder/$folder"
      return $?;
    fi

    # proj_handler -n [<version>]
    if (( proj_handler_is_n )); then
      pro -n "$proj_cmd" "$1"
      return $?
    fi

    # proj_handler -u [<setting>]
    if (( proj_handler_is_u )); then
      pro -u "$proj_cmd" "$1"
      return $?
    fi
  fi

  # proj_handler -f [<folder>]
  if (( proj_handler_is_f )); then
    local folder="$1"

    if (( ! single_mode )) && [[ -z "$folder" ]]; then
      print " fatal: folder argument is required" >&2
      print " run: ${hi_yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if ! check_proj_ -fv $i; then return 1; fi
    local proj_folder="${PUMP_FOLDER[$i]}"

    local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder")}")

    if [[ -z "$dirs" && -n "$folder" ]]; then
      print " not a valid folder argument: $folder" >&2
      dirs=("${(@f)$(get_folders_ -p "$proj_folder")}")
      folder=""
    fi

    if [[ -n "$dirs" ]]; then
      folder=($(choose_one_ -i "folder" "${dirs[@]}"))
    fi

    local folder_to_open="${proj_folder}/${folder}"

    proj_handler_open_ $i "$folder_to_open"
    return $?;
  fi

  # proj_handler <sub_cmd>
  if [[ " ${sub_cmds[*]} " == *" $1 "* ]]; then
    local sub_cmd="$1"

    local args=("${@:2}")

    if (( proj_handler_is_h )); then
      args+=("-h")
    fi

    if [[ "$sub_cmd" == "bkp" ]]; then
      proj_bkp_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "clone" ]]; then
      proj_clone_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "gha" ]]; then
      proj_gha_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "jira" ]]; then
      proj_jira_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "prs" ]]; then
      proj_prs_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "release" ]]; then
      proj_release_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "releases" ]]; then
      proj_releases_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "rev" ]]; then
      proj_rev_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "revs" ]]; then
      proj_rev_ -e "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "tag" ]]; then
      proj_tag_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "tags" ]]; then
      proj_tags_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

  fi

  local folder="$1"
  local folder_to_open=""

  if ! check_proj_ -fv $i; then return 1; fi
  local proj_folder="${PUMP_FOLDER[$i]}"

  if (( single_mode )); then
    if [[ -n "$folder" ]]; then
      local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder")}")

      if [[ -z "$dirs" ]]; then
        print " not a valid folder argument: $folder" >&2
        folder=""
      else
        folder=($(choose_one_ -i "folder" "${dirs[@]}"))
      fi
    fi

    folder_to_open="${proj_folder}/${folder}"
  else
    local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder")}")

    if [[ -z "$dirs" && -n "$folder" ]]; then
      print " not a valid folder argument: $folder" >&2
      dirs=("${(@f)$(get_folders_ -p "$proj_folder")}")
      folder=""
    fi

    if [[ -n "$dirs" ]]; then
      folder=($(choose_one_ -i "folder" "${dirs[@]}"))
    fi

    folder_to_open="${proj_folder}/${folder}"
  fi

  proj_handler_open_ $i "$folder_to_open"
}

function proj_handler_open_() {
  local i="$1"
  local folder_to_open="$2"

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  
  if [[ "$folder_to_open" == "$proj_folder/" && -z "$(ls "$proj_folder")" ]]; then
    print " project folder is empty!" >&2
    print " run: ${hi_yellow_cor}${proj_cmd} clone${reset_cor}" >&2
  fi

  cd "$folder_to_open"
}

# commit functions ====================================================
function commit() {
  set +x
  eval "$(parse_flags_ "$0" "ams" "" "$@")"
  (( commit_is_debug )) && set -x

  if (( commit_is_h )); then
    print "  ${hi_yellow_cor}commit${reset_cor} : commit with https://www.conventionalcommits.org"
    print "  ${hi_yellow_cor}commit <message>${reset_cor} : commit  --no-verify --message"
    print "  --"
    print "  ${hi_yellow_cor}commit -m <message>${reset_cor} : same as commit <message>"
    print "  ${hi_yellow_cor}commit -a${reset_cor} : commit all files"
    print "  ${hi_yellow_cor}commit -s${reset_cor} : --signoff"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")

  if (( commit_is_a || CURRENT_PUMP_COMMIT_ADD )); then
    if ! git add .; then return 1; fi
  elif [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
    confirm_ "commit all staged and unstaged files?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      if ! git add .; then return 1; fi

      if (( i )) && confirm_ "commit all files and don't ask again?" "yes" "ask again"; then
        update_config_ $i "PUMP_COMMIT_ADD" 1
      fi
    fi
  fi

  local flags=()

  if (( commit_is_s || CURRENT_PUMP_COMMIT_SIGNOFF )); then
    flags=("--signoff")
  elif [[ -z "$CURRENT_PUMP_COMMIT_SIGNOFF" ]]; then
    confirm_ "sign off commit?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      flags=("--signoff")

      if (( i )) && confirm_ "sign off all commits and don't ask again?" "yes" "ask again"; then
        update_config_ $i "PUMP_COMMIT_SIGNOFF" 1
      fi
    fi
  fi

  if [[ -z "$1" ]]; then
    if ! command -v gum &>/dev/null; then
      print " fatal: command requires gum" >&2
      print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
      return 1;
    fi
    
    # types="fix|feat|docs|refactor|test|chore|style|revert"
    local type_commit=""
    type_commit=$(choose_one_ "commmit type" "fix" "feat" "test" "build" "chore" "ci" "docs" "perf" "refactor" "revert" "style")
    if [[ -z "$type_commit" ]]; then return 0; fi

    # scope is optional
    local scope_commit=""
    scope_commit=$(gum input --placeholder "scope")
    if (( $? != 0 )); then return 0; fi
    
    if [[ -n "$scope_commit" ]]; then
      scope_commit="($scope_commit)"
    fi

    if confirm_ "breaking change?"; then
      type_commit="${type_commit}!"
    fi
    
    local commit_msg=""
    commit_msg="$(gum input --value "${type_commit}${scope_commit}: ")"
    if (( $? != 0 )); then return 0; fi
    if [[ -z "$commit_msg" ]]; then return 0; fi

    commit_msg="${commit_msg%.}"

    local my_branch=$(get_my_branch_ "$PWD")
    if [[ -z "$my_branch" ]]; then return 1; fi

    local jira_key=$(extract_jira_key_ "$my_branch" "$PWD")
    
    if [[ -n "$jira_key" ]]; then
      local skip=0;

      local default_branch=$(get_default_branch_)
      
      git --no-pager log --no-merges "${default_branch}..${my_branch}" --pretty=format:'%s' | xargs -0 | while read -r line; do
        if [[ "$line" == "$jira_key"* ]]; then
          skip=1;
          break;
        fi
      done

      if (( skip == 0 )); then
        commit_msg="${ticket} ${commit_msg}"
      fi
    fi

    git commit --no-verify --message "$commit_msg" ${flags[@]} $@
  elif [[ $1 != -* ]]; then
    git commit --no-verify --message "$1" ${flags[@]} ${@:2}
  else
    git commit --no-verify ${flags[@]} $@
  fi  
}
# end of commit functions =============================================

function help() {
  set +x
  eval "$(parse_no_flags_ "$0" "$@")"

  if command -v gum &>/dev/null; then
    gum style --border=rounded --margin=0 --padding="1 22" --border-foreground 212 --width=71 \
      --align=center "welcome to $(gum style --foreground 212 "pump my shell! $PUMP_VERSION")"
  else
    display_line_ "" "${pink_cor}"
    display_line_ "pump my shell!" "${pink_cor}" 72 "${reset_cor}"
    display_line_ "$PUMP_VERSION" "${pink_cor}" 72 "${reset_cor}"
    display_line_ "" "${pink_cor}"
  fi

  local node_version="not installed";
  
  if command -v node &>/dev/null; then
    node_version=$(node -v 2>/dev/null)
  fi
  
  print ""
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print "  project: ${blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}"
  fi
  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print "  manager: ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
  fi
  print "  node v.: ${hi_cyan_cor}${node_version#v}${reset_cor}"

  local i=0 found=0
  for i in {1..9}; do
    if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then found=$i; break; fi
  done

  if (( found == 0 )); then
    help_general_
    print ""
    pro -a
    return $?;
  fi
  
  help_most_popular_

  if ! pause_output_; then return 0; fi
  help_projects_
  
  if ! pause_output_; then return 0; fi
  help_general_
  
  if ! pause_output_; then return 0; fi
  help_git_

  if ! pause_output_; then return 0; fi
  help_pkg_manager_

  print ""
  print "  * use ${hi_yellow_cor}-h${reset_cor} after any command to see more usage"
  print ""
  print "  visit: ${blue_cor}https://github.com/fab1o/pump-zsh/wiki${reset_cor}"
  print ""
}

function help_projects_() {
  local spaces="14s"

  print ""
  display_line_ "project" "${blue_cor}"
  print ""
  print " ${blue_cor} pro ${reset_cor}\t\t = manage projects"
  
  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_FOLDER[$i]}" && -n "${PUMP_SHORT_NAME[$i]}" ]]; then
      printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "${PUMP_SHORT_NAME[$i]}" "manage project ${PUMP_SHORT_NAME[$i]}"
    fi
  done
}

function help_general_() {
  local spaces="14s"
  
  print ""
  display_line_ "general" "${yellow_cor}"
  print ""
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "cl" "clear terminal"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete utility"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "help" "display this help"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "hg <text>" "history | grep text"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "kill <port>" "kill port"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "ll" "display all files"
  [[ "$(uname)" == "Darwin" ]] && printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "macdown" "download macos installers"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "nver" "display node version"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "nlist" "display global npm packages"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "refresh" "source .zshrc"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "upgrade" "omz update + pump update"
}

function help_most_popular_() {
  local spaces="14s"
  local max=53 # the perfect number for the spaces

  local pkg_manager="${CURRENT_PUMP_PKG_MANAGER:-npm}"

  local _fix="${CURRENT_PUMP_FIX:-"$pkg_manager run fix (format + lint)"}"
  local _run="${CURRENT_PUMP_RUN:-"$pkg_manager run dev or $pkg_manager start"}"
  local _setup="${CURRENT_PUMP_SETUP:-"$pkg_manager run setup or $pkg_manager install"}"
  
  print ""
  display_line_ "most popular" "${pink_cor}"
  print ""
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME" "manage project $CURRENT_PUMP_SHORT_NAME"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME -h" "see more usage*"
  else
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pro" "manage projects"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pro -h" "see more usage*"
  fi
  print ""
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "cl" "clear terminal"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete utility"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch from upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push branch to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "recommit" "add changes to last commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort merge/rebase/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "conti" "continue merge/rebase/chp"
  print ""
  # if (( ${#CURRENT_PUMP_COV} > max )); then
  #   printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "run CURRENT_PUMP_COV"
  # else
  #   printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "$CURRENT_PUMP_COV"
  # fi
  # printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov <b>" "compare coverage"
  if (( ${#_fix} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "run PUMP_FIX"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "$_fix"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "refix" "amend last commit + fix"
  if (( ${#_run} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "run PUMP_RUN"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "$_run"
  fi
  if (( ${#_setup} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "run PUMP_SETUP"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "$_setup"
  fi
  if (( ${#CURRENT_PUMP_TEST} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "test" "run CURRENT_PUMP_TEST"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "test" "$CURRENT_PUMP_TEST"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "tsc" "$pkg_manager run tsc"
}

function help_git_ {
  local spaces="14s"

  print ""
  display_line_ "git branch" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "back" "switch back to previous branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "base" "switch to base branch of current branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "co" "switch to a branch or create new branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "dev" "switch to dev or develop branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "main" "switch to main branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "prod" "switch to prod or production branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "stage" "switch to stage or staging branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "renb" "rename current branch"

  if ! pause_output_; then return 0; fi
  print ""
  
  display_line_ "git clean" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "clean" "clean untracked files only"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "delb" "delete branches"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "discard" "discard tracked and untracked files"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "prune" "prune branches and tags"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset1" "reset soft 1 commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset2" "reset soft 2 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset3" "reset soft 3 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset4" "reset soft 4 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset5" "reset soft 5 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseta" "erase every change, reset to last commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseto" "erase every change, reset to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "restore" "clean tracked files only"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git commit" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "add" "add files to index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rem" "remove files from index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "commit" "add + commit wizard"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "commit <m>" "add + commit message"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "recommit" "add changes to last commit"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git config" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "gconf" "display git config"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "st" "display git status"

  if ! pause_output_; then return 0; fi

  print ""
  display_line_ "git log" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "glog" "git log"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "gll" "display local branches"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "glr" "display upstream branches"

  if ! pause_output_; then return 0; fi

  print ""
  display_line_ "git merge" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort rebase/merge/revert/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "chp" "cherry-pick a commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "conti" "continue rebase/merge/revert/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "revert" "revert a commit"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git pull" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "fetch" "fetch from upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch from upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pullr" "pull --rebase"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git push" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request in github"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push branch to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pushf" "force push branch to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"
}

function help_pkg_manager_() {
  local spaces="14s"
  local max=53 # the perfect number for the spaces
  
  local pkg_manager="${CURRENT_PUMP_PKG_MANAGER:-npm}"

  local _fix="${CURRENT_PUMP_FIX:-"$pkg_manager run fix (format + lint)"}"
  local _run="${CURRENT_PUMP_RUN:-"$pkg_manager run dev or $pkg_manager start"}"
  local _setup="${CURRENT_PUMP_SETUP:-"$pkg_manager run setup or $pkg_manager install"}"
  local _run_stage="${CURRENT_PUMP_RUN_STAGE:-"$pkg_manager run stage or $pkg_manager start"}"
  local _run_prod="${CURRENT_PUMP_RUN_PROD:-"$pkg_manager run prod or $pkg_manager start"}"

  print ""
  display_line_ "$pkg_manager" "${hi_magenta_cor}"
  print ""
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "build" "$pkg_manager run build"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "deploy" "$pkg_manager run deploy"
  if (( ${#_fix} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "run PUMP_FIX"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "$_fix"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "format" "$pkg_manager run format"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "lint" "$pkg_manager run lint"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "rdev" "$pkg_manager run dev"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "rstart" "$pkg_manager run start"

  if (( ${#_run} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "run PUMP_RUN"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "$_run"
  fi
  if (( ${#_run_stage} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run stage" "run PUMP_RUN_STAGE"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run stage" "$_run_stage"
  fi
  if (( ${#_run_prod} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run prod" "run PUMP_RUN_PROD"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run prod" "$_run_prod"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "sb" "$pkg_manager run storybook"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "sbb" "$pkg_manager run storybook:build"
  if (( ${#_setup} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "run PUMP_SETUP"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "$_setup"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "start" "$pkg_manager start"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "tsc" "$pkg_manager run tsc"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "watch" "$pkg_manager run watch"
  
  if ! pause_output_; then return 0; fi

  print ""
  display_line_ "$pkg_manager test" "${hi_magenta_cor}"
  print ""
  if (( ${#CURRENT_PUMP_COV} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "run CURRENT_PUMP_COV"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "$CURRENT_PUMP_COV"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov <b>" "compare coverage"
  if (( ${#CURRENT_PUMP_E2EUI} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "e2eui" "run CURRENT_PUMP_E2EUI"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "e2eui" "$CURRENT_PUMP_E2EUI"
  fi
  if (( ${#CURRENT_PUMP_TEST} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "test" "run CURRENT_PUMP_TEST"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "test" "$CURRENT_PUMP_TEST"
  fi
  if (( ${#CURRENT_PUMP_TEST_WATCH} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "testw" "run CURRENT_PUMP_TEST_WATCH"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "testw" "$CURRENT_PUMP_TEST_WATCH"
  fi
  if [[ "$CURRENT_PUMP_TEST" != "$pkg_manager test" ]]; then
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "${pkg_manager:0:1}test" "$pkg_manager test"
  fi
  if [[ "$CURRENT_PUMP_COV" != "$pkg_manager run test:coverage" ]]; then
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "${pkg_manager:0:1}cov" "$pkg_manager run test:coverage"
  fi
  if [[ "$CURRENT_PUMP_E2E" != "$pkg_manager run test:e2e" ]]; then
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "${pkg_manager:0:1}e2e" "$pkg_manager run test:e2e"
  fi
  if [[ "$CURRENT_PUMP_E2EUI" != "$pkg_manager run test:e2e-ui" ]]; then
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "${pkg_manager:0:1}e2eui" "$pkg_manager run test:e2e-ui"
  fi
  if [[ "$CURRENT_PUMP_TEST_WATCH" != "$pkg_manager run test:watch" ]]; then
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "${pkg_manager:0:1}testw" "$pkg_manager run test:watch"
  fi
}

function validate_proj_cmd_strict_() {
  local i="$1"
  local proj_cmd="$2"
  local old_proj_cmd="$3"

  if ! validate_proj_cmd_ $i "$proj_cmd"; then
    return 1;
  fi

  # very important to not change the reserved here:
  # must declare first, then assign value
  local reserved=""
  reserved="$(whence -w "$proj_cmd" 2>/dev/null)"
  if (( $? == 0 )); then
    if [[ $reserved =~ ": function" ]]; then
      if [[ "$old_proj_cmd" == "$proj_cmd" ]]; then
        return 0;
      fi
    fi
    print "  ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  local invalid_values=("pwd" "quit" "done" "path")

  if [[ " ${invalid_values[*]} " == *" $proj_cmd "* ]]; then
    print "  ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  return 0;
}

function validate_proj_cmd_() {
  local i="$1"
  local proj_cmd="$2"
  local qty=${3:-13}

  local error_msg=""

  if [[ -z "$proj_cmd" ]]; then
    error_msg="project name is missing"
  elif [[ ${#proj_cmd} -gt $qty ]]; then
    error_msg="project name is invalid: $qty max characters"
  elif ! [[ "$proj_cmd" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    error_msg="project name is invalid: no special characters"
  elif [[ $proj_cmd == -* ]]; then
    error_msg="project name is invalid"
    return 1;
  else
    # check for duplicates across other indices
    local j=0
    for j in {1..10}; do
      if [[ $j -ne $i && "${PUMP_SHORT_NAME[$j]}" == "$proj_cmd" ]]; then
        error_msg="project name is in use: $proj_cmd"
        break;
      fi
    done
  fi

  if [[ -n "$error_msg" ]]; then
    print "  ${red_cor}${error_msg}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  return 0;
}

function colors_() {
  local i=0
  for i in {0..255};
    do print -P "%F{$i}Color $i%f";
  done
}

function get_folders_() {
  set +x
  eval "$(parse_flags_ "$0" "pontsOfj" "" "$@")"

  local folder="${1:-$PWD}"
  local name_search="$2"

  if [[ ! -d "$folder" ]]; then
    print " fatal: invalid folder argument: ${folder}" >&2
    return 1;
  fi

  local dirs=()

  # m	Sort by modification time
  # n	Sort by name
  # o	Sort in ascending order (default)
  # O	Sort in reverse order
  # N	Return an array, not a string

  unsetopt dot_glob

  if (( get_folders_is_o && get_folders_is_n )); then
    if (( get_folders_is_s )); then
      dirs=("$folder"/"$name_search"*(N/on))
    else
      dirs=("$folder"/*"$name_search"*(N/on))
    fi
  elif (( get_folders_is_o && get_folders_is_t )); then
    if (( get_folders_is_s )); then
      dirs=("$folder"/"$name_search"*(N/om))
    else
      dirs=("$folder"/*"$name_search"*(N/on))
    fi
  elif (( get_folders_is_O && get_folders_is_n )); then
    if (( get_folders_is_s )); then
      dirs=("$folder"/"$name_search"*(N/On))
    else
      dirs=("$folder"/*"$name_search"*(N/On))
    fi
  elif (( get_folders_is_O && get_folders_is_t )); then
    if (( get_folders_is_s )); then
      dirs=("$folder"/"$name_search"*(N/Om))
    else
      dirs=("$folder"/*"$name_search"*(N/Om))
    fi
  else
    if (( get_folders_is_s )); then
      dirs=("$folder"/"$name_search"*(N/On))
    else
      dirs=("$folder"/*"$name_search"*(N/On))
    fi
  fi

  local folders=()

  local dir=""
  for dir in "${dirs[@]}"; do
    if [[ "${dir##*/}" != ".revs" && "${dir##*/}" != ".cov" ]]; then
      folders+=("${dir##*/}")
    fi
  done

  local exclude_folders=("node_modules")
  local filtered_folders=()
  local name=""

  if (( get_folders_is_p || get_folders_is_f || get_folders_is_j )); then
    local priorities=(dev develop release main master production stage staging trunk mainline default stable)

    if (( get_folders_is_p )); then
      for name in "${priorities[@]}"; do
        if [[ " ${folders[@]} " == *" $name "* ]]; then
          filtered_folders+=("$name")
        fi
      done
    fi

    for name in "${folders[@]}"; do
      if [[ ! " ${priorities[@]} " == *" $name "* && ! " ${exclude_folders[@]} " == *" $name "* ]]; then
        if (( get_folders_is_j )); then
          local jira_key=$(extract_jira_key_ "$name")
          if [[ -n "$jira_key" ]]; then filtered_folders+=("$name"); fi
        else
          filtered_folders+=("$name")
        fi
      fi
    done
  else
    for name in "${folders[@]}"; do
      filtered_folders+=("$name")
    done
  fi

  for name in "${filtered_folders[@]}"; do
    echo "$name"
  done
}

# General functions ========================================================================
alias ll="ls -la" # doesn't work as a function

function cl() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( cl_is_h )); then
    print "  ${hi_yellow_cor}cl${reset_cor} : clear terminal and reset debug mode"
    return 0;
  fi

  is_debug=0

  printf "\033c"
}

function kill() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( kill_is_h )); then
    print "  ${hi_yellow_cor}kill <port>${reset_cor} : kill a port number"
    return 0;
  fi

  npx --yes kill-port $1
}

function refresh() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  #(( refresh_is_debug )) && set -x # do not turn on for refresh

  if (( refresh_is_h )); then
    print "  ${hi_yellow_cor}refresh${reset_cor} : runs 'zsh'"
    return 0;
  fi

  zsh
}

function hg() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( hg_is_h )); then
    print "  ${hi_yellow_cor}hg <test>${reset_cor} : history | grep text"
    return 0;
  fi

  if (( $# == 0 )); then
    history | grep -i "$HIST_SEARCH"
  else
    history | grep -i "$1"
  fi
}

function nver() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( nver_is_h )); then
    print "  ${hi_yellow_cor}nver${reset_cor} : display node version"
    return 0;
  fi

  if (( $# == 0 )); then
    node -e 'console.log(process.version, process.arch, process.platform)'
  else
    node -e "console.log(process.versions['$1'])"
  fi
}

function nlist() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( nlist_is_h )); then
    print "  ${hi_yellow_cor}nlist${reset_cor} : display global npm packages"
    return 0;
  fi

  if (( $# == 0 )); then
    npm list --global --depth=0
  else
    npm list --global $@
  fi
}

# ========================================================================

# general settings
typeset -g PUMP_PUSH_NO_VERIFY
typeset -g PUMP_PUSH_SET_UPSTREAM
typeset -g PUMP_RUN_OPEN_COV
typeset -g PUMP_USE_MONOGRAM
typeset -g PUMP_PR_TITLE_FORMAT

# project config settinhs
typeset -gA PUMP_SHORT_NAME
typeset -gA PUMP_FOLDER
typeset -gA PUMP_REPO
typeset -gA PUMP_SINGLE_MODE
typeset -gA PUMP_PKG_MANAGER
typeset -gA PUMP_CODE_EDITOR
typeset -gA PUMP_CLONE
typeset -gA PUMP_SETUP
typeset -gA PUMP_FIX
typeset -gA PUMP_RUN
typeset -gA PUMP_RUN_STAGE
typeset -gA PUMP_RUN_PROD
typeset -gA PUMP_PRO
typeset -gA PUMP_USE
typeset -gA PUMP_TEST
typeset -gA PUMP_RETRY_TEST
typeset -gA PUMP_COV
typeset -gA PUMP_TEST_WATCH
typeset -gA PUMP_E2E
typeset -gA PUMP_E2EUI
typeset -gA PUMP_PR_TEMPLATE_FILE
typeset -gA PUMP_PR_REPLACE
typeset -gA PUMP_PR_APPEND
typeset -gA PUMP_PR_APPROVAL_MIN
typeset -gA PUMP_INTERVAL
typeset -gA PUMP_COMMIT_ADD
typeset -gA PUMP_COMMIT_SIGNOFF
typeset -gA PUMP_PRINT_README
typeset -gA PUMP_PKG_NAME
typeset -gA PUMP_JIRA_IN_PROGRESS
typeset -gA PUMP_JIRA_IN_REVIEW
typeset -gA PUMP_JIRA_IN_DONE
typeset -gA PUMP_NVM_SKIP_LOOKUP
typeset -gA PUMP_NVM_USE_V

# ========================================================================

export CURRENT_PUMP_SHORT_NAME=""

typeset -g CURRENT_PUMP_FOLDER=""
typeset -g CURRENT_PUMP_REPO=""
typeset -g CURRENT_PUMP_SINGLE_MODE=""
typeset -g CURRENT_PUMP_PKG_MANAGER=""
typeset -g CURRENT_PUMP_CODE_EDITOR=""
typeset -g CURRENT_PUMP_CLONE=""
typeset -g CURRENT_PUMP_SETUP=""
typeset -g CURRENT_PUMP_FIX=""
typeset -g CURRENT_PUMP_RUN=""
typeset -g CURRENT_PUMP_RUN_STAGE=""
typeset -g CURRENT_PUMP_RUN_PROD=""
typeset -g CURRENT_PUMP_PRO=""
typeset -g CURRENT_PUMP_USE=""
typeset -g CURRENT_PUMP_TEST=""
typeset -g CURRENT_PUMP_RETRY_TEST=""
typeset -g CURRENT_PUMP_COV=""
typeset -g CURRENT_PUMP_OPEN_COV=""
typeset -g CURRENT_PUMP_TEST_WATCH=""
typeset -g CURRENT_PUMP_E2E=""
typeset -g CURRENT_PUMP_E2EUI=""
typeset -g CURRENT_PUMP_PR_TEMPLATE_FILE=""
typeset -g CURRENT_PUMP_PR_REPLACE=""
typeset -g CURRENT_PUMP_PR_APPEND=""
typeset -g CURRENT_PUMP_PR_APPROVAL_MIN=""
typeset -g CURRENT_PUMP_INTERVAL=""
typeset -g CURRENT_PUMP_COMMIT_ADD=""
typeset -g CURRENT_PUMP_COMMIT_SIGNOFF=""
typeset -g CURRENT_PUMP_PRINT_README=""
typeset -g CURRENT_PUMP_PKG_NAME=""
typeset -g CURRENT_PUMP_JIRA_IN_PROGRESS=""
typeset -g CURRENT_PUMP_JIRA_IN_REVIEW=""
typeset -g CURRENT_PUMP_JIRA_DONE=""
typeset -g CURRENT_PUMP_NVM_SKIP_LOOKUP=""
typeset -g CURRENT_PUMP_NVM_USE_V=""

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g TEMP_PUMP_SHORT_NAME=""
typeset -g TEMP_PUMP_FOLDER=""
typeset -g TEMP_PUMP_REPO=""
typeset -g TEMP_SINGLE_MODE=""
typeset -g TEMP_PUMP_PKG_MANAGER=""

typeset -g SAVE_COR=""
typeset -g CHPWD_SILENT=0
# ========================================================================

function preexec() {
  timer=$(print -P %D{%s%3.})
}

function precmd() {
  local time_took=""

  if [[ $timer ]]; then;
    local now=$(print -P %D{%s%3.})
    local d_ms=$(($now - $timer))
    local d_s=$((d_ms / 1000))
    local ms=$((d_ms % 1000))
    local s=$((d_s % 60))
    local m=$(((d_s / 60) % 60))
    local h=$((d_s / 3600))

    if ((h > 0)); then
      time_took="${h}h${m}m${s}s";
    elif ((m > 0)); then
      time_took="${m}m${s}.$(printf $(($ms / 100)))s";
    elif ((s > 9)); then
      time_took="${s}.$(printf %02d $(($ms / 10)))s";
    elif ((s > 0)); then
      time_took="${s}.$(printf %03d $ms)s";
    else
      time_took="${ms}ms";
    fi
    unset timer
  fi

  export PUMP_TIME_TOOK="$time_took"
}

function pump_chpwd_pwd_() {
  set_current_proj_ 0 # set to default values

  if is_folder_pkg_ "$(pwd)" &>/dev/null; then
    #if project is available, set values according to the project
    local pk_manager=""
    
    if (( CHPWD_SILENT )); then
      pk_manager=$(detect_pkg_manager_ "$(pwd)" 2>/dev/null)
    else
      pk_manager=$(detect_pkg_manager_ "$(pwd)")
    fi
    
    CURRENT_PUMP_PKG_MANAGER="${pk_manager:-npm}"
    CURRENT_PUMP_TEST="$CURRENT_PUMP_PKG_MANAGER test"
    CURRENT_PUMP_COV="$CURRENT_PUMP_PKG_MANAGER run test:coverage"
    CURRENT_PUMP_TEST_WATCH="$CURRENT_PUMP_PKG_MANAGER run test:watch"
    CURRENT_PUMP_E2E="$CURRENT_PUMP_PKG_MANAGER run test:e2e"
    CURRENT_PUMP_E2EUI="$CURRENT_PUMP_PKG_MANAGER run test:e2e-ui"

    CURRENT_PUMP_SINGLE_MODE=1

    if (( CHPWD_SILENT )); then
      CURRENT_PUMP_NVM_USE_V=$(detect_node_version_ -a "$(pwd)" 2>/dev/null)
    else
      CURRENT_PUMP_NVM_USE_V=$(detect_node_version_ -a "$(pwd)")
    fi

    if [[ -n "$CURRENT_PUMP_NVM_USE_V" ]]; then
      if (( CHPWD_SILENT )); then
        nvm use $CURRENT_PUMP_NVM_USE_V &>/dev/null
      else
        nvm use $CURRENT_PUMP_NVM_USE_V
      fi
    fi

    # print " ${yellow_cor}add this project to save detections, run: ${hi_yellow_cor}pro -a${reset_cor}" 2>/dev/tty
    return 0;
  fi

  return 1;
}

# cd pro pwd
function pump_chpwd_() {
  set +x
  local proj=$(find_proj_by_folder_ "$(pwd)")

  if [[ -n "$proj" ]]; then
    if pro "$proj"; then
      fetch --quiet &>/dev/null
    fi
  else
    if pump_chpwd_pwd_; then
      fetch --quiet &>/dev/null
    fi
  fi
}

load_config_
load_settings_
set_current_proj_ 0

local i=0
for i in {1..9}; do
  if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
    local func_name="${PUMP_SHORT_NAME[$i]}"
    functions[$func_name]="proj_handler $i \"\$@\";"
  fi
done

pro -f "pwd" 2>/dev/null
add-zsh-hook chpwd pump_chpwd_

# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs
