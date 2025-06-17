typeset -g is_debug=0 # (debug flag) when -d is on, it will be shared across all subsequent function calls
typeset -g MAX_NAME_COUNT=15

typeset -g dark_gray_cor="\e[38;5;240m"
typeset -g gray_cor="\e[38;5;248m"

typeset -g bright_green_cor="\e[1m\e[38;5;151m"
typeset -g solid_green_cor="\e[32m"
typeset -g green_cor="\e[92m"

# typeset -g bright_yellow_cor="\e[1m\e[38;5;220m"
typeset -g bright_yellow_cor="\e[1m\e[38;5;228m"
typeset -g solid_yellow_cor="\e[33m"
typeset -g yellow_cor="\e[93m"

typeset -g orange_cor="\e[38;5;208m"
typeset -g dark_orange_cor="\e[38;5;202m"

typeset -g bright_red_cor="\e[38;5;160m"
typeset -g solid_red_cor="\e[31m"
typeset -g red_cor="\e[91m"

typeset -g bright_magenta_cor="\e[38;5;201m"
typeset -g solid_magenta_cor="\e[35m"
typeset -g magenta_cor="\e[95m"

typeset -g bright_blue_cor="\e[1m\e[38;5;75m"
typeset -g solid_blue_cor="\e[34m"
typeset -g blue_cor="\e[94m"

typeset -g solid_cyan_cor="\e[36m"
typeset -g cyan_cor="\e[96m"

typeset -g solid_pink_cor="\e[0;95m"
typeset -g pink_cor="\e[38;5;212m"

typeset -g purple_cor="\e[38;5;99m"

typeset -g reset_cor="\e[0m"

typeset -g green_prompt_cor=$'\e[32m'
typeset -g blue_prompt_cor=$'\e[0;94m'
typeset -g magenta_prompt_cor=$'\e[0;95m'

typeset -g bright_pink_prompt_cor=$'\e[38;5;201m'
typeset -g pink_prompt_cor=$'\e[38;5;212m'

typeset -g purple_prompt_cor=$'\e[38;5;99m'
typeset -g bold_purple_prompt_cor=$'\e[1;38;5;99m'
typeset -g light_purple_prompt_cor=$'\e[38;2;167;139;250m'

typeset -g reset_prompt_cor=$'\e[0m'

typeset -g PUMP_VERSION="0.0.0"

typeset -g PUMP_VERSION_FILE="$(dirname "$0")/.version"
typeset -g PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"

[[ -f "$PUMP_VERSION_FILE" ]] && PUMP_VERSION=$(<"$PUMP_VERSION_FILE")

if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
  cp "$(dirname "$0")/config/pump.zshenv.default" "$PUMP_CONFIG_FILE" &>/dev/null
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    print " ${red_cor}fatal:${reset_cor} config file does not exist, re-install pump-zsh:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi
fi

# function parse_flags_clean_() {
#   if [[ -z "$1" ]]; then
#     print "${red_cor} fatal: requires a prefix${reset_cor}" >&2
#     return 1;
#   fi

#   local prefix="$1"
#   local valid_flags="d${2}h"

#   shift 2

#   local OPTIND=1 opt
  
#   for opt in {a..z}; do
#     echo "${prefix}is_$opt=0"
#   done

#   local invalid=0

#   while getopts ":abcdefghijklmnopqrstuvwxyz" opt; do
#     case "$opt" in
#       \?) break ;;
#       *)
#         if [[ $valid_flags != *$opt* ]]; then
#           invalid=1
#           print "${red_cor} ${prefix%_} invalid option: -$opt${reset_cor}" >&2
#           echo "${prefix}is_h=1"
#         fi
#         echo "${prefix}is_$opt=1"
#         ;;
#     esac
#   done

#   (( invalid )) && print " try:" >&2

#   if (( OPTIND > 1 )); then
#     shift $((OPTIND - 1))
#   fi
#   echo "set -- ${(q+)@}"
# }

function clear_last_line_1_() {
  print -n "\033[1A\033[2K" >&1
}

function clear_last_line_2_() {
  print -n "\033[1A\033[2K" >&2
}

function clear_last_line_tty_() {
  print -n "\033[1A\033[2K" 2>/dev/tty
}

function parse_flags_() {
  set +x

  if [[ -z "$1" ]]; then
    print "${red_cor} fatal: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags=""
  local valid_flags_pass_along="$3"

  if [[ -n "$2" ]]; then
    valid_flags="dh${2}${3}"
  fi

  shift 3

  local flags=()
  local non_flags=()
  local flags_double_dash=()

  local ch=""
  for ch in {a..z}; do
    echo "${prefix}is_$ch=0"
  done

  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"
      local i=0
      for (( i=0; i < ${#letters}; i++ )); do
        ch="${letters:$i:1}"
        
        echo "${prefix}is_$ch=1"

        if [[ -n "$valid_flags" ]]; then
          if [[ $valid_flags != *$ch* ]]; then
            if [[ "$ch" != "d" ]]; then flags+=("-$ch"); fi
            print " ${red_cor}fatal: invalid option: -$ch${reset_cor}" >&2
            echo "${prefix}is_h=1"
          elif [[ $valid_flags_pass_along == *$ch* ]]; then
            flags+=("-$ch")
          fi
        else
          if [[ "$ch" != "d" ]]; then flags+=("-$ch"); fi
        fi

        if [[ "$ch" == "d" || "$is_debug" -eq 1 ]]; then
          echo "is_debug=1"
          echo "${prefix}is_d=1"
        fi
      done
    elif [[ "$arg" == --* ]]; then
      flags_double_dash+=("$arg")
    else
      non_flags+=("$arg")
    fi
  done

  if [[ ${#non_flags} -gt 0 ]]; then
    echo "set -- ${(q+)non_flags[@]} ${(q+)flags[@]} ${(q+)flags_double_dash[@]}"
  else
    echo "set -- "" ${(q+)flags[@]} ${(q+)flags_double_dash[@]}"
  fi
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
    ##########################################################################
    # VERY IMPORTANT: 2>/dev/tty to display on VSCode Terminal and on refresh
    ##########################################################################
    if (( change_default )); then
      gum confirm "confirm:${reset_prompt_cor} $question" \
        --no-show-help \
        --default=false \
        --affirmative="$option1" \
        --negative="$option2" 2>/dev/tty
    else
      gum confirm "confirm:${reset_prompt_cor} $question" \
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
      *) clear_last_line_1_;;
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
  eval "$(parse_flags_ "update_" "f" "" "$@")"
  (( update_is_d )) && set -x

  local release_tag="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
  local latest_version=$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest_version" && "$PUMP_VERSION" != "$latest_version" ]]; then
    print " new version available for pump-zsh: ${magenta_cor}${PUMP_VERSION}${reset_cor} -> ${purple_cor}${latest_version}${reset_cor}"
    
    if (( ! update_is_f )); then
      if ! confirm_ "install new version?"; then
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
    print " pump version: ${purple_cor}$PUMP_VERSION${reset_cor}"
    zsh
    return 0;
  else
    if (( update_is_f )); then
      print " no update available for pump-zsh: ${purple_cor}${PUMP_VERSION}${reset_cor}"
    fi
  fi
}

update_

function cl() {
  set +x
  is_debug=0
  tput reset
}

function input_from_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-50}"
  local value="$4"

  local _input=""

  # >&2 needs to display because this is called from a subshell
  print " ${light_purple_prompt_cor}${header}:${reset_cor}" >&2

  if command -v gum &>/dev/null; then
    _input=$(gum input --placeholder="$placeholder" --char-limit="$max" --value="$value")
    if (( $? == 130 )); then return 130; fi
  else
    # do not return placeholder if not gum input
    # if [[ -n "$placeholder" ]]; then
    #   echo "$placeholder"
    #   return 0;
    # fi

    trap 'print ""; return 130' INT # for some reason it returns 2
    stty -echoctl
    read "?> " _input
    stty echoctl
    trap - INT
  fi
  
  # if [[ "$_input" == $'\e' ]]; then # doesn't work
  #   return 130;
  # fi

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
  eval "$(parse_flags_ "filter_one_" "a" "" "$@")"
  (( filter_one_is_d )) && set -x

  local header="$1"

  local RET=0

  if command -v gum &>/dev/null; then
    print "${bold_purple_prompt_cor} choose $header: ${reset_cor}" >&2
    
    local choice=""
    
    if (( filter_one_is_a )); then
      choice="$(gum filter --select-if-one --height="20" --limit=1 --indicator=">" --placeholder=" type to filter" -- ${@:2})"
    else
      choice="$(gum filter --height="20" --limit=1 --indicator=">" --placeholder=" type to filter" -- ${@:2})"
    fi
    RET=$?
    
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choice"
  else
    if (( filter_one_is_a )); then
      choose_one_ -a $@
    else
      choose_one_ $@
    fi
  fi
}

function choose_one_() {
  set +x
  eval "$(parse_flags_ "choose_one_" "a" "" "$@")"
  (( choose_one_is_d )) && set -x

  local header="$1"

  local RET=0

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_one_is_a )); then
      choice="$(gum choose --select-if-one --height="20" --limit=1 --header=" choose $header:${reset_prompt_cor}" -- ${@:2} 2>/dev/tty)"
    else
      choice="$(gum choose --height="20" --limit=1 --header=" choose $header:${reset_prompt_cor}" -- ${@:2} 2>/dev/tty)"
    fi
    
    RET=$?
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choice"
    return 0;
  fi
  
  trap 'print ""; return 130' INT # for some reason it returns 2

  PS3="${light_purple_prompt_cor}choose $header: ${reset_prompt_cor}"

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
  eval "$(parse_flags_ "choose_multiple_" "a" "" "$@")"
  (( choose_multiple_is_d )) && set -x

  local header="$1"

  local RET=0
  local choices

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_multiple_is_a )); then
      choices="$(gum choose --select-if-one --height="20" --no-limit --header=" choose multiple $header ${light_purple_prompt_cor}(use spacebar to select)${bold_purple_prompt_cor}:${reset_prompt_cor}" -- ${@:2})"
    else
      choices="$(gum choose --height="20" --no-limit --header=" choose multiple $header ${light_purple_prompt_cor}(use spacebar to select)${bold_purple_prompt_cor}:${reset_prompt_cor}" -- ${@:2})"
    fi
    RET=$?
    
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choices"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  choices=()
  PS3="${light_purple_prompt_cor}choose multiple $header, then choose \"done\" to finish ${choices[*]}${reset_prompt_cor}"

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

