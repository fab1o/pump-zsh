typeset -g is_debug=0 # (debug flag) when -d is on, it will be shared across all subsequent function calls
typeset -g MAX_NAME_COUNT=15

typeset -Ag node_folder node_branch node_project
typeset -Ag ll_next ll_prev
typeset -gi node_counter=0
typeset -g head=""

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

typeset -g purple_prompt_cor=$'\e[1;38;5;99m'
typeset -g lightpurple_prompt_cor=$'\e[38;2;167;139;250m'
typeset -g reset_prompt_cor=$'\e[0m'

typeset -g PUMP_VERSION="0.0.0"

typeset -g PUMP_VERSION_FILE="$(dirname "$0")/.version"
typeset -g PUMP_WORKING_FILE="$(dirname "$0")/.working"
typeset -g PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"
# typeset -g PUMP_PRO_FILE="$(dirname "$0")/.pump"
# typeset -g PUMP_PRO_PWD_FILE="$(dirname "$0")/.pump.pwd"

[[ -f "$PUMP_VERSION_FILE" ]] && PUMP_VERSION=$(<"$PUMP_VERSION_FILE")

if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
  cp "$(dirname "$0")/config/pump.zshenv.default" "$PUMP_CONFIG_FILE" &>/dev/null
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    print "${red_cor} config file '$PUMP_CONFIG_FILE' does not exist, re-install pump-zsh ${reset_cor}"
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

        if [[ $valid_flags != *$ch* ]]; then
          if [[ "$ch" != "d" ]]; then flags+=("-$ch"); fi
          print " ${red_cor}fatal: invalid option: -$ch${reset_cor}" >&2
          echo "${prefix}is_h=1"
        elif [[ $valid_flags_pass_along == *$ch* ]]; then
          flags+=("-$ch")
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

  # local OPTIND=1 opt
  # while getopts ":abcdefghijklmnopqrstuvwxyz" opt; do; done

  # if (( OPTIND > 1 )); then
  #   shift $((OPTIND - 1))
  # else
    if [[ ${#non_flags} -gt 0 ]]; then
      echo "set -- ${(q+)non_flags[@]} ${(q+)flags[@]} ${(q+)flags_double_dash[@]}"
    else
      echo "set -- "" ${(q+)flags[@]} ${(q+)flags_double_dash[@]}"
    fi
  # fi
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
      gum confirm ""confirm:$'\e[0m'" $question" \
        --no-show-help \
        --default=false \
        --affirmative="$option1" \
        --negative="$option2" 2>/dev/tty
    else
      gum confirm ""confirm:$'\e[0m'" $question" \
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
      if ! confirm_ "would you like to install new version?"; then
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

function ll_add_node_() {
  local project="$1"
  local folder="$(pwd)"
  
  local branch=$(git branch --show-current)

  if [[ -z "$project" ]]; then
    project=$(find_proj_by_folder_)
  fi

  node_project[$id]="$i"
  node_folder[$id]="$folder"
  node_branch[$id]="$branch"

  local id="node$((++node_counter))"

  node_project[$id]="$i"
  node_folder[$id]="$folder"
  node_branch[$id]="$branch"

  if [[ -z "$head" ]]; then
    ll_next[$id]="$id"
    ll_prev[$id]="$id"
    head="$id"
  else
    local tail="${ll_prev[$head]}"
    ll_next[$tail]="$id"
    ll_prev[$id]="$tail"
    ll_next[$id]="$head"
    ll_prev[$head]="$id"
  fi
}

function ll_remove_node_() {
  local folder="$1" branch="$2" project="$3"

  if [[ -z "$head" ]]; then
    return 1;
  fi

  local id="$head"

  while true; do
    if [[ "${node_folder[$id]}" == "$folder" &&
          "${node_branch[$id]}" == "$branch" &&
          "${node_project[$id]}" == "$project" ]]; then
  
      local prev="${ll_prev[$id]}"
      local next="${ll_next[$id]}"

      if [[ "$id" == "$prev" ]]; then
        # Single node
        unset node_folder[$id] node_branch[$id] node_project[$id]
        unset ll_prev[$id] ll_next[$id]
        head=""
      else
        ll_next[$prev]="$next"
        ll_prev[$next]="$prev"
        [[ "$id" == "$head" ]] && head="$next"
        unset node_folder[$id] node_branch[$id] node_project[$id]
        unset ll_prev[$id] ll_next[$id]
      fi

      return 0
    fi

    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break;
  done

  return 1;
}

function ll_traverse_() {
  if [[ -z "$head" ]]; then
    return
  fi

  local id="$head"

  while true; do
    print "pro=${PUMP_PROJ_SHORT_NAME[${node_project[$id]}]}, folder=${node_folder[$id]}, branch=${node_branch[$id]}"
    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break;
  done
}

function ll_save_() {
  local file="${1:-$PUMP_WORKING_FILE}"

  echo "" > "$file"

  if [[ -z "$head" ]]; then return; fi

  local id="$head"
  while true; do
    echo "${node_project[$id]}|${node_folder[$id]}|${node_branch[$id]}" >> "$file"
    id="${ll_next[$id]}"
    [[ "$id" == "$head" ]] && break;
  done
}

function ll_restore_() {
  local file="${1:-$PUMP_WORKING_FILE}"

  if [[ ! -f "$file" ]]; then
    return 1;
  fi

  # Clear everything
  node_folder=()
  node_branch=()
  node_project=()
  ll_next=()
  ll_prev=()
  head=""

  while IFS='|' read -r project folder branch; do
    ll_add_node_ "$project" "$folder" "$branch"
  done < "$file"
}

function input_from_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-50}"
  local value="$4"

  local _input=""

  # >&2 needs to display because this is called from a subshell
  # print " ${header}:" >&2
  print "${lightpurple_prompt_cor} ${header}:${reset_cor}" >&2

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

    # clear_last_line_2_
  fi
  
  # clear_last_line_2_

  # if [[ "$_input" == $'\e' ]]; then # doesn't work
  #   return 130;
  # fi

  _input=$(printf '%s' "$_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

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
    print "${purple_prompt_cor} choose $header: ${reset_cor}" >&2
    
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

  PS3="${lightpurple_prompt_cor}choose $header: ${reset_prompt_cor}"

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
  eval "$(parse_flags_ "choose_multiple_" "" "" "$@")"
  (( choose_multiple_is_d )) && set -x

  local header="$1"

  local RET=0
  local choices

  if command -v gum &>/dev/null; then
    local choice=""
    if (( choose_multiple_is_a )); then
      choices="$(gum choose --select-if-one --height="20" --no-limit --header=" choose $header ${lightpurple_prompt_cor}(use spacebar to select)${purple_prompt_cor}:${reset_prompt_cor}" -- ${@:2})"
    else
      choices="$(gum choose --height="20" --no-limit --header=" choose $header ${lightpurple_prompt_cor}(use spacebar to select)${purple_prompt_cor}:${reset_prompt_cor}" -- ${@:2})"
    fi
    RET=$?
    
    if (( RET != 0 )); then return $RET; fi
    
    echo "$choices"
    return 0;
  fi

  trap 'print ""; return 130' INT # for some reason it returns 2

  choices=()
  PS3="${lightpurple_prompt_cor}choose $header, then choose \"done\" to finish ${choices[*]}${reset_prompt_cor}"

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
  #dirs=("$folder"/*(N/om))  # o = sort by modified time
  #dirs=("$folder"/*(N/on))  # n = sort by name
  local dirs=("$folder"/*(/N/on))
  local filtered=()

  local dir=""
  for dir in "${dirs[@]}"; do
    local name="${dir##*/}"
    [[ $name != "revs" ]] && filtered+=("$name")
  done

  local priorities=(dev develop release main master production stage staging trunk mainline default stable)
  local ordered=()

  for name in "${priorities[@]}"; do
    if [[ " ${filtered[@]} " == *" $name "* ]]; then
      ordered+=("$name")
    fi
  done

  for name in "${filtered[@]}"; do
    if [[ ! " ${priorities[@]} " == *" $name "* ]]; then
      ordered+=("$name")
    fi
  done

  echo "${ordered[@]}"
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

function update_setting_() {
  check_config_file_

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then
    # print "  warn: config file $PUMP_CONFIG_FILE does not exist, cannot update setting" >&2
    return 0;
  fi

  local i="$1"
  local key="$2"
  local value="$3"

  if [[ "$value" == "${(P)key}[$i]" ]]; then
    return 0; # no change
  fi

  if [[ "$key" == "PUMP_PROJ_SHORT_NAME" ]]; then
    if (( i > 0 )); then
      if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        unset -f "${PUMP_PROJ_SHORT_NAME[$i]}" &>/dev/null
      fi
    else
      if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
        unset -f "$CURRENT_PUMP_PROJ_SHORT_NAME" &>/dev/null
      fi
    fi
    functions[$value]="proj_handler $i \"\$@\";"
  fi

  if (( i > 0 )); then
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" && "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
      eval "CURRENT_${key}=\"$value\""
    fi
    eval "${key}[$i]=\"$value\""
  else
    eval "CURRENT_${key}=\"$value\""
  fi

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
    print "   - check if you have write permissions to the file: $PUMP_CONFIG_FILE" >&2
    print "   - re-install pump-zsh" >&2
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
  print "${lightpurple_prompt_cor} ${header}:${reset_cor}" >&2
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
        confirm_ "set project folder to: "$'\e[94m'${realfolder}$'\e[0m'" or continue to browse further?" "set folder" "continue to browse"
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
    
    local dirs=($(get_folders_ "$folder_path"))
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
    confirm_ "is there a repository for this project in Github?"
    if (( $? == 130 || $? == 2 )); then return 130; fi
    if (( $? == 0 )); then
      local gh_owner=""
      gh_owner=$(input_from_ "type the Github owner account (username or organization)")
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

function delete_pump_working_() {
  local item="$1"
  local pump_working_branch="$2"
  local proj_arg="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  if [[ "$item" == "$pump_working_branch" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        rm -f "${PUMP_WORKING_FILE[$i]}"
        PUMP_WORKING[$i]=""
        break;
      fi
    done
  fi
}

function delete_pump_workings_() {
  local pump_working_branch="$1"
  local proj_arg="$2"
  local selected_items="$3"

  if [[ -z "$pump_working_branch" || -z "$proj_arg" ]]; then
    return 0;
  fi

  for item in $selected_items; do
    delete_pump_working_ "$item" "$pump_working_branch" "$proj_arg"
  done
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
function check_proj_cmd_() {
  set +x
  eval "$(parse_flags_ "check_proj_cmd_" "s" "" "$@")"
  (( check_proj_cmd_is_d )) && set -x

  local i="$1"
  local typed_proj_cmd="$2"
  local pkg_name="$3"
  local old_proj_cmd="$4"

  validate_proj_cmd_strict_ "$typed_proj_cmd" "$old_proj_cmd"
}

function check_proj_repo_() {
  set +x
  eval "$(parse_flags_ "check_proj_repo_" "aes" "" "$@")"
  (( check_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_repo="$2"
  local proj_folder="$3"
  local pkg_name="$4"

  local error_msg=""

  if [[ -z "$proj_repo" ]]; then
    error_msg="project repository is missing for ${solid_blue_cor}$pkg_name${reset_cor}"
  else
    # check for duplicates across other indices
    if ! [[ "$proj_repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
      error_msg="project repository is invalid: $proj_repo"
    else
      if command -v gum &>/dev/null; then
        # so that the spinner can display, add to the end: 2>/dev/tty
        gum spin --timeout=9s --title="checking repository uri..." -- git ls-remote "${proj_repo}" --quiet 2>/dev/tty
      else
        print " checking repository uri..." >&2
        git ls-remote "${proj_repo}" --quiet
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
    print "${yellow_cor}  ${error_msg}${reset_cor}" >&2

    if (( check_proj_repo_is_s )); then
      if (( check_proj_repo_is_a )); then
        if save_proj_repo_ -a $i "$proj_folder" "$pkg_name"; then return 0; fi
      elif (( check_proj_repo_is_e )); then
        if save_proj_repo_ -e $i "$proj_folder" "$pkg_name"; then return 0; fi
      else
        if save_proj_repo_ $i "$proj_folder" "$pkg_name"; then return 0; fi
      fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_folder_() {
  set +x
  eval "$(parse_flags_ "check_proj_folder_" "s" "" "$@")"
  (( check_proj_folder_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local pkg_name="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$pkg_name" ]]; then
      error_msg="project folder is missing for ${solid_blue_cor}$pkg_name${reset_cor}: $proj_folder"
    else
      error_msg="project folder is missing: $proj_folder"
    fi
  else
    if (( check_proj_folder_is_s )) && [[ ! -d "$proj_folder" ]]; then
      if ! mkdir -p "$proj_folder"; then
        if [[ -n "$pkg_name" ]]; then
          error_msg="failed to create project folder for ${solid_blue_cor}$pkg_name${reset_cor}: $proj_folder"
        else
          error_msg="failed to create project folder: $proj_folder"
        fi
      fi
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
    print "${yellow_cor}  ${error_msg}${reset_cor}" >&2

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ -s $i "$pkg_name" "$proj_repo"; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "check_proj_pkg_manager_" "s" "" "$@")"
  (( check_proj_pkg_manager_is_d )) && set -x

  local i="$1"
  local pkg_manager="$2"
  local proj_folder="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$pkg_manager" ]]; then
    error_msg="package manager is missing"
  else
    local valid_pkg_managers=("npm" "yarn" "pnpm" "bun") #"poe"

    if ! [[ " ${valid_pkg_managers[@]} " =~ " $pkg_manager " ]]; then
      error_msg="package manager is invalid: $pkg_manager"
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print "${yellow_cor}  ${error_msg}${reset_cor}" 2>/dev/tty

    if (( check_proj_pkg_manager_is_s )); then
      if save_pkg_manager_ $i "$proj_folder" "$proj_repo"; then return 0; fi
    fi
    return 1;
  fi

  return 0;
}
# end of data checkers

function choose_mode_() {
  local proj_folder="$(basename "$1")"
  local mode="$2"

  local multiple_title=$(gum style --align=center --margin="0" --padding="0" --border=none --width=25 --foreground 212 "multiple mode")
  local single_title=$(gum style --align=center --margin="0" --padding="0" --border=none --width=25 --foreground 99 "single mode")

  local titles=$(gum join --align=center --horizontal "$multiple_title" "$single_title")

  local multiple=$'  '/"$(basename $(dirname "$1"))"'/
   └── '"${proj_folder}"'/
       ├── main/
       ├── feature-1/
       └── feature-2/'

  local single=$'  '/"$(basename $(dirname "$1"))"'/
   └── '"${proj_folder}"'/


  '
  # local multiple=$'
  # '/"$(basename $(dirname "$1"))"'/
  #  └── '"${proj_folder}"'/
  #      ├── main/
  #      ├── feature-1/
  #      ├── feature-2/
  #      └── .revs/
  #          ├── rev.pr-1/
  #          └── rev.pr-2/'

  # local single=$'
  # '/"$(basename $(dirname "$1"))"'/
  #  ├── '"${proj_folder}"'/ 
  #  └── '.".${proj_folder}"'-revs/
  #      ├── rev.pr-1/
  #      └── rev.pr-2/
  

  # '

  multiple=$(gum style --align=left --margin="0" --padding="0" --border=normal --width=25 --border-foreground 212 "$multiple")
  single=$(gum style --align=left --margin="0" --padding="0" --border=normal --width=25 --border-foreground 99 "$single")

  local examples=$(gum join  --align=center --horizontal "$multiple" "$single")
  
  print "" >&2
  gum join --align=center --vertical "$titles" "$examples"

  local default=$((( mode )) && echo "single" || echo "multiple")

  print " • ${pink_cor}multiple mode${reset_cor}:" >&2
  print "   manages branches in separate folders" >&2
  print "   designed for professionals with extensive branching workflows" >&2
  print " • ${purple_cor}single mode${reset_cor}:" >&2
  print "   manages branches within a single folder" >&2
  print "   ideal for small projects with a limited number of branches" >&2
  print "" >&2

  confirm_ "how do you prefer to manage the project: "$'\e[38;5;212m'multiple$'\e[0m'" or "$'\e[38;5;99m'single$'\e[0m'" mode?" "multiple" "single" "$default"
  local RET=$?

  local i=0
  for i in {1..16}; do
    clear_last_line_2_
  done

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

  confirm_ "would you like to move the contents to a new folder and re-clone the project?"
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
  eval "$(parse_flags_ "save_proj_cmd_" "" "" "$@")"
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
    clear_last_line_1_
    print "  ${SAVE_PROJ_COR}project name:${reset_cor} $TEMP_PUMP_PROJ_SHORT_NAME" >&1
    print "" >&1
  fi
}

function save_proj_mode_() {
  set +x
  eval "$(parse_flags_ "save_proj_mode_" "aeq" "" "$@")"
  (( save_proj_mode_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local single_mode="$3"

  local RET=0

  if (( save_proj_mode_is_e || save_proj_mode_is_a )) || [[ -z "$single_mode" ]]; then
    choose_mode_ "$proj_folder" "$single_mode"
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

  if (( save_proj_mode_is_q )); then
    return 0;
  fi

  clear_last_line_2_
  clear_last_line_1_
  if (( single_mode )); then
    print "  ${SAVE_PROJ_COR}project mode:${reset_cor} single" >&1
  else
    print "  ${SAVE_PROJ_COR}project mode:${reset_cor} multiple" >&1
  fi
  print "" >&1
}

function save_proj_folder_() {
  set +x
  eval "$(parse_flags_ "save_proj_folder_" "aerfs" "" "$@")"
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
      confirm_ "would you like to use as project folder: "$'\e[94m'$PWD$'\e[0m'"?"
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
    confirm_ "would you like to keep using project folder: "$'\e[94m'$proj_folder$'\e[0m'"?"
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

    if ! check_proj_folder_ $i "$proj_folder" "$folder_name" "$proj_repo"; then return 1; fi
  
    if (( folder_exists == 0 )); then
      proj_folder="${proj_folder}/${folder_name}"

      if (( save_proj_folder_is_s )); then # only create folder is calling from check_proj_folder_
        if [[ ! -d "$proj_folder" ]]; then
          mkdir -p "$proj_folder"
        fi
      fi
    fi
  else
    if ! check_proj_folder_ -s $i "$proj_folder" "$folder_name" "$proj_repo"; then return 1; fi
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
  eval "$(parse_flags_ "save_proj_repo_" "afe" "" "$@")"
  (( save_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_cmd="$3"
  local proj_repo="$4"

  local RET=0

  if (( ! save_proj_repo_is_f )); then
    if (( save_proj_repo_is_e )) && [[ -n "$proj_repo" ]]; then
      confirm_ "would you like to keep using repository: "$'\e[94m'$proj_repo$'\e[0m'"?"
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
      if ! check_proj_repo_ -s $i "$proj_repo";  then return 1; fi
    fi
  fi

  if [[ -z "$TEMP_PUMP_PROJ_REPO" ]]; then
    TEMP_PUMP_PROJ_REPO="$proj_repo"
  
    update_setting_ $i "PUMP_PROJ_REPO" "$TEMP_PUMP_PROJ_REPO" &>/dev/null

    clear_last_line_1_
    print "  ${SAVE_PROJ_COR}project repository:${reset_cor} ${TEMP_PUMP_PROJ_REPO}" >&1
    print "" >&1
  fi
}

function save_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "save_pkg_manager_" "f" "" "$@")"
  (( save_pkg_manager_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  if (( ! save_pkg_manager_is_f )); then
    print "  detecting package manager..." >&1
  fi

  local pkg_manager=$(detect_pkg_manager_ "$proj_folder")

  if [[ -z "$pkg_manager" ]]; then
    pkg_manager=$(detect_pkg_manager_online_ "$proj_repo")
  fi

  if (( ! save_pkg_manager_is_f )); then
    clear_last_line_2_
  fi

  local RET=0

  if [[ -n "$pkg_manager" ]] && (( ! save_pkg_manager_is_f )); then
    confirm_ "package manager "$'\e[38;5;212m'${pkg_manager}$'\e[0m'"?"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      pkg_manager=""
    fi
  fi

  if [[ -z "$pkg_manager" ]]; then
    pkg_manager=($(choose_one_ "package manager" "npm" "yarn" "pnpm" "bun")) # "poe"
    if [[ -z "$pkg_manager" ]]; then return 1; fi

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder"; then return 1; fi
  fi

  update_setting_ $i "PUMP_PKG_MANAGER" "$pkg_manager" &>/dev/null
  
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
    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
    update_setting_ $i "PUMP_PROJ_SINGLE_MODE" 1 &>/dev/null

    update_setting_ $i "PUMP_PROJ_FOLDER" $PWD &>/dev/null
    update_setting_ $i "PUMP_PROJ_REPO" $proj_repo &>/dev/null

    if ! save_pkg_manager_ -f $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
    if ! save_proj_cmd_ $i "$proj_cmd" "${PUMP_PROJ_SHORT_NAME[$i]}"; then return 1; fi
  else
    remove_proj_ $i &>/dev/null

    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
    update_setting_ $i "PUMP_PROJ_SINGLE_MODE" 1 &>/dev/null

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo"; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -f $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
    if ! save_proj_cmd_ $i "$proj_cmd"; then return 1; fi

    if ! update_setting_ $i "PUMP_PROJ_SHORT_NAME" "$TEMP_PUMP_PROJ_SHORT_NAME"; then return 1; fi

    display_line_ "" "${SAVE_PROJ_COR}"
    print "  ${SAVE_PROJ_COR}project saved!${reset_cor}" >&1
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

    if ! save_proj_mode_ -e $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SINGLE_MODE[$i]}"; then return 1; fi
  
    if ! save_proj_cmd_ $i "$proj_name" "${PUMP_PROJ_SHORT_NAME[$i]}"; then return 1; fi
  else
    # adding a new project
    remove_proj_ $i &>/dev/null

    if ! save_proj_cmd_ $i "$proj_name"; then return 1; fi

    while [[ -z "${PUMP_PROJ_FOLDER[$i]}" ]]; do
      proj_cmd="${TEMP_PUMP_PROJ_SHORT_NAME:-$proj_cmd}"

      if ! save_proj_repo_ -a $i "${PUMP_PROJ_FOLDER[$i]}" "$TEMP_PUMP_PROJ_SHORT_NAME" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi
      if ! save_proj_folder_ -a $i "$TEMP_PUMP_PROJ_SHORT_NAME" "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}"; then return 1; fi
    done

    if is_git_repo_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=1
    elif get_proj_for_git_ "${PUMP_PROJ_FOLDER[$i]}" "$TEMP_PUMP_PROJ_SHORT_NAME" &>/dev/null; then
      PUMP_PROJ_SINGLE_MODE[$i]=0
    fi

    if ! save_proj_mode_ -a $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SINGLE_MODE[$i]}"; then return 1; fi
  fi

  if ! save_pkg_manager_ $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}"; then return 1; fi

  # if [[ -z "$TEMP_PUMP_PROJ_SHORT_NAME" ]]; then
  #   if (( save_proj_is_e )); then
  #     # editing a project, pass the old name
  #     if ! save_proj_cmd_ $i "$proj_name" "${PUMP_PROJ_SHORT_NAME[$i]}"; then return 1; fi
  #   else
  #     if ! save_proj_cmd_ $i "$proj_name"; then return 1; fi
  #   fi
  # fi

  local pkg_name=$(get_pkg_name_ "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_REPO[$i]}")
  
  if [[ -n "$pkg_name" ]]; then
    update_setting_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  fi
  
  if ! update_setting_ $i "PUMP_PROJ_SHORT_NAME" "$TEMP_PUMP_PROJ_SHORT_NAME"; then return 1; fi
  
  display_line_ "" "${SAVE_PROJ_COR}"
  print "  ${SAVE_PROJ_COR}project saved!${reset_cor}" >&1
  print "" >&1
  
  load_config_entry_ $i

  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  if [[ ! -d "${PUMP_PROJ_FOLDER[$i]}" ]]; then
    mkdir -p "${PUMP_PROJ_FOLDER[$i]}"
  fi

  if (( ! single_mode )); then
    if is_git_repo_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}" &>/dev/null; then
      if create_backup_proj_folder_ "${PUMP_PROJ_FOLDER[$i]}"; then
        print " project must be cloned again as project mode has changed" >&1
        print " run: ${yellow_cor}clone ${proj_cmd}${reset_cor}" >&1
      fi
    fi
  fi

  if (( refresh )); then
    set_current_proj_ $i
    refresh_curr_proj_ $i
    return 0;
  fi
  
  print " now run command: ${solid_blue_cor}${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor}" >&1
}
# end of save project data to config file =========================================

function refresh_curr_proj_() {
  local i="$1"

  unset_aliases_

  set_aliases_ $i

  # do not need to refresh because themes were fixed
  # if [[ -n "$ZSH_THEME" ]]; then
  #   source "$ZSH/themes/${ZSH_THEME}.zsh-theme"
  # fi
}

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
  unset -f fix &>/dev/null
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

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    return 1;
  fi

  if ! check_proj_pkg_manager_ -s $i "$CURRENT_PUMP_PKG_MANAGER" "$CURRENT_PUMP_PROJ_FOLDER" "$CURRENT_PUMP_PROJ_REPO"; then return 1; fi

  if [[ -z "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    CURRENT_PUMP_PKG_MANAGER="${PUMP_PKG_MANAGER[$i]}"
  fi

  # Reset all aliases
  #unalias -a &>/dev/null
  alias i="$CURRENT_PUMP_PKG_MANAGER install"
  alias install="$CURRENT_PUMP_PKG_MANAGER install"
  # Package manager aliases =========================================================
  alias build="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  alias deploy="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  alias fix="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")format && $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  alias format="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  alias ig="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")install --global"
  alias lint="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  alias rdev="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  alias sb="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  alias sbb="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  alias start="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
  alias tsc="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  alias watch="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")watch"

  if [[ "$CURRENT_PUMP_COV" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    alias ${CURRENT_PUMP_PKG_MANAGER:0:1}cov="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    alias ${CURRENT_PUMP_PKG_MANAGER:0:1}test="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$CURRENT_PUMP_E2E" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    alias ${CURRENT_PUMP_PKG_MANAGER:0:1}e2e="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$CURRENT_PUMP_E2EUI" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    alias ${CURRENT_PUMP_PKG_MANAGER:0:1}e2eui="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$CURRENT_PUMP_TEST_WATCH" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    alias ${CURRENT_PUMP_PKG_MANAGER:0:1}testw="$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
}

function remove_proj_() {
  local i="$1"

  local proj_name="${PUMP_PROJ_SHORT_NAME[$i]}"

  if [[ -n "$proj_name" ]]; then
    unset -f $proj_name &>/dev/null
  fi

  # unset_aliases_

  update_setting_ $i "PUMP_PROJ_SHORT_NAME" "" # let this one
  update_setting_ $i "PUMP_PROJ_FOLDER" "" &>/dev/null
  update_setting_ $i "PUMP_PROJ_REPO" "" &>/dev/null
  update_setting_ $i "PUMP_PROJ_SINGLE_MODE" "" &>/dev/null
  update_setting_ $i "PUMP_PKG_MANAGER" "" &>/dev/null
  update_setting_ $i "PUMP_CODE_EDITOR" "" &>/dev/null
  update_setting_ $i "PUMP_CLONE" "" &>/dev/null
  update_setting_ $i "PUMP_SETUP" "" &>/dev/null
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
  update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" "" &>/dev/null
  update_setting_ $i "PUMP_NVM_USE_V" "" &>/dev/null
  update_setting_ $i "PUMP_DEFAULT_BRANCH" "" &>/dev/null
  
  if [[ -n "$proj_name" ]]; then
    print " project removed: $proj_name"
  fi
}

function set_current_proj_() {
  local i="$1"

  CURRENT_PUMP_PROJ_SHORT_NAME="${PUMP_PROJ_SHORT_NAME[$i]}"
  CURRENT_PUMP_PROJ_FOLDER="${PUMP_PROJ_FOLDER[$i]}"
  CURRENT_PUMP_PROJ_REPO="${PUMP_PROJ_REPO[$i]}"
  CURRENT_PUMP_PROJ_SINGLE_MODE="${PUMP_PROJ_SINGLE_MODE[$i]}"
  CURRENT_PUMP_PKG_MANAGER="${PUMP_PKG_MANAGER[$i]}"
  CURRENT_PUMP_CODE_EDITOR="${PUMP_CODE_EDITOR[$i]}"
  CURRENT_PUMP_CLONE="${PUMP_CLONE[$i]}"
  CURRENT_PUMP_SETUP="${PUMP_SETUP[$i]}"
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
  CURRENT_PUMP_NVM_SKIP_LOOKUP="${PUMP_NVM_SKIP_LOOKUP[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"
  CURRENT_PUMP_DEFAULT_BRANCH="${PUMP_DEFAULT_BRANCH[$i]}"
}

function clear_curr_proj_() {
  unset_aliases_
  set_current_proj_ 0
}

function get_node_engine_() {
  local folder="${1:-$PWD}"

  local proj_folder=$(get_proj_for_pkg_ "$folder" "package.json")
  if [[ -z "$proj_folder" ]]; then return 1; fi

  local package_json="${proj_folder}/package.json"
  if [[ ! -f $package_json ]]; then return 1; fi

  if ! command -v nvm &>/dev/null; then return 1; fi

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

    if ! command -v nvm &>/dev/null; then return 1; fi

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
    print " ${yellow_cor}warning: no matching node versions found for engine: $node_engine ${reset_cor}" 2>/dev/tty >&2
    print " try to install a version with: nvm install" 2>/dev/tty >&2
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
    print " [${solid_magenta_cor}PUMP_PROJ_SHORT_NAME_$i=${reset_cor}${PUMP_PROJ_SHORT_NAME[$i]}]"
    print " [${solid_magenta_cor}PUMP_PROJ_FOLDER_$i=${reset_cor}${PUMP_PROJ_FOLDER[${solid_magenta_cor}$i]}]"
    print " [${solid_magenta_cor}PUMP_PROJ_REPO_$i=${reset_cor}${PUMP_PROJ_REPO[$i]}]"
    print " [${solid_magenta_cor}PUMP_PROJ_SINGLE_MODE_$i=${reset_cor}${PUMP_PROJ_SINGLE_MODE[$i]}]"
    print " [${solid_magenta_cor}PUMP_PKG_MANAGER_$i=${reset_cor}${PUMP_PKG_MANAGER[$i]}]"
    print " [${solid_magenta_cor}PUMP_RUN_$i=${reset_cor}${PUMP_RUN[$i]}]"
    print " [${solid_magenta_cor}PUMP_RUN_STAGE_$i=${reset_cor}${PUMP_RUN_STAGE[$i]}]"
    print " [${solid_magenta_cor}PUMP_RUN_PROD_$i=${reset_cor}${PUMP_RUN_PROD[$i]}]"
    print " [${solid_magenta_cor}PUMP_SETUP_$i=${reset_cor}${PUMP_SETUP[$i]}]"
    print " [${solid_magenta_cor}PUMP_CLONE_$i=${reset_cor}${PUMP_CLONE[$i]}]"
    print " [${solid_magenta_cor}PUMP_PRO_$i=${reset_cor}${PUMP_PRO[$i]}]"
    print " [${solid_magenta_cor}PUMP_USE_$i=${reset_cor}${PUMP_USE[$i]}]"
    print " [${solid_magenta_cor}PUMP_CODE_EDITOR_$i=${reset_cor}${PUMP_CODE_EDITOR[$i]}]"
    print " [${solid_magenta_cor}PUMP_COV_$i=${reset_cor}${PUMP_COV[$i]}]"
    print " [${solid_magenta_cor}PUMP_OPEN_COV_$i=${reset_cor}${PUMP_OPEN_COV_[$i]}]"
    print " [${solid_magenta_cor}PUMP_TEST_$i=${reset_cor}${PUMP_TEST[$i]}]"
    print " [${solid_magenta_cor}PUMP_RETRY_TEST_$i=${reset_cor}${PUMP_RETRY_TEST[$i]}]"
    print " [${solid_magenta_cor}PUMP_TEST_WATCH_$i=${reset_cor}${PUMP_TEST_WATCH[$i]}]"
    print " [${solid_magenta_cor}PUMP_E2E_$i=${reset_cor}${PUMP_E2E[$i]}]"
    print " [${solid_magenta_cor}PUMP_E2EUI_$i=${reset_cor}${PUMP_E2EUI[$i]}]"
    print " [${solid_magenta_cor}PUMP_PR_TEMPLATE_$i=${reset_cor}${PUMP_PR_TEMPLATE[$i]}]"
    print " [${solid_magenta_cor}PUMP_PR_REPLACE_$i=${reset_cor}${PUMP_PR_REPLACE[$i]}]"
    print " [${solid_magenta_cor}PUMP_PR_APPEND_$i=${reset_cor}${PUMP_PR_APPEND[$i]}]"
    print " [${solid_magenta_cor}PUMP_PR_RUN_TEST_$i=${reset_cor}${PUMP_PR_RUN_TEST[$i]}]"
    print " [${solid_magenta_cor}PUMP_COMMIT_ADD_$i=${reset_cor}${PUMP_COMMIT_ADD[$i]}]"
    print " [${solid_magenta_cor}PUMP_PUSH_ON_REFIX_$i=${reset_cor}${PUMP_PUSH_ON_REFIX[$i]}]"
    print " [${solid_magenta_cor}PUMP_GHA_INTERVAL_$i=${reset_cor}${PUMP_GHA_INTERVAL[$i]}]"
    print " [${solid_magenta_cor}PUMP_GHA_WORKFLOW_$i=${reset_cor}${PUMP_GHA_WORKFLOW[$i]}]"
    print " [${solid_magenta_cor}PUMP_PRINT_README_$i=${reset_cor}${PUMP_PRINT_README[$i]}]"
    print " [${solid_magenta_cor}PUMP_PKG_NAME_$i=${reset_cor}${PUMP_PKG_NAME[$i]}]"
    print " [${solid_magenta_cor}PUMP_SKIP_NVM_LOOKUP_$i=${reset_cor}${PUMP_NVM_SKIP_LOOKUP[$i]}]"
    print " [${solid_magenta_cor}PUMP_NVM_USE_V$i=${reset_cor}${PUMP_NVM_USE_V[$i]}]"
    print " [${solid_magenta_cor}PUMP_DEFAULT_BRANCH_$i=${reset_cor}${PUMP_DEFAULT_BRANCH[$i]}]"

    return 0;
  fi

  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_SHORT_NAME=${reset_cor}$CURRENT_PUMP_PROJ_SHORT_NAME]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_FOLDER=${reset_cor}$CURRENT_PUMP_PROJ_FOLDER]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_REPO=${reset_cor}$CURRENT_PUMP_PROJ_REPO]"
  print " [${solid_pink_cor}CURRENT_PUMP_PROJ_SINGLE_MODE=${reset_cor}$CURRENT_PUMP_PROJ_SINGLE_MODE]"
  print " [${solid_pink_cor}CURRENT_PUMP_PKG_MANAGER=${reset_cor}$CURRENT_PUMP_PKG_MANAGER]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN=${reset_cor}$CURRENT_PUMP_RUN]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN_STAGE=${reset_cor}$CURRENT_PUMP_RUN_STAGE]"
  print " [${solid_pink_cor}CURRENT_PUMP_RUN_PROD=${reset_cor}$CURRENT_PUMP_RUN_PROD]"
  print " [${solid_pink_cor}CURRENT_PUMP_SETUP=${reset_cor}$CURRENT_PUMP_SETUP]"
  print " [${solid_pink_cor}CURRENT_PUMP_CLONE=${reset_cor}$CURRENT_PUMP_CLONE]"
  print " [${solid_pink_cor}CURRENT_PUMP_PRO=${reset_cor}$CURRENT_PUMP_PRO]"
  print " [${solid_pink_cor}CURRENT_PUMP_USE=${reset_cor}$CURRENT_PUMP_USE]"
  print " [${solid_pink_cor}CURRENT_PUMP_CODE_EDITOR=${reset_cor}$CURRENT_PUMP_CODE_EDITOR]"
  print " [${solid_pink_cor}CURRENT_PUMP_COV=${reset_cor}$CURRENT_PUMP_COV]"
  print " [${solid_pink_cor}CURRENT_PUMP_OPEN_COV=${reset_cor}$CURRENT_PUMP_OPEN_COV]"
  print " [${solid_pink_cor}CURRENT_PUMP_TEST=${reset_cor}$CURRENT_PUMP_TEST]"
  print " [${solid_pink_cor}CURRENT_PUMP_RETRY_TEST=${reset_cor}$CURRENT_PUMP_RETRY_TEST]"
  print " [${solid_pink_cor}CURRENT_PUMP_TEST_WATCH=${reset_cor}$CURRENT_PUMP_TEST_WATCH]"
  print " [${solid_pink_cor}CURRENT_PUMP_E2E=${reset_cor}$CURRENT_PUMP_E2E]"
  print " [${solid_pink_cor}CURRENT_PUMP_E2EUI=${reset_cor}$CURRENT_PUMP_E2EUI]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_TEMPLATE=${reset_cor}$CURRENT_PUMP_PR_TEMPLATE]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_REPLACE=${reset_cor}$CURRENT_PUMP_PR_REPLACE]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_APPEND=${reset_cor}$CURRENT_PUMP_PR_APPEND]"
  print " [${solid_pink_cor}CURRENT_PUMP_PR_RUN_TEST=${reset_cor}$CURRENT_PUMP_PR_RUN_TEST]"
  print " [${solid_pink_cor}CURRENT_PUMP_COMMIT_ADD=${reset_cor}$CURRENT_PUMP_COMMIT_ADD]"
  print " [${solid_pink_cor}CURRENT_PUMP_PUSH_ON_REFIX=${reset_cor}$CURRENT_PUMP_PUSH_ON_REFIX]"
  print " [${solid_pink_cor}CURRENT_PUMP_GHA_INTERVAL=${reset_cor}$CURRENT_PUMP_GHA_INTERVAL]"
  print " [${solid_pink_cor}CURRENT_PUMP_GHA_WORKFLOW=${reset_cor}$CURRENT_PUMP_GHA_WORKFLOW"
  print " [${solid_pink_cor}CURRENT_PUMP_PRINT_README=${reset_cor}$CURRENT_PUMP_PRINT_README]"
  print " [${solid_pink_cor}CURRENT_PUMP_PKG_NAME=${reset_cor}$CURRENT_PUMP_PKG_NAME]"
  print " [${solid_pink_cor}CURRENT_PUMP_NVM_SKIP_LOOKUP=${reset_cor}$CURRENT_PUMP_NVM_SKIP_LOOKUP]"
  print " [${solid_pink_cor}CURRENT_PUMP_NVM_USE_V=${reset_cor}$CURRENT_PUMP_NVM_USE_V]"
  print " [${solid_pink_cor}CURRENT_PUMP_DEFAULT_BRANCH=${reset_cor}$CURRENT_PUMP_DEFAULT_BRANCH]"
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

  if ! find_proj_index_ "$proj_arg" &>/dev/null; then
    return 1;
  fi
}

function find_proj_index_() {
  local proj_arg="$1"
  local default_index="$2"

  if [[ -z "$proj_arg" ]]; then
    if [[ -n "$default_index" ]]; then
      echo "$default_index"
      return 0;
    fi

    print " fatal: no project argument provided" >&2
    print "  ${yellow_cor}pro -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
      echo "$i"
      return 0;
    fi
  done

  if [[ -n "$default_index" ]]; then
    echo "$default_index"
    return 0;
  fi

  print " fatal: not a valid project argument: $proj_arg" >&2
  print "  ${yellow_cor}pro${reset_cor} : to set project" >&2
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
    local found_file=$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}*" \) -prune -o -maxdepth 1 -iname "${pattern}*" -print -quit 2>/dev/null)
    
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

  if [[ ! -d "$folder" ]]; then return 1; fi

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
    pull "${proj_folder}" --quiet
  fi

  echo "$proj_folder"
}

function get_proj_for_git_() {
  local folder="${1:-$PWD}"
  local proj_cmd="$2"

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
    print "  ${yellow_cor}clone $proj_cmd${reset_cor} : to clone project" >&2
  fi

  return 1;
}

function is_git_repo_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
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

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder")
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

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

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder")
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
        echo "${remote_branch:t}"
      fi
      return 0;
    fi
    return 1;
  fi

  # get_remote_branch_ -l or get_remote_branch_
  # get remote name or local name if remote doesn't exist, always returns name
  # use it to check if branch exists in remote or local
  local ref
  for ref in refs/{remotes/{origin,upstream},heads}/$branch; do
    if git -C "$git_proj_folder" show-ref -q --verify $ref; then
      if (( get_remote_branch_is_f )); then
        echo "$ref"
      else
        echo "${ref:t}"
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
    default_branch_choice=$(choose_one_ 1 "default branch" 5 "$default_branch" "$my_branch")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    selected_default_branch="$default_branch_choice"

  elif [[ -n "$default_branch" ]]; then
    selected_default_branch="$default_branch";
  else
    selected_default_branch="$my_branch";
  fi

  echo "$selected_default_branch"
  return 0;
}

function get_default_branch_() {
  set +x
  eval "$(parse_flags_ "get_default_branch_" "f" "" "$@")"
  (( get_default_branch_is_d )) && set -x

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
    default_branch=$(get_remote_branch_ -f "$branch" "$proj_folder")
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

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder")
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
  eval "$(parse_flags_ "select_branches_" "talr" "" "$@")"
  (( select_branches_is_d )) && set -x

  local searchText="$1"
  local proj_folder="${2:-$PWD}"
  local include_special_branches="${3:-1}"
  local exclude_branches=(${@:4})

  local remote_name=$(get_remote_origin_ "$proj_folder")

  local branch_results=()

  if (( select_branches_is_a )); then
    fetch "$proj_folder" --quiet
    branch_results=("${(@f)$(git -C "$proj_folder" branch --all --list "*$searchText*" --format="%(refname:short)" \
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
    branch_results=("${(@f)$(git -C "$proj_folder" branch --list "*$searchText*" --format="%(refname:short)" \
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
    print "" >&2
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

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder")
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

  local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_cmd")
  if [[ -z "$git_proj_folder" ]]; then return 1; fi

  add-zsh-hook -d chpwd pump_chpwd_

  local _pwd="$(pwd)"
  
  cd "$git_proj_folder" # use cd here, not pushd

  pr_list=$(gh pr list | grep -i "$search_text" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}')

  cd $_pwd

  add-zsh-hook chpwd pump_chpwd_

  if [[ -z "$pr_list" ]]; then
    if [[ -n "$proj_cmd" ]]; then
      print " no pull requests found for $proj_cmd" >&2
    else
      print " no pull requests found" >&2
    fi
    return 1;
  fi

  local count=$(echo "$pr_list" | wc -l)
  local titles=$(echo "$pr_list" | cut -f2)

  local select_pr_title=""
  local RET=0

  if [[ $count -gt 20 ]]; then
    print "${purple_prompt_cor} choose pull request: ${reset_cor}" >&2
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

function open_working_() {
  local project="$node_project[$head]"
  local folder="$node_folder[$head]"
  local branch="$node_branch[$head]"

  local past_folder="$(pwd)"
  local past_branch=$(git branch --show-current)
  
  if [[ -n "$folder" ]]; then
    if pushd "$folder" &>/dev/null; then
      if [[ -n "$branch" ]]; then
        co -ex "$branch"
        ll_add_node_ "$project" "$past_folder" "$past_branch"
      fi
    fi
  elif [[ -n "$branch" ]]; then
    co -ex "$branch"
  fi
}

function get_from_pkg_json_() {
  local key_name="${1:-"name"}"
  local folder="${2:-$PWD}"
  
  local value="";
  local file="${folder}/package.json"

  if [[ -f "$file" ]]; then
    if command -v jq &>/dev/null; then
      value=$(jq -r --arg key "$key_name" '.[$key] // empty' "$file")
    else
      value=$(grep -E '"'$key_name'"\s*:\s*"' "$file" | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
    fi
    echo "$value"
    return 0;
  fi

  return 1;
}

function load_config_entry_() {
  local i=${1:-0}

  local keys=(
    PUMP_PROJ_SINGLE_MODE
    PUMP_PKG_MANAGER
    PUMP_CODE_EDITOR
    PUMP_CLONE
    PUMP_SETUP
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
        PUMP_RUN)
          value="${PUMP_PKG_MANAGER[$i]} ${run}dev"
          ;;
        PUMP_RUN_STAGE)
          value="${PUMP_PKG_MANAGER[$i]} ${run}stage"
          ;;
        PUMP_RUN_PROD)
          value="${PUMP_PKG_MANAGER[$i]} ${run}prod"
          ;;
        PUMP_SETUP)
          value="${PUMP_PKG_MANAGER[$i]} ${run}setup"
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
  load_config_entry_
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
    base_branch="$(get_default_branch_ "$proj_folder")"
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
    confirm_ "delete $type: $file"$'\e[0m'" ?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET != 0 )); then
      print -l -- " ${magenta_cor}deleted${reset_cor} $file"
      return $RET;
    fi
  fi

  # if [[ -d "$file" && -n "$pump_working_branch" && -n "$_pro" ]]; then
  #   delete_pump_working_ $(basename "$file") "$pump_working_branch" "$_pro"
  # fi
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

  for file in ${files[@]}; do
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
        confirm_ "delete all: "$'\e[94m'"${(j:, :)files[$count,-1]}"$'\e[0m'" ?"
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

  setopt null_glob
  if (( del_is_a )); then
    setopt dot_glob
  else
    setopt no_dot_glob
  fi

  local files=()
  local pattern=""

  if [[ -z "$1" ]]; then
    # capture all files in current folder
    rm -rf -- .DS_Store &>/dev/null
    files=(*)

    if (( ${#files[@]} > 1 )); then
      files=("${(@f)$(choose_multiple_ "files to delete" "${files[@]}")}")
    fi
  else
    # capture all arguments (quoted or not) as a single pattern
    pattern="$*"
    # expand the pattern — if it's a glob, this expands to matches
    files=(${(z)~pattern})
  fi

  unsetopt null_glob
    if (( del_is_a )); then
    unsetopt dot_glob
  else
    unsetopt no_dot_glob
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
      print "  ${yellow_cor}refix -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi
  if ! is_proj_folder_ "$folder"; then return 1; fi

  last_commit_msg=$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " fatal: last commit is a merge commit, create a new commit instead" >&2 
    return 1;
  fi
  
  if ! LC_ALL=C git -C "$folder" reset --soft HEAD~1 1>/dev/null; then return 1; fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="refixing... \"$last_commit_msg\"" -- sh -c "read < $pipe_name" &
  spin_pid=$!

  $CURRENT_PUMP_PKG_MANAGER run format &>/dev/null
  $CURRENT_PUMP_PKG_MANAGER run lint &>/dev/null
  $CURRENT_PUMP_PKG_MANAGER run format &>/dev/null

  print "   refixing... \"$last_commit_msg\""

  echo "done" > "$pipe_name" &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  setopt notify
  setopt monitor

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
            update_setting_ $i "PUMP_PUSH_ON_REFIX" 1
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
    print " ${yellow_cor}pro${reset_cor} : to set project" >&2
    return 1;
  fi

  local i=$(find_proj_index_ "$CURRENT_PUMP_PROJ_SHORT_NAME")
  (( i )) || return 1;

  local proj_folder="$PWD"
  local proj_repo=""
  
  if ! check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "$CURRENT_PUMP_PROJ_SHORT_NAME"; then
    return 1;
  fi
  proj_repo="${PUMP_PROJ_REPO[$i]}"

  if [[ -z "$CURRENT_PUMP_COV" || -z "$CURRENT_PUMP_SETUP" ]]; then
    print " CURRENT_PUMP_COV or CURRENT_PUMP_SETUP is missing for ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor} - edit your pump.zshenv then  ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch_arg="$1"

  branch_arg=$(get_remote_branch_ "$branch_arg" "$proj_folder")

  if [[ -z "$branch_arg" ]]; then
    print " fatal: not a valid branch argument" >&2
    print "  ${yellow_cor}covc -h${reset_cor} : to see usage" >&2
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
  
  git --no-pager log --no-merges --pretty=format:'%H | %s' \
    "${default_branch}..${my_remote_branch}" | xargs -0 | while IFS= read -r line; do
    
    local commit_hash=$(echo "$line" | cut -d'|' -f1 | xargs)
    local commit_message="$(echo "$line" | cut -d'|' -f2- | xargs)"

    commit_message="- $commit_hash - $commit_message"

    if (( read_commits_is_c )); then
      echo "$commit_message"
    fi
    
    if (( read_commits_is_t )); then
      local ticket=""
      local rest="$commit_message"

      if [[ $rest =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
        ticket="${match[1]}"
        ticket="$(echo "$ticket" | xargs)"

        if [[ $rest =~ [[:alnum:]]+-[[:digit:]]+(.*) ]]; then
          rest="${match[1]}"
          rest="$(echo "$rest" | xargs)"
        fi
      fi

      local types="fix|feat|docs|refactor|test|chore|style|revert"
      if [[ $rest =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}}):[[:space:]]*(.*)" ]]; then
        rest="${match[2]}"
      fi

      if [[ -n "$ticket" ]]; then
        pr_title="${ticket} ${rest}"
      else
        pr_title="$rest"
      fi
      
      pr_title="$(echo "$pr_title" | xargs)"
    fi
  done

  if (( read_commits_is_t )); then
    echo "$pr_title"
  fi
}

function pr() {
  set +x
  eval "$(parse_flags_ "pr_" "tl" "" "$@")"
  (( pr_is_d )) && set -x

  if (( pr_is_h )); then
    print "  ${yellow_cor}pr ${solid_yellow_cor}<title>${reset_cor} : to create a pull request"
    print "  ${yellow_cor}pr -l${reset_cor} : to create a pull request and select labels if any"
    print "  ${yellow_cor}pr -t${reset_cor} : to create a pull request only if tests pass"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: pr requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

  if gh pr view --web &>/dev/null; then
    return 0;
  fi

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
  local default_branch=$(get_default_branch_ -f)

  if [[ -z "$my_remote_branch" || -z "$default_branch" ]]; then
    print " fatal: cannot determine remote or default branch" >&2
    print " make sure the branch is pushed and a default branch is set" >&2
    return 1;
  fi

  local pr_commit_msgs=("${(@f)$(read_commits_ -c "$my_remote_branch" "$default_branch")}")
  local pr_title=$(read_commits_ -t "$my_remote_branch" "$default_branch")

  if [[ -z "$pr_commit_msgs" || -z "$pr_title" ]]; then
    print " fatal: no commits found, cannot create pull request" >&2
    return 1;
  fi

  local new_pr_title="" # must declare before input_from_ so the cancel (ctrl+c) works
  new_pr_title=$(input_from_ "Pull Request Title" "$pr_title")
  if (( $? == 130 )); then return 130; fi

  if [[ -n "$new_pr_title" ]]; then
    pr_title="$new_pr_title"
  fi

  local PR_BODY="${(F)pr_commit_msgs}"

  # for commit in "${pr_commit_msgs[@]}"; do
  #   PR_BODY+="${commit}\n"
  # done

  if [[ -n "$CURRENT_PUMP_PR_REPLACE" && -f "$CURRENT_PUMP_PR_TEMPLATE" ]]; then
    local pr_template="$(cat $CURRENT_PUMP_PR_TEMPLATE)"
    
    if [[ -n "$pr_template" ]]; then
      if (( CURRENT_PUMP_PR_APPEND )); then
        # Append commit msgs right after CURRENT_PUMP_PR_REPLACE in pr template
        PR_BODY=$(echo "$pr_template" | perl -pe "s/(\Q${CURRENT_PUMP_PR_REPLACE}\E)/\1\n\n${PR_BODY}\n/")
      else
        # Replace CURRENT_PUMP_PR_REPLACE with commit msgs in pr template
        PR_BODY=$(echo "$pr_template" | perl -pe "s/\Q${CURRENT_PUMP_PR_REPLACE}\E/${PR_BODY}/g")
      fi
    fi
  fi

  if [[ -z "$PR_BODY" ]]; then
    print " no pull request body, cannot create pull request" >&2
    return 1;
  fi

  if (( ! pr_is_t )) && [[ -z "$CURRENT_PUMP_PR_RUN_TEST" ]]; then
    if confirm_ "run tests before pull request?"; then
      if confirm_ "save this preference and don't ask again?" "save" "ask again"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_PR_RUN_TEST" 1
            break;
          fi
        done
        print ""
      fi
    fi
  fi

  if (( CURRENT_PUMP_PR_RUN_TEST || pr_is_t )); then
    test || return 1;
  fi

  # debugging purposes
  # print -- "${magenta_cor}Title:${reset_cor} $pr_title"
  # print -- "${magenta_cor}Body:${reset_cor}"
  # print -- "$PR_BODY"

  # push || return 1;

  if (( pr_is_l )); then
    local proj_repo=""

    local i=0
    for i in {1..9}; do
      if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        if check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "$CURRENT_PUMP_PROJ_SHORT_NAME"; then
          proj_repo="${PUMP_PROJ_REPO[$i]}"
        fi
        break;
      fi
    done

    if [[ -n "$proj_repo" ]]; then
      local labels=("${(@f)$(gh label list --repo "$proj_repo" --limit 25 | awk '{print $1}')}")
      
      if [[ -n "$labels" ]]; then
        local choose_labels=$(choose_multiple_ "labels" "none ${labels[@]}")
        if [[ -z "$choose_labels" ]]; then return 1; fi

        if [[ "$choose_labels" == "none" ]]; then
          gh pr create --assignee="@me" --title="$pr_title" --body="$PR_BODY" --web --head="$my_branch"
        else
          local choose_labels_comma="${(j:,:)${(f)choose_labels}}"
          gh pr create --assignee="@me" --title="$pr_title" --body="$PR_BODY" --web --head="$my_branch" --label="$choose_labels_comma"
        fi
      fi
    fi
  fi

  gh pr create --assignee="@me" --title="$pr_title" --body="$PR_BODY" --web --head="$my_branch"
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

  local proj_arg=""
  local folder_arg=""
  local _env="dev"

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    _env="$3"
    folder_arg="$2"
  elif [[ -n "$2" ]]; then
    local i=$(find_proj_index_ "$1" 2>/dev/null)
    if (( i )); then
      proj_arg="$1"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        if ! save_proj_mode_ $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SINGLE_MODE[$i]}" 1>/dev/null; then return 1; fi

        local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

        if (( single_mode )); then
          _env="$2";
        else
          folder_arg="$2";
        fi
      else
        folder_arg="$2"
      fi
    else
      folder_arg="$1"
      _env="$2"
    fi
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      _env="$1"
    else
      folder_arg="$1"
    fi
  fi
  
  local i=$(find_proj_index_ "${proj_arg:-$CURRENT_PUMP_PROJ_SHORT_NAME}" 2>/dev/null)
  (( i )) || return 1;

  if [[ "$_env" != "dev" && "$_env" != "stage" && "$_env" != "prod" ]]; then
    print " env is incorrect, valid options are: dev, stage or prod" >&2
    print "  ${yellow_cor}run -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  local proj_folder=""
  local _run=""

  if [[ "$_env" == "stage" ]]; then
    _run="${PUMP_RUN_STAGE[$i]}"
  elif [[ "$_env" == "prod" ]]; then
    _run="${PUMP_RUN_PROD[$i]}"
  else
    _run="${PUMP_RUN[$i]}"
  fi

  if [[ -n "$proj_arg" ]]; then
    if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SHORT_NAME[$i]}" "${PUMP_PROJ_REPO[$i]}"; then
      return 1;
    fi
    proj_folder="${PUMP_PROJ_FOLDER[$i]}"

    if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
      print " missing project folder or project folder doesn't exist for $proj_arg" >&2
      print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
      return 1;
    fi
  fi

  if [[ -z "$_run" ]]; then
    print " missing PUMP_RUN_$i" >&2
    print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local folder_to_execute=""

  if [[ -n "$proj_folder" && -n "$folder_arg" ]]; then
    folder_to_execute="${proj_folder}/${folder_arg}"

    if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then return 1; fi

  elif [[ -n "$proj_folder" ]]; then
    folder_to_execute="$proj_folder"

    if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then
      local dirs=($(get_folders_ "$proj_folder"))
      
      if (( ${#dirs[@]} )); then
        local folder=$(choose_one_ -a "folder to setup" "${dirs[@]}")
        if [[ -z "$folder" ]]; then return 1; fi
        
        folder_to_execute="${proj_folder}/${folder}"
      fi
    fi
  else
    folder_to_execute="$PWD"
  fi

  if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then return 1; fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "_env=$_env"
  # print "folder_to_execute=$folder_to_execute"
  # print " --------"

  cd "$folder_to_execute"

  print " running $_env on ${gray_cor}${folder_to_execute}${reset_cor}"
  print " ${solid_pink_cor}${_run}${reset_cor}"
  
  if ! eval "$_run"; then
    print " ${red_cor}failed to run PUMP_RUN_$i ${reset_cor}" >&2
    print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
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

  local proj_arg=""
  local folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    folder_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ $1; then
      proj_arg="$1"
    else
      folder_arg="$1"
    fi
  else
    proj_arg=""
  fi
  
  local i=$(find_proj_index_ "${proj_arg:-$CURRENT_PUMP_PROJ_SHORT_NAME}" 2>/dev/null)
  (( i )) || return 1;

  local proj_folder="";
  local _setup="${PUMP_SETUP[$i]}"
  local pkgManager="${PUMP_PKG_MANAGER[$i]}"

  if [[ -n "$proj_arg" ]]; then
    if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SHORT_NAME[$i]}" "${PUMP_PROJ_REPO[$i]}"; then
      return 1;
    fi
    proj_folder="${PUMP_PROJ_FOLDER[$i]}"

    if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
      print " missing project folder or project folder doesn't exist for $proj_arg" >&2
      print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
      return 1;
    fi
  fi

  if [[ -z "$_setup" ]]; then
    print " missing PUMP_SETUP_$i" >&2
    print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local folder_to_execute=""

  if [[ -n "$proj_folder" && -n "$folder_arg" ]]; then
    folder_to_execute="${proj_folder}/${folder_arg}"

    if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then return 1; fi

  elif [[ -n "$proj_folder" ]]; then
    folder_to_execute="$proj_folder"

    if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then
      local dirs=($(get_folders_ "$proj_folder"))
      
      if (( ${#dirs[@]} )); then
        local folder=$(choose_one_ -a "folder to setup" "${dirs[@]}")
        if [[ -z "$folder" ]]; then return 1; fi
        
        folder_to_execute="${proj_folder}/${folder}"
      fi
    fi
  else
    folder_to_execute="$PWD"
  fi

  if ! is_proj_folder_ "$folder_to_execute" &>/dev/null; then return 1; fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "folder_to_execute=$folder_to_execute"
  # print " --------"

  cd "$folder_to_execute"

  print " setting up ${gray_cor}${folder_to_execute}${reset_cor}"
  print " ${solid_pink_cor}${_setup}${reset_cor}"

  if ! eval "$_setup"; then
    print " ${red_cor}failed to run PUMP_SETUP_$i ${reset_cor}" >&2
    print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  print ""
  print " next thing you may wanna do:"

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    local scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' "$pkg_json")

    local entry;
    for entry in ${(f)scripts}; do
      local name="${entry%%=*}"
      local cmd="${entry#*=}"

      if [[ "$name" == "build" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}build${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")build\")"; fi
      if [[ "$name" == "deploy" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}deploy${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")deploy\")"; fi
      if [[ "$name" == "start" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}start${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")start\")"; fi
      if [[ "$name" == "dev" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")dev\")"; fi
      if [[ "$name" == "stage" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run stage${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")stage\")"; fi
      if [[ "$name" == "prod" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}run prod${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")prod\")"; fi
      if [[ "$name" == "test" && -n "$cmd" ]]; then print "  • run ${solid_magenta_cor}test${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")test\")"; fi
    done
    print "  --"
  fi

  print "  •  ${yellow_cor}help${reset_cor} : to see more options"
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
  eval "$(parse_flags_ "revs_" "" "" "$@")"
  (( revs_is_d )) && set -x

  if (( revs_is_h )); then
    if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print "  ${yellow_cor}revs${reset_cor} : to list reviews from $CURRENT_PUMP_PROJ_SHORT_NAME"
    fi
    print "  ${yellow_cor}revs <pro>${reset_cor} : to list reviews from project"
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
      print "  ${yellow_cor}revs -h${reset_cor} : to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$proj_arg" ]]; then
    print " no project is set" >&2
    print "  ${yellow_cor}pro${reset_cor} : to set project" >&2
    return 1;
  fi

  local i=$(find_proj_index_ "$proj_arg" 2>/dev/null)
  (( i )) || return 1;

  local proj_folder=""
  local single_mode=""

  if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg" "${PUMP_PROJ_REPO[$i]}"; then
    return 1;
  fi
  proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  if ! save_proj_mode_ $i "$proj_folder" "${PUMP_PROJ_SINGLE_MODE[$i]}" 1>/dev/null; then
    return 1;
  fi
  single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
    print " missing project folder or project folder doesn't exist for $proj_arg" >&2
    print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
    return 1;
  fi

  local revs_folder=$(get_revs_folder_ "$proj_folder" "$single_mode")

  local rev_options=(${~revs_folder}/rev.*(N/))

  if [[ ${#rev_options[@]} -eq 0 ]]; then
    print " no reviews found for $proj_arg" >&2
    if [[ "$proj_arg" != "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
      print -n "  ${yellow_cor}$proj_arg${reset_cor} then" >&2
    fi
    print "  ${yellow_cor}rev${reset_cor} : to open a review" >&2
    return 1;
  fi

  local rev_choice=$(choose_one_ "review to open" "${(@f)$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')}")
  if [[ -z "$rev_choice" ]]; then return 1; fi

  rev -e "$proj_arg" "${rev_choice//rev./}"
}

function rev() {
  set +x
  eval "$(parse_flags_ "rev_" "eb" "" "$@")"
  (( rev_is_d )) && set -x

  if (( rev_is_h )); then
    print "  ${yellow_cor}rev${reset_cor} : open a review by pull requests"
    print "  ${yellow_cor}rev -b${reset_cor} : open a review by branches"
    print "  ${yellow_cor}rev -e <branch>${reset_cor} : open review by an exact branch, no lookup"
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
    if is_project_ $1; then
      proj_arg="$1"
    else
      branch_arg="$1"
    fi
  fi

  local i=$(find_proj_index_ "$proj_arg")
  (( i )) || return 1;

  local proj_repo=""
  local proj_folder=""
  local single_mode=""
  local _setup=""
  local _clone=""
  local code_editor=""

  if ! check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg"; then
    return 1;
  fi
  proj_repo="${PUMP_PROJ_REPO[$i]}"

  if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg" "$proj_repo"; then
    return 1;
  fi
  proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  if ! save_proj_mode_ $i "$proj_folder" "${PUMP_PROJ_SINGLE_MODE[$i]}" 1>/dev/null; then
    return 1;
  fi
  single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  _setup="${PUMP_SETUP[$i]}"
  _clone="${PUMP_CLONE[$i]}"
  code_editor="${PUMP_CODE_EDITOR[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " missing repository uri for $proj_arg" >&2
    print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
    print " missing project folder or project folder doesn't exist for $proj_arg" >&2
    print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
    return 1;
  fi

  local revs_folder="$(get_revs_folder_ "$proj_folder" "$single_mode")"

  local branch="";

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
      print "  ${yellow_cor}rev -h${reset_cor} : to see usage" >&2
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
    fi

    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local full_rev_folder="${revs_folder}/rev.${branch_folder}"

  local skip_setup=0
  local already_merged=0;

  if [[ -d "$full_rev_folder" ]]; then
    print " opening review and pulling changes: ${green_cor}$branch ${reset_cor}"

    if ! git -C "$full_rev_folder" checkout $branch --quiet; then
      if reseta "$full_rev_folder"; then
        git -C "$full_rev_folder" checkout $branch --quiet
      else
        skip_setup=1
      fi
    fi
    
    cd "$full_rev_folder"

    if (( ! skip_setup )); then
      local git_status=$(git -C "$full_rev_folder" status --porcelain 2>/dev/null)
      if [[ -n "$git_status" ]]; then
        skip_setup=1
        
        if confirm_ "review is not clean, erase your changes and match branch to pull request?"; then
          if reseta "$full_rev_folder"; then
            if ! pull "$full_rev_folder" --quiet; then
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
        if ! pull "$full_rev_folder" --quiet; then
          skip_setup=1
          already_merged=1
        fi
      fi
    fi

  else
    local git_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg")
    if [[ -z "$git_proj_folder" ]]; then return 1; fi

    print " creating review for pull request: ${green_cor}$branch ${reset_cor}"

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
    if [[ -n "$_setup" ]]; then
      print " setting up ${gray_cor}${full_rev_folder}${reset_cor}"
      print " ${solid_pink_cor}${_setup}${reset_cor}"

      if ! eval "$_setup"; then
        print " ${red_cor}failed to run PUMP_SETUP_$i ${reset_cor}" >&2
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
        print "  ${yellow_cor}clone -h${reset_cor} : to see usage" >&2
        return 1;
      fi
    fi
  else
    if (( ${#PUMP_PROJ_SHORT_NAME} == 0 )); then
      print " no projects found" >&2
      print "  ${yellow_cor}pro -a${reset_cor} : to add a project" >&2
      return 1;
    fi

    proj_arg=$(choose_one_ -a "project to clone" "${PUMP_PROJ_SHORT_NAME[@]}")
    if [[ -z "$proj_arg" ]]; then return 1; fi
  fi
  
  local i=$(find_proj_index_ "$proj_arg")
  (( i )) || return 1;

  local proj_repo=""
  local proj_folder=""
  local single_mode=""
  local _clone="${PUMP_CLONE[$i]}"
  local print_readme="${PUMP_PRINT_README[$i]}"
  local pump_default_branch="${PUMP_DEFAULT_BRANCH[$i]}"
  local pkgManager="${PUMP_PKG_MANAGER[$i]}"

  if ! check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg"; then
    return 1;
  fi
  proj_repo="${PUMP_PROJ_REPO[$i]}"

  if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg" "$proj_repo"; then
    return 1;
  fi
  proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  if ! save_proj_mode_ $i "$proj_folder" "${PUMP_PROJ_SINGLE_MODE[$i]}" 1>/dev/null; then
    return 1;
  fi
  single_mode="${PUMP_PROJ_SINGLE_MODE[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " missing repository uri for $proj_arg" >&2
    print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    print " missing project folder or project folder doesn't exist for $proj_arg" >&2
    print "  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project" >&2
    return 1;
  fi

  if [[ ! -d "$proj_folder" ]]; then
    if ! mkdir -p "$proj_folder"; then
      print " fatal: failed to create project folder: $proj_folder" >&2
      return 1;
    fi
  fi

  local folder_to_clone=""

  local temp_default_branch_1=""
  local temp_default_branch_2=""

  local working_proj_folder=$(get_proj_for_git_ "$proj_folder" "$proj_arg" 2>/dev/null)

  if (( single_mode )); then
    rm -rf -- "${proj_folder}/.DS_Store" &>/dev/null
    if [[ -n "$working_proj_folder" || -n "$(ls -A "$proj_folder" 2>/dev/null)" ]]; then
      print " cannot clone project $proj_arg because it was set to ${pruple_cor}single mode${reset_cor} and folder is not empty: $proj_folder" >&2
      print " either clean the folder, or  ${yellow_cor}$proj_arg -e${reset_cor} : to edit project and switch to ${pink_cor}multiple mode${reset_cor}" >&2
      return 1;
    fi

    folder_to_clone="$proj_folder"
  else
    if [[ -n "$working_proj_folder" ]]; then
      if [[ -z "$branch_arg" ]]; then
        branch_arg=$(input_branch_name_ "type the name of your feature branch")
        if [[ -z "$branch_arg" ]]; then return 1; fi
      fi

      local branch_folder="${branch_arg//\\/-}"
      branch_folder="${branch_folder//\//-}"

      folder_to_clone="${proj_folder}/${branch_folder}"

      rm -rf -- "${folder_to_clone}/.DS_Store" &>/dev/null
      if [[ -d "$folder_to_clone" && -n "$(ls -A "$folder_to_clone" 2>/dev/null)" ]]; then
        print " destination path already exists and is not empty: $folder_to_clone" >&2
        print "  ${yellow_cor}${proj_arg} ${branch_folder}${reset_cor} : to go to that folder" >&2
        return 1;
      fi
    fi
  fi

  local default_branch="${default_branch_arg:-$pump_default_branch}"

  if [[ -z "$default_branch" ]]; then
    default_branch=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg")
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -z "$default_branch" ]]; then
      local placeholder=$(get_default_branch_ "$working_proj_folder")
      default_branch=$(input_branch_name_ "type the name of the default branch" "$placeholder")
      if [[ -z "$default_branch" ]]; then return 1; fi
    fi
  fi

  if [[ -z "$pump_default_branch" || "$default_branch" != "$pump_default_branch" ]]; then
    if confirm_ "save default branch "$'\e[32m'$default_branch$'\e[0m'" and don't ask again, unless it changes?"; then
      update_setting_ $i "PUMP_DEFAULT_BRANCH" $default_branch
    fi
  fi

  if [[ -z "$branch_arg" ]]; then
    branch_arg="$default_branch"
  else
    branch_arg="${${USER:0:1}:l}-$branch_arg"
    remote_branch=$(get_remote_branch_ "$branch_arg" "$proj_folder")

    if [[ -n "$remote_branch" ]]; then
      print " fatal: branch already exists on remote: $branch_arg "
      return 1;
    fi
  fi
  
  if [[ "$branch_arg" != "$my_branch" ]]; then
    print " preparing to clone branch: ${green_cor}${branch_arg}${reset_cor} based on ${solid_green_cor}${default_branch}${reset_cor}"
  else
    print " preparing to clone branch: ${green_cor}${branch_arg}${reset_cor}"
  fi

  if [[ -z "$folder_to_clone" ]]; then
    local branch_folder="${branch_arg//\\/-}"
    branch_folder="${branch_folder//\//-}"

    folder_to_clone="${proj_folder}/${branch_folder}"
  fi

  if command -v gum &>/dev/null; then
    if ! gum spin --title="cloning... $proj_repo on branch: $branch_arg" -- git clone "$proj_repo" "$folder_to_clone"; then
      print " failed to clone, either folder is not empty or have no access rights: $proj_repo" >&2
      return 1;
    fi
  else
    print " cloning... $proj_repo on branch: $branch_arg"
    if ! git clone --quiet "$proj_repo" "$folder_to_clone"; then return 1; fi
  fi

  # local past_folder="$PWD"

  cd "$folder_to_clone"

  # if (( $? == 0 )); then
  #   save_pump_working_ "$proj_arg"
  # fi

  local my_branch=$(git branch --show-current)

  if [[ "$branch_arg" != "$my_branch" ]]; then
    git checkout -b "$branch_arg" --quiet
  fi

  if [[ "$default_branch" != "$branch_arg" ]]; then
    print " ${solid_pink_cor}git config init.defaultBranch $default_branch ${reset_cor}"
    git config init.defaultBranch "$default_branch"
    git config "branch.${branch_arg}.gh-merge-base" "$default_branch"
  fi

  if [[ -n "$_clone" ]]; then
    print " ${solid_pink_cor}$_clone ${reset_cor}"
    if ! eval "$_clone"; then
      print " ${red_cor}failed to run PUMP_CLONE_$i ${reset_cor}" >&2
      print " edit your pump.zshenv config, then  ${yellow_cor}refresh${reset_cor}" >&2
    fi
  fi
  
  print ""
  print " successfully cloned project: ${solid_blue_cor}${proj_arg}${reset_cor}"
  print " default branch is ${green_cor}$(git config --get init.defaultBranch)${reset_cor}"
  
  print ""
  print " next thing you may wanna do:"

  local readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -maxdepth $maxdepth -type f -iname "README.md*" -print -quit 2>/dev/null)
  if [[ -z "$readme_file" ]]; then
    readme_file=$(find . \( -path "*/.*" -a ! -iname "README.md*" \) -prune -o -type f -iname "readme.md*" -print -quit 2>/dev/null)
  fi
  if [[ -n "$readme_file" ]]; then
    print " •  ${yellow_cor}${proj_arg} -i${reset_cor} : to show the 'readme' file"
    print " --"
  fi

  local pkg_json="package.json"
  if [[ -f $pkg_json ]]; then
    print " • run ${solid_magenta_cor}setup${reset_cor} (alias for \"$pkgManager $([[ $pkgManager == "yarn" ]] && echo "" || echo "run ")setup\" if you have in your package.json)"
    print " • run ${solid_magenta_cor}i${reset_cor} or ${solid_magenta_cor}install${reset_cor} (alias for \"$pkgManager i\")"
    print " --"
  fi

  print " •  ${yellow_cor}rev${reset_cor} : to open a review"
  print " •  ${yellow_cor}help${reset_cor} : to see more options"
  
  
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
  #       update_setting_ $i "PUMP_PRINT_README" 1
  #     else
  #       update_setting_ $i "PUMP_PRINT_README" 0
  #     fi
  #   fi
  # fi
  
}

function abort() {
  set +x
  eval "$(parse_flags_ "abort_" "" "" "$@")"
  (( abort_is_d )) && set -x

  if (( abort_is_h )); then
    print "  ${yellow_cor}abort${reset_cor} : to abort any in progress rebase, merge and cherry-pick"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  GIT_EDITOR=true git rebase --abort &>/dev/null
  GIT_EDITOR=true git merge --abort  &>/dev/null
  GIT_EDITOR=true git cherry-pick --abort &>/dev/null
}

function renb() {
  set +x
  eval "$(parse_flags_ "renb_" "" "" "$@")"
  (( renb_is_d )) && set -x

  if (( renb_is_h )); then
    print "  ${yellow_cor}renb <branch>${reset_cor} : to rename a branch"
    return 0;
  fi

  local new_name="$1"

  if [[ -z "$new_name" ]]; then
    print " missing branch name" >&2
    print "  ${yellow_cor}renb -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

  local current_name=$(git branch --show-current)
  local base_branch=$(git config --get "branch.${current_name}.gh-merge-base" 2>/dev/null)

  git branch -m "$new_name" ${@:2}

  if (( $? == 0 )); then
    git config "branch.${new_name}.gh-merge-base" "$base_branch" &>/dev/null
    git config --remove-section "branch.${current_name}" &>/dev/null

    if git push origin :"$current_name" --quiet; then
      git push --set-upstream origin "$new_name"
    fi
  fi
}

function chp() {
  set +x
  eval "$(parse_flags_ "chp_" "" "s" "$@")"
  (( chp_is_d )) && set -x

  if (( chp_is_h )); then
    print "  ${yellow_cor}chp <commit_hash>${reset_cor} : to cherry-pick a commit"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    print " missing commit hash" >&2
    print "  ${yellow_cor}chp -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi
  
  git cherry-pick "$1" ${@:2}
}

function chc() {
  set +x
  eval "$(parse_flags_ "chc_" "" "s" "$@")"
  (( chc_is_d )) && set -x

  if (( chc_is_h )); then
    print "  ${yellow_cor}chc${reset_cor} : to continue in progress cherry-pick"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  GIT_EDITOR=true git cherry-pick --continue $@ &>/dev/null
}

function mc() {
  set +x
  eval "$(parse_flags_ "mc_" "" "" "$@")"
  (( mc_is_d )) && set -x

  if (( mc_is_h )); then
    print "  ${yellow_cor}mc${reset_cor} : to continue in progress merge"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git add .

  GIT_EDITOR=true git merge --continue $@ &>/dev/null
}

function rc() {
  set +x
  eval "$(parse_flags_ "rc_" "" "" "$@")"
  (( rc_is_d )) && set -x

  if (( rc_is_h )); then
    print "  ${yellow_cor}rc${reset_cor} : to continue in progress rebase"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git add .

  GIT_EDITOR=true git rebase --continue $@ &>/dev/null
}

function cont() {
  set +x
  eval "$(parse_flags_ "cont_" "" "" "$@")"
  (( conti_is_d )) && set -x

  if (( conti_is_h )); then
    print "  ${yellow_cor}cont${reset_cor} : to continue any in progress rebase, merge or cherry-pick"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git add .
  local RET=$?

  if (( RET == 0 )); then
    GIT_EDITOR=true git rebase --continue $@ &>/dev/null
    GIT_EDITOR=true git merge --continue $@ &>/dev/null
    GIT_EDITOR=true git cherry-pick --continue $@ &>/dev/null
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
        confirm_ "add all unstaged changes to commit \""$'\e[94m'$last_commit_msg$'\e[0m'"\" ?"
        if (( $? == 130 || $? == 2 )); then return 130; fi
        if (( $? == 0 )); then
          if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi

          if git add . && confirm_ "save this preference and don't ask again?" "save" "ask again"; then
            local i=0
            for i in {1..9}; do
              if [[ "$CURRENT_PUMP_PROJ_SHORT_NAME" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
                update_setting_ $i "PUMP_COMMIT_ADD" 1
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
      print "  ${yellow_cor}fetch -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi

  local RET=0

  if (( fetch_is_t )); then 
    git -C "$folder" fetch --all --tags --prune-tags --force $@
    RET=$?
    if (( fetch_is_o )); then
      return $RET;
    fi
  fi

  local remote_name=$(get_remote_origin_ "$folder")
  local results="$(git -C "$folder" fetch $remote_name --prune $@ 2>/dev/null)"
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
  print "${solid_yellow_cor} Username:${reset_cor} $(git config --get user.name)"
  print "${solid_yellow_cor} Email:${reset_cor} $(git config --get user.email)"
  print "${solid_yellow_cor} Default branch:${reset_cor} $(git config --get init.defaultBranch)"
}

function glog() {
  set +x
  eval "$(parse_flags_ "glog_" "c" "" "$@")"
  (( glog_is_d )) && set -x

  if (( glog_is_h )); then
    print "  ${yellow_cor}glog ${solid_yellow_cor}[<folder>]${reset_cor} : to log all commits"
    print "  ${yellow_cor}glog -n${reset_cor} : to log n commits"
    print "  ${yellow_cor}glog -c${reset_cor} : to log commits from current branch for posting in comments (and to clipboard)"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print "  ${yellow_cor}glog -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi
  
  local RET=0

  if (( glog_is_c )); then
    local default_branch=$(get_default_branch_ -f)
  local my_remote_branch=$(get_remote_branch_ -f "$my_branch")

  # print "default_branch $default_branch"
  # print "my_remote_branch $my_remote_branch"

  ## TODO: Confirm this is working
  # if [[ -n "$my_remote_branch" ]]; then
  git --no-pager log --no-merges --pretty=format:'%H | %s' \
    "${default_branch}..${my_remote_branch}" | xargs -0 | while IFS= read -r line; do
    print -- "- $line"
  done

    # local merge_commits=""
    # merge_commits=($(git -C "$folder" log -100 --pretty=format:"%H %P" | awk '{ if (NF > 2) print $1 }'))

    # if [[ -z "$merge_commits" ]]; then
    #   print " no merge commits found" >&2
    #   return 1;
    # fi

    # print ""

    # local merge_hash="${merge_commits[1]}"
    # local first=$(git -C "$folder" rev-parse "$(git -C "$folder" log -1 --pretty=format:"%H")")
    # local last=$(git -C "$folder" rev-parse "${merge_hash}^2")

    # git -C "$folder" --no-pager log --oneline --graph --date=relative --no-merges --first-parent $first ^$last
    # git -C "$folder" log --no-merges --first-parent $first ^$last --pretty=format:'- %H - %s' | pbcopy
    RET=$?
  else
    git -C "$folder" --no-pager log main HEAD --oneline --graph --date=relative $@
    RET=$?
  fi

  print ""
  return $RET;
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
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
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
    if [[ -n "$branch_arg" ]]; then
      print ""
      git -C "$folder" --no-pager log --oneline "${remote_name}/${branch_arg}@{1}..${remote_name}/${branch_arg}"
      # no pbcopy
    fi
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
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
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
    git -C "$folder" push --no-verify --force $remote_name $my_branch $@
    RET=$?
  else
    git -C "$folder" push --no-verify --force-with-lease $remote_name $my_branch $@
    RET=$?
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    if [[ -n "$my_branch" ]]; then
      print ""
      git -C "$folder" --no-pager log "${remote_name}/${my_branch}@{1}..${remote_name}/${my_branch}" --oneline
      # no pbcopy
    fi
  fi

  return $RET;
}

function dtag() {
  set +x
  eval "$(parse_flags_ "dtag_" "" "q" "$@")"
  (( dtag_is_d )) && set -x

  if (( dtag_is_h )); then
    print "  ${yellow_cor}dtag${reset_cor} : to delete a tag"
    print "  ${yellow_cor}dtag ${solid_yellow_cor}<name>${reset_cor} : to delete a tag directly"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi
  
  prune --quiet

  local remote_name="$(get_remote_origin_)"

  if [[ -z "$1" ]]; then
    # list all tags suing tags command then use choose_multiple_ to select tags, then delete all selected tags
    local tags=$(tags 2>/dev/null)
    if [[ -z "$tags" ]]; then
      print " no tags found to delete" >&2
      return 0;
    fi
    local selected_tags=($(choose_multiple_ "tags to delete" $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then
      return 1;
    fi
    for tag in $selected_tags; do
      git tag "$remote_name" --delete "$tag" 2>/dev/null
      git push "$remote_name" --delete "$tag" ${@:2} 2>/dev/null
    done
    return 0;
  fi

  git tag "$remote_name" --delete "$1" 2>/dev/null
  git push "$remote_name" --delete "$1" 2>/dev/null

  return 0; # don't care if it fails to delete, consider success
}

function pull() {
  set +x
  eval "$(parse_flags_ "pull_" "to" "prqf" "$@")"
  (( pull_is_d )) && set -x

  if (( pull_is_h )); then
    print "  ${yellow_cor}pull ${solid_yellow_cor}[<branch>] [<folder>]${reset_cor} : to pull branch from origin"
    print "  ${yellow_cor}pull -t${reset_cor} : to pull tags along with branches"
    print "  ${yellow_cor}pull -to${reset_cor} : to pull tags only"
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
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print "  ${yellow_cor}push -h${reset_cor} : to see usage" >&2
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

  local remote_name=$(get_remote_origin_ "$folder")

  if ! git -C "$folder" fetch $remote_name $branch_arg; then return 1; fi

  local RET=0

  if (( pull_is_t )); then
    git -C "$folder" pull $remote_name $branch_arg --tags $@
    RET=$?
    if (( pull_is_o )); then return $RET; fi
  fi

  git -C "$folder" pull $remote_name $branch_arg $@ 2>/dev/null
  if (( $? != 0 )); then
    git -C "$folder" pull $remote_name $branch_arg --rebase $@ 2>/dev/null
    if (( $? != 0 )); then
      git -C "$folder" pull $remote_name $branch_arg --rebase --autostash $@
      return $?;
    fi
  fi

  if (( ! ${argv[(Ie)--quiet]} )); then
    print ""
    git -C "$folder" --no-pager log -1 --oneline
    # no pbcopy
  fi
}

# tagging functions ===============================================
function drelease() {
  set +x
  eval "$(parse_flags_ "drelease_" "" "" "$@")"
  (( drelease_is_d )) && set -x

  if (( drelease_is_h )); then
    print "  ${yellow_cor}drelease${reset_cor} : to delete a release and the tag"
    print "  ${yellow_cor}drelease ${solid_yellow_cor}<tag>${reset_cor} : to delete a release and the tag directly"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: drelease requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_; then return 1; fi

  local tag="$1"

  if [[ -z "$tag" ]]; then
    local tags=$(tags 2>/dev/null)
    if [[ -z "$tags" ]]; then
      print " no tags found to delete" >&2
      return 0;
    fi

    local selected_tags=($(choose_multiple_ "tags to delete" $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then
      return 1;
    fi

    for tag in $selected_tags; do
      if command -v gum &>/dev/null; then
        if ! gum spin --title="deleting... $tag" -- gh release delete "$tag" --cleanup-tag -y; then continue; fi
      else
        print " deleting... $tag"
        if ! gh release delete "$tag" --cleanup-tag -y; then continue; fi
      fi
      print " ${magenta_cor}deleted${reset_cor} $tag"
    done

    return 0;
  fi

  gh release delete "$tag" --cleanup-tag -y

  return 0; # don't care if it fails to delete, consider success
}

function release() {
  set +x
  eval "$(parse_flags_ "release_" "mnps" "" "$@")"
  (( release_is_d )) && set -x

  if (( release_is_h )); then
    print "  ${yellow_cor}release${reset_cor} : to create a new release of package.json version"
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

  if ! is_git_repo_; then return 1; fi
  if ! is_proj_folder_; then return 1; fi

  local my_branch="$(git branch --show-current)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot create release" >&2
    return 1;
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    print " uncommitted changes detected, cannot create release" >&2
    st
    return 1;
  fi

  # check if name is conventional
  if ! [[ "$my_branch" =~ ^(main|master|stage|staging|prod|production|release)$ || "$my_branch" == release* ]]; then
    print " ${yellow_cor}warning: unconventional branch to release: $my_branch ${yellow_cor}"
  fi

  local tag="$1"

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

      if ! pull --quiet; then return 1; fi

      if [[ -n "$release_type" ]]; then
        if ! npm version "$release_type" --no-commit-hooks --no-git-tag-version &>/dev/null; then
          print " fatal: not able to bump version: $release_type" >&2
          return 1;
        fi
      fi

      tag="$(npm pkg get version --workspaces=false | tr -d '"' 2>/dev/null)"
    fi

    if [[ -z "$tag" ]]; then
      local latest_tag=$(tags 1 2>/dev/null)
      local pkg_tag=""

      pkg_tag="$(get_from_pkg_json_ "version")"

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
    if ! confirm_ "create release: $tag ?"; then
      clean
      return 1;
    fi
  fi

  # check of git status is dirty
  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -n "$git_status" ]]; then
    if ! git add .; then return 1; fi
    if ! git commit --no-verify --message="chore: release version $tag"; then return 1; fi
  fi
  
  if gh release view "$tag" 1>/dev/null 2>&1; then
    if (( ! release_is_s )); then
      if ! confirm_ "$tag has already been released, delete and release again?"; then
        return 1;
      fi
    fi
    release_is_s=1
    gh release delete "$tag" --yes
  fi

  # check if tag already exists
  local existing_tag="$(git tag --list "$tag" 2>/dev/null)"
  if [[ -n "$existing_tag" ]]; then
    if (( ! release_is_s )); then
      if ! confirm_ "$tag already exists, delete and release again?"; then
        return 1;
      fi
    fi
    if ! dtag "$tag" --quiet; then return 1; fi
  fi

  if ! tag "$tag"; then return 1; fi
  if ! push --tags --quiet; then return 1; fi

  gh release create "$tag" --title="$tag" --generate-notes
}

function tag() {
  set +x
  eval "$(parse_flags_ "tag_" "" "" "$@")"
  (( tag_is_d )) && set -x

  if (( tag_is_h )); then
    print " release_ = ${yellow_cor}tag${reset_cor} : to create a new tag from package.json version"
    print " release_ = ${yellow_cor}tag ${solid_yellow_cor}<name>${reset_cor} : to create a new tag directly"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi
  if ! is_proj_folder_; then return 1; fi
  
  prune &>/dev/null

  local tag="$1"

  if [[ -z "$tag" ]]; then
    tag=$(get_from_pkg_json_ "version")
    if [[ -n "$tag" ]]; then
      if ! confirm_ "create tag: $tag ?"; then
        tag=""
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    tag=$(input_path_ "type the tag name")
    if [[ -z "$tag" ]]; then return 1; fi
  fi

  git tag --annotate "$tag" --message="$tag" ${@:2}
  local RET=$?

  if (( RET == 0 )); then
    git push --no-verify --tags
    RET=$?
  fi

  return $RET;
}

function tags() {
  set +x
  eval "$(parse_flags_ "tags_" "" "" "$@")"
  (( tags_is_d )) && set -x

  if (( tags_is_h )); then
    print "  ${yellow_cor}tags${reset_cor} : to list all tags"
    print "  ${yellow_cor}tags <x>${reset_cor} : to list x number of tags"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  prune &>/dev/null

  local n="${1:-100}"
  local tags=""

  if (( n == 1 )); then
    tags=$(git describe --tags --abbrev=0 2>/dev/null)
  fi

  if [[ -z "$tags" ]]; then
    tags=$(git for-each-ref refs/tags --sort=-taggerdate --format='%(refname:short)' --count="$n")
  fi

  if [[ -z "$tags" ]]; then
    tags=$(git for-each-ref refs/tags --sort=-creatordate --format='%(refname:short)' --count="$n")
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
      print "  ${yellow_cor}restore -h${reset_cor} : to see usage" >&2
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
      print "  ${yellow_cor}clean -h${reset_cor} : to see usage" >&2
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
      print "  ${yellow_cor}discard -h${reset_cor} : to see usage" >&2
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
      print "  ${yellow_cor}reseta -h${reset_cor} : to see usage" >&2
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

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print "  ${yellow_cor}prune -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi

  fetch --quiet

  local link=""

  local repo=$(get_repo_ "$folder")
  if [[ -n "$repo" ]]; then
    local repo_name=$(get_repo_name_ "$repo" 2>/dev/null)
    link="https://github.com/$repo_name/tree/"
  fi

  gum spin --title="loading..." -- git -C "$folder" branch -r --list "*$1*" --sort=authordate --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' | sed \
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

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print "  ${yellow_cor}prune -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi

  git -C "$folder" branch --list "*$1*" --sort=authordate --format="%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=2)" | sed \
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
    local i=$(find_proj_index_ "$proj_arg")
    (( i )) || return 1;

    found=$i;

    if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "${PUMP_PROJ_SHORT_NAME[$i]}" "${PUMP_PROJ_REPO[$i]}"; then
      return 1;
    fi
    
    proj_folder=$(get_proj_for_git_ "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg")
    if [[ -z "$proj_folder" ]]; then return 1; fi

    if ! check_proj_repo_ -se $i "${PUMP_PROJ_REPO[$i]}" "${PUMP_PROJ_FOLDER[$i]}" "$proj_arg"; then
      return 1;
    fi
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
    if confirm_ "would you like to save \"$workflow_arg\" as the default workflow for this project?"; then
      update_setting_ $found "PUMP_GHA_WORKFLOW" "\"$workflow_arg\""
    fi
  fi

  return $RET;
}

function is_branch_() {
  set +x
  eval "$(parse_flags_ "is_branch_" "alr" "" "$@")"
  (( abort_is_d )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  # check if branch exists locally
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    return 0;
  fi

  # check if it exists remotely (on origin)
  if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
    return 0;
  fi
  
  return 1; # not a branch
}

function co() {
  set +x
  eval "$(parse_flags_ "co_" "alprexbcq" "" "$@")"
  (( co_is_d )) && set -x

  if (( co_is_h )); then
    print "  ${yellow_cor}co${reset_cor} : to switch to a branch"
    print "  --"
    print "  ${yellow_cor}co -a${reset_cor} : to list all branches (default)"
    print "  ${yellow_cor}co -l${reset_cor} : to list only local branches"
    print "  ${yellow_cor}co -pr${reset_cor} : to list pull requests instead (for quick code reviews)"
    print "  --"
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
      local default_branch=$(get_default_branch_ "$proj_folder")

      print " succeed detached pull request: ${green_cor}${pr[3]}${reset_cor}"
      print " HEAD is now at $(git log -1 --pretty=format:'%h %s')"
      print " your branch is detached, you may now run:"
      print "  ${yellow_cor}co ${pr[2]}${reset_cor} : to switch to the branch"
      print "  ${yellow_cor}co ${${USER:0:1}:l}-${pr[2]} ${default_branch}${reset_cor} : to create branch off of a base branch"
    fi

    return $RET;
  fi

  if (( co_is_p || co_is_r )); then
    print " ${red_cor}fatal: invalid option${reset_cor}" >&2
    print "  ${yellow_cor}co -pr${reset_cor} : to select from pull requests instead of branches and detach HEAD"
    return 1;
  fi

  # co -a all branches
  if (( co_is_a )); then
    local branch_choice="$(select_branch_ -at "$1" "branch" "$PWD" "$(git branch --show-current)")"
    
    if [[ -z "$branch_choice" ]]; then return 1; fi

    if [[ -n "$1" ]]; then
      co -e "$branch_choice" ${@:2}
    else
      co -e "$branch_choice" $@
    fi
    return $?;
  fi

  # co -l local branches
  if (( co_is_l )); then
    local branch_choice=""
    # 2>/dev/null because we call co -a later
    branch_choice="$(select_branch_ -lt "$1" "branch" "$PWD" "$(git branch --show-current)" 2>/dev/null)"
    if (( $? == 130 )); then return 1; fi
    
    if [[ -z "$branch_choice" ]]; then
      co -a $@
      return $?;
    fi

    if [[ -n "$1" ]]; then
      co -e "$branch_choice" ${@:2}
    else
      co -e "$branch_choice" $@
    fi
    return $?;
  fi

  # co -b or -c branch create branch
  if (( co_is_b || co_is_c )); then
    local branch="$1"
    local base_branch="$2"

    if [[ -n "$base_branch" ]]; then
      co "$branch" "$base_branch"
      return $?;
    fi

    base_branch=$(git branch --show-current)

    if [[ -n "$base_branch" ]]; then
      co "$branch" "$base_branch"
    else
      print " fatal: cannot create branch from detached branch" >&2
      print "  ${yellow_cor}co <branch> <base_branch>${reset_cor} : to create branch off of a base branch"
      return 1;
    fi
  fi

  # co -e branch just checkout, do not create branch
  if (( co_is_e || co_is_x )); then
    local branch="$1"

    if [[ -z "$branch" ]]; then
      print " fatal: branch is required" >&2
      return 1;
    fi
    
    # local current_branch=$(git branch --show-current)
    # local _past_folder="$(pwd)"

    git switch "$branch" ${@:2}
    RET=$?

    # if (( RET == 0 )); then
    #   ll_add_node_
    # fi

    return $RET;
  fi

  # co $1 or co (no arguments)
  if [[ -z "$2" || "$2" == --* ]]; then
    co -a $@
    return $?;
  fi

  # co branch BASE_BRANCH (creating branch)
  local branch="$1"

  if [[ -z "$branch" ]]; then
    print " fatal: branch argument is required" >&2
    return 1;
  fi

  local remote_branch="$(get_remote_branch_ "$branch")"

  if [[ -n "$remote_branch" ]]; then
    print " fatal: branch already exists on remote: $branch" >&2
    return 1;
  fi

  local base_branch="$(select_branch_ -at "$2" "base branch")"
  if [[ -z "$base_branch" ]]; then return 1; fi

  if ! git checkout -b "$branch" "$base_branch" ${@:3}; then return 1; fi

  # ll_add_node_

  git config "branch.${branch}.gh-merge-base" "$base_branch"
  
  return 0;
}

function next() {
  set +x
  eval "$(parse_flags_ "next_" "" "" "$@")"
  (( next_is_d )) && set -x

  if (( next_is_h )); then
    print "  ${yellow_cor}next${reset_cor} : to go the next folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " fatal: no next folder or branch found" >&2
    return 1;
  fi

  $head=$ll_next[$head]
  open_working_
}

function prev() {
  set +x
  eval "$(parse_flags_ "prev_" "" "" "$@")"
  (( prev_is_d )) && set -x

  if (( prev_is_h )); then
    print "  ${yellow_cor}prev${reset_cor} : to go the previous folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " fatal: no previous folder or branch found" >&2
    return 1;
  fi

  $head=$ll_prev[$head]
  open_working_
}

function back() {
  set +x
  eval "$(parse_flags_ "back_" "" "" "$@")"
  (( back_is_d )) && set -x

  if (( back_is_h )); then
    print "  ${yellow_cor}back${reset_cor} : to go back the previous branch"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  git switch -

  # if (( $? == 0 )); then
  #   $head=$ll_prev[$head]
  #   open_working_
  # fi
}

function dev() {
  # checkout dev or develop branch
  set +x
  eval "$(parse_flags_ "dev_" "" "" "$@")"
  (( dev_is_d )) && set -x

  if (( dev_is_h )); then
    print "  ${yellow_cor}dev${reset_cor} : to switch to dev branch in current project"
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
      print "  ${yellow_cor}prod${reset_cor} : to switch to production branch in current project"
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
      print "  ${yellow_cor}stage${reset_cor} : to switch to staging branch in current project"
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
    print "  ${yellow_cor}rebase${reset_cor} : to apply the commits from your branch on top of the HEAD of $(git config --get init.defaultBranch)"
    print "  ${yellow_cor}rebase ${solid_yellow_cor}<base_branch> [<folder>]${reset_cor} : to apply the commits on top of the HEAD of base branch"
    print "  ${yellow_cor}rebase -a${reset_cor} : to rebase multiple branches"
    print "  ${yellow_cor}rebase -p${reset_cor} : to push after rebase succeeds with no conflicts"
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
      print "  ${yellow_cor}rebase -h${reset_cor} : to see usage" >&2
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

  # print " base branch is: ${solid_green_cor}${base_branch}${reset_cor}"
  # print " folder: ${solid_green_cor}${folder}${reset_cor}"
  # print " branch_arg: ${solid_green_cor}${branch_arg}${reset_cor}"
  # print " @: $@"
  # print " {@:4}: ${@:4}"

  # return 0;

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  if (( rebase_is_a )); then
    local selected_branches=($(select_branches_ -lt "" "$folder" 0 "$base_branch"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local RET=0

    local b=""
    for b in ${selected_branches[@]}; do
      if ! rebase "$base_branch" "$folder" "$b" $@; then
        RET=1
        break;
      fi
    done

    return $RET;
  fi

  if [[ "$branch_arg" == "$base_branch" ]]; then
    print " fatal: cannot rebase, branches are the same: $branch_arg" >&2
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
    print "  ${yellow_cor}merge${reset_cor} : to create a new merge commit from $(git config --get init.defaultBranch)"
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
      print "  ${yellow_cor}merge -h${reset_cor} : to see usage" >&2
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

  shift $arg_count

  local remote_name=$(get_remote_origin_ "$folder")
  base_branch=$(echo "$base_branch" | sed "s/^${remote_name}\///")

  if (( merge_is_a )); then
    local selected_branches=($(select_branches_ -lt "" "$folder" 0 "$base_branch"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local RET=0

    local b=""
    for b in ${selected_branches[@]}; do
      if ! merge "$base_branch" "$folder" "$b" $@; then
        RET=1
        break;
      fi
    done

    return $RET;
  fi

  if [[ "$branch_arg" == "$base_branch" ]]; then
    print " fatal: cannot merge, branches are the same: $branch_arg" >&2
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
      print "  ${yellow_cor}prune -h${reset_cor} : to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_git_repo_ "$folder"; then return 1; fi

  local default_main_branch=$(git -C "$folder" config --get init.defaultBranch)

  # delete all local tags
  # git tag -l | xargs git tag -d 1>/dev/null

  # Get all local tags
  local local_tags=("${(@f)$(git -C "$folder" tag)}")

  # Get all remote tags (strip refs/tags/)
  local remote_tags=("${(@f)$(git -C "$folder" ls-remote --tags origin)}")
  local remote_tag_names=()
  
  for line in "${remote_tags[@]}"; do
    [[ $line =~ refs/tags/(.+)$ ]] && remote_tag_names+=("${match[1]}")
  done

  local tag=""
  # Remove local tags not in remote
  for tag in "${local_tags[@]}"; do
    if ! [[ "${remote_tag_names[@]}" == *"$tag"* ]]; then
      git -C "$folder" tag -d "$tag"
    fi
  done

  # fetch tags that exist in the remote
  fetch "$folder" -t --quiet
  
  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches="$(git -C "$folder" branch --merged | grep -v "^\*\\|${default_main_branch}" | sed 's/^[ *]*//')"

  for branch in $branches; do
    git -C "$folder" branch -D "$branch"
    git -C "$folder" config --remove-section "branch.${branch}" &>/dev/null
  done

  local current_branches=$(git -C "$folder" branch --format '%(refname:short)')

  # Loop through all Git config sections to find old branches
  for config in $(git -C "$folder" config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    # Check if the branch exists locally
    if ! echo "$current_branches" | grep -q "^$branch_name\$"; then
      git -C "$folder" config --remove-section "branch."$branch_name"" &>/dev/null
    fi
  done

  git -C "$folder" prune $@
}

function delb() {
  set +x
  eval "$(parse_flags_ "delb_" "sra" "" "$@")"
  (( delb_is_d )) && set -x

  if (( delb_is_h )); then
    print "  ${yellow_cor}delb ${solid_yellow_cor}[<branch>]${reset_cor} : to delete a branch locally "
    print "  ${yellow_cor}delb -r ${solid_yellow_cor}[<branch>]${reset_cor} : to also delete remotely (excludes main branches)"
    print "  ${yellow_cor}delb -a${reset_cor} : to include all branches (use with -r)"
    print "  ${yellow_cor}delb -s${reset_cor} : to skip confirmation (cannot use with -r)"
    return 0;
  fi

  if ! is_git_repo_; then return 1; fi

  if (( delb_is_s && delb_is_r )); then
    print " ${red_cor}fatal: cannot use -s and -r together${reset_cor}" >&2
    print "  ${yellow_cor}delb -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  local branch_arg="$1"
  local deleted_branches=()

  if (( delb_is_r )); then
    selected_branches=($(select_branches_ -r "$branch_arg" "$PWD" "$delb_is_a"))
  else
    selected_branches=($(select_branches_ -l "$branch_arg" "$PWD" 1))
  fi
  
  if [[ -z "$selected_branches" ]]; then return 1; fi

  local RET=0

  for branch in ${selected_branches[@]}; do
    if (( ! delb_is_s || delb_is_r )); then
      local origin=$((( delb_is_r )) && echo "remote" || echo "local")
      confirm_ "delete ${origin} branch: "$'\e[0;95m'$branch$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi
    # git already does that
    # git config --remove-section "branch.${branch}" &>/dev/null

    if (( delb_is_r )); then
      local remote_name=$(get_remote_origin_)

      git branch -D "$branch" &>/dev/null
      git push --delete "$remote_name" "$branch"
    else
      git branch -D "$branch"
    fi
    RET=$?
    if (( RET == 0 )); then
      deleted_branches+=("$branch")
    fi
  done

  # if (( ${#deleted_branches[@]} )); then
  #   delete_pump_workings_ "$pump_working_branch" "$proj_arg" "${deleted_branches[@]}"
  # fi

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
      print "  ${yellow_cor}st -h${reset_cor} : to see usage" >&2
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
  eval "$(parse_flags_ "pro_" "aerucfilnx" "" "$@")"
  (( pro_is_d )) && set -x

  if (( pro_is_h )); then
    print "  ${yellow_cor}pro <name>${reset_cor} : to set a project"
    print "  ${yellow_cor}pro -a ${solid_yellow_cor}<name>${reset_cor} : to add new project"
    print "  ${yellow_cor}pro -e <name>${reset_cor} : to edit a project"
    print "  ${yellow_cor}pro -r <name>${reset_cor} : to remove a project"
    print "  --"
    print "  ${yellow_cor}pro -i <name>${reset_cor} : to display the project's readme if available"
    print "  ${yellow_cor}pro -n <name>${reset_cor} : to set Node.js version for a project"
    print "  ${yellow_cor}pro -c ${solid_yellow_cor}<name>${reset_cor} : to show a project's settings"
    print "  ${yellow_cor}pro -u ${solid_yellow_cor}<name>${reset_cor} : to unset project's \"don't ask again\" settings"
    pro -l
    return 0;
  fi

  if (( pro_is_l )); then
    # pro -l list projects
    print "  --"
    if (( ${#PUMP_PROJ_SHORT_NAME} == 0 )); then
      print "  no projects yet" >&2
      print "   ${yellow_cor}pro -a <name>${reset_cor} : to add a new project" >&2
      return 1;
    fi
    
    if [[ -n "${PUMP_PROJ_SHORT_NAME[*]}" ]]; then
      local i=0
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          print "  ${solid_blue_cor}${PUMP_PROJ_SHORT_NAME[$i]}${reset_cor} : to set project ${PUMP_PROJ_SHORT_NAME[$i]}"
        fi
      done
    fi

    return 0;
  fi

  local proj_arg="$1"

  # pro -i [<name>] display project readme
  if (( pro_is_i )); then
    if [[ -z "$proj_arg" ]]; then
      proj_arg="${CURRENT_PUMP_PROJ_SHORT_NAME}"
    fi

    local i=$(find_proj_index_ "$proj_arg")
    (( i )) || return 1;

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
    local i=$(find_proj_index_ "$proj_arg" 0 2>/dev/null)

    update_setting_ $i "PUMP_PR_RUN_TEST" "" &>/dev/null
    update_setting_ $i "PUMP_COMMIT_ADD" "" &>/dev/null
    update_setting_ $i "PUMP_PUSH_ON_REFIX" "" &>/dev/null
    update_setting_ $i "PUMP_PRINT_README" "" &>/dev/null
    update_setting_ $i "PUMP_GHA_WORKFLOW" "" &>/dev/null
    update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" "" &>/dev/null
    update_setting_ $i "PUMP_NVM_USE_V" "" &>/dev/null
    update_setting_ $i "PUMP_DEFAULT_BRANCH" "" &>/dev/null
    update_setting_ $i "PUMP_CODE_EDITOR" "" &>/dev/null
    
    return $?;
  fi

  # pro -c [<name>] show project config
  if (( pro_is_c )); then
    local i=$(find_proj_index_ "$proj_arg" 0 2>/dev/null)
    
    print_current_proj_ $i
    return $?;
  fi

  # pro -e <name> edit project
  if (( pro_is_e )); then
    local i=$(find_proj_index_ "$proj_arg")
    (( i )) || return 1;

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

    print " fatal: no more slots available, please remove a project to add a new one" >&2
    print "  ${yellow_cor}pro -h${reset_cor} : to see usage" >&2
    return 1;
  fi

  # pro -r <name> remove project
  if (( pro_is_r )); then
    local i=$(find_proj_index_ "$proj_arg")

    if (( ! i )); then
      local projects=()
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          projects+=("${PUMP_PROJ_SHORT_NAME[$i]}")
        fi
      done
      if (( ${#projects[@]} == 0 )); then
        print " fatal: no projects to remove" >&2
        print "  ${yellow_cor}pro -l${reset_cor} : to see available projects" >&2
        return 1;
      fi
      
      local selected_projects=$(choose_multiple_ "project to remove" "${(@f)$(printf "%s\n" "${projects[@]}")}")
      if [[ -z "$selected_projects" ]]; then return 1; fi

      local proj=""
      for proj in ${selected_projects[@]}; do
        local refresh=0;
        [[ "$proj" == "$CURRENT_PUMP_PROJ_SHORT_NAME" ]] && refresh=1;

        if ! remove_proj_ $i; then
          return 1;
        fi

        print " removed: ${solid_blue_cor}${proj}${reset_cor}"

        if (( refresh )); then
          clear_curr_proj_
          refresh_curr_proj_ $i
        fi
      done
      return $?;
    fi

    return 1;
  fi

  # pro -n <name> set Node.js version for a project
  if (( pro_is_n )); then
    local i=$(find_proj_index_ "$proj_arg")
    (( i )) || return 1;

    local nvm_skip_lookup="${PUMP_NVM_SKIP_LOOKUP[$i]}"
    local proj_folder="${PUMP_PROJ_FOLDER[$i]}"
    local pump_pro="${PUMP_PRO[$i]}"

    # if (( pro_is_f )); then
    #   echo "$CURRENT_PUMP_PROJ_SHORT_NAME" > "$PUMP_PRO_PWD_FILE"
    # else
    #   echo "$CURRENT_PUMP_PROJ_SHORT_NAME" > "$PUMP_PRO_FILE"
    # fi

    local version_to_use=""
    local RET=1;

    if (( nvm_skip_lookup && pro_is_x )); then
      local nvm_use_v="${PUMP_NVM_USE_V[$i]}"
      version_to_use="$nvm_use_v"

      if [[ -n "$version_to_use" ]] && command -v nvm &>/dev/null; then
        nvm use "$version_to_use"
        RET=$?
      fi
    else
      setopt NO_NOTIFY
      {
        # exec
        gum spin --title="detecting Node.js..." -- bash -c 'sleep 3'
        # echo -e "\r\033[K"
        # tput sgr0
      } 2>/dev/tty

      # gum spin --title="detecting Node.js engine..." -- sleep 2 2>/dev/tty &!

      proj_folder=$(get_proj_for_pkg_ "$proj_folder" "package.json")
      if [[ -z "$proj_folder" ]]; then
        return 1;
      fi

      local node_engine=$(get_node_engine_ "$proj_folder")

      if [[ -n "$node_engine" ]]; then
        local versions=()
        versions=("${(@f)$(get_node_versions_ "$proj_folder" "oldest" "$node_engine")}")
          
        # if [[ -n "$nvm_use_v" ]] && \
        #     [[ ! " ${versions[@]} " =~ " ${nvm_use_v} " ]] && \
        #     is_node_version_valid_ "$node_engine" "$nvm_use_v"; \
        # then
        #   versions+=("${nvm_use_v}")
        # fi

        if (( ${#versions[@]} > 2 )); then
          version_to_use=$(choose_one_ "Node.js version to use with ${proj_arg}'s engine $node_engine" "${(@f)$(printf "%s\n" "${versions[@]}" | sort -V)}")
          RET=$?

        elif (( ${#versions[@]} == 2 )); then
          confirm_ "Node.js version to use with ${proj_arg}'s engine $node_engine:" "${versions[1]}" "${versions[2]}"
          RET=$?
          if (( RET == 0 )); then
            version_to_use="${versions[1]}"
          elif (( RET == 1 )); then
            version_to_use="${versions[2]}"
          fi

        elif (( ${#versions[@]} == 1 )); then
          version_to_use="${versions[1]}"
        fi
      fi

      if [[ -n "$version_to_use" ]]; then
        if command -v nvm &>/dev/null; then
          local major_version=$(get_major_version_ "$version_to_use")
          if [[ -z "$major_version" ]]; then major_version="$version_to_use"; fi
          if nvm use "$major_version"; then
            update_setting_ $i "PUMP_NVM_USE_V" "$major_version" &>/dev/null
            RET=0
          fi
        fi
      fi
    fi

    if [[ -n "$pump_pro" ]]; then
      eval "$pump_pro"
    fi

    if (( RET == 0 && pro_is_x )) && [[ -z "$nvm_skip_lookup" ]]; then
      confirm_ "save Node.js version to skip checking for versions from now on? you won't be asked again"
      local _RET=$?

      if (( _RET == 0 )); then
        update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" 1 &>/dev/null
      elif (( _RET == 1 )); then
        update_setting_ $i "PUMP_NVM_SKIP_LOOKUP" 0 &>/dev/null
      fi
    fi

    return $RET;
  fi

  # pro pwd project based on current working directory
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(find_proj_by_folder_)

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      if ! is_proj_folder_ &>/dev/null; then return 1; fi
      
      local pkg_name=$(get_pkg_name_)
      local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")

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
        if confirm_ "would you like to add project: "$'\e[38;5;201m'"$pkg_name"$'\e[0m'" ?"; then
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
    else
      print " fatal: not a valid project argument" >&2
    fi

    print "  ${yellow_cor}pro -h${reset_cor} : to see usage" >&2
    pro -l
    
    return 1;
  fi

  # pro <name>
  local i=$(find_proj_index_ "$proj_arg")
  if (( ! i )); then
    pro -l
    return 1;
  fi

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

  if (( pro_is_f )) || [[ "$proj_arg" != "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    set_current_proj_ $i
    # refresh the current project
    print -n " project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJ_SHORT_NAME}${reset_cor}" >/dev/tty
    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" >/dev/tty
    fi
    print "" >/dev/tty

    refresh_curr_proj_ $i

    pro -nx "$proj_arg"
  fi
}

function proj_handler() {
  # project handler =========================================================
  # pump()
  local i="$1"
  shift

  set +x
  eval "$(parse_flags_ "proj_handler_" "meincu" "" "$@")"
  (( proj_handler_is_d )) && set -x

  local proj_cmd="${PUMP_PROJ_SHORT_NAME[$i]}"

  if ! check_proj_folder_ -s $i "${PUMP_PROJ_FOLDER[$i]}" "$proj_cmd" "${PUMP_PROJ_REPO[$i]}"; then
    return 1;
  fi

  local proj_folder="${PUMP_PROJ_FOLDER[$i]}"

  if [[ -z "$proj_folder" ]]; then return 1; fi

  local working="${PUMP_WORKING[$i]}"

  if ! save_proj_mode_ -q $i "$proj_folder" "${PUMP_PROJ_SINGLE_MODE[$i]}"; then return 1; fi
  
  local single_mode="${PUMP_PROJ_SINGLE_MODE[$i]:-1}"

  if (( proj_handler_is_h )); then
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd${reset_cor} : to open a $proj_cmd folder"
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd -m${reset_cor} : to open the $proj_cmd's default folder"
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd <folder>${reset_cor} : to open a $proj_cmd's folder"
    
    (( single_mode )) && print "  ${yellow_cor}$proj_cmd${reset_cor} : to open $proj_cmd"
    (( single_mode )) && print "  ${yellow_cor}$proj_cmd <branch>${reset_cor} : to open $proj_cmd and switch to branch"
    print "  --"
    print "  ${yellow_cor}$proj_cmd -e${reset_cor} : to edit ${proj_cmd}"
    print "  ${yellow_cor}$proj_cmd -i${reset_cor} : to display ${proj_cmd}'s readme if available"
    print "  ${yellow_cor}$proj_cmd -n${reset_cor} : to set Node.js version for $proj_cmd"
    print "  ${yellow_cor}$proj_cmd -c${reset_cor} : to show ${proj_cmd}'s settings"
    print "  ${yellow_cor}$proj_cmd -u${reset_cor} : to unset ${proj_cmd}'s \"don't ask again\" settings"
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

  if (( proj_handler_is_c )); then
    pro -c "$proj_cmd"
    return $?
  fi

  if (( proj_handler_is_u )); then
    pro -u "$proj_cmd"
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
        print "  ${yellow_cor}$proj_cmd -h${reset_cor} : to see usage" >&2
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
    else  
      local dirs=($(get_folders_ "$proj_folder"))
      
      if (( ${#dirs[@]} )); then
        local chosen_folder=($(choose_one_ -a "folder to open" "${dirs[@]}"))
        
        if [[ -n "$chosen_folder" ]]; then
          resolved_folder="${proj_folder}/${chosen_folder}"
        fi
      fi
    fi
  fi

  mkdir -p $resolved_folder
  cd "$resolved_folder"

  if [[ -z "$(ls "$resolved_folder")" ]]; then
    print " project folder is empty" >&1
    print " run: ${yellow_cor}clone ${proj_cmd}${reset_cor}" >&1
  else
    if [[ -n "$branch_arg" ]]; then
      co "$branch_arg"
    fi
  fi

  # pro $proj_cmd
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
    print "  ${yellow_cor}${COMMIT1}${reset_cor} : to open commit wizard"
    print "  ${yellow_cor}${COMMIT1} <message>${reset_cor} : to commit with message (no wizard)"
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
            update_setting_ $i "PUMP_COMMIT_ADD" 1
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
    local type_commit=$(gum choose "fix" "feat" "docs" "refactor" "test" "chore" "style" "revert")
    if [[ -z "$type_commit" ]]; then
      return 0;
    fi

    # scope is optional
    scope_commit=$(gum input --placeholder "scope")
    if (( $? != 0 )); then return 0; fi
    
    if [[ -n "$scope_commit" ]]; then
      scope_commit="($scope_commit)"
    fi

    local msg_arg=""

    msg_arg="$(gum input --value "${type_commit}${scope_commit}: ")"
    if (( $? != 0 )); then return 0; fi

    local my_branch=$(git branch --show-current)
    
    if [[ $my_branch =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then # [A-Z]+-[0-9]+
      local ticket="${match[1]} "
      local skip=0;

      # check if an old commit message already contains the ticket number
      git log -n 15 --pretty=format:"%s" | xargs -0 | while read -r line; do
        if [[ "$line" == "$ticket"* ]]; then
          skip=1;
          break;
        fi
      done

      if (( skip == 0 )); then
        msg_arg="$ticket $commit_msg"
      fi
    fi

    git commit --no-verify --message "$msg_arg" $@
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
  else
    print ""
    display_line_ "no project is set" "${red_cor}"
    print ""
    if (( ${#PUMP_PROJ_SHORT_NAME} == 0 )); then
      pro -a
    else
      print "  ${red_cor}pro <name>${reset_cor}\t = to set project and enable commands not listed here"
      local i=0
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJ_FOLDER[$i]}" && -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
          local short="${PUMP_PROJ_SHORT_NAME[$i]}"
          local tab=$([[ ${#short} -lt 5 ]] && echo -e "\t\t" || echo -e "\t")
          
          print " ${red_cor} $short ${reset_cor}${tab} = set project to $short"
        fi
      done
    fi
  fi
  
  print ""
  display_line_ "general" "${solid_yellow_cor}"
  print ""
  print " ${solid_yellow_cor} cl ${reset_cor}\t\t = clear"
  print " ${solid_yellow_cor} colors ${reset_cor}\t = display colors from 0 to 255"
  print " ${solid_yellow_cor} del ${reset_cor}\t\t = delete utility"
  print " ${solid_yellow_cor} help ${reset_cor}\t\t = display this help"
  print " ${solid_yellow_cor} hg <text> ${reset_cor}\t = history | grep text"
  print " ${solid_yellow_cor} kill <port> ${reset_cor}\t = kill port"
  print " ${solid_yellow_cor} ll ${reset_cor}\t\t = ls -la"
  print " ${solid_yellow_cor} nver ${reset_cor}\t\t = node version"
  print " ${solid_yellow_cor} nlist ${reset_cor}\t = npm list global"
  print " ${solid_yellow_cor} refresh ${reset_cor}\t = source .zshrc"
  print " ${solid_yellow_cor} upgrade ${reset_cor}\t = upgrade pump + zsh + omp"

  if ! pause_output_; then return 0; fi

  display_line_ "get started" "${blue_cor}"
  print ""
  print "  1. set a project, type:${solid_blue_cor} pro${reset_cor}"
  print "  2. clone project, type:${blue_cor} clone${reset_cor}"
  print "  3. setup project, type:${blue_cor} setup${reset_cor}"
  print "  4. run a project, type:${blue_cor} run${reset_cor}"

  if ! pause_output_; then return 0; fi

  if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    display_line_ "project selection" "${solid_blue_cor}"
    print ""
    print " ${solid_blue_cor} pro ${reset_cor}\t\t = project management"

    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_PROJ_FOLDER[$i]}" && -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
        local short="${PUMP_PROJ_SHORT_NAME[$i]}"
        local tab=$([[ ${#short} -lt 5 ]] && echo -e "\t\t" || echo -e "\t")
        
        print " ${solid_blue_cor} $short ${reset_cor}${tab} = set project to $short"
      fi
    done
    if ! pause_output_; then return 0; fi
  fi

  if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    display_line_ "setup & run" "${blue_cor}"
    print ""
    print " ${blue_cor} clone ${reset_cor}\t = clone project or branch"
    
    local _setup=${CURRENT_PUMP_SETUP:-$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}
    local max=53

    if (( ${#_setup} > max )); then
      # print " ${blue_cor} setup ${reset_cor}\t = ${_setup[1,$max]}"
      print " ${blue_cor} setup ${reset_cor}\t = run PUMP_SETUP"
    else
      print " ${blue_cor} setup ${reset_cor}\t = $_setup"
    fi
    if (( ${#CURRENT_PUMP_RUN} > max )); then
      print " ${blue_cor} run ${reset_cor}\t\t = run PUMP_RUN"
    else
      print " ${blue_cor} run ${reset_cor}\t\t = $CURRENT_PUMP_RUN"
    fi
    if (( ${#CURRENT_PUMP_RUN_STAGE} > max )); then
      print " ${blue_cor} run stage ${reset_cor}\t = run PUMP_RUN_STAGE"
    else
      print " ${blue_cor} run stage ${reset_cor}\t = $CURRENT_PUMP_RUN_STAGE"
    fi
    if (( ${#CURRENT_PUMP_RUN_PROD} > max )); then
      print " ${blue_cor} run prod ${reset_cor}\t = run PUMP_RUN_PROD"
    else
      print " ${blue_cor} run prod ${reset_cor}\t = $CURRENT_PUMP_RUN_PROD"
    fi

    if ! pause_output_; then return 0; fi
  fi
  
  display_line_ "code review" "${cyan_cor}"
  print ""
  print " ${cyan_cor} rev ${reset_cor}\t\t = open a pull request for review"
  print " ${cyan_cor} revs ${reset_cor}\t\t = list existing reviews"
  print " ${cyan_cor} prune revs ${reset_cor}\t = delete merged reviews"

  if ! pause_output_; then return 0; fi

  if [[ -n "$CURRENT_PUMP_PROJ_SHORT_NAME" ]]; then
    display_line_ "$CURRENT_PUMP_PKG_MANAGER" "${solid_magenta_cor}"
    print ""
    print " ${solid_magenta_cor} build ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
    print " ${solid_magenta_cor} deploy ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
    print " ${solid_magenta_cor} fix ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")format + lint"
    print " ${solid_magenta_cor} format ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
    print " ${solid_magenta_cor} i ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
    print " ${solid_magenta_cor} ig ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
    print " ${solid_magenta_cor} lint ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
    print " ${solid_magenta_cor} rdev ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
    print " ${solid_magenta_cor} sb ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
    print " ${solid_magenta_cor} sbb ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
    print " ${solid_magenta_cor} start ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
    print " ${solid_magenta_cor} tsc ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
    print " ${solid_magenta_cor} watch ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")watch"
    
    if ! pause_output_; then return 0; fi

    display_line_ "testing" "${magenta_cor}"
    print ""
    if [[ "$CURRENT_PUMP_COV" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
      print " ${solid_magenta_cor} ${CURRENT_PUMP_PKG_MANAGER:0:1}cov ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
    fi
    if [[ "$CURRENT_PUMP_E2E" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
      print " ${solid_magenta_cor} ${CURRENT_PUMP_PKG_MANAGER:0:1}e2e ${reset_cor}\t\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
    fi
    if [[ "$CURRENT_PUMP_E2EUI" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
      print " ${solid_magenta_cor} ${CURRENT_PUMP_PKG_MANAGER:0:1}e2eui ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
    fi
    if [[ "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
      print " ${solid_magenta_cor} ${CURRENT_PUMP_PKG_MANAGER:0:1}test ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
    fi
    if [[ "$CURRENT_PUMP_TEST_WATCH" != "$CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
      print " ${solid_magenta_cor} ${CURRENT_PUMP_PKG_MANAGER:0:1}testw ${reset_cor}\t = $CURRENT_PUMP_PKG_MANAGER $([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
    fi
    print " ${magenta_cor} cov ${reset_cor}\t\t = $CURRENT_PUMP_COV"
    print " ${magenta_cor} e2e ${reset_cor}\t\t = $CURRENT_PUMP_E2E"
    print " ${magenta_cor} e2eui ${reset_cor}\t = $CURRENT_PUMP_E2EUI"
    print " ${magenta_cor} test ${reset_cor}\t\t = $CURRENT_PUMP_TEST"
    print " ${magenta_cor} testw ${reset_cor}\t = $CURRENT_PUMP_TEST_WATCH"

    if ! pause_output_; then return 0; fi
  fi
  
  display_line_ "git" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} gconf ${reset_cor}\t = show git config"
  print " ${solid_cyan_cor} gha ${reset_cor}\t\t = view last workflow run"
  print " ${solid_cyan_cor} st ${reset_cor}\t\t = show git status"
  
  if ! pause_output_; then return 0; fi

  display_line_ "git branch" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} back ${reset_cor}\t\t = go back to previous branch in the current folder"
  print " ${solid_cyan_cor} co ${reset_cor}\t\t = switch branch (checkout)"
  print " ${solid_cyan_cor} dev ${reset_cor}\t\t = switch to dev or develop branch"
  print " ${solid_cyan_cor} main ${reset_cor}\t\t = switch to main branch"
  print " ${solid_cyan_cor} next ${reset_cor}\t\t = go to the next working folder/branch"
  print " ${solid_cyan_cor} prev ${reset_cor}\t\t = go to the previous working folder/branch"
  print " ${solid_cyan_cor} prod ${reset_cor}\t\t = switch to prod or production branch"
  print " ${solid_cyan_cor} renb <b>${reset_cor}\t = rename branch"
  print " ${solid_cyan_cor} stage ${reset_cor}\t = switch to stage or staging branch"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git clean" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} clean${reset_cor}\t\t = clean unstaged changes"
  print " ${solid_cyan_cor} delb ${reset_cor}\t\t = delete branches"
  print " ${solid_cyan_cor} discard ${reset_cor}\t = clean + restore"
  print " ${solid_cyan_cor} prune ${reset_cor}\t = prune branches and tags"
  print " ${solid_cyan_cor} reset1 ${reset_cor}\t = reset soft 1 commit"
  print " ${solid_cyan_cor} reset2 ${reset_cor}\t = reset soft 2 commits"
  print " ${solid_cyan_cor} reset3 ${reset_cor}\t = reset soft 3 commits"
  print " ${solid_cyan_cor} reset4 ${reset_cor}\t = reset soft 4 commits"
  print " ${solid_cyan_cor} reset5 ${reset_cor}\t = reset soft 5 commits"
  print " ${solid_cyan_cor} reseta ${reset_cor}\t = erase everything, reset to last commit"
  print " ${solid_cyan_cor} restore ${reset_cor}\t = clean staged changes"

  if ! pause_output_; then return 0; fi

  display_line_ "git log" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} glog ${reset_cor}\t\t = git log"
  print " ${solid_cyan_cor} gll ${reset_cor}\t\t = list branches"
  print " ${solid_cyan_cor} glr ${reset_cor}\t\t = list remote branches"

  if ! pause_output_; then return 0; fi

  display_line_ "git merge" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} abort${reset_cor}\t\t = abort rebase/merge/chp"
  print " ${solid_cyan_cor} chc ${reset_cor}\t\t = continue cherry-pick"
  print " ${solid_cyan_cor} chp ${reset_cor}\t\t = cherry-pick commit"
  print " ${solid_cyan_cor} cont ${reset_cor}\t\t = continue rebase/merge/chp"
  print " ${solid_cyan_cor} mc ${reset_cor}\t\t = continue merge"
  print " ${solid_cyan_cor} merge ${reset_cor}\t = merge from $(git config --get init.defaultBranch)"
  print " ${solid_cyan_cor} merge <b> ${reset_cor}\t = merge from branch"
  print " ${solid_cyan_cor} rc ${reset_cor}\t\t = continue rebase"
  print " ${solid_cyan_cor} rebase ${reset_cor}\t = rebase from $(git config --get init.defaultBranch)"
  print " ${solid_cyan_cor} rebase <b> ${reset_cor}\t = rebase from branch"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "git pull" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} fetch ${reset_cor}\t = fetch from $remote_name"
  print " ${solid_cyan_cor} pull ${reset_cor}\t\t = pull from $remote_name"
  print ""

  if ! pause_output_; then return 0; fi
  
  display_line_ "git push" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} add ${reset_cor}\t\t = add files to index"
  if [[ "$COMMIT1" == "c" ]]; then
    print " ${solid_cyan_cor} $COMMIT1 ${reset_cor}\t\t = open commit wizard"
    print " ${solid_cyan_cor} $COMMIT1 <m>${reset_cor}\t\t = commit message"
  else
    print " ${solid_cyan_cor} $COMMIT1 ${reset_cor}\t = open commit wizard"
    print " ${solid_cyan_cor} $COMMIT1 <m>${reset_cor}\t = commit message"
  fi
  print " ${solid_cyan_cor} pr ${reset_cor}\t\t = create pull request"
  print " ${solid_cyan_cor} push ${reset_cor}\t\t = push all no-verify to $remote_name"
  print " ${solid_cyan_cor} pushf ${reset_cor}\t = push force all to $remote_name"

  if ! pause_output_; then return 0; fi
  
  display_line_ "git stash" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} pop ${reset_cor}\t\t = apply stash then remove from list"
  print " ${solid_cyan_cor} stash ${reset_cor}\t = stash files"

  if ! pause_output_; then return 0; fi
  
  display_line_ "release" "${yellow_cor}"
  print ""
  print " ${yellow_cor} dtag ${reset_cor}\t\t = delete a tag"
  print " ${yellow_cor} drelease ${reset_cor}\t = delete a release"
  print " ${yellow_cor} release ${reset_cor}\t = create a release"
  print " ${yellow_cor} tag ${reset_cor}\t\t = create a tag"
  print " ${yellow_cor} tags ${reset_cor}\t\t = list latest tags"
  print " ${yellow_cor} tags 1 ${reset_cor}\t = display latest tag"
  
  if ! pause_output_; then return 0; fi
  
  display_line_ "multi-step task" "${solid_pink_cor}"
  print ""
  print " ${solid_pink_cor} cov <b> ${reset_cor}\t = compare test coverage with another branch"
  print " ${solid_pink_cor} refix ${reset_cor}\t = reset last commit, run fix then re-push"
  print " ${solid_pink_cor} recommit ${reset_cor}\t = reset last commit then commit changes to index again"
  print " ${solid_pink_cor} release ${reset_cor}\t = bump version and create a release on github"
  print " ${solid_pink_cor} repush ${reset_cor}\t = reset last commit then push changes again"
  print " ${solid_pink_cor} rev ${reset_cor}\t\t = open a pull request for review on code editor"

  print ""
  print ""
  print "  to learn more, visit:${blue_cor} https://github.com/fab1o/pump-zsh/wiki ${reset_cor}"
}

function validate_proj_cmd_strict_() {
  set +x
  eval "$(parse_flags_ "validate_proj_cmd_strict_" "" "" "$@")"
  (( validate_proj_cmd_strict_is_d )) && set -x

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
    print "${yellow_cor}  project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  local invalid_values=("pwd" "quit" "done" "-")

  if [[ " ${invalid_values[*]} " == *" $proj_cmd "* ]]; then
    print "${yellow_cor}  project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  return 0;
}

function validate_proj_cmd_() {
  local proj_cmd="$1"
  local qty=$MAX_NAME_COUNT

  local error_msg=""

  if [[ -z "$proj_cmd" ]]; then
    error_msg="project name is missing"
  elif [[ ${#proj_cmd} -gt $qty ]]; then
    error_msg="project name is invalid: $qty max characters"
  elif ! [[ "$proj_cmd" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    error_msg="project name is invalid: no special characters"
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
    print "${yellow_cor}  ${error_msg}${reset_cor}" 2>/dev/tty
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
    clear_curr_proj_
    refresh_curr_proj_
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

local i=0
for i in {1..9}; do
  if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
    local func_name="${PUMP_PROJ_SHORT_NAME[$i]}"
    functions[$func_name]="proj_handler $i \"\$@\";"
  fi
done

# function activate_pro_() {
#   # pro pwd
#   if pro -f "pwd" 2>/dev/null; then
#     rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
#     return 0;
#   fi

#   # Read the current project short name from the PUMP_PRO_FILE if it exists
#   if [[ -f "$PUMP_PRO_FILE" ]]; then
#     local project_names=()
#     local pump_pro_file_value=$(<"$PUMP_PRO_FILE")

#     if [[ -n "$pump_pro_file_value" ]]; then
#       local i=0
#       local found=0
#       for i in {1..9}; do
#         if [[ "$pump_pro_file_value" == "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
#           found=1
#           if ! validate_proj_cmd_ "$pump_pro_file_value" &>/dev/null; then
#             rm -f "$PUMP_PRO_FILE" &>/dev/null
#           else
#             project_names=("$pump_pro_file_value")
#           fi
#           break;
#         fi
#       done
#       if (( found == 0 )); then
#         rm -f "$PUMP_PRO_FILE" &>/dev/null
#       fi
#     fi
#   fi

#   local i=0
#   for i in {1..9}; do
#     if [[ -n "${PUMP_PROJ_SHORT_NAME[$i]}" ]]; then
#       if [[ ! " ${project_names[@]} " =~ " ${PUMP_PROJ_SHORT_NAME[$i]} " ]]; then
#         project_names+=("${PUMP_PROJ_SHORT_NAME[$i]}")
#       fi
#     fi
#   done

#   # Loop over the projects to check and execute them
#   for project in "${project_names[@]}"; do
#     if pro -f "$project" 2>/dev/null; then
#       rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
#       return 0;
#     fi
#   done

#   return 1;
# }

# activate_pro_ # set project

if pro -f "pwd" 2>/dev/null; then
  # rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
fi

# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs

add-zsh-hook chpwd pump_chpwd_
