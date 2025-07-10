# regular colors
typeset -g black_cor=$'\e[0;30m'
typeset -g red_cor=$'\e[0;31m'
typeset -g green_cor=$'\e[0;32m'
typeset -g low_yellow_cor=$'\e[0;33m'
typeset -g yellow_cor=$'\e[0;93m' # same as hi_yellow_cor
typeset -g blue_cor=$'\e[0;34m'
typeset -g magenta_cor=$'\e[0;35m'
typeset -g cyan_cor=$'\e[0;36m'
typeset -g white_cor=$'\e[0;37m'

# special colors
typeset -g purple_cor=$'\e[38;5;99m'
typeset -g bold_purple_cor=$'\e[1;38;5;99m'
typeset -g pink_cor=$'\e[38;5;212m'
typeset -g bold_pink_cor=$'\e[1;38;5;212m'
typeset -g orange_cor=$'\e[38;5;208m'
typeset -g dark_orange_cor=$'\e[38;5;202m'
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

function parse_flags_() {
  parse_flags__ "$1" "$2$3" "$3" "${@:4}"
}

function parse_flags__() {
  set +x

  if [[ -z "$1" ]]; then
    print "${red_cor} fatal: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags="h$2"
  local valid_flags_pass_along="$3"

  shift 3

  typeset -g invalid_opts is_debug
  local internal_func=0

  if [[ "$prefix" =~ _$ ]]; then
    internal_func=1
  else
    invalid_opts=()
    prefix="${prefix}_"
  fi

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

        if [[ -n "$valid_flags" ]]; then
          if [[ $valid_flags != *$opt* ]]; then
            flags+=("-$opt")

            if [[ ! " ${invalid_opts[@]} " =~ " $opt " ]]; then
              invalid_opts+=($opt)
              echo "invalid_option+=($opt)"
              if (( ! internal_func )); then
                print "  ${red_cor}fatal: invalid option: -$opt${reset_cor}" >&2
                print "  --" >&2
              fi
            fi

            echo "${prefix}is_h=1"
          elif [[ $valid_flags_pass_along == *$opt* ]]; then
            flags+=("-$opt")
          fi
        else
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
    print "${red_cor} fatal: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags="h$2"

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
      local letters="${arg#-}"

      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        echo "${prefix}is_$opt=1"

        if [[ -n "$valid_flags" ]]; then
          if [[ $valid_flags != *$opt* ]]; then
            print "  ${red_cor}fatal: invalid option: -$opt${reset_cor}" >&2
            print "  --" >&2
            echo "${prefix}is_h=1"
          fi
        fi
      done
    else
      non_flags+=("$arg")
    fi
  done

  if [[ ${#non_flags} -gt 0 ]]; then
    print -r -- "set -- ${(q)non_flags[@]}"
  fi
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
  local question="$1"
  local option1="${2-yes}"
  local option2="${3-no}"
  local default="$4"

  local opt1="${option1[1]}"
  local opt2="${option2[1]}"

  local RET=0

  if command -v gum &>/dev/null; then
    if [[ -n "$default" && "$default" == "$option2" ]]; then
      change_default=1
    else
      change_default=0
    fi
    # VERY IMPORTANT: 2>/dev/tty to display on VSCode Terminal and on refresh
    if (( change_default )); then
      gum confirm "confirm:${reset_cor} $question" \
        --no-show-help \
        --default=false \
        --affirmative="$option1" \
        --negative="$option2" 2>/dev/tty
    else
      gum confirm "confirm:${reset_cor} $question" \
        --no-show-help \
        --affirmative="$option1" \
        --negative="$option2" 2>/dev/tty
    fi
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

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
      if ! confirm_ "install new version?" "install" "no"; then
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
  print " ${bold_purple_cor}${header}:${reset_cor}" >&2

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
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( filter_one_is_debug )) && set -x

  local header="$1"

  if command -v gum &>/dev/null; then
    print "${bold_purple_cor} choose $header: ${reset_cor}" >&2
    
    local choice=""
    
    if (( filter_one_is_a )); then
      choice="$(gum filter --select-if-one --height="20" --limit=1 --indicator=">" --placeholder=" type to filter" -- ${@:2})"
    else
      choice="$(gum filter --height="20" --limit=1 --indicator=">" --placeholder=" type to filter" -- ${@:2})"
    fi
    local RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choice"
    return 0;
  fi

  if (( filter_one_is_a )); then
    choose_one_ -a $@
  else
    choose_one_ $@
  fi
}

function choose_one_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( choose_one_is_debug )) && set -x

  local header="$1"

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_one_is_a )); then
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

  PS3="${bold_purple_cor}choose $header: ${reset_cor}"

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
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( choose_multiple_is_debug )) && set -x

  local header="$1"

  local choices

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_multiple_is_a )); then
      choices="$(gum choose --select-if-one --height="20" --no-limit --header=" choose multiple $header ${bold_purple_cor}(use spacebar to select)${bold_purple_cor}:${reset_cor}" -- ${@:2})"
    else
      choices="$(gum choose --height="20" --no-limit --header=" choose multiple $header ${bold_purple_cor}(use spacebar to select)${bold_purple_cor}:${reset_cor}" -- ${@:2})"
    fi
    local RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choices"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  choices=()
  PS3="${bold_purple_cor}choose multiple $header, then choose \"done\" to finish ${choices[*]}${reset_cor}"

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

function update_config_() {
  if ! check_config_file_; then
    print " ${red_cor}fatal: config file $PUMP_CONFIG_FILE does not exist, cannot update config${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local i="$1"
  local key="$2"
  local value="$3"
  local display_disclaimer="${4:-1}"

  value=$(echo $value | xargs)

  if [[ "$key" == "PUMP_SHORT_NAME" ]]; then
    update_config_short_name_ "$i" "$key" "$value"
  fi

  if (( i == 0 )); then
    return 0;
  # local _value=""
  # eval "_value=\${${key}[$i]}"
  # if [[ "$value" == "$_value" ]]; then
  #   return 0; # no change
  # fi
  fi

  # set the key variable
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" && "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
    if [[ -z "$value" ]]; then
      eval "CURRENT_${key}=\${${key}[0]}"
    else
      eval "CURRENT_${key}=\"$value\""
    fi
  fi

  eval "${key}[$i]=\"$value\""

  # set the config file
  local key_i="${key}_${i}"

  if grep -q "^${key_i}=" "$PUMP_CONFIG_FILE"; then
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS (BSD sed) requires correct handling of patterns
      sed -i '' "s|^$key_i=.*|$key_i=$value|" "$PUMP_CONFIG_FILE"
    else
      # Linux (GNU sed)
      sed -i "s|^$key_i=.*|$key_i=$value|" "$PUMP_CONFIG_FILE"
    fi
  else
    echo "$key_i=$value" >> "$PUMP_CONFIG_FILE"
  fi

  if (( $? != 0 )); then
    print "  ${yellow_cor}warning: failed to update ${key}_i in config${reset_cor}" >&2
    print "   • check if you have write permissions to the file: $PUMP_CONFIG_FILE" >&2
    print "   • re-install pump-zsh" >&2
  else
    print " ${gray_cor}updated config ${hi_gray_cor}${key}_$i=${value}${reset_cor}"
  fi
  if (( display_disclaimer )); then
    print " ${gray_cor}tip: reset config by running ${PUMP_SHORT_NAME[$i]} -u${reset_cor}"
  fi

  return 0;
}

function input_branch_name_() {
  local header="$1"
  local placeholder="$2"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder" 60)
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -n "$typed_value" ]] && git check-ref-format --branch "$typed_value" 1>/dev/null; then
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
  print "${bold_purple_cor} ${header}:${reset_cor}" >&2
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
          local found=0
          local j=0
          for j in {1..10}; do
            if [[ $j -ne $i && -n "$PUMP_FOLDER[$j]" && -n "${PUMP_SHORT_NAME[$j]}" ]]; then
              local folder_a="${PUMP_FOLDER[$j]:A}"

              if [[ "$new_folder_a" == "$folder_a" ]]; then
                found=$j
                print "  ${yellow_cor}folder in use by another project, select another folder${reset_cor}" >&2
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
  printf " "
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

  if [[ $input == "q" ]]; then
      clear
      return 1;
  fi

  echo "" # move to new line cleanly
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
  eval "$(parse_flags_ "$0" "rfmpv" "q" "$@")"
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
    if (( check_proj_is_v )); then
      if ! check_proj_repo_ -svq $i "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" ${@:2}; then return 1; fi
    else
      if ! check_proj_repo_ -sq $i "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" ${@:2}; then return 1; fi
    fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_REPO[$i]}" ]]; then
      print " ${red_cor}missing repository uri for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run ${yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_f )); then
    if ! check_proj_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "${PUMP_REPO[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_FOLDER[$i]}" || ! -d "${PUMP_FOLDER[$i]}" ]]; then
      print " ${red_cor}missing project folder for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run ${yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
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
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
  (( check_proj_cmd_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local old_proj_cmd="$3"

  if validate_proj_cmd_strict_ "$proj_cmd" "$old_proj_cmd"; then
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
  eval "$(parse_flags_ "$0" "sq" "" "$@")"
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
  else
    if (( check_proj_folder_is_s && ! check_proj_folder_is_q )); then
      local real_proj_folder=$(realpath -- "$proj_folder" 2>/dev/null)
      if [[ -z "$real_proj_folder" ]]; then
        if [[ -n "$pkg_name" ]]; then
          error_msg="project folder is invalid for $pkg_name: $proj_folder"
        else
          error_msg="project folder is invalid: $proj_folder"
        fi
      fi
    fi
  fi

  local j=0
  local realfolder="${proj_folder:A}"
  for j in {1..10}; do
    if [[ $j -ne $i && -n "$PUMP_FOLDER[$j]" && -n "${PUMP_SHORT_NAME[$j]}" ]]; then
      local realfolder_proj="${PUMP_FOLDER[$j]:A}"

      if [[ "$realfolder" == "$realfolder_proj" ]]; then
        error_msg="in use, please select another folder" >&2
        break;
      fi
    fi
  done

  if [[ -n "$error_msg" ]]; then
    print "  ${red_cor}${error_msg}${reset_cor}" >&2

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ -s $i "$pkg_name" "$proj_repo" "" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
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

    local multiple=$'  '/"$parent_folder_name"'/
   └─ '"$folder_name"'/
      ├─ main/
      ├─ feature-1/
      └─ feature-2/'

    local single=$'  '/"$parent_folder_name"'/
   └─ '"$folder_name"'/


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

  if command -v gum &>/dev/null; then
    setopt NO_NOTIFY
    {
      gum spin --title="detecting package manager..." -- bash -c 'sleep 2'
    } 2>/dev/tty
  fi

  local manager=""

  local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json")
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
  eval "$(parse_flags_ "$0" "aeq" "" "$@")"
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
    update_config_ $i "PUMP_SINGLE_MODE" "$single_mode" &>/dev/null
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
  eval "$(parse_flags_ "$0" "aefs" "q" "$@")"
  (( save_proj_folder_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local proj_repo="$3"
  local proj_folder="$4"

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

  if [[ -z "$proj_folder" ]]; then
    confirm_ "would you like to use an existing folder or create a new folder?" "use existing folder" "create new folder"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      header="select an existing project folder"
      folder_exists=1
    fi
    if (( RET == 1 )); then
      save_proj_repo_ -a $i "$proj_folder" "$proj_cmd" "$proj_repo"
      proj_repo="$TEMP_PUMP_REPO"
    fi
  fi

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$proj_repo" ]]; then
      local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
      proj_cmd=$(sanitize_pkg_name_ "${repo_name:t}")
    fi

    if (( RET == 1 )); then
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

    if ! check_proj_folder_ -q $i "$proj_folder" "$proj_cmd" "$proj_repo"; then return 1; fi

    if (( folder_exists == 0 )); then
      proj_folder="${proj_folder}/${proj_cmd}"

      if (( save_proj_folder_is_s )); then # only create folder if calling from check_proj_folder_
        if [[ ! -d "$proj_folder" ]]; then
          mkdir -p -- "$proj_folder"
        fi
      fi
    fi
  else
    if ! check_proj_folder_ -sq $i "$proj_folder" "$proj_cmd" "$proj_repo" ${@:5}; then return 1; fi
  fi

  if [[ -z "$proj_folder" ]]; then return 1; fi

  if (( save_proj_folder_is_q )); then
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

  local RET=0

  if (( ! save_proj_repo_is_f )) && [[ -n "$proj_repo" ]]; then
    confirm_ "keep using repository: ${blue_cor}${proj_repo}${reset_cor} ?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      proj_repo=""
    fi
  elif [[ -n "$proj_folder" ]]; then
    proj_repo=$(get_repo_ "$proj_folder" 2>/dev/null)
  fi

  if (( ! save_proj_repo_is_f )); then
    if [[ -z "$proj_repo" ]]; then
      proj_repo="$(find_repo_ "type the git repository uri (ssh or https)" "$proj_repo")"
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
    pkg_manager=($(choose_one_ "package manager" "npm" "yarn" "pnpm" "bun")) # "poe"
    if [[ -z "$pkg_manager" ]]; then return 1; fi

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder" "$proj_repo" ${@:4}; then return 1; fi
  fi
  
  if [[ -z "$pkg_manager" ]]; then return 1; fi

  update_config_ $i "PUMP_PKG_MANAGER" "$pkg_manager" &>/dev/null

  if (( save_pkg_manager_is_q )); then
    return 0;
  fi

  print "  ${SAVE_COR}package manager:${reset_cor} ${pkg_manager}${reset_cor}" >&1
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

  # all the config setting comes from $PWD
  if (( save_proj_f_is_e )); then
    update_config_ $i "PUMP_SHORT_NAME" "$proj_cmd" &>/dev/null

    if ! save_pkg_manager_ -fq $i "$PWD" "$proj_repo"; then return 1; fi
  else
    remove_proj_ $i

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo"; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -fa $i "$PWD" "$proj_repo"; then return 1; fi
    if ! save_proj_cmd_ -f $i "$proj_cmd"; then return 1; fi

    if ! update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null; then return 1; fi
    
    print "" >&1
    print "  ${SAVE_COR}project saved!${reset_cor}" >&1
    display_line_ "" "${SAVE_COR}"
  fi
  
  update_config_ $i "PUMP_FOLDER" "$PWD" &>/dev/null
  update_config_ $i "PUMP_REPO" "$proj_repo" &>/dev/null
  update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  update_config_ $i "PUMP_SINGLE_MODE" 1 &>/dev/null

  unset TEMP_SINGLE_MODE
  unset TEMP_PUMP_FOLDER
  unset TEMP_PUMP_REPO
  unset TEMP_PUMP_SHORT_NAME

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
    SAVE_COR="${yellow_cor}"
    display_line_ "edit project: ${proj_name}" "${SAVE_COR}"
  else
    SAVE_COR="${hi_cyan_cor}"
    display_line_ "add new project" "${SAVE_COR}"
  fi
  
  local old_single_mode=$(get_proj_mode_from_folder_ "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}")
  local refresh=0

  TEMP_PUMP_SHORT_NAME=""

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

    # while [[ -z "$TEMP_PUMP_FOLDER" ]]; do
    if ! save_proj_folder_ -a $i "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO" "$TEMP_PUMP_FOLDER"; then return 1; fi
    if ! save_proj_repo_ -a $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO"; then return 1; fi
    # done
    
    if ! save_proj_mode_ -a $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
  fi

  if ! save_pkg_manager_ $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO"; then return 1; fi

  local pkg_name=$(get_pkg_name_ "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO")
  
  if [[ -n "$pkg_name" ]]; then
    update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  fi

  if ! update_config_ $i "PUMP_SINGLE_MODE" "$TEMP_SINGLE_MODE" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_FOLDER" "$TEMP_PUMP_FOLDER" &>/dev/null; then return 1; fi
  if ! update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null; then return 1; fi

  print "" >&1
  print "  ${SAVE_COR}project saved!${reset_cor}" >&1
  display_line_ "" "${SAVE_COR}"

  unset TEMP_SINGLE_MODE
  unset TEMP_PUMP_FOLDER
  unset TEMP_PUMP_REPO
  unset TEMP_PUMP_SHORT_NAME

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
        print " warning: ${PUMP_SHORT_NAME[$i]} must be cloned again as project mode has changed" >&1
        print " run: ${yellow_cor}${PUMP_SHORT_NAME[$i]} clone${reset_cor}" >&1
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

  if [[ -z "$i" ]]; then
    print " fatal: set_aliases_ missing index" >&2
    return 1;
  fi

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
  eval "$(parse_flags_ "$0" "r" "" "$@")"
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
  update_config_ $i "PUMP_PR_RUN_TEST" "" &>/dev/null
  update_config_ $i "PUMP_GHA_INTERVAL" "" &>/dev/null
  update_config_ $i "PUMP_COMMIT_ADD" "" &>/dev/null
  update_config_ $i "PUMP_REFIX_PUSH" "" &>/dev/null
  update_config_ $i "PUMP_REFIX_AMEND" "" &>/dev/null
  update_config_ $i "PUMP_PRINT_README" "" &>/dev/null
  update_config_ $i "PUMP_PKG_NAME" "" &>/dev/null
  update_config_ $i "PUMP_JIRA_IN_PROGRESS" "" &>/dev/null
  update_config_ $i "PUMP_JIRA_IN_REVIEW" "" &>/dev/null
  update_config_ $i "PUMP_JIRA_DONE" "" &>/dev/null
  update_config_ $i "PUMP_NVM_SKIP_LOOKUP" "" &>/dev/null
  update_config_ $i "PUMP_NVM_USE_V" "" &>/dev/null
  update_config_ $i "PUMP_DEFAULT_BRANCH" "" &>/dev/null
  update_config_ $i "PUMP_NO_MONOGRAM" "" &>/dev/null
}

function set_current_proj_() {
  local i="$1"

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
  CURRENT_PUMP_PR_RUN_TEST="${PUMP_PR_RUN_TEST[$i]}"
  CURRENT_PUMP_GHA_INTERVAL="${PUMP_GHA_INTERVAL[$i]}"
  CURRENT_PUMP_COMMIT_ADD="${PUMP_COMMIT_ADD[$i]}"
  CURRENT_PUMP_REFIX_PUSH="${PUMP_REFIX_PUSH[$i]}"
  CURRENT_PUMP_REFIX_AMEND="${PUMP_REFIX_AMEND[$i]}"
  CURRENT_PUMP_PRINT_README="${PUMP_PRINT_README[$i]}"
  CURRENT_PUMP_PKG_NAME="${PUMP_PKG_NAME[$i]}"
  CURRENT_PUMP_JIRA_IN_PROGRESS="${PUMP_JIRA_IN_PROGRESS[$i]}"
  CURRENT_PUMP_JIRA_IN_REVIEW="${PUMP_JIRA_IN_REVIEW[$i]}"
  CURRENT_PUMP_JIRA_DONE="${PUMP_JIRA_DONE[$i]}"
  CURRENT_PUMP_NVM_SKIP_LOOKUP="${PUMP_NVM_SKIP_LOOKUP[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"
  CURRENT_PUMP_DEFAULT_BRANCH="${PUMP_DEFAULT_BRANCH[$i]}"
  CURRENT_PUMP_NO_MONOGRAM="${PUMP_NO_MONOGRAM[$i]}"

  set_aliases_ $i

  # do not need to refresh because themes were fixed
  # if [[ -n "$ZSH_THEME" ]]; then
  #   source "$ZSH/themes/${ZSH_THEME}.zsh-theme"
  # fi
}

function get_node_engine_() {
  local folder="${1:-$PWD}"

  local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json")
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
    local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json")
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
    local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json")
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
    print " [${hi_magenta_cor}PUMP_PR_RUN_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_RUN_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COMMIT_ADD_$i=${reset_cor}${hi_gray_cor}${PUMP_COMMIT_ADD[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_REFIX_PUSH_$i=${reset_cor}${hi_gray_cor}${PUMP_REFIX_PUSH[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_REFIX_AMEND_$i=${reset_cor}${hi_gray_cor}${PUMP_REFIX_AMEND[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_GHA_INTERVAL_$i=${reset_cor}${hi_gray_cor}${PUMP_GHA_INTERVAL[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PRINT_README_$i=${reset_cor}${hi_gray_cor}${PUMP_PRINT_README[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_NAME_$i=${reset_cor}${hi_gray_cor}${PUMP_PKG_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_PROGRESS_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_PROGRESS[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_REVIEW_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_REVIEW[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_DONE_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SKIP_NVM_LOOKUP_$i=${reset_cor}${hi_gray_cor}${PUMP_NVM_SKIP_LOOKUP[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_NVM_USE_V$i=${reset_cor}${hi_gray_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_DEFAULT_BRANCH_$i=${reset_cor}${hi_gray_cor}${PUMP_DEFAULT_BRANCH[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_NO_MONOGRAM_$i=${reset_cor}${hi_gray_cor}${PUMP_NO_MONOGRAM[$i]}${reset_cor}]"

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
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_RUN_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_RUN_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COMMIT_ADD=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_COMMIT_ADD}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_REFIX_PUSH=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_REFIX_PUSH}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_REFIX_AMEND=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_REFIX_AMEND}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_GHA_INTERVAL=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_GHA_INTERVAL}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PRINT_README=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PRINT_README}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_NAME=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PKG_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_PROGRESS=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_PROGRESS}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_REVIEW=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_REVIEW}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_DONE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_SKIP_LOOKUP=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NVM_SKIP_LOOKUP}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_USE_V=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NVM_USE_V}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_DEFAULT_BRANCH=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_DEFAULT_BRANCH}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NO_MONOGRAM=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NO_MONOGRAM}${reset_cor}]"
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
        print " run ${yellow_cor}pump -a${reset_cor} to add a project"
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
      print " run ${yellow_cor}pump -a${reset_cor} to add a project" >&2
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

  if [[ -z "$folder" ]]; then return 1; fi

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

  if [[ -z "$proj_folder" ]]; then return 1; fi

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
    print " fatal: not a valid folder: $proj_folder" >&2
    if [[ -n "$proj_cmd" ]]; then
      print " run ${yellow_cor}$proj_cmd -e${reset_cor} to edit project" >&2
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
    print " run ${yellow_cor}$proj_cmd clone${reset_cor} to clone project" >&2
  fi

  return 1;
}

function is_folder_git_() {
  local folder="${1:-$PWD}"

  folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2 
    return 1;
  fi

  if ! git -C "$folder" rev-parse --is-inside-work-tree 1>/dev/null; then 
    return 1;
  fi
}

function get_local_branch_() {
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
  local proj_folder="${1-$PWD}"

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then
    echo "origin"
    return 0;
  fi

  if [[ -z "$git_proj_folder" ]] || ! git -C "$git_proj_folder" rev-parse --is-inside-work-tree &>/dev/null; then
     echo "origin"
     return 0;
  fi

  local ref
  for ref in refs/remotes/{origin,upstream}/{main,master,stage,staging,prod,production,release,dev,develop,trunk,mainline,default,stable}; do
    if git -C "$git_proj_folder" show-ref -q --verify $ref; then
      echo "${${ref:h}:t}"
      return 0
    fi
  done

  echo "origin"
}

function get_remote_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "frl" "" "$@")"
  (( get_remote_branch_is_debug )) && set -x

  local branch="$1"
  local proj_folder="${2-$PWD}"

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  # get_remote_branch_ -r
  # get local name but if branch is not in remote, it fails
  # use it to check if branch exists in remote
  if (( get_remote_branch_is_r )); then
    local remote_name=$(get_remote_origin_ "$git_proj_folder")
    local remote_branch=$(git -C "$git_proj_folder" ls-remote --heads $remote_name $branch | awk '{print $2}' 2>/dev/null)
    if [[ -n "$remote_branch" ]]; then
      if (( get_remote_branch_is_f )); then
        echo "$remote_branch"
      else
        echo "${remote_branch#refs/heads/}"
      fi
      return 0;
    fi
    return 1;
  fi

  # get_remote_branch_ -l or get_remote_branch_
  # get remote name or local name if remote doesn't exist, always returns name
  # use it to check if branch exists in remote or local
  local ref=""
  for ref in refs/{remotes/{origin,upstream},heads}/$branch; do
    if git -C "$git_proj_folder" show-ref -q --verify $ref; then
      if (( get_remote_branch_is_f )); then
        echo "$ref"
      else
        echo "$branch"
      fi
      return 0
    fi
  done
  
  return 1;
}

function get_clone_default_branch_() {
  local repo_uri="$1"
  local folder="$2"
  local branch_arg="$3"

  if [[ "$branch_arg" == "main" || "$branch_arg" == "master" ]]; then
    echo "$branch_arg"
    return 0;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="cleaning the temp folder..." -- rm -rf -- "${folder}/.temp"
    if ! gum spin --title="determining the default branch..." -- git clone "$repo_uri" "${folder}/.temp" --quiet; then return 1; fi
  else
    print " determining the default branch..." >&2
    rm -rf -- "${folder}/.temp"
    if ! git clone "$repo_uri" "${folder}/.temp" --quiet; then return 1; fi
  fi
  
  local default_branch=$(git -C "${folder}/.temp" config --get init.defaultBranch)
  local my_branch=$(git -C "${folder}/.temp" symbolic-ref --short HEAD 2>/dev/null)

  rm -rf -- "${folder}/.temp"

  local selected_default_branch=""

  if [[ -n "$default_branch" && -n "$my_branch" && "$default_branch" != "$my_branch" ]]; then
    local default_branch_choice=""
    default_branch_choice=$(choose_one_ -a "default branch" "$default_branch" "$my_branch")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    selected_default_branch="$default_branch_choice"

  elif [[ -n "$default_branch" ]]; then
    selected_default_branch="$default_branch";
  else
    selected_default_branch="$my_branch";
  fi

  echo "$selected_default_branch"
}

function get_default_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( get_default_branch_is_debug )) && set -x

  local proj_folder="${1:-$PWD}"
  local default_branch=""

  if git -C "$proj_folder" rev-parse --is-inside-work-tree &>/dev/null; then
    local remote_name=$(get_remote_origin_ "$proj_folder")

    default_branch="$(LC_ALL=C git -C "$proj_folder" symbolic-ref refs/remotes/${remote_name}/HEAD 2>/dev/null)"
    if [[ -z "$default_branch" ]]; then
      default_branch=$(LC_ALL=C git -C "$proj_folder" remote show $remote_name 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    fi
  else
    local branch="$(git -C "$proj_folder" config --get init.defaultBranch 2>/dev/null)"
    if [[ -n "$branch" ]]; then
      default_branch=$(get_remote_branch_ -f "$branch" "$proj_folder")
    fi
  fi

  if [[ -n "$default_branch" ]]; then
    if (( get_default_branch_is_f )); then
      echo "$default_branch"
    else
      echo "${default_branch:t}"
    fi
    return 0;
  fi

  echo "main"
  return 1; # should never happen
}

function get_repo_() {
  local proj_folder="${1-$PWD}"

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$proj_folder")
  local remote_repo=$(git -C "$git_proj_folder" remote get-url "$remote_name" 2>/dev/null)

  if [[ -n "$remote_repo" ]]; then
    echo "$remote_repo"
    return 0;
  fi
  
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
  eval "$(parse_flags_ "$0" "talres" "" "$@")"
  (( select_branches_is_debug )) && set -x

  local searchText="$1"
  local proj_folder="${2:-$PWD}"
  local exclude_branches=(${@:4})

  local remote_name=$(get_remote_origin_ "$proj_folder")

  local branch_results=()

  if (( select_branches_is_e )); then
    select_branches_is_t=1
  else
    searchText="*$searchText*"
  fi

  if (( select_branches_is_a )); then
    fetch --quiet "$proj_folder"
    branch_results=("${(@f)$(git -C "$proj_folder" branch --all --list "$searchText" --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  elif (( select_branches_is_r )); then
    fetch --quiet "$proj_folder"
    branch_results=("${(@f)$(git -C "$proj_folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | grep -i "$searchText" \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$proj_folder" branch --list "$searchText" --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  fi

  local branches_excluded=("$exclude_branches")

  if (( select_branches_is_s )); then
    branches_excluded+=("main" "master" "dev" "develop" "stage" "staging" "prod" "production" "release")
    if (( select_branches_is_r )); then
      branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
    fi
  fi

  local filtered_branches=()

  if [[ -n "$branches_excluded" && -n "$branch_results" ]]; then
    for branch in "${branch_results[@]}"; do
      if [[ ! " ${branches_excluded[*]} " == *" $branch "* ]]; then
        filtered_branches+=("$branch")
      fi
    done
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    print -n " fatal: did not find any branch" >&2
    if [[ -n "$exclude_branches" ]]; then
      print -n ", excluding some special branches," >&2
    fi
    if [[ -n "$searchText" ]]; then
      print -n " matching: $searchText" >&2
    fi
    print " known to git" >&2
    return 1;
  fi

  local branch_choices=""
  if (( select_branches_is_t )); then
    branch_choices=$(choose_multiple_ -a "branches" $filtered_branches)
  else
    branch_choices=$(choose_multiple_ "branches" $filtered_branches)
  fi
  if (( $? == 130 || $? == 2 )); then return 130; fi

  echo "${branch_choices[@]}"
}

function select_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "alrqtix" "" "$@")"
  (( select_branch_is_debug )) && set -x

  local search_arg="$1"
  local header="${2-branch}"
  local proj_folder="${3:-$PWD}"
  local exclude_branch="$4"

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$git_proj_folder")
  local branch_results=()
    
  local search_text="*$search_arg*"
  if (( select_branch_is_x )) && [[ -n "$search_arg" ]]; then
    search_text="$search_arg"
  fi

  if (( select_branch_is_a )); then
    fetch --quiet "$git_proj_folder"

    branch_results=("${(@f)$(git -C "$git_proj_folder" branch --all --list "$search_text" --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  elif (( select_branch_is_r )); then
    fetch --quiet "$git_proj_folder"
    branch_results=("${(@f)$(git -C "$git_proj_folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | sed "s#^$remote_name/##" \
      | grep -i "$search_arg" \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$git_proj_folder" branch --list "$search_text" --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    )}")
  fi

  local filtered_branches=()

  if [[ -n "$exclude_branch" ]]; then
    local branch=""
    for branch in "${branch_results[@]}"; do
      if [[ "$exclude_branch" != "$branch" ]]; then
        filtered_branches+=("$branch")
      fi
    done
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    if (( ! select_branch_is_q )); then
      if [[ -n "$search_arg" ]]; then
        if (( select_branch_is_x )); then
          print " fatal: did not match any branch known to git: $search_arg" >&2
        else
          print " fatal: did not match any branch known to git matching: $search_arg" >&2
        fi
      else
        print " fatal: did not find any branch known to git" >&2
      fi
    fi
    return 1;
  fi

  local branch_choice=""

  # return immediately if only one branch is found, if not, return 1
  if (( select_branch_is_i )); then
    if (( ${#filtered_branches[@]} == 1 )); then
      branch_choice="${filtered_branches[1]}"
      echo "$branch_choice"
      return 0;
    fi
    return 1;
  fi

  if (( ${#filtered_branches[@]} > 20 )); then
    if (( select_branch_is_t )); then
      branch_choice=$(filter_one_ -a "$header" $filtered_branches)
    else
      branch_choice=$(filter_one_ "$header" $filtered_branches)
    fi
  else
    if (( select_branch_is_t )); then
      branch_choice=$(choose_one_ -a "$header" $filtered_branches)
    else
      branch_choice=$(choose_one_ "$header" $filtered_branches)
    fi
  fi
  if (( $? == 130 || $? == 2 )); then return 130; fi

  echo "$branch_choice"
}

function select_pr_() {
  local search_text="$1"
  local proj_repo="$2"

  local pr_list=$(gh pr list --repo "$proj_repo" | grep -i "$search_text" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}')

  if [[ -z "$pr_list" ]]; then
    if [[ -n "$proj_cmd" ]]; then
      print " no pull requests for $proj_cmd" >&2
    else
      print " no pull requests" >&2
    fi
    return 0;
  fi

  local count=$(echo "$pr_list" | wc -l)
  local titles=("${(@f)$(echo "$pr_list" | cut -f2)}")

  local select_pr_title=""
  select_pr_title=$(choose_one_ -a "pull request" "${titles[@]}")
  if (( $? == 130 || $? == 2 )); then return 130; fi
  if [[ -z "$select_pr_title" ]]; then return 1; fi

  local select_pr_choice=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}')
  local select_pr_branch=$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}')

  if [[ -z "$select_pr_choice" || -z "$select_pr_branch" ]]; then return 1; fi

  echo "${select_pr_choice}|${select_pr_branch}|${select_pr_title}"
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

  get_value_from_json_ "scripts" "$key_name" "$folder" "package.json"
}

function get_value_from_json_() {
  local section="$1"
  local key_name="$2"
  local folder="$3"
  local file="$4"

  local real_file="$(realpath -- "${folder}/${file}" 2>/dev/null)"

  if [[ -z "$real_file" ]]; then return 1; fi
  if [[ ! -f "$real_file" ]]; then return 1; fi

  local value="";

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
    print " fatal: load_config_entry_ missing project index" >&2
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
    PUMP_PR_RUN_TEST
    PUMP_GHA_INTERVAL
    PUMP_COMMIT_ADD
    PUMP_REFIX_PUSH
    PUMP_REFIX_AMEND
    PUMP_PRINT_README
    PUMP_PKG_NAME
    PUMP_JIRA_IN_PROGRESS
    PUMP_JIRA_IN_REVIEW
    PUMP_JIRA_DONE
    PUMP_NVM_SKIP_LOOKUP
    PUMP_NVM_USE_V
    PUMP_DEFAULT_BRANCH
    PUMP_NO_MONOGRAM
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
        PUMP_GHA_INTERVAL)
          value=9
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
        PUMP_PR_REPLACE[$i]="$value"
        ;;
      PUMP_PR_APPEND)
        PUMP_PR_APPEND[$i]="$value"
        ;;
      PUMP_PR_RUN_TEST)
        PUMP_PR_RUN_TEST[$i]="$value"
        ;;
      PUMP_GHA_INTERVAL)
        PUMP_GHA_INTERVAL[$i]="$value"
        ;;
      PUMP_COMMIT_ADD)
        PUMP_COMMIT_ADD[$i]="$value"
        ;;
      PUMP_REFIX_PUSH)
        PUMP_REFIX_PUSH[$i]="$value"
        ;;
      PUMP_REFIX_AMEND)
        PUMP_REFIX_AMEND[$i]="$value"
        ;;
      PUMP_PRINT_README)
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
      PUMP_DEFAULT_BRANCH)
        PUMP_DEFAULT_BRANCH[$i]="$value"
        ;;
      PUMP_NO_MONOGRAM)
        PUMP_NO_MONOGRAM[$i]="$value"
        ;;
    esac
    # print "$i - key: [$key], value: [$value]"
  done
}

function load_settings_() {
  check_settings_file_

  PUMP_PUSH_NO_VERIFY=$(sed -n "s/^PUMP_PUSH_NO_VERIFY${i}=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)

  if [[ "$PUMP_PUSH_NO_VERIFY" -ne 0 && "$PUMP_PUSH_NO_VERIFY" -ne 1 ]]; then
    PUMP_PUSH_NO_VERIFY=1
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
      print " ${red_cor}error in your pump.zshenv config file: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print " edit the file, then run ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    [[ -z "$proj_cmd" ]] && continue;  # skip if not defined

    if ! validate_proj_cmd_strict_ "$proj_cmd"; then
      print "  ${red_cor}in your pump.zshenv config file: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print "  edit the file, then run ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project repo
    local proj_repo=""
    proj_repo=$(sed -n "s/^PUMP_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)
    
    if (( $? != 0 )); then
      print " ${red_cor}error in your pump.zshenv config file: PUMP_REPO_${i}${reset_cor}" 2>/dev/tty
      print " edit the file, then run ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project folder path
    local proj_folder=""
    proj_folder=$(sed -n "s/^PUMP_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)
    
    if (( $? != 0 )); then
      print " ${red_cor}error in your pump.zshenv config file: PUMP_FOLDER_${i}${reset_cor}" 2>/dev/tty
      print " edit the file, then run ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    [[ -z "$proj_folder" ]] && continue;  # skip if not defined

    if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then
      print "  ${red_cor}in your pump.zshenv config file: PUMP_FOLDER_${i}${reset_cor}" 2>/dev/tty
      print "  edit the file, then run ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
    fi

    PUMP_REPO[$i]="$proj_repo"
    PUMP_SHORT_NAME[$i]="$proj_cmd"
    PUMP_FOLDER[$i]="$proj_folder"

    load_config_entry_ $i
  done
}

function get_branch_status_() {
  local my_branch="$1"
  local base_branch="$2"
  local proj_folder="${3:-$PWD}"

  if [[ -z "$base_branch" ]]; then
    base_branch="$(get_default_branch_ "$proj_folder" 2>/dev/null)"
    if [[ -z "$base_branch" ]]; then return 1; fi
  fi

  local remote_name=$(get_remote_origin_ "$proj_folder")

  fetch --quiet "$proj_folder"
  
  read behind ahead < <(git -C "$proj_folder" rev-list --left-right --count "${remote_name}/${base_branch}...HEAD")

  echo "${behind}|${ahead}"
}

function del_file_() {
  eval "$(parse_single_flags_ "$0" "sq" "$@")"
  (( del_file_is_debug )) && set -x

  local file="$1"
  local count="$2"
  local type="$3"

  if [[ -z "$type" ]]; then
    if [[ -L "$file" ]]; then
      type="symlink"
    elif [[ -d "$file" ]]; then
      type="folder"
    else
      type="file"
    fi
  fi

  local RET=0

  if (( ! del_file_is_s && count <= 3 )) && [[ "${file:t}" != ".DS_Store" ]]; then;
    confirm_ "delete $type: ${blue_cor}$file${reset_cor}?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET != 0 )); then
      print -l -- " ${magenta_cor}deleted${reset_cor} $file"
      return $RET;
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
  else
    print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  fi

  return 0;
}

function del_files_() {
  eval "$(parse_single_flags_ "$0" "as" "$@")"
  (( del_files_is_debug )) && set -x

  local dont_ask=0
  local count=0
  local files=("$@")

  local RET=0

  for file in "${files[@]}"; do
    if (( ! del_files_is_s )); then
      ((count++))
    fi

    local a_file="" # abolute file path

    if [[ -L "$file" ]]; then
      a_file=$(realpath -- "$file" 2>/dev/null)
    else
      file=$(realpath -- "$file" 2>/dev/null)
    fi

    if (( count > 3 )); then
      if (( dont_ask == 0 )); then
        dont_ask=1;
        confirm_ "delete all: ${blue_cor}${(j:, :)files[$count,-1]}${reset_cor}?"
        RET=$?
        if (( RET == 130 )); then
          break;
        elif (( RET == 1 )); then
          count=0
        else
          del_files_is_s=1
        fi
      else
        count=0
      fi
    fi

    if [[ -n "$file" ]]; then
      if (( del_files_is_s )); then
        del_file_ -s "$file" $count
      else
        del_file_ "$file" $count
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi

    if [[ -n "$a_file" ]]; then
      if (( del_files_is_s )); then
        del_file_ -s "$file" $count
      else
        del_file_ "$file" $count
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi
  done

  return $RET;
}

function upgrade() {
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( upgrade_is_debug )) && set -x

  if (( upgrade_is_h )); then
    print "  ${yellow_cor}upgrade${reset_cor} : upgrade pump and Oh My Zsh!"
    return 0;
  fi

  update_ -f
  omz update
}

function del() {
  eval "$(parse_single_flags_ "$0" "s" "$@")"
  (( del_is_debug )) && set -x

  if (( del_is_h )); then
    print "  ${yellow_cor}del ${low_yellow_cor}[<glob>]${reset_cor} : delete files"
    print "  ${yellow_cor}del -s${reset_cor} : skip confirmation"
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
    del_files_ -s "${files[@]}"
  else
    del_files_ "${files[@]}"
  fi
}

function fix() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( fix_is_debug )) && set -x

  if (( fix_is_h )); then
    print "  ${yellow_cor}fix ${low_yellow_cor}[<folder>]${reset_cor} : run fix script or format + lint scripts"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}fix -h${reset_cor} to see usage" >&2
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
        print " fatal: missing \"fix\", \"format\" and \"lint\" script in package.json" >&2
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
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( refix_is_debug )) && set -x

  if (( refix_is_h )); then
    print "  ${yellow_cor}refix ${low_yellow_cor}[<folder>]${reset_cor} : reset last commit then run fix lint and format then re-push"
    print "  ${yellow_cor}refix -q${reset_cor} : no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}refix -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  if ! is_folder_pkg_ "$folder"; then return 1; fi

  if [[ -z "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print " fatal: project is not set" >&2
    print " run ${yellow_cor}pro${reset_cor} to set project" >&2
    return 1;
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
      break;
    fi
  done

  local amend=0
  local commit_msg="style: lint and format"

  if (( refix_is_q )); then
    amend=1
  else
    if [[ -z "$CURRENT_PUMP_REFIX_AMEND" ]]; then
      confirm_ "create a new commit or amend last commit" "create" "amend"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      
      update_config_ $i "PUMP_REFIX_AMEND" $RET
    fi
    amend="$CURRENT_PUMP_REFIX_AMEND"
  fi

  if (( amend )); then
    commit_msg=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs -0)

    if [[ "$commit_msg" == Merge* ]]; then
      if (( ! refix_is_q )); then
        print " ${yellow_cor}warning: last commit is a merge commit, refix must create a new commit${reset_cor}" >&2
      fi
      commit_msg="style: format codebase"
      amend=0
    fi
  fi

  if (( refix_is_q )); then
    if command -v gum &>/dev/null; then
      unsetopt monitor
      unsetopt notify
      local pipe_name=$(mktemp -u)
      mkfifo "$pipe_name" &>/dev/null
      gum spin --title="refixing... \"$commit_msg\"" -- sh -c "read < $pipe_name" &
      local spin_pid=$!

      fix "$folder" &>/dev/null
      
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null
      setopt notify
      setopt monitor
    else
      fix "$folder" &>/dev/null
    fi
  else
    fix "$folder"
  fi

  if (( $? != 0 )); then
    print "" >&2
    print " ${red_cor}fatal: refix encountered an issue${reset_cor}" >&2
    return 1;
  fi

  if ! git -C "$folder" add .; then return 1; fi

  if (( amend )); then
    if ! git -C "$folder" commit --amend --message="$commit_msg" $@; then return 1; fi
  else
    if ! git -C "$folder" commit --message="$commit_msg" $@; then return 1; fi
  fi

  if [[ -n "$CURRENT_PUMP_REFIX_PUSH" && $CURRENT_PUMP_REFIX_PUSH -eq 0 ]]; then
    return 0;
  fi

  if [[ -z "$CURRENT_PUMP_REFIX_PUSH" ]] && (( ! refix_is_q )); then
    if confirm_ "fix done, push updates now?" "push" "no"; then
      update_config_ $i "PUMP_REFIX_PUSH" 1
    else
      return 0;
    fi
  fi

  pushf "$folder" $@
}

function covc_() {
  eval "$(parse_flags_ "$0" "x" "" "$@")"

  if ! command -v gum &>/dev/null; then
    print " fatal: cov requires gum" >&2
    print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
    return 1;
  fi

  if ! is_folder_pkg_; then return 1; fi
  if ! is_folder_git_; then return 1; fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")
  (( i )) || return 1;

  if ! check_proj_ -fmrvp $i; then return 1; fi 

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local pump_cov="${PUMP_COV[$i]}"
  local pump_setup="${PUMP_SETUP[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " PUMP_REPO_$i is missing for $proj_cmd" >&2
    return 1;
  fi

  if [[ -z "$pump_cov" ]]; then
    print " PUMP_COV_$i is missing for $proj_cmd" >&2
    print " edit your pump.zshenv file, then run ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch_arg="$1"

  branch_arg=$(get_remote_branch_ "$branch_arg" "$proj_folder")

  if [[ -z "$branch_arg" ]]; then
    print " fatal: not a valid branch argument" >&2
    print " run ${yellow_cor}cov -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local my_branch=$(git branch --show-current)

  if [[ "$branch_arg" == "$my_branch" ]]; then
    print " trying to compare with the same branch" >&2
    return 1;
  fi

  local branch_status=("${(@s:|:)$(get_branch_status_ "$my_branch" "$branch_arg" "" 1>/dev/null)}")
  local branch_behind="${branch_status[1]}"
  local branch_ahead="${branch_status[2]}"

  if [[ -n "$branch_behind" || -n "$branch_ahead" ]]; then
    print " ${yellow_cor}warning: your branch is behind "$branch_arg" by $branch_behind commits and ahead by $branch_ahead commits${reset_cor}" >&2
    if ! confirm_ "continue anyway?" "continue" "abort"; then
      return 1;
    fi
  fi

  local cov_folder="$(get_proj_special_folder_ -c "$proj_cmd" "$proj_folder" "$single_mode")"

  unsetopt monitor
  unsetopt notify

  local pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${branch_arg}" -- sh -c "read < $pipe_name" &
  local spin_pid=$!

  if is_folder_git_ "$cov_folder" &>/dev/null; then
    reseta -o "$cov_folder" --quiet &>/dev/null
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: could not clone project repo: $proj_repo" >&2
      return 1;
    fi
  fi

  if git -C "$cov_folder" switch "$branch_arg" --quiet &>/dev/null; then
    if ! pullr "$cov_folder" --quiet &>/dev/null; then
      rm -rf -- "$cov_folder" &>/dev/null
      git clone "$proj_repo" "$cov_folder" --quiet &>/dev/null
      if (( $? != 0 )); then
        print " fatal: could not clone project repo: $proj_repo" >&2
        return 1;
      fi
    fi
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: could not clone project repo: $proj_repo" >&2
      return 1;
    fi
  fi

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

  if ! git switch "$my_branch" --quiet &>/dev/null; then
    print " did not match any branch known to git: $branch_arg" >&2
    return 1;
  fi

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${my_branch}" -- sh -c "read < $pipe_name" &
  spin_pid=$!

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

  print ""
  display_line_ "coverage" "${hi_gray_cor}" 68
  display_double_line_ "${1:0:22}" "${hi_gray_cor}" "${my_branch:0:22}" "${hi_gray_cor}" 70
  print ""
  
  local spaces1="24s"
  local spaces2="23s"
  local color=""

  if [[ $lines1 -gt $lines2 ]]; then color="${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then color="${green_cor}"; else color=""; fi
  printf "  %-$spaces1 %s" "Lines" "$(printf "%.2f" $lines1)%"
  printf "  | "
  printf " %-$spaces2 ${color}%s${reset_cor}\n" "Lines" "$(printf "%.2f" $lines2)%"

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
    print "  ${yellow_cor}test${reset_cor} : run PUMP_TEST"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  if ! is_folder_pkg_; then return 1; fi

  (eval "$CURRENT_PUMP_TEST" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ✅ ${green_cor}test passed on first run${reset_cor}"
    return 0
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_TEST" $@)
    RET=$?

    if (( RET == 0 )); then
      print " ✅ ${green_cor}test passed on second run${reset_cor}"
      return 0;
    fi
  fi
    
  print " ❌ ${red_cor}test failed${reset_cor}"
  
  trap - INT
  
  return 1;
}

function cov() {
  set +x
  eval "$(parse_flags_ "$0" "o" "" "$@")"
  (( cov_is_debug )) && set -x

  if (( cov_is_h )); then
    print "  ${yellow_cor}cov${reset_cor} : run PUMP_COV"
    print "  ${yellow_cor}cov -o${reset_cor} : run PUMP_OPEN_COV script after coverage is done"
    print "  ${yellow_cor}cov <branch>${reset_cor} : compare test coverage with another branch"
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
    print " ✅ ${green_cor}test coverage passed on first run${reset_cor}"

    if (( cov_is_o )) && [[ -n "$CURRENT_PUMP_OPEN_COV" ]]; then
      eval "$CURRENT_PUMP_OPEN_COV"
    fi
    return 0
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_COV" $@)
    RET=$?

    if (( RET == 0 )); then
      print " ✅ ${green_cor}test coverage passed on second run${reset_cor}"
      
      if (( cov_is_o )) && [[ -n "$CURRENT_PUMP_OPEN_COV" ]]; then
        eval "$CURRENT_PUMP_OPEN_COV"
      fi
      return 0;
    fi
  fi
    
  print " ❌ ${red_cor}test coverage failed${reset_cor}"
  
  trap - INT

  return 1;
}

function testw() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( testw_is_debug )) && set -x

  if (( testw_is_h )); then
    print "  ${yellow_cor}testw${reset_cor} : run PUMP_TEST_WATCH"
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
    print "  ${yellow_cor}e2e${reset_cor} : run PUMP_E2E"
    print "  ${yellow_cor}e2e <e2e_project>${reset_cor} : run PUMP_E2E --project <e2e_project>"
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
    print "  ${yellow_cor}e2eui${reset_cor} : run PUMP_E2EUI"
    print "  ${yellow_cor}e2eui ${low_yellow_cor}[<test_project>]${reset_cor} : run PUMP_E2EUI --project"
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
    print "  ${yellow_cor}add ${low_yellow_cor}[<glob>]${reset_cor} : add files to index"
    print "  ${yellow_cor}add -a${reset_cor} : add all tracked and untracked files"
    print "  ${yellow_cor}add -t${reset_cor} : add only tracked files"
    print "  ${yellow_cor}add -ta${reset_cor} : add all tracked files (not untracked)"
    print "  ${yellow_cor}add -q${reset_cor} : --quiet"
    print "  ${yellow_cor}add -sb${reset_cor} : show git status in short-format"
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
    print "  ${yellow_cor}rem ${low_yellow_cor}[<glob>]${reset_cor} : remove files from index"
    print "  ${yellow_cor}rem -a${reset_cor} : remove all tracked and untracked files"
    print "  ${yellow_cor}rem -t${reset_cor} : remove only tracked files"
    print "  ${yellow_cor}rem -ta${reset_cor} : remove all tracked files (not untracked)"
    print "  ${yellow_cor}rem -q${reset_cor} : --quiet"
    print "  ${yellow_cor}rem -sb${reset_cor} : show git status in short-format"
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
    print "  ${yellow_cor}reset1 ${low_yellow_cor}[<folder>]${reset_cor} : reset last commit"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}reset1 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --graph --decorate -1
  git -C "$folder" reset --quiet --soft HEAD~1 $@
}

function reset2() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset2_is_debug )) && set -x

  if (( reset2_is_h )); then
    print "  ${yellow_cor}reset2 ${low_yellow_cor}[<folder>]${reset_cor} : reset 2 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}reset2 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --graph --decorate -2
  git -C "$folder" reset --quiet --soft HEAD~2 $@
}

function reset3() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset3_is_debug )) && set -x

  if (( reset3_is_h )); then
    print "  ${yellow_cor}reset3 ${low_yellow_cor}[<folder>]${reset_cor} : reset 3 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}reset3 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --graph --decorate -3
  git -C "$folder" reset --quiet --soft HEAD~3 $@
}

function reset4() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset4_is_debug )) && set -x

  if (( reset4_is_h )); then
    print "  ${yellow_cor}reset4 ${low_yellow_cor}[<folder>]${reset_cor} : reset 4 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}reset4 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --graph --decorate -4
  git -C "$folder" reset --quiet --soft HEAD~4 $@
}

function reset5() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset5_is_debug )) && set -x

  if (( reset5_is_h )); then
    print "  ${yellow_cor}reset5 ${low_yellow_cor}[<folder>]${reset_cor} : reset 5 last commits"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}reset5 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --graph --decorate -5
  git -C "$folder" reset --quiet --soft HEAD~5 $@
}

function read_commits_() {
  set +x
  eval "$(parse_flags_ "$0" "tc" "" "$@")"
  (( read_commits_is_debug )) && set -x
  
  local my_branch="$1"

  local my_remote_branch=$(get_remote_branch_ -f "$my_branch")
  local default_branch=$(git config --get "branch.${my_branch}.gh-merge-base")

  if [[ -z "$default_branch" ]]; then
    default_branch=$(get_default_branch_ -f 2>/dev/null)
  fi

  if [[ -z "$my_remote_branch" || -z "$default_branch" ]]; then
    print " fatal: cannot determine remote or default branch" >&2
    print " make sure the branch is pushed and default branch exists" >&2
    print " run ${yellow_cor}push${reset_cor}" >&2
    return 1;
  fi

  if [[ "${my_remote_branch:t}" == "${default_branch:t}" ]]; then
    print " fatal: your branch is the same as base branch" >&2
    return 1;
  fi

  local pr_title=""
  local commit_message=""

  git log --no-merges --pretty=format:'%H%x1F%s%x00' \
    "${default_branch}..${my_remote_branch}" | while IFS= read -r -d '' line; do
    
    local commit_hash="${line%%$'\x1F'*}"
    commit_hash="${commit_hash//$'\n'/}"
    commit_message="${line#*$'\x1F'}"

    # print "commit_hash=[$commit_hash]"
    # print "commit_message=[$commit_message]"

    if [[ -z "$commit_hash" || -z "$commit_message" ]]; then
      continue;
    fi

    local jira_key=$(extract_jira_key_ "$commit_message")
    
    if [[ -n "$jira_key" ]]; then
      local rest="${commit_message//$jira_key/}"

      commit_message="$rest"

      local types="fix|feat|docs|refactor|test|chore|style|revert"
      if [[ $rest =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}}):[[:space:]]*(.*)" ]]; then
        rest="${match[2]}"
      fi

      # xargs so it's safe to use for title, it converts to 1 line
      pr_title=$(echo "${jira_key} ${rest}" | xargs)
    fi

    if (( read_commits_is_c )); then
      echo "- $commit_hash - $commit_message"
    fi
  done

  if (( read_commits_is_t )); then
    if [[ -z "$pr_title" ]]; then
      pr_title=$(echo "$commit_message" | xargs)
    fi

    echo "$pr_title"
    return 0;
  fi

  if [[ -z "$commit_message" ]]; then
    print " fatal: no commits found, cannot create pull request" >&2
    return 1;
  fi
}

function pra() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( pra_is_debug )) && set -x

  if (( pra_is_h )); then
    print "  ${yellow_cor}pra${reset_cor} : set assignee as the author of all pull requests"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: pra requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! command -v jq &>/dev/null; then
    print " fatal: pra requires jq" >&2
    print " install jq: ${blue_cor}https://jqlang.org/download/${reset_cor}" >&2
    return 1;
  fi

  if ! is_folder_git_; then return 1; fi

  local prs=""
  
  if command -v gum &>/dev/null; then
    prs=$(gum spin --title="fetching pull requests..." -- gh pr list --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')
  else
    print " fetching pull requests..."
    prs=$(gh pr list --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')
  fi
  
  if (( $? != 0 )); then return 1; fi

  echo $prs | jq -c '.' | while read -r pr; do
    local pr_number=$(echo $pr | jq -r '.number')
    local author=$(echo $pr | jq -r '.author')
    local assignees=$(echo $pr | jq -r '.assignees | length')

    if [[ "$author" == "app/dependabot" ]]; then
      print " ${yellow_cor}PR #$pr_number is from Dependabot, skipping${reset_cor}"
      continue;
    fi

    if [[ "$assignees" -eq 0 ]]; then
      if gh pr edit "$pr_number" --add-assignee "$author"; then
        print " ${green_cor}PR #$pr_number set to $author${reset_cor}"
      else
        print " ${red_cor}PR #$pr_number not set to $author${reset_cor}"
      fi
    else
      print " ${green_cor}PR #$pr_number already has assignees${reset_cor}"
    fi
  done

}

function extract_jira_key_() {
  local text="$1"
  local folder="${2:-$PWD}"

  if [[ -n "$text" && $text =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
    local jira_key="$(echo "${match[1]}" | xargs)"

    echo "$jira_key"
    return 0;
  fi

  local folder_name="$(basename "$folder")"
  if [[ $folder_name =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
    local jira_key="$(echo "${match[1]}" | xargs)"
    
    echo "$jira_key"
    return 0;
  fi

  return 1;
}

function pr() {
  set +x
  eval "$(parse_flags_ "$0" "tslbfdec" "" "$@")"
  (( pr_is_debug )) && set -x

  if (( pr_is_h )); then
    print "  ${yellow_cor}pr${reset_cor} : create a pull request"
    print "  ${yellow_cor}pr -t${reset_cor} : run tests"
    print "  ${yellow_cor}pr -s${reset_cor} : skip confirmation"
    print "  --"
    print "  ${yellow_cor}pr -l${reset_cor} : set labels"
    print "  ${yellow_cor}pr -lb${reset_cor} : set label type: bug"
    print "  ${yellow_cor}pr -lf${reset_cor} : set label type: feature"
    print "  ${yellow_cor}pr -ld${reset_cor} : set label type: documentation"
    print "  ${yellow_cor}pr -le${reset_cor} : set label type: enhancement"
    print "  ${yellow_cor}pr -lc${reset_cor} : set label type: devops or ci"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: pr requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! command -v perl &>/dev/null; then
    print " fatal: pr requires perl" >&2
    print " install perl: ${blue_cor}https://learn.perl.org/installing/${reset_cor}" >&2
    return 1;
  fi

  if ! is_folder_git_; then return 1; fi

  local my_branch=$(git branch --show-current)

  if [[ -z "$my_branch" ]]; then
    print " fatal: branch is detached, cannot create pull request" >&2
    return 1;
  fi

  local i=$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")
  (( i )) || return 1;

  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    if (( pr_is_t )); then
      print " fatal: uncommitted changes detected, cannot create pull request" >&2
      print " run ${yellow_cor}pr -s${reset_cor} to skip tests" >&2
      return 1;
    fi

    if (( ! pr_is_s )); then
      if ! confirm_ "uncommitted changes detected, continue anyway?" "continue" "abort"; then
        return 0;
      fi
    fi
  fi

  fetch --quiet

  local pr_commit_msgs=("${(@f)$(read_commits_ -c "$my_branch")}")
  if [[ -z "$pr_commit_msgs" ]]; then return 1; fi

  local pr_title=$(read_commits_ -t "$my_branch")
  if [[ -z "$pr_title" ]]; then return 1; fi
  
  local jira_key=""
  local pr_labels=""

  if (( ! pr_is_s )); then
    pr_title=$(input_text_ "pull request title" "$pr_title" 255 "$pr_title")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -z "$pr_title" ]]; then return 1; fi
    print " ${bold_purple_cor}pull request title:${reset_cor} $pr_title" >&2

    jira_key=$(extract_jira_key_ "$pr_title")
    if (( $? == 1 )) && [[ -n "$jira_key" ]]; then
      pr_title="${jira_key} ${pr_title}"
    fi
  fi

  local all_labels=()

  # pr -l
  if (( pr_is_l && ! pr_is_s )); then
    if ! check_proj_ -r $i; then return 1; fi

    local proj_repo="${PUMP_REPO[$i]}"
    if [[ -z "$proj_repo" ]]; then
      print " fatal: PUMP_REPO_$i is not set" >&2
      print " edit your pump.zshenv to fix it" >&2
      return 1;
    fi

    all_labels=("${(@f)$(gh label list --repo "$proj_repo" --limit 30 | awk '{print $1}')}")
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
      if (( $? == 130 || $? == 2 )); then return 130; fi
    fi

    if [[ -n "$choose_labels" ]]; then
      pr_labels="${(j:,:)choose_labels}"
      print " ${bold_purple_cor}labels:${reset_cor} $choose_labels" >&2
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
        print " ${bold_purple_cor}pull request template:${reset_cor}"
        print " ${cyan_cor}${pr_template}${reset_cor}"
      fi

      local pr_replace=""
      pr_replace=$(input_text_ "placeholder text in the template where you want the body to be inserted")
      if (( $? == 130 || $? == 2 )); then return 130; fi
      
      if [[ -n "$pr_replace" ]]; then
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

  local test_script=""

  if [[ -n "$CURRENT_PUMP_TEST" && "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER test" ]]; then
    test_script="$CURRENT_PUMP_TEST"
  else
    test_script=$(get_script_from_pkg_json_ "test")
  fi

  if [[ -n "$test_script" ]]; then
    if (( ! pr_is_t && ! pr_is_s )) && [[ -z "$CURRENT_PUMP_PR_RUN_TEST" ]]; then
      confirm_ "run tests before pull request?";
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        update_config_ $i "PUMP_PR_RUN_TEST" 1 $updated_config
      else
        update_config_ $i "PUMP_PR_RUN_TEST" 0 $updated_config
      fi
    fi

    if (( pr_is_t || CURRENT_PUMP_PR_RUN_TEST )); then
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

  if gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$pr_labels"; then
    if [[ -n "$jira_key" ]]; then
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
    print "  ${yellow_cor}run${reset_cor} : run dev in current folder"
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${yellow_cor}run dev${reset_cor} : run dev in current folder"
      print "  ${yellow_cor}run stage${reset_cor} : run stage in current folder"
      print "  ${yellow_cor}run prod${reset_cor} : run prod in current folder"
      print "  --"
      print "  ${yellow_cor}run <folder>${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s folder on dev environment"
      print "  ${yellow_cor}run <folder> ${low_yellow_cor}[<env>]${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s folder on given environment"
    else
      print "  ${yellow_cor}run <folder>${reset_cor} : run dev in a folder"
    fi
    print "  --"
    print "  ${yellow_cor}run <project>${reset_cor} : run a project's on dev environment if single mode"
    print "  ${yellow_cor}run <project> [<env>]${reset_cor} : run a project's on an environment if single mode"
    print "  ${yellow_cor}run <project> <folder> ${low_yellow_cor}[<env>]${reset_cor} : run a project's folder on an environment"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""
  local env_mode=""

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    folder_arg="$2"
    if [[ "$3" == "dev" || "$3" == "stage" || "$3" == "prod" ]]; then
      env_mode="$3"
    else
      print " fatal: not a valid environment argument: $3" >&2
      print " run ${yellow_cor}run -h${reset_cor} to see usage" >&2
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
  local pkg_manager=""
  local pump_run=""
  
  local i=0
  
  if [[ -n "$proj_arg" ]]; then
    i=$(find_proj_index_ -o "$proj_arg" "project to run")
    if (( ! i )); then
      print " run ${yellow_cor}run -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"

    if ! check_proj_ -fmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"
    pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    pump_run="${PUMP_RUN[$i]}"

    if [[ "$env_mode" == "stage" ]]; then
      pump_run="${PUMP_RUN_STAGE[$i]}"
    elif [[ "$env_mode" == "prod" ]]; then
      pump_run="${PUMP_RUN_PROD[$i]}"
    fi

  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"
    proj_folder="$CURRENT_PUMP_FOLDER"
    pkg_manager="${CURRENT_PUMP_PKG_MANAGER:-npm}"
    pump_run="$CURRENT_PUMP_RUN"
  fi

  local folder_to_execute=""

  if [[ -n "$proj_cmd" ]]; then
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
        print " run ${yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder=$(choose_one_ -a "folder to run for $proj_cmd" "${dirs[@]}")
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    else
      folder_to_execute="$proj_folder"
    fi
  else # no proj_cmd
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run ${yellow_cor}run -h${reset_cor} to see usage"
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  if ! is_folder_pkg_ "$folder_to_execute"; then return 1; fi

  cd "$folder_to_execute"

  print " running $env_mode on ${green_cor}${folder_to_execute}${reset_cor}"

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
    print " ${magenta_cor}${pump_run}${reset_cor}"
    
    eval "$pump_run"
  else
    print " ${magenta_cor}${pump_run}${reset_cor}"
    
    if ! eval "$pump_run"; then
      if [[ "$env_mode" == "stage" || "$env_mode" == "prod" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_${env_mode:U}_$i ${reset_cor}" >&2
      else
        print " ${red_cor}failed to run PUMP_RUN_$i ${reset_cor}" >&2
      fi
      print " edit your pump.zshenv file, then run ${yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi
}

function setup() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( setup_is_debug )) && set -x

  if (( setup_is_h )); then
    print "  ${yellow_cor}setup${reset_cor} : run setup script in current folder"
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${yellow_cor}setup <folder>${reset_cor} : run setup script in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
    else
      print "  ${yellow_cor}setup <folder>${reset_cor} : run setup script in a folder"
    fi
    print "  --"
    print "  ${yellow_cor}setup <project>${reset_cor} : run setup script in a project's folder if single mode"
    print "  ${yellow_cor}setup <project> <folder>${reset_cor} : run setup script in a project's folder"
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
      print " run ${yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  elif [[ -n "$1" ]]; then
    if [[ -d "$1" ]]; then
      folder_arg="$1"
    elif is_project_ "$1"; then
      proj_arg="$1"
    else
      print " fatal: not a valid argument: $1" >&2
      print " run ${yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local proj_cmd=""
  local proj_folder=""
  local single_mode=""
  local pkg_manager=""
  local pump_setup=""
  
  local i=0

  if [[ -n "$proj_arg" ]]; then
    i=$(find_proj_index_ -o "$proj_arg" "project to setup")
    if (( ! i )); then return 1; fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"
    
    if ! check_proj_ -fmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"
    pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    pump_setup="${PUMP_SETUP[$i]}"
  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"
    proj_folder="$CURRENT_PUMP_FOLDER"
    pkg_manager="${CURRENT_PUMP_PKG_MANAGER:-npm}"
    pump_setup="$CURRENT_PUMP_SETUP"
  fi

  local folder_to_execute=""

  if [[ -n "$proj_cmd" ]]; then
    if (( ! single_mode )); then
      local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$folder_arg")}")
      if [[ -z "$dirs" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder_arg" >&2
        print " run ${yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder=$(choose_one_ -a "folder to setup" "${dirs[@]}")
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    else
      folder_to_execute="$proj_folder"
    fi
  else # no proj_cmd
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run ${yellow_cor}setup -h${reset_cor} to see usage"
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  if ! is_folder_pkg_ "$folder_to_execute"; then
    print " run ${yellow_cor}setup -h${reset_cor} to see usage"
    return 1;
  fi

  cd "$folder_to_execute"

  print " setting up... ${green_cor}${folder_to_execute}${reset_cor}"

  if [[ -z "$pump_setup" ]]; then
    pump_setup=$(get_script_from_pkg_json_ "setup" "$folder_to_execute")
    if [[ -n "$pump_setup" ]]; then
      pump_setup="$pkg_manager run setup"
    else
      pump_setup="$pkg_manager install"
    fi
    print " ${magenta_cor}${pump_setup}${reset_cor}"

    eval "$pump_setup"
  else
    print " ${magenta_cor}${pump_setup}${reset_cor}"

    if ! eval "$pump_setup"; then
      print " ${red_cor}failed to run PUMP_SETUP_$i ${reset_cor}" >&2
      print " edit your pump.zshenv file, then run ${yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi

  print ""
  print " next thing to run:"

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    local scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' "$pkg_json")
  
    local entry;
    for entry in "${(f)scripts}"; do
      local name="${entry%%=*}"
      local cmd="${entry#*=}"

      if [[ "$name" == "build" && -n "$cmd" ]]; then print "  • ${yellow_cor}build${reset_cor} (alias for \"$pkg_manager run build\")"; fi
      if [[ "$name" == "deploy" && -n "$cmd" ]]; then print "  • ${yellow_cor}deploy${reset_cor} (alias for \"$pkg_manager run deploy\")"; fi
      if [[ "$name" == "dev" && -n "$cmd" ]]; then print "  • ${yellow_cor}run${reset_cor} (alias for \"$pkg_manager run dev\")"; fi
      if [[ "$name" == "fix" && -n "$cmd" ]]; then print "  • ${yellow_cor}fix${reset_cor} (alias for \"$pkg_manager run fix\")"; fi
      if [[ "$name" == "format" && -n "$cmd" ]]; then print "  • ${yellow_cor}format${reset_cor} (alias for \"$pkg_manager run format\")"; fi
      if [[ "$name" == "lint" && -n "$cmd" ]]; then print "  • ${yellow_cor}lint${reset_cor} (alias for \"$pkg_manager run lint\")"; fi
      if [[ "$name" == "prod" && -n "$cmd" ]]; then print "  • ${yellow_cor}run prod${reset_cor} (alias for \"$pkg_manager run prod\")"; fi
      if [[ "$name" == "stage" && -n "$cmd" ]]; then print "  • ${yellow_cor}run stage${reset_cor} (alias for \"$pkg_manager run stage\")"; fi
      if [[ "$name" == "start" && -n "$cmd" ]]; then print "  • ${yellow_cor}start${reset_cor} (alias for \"$pkg_manager start\")"; fi
      if [[ "$name" == "test" && -n "$cmd" ]]; then print "  • ${yellow_cor}test${reset_cor} (alias for \"$pkg_manager test\")"; fi
      if [[ "$name" == "tsc" && -n "$cmd" ]]; then print "  • ${yellow_cor}tsc${reset_cor} (alias for \"$pkg_manager tsc\")"; fi
    done
    print "  --"
  fi

  if [[ -n "$proj_cmd" ]]; then
    print "  • ${yellow_cor}${proj_cmd} -h${reset_cor} to see more options"
  fi
  print "  • ${yellow_cor}help${reset_cor} for more help"
}

function proj_revs_() {
  set +x
  eval "$(parse_flags_ "$0" "da" "" "$@")"
  (( proj_revs_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_revs_is_h )); then
    eval "$proj_cmd -h | grep -w --color=never -E '\brevs\b'"
    return 0;
  fi

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run ${yellow_cor}$proj_cmd revs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder" "$single_mode")"
  local rev_options=(${~revs_folder}/rev.*(N/))

  if (( ${#rev_options[@]} == 0 )); then
    print " no reviews for $proj_cmd" >&2
    return 0;
  fi

  # proj_revs_ -d proj_revs_ -a
  if (( proj_revs_is_d && proj_revs_is_a )); then
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
    rev_choices=($(choose_multiple_ "reviews to delete" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}"))
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

  local rev_choice=$(choose_one_ "review to open" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}")
  if [[ -z "$rev_choice" ]]; then return 1; fi

  proj_rev_ -e "$proj_cmd" "${rev_choice//rev./}"
}

function proj_rev_() {
  set +x
  eval "$(parse_flags_ "$0" "ebja" "" "$@")"
  (( proj_rev_is_debug )) && set -x

  local proj_cmd="$1"
  local branch_arg="$2"

  if (( proj_rev_is_h )); then
    eval "$proj_cmd -h | grep -w --color=never -E '\brev\b'"
    return 0;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -rfmqv $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local code_editor="${PUMP_CODE_EDITOR[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder" "$single_mode")"

  local branch=""
  local pr_title=""
  local pr_number=""

  # proj_rev_ -e exact branch
  if (( proj_rev_is_e )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}${proj_cmd} rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -d "${revs_folder}/rev.${branch_arg}" ]]; then
      branch="$branch_arg"
    fi

    if [[ -z "$branch" ]]; then
      branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")
    fi

    if [[ -z "$branch" ]]; then
      print " fatal: did not match any branch known to git: $branch_arg" >&2
      print " run ${yellow_cor}${proj_cmd} rev -h${reset_cor} to see usage" >&2
      return 1;
    fi
  
  # proj_rev_ -j select branch
  elif (( proj_rev_is_j )); then
    local jira_key="$branch_arg"
    if [[ -z "$jira_key" ]]; then
      jira_key=$(select_jira_key_ -r $i "$proj_cmd")
      if [[ -z "$jira_key" ]]; then return 1; fi
    fi

    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
    if [[ -z "$git_proj_folder" ]]; then return 1; fi

    branch=$(select_branch_ -ai "$jira_key" "branch to review" "$git_proj_folder")
    
    if [[ -z "$branch" ]]; then return 1; fi

  # proj_rev_ -b select branch
  elif (( proj_rev_is_b )); then
    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
    if [[ -z "$git_proj_folder" ]]; then return 1; fi

    if [[ -n "$branch_arg" ]]; then
      branch=$(select_branch_ -rt "$branch_arg" "branch to review" "$git_proj_folder")
    else
      branch=$(select_branch_ -r "$branch_arg" "branch to review" "$git_proj_folder")
    fi

    if [[ -z "$branch" ]]; then return 1; fi

  else
    # check if branch arg was given and it's a branch
    if [[ -n "$branch_arg" ]]; then
      branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")
    fi

    if [[ -z "$branch" ]]; then
      local pr=("${(@s:|:)$(select_pr_ "$branch_arg" "$proj_repo")}")
      if [[ -z "${pr[2]}" ]]; then return 1; fi
      
      pr_number="${pr[1]}"
      branch="${pr[2]}"
      pr_title="${pr[3]}"
    fi

    if [[ -z "$branch" ]]; then return 1; fi
  fi

  # proj_rev_ -a
  if (( proj_rev_is_a )); then
    if ! command -v gh &>/dev/null; then
      print " fatal: rev -a requires gh" >&2
      print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
      return 1;
    fi

    local pr_number_or_branch="${pr_number:-$branch}"

    gh pr review "$pr_number_or_branch" --approve --repo "$proj_repo"
    return $?;
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local full_rev_folder="${revs_folder}/rev.${branch_folder}"

  local skip_setup=0
  local already_merged=0;

  if [[ -n "$pr_title" ]]; then
    print " preparing review for... ${green_cor}${pr_title}${reset_cor}"
    print " branch: ${green_cor}${branch}${reset_cor}"
  else
    print " preparing review for... ${green_cor}${branch}${reset_cor}"
  fi

  if is_folder_git_ "$full_rev_folder" &>/dev/null; then

    local rev_branch="$(git -C "$full_rev_folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ "$branch" != "$rev_branch" ]]; then
      if ! git -C "$full_rev_folder" switch "$branch" --discard-changes --quiet; then
        if reseta -o --quiet "$full_rev_folder" &>/dev/null; then
          git -C "$full_rev_folder" switch "$branch" --quiet
        else
          skip_setup=1
        fi
      fi
    fi

    if (( ! skip_setup )); then
      if [[ -n "$(git -C "$full_rev_folder" status --porcelain 2>/dev/null)" ]]; then
        skip_setup=1
        
        if confirm_ "branch does not reflect pull request, erase changes and reset branch?" "reset" "do nothing"; then
          if reseta -o --quiet "$full_rev_folder" &>/dev/null; then
            if ! pull --quiet "$full_rev_folder"; then
              skip_setup=1
              already_merged=1
            fi
          else
            skip_setup=1
            print " ${red_cor}failed to clean branch${reset_cor}" >&2
          fi
        else
          cd "$full_rev_folder"
          return 0;
        fi
      else
        if ! pull --quiet "$full_rev_folder"; then
          skip_setup=1
          already_merged=1
        fi
      fi
    fi

  else
    if command -v gum &>/dev/null; then
      gum spin --title="cloning... $proj_repo" -- rm -rf -- "$full_rev_folder"
      if ! gum spin --title="cloning... $proj_repo" -- git clone "$proj_repo" "$full_rev_folder"; then
        print " ${red_cor}fatal: failed to clone $proj_repo ${reset_cor}" >&2
        return 1;
      fi
    else
      print " cloning... $proj_repo"
      rm -rf -- "$full_rev_folder"
      if ! git clone "$proj_repo" "$full_rev_folder"; then return 1; fi
    fi

    if ! git -C "$full_rev_folder" switch "$branch" --quiet &>/dev/null; then
      print " ${red_cor}failed to switch to branch: ${branch}${reset_cor}"
      already_merged=1
    else
      if ! pull --quiet "$full_rev_folder"; then
        already_merged=1
      fi
    fi

    cd "$full_rev_folder"

    if [[ -n "$pump_clone" ]]; then
      print " ${magenta_cor}${pump_clone}${reset_cor}"
      if ! eval "$pump_clone"; then
        print " ${red_cor}failed to run PUMP_CLONE_$i ${reset_cor}" >&2
        print " edit your pump.zshenv file, then run ${yellow_cor}refresh${reset_cor}" >&2
      fi
    fi
  fi

  local pr_link=""

  if command -v gh &>/dev/null; then
    pr_link="$(gh pr view "$branch" --repo "$proj_repo" --json url -q .url 2>/dev/null)"
  fi

  if (( ! skip_setup )); then
    cd "$full_rev_folder"
    setup
    print "  • ${yellow_cor}revs${reset_cor} to open an existing code review"
  fi

  if (( already_merged )); then
    print ""
    print -n " ${red_cor}alert: pull request may be already merged" 
    if [[ -n "$pr_link" ]]; then
      print -n ", check out link: ${blue_cor}$pr_link"
    fi
    print "${reset_cor}"
    print ""

    cd "$full_rev_folder"
    return 0;
  fi

  if [[ -n "$pr_link" ]]; then
    print ""
    print " check out pull request link: ${blue_cor}$pr_link${reset_cor}"
  fi
  
  print ""

  if [[ -z "$code_editor" ]]; then
    code_editor=$(input_text_ "type the command of your code editor" "code" 255 "code")
    if [[ -n "$code_editor" ]] && eval "$code_editor -- $full_rev_folder"; then
      update_config_ $i "PUMP_CODE_EDITOR" "$code_editor"
      return 0;
    fi

    cd "$full_rev_folder"
    return 1;
  fi

  if confirm_ "open code editor?" "open" "no"; then
    eval "$code_editor -- $full_rev_folder"
  fi

  cd "$full_rev_folder"
}

function proj_clone_() {
  set +x
  eval "$(parse_flags_ "$0" "er" "" "$@")"
  (( proj_clone_is_debug )) && set -x

  local proj_cmd="$1"
  local branch_arg="$2"
  local base_branch_arg="$3"

  if (( proj_clone_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\bclone\b'"
    return 0;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -rfmqv $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local print_readme="${PUMP_PRINT_README[$i]}"
  local pump_default_branch="${PUMP_DEFAULT_BRANCH[$i]}"

  if (( single_mode )) && [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run ${yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

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
      if (( ! proj_clone_is_r )); then
        confirm_ "project folder is not empty, create backup and re-clone?" "re-clone" "do nothing"; 
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 1 )); then
          print " cannot clone $proj_cmd because it's set to ${purple_cor}single mode${reset_cor}" >&2
          print " run ${yellow_cor}$proj_cmd -e${reset_cor} to switch to ${pink_cor}multiple mode${reset_cor}" >&2
          return 0;
        fi
      fi
      create_backup=1
    fi

    folder_to_clone="$proj_folder"
  else
    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)

    if [[ -n "$git_proj_folder" ]]; then
      if [[ -z "$branch_arg" ]]; then
        branch_arg=$(input_branch_name_ "feature branch name")
        if [[ -z "$branch_arg" ]]; then return 1; fi

        print " ${purple_cor}feature branch name:${reset_cor} $branch_arg"
      fi

      local branch_folder="${branch_arg//\\/-}"
      branch_folder="${branch_folder//\//-}"

      folder_to_clone="${proj_folder}/${branch_folder}"

      rm -rf -- "${folder_to_clone}/.DS_Store"
      if is_folder_git_ "$folder_to_clone" &>/dev/null; then
        skip_clone=1
      fi
    fi
  fi

  local default_branch=""

  if (( skip_clone == 0 )); then
    default_branch="${base_branch_arg:-$pump_default_branch}"
    
    if [[ -z "$default_branch" ]]; then
      default_branch=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg")
      if (( $? == 130 || $? == 2 )); then return 130; fi

      if [[ -z "$default_branch" ]]; then
        local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
        local placeholder=$(get_default_branch_ "$git_proj_folder" 2>/dev/null)
        default_branch=$(input_branch_name_ "type the default branch" "$placeholder")
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

  if [[ "$branch_arg" != "$default_branch" ]]; then
    local jira_key=$(extract_jira_key_ "$branch_arg" "$folder_to_clone")
    if [[ -n "$jira_key" ]] && (( ! proj_clone_is_e )); then
      branch_arg=$(get_branch_with_monogram_ $i "$branch_arg")
    fi
  fi

  if (( ! skip_clone )); then
    print " preparing to clone branch: ${green_cor}${branch_arg}${reset_cor}"

    if (( create_backup )); then
      if ! create_backup_ -s $i "$proj_folder"; then
        return 1;
      fi
    fi

    rm -rf -- "${folder_to_clone}/.DS_Store"
    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo" -- git clone "$proj_repo" "$folder_to_clone"; then
        print " ${red_cor}fatal: failed to clone $proj_repo ${reset_cor}" >&2
        return 1;
      fi
    else
      print " cloning... $proj_repo"
      if ! git clone "$proj_repo" "$folder_to_clone"; then return 1; fi
    fi
  fi

  local RET=0

  local my_branch=$(git -C "$folder_to_clone" branch --show-current)
  if [[ "$branch_arg" != "$my_branch" ]]; then
    if [[ "$branch_arg" != "$default_branch" ]]; then
      local remote_branch=$(get_remote_branch_ "$branch_arg" "$folder_to_clone")
      if [[ -n "$remote_branch" ]]; then
        git -C "$folder_to_clone" switch "$remote_branch" &>/dev/null
      fi      
    fi
    if ! git -C "$folder_to_clone" switch -c "$branch_arg" &>/dev/null; then
      if (( ! proj_clone_is_e )); then
        print " ${yellow_cor}warning: did not create a new branch because it already exists: ${branch_arg}${reset_cor}"
      fi
      if ! git -C "$folder_to_clone" switch "$branch_arg" &>/dev/null; then
        print " ${red_cor}fatal: failed to switch branch: $branch_arg" >&2
        RET=1
      fi
    fi
  fi

  cd "$folder_to_clone"

  if (( skip_clone )); then
    return $RET;
  fi

  if [[ -n "$default_branch" && "$default_branch" != "$branch_arg" ]]; then
    local existing_default_branch=$(get_remote_branch_ -r "$default_branch" "$folder_to_clone")
    if [[ -z "$existing_default_branch" ]] && [[ "$default_branch" == "$base_branch_arg" || "$default_branch" == "$pump_default_branch" ]]; then
      print " ${yellow_cor}warning: default branch does not exist in remote repository: $default_branch${reset_cor}" >&2
    else
      print " ${magenta_cor}git config init.defaultBranch $default_branch${reset_cor}"
      git config init.defaultBranch "$default_branch"
      print " ${magenta_cor}git config branch.${branch_arg}.gh-merge-base $default_branch${reset_cor}"
      git config "branch.${branch_arg}.gh-merge-base" "$default_branch"

      if [[ -z "$pump_default_branch" || "$default_branch" != "$pump_default_branch" ]]; then
        if confirm_ "save default branch ${green_cor}${default_branch}${reset_cor} and don't ask again?" "save" "ask again"; then
          update_config_ $i "PUMP_DEFAULT_BRANCH" "$default_branch"
        fi
      fi
    fi
  fi

  if [[ -n "$pump_clone" ]]; then
    print " ${magenta_cor}${pump_clone}${reset_cor}"
    if ! eval "$pump_clone"; then
      print " ${red_cor}failed to run PUMP_CLONE_$i ${reset_cor}" >&2
      print " edit your pump.zshenv file, then run ${yellow_cor}refresh${reset_cor}" >&2
    fi
  fi

  print " default branch is: ${green_cor}$(git config --get init.defaultBranch)${reset_cor}"

  print ""
  print " next thing to run:"

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    local pump_setup="${PUMP_SETUP[$i]}"

    if [[ -z "$pump_setup" ]]; then
      local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
      local setup_script=$(get_script_from_pkg_json_ "setup" "$folder_to_clone")

      if [[ -n "$setup_script" ]]; then
        print "  • ${yellow_cor}setup${reset_cor} (alias for \"$pkg_manager run setup\")"
      else
        print "  • ${yellow_cor}setup${reset_cor} (alias for \"$pkg_manager install\")"
      fi
      print "    ${white_cor}edit PUMP_SETUP_$i in your pump.zshenv file to customize the setup script${reset_cor}"
    else
      print "  • ${yellow_cor}setup${reset_cor} (runs PUMP_SETUP_$i)"
    fi
    print "  --"
  fi

  print "  • ${yellow_cor}${proj_cmd} -h${reset_cor} to see more usage"
  print "  • ${yellow_cor}help${reset_cor} for more help"

  return $RET;
}

function select_jira_key_() {
  set +x
  eval "$(parse_flags_ "$0" "ar" "" "$@")"
  (( select_jira_key_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"

  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"

  if ! command -v acli &>/dev/null; then
    print " acli is not installed" >&2
    print " install at: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2

    return 1;
  fi

  local projects=$(acli jira project list --recent --json | jq -r '.[].key' 2>/dev/null)
  if [[ -z "$projects" ]]; then
    print " no jira projects found" >&2
    print " run ${yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2

    return 1;
  fi

  local jira_proj=$(choose_one_ "jira project for $proj_cmd" "${(@f)$(printf "%s\n" "${projects}")}")
  if [[ -z "$jira_proj" ]]; then return 1; fi

  local tickets=""

  if (( select_jira_key_is_a )); then
    # search for all tickets in the project
    tickets=$(acli jira workitem search --jql "project='$jira_proj' AND status!='$jira_done' AND \
    Sprint IS NOT EMPTY ORDER BY priority DESC" --fields="key,summary,status,assignee" | awk 'NR > 1' 2>/dev/null)

  elif (( select_jira_key_is_r)); then
    # search for tickets not assigned to current user
    tickets=$(acli jira workitem search --jql "project='$jira_proj' AND assignee!=currentUser() AND status!='$jira_done' AND \
    Sprint IS NOT EMPTY ORDER BY priority DESC" --fields="key,summary,status,assignee" | awk 'NR > 1' 2>/dev/null)

  else
    # search for tickets assigned to current user or not assigned and in "To Do" status
    tickets=$(acli jira workitem search --jql "project='$jira_proj' AND ((assignee IS EMPTY AND status='To Do') OR (assignee=currentUser() AND status!='$jira_done')) AND \
      Sprint IS NOT EMPTY ORDER BY priority DESC" --fields="key,summary,status,assignee" | awk 'NR > 1' 2>/dev/null)
  fi

  if [[ -z "$tickets" ]]; then
    print " no jira tickets found for $jira_proj" >&2
    return 0;
  fi

  local ticket=""
  ticket=$(choose_one_ "jira ticket" "${(@f)$(printf "%s\n" "$tickets")}")
  if [[ -z "$ticket" ]]; then return 1; fi

  local jira_key="${ticket%% *}"

  echo "$jira_key"

  return 0;
}

function get_branch_with_monogram_() {
  local i="$1"
  local pump_no_monogram="${PUMP_NO_MONOGRAM[$i]}"

  local branch_name="$2"

  if [[ -z "$pump_no_monogram" ]]; then
    confirm_ "use initials for the branch name: ${green_cor}${${USER:0:1}:l}-${branch_name}${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    update_config_ $i "PUMP_NO_MONOGRAM" $RET >&2
    
    pump_no_monogram="${PUMP_NO_MONOGRAM[$i]}"
  fi

  if (( pump_no_monogram == 0 )); then
    branch_name="${${USER:0:1}:l}-${branch_name}"
  fi

  echo "$branch_name"
}

function proj_jira_() {
  set +x
  eval "$(parse_flags_ "$0" "csrpv" "" "$@")"
  (( proj_jira_is_debug )) && set -x

  local proj_cmd="$1"
  local jira_key="$2"
  local jira_status="$3"

  if (( proj_jira_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\bjira\b'"
    return 0;
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fm $i; then return 1; fi

  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"

  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"In Progress"}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"In Review"}"
  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"

  # resolve jira_key
  if (( proj_jira_is_c || proj_jira_is_v )); then
    local resolved_folder="$proj_folder"
    
    if (( single_mode )); then
      local branch_found=$(select_branch_ -li "$jira_key" "branch" "$proj_folder" 2>/dev/null)
      if [[ -n "$branch_found" ]]; then
        jira_key=$(extract_jira_key_ "$branch_found")
      fi
    else
      local dirs=("${(@f)$(get_folders_ -f "$proj_folder" "$jira_key")}")
      if [[ -z "$dirs" ]]; then
        print " no folders found in project: $proj_cmd" >&2
        return 0;
      fi

      local folder=($(choose_one_ -a "folder" "${dirs[@]}"))
      if [[ -z "$folder" ]]; then return 1; fi

      resolved_folder="${proj_folder}/${folder}"

      jira_key=$(extract_jira_key_ "$folder" "$resolved_folder")
    fi

    if (( proj_jira_is_c )); then
      if (( single_mode )); then
        co -m "$resolved_folder"
        delb -se "$branch_arg" "$resolved_folder"
      else
        del "$resolved_folder"
      fi
      return $?;
    fi

    if (( proj_jira_is_v )); then
      if [[ -z "$jira_key" ]]; then
        print " fatal: could not locate a jira ticket" >&2
        return 1;
      fi

      local current_jira_status=$(acli jira workitem view "$jira_key" --fields="status" --json | jq -r '.fields.status.name')
      if [[ -z "$current_jira_status" ]]; then
        print " fatal: cannot retrieve status of jira ticket: $jira_key" >&2
        return 1;
      fi

      print " jira ticket: $jira_key"
      print " current jira status: ${green_cor}${current_jira_status}${reset_cor}"
      return 0;
    fi
  fi

  # transitioning status
  if (( proj_jira_is_s || proj_jira_is_r || proj_jira_is_p )); then
    if [[ -z "$jira_key" ]]; ; then
      jira_key=$(select_jira_key_ $i "$proj_cmd")
      if [[ -z "$jira_key" ]]; then return 1; fi
    fi

    if (( proj_jira_is_s )); then
      if [[ -z "$jira_status" ]]; then
        print " missing status argument" >&2
        return 1;
      fi
    else
      if (( proj_jira_is_p )); then
        jira_status="$jira_in_progress"
      elif (( proj_jira_is_r )); then
        jira_status="$jira_in_review"
      elif (( proj_jira_is_c )); then
        jira_status="$jira_done"
      fi
    fi

    local current_jira_status=$(acli jira workitem view "$jira_key" --fields="status" --json | jq -r '.fields.status.name')
    if [[ -z "$current_jira_status" ]]; then
      print " fatal: cannot retrieve status of jira ticket: $jira_key" >&2
      return 1;
    fi

    if [[ "$current_jira_status" == "$jira_status" ]]; then
      print " ✓ Work item $jira_key status: $current_jira_status" | grep -w "$jira_key"
      return 0;
    fi

    local RET=0

    local current_jira_assignee=$(acli jira workitem view "$jira_key" --fields="assignee" --json | jq -r '.fields.assignee.emailAddress // empty')
    local current_user=$(acli jira auth status | awk -F': ' '/Email:/ { print $2 }' 2>/dev/null)

    if [[ -z "$current_user" ]]; then
      print " fatal: cannot retrieve current jira user" >&2
      print " run ${yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2
      return 1;
    fi

    if [[ -n "$current_jira_assignee" && "$current_jira_assignee" != "$current_user" && "$current_jira_status" == "$jira_done" ]]; then
      print " ✓ Work item $jira_key status: $jira_done" | grep -w "$jira_key"
      print " cannot transition a closed jira ticket assigned to $current_jira_assignee" >&2
      return 0;
    fi

    if [[ -n "$current_jira_assignee" && "$current_jira_assignee" != "$current_user" ]]; then
      confirm_ "transition of jira ticket ${jira_key} (assigned to $current_jira_assignee) to status: ${green_cor}${jira_status}${reset_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 0; fi
    fi

    local output=""
    output=$(acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)
    RET=$?

    if echo "$output" | grep -qE "Failure"; then
      jira_status=$(input_from_ "Enter jira status (e.g. In Progress, In Review, Done)" "" 20)
      if [[ -n "$jira_status" ]] && ; then
        acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes
        RET=$?
        if (( proj_jira_is_p )); then
          update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_status"
        elif (( proj_jira_is_r )); then
          update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_status"
        elif (( proj_jira_is_c )); then
          update_config_ $i "PUMP_JIRA_DONE" "$jira_status"
        fi

        jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"$jira_in_progress"}"
        jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"$jira_in_review"}"
        jira_done="${PUMP_JIRA_DONE[$i]:-"$jira_done"}"
      fi
    else
      print " $output" | grep -w "$jira_key"
    fi

    return $RET;
  fi # end of transitioning status

  if [[ -z "$jira_key" ]]; ; then
    jira_key=$(select_jira_key_ $i "$proj_cmd")
    if [[ -z "$jira_key" ]]; then return 1; fi
  fi

  local is_cloned=0

  local git_proj_folder=""

  if (( single_mode )); then
    if ! is_folder_git_ "$proj_folder" &>/dev/null; then
      git_proj_folder="$proj_folder"
      if proj_clone_ "$proj_cmd" "$jira_key"; then
        is_cloned=1
      else
        return 1;
      fi
    fi
  else
    git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
    if [[ -z "$git_proj_folder" ]]; then
      if proj_clone_ "$proj_cmd" "$jira_key"; then
        git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
        is_cloned=1
      else
        return 1;
      fi
    fi
  fi

  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  if (( ! is_cloned )); then
    local branch_found=$(select_branch_ -li "$jira_key" "branch" "$git_proj_folder" 2>/dev/null)

    if [[ -n "$branch_found" ]]; then
      cd "$git_proj_folder"
      if co -e "$branch_found"; then
        is_cloned=1
      else
        return 1;
      fi
    else
      if (( ! single_mode )); then
        branch_found=$(select_branch_ -ri "$jira_key" "branch" "$git_proj_folder" 2>/dev/null)
        
        if [[ -n "$branch_found" ]]; then
          if proj_clone_ -e "$proj_cmd" "$jira_key"; then
            is_cloned=1
          else
            return 1;
          fi
        fi
      fi
    fi

    if (( ! is_cloned )); then
      local branch_name="$jira_key"

      # then ether create a new branch or new folder/clone
      if (( single_mode )); then
        local default_branch=$(get_default_branch_ "$git_proj_folder" 2>/dev/null)
        
        if [[ -z "$default_branch" ]]; then
          print " could not determine default branch for project: $proj_cmd" >&2
          print " run ${yellow_cor}co $branch_name <default_branch>${reset_cor} to create a new branch" >&2
          return 1;
        fi

        branch_name=$(get_branch_with_monogram_ $i "$branch_name")

        cd "$git_proj_folder"

        if ! co "$branch_name" "$default_branch"; then
          return 1;
        fi
      else
        # multiple mode
        if ! proj_clone_ "$proj_cmd" "$branch_name"; then
          return 1;
        fi
      fi
    fi
  fi

  local current_jira_assignee=$(acli jira workitem view "$jira_key" --fields="assignee" --json | jq -r '.fields.assignee.emailAddress // empty')
  local current_user=$(acli jira auth status | awk -F': ' '/Email:/ { print $2 }' 2>/dev/null)

  if [[ -z "$current_user" ]]; then
    print " fatal: cannot retrieve current jira user" >&2
    print " run ${yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2
    return 1;
  fi

  if [[ "$current_jira_assignee" != "$current_user" ]]; then
    if [[ -n "$current_jira_assignee" ]]; then
      confirm_ "jira ticket ${jira_key} is assigned to $current_jira_assignee - re-assign it to you?" "re-assign" "no"
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 0 )); then
        acli jira workitem assign --key="$jira_key" --assignee="@me" --yes
      fi
    else
      acli jira workitem assign --key="$jira_key" --assignee="@me" --yes
    fi
  fi

  proj_jira_ -p "$proj_cmd" "$jira_key"
}

function abort() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( abort_is_debug )) && set -x

  if (( abort_is_h )); then
    print "  ${yellow_cor}abort ${low_yellow_cor}[<folder>]${reset_cor} : abort any in progress rebase, merge and cherry-pick"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}abort -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! GIT_EDITOR=true git -C "$folder" rebase --abort $@ &>/dev/null; then
    if ! GIT_EDITOR=true git -C "$folder" merge --abort $@ &>/dev/null; then
      if ! GIT_EDITOR=true git -C "$folder" cherry-pick --abort $@ &>/dev/null; then
        return 1;
      fi
    fi
  fi
}

function renb() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
  (( renb_is_debug )) && set -x

  if (( renb_is_h )); then
    print "  ${yellow_cor}renb <new_branch_name>${reset_cor} : rename current branch locally"
    print "  ${yellow_cor}renb -r${reset_cor} : also rename current branch remotelly"
    return 0;
  fi

  local new_name="$1"

  if [[ -z "$new_name" ]]; then
    print " fatal: branch argument is required" >&2
    print " run ${yellow_cor}renb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! is_folder_git_; then return 1; fi

  local current_name=$(git branch --show-current)
  if [[ -z "$current_name" ]]; then
    print " fatal: branch is detached, cannot rename branch" >&2
    return 1;
  fi

  local base_branch=$(git config --get "branch.${current_name}.gh-merge-base" 2>/dev/null)

  git branch -m "$new_name" ${@:2}

  if (( $? == 0 )); then
    git config "branch.${new_name}.gh-merge-base" "$base_branch" &>/dev/null
    git config --remove-section "branch.${current_name}" &>/dev/null

    if (( renb_is_r )); then
      if git push origin :$current_name --quiet; then
        git push --set-upstream origin "$new_name"
      fi
    fi
  fi
}

function chp() {
  set +x
  eval "$(parse_flags_ "$0" "" "s" "$@")"
  (( chp_is_debug )) && set -x

  if (( chp_is_h )); then
    print "  ${yellow_cor}chp <commit_hash> ${low_yellow_cor}[<folder>]${reset_cor} : cherry-pick a commit"
    return 0;
  fi

  local folder="$PWD"
  local hash_arg=""
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      hash_arg="$1"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}chp -h${reset_cor} to see usage" >&2
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

  if [[ -z "$hash_arg" ]]; then
    print " fatal: commit hash argument is required" >&2
    print " run ${yellow_cor}chp -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  git -C "$folder" cherry-pick "$hash_arg" ${@:2}
}

function chc() {
  set +x
  eval "$(parse_flags_ "$0" "" "s" "$@")"
  (( chc_is_debug )) && set -x

  if (( chc_is_h )); then
    print "  ${yellow_cor}chc ${low_yellow_cor}[<folder>]${reset_cor} : continue in progress cherry-pick"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}chc -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null
}

function mc() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( mc_is_debug )) && set -x

  if (( mc_is_h )); then
    print "  ${yellow_cor}mc ${low_yellow_cor}[<folder>]${reset_cor} : continue in progress merge"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}mc -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! git -C "$folder" add .; then return 1; fi

  GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null
}

function rc() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( rc_is_debug )) && set -x

  if (( rc_is_h )); then
    print "  ${yellow_cor}rc ${low_yellow_cor}[<folder>]${reset_cor} : continue in progress rebase"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}rc -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! git -C "$folder" add .; then return 1; fi

  GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null
}

function cont() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( conti_is_debug )) && set -x

  if (( conti_is_h )); then
    print "  ${yellow_cor}cont ${low_yellow_cor}[<folder>]${reset_cor} : continue any in progress rebase, merge or cherry-pick"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}cont -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! git -C "$folder" add .; then return 1; fi

  if ! GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null; then
    if ! GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null; then
      if ! GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null; then
        return 1;
      fi
    fi
  fi
}

function recommit() {
  set +x
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
  (( recommit_is_debug )) && set -x

  if (( recommit_is_h )); then
    print "  ${yellow_cor}recommit ${low_yellow_cor}[<folder>]${reset_cor} : reset last commit then re-commit all changes with the same message"
    print "  ${yellow_cor}recommit -s${reset_cor} : only staged changes"
    print "  ${yellow_cor}recommit -q${reset_cor} : no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}recommit -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( ! recommit_is_q )); then
      print " nothing to do, working tree clean"
    fi
    return 1;
  fi
  
  if (( ! recommit_is_s )); then
    if ! git -C "$folder" add .; then return 1; fi
  fi

  if git -C "$folder" commit --amend --no-edit $@; then
    if (( ! ${argv[(Ie)--quiet]} && ! recommit_is_q )); then
      print ""
      git -C "$folder" --no-pager log --oneline --graph --decorate -1
      # no pbcopy
    fi
  fi
}

function fetch() {
  set +x
  eval "$(parse_flags_ "$0" "afpt" "qn" "$@")"
  (( fetch_is_debug )) && set -x

  if (( fetch_is_h )); then
    print "  ${yellow_cor}fetch ${low_yellow_cor}[folder]${reset_cor} : fetch remote changes"
    print "  ${yellow_cor}fetch -a${reset_cor} : --all"
    print "  ${yellow_cor}fetch -f${reset_cor} : --force"
    print "  ${yellow_cor}fetch -p${reset_cor} : --prune"
    print "  ${yellow_cor}fetch -t${reset_cor} : --tags"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}fetch -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

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

  local RET=0
  local results=""

  if (( fetch_is_a )); then
    results="$(git -C "$folder" fetch ${flags[@]} $@ 2>&1 | tee /dev/tty)"
    RET=$?
  else
    local remote_name=$(get_remote_origin_ "$folder")
    
    results="$(git -C "$folder" fetch $remote_name ${flags[@]} $@ 2>&1 | tee /dev/tty)"
    RET=$?
  fi

  if [[ -n "$results" ]]; then
    local current_branches=$(git -C "$folder" branch --format '%(refname:short)')

    local config=""
    for config in $(git -C "$folder" config --get-regexp "^branch\." | awk '{print $1}'); do
      local branch_name="${config#branch.}"

      if ! echo "$current_branches" | grep -q "^${branch_name}$"; then
        git -C "$folder" config --remove-section "branch.${branch_name}" &>/dev/null
      fi
    done

    print "$results"
  fi

  return $RET;
}

function gconf() {
  set +x
  eval "$(parse_flags_ "$0" "ac" "" "$@")"
  (( gconf_is_debug )) && set -x

  if (( gconf_is_h )); then
    print "  ${yellow_cor}gconf ${low_yellow_cor}[<scope>] [<folder>]${reset_cor} : display git configuration"
    return 0;
  fi

  local folder="$PWD"
  local scope_arg="local"

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}gconf -h${reset_cor} to see usage" >&2
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

  echo "${yellow_cor}== ${scope_arg} config ==${reset_cor}"

  git config --${scope_arg} --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
    printf "  ${cyan_cor}%-40s${reset_cor} = ${green_cor}%s${reset_cor}\n" "$key" "$value"
  done
  
  print ""
}

function glog() {
  set +x
  eval "$(parse_flags_ "$0" "c" "" "$@")"
  (( glog_is_debug )) && set -x

  if (( glog_is_h )); then
    print "  ${yellow_cor}glog ${low_yellow_cor}[<n>] [<branch>] [<folder>]${reset_cor} : log last n commits (7 by default)"
    print "  ${yellow_cor}glog -c <branch>${reset_cor} : log branch's commits since a given branch"
    print "  ${yellow_cor}glog -c${reset_cor} : log branch's commits since default branch"
    print "  ${yellow_cor}glog -n${reset_cor} : log n number of commits"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local base_branch=""
  local arg_count=0
  local n=7

  if [[ -n "$3" && $3 != -* ]]; then
    if [[ -d "$3" ]]; then
      folder="$3"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    branch_arg="$2"
    
    if [[ $1 == <-> ]]; then
      n="$1"
    else
      print " fatal: not a valid n argument: $1" >&2
      print " run ${yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    arg_count=3
  
  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      if [[ $1 == <-> ]]; then
        branch_arg="$2"
      else
        print " fatal: not a valid folder argument: $2" >&2
        print " run ${yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    if [[ -n "$1" && $1 != -* ]]; then
      if [[ $1 == <-> ]]; then
        n="$1"
      else
        if [[ -n "$folder" ]]; then
          branch_arg="$1"
        else
          folder="$1"
        fi
      fi
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    elif [[ $1 == <-> ]]; then
      n="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( glog_is_c )); then
    local my_branch=$(git -C "$folder" branch --show-current)
    if [[ -z "$my_branch" ]]; then
      my_branch="HEAD"
    fi

    if [[ -z "$branch_arg" ]]; then
      branch_arg=$(get_default_branch_ "$folder" 2>/dev/null)
    fi

    git -C "$folder" --no-pager log $branch_arg..$my_branch --oneline --graph --decorate $@
  else
    if (( n )); then
      git -C "$folder" --no-pager log $branch_arg --oneline --graph --decorate -n $n $@
    else
      git -C "$folder" --no-pager log $branch_arg --oneline --graph --decorate $@
    fi
  fi
}

function push() {
  set +x
  eval "$(parse_flags_ "$0" "tfnv" "qs" "$@")"
  (( push_is_debug )) && set -x

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( push_is_h )); then
    print "  ${yellow_cor}push ${low_yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify"
    print "  ${yellow_cor}push -f${reset_cor} : --force-with-lease"
    print "  ${yellow_cor}push -t${reset_cor} : --tags"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${yellow_cor}push -v${reset_cor} : --verify"
    else
      print "  ${yellow_cor}push -nv${reset_cor} : --no-verify"
    fi
    print "  ${yellow_cor}push -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local base_branch=""
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}push -h${reset_cor} to see usage" >&2
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

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " current branch is detached, cannot push" >&2
      return 1;
    fi
  fi

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
  eval "$(parse_flags_ "$0" "tfnv" "qs" "$@")"
  (( pushf_is_debug )) && set -x

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( pushf_is_h )); then
    print "  ${yellow_cor}pushf ${low_yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify --force-with-lease"
    print "  ${yellow_cor}pushf -f${reset_cor} : --force"
    print "  ${yellow_cor}pushf -t${reset_cor} : --tags"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${yellow_cor}pushf -v${reset_cor} : --verify"
    else
      print "  ${yellow_cor}pushf -nv${reset_cor} : --no-verify"
    fi
    print "  ${yellow_cor}pushf -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local base_branch=""
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}pushf -h${reset_cor} to see usage" >&2
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

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " branch is detached or not tracking a remote branch, cannot force push" >&2
      return 1;
    fi
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
    print "  ${yellow_cor}repush ${low_yellow_cor}[<folder>]${reset_cor} : reset last commit without losing your changes then re-push all changes using the same message"
    print "  ${yellow_cor}repush -s${reset_cor} : only staged changes"
    print "  ${yellow_cor}repush -q${reset_cor} : no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}repush -h${reset_cor} to see usage" >&2
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
    print "  ${yellow_cor}pullr ${low_yellow_cor}[<branch>] [<folder>]${reset_cor} : pull --rebase"
    print "  ${yellow_cor}pullr -q${reset_cor} : --quiet"
    return 0;
  fi

  pull -r "$@"
}

function pull() {
  set +x
  eval "$(parse_flags_ "$0" "trm" "pfq" "$@")"
  (( pull_is_debug )) && set -x

  if (( pull_is_h )); then
    print "  ${yellow_cor}pull ${low_yellow_cor}[<branch>] [<folder>]${reset_cor} : pull from remote"
    print "  ${yellow_cor}pull -t${reset_cor} : --tags"
    print "  ${yellow_cor}pull -r${reset_cor} : --rebase"
    print "  ${yellow_cor}pull -rm${reset_cor} : --rebase=merges"
    print "  ${yellow_cor}pull -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""

  local base_branch=""
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}pull -h${reset_cor} to see usage" >&2
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
    git -C "$folder" --no-pager log --oneline --graph --decorate -1
    # no pbcopy
  fi

  return $RET
}

function dtag() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( dtag_is_debug )) && set -x

  if (( dtag_is_h )); then
    print "  ${yellow_cor}dtag ${low_yellow_cor}[<project>] [<name>]${reset_cor} : delete a project's tag"
    print "  ${yellow_cor}dtag ${low_yellow_cor}<name>${reset_cor} : delete a tag directly"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_SHORT_NAME"
  local tag=""
  local arg_count=0

  if is_project_ "$1"; then
    proj_arg="$1"
    (( arg_count++ ))
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
      (( arg_count++ ))
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
    (( arg_count++ ))
  fi

  shift $arg_count
  
  local i=$(find_proj_index_ -o "$proj_arg" "project to delete tag")
  if (( ! i )); then return 1; fi
  
  proj_arg="${PUMP_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$proj_folder")

  if [[ -z "$tag" ]]; then
    local tags=("${(@f)$(git -C "$proj_folder" tag)}")
    
    if [[ -z "$tags" ]]; then
      print " no tags found"
      return 0;
    fi

    local selected_tags=("${(@f)$(choose_multiple_ "tags to delete" "${tags[@]}")}")
    if [[ -z "$selected_tags" ]]; then return 1; fi

    for tag in "${selected_tags[@]}"; do
      git -C "$proj_folder" tag $remote_name --delete "$tag" $@  2>/dev/null
      git -C "$proj_folder" push $remote_name --delete "$tag" $@ 2>/dev/null
    done

    return 0;
  fi

  git -C "$proj_folder" tag $remote_name --delete "$tag" $@ 2>/dev/null
  git -C "$proj_folder" push $remote_name --delete "$tag" $@ 2>/dev/null

  return 0; # don't care if it fails to delete, consider success
}

function proj_bkp_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "h" "$@")"
  (( proj_bkp_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_bkp_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\bbkp\b'"
    return 0;
  fi

  if (( proj_bkp_is_d )); then
    proj_dbkp_ $@
    return $?;
  fi

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run ${yellow_cor}$proj_cmd bkp -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local folder_to_backup="$proj_folder"

  if (( ! single_mode )); then
    local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
    if [[ -z "$dirs" ]]; then
      print " there is no folder to backup"
      return 0;
    fi

    local folder=($(choose_one_ "folder" "${dirs[@]}"))
    if [[ -z "$folder" ]]; then return 1; fi

    folder_to_backup="${proj_folder}/${folder}"
  fi

  if [[ -z "$(ls "$folder_to_backup")" ]]; then
    print " project folder is empty"
    return 0;
  fi

  local node_modules=0

  if [[ -d "$folder_to_backup/node_modules" ]]; then
    node_modules=1
  fi

  create_backup_ $i "$folder_to_backup"

  if (( node_modules )); then
    print " ${low_yellow_cor}warning: node_modules is deleted on backup to reduce size${reset_cor}"
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

  if (( proj_dbkp_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\bbkp -d\b'"
    return 0;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fm $i; then return 1; fi

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
    print " there is no backup"
    return 0;
  fi

  local dirs=("${(@f)$(get_folders_ "$backups_folder")}")

  if [[ -z "$dirs" ]]; then
    print " there is no backup"
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

# release and tag functions ===============================================

# delete release
function proj_drelease_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_drelease_is_debug )) && set -x

  local proj_cmd="$1"

  local tag=""
  local type=""

  if (( proj_drelease_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\brelease -d\b'"
    return 0;
  fi

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

  if [[ -z "$tag" ]]; then
    local tags=("${(@f)$(gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}')}")
    if [[ -z "$tags" ]]; then
      print " no release found"
      return 0;
    fi

    local selected_tags=("${(@f)$(choose_multiple_ "tags to delete" "${tags[@]}")}")
    if [[ -z "$selected_tags" ]]; then return 1; fi

    local selected_tag
    for selected_tag in "${selected_tags[@]}"; do
      tag=$(echo -e "$selected_tag" | awk -F '\t' '{print $1}')
      local type=$(echo -e "$selected_tag" | awk -F '\t' '{print $2}')
      
      proj_drelease_ "$proj_cmd" "$tag" "$type"
    done
    
    return $?;
  fi

  local RET=0

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $tag $type" -- gh release delete "$tag" --repo "$proj_repo" --cleanup-tag -y
    RET=$?
    dtag "$proj_cmd" "$tag" &>/dev/null
  else
    print " deleting... $tag $type"
    gh release delete "$tag" --repo "$proj_repo" --cleanup-tag -y
    RET=$?
    dtag "$proj_cmd" "$tag" &>/dev/null
  fi

  if (( RET == 0 )); then
    print " ${magenta_cor}deleted${reset_cor} $tag $type"
    return 0;
  fi

  return 1;
}

function proj_release_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "h" "$@")"
  (( proj_release_is_debug )) && set -x

  local proj_cmd="$1"
  local tag=""

  if (( proj_release_is_h )); then
    eval "$proj_cmd -h | grep --color=never -E '\brelease\b'"
    return 0;
  fi

  if (( proj_release_is_d )); then
    proj_drelease_ $@
    return $?;
  fi

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
  fi
  
  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -fr $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local my_branch="$(git -C "$proj_folder" branch --show-current)"

  if [[ -z "$my_branch" ]]; then
    print " fatal: branch is detached" >&2
    print " make sure you are on a release branch before" >&2
    return 1;
  fi

  if [[ -n "$(git -C "$proj_folder" status --porcelain)" ]]; then
    print " fatal: uncommitted changes detected" >&2
    print " commit or stash your changes before creating a release" >&2
    return 1;
  fi

  # check if name is conventional
  if ! [[ "$my_branch" =~ ^(main|master|stage|staging|prod|production|release)$ || "$my_branch" == release* ]]; then
    print " ${yellow_cor}warning: unconventional branch to release: $my_branch ${yellow_cor}"
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

      if ! pull --quiet "$proj_folder"; then return 1; fi

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
      print " tag must have format: <major>.<minor>.<patch>"
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
    if ! confirm_ "create a new release for $proj_cmd: $tag ?"; then
      clean "$proj_folder"
      return 1;
    fi
  fi

  # check of git status is dirty
  if [[ -n "$(git -C "$proj_folder" status --porcelain 2>/dev/null)" ]]; then
    if ! git -C "$proj_folder" add .; then return 1; fi
    if ! git -C "$proj_folder" commit --no-verify --message="chore: release version $tag"; then return 1; fi
  fi

  if gh release view "$tag" --repo "$proj_repo" 1>/dev/null 2>&1; then
    if (( ! proj_release_is_s )); then
      if confirm_ "release already exists: $tag - re-release it?"; then
        gh release delete "$tag" --repo "$proj_repo" --yes
      fi
    fi
  fi

  dtag -q "$proj_cmd" "$tag" &>/dev/null

  if ! tag "$proj_cmd" "$tag"; then return 1; fi
  if ! push --tags --quiet "$proj_folder"; then return 1; fi

  if gh release create "$tag" --repo "$proj_repo" --title="$tag" --generate-notes; then
    push "$proj_folder"
  fi
}

function tag() {
  set +x
  eval "$(parse_flags_ "$0" "sq" "q" "$@")"
  (( tag_is_debug )) && set -x

  if (( tag_is_h )); then
    print "  ${yellow_cor}tag ${low_yellow_cor}[<project>] [<name>]${reset_cor} : create a new tag for a project"
    print "  ${yellow_cor}tag ${low_yellow_cor}[<name>]${reset_cor} : create a new tag directly"
    print "  ${yellow_cor}tag -s${reset_cor} : skip confirmation"
    print "  ${yellow_cor}tag -q${reset_cor} : tag --quiet"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_SHORT_NAME"
  local tag=""
  local arg_count=0

  if is_project_ "$1"; then
    proj_arg="$1"
    (( arg_count++ ))
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
      (( arg_count++ ))
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
    (( arg_count++ ))
  fi

  shift $arg_count
  
  local i=$(find_proj_index_ -o "$proj_arg" "project to create tag")
  if (( ! i )); then return 1; fi

  proj_arg="${PUMP_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if ! is_folder_pkg_ "$proj_folder"; then return 1; fi
  
  prune "$proj_folder" &>/dev/null

  # print " ${yellow_cor}tagging project:${reset_cor} $proj_arg"
  # print " ${yellow_cor}tagging folder:${reset_cor} $proj_folder"
  # print " ${yellow_cor}tagging name:${reset_cor} $tag"

  if [[ -z "$tag" ]]; then
    tag=$(get_from_pkg_json_ "version" "$proj_folder")
    if [[ -n "$tag" ]]; then
      if (( ! tag_is_s )); then
        confirm_ "create tag: $tag ?"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 1 )); then
          tag=""
        fi
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    if (( ! tag_is_s )); then
      tag=$(input_text_ "tag name")
      if [[ -z "$tag" ]]; then return 1; fi

      print " ${purple_cor}tag name:${reset_cor} $tag"
    else
      return 1;
    fi
  fi

  git -C "$proj_folder" tag --annotate "$tag" --message "$tag"
  
  if (( $? == 0 )); then
    git -C "$proj_folder" push --no-verify --tags $@
    return $?;
  fi

  return 1;
}

function tags() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( tags_is_debug )) && set -x

  if (( tags_is_h )); then
    print "  ${yellow_cor}tags ${low_yellow_cor}[<project>] [<n>]${reset_cor} : list tags of a project"
    print "  ${yellow_cor}tags ${low_yellow_cor}<n>${reset_cor} : list n number of tags of a project"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_SHORT_NAME"
  local n=100

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 == <-> ]]; then
      n="$2"
    fi
  elif [[ -n "$1" && $1 == <-> ]]; then
    n="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg" "project to list tags")
  if (( ! i )); then return 1; fi

  proj_arg="${PUMP_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  prune "$proj_folder" &>/dev/null

  local tags=""

  # if (( n == 1 )); then
  #   tags=$(git -C "$proj_folder" describe --tags --abbrev=0 2>/dev/null)
  # fi

  if [[ -z "$tags" ]]; then
    tags=$(git -C "$proj_folder" for-each-ref refs/tags --sort=-creatordate --format='%(creatordate:short)\t%(refname:short)' --count="$n")
  fi

  if [[ -z "$tags" ]]; then
    print " no tags found"
    return 0;
  fi
  
  print "$tags"
}
# end of tagging functions ===============================================

function print_clean_() {
  print "  ${yellow_cor}softer${reset_cor} : $(clean -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/  :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${orange_cor}soft${reset_cor}   : $(restore -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/:/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${dark_orange_cor}medium${reset_cor} : $(discard -hq | sed 's/\[\<folder\>\]//g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${hi_red_cor}hard${reset_cor}   : $(reseta -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/ :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
}

function restore() {
  set +x
  eval "$(parse_flags_ "$0" "a" "q" "$@")"
  (( restore_is_debug )) && set -x

  if (( restore_is_h )); then
    print "  ${yellow_cor}restore ${low_yellow_cor}[<folder>]${reset_cor} : clean staged files only"
    print "  ${yellow_cor}restore -a${low_yellow_cor}[<folder>]${reset_cor} : include untracked files in working tree"
    print "  ${yellow_cor}restore -q${reset_cor} : restore --quiet"
    if (( ! restore_is_q )); then
      print " --"
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
      print " run ${yellow_cor}restore -h${reset_cor} to see usage" >&2
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
    print "  ${yellow_cor}clean ${low_yellow_cor}[<folder>]${reset_cor} : clean untracked files"
    print "  ${yellow_cor}clean -q${reset_cor} : clean --quiet"
    if (( ! clean_is_q )); then
      print " --"
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
      print " run ${yellow_cor}clean -h${reset_cor} to see usage" >&2
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
    print "  ${yellow_cor}discard ${low_yellow_cor}[<folder>]${reset_cor} : discard tracked and untracked files"
    print "  ${yellow_cor}discard -q${reset_cor} : discard --quiet"
    if (( ! discard_is_q )); then
      print " --"
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
      print " run ${yellow_cor}discard -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" reset HEAD . $@
  clean "$folder" $@
  # restore "$folder"
}

function reseta() {
  set +x
  eval "$(parse_flags_ "$0" "o" "q" "$@")"
  (( reseta_is_debug )) && set -x

  if (( reseta_is_h )); then
    print "  ${yellow_cor}reseta ${low_yellow_cor}[<folder>]${reset_cor} : erase everything and match HEAD to latest commit of current branch"
    print "  ${yellow_cor}reseta -o${reset_cor} : erase everything and match HEAD to origin"
    print "  ${yellow_cor}reseta -q${reset_cor} : reset --quiet"
    if (( ! reseta_is_q )); then
      print " --"
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
      print " run ${yellow_cor}reseta -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  clean --quiet "$folder" &>/dev/null

  if (( reseta_is_o )); then
    local remote_name=$(get_remote_origin_ "$folder")
    local my_branch=$(git -C "$folder" branch --show-current)

    if [[ -z "$my_branch" ]]; then
      print " current branch is detached, cannot reset to origin" >&2
      return 1;
    fi
  
    git -C "$folder" fetch $remote_name --quiet
    git -C "$folder" reset --hard "${remote_name}/${my_branch}" $@
  else
    git -C "$folder" reset --hard $@
  fi
}

function glr() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( glr_is_debug )) && set -x

  if (( glr_is_h )); then
    print "  ${yellow_cor}glr ${low_yellow_cor}[<folder>]${reset_cor} : list remote branches"
    print "  ${yellow_cor}glr <branch> ${low_yellow_cor}[<folder>]${reset_cor} : list remote branches matching branch"
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
  local repo_name=$(get_repo_name_ "$repo" 2>/dev/null)
  local link="https://github.com/$repo_name/tree/"

  gum spin --title="loading..." -- git -C "$folder" branch -r --list "*$branch_arg*" --sort=authordate \
    --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' \
    | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e "s/\([^\ ]*\)$/\x1b[34m\x1b]8;;${link//\//\\/}\1\x1b\\\\\1\x1b]8;;\x1b\\\\\x1b[0m/"
}

function gll() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( gll_is_debug )) && set -x

  if (( gll_is_h )); then
    print "  ${yellow_cor}gll ${low_yellow_cor}[<folder>]${reset_cor} : list local branches"
    print "  ${yellow_cor}gll <branch> ${low_yellow_cor}[<folder>]${reset_cor} : list local branches matching <branch>"
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
    print -n "\a ${red_cor}✗ workflow failed: ${workflow} (status: ${workflow_status})${reset_cor}"
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
    eval "$proj_cmd -h | grep --color=never -E '\bgha\b'"
    return 0;
  fi

  local i=$(get_proj_index_ "$proj_cmd")

  if ! check_proj_ -r $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"
  local gha_interval="${PUMP_GHA_INTERVAL[$i]}"

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
      print " no workflows found for $proj_cmd" >&2
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

  if [[ -z "$gha_interval" || "$gha_interval" != <-> ]]; then
    gha_interval=9
  fi

  while true; do
    workflow_run_ "$workflow_arg" "$proj_repo"
    RET=$?

    if (( RET != 0 || proj_gha_is_a == 0 )); then
      break;
    fi
    
    local minutes_left=$gha_interval
    print ""
    while (( minutes_left > 0 )); do
      if (( minutes_left % 2 != 0 )); then
        print " sleeping for $minutes_left minutes..."
      fi
      sleep 60
      (( minutes_left-- ))
    done
  done

  return $RET;
}

function co() {
  set +x
  eval "$(parse_flags_ "$0" "alprebcmx" "q" "$@")"
  (( co_is_debug )) && set -x

  if (( co_is_h )); then
    print "  ${yellow_cor}co${reset_cor} : switch to a branch"
    print "  ${yellow_cor}co <branch> <base_branch>${reset_cor} : create a new branch off of base branch"
    print "  --"
    print "  ${yellow_cor}co -a${reset_cor} : list all branches (default)"
    print "  ${yellow_cor}co -l${reset_cor} : list only local branches"
    print "  ${yellow_cor}co -pr${reset_cor} : list pull requests and detach branch (for quick code reviews)"
    print "  --"
    print "  ${yellow_cor}co -m ${low_yellow_cor}[<folder>]${reset_cor} : switch to the default branch"
    print "  ${yellow_cor}co -e <branch>${reset_cor} : switch to an exact branch, no lookup"
    print "  ${yellow_cor}co -c <branch>${reset_cor} : create a new branch (switch -c)"
    print "  ${yellow_cor}co -b <branch>${reset_cor} : create a new branch (checkout -b)"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_SHORT_NAME"
  local proj_folder="$PWD"

  if ! is_folder_git_ "$proj_folder"; then; return 1; fi

  local RET=0

  # co -pr switch by pull request
  if (( co_is_p && co_is_r )); then
    local proj_repo=$(get_repo_ "$proj_folder")
    if [[ -z "$proj_repo" ]]; then return 1; fi

    local pr=("${(@s:|:)$(select_pr_ "$1" "$proj_repo")}")
    if [[ -z "$pr" ]]; then return 1; fi
    
    if command -v gum &>/dev/null; then
      gum spin --title="detaching pull request: ${green_cor}${pr[3]}${reset_cor}" -- \
        gh pr checkout --force --detach "${pr[1]}"
      RET=$?
      if (( RET == 0 )); then
        print "   detaching pull request: ${green_cor}${pr[3]}${reset_cor}"
      fi
    else
      print "   detaching pull request: ${green_cor}${pr[3]}${reset_cor}"
      gh pr checkout --force --detach "${pr[1]}" &>/dev/null
      RET=$?
    fi

    if (( RET == 0 )); then
      print ""
      print " HEAD is now at $(git log -1 --pretty=format:'%h %s')"
      print ""
      print " your branch is detached, run:"
      print "  • ${yellow_cor}co -e ${pr[2]}${reset_cor} (alias for \"git switch\")"
      print "  • ${yellow_cor}co -c ${${USER:0:1}:l}-${pr[2]}${reset_cor} (alias for \"git switch -c\")"
    fi

    return $RET;
  fi

  if (( co_is_p || co_is_r )); then
    print " ${red_cor}fatal: invalid option${reset_cor}" >&2
    print " run ${yellow_cor}co -h${reset_cor} to see usage" >&2

    return 1;
  fi

  # co -a all branches
  if (( co_is_a )); then
    local branch_arg=""
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    local current_branch=$(git branch --show-current)
    local branch_choice=""

    if [[ "$current_branch" != "$branch_arg" ]]; then
      if [[ -n "$branch_arg" ]]; then
        branch_choice=$(select_branch_ -at "$branch_arg" "branch to switch" "$proj_folder" "$current_branch")
      else
        branch_choice=$(select_branch_ -a "$branch_arg" "branch to switch" "$proj_folder")
      fi
      if (( $? == 130 || $? == 2 )); then return 1; fi
      if [[ -z "$branch_choice" ]]; then return 1; fi
    else
      branch_choice="$current_branch"
    fi

    if [[ -n "$branch_arg" ]]; then
      co -e "$branch_choice" ${@:2}
    else
      co -e "$branch_choice" $@
    fi

    return $?;
  fi

  # co -l local branches
  if (( co_is_l )); then
    local branch_arg=""
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    local current_branch=$(git branch --show-current)
    local branch_choice=""

    if [[ "$current_branch" != "$branch_arg" ]]; then
      branch_choice=$(select_branch_ -l "$branch_arg" "branch to switch" "$proj_folder" "$current_branch" 2>/dev/null)
      if (( $? == 130 || $? == 2 )); then return 1; fi
      # if branch_choice is empty, let it be, we will call co -a
    else
      branch_choice="$current_branch"
    fi
    
    if [[ -z "$branch_choice" ]]; then
      co -a $@

      return $?;
    fi

    if [[ -n "$branch_arg" ]]; then
      co -e "$branch_choice" ${@:2}
    else
      co -e "$branch_choice" $@
    fi

    return $?;
  fi

  # co -m switch to default branch
  if (( co_is_m )); then
    local folder="$PWD"

    if [[ -n "$1" && $1 != -* ]]; then
      if [[ ! -d "$1" ]]; then
        print " fatal: not a valid folder argument: $1" >&2
        print " run ${yellow_cor}co -h${reset_cor} to see usage" >&2
        return 1;
      fi
      folder="$1"
      shift
    fi

    local default_branch=$(get_default_branch_)
    if [[ -z "$default_branch" ]]; then
      print " fatal: cannot determine default branch" >&2
      return 1;
    fi

    git -C "$folder" switch "$default_branch" $@
    
    return $?;
  fi

  # co -e branch just switch, do not create branch
  if (( co_is_e )); then
    local branch_arg=""

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      return 1;
    fi

    git switch "$branch_arg" ${@:2}
    
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
    fi

    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      return 1;
    fi

    if [[ -z "$base_branch" ]]; then
      base_branch=$(git branch --show-current)
    fi

    if [[ -n "$base_branch" ]]; then
      if [[ -n "$2" && $2 != -* ]]; then
        co -x "$branch_arg" "$base_branch" ${@:3}
      else
        co -x "$branch_arg" "$base_branch" ${@:2}
      fi
      return $?;
    fi

    if (( co_is_c )); then
      git switch -c "$branch_arg" ${@:2}
    else
      git checkout -b "$branch_arg" ${@:2}
    fi

    return $?;
  fi

  # co $1 or co (no arguments)
  if [[ -z "$2" || "$2" == -* ]]; then
    co -a $@

    return $?;
  fi

  # co -x or co branch BASE_BRANCH (creating branch)
  local branch_arg=""

  if [[ -n "$1" && $1 != -* ]]; then
    branch_arg="$1"
  fi

  if [[ -z "$branch_arg" ]]; then
    print " fatal: branch argument is required" >&2
    return 1;
  fi

  local base_branch_arg=""
  if [[ -n "$2" && $2 != -* ]]; then
    base_branch_arg="$2"
  fi

  local base_branch=""

  if (( co_is_x )); then
    base_branch=$(select_branch_ -aix "$base_branch_arg" "base branch" "$proj_folder")
  else
    base_branch=$(select_branch_ -at "$base_branch_arg" "base branch" "$proj_folder")
  fi
  RET=$?

  if (( RET != 0 )); then return 1; fi
  if [[ -z "$base_branch" ]]; then
    if (( co_is_x )); then
      print " fatal: could not find branch: $base_branch_arg" >&2
    fi
    return 1;
  fi

  if git switch -c "$branch_arg" "$base_branch" ${@:3}; then
    git config "branch.${branch_arg}.gh-merge-base" "$base_branch"
  fi

  return $RET;
}

function back() {
  # switch to previous branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( back_is_debug )) && set -x

  if (( back_is_h )); then
    print "  ${yellow_cor}back ${low_yellow_cor}[<folder>]${reset_cor} : go back the previous branch"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}back -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" switch - $@
}

function dev() {
  # switch to dev or develop branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( dev_is_debug )) && set -x

  if (( dev_is_h )); then
    print "  ${yellow_cor}dev${reset_cor} : switch to a dev branch in current project"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{dev,devel,develop,development}; do
    if git show-ref -q --verify $ref; then
      git switch ${ref:t}
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function main() {
  # switch to main branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( main_is_debug )) && set -x

  if (( main_is_h )); then
    print "  ${yellow_cor}main${reset_cor} : switch to main branch in current project"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if git show-ref -q --verify $ref; then
      git switch ${ref:t}
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function prod() {
  # switch to prod branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( prod_is_debug )) && set -x

  if (( prod_is_h )); then
      print "  ${yellow_cor}prod${reset_cor} : switch to prod or production branch in current project"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{prod,production}; do
    if git show-ref -q --verify $ref; then
      git switch ${ref:t}
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function stage() {
  # switch stage branch
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( stage_is_debug )) && set -x

  if (( stage_is_h )); then
      print "  ${yellow_cor}stage${reset_cor} : switch to stage or staging branch in current project"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{stage,staging}; do
    if git show-ref -q --verify $ref; then
      git switch ${ref:t}
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function rebase() {
  set +x
  eval "$(parse_flags_ "$0" "apq" "mpqi" "$@")"
  (( rebase_is_debug )) && set -x

  if (( rebase_is_h )); then
    print "  ${yellow_cor}rebase${reset_cor} : apply the commits from your branch on top of the HEAD of default branch"
    print "  ${yellow_cor}rebase ${low_yellow_cor}[<base_branch>] [<folder>]${reset_cor} : apply the commits on top of the HEAD of base branch"
    print "  ${yellow_cor}rebase -a${reset_cor} : rebase multiple branches"
    print "  ${yellow_cor}rebase -m${reset_cor} : rebase --merge"
    print "  ${yellow_cor}rebase -i${reset_cor} : rebase --interactive"
    print "  ${yellow_cor}rebase -p${reset_cor} : push after rebase if succeeds with no conflicts"
    return 0;
  fi

  local folder="$PWD"
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      (( arg_count++ ))
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local base_branch=""
  local branch_arg=""

  if [[ -n "$3" && $3 != -* ]]; then
    base_branch="$1"
    branch_arg="$3"
    (( arg_count+=2 ))
  elif [[ -n "$1" && $1 != -* ]]; then
    base_branch="$1"
    (( arg_count++ ))
  else
    base_branch=$(git -C "$folder" config --get init.defaultBranch)
  fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " current branch is detached, cannot rebase" >&2
      return 1;
    fi
  else
    if git -C "$folder" switch "$branch_arg" --quiet; then return 1; fi
  fi

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    return 1;
  fi

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  local RET=0

  if (( rebase_is_a )); then
    local selected_branches=($(select_branches_ -lts "" "$folder" "$base_branch"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if ! rebase "$base_branch" "$folder" "$branch" $@; then
        RET=1
        break;
      fi
    done

    return $RET;
  fi

  if [[ "$branch_arg" == "$base_branch" ]]; then
    print " fatal: cannot rebase, base branch is the same as branch argument: $branch_arg" >&2
    return 1;
  fi

  fetch --quiet "$folder"

  print -n " rebasing branch ${green_cor}${branch_arg}${reset_cor} on top of ${hi_green_cor}${base_branch}${reset_cor}"
  if (( merge_is_p )); then
    print -n " then pushing"
  fi
  print ""

  git -C "$folder" rebase "${remote_name}/${base_branch}" $@
  RET=$?

  if (( RET == 0 && rebase_is_p )); then
    pushf "$branch_arg" "$folder"
    RET=$?
  fi

  return $RET;
}

function merge() {
  set +x
  eval "$(parse_flags_ "$0" "apq" "spq" "$@")"
  (( merge_is_debug )) && set -x

  if (( merge_is_h )); then
    print "  ${yellow_cor}merge${reset_cor} : create a new merge commit from default branch"
    print "  ${yellow_cor}merge ${low_yellow_cor}[<base_branch>] [<folder>]${reset_cor} : create a new merge commit from base branch"
    print "  ${yellow_cor}merge -a${reset_cor} : merge multiple branches"
    print "  ${yellow_cor}merge -s <strategy>${reset_cor} : merge --strategy"
    print "  ${yellow_cor}merge -p${reset_cor} : push after merge succeeds with no conflicts"
    return 0;
  fi

  local folder="$PWD"
  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      (( arg_count++ ))
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local base_branch=""
  local branch_arg=""

  if [[ -n "$3" && $3 != -* ]]; then
    base_branch="$1"
    branch_arg="$3"
    (( arg_count+=2 ))
  elif [[ -n "$1" && $1 != -* ]]; then
    base_branch="$1"
    (( arg_count++ ))
  else
    base_branch=$(git -C "$folder" config --get init.defaultBranch)
  fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " current branch is detached, cannot merge" >&2
      return 1;
    fi
  else
    if git -C "$folder" switch "$branch_arg" --quiet; then return 1; fi
  fi

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    return 1;
  fi

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  local RET=0

  if (( merge_is_a )); then
    local selected_branches=($(select_branches_ -lts "" "$folder" "$base_branch"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if ! merge "$base_branch" "$folder" "$branch" $@; then
        RET=1
        break;
      fi
    done

    return $RET;
  fi

  if [[ "$branch_arg" == "$base_branch" ]]; then
    print " fatal: cannot merge, base branch is the same as branch argument: $branch_arg" >&2
    return 1;
  fi

  fetch --quiet "$folder"

  print -n " merging branch ${green_cor}${branch_arg}${reset_cor} from ${hi_green_cor}${base_branch}${reset_cor}"
  if (( merge_is_p )); then
    print -n " then pushing"
  fi
  print ""

  git -C "$folder" merge "${remote_name}/${base_branch}" --no-edit $@
  RET=$?

  if (( RET == 0 && merge_is_p )); then
    push "$branch_arg" "$folder"
    RET=$?
  fi

  return $RET;
}

function prune() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( prune_is_debug )) && set -x

  if (( prune_is_h )); then
    print "  ${yellow_cor}prune ${low_yellow_cor}[<folder>]${reset_cor} : clean up unreachable or orphaned git branches and tags"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}prune -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  # delete all local tags
  # git tag -l | xargs git tag -d 1>/dev/null

  # get all local tags
  local local_tags=("${(@f)$(git -C "$folder" tag)}")

  # get all remote tags (strip refs/tags/)
  local remote_tags=("${(@f)$(git -C "$folder" ls-remote --tags origin)}")
  local remote_tag_names=()
  
  local rtag=""
  for rtag in "${remote_tags[@]}"; do
    [[ $rtag =~ refs/tags/(.+)$ ]] && remote_tag_names+=("${match[1]}")
  done

  local tag=""
  for tag in "${local_tags[@]}"; do
    if ! [[ " ${remote_tag_names[*]} " == *" $tag "* ]]; then
      git -C "$folder" tag -d "$tag"
    fi
  done

  # fetch tags that exist in the remote
  fetch -t --quiet "$folder"
  
  local default_main_branch=$(git -C "$folder" config --get init.defaultBranch)
  if [[ -z "$default_main_branch" ]]; then
    default_main_branch="main"
  fi

  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches="$(git -C "$folder" branch --merged | grep -v "^\*\\|${default_main_branch}" | sed 's/^[ *]*//')"
  if [[ -n "$branches" ]]; then
    for branch in "$branches"; do
      git -C "$folder" branch -D "$branch"
      git -C "$folder" config --remove-section "branch.${branch}" &>/dev/null
    done
  fi

  local current_branches=$(git -C "$folder" branch --format '%(refname:short)')
  if [[ -n "$current_branches" ]]; then
    # loop through all Git config sections to find old branches
    for config in $(git -C "$folder" config --get-regexp "^branch\." | awk '{print $1}'); do
      local branch_name="${config#branch.}"

      # check if the branch exists locally
      if ! echo "$current_branches" | grep -q "^$branch_name\$"; then
        git -C "$folder" config --remove-section "branch."$branch_name"" &>/dev/null
      fi
    done
  fi

  git -C "$folder" prune $@
}

function delb() {
  set +x
  eval "$(parse_flags_ "$0" "sera" "" "$@")"
  (( delb_is_debug )) && set -x

  if (( delb_is_h )); then
    print "  ${yellow_cor}delb ${low_yellow_cor}[<branch>] [<folder>]${reset_cor} : delete a branch locally"
    print "  ${yellow_cor}delb -e <branch>${reset_cor} : delete only if matches exact name"
    print "  ${yellow_cor}delb -r${reset_cor} : also delete remotely (excludes main branches)"
    print "  ${yellow_cor}delb -a${reset_cor} : include all branches (use with -r)"
    print "  ${yellow_cor}delb -s${reset_cor} : skip confirmation (cannot use with -r)"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""
  local proj_arg=""
  
  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run ${yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
  fi

  if (( delb_is_e )) && [[ -z "$branch_arg" ]]; then
    print " fatal: branch argument is required with -e option" >&2
    print " run ${yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( delb_is_s && delb_is_r )); then
    print " ${red_cor}fatal: cannot use -s and -r together${reset_cor}" >&2
    print " run ${yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( delb_is_r )); then
    if (( delb_is_e )); then
      if (( delb_is_a )); then
        selected_branches=($(select_branches_ -re "$branch_arg" "$folder"))
      else
        selected_branches=($(select_branches_ -res "$branch_arg" "$folder"))
      fi
    else
      if (( delb_is_a )); then
        selected_branches=($(select_branches_ -r "$branch_arg" "$folder"))
      else
        selected_branches=($(select_branches_ -rs "$branch_arg" "$folder"))
      fi
    fi
  else
    if (( delb_is_e )); then
      selected_branches=($(select_branches_ -le "$branch_arg" "$folder"))
    else
      selected_branches=($(select_branches_ -l "$branch_arg" "$folder"))
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
    if (( dont_ask == 0 && count > 3 )); then
      dont_ask=1;
      confirm_ "delete all: ${blue_cor}${(j:, :)selected_branches[$count,-1]}${reset_cor}?"
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
      local origin=$( (( delb_is_r )) && echo "remote" || echo "local" )
      confirm_ "delete ${origin} branch: ${magenta_cor}${branch}${reset_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi
    # git already does that
    # git config --remove-section "branch.${branch}" &>/dev/null

    if (( delb_is_r )); then
      local remote_name=$(get_remote_origin_ "$folder")

      branch="${branch#$remote_name/}"

      git -C "$folder" branch -D "$branch" &>/dev/null
      git -C "$folder" push --delete "$remote_name" "$branch"
    else
      git -C "$folder" branch -D "$branch"
    fi
    RET=$?
  done

  return $RET;
}

function st() {
  set +x
  eval "$(parse_flags_ "$0" "sb" "sb" "$@")"
  (( st_is_debug )) && set -x

  if (( st_is_h )); then
    print "  ${yellow_cor}st ${low_yellow_cor}[<folder>]${reset_cor} : show git status"
    print "  ${yellow_cor}st -sb${reset_cor} : show git status in short-format"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run ${yellow_cor}st -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  # -sb is equivalent to git status -sb
  git -C "$folder" status $@
}
  
function get_pkg_name_() {
  local proj_folder="$1"
  local proj_repo="$2"

  if [[ -z "$proj_repo" ]]; then
    local git_proj_folder=""

    if [[ -n "$proj_folder" ]]; then
      git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
    else
      git_proj_folder="$PWD"
    fi

    if [[ -n "$git_proj_folder" ]] && is_folder_git_ "$git_proj_folder" &>/dev/null; then
      proj_repo=$(get_repo_ "$git_proj_folder" 2>/dev/null)
    fi
  fi

  if [[ -z "$proj_folder" ]]; then
    proj_folder="$PWD"
  fi

  local folder=$(get_proj_for_pkg_ "$proj_folder")
  if [[ -n "$folder" ]]; then
    local pkg_name=$(get_from_pkg_json_ "name" "$folder")
  
    if [[ -z "$pkg_name" && -n "$proj_repo" ]]; then
      pkg_name=$(get_pkg_field_online_ "name" "$proj_repo")
    fi
  fi
  
  if [[ -z "$pkg_name" ]]; then
    pkg_name="$(basename -- "$proj_folder")"
  fi

  pkg_name="${pkg_name//[[:space:]]/}"

  echo "$pkg_name"
}

function detect_node_version_() {
  set +x
  eval "$(parse_flags_ "$0" "a" "" "$@")"
  (( detect_node_version_debug )) && set -x

  local proj_folder="${1:-$PWD}"
  local node_v_arg="$2"

  if ! command -v nvm &>/dev/null; then return 1; fi
  if ! command -v node &>/dev/null; then return 1; fi

  local nvm_use_v=""

  # check for .nvmrc file
  if [[ -f "$proj_folder/.nvmrc" ]]; then
    if command -v gum &>/dev/null; then
      setopt NO_NOTIFY
      {
        gum spin --title="detecting node version..." -- bash -c 'sleep 2'
      } 2>/dev/tty
    fi

    local nvm_version=$(cat "$proj_folder/.nvmrc" 2>/dev/null)
    nvm_use_v=$(nvm version $nvm_version 2>/dev/null)
    if [[ -z "$nvm_use_v" || "$nvm_use_v" == "N/A" ]]; then
      print " ${yellow_cor}warning: nvm version $nvm_version not found${reset_cor}" >&2
      nvm_use_v="$nvm_version"
    fi
    echo "$nvm_use_v"
    return 0;
  fi

  # gum spin --title="detecting node version..." -- sleep 2 2>/dev/tty &!
  if command -v gum &>/dev/null; then
    setopt NO_NOTIFY
    {
      gum spin --title="detecting node version..." -- bash -c 'sleep 3'
    } 2>/dev/tty
  fi

  local node_engine=$(get_node_engine_ "$proj_folder")

  if [[ -n "$node_engine" ]]; then
    local versions=($(get_node_versions_ "$proj_folder" "$node_engine"))

    if [[ -z "$versions" ]]; then
      print " ${yellow_cor}warning: no matching node version found in nvm for engine: ${node_engine}${reset_cor}" >&2
      print " install node: ${yellow_cor}nvm install <version>${reset_cor}" >&2
    else
      if [[ -n "$node_v_arg" && " ${versions[*]} " == *" $node_v_arg "* ]]; then
        nvm_use_v="$node_v_arg"
      elif (( detect_node_version_is_a )); then
        nvm_use_v="${versions[1]}"
      else
        nvm_use_v=$(choose_one_ -a "node version to use with engine $node_engine" "${versions[@]}")
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
    print "  ${yellow_cor}pro [<name>]${reset_cor} : set a project"
    print "  ${yellow_cor}pro -l${reset_cor} : list all projects"
    print "  ${yellow_cor}pro -a ${low_yellow_cor}[<name>]${reset_cor} : add a new project"
    print "  ${yellow_cor}pro -e [<name>]${reset_cor} : edit a project"
    print "  ${yellow_cor}pro -r [<name>]${reset_cor} : remove a project"
    print "  --"
    print "  ${yellow_cor}pro -i ${low_yellow_cor}[<name>]${reset_cor} : display project config settings"
    print "  ${yellow_cor}pro -n ${low_yellow_cor}[<name>]${reset_cor} : set the project node version using nvm"
    print "  ${yellow_cor}pro -u ${low_yellow_cor}[<name>] [<setting>]${reset_cor} : reset project config settings"
    return 0;
  fi

  if (( pro_is_l )); then
    # pro -l list projects
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

    check_proj_ -fmq $i

    local pro_i_cor="${blue_cor}"

    print " ${pro_i_cor}project name:${reset_cor} ${PUMP_SHORT_NAME[$i]}"
    print " ${pro_i_cor}project repository:${reset_cor} ${PUMP_REPO[$i]}"
    print " ${pro_i_cor}project folder:${reset_cor} ${PUMP_FOLDER[$i]}"
    print " ${pro_i_cor}project mode:${reset_cor} $( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "single" || echo "multiple" )"
    print " ${pro_i_cor}package manager:${reset_cor} ${PUMP_PKG_MANAGER[$i]}"
    print " ${pro_i_cor}node.js version:${reset_cor} ${PUMP_NVM_USE_V[$i]}"
    return $?;
  fi

  # pro -u [<name>] reset project settings
  if (( pro_is_u )); then
    local i=$(find_proj_index_ -oe "$proj_arg"  "project to reset settings for")
    (( i )) || return 1;
    
    proj_arg="${PUMP_SHORT_NAME[$i]}"

    local setting_arg="$2"

    local settings=(
      "PUMP_CODE_EDITOR"
      "PUMP_COMMIT_ADD"
      "PUMP_DEFAULT_BRANCH"
      "PUMP_NO_MONOGRAM"
      "PUMP_NVM_SKIP_LOOKUP"
      "PUMP_NVM_USE_V"
      "PUMP_PR_APPEND"
      "PUMP_PR_REPLACE"
      "PUMP_PR_RUN_TEST"
      "PUMP_PRINT_README"
      "PUMP_REFIX_AMEND"
      "PUMP_REFIX_PUSH"
    )

    if [[ -n "$setting_arg" && " ${settings[*]} " != *" $setting_arg "* ]]; then
      print " invalid setting argument" >&2
      return 1;
    fi

    if [[ -n "$setting_arg" ]]; then
      update_config_ $i "$setting_arg" "" 0 2>/dev/null
      return $?;
    fi

    local selected_settings=($(choose_multiple_ "settings to reset" "${settings[@]}"))
    if [[ -z "$selected_settings" ]]; then return 1; fi

    local setting=""
    for setting in "${selected_settings[@]}"; do
      pro -u "$proj_arg" "$setting"
    done
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
          if confirm_ "project already exists: ${blue_cor}${proj_cmd}${reset_cor} - do you want to edit it?" "edit" "no"; then
            save_proj_ -e $foundI "$proj_cmd"
          fi
          return $?;
        else
          save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name"
        fi
        return $?;
      fi
    done

    print " no more slots available, remove a project to add a new one"
    print " run ${yellow_cor}pro -h${reset_cor} to see usage"
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

    if ! remove_proj_ -r $i; then
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
    local i=$(find_proj_index_ -oe "$proj_arg"  "project to set node version for")
    (( i )) || return 1;

    local node_v_arg="$2"

    if ! check_proj_ -fm $i; then return 1; fi

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
      local proj_folder=$(get_proj_for_pkg_ "${PUMP_FOLDER[$i]}")
      if [[ -z "$proj_folder" ]]; then return 1; fi

      nvm_use_v=$(detect_node_version_ "$proj_folder" "$node_v_arg")

      if [[ -n "$nvm_use_v" ]]; then
        if nvm use "$nvm_use_v"; then
          update_config_ $i "PUMP_NVM_USE_V" "$nvm_use_v" 0
          update_config_ $i "PUMP_NVM_SKIP_LOOKUP" 1

          if (( ! pro_is_x )); then
            print -n " node version set";
            if [[ -n "$old_nvm_use_v" ]]; then
              print -n " from: ${low_yellow_cor}${old_nvm_use_v}${reset_cor}"
            fi
            print " to: ${bold_green_cor}${nvm_use_v}${reset_cor}"
          fi
        fi
      else
        if [[ -z "$nvm_skip_lookup" ]]; then
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
        save_proj_f_ -e $foundI "$proj_cmd" "$pkg_name" 2>/dev/tty
      else
        if confirm_ "add new project: ${bold_pink_cor}${pkg_name}${reset_cor}?" "add" "no"; then
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
      print " run ${yellow_cor}pro -a <name>${reset_cor} to add a new project"
      return 0;
    fi
    
    proj_arg=$(choose_one_ "project to set" "${projects[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi

    pro "$proj_arg"
    return $?;
  fi

  # pro <name>
  local i=$(find_proj_index_ -o "$proj_arg"  "project to set")
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

  print -n " project set to: ${blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}" >/dev/tty
  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print -n " with ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" >/dev/tty
  fi
  print "" >/dev/tty

  pro -nx "$proj_arg"

  if [[ -n "$CURRENT_PUMP_PRO" ]]; then
    eval "$CURRENT_PUMP_PRO"
  fi

  # fetch the project folder if possible
  fetch --quiet 2>/dev/null
}

# project handler =========================================================
# pump()
function proj_handler() {
  local i="$1"
  shift

  set +x
  eval "$(parse_flags_exclusive_ "$0" "miue" "cprvdsmnbjae" "$@")"
  (( proj_handler_is_debug )) && set -x

  if ! check_proj_ -mq $i; then return 1; fi

  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  local sub_cmds=("bkp" "clone" "gha" "jira" "release" "rev" "revs")

  if [[ " ${sub_cmds[*]} " != *" $1 "* ]]; then
    if (( proj_handler_is_h )); then
      print "  ${yellow_cor}${proj_cmd}${reset_cor} : open project"
      (( ! single_mode )) && print "  ${yellow_cor}${proj_cmd} <folder>${reset_cor} : open project into a folder in ${proj_cmd}"
      (( single_mode )) && print "  ${yellow_cor}${proj_cmd} <branch>${reset_cor} : open project and switch to branch"
      (( ! single_mode )) && print "  ${yellow_cor}${proj_cmd} -m${reset_cor} : open the default folder"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} -e${reset_cor} : edit project"
      print "  ${yellow_cor}${proj_cmd} -i${reset_cor} : display project settings"
      print "  ${yellow_cor}${proj_cmd} -n${reset_cor} : set the node version using nvm"
      print "  ${yellow_cor}${proj_cmd} -r${reset_cor} : remove project"
      print "  ${yellow_cor}${proj_cmd} -u ${low_yellow_cor}[<setting>]${reset_cor} : reset settings"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} bkp${reset_cor} : create backup of the project"
      print "  ${yellow_cor}${proj_cmd} bkp -d ${low_yellow_cor}[<folder>]${reset_cor} : delete backup folders"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} clone${reset_cor} : clone project"
      (( ! single_mode )) && print "  ${yellow_cor}${proj_cmd} clone <branch> [<base_branch>]${reset_cor} : clone a branch"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} gha ${low_yellow_cor}[<workflow>]${reset_cor} : check status of a workflow"
      print "  ${yellow_cor}${proj_cmd} gha -a ${low_yellow_cor}[<workflow>]${reset_cor} : run in auto mode"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} jira ${low_yellow_cor}[<jira_key>]${reset_cor} : open a ticket"
      print "  ${yellow_cor}${proj_cmd} jira -c ${low_yellow_cor}[<jira_key>]${reset_cor} : close a ticket"
      print "  ${yellow_cor}${proj_cmd} jira -p ${low_yellow_cor}[<jira_key>]${reset_cor} : move a ticket to \"In Progress\" status"
      print "  ${yellow_cor}${proj_cmd} jira -r ${low_yellow_cor}[<jira_key>]${reset_cor} : move a ticket to \"In Review\" status"
      print "  ${yellow_cor}${proj_cmd} jira -s ${low_yellow_cor}[<jira_key>]${reset_cor} : move a ticket status"
      print "  ${yellow_cor}${proj_cmd} jira -v ${low_yellow_cor}[<jira_key>]${reset_cor} : view a ticket status"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} release ${low_yellow_cor}[<tag>]${reset_cor} : create a release tag"
      print "  ${yellow_cor}${proj_cmd} release -d ${low_yellow_cor}[<tag>]${reset_cor} : delete a release"
      print "  ${yellow_cor}${proj_cmd} release -s${reset_cor} : skip confirmation"
      print "  ${yellow_cor}${proj_cmd} release -m${reset_cor} : bump the major version by 1 and create a release"
      print "  ${yellow_cor}${proj_cmd} release -n${reset_cor} : bump the minor version by 1 and create a release"
      print "  ${yellow_cor}${proj_cmd} release -p${reset_cor} : bump the patch version by 1 and create a release"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} rev ${low_yellow_cor}[<branch_or_pr>]${reset_cor} : create a code review by branch or pull request"
      print "  ${yellow_cor}${proj_cmd} rev -a ${low_yellow_cor}[<branch_or_pr>]${reset_cor}${reset_cor} : approve a pull request"
      print "  ${yellow_cor}${proj_cmd} rev -b ${low_yellow_cor}[<branch>]${reset_cor} : create a code review by branch"
      print "  ${yellow_cor}${proj_cmd} rev -e <branch>${reset_cor} : create a code review by an exact branch"
      print "  ${yellow_cor}${proj_cmd} rev -j ${low_yellow_cor}[<jira_key>]${reset_cor} : create a code review by ticket"
      print "  --"
      print "  ${yellow_cor}${proj_cmd} revs${reset_cor} : open an existing code review"
      print "  ${yellow_cor}${proj_cmd} revs -d${reset_cor} : delete code reviews"
      print "  ${yellow_cor}${proj_cmd} revs -da${reset_cor} : delete all code reviews"
      
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
        print "  --" >&2
        eval "$proj_cmd -h"
        return 0;
      fi
      
      if ! check_proj_ -fq $i; then return 1; fi
      
      local proj_folder="${PUMP_FOLDER[$i]}"
      local folder=""

      mkdir -p -- "$proj_folder"

      if (( ! single_mode )); then
        folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)

        if [[ -n "$folder" ]]; then
          folder="$(basename "$folder")"
        fi
      fi

      proj_handler_open_ "$proj_cmd" "$proj_folder/$folder"
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
      if ! command -v git &>/dev/null; then
        print " fatal: $proj_cmd clone requires git" >&2
        print " install git: ${blue_cor}https://git-scm.com/downloads/${reset_cor}" >&2
        return 1;
      fi

      proj_clone_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "gha" ]]; then
      if ! command -v gh &>/dev/null; then
        print " fatal: $proj_cmd gha requires gh" >&2
        print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
        return 1;
      fi

      proj_gha_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "jira" ]]; then
      if ! command -v acli &>/dev/null; then
        print " fatal: $proj_cmd jira requires acli" >&2
        print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2
        return 1;
      fi

      proj_jira_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "revs" ]]; then
      if ! command -v gum &>/dev/null; then
        print " fatal: $proj_cmd revs requires gum" >&2
        print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
        return 1;
      fi

      proj_revs_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "rev" ]]; then
      if ! command -v gum &>/dev/null; then
        print " fatal: $proj_cmd rev requires gum" >&2
        print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
        return 1;
      fi

      proj_rev_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "release" ]]; then
      if ! command -v gh &>/dev/null; then
        print " fatal: $proj_cmd release requires gh" >&2
        print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
        return 1;
      fi

      proj_release_ "$proj_cmd" "${args[@]}"
      return $?;
    fi
  fi

  if ! check_proj_ -fq $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  mkdir -p -- "$proj_folder"

  local folder_to_open=""
  local branch=""

  if (( single_mode )); then
    branch="$1"

    folder_to_open="$proj_folder"
  else
    local folder=""

    local dirs=("${(@f)$(get_folders_ -p "$proj_folder" "$1")}")
    if [[ -n "$dirs" ]]; then
      folder=($(choose_one_ -a "folder" "${dirs[@]}"))
    else
      print " warning: not a valid folder argument: $1" >&2
    fi

    folder_to_open="${proj_folder}/${folder}"
  fi

  proj_handler_open_ "$proj_cmd" "$folder_to_open" "$branch"
}

function proj_handler_open_() {
  local proj_cmd="$1"
  local resolved_folder="$2"
  local branch="$3"
  
  if cd "$resolved_folder"; then
    if [[ -z "$(ls "$resolved_folder")" ]]; then
      print " project folder is empty" >&1
      print " run: ${yellow_cor}${proj_cmd} clone${reset_cor}" >&1
      return 0;
    fi
    
    if [[ -n "$branch" ]]; then
      co "$branch"
    fi
  fi
}

# commit functions ====================================================
typeset -g COMMIT1=""
typeset -g COMMIT2=""

if command -v c &>/dev/null; then
  if (( ${+functions[c]} && -n "${functions[c]}" )); then
    unset -f c
    COMMIT1="c"
    if ! command -v commit &>/dev/null; then
      COMMIT2="commit"
    fi
  else
    COMMIT1="commit"
  fi
else
  COMMIT1="c"
  if ! command -v commit &>/dev/null; then
    COMMIT2="commit"
  fi
fi

functions[$COMMIT1]="__commit \"\$@\";"
if [[ -n "$COMMIT2" ]]; then
  functions[$COMMIT2]="__commit \"\$@\";"
fi

function __commit() {
  set +x
  eval "$(parse_flags_ "$0" "am" "s" "$@")"
  (( commit_is_debug )) && set -x

  if (( commit_is_h )); then
    print "  ${yellow_cor}${COMMIT1}${reset_cor} : commit with https://www.conventionalcommits.org"
    print "  ${yellow_cor}${COMMIT1} <message>${reset_cor} : commit  --no-verify --message"
    print "  ${yellow_cor}${COMMIT1} -m <message>${reset_cor} : same as ${COMMIT1} <message>"
    print "  ${yellow_cor}${COMMIT1} -a${reset_cor} : commit all files"
    return 0;
  fi

  if ! is_folder_git_; then return 1; fi

  if (( commit_is_a || CURRENT_PUMP_COMMIT_ADD )); then
    if ! git add .; then return 1; fi
  elif [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
    confirm_ "commit all changes (git add .)?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      if ! git add .; then return 1; fi

      if confirm_ "save this preference and don't ask again?" "save" "ask again"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
            update_config_ $i "PUMP_COMMIT_ADD" 1
            break;
          fi
        done
      fi
    fi
  fi

  if [[ -z "$1" ]]; then
    if ! command -v gum &>/dev/null; then
      print " fatal: commit wizard requires gum" >&2
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

    local my_branch=$(git branch --show-current)
    if [[ -z "$my_branch" ]]; then
      print " fatal: branch is detached, cannot create commit" >&2
      return 1;
    fi

    local jira_key=$(extract_jira_key_ "$my_branch")
    
    if [[ -n "$jira_key" ]]; then
      local skip=0;

      local default_branch=$(get_default_branch_)
      
      git --no-pager log --no-merges "${default_branch}..${my_branch}" --pretty=format:"%s" | xargs -0 | while read -r line; do
        if [[ "$line" == "$jira_key"* ]]; then
          skip=1;
          break;
        fi
      done

      if (( skip == 0 )); then
        commit_msg="${ticket} ${commit_msg}"
      fi
    fi

    git commit --no-verify --message "$commit_msg" $@
  elif [[ $1 != -* ]]; then
    git commit --no-verify --message "$1" ${@:2}
  else
    git commit --no-verify $@
  fi  
}
# end of commit functions =============================================

function help() {
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
    print "  manager: ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
    print "  node v.: ${hi_green_cor}${node_version#v}${reset_cor}"
  else
    print "  project: ${red_cor}none${reset_cor}"
    print "  manager: ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
    print "  node v.: ${hi_green_cor}${node_version#v}${reset_cor}"
  fi
  print ""

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
  print "  use ${yellow_cor}-h${reset_cor} after any command to see more usage"
  print "  visit: ${blue_cor}https://github.com/fab1o/pump-zsh/wiki${reset_cor}"
}

function help_projects_() {
  local spaces="14s"

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
  
  display_line_ "general" "${low_yellow_cor}"
  print ""
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "cl" "clear terminal"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete utility"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "help" "display this help"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "hg <text>" "history | grep text"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "kill <port>" "kill port"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "ll" "list all files"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "nver" "node version"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "nlist" "npm list global"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "refresh" "source .zshrc"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "upgrade" "omz update + pump update"
}

function help_most_popular_() {
  local spaces="14s"
  local max=53 # the perfect number for the spaces

  local pkg_manager="${CURRENT_PUMP_PKG_MANAGER:-npm}"

  local _fix="${CURRENT_PUMP_FIX:-"$pkg_manager run fix (format + lint)"}"
  local _run="${CURRENT_PUMP_RUN:-"$pkg_manager run dev or $pkg_manager start"}"
  local _setup="${CURRENT_PUMP_SETUP:-"$pkg_manager run setup or $pkg_manager install"}"
  
  display_line_ "most popular" "${pink_cor}"
  print ""
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME" "manage project $CURRENT_PUMP_SHORT_NAME"
    if (( ! $CURRENT_PUMP_SINGLE_MODE )); then
      printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME clone" "clone project"
    fi
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME jira" "manage jira tickets"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME release" "manage releases"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME rev" "manage code reviews"
  else
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pro" "manage projects"
  fi
  print ""
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "cl" "clear terminal"
  printf "  ${low_yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete utility"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "git pull branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "git push branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort merge/rebase/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "cont" "abort merge/rebase/chp"
  print ""
  if (( ${#CURRENT_PUMP_COV} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "run CURRENT_PUMP_COV"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "$CURRENT_PUMP_COV"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "cov <b>" "compare coverage"
  if (( ${#_fix} > max )); then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "run PUMP_FIX"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "$_fix"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "refix" "fix + re-push"
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

  display_line_ "git branch" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "back" "switch back to previous branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "co" "switch and create branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "dev" "switch to dev or develop branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "main" "switch to main branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "prod" "switch to prod or production branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "renb <b>" "rename current branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "stage" "switch to stage or staging branch"

  if ! pause_output_; then return 0; fi
  
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
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseta" "erase everything, reset to last commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "restore" "clean tracked files only"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git commit" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "add" "add files to index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rem" "remove files from index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "$COMMIT1" "add + commit wizard"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "$COMMIT1 <m>" "add + commit message"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "recommit" "ammend last commit + add"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git config" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "gconf" "display git config"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "st" "display git status"

  if ! pause_output_; then return 0; fi

  display_line_ "git log" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "glog" "git log"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "gll" "list local branches"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "glr" "list remote branches"

  if ! pause_output_; then return 0; fi

  display_line_ "git merge" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort rebase/merge/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "chc" "continue cherry-pick"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "chp" "cherry-pick commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "cont" "continue rebase/merge/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "mc" "continue merge"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rc" "continue rebase"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git pr" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pra" "set assignee to all pull requests"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "git pull" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "fetch" "fetch from remote"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch from remote"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pullr" "pull --rebase"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git push" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request on github"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push branch to remote"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pushf" "force push branch to remote"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git tag" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "dtag" "delete tags"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "tag" "create a tag"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "tags" "display latest tags"
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
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "tsc" "$pkg_manager run tsc"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "watch" "$pkg_manager run watch"
  
  if ! pause_output_; then return 0; fi

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
  local proj_cmd="$1"
  local old_proj_cmd="$2"

  if ! validate_proj_cmd_ "$proj_cmd"; then
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
  local proj_cmd="$1"
  local qty=${2:-13}

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
  for i in {0..255}; do print -P "%F{$i}Color $i%f"; done
}

function get_folders_() {
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

  local filtered_folders=()
  local name=""

  if (( get_folders_is_p || get_folders_is_f )); then
    local priorities=(dev develop release main master production stage staging trunk mainline default stable)

    if (( get_folders_is_p )); then
      for name in "${priorities[@]}"; do
        if [[ " ${folders[@]} " == *" $name "* ]]; then
          filtered_folders+=("$name")
        fi
      done
    fi

    for name in "${folders[@]}"; do
      if [[ ! " ${priorities[@]} " == *" $name "* ]]; then
        filtered_folders+=("$name")
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
    print "  ${yellow_cor}cl${reset_cor} : clear terminal and reset debug mode"
    return 0;
  fi

  is_debug=0

  printf "\033c"
}

function kill() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( kill_is_h )); then
    print "  ${yellow_cor}kill <port>${reset_cor} : kill a port number"
    return 0;
  fi

  npx --yes kill-port $1
}

function refresh() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  #(( refresh_is_debug )) && set -x # do not turn on for refresh

  if (( refresh_is_h )); then
    print "  ${yellow_cor}refresh${reset_cor} : runs 'zsh'"
    return 0;
  fi

  zsh
}

function hg() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( hg_is_h )); then
    print "  ${yellow_cor}hg <test>${reset_cor} : history | grep text"
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
    print "  ${yellow_cor}nver${reset_cor} : display node version"
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
    print "  ${yellow_cor}nlist${reset_cor} : list global npm packages"
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
typeset -gA PUMP_PR_RUN_TEST
typeset -gA PUMP_GHA_INTERVAL
typeset -gA PUMP_COMMIT_ADD
typeset -gA PUMP_REFIX_PUSH
typeset -gA PUMP_REFIX_AMEND
typeset -gA PUMP_PRINT_README
typeset -gA PUMP_PKG_NAME
typeset -gA PUMP_JIRA_IN_PROGRESS
typeset -gA PUMP_JIRA_IN_REVIEW
typeset -gA PUMP_JIRA_IN_DONE
typeset -gA PUMP_NVM_SKIP_LOOKUP
typeset -gA PUMP_NVM_USE_V
typeset -gA PUMP_DEFAULT_BRANCH
typeset -gA PUMP_NO_MONOGRAM

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
typeset -g CURRENT_PUMP_PR_RUN_TEST=""
typeset -g CURRENT_PUMP_GHA_INTERVAL=""
typeset -g CURRENT_PUMP_COMMIT_ADD=""
typeset -g CURRENT_PUMP_REFIX_PUSH=""
typeset -g CURRENT_PUMP_REFIX_AMEND=""
typeset -g CURRENT_PUMP_PRINT_README=""
typeset -g CURRENT_PUMP_PKG_NAME=""
typeset -g CURRENT_PUMP_JIRA_IN_PROGRESS=""
typeset -g CURRENT_PUMP_JIRA_IN_REVIEW=""
typeset -g CURRENT_PUMP_JIRA_DONE=""
typeset -g CURRENT_PUMP_NVM_SKIP_LOOKUP=""
typeset -g CURRENT_PUMP_NVM_USE_V=""
typeset -g CURRENT_PUMP_DEFAULT_BRANCH=""
typeset -g CURRENT_PUMP_NO_MONOGRAM=""

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g SAVE_COR=""

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
    local pk_manager=$(detect_pkg_manager_ "$(pwd)")
    
    CURRENT_PUMP_PKG_MANAGER=${pk_manager:-npm}
    CURRENT_PUMP_COV="$CURRENT_PUMP_PKG_MANAGER run test:coverage"
    CURRENT_PUMP_TEST_WATCH="$CURRENT_PUMP_PKG_MANAGER run test:watch"
    CURRENT_PUMP_TEST="$CURRENT_PUMP_PKG_MANAGER test"
    CURRENT_PUMP_E2E="$CURRENT_PUMP_PKG_MANAGER run test:e2e"
    CURRENT_PUMP_E2EUI="$CURRENT_PUMP_PKG_MANAGER run test:e2e-ui"

    CURRENT_PUMP_SINGLE_MODE=1

    CURRENT_PUMP_NVM_USE_V=$(detect_node_version_ -a "$(pwd)")

    if [[ -n "$CURRENT_PUMP_NVM_USE_V" ]]; then
      nvm use $CURRENT_PUMP_NVM_USE_V
    fi

    # print " ${low_yellow_cor}tip: add this project to save detections, run: ${yellow_cor}pro -a${reset_cor}" 2>/dev/tty
  fi
}

# cd pro pwd
function pump_chpwd_() {
  set +x
  local proj_arg=$(find_proj_by_folder_ "$(pwd)")

  if [[ -n "$proj_arg" ]]; then
    pro "$proj_arg"
  else
    pump_chpwd_pwd_
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