function get_folders_() {
  local folder="$1"

  [[ ! -d "$folder" ]] && return 1

  #dirs=("$folder"/*(/))
  #dirs=("$folder"/*(N/om))  # o = sort by name, O = sort by name descending
  #dirs=("$folder"/*(N/on))  # n = sort by time (newest last)
  local dirs=("$folder"/*(/N/On))
  local filtered=()

  local dir=""
  for dir in "${dirs[@]}"; do
    [[ "${dir##*/}" != "revs" ]] && filtered+=("${dir##*/}")
  done

  local priorities=(dev develop release main master production stage staging trunk mainline default stable)

  local name=""
  for name in "${priorities[@]}"; do
    if [[ " ${filtered[@]} " == *" $name "* ]]; then
      echo "$name"
    fi
  done

  for name in "${filtered[@]}"; do
    if [[ ! " ${priorities[@]} " == *" $name "* ]]; then
      echo "$name"
    fi
  done

  # if ordered was an array
  # printf '%s\n' "${ordered[@]}"
}

function check_config_file_() {
  local config_dir=$(dirname "$PUMP_CONFIG_FILE")
  local config_name=$(basename "$PUMP_CONFIG_FILE")

  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir"
  fi

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    touch "$PUMP_CONFIG_FILE"
    chmod 644 "$PUMP_CONFIG_FILE"
  fi
}

function update_setting_short_name_() {
  local i="$1"
  local key="$2"
  local value="$3"

  # set and unset proj_handler function
  if [[ "$key" == "PUMP_PROJ_SHORT_NAME" ]]; then
    if (( i > 0 )); then
      if [[ "$value" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        return 0; # no change
      fi

      if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        unset -f "${PUMP_PROJ_SHORT_NAME[$i]}" &>/dev/null
      fi
    else
      if [[ "$value" == "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
        return 0; # no change
      fi

      if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
        unset -f "$CURRENT_PUMP_PROJ_SHORT_NAME" &>/dev/null
      fi
    fi
    functions[$value]="proj_handler $i \"\$@\";"
  fi
}

function update_setting_() {
  check_config_file_

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    # print "  warn: config file $PUMP_CONFIG_FILE does not exist, cannot update setting" >&2
    return 0;
  fi

  local i="$1"
  local key="$2"
  local value="$3"

  if [[ "$key" == "PUMP_PROJ_SHORT_NAME" ]]; then
    update_setting_short_name_ "$i" "$key" "$value"
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
  if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" && "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
    if [[ -z "$value" ]]; then
      eval "CURRENT_${key}=\${${key}[0]}"
    else
      eval "CURRENT_${key}=\"$value\""
    fi
  fi

  eval "${key}[$i]=\"$value\""

  # set the config file
  local key_i="${key}_${i}"

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD sed) requires correct handling of patterns
    sed -i '' "s|^$key_i=.*|$key_i=$value|" "$PUMP_CONFIG_FILE"
  else
    # Linux (GNU sed)
    sed -i "s|^$key_i=.*|$key_i=$value|" "$PUMP_CONFIG_FILE"
  fi

  if (( $? != 0 )); then
    print "  ${yellow_cor}warning: failed to update ${key}_i in config${reset_cor}" >&2
    print "   • check if you have write permissions to the file: $PUMP_CONFIG_FILE" >&2
    print "   • re-install pump-zsh" >&2
  else
    print " updated setting: [${solid_magenta_cor}${key}_$i=${reset_cor}${gray_cor}${value}${reset_cor}]"
  fi

  return 0;
}

function input_branch_name_() {
  local header="$1"
  local placeholder="$2"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder")
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -n "$typed_value" ]] && git check-ref-format --branch "$typed_value" 1>/dev/null; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function input_name_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-$MAX_NAME_COUNT}"

  while true; do
    local typed_value=""
    typed_value=$(input_from_ "$header" "$placeholder" "$max")
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
  local i="$1"
  local header="$2"
  local folder_name="$3"
  local folder_exists="$4"

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
  print "${light_purple_prompt_cor} ${header}:${reset_cor}" >&2
  print "" >&2

  add-zsh-hook -d chpwd pump_chpwd_

  cd "${HOME:-/}" # start from home

  local RET=0

  local chosen_folder=""

  while true; do
    if [[ -n "$folder_path" ]]; then
      local new_folder=""

      if (( folder_exists )); then
        new_folder="$folder_path"
      else
        new_folder="${folder_path}/${folder_name}"
      fi

      local realfolder="${new_folder:A}"

      if [[ ! -d "$folder_path" ]]; then
        print "  ${red_cor}not a folder, please select a folder${reset_cor}" >&2
        cd "$HOME"
      else
        confirm_ "set project folder to: ${blue_prompt_cor}${realfolder}${reset_prompt_cor} or continue to browse further?" "set folder" "continue to browse"
        RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 1 )); then
          cd "$folder_path"
        else
          local found=0
          local j=0
          for j in {1..10}; do
            if [[ $j -ne $i && -n "$PUMP_PROJ_FOLDER[$j]" && -n "${PUMP_PROJ_SHORT_NAME[$j]}" ]]; then
              local realfolder_proj="${PUMP_PROJ_FOLDER[$j]:A}"

              if [[ "$realfolder" == "$realfolder_proj" ]]; then
                found=$j
                print "  ${yellow_cor}in use, please select another folder${reset_cor}" >&2
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
    
    local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
    if [[ -z "$dirs" ]]; then
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
    echo "$chosen_folder"
    return 0;
  fi

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
      gh_owner=$(input_from_ "type the Github owner account (username or organization) skip if not on Github")
      if (( $? == 130 || $? == 2 )); then return 130; fi

      if [[ -n "$gh_owner" ]]; then
        local list_repos=$(gh repo list $gh_owner --limit 100 --json nameWithOwner -q '.[].nameWithOwner' 2>/dev/null)
        local repos=("${(@f)list_repos}")
        
        if (( $? == 0 && ${#repos[@]} > 1 )); then
          local selected_repo=""
          selected_repo=$(choose_one_ "repository" "${repos[@]}")
          if (( $? != 0 )); then return 1; fi

          if [[ -n "$selected_repo" ]]; then
            local repo_uri=""
            
            confirm_ "ssh or https?" "ssh" "https"
            if (( $? == 130 || $? == 2 )); then return 130; fi
            if (( $? == 0 )); then
              repo_uri="git@github.com:${selected_repo}.git"
            else
              repo_uri="https://github.com/${selected_repo}.git"
            fi

            echo "$repo_uri"
            return 0;
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
  local total_width=${5:-72}

  local factor=2
  local total_width1=$total_width

  if [[ -z "$word1" ]]; then
    factor=0
  else
    total_width1=$(( total_width / 2 - factor ))
  fi

  local padding=$(( total_width1 - factor ))
  local line="$(printf '%*s' "$padding" '' | tr ' ' '─')"

  if [[ -n "$word1" ]]; then
    local word_length1=${#word1}

    local padding1=$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - factor : word_length1 - total_width1 - factor ) / 2 ))
    local line1="$(printf '%*s' "$padding1" '' | tr ' ' '─') $word1 $(printf '%*s' "$padding1" '' | tr ' ' '─')"

    if (( ${#line1} < total_width1 )); then
      local pad_len1=$(( total_width1 - ${#line1} ))
      padding1=$(printf '%*s' $pad_len1 '' | tr ' ' '-')
      line1="${line1}${padding1}"
    fi
    
    line="$line1"
  fi

  if [[ -n "$word2" ]]; then
    local word_length2=${#word2}
    local total_width2=$total_width1

    local padding2=$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))
    local line2="$(printf '%*s' "$padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$padding2" '' | tr ' ' '─')"

    if (( ${#line2} < total_width2 )); then
      local pad_len2=$(( total_width2 - ${#line2} ))
      padding2=$(printf '%*s' $pad_len2 '' | tr ' ' '-')
      line2="${line2}${padding2}"
    fi

    line="$line1 | ${color2}$line2"
  fi

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
  eval "$(parse_flags_ "check_proj_" "crfmpjq" "q" "$@")"
  (( check_proj_is_d )) && set -x
  
  local i="$1"

  if (( check_proj_is_c )); then
    if ! check_proj_cmd_ $i "${PUMP_PROJ_SHORT_NAME[$i]}" ${@:2}; then return 1; fi
  fi

  if (( check_proj_is_r )); then
    if ! check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SHORT_NAME[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PROJ_REPO[$i]}" ]]; then
      print " ${red_cor}missing repository uri for ${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run ${yellow_cor}${PUMP_PROJ_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_f )); then
    if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SHORT_NAME[$i]}" "${PUMP_PROJ_REPO[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PROJ_FOLDER[$i]}" || ! -d "${PUMP_PROJ_FOLDER[$i]}" ]]; then
      print " ${red_cor}missing project folder for ${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run ${yellow_cor}${PUMP_PROJ_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_m )); then
    if ! save_proj_mode_ -q $i "${PUMP_PROJ_SINGLE_MODE[$i]}" "${PUMP_PROJ_FOLDER[$i]}" ${@:2} 1>/dev/null; then return 1; fi
  fi

  if (( check_proj_is_p )); then
    if ! check_proj_pkg_manager_ -q $i "${PUMP_PKG_MANAGER[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}" ${@:2}; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PKG_MANAGER[$i]}" ]]; then
      print " ${red_cor}missing package manager for ${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_j )); then
    if ! save_jira_ -aq $i "${PUMP_JIRA_PROJ[$i]}" ${@:2} 1>/dev/null; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_JIRA_PROJ[$i]}" ]]; then
      print " ${red_cor}missing jira project for ${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&2
      return 1;
    fi
  fi
}

function check_proj_cmd_() {
  set +x
  eval "$(parse_flags_ "check_proj_cmd_" "sq" "" "$@")"
  (( check_proj_cmd_is_d )) && set -x

  local i="$1"
  local typed_proj_cmd="$2"
  local pkg_name="$3"
  local old_proj_cmd="$4"

  validate_proj_cmd_strict_ "$typed_proj_cmd" "$old_proj_cmd"
}

function check_proj_repo_() {
  set +x
  eval "$(parse_flags_ "check_proj_repo_" "aesq" "ae" "$@")"
  (( check_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_repo="$2"
  local proj_folder="$3"
  local pkg_name="$4"

  local error_msg=""

  if [[ -z "$proj_repo" ]]; then
    if [[ -n "$pkg_name" ]]; then
      error_msg="project repository is missing for $pkg_name"
    else
      error_msg="project repository is missing"
    fi
  else
    # check for duplicates across other indices
    if ! [[ "$proj_repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
      error_msg="project repository is invalid: $proj_repo"
    else
      if command -v gum &>/dev/null; then
        # so that the spinner can display, add to the end: 2>/dev/tty
        gum spin --timeout=9s --title="checking repository uri..." -- git ls-remote "${proj_repo}" --quiet --exit-code 2>/dev/tty
      else
        print " checking repository uri..." >&2
        git ls-remote "${proj_repo}" --quiet --exit-code
      fi
      if (( $? != 0 )); then
        error_msg="repository uri is invalid or no access rights: $proj_repo"
        error_msg+="\n  - check if the repository exists"
        error_msg+="\n  - check if you have access rights to the repository"
        error_msg+="\n  - check if the repository is private and you have set up SSH keys or access tokens"
        error_msg+="\n  - wait a moment and try again"
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print "  ${red_cor}${error_msg}${reset_cor}" >&2

    if (( check_proj_repo_is_s )); then
      if save_proj_repo_ $i "$proj_folder" "$pkg_name" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_folder_() {
  set +x
  eval "$(parse_flags_ "check_proj_folder_" "sq" "" "$@")"
  (( check_proj_folder_is_d )) && set -x

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
    if (( check_proj_folder_is_s )); then
      local real_proj_folder=$(realpath -- "$proj_folder" 2>/dev/null)
      if [[ -z "$real_proj_folder" ]]; then
        if (( check_proj_folder_is_q )); then
          #mkdir -p "$proj_folder" 2>/dev/null
        else
          if [[ -n "$pkg_name" ]]; then
            error_msg="project folder doesn't exist for $pkg_name: $proj_folder"
          else
            error_msg="project folder doesn't exist: $proj_folder"
          fi
        fi
      fi
      # if ! mkdir -p "$proj_folder"; then
      #   if [[ -n "$pkg_name" ]]; then
      #     error_msg="failed to create project folder for ${solid_blue_cor}$pkg_name${reset_cor}: $proj_folder"
      #   else
      #     error_msg="failed to create project folder: $proj_folder"
      #   fi
      # fi
    fi
  fi

  local j=0
  local realfolder="${proj_folder:A}"
  for j in {1..10}; do
    if [[ $j -ne $i && -n "$PUMP_PROJ_FOLDER[$j]" && -n "${PUMP_PROJ_SHORT_NAME[$j]}" ]]; then
      local realfolder_proj="${PUMP_PROJ_FOLDER[$j]:A}"

      if [[ "$realfolder" == "$realfolder_proj" ]]; then
        error_msg="in use, please select another folder" >&2
        break;
      fi
    fi
  done

  if [[ -n "$error_msg" ]]; then
    print "  ${red_cor}${error_msg}${reset_cor}" >&2

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ -s $i "$pkg_name" "$proj_repo" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "check_proj_pkg_manager_" "sq" "" "$@")"
  (( check_proj_pkg_manager_is_d )) && set -x

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
  local mode="$1"
  local proj_folder="$2"

  local parent_folder_name="$(basename $(dirname "$proj_folder"))"
  parent_folder_name="${parent_folder_name[1,46]}"
  local folder_name="$(basename "$proj_folder")"
  folder_name="${folder_name[1,46]}"

  if [[ -n "$proj_folder" ]]; then
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
    gum join --align=center --vertical "$titles" "$examples"
  fi

  print " • ${pink_cor}multiple mode${reset_cor}:" >&2
  print "   manages branches in separate folders" >&2
  print "   designed for professionals with extensive branching workflows" >&2
  print " • ${purple_cor}single mode${reset_cor}:" >&2
  print "   manages branches within a single folder" >&2
  print "   ideal for small projects with a limited number of branches" >&2
  print "" >&2

  local default=$((( mode )) && echo "single" || echo "multiple")

  confirm_ "manage the project with ${pink_prompt_cor}multiple${reset_prompt_cor} or ${purple_prompt_cor}single${reset_prompt_cor} mode?" "multiple" "single" "$default"
  local RET=$?

  local i=0
  if [[ -n "$proj_folder" ]]; then
    for i in {1..15}; do
      clear_last_line_2_
    done
  else
    for i in {1..6}; do
      clear_last_line_2_
    done
  fi

  return $RET;
}

function print_tree_ascii_() {
  local dir="${1:-$PWD}"
  local cor="${2:-$green_cor}"
  local max="$3"
  local is_deep="$4"

  if [[ ! -d "$dir" ]]; then return 1; fi

  if [[ -z ${(f)"$(echo "$dir"/*)"} ]]; then
    return 1;
  fi

  local dir_name="$(basename "$dir")"

  print "  ${cor}/${dir_name}/${reset_cor}" >&2
  local total=$(print_tree_ "$dir" "$cor" "$max" "$is_deep")

  ((total++))

  confirm_ "move the contents to a new folder and re-clone the project?"
  local RET=$?

  local i=0
  for i in {1..$total}; do
    clear_last_line_2_
  done

  return $RET;
}

function print_tree_() {
  local path="$1"
  local cor="$2"
  local max="${3:-0}"
  local is_deep="${4:-0}"
  local prefix="$5"

  # Enable proper globbing
  setopt local_options null_glob

  local -a entries=()
  for f in "$path"/*; do
    [[ -e "$f" ]] && entries+=("$f")
  done

  local total=${#entries}
  local count=0

  for entry in "${entries[@]}"; do
    ((count++))
    local name="${entry:t}"  # filename
    local is_last=0; (( count == total )) && is_last=1
    local connector="├──"; (( is_last )) && connector="└──"

    if [[ -d "$entry" ]]; then
      print "   ${cor}${prefix}${connector} ${name}/${reset_cor}" >&2
      local new_prefix="   ${prefix}"
      (( is_last )) && new_prefix+="    " || new_prefix+="│   "

      if (( is_deep )); then
        print_tree_ "$entry" "$cor" "$max" "$is_deep" "$new_prefix"
      fi
    else
      print "   ${cor}${prefix}${connector} ${name}${reset_cor}" >&2
    fi
    if (( count == max )); then
      ((count++))
      print "   ${cor}${prefix}└── ...${reset_cor}" >&2
      break;
    fi
  done

  echo $count
}

function create_backup_proj_folder_() {
  local proj_folder="$1"

  local folder_name="$(basename "$proj_folder")"
  local parent_folder="$(dirname "$proj_folder")"
  local new_proj_folder="${parent_folder}/${folder_name}-backup"

  if [[ ! -d "$new_proj_folder" ]]; then
    mkdir -p "$new_proj_folder" &>/dev/null
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="creating backup for ${folder_name}..." -- \
      rsync -a --remove-source-files "${proj_folder}/" "${new_proj_folder}/"
    gum spin --title="cleaning ${folder_name}..." -- \
      find "$proj_folder" -type d -empty -delete
  else
    print " creating backup for ${folder_name}..."
    rsync -a --remove-source-files "${proj_folder}/" "${new_proj_folder}/"
    find "$proj_folder" -type d -empty -delete
  fi

  mkdir -p "$proj_folder" &>/dev/null
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
    local package_json=$(gh api "${url}/package.json" --jq .download_url 2>/dev/null)

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
    local package_json=$(gh api "${url}/package.json" --jq .download_url 2>/dev/null)

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
  eval "$(parse_flags_ "save_proj_cmd_" "fae" "" "$@")"
  (( save_proj_cmd_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"
  local old_proj_cmd="$3"

  local typed_proj_cmd=""
  typed_proj_cmd=$(input_name_ "type your project name" "$pkg_name" 2>/dev/tty)
  if (( $? == 130 || $? == 2 )); then return 130; fi
  if [[ -z "$typed_proj_cmd" ]]; then return 1; fi

  if ! check_proj_cmd_ $i "$typed_proj_cmd" "$pkg_name" "$old_proj_cmd"; then
    (( TEMP_SAVE_PROJ_CMD_ATTEMPTS++ ))
    if save_proj_cmd_ $i "$pkg_name" "$old_proj_cmd"; then return 0; fi
    return 1;
  fi

  if [[ -z "$TEMP_PUMP_PROJ_SHORT_NAME" ]]; then
    if (( TEMP_SAVE_PROJ_CMD_ATTEMPTS > 0 )); then
      local i=0
      for i in {1..$TEMP_SAVE_PROJ_CMD_ATTEMPTS}; do
        clear_last_line_tty_
      done
      TEMP_SAVE_PROJ_CMD_ATTEMPTS=0
    fi
    TEMP_PUMP_PROJ_SHORT_NAME="$typed_proj_cmd"
    if (( save_proj_cmd_is_e )); then
      clear_last_line_1_
    fi
    print "  ${SAVE_PROJ_COR}project name:${reset_cor} $TEMP_PUMP_PROJ_SHORT_NAME" >&1
    print "" >&1
  fi
}

function save_proj_mode_() {
  set +x
  eval "$(parse_flags_ "save_proj_mode_" "aeq" "" "$@")"
  (( save_proj_mode_is_d )) && set -x

  local i="$1"
  local single_mode="$2"
  local proj_folder="$3"

  local RET=0

  if (( save_proj_mode_is_e || save_proj_mode_is_a )) || [[ -z "$single_mode" ]]; then
    choose_mode_ "$single_mode" "$proj_folder"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    single_mode=$RET
  else
    if [[ "$single_mode" -eq 0 ]]; then
      single_mode=0
    else
      single_mode=1
    fi
  fi

  update_setting_ $i "PUMP_PROJ_SINGLE_MODE" "$single_mode" &>/dev/null

  if (( save_proj_mode_is_q )); then return 0; fi

  clear_last_line_2_
  clear_last_line_1_
  print "  ${SAVE_PROJ_COR}project mode:${reset_cor} $( (( single_mode )) && echo "single" || echo "multiple" )" >&1
  print "" >&1
}

function save_proj_folder_() {
  set +x
  eval "$(parse_flags_ "save_proj_folder_" "aerfsq" "q" "$@")"
  (( save_proj_folder_is_d )) && set -x

  local i="$1"
  local folder_name="$2"
  local proj_repo="$3"
  local proj_folder="$4"

  local folder_exists=0

  if (( save_proj_folder_is_a || save_proj_folder_is_r )); then
    if [[ -n "$proj_folder" && "$proj_folder" == "${PUMP_PROJ_FOLDER[$i]}" ]]; then
      return 0;
    fi
    if (( save_proj_folder_is_a )); then
      # ask to use pwd
      confirm_ "use as project folder: ${blue_prompt_cor}$PWD${reset_prompt_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        proj_folder="$PWD"
        folder_exists=1
      fi
    fi
  fi

  local RET=0
  
  if (( save_proj_folder_is_e )) && [[ -n "$proj_folder" ]]; then
    confirm_ "keep using project folder: ${blue_prompt_cor}$proj_folder${reset_prompt_cor}?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      proj_folder=""
      header="select the project folder"
    fi
  elif (( save_proj_folder_is_r )); then
    RET=1
    header="select the cloned project folder"
  elif [[ -z "$proj_folder" ]]; then
    confirm_ "would you like create a new folder or use an existing folder?" "create new folder" "use existing folder"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      header="select the existing folder"
    fi
  fi

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$proj_repo" ]]; then
      local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
      folder_name=$(sanitize_pkg_name_ "${repo_name:t}")
    fi
    
    if (( RET == 1 )); then
      folder_exists=1
    else      
      if [[ -z "$folder_name" ]]; then
        if ! save_proj_cmd_ $i "$folder_name" "${PUMP_PROJ_SHORT_NAME[$i]}"; then return 1; fi
        folder_name="$TEMP_PUMP_PROJ_SHORT_NAME"
      fi

      header="choose the parent directory where the new project folder will be created"
    fi

    proj_folder=$(find_proj_folder_ $i "$header" "$folder_name" "$folder_exists")
    clear_last_line_2_
    clear_last_line_2_
    if [[ -z "$proj_folder" ]]; then return 1; fi

    if ! check_proj_folder_ -q $i "$proj_folder" "$folder_name" "$proj_repo"; then return 1; fi
  
    if (( folder_exists == 0 )); then
      proj_folder="${proj_folder}/${folder_name}"

      if (( save_proj_folder_is_s )); then # only create folder if calling from check_proj_folder_
        if [[ ! -d "$proj_folder" ]]; then
          mkdir -p "$proj_folder"
        fi
      fi
    fi
  else
    if ! check_proj_folder_ -sq $i "$proj_folder" "$folder_name" "$proj_repo" ${@:5}; then return 1; fi
  fi

  if [[ -z "$proj_folder" ]]; then return 1; fi

  if (( save_proj_folder_is_q )); then
    update_setting_ $i "PUMP_PROJ_FOLDER" "$proj_folder" &>/dev/null
    return 0;
  fi

  if [[ -z "$TEMP_PUMP_PROJ_FOLDER" ]]; then
    TEMP_PUMP_PROJ_FOLDER="$proj_folder"
    update_setting_ $i "PUMP_PROJ_FOLDER" "$TEMP_PUMP_PROJ_FOLDER" &>/dev/null

    clear_last_line_1_
    print "  ${SAVE_PROJ_COR}project folder:${reset_cor} ${TEMP_PUMP_PROJ_FOLDER}" >&1
    print "" >&1
  fi
}

function save_proj_repo_() {
  set +x
  eval "$(parse_flags_ "save_proj_repo_" "afeq" "q" "$@")"
  (( save_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_cmd="$3"
  local proj_repo="$4"

  local RET=0

  if (( ! save_proj_repo_is_f )); then
    if (( save_proj_repo_is_e )) && [[ -n "$proj_repo" ]]; then
      confirm_ "keep using repository: ${blue_prompt_cor}$proj_repo${reset_prompt_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then
        proj_repo=""
      fi
    elif (( save_proj_repo_is_a )) && [[ -z "$proj_repo" ]]; then
      confirm_ "are you adding an existing cloned project folder?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        if ! save_proj_folder_ -r $i "$proj_cmd"; then return 1; fi
        proj_folder="${PUMP_PROJ_FOLDER[$i]}"
      fi
    fi
  fi

  if (( RET != 1 )) && [[ -z "$proj_repo" && -n "$proj_folder" ]]; then
    proj_repo=$(get_repo_ "$proj_folder")
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
      if ! check_proj_repo_ -s $i "$proj_repo" "$proj_folder" "$proj_cmd" ${@:5};  then return 1; fi
    fi
  fi

  if [[ -z "$proj_repo" ]]; then return 1; fi

  if (( save_proj_repo_is_q )); then
    update_setting_ $i "PUMP_PROJ_REPO" "$proj_repo" &>/dev/null
    return 0;
  fi

  if [[ -z "$TEMP_PUMP_PROJ_REPO" ]]; then
    TEMP_PUMP_PROJ_REPO="$proj_repo"
  
    update_setting_ $i "PUMP_PROJ_REPO" "$TEMP_PUMP_PROJ_REPO" &>/dev/null

    if (( save_proj_repo_is_a )); then
      clear_last_line_1_
    fi
    print "  ${SAVE_PROJ_COR}project repository:${reset_cor} ${TEMP_PUMP_PROJ_REPO}" >&1
    print "" >&1
  fi
}

function save_jira_() {
  set +x
  eval "$(parse_flags_ "save_jira_" "feaq" "" "$@")"
  (( save_jira_is_d )) && set -x

  local i="$1"
  local jira_proj="$2"

  if (( save_jira_is_a )) && [[ -n "$jira_proj" ]]; then
    return 0;
  fi

  # confirm_ "set a JIRA project for this project?"
  # local RET=$?
  # if (( RET == 130 || RET == 2 )); then return 130; fi
  # if (( RET == 0 )); then
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

  jira_proj=$(choose_one_ "jira project" "${(@f)$(printf "%s\n" "${projects}")}")
  if [[ -z "$jira_proj" ]]; then return 1; fi
  # else
  #   jira_proj=""
  # fi

  update_setting_ $i "PUMP_JIRA_PROJ" "$jira_proj" &>/dev/null

  if (( save_jira_is_q )); then return 0; fi

  if (( save_jira_is_e )); then
    clear_last_line_1_
  fi
  clear_last_line_1_
  print "  ${SAVE_PROJ_COR}jira project:${reset_cor} ${jira_proj}" >&1
  print "" >&1
}

function save_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "save_pkg_manager_" "fq" "" "$@")"
  (( save_pkg_manager_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  if (( ! save_pkg_manager_is_f )); then
    print "  detecting package manager..." >&1
  fi

  local pkg_manager=$(detect_pkg_manager_ "$proj_folder")

  if [[ -z "$pkg_manager" && -n "$proj_repo" ]]; then
    pkg_manager=$(detect_pkg_manager_online_ "$proj_repo")
  fi

  if (( ! save_pkg_manager_is_f )); then
    clear_last_line_2_
  fi

  local RET=0

  if [[ -n "$pkg_manager" ]] && (( ! save_pkg_manager_is_f )); then
    confirm_ "set package manager ${pink_prompt_cor}${pkg_manager}${reset_prompt_cor}?"
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

  update_setting_ $i "PUMP_PKG_MANAGER" "$pkg_manager" &>/dev/null

  if (( save_pkg_manager_is_q )); then return 0; fi

  clear_last_line_1_
  print "  ${SAVE_PROJ_COR}package manager:${reset_cor} ${pkg_manager}" >&1
  print "" >&1
}

function save_proj_f_() {
  set +x
  eval "$(parse_flags_ "save_proj_f_" "ae" "" "$@")"
  (( save_proj_f_is_d )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local pkg_name="$3"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_f_ index is invalid: $i" >&2
    return 1;
  fi

  local proj_repo=$(get_repo_)

  TEMP_PUMP_PROJ_FOLDER=""
  TEMP_PUMP_PROJ_REPO=""
  TEMP_PUMP_PROJ_SHORT_NAME=""
  TEMP_SAVE_PROJ_CMD_ATTEMPTS=0
  SAVE_PROJ_COR="${bright_yellow_cor}"

  if (( save_proj_f_is_a )); then
    SAVE_PROJ_COR="${bright_green_cor}"
    display_line_ "add new project" "${SAVE_PROJ_COR}"
    print "" >&1
  fi

  # for pro pwd, all the settings come from $PWD

  if (( save_proj_f_is_e )); then
    update_setting_ $i "PUMP_PROJ_SHORT_NAME" "$proj_cmd" &>/dev/null
    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
    update_setting_ $i "PUMP_PROJ_SINGLE_MODE" 1 &>/dev/null

    update_setting_ $i "PUMP_PROJ_FOLDER" "$PWD" &>/dev/null
    update_setting_ $i "PUMP_PROJ_REPO" "$proj_repo" &>/dev/null

    if ! save_pkg_manager_ -fq $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
  else
    remove_proj_ $i

    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
    update_setting_ $i "PUMP_PROJ_SINGLE_MODE" 1 &>/dev/null

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo"; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -fa $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
    if ! save_proj_cmd_ -f $i "$proj_cmd"; then return 1; fi

    if ! update_setting_ $i "PUMP_PROJ_SHORT_NAME" "$TEMP_PUMP_PROJ_SHORT_NAME" &>/dev/null; then return 1; fi

    print "  ${SAVE_PROJ_COR}project saved!${reset_cor}" >&1
    display_line_ "" "${SAVE_PROJ_COR}"
    print "" >&1
  fi

  load_config_entry_ $i

  pro -f "${PUMP_PROJ_SHORT_NAME[$i]}"
  # rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
}

function save_proj_() {
  set +x
  eval "$(parse_flags_ "save_proj_" "ae" "" "$@")"
  (( save_proj_is_d )) && set -x

  local i="$1"
  local proj_name="$2"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_ index is invalid: $i" >&2
    return 1;
  fi

  TEMP_PUMP_PROJ_FOLDER=""
  TEMP_PUMP_PROJ_REPO=""
  TEMP_PUMP_PROJ_SHORT_NAME=""
  TEMP_SAVE_PROJ_CMD_ATTEMPTS=0

  # display header
  if (( save_proj_is_e )); then
    SAVE_PROJ_COR="${bright_yellow_cor}"
    display_line_ "edit project: ${proj_name}" "${SAVE_PROJ_COR}"
  else
    SAVE_PROJ_COR="${bright_green_cor}"
    display_line_ "add new project" "${SAVE_PROJ_COR}"
  fi

  print "" >&1

  local old_pkg_manager=""
  local refresh=0

  if (( save_proj_is_e )); then
    # editing a project
    if [[ "$proj_arg" == "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      refresh=1
    fi

    old_pkg_manager="${PUMP_PKG_MANAGER[$i]}"

    if ! save_proj_repo_ -e $i "${PUMP_PROJ_FOLDER[$i]}" "$proj_name" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
    if ! save_proj_folder_ -e $i "$proj_name" "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}"; then return 1; fi

    if is_git_repo_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=1
    elif get_proj_for_git_ "${PUMP_PROJ_FOLDER[$i]}" "$TEMP_PUMP_PROJ_SHORT_NAME" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=0
    fi

    if ! save_proj_mode_ -e $i "${PUMP_PROJ_SINGLE_MODE[$i]}" "${PUMP_PROJ_FOLDER[$i]}"; then return 1; fi
  
    if ! save_proj_cmd_ -e $i "$proj_name" "${PUMP_PROJ_SHORT_NAME[$i]}"; then return 1; fi
  else
    # adding a new project
    remove_proj_ $i

    if ! save_proj_cmd_ -a $i "$proj_name"; then return 1; fi

    while [[ -z "${PUMP_PROJ_FOLDER[$i]}" ]]; do
      if ! save_proj_repo_ -a $i "${PUMP_PROJ_FOLDER[$i]}" "$TEMP_PUMP_PROJ_SHORT_NAME" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
      if ! save_proj_folder_ -a $i "$TEMP_PUMP_PROJ_SHORT_NAME" "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}"; then return 1; fi
    done

    if is_git_repo_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=1
    elif get_proj_for_git_ "${PUMP_PROJ_FOLDER[$i]}" "$TEMP_PUMP_PROJ_SHORT_NAME" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=0
    fi

    if ! save_proj_mode_ -a $i "${PUMP_PROJ_SINGLE_MODE[$i]}" "${PUMP_PROJ_FOLDER[$i]}"; then return 1; fi
  fi

  if ! save_pkg_manager_ $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi

  local pkg_name=$(get_pkg_name_ "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}")
  
  if [[ -n "$pkg_name" ]]; then
    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  fi
  
  if ! update_setting_ $i "PUMP_PROJ_SHORT_NAME" "$TEMP_PUMP_PROJ_SHORT_NAME" &>/dev/null; then return 1; fi
  
  print "  ${SAVE_PROJ_COR}project saved!${reset_cor}" >&1
  display_line_ "" "${SAVE_PROJ_COR}"
  print "" >&1
  
  load_config_entry_ $i

  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  if [[ ! -d "${PUMP_PROJ_FOLDER[$i]}" ]]; then
    mkdir -p "${PUMP_PROJ_FOLDER[$i]}"
  fi

  local display_msg=1

  if (( ! single_mode )); then
    if is_git_repo_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null; then
      if create_backup_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}"; then
        print " project must be cloned again as project mode has changed" >&1
        print " run: ${yellow_cor}clone ${proj_cmd}${reset_cor}" >&1
        display_msg=0
      fi
    fi
  fi

  if (( refresh )); then
    set_current_proj_ $i
    display_msg=0
  fi
  
  if (( display_msg )); then
    print " now run command: ${solid_blue_cor}${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&1
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

  unset -f i &>/dev/null
  unset -f build &>/dev/null
  unset -f deploy &>/dev/null
  unset -f format &>/dev/null
  unset -f ig &>/dev/null
  unset -f lint &>/dev/null
  unset -f rdev &>/dev/null
  unset -f sb &>/dev/null
  unset -f sbb &>/dev/null
  unset -f start &>/dev/null
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
  alias i="$pkg_manager install"
  alias install="$pkg_manager install"
  # Package manager aliases =========================================================
  alias build="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")build"
  alias deploy="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")deploy"
  alias format="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")format"
  alias ig="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")install --global"
  alias lint="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")lint"
  alias rdev="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")dev"
  alias sb="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")storybook"
  alias sbb="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")storybook:build"
  alias start="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")start"
  alias tsc="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")tsc"
  alias watch="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")watch"

  if [[ "$pump_cov" != "$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    alias ${pkg_manager:0:1}cov="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$pump_test" != "$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    alias ${pkg_manager:0:1}test="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$pump_e2e" != "$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    alias ${pkg_manager:0:1}e2e="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$pump_e2eui" != "$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    alias ${pkg_manager:0:1}e2eui="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$pump_test_watch" != "$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    alias ${pkg_manager:0:1}testw="$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
}

function remove_proj_() {
  local i="$1"

  unset_aliases_

  update_setting_ $i "PUMP_PROJ_SHORT_NAME" "" 1>/dev/null # let this one
  update_setting_ $i "PUMP_PROJ_FOLDER" "" &>/dev/null
  update_setting_ $i "PUMP_PROJ_REPO" "" &>/dev/null
  update_setting_ $i "PUMP_PROJ_SINGLE_MODE" "" &>/dev/null
  update_setting_ $i "PUMP_PKG_MANAGER" "" &>/dev/null
  update_setting_ $i "PUMP_CODE_EDITOR" "" &>/dev/null
  update_setting_ $i "PUMP_CLONE" "" &>/dev/null
  update_setting_ $i "PUMP_SETUP" "" &>/dev/null
  update_setting_ $i "PUMP_FIX" "" &>/dev/null
  update_setting_ $i "PUMP_RUN" "" &>/dev/null
  update_setting_ $i "PUMP_RUN_STAGE" "" &>/dev/null
  update_setting_ $i "PUMP_RUN_PROD" "" &>/dev/null
  update_setting_ $i "PUMP_PRO" "" &>/dev/null
  update_setting_ $i "PUMP_USE" "" &>/dev/null
  update_setting_ $i "PUMP_TEST" "" &>/dev/null
  update_setting_ $i "PUMP_RETRY_TEST" "" &>/dev/null
  update_setting_ $i "PUMP_COV" "" &>/dev/null
  update_setting_ $i "PUMP_OPEN_COV" "" &>/dev/null
  update_setting_ $i "PUMP_TEST_WATCH" "" &>/dev/null
  update_setting_ $i "PUMP_E2E" "" &>/dev/null
  update_setting_ $i "PUMP_E2EUI" "" &>/dev/null
  update_setting_ $i "PUMP_PR_TEMPLATE" "" &>/dev/null
  update_setting_ $i "PUMP_PR_REPLACE" "" &>/dev/null
  update_setting_ $i "PUMP_PR_APPEND" "" &>/dev/null
  update_setting_ $i "PUMP_PR_RUN_TEST" "" &>/dev/null
  update_setting_ $i "PUMP_GHA_INTERVAL" "" &>/dev/null
  update_setting_ $i "PUMP_COMMIT_ADD" "" &>/dev/null
  update_setting_ $i "PUMP_GHA_WORKFLOW" "" &>/dev/null
  update_setting_ $i "CURRENT_PUMP_PUSH_ON_REFIX" "" &>/dev/null
  update_setting_ $i "PUMP_PRINT_README" "" &>/dev/null
  update_setting_ $i "PUMP_PKG_NAME" "" &>/dev/null
  update_setting_ $i "PUMP_JIRA_PROJ" "" &>/dev/null
  update_setting_ $i "PUMP_JIRA_IN_PROGRESS" "" &>/dev/null
  update_setting_ $i "PUMP_JIRA_IN_REVIEW" "" &>/dev/null
  update_setting_ $i "PUMP_JIRA_DONE" "" &>/dev/null
  update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" "" &>/dev/null
  update_setting_ $i "PUMP_NVM_USE_V" "" &>/dev/null
  update_setting_ $i "PUMP_DEFAULT_BRANCH" "" &>/dev/null
}

function set_current_proj_() {
  local i="$1"

  unset_aliases_

  CURRENT_PUMP_PROJ_SHORT_NAME="${PUMP_PROJ_SHORT_NAME[$i]}"
  CURRENT_PUMP_PROJ_FOLDER="${PUMP_PROJ_FOLDER[$i]}"
  CURRENT_PUMP_PROJ_REPO="${PUMP_PROJ_REPO[$i]}"
  CURRENT_PUMP_PROJ_SINGLE_MODE="${PUMP_PROJ_SINGLE_MODE[$i]}"
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
  CURRENT_PUMP_PR_TEMPLATE="${PUMP_PR_TEMPLATE[$i]}"
  CURRENT_PUMP_PR_REPLACE="${PUMP_PR_REPLACE[$i]}"
  CURRENT_PUMP_PR_APPEND="${PUMP_PR_APPEND[$i]}"
  CURRENT_PUMP_PR_RUN_TEST="${PUMP_PR_RUN_TEST[$i]}"
  CURRENT_PUMP_GHA_INTERVAL="${PUMP_GHA_INTERVAL[$i]}"
  CURRENT_PUMP_COMMIT_ADD="${PUMP_COMMIT_ADD[$i]}"
  CURRENT_PUMP_GHA_WORKFLOW="${PUMP_GHA_WORKFLOW[$i]}"
  CURRENT_PUMP_PUSH_ON_REFIX="${PUMP_PUSH_ON_REFIX[$i]}"
  CURRENT_PUMP_PRINT_README="${PUMP_PRINT_README[$i]}"
  CURRENT_PUMP_PKG_NAME="${PUMP_PKG_NAME[$i]}"
  CURRENT_PUMP_JIRA_PROJ="${PUMP_JIRA_PROJ[$i]}"
  CURRENT_PUMP_JIRA_IN_PROGRESS="${PUMP_JIRA_IN_PROGRESS[$i]}"
  CURRENT_PUMP_JIRA_IN_REVIEW="${PUMP_JIRA_IN_REVIEW[$i]}"
  CURRENT_PUMP_JIRA_DONE="${PUMP_JIRA_DONE[$i]}"
  CURRENT_PUMP_NVM_SKIP_LOOKUP="${PUMP_NVM_SKIP_LOOKUP[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"
  CURRENT_PUMP_DEFAULT_BRANCH="${PUMP_DEFAULT_BRANCH[$i]}"

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
  local sort_by="${2:-latest}"
  local node_engine="$3"

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
  local installed_versions=($(nvm ls --no-colors | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^[-> ]*//' | sed 's/^v//' | sed 's/ *\*$//'))

  if (( ${#installed_versions[@]} == 0 )); then return 1; fi

  local matching_versions=()

  # find matching versions
  for version in "${installed_versions[@]}"; do
    if is_node_version_valid_ "$node_engine" "$version"; then
      matching_versions+=("$version")
    fi
  done

  if (( ${#matching_versions[@]} == 0 )); then
    print " warning: no matching node version found for engine: $node_engine" 2>/dev/tty >&2
    print " run: ${yellow_cor}nvm install <version>${reset_cor} to install it" 2>/dev/tty >&2
    return 1;
  fi

  if [[ "$sort_by" == "latest" ]]; then
    echo "$(printf "%s\n" "${matching_versions[@]}" | sort -V | tail -n 10)"
  else
    echo "$(printf "%s\n" "${matching_versions[@]}" | sort -V | head -n 10)"
  fi
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
  
  display_line_ "" "$dark_gray_cor"

  if (( i > 0 )); then
    print " [${solid_magenta_cor}PUMP_PROJ_SHORT_NAME_$i=${reset_cor}${gray_cor}${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PROJ_FOLDER_$i=${reset_cor}${gray_cor}${PUMP_PROJ_FOLDER[${solid_magenta_cor}$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PROJ_REPO_$i=${reset_cor}${gray_cor}${PUMP_PROJ_REPO[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PROJ_SINGLE_MODE_$i=${reset_cor}${gray_cor}${PUMP_PROJ_SINGLE_MODE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PKG_MANAGER_$i=${reset_cor}${gray_cor}${PUMP_PKG_MANAGER[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_RUN_$i=${reset_cor}${gray_cor}${PUMP_RUN[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_RUN_STAGE_$i=${reset_cor}${gray_cor}${PUMP_RUN_STAGE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_RUN_PROD_$i=${reset_cor}${gray_cor}${PUMP_RUN_PROD[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_SETUP_$i=${reset_cor}${gray_cor}${PUMP_SETUP[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_FIX_$i=${reset_cor}${gray_cor}${PUMP_FIX[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_CLONE_$i=${reset_cor}${gray_cor}${PUMP_CLONE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PRO_$i=${reset_cor}${gray_cor}${PUMP_PRO[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_USE_$i=${reset_cor}${gray_cor}${PUMP_USE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_CODE_EDITOR_$i=${reset_cor}${gray_cor}${PUMP_CODE_EDITOR[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_COV_$i=${reset_cor}${gray_cor}${PUMP_COV[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_OPEN_COV_$i=${reset_cor}${gray_cor}${PUMP_OPEN_COV_[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_TEST_$i=${reset_cor}${gray_cor}${PUMP_TEST[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_RETRY_TEST_$i=${reset_cor}${gray_cor}${PUMP_RETRY_TEST[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_TEST_WATCH_$i=${reset_cor}${gray_cor}${PUMP_TEST_WATCH[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_E2E_$i=${reset_cor}${gray_cor}${PUMP_E2E[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_E2EUI_$i=${reset_cor}${gray_cor}${PUMP_E2EUI[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PR_TEMPLATE_$i=${reset_cor}${gray_cor}${PUMP_PR_TEMPLATE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PR_REPLACE_$i=${reset_cor}${gray_cor}${PUMP_PR_REPLACE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PR_APPEND_$i=${reset_cor}${gray_cor}${PUMP_PR_APPEND[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PR_RUN_TEST_$i=${reset_cor}${gray_cor}${PUMP_PR_RUN_TEST[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_COMMIT_ADD_$i=${reset_cor}${gray_cor}${PUMP_COMMIT_ADD[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PUSH_ON_REFIX_$i=${reset_cor}${gray_cor}${PUMP_PUSH_ON_REFIX[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_GHA_INTERVAL_$i=${reset_cor}${gray_cor}${PUMP_GHA_INTERVAL[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_GHA_WORKFLOW_$i=${reset_cor}${gray_cor}${PUMP_GHA_WORKFLOW[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PRINT_README_$i=${reset_cor}${gray_cor}${PUMP_PRINT_README[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_PKG_NAME_$i=${reset_cor}${gray_cor}${PUMP_PKG_NAME[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_JIRA_PROJ_$i=${reset_cor}${gray_cor}${PUMP_JIRA_PROJ[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_JIRA_IN_PROGRESS_$i=${reset_cor}${gray_cor}${PUMP_JIRA_IN_PROGRESS[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_JIRA_IN_REVIEW_$i=${reset_cor}${gray_cor}${PUMP_JIRA_IN_REVIEW[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_JIRA_DONE_$i=${reset_cor}${gray_cor}${PUMP_JIRA_DONE[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_SKIP_NVM_LOOKUP_$i=${reset_cor}${gray_cor}${PUMP_NVM_SKIP_LOOKUP[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_NVM_USE_V$i=${reset_cor}${gray_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}]"
    print " [${solid_magenta_cor}PUMP_DEFAULT_BRANCH_$i=${reset_cor}${gray_cor}${PUMP_DEFAULT_BRANCH[$i]}${reset_cor}]"

    return 0;
  fi

  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_SHORT_NAME=${reset_cor}${gray_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_FOLDER=${reset_cor}${gray_cor}${CURRENT_PUMP_PROJ_FOLDER}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_REPO=${reset_cor}${gray_cor}${CURRENT_PUMP_PROJ_REPO}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_SINGLE_MODE=${reset_cor}${gray_cor}${CURRENT_PUMP_PROJ_SINGLE_MODE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PKG_MANAGER=${reset_cor}${gray_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN=${reset_cor}${gray_cor}${CURRENT_PUMP_RUN}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN_STAGE=${reset_cor}${gray_cor}${CURRENT_PUMP_RUN_STAGE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN_PROD=${reset_cor}${gray_cor}${CURRENT_PUMP_RUN_PROD}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_SETUP=${reset_cor}${gray_cor}${CURRENT_PUMP_SETUP}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_FIX=${reset_cor}${gray_cor}${CURRENT_PUMP_FIX}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_CLONE=${reset_cor}${gray_cor}${CURRENT_PUMP_CLONE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PRO=${reset_cor}${gray_cor}${CURRENT_PUMP_PRO}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_USE=${reset_cor}${gray_cor}${CURRENT_PUMP_USE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_CODE_EDITOR=${reset_cor}${gray_cor}${CURRENT_PUMP_CODE_EDITOR}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_COV=${reset_cor}${gray_cor}${CURRENT_PUMP_COV}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_OPEN_COV=${reset_cor}${gray_cor}${CURRENT_PUMP_OPEN_COV}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_TEST=${reset_cor}${gray_cor}${CURRENT_PUMP_TEST}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_RETRY_TEST=${reset_cor}${gray_cor}${CURRENT_PUMP_RETRY_TEST}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_TEST_WATCH=${reset_cor}${gray_cor}${CURRENT_PUMP_TEST_WATCH}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_E2E=${reset_cor}${gray_cor}${CURRENT_PUMP_E2E}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_E2EUI=${reset_cor}${gray_cor}${CURRENT_PUMP_E2EUI}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_TEMPLATE=${reset_cor}${gray_cor}${CURRENT_PUMP_PR_TEMPLATE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_REPLACE=${reset_cor}${gray_cor}${CURRENT_PUMP_PR_REPLACE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_APPEND=${reset_cor}${gray_cor}${CURRENT_PUMP_PR_APPEND}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_RUN_TEST=${reset_cor}${gray_cor}${CURRENT_PUMP_PR_RUN_TEST}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_COMMIT_ADD=${reset_cor}${gray_cor}${CURRENT_PUMP_COMMIT_ADD}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PUSH_ON_REFIX=${reset_cor}${gray_cor}${CURRENT_PUMP_PUSH_ON_REFIX}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_GHA_INTERVAL=${reset_cor}${gray_cor}${CURRENT_PUMP_GHA_INTERVAL}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_GHA_WORKFLOW=${reset_cor}${gray_cor}${CURRENT_PUMP_GHA_WORKFLOW}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PRINT_README=${reset_cor}${gray_cor}${CURRENT_PUMP_PRINT_README}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_PKG_NAME=${reset_cor}${gray_cor}${CURRENT_PUMP_PKG_NAME}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_JIRA_PROJ=${reset_cor}${gray_cor}${CURRENT_PUMP_JIRA_PROJ}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_JIRA_IN_PROGRESS=${reset_cor}${gray_cor}${CURRENT_PUMP_JIRA_IN_PROGRESS}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_JIRA_REVIEW=${reset_cor}${gray_cor}${CURRENT_PUMP_JIRA_IN_REVIEW}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_JIRA_DONE=${reset_cor}${gray_cor}${CURRENT_PUMP_JIRA_DONE}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_NVM_SKIP_LOOKUP=${reset_cor}${gray_cor}${CURRENT_PUMP_NVM_SKIP_LOOKUP}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_NVM_USE_V=${reset_cor}${gray_cor}${CURRENT_PUMP_NVM_USE_V}${reset_cor}]"
  print " [${solid_pink_cor}CURRENT_PUMP_DEFAULT_BRANCH=${reset_cor}${gray_cor}${CURRENT_PUMP_DEFAULT_BRANCH}${reset_cor}]"
}

function which_pro_index_pwd_() {
  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" && -n "${PUMP_PROJ_FOLDER[$i]}" ]]; then
      if [[ $PWD == $PUMP_PROJ_FOLDER[$i]* ]]; then
        echo "$i"
        return 0;
      fi
    fi
  done

  echo "0"
  return 1;
}

function is_project_() {
  local proj_arg="$1"

  if [[ -z "$proj_arg" ]]; then return 1; fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
      return 0;
    fi
  done

  return 1;
}

function get_projects_() {
  if [[ -n "${PUMP_PROJ_SHORT_NAME[*]}" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        echo "${PUMP_PROJ_SHORT_NAME[$i]}"
      fi
    done
  fi
}

function find_proj_index_() {
  set +x
  eval "$(parse_flags_ "find_proj_index_" "zoe" "" "$@")"
  (( find_proj_index_is_d )) && set -x

  local proj_arg="$1"
  local default_index="$2"

  if [[ -z "$proj_arg" ]]; then
    if [[ -n "$default_index" ]]; then
      echo "$default_index"
      return 0;
    fi

    if (( find_proj_index_is_o )); then
      local projects=($(get_projects_))
      if [[ -z "$projects" ]]; then
        print " fatal: no projects found" >&2
        print " run ${yellow_cor}pump -a${reset_cor} to add a project" >&2
        return 1;
      fi

      proj_arg=$(choose_one_ "project" "${projects[@]}")
      if [[ -z "$proj_arg" ]]; then return 1; fi
    else
      print " missing project argument" >&2
      return 1;
    fi
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
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

    proj_arg=$(choose_one_ "project" "${projects[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi

    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        echo "$i"
        return 0;
      fi
    done
  fi

  return 1;
}

function find_proj_by_folder_() {
  set +x
  eval "$(parse_flags_ "find_proj_by_folder_" "k" "" "$@")"
  (( find_proj_by_folder_is_d )) && set -x

  local folder="${1:-$PWD}"

  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" && -n "${PUMP_PROJ_FOLDER[$i]}" ]]; then
      if [[ "${folder:A}" == "${PUMP_PROJ_FOLDER[$i]:A}" ]]; then
        echo "${PUMP_PROJ_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  for i in {1..9}; do
    if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" && -n "${PUMP_PROJ_FOLDER[$i]}" ]]; then
      if [[ "${folder:A}/" == "${PUMP_PROJ_FOLDER[$i]:A}/"* ]]; then
        echo "${PUMP_PROJ_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  if (( ! find_proj_by_folder_is_k )); then
    local parent_folder="$(dirname "$folder")"
    local folder_name="$(basename "$folder")"

    folder_name="${folder_name#.}"
    folder_name="${folder_name%-revs}"
    folder_name="${folder_name%-coverage}"

    local name=$(find_proj_by_folder_ -k "${parent_folder}/${folder_name}" 2>/dev/null)

    if [[ -n "$name" ]]; then
      echo "$name"
      return 0;
    fi
  fi

  # cannot determine project based on pwd
  return 1;
}

function is_proj_folder_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  local files=("package.json" ".git" "README.md" "index.js" "index.ts")

  for file in "${files[@]}"; do
    if [[ -e "${folder}/${file}" ]]; then
      return 0;
    fi

    local pattern=$(printf "%q" "$file")
    local found_file=$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}" \) -prune -o -maxdepth 1 -iname "${pattern}*" -print -quit 2>/dev/null)
    
    if [[ -n "$found_file" ]]; then
      return 0;
    fi
  done

  print " fatal: not a project folder: $folder" >&2
  return 1;
}

function get_default_folder_() {
  local proj_folder="${1:-$PWD}"

  local folder=""

  local dirs=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop" "trunk" "mainline" "default" "stable")
  local dir=""
  for dir in "${dirs[@]}"; do
    folder="${proj_folder}/${dir}"
    if [[ -d "$folder" ]]; then
      if is_git_repo_ "$folder" &>/dev/null; then
        break;
      fi
    fi
  done

  if [[ -z "$folder" ]]; then
    folder=$(get_proj_for_git_ "$proj_folder")
  fi

  if [[ -n "$folder" ]]; then
    echo "$(basename "$folder")"
    return 0;
  fi

  return 1;
}

# function shorten_path_() {
#   local folder="$1"
#   local count="${2:-2}"

#   # Remove trailing slash if present
#   local folder="${folder%/}"

#   # split path into array
#   IFS='/' parts=(${(s:/:)folder})
#   # IFS='/' read -r -A parts <<< "$folder" # either way works, but this in bash
#   local len=${#parts[@]}

#   # Calculate start index
#   local start=$(( len - count ))

#   (( start < 0 )) && start=0

#   # Print the last COUNT elements joined by /
#   local output="${(j:/:)parts[@]:$start}"

#   # Prepend ".../" if not returning the full path
#   if (( count < len )); then
#     echo ".../$output"
#     return 0;
#   fi

#   echo "$output"
# }

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
      proj_folder="$(dirname "$found_file")"
    fi
  fi

  if [[ -z "$proj_folder" ]]; then return 1; fi

  if is_git_repo_ "${proj_folder}" &>/dev/null; then
    pull "${proj_folder}" --quiet &>/dev/null
  fi

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

  if is_git_repo_ "$folder" &>/dev/null; then
    echo "$folder"
    return 0;
  fi

  local dirs=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop" "trunk" "mainline" "default" "stable")
  local dir=""
  for dir in "${dirs[@]}"; do
    if is_git_repo_ "${folder}/${dir}" &>/dev/null; then
      echo "${folder}/${dir}"
      return 0;
    fi
  done

  local found_git="$(find "$folder" \( -path "*/.*" -a ! -name ".git" \) -prune -o -maxdepth 2 -type d -name ".git" -print -quit 2>/dev/null)"
  if [[ -z "$found_git" ]]; then
    found_git="$(find "$folder" \( -path "*/.*" -a ! -name ".git" \) -prune -o -type d -name ".git" -print -quit 2>/dev/null)"
  fi

  if [[ -n "$found_git" ]]; then
    local dir="${folder}/$(dirname "$found_git")"
    if is_git_repo_ "$dir" &>/dev/null; then
      echo "$dir"
      return 0;
    fi
  fi
  
  print " fatal: could not locate a repository folder: $folder" >&2

  if [[ -n "$proj_cmd" ]]; then
    print " run ${yellow_cor}clone $proj_cmd${reset_cor} to clone project" >&2
  fi

  return 1;
}

function is_git_repo_() {
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
  eval "$(parse_flags_ "get_remote_branch_" "frl" "" "$@")"
  (( get_remote_branch_is_d )) && set -x

  local branch="$1"
  local proj_folder="${2-$PWD}"

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  # get_remote_branch_ -r
  # get local name but if branch is not in remote, it fails
  # use it to check if branch exists in remote
  if (( get_remote_branch_is_r )); then
    local remote_name=$(get_remote_origin_ "$git_proj_folder")
    local remote_branch=$(git -C "$git_proj_folder" ls-remote --heads "$remote_name" "$branch" | awk '{print $2}' 2>/dev/null)
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
    gum spin --title="determining the default branch..." -- rm -rf "${folder}/.temp"
    if ! gum spin --title="determining the default branch..." -- git clone "$repo_uri" "${folder}/.temp" --quiet; then return 1; fi
  else
    print " determining the default branch..."
    rm -rf "${folder}/.temp" &>/dev/null
    if ! git clone "$repo_uri" "${folder}/.temp" --quiet; then return 1; fi
  fi

  add-zsh-hook -d chpwd pump_chpwd_
  pushd "${folder}/.temp" &>/dev/null
  
  local default_branch=$(git config --get init.defaultBranch)
  local my_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  popd &>/dev/null
  add-zsh-hook chpwd pump_chpwd_

  rm -rf "${folder}/.temp" &>/dev/null

  # local default_branch_folder="${default_branch//\\/-}"
  # default_branch_folder="${default_branch_folder//\//-}"

  # local my_branch_folder="${my_branch//\\/-}"
  # my_branch_folder="${my_branch_folder//\//-}"

  # if [[ -z "$branch_arg" ]]; then
  #   if [[ -d "${folder}/$default_branch_folder" ]]; then
  #     default_branch=""
  #   fi

  #   if [[ -d "${folder}/$my_branch_folder" ]]; then
  #     my_branch=""
  #   fi
  # fi

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
  eval "$(parse_flags_ "get_default_branch_" "f" "" "$@")"
  (( get_default_branch_is_d )) && set -x

  local proj_folder="${1:-$PWD}"
  local default_branch=""

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then
    return 1;
  fi

  if git -C "$git_proj_folder" rev-parse --is-inside-work-tree &>/dev/null; then
    local remote_name=$(get_remote_origin_ "$git_proj_folder")

    default_branch="$(LC_ALL=C git -C "$git_proj_folder" symbolic-ref refs/remotes/${remote_name}/HEAD 2>/dev/null)"
    if [[ -z "$default_branch" ]]; then
      default_branch=$(LC_ALL=C git -C "$git_proj_folder" remote show $remote_name 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    fi
  else
    local branch="$(git -C "$git_proj_folder" config --get init.defaultBranch 2>/dev/null)"
    if [[ -n "$branch" ]]; then
      default_branch=$(get_remote_branch_ -f "$branch" "$git_proj_folder")
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
  local branch="$2"

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
  eval "$(parse_flags_ "select_branches_" "talre" "" "$@")"
  (( select_branches_is_d )) && set -x

  local searchText="$1"
  local proj_folder="${2:-$PWD}"
  local include_special_branches="${3:-1}"
  local exclude_branches=(${@:4})

  local remote_name=$(get_remote_origin_ "$proj_folder")

  local branch_results=()

  if (( select_branches_is_e )); then
    select_branches_is_t=1
  else
    searchText="*$searchText*"
  fi

  if (( select_branches_is_a )); then
    fetch "$proj_folder" --quiet
    branch_results=("${(@f)$(git -C "$proj_folder" branch --all --list "$searchText" --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | sort -fu
    )}")
  elif (( select_branches_is_r )); then
    fetch "$proj_folder" --quiet
    branch_results=("${(@f)$(git -C "$proj_folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | grep -i "$searchText" \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$proj_folder" branch --list "$searchText" --format="%(refname:short)" \
      | grep -v 'detached' \
      | sort -fu
    )}")
  fi

  local branches_excluded=("$exclude_branches")

  if (( ! include_special_branches )); then
    branches_excluded+=("main" "master" "dev" "develop" "stage" "staging" "prod" "production" "release")
    branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
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
  eval "$(parse_flags_ "select_branch_" "talr" "" "$@")"
  (( select_branch_is_d )) && set -x

  local searchText="$1"
  local header="${2-branch}"
  local proj_folder="${3:-$PWD}"
  local exclude_branches=(${@:4})

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  local remote_name=$(get_remote_origin_ "$git_proj_folder")
  local branch_results=()

  if (( select_branch_is_a )); then
    fetch "$git_proj_folder" --quiet
    branch_results=("${(@f)$(git -C "$git_proj_folder" branch --all --list "*$searchText*" --format="%(refname:short)" \
      | sed "s#^$remote_name/##" \
      | grep -v 'detached' \
      | sort -fu
    )}")
  elif (( select_branch_is_r )); then
    fetch "$git_proj_folder" --quiet
    branch_results=("${(@f)$(git -C "$git_proj_folder" for-each-ref --format='%(refname:short)' refs/remotes \
      | sed "s#^$remote_name/##" \
      | grep -i "$searchText" \
      | sort -fu
    )}")
  else
    branch_results=("${(@f)$(git -C "$git_proj_folder" branch --list "*$searchText*" --format="%(refname:short)" \
      | grep -v 'detached' \
      | sort -fu
    )}")
  fi

  local filtered_branches=()

  if [[ -n "$exclude_branches" && -n "$branch_results" ]]; then
    for branch in "${branch_results[@]}"; do
      if [[ ! " ${exclude_branches[*]} " == *" $branch "* ]]; then
        filtered_branches+=("$branch")
      fi
    done
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    if [[ -n "$searchText" ]]; then
      print " fatal: did not match any branch known to git: $searchText" >&2
    else
      print " fatal: did not find any branch known to git" >&2
    fi
    return 1;
  fi

  local branch_choice=""

  if [[ ${#filtered_branches[@]} -gt 20 ]]; then
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
  if ! command -v gh &>/dev/null; then
    print " fatal: requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  local search_text="$1"
  local proj_folder="${2:-$PWD}"
  local proj_cmd="$3"

  local _pwd="$(pwd)"

  local pr_list=""

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd" 2>/dev/null)
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  add-zsh-hook -d chpwd pump_chpwd_

  local _pwd="$(pwd)"
  
  cd "$git_proj_folder" # use cd here, not pushd

  pr_list=$(gh pr list | grep -i "$search_text" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}')

  cd $_pwd

  add-zsh-hook chpwd pump_chpwd_

  if [[ -z "$pr_list" ]]; then
    if [[ -n "$proj_cmd" ]]; then
      print " no pull requests for $proj_cmd" >&2
    else
      print " no pull requests" >&2
    fi
    return 1;
  fi

  local count=$(echo "$pr_list" | wc -l)
  local titles=$(echo "$pr_list" | cut -f2)

  local select_pr_title=""
  local RET=0

  if [[ $count -gt 20 ]]; then
    print "${bold_purple_prompt_cor} choose pull request: ${reset_cor}" >&2
    select_pr_title=$(echo "$titles" | gum filter --limit 1 --select-if-one --height 20  --indicator=">" --placeholder=" type to filter")
    RET=$?
  else
    select_pr_title=$(echo "$titles" | gum choose --limit 1 --select-if-one --height 20 --header=" choose pull request:")
    RET=$?
  fi
  if (( RET == 130 || RET == 2 )); then return 130; fi
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
      value=$(grep -E '"'$key_name'"\s*:\s*"' "$file" | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
      # value=$(grep -Po '"'"$key_name"'"\s*:\s*"\K[^"]+' "$file" | head -1) only in GNU grep
    fi
    echo "$value"
    return 0;
  fi

  return 1;
}

function get_script_from_pkg_json_() {
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
      value=$(jq -r --arg key "$key_name" '.scripts[$key] // empty' "$file")
    else
      value=$(grep -E '"'$key_name'"\s*:\s*"' "$file" | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
      # value=$(grep -Po '"'"$key_name"'"\s*:\s*"\K[^"]+' "$file" | head -1) only in GNU grep
    fi
    echo "$value"
    return 0;
  fi

  return 1;
}

function load_config_entry_() {
  local i="$1"

  if [[ -z "$i" ]]; then
    print " fatal: load_config_entry_ missing project index" >&2
    return 1;
  fi

  local keys=(
    PUMP_PROJ_SINGLE_MODE
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
    PUMP_PR_TEMPLATE
    PUMP_PR_REPLACE
    PUMP_PR_APPEND
    PUMP_PR_RUN_TEST
    PUMP_GHA_INTERVAL
    PUMP_COMMIT_ADD
    PUMP_GHA_WORKFLOW
    PUMP_PUSH_ON_REFIX
    PUMP_PRINT_README
    PUMP_PKG_NAME
    PUMP_JIRA_PROJ
    PUMP_JIRA_IN_PROGRESS
    PUMP_JIRA_IN_REVIEW
    PUMP_JIRA_DONE
    PUMP_NVM_SKIP_LOOKUP
    PUMP_NVM_USE_V
    PUMP_DEFAULT_BRANCH
  )

  local key=""
  for key in "${keys[@]}"; do
    value=$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")

    # If the value is not set, provide default values for specific keys
    if [[ -z "$value" ]]; then
      local run=$([[ $PUMP_PKG_MANAGER[$i] == "yarn" ]] && echo "" || echo "run ")

      case "$key" in
        # PUMP_PROJ_SINGLE_MODE) # on clone we want to let the user select the mode if nothing is set on the config
        #   value=0
        #   ;;
        PUMP_PKG_MANAGER)
          value="npm"
          ;;
        PUMP_USE)
          value="node"
          ;;
        PUMP_TEST)
          value="${PUMP_PKG_MANAGER[$i]} ${run}test"
          ;;
        PUMP_RETRY_TEST)
          value=0
          ;;
        PUMP_COV)
          value="${PUMP_PKG_MANAGER[$i]} ${run}test:coverage"
          ;;
        PUMP_TEST_WATCH)
          value="${PUMP_PKG_MANAGER[$i]} ${run}test:watch"
          ;;
        PUMP_E2E)
          value="${PUMP_PKG_MANAGER[$i]} ${run}test:e2e"
          ;;
        PUMP_E2EUI)
          value="${PUMP_PKG_MANAGER[$i]} ${run}test:e2e-ui"
          ;;
        PUMP_PR_APPEND)
          value=0
          ;;
        PUMP_GHA_INTERVAL)
          value=10
          ;;
        *)
          continue
          ;;
      esac
    fi

    # store the value
    case "$key" in
      PUMP_PROJ_SINGLE_MODE)
        PUMP_PROJ_SINGLE_MODE[$i]="$value"
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
      PUMP_PR_TEMPLATE)
        PUMP_PR_TEMPLATE[$i]="$value"
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
      PUMP_GHA_WORKFLOW)
        PUMP_GHA_WORKFLOW[$i]=$value
        ;;
      PUMP_PUSH_ON_REFIX)
        PUMP_PUSH_ON_REFIX[$i]="$value"
        ;;
      PUMP_PRINT_README)
        PUMP_PRINT_README[$i]="$value"
        ;;
      PUMP_PKG_NAME)
        PUMP_PKG_NAME[$i]="$value"
        ;;
      PUMP_JIRA_PROJ)
        PUMP_JIRA_PROJ[$i]="$value"
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
    esac
    # print "$i - key: [$key], value: [$value]"
  done
}

function load_config_() {
  load_config_entry_ 0
  # Iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    proj_cmd=$(sed -n "s/^PUMP_PROJ_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJ_SHORT_NAME_${i}" 2>/dev/tty
      continue;
    fi

    [[ -z "$proj_cmd" ]] && continue;  # skip if not defined

    if ! validate_proj_cmd_strict_ "$proj_cmd"; then
      print "  in config data at PUMP_PROJ_SHORT_NAME_$i" 2>/dev/tty
      print "  fix the issue then  ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project repo
    local proj_repo=""
    proj_repo=$(sed -n "s/^PUMP_PROJ_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJ_REPO_${i}" 2>/dev/tty
      continue;
    fi

    # Set project folder path
    local proj_folder=""
    proj_folder=$(sed -n "s/^PUMP_PROJ_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJ_FOLDER_${i}" 2>/dev/tty
      continue;
    fi

    if [[ -n "$proj_folder" ]]; then
      if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then
        print "  error in config data at PUMP_PROJ_FOLDER_${i}" 2>/dev/tty
        print "  fix the issue then  ${yellow_cor}refresh${reset_cor}" 2>/dev/tty
      fi
    fi

    PUMP_PROJ_REPO[$i]="$proj_repo"
    PUMP_PROJ_SHORT_NAME[$i]="$proj_cmd"
    PUMP_PROJ_FOLDER[$i]="$proj_folder"

    load_config_entry_ $i
  done
}

function print_branch_status_() {
  local my_branch="$1"
  local base_branch="$2"
  local proj_folder="${3:-$PWD}"

  if [[ -z "$base_branch" ]]; then
    base_branch="$(get_default_branch_ "$proj_folder" 2>/dev/null)"
    if [[ -z "$base_branch" ]]; then return 1; fi
  fi

  local remote_name=$(get_remote_origin_ "$proj_folder")

  fetch "$proj_folder" --quiet
  
  read behind ahead < <(git -C "$proj_folder" rev-list --left-right --count "${remote_name}/${base_branch}...HEAD")

  if [[ "$base_branch" == "$my_branch" ]]; then
    if (( behind )); then
      print " ${yellow_cor}warning: your branch is behind "$base_branch" by $behind commits and ahead by $ahead commits${reset_cor}" >&2
    fi
  else
    if (( behind || ahead )); then
      print " ${yellow_cor}warning: your branch is behind "$base_branch" by $behind commits and ahead by $ahead commits${reset_cor}" >&2
    fi
  fi

  echo "$behind $ahead"
}

# general functions =========================================================
function kill() {
  if [[ -z "$1" ]]; then
    print "  ${yellow_cor}kill <port>${reset_cor} : to kill a port number"
    return 0;
  fi

  npx --yes kill-port $1
}

function refresh() {
  set +x
  eval "$(parse_flags_ "refresh_" "" "" "$@")"
  #(( refresh_is_d )) && set -x # do not turn on for refresh

  if (( refresh_is_h )); then
    print "  ${yellow_cor}refresh${reset_cor} : runs 'exec zsh'"
    return 0;
  fi

  zsh
}

function upgrade() {
  if omz update; then
    print ""
    update_ -f
  fi
}

function del_file_() {
  eval "$(parse_flags_ "del_file_" "s" "" "$@")"
  (( del_file_d )) && set -x

  local count="$1"
  local file="$2"
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

  if (( ! del_file_s && count <= 3 )) && [[ "${file:t}" != ".DS_Store" ]]; then;
    confirm_ "delete $type: ${blue_prompt_cor}$file${reset_prompt_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET != 0 )); then
      print -l -- " ${magenta_cor}deleted${reset_cor} $file"
      return $RET;
    fi
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $file" -- rm -rf -- "$file"
  else
    print "deleting... $file"
    rm -rf -- "$file"
  fi
  if (( $? == 0 )); then
    if [[ "$file" == "$PWD" ]]; then
      print -l -- " ${yellow_cor}deleted${reset_cor} $file"
      cd ..
    else
      print -l -- " ${magenta_cor}deleted${reset_cor} $file"
    fi
  else
    print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  fi

  return 0;
}

function del_files_() {
  eval "$(parse_flags_ "del_files_" "as" "" "$@")"
  (( del_files_d )) && set -x

  local dont_ask=0
  local count=0
  local files=("$@")

  local RET=0

  for file in "${files[@]}"; do
    ((count++))

    local a_file="" # abolute file path

    if [[ -L "$file" ]]; then
      a_file=$(realpath -- "$file" 2>/dev/null)
    else
      file=$(realpath -- "$file" 2>/dev/null)
    fi

    if (( ! del_files_s && count > 3 )); then
      if (( dont_ask == 0 )); then
        dont_ask=1;
        confirm_ "delete all: ${blue_prompt_cor}${(j:, :)files[$count,-1]}${reset_prompt_cor}?"
        RET=$?
        if (( RET == 130 )); then
          break;
        elif (( RET == 1 )); then
          count=0
        else
          del_files_s=1
        fi
      else
        count=0
      fi
    fi

    if [[ -n "$file" ]]; then
      del_file_ $count "$file"
      RET=$?
      if (( RET == 130 )); then break; fi
    fi

    if [[ -n "$a_file" ]]; then
      del_file_ $count "$a_file"
      RET=$?
      if (( RET == 130 )); then break; fi
    fi
  done

  return $RET;
}

function del() {
  eval "$(parse_flags_ "del_" "sa" "" "$@")"
  (( del_is_d )) && set -x

  if (( del_is_h )); then
    print "  ${yellow_cor}del ${solid_yellow_cor}<glob>${reset_cor} : to delete files"
    print "  ${yellow_cor}del -a${reset_cor} : to include hidden files"
    print "  ${yellow_cor}del -s${reset_cor} : to skip confirmation"
    return 0;
  fi
  
  rm -rf -- .DS_Store &>/dev/null

  local files=()
  local pattern=""

  if [[ -z "$1" ]]; then
    setopt null_glob
    if (( del_is_a )); then
      setopt dot_glob
    else
      setopt no_dot_glob
    fi

    # capture all files in current folder
    files=(*)

    unsetopt null_glob
    if (( del_is_a )); then
      unsetopt dot_glob
    else
      unsetopt no_dot_glob
    fi

    if (( ${#files[@]} > 1 )); then
      files=("${(@f)$(choose_multiple_ "files to delete" "${files[@]}")}")
    fi
  else
    # capture all arguments (quoted or not) as a single pattern
    pattern="$*"
  
    # expand the pattern — if it's a glob, this expands to matches
    files=(${(z)~pattern})
  fi

  # print "files[1] = ${files[1]}"
  # print "pattern $pattern"
  # print "qty ${#files[@]}"
  # print "files @ ${files[@]}"
  # print "files * ${files[*]}"

  if (( ${#files[@]} == 0 )); then return 0; fi

  if (( del_is_s )); then
    del_files_ -s "${files[@]}"
  else
    del_files_ "${files[@]}"
  fi
}

function fix() {
  set +x
  eval "$(parse_flags_ "fix_" "q" "" "$@")"
  (( fix_is_d )) && set -x

  if (( fix_is_h )); then
    print "  ${yellow_cor}fix ${solid_yellow_cor}[<folder>]${reset_cor} : to run fix script, or format + lint script if no fix script is defined"
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

  if ! is_proj_folder_ "$folder"; then return 1; fi

  local _pwd="$(pwd)"

  add-zsh-hook -d chpwd pump_chpwd_
  cd "$folder"

  local pump_fix="$CURRENT_PUMP_FIX"
  local RET=1;

  if [[ -n "$pump_fix" ]]; then
    eval "$pump_fix"
    RET=$?
  else
    local pkg_manager="$CURRENT_PUMP_PKG_MANAGER$([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo " run")"

    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      local _fix=$(get_script_from_pkg_json_ "fix" "$folder")
      local _lint=$(get_script_from_pkg_json_ "lint" "$folder")
      local _format=$(get_script_from_pkg_json_ "format" "$folder")

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
        print " ${red_cor}fatal:${reset_cor} no fix, format or lint script defined in package.json" >&2
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
  eval "$(parse_flags_ "refix_" "q" "" "$@")"
  (( refix_is_d )) && set -x

  if (( refix_is_h )); then
    print "  ${yellow_cor}refix ${solid_yellow_cor}[<folder>]${reset_cor} : to reset last commit then run fix lint and format then re-push"
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

  if ! is_git_repo_ "$folder"; then return 1; fi
  if ! is_proj_folder_ "$folder"; then return 1; fi

  if [[ -z "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    print " fatal: project is not set" >&2
    print " run ${yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -z "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print " fatal: project's package manager is not set" >&2
    return 1;
  fi

  local last_commit_msg=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    last_commit_msg=$(input_from_ "commit message" "" 255)
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$last_commit_msg" ]]; then return 1; fi

    print " ${light_purple_prompt_cor}commit message:${reset_cor} $last_commit_msg" >&2
  else
    if ! git -C "$folder" reset --soft HEAD~1 1>/dev/null; then return 1; fi
  fi

  # if command -v gum &>/dev/null; then
  #   # start spinning
  #   unsetopt monitor
  #   unsetopt notify
  #   pipe_name=$(mktemp -u)
  #   mkfifo "$pipe_name" &>/dev/null
  #   gum spin --title="refixing... \"$last_commit_msg\"" -- sh -c "read < $pipe_name" &
  #   spin_pid=$!
  #   # start spinning
  # else
  #   print " refixing... \"$last_commit_msg\""
  # fi

  fix "$folder" &>/dev/null

  # if command -v gum &>/dev/null; then
  #   # reset spinning
  #   print "   refixing... \"$last_commit_msg\""
  #   echo "done" > "$pipe_name" &>/dev/null
  #   rm "$pipe_name"
  #   wait $spin_pid &>/dev/null
  #   setopt notify
  #   setopt monitor
  #   # reset spinning
  # fi

  if (( $? != 0 )); then
    # $CURRENT_PUMP_PKG_MANAGER run lint --quiet --exit-on-fatal-error
    print "" >&2
    print " ${red_cor}fatal: refix encountered an issue${reset_cor}" >&2
    # reseta "$folder" --quiet &>/dev/null
    # pull "$folder" --quiet &>/dev/null
    return 1;
  fi

  git -C "$folder" add .
  
  if ! git -C "$folder" commit --message="$last_commit_msg" $@; then return 1; fi

  if [[ -n "$CURRENT_PUMP_PUSH_ON_REFIX" && $CURRENT_PUMP_PUSH_ON_REFIX -eq 0 ]]; then
    return 0;
  fi

  if [[ -z "$CURRENT_PUMP_PUSH_ON_REFIX" ]]; then
    if confirm_ "fix done, push updates now?"; then
      if confirm_ "save this preference and don't ask again?" "save" "ask again"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_PUSH_ON_REFIX" 1 &>/dev/null
            break;
          fi
        done
      fi
    else
      return 0;
    fi
  fi

  pushf $@
}

function covc() {
  set +x
  eval "$(parse_flags_ "covc_" "x" "" "$@")"
  (( covc_is_d )) && set -x

  if (( covc_is_h )); then
    print "  ${yellow_cor}covc <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " fatal: covc requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  if ! is_proj_folder_; then return 1; fi
  if ! is_git_repo_; then return 1; fi

  if [[ -z "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    print " fatal: project is not set"
    print " run ${yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i=$(find_proj_index_ "$CURRENT_PUMP_PROJ_SHORT_NAME")
  (( i )) || return 1;

  if ! check_proj_ -r $i; then return 1; fi 

  local proj_repo="${PUMP_PROJ_REPO[$i]}"
  local proj_folder="$PWD"

  if [[ -z "$CURRENT_PUMP_COV" || -z "$CURRENT_PUMP_SETUP" ]]; then
    print " CURRENT_PUMP_COV or CURRENT_PUMP_SETUP is missing for ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor} - edit your pump.zshenv then  ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch_arg="$1"

  branch_arg=$(get_remote_branch_ "$branch_arg" "$proj_folder")

  if [[ -z "$branch_arg" ]]; then
    print " fatal: not a valid branch argument" >&2
    print " run ${yellow_cor}covc -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local my_branch=$(git -C "$proj_folder" branch --show-current)

  if [[ "$branch_arg" == "$my_branch" ]]; then
    print " trying to compare with the same branch" >&2
    return 1;
  fi

  print_branch_status_ "$my_branch" "$branch_arg" "$proj_folder" 1>/dev/null

  local parent_folder="$(dirname "$CURRENT_PUMP_PROJ_FOLDER")"
  local folder_name="$(basename "$CURRENT_PUMP_PROJ_FOLDER")"
  local coverage_folder_single_mode="${parent_folder}/.${folder_name}-coverage"
  local coverage_folder_multiple_mode="${CURRENT_PUMP_PROJ_FOLDER}/.coverage"

  if (( $CURRENT_PUMP_PROJ_SINGLE_MODE )); then
    cov_folder="$coverage_folder_single_mode"
  else
    cov_folder="$coverage_folder_multiple_mode"
  fi

  if is_git_repo_ "$cov_folder" &>/dev/null; then
    reseta "$cov_folder" --quiet &>/dev/null
  else
    gum spin --title="preparing branch... ${branch_arg}" -- rm -rf "$cov_folder"
    gum spin --title="preparing branch... ${branch_arg}" -- git clone "$proj_repo" "$cov_folder"
    if (( $? != 0 )); then
      print " fatal: could not clone project repo: $proj_repo" >&2
      return 1;
    fi
  fi

  if git -C "$cov_folder" switch "$branch_arg" --quiet &>/dev/null; then
    if ! pull "$cov_folder" --quiet &>/dev/null; then
      if (( covc_is_x )); then
        print " fatal: could not pull branch: $branch_arg" >&2
        return 1;
      fi
      gum spin --title="preparing branch... ${branch_arg}" -- rm -rf "$cov_folder"
      covc -x "$branch_arg"
      return $?;
    fi
  else
    if (( covc_is_x )); then
      print " fatal: could not switch to branch: $branch_arg" >&2
      return 1;
    fi
    gum spin --title="preparing branch... ${branch_arg}" -- rm -rf "$cov_folder"
    covc -x "$branch_arg"
    return $?;
  fi

  pushd "$cov_folder" &>/dev/null
  
  if [[ -n "$CURRENT_PUMP_CLONE" ]]; then
    eval "$CURRENT_PUMP_CLONE" &>/dev/null;
  fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${branch_arg}" -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$CURRENT_PUMP_SETUP" &>/dev/null

  local is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  if ! eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
  fi

  echo "   running test coverage... ${branch_arg}"

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  summary1=$(grep -A 4 "Coverage summary" "coverage/coverage-summary.txt")

  # Extract each coverage percentage
  statements1=$(echo "$summary1" | grep "Statements" | awk '{print $3}' | tr -d '%')
  branches1=$(echo "$summary1" | grep "Branches" | awk '{print $3}' | tr -d '%')
  funcs1=$(echo "$summary1" | grep "Functions" | awk '{print $3}' | tr -d '%')
  lines1=$(echo "$summary1" | grep "Lines" | awk '{print $3}' | tr -d '%')

  if (( is_delete_cov_folder )); then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.txt" &>/dev/null
  fi

  popd &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  if ! git switch "$my_branch" --quiet &>/dev/null; then
    print " did not match any branch known to git: $branch_arg" >&2
    return 1;
  fi

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage on ${my_branch}..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$CURRENT_PUMP_SETUP" &>/dev/null

  if ! eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
  fi

  echo "   running test coverage on ${my_branch}..."

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  summary2=$(grep -A 4 "Coverage summary" "coverage/coverage-summary.txt")

  # Extract each coverage percentage
  statements2=$(echo "$summary2" | grep "Statements" | awk '{print $3}' | tr -d '%')
  branches2=$(echo "$summary2" | grep "Branches" | awk '{print $3}' | tr -d '%')
  funcs2=$(echo "$summary2" | grep "Functions" | awk '{print $3}' | tr -d '%')
  lines2=$(echo "$summary2" | grep "Lines" | awk '{print $3}' | tr -d '%')

  # # Print the extracted values
  print ""
  display_line_ "coverage" "${gray_cor}" 68
  display_double_line_ "${1:0:22}" "${gray_cor}" "${my_branch:0:22}" "${gray_cor}" 68
  print ""

  color=$(if [[ $statements1 -gt $statements2 ]]; then echo "${red_cor}"; elif [[ $statements1 -lt $statements2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Statements\t\t: $(printf "%.2f" $statements1)%  |${color} Statements\t\t: $(printf "%.2f" $statements2)% ${reset_cor}"
  
  color=$(if [[ $branches1 -gt $branches2 ]]; then echo "${red_cor}"; elif [[ $branches1 -lt $branches2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Branches\t\t: $(printf "%.2f" $branches1)%  |${color} Branches\t\t: $(printf "%.2f" $branches2)% ${reset_cor}"
  
  color=$(if [[ $funcs1 -gt $funcs2 ]]; then echo "${red_cor}"; elif [[ $funcs1 -lt $funcs2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Functions\t\t: $(printf "%.2f" $funcs1)%  |${color} Functions\t\t: $(printf "%.2f" $funcs2)% ${reset_cor}"
  
  color=$(if [[ $lines1 -gt $lines2 ]]; then echo "${red_cor}"; elif [[ $lines1 -lt $lines2 ]]; then echo "${green_cor}"; else echo ""; fi)
  print " Lines\t\t\t: $(printf "%.2f" $lines1)%  |${color} Lines\t\t: $(printf "%.2f" $lines2)% ${reset_cor}"
  print ""

  if (( is_delete_cov_folder )); then
    rm -rf "coverage" &>/dev/null
  else
    rm -f "coverage/coverage-summary.txt" &>/dev/null
  fi

  print ""
  print "#### Coverage"
  print "| \`$1\` | \`${my_branch}\` |"
  print "| --- | --- |"
  print "| Statements: $(printf "%.2f" $statements1)% | Statements: $(printf "%.2f" $statements2)% |"
  print "| Branches: $(printf "%.2f" $branches1)% | Branches: $(printf "%.2f" $branches2)% |"
  print "| Functions: $(printf "%.2f" $funcs1)% | Functions: $(printf "%.2f" $funcs2)% |"
  print "| Lines: $(printf "%.2f" $lines1)% | Lines: $(printf "%.2f" $lines2)% |"
  print ""

  setopt monitor
  setopt notify
}

# test functions =========================================================
function test() {
  set +x
  eval "$(parse_flags_ "test_" "" "" "$@")"
  (( test_is_d )) && set -x

  if (( test_is_h )); then
    print "  ${yellow_cor}test${reset_cor} : to run PUMP_TEST"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  if ! is_proj_folder_; then return 1; fi

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
  eval "$(parse_flags_ "cov_" "" "" "$@")"
  (( cov_is_d )) && set -x

  if (( cov_is_h )); then
    print "  ${yellow_cor}cov${reset_cor} : to run PUMP_COV"
    print "  ${yellow_cor}cov <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! is_proj_folder_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    covc $@
    return $?;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  if ! is_proj_folder_; then return 1; fi

  (eval "$CURRENT_PUMP_COV" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ✅ ${green_cor}test coverage passed on first run${reset_cor}"

    if [[ -n "$CURRENT_PUMP_OPEN_COV" ]]; then
      eval "$CURRENT_PUMP_OPEN_COV"
    fi
    return 0
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_COV" $@)
    RET=$?

    if (( RET == 0 )); then
      print " ✅ ${green_cor}test coverage passed on second run${reset_cor}"
      
      if [[ -n "$CURRENT_PUMP_OPEN_COV" ]]; then
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
  eval "$(parse_flags_ "testw_" "" "" "$@")"
  (( testw_is_d )) && set -x

  if (( testw_is_h )); then
    print "  ${yellow_cor}testw${reset_cor} : to run PUMP_TEST_WATCH"
    return 0;
  fi

  if ! is_proj_folder_; then return 1; fi

  eval "$CURRENT_PUMP_TEST_WATCH" $@
}

function e2e() {
  set +x
  eval "$(parse_flags_ "e2e_" "" "" "$@")"
  (( e2e_is_d )) && set -x

  if (( e2e_is_h )); then
    print "  ${yellow_cor}e2e${reset_cor} : to run PUMP_E2E"
    print "  ${yellow_cor}e2e <e2e_project>${reset_cor} : to run PUMP_E2E --project <e2e_project>"
    return 0;
  fi

  if ! is_proj_folder_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2E" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2E" $@
  fi
}

function e2eui() {
  set +x
  eval "$(parse_flags_ "e2eui_" "" "" "$@")"
  (( e2eui_is_d )) && set -x

  if (( e2eui_is_h )); then
    print "  ${yellow_cor}e2eui${reset_cor} : to run PUMP_E2EUI"
    print "  ${yellow_cor}e2eui ${solid_yellow_cor}<test_project>${reset_cor} : to run PUMP_E2EUI --project"
    return 0;
  fi

  if ! is_proj_folder_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2EUI" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2EUI" $@
  fi
}

# github functions =========================================================
function add() {
  set +x
  eval "$(parse_flags_ "add_" "" "" "$@")"
  (( add_is_d )) && set -x

  if (( add_is_h )); then
    print "  ${yellow_cor}add${reset_cor} : to add all files to index"
    print "  ${yellow_cor}add <glob>${reset_cor} : to add certain files to index"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if [[ -n "$1" && $1 != -*  ]]; then
    git add "$1" ${@:2}
  else
    git add . $@
  fi
}

function read_commits_() {
  set +x
  eval "$(parse_flags_ "read_commits_" "tc" "" "$@")"
  (( read_commits_is_d )) && set -x
  
  local my_branch="$1"
  local default_branch="$2"

  local pr_title=""
  local commit_message=""

  git --no-pager log --no-merges --pretty=format:'%H | %s' \
    "${default_branch}..${my_remote_branch}" | xargs -0 | while IFS= read -r line; do
    
    local commit_hash=$(echo "$line" | cut -d'|' -f1 | xargs)
    commit_message="$(echo "$line" | cut -d'|' -f2- | xargs)"

    local jira_key=""
    local rest=""

    jira_key=$(extract_jira_key_ "$commit_message")
    if (( $? == 0 )); then
      if [[ $commit_message =~ [[:alnum:]]+-[[:digit:]]+(.*) ]]; then
        rest="${match[1]}"
        rest="$(echo "$rest" | xargs)"
      fi
    fi

    local types="fix|feat|docs|refactor|test|chore|style|revert"
    if [[ $rest =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}}):[[:space:]]*(.*)" ]]; then
      rest="${match[2]}"
    fi

    if [[ -n "$jira_key" && -n "$rest" ]]; then
      pr_title=$(echo "${jira_key} ${rest}" | xargs)
    fi

    if (( read_commits_is_c )); then
      echo "- $commit_hash - $commit_message"
    fi
  done

  if (( read_commits_is_t )); then
    if [[ -z "$pr_title" ]]; then
      pr_title="$commit_message"
    fi

    echo "$pr_title"
    return 0;
  fi
}

function pra() {
  set +x
  eval "$(parse_flags_ "pra_" "" "" "$@")"
  (( pra_is_d )) && set -x

  if (( pra_is_h )); then
    print "  ${yellow_cor}pra${reset_cor} : to set assignee as the author of Pull Requests"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: pra requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! command -v jq &>/dev/null; then
    print " fatal: pra requires jq" >&2
    print " install jq:${blue_cor} https://jqlang.org/download/ ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

  local prs=""
  if command -v gum &>/dev/null; then
    prs=$(gum spin --title="fetching pull requests..." -- gh pr list --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees}')
  else
    print " fetching pull requests..."
    prs=$(gh pr list --limit 100 --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees}')
  fi
  if (( $? != 0 )); then return 1; fi

  echo $prs | jq -c '.' | while read -r pr; do
    pr_number=$(echo $pr | jq -r '.number')
    author=$(echo $pr | jq -r '.author')
    assignees=$(echo $pr | jq -r '.assignees | length')

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

  local jira_key=""

  if [[ $text =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
    jira_key="${match[1]}"
    jira_key="$(echo "$jira_key" | xargs)"
  else
    local folder_name="$(basename "$folder")"
    if [[ $folder_name =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
      jira_key="${match[1]}"
      jira_key="$(echo "$jira_key" | xargs)"

      echo "$jira_key"
      return 1;
    fi
  fi

  if [[ -n "$jira_key" ]]; then
    echo "$jira_key"
    return 0;
  fi

  return 1;
}

function pr() {
  set +x
  eval "$(parse_flags_ "pr_" "sl" "" "$@")"
  (( pr_is_d )) && set -x

  if (( pr_is_h )); then
    print "  ${yellow_cor}pr ${solid_yellow_cor}<title>${reset_cor} : to create a pull request"
    print "  ${yellow_cor}pr -l${reset_cor} : to create a pull request and select labels if any"
    print "  ${yellow_cor}pr -s${reset_cor} : to skip tests"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: pr requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

  # if gh pr view --web &>/dev/null; then return 0; fi

  # local git_status=$(git status --porcelain 2>/dev/null)
  # if [[ -n "$git_status" ]]; then
  #   print " uncommitted changes detected, cannot create pull request" >&2;
  #   return 1;
  # fi

  local my_branch=$(git branch --show-current)
  if [[ -z "$my_branch" ]]; then
    print " fatal: branch is detached, cannot create pull request" >&2
    return 1;
  fi

  fetch --quiet

  local my_remote_branch=$(get_remote_branch_ -f "$my_branch")
  local default_branch=$(get_default_branch_ -f 2>/dev/null)

  if [[ -z "$my_remote_branch" || -z "$default_branch" ]]; then
    print " fatal: cannot determine remote or default branch" >&2
    print " make sure the branch is pushed and a default branch is set" >&2
    return 1;
  fi

  local pr_commit_msgs=("${(@f)$(read_commits_ -c "$my_remote_branch" "$default_branch")}")
  local pr_title=$(read_commits_ -t "$my_remote_branch" "$default_branch")
  local jira_key=""

  if [[ -z "$pr_commit_msgs" || -z "$pr_title" ]]; then
    print " fatal: no commits found, cannot create pull request" >&2
    return 1;
  fi

  pr_title=$(input_name_ "pull request title" "$pr_title" 255)
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$pr_title" ]]; then return 1; fi

  print " ${light_purple_prompt_cor}pull request title:${reset_cor} $pr_title" >&2

  jira_key=$(extract_jira_key_ "$pr_title")
  if (( $? == 1 )); then
    if [[ -n "$jira_key" ]]; then
      pr_title="${jira_key} ${pr_title}"
    fi
  fi

  local pr_body="${(F)pr_commit_msgs}"

  # for commit in "${pr_commit_msgs[@]}"; do
  #   pr_body+="${commit}\n"
  # done

  if [[ -n "$CURRENT_PUMP_PR_REPLACE" && -f "$CURRENT_PUMP_PR_TEMPLATE" ]]; then
    local pr_template="$(cat $CURRENT_PUMP_PR_TEMPLATE)"
    
    if [[ -n "$pr_template" ]]; then
      if (( CURRENT_PUMP_PR_APPEND )); then
        # Append commit msgs right after CURRENT_PUMP_PR_REPLACE in pr template
        pr_body=$(echo "$pr_template" | perl -pe "s/(\Q${CURRENT_PUMP_PR_REPLACE}\E)/\1\n\n${pr_body}\n/")
      else
        # Replace CURRENT_PUMP_PR_REPLACE with commit msgs in pr template
        pr_body=$(echo "$pr_template" | perl -pe "s/\Q${CURRENT_PUMP_PR_REPLACE}\E/${pr_body}/g")
      fi
    fi
  fi

  if [[ -z "$pr_body" ]]; then
    print " no pull request body, cannot create pull request" >&2
    return 1;
  fi

  if (( ! pr_is_s )) && [[ -z "$CURRENT_PUMP_PR_RUN_TEST" ]]; then
    if confirm_ "run tests before pull request?"; then
      if confirm_ "save this preference and don't ask again?" "save" "ask again"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_PR_RUN_TEST" 1 &>/dev/null
            break;
          fi
        done
        print ""
      fi
    fi
  fi

  if (( ! pr_is_s && CURRENT_PUMP_PR_RUN_TEST )); then
    test || return 1;
  fi

  # print -- "debugging purposes:"
  # print -- "${magenta_cor}jira_key:${reset_cor} $jira_key"
  # print -- "${magenta_cor}Title:${reset_cor} $pr_title"
  # print -- "${magenta_cor}Body:${reset_cor}"
  # print -- "$pr_body"
  # return 1;

  if (( pr_is_l )); then
    local i=$(find_proj_index_ "$CURRENT_PUMP_PROJ_SHORT_NAME")
    (( i )) || return 1;
    
    if ! check_proj_ -r $i; then return 1; fi

    local proj_repo="${PUMP_PROJ_REPO[$i]}"

    if [[ -n "$proj_repo" ]]; then
      local labels=("${(@f)$(gh label list --repo "$proj_repo" --limit 25 | awk '{print $1}')}")
      
      if [[ -n "$labels" ]]; then
        local choose_labels=$(choose_multiple_ "labels" "none ${labels[@]}")
        if [[ -z "$choose_labels" ]]; then return 1; fi

        if [[ "$choose_labels" == "none" ]]; then
          gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
        else
          local choose_labels_comma="${(j:,:)${(f)choose_labels}}"
          gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$choose_labels_comma"
        fi
      fi
    fi
  fi

  if gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"; then
    if [[ -n "$jira_key" ]]; then
      jira -r "$CURRENT_PUMP_PROJ_SHORT_NAME" "$jira_key" 2>/dev/null
    fi
    return 0;
  fi

  return 1;
}

function run() {
  set +x
  eval "$(parse_flags_ "run_" "" "" "$@")"
  (( run_is_d )) && set -x

  if (( run_is_h )); then
    print "  ${yellow_cor}run${reset_cor} : to run dev in current folder"
    print "  --"
    print "  ${yellow_cor}run dev${reset_cor} : to run dev in current folder"
    print "  ${yellow_cor}run stage${reset_cor} : to run stage in current folder"
    print "  ${yellow_cor}run prod${reset_cor} : to run prod in current folder"
    print "  --"
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print "  ${yellow_cor}run <folder>${reset_cor} : to run a ${CURRENT_PUMP_PROJ_SHORT_NAME}'s folder on dev environment"
      print "  ${yellow_cor}run <folder> ${solid_yellow_cor}<env>${reset_cor} : to run a ${CURRENT_PUMP_PROJ_SHORT_NAME}'s folder on given environment"
      print "  --"
    fi
    print "  ${yellow_cor}run <pro> <folder>${reset_cor} : to run a project's folder on dev environment"
    print "  ${yellow_cor}run <pro> <folder> ${solid_yellow_cor}<env>${reset_cor} : to run a project's folder on a given environment"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local folder_arg=""
  local env_mode="dev"

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    env_mode="$3"
    folder_arg="$2"
  elif [[ -n "$2" ]]; then
    local i=$(find_proj_index_ "$1" 2>/dev/null)
    if (( i )); then
      proj_arg="$1"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        if ! check_proj_ -m $i; then return 1; fi
        
        local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

        if (( single_mode )); then
          env_mode="$2";
        else
          folder_arg="$2";
        fi
      else
        folder_arg="$2"
      fi
    elif is_proj_folder_ "$1" &>/dev/null; then
      folder_arg="$1"
      env_mode="$2"
    else
      proj_arg="$1"
      folder_arg="$2"
    fi
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      env_mode="$1"
    elif is_proj_folder_ "$1" &>/dev/null; then
      folder_arg="$1"
    else
      proj_arg="$1"
    fi
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " run ${yellow_cor}run -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if [[ "$env_mode" != "dev" && "$env_mode" != "stage" && "$env_mode" != "prod" ]]; then
    print " env is incorrect, valid options are: dev, stage or prod" >&2
    print " run ${yellow_cor}run -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
  local pump_run="${PUMP_RUN[$i]}"

  if [[ "$env_mode" == "stage" ]]; then
    pump_run="${PUMP_RUN_STAGE[$i]}"
  elif [[ "$env_mode" == "prod" ]]; then
    pump_run="${PUMP_RUN_PROD[$i]}"
  fi

  local folder_to_execute="$PWD"

  if [[ -n "$folder_arg" ]]; then
    folder_to_execute="${proj_folder}/${folder_arg}"
  else
    if [[ "$proj_arg" != "$CURRENT_PUMP_PROJ_SHORT_NAME" ]] || ! is_proj_folder_ "$PWD" &>/dev/null; then
      if (( single_mode )); then
        folder_to_execute="$proj_folder"
      else
        local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
        if [[ -n "$dirs" ]]; then
          local folder=$(choose_one_ -a "folder to run" "${dirs[@]}")
          if [[ -z "$folder" ]]; then return 1; fi
          
          folder_to_execute="${proj_folder}/${folder}"
        fi
      fi
    fi
  fi

  if ! is_proj_folder_ "$folder_to_execute"; then return 1; fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "env_mode=$env_mode"
  # print "folder_to_execute=$folder_to_execute"
  # print " --------"

  cd "$folder_to_execute"

  print " running $env_mode on ${gray_cor}${folder_to_execute}${reset_cor}"

  if [[ -z "$pump_run" ]]; then
    if [[ -n "$pkg_manager" ]]; then
      local pkg_manager_run="$pkg_manager$([[ $pkg_manager == "yarn" ]] && echo "" || echo " run")"
      local pump_run_env=$(get_script_from_pkg_json_ "$env_mode" "$folder")
      if [[ -n "$pump_run_env" ]]; then
        pump_run="$pkg_manager_run $env_mode"
      else
        local pump_run_start=$(get_script_from_pkg_json_ "start" "$folder")
        if [[ -n "$pump_run_start" ]]; then
          pump_run="$pkg_manager start"
        else
          print " fatal: no script not found in package.json: ${yellow_cor}$pkg_manager_run $env_mode${reset_cor} or ${yellow_cor}$pkg_manager start${reset_cor}" >&2
          return 1;
        fi
      fi
    fi
    print " ${solid_pink_cor}${pump_run}${reset_cor}"
    
    if ! eval "$pump_run"; then return 1; fi
  else
    print " ${solid_pink_cor}${pump_run}${reset_cor}"
    
    if ! eval "$pump_run"; then
      if [[ "$env_mode" == "stage" || "$env_mode" == "prod" ]]; then
        print " ${red_cor}fatal: failed to run PUMP_RUN_${env_mode:U}_$i ${reset_cor}" >&2
      else
        print " ${red_cor}fatal: failed to run PUMP_RUN_$i ${reset_cor}" >&2
      fi
      print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi
}

function setup() {
  set +x
  eval "$(parse_flags_ "setup_" "" "" "$@")"
  (( setup_is_d )) && set -x

  if (( setup_is_h )); then
      print "  ${yellow_cor}setup${reset_cor} : to setup current folder"
      if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
        print "  ${yellow_cor}setup <folder>${reset_cor} : to setup a folder for $CURRENT_PUMP_PROJ_SHORT_NAME"
      fi
      print "  --"
    print "  ${yellow_cor}setup <pro>${reset_cor} : to setup a project"
    print "  ${yellow_cor}setup <pro> ${solid_yellow_cor}<folder>${reset_cor} : to setup a project's folder"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    folder_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    elif is_proj_folder_ "$1" &>/dev/null; then
      folder_arg="$1"
    else
      proj_arg="$1"
    fi
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " to see usage{yellow_cor}setup -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"
  
  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
  local pump_setup="${PUMP_SETUP[$i]}"

  local folder_to_execute="$PWD"

  if [[ -n "$folder_arg" ]]; then
    folder_to_execute="${proj_folder}/${folder_arg}"
  else
    if [[ "$proj_arg" != "$CURRENT_PUMP_PROJ_SHORT_NAME" ]] || ! is_proj_folder_ "$PWD" &>/dev/null; then
      if (( single_mode )); then
        folder_to_execute="$proj_folder"
      else
        local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
        if [[ -n "$dirs" ]]; then
          local folder=$(choose_one_ -a "folder to setup" "${dirs[@]}")
          if [[ -z "$folder" ]]; then return 1; fi
          
          folder_to_execute="${proj_folder}/${folder}"
        fi
      fi
    fi
  fi

  if ! is_proj_folder_ "$folder_to_execute"; then return 1; fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "folder_to_execute=$folder_to_execute"
  # print " --------"

  cd "$folder_to_execute"

  print " setting up ${gray_cor}${folder_to_execute}${reset_cor}"

  if [[ -z "$pump_setup" ]]; then
    if [[ -n "$pkg_manager" ]]; then
      local pkg_manager_run="$pkg_manager$([[ $pkg_manager == "yarn" ]] && echo "" || echo " run")"
      pump_setup=$(get_script_from_pkg_json_ "setup" "$folder")
      if [[ -n "$pump_setup" ]]; then
        pump_setup="$pkg_manager_run setup"
      else
        pump_setup="$pkg_manager install"
      fi
    fi
    print " ${solid_pink_cor}${pump_setup}${reset_cor}"
    
    if ! eval "$pump_setup"; then return 1; fi
  else
    print " ${solid_pink_cor}${pump_setup}${reset_cor}"
    
    if ! eval "$pump_setup"; then
      print " ${red_cor}fatal: failed to run PUMP_SETUP_$i ${reset_cor}" >&2
      print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi
  fi

  print ""
  print " next thing you may wanna do:"

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    local scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' "$pkg_json")
    
    local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
  
    local entry;
    for entry in "${(f)scripts}"; do
      local name="${entry%%=*}"
      local cmd="${entry#*=}"

      if [[ "$name" == "build" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}build${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")build\")"; fi
      if [[ "$name" == "deploy" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}deploy${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")deploy\")"; fi
      if [[ "$name" == "start" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}start${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")start\")"; fi
      if [[ "$name" == "dev" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")dev\")"; fi
      if [[ "$name" == "stage" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run stage${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")stage\")"; fi
      if [[ "$name" == "prod" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run prod${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")prod\")"; fi
      if [[ "$name" == "test" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}test${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")test\")"; fi
    done
    print "  --"
  fi

  print "  • run ${yellow_cor}help${reset_cor} to see more options"
}

function get_revs_folder_() {
  local proj_folder="$1"
  local single_mode="$2"

  local parent_folder="$(dirname "$proj_folder")"
  local folder_name="$(basename "$proj_folder")"
  local revs_folder_single_mode="${parent_folder}/.${folder_name}-revs"
  local revs_folder_multiple_mode="${proj_folder}/.revs"

  local revs_folder_single_mode_content="$(find "$revs_folder_single_mode" -maxdepth 1 -type d -name 'rev.*' 2>/dev/null)"
  local revs_folder_multiple_mode_content="$(find "$revs_folder_multiple_mode" -maxdepth 1 -type d -name 'rev.*' 2>/dev/null)"

  if (( single_mode )); then
    if [[ -n "$revs_folder_single_mode_content" ]]; then
      echo "$revs_folder_single_mode"
      return 0;
    fi
  fi

  if [[ -n "$revs_folder_multiple_mode_content" ]]; then
    echo "$revs_folder_multiple_mode"
    return 0;
  fi

  if (( single_mode )); then
    echo "$revs_folder_single_mode"
    mkdir -p "$revs_folder_single_mode" &>/dev/null
  else
    echo "$revs_folder_multiple_mode"
    mkdir -p "$revs_folder_multiple_mode" &>/dev/null
  fi
}

function revs() {
  set +x
  eval "$(parse_flags_ "revs_" "p" "" "$@")"
  (( revs_is_d )) && set -x

  if (( revs_is_h )); then
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print "  ${yellow_cor}revs${reset_cor} : to list reviews from $CURRENT_PUMP_PROJ_SHORT_NAME"
    fi
    print "  ${yellow_cor}revs <pro>${reset_cor} : to list reviews from project"
    print "  ${yellow_cor}revs -p${reset_cor} : to prune reviews"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " fatal: revs requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi
  
  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"

  if [[ -n "$1" ]]; then
    local valid_project=0
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        valid_project=1
        break;
      fi
    done

    if (( valid_project == 0 )); then
      print " fatal: not a valid project: $1" >&2
      print " run ${yellow_cor}revs -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$proj_arg" ]]; then
    print " no project is set" >&2
    print " run ${yellow_cor}pro${reset_cor} to set project" >&2
    return 1;
  fi

  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " run ${yellow_cor}revs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  local revs_folder=$(get_revs_folder_ "$proj_folder" "$single_mode")
  local rev_options=(${~revs_folder}/rev.*(N/))

  if (( ${#rev_options[@]} == 0 )); then
    print " no reviews found for $proj_arg" >&2
    print " run ${yellow_cor}rev -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local rev_choices=()
  local rev_choice=""

  if (( revs_is_p )); then
    rev_choices=($(choose_multiple_ "reviews to prune" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}"))
    if [[ -z "$rev_choices" ]]; then return 1; fi
  else
    rev_choice=$(choose_one_ "review to open" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}")
    if [[ -z "$rev_choice" ]]; then return 1; fi
  fi

  if (( revs_is_p )); then
    local full_revs=()

    for rev in "${rev_choices[@]}"; do
      full_revs+=("${revs_folder}/${rev}")
    done

    # del "${full_revs[@]}"
    for rev in "${rev_choices[@]}"; do
      local rev_folder="${revs_folder}/${rev}"
      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $rev" -- rm -rf -- "$rev_folder"
      else
        print "deleting... $rev"
        rm -rf -- "$rev_folder"
      fi
      if (( $? == 0 )); then
        print -l -- " ${green_cor}deleted${reset_cor} $rev"
      else
        print -l -- " ${red_cor}not deleted${reset_cor} $rev"
      fi
    done

  else
    rev -e "$proj_arg" "${rev_choice//rev./}"
  fi
}

function rev() {
  set +x
  eval "$(parse_flags_ "rev_" "eb" "" "$@")"
  (( rev_is_d )) && set -x

  if (( rev_is_h )); then
    print "  ${yellow_cor}rev${reset_cor} : open a review by pull request"
    print "  ${yellow_cor}rev -b${reset_cor} : open a review by branch"
    print "  ${yellow_cor}rev -e <branch>${reset_cor} : open review by an exact branch (no lookup)"
    print "  --"
    print "  ${yellow_cor}rev <pro>${reset_cor} : to open a review for a project"
    print "  ${yellow_cor}rev <pro> ${solid_yellow_cor}<branch>${reset_cor} : to open a review for a project's branch"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " fatal: rev requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " run ${yellow_cor}rev -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  local pump_setup="${PUMP_SETUP[$i]}"
  local pump_clone="${PUMP_CLONE[$i]}"
  local code_editor="${PUMP_CODE_EDITOR[$i]}"

  if ! check_proj_ -rfm $i; then return 1; fi

  local proj_repo="${PUMP_PROJ_REPO[$i]}"
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  local revs_folder="$(get_revs_folder_ "$proj_folder" "$single_mode")"

  local branch=""
  local pr_title=""

  # rev -e exact branch
  if (( rev_is_e )); then
    if [[ -d "${revs_folder}/rev.${branch_arg}" ]]; then
      branch="$branch_arg"
    fi

    if [[ -z "$branch" ]]; then
      branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")
    fi

    if [[ -z "$branch" ]]; then
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

  # rev -b select branch
  elif (( rev_is_b )); then
    branch="$(select_branch_ -rt "$branch_arg" "branch" "$proj_folder")"
    
    if [[ -z "$branch" ]]; then return 1; fi

  else
    # check if branch arg was given and it's a branch
    if [[ -n "$branch_arg" ]]; then
      branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")
    fi

    if [[ -z "$branch"  ]]; then
      local pr=("${(@s:|:)$(select_pr_ "$branch_arg" "$proj_folder" "$proj_arg")}")
      if [[ -z "${pr[2]}" ]]; then return 1; fi
      
      branch="${pr[2]}"
      pr_title="${pr[3]}"
    fi

    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local full_rev_folder="${revs_folder}/rev.${branch_folder}"

  local skip_setup=0
  local already_merged=0;

  if [[ -d "$full_rev_folder" ]]; then
    print " opening review and pulling changes: ${green_cor}${pr_title:-$branch}${reset_cor}"
    
    cd "$full_rev_folder"

    if ! git checkout "$branch" --quiet; then
      if reseta; then
        git checkout "$branch" --quiet
      else
        skip_setup=1
      fi
    fi

    if (( ! skip_setup )); then
      local git_status=$(git status --porcelain 2>/dev/null)
      if [[ -n "$git_status" ]]; then
        skip_setup=1
        
        if confirm_ "review is not clean, erase your changes and match branch to pull request?"; then
          if reseta; then
            if ! pull --quiet; then
              skip_setup=1
              already_merged=1
            fi
          else
            skip_setup=1
            print " ${red_cor}failed to clean review folder: $full_rev_folder ${reset_cor}" >&2
          fi
        else
          return 1;
        fi
      else
        if ! pull --quiet; then
          skip_setup=1
          already_merged=1
        fi
      fi
    fi

  else
    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg")
    if [[ -z "$git_proj_folder" ]]; then return 1; fi

    print " creating review for pull request: ${green_cor}${branch}${reset_cor}"

    if command -v gum &>/dev/null; then
      local output=""
      output=$(gum spin --title="cloning... $proj_repo" -- git clone "$proj_repo" "$full_rev_folder" 2>&1)
      if (( $? != 0 )); then print "$output" >&2; return 1; fi
    else
      print " cloning... $proj_repo";
      if ! git clone $proj_repo "$full_rev_folder" --quiet; then return 1; fi
    fi

    git -C "$full_rev_folder" checkout "$branch" --quiet
    # end of cloning

    if ! pull "$full_rev_folder" --quiet; then
      already_merged=1
    fi

    cd "$full_rev_folder"
  fi

  local pr_link=""

  if command -v gh &>/dev/null; then
    pr_link=$(gh pr view $branch --json url -q .url 2>/dev/null)
  fi

  if (( ! skip_setup )); then
    if [[ -n "$pump_setup" ]]; then
      print " setting up ${gray_cor}${full_rev_folder}${reset_cor}"
      print " ${solid_pink_cor}${pump_setup}${reset_cor}"

      if ! eval "$pump_setup"; then
        print " ${red_cor}fatal: failed to run PUMP_SETUP_$i ${reset_cor}" >&2
        print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
      fi
    fi
  fi

  if (( already_merged )); then
    print ""
    print -n " ${yellow_cor}warning: pull request is already merged" 
    if [[ -n "$pr_link" ]]; then
      print -n ", check out link: ${blue_cor}$pr_link"
    fi
    print "${reset_cor}"
    print ""

    return 0;
  fi

  if [[ -n "$pr_link" ]]; then
    print ""
    print " check out pull request link: ${blue_cor}$pr_link${reset_cor}"
  fi
  
  print ""

  if [[ -z "$code_editor" ]]; then
    code_editor=$(input_name_ "type the command of your code editor" "code" 255)
    if [[ -n "$code_editor" ]] && eval $code_editor .; then
      update_setting_ $i "PUMP_CODE_EDITOR" $code_editor &>/dev/null
      return 0;
    fi

    return 1;
  else
    if confirm_ "open code editor?"; then
      eval $code_editor .
    fi
  fi
}

function clone() {
  set +x
  eval "$(parse_flags_ "clone_" "" "" "$@")"
  (( clone_is_d )) && set -x

  if (( clone_is_h )); then
    print "  ${yellow_cor}clone${reset_cor} : to clone a project"
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print "  ${yellow_cor}clone <branch>${reset_cor} : to clone ${CURRENT_PUMP_PROJ_SHORT_NAME}'s branch, only if project is in multiple mode"
      print "  ${yellow_cor}clone <branch> <default_branch>${reset_cor} : to clone ${CURRENT_PUMP_PROJ_SHORT_NAME}'s branch with a given default branch, only if project is in multiple mode"
    fi
    print "  ${yellow_cor}clone <pro>${reset_cor} : to clone a project directly"
    print "  ${yellow_cor}clone <pro> <branch>${reset_cor} : to clone a project's branch, only if project is in multiple mode"
    print "  ${yellow_cor}clone <pro> <branch> <default_branch>${reset_cor} : to clone a project's branch with a given default branch, only if project is in multiple mode"
    return 0;
  fi

  local proj_arg=""
  local branch_arg=""
  local default_branch_arg=""

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    branch_arg="$2"
    default_branch_arg="$3"
  elif [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    local valid_project=0
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        valid_project=1
        break;
      fi
    done
    if (( ! valid_project )); then
      if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
        branch_arg="$1"
      else
        print " fatal: not a valid project or branch: $1" >&2
        print " run ${yellow_cor}clone -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi
  else
    if (( ${#PUMP_PROJ_SHORT_NAME} == 0 )); then
      print " no projects found" >&2
      print " run ${yellow_cor}pro -a${reset_cor} to add a project" >&2
      return 1;
    fi

    proj_arg=$(choose_one_ -a "project to clone" "${PUMP_PROJ_SHORT_NAME[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " run ${yellow_cor}clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local print_readme="${PUMP_PRINT_README[$i]}"
  local pump_default_branch="${PUMP_DEFAULT_BRANCH[$i]}"

  if ! check_proj_ -rfm -q $i; then return 1; fi

  local proj_repo="${PUMP_PROJ_REPO[$i]}"
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  local folder_to_clone=""

  local temp_default_branch_1=""
  local temp_default_branch_2=""

  local skip_clone=0

  if (( single_mode )); then
    rm -rf -- "${proj_folder}/.DS_Store" &>/dev/null
    if [[ -n "$(ls -A "$proj_folder" 2>/dev/null)" ]]; then
      print " cannot clone because project is set to ${purple_cor}single mode${reset_cor} and folder is not empty: $proj_folder" >&2
      print " clean the folder or run ${yellow_cor}$proj_arg -e${reset_cor} to edit project and switch to ${pink_cor}multiple mode${reset_cor}" >&2
      return 1;
    fi

    folder_to_clone="$proj_folder"
  else
    local working_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg" 2>/dev/null)

    if [[ -n "$working_proj_folder" ]]; then
      if [[ -z "$branch_arg" ]]; then
        branch_arg=$(input_branch_name_ "feature branch name")
        if [[ -z "$branch_arg" ]]; then return 1; fi

        print " ${purple_cor}feature branch name:${reset_cor} $branch_arg"
      fi

      local branch_folder="${branch_arg//\\/-}"
      branch_folder="${branch_folder//\//-}"

      folder_to_clone="${proj_folder}/${branch_folder}"

      rm -rf -- "${folder_to_clone}/.DS_Store" &>/dev/null
      if [[ -d "$folder_to_clone" && -n "$(ls -A "$folder_to_clone" 2>/dev/null)" ]]; then
        if is_git_repo_ "$folder_to_clone"; then
          skip_clone=1
        fi
      fi
    fi
  fi

  if (( ! skip_clone )); then
    local default_branch="${default_branch_arg:-$pump_default_branch}"

    if [[ -z "$default_branch" ]]; then
      default_branch=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg")
      if (( $? == 130 || $? == 2 )); then return 130; fi

      if [[ -z "$default_branch" ]]; then
        local placeholder=$(get_default_branch_ "$proj_folder" 2>/dev/null)
        default_branch=$(input_branch_name_ "type the default branch" "$placeholder")
        if [[ -z "$default_branch" ]]; then return 1; fi
      fi
    fi

    if [[ -z "$pump_default_branch" || "$default_branch" != "$pump_default_branch" ]]; then
      confirm_ "save default branch ${green_prompt_cor}$default_branch${reset_prompt_cor} and don't ask again, unless it changes?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        update_setting_ $i "PUMP_DEFAULT_BRANCH" $default_branch &>/dev/null
      fi
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
    
    if [[ -z "$branch_arg" ]]; then
      branch_arg="$default_branch"
    fi
    
    branch_arg="${${USER:0:1}:l}-${branch_arg}"
  
    if [[ "$branch_arg" != "${${USER:0:1}:l}-${default_branch}" ]]; then
      print " preparing to clone branch: ${green_cor}${branch_arg}${reset_cor} based on ${solid_green_cor}${default_branch}${reset_cor}"
    else
      print " preparing to clone branch: ${green_cor}${branch_arg}${reset_cor}"
    fi

    rm -rf -- "${folder_to_clone}/.DS_Store" &>/dev/null
    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo on branch: $branch_arg" -- git clone "$proj_repo" "$folder_to_clone"; then
        print " failed to clone: folder is not empty or no access rights: $proj_repo" >&2
        return 1;
      fi
    else
      print " cloning... $proj_repo on branch: $branch_arg"
      if ! git clone --quiet "$proj_repo" "$folder_to_clone"; then return 1; fi
    fi

  fi # end if (( ! skip_clone ))

  remote_branch=$(get_remote_branch_ -r "$branch_arg" "$proj_folder")

  if [[ -n "$remote_branch" ]]; then
    print " fatal: branch already exists on remote: $branch_arg" >&2
    return 1;
  fi

  cd "$folder_to_clone"

  # local jira_key=$(extract_jira_key_ "$branch_arg" "$folder_to_clone")
  # if [[ -n "$jira_key" ]]; then
  #   jira -p "$proj_arg" "$jira_key" 2>/dev/null
  # fi

  local my_branch=$(git branch --show-current)
  if [[ "$branch_arg" != "$my_branch" ]]; then
    if ! git checkout -b "$branch_arg" --quiet &>/dev/null; then
      git checkout "$branch_arg" --quiet &>/dev/null
    fi
  fi

  if (( skip_clone )); then
    return 0;
  fi

  if [[ "$default_branch" != "$branch_arg" ]]; then
    print " ${solid_pink_cor}git config init.defaultBranch $default_branch ${reset_cor}"
    git config init.defaultBranch "$default_branch"
    git config "branch.${branch_arg}.gh-merge-base" "$default_branch"
  fi

  if [[ -n "$pump_clone" ]]; then
    print " ${solid_pink_cor}${pump_clone}${reset_cor}"
    if ! eval "$pump_clone"; then
      print " ${red_cor}fatal: failed to run PUMP_CLONE_$i ${reset_cor}" >&2
      print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
    fi
  fi
  
  print ""
  print " successfully cloned project: ${solid_blue_cor}${proj_arg}${reset_cor}"
  print " default branch is: ${green_cor}$(git config --get init.defaultBranch)${reset_cor}"
  
  print ""
  print " next thing you may wanna do:"

  local readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -maxdepth $maxdepth -type f -iname "README.md*" -print -quit 2>/dev/null)
  if [[ -z "$readme_file" ]]; then
    readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -type f -iname "readme.md*" -print -quit 2>/dev/null)
  fi
  if [[ -n "$readme_file" ]]; then
    print " • run ${yellow_cor}${proj_arg} -i${reset_cor} to show the 'readme' file"
    print " --"
  fi

  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    print " • run ${solid_magenta_cor}setup${reset_cor} (alias for \"$pkg_manager $([[ $pkg_manager == "yarn" ]] && echo "" || echo "run ")setup\")"
    print " • run ${solid_magenta_cor}i${reset_cor} or ${solid_magenta_cor}install${reset_cor} (alias for \"$pkg_manager install\")"
    print "   you can also fully customize ${solid_magenta_cor}setup${reset_cor} by editing the pump.zshenv file entry: PUMP_SETUP"
    print " --"
  fi

  print " • run ${yellow_cor}rev${reset_cor} to open a review"
  print " • run ${yellow_cor}help${reset_cor} to see more options"
  
  
  # README FUNCTIONALITY AFTER CLONING HAS BEEN DISABLED
  # if [[ -z "$print_readme" ]] || (( print_readme )); then # display readme file
  #   local maxdepth=2; (( single_mode )) && maxdepth=1

  #   local readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -maxdepth $maxdepth -type f -iname "README.md*" -print -quit 2>/dev/null)
  #   if [[ -z "$readme_file" ]]; then
  #     readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -type f -iname "readme.md*" -print -quit 2>/dev/null)
  #   fi
    
  #   local RET=0
  #   if [[ -n "$readme_file" ]]; then
  #     if command -v glow &>/dev/null; then
  #       glow "$readme_file"
  #       RET=$?
  #     else
  #       cat "$readme_file"
  #       RET=$?
  #     fi
  #   fi

  #   if (( RET == 0 )) && [[ -z "$print_readme" ]]; then
  #     print ""
  #     confirm_ "always display the readme file for future branches in "$'\e[34m'$proj_arg$'\e[0m'" when available?" "always" "never"
  #     if (( $? == 130 || $? == 2 )); then return 1; fi
  #     if (( $? == 0 )); then
  #       update_setting_ $i "PUMP_PRINT_README" 1 &>/dev/null
  #     else
  #       update_setting_ $i "PUMP_PRINT_README" 0 &>/dev/null
  #     fi
  #   fi
  # fi
  
}

function select_jira_key_() {
  set +x
  eval "$(parse_flags_ "select_jira_key_" "" "" "$@")"
  (( select_jira_key_is_d )) && set -x

  local i="$1"
  local jira_proj="$2"

  if [[ -z "$jira_proj" ]]; then
    if ! check_proj_ -j $i; then return 1; fi
    jira_proj="${PUMP_JIRA_PROJ[$i]}"
    if [[ -z "$jira_proj" ]]; then return 1; fi
  fi

  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"In Progress"}"

  local tickets=$(acli jira workitem search --jql "project='$jira_proj' AND ((assignee IS EMPTY AND status='To Do') OR (assignee=currentUser() AND \
    (status='Blocked' OR status='To Do' OR status='Code Review' OR status='In Review' OR status='$jira_in_progress'))) AND \
    Sprint IS NOT EMPTY ORDER BY priority DESC" --fields="key,summary,status,assignee" | awk 'NR > 1' 2>/dev/null)
  if [[ -z "$tickets" ]]; then
    print " no jira projects found" >&2
    print " run ${yellow_cor}acli jira auth login --web${reset_cor} to make sure you are authenticated" >&2
    return 1;
  fi

  local ticket=""
  ticket=$(choose_one_ "jira ticket" "${(@f)$(printf "%s\n" "$tickets")}")
  if [[ -z "$ticket" ]]; then return 1; fi

  local jira_key=${ticket%% *}

  echo "$jira_key"
  return 0;
}

function jira() {
  set +x
  eval "$(parse_flags_ "jira_" "scrp" "" "$@")"
  (( jira_is_d )) && set -x

  if (( jira_is_h )); then
    print "  ${yellow_cor}jira${reset_cor} : to start the work on a new ticket for current project"
    print "  ${yellow_cor}jira ${solid_yellow_cor}<pro>${reset_cor} : to start the work on a new ticket for a project"
    print "  ${yellow_cor}jira -p <pro> <key>${reset_cor} : to update the status of a ticket to \"In Progress\""
    print "  ${yellow_cor}jira -r <pro> <key>${reset_cor} : to update the status of a ticket to \"In Review\""
    print "  ${yellow_cor}jira -c <pro> <key>${reset_cor} : to update the status of a ticket to \"Close\" or \"Done\""
    print "  ${yellow_cor}jira -s <key> <status>${reset_cor} : to update the status of a ticket (e.g. \"In Progress\", \"In Review\", \"Done\")"
    return 0;
  fi

  if ! command -v acli &>/dev/null; then
    print " acli is not installed" >&2
    print " install at: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2
    return 1;
  fi

  # do not assign CURRENT_PUMP_PROJ_SHORT_NAME here, because user must define it
  # as we cannot determine if a jira ticket belongs to current project with correct statutes
  local proj_arg=""
  local jira_key=""
  local jira_status=""

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    jira_key="$2"
    jira_status="$3"
  elif [[ -n "$2" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
      jira_key="$2"
    else
      jira_key="$1"
      jira_status="$2"
    fi
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    else
      jira_key="$1"
    fi
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! check_proj_ -fm $i; then return 1; fi
  
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"In Progress"}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"In Review"}"
  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"
  local jira_proj="${PUMP_JIRA_PROJ[$i]}"

  if (( jira_is_s || jira_is_r || jira_is_c || jira_is_p )); then
    if [[ -z "$jira_key" ]]; then
      print " missing key argument" >&2
      print " run ${yellow_cor}jira -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( jira_is_s )); then
      if [[ -z "$jira_status" ]]; then
        print " missing status argument" >&2
        print " run ${yellow_cor}jira -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      if (( jira_is_p )); then
        jira_status="$jira_in_progress"
      elif (( jira_is_r )); then
        jira_status="$jira_in_review"
      elif (( jira_is_c )); then
        jira_status="$jira_done"
      fi
    fi

    local current_jira_status=$(acli jira workitem view "$jira_key" --fields status --json | jq -r '.fields.status.name')
    if [[ -z "$current_jira_status" ]]; then
      print " fatal: cannot find jira key: $jira_key" >&2
      return 1;
    fi

    if [[ "$current_jira_status" == "$jira_done" || "$current_jira_status" == "$jira_status" ]]; then
      return 0;
    fi

    local output=$(acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes 2>&1 | tee /dev/tty)
    
    if echo "$output" | grep -qE "Failure"; then
      jira_status=$(input_from_ "Enter jira status (e.g. In Progress, In Review, Done)")
      if [[ -n "$jira_status" ]] && ; then
        acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes
        if (( jira_is_p )); then
          update_setting_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_status" &>/dev/null
        elif (( jira_is_r )); then
          update_setting_ $i "PUMP_JIRA_IN_REVIEW" "$jira_status" &>/dev/null
        elif (( jira_is_c )); then
          update_setting_ $i "PUMP_JIRA_DONE" "$jira_status" &>/dev/null
        fi

        jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"$jira_in_progress"}"
        jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"$jira_in_review"}"
        jira_done="${PUMP_JIRA_DONE[$i]:-"$jira_done"}"
      fi
    fi

    return $?;
  fi

  if (( single_mode )); then
    if [[ ! -d "$proj_folder" || -z "$(ls "$proj_folder" 2>/dev/null)" ]]; then
      print " cannot run jira before cloning the project" >&2
      print " run ${yellow_cor}clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  else
    local working_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg" 2>/dev/null)
    if [[ -z "$working_proj_folder" || ! -d "$working_proj_folder" || -z "$(ls "$working_proj_folder" 2>/dev/null)" ]]; then
      print " cannot run jira before cloning the project" >&2
      print " run ${yellow_cor}clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$jira_key" ]]; ; then
    jira_key=$(select_jira_key_ $i "$jira_proj")
    if [[ -z "$jira_key" ]]; then return 1; fi
  fi

  acli jira workitem assign --key="$jira_key" --assignee="@me" --yes

  local RET=0

  if (( single_mode )); then
    fetch "$proj_folder" --quiet
    
    local branch="${${USER:0:1}:l}-$jira_key"
    local find_branch=$(git -C "$proj_folder" branch --all --list "$branch" --format="%(refname:short)")
    
    cd "$proj_folder"
    
    if [[ -n "$find_branch" ]]; then
      co -e "$branch"
      RET=$?
    else
      local default_branch=$(get_default_branch_ "$proj_folder")
      
      if [[ -z "$default_branch" ]]; then
        print " could not determine default branch for project: $proj_arg" >&2
        print " run ${yellow_cor}co $branch <default_branch>${reset_cor} to create a new branch" >&2
        return 1;
      fi

      co "$branch" "$default_branch"
      RET=$?
    fi

  else
    clone "$proj_arg" "$jira_key"
    RET=$?
  fi

  jira -p "$proj_arg" "$jira_key"

  return $RET;
}

function abort() {
  set +x
  eval "$(parse_flags_ "abort_" "" "" "$@")"
  (( abort_is_d )) && set -x

  if (( abort_is_h )); then
    print "  ${yellow_cor}abort ${solid_yellow_cor}[<folder>]${reset_cor} : to abort any in progress rebase, merge and cherry-pick"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

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
  eval "$(parse_flags_ "renb_" "r" "" "$@")"
  (( renb_is_d )) && set -x

  if (( renb_is_h )); then
    print "  ${yellow_cor}renb <new_branch_name>${reset_cor} : to rename current branch locally"
    print "  ${yellow_cor}renb -r${reset_cor} : to also rename current branch remotelly"
    return 0;
  fi

  local new_name="$1"

  if [[ -z "$new_name" ]]; then
    print " fatal: branch argument is required" >&2
    print " run ${yellow_cor}renb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

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
  eval "$(parse_flags_ "chp_" "" "s" "$@")"
  (( chp_is_d )) && set -x

  if (( chp_is_h )); then
    print "  ${yellow_cor}chp <commit_hash> ${solid_yellow_cor}[<folder>]${reset_cor} : to cherry-pick a commit"
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

  if ! is_git_repo_ "$folder"; then return 1; fi
  
  git -C "$folder" cherry-pick "$hash_arg" ${@:2}
}

function chc() {
  set +x
  eval "$(parse_flags_ "chc_" "" "s" "$@")"
  (( chc_is_d )) && set -x

  if (( chc_is_h )); then
    print "  ${yellow_cor}chc ${solid_yellow_cor}[<folder>]${reset_cor} : to continue in progress cherry-pick"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null
}

function mc() {
  set +x
  eval "$(parse_flags_ "mc_" "" "" "$@")"
  (( mc_is_d )) && set -x

  if (( mc_is_h )); then
    print "  ${yellow_cor}mc ${solid_yellow_cor}[<folder>]${reset_cor} : to continue in progress merge"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" add .
  local RET=$?

  if (( RET == 0 )); then
    GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null
    RET=$?
  fi

  return $RET;
}

function rc() {
  set +x
  eval "$(parse_flags_ "rc_" "" "" "$@")"
  (( rc_is_d )) && set -x

  if (( rc_is_h )); then
    print "  ${yellow_cor}rc ${solid_yellow_cor}[<folder>]${reset_cor} : to continue in progress rebase"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" add .
  local RET=$?

  if (( RET == 0 )); then
    GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null
    RET=$?
  fi

  return $RET;
}

function cont() {
  set +x
  eval "$(parse_flags_ "cont_" "" "" "$@")"
  (( conti_is_d )) && set -x

  if (( conti_is_h )); then
    print "  ${yellow_cor}cont ${solid_yellow_cor}[<folder>]${reset_cor} : to continue any in progress rebase, merge or cherry-pick"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" add .
  local RET=$?

  if (( RET == 0 )); then
    if ! GIT_EDITOR=true git -C "$folder" rebase --continue $@ &>/dev/null; then
      if ! GIT_EDITOR=true git -C "$folder" merge --continue $@ &>/dev/null; then
        if ! GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null; then
          return 1;
        fi
      fi
    fi
  fi

  return $RET;
}

function reset1() {
  set +x
  eval "$(parse_flags_ "reset1_" "" "" "$@")"
  (( reset1_is_d )) && set -x

  if (( reset1_is_h )); then
    print "  ${yellow_cor}reset1${reset_cor} : to reset last commit"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git --no-pager log -1 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~1 $@
}

function reset2() {
  set +x
  eval "$(parse_flags_ "reset2_" "" "" "$@")"
  (( reset2_is_d )) && set -x

  if (( reset2_is_h )); then
    print "  ${yellow_cor}reset2${reset_cor} : to reset 2 last commits"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git --no-pager log -2 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~2 $@
}

function reset3() {
  set +x
  eval "$(parse_flags_ "reset3_" "" "" "$@")"
  (( reset3_is_d )) && set -x

  if (( reset3_is_h )); then
    print "  ${yellow_cor}reset3${reset_cor} : to reset 3 last commits"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git --no-pager log -3 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~3 $@
}

function reset4() {
  set +x
  eval "$(parse_flags_ "reset4_" "" "" "$@")"
  (( reset4_is_d )) && set -x

  if (( reset4_is_h )); then
    print "  ${yellow_cor}reset4${reset_cor} : to reset 4 last commits"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git --no-pager log -4 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~4 $@
}

function reset5() {
  set +x
  eval "$(parse_flags_ "reset5_" "" "" "$@")"
  (( reset5_is_d )) && set -x

  if (( reset5_is_h )); then
    print "  ${yellow_cor}reset5${reset_cor} : to reset 5 last commits"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git --no-pager log -5 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~5 $@
}

function repush() {
  set +x
  eval "$(parse_flags_ "repush_" "x" "" "$@")"
  (( repush_is_d )) && set -x

  if (( repush_is_h )); then
    print "  ${yellow_cor}repush${reset_cor} : to reset last commit without losing your changes then re-push all changes using the same message"
    print "  ${yellow_cor}repush -x${reset_cor} : only staged changes"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if (( repush_is_x )); then
    if ! recommit -s --quiet 1>/dev/null; then return 1; fi
  else
    if ! recommit --quiet 1>/dev/null; then return 1; fi
  fi
  
  pushf $@
}

function recommit() {
  set +x
  eval "$(parse_flags_ "recommit_" "xsq" "sq" "$@")"
  (( recommit_is_d )) && set -x

  if (( recommit_is_h )); then
    print "  ${yellow_cor}recommit${reset_cor} : to reset last commit then re-commit all changes with the same message"
    print "  ${yellow_cor}recommit -x${reset_cor} : only staged changes"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -z "$git_status" ]]; then
    print " nothing to do, working tree clean" >&2
    return 1;
  fi

  local last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0 2>/dev/null)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " cannot recommit, last commit is a merge commit" >&2
    return 1;
  fi

  local qty_staged_files=0
  local qty_unstaged_files=0

  if (( recommit_is_x )); then
    qty_staged_files=$(git diff --cached --name-only | wc -l)
    if (( qty_staged_files == 0 )); then
      print " nothing to recommit, no staged changes" >&2
      return 1;
    else
      if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi
    fi
  else
    qty_unstaged_files=$(git diff --name-only | wc -l)
    if (( qty_unstaged_files > 1 )); then
      if [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
        confirm_ "include all unstaged changes to commit \"${blue_prompt_cor}$last_commit_msg${reset_prompt_cor}\"?"
        if (( $? == 130 || $? == 2 )); then return 130; fi
        if (( $? == 0 )); then
          if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi

          if git add . && confirm_ "save this preference and don't ask again?" "save" "ask again"; then
            local i=0
            for i in {1..9}; do
              if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
                update_setting_ $i "PUMP_COMMIT_ADD" 1 &>/dev/null
                break;
              fi
            done
            print ""
          fi
        else
          qty_staged_files=$(git diff --cached --name-only | wc -l)
          if (( qty_staged_files == 0 )); then
            print " nothing to recommit, no staged changes" >&2
            return 1;
          fi
        fi
      elif (( CURRENT_PUMP_COMMIT_ADD )); then
        if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi
        git add .
      fi
    else
      if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi
      git add .
    fi
  fi

  if git commit --message="$last_commit_msg" $@; then
    if (( ! ${argv[(Ie)--quiet]} )); then
      print ""
      git --no-pager log -1 --oneline
      # no pbcopy
    fi
  fi
}

function fetch() {
  set +x
  eval "$(parse_flags_ "fetch_" "to" "pqn" "$@")"
  # (( fetch_is_d )) && set -x

  if (( fetch_is_h )); then
    print "  ${yellow_cor}fetch ${solid_yellow_cor}[folder]${reset_cor} : to fetch and prune from origin all branches and tags"
    print "  ${yellow_cor}fetch -t${reset_cor} : to force fetch"
    print "  ${yellow_cor}fetch -to${reset_cor} : to fetch all tags only"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  local RET=0

  if (( fetch_is_t )); then 
    git -C "$folder" fetch --all --tags --prune-tags --force $@
    RET=$?
    if (( fetch_is_o )); then return $RET; fi
  fi

  local remote_name=$(get_remote_origin_ "$folder")
  local results=""
  results="$(git -C "$folder" fetch $remote_name --prune $@ 2>&1 | tee /dev/tty)"
  RET=$?

  if [[ -n "$results" ]]; then
    local current_branches=$(git -C "$folder" branch --format '%(refname:short)')

    for config in $(git -C "$folder" config --get-regexp "^branch\." | awk '{print $1}'); do
      local branch_name="${config#branch.}"

      if ! echo "$current_branches" | grep -q "^${branch_name}$"; then
        git -C "$folder" config --remove-section "branch.${branch_name}" &>/dev/null
      fi
    done

    print $results
  fi

  return $RET;
}

function gconf() {
  set +x
  eval "$(parse_flags_ "gconf_" "ac" "" "$@")"
  (( gconf_is_d )) && set -x

  if (( gconf_is_h )); then
    print "  ${yellow_cor}gconf ${solid_yellow_cor}[<scope>] [<folder>]${reset_cor} : to display git configuration"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  echo "${yellow_cor}== ${scope_arg} config ==${reset_cor}"

  git config --${scope_arg} --list 2>/dev/null | sort | while IFS='=' read -r key value; do
    printf "  ${cyan_cor}%-40s${reset_cor} = ${green_cor}%s${reset_cor}\n" "$key" "$value"
  done
  
  print ""
}

function glog() {
  set +x
  eval "$(parse_flags_ "glog_" "ac" "" "$@")"
  (( glog_is_d )) && set -x

  if (( glog_is_h )); then
    print "  ${yellow_cor}glog ${solid_yellow_cor}[<folder>]${reset_cor} : to log last 10 commits"
    print "  ${yellow_cor}glog -c ${solid_yellow_cor}[<branch>]${reset_cor} : to log branch's commits since default branch"
    print "  ${yellow_cor}glog -a ${solid_yellow_cor}[<branch>]${reset_cor} : to log all commits"
    print "  ${yellow_cor}glog -n ${solid_yellow_cor}[<folder>]${reset_cor} : to log n commits, where n is a number"
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
      print " run ${yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      if [[ ! $1 =~ '^[0-9]+$' ]]; then
        branch_arg="$1"
      fi
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]] && [[ ! $1 =~ '^[0-9]+$' ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_git_repo_ "$folder"; then return 1; fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
  fi

  local default_branch=$(get_default_branch_ "$folder" 2>/dev/null)
  local remote_name=$(get_remote_origin_ "$folder")

  if (( glog_is_c )); then
    if (( glog_is_a )); then
      git -C "$folder" --no-pager log $branch_arg HEAD --oneline --graph --date=relative --no-decorate $@
    else
      if [[ -n "$default_branch" && -n "$branch_arg" && "$default_branch" != "$branch_arg" ]]; then
        git -C "$folder" --no-pager log --no-merges --oneline "${default_branch}..${branch_arg}" --no-decorate $@
      fi
    fi
    return $?;
  fi

  if (( glog_is_a )); then
    git -C "$folder" --no-pager log $branch_arg HEAD --oneline --graph --date=relative $@
  else
    git -C "$folder" --no-pager log $branch_arg HEAD --oneline --graph --date=relative -n 10 $@
  fi
}

function push() {
  set +x
  eval "$(parse_flags_ "push_" "tfu" "qn" "$@")" # do not pass flags because we want the user to pass any flags
  (( push_is_d )) && set -x

  if (( push_is_h )); then
    print "  ${yellow_cor}push ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to push --no-verify --set-upstream"
    print "  ${yellow_cor}push -f${reset_cor} : to push --no-verify --force-with-lease"
    print "  ${yellow_cor}push -t${reset_cor} : to push --no-verify --tags --force"
    print "  ${yellow_cor}push -tf${reset_cor} : to push --no-verify --tags"
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
    else
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}push -h${reset_cor} to see usage" >&2
      return 1;
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " current branch is detached, cannot push" >&2
      return 1;
    fi
  fi

  fetch "$folder" --quiet

  if (( push_is_t && push_is_f )); then
    git -C "$folder" push --no-verify --tags --force
    return $?;
  fi

  if (( push_is_t )); then
    git -C "$folder" push --no-verify --tags
    return $?;
  fi

  if (( push_is_f )); then
    pushf "$folder" "$branch_arg"
    return $?;
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  git -C "$folder" push --no-verify --set-upstream $remote_name $branch_arg
  local RET=$?

  if (( RET != 0 && quiet == 0 )); then
    if confirm_ "failed, try push force with lease?"; then
      pushf "$branch_arg" "$folder"
      return $?;
    fi
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    print ""
    glog -ca "$branch_arg" "$folder" -1
    # no pbcopy
  fi

  return $RET;
}

function pushf() {
  set +x
  eval "$(parse_flags_ "pushf_" "tf" "qn" "$@")"
  (( pushf_is_d )) && set -x

  if (( pushf_is_h )); then
    print "  ${yellow_cor}pushf ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to push --no-verify --force-with-lease"
    print "  ${yellow_cor}pushf -f${reset_cor} : to push --no-verify --force"
    print "  ${yellow_cor}pushf -t${reset_cor} : to push --no-verify --tags"
    print "  ${yellow_cor}pushf -tf${reset_cor} : to push --no-verify --tags --force"
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
    else
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}pushf -h${reset_cor} to see usage" >&2
      return 1;
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg=$(git -C "$folder" branch --show-current)
    if [[ -z "$branch_arg" ]]; then
      print " branch is detached or not tracking a remote branch, cannot force push" >&2
      return 1;
    fi
  fi

  local RET=0

  if (( pushf_is_t )); then
    if (( pushf_is_t && pushf_is_f )); then
      git -C "$folder" push --no-verify --tags --force $@
      RET=$?
    else
      git -C "$folder" push --no-verify --tags $@
      RET=$?
    fi

    return $RET;
  fi

  local remote_name=$(get_remote_origin_ "$folder")

  if (( pushf_is_f )); then
    git -C "$folder" push --no-verify --force $remote_name $branch_arg $@
    RET=$?
  else
    git -C "$folder" push --no-verify --force-with-lease $remote_name $branch_arg $@
    RET=$?
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    print ""
    glog -ca "$branch_arg" "$folder" -1
    # no pbcopy
  fi

  return $RET;
}

function pullr() {
  set +x
  eval "$(parse_flags_ "pullr_" "" "pqf" "$@")"
  (( pullr_is_d )) && set -x

  if (( pullr_is_h )); then
    print "  ${yellow_cor}pullr ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to pull --rebase"
    return 0;
  fi

  pull -r $@
}

function pull() {
  set +x
  eval "$(parse_flags_ "pull_" "tor" "pqf" "$@")"
  (( pull_is_d )) && set -x

  if (( pull_is_h )); then
    print "  ${yellow_cor}pull ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to pull branch from origin"
    print "  ${yellow_cor}pull -t${reset_cor} : to pull tags along with branches"
    print "  ${yellow_cor}pull -to${reset_cor} : to pull tags only"
    print "  ${yellow_cor}pull -r${reset_cor} : to pull --rebase"
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
    else
      print " fatal: not a valid branch argument" >&2
      print " run ${yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  local remote_name=$(get_remote_origin_ "$folder")

  if ! git -C "$folder" fetch $remote_name $branch_arg $@; then
    return 1;
  fi

  local RET=0
  local is_quiet=$( (( ${argv[(Ie)--quiet]} || pull_is_q )) && echo 1 || echo 0)

  if (( pull_is_t )); then
    git -C "$folder" pull $remote_name $branch_arg --tags $@
    RET=$?
    if (( pull_is_o )); then return $RET; fi
  fi

  git -C "$folder" pull $remote_name $branch_arg $@ 2>/dev/null
  RET=$?
  if (( RET != 0 )); then
    if (( ! pull_is_r && ! is_quiet )); then
      confirm_ "pull failed, try pull --rebase?"
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 1; fi
      if (( _RET == 0 )); then
        pull_is_r=1
      fi
    fi

    if (( is_quiet )); then
      RET=0
    fi

    if (( pull_is_r )); then
      git -C "$folder" pull $remote_name $branch_arg --rebase $@ 2>/dev/null
      RET=$?
      if (( RET != 0 )); then
        git -C "$folder" pull $remote_name $branch_arg --rebase --autostash $@
        RET=$?
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    print ""
    glog -ca "$branch_arg" "$folder" -1
    # no pbcopy
  fi

  return $RET
}

function dtag() {
  set +x
  eval "$(parse_flags_ "dtag_" "" "q" "$@")"
  (( dtag_is_d )) && set -x

  if (( dtag_is_h )); then
    print "  ${yellow_cor}dtag ${solid_yellow_cor}<pro>${reset_cor} : to delete a project's tag"
    print "  ${yellow_cor}dtag ${solid_yellow_cor}<name>${reset_cor} : to delete a tag directly"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local tag=""

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}dtag -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$proj_folder" ]]; then return 1; fi
  
  prune "$proj_folder"

  local remote_name="$(get_remote_origin_ "$proj_folder")"

  if [[ -z "$tag" ]]; then
    # list all tags suing tags command then use choose_multiple_ to select tags, then delete all selected tags
    local tags=$(tags "$proj_arg" 2>/dev/null)
    
    if [[ -z "$tags" ]]; then
      print " no tags found to delete"
      return 0;
    fi

    local selected_tags=($(choose_multiple_ "tags to delete" $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then return 1; fi

    for tag in "$selected_tags"; do
      git -C "$proj_folder" tag "$remote_name" --delete "$tag" 2>/dev/null
      git -C "$proj_folder" push "$remote_name" --delete "$tag" 2>/dev/null
    done

    return 0;
  fi

  git -C "$proj_folder" tag "$remote_name" --delete "$tag" 2>/dev/null
  git -C "$proj_folder" push "$remote_name" --delete "$tag" 2>/dev/null

  return 0; # don't care if it fails to delete, consider success
}

# tagging functions ===============================================
function drelease() {
  set +x
  eval "$(parse_flags_ "drelease_" "" "" "$@")"
  (( drelease_is_d )) && set -x

  if (( drelease_is_h )); then
    print "  ${yellow_cor}drelease ${solid_yellow_cor}<pro>${reset_cor} : to delete a project's release and the tag"
    print "  ${yellow_cor}drelease ${solid_yellow_cor}<tag>${reset_cor} : to delete a project's release and the tag directly"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: drelease requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local tag=""

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}drelease -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if [[ -z "$tag" ]]; then
    local tags=$(tags "$proj_arg" 2>/dev/null)
    if [[ -z "$tags" ]]; then
      print " no tags found to delete"
      return 0;
    fi

    local selected_tags=($(choose_multiple_ "tags to delete" $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then return 1; fi

    local _pwd="$(pwd)"

    add-zsh-hook -d chpwd pump_chpwd_
    cd "$proj_folder"

    for tag in "${selected_tags[@]}"; do
      if command -v gum &>/dev/null; then
        if ! gum spin --title="deleting... $tag" -- gh release delete "$tag" --cleanup-tag -y; then
          dtag "$proj_arg" "$tag" &>/dev/null
        fi
      else
        print " deleting... $tag"
        if ! gh release delete "$tag" --cleanup-tag -y; then
          dtag "$proj_arg" "$tag" &>/dev/null
        fi
      fi
      print " ${magenta_cor}deleted${reset_cor} $tag"
    done
    
    cd "$_pwd"
    add-zsh-hook chpwd pump_chpwd_
    return 0;
  fi

  local _pwd="$(pwd)"

  add-zsh-hook -d chpwd pump_chpwd_
  cd "$proj_folder"

  gh release delete "$tag" --cleanup-tag -y

  cd "$_pwd"
  add-zsh-hook chpwd pump_chpwd_

  return 0; # don't care if it fails to delete, consider success
}

function release() {
  set +x
  eval "$(parse_flags_ "release_" "mnps" "" "$@")"
  (( release_is_d )) && set -x

  if (( release_is_h )); then
    print "  ${yellow_cor}release ${solid_yellow_cor}<pro>${reset_cor} : to create a new release of package.json version"
    print "  ${yellow_cor}release ${solid_yellow_cor}<version>${reset_cor} : to create a new release, version format: <major>.<minor>.<patch> i.e: 1.0.0"
    print "  ${yellow_cor}release -s${reset_cor} : to skip confirmation"
    print "  --"
    print "  ${yellow_cor}release -m${reset_cor} : to bump the major version by 1 and create a release"
    print "  ${yellow_cor}release -n${reset_cor} : to bump the minor version by 1 and create a release"
    print "  ${yellow_cor}release -p${reset_cor} : to bump the patch version by 1 and create a release"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: release requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local tag=""

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}release -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if ! is_proj_folder_ "$proj_folder"; then return 1; fi

  local my_branch="$(git -C "$proj_folder" branch --show-current)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot create release" >&2
    return 1;
  fi

  if [[ -n "$(git -C "$proj_folder" status --porcelain)" ]]; then
    print " uncommitted changes detected, cannot create release" >&2
    st "$proj_folder"
    return 1;
  fi

  # check if name is conventional
  if ! [[ "$my_branch" =~ ^(main|master|stage|staging|prod|production|release)$ || "$my_branch" == release* ]]; then
    print " ${yellow_cor}warning: unconventional branch to release: $my_branch ${yellow_cor}"
  fi

  if [[ -z "$tag" ]]; then
    if command -v npm &>/dev/null; then
      local release_type=""
      if (( release_is_m )); then
        release_type="major"
      elif (( release_is_n )); then
        release_type="minor"
      elif (( release_is_p )); then
        release_type="patch"
      fi

      if ! pull "$proj_folder" --quiet; then return 1; fi

      local _pwd="$(pwd)"
      add-zsh-hook -d chpwd pump_chpwd_
      cd "$proj_folder"

      if [[ -n "$release_type" ]]; then
        if ! npm version "$release_type" --no-commit-hooks --no-git-tag-version &>/dev/null; then
          print " fatal: not able to bump version: $release_type" >&2

          cd "$_pwd"
          add-zsh-hook chpwd pump_chpwd_
          return 1;
        fi
      fi

      tag="$(npm pkg get version --workspaces=false | tr -d '"' 2>/dev/null)"
      
      cd "$_pwd"
      add-zsh-hook chpwd pump_chpwd_
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
      print " please provide a version or tag name" >&2
      return 1;
    fi
  else
    if [[ "$tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
      tag="${tag#v}"
    fi

    if [[ "$tag" =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
      IFS='.' read -r major_version minor_version patch_version <<< "$tag"

      if (( release_is_is_m )); then
        ((major_version++))
        minor_version=0
        patch_version=0
      elif (( release_is_is_n )); then
        ((minor_version++))
        patch_version=0
      else
        ((patch_version++))
      fi

      tag="${major_version}.${minor_version}.${patch_version}"
    fi
  fi

  if (( ! release_is_s )); then
    if ! confirm_ "create a new release for $proj_arg: $tag ?"; then
      clean "$proj_folder"
      return 1;
    fi
  fi

  # check of git status is dirty
  local git_status=$(git -C "$proj_folder" status --porcelain 2>/dev/null)
  if [[ -n "$git_status" ]]; then
    if ! git -C "$proj_folder" add .; then return 1; fi
    if ! git -C "$proj_folder" commit --no-verify --message="chore: release version $tag"; then return 1; fi
  fi

  local _pwd="$(pwd)"
  add-zsh-hook -d chpwd pump_chpwd_
  cd "$proj_folder"

  if gh release view "$tag" 1>/dev/null 2>&1; then
    if (( ! release_is_s )); then
      if ! confirm_ "$tag has already been released, delete and release again?"; then
        cd "$_pwd"
        add-zsh-hook chpwd pump_chpwd_
        return 1;
      fi
    fi
    release_is_s=1
    gh release delete "$tag" --yes
  fi

  cd "$_pwd"
  add-zsh-hook chpwd pump_chpwd_

  # check if tag already exists
  local existing_tag="$(git -C "$proj_folder" tag --list "$tag" 2>/dev/null)"
  if [[ -n "$existing_tag" ]]; then
    if (( ! release_is_s )); then
      if ! confirm_ "$tag already exists, delete and release again?"; then
        return 1;
      fi
    fi
    if ! dtag "$proj_arg" "$tag" --quiet; then return 1; fi
  fi

  if ! tag "$proj_arg" "$tag"; then return 1; fi
  if ! push "$proj_folder" --tags --quiet; then return 1; fi

  local _pwd="$(pwd)"
  add-zsh-hook -d chpwd pump_chpwd_
  cd "$proj_folder"

  gh release create "$tag" --title="$tag" --generate-notes
  local RET=$?

  print ""
  glog -ca -1

  cd "$_pwd"
  add-zsh-hook chpwd pump_chpwd_

  return $RET;
}

function tag() {
  set +x
  eval "$(parse_flags_ "tag_" "" "" "$@")"
  (( tag_is_d )) && set -x

  if (( tag_is_h )); then
    print " release_ = ${yellow_cor}tag ${solid_yellow_cor}<pro>${reset_cor} : to create a new tag for a project"
    print " release_ = ${yellow_cor}tag ${solid_yellow_cor}<name>${reset_cor} : to create a new tag directly"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local tag=""

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 != -* ]]; then
      tag="$2"
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    tag="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}tag -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  if ! is_proj_folder_ "$proj_folder"; then return 1; fi
  
  prune "$proj_folder" &>/dev/null

  # print " ${yellow_cor}tagging project:${reset_cor} $proj_arg"
  # print " ${yellow_cor}tagging folder:${reset_cor} $proj_folder"
  # print " ${yellow_cor}tagging name:${reset_cor} $tag"

  if [[ -z "$tag" ]]; then
    tag=$(get_from_pkg_json_ "version" "$proj_folder")
    if [[ -n "$tag" ]]; then
      if ! confirm_ "create tag: $tag ?"; then
        tag=""
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    tag=$(input_path_ "tag name")
    if [[ -z "$tag" ]]; then return 1; fi

    print " ${purple_cor}tag name:${reset_cor} $tag"
  fi

  git -C "$proj_folder" tag --annotate "$tag" --message="$tag"
  
  if (( $? == 0 )); then
    git -C "$proj_folder" push --no-verify --tags
    return $?;
  fi

  return 1;
}

function tags() {
  set +x
  eval "$(parse_flags_ "tags_" "" "" "$@")"
  (( tags_is_d )) && set -x

  if (( tags_is_h )); then
    print "  ${yellow_cor}tags ${solid_yellow_cor}<pro>${reset_cor} : to list all tags of a project"
    print "  ${yellow_cor}tags ${solid_yellow_cor}<x>${reset_cor} : to list x number of tags of a project"
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local n=100

  if is_project_ "$1"; then
    proj_arg="$1"
    if [[ -n "$2" && $2 == <-> ]]; then
      n="$2"
    fi
  elif [[ -n "$1" && $1 == <-> ]]; then
    n="$1"
  fi
  
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print "  ${yellow_cor}tags -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi
  
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  prune "$proj_folder" &>/dev/null

  local tags=""

  if (( n == 1 )); then
    tags=$(git -C "$proj_folder" describe --tags --abbrev=0 2>/dev/null)
  fi

  if [[ -z "$tags" ]]; then
    tags=$(git -C "$proj_folder" for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)' --count="$n")
  fi

  if [[ -z "$tags" ]]; then
    tags=$(git -C "$proj_folder" for-each-ref refs/tags --sort=-creatordate --format='%(refname:short)' --count="$n")
  fi

  if [[ -z "$tags" ]]; then
    print " no tags found" >&2
    return 1;
  fi
  
  print "$tags"
}
# end of tagging functions ===============================================

function print_clean_() {
  print "  ${yellow_cor}softest${reset_cor} : $(clean -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/  :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${orange_cor}softer${reset_cor}  : $(restore -hq | sed 's/\[\<folder\>\]//g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${dark_orange_cor}medium${reset_cor}  : $(discard -hq | sed 's/\[\<folder\>\]//g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
  print "  ${bright_red_cor}hard${reset_cor}    : $(reseta -hq | sed 's/\[\<folder\>\]//g' | sed 's/:/ :/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -n 1)"
}

function restore() {
  set +x
  eval "$(parse_flags_ "restore_" "q" "q" "$@")"
  (( restore_is_d )) && set -x

  if (( restore_is_h )); then
    print "  ${yellow_cor}restore ${solid_yellow_cor}[<folder>]${reset_cor} : to clean staged changes"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" restore --quiet .
}

function clean() {
  set +x
  eval "$(parse_flags_ "clean_" "q" "q" "$@")"
  (( clean_is_d )) && set -x

  if (( clean_is_h )); then
    print "  ${yellow_cor}clean ${solid_yellow_cor}[<folder>]${reset_cor} : to clean unstaged changes"
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

  if ! is_git_repo_ "$folder"; then return 1; fi
  
  git -C "$folder" clean -fd --quiet
}

function discard() {
  set +x
  eval "$(parse_flags_ "discard_" "q" "q" "$@")"
  (( discard_is_d )) && set -x

  if (( discard_is_h )); then
    print "  ${yellow_cor}discard ${solid_yellow_cor}[<folder>]${reset_cor} : to clean staged and unstaged changes (clean + restore)"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" reset HEAD .
  clean "$folder"
  restore "$folder"
}

function reseta() {
  set +x
  eval "$(parse_flags_ "reseta_" "oq" "q" "$@")"
  (( reseta_is_d )) && set -x

  if (( reseta_is_h )); then
    print "  ${yellow_cor}reseta ${solid_yellow_cor}[<folder>]${reset_cor} : to erase everything and match HEAD to latest commit of current branch"
    print "  ${yellow_cor}reseta -o${solid_yellow_cor}[<folder>]${reset_cor} : to erase everything and match HEAD to origin"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

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
  eval "$(parse_flags_ "glr_" "" "" "$@")"
  (( glr_is_d )) && set -x

  if (( glr_is_h )); then
    print "  ${yellow_cor}glr ${solid_yellow_cor}[<folder>]${reset_cor} : to list remote branches"
    print "  ${yellow_cor}glr <branch> ${solid_yellow_cor}[<folder>]${reset_cor} : to list remote branches matching branch"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  fetch "$folder" --quiet

  local link=""
  local repo=$(get_repo_ "$folder")
  
  if [[ -n "$repo" ]]; then
    local repo_name=$(get_repo_name_ "$repo" 2>/dev/null)
    link="https://github.com/$repo_name/tree/"
  fi

  gum spin --title="loading..." -- git -C "$folder" branch -r --list "*$branch_arg*" --sort=authordate \
    --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' \
    | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e "s/\([^\ ]*\)$/\x1b[34m\x1b]8;;${link//\//\\/}\1\x1b\\\\\1\x1b]8;;\x1b\\\\\x1b[0m/"
}

function gll() {
  set +x
  eval "$(parse_flags_ "gll_" "" "" "$@")"
  (( gll_is_d )) && set -x

  if (( gll_is_h )); then
    print "  ${yellow_cor}gll ${solid_yellow_cor}[<folder>]${reset_cor} : to list local branches"
    print "  ${yellow_cor}gll <branch> ${solid_yellow_cor}[<folder>]${reset_cor} : to list local branches matching <branch>"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" branch --list "*$branch_arg*" --sort=authordate \
    --format="%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=2)" \
    | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'
}

function gha_() {
  local workflow="$1"
  local msg="${2:-checking workflow status...}"

  local url="$(gum spin --title="$msg" -- gh run list --workflow="${workflow}" --limit 1 --json url --jq '.[0].url')"
  local workflow_status="$(gum spin --title="$msg" -- gh run list --workflow="${workflow}" --limit 1 --json conclusion --jq '.[0].conclusion')"
  local workflow_status="$(gum spin --title="$msg" -- gh run list --workflow="${workflow}" --limit 1 --json conclusion --jq '.[0].conclusion')"

  if [[ -z "$workflow_status" ]]; then
    print " ⏳ ${gray_cor}workflow is running! $workflow ${reset_cor}" >&2
    return 0; # this nust be zero for auto mode
  fi

  # Output status with emoji
  if [[ "$workflow_status" == "success" ]]; then
    print -n " ✅ ${green_cor}workflow passed! $workflow ${reset_cor}"
  else
    print -n "\a ❌ ${red_cor}workflow failed! $workflow (status: $workflow_status) ${reset_cor}"
  fi
  
  if [[ -n "$url" ]]; then
    print ": ${blue_cor} $url ${reset_cor}"
  else
    print ""
  fi
  
  return 0;
}

function gha() {
  set +x
  eval "$(parse_flags_ "gha_" "a" "" "$@")"
  (( gha_is_d )) && set -x

  if (( gha_is_h )); then
    print "  ${yellow_cor}gha${reset_cor} : to check status of a workflow in current project"
    print "  ${yellow_cor}gha ${solid_yellow_cor}<workflow>${reset_cor} : to check status of a given workflow in current project"
    print "  ${yellow_cor}gha <pro> ${solid_yellow_cor}<workflow>${reset_cor} : to check status of a given workflow for a project"
    print "  ${yellow_cor}gha -a${reset_cor} : to run in auto mode"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " fatal: gha requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local workflow_arg=""
  local proj_arg=""

  # Parse arguments
  if [[ -n "$2" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
      workflow_arg="$2"
    else
      workflow_arg="$1"
    fi
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    else
      workflow_arg="$1"
    fi
  fi

  local proj_folder=""
  local proj_repo=""
  local gha_interval=""
  local gha_workflow=""
  local found=0

  if [[ -n "$proj_arg" ]]; then
    local i=$(find_proj_index_ -o "$proj_arg")
    if (( ! i )); then
      print " run ${yellow_cor}gha -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"
    found=$i;

    if ! check_proj_ -fr $i; then return 1; fi
    
    proj_folder=$(get_proj_for_git_ "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg")
    if [[ -z "$proj_folder" ]]; then return 1; fi

    proj_repo="${PUMP_PROJ_REPO[$i]}"

    gha_interval="${PUMP_GHA_INTERVAL[$i]}"
    gha_workflow="${PUMP_GHA_WORKFLOW[$i]}"
  else
    if ! is_git_repo_; then return 1; fi

    proj_folder="$(pwd)"
    local remote_name=$(get_remote_origin_)
    proj_repo=$(git remote get-url $remote_name)
  fi

  local ask_save=0
  local RET=0

  cd "$proj_folder"

  if [[ -z "$workflow_arg" && -z "$gha_workflow" ]]; then
    local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
    local workflow_choices=$(gh workflow list --repo "$repo_name" | cut -f1)
    
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      print " fatal: no workflows found" >&2
      return 1;
    fi
    
    workflow_arg=$(gh workflow list | cut -f1 | sort -fu | gum choose --header=" choose workflow:" --height=15)
    if [[ -z "$workflow_arg" ]]; then
      return 1;
    fi

    ask_save=1
  elif [[ -n "$workflow_arg" ]]; then
    ask_save=0
  elif [[ -n "$gha_workflow" ]]; then
    workflow_arg="$gha_workflow"
    ask_save=0    
  fi

  if [[ -z "$gha_interval" || "$gha_interval" != <-> ]]; then
    gha_interval=10
  fi

  while true; do
    gha_ "$workflow_arg"
    RET=$?

    if (( RET != 0 || gha_is_a == 0 )); then
      break;
    fi
    
    print ""
    print " sleeping for $gha_interval minutes..."
    sleep $(($gha_interval * 60))
  done

  if (( RET == 0 && found && ask_save && gha_is_a == 0 )); then
    # ask to save the workflow
    if confirm_ "save \"$workflow_arg\" as the default workflow for this project?"; then
      update_setting_ $found "PUMP_GHA_WORKFLOW" "\"$workflow_arg\"" &>/dev/null
    fi
  fi

  return $RET;
}

# function is_branch_() {
#   set +x
#   eval "$(parse_flags_ "is_branch_" "alr" "" "$@")"
#   (( abort_is_d )) && set -x

#   local branch="$1"
#   local folder="${2:-$PWD}"

#   # check if branch exists locally
#   if git show-ref --verify --quiet "refs/heads/$branch"; then
#     return 0;
#   fi

#   # check if it exists remotely (on origin)
#   if git ls-remote --heads origin "$branch" --exit-code | grep -q "$branch"; then
#     return 0;
#   fi
  
#   return 1; # not a branch
# }

function co() {
  set +x
  eval "$(parse_flags_ "co_" "alprexbcqm" "" "$@")"
  (( co_is_d )) && set -x

  if (( co_is_h )); then
    print "  ${yellow_cor}co${reset_cor} : to switch to a branch"
    print "  --"
    print "  ${yellow_cor}co -a${reset_cor} : to list all branches (default)"
    print "  ${yellow_cor}co -l${reset_cor} : to list only local branches"
    print "  ${yellow_cor}co -pr${reset_cor} : to list pull requests instead (for quick code reviews)"
    print "  --"
    print "  ${yellow_cor}co -m${reset_cor} : to switch to default branch"
    print "  ${yellow_cor}co -e <branch>${reset_cor} : to switch to an exact branch, no lookup"
    print "  ${yellow_cor}co -b <branch> ${reset_cor} : to create branch off of current branch"
    print "  ${yellow_cor}co <branch> <base_branch>${reset_cor} : to create branch off of a base branch"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " fatal: co requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local proj_arg="$CURRENT_PUMP_PROJ_SHORT_NAME"
  local proj_folder="$PWD"

  if ! is_git_repo_; then; return 1; fi

  local RET=0

  # co -pr checkout by pull request
  if (( co_is_p && co_is_r )); then
    local pr=("${(@s:|:)$(select_pr_ "$1" "$proj_folder" "$proj_arg")}")
    if [[ -z "$pr" ]]; then return 1; fi
    
    gum spin --title="detaching pull request: ${pr[3]}" -- \
      gh pr checkout --force --detach "${pr[1]}"
    RET=$?

    if (( RET == 0 )); then
      local default_branch=$(get_default_branch_ "$proj_folder" 2>/dev/null)

      print " succeed detached pull request: ${green_cor}${pr[3]}${reset_cor}"
      print " HEAD is now at $(git log -1 --pretty=format:'%h %s')"
      print " your branch is detached, you may now run:"
      print " run ${yellow_cor}co ${pr[2]}${reset_cor} to switch to the branch"
      if [[ -n "$default_branch" ]]; then
        print " run ${yellow_cor}co ${${USER:0:1}:l}-${pr[2]} ${default_branch}${reset_cor} to create branch off of a base branch"
      fi
    fi

    return $RET;
  fi

  if (( co_is_p || co_is_r )); then
    print " ${red_cor}fatal: invalid option${reset_cor}" >&2
    print " run ${yellow_cor}co -pr${reset_cor} to select from pull requests instead of branches and detach HEAD"

    return 1;
  fi

  # co -a all branches
  if (( co_is_a )); then
    local branch_arg=""
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    local current_branch=$(git branch --show-current)
    local branch_choice="$(select_branch_ -at "$branch_arg" "branch" "$PWD" "$current_branch")"
    if [[ -z "$branch_choice" ]]; then return 1; fi

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

    local branch_choice=""
    # 2>/dev/null because we call co -a later
    local current_branch=$(git branch --show-current)
    branch_choice="$(select_branch_ -lt "$branch_arg" "branch" "$PWD" "$current_branch" 2>/dev/null)"
    if (( $? == 130 )); then return 1; fi
    
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
    local default_branch=$(get_default_branch_)
    if [[ -z "$default_branch" ]]; then
      print " fatal: cannot determine default branch" >&2
      return 1;
    fi

    git switch "$default_branch" $@
    
    return $?;
  fi

  # co -b or -c branch create branch
  if (( co_is_b || co_is_c )); then
    local branch_arg=""
    local base_branch="$2"

    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    fi

    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      return 1;
    fi

    if [[ -z "$base_branch" ]]; then
      base_branch=$(git branch --show-current)

      if [[ -z "$base_branch" ]]; then
        print " fatal: cannot create branch from detached branch" >&2
        print " run ${yellow_cor}co <branch> <base_branch>${reset_cor} to create branch off of a base branch" >&2
        return 1;
      fi
    fi

    co "$branch_arg" "$base_branch"

    return $?;
  fi

  # co -e branch just checkout, do not create branch
  if (( co_is_e || co_is_x )); then
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

  # co $1 or co (no arguments)
  if [[ -z "$2" || "$2" == --* ]]; then
    co -a $@

    return $?;
  fi

  # co branch BASE_BRANCH (creating branch)
  local branch_arg=""

  if [[ -n "$1" && $1 != -* ]]; then
    branch_arg="$1"
  fi

  if [[ -z "$branch_arg" ]]; then
    print " fatal: branch argument is required" >&2
    return 1;
  fi

  local remote_branch="$(get_remote_branch_ "$branch_arg")"

  if [[ -n "$remote_branch" ]]; then
    print " fatal: branch already exists on remote: $branch_arg" >&2
    return 1;
  fi

  local base_branch_arg=""
  if [[ -n "$2" && $2 != -* ]]; then
    base_branch_arg="$2"
  fi

  local base_branch="$(select_branch_ -at "$base_branch_arg" "base branch")"
  if [[ -z "$base_branch" ]]; then return 1; fi

  if ! git checkout -b "$branch_arg" "$base_branch" ${@:3}; then return 1; fi

  # local jira_key=$(extract_jira_key_ "$branch_arg")
  # if [[ -n "$jira_key" ]]; then
  #   jira -p "$jira_key" 2>/dev/null
  # fi

  git config "branch.${branch_arg}.gh-merge-base" "$base_branch"
  
  return 0;
}

function back() {
  set +x
  eval "$(parse_flags_ "back_" "" "" "$@")"
  (( back_is_d )) && set -x

  if (( back_is_h )); then
    print "  ${yellow_cor}back ${solid_yellow_cor}[<folder>]${reset_cor} : to go back the previous branch"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" switch - $@
}

function dev() {
  # checkout dev or develop branch
  set +x
  eval "$(parse_flags_ "dev_" "" "" "$@")"
  (( dev_is_d )) && set -x

  if (( dev_is_h )); then
    print "  ${yellow_cor}dev${reset_cor} : to switch to a dev branch in current project"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{dev,devel,develop,development}; do
    if git show-ref -q --verify $ref; then
      co -e ${ref:t} &>/dev/null
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function main() {
  # checkout main branch
  set +x
  eval "$(parse_flags_ "main_" "" "" "$@")"
  (( main_is_d )) && set -x

  if (( main_is_h )); then
    print "  ${yellow_cor}main${reset_cor} : to switch to main branch in current project"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if git show-ref -q --verify $ref; then
      co -e ${ref:t} &>/dev/null
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function prod() {
  # checkout prod branch
  set +x
  eval "$(parse_flags_ "prod_" "" "" "$@")"
  (( prod_is_d )) && set -x

  if (( prod_is_h )); then
      print "  ${yellow_cor}prod${reset_cor} : to switch to prod or production branch in current project"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{prod,production}; do
    if git show-ref -q --verify $ref; then
      co -e ${ref:t} &>/dev/null
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function stage() {
  # checkout stage branch
  set +x
  eval "$(parse_flags_ "stage_" "" "" "$@")"
  (( stage_is_d )) && set -x

  if (( stage_is_h )); then
      print "  ${yellow_cor}stage${reset_cor} : to switch to stage or staging branch in current project"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  for ref in refs/{heads,remotes/{origin,upstream}}/{stage,staging}; do
    if git show-ref -q --verify $ref; then
      co -e ${ref:t} &>/dev/null
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git" >&2
  return 1;
}

function rebase() {
  set +x
  eval "$(parse_flags_ "rebase_" "apq" "pqi" "$@")"
  (( rebase_is_d )) && set -x

  if (( rebase_is_h )); then
    print "  ${yellow_cor}rebase${reset_cor} : to apply the commits from your branch on top of the HEAD of default branch"
    print "  ${yellow_cor}rebase ${solid_yellow_cor}<base_branch> [<folder>]${reset_cor} : to apply the commits on top of the HEAD of base branch"
    print "  ${yellow_cor}rebase -a${reset_cor} : to rebase multiple branches"
    print "  ${yellow_cor}rebase -p${reset_cor} : to push after rebase if succeeds with no conflicts"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  local base_branch=""
  local branch_arg="$(git -C "$folder" branch --show-current)"

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

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    return 1;
  fi

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  local RET=0

  if (( rebase_is_a )); then
    local selected_branches=($(select_branches_ -lt "" "$folder" 0 "$base_branch"))
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

  fetch "$folder" --quiet

  print -n " rebasing branch ${green_cor}${branch_arg}${reset_cor} of ${solid_green_cor}${base_branch}${reset_cor}"
  if (( merge_is_p )); then
    print -n " then pushing"
  fi
  print ""

  git -C "$folder" rebase "${remote_name}/${base_branch}" $@
  RET=$?

  if (( RET == 0 && rebase_is_p )); then
    pushf "$folder"
    RET=$?
  fi

  return $RET;
}

function merge() {
  set +x
  eval "$(parse_flags_ "merge_" "apq" "pq" "$@")"
  (( merge_is_d )) && set -x

  if (( merge_is_h )); then
    print "  ${yellow_cor}merge${reset_cor} : to create a new merge commit from default branch"
    print "  ${yellow_cor}merge ${solid_yellow_cor}<base_branch> [<folder>]${reset_cor} : to create a new merge commit from base branch"
    print "  ${yellow_cor}merge -a${reset_cor} : to merge multiple branches"
    print "  ${yellow_cor}merge -p${reset_cor} : to push after merge succeeds with no conflicts"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  local base_branch=""
  local branch_arg="$(git -C "$folder" branch --show-current)"

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

  if [[ -z "$base_branch" ]]; then
    print " fatal: base branch is not defined" >&2
    return 1;
  fi

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  local RET=0

  if (( merge_is_a )); then
    local selected_branches=($(select_branches_ -lt "" "$folder" 0 "$base_branch"))
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

  fetch "$folder" --quiet

  print -n " merging branch ${green_cor}${branch_arg}${reset_cor} from ${solid_green_cor}${base_branch}${reset_cor}"
  if (( merge_is_p )); then
    print -n " then pushing"
  fi
  print ""

  git -C "$folder" merge "${remote_name}/${base_branch}" --no-edit $@
  RET=$?

  if (( RET == 0 && merge_is_p )); then
    push "$folder"
    RET=$?
  fi

  return $RET;
}

function prune() {
  set +x
  eval "$(parse_flags_ "prune_" "" "" "$@")"
  (( prune_is_d )) && set -x

  if (( prune_is_h )); then
    print "  ${yellow_cor}prune ${solid_yellow_cor}[<folder>]${reset_cor} : to clean up unreachable or orphaned git branches and tags"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  # delete all local tags
  # git tag -l | xargs git tag -d 1>/dev/null

  # get all local tags
  local local_tags=("${(@f)$(git -C "$folder" tag)}")

  # get all remote tags (strip refs/tags/)
  local remote_tags=("${(@f)$(git -C "$folder" ls-remote --tags origin)}")
  local remote_tag_names=()
  
  local line=""
  for line in "${remote_tags[@]}"; do
    [[ $line =~ refs/tags/(.+)$ ]] && remote_tag_names+=("${match[1]}")
  done

  local tag=""
  for tag in "${local_tags[@]}"; do
    if ! [[ "${remote_tag_names[@]}" == *"$tag"* ]]; then
      git -C "$folder" tag -d "$tag"
    fi
  done

  # fetch tags that exist in the remote
  fetch "$folder" -t --quiet
  
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
  eval "$(parse_flags_ "delb_" "sera" "" "$@")"
  (( delb_is_d )) && set -x

  if (( delb_is_h )); then
    print "  ${yellow_cor}delb${reset_cor} : to delete a branch locally in current folder"
    print "  ${yellow_cor}delb ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to delete a branch locally in folder"
    print "  ${yellow_cor}delb -r${reset_cor} : to also delete remotely (excludes main branches)"
    print "  ${yellow_cor}delb -a${reset_cor} : to include all branches (use with -r)"
    print "  ${yellow_cor}delb -s${reset_cor} : to skip confirmation (cannot use with -r)"
    print "  ${yellow_cor}delb -e${reset_cor} : to delete only if matches exact name"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  if (( delb_is_s && delb_is_r )); then
    print " ${red_cor}fatal: cannot use -s and -r together${reset_cor}" >&2
    print " run ${yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local deleted_branches=()

  if (( delb_is_r )); then
    if (( delb_is_e )); then
      selected_branches=($(select_branches_ -re "$branch_arg" "$folder" "$delb_is_a"))
    else
      selected_branches=($(select_branches_ -r "$branch_arg" "$folder" "$delb_is_a"))
    fi
  else
    if (( delb_is_e )); then
      selected_branches=($(select_branches_ -le "$branch_arg" "$folder" 1))
    else
      selected_branches=($(select_branches_ -l "$branch_arg" "$folder" 1))
    fi
  fi
  if [[ -z "$selected_branches" ]]; then return 1; fi

  local RET=0

  local branch=""
  for branch in "${selected_branches[@]}"; do
    if (( ! delb_is_s || delb_is_r )); then
      local origin=$((( delb_is_r )) && echo "remote" || echo "local")
      confirm_ "delete ${origin} branch: ${magenta_prompt_cor}${branch}${reset_prompt_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi
    # git already does that
    # git config --remove-section "branch.${branch}" &>/dev/null

    if (( delb_is_r )); then
      local remote_name=$(get_remote_origin_)

      git -C "$folder" branch -D "$branch" &>/dev/null
      git -C "$folder" push --delete "$remote_name" "$branch"
    else
      git -C "$folder" branch -D "$branch"
    fi
    RET=$?
    if (( RET == 0 )); then
      deleted_branches+=("$branch")
    fi
  done

  return $RET;
}

function st() {
  set +x
  eval "$(parse_flags_ "st_" "sb" "sb" "$@")"
  (( st_is_d )) && set -x

  if (( st_is_h )); then
    print "  ${yellow_cor}st ${solid_yellow_cor}[<folder>]${reset_cor} : to show git status"
    print "  ${yellow_cor}st -sb${reset_cor} : to show git status in short-format"
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

  if ! is_git_repo_ "$folder"; then return 1; fi

  # -sb is equivalent to git status -sb
  git -C "$folder" status $@
}

function get_pkg_name_() {
  local proj_folder="${1-$PWD}"
  local proj_repo="$2"

  if [[ -z "$proj_repo" ]]; then
    local folder=$(get_proj_for_git_ "$proj_folder" 2>/dev/null)
    if [[ -n "$folder" ]]; then
      proj_repo=$(get_repo_ "$folder")
    fi
  fi

  local folder=$(get_proj_for_pkg_ "$proj_folder")
  if [[ -n "$folder" ]]; then
    local pkg_name=$(get_from_pkg_json_ "name" "$folder")
  
    if [[ -z "$pkg_name" && -n "$proj_repo" ]]; then
      pkg_name=$(get_pkg_field_online_ "name" "$proj_repo")
    fi
  fi
  
  if [[ -z "$pkg_name" ]]; then
    pkg_name=$(basename "$proj_folder")
  fi

  pkg_name="${pkg_name//[[:space:]]/}"

  echo "$pkg_name"
}

function pro() {
  set +x
  eval "$(parse_flags_ "pro_" "aerucfitlnx" "" "$@")"
  (( pro_is_d )) && set -x

  if (( pro_is_h )); then
    print "  ${yellow_cor}pro <name>${reset_cor} : to set a project"
    print "  ${yellow_cor}pro -l${reset_cor} : to list all projects"
    print "  ${yellow_cor}pro -a ${solid_yellow_cor}<name>${reset_cor} : to add new project"
    print "  ${yellow_cor}pro -e <name>${reset_cor} : to edit a project"
    print "  ${yellow_cor}pro -r <name>${reset_cor} : to remove a project"
    print "  --"
    print "  ${yellow_cor}pro -i ${solid_yellow_cor}<name>${reset_cor} : to display top project's settings"
    print "  ${yellow_cor}pro -c ${solid_yellow_cor}<name>${reset_cor} : to display all project's settings"
    print "  ${yellow_cor}pro -t ${solid_yellow_cor}<name>${reset_cor} : to display project's readme if available"
    print "  ${yellow_cor}pro -n ${solid_yellow_cor}<name>${reset_cor} : to reset node.js version for a project"
    print "  ${yellow_cor}pro -u ${solid_yellow_cor}<name>${reset_cor} : to unset project's \"don't ask again\" settings"
    print "  --"
    pro -l
    return 0;
  fi

  if (( pro_is_l )); then
    # pro -l list projects
    if (( ${#PUMP_PROJ_SHORT_NAME[@]} == 0 )); then
      print "  no projects yet" >&2
      print "   ${yellow_cor}pro -a <name>${reset_cor} : to add a new project" >&2
      return 1;
    fi
    
    if [[ -n "${PUMP_PROJ_SHORT_NAME[*]}" ]]; then
      local i=0
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          print " ${solid_blue_cor}${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor} = set project to ${PUMP_PROJ_SHORT_NAME[$i]}"
        fi
      done
    fi

    return 0;
  fi

  local proj_arg="$1"

  # pro -i [<name>] display main project's settings
  if (( pro_is_i )); then
    if [[ -z "$proj_arg" ]]; then
      proj_arg="${CURRENT_PUMP_PROJ_SHORT_NAME}"
    fi

    local i=$(find_proj_index_ -oe "$proj_arg")
    (( i )) || return 1;

    local pro_i_cor="${blue_cor}"

    display_line_ "" "${pro_i_cor}"
    print "  ${pro_i_cor}project name:${reset_cor} ${PUMP_PROJ_SHORT_NAME[$i]}"
    print "  ${pro_i_cor}project repository:${reset_cor} ${PUMP_PROJ_REPO[$i]}"
    print "  ${pro_i_cor}project folder:${reset_cor} ${PUMP_PROJ_FOLDER[$i]}"
    print "  ${pro_i_cor}project mode:${reset_cor} $( (( ${PUMP_PROJ_SINGLE_MODE[$i]} )) && echo "single" || echo "multiple" )"
    print "  ${pro_i_cor}package manager:${reset_cor} ${PUMP_PKG_MANAGER[$i]}"
    print "  ${pro_i_cor}node.js version:${reset_cor} ${PUMP_NVM_USE_V[$i]}"
    display_line_ "" "${pro_i_cor}"
    return $?;
  fi

  # pro -t [<name>] display project readme
  if (( pro_is_t )); then
    if [[ -z "$proj_arg" ]]; then
      proj_arg="${CURRENT_PUMP_PROJ_SHORT_NAME}"
    fi

    local i=$(find_proj_index_ -oe "$proj_arg")
    (( i )) || return 1;

    proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

    local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"
    local maxdepth=2; (( single_mode )) && maxdepth=1
    
    local readme_file=$(find "${PUMP_PROJ_FOLDER[$i]}" \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -maxdepth $maxdepth -type f -iname "README.md*" -print -quit 2>/dev/null)
    if [[ -z "$readme_file" ]]; then
      readme_file=$(find "${PUMP_PROJ_FOLDER[$i]}" \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -type f -iname "README.md*" -print -quit 2>/dev/null)
    fi

    if [[ -n "$readme_file" ]]; then
      print " displaying readme at ${green_cor}${readme_file}${reset_cor}" >&1

      if command -v glow &>/dev/null; then
        glow "$readme_file"
      else
        cat "$readme_file"
      fi
    fi
    return $?;
  fi

  # pro -u [<name>] reset project settings
  if (( pro_is_u )); then
    local i=$(find_proj_index_ -oe "$proj_arg")
    (( i )) || return 1;
    
    proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

    update_setting_ $i "PUMP_PR_RUN_TEST" "" 2>/dev/null
    update_setting_ $i "PUMP_COMMIT_ADD" "" 2>/dev/null
    update_setting_ $i "PUMP_PUSH_ON_REFIX" "" 2>/dev/null
    update_setting_ $i "PUMP_PRINT_README" "" 2>/dev/null
    update_setting_ $i "PUMP_GHA_WORKFLOW" "" 2>/dev/null
    update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" "" 2>/dev/null
    update_setting_ $i "PUMP_NVM_USE_V" "" 2>/dev/null
    update_setting_ $i "PUMP_DEFAULT_BRANCH" "" 2>/dev/null
    update_setting_ $i "PUMP_CODE_EDITOR" "" 2>/dev/null
    update_setting_ $i "PUMP_JIRA_PROJ" "" 2>/dev/null

    return $?;
  fi

  # pro -c [<name>] show project config
  if (( pro_is_c )); then
    local i=$(find_proj_index_ "$proj_arg" 0)
    [[ -n "$i" ]] || return 1;
    
    print_current_proj_ $i
    return $?;
  fi

  # pro -e <name> edit project
  if (( pro_is_e )); then
    local i=$(find_proj_index_ -oe "$proj_arg")
    (( i )) || return 1;

    proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

    save_proj_ -e $i "$proj_arg"
    return $?;
  fi
  
  # pro -a <name> add project
  if (( pro_is_a )); then
    local i=0
    for i in {1..9}; do
      if [[ -z "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        if [[ -n "$proj_arg" ]]; then
          if ! check_proj_cmd_ $i "$proj_arg"; then return 1; fi
        fi

        save_proj_ -a $i "$proj_arg"
        return $?;
      fi
    done

    print " fatal: no more slots available, remove a project to add a new one" >&2
    print " run ${yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # pro -r <name> remove project
  if (( pro_is_r )); then
    if [[ -z "$proj_arg" ]]; then
      local projects=()
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          projects+=("${PUMP_PROJ_SHORT_NAME[$i]}")
        fi
      done
      if (( ${#projects[@]} == 0 )); then
        print " fatal: no projects to remove" >&2
        return 1;
      fi
      
      local selected_projects=($(choose_multiple_ "projects to remove" "${(@f)$(printf "%s\n" "${projects[@]}")}"))
      if [[ -z "$selected_projects" ]]; then return 1; fi

      local proj=""
      for proj in "${selected_projects[@]}"; do
        pro -r "$proj"
      done
      return $?;
    fi

    local i=$(find_proj_index_ "$proj_arg")
    (( i )) || return 1;

    local refresh=0;
    [[ "$proj_arg" == "$CURRENT_PUMP_PROJ_SHORT_NAME" ]] && refresh=1;

    if ! remove_proj_ $i; then
      print " failed to remove: ${proj_arg}" >&2
      return 1;
    fi

    print " removed: ${proj_arg}"

    if (( refresh )); then
      set_current_proj_ 0
    fi

    return $?;
  fi

  # pro -n <name> set node.js version for a project
  if (( pro_is_n )); then
    local i=$(find_proj_index_ -oe "$proj_arg")
    (( i )) || return 1;

    proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

    if ! command -v nvm &>/dev/null; then
      return 1;
    fi

    # if (( pro_is_f )); then
    #   echo "$CURRENT_PUMP_PROJ_SHORT_NAME" > "$PUMP_PRO_PWD_FILE"
    # else
    #   echo "$CURRENT_PUMP_PROJ_SHORT_NAME" > "$PUMP_PRO_FILE"
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
      local proj_folder=$(get_proj_for_pkg_ "${PUMP_PROJ_FOLDER[$i]}" "package.json")
      if [[ -z "$proj_folder" ]]; then return 1; fi

      setopt NO_NOTIFY
      {
        # exec
        gum spin --title="detecting node.js..." -- bash -c 'sleep 3'
        # echo -e "\r\033[K"
        # tput sgr0
      } 2>/dev/tty

      # gum spin --title="detecting node.js engine..." -- sleep 2 2>/dev/tty &!

      local node_engine=$(get_node_engine_ "$proj_folder")

      if [[ -n "$node_engine" ]]; then
        local versions=()
        versions=$(get_node_versions_ "$proj_folder" "oldest" "$node_engine")
          
        # if [[ -n "$nvm_use_v" ]] && \
        #     [[ ! " ${versions[@]} " =~ " ${nvm_use_v} " ]] && \
        #     is_node_version_valid_ "$node_engine" "$nvm_use_v"; \
        # then
        #   versions+=("${nvm_use_v}")
        # fi
        if [[ -n "$versions" ]]; then
          nvm_use_v=$(choose_one_ -a "node.js version to use with ${proj_arg}'s engine $node_engine" "${(@f)$(printf "%s\n" "$versions" | sort -V)}")
        fi
      fi

      # if [[ -n "$nvm_use_v" ]]; then
      #   # local major_version=$(get_major_version_ "$nvm_use_v")
      #   # if [[ -z "$major_version" ]]; then major_version="$nvm_use_v"; fi
      #   update_setting_ $i "PUMP_NVM_USE_V" "$nvm_use_v" &>/dev/null
      # fi

      if [[ -n "$nvm_use_v" ]] && (( pro_is_x )); then
        nvm use "$nvm_use_v"
      fi

      if [[ -n "$nvm_use_v" ]] && (( ! pro_is_x )); then
        print -n " node.js version set";
        if [[ -n "$old_nvm_use_v" ]]; then
          print -n " from: ${solid_yellow_cor}$old_nvm_use_v${reset_cor}"
        fi
        print " to: ${green_cor}$nvm_use_v${reset_cor}"

        update_setting_ $i "PUMP_NVM_USE_V" "$nvm_use_v" &>/dev/null
        update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" 1 &>/dev/null

      elif [[ -n "$node_engine" && -n "$nvm_use_v" && -z "$nvm_skip_lookup" ]]; then
        if confirm_ "save node.js version and stop detecting?"; then
          update_setting_ $i "PUMP_NVM_USE_V" "$nvm_use_v" &>/dev/null
          update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" 1 &>/dev/null
        fi

      elif [[ -z "$node_engine" && -z "$nvm_skip_lookup" ]]; then
        if confirm_ "skip detecting node.js version from now on?"; then
          update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" 1 &>/dev/null
        fi
      fi
    fi

    return 0;
  fi # end of pro -n

  # pro pwd project based on current working directory
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(find_proj_by_folder_)

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      if ! is_proj_folder_ &>/dev/null; then
        return 1;
      fi

      local pkg_name=$(get_pkg_name_)
      local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")
      # print " project not found, adding new project: ${solid_blue_cor}${proj_cmd}${reset_cor}" 2>/dev/tty

      local i=0 foundI=0 emptyI=0
      for i in {1..9}; do
        # give option to edit the project because it could have been moved to a different folder
        # that find_proj_by_folder_ doesn't pick up
        if (( foundI == 0 )); then
          if [[ "$proj_cmd" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
            foundI=$i
          elif [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" && "$pkg_name" == "${PUMP_PKG_NAME[$i]}" ]]; then
            foundI=$i
            proj_cmd="${PUMP_PROJ_SHORT_NAME[$i]}"
          fi
        fi
        if (( emptyI == 0 )) && [[ -z "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          emptyI=$i
        fi
      done

      # if foundI != 0, it's because a project with the same name already exists but the folder is different
      if (( foundI )); then
        save_proj_f_ -e $foundI "$proj_cmd" "$pkg_name"
      else
        if confirm_ "add new project: ${bright_pink_prompt_cor}${pkg_name}${reset_prompt_cor}?"; then
          save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name"
        fi
      fi

      return $?;
    fi
  fi

  if [[ -z "$proj_arg" ]]; then
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print -n " project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor}"
      if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
        print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
      fi
      print ""
    fi

    print " run ${yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # pro <name>
  local i=$(find_proj_index_ -o "$proj_arg")
  if (( ! i )); then
    print " run ${yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_PROJ_SHORT_NAME[$i]}"

  # load the project config settings
  load_config_entry_ $i

  # if (( pro_is_f )); then
  #   if [[ -f "$PUMP_PRO_PWD_FILE" ]]; then
  #     CURRENT_PUMP_PROJ_SHORT_NAME=$(<"$PUMP_PRO_PWD_FILE")
  #   fi
  # else
  #   if [[ -f "$PUMP_PRO_FILE" ]]; then
  #     CURRENT_PUMP_PROJ_SHORT_NAME=$(<"$PUMP_PRO_FILE")
  #   fi
  # fi

  # print "hey $proj_arg - $CURRENT_PUMP_PROJ_SHORT_NAME" >&2

  if (( pro_is_f )) || [[ "$proj_arg" != "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    set_current_proj_ $i

    print -n " project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor}" >/dev/tty
    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" >/dev/tty
    fi
    print "" >/dev/tty

    pro -nx "$proj_arg"

    if [[ -n "$CURRENT_PUMP_PRO" ]]; then
      eval "$CURRENT_PUMP_PRO"
    fi
  fi
}

# project handler =========================================================
# pump()
function proj_handler() {
  local i="$1"
  shift

  set +x
  eval "$(parse_flags_ "proj_handler_" "ocmein" "" "$@")"
  (( proj_handler_is_d )) && set -x

  if ! check_proj_ -fm $i; then return 1; fi

  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"
  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  local proj_cmd="${PUMP_PROJ_SHORT_NAME[$i]}"

  if (( proj_handler_is_h )); then
    print "  ${yellow_cor}${proj_cmd}${reset_cor} : to set and open ${proj_cmd}"
    (( ! single_mode )) && print "  ${yellow_cor}${proj_cmd} <folder>${reset_cor} : to set ${proj_cmd} and open folder"
    (( single_mode )) && print "  ${yellow_cor}${proj_cmd} <branch>${reset_cor} : to set/open ${proj_cmd} and switch to branch"
    print "  --"
    print "  ${yellow_cor}${proj_cmd} -o ${solid_yellow_cor}[<jira_key>]${reset_cor} : to open a ${proj_cmd}'s ticket"
    print "  ${yellow_cor}${proj_cmd} -c ${solid_yellow_cor}[<jira_key>]${reset_cor} : to close a ${proj_cmd}'s ticket"
    (( ! single_mode )) && print "  ${yellow_cor}${proj_cmd} -m${reset_cor} : to open ${proj_cmd}'s default folder"
    print "  --"
    print "  ${yellow_cor}${proj_cmd} -e${reset_cor} : to edit ${proj_cmd}"
    print "  ${yellow_cor}${proj_cmd} -i${reset_cor} : to display top ${proj_cmd}'s settings"
    print "  ${yellow_cor}${proj_cmd} -n${reset_cor} : to reset ${proj_cmd}'s node.js version"
    return 0;
  fi
  
  if (( proj_handler_is_e )); then
    pro -e "$proj_cmd"
    return $?
  fi
  
  if (( proj_handler_is_i )); then
    pro -i "$proj_cmd"
    return $?
  fi

  if (( proj_handler_is_n )); then
    pro -n "$proj_cmd"
    return $?
  fi

  local folder_arg=""
  local branch_arg=""

  if [[ -n "$1" ]]; then
    if (( single_mode )); then
      if [[ -d "${proj_folder}/$1" ]]; then
        folder_arg="$1"
      else
        branch_arg="$1"
      fi
    else
      if [[ -d "${proj_folder}/$1" ]]; then
        folder_arg="$1"
      else
        print " fatal: not a valid folder argument: $1" >&2
        print " run ${yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

  elif (( proj_handler_is_m )); then
    if (( ! single_mode )); then
      folder_arg=$(get_default_folder_ "$proj_folder" 2>/dev/null)
    fi
  fi

  local resolved_folder="$proj_folder"

  # resolve folder_arg
  if (( single_mode )); then
    if [[ -n "$folder_arg" ]]; then
      resolved_folder="${proj_folder}/${folder_arg}"
    fi
  else
    if [[ -n "$folder_arg" ]]; then
      resolved_folder="${proj_folder}/${folder_arg}"
    
    elif (( ! proj_handler_is_o )); then
      local dirs=("${(@f)$(get_folders_ "$proj_folder")}")
      
      if [[ -n "$dirs" ]]; then
        local header="folder to open"
        if (( proj_handler_is_c )); then
          header="folder to close"
        fi
        folder_arg=($(choose_one_ -a "$header" "${dirs[@]}"))
          
        if [[ -n "$folder_arg" ]]; then
          resolved_folder="${proj_folder}/${folder_arg}"
        fi
      fi
    fi
  fi

  local jira_key=""

  if (( proj_handler_is_c || proj_handler_is_o )); then
    if (( single_mode )); then
      _arg="$branch_arg"
    else
      _arg="$folder_arg"
      if (( proj_handler_is_c )) && [[ -z "$_arg" ]]; then
        print " fatal: not a valid argument" >&2
        print " run ${yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    if [[ -n "$_arg" ]]; then
      jira_key=$(extract_jira_key_ "$_arg")

      if [[ -z "$jira_key" ]]; then
        print " fatal: not a valid argument" >&2
        print " run ${yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      local jira_key=$(select_jira_key_ $i)
      if [[ -z "$jira_key" ]]; then return 1; fi
    fi
  fi
  
  if (( proj_handler_is_o )); then
    jira "$proj_cmd" "$jira_key"
    return $?;
  fi

  if (( proj_handler_is_c )); then
    if (( single_mode )); then
      co -m
      delb -se "$branch_arg" "$resolved_folder"
    else
      del "$resolved_folder"
    fi

    if (( $? == 0 )); then
      jira -c "$proj_cmd" "$jira_key" 2>/dev/null
      return 0;
    fi

    return 1;
  fi

  cd "$resolved_folder"

  if (( $? == 0 )); then
    if [[ -z "$(ls "$resolved_folder")" ]]; then
      print " project folder is empty" >&1
      print " run: ${yellow_cor}clone ${proj_cmd}${reset_cor}" >&1
    elif [[ -n "$branch_arg" ]]; then
      co "$branch_arg"
    fi
  fi
}

function stash() {
  set +x
  eval "$(parse_flags_ "stash_" "vl" "" "$@")"
  (( stash_is_d )) && set -x

  if (( stash_is_h )); then
    print "  ${yellow_cor}stash${reset_cor} : to stash all files"
    print "  ${yellow_cor}stash ${solid_yellow_cor}<name>${reset_cor} : to stash files"
    print "  ${yellow_cor}stash -v ${solid_yellow_cor}n${reset_cor} : to view latest nth stash"
    print "  ${yellow_cor}stash -l ${solid_yellow_cor}n${reset_cor} : to list stashes, limit by n"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if (( stash_is_v )); then
    git stash show -p stash@{${1:-0}}
    return $?;
  elif (( stash_is_l )); then
    git stash list | head -n ${1:-10}
    return $?;
  fi

  if (( stash_is_v )); then
    git stash show -p stash@{${1:-0}}
    return $?;
  elif (( stash_is_l )); then
    git stash list | head -n ${1:-10}
    return $?;
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    git stash push --include-untracked --message "$1" ${@:2}
  else
    git stash push --include-untracked --message "$(date +%Y-%m-%d_%H:%M:%S)" $@
  fi
}

function pop() {
  set +x
  eval "$(parse_flags_ "pop_" "a" "" "$@")"
  (( pop_is_d )) && set -x

  if (( pop_is_h )); then
    print "  ${yellow_cor}pop${reset_cor} : to pop and apply latest stash"
    print "  ${yellow_cor}pop -a${reset_cor} : to pop and apply all stashes"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if (( pop_is_a )); then
    local stashes=()
    local stash

    # collect stash refs in an array
    while IFS= read -r line; do
      stash="${line%%:*}"  # strip everything after the first colon
      stashes+=("$stash")
    done < <(git stash list)

    # pop in reverse order (so indices don’t shift)
    for (( i=${#stashes[@]}-1; i>=0; i-- )); do
      echo "Popping ${stashes[$i]}..."
      git stash pop --index "${stashes[$i]}" || break;
    done
  else
    git stash pop --index
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
  eval "$(parse_flags_ "commit_" "am" "s" "$@")"
  (( commit_is_d )) && set -x

  if (( commit_is_h )); then
    print "  ${yellow_cor}${COMMIT1}${reset_cor} : commit wizard (https://www.conventionalcommits.org/)"
    print "  ${yellow_cor}${COMMIT1} <message>${reset_cor} : to commit  --no-verify --message"
    print "  ${yellow_cor}${COMMIT1} -m <message>${reset_cor} : same as ${COMMIT1} <message>"
    print "  ${yellow_cor}${COMMIT1} -a${reset_cor} : commit all files"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if (( commit_is_a || CURRENT_PUMP_COMMIT_ADD )); then
    git add .
  elif [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
    if confirm_ "commit all changes?"; then
      if git add . && confirm_ "save this preference and don't ask again?" "save" "ask again"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_COMMIT_ADD" 1 &>/dev/null
            break;
          fi
        done
        print ""
      fi
    fi
  fi

  if [[ -z "$1" ]]; then
    if ! command -v gum &>/dev/null; then
      print " fatal: commit wizard requires gum" >&2
      print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
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
  #tput reset
  if command -v gum &>/dev/null; then
    gum style --border=rounded --margin=0 --padding="1 16" --border-foreground 212 --width=71 \
      --align=center "welcome to $(gum style --foreground 212 "fab1o's pump my shell! v$PUMP_VERSION")"
  else
    display_line_ "" "${pink_cor}"
    display_line_ "fab1o's pump my shell!" "${pink_cor}" 72 "${reset_cor}"
    display_line_ "v$PUMP_VERSION" "${pink_cor}" 72 "${reset_cor}"
    display_line_ "" "${pink_cor}"
  fi

  local remote_name=$(get_remote_origin_)

  if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    print ""
    print -n "  project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor}"
    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
    fi
    print ""
  fi

  local spaces="14s"

  print ""
  display_line_ "get started" "${gray_cor}"
  print ""
  print "  1. set a project, run:${solid_blue_cor} pro -h${reset_cor} to see usage"
  print "  2. clone project, run:${yellow_cor} clone -h${reset_cor} to see usage"
  print "  3. setup project, run:${yellow_cor} setup -h${reset_cor} to see usage"
  print "  4. run a project, run:${yellow_cor} run -h${reset_cor} to see usage"
  print "  5. start new job, run:${blue_cor} jira -h${reset_cor} to see usage"

  if ! pause_output_; then return 0; fi

  display_line_ "set project" "${solid_blue_cor}"
  print ""
  print " ${solid_blue_cor} pro ${reset_cor}\t\t = set project"
  if (( ${#PUMP_PROJ_SHORT_NAME} == 0 )); then
    pro -a
  else
    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_PROJ_FOLDER[$i]}" && -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        printf "  ${solid_blue_cor}%-$spaces${reset_cor} = %s \n" "${PUMP_PROJ_SHORT_NAME[$i]}" "set project to ${PUMP_PROJ_SHORT_NAME[$i]}"
      fi
    done
  fi

  if ! pause_output_; then return 0; fi

  display_line_ "setup & run" "${yellow_cor}"
  print ""
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "clone" "clone project or branch"

  local _setup="run \"setup\" script or package manager's install"
  local _run="${CURRENT_PUMP_RUN:-"run \"dev\" script"}"
  local _run_stage="${CURRENT_PUMP_RUN_STAGE:-"run \"stage\" script"}"
  local _run_prod="${CURRENT_PUMP_RUN_PROD:-"run \"prod\" script"}"
  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    _setup="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")setup or $CURRENT_PUMP_PKG_MANAGER install"
    _run="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")dev or $CURRENT_PUMP_PKG_MANAGER start"
    _run_stage="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")stage or $CURRENT_PUMP_PKG_MANAGER start"
    _run_prod="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")prod or $CURRENT_PUMP_PKG_MANAGER start"
  fi

  local max=53

  if (( ${#_setup} > max )); then
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "setup" "run PUMP_SETUP"
  else
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "setup" "$_setup"
  fi
  if (( ${#_run} > max )); then
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run" "run PUMP_RUN"
  else
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run" "$_run"
  fi
  if (( ${#_run_stage} > max )); then
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run stage" "run PUMP_RUN_STAGE"
  else
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run stage" "$_run_stage"
  fi
  if (( ${#_run_prod} > max )); then
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run prod" "run PUMP_RUN_PROD"
  else
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "run prod" "$_run_prod"
  fi

  if ! pause_output_; then return 0; fi

  display_line_ "code review" "${cyan_cor}"
  print ""
  printf "  ${cyan_cor}%-$spaces${reset_cor} = %s \n" "rev" "open a review"
  printf "  ${cyan_cor}%-$spaces${reset_cor} = %s \n" "revs" "list existing reviews"

  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    if ! pause_output_; then return 0; fi

    display_line_ "$CURRENT_PUMP_PKG_MANAGER" "${solid_magenta_cor}"
    print ""
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "build" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "deploy" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
    
    local _fix="${CURRENT_PUMP_FIX:-"$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")fix or format + lint"}"
    if (( ${#_fix} > max )); then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "run PUMP_FIX"
    else
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "$_fix"
    fi
    
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "format" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "i" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "ig" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "lint" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "rdev" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "sb" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "sbb" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "start" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "tsc" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
    printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "watch" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")watch"
    
    if ! pause_output_; then return 0; fi

    display_line_ "testing" "${magenta_cor}"
    print ""
    if [[ "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "${CURRENT_PUMP_PKG_MANAGER:0:1}test" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
    fi
    if [[ "$CURRENT_PUMP_COV" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "${CURRENT_PUMP_PKG_MANAGER:0:1}cov" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
    fi
    if [[ "$CURRENT_PUMP_E2E" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "${CURRENT_PUMP_PKG_MANAGER:0:1}e2e" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
    fi
    if [[ "$CURRENT_PUMP_E2EUI" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "${CURRENT_PUMP_PKG_MANAGER:0:1}e2eui" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
    fi
    if [[ "$CURRENT_PUMP_TEST_WATCH" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
      printf "  ${solid_magenta_cor}%-$spaces${reset_cor} = %s \n" "${CURRENT_PUMP_PKG_MANAGER:0:1}testw" "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
    fi

    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "cov" "$CURRENT_PUMP_COV"
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "e2e" "$CURRENT_PUMP_E2E"
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "e2eui" "$CURRENT_PUMP_E2EUI"
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "test" "$CURRENT_PUMP_TEST"
    printf "  ${magenta_cor}%-$spaces${reset_cor} = %s \n" "testw" "$CURRENT_PUMP_TEST_WATCH"
  fi
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "git" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "gconf" "show git config"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "gha" "view last workflow run"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "st" "show git status"
  
  if ! pause_output_; then return 0; fi

  display_line_ "git branch" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "back" "switch back to previous branch"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "co" "switch branch (checkout)"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "dev" "switch to dev or develop branch"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "main" "switch to main branch"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "prod" "switch to prod or production branch"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "renb <b>" "rename current branch"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "stage" "switch to stage or staging branch"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git clean" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "clean" "clean unstaged changes"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "delb" "delete branches"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "discard" "clean + restore"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "prune" "prune branches and tags"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset1" "reset soft 1 commit"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset2" "reset soft 2 commits"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset3" "reset soft 3 commits"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset4" "reset soft 4 commits"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset5" "reset soft 5 commits"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseta" "erase everything, reset to last commit"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "restore" "clean staged changes"

  if ! pause_output_; then return 0; fi

  display_line_ "git log" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "glog" "git log"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "gll" "list local branches"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "glr" "list remote branches"

  if ! pause_output_; then return 0; fi

  display_line_ "git merge" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort rebase/merge/chp"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "chc" "continue cherry-pick"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "chp" "cherry-pick commit"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "cont" "continue rebase/merge/chp"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "mc" "continue merge"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge)"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "rc" "continue rebase"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase)"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "git pull" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "fetch" "fetch from $remote_name"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull from $remote_name"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "pullr" "pull rebase from $remote_name"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git push" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "add" "add files to index"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "$COMMIT1" "commit wizard"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "$COMMIT1 <m>" "commit with message"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push to $remote_name"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "pushf" "force push to $remote_name"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git stash" "${solid_cyan_cor}"
  print ""
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "pop" "apply stash then remove from list"
  printf "  ${solid_cyan_cor}%-$spaces${reset_cor} = %s \n" "stash" "stash files"

  if ! pause_output_; then return 0; fi
  
  display_line_ "release" "${solid_pink_cor}"
  print ""
  printf "  ${solid_pink_cor}%-$spaces${reset_cor} = %s \n" "dtag" "delete a tag"
  printf "  ${solid_pink_cor}%-$spaces${reset_cor} = %s \n" "drelease" "delete a release"
  printf "  ${solid_pink_cor}%-$spaces${reset_cor} = %s \n" "release" "create a release"
  printf "  ${solid_pink_cor}%-$spaces${reset_cor} = %s \n" "tag" "create a tag"
  printf "  ${solid_pink_cor}%-$spaces${reset_cor} = %s \n" "tags" "display latest tags"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "special task" "${blue_cor}"
  print ""
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "cov <b>" "compare test coverage with another branch"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "jira" "clone/checkout work for a jira ticket"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pra" "set assignee to all pull requests"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "refix" "reset last commit, run fix then re-push"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "recommit" "reset last commit then commit changes to index again"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "release" "bump version and create a release on github"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "repush" "reset last commit then push changes again"
  printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "rev" "open a pull request for review on code editor or browser"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "general" "${solid_yellow_cor}"
  print ""
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "cl" "clear terminal"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "colors" "display colors from 0 to 255"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete utility"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "help" "display this help"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "hg <text>" "history | grep text"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "kill <port>" "kill port"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "ll" "ls -la"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "nver" "node version"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "nlist" "npm list global"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "refresh" "source .zshrc"
  printf "  ${solid_yellow_cor}%-$spaces${reset_cor} = %s \n" "upgrade" "omz update + pump update"

  print ""
  print "  try ${yellow_cor}-h${reset_cor} after any command to see more usage details"
  print "  and visit: ${blue_cor}https://github.com/fab1o/pump-zsh/wiki${reset_cor}"
}

function validate_proj_cmd_strict_() {
  # set +x
  # eval "$(parse_flags_ "validate_proj_cmd_strict_" "" "" "$@")"
  # (( validate_proj_cmd_strict_is_d )) && set -x

  local proj_cmd="$1"
  local old_proj_cmd="${2:-$proj_cmd}"

  if ! validate_proj_cmd_ "$proj_cmd"; then
    return 1;
  fi

  local reserved=""
  reserved="$(whence -w "$proj_cmd" 2>/dev/null)"
  if (( $? == 0 )); then
    # if [[ $reserved =~ ": command" ]]; then
      # if confirm_ "project name is reserved: $(whence $proj_cmd) - use it anyway?"; then
      #   return 0;
      # fi
      # return 1;
    if [[ $reserved =~ ": function" ]]; then
      if [[ "$old_proj_cmd" == "$proj_cmd" ]]; then
        return 0;
      fi
    fi
    print "  ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  local invalid_values=("pwd" "quit" "done")

  if [[ " ${invalid_values[*]} " == *" $proj_cmd "* ]]; then
    print "  ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  return 0;
}

function validate_proj_cmd_() {
  local proj_cmd="$1"
  local qty=${2:-$MAX_NAME_COUNT}

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
      if [[ $j -ne $i && "${PUMP_PROJ_SHORT_NAME[$j]}" == "$proj_cmd" ]]; then
        error_msg="project name already in use: $proj_cmd"
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

function colors() {
  for i in {0..255}; do print -P "%F{$i}Color $i%f"; done
}

# cd pro
function pump_chpwd_() {
  local proj_arg=$(find_proj_by_folder_)

  if [[ -n "$proj_arg" ]]; then
    pro "$proj_arg"
  else
    set_current_proj_ 0
  fi
}

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

typeset -gA PUMP_PROJ_SHORT_NAME
typeset -gA PUMP_PROJ_FOLDER
typeset -gA PUMP_PROJ_REPO
typeset -gA PUMP_PROJ_SINGLE_MODE
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
typeset -gA PUMP_PR_TEMPLATE
typeset -gA PUMP_PR_REPLACE
typeset -gA PUMP_PR_APPEND
typeset -gA PUMP_PR_RUN_TEST
typeset -gA PUMP_GHA_INTERVAL
typeset -gA PUMP_COMMIT_ADD
typeset -gA PUMP_GHA_WORKFLOW
typeset -gA PUMP_PUSH_ON_REFIX
typeset -gA PUMP_PRINT_README
typeset -gA PUMP_PKG_NAME
typeset -gA PUMP_JIRA_PROJ
typeset -gA PUMP_JIRA_IN_PROGRESS
typeset -gA PUMP_JIRA_IN_REVIEW
typeset -gA PUMP_JIRA_IN_DONE
typeset -gA PUMP_NVM_SKIP_LOOKUP
typeset -gA PUMP_NVM_USE_V
typeset -gA PUMP_DEFAULT_BRANCH

# ========================================================================
export CURRENT_PUMP_PROJ_SHORT_NAME=""
typeset -g CURRENT_PUMP_PROJ_FOLDER=""
typeset -g CURRENT_PUMP_PROJ_REPO=""
typeset -g CURRENT_PUMP_PROJ_SINGLE_MODE=""
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
typeset -g CURRENT_PUMP_PR_TEMPLATE=""
typeset -g CURRENT_PUMP_PR_REPLACE=""
typeset -g CURRENT_PUMP_PR_APPEND=""
typeset -g CURRENT_PUMP_PR_RUN_TEST=""
typeset -g CURRENT_PUMP_GHA_INTERVAL=""
typeset -g CURRENT_PUMP_COMMIT_ADD=""
typeset -g CURRENT_PUMP_GHA_WORKFLOW=""
typeset -g CURRENT_PUMP_PUSH_ON_REFIX=""
typeset -g CURRENT_PUMP_PRINT_README=""
typeset -g CURRENT_PUMP_PKG_NAME=""
typeset -g CURRENT_PUMP_JIRA_PROJ=""
typeset -g CURRENT_PUMP_JIRA_IN_PROGRESS=""
typeset -g CURRENT_PUMP_JIRA_IN_REVIEW=""
typeset -g CURRENT_PUMP_JIRA_DONE=""
typeset -g CURRENT_PUMP_NVM_SKIP_LOOKUP=""
typeset -g CURRENT_PUMP_NVM_USE_V=""
typeset -g CURRENT_PUMP_DEFAULT_BRANCH=""

typeset -g MULTIPLE_MODE=0
typeset -g SINGLE_MODE=1

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g TEMP_PUMP_PROJ_FOLDER=""
typeset -g TEMP_PUMP_PROJ_REPO=""
typeset -g TEMP_PUMP_PROJ_SHORT_NAME=""
typeset -g TEMP_SAVE_PROJ_CMD_ATTEMPTS=0
typeset -g TEMP_SAVE_PROJ_REPO=0
typeset -g TEMP_SAVE_PROJ_FOLDER=0
typeset -g SAVE_PROJ_COR=""

# ========================================================================

# General
alias ll="ls -la"

function hg() {
  if (( $# == 0 )); then
    history | grep -i "$HIST_SEARCH"
  else
    history | grep -i "$1"
  fi
}

function nver() {
  if (( $# == 0 )); then
    node -e 'console.log(process.version, process.arch, process.platform)'
  else
    node -e "console.log(process.versions['$1'])"
  fi
}

function nlist() {
  if (( $# == 0 )); then
    npm list --global --depth=0
  else
    npm list --global "$@"
  fi
}

load_config_
set_current_proj_ 0

local i=0
for i in {1..9}; do
  if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
    local func_name="${PUMP_PROJ_SHORT_NAME[$i]}"
    functions[$func_name]="proj_handler $i \"\$@\";"
  fi
done

pro -f "pwd" 2>/dev/null

add-zsh-hook chpwd pump_chpwd_

# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs
