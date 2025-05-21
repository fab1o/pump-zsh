typeset -g is_debug=0 # (debug flag) when -d is on, it will be shared across all subsequent function calls

typeset -Ag node_folder node_branch node_project
typeset -Ag ll_next ll_prev
typeset -gi node_counter=0
typeset -g head=""

typeset -g dark_gray_cor="\e[38;5;238m"
typeset -g gray_cor="\e[38;5;252m"

typeset -g bright_green_cor="\e[1m\e[38;5;151m"
typeset -g solid_green_cor="\e[32m"
typeset -g green_cor="\e[92m"

# typeset -g bright_yellow_cor="\e[1m\e[38;5;220m"
typeset -g bright_yellow_cor="\e[1m\e[38;5;228m"
typeset -g solid_yellow_cor="\e[33m"
typeset -g yellow_cor="\e[93m"

typeset -g solid_magenta_cor="\e[35m"
typeset -g magenta_cor="\e[95m"

typeset -g solid_red_cor="\e[31m"
typeset -g red_cor="\e[91m"

typeset -g bright_blue_cor="\e[1m\e[38;5;75m"
typeset -g solid_blue_cor="\e[34m"
typeset -g blue_cor="\e[94m"

typeset -g solid_cyan_cor="\e[36m"
typeset -g cyan_cor="\e[96m"

typeset -g bright_pink_cor="\e[0;95m"
typeset -g pink_cor="\e[0;95m"
typeset -g purple_cor="\e[38;5;99m"

typeset -g reset_cor="\e[0m"

typeset -g PUMP_VERSION="0.0.0"

typeset -g PUMP_VERSION_FILE="$(dirname "$0")/.version"
typeset -g PUMP_WORKING_FILE="$(dirname "$0")/.working"
typeset -g PUMP_CONFIG_FILE="$(dirname "$0")/config/pump.zshenv"
typeset -g PUMP_PRO_FILE="$(dirname "$0")/.pump"

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

function print_debug_() {
  if (( is_debug )); then
    print "${solid_blue_cor}debug: $1 ${reset_cor}" >&2
  fi
}

function parse_flags_() {
  set +x
  if [[ -z "$1" ]]; then
    print "${red_cor} fatal: parse_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix="$1"
  local valid_flags=""

  if [[ -n "$2" ]]; then
    valid_flags="d${2}h"
  fi

  shift 2

  local flags=()
  local non_flags=()
  local flags_double_dash=()

  local ch=""
  for ch in {a..z}; do
    echo "${prefix}is_$ch=0"
  done

  local is_invalid=0
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
            flags+=("-$ch")
            is_invalid=1
            print "${red_cor} ${prefix%_} invalid option: -$ch${reset_cor}" >&2
            echo "${prefix}is_h=1"
          else
            if [[ "$ch" == "q" ]]; then
              flags_double_dash+=("--quiet")
            fi
          fi
        else
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

function confirm_from_() {
  if command -v gum &>/dev/null; then
    # GUM_BIN=$(command -v gum)
    # very important to 2>/dev/tty so that it is displayed on refresh
    gum confirm ""confirm:$'\e[0m'" $1" --no-show-help 2>/dev/tty
    return $?
  fi

  trap 'print ""; return 130' INT
  
  read -qs "?"$'\e[38;5;99m'confirm:$'\e[0m'" $1 (y/n) "
  local RET=$?

  if (( RET == 130 )); then
    print ""
    return 130;
  fi
  
  if [[ $REPLY == [yY] ]]; then
    print "y"
    return 0;
  fi
  
  if [[ $REPLY == [nN] ]]; then
    print "n"
    return 1;
  fi
  
  #print $REPLY >&2
  return 130;

  trap - INT
}

function update_() {
  eval "$(parse_flags_ "update_" "f" "$@")"
  (( update_is_d )) && set -x

  local release_tag="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
  local latest_version=$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest_version" && "$PUMP_VERSION" != "$latest_version" ]]; then
    print " new version available for pump-zsh: ${magenta_cor}${PUMP_VERSION}${reset_cor} -> ${purple_cor}${latest_version}${reset_cor}"
    
    if (( ! update_is_f )); then
      if ! confirm_from_ "do you want to install new version?"; then
        return 0;
      fi
    fi

    #print " if you encounter an error after installation, don't worry — simply restart your terminal"

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
  local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

  if [[ -z "$project" ]]; then
    project=$(which_pro_pwd_)
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
    return 1
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

  return 1
}

function ll_traverse_() {
  if [[ -z "$head" ]]; then
    return
  fi

  local id="$head"

  while true; do
    print "pro=${PUMP_PROJECT_SHORT_NAME[${node_project[$id]}]}, folder=${node_folder[$id]}, branch=${node_branch[$id]}"
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
    return 1
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

function confirm_between_() {
  local question="$1"
  local option1="$2"
  local option2="$3"
  local is_echod="${4:-0}"

  local opt1="${option1[1]}"
  local opt2="${option2[1]}"

  local chosen_mode=""

  local RET=0

  if command -v gum &>/dev/null; then
    gum confirm ""mode:$'\e[0m'" $1" --no-show-help --affirmative="$option1" --negative="$option2" 2>/dev/tty
    RET=$?
    if (( RET == 130 )); then
      return 130;
    fi
    if (( RET == 0 )); then
      chosen_mode="$opt1"
    elif (( RET == 1 )); then
      chosen_mode="$opt2"
    fi
  else
    while true; do
      echo -n ""$'\e[38;5;99m'mode:$'\e[0m'" $1? "$'\e[38;5;218m'$option1$'\e[0m'" or "$'\e[38;5;218m'$option2$'\e[0m'" repositories? [${opt1:l}/${opt2:l}]: " 2>/dev/tty
      stty -echo                  # Turn off input echo
      read -k 1 mode              # Read one character
      stty echo                   # Turn echo back on
      case "$mode" in
        [sSmM]) break ;;          # Accept only s or m (case-insensitive)
        *) echo "" ;;
      esac
    done
    if [[ "$mode" == "${opt1:l}" || "$mode" == "${opt1:u}" ]]; then
      chosen_mode="$opt1"
      RET=0
    elif [[ "$mode" == "${opt2:l}" || "$mode" == "${opt2:u}" ]]; then
      chosen_mode="$opt2"
      RET=1
    else
      return 130;
    fi
  fi

  if (( is_echod )); then
    echo $chosen_mode
  fi

  return $RET;
}

function input_from_() {
  # very important to 1>/dev/tty so that it is displayed on refresh
  local header="$1"
  local placeholder="$2"

  local _input=""
  if command -v gum &>/dev/null; then
    print "${purple_cor} $header:${reset_cor}" 1>/dev/tty

    _input=$(gum input --placeholder="$placeholder" 2>/dev/tty)
    if (( $? != 0 )); then return 1; fi
  else
    if [[ -n "$placeholder" ]]; then
      echo "$placeholder"
      return 0;
    fi
  
    print "${purple_cor} $header:${reset_cor}" 1>/dev/tty

    trap 'print ""; return 130' INT
    stty -echoctl
    read "?> " _input || { echo ""; echo ""; return 1; }
    stty echoctl
    trap - INT
  fi

  _input="$(echo "$_input" | xargs)"

  echo "$_input"
  return 0;
}

function choose_multiple_() {
  local purple=$'\e[38;5;99m'
  local cor=$'\e[38;2;167;139;250m'
  local reset=$'\e[0m'

  local auto=$1
  local header="$2"
  local height="${3:-20}"

  if command -v gum &>/dev/null; then
    if (( auto )); then
      echo "$(gum choose --select-if-one --no-limit --header="${purple} $header ${cor}(use spacebar)${purple}:${reset}" --height="$height" ${@:4} 2>/dev/tty)"
    else
      echo "$(gum choose --no-limit --header="${purple} $header ${cor}(use spacebar)${purple}:${reset}" --height="$height" ${@:4} 2>/dev/tty)"
    fi
    return 0;
  fi

  trap 'print ""; return 130' INT

  function TRAPINT() { return 130 }
  PS3="${purple}$header: ${reset}" 2>/dev/tty
  select choice in "${@:4}" "quit"; do
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

function filter_one_() { # gum filter does not have
  local auto="$1"

  if command -v gum &>/dev/null; then
    print "${purple_cor} $2: ${reset_cor}" >&2
    if (( auto )); then
      echo "$(gum filter --height 20 --limit=1 --select-if-one --indicator=">" --placeholder=" $3" ${@:4} 2>/dev/tty)"
    else
      echo "$(gum filter --height 20 --limit=1 --indicator=">" --placeholder=" $3" ${@:4} 2>/dev/tty)"
    fi
  else
    choose_one_ $auto "$3" 20 "$4"
  fi
}

function choose_one_() {
  local auto="$1"
  local header="$2"
  local height="${3:-20}"

  local purple=$'\e[38;5;99m'
  local reset=$'\e[0m'

  if command -v gum &>/dev/null; then
    if (( auto )); then
      local choice=""
      choice="$(gum choose --limit=1 --select-if-one --header="${purple} $header:${reset}" --height="$height" ${@:4} 2>/dev/tty)"
    else
      choice="$(gum choose --limit=1 --header="${purple} $header:${reset}" --height="$height" ${@:4} 2>/dev/tty)"
    fi
    if (( $? != 0 )); then return 1; fi

    echo "$choice"
    return 0;
  fi
  
  trap 'print ""; return 130' INT

  PS3="${purple}$header: ${reset}"
  select choice in "${@:4}" "quit"; do
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

function get_folders_() {
  local _pwd=$(pwd)

  if [[ -n "$1" && -d "$1" ]]; then
    cd "$1"
  fi

  #dirs=(*(/))
  #dirs=(*(N/om))  # o = sort by modified time
  #dirs=(*(N/on))  # n = sort by name
  local dirs=(*(/N/on))
  local filtered=()
  local name=""
  for name in "${dirs[@]}"; do
    [[ $name != "revs" ]] && filtered+=$name
  done

  local priorities=(main stage dev develop staging master)
  local ordered=()

  for name in "${priorities[@]}"; do
    if [[ " ${filtered[@]} " == *" $name "* ]]; then
      ordered+="$name"
    fi
  done

  for name in "${filtered[@]}"; do
    if [[ " ${priorities[@]} " != *" $name "* ]]; then
      ordered+="$name"
    fi
  done


  echo "${ordered[@]}"
  
  cd "$_pwd"
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

# save project data to config file
function update_proj_cmd_() {
  eval "$(parse_flags_ "update_proj_cmd_" "" "$@")"
  (( update_proj_cmd_is_d )) && set -x

  local i="$1"
  local proj_cmd="$2"

  if (( i > 0 )); then
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      unset -f "${PUMP_PROJECT_SHORT_NAME[$i]}" &>/dev/null
    fi
  else
    if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      unset -f "$CURRENT_PUMP_PROJECT_SHORT_NAME" &>/dev/null
    fi
  fi

  eval "function ${proj_cmd}() { proj_handler_ $i \"\$@\"; }"

  update_setting_ $i "PUMP_PROJECT_SHORT_NAME" "$proj_cmd"
}

function update_setting_() {
  check_config_file_

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then return 1; fi

  local i="$1"
  local general_key="$2" 
  local value="$3"

  if (( i > 0 )); then
    if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      eval "CURRENT_${general_key}=\"$value\""
    fi
    eval "${general_key}[$i]=\"$value\""
  else
    eval "CURRENT_${general_key}=\"$value\""
  fi

  local key="${general_key}_${i}"

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD sed) requires correct handling of patterns
    sed -i '' "s|^$key=.*|$key=$value|" "$PUMP_CONFIG_FILE"
  else
    # Linux (GNU sed)
    sed -i "s|^$key=.*|$key=$value|" "$PUMP_CONFIG_FILE"
  fi

  if (( $? != 0 )); then
    print "  warn: failed to update $key in $PUMP_CONFIG_FILE" >&2
  fi

  return 0;
}

function input_branch_name_() {
  local header="$1"

  while true; do
    local typed_value=""
    typed_value="$(input_from_ "$header")"
    if (( $? != 0 )); then return 1; fi
    
    if git check-ref-format --branch "$typed_value"; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function input_name_() {
  local header="$1"
  local placeholder="$2"

  while true; do
    local typed_value=""
    typed_value="$(input_from_ "$header" "$placeholder")"
    if (( $? != 0 )); then return 1; fi
    
    if [[ -z "$typed_value" ]]; then
      if [[ -n "$placeholder" ]] && command -v gum &>/dev/null; then
        typed_value="$placeholder"
      fi
    fi
    if [[ -n "$typed_value" ]]; then
      echo "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function choose_proj_folder_() {
  local i="$1"
  local header="$2"
  local folder_name="$3"
  local folder_exists="$4"

  if ! command -v gum &>/dev/null; then
    local path=""
    path="$(input_path_ "$2")"
    if (( $? != 0 )); then return 1; fi

    echo "$path"
    return 0;
  fi

  local folder_path=""

  print "${purple_cor} ${header}:${reset_cor}" 1>/dev/tty
  # print "" 1>/dev/tty

  cd "${HOME:-/}" # start from home

  while true; do
    if [[ -n "$folder_path" ]]; then
      local new_folder=""

      if (( folder_exists )); then
        new_folder="$folder_path"
      else
        new_folder="${folder_path}/$folder_name"
      fi

      confirm_between_ "set project folder to: "$'\e[94m'${new_folder}$'\e[0m'" or continue to browse further?" "set folder" "continue to browse"
      local RET=$?
      if (( RET == 130 )); then
        return 130;
      fi
      if (( RET == 1 )); then
        cd "$folder_path"
      else
        local found=0
        local realfolder="$(realpath "$folder_path" 2>/dev/null)"
        if (( ! folder_exists )); then
          realfolder="${realfolder}/$folder_name"
        fi
        for j in {1..10}; do
          if [[ $j -ne $i && -n "$PUMP_PROJECT_FOLDER[$j]" && -n "${PUMP_PROJECT_SHORT_NAME[$j]}" ]]; then
            local realfolder_proj="$(realpath "$PUMP_PROJECT_FOLDER[$j]" 2>/dev/null)"

            if [[ "$realfolder" == "$realfolder_proj" ]]; then
              found=1
              print "  ${yellow_cor}project folder already in use by another project, choose a new one ${reset_cor}" >&2
              cd "$HOME"
            fi
          fi
        done

        if (( found == 0 )); then
          echo "$folder_path"
          return 0;
        fi
      fi
    fi

    folder_path=""
    
    local dirs=($(get_folders_ 2>/dev/null))
    if (( ! ${#dirs[@]} )); then
      cd "${HOME:-/}"
    fi

    local chose_folder=""
    chose_folder="$(gum file --directory --height 14)"
    if (( $? == 130 )); then return 1; fi

    if [[ -n "$chose_folder" ]]; then
      folder_path="$chose_folder"
    else
      return 1;
    fi
  done

  return 1;
}

function input_path_() {
  local header="$1"

  print "${purple_cor} ${header}:${reset_cor}" 1>/dev/tty

  while true; do
    local typed_value=""
    typed_value="$(input_from_)"
    if (( $? != 0 )); then return 1; fi

    if [[ -z "$typed_value" ]]; then
      return 1;
    fi

    if [[ "$typed_value" =~ ^[a-zA-Z0-9/,._-]+$ ]]; then
      echo "$typed_value"
      break;
    fi
  done
}

function validate_repo_() {
  local repo="$1"

  if [[ "$repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
    return 0;
  fi

  print "  repository must be a valid ssh or https uri" 2>/dev/tty >&2
  return 1;
}

function input_repo_() {
  local header="$1"
  local placeholder="$2"

  if command -v gh &>/dev/null; then
    confirm_from_ "do you want to access your Github account to choose from a list of repositories?"
    local RET=$?
    if (( RET == 130 )); then return 1; fi

    if (( RET == 0 )); then
      local gh_owner=""
      gh_owner=$(input_from_ "type the github owner account (username or organization)")
      if (( $? != 0 )); then return 1; fi

      if [[ -n "$gh_owner" ]]; then
        local repos=""
        repos=("${(@f)$(gh repo list $gh_owner --limit 100 --json nameWithOwner -q '.[].nameWithOwner')}")
        
        if (( $? == 0 && ${#repos[@]} > 1 )); then
          local selected_repo=""
          selected_repo=$(choose_one_ 0 "choose repository" 30 "${repos[@]}")
          if (( $? != 0 )); then return 1; fi
  
          if [[ -n "$selected_repo" ]]; then
            local mode=""
            mode=$(confirm_between_ "ssh or https?" "ssh" "https" 1)
            if (( $? == 130 )); then return 1; fi

            local repo_uri=""
            if [[ "$mode" == "s" ]]; then
              repo_uri="git@github.com:${selected_repo}.git"
            else
              repo_uri="https://github.com/${selected_repo}.git"
            fi

            echo "$repo_uri"
            return 0;
          fi
        else
          print "  no repositories found for $gh_owner" 2>/dev/tty >&2
        fi
      fi
    fi
  fi

  while true; do
    local typed_value=""
    typed_value="$(input_from_ "$header" "$placeholder")"
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
      fi
    fi
  done

  return 1;
}

function pause_output_() {
  printf " "
  stty -echo

  IFS= read -r -k1 input

  if [[ $input == $'\e' ]]; then
      # read the rest of the escape sequence (e.g. for arrow keys)
      IFS= read -r -k2 rest
      input+=$rest
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

  echo  # move to new line cleanly
}

function display_line_() {
  local word1="$1"
  local color=${2:-$gray_cor}
  local total_width1=${3:-72}
  local word2="$4"
  local total_width2=${5:-72}

  local padding=$(( total_width1 - 2 ))
  local line="$(printf '%*s' "$padding" '' | tr ' ' '─')"

  if [[ -n "$word1" ]]; then
    local word_length1=${#word1}

    local padding1=$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - 2 : word_length1 - total_width1 - 2 ) / 2 ))
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

    local padding2=$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))
    local line2="$(printf '%*s' "$padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$padding2" '' | tr ' ' '─')"

    if (( ${#line2} < total_width2 )); then
      local pad_len2=$(( total_width2 - ${#line2} ))
      padding2=$(printf '%*s' $pad_len2 '' | tr ' ' '-')
      line2="${line2}${padding2}"
    fi

    line="$line1 | $line2"
  fi

  print "${color} $line ${reset_cor}"
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
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
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

  # Convert to lowercase
  sanitized="${pkg_name:l}"

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
  eval "$(parse_flags_ "check_proj_cmd_" "" "$@")"
  (( check_proj_cmd_is_d )) && set -x

  local i="$1"
  local typed_name="$2"
  local pkg_name="$3"
  local flag="$4"

  if ! validate_proj_cmd_strict_ "$typed_name" 13 $flag; then
    if (( check_proj_cmd_is_s )); then
      if save_proj_cmd_ $i "$pkg_name" $flag; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_repo_() {
  eval "$(parse_flags_ "check_proj_repo_" "s" "$@")"
  (( check_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_repo="$2"
  local proj_folder="$3"
  local pkg_name="$4"

  local error_msg=""

  if [[ -z "$proj_repo" ]]; then
    error_msg="project repository is missing"
  else
    # check for duplicates across other indices
    if ! [[ "$proj_repo" =~ '^((git@[a-zA-Z0-9._-]+:[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?)|(https://[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+(\.git)?))$' ]]; then
      error_msg="project repository is invalid: $proj_repo"
    else
      if command -v gum &>/dev/null; then
        # so that the spinner can display, add to the end: 2>/dev/tty
        gum spin --timeout=7s --title="checking repository uri..." -- git ls-remote "${proj_repo}" --quiet 2>/dev/tty
      else
        print " checking repository uri..."
        git ls-remote "${proj_repo}" --quiet
      fi
      if (( $? != 0 )); then
        error_msg="repository uri is invalid or no access rights: $proj_repo"
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print "  $error_msg" 2>/dev/tty >&2

    if (( check_proj_repo_is_s )); then
      if save_proj_repo_ $i "$proj_folder" "$pkg_name"; then return 0; fi
    fi

    return 1;
  fi

  TEMP_PUMP_PROJECT_REPO="$proj_repo"

  return 0;
}

function check_proj_folder_() {
  eval "$(parse_flags_ "check_proj_folder_" "s" "$@")"
  (( check_proj_folder_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local pkg_name="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$proj_folder" ]]; then
    error_msg="project folder is missing"
  fi

  if [[ -n "$error_msg" ]]; then
    print "  $error_msg" 2>/dev/tty >&2

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ $i "$pkg_name" "$proj_repo"; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_pkg_manager_() {
  eval "$(parse_flags_ "check_proj_pkg_manager_" "s" "$@")"
  (( check_proj_pkg_manager_is_d )) && set -x

  local i="$1"
  local pkg_manager="$2"
  local proj_folder="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$pkg_manager" ]]; then
    error_msg="package manager is missing"
  else
    local valid_pkg_managers=("npm" "yarn" "pnpm" "bun" "poe")

    if ! [[ " ${valid_pkg_managers[@]} " =~ " $pkg_manager " ]]; then
      error_msg="package manager is invalid: $pkg_manager"
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print " $error_msg" 2>/dev/tty >&2

    if (( check_proj_pkg_manager_is_s )); then
      if save_pkg_manager_ $i "$proj_folder" "$proj_repo"; then return 0; fi
    fi
    return 1;
  fi

  return 0;
}
# end of data checkers

function clear_last_line_() {
  print -n "\033[1A\033[2K" 2>/dev/tty >&2
}

function save_proj_cmd_() {
  eval "$(parse_flags_ "save_proj_cmd_" "" "$@")"
  (( save_proj_cmd_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"
  local flag="$3"
  
  local pkg_name_sanitized=$(sanitize_pkg_name_ "$pkg_name" 2>/dev/tty)

  local typed_name=$(input_name_ "type your project alias name" "$pkg_name_sanitized")
  if [[ -z "$typed_name" ]]; then return 1; fi
  
  if ! check_proj_cmd_ $i "$typed_name" "$pkg_name" $flag; then return 1; fi

  if [[ -z "$TEMP_PUMP_PROJECT_SHORT_NAME" ]]; then
    update_proj_cmd_ $i "$typed_name"
    TEMP_PUMP_PROJECT_SHORT_NAME="$typed_name"
  fi
}

function choose_mode_() {
  local proj_folder="$(basename "$1")"

  print ""

  local multiple_title=$(gum style --align=center --margin="0" --align=left --padding="0 7" --border=none --width=40 --foreground 212 "example of multiple mode")
  local single_title=$(gum style --align=center --margin="0" --align=left --padding="0 8" --border=none --width=40 --foreground 57 "example of single mode")

  local titles=$(gum join --align=center --horizontal "$multiple_title" "$single_title")

  local multiple=$'
  '"$(basename $(dirname "$1"))"'/
  └── '"${proj_folder}"'/
      ├── main/
      ├── feature-1/
      ├── feature-2/
      └── revs/
          ├── rev.pr-1/
          └── rev.pr-2/'

  local single=$'
  '"$(basename $(dirname "$1"))"'/
  ├── '"${proj_folder}"'/ 
  └── '"${proj_folder}"'-revs/
      ├── rev.pr-1/
      └── rev.pr-2/
  

  '

  multiple=$(gum style --margin="0" --align=left --padding="0 0 1 0" --border=normal --width=40 --border-foreground 212 "$multiple")
  single=$(gum style --margin="0" --align=left --padding="0 0 1 0" --border=normal --width=40 --border-foreground 57 "$single")

  local examples=$(gum join  --align=center --horizontal "$multiple" "$single")
  
  gum join --align=center --vertical "$titles" "$examples"

  confirm_between_ "how do you prefer to manage the project: "$'\e[38;5;212m'multiple$'\e[0m'" or "$'\e[38;5;99m'single$'\e[0m'" mode? "$'\n'"\
      "$'\e[0m'"see the example above: "$'\n\e[0m'"       • multiple mode creates a separate folder for new feature branches"$'\n\e[0m'"       • single mode manages all feature branches within a single folder" "multiple" "single" $2

}

function save_proj_mode_() {
  eval "$(parse_flags_ "save_proj_mode_" "" "$@")"
  (( save_proj_mode_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local single_mode="$3"

  if [[ -z "$single_mode" ]] || (( single_mode != 0 && single_mode != 1 )); then
    choose_mode_ "$proj_folder"
    local RET=$?
    if (( RET == 130 )); then return 130; fi
    single_mode=$RET

    if [[ -d "$proj_folder" && -n "$(ls -A "$proj_folder")" ]]; then
      local is_move=0;

      if (( single_mode )); then
        confirm_from_ "do you want to move contents of the project folder to a new folder and re-clone the project?"
        RET=$?
        if (( RET == 130 )); then return 130; fi
        if (( RET == 0 )); then
          is_move=1;
        fi
      else
        is_move=1;
      fi

      if (( is_move )); then
        local folder_name="$(basename "$proj_folder")"
        local parent_folder="$(dirname "$proj_folder")"
        local new_proj_folder="${parent_folder}/${folder_name}-backup"

        if [[ ! -d "$new_proj_folder" ]]; then
          mkdir -p "$new_proj_folder"
        fi

        setopt null_glob dot_glob
        mv "$proj_folder"/* "$proj_folder"/.* "$new_proj_folder" &>/dev/null
        unsetopt null_glob dot_glob
      fi
    fi
  fi

  update_setting_ $i "PUMP_PROJECT_SINGLE_MODE" "$single_mode"

  if (( single_mode )); then
    print "  ${pink_cor}project mode:${reset_cor} single" >&1
  else
    print "  ${pink_cor}project mode:${reset_cor} multiple" >&1
  fi
}

function save_proj_folder_() {
  eval "$(parse_flags_ "save_proj_folder_" "aer" "$@")"
  (( save_proj_folder_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"
  local proj_repo="$3"
  local proj_folder="$4"

  if [[ -n "$proj_folder" && "$proj_folder" == "${PUMP_PROJECT_FOLDER[$i]}"  ]]; then
    return 0;
  fi

  if [[ -n "$proj_repo" ]]; then
    pkg_name="$(get_repo_name_ "$proj_repo" 1 2>/dev/tty)"
  fi

  local pkg_name_sanitized=$(sanitize_pkg_name_ "$pkg_name" 2>/dev/tty)

  local RET=0
  local folder_exists=0
  
  if (( save_proj_folder_is_e )); then
    if [[ -n "${PUMP_PROJECT_FOLDER[$i]}" ]]; then
      confirm_from_ "do you want to keep using project folder: "$'\e[94m'${PUMP_PROJECT_FOLDER[$i]}$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 0 )); then return 0; fi
    fi
  elif (( save_proj_folder_is_r )); then
    RET=1
    header="select the cloned folder"
  elif [[ -z "$proj_folder" ]]; then
    confirm_between_ "would you like create a new folder or use an existing folder?" "create new folder" "use existing folder"
    RET=$?
    header="select the existing folder"
  fi

  if [[ -z "$proj_folder" ]]; then
    if (( RET == 130 )); then return 1; fi
    if (( RET == 1 )); then
      folder_exists=1
    else
      if [[ -z "$pkg_name_sanitized" ]]; then
        confirm_from_ "do you have a git repository?"
        RET=$?
        if (( RET == 130 )); then return 1; fi
        if (( RET == 0 )); then return 0; fi
      fi

      header="choose the parent directory where the new project folder will be created"
    fi

    proj_folder=$(choose_proj_folder_ $i "$header" "$pkg_name_sanitized" "$folder_exists")
    if [[ -z "$proj_folder" ]]; then return 1; fi

    if ! check_proj_folder_ $i "$proj_folder" "$pkg_name_sanitized" "$proj_repo"; then return 1; fi
  
    if (( folder_exists == 0 )); then
      proj_folder="${proj_folder}/$pkg_name_sanitized"

      if [[ ! -d "$proj_folder" ]]; then
        mkdir -p "$proj_folder"
      fi
    fi
  fi

  update_setting_ $i "PUMP_PROJECT_FOLDER" "$proj_folder"
  
  print "  ${pink_cor}project folder:${reset_cor} ${proj_folder}" >&1
}

function save_proj_repo_() {
  eval "$(parse_flags_ "save_proj_repo_" "ae" "$@")"
  (( save_proj_repo_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local pkg_name="$3"
  local proj_repo="$4"
  local RET=0

  if (( save_proj_repo_is_e )) && [[ -n "$proj_repo" ]]; then
    confirm_from_ "do you want to keep using repository: "$'\e[94m'$proj_repo$'\e[0m'" ?"
    RET=$?
    if (( RET == 130 )); then return 1; fi
    if (( RET == 0 )); then return 0; fi
  elif (( save_proj_repo_is_a )) && [[ -z "$proj_repo" ]]; then
    confirm_from_ "are you adding an existing project?"
    RET=$?
    if (( RET == 130 )); then return 1; fi
    if (( RET == 0 )); then
      if ! save_proj_folder_ -r $i "$pkg_name"; then return 1; fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"
    else
      confirm_from_ "is there a repository for this project?"
      RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 1 )); then
        return 0;
      fi
    fi
  fi

  local _pwd="$(pwd)"

  if [[ -z "$proj_repo" ]] && open_proj_for_git_ "$proj_folder" &>/dev/null; then
    local remote_origin="$(get_remote_origin_)"
    remote_repo="$(git remote get-url "$remote_origin" 2>/dev/null)"
    RET=$?
    cd "$_pwd"

    if (( RET == 0 )) && [[ -n "$remote_repo" && "$remote_repo" != "${PUMP_PROJECT_REPO[$i]}" ]]; then
      confirm_from_ "do you want to use repository: "$'\e[94m'${remote_repo}$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 0 )); then
        proj_repo="$remote_repo"
      fi
    fi
  fi

  if (( save_proj_repo_is_a )); then
    if [[ -z "$proj_repo" ]]; then
      proj_repo=$(input_repo_ "type the repository uri (ssh or https)")
    fi
  else
    proj_repo=$(input_repo_ "type the repository uri (ssh or https)" "$proj_repo")
  fi

  if [[ -z "$proj_repo" ]]; then return 1; fi

  if [[ "$proj_repo" == "." ]]; then
    proj_repo=""
  else
    # don't pass $proj_folder to check_proj_repo_ so it doesn't ask again if we want to use the same repo
    if ! check_proj_repo_ -s $i "$proj_repo" "";  then return 1; fi

    print "  ${pink_cor}project repository:${reset_cor} ${proj_repo}" >&1
  fi

  update_setting_ $i "PUMP_PROJECT_REPO" "$proj_repo"
}

function save_pkg_manager_() {
  eval "$(parse_flags_ "save_pkg_manager_" "" "$@")"
  (( save_pkg_manager_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  local pkg_manager="$(detect_pkg_manager_ "$proj_folder")"

  if [[ -n "$pkg_manager" ]]; then
    confirm_from_ "confirm package manager: "$'\e[94m'${pkg_manager}$'\e[0m'" ?"
    local RET=$?
    if (( RET == 130 )); then return 1; fi
    if (( RET == 1 )); then
      pkg_manager=""
      proj_repo=""
    fi
  fi

  if [[ -z "$pkg_manager" && -n "$proj_repo" ]]; then
    pkg_manager=$(detect_pkg_manager_online_ "$proj_repo")

    if [[ -n "$pkg_manager" ]]; then
      confirm_from_ "confirm package manager: "$'\e[94m'${pkg_manager}$'\e[0m'" ?"
      local RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 1 )); then
        pkg_manager=""
      fi
    fi
  fi

  if [[ -z "$pkg_manager" ]]; then
    pkg_manager=($(choose_one_ 0 "choose package manager" 10 "npm" "yarn" "pnpm" "bun" "poe"))
    if [[ -z "$pkg_manager" ]]; then return 1; fi

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder"; then return 1; fi
  fi

  update_setting_ $i "PUMP_PACKAGE_MANAGER" "$pkg_manager"
  
  print "  ${pink_cor}package manager:${reset_cor} ${pkg_manager}" >&1
}

function detect_pkg_manager_online_() {
  local repo="$1"
  
  if [[ -z "$repo" ]]; then
    return 1
  fi

  local url=""
  if [[ "$repo" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    local owner_repo="${match[1]}"
    url="https://raw.githubusercontent.com/${owner_repo}/refs/heads/main"
  else
    return 1
  fi

  local manager=""

  if command -v jq &>/dev/null; then
    manager=$(curl -fs "${url}/package.json" | jq -r --arg key "$key_name" '.[$key]')
    if [[ "$manager" == "null" ]]; then
      manager=""
    fi
  else
    manager=$(curl -fs "${url}/package.json" | grep -E '"'$key_name'"\s*:\s*"' | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  # 1. Lockfile-based detection (most reliable)
  if curl -fs "${url}/bun.lockb" -o /dev/null; then
    manager="bun"
  elif curl -fs "${url}/pnpm-lock.yaml" -o /dev/null; then
    manager="pnpm"
  elif curl -fs "${url}/yarn.lock" -o /dev/null; then
    manager="yarn"
  elif curl -fs "${url}/package-lock.json" -o /dev/null; then
    manager="npm"
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  local pyproject="pyproject.toml"

  if curl -fs "${url}/${pyproject}" | grep -qE '^\s*\[tool\.poe\.tasks\]'; then
    manager="poe"
  fi

  echo "$manager"
}

function detect_pkg_manager_() {
  local folder="$1"

  local manager=""
  local pkg_json="package.json"
  local pyproject="pyproject.toml"

  folder=$(get_proj_for_pkg_from_within_ "$folder" 2>/dev/null)
  
  if [[ -z "$folder" ]]; then
    return 1
  fi

  local _pwd="$(pwd)"

  cd "$folder"

  if [[ -f "$pkg_json" ]]; then
    local line="$(get_from_pkg_json_ "packageManager" "$pkg_json")"
    
    if [[ $line =~ ([^\"]+) ]]; then
      manager="${match[1]%%@*}"
      echo "$manager"
      cd "$_pwd"
      return 0;
    fi
  fi

  # 1. Lockfile-based detection (most reliable)
  if [[ -f "bun.lockb" ]]; then
    manager="bun"
  elif [[ -f "pnpm-lock.yaml" ]]; then
    manager="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    manager="yarn"
  elif [[ -f "package-lock.json" ]]; then
    manager="npm"
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    cd "$_pwd"
    return 0;
  fi

  if [[ -f "$pyproject" ]] && grep -qE '^\s*\[tool\.poe\.tasks\]' "$pyproject"; then
    manager="poe"
  else
    manager="npm"
  fi

  cd "$_pwd"

  echo "$manager"
}

function save_proj_() {
  # a - add, f - force, e - edit
  eval "$(parse_flags_ "save_proj_" "afe" "$@")"
  (( save_proj_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_ index is invalid: $i"
    return 1;
  fi

  # display header
  local cor=""
  if (( save_proj_is_e )); then
    cor="${bright_yellow_cor}"
    display_line_ "edit project: ${pkg_name}" "${cor}"
  else
    cor="${bright_green_cor}"
    display_line_ "add new project" "${cor}"
  fi

  if (( save_proj_is_e )); then
    if ! save_proj_repo_ -e $i "${PUMP_PROJECT_FOLDER[$i]}" "$pkg_name" "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi
    if ! save_proj_folder_ -e $i "$pkg_name" "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi

  elif (( save_proj_is_f )); then
    # for pro pwd, all the settings come from the pwd
    PUMP_PROJECT_REPO[$i]=""
    PUMP_PROJECT_FOLDER[$i]=""
    PUMP_PACKAGE_MANAGER[$i]=""
    PUMP_PROJECT_SINGLE_MODE[$i]=1

    local proj_folder="$(pwd)"
    local proj_repo="$(git remote get-url "$(get_remote_origin_)" 2>/dev/null)"

    while [[ -z "${PUMP_PROJECT_FOLDER[$i]}" ]]; do
      if ! save_proj_repo_ -a $i "$proj_folder" "$pkg_name" "$proj_repo"; then return 1; fi
      if ! save_proj_folder_ -a $i "$pkg_name" "${PUMP_PROJECT_REPO[$i]}" "$proj_folder"; then return 1; fi

      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"
      proj_repo="${PUMP_PROJECT_REPO[$i]}"
    done

  elif (( save_proj_is_a )); then
    PUMP_PROJECT_REPO[$i]=""
    PUMP_PROJECT_FOLDER[$i]=""
    PUMP_PACKAGE_MANAGER[$i]=""
    PUMP_PROJECT_SINGLE_MODE[$i]=""

    while [[ -z "${PUMP_PROJECT_FOLDER[$i]}" ]]; do
      if ! save_proj_repo_ -a $i "${PUMP_PROJECT_FOLDER[$i]}" "$pkg_name" "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi
      if ! save_proj_folder_ -a $i "$pkg_name" "${PUMP_PROJECT_REPO[$i]}" "${PUMP_PROJECT_FOLDER[$i]}"; then return 1; fi
    done

    if is_git_repo_ "${PUMP_PROJECT_FOLDER[$i]}" &>/dev/null || is_proj_folder_ "${PUMP_PROJECT_FOLDER[$i]}" &>/dev/null; then
      PUMP_PROJECT_SINGLE_MODE[$i]=1
    elif get_proj_for_git_ "${PUMP_PROJECT_FOLDER[$i]}" &>/dev/null; then
      PUMP_PROJECT_SINGLE_MODE[$i]=0
    fi
  fi

  if ! save_pkg_manager_ $i "${PUMP_PROJECT_FOLDER[$i]}" "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi
  if ! save_proj_mode_ $i "${PUMP_PROJECT_FOLDER[$i]}" "${PUMP_PROJECT_SINGLE_MODE[$i]}"; then return 1; fi
  
  TEMP_PUMP_PROJECT_SHORT_NAME=""
  if (( save_proj_is_e )); then
    if ! save_proj_cmd_ -e $i "$pkg_name"; then return 1; fi
  else
    if ! save_proj_cmd_ -a $i "$pkg_name"; then return 1; fi
  fi

  print "  ${pink_cor}project name:${reset_cor} ${PUMP_PROJECT_SHORT_NAME[$i]}" >&1

  display_line_ "" "${cor}"
  print "  ${cor}project saved!${reset_cor}" >&1

  load_config_entry_ $i

  if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
    save_current_proj_ $i
  fi

  if (( save_proj_is_f )) || [[ -z "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    pro -s "${PUMP_PROJECT_SHORT_NAME[$i]}"
  else
    print "" >&1
    print "  now try running: ${yellow_cor}${PUMP_PROJECT_SHORT_NAME[$i]}${reset_cor}" >&1
  fi

  return 0;
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
  unset -f fix &>/dev/null
  unset -f format &>/dev/null
  unset -f ig &>/dev/null
  unset -f lint &>/dev/null
  unset -f rdev &>/dev/null
  unset -f tsc &>/dev/null
  unset -f sb &>/dev/null
  unset -f sbb &>/dev/null
  unset -f start &>/dev/null
}

function set_aliases_() {
  local i="$1"

  if ! check_proj_pkg_manager_ -s $i "$CURRENT_PUMP_PACKAGE_MANAGER" "$CURRENT_PUMP_PROJECT_FOLDER"; then return 1; fi

  if [[ -z "$CURRENT_PUMP_PACKAGE_MANAGER" ]]; then
    CURRENT_PUMP_PACKAGE_MANAGER="${PUMP_PACKAGE_MANAGER[$i]}"
  fi

  # Reset all aliases
  #unalias -a &>/dev/null
  alias i="$CURRENT_PUMP_PACKAGE_MANAGER install"
  # Package manager aliases =========================================================
  alias build="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  alias deploy="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  alias fix="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format && $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  alias format="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  alias ig="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install --global"
  alias lint="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  alias rdev="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  alias tsc="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  alias sb="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  alias sbb="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  alias start="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"

  if [[ "$CURRENT_PUMP_COV" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    alias ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}cov="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    alias ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}test="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$CURRENT_PUMP_E2E" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    alias ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}e2e="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$CURRENT_PUMP_E2EUI" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    alias ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}e2eui="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$CURRENT_PUMP_TEST_WATCH" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    alias ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}testw="$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
}

function remove_prj_() {
  i="$1"

  unset_aliases_
  unset -f "${PUMP_PROJECT_SHORT_NAME[$i]}" &>/dev/null

  update_setting_ $i "PUMP_PROJECT_SHORT_NAME" "" # let this one
  update_setting_ $i "PUMP_PROJECT_FOLDER" "" 1>/dev/null
  update_setting_ $i "PUMP_PROJECT_REPO" "" 1>/dev/null
  update_setting_ $i "PUMP_PROJECT_SINGLE_MODE" "" 1>/dev/null
  update_setting_ $i "PUMP_PACKAGE_MANAGER" "" 1>/dev/null
  update_setting_ $i "PUMP_CODE_EDITOR" "" 1>/dev/null
  update_setting_ $i "PUMP_CLONE" "" 1>/dev/null
  update_setting_ $i "PUMP_SETUP" "" 1>/dev/null
  update_setting_ $i "PUMP_RUN" "" 1>/dev/null
  update_setting_ $i "PUMP_RUN_STAGE" "" 1>/dev/null
  update_setting_ $i "PUMP_RUN_PROD" "" 1>/dev/null
  update_setting_ $i "PUMP_PRO" "" 1>/dev/null
  update_setting_ $i "PUMP_TEST" "" 1>/dev/null
  update_setting_ $i "PUMP_COV" "" 1>/dev/null
  update_setting_ $i "PUMP_TEST_WATCH" "" 1>/dev/null
  update_setting_ $i "PUMP_E2E" "" 1>/dev/null
  update_setting_ $i "PUMP_E2EUI" "" 1>/dev/null
  update_setting_ $i "PUMP_PR_TEMPLATE" "" 1>/dev/null
  update_setting_ $i "PUMP_PR_REPLACE" "" 1>/dev/null
  update_setting_ $i "PUMP_PR_APPEND" "" 1>/dev/null
  update_setting_ $i "PUMP_PR_RUN_TEST" "" 1>/dev/null
  update_setting_ $i "PUMP_GHA_INTERVAL" "" 1>/dev/null
  update_setting_ $i "PUMP_COMMIT_ADD" "" 1>/dev/null
  update_setting_ $i "PUMP_GHA_WORKFLOW" "" 1>/dev/null
  update_setting_ $i "CURRENT_PUMP_PUSH_ON_REFIX" "" 1>/dev/null
  update_setting_ $i "PUMP_DEFAULT_BRANCH" "" 1>/dev/null
  update_setting_ $i "PUMP_PRINT_README" "" 1>/dev/null
}

function save_current_proj_() {
  local i="$1"

  CURRENT_PUMP_PROJECT_SHORT_NAME="${PUMP_PROJECT_SHORT_NAME[$i]}"
  CURRENT_PUMP_PROJECT_FOLDER="${PUMP_PROJECT_FOLDER[$i]}"
  CURRENT_PUMP_PROJECT_REPO="${PUMP_PROJECT_REPO[$i]}"
  CURRENT_PUMP_PROJECT_SINGLE_MODE="${PUMP_PROJECT_SINGLE_MODE[$i]}"
  CURRENT_PUMP_PACKAGE_MANAGER="${PUMP_PACKAGE_MANAGER[$i]}"
  CURRENT_PUMP_CODE_EDITOR="${PUMP_CODE_EDITOR[$i]}"
  CURRENT_PUMP_CLONE="${PUMP_CLONE[$i]}"
  CURRENT_PUMP_SETUP="${PUMP_SETUP[$i]}"
  CURRENT_PUMP_RUN="${PUMP_RUN[$i]}"
  CURRENT_PUMP_RUN_STAGE="${PUMP_RUN_STAGE[$i]}"
  CURRENT_PUMP_RUN_PROD="${PUMP_RUN_PROD[$i]}"
  CURRENT_PUMP_PRO="${PUMP_PRO[$i]}"
  CURRENT_PUMP_TEST="${PUMP_TEST[$i]}"
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
  CURRENT_PUMP_DEFAULT_BRANCH="${PUMP_DEFAULT_BRANCH[$i]}"
  CURRENT_PUMP_PRINT_README="${PUMP_PRINT_README[$i]}"
}

# function clear_curr_prj_() {
#   load_config_entry_
#   unset_aliases_
#   save_current_proj_ 0
# }

function get_proj_index_() {
  local proj_arg="$1"

  if [[ -z "$proj_arg" ]]; then
    return 1;
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      echo "$i"
      return 0;
    fi
  done

  return 1;
}

function is_project_() {
  local proj_arg="$1"

  if ! get_proj_index_ "$proj_arg" 1>/dev/null; then return 1; fi
}

function print_current_proj_() {
  local i="$1"
  
  display_line_ "" "$dark_gray_cor"

  if (( i > 0 )); then
    print "${solid_magenta_cor} PUMP_PROJECT_SHORT_NAME_$i=${reset_cor}${PUMP_PROJECT_SHORT_NAME[$i]}"
    print "${solid_magenta_cor} PUMP_PROJECT_FOLDER_$i=${reset_cor}${PUMP_PROJECT_FOLDER[$i]}"
    print "${solid_magenta_cor} PUMP_PROJECT_REPO_$i=${reset_cor}${PUMP_PROJECT_REPO[$i]}"
    print "${solid_magenta_cor} PUMP_PROJECT_SINGLE_MODE_$i=${reset_cor}${PUMP_PROJECT_SINGLE_MODE[$i]}"
    print "${solid_magenta_cor} PUMP_PACKAGE_MANAGER_$i=${reset_cor}${PUMP_PACKAGE_MANAGER[$i]}"
    print "${solid_magenta_cor} PUMP_RUN_$i=${reset_cor}${PUMP_RUN[$i]}"
    print "${solid_magenta_cor} PUMP_RUN_STAGE_$i=${reset_cor}${PUMP_RUN_STAGE[$i]}"
    print "${solid_magenta_cor} PUMP_RUN_PROD_$i=${reset_cor}${PUMP_RUN_PROD[$i]}"
    print "${solid_magenta_cor} PUMP_SETUP_$i=${reset_cor}${PUMP_SETUP[$i]}"
    print "${solid_magenta_cor} PUMP_CLONE_$i=${reset_cor}${PUMP_CLONE[$i]}"
    print "${solid_magenta_cor} PUMP_PRO_$i=${reset_cor}${PUMP_PRO[$i]}"
    print "${solid_magenta_cor} PUMP_CODE_EDITOR_$i=${reset_cor}${PUMP_CODE_EDITOR[$i]}"
    print "${solid_magenta_cor} PUMP_COV_$i=${reset_cor}${PUMP_COV[$i]}"
    print "${solid_magenta_cor} PUMP_OPEN_COV_$i=${reset_cor}${PUMP_OPEN_COV_[$i]}"
    print "${solid_magenta_cor} PUMP_TEST_$i=${reset_cor}${PUMP_TEST[$i]}"
    print "${solid_magenta_cor} PUMP_TEST_WATCH_$i=${reset_cor}${PUMP_TEST_WATCH[$i]}"
    print "${solid_magenta_cor} PUMP_E2E_$i=${reset_cor}${PUMP_E2E[$i]}"
    print "${solid_magenta_cor} PUMP_E2EUI_$i=${reset_cor}${PUMP_E2EUI[$i]}"
    print "${solid_magenta_cor} PUMP_PR_TEMPLATE_$i=${reset_cor}${PUMP_PR_TEMPLATE[$i]}"
    print "${solid_magenta_cor} PUMP_PR_REPLACE_$i=${reset_cor}${PUMP_PR_REPLACE[$i]}"
    print "${solid_magenta_cor} PUMP_PR_APPEND_$i=${reset_cor}${PUMP_PR_APPEND[$i]}"
    print "${solid_magenta_cor} PUMP_PR_RUN_TEST_$i=${reset_cor}${PUMP_PR_RUN_TEST[$i]}"
    print "${solid_magenta_cor} PUMP_COMMIT_ADD_$i=${reset_cor}${PUMP_COMMIT_ADD[$i]}"
    print "${solid_magenta_cor} PUMP_PUSH_ON_REFIX_$i=${reset_cor}${PUMP_PUSH_ON_REFIX[$i]}"
    print "${solid_magenta_cor} PUMP_DEFAULT_BRANCH_$i=${reset_cor}${PUMP_DEFAULT_BRANCH[$i]}"
    print "${solid_magenta_cor} PUMP_PRINT_README_$i=${reset_cor}${PUMP_PRINT_README[$i]}"
    print "${solid_magenta_cor} PUMP_GHA_INTERVAL_$i=${reset_cor}${PUMP_GHA_INTERVAL[$i]}"
    print "${solid_magenta_cor} PUMP_GHA_WORKFLOW_$i=${reset_cor}${PUMP_GHA_WORKFLOW[$i]}"

    return 0;
  fi

  print "${pink_cor} CURRENT_PUMP_PROJECT_SHORT_NAME=${reset_cor}$CURRENT_PUMP_PROJECT_SHORT_NAME"
  print "${pink_cor} CURRENT_PUMP_PROJECT_FOLDER=${reset_cor}$CURRENT_PUMP_PROJECT_FOLDER"
  print "${pink_cor} CURRENT_PUMP_PROJECT_REPO=${reset_cor}$CURRENT_PUMP_PROJECT_REPO"
  print "${pink_cor} CURRENT_PUMP_PROJECT_SINGLE_MODE=${reset_cor}$CURRENT_PUMP_PROJECT_SINGLE_MODE"
  print "${pink_cor} CURRENT_PUMP_PACKAGE_MANAGER=${reset_cor}$CURRENT_PUMP_PACKAGE_MANAGER"
  print "${pink_cor} CURRENT_PUMP_RUN=${reset_cor}$CURRENT_PUMP_RUN"
  print "${pink_cor} CURRENT_PUMP_RUN_STAGE=${reset_cor}$CURRENT_PUMP_RUN_STAGE"
  print "${pink_cor} CURRENT_PUMP_RUN_PROD=${reset_cor}$CURRENT_PUMP_RUN_PROD"
  print "${pink_cor} CURRENT_PUMP_SETUP=${reset_cor}$CURRENT_PUMP_SETUP"
  print "${pink_cor} CURRENT_PUMP_CLONE=${reset_cor}$CURRENT_PUMP_CLONE"
  print "${pink_cor} CURRENT_PUMP_PRO=${reset_cor}$CURRENT_PUMP_PRO"
  print "${pink_cor} CURRENT_PUMP_CODE_EDITOR=${reset_cor}$CURRENT_PUMP_CODE_EDITOR"
  print "${pink_cor} CURRENT_PUMP_COV=${reset_cor}$CURRENT_PUMP_COV"
  print "${pink_cor} CURRENT_PUMP_OPEN_COV=${reset_cor}$CURRENT_PUMP_OPEN_COV"
  print "${pink_cor} CURRENT_PUMP_TEST=${reset_cor}$CURRENT_PUMP_TEST"
  print "${pink_cor} CURRENT_PUMP_TEST_WATCH=${reset_cor}$CURRENT_PUMP_TEST_WATCH"
  print "${pink_cor} CURRENT_PUMP_E2E=${reset_cor}$CURRENT_PUMP_E2E"
  print "${pink_cor} CURRENT_PUMP_E2EUI=${reset_cor}$CURRENT_PUMP_E2EUI"
  print "${pink_cor} CURRENT_PUMP_PR_TEMPLATE=${reset_cor}$CURRENT_PUMP_PR_TEMPLATE"
  print "${pink_cor} CURRENT_PUMP_PR_REPLACE=${reset_cor}$CURRENT_PUMP_PR_REPLACE"
  print "${pink_cor} CURRENT_PUMP_PR_APPEND=${reset_cor}$CURRENT_PUMP_PR_APPEND"
  print "${pink_cor} CURRENT_PUMP_PR_RUN_TEST=${reset_cor}$CURRENT_PUMP_PR_RUN_TEST"
  print "${pink_cor} CURRENT_PUMP_COMMIT_ADD=${reset_cor}$CURRENT_PUMP_COMMIT_ADD"
  print "${pink_cor} CURRENT_PUMP_PUSH_ON_REFIX=${reset_cor}$CURRENT_PUMP_PUSH_ON_REFIX"
  print "${pink_cor} CURRENT_PUMP_DEFAULT_BRANCH=${reset_cor}$CURRENT_PUMP_DEFAULT_BRANCH"
  print "${pink_cor} CURRENT_PUMP_PRINT_README=${reset_cor}$CURRENT_PUMP_PRINT_README"
  print "${pink_cor} CURRENT_PUMP_GHA_INTERVAL=${reset_cor}$CURRENT_PUMP_GHA_INTERVAL"
  print "${pink_cor} CURRENT_PUMP_GHA_WORKFLOW=${reset_cor}$CURRENT_PUMP_GHA_WORKFLOW"
}

function which_pro_index_pwd_() {
  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" && -n "${PUMP_PROJECT_FOLDER[$i]}" ]]; then
      if [[ $(pwd) == $PUMP_PROJECT_FOLDER[$i]* ]]; then
        echo "$i"
        return 0;
      fi
    fi
  done

  echo "0"
  return 1;
}

function which_pro_pwd_() {
  local i=0
  local current_path=$(realpath "$(pwd)" 2>/dev/null)
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" && -n "${PUMP_PROJECT_FOLDER[$i]}" ]]; then
      local proj_path=""
      proj_path=$(realpath "${PUMP_PROJECT_FOLDER[$i]}" 2>/dev/null)
      if (( $? == 0 )) && [[ -n "$proj_path" && $current_path == $proj_path* ]]; then
        echo "${PUMP_PROJECT_SHORT_NAME[$i]}"
        return 0;
      fi
    fi
  done

  # Cannot determine project based on pwd
  return 1;
}

function is_proj_folder_() {
  local folder="$1"

  if ! get_proj_for_pkg_from_within_ "$folder" 1>/dev/null; then return 2; fi

  return 0;
}

function get_proj_for_pkg_from_within_() {
  local folder="$1"

  if [[ -z "$1" ]]; then
    print " fatal: no argument provided" >&2
    return 2;
  fi

  if [[ -n "$folder" && -d "$folder" ]]; then
    if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" ]]; then # || -f "$folder/environment.yml" || -f "$folder/Cargo.toml"  ]]; then
      echo "$folder"
      return 0;
    fi

    while [[ "$folder" != "/" ]]; do
      if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" ]]; then # || -f "$folder/environment.yml" || -f "$folder/Cargo.toml" ]]; then
        echo "$folder"
        return 0;
      fi
      folder="$(dirname "$folder")"
    done
  fi

  print " not a project folder: $1" >&2

  return 1;
}

function is_git_repo_() {
  local folder="$1"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " not a git repository (or any of the parent directories): $folder" >&2 
    return 1;
  fi

  if ! git -C "$folder" rev-parse --is-inside-work-tree 1>/dev/null; then 
    return 1;
  fi
  
  return 0;
}

function get_default_folder_() {
  local proj_folder="${1:-$(pwd)}"
  local git_folder=$(get_proj_for_git_ "$proj_folder")

  if [[ -z "$git_folder" ]]; then
    return 1;
  fi

  local _pwd=$(pwd)
  cd "$git_folder"
  local default_folder="$(git config --get init.defaultBranch)"
  cd "$_pwd"

  if is_git_repo_ "${proj_folder}/${default_folder}" &>/dev/null; then    
    echo "${proj_folder}/${default_folder}"
  else
    echo "$git_folder"
  fi
}

function shorten_path_() {
  local folder="$1"
  local count="${2:-2}"

  # Remove trailing slash if present
  local folder="${folder%/}"

  # split path into array
  IFS='/' parts=(${(s:/:)folder})
  # IFS='/' read -r -A parts <<< "$folder" # either way works, but this in bash
  local len=${#parts[@]}

  # Calculate start index
  local start=$(( len - count ))

  (( start < 0 )) && start=0

  # Print the last COUNT elements joined by /
  local output="${(j:/:)parts[@]:$start}"

  # Prepend ".../" if not returning the full path
  if (( count < len )); then
    if [[ -z "$3" ]]; then
      echo ".../$output"
      return 0;
    fi
  fi

  echo "$output"
}

function open_proj_for_pkg_() {
  local folder="$1"
  local file="$2"

  if [[ -z "$1" ]]; then
    print " fatal: no argument provided" >&2
    return 1;
  fi

  local proj_folder=$(get_proj_for_pkg_ "$folder" "$file")
  if [[ -z "$proj_folder" ]]; then
    return 1;
  fi

  cd "$proj_folder"
}

function get_proj_for_pkg_() {
  local folder="$1"
  local file="$2"

  if [[ ! -d "$folder" ]]; then
    return 1;
  fi

  if [[ -n "$file" && -n $(ls "$folder" | grep -i "^${(q)file}\$") ]]; then
    echo "$folder"
    return 0;
  else
    if [[ -f "$folder/package.json" || -f "$folder/pyproject.toml" ]]; then
      echo "$folder"
      return 0;
    fi
  fi

  local folders=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop")

  # Loop through each folder name
  local dir=""
  for dir in "${folders[@]}"; do
    if [[ -n "$file" && -d "${folder}/${dir}" && -n $(ls "${folder}/${dir}" | grep -i "^${(q)file}\$") ]]; then
      echo "${folder}/${dir}"
      return 0;
    else
      if [[ -d "${folder}/${dir}" && -f "$folder/${dir}/$file" || -f "${folder}/${dir}/package.json" || -f "${folder}/${dir}/pyproject.toml" ]]; then
        echo "${folder}/${dir}"
        return 0;
      fi
    fi
  done

  return 1;
}

function open_proj_for_git_() {
  local folder="$1"

  if [[ -z "$1" ]]; then
    print " fatal: no argument provided" >&2
    return 1;
  fi

  local git_folder=$(get_proj_for_git_ "$folder")

  if [[ -z "$git_folder" ]]; then
    print " not a git repository (or any of the parent directories): $folder" >&2
    return 1;
  fi

  cd "$git_folder"
}

function get_proj_for_git_() {
  local folder="$1"

  if is_git_repo_ "$folder"; then
    echo "$folder"
    return 0;
  fi

  local folders=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop")

  # Loop through each folder name
  local dir=""
  for dir in "${folders[@]}"; do
    if is_git_repo_ "${folder}/${dir}"; then
      echo "${folder}/${dir}"
      return 0;
    fi
  done

  return 1;
}

function get_remote_origin_() {
  local branch="$1"

  if [[ -z "$branch" ]]; then
    branch="$(git branch --show-current 2>/dev/null)"
  fi

  local remote_origin=""
  
  if [[ -n "$branch" ]]; then
    remote_origin="$(git config --get branch.${branch}.remote 2>/dev/null)"
  fi

  if [[ -z "$remote_origin" ]]; then
    remote_origin="origin"
  fi

  echo "$remote_origin"
}

function select_branch_() {
  # select_branch_ -a <search_text>
  local auto=${1:-0}
  local filter="$2"
  local searchText="$3"
  local multiple=${4:-0}
  local header="" # $5
  local include_special_branches=${6:-1}

  local remote_origin="$(get_remote_origin_)"

  local branch_choices=""

  # | sed "s/^${remote_origin}\///" \

  if [[ "$filter" == "--all" || "$filter" == "-a" ]]; then
    branch_choices=$(git branch --all --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -i "$searchText" \
      | sort -fu
    )
  elif [[ "$filter" == "-r" ]]; then
    branch_choices=$(git for-each-ref --format='%(refname:short)' refs/remotes \
      | grep -v "^${remote_origin}/HEAD\$" \
      | grep -i "$searchText" \
      | sort -fu
    )
  else
    branch_choices=$(git branch --list --format="%(refname:short)" \
      | grep -v "${remote_origin}/" \
      | grep -v 'detached' \
      | grep -i "$searchText" \
      | sort -fu
    )
  fi

  if (( ! include_special_branches )); then
    local excluded_branches=("main" "master" "dev" "develop" "stage" "staging")

    local branch_choices_array=($(echo "$branch_choices" | tr '\n' ' '))
    local filtered_branches=()

    for branch in "${branch_choices_array[@]}"; do
      if [[ ! " ${excluded_branches[@]} " == *" $branch "* ]]; then
        filtered_branches+=("$branch")
      fi
    done

    branch_choices="${filtered_branches[@]}"
  fi

  if [[ -z "$branch_choices" ]]; then
    if [[ -n "$searchText" ]]; then
      print " did not match any branch known to git: $searchText" >&2
    else
      print " did not find any branch known to git" >&2
    fi
    return 1;
  fi

  local select_branch_choices=""

  if (( multiple )); then
    header=${5:-"choose branches"}
    select_branch_choices=$(choose_multiple_ 0 "$header" 20 $(echo "$branch_choices" | tr ' ' '\n'))
  else
    header=${5:-"choose a branch"}

    local branch_choices_count=$(echo "$branch_choices" | wc -l)
    
    if [[ $branch_choices_count -gt 20 ]]; then
      select_branch_choices=$(filter_one_ $auto "$header" "type to filter" $(echo "$branch_choices" | tr ' ' '\n'))
    else
      select_branch_choices=$(choose_one_ $auto "$header" 20 $(echo "$branch_choices" | tr ' ' '\n'))
    fi
  fi

  local clean_branch_choices=()

  for branch in "${select_branch_choices[@]}"; do
    branch=$(echo "$branch" | sed "s/^${remote_origin}\///")
    clean_branch_choices+=("$branch")
  done

  echo "${clean_branch_choices[@]}"
}

function select_pr_() {
  if ! command -v gh &>/dev/null; then
    print " requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  local pr_list=$(gh pr list | grep -i "$1" | awk -F'\t' '{print $1 "\t" $2 "\t" $3}');

  if [[ -z "$pr_list" ]]; then
    print " no pull requests found" >&2
    print "" >&2
    return 1;
  fi

  local titles=$(echo "$pr_list" | cut -f2);
  local count=$(echo "$pr_list" | wc -l)

  local select_pr_title=""

  if [[ $count -gt 20 ]]; then
    print "${purple_cor} choose pull request: ${reset_cor}" >&2
    select_pr_title=$(echo "$titles" | gum filter --limit 1 --select-if-one --height 20  --indicator=">" --placeholder=" type to filter");
  else
    select_pr_title=$(echo "$titles" | gum choose --limit 1 --select-if-one --height 20 --header=" choose pull request:");
  fi

  if [[ -z "$select_pr_title" ]]; then
    return 1;
  fi

  local select_pr_choice="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}')"
  local select_pr_branch="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}')"

  if [[ -z "$select_pr_choice" || -z "$select_pr_branch" ]]; then
    return 1;
  fi

  echo "${select_pr_choice}|${select_pr_branch}|${select_pr_title}"

  return 0;
}

function get_repo_name_() {
  local uri="$1"
  local mode="$2"

  local repo=""

  if (( mode == 1 )); then
    # Remove trailing .git if present
    uri="${uri%.git}"

    # Extract the last path segment (after the last slash or colon)
    repo="${uri##*/}"           # handles https
    repo="${repo##*:}"          # handles ssh

    echo "$repo"
    return 0;
  fi

  if [[ "$uri" == git@*:* ]]; then
    # SSH-style: git@host:user/repo.git
    if [[ "$uri" =~ '^[^@]+@[^:]+:([^[:space:]]+)(\.git)?$' ]]; then
      repo="${match[1]}"
    fi
  elif [[ "$uri" == http*://* ]]; then
    # HTTPS-style: https://host/user/repo(.git)
    if [[ "$uri" =~ '^https\?*://[^/]+/([^[:space:]]+)(\.git)?$' ]]; then
      repo="${match[1]}"
    fi
  fi

  echo "$repo"
}

function open_working_() {
  local project="$node_project[$head]"
  local folder="$node_folder[$head]"
  local branch="$node_branch[$head]"

  local past_folder="$(pwd)"
  local past_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
  
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

function get_clone_default_branch_() {
  # $1 = repo uri # $2 = folder # $3 = branch to clone
  if [[ "$3" == "main" || "$3" == "master" ]]; then
    echo "$3"
    return 0;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="determining the default branch..." -- rm -rf "$2/.temp";
    if ! gum spin --title="determining the default branch..." -- git clone "$1" "$2/.temp" --quiet; then return 1; fi
  else
    print " determining the default branch..."
    rm -rf "$2/.temp" &>/dev/null
    if ! git clone "$1" "$2/.temp" --quiet; then return 1; fi
  fi

  pushd "$2/.temp" &>/dev/null
  
  local default_branch="$(git config --get init.defaultBranch)"
  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  popd &>/dev/null

  rm -rf "$2/.temp" &>/dev/null

  local default_branch_folder="${default_branch//\\/-}"
  default_branch_folder="${default_branch_folder//\//-}"

  local my_branch_folder="${my_branch//\\/-}"
  my_branch_folder="${my_branch_folder//\//-}"

  if [[ -z "$3" ]]; then
    if [[ -d "$2/$default_branch_folder" ]]; then
      default_branch=""
    fi

    if [[ -d "$2/$my_branch_folder" ]]; then
      my_branch=""
    fi
  fi


  local default_branch_choice="";

  if [[ "$my_branch" != "$default_branch" && -n "$default_branch" && -n "$my_branch" ]]; then
    default_branch_choice=$(choose_one_ 1 "choose default branch" 5 "$default_branch" "$my_branch");
    if (( $? != 0 )); then return 1; fi

  elif [[ -n "$default_branch" ]]; then
    default_branch_choice="$default_branch";
  elif [[ -n "$my_branch" ]]; then
    default_branch_choice="$my_branch";
  fi

  if [[ -z "$default_branch_choice" ]]; then
    return 1;
  fi

  echo "$default_branch_choice"
}

function get_from_pkg_json_() {
  local key_name="${1:-name}"
  local pkg_json="${2:-"package.json"}"

  if [[ -f "$pkg_json" ]]; then
    local value;
    if command -v jq &>/dev/null; then
      value=$(jq -r --arg key "$key_name" '.[$key]' "$pkg_json")
      if [[ "$value" == "null" ]]; then
        value=""
      fi
    else
      value=$(grep -E '"'$key_name'"\s*:\s*"' "$pkg_json" | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
    fi
    if [[ -n "$value" ]]; then
      echo "$value"
      return 0;
    fi
  fi
}

function load_config_entry_() {
  local i=${1:-0}

  local keys=(
    PUMP_PROJECT_SINGLE_MODE
    PUMP_PACKAGE_MANAGER
    PUMP_CODE_EDITOR
    PUMP_CLONE
    PUMP_SETUP
    PUMP_RUN
    PUMP_RUN_STAGE
    PUMP_RUN_PROD
    PUMP_PRO
    PUMP_TEST
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
    PUMP_DEFAULT_BRANCH
    PUMP_PRINT_README
  )

  local key=""
  for key in "${keys[@]}"; do
    value=$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")

    # If the value is not set, provide default values for specific keys
    if [[ -z "$value" ]]; then
      local run=$([[ $PUMP_PACKAGE_MANAGER[$i] == "yarn" ]] && echo "" || echo "run ")

      case "$key" in
        # PUMP_PROJECT_SINGLE_MODE) # on clone we want to let the user select the mode if nothing is set on the config
        #   value="0"
        #   ;;
        PUMP_PACKAGE_MANAGER)
          value="npm"
          ;;
        PUMP_CODE_EDITOR)
          value="code"
          ;;
        PUMP_RUN)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}dev"
          ;;
        PUMP_RUN_STAGE)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}stage"
          ;;
        PUMP_RUN_PROD)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}prod"
          ;;
        PUMP_TEST)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}test"
          ;;
        PUMP_COV)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}test:coverage"
          ;;
        PUMP_TEST_WATCH)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}test:watch"
          ;;
        PUMP_E2E)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}test:e2e"
          ;;
        PUMP_E2EUI)
          value="${PUMP_PACKAGE_MANAGER[$i]} ${run}test:e2e-ui"
          ;;
        PUMP_PR_APPEND)
          value="0"
          ;;
        PUMP_GHA_INTERVAL)
          value="10"
          ;;
        PUMP_PRINT_README)
          value="0"
          ;;
        *)
          continue
          ;;
      esac
    fi

    # store the value
    case "$key" in
      PUMP_PROJECT_SINGLE_MODE)
        PUMP_PROJECT_SINGLE_MODE[$i]="$value"
        ;;
      PUMP_PACKAGE_MANAGER)
        PUMP_PACKAGE_MANAGER[$i]="$value"
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
      PUMP_TEST)
        PUMP_TEST[$i]="$value"
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
      PUMP_DEFAULT_BRANCH)
        PUMP_DEFAULT_BRANCH[$i]="$value"
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
    esac
    # print "$i - key: $key, value: $value"
  done
}

function load_config_() {
  load_config_entry_
  # Iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    proj_cmd=$(sed -n "s/^PUMP_PROJECT_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJECT_SHORT_NAME_${i}" >&2
      continue;
    fi

    [[ -z "$proj_cmd" ]] && continue;  # skip if not defined

    if ! validate_proj_cmd_ "$proj_cmd"; then
      print "  in config data at PUMP_PROJECT_SHORT_NAME_${i}" >&2
      continue;
    fi

    PUMP_PROJECT_SHORT_NAME[$i]="$proj_cmd"

    # Set project repo
    local proj_repo=""
    proj_repo=$(sed -n "s/^PUMP_PROJECT_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJECT_REPO_${i}" >&2
      continue;
    fi

    PUMP_PROJECT_REPO[$i]="$proj_repo"

    # Set project folder path
    local proj_folder=""
    proj_folder=$(sed -n "s/^PUMP_PROJECT_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJECT_FOLDER_${i}" >&2
      continue;
    fi

    if [[ -n "$proj_folder" ]]; then
      if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then
        print "  error in config data at PUMP_PROJECT_FOLDER_${i}" >&2
      fi
    fi

    PUMP_PROJECT_FOLDER[$i]="$proj_folder"

    load_config_entry_ $i
  done
}

function activate_pro_() {
  local use_pwd="$1"

  local pump_pro_file_value=""
  local project_names=()

  # pro pwd
  if (( use_pwd )) && pro -f "pwd" 2>/dev/null; then
    return 0;
  fi

  # Read the current project short name from the PUMP_PRO_FILE if it exists
  if [[ -f "$PUMP_PRO_FILE" ]]; then
    pump_pro_file_value=$(<"$PUMP_PRO_FILE")

    if [[ -n "$pump_pro_file_value" ]]; then
      local i=0
      for i in {1..9}; do
        if [[ "$pump_pro_file_value" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          if ! validate_proj_cmd_ "$pump_pro_file_value" &>/dev/null; then
            rm -f "$PUMP_PRO_FILE" &>/dev/null
            pump_pro_file_value=""
          else
            project_names=("$pump_pro_file_value")
          fi
          break;
        fi
      done
    fi
  fi

  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      if [[ ! " ${project_names[@]} " =~ " ${PUMP_PROJECT_SHORT_NAME[$i]} " ]]; then
        project_names+=("${PUMP_PROJECT_SHORT_NAME[$i]}")
      fi
    fi
  done

  # Loop over the projects to check and execute them
  for project in "${project_names[@]}"; do
    if pro -f "$project" 2>/dev/null; then
      break;
    fi
  done
}

function branch_status_() {
  local branch="$1"
  local default_branch="$(git config --get init.defaultBranch)"

  if [[ -z "$branch" ]]; then
    branch="$(git config --get init.defaultBranch)";
  fi

  if [[ -z "$branch" ]]; then
    return 0;
  fi

  local remote_origin="$(get_remote_origin_ "$branch")"

  git fetch "$remote_origin" "$branch" --quiet
  read behind ahead < <(git rev-list --left-right --count "$remote_origin/$branch...HEAD")

  if [[ "$branch" == "$default_branch" ]]; then
    if (( behind )); then
      print " ${yellow_cor}warning${reset_cor}: your branch is behind "$branch" by $behind commits and ahead by $ahead commits" >&2
    fi
  else
    if (( behind || ahead )); then
      print " ${yellow_cor}warning${reset_cor}: your branch is behind "$branch" by $behind commits and ahead by $ahead commits" >&2
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
  eval "$(parse_flags_ "refresh_" "" "$@")"
  #(( refresh_is_d )) && set -x # do not turn on for refresh

  if (( refresh_is_h )); then
    print "  ${yellow_cor}refresh${reset_cor} : to source \$HOME/.zshrc"
    return 0;
  fi

  zsh
}

function upgrade() {
  if command -v omz &>/dev/null; then
    omz update
  fi

  if command -v oh-my-posh &>/dev/null; then
    oh-my-posh upgrade
  fi

  update_ -f
}

function del() {
  eval "$(parse_flags_ "del_" "as" "$@")"
  (( del_is_d )) && set -x

  if (( del_is_h )); then
    print "  ${yellow_cor}del${reset_cor} : to delete in current directory"
    print "  ${yellow_cor}del <glob>${reset_cor} : to delete files (or folders)"
    print "  ${yellow_cor}del -a${reset_cor} : to include hidden files"
    print "  ${yellow_cor}del -s${reset_cor} : to skip confirmation"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    local files;
    if (( del_is_a )); then
      files=(*(DN)) # include dotfiles, but not . and ..
    else
      files=(*)
    fi
    if (( ${#files[@]} )); then
      local selected_files=("${(@f)$(choose_multiple_ 1 "choose what to delete" 20 "${files[@]}")}")
      if [[ -z "$selected_files" ]]; then
        return 1;
      fi

      # delete_pump_workings_ "$pump_working_branch" "$_pro" "${selected_files[@]}"
      local file=""
      for file in "${selected_files[@]}"; do
        if (( ! del_is_s )) && [[ ".DS_Store" != "$file" ]]; then
          if [[ -d "$file" && -n "$(ls -A "$file")" ]] || [[ ! -d "$file" ]]; then
            confirm_from_ "delete "$'\e[94m'$file$'\e[0m'" ?"
            local RET=$?
            if (( RET == 130 )); then
              return 130;
            fi
            if (( RET == 1 )); then
              continue;
            fi
          fi
        fi

        if command -v gum &>/dev/null; then
          gum spin --title="deleting... $file" -- rm -rf "$file"
        else
          print "deleting... $file"
          rm -rf "$file"
        fi
        if (( $? == 0 )); then
          print "${magenta_cor} deleted${blue_cor} $file ${reset_cor}"
        fi
      done
      #ls
    # else
    #   print " no files"
    fi
    return 0;
  fi

  setopt dot_glob null_glob
  # Capture all args (quoted or not) as a single pattern
  local pattern="$*"
  # Expand the pattern — if it's a glob, this expands to matches
  local files=(${(z)~pattern})

  # print "1 ${files[1]}"
  # print "pattern $pattern"
  # print "qty ${#files[@]}"

  local _count=0
  local is_all=$del_is_s
  local dont_ask=$del_is_s

  # Check if it's a glob pattern with multiple or changed matches
  if [[ ${#files[@]} -gt 1 || "$pattern" != "${files[1]}" ]] || [[ ${#files[@]} -eq 1 && "$pattern" == "${files[1]}" ]]; then
    local f=""
    for f in $files; do
      f="$(realpath "$f" 2>/dev/null)"
      if (( $? != 0 )) || [[ ! -e "$f" ]]; then
        print " not a file or folder: $f" >&2
        continue;
      fi

      local file_type=""
      if [[ -d "$f" ]]; then
        file_type=" folder"
      elif [[ -f "$f" ]]; then
        file_type=" file"
      fi

      if (( ! del_is_s && _count < 3 )) && [[ ".DS_Store" != "$f" ]]; then
        if [[ -d "$f" && -n "$(ls -A "$f")" ]] || [[ ! -d "$f" ]]; then
          confirm_from_ "delete${file_type}: "$'\e[94m'$f$'\e[0m'" ?"
          local RET=$?
          if (( RET == 130 )); then
            break;
          elif (( RET == 1 )); then
            continue;
          fi
        fi
      else
        if (( is_all == 0 && dont_ask == 0 )); then
          maxlen=90
          split_pattern=""

          while [[ -n $pattern ]]; do
            line="${pattern[1,$maxlen]}"
            split_pattern+=""$'\e[94m'$line$'\n\e[0m'""
            pattern="${pattern[$((maxlen + 1)),-1]}"
          done
          split_pattern="${split_pattern%""$'\n\e[0m'""}"
          confirm_from_ "delete all: $split_pattern"$'\e[0m'" ?"
          local RET=$?
          if (( RET == 130 )); then
            break;
          elif (( RET == 1 )); then
            dont_ask=1
          else
            is_all=1
          fi
        fi

        if (( is_all == 0 )); then
          if [[ -d "$f" && -n "$(ls -A "$f")" ]] || [[ ! -d "$f" ]]; then
            confirm_from_ "delete${file_type}: "$'\e[94m'$f$'\e[0m'" ?"
            RET=$?
            if (( RET == 130 )); then
              break;
            elif (( RET == 1 )); then
              continue;
            fi
          fi
        fi
      fi

      _count=$(( _count + 1 ))

      # if [[ -d "$f" && -n "$pump_working_branch" && -n "$_pro" ]]; then
      #   delete_pump_working_ $(basename "$f") "$pump_working_branch" "$_pro"
      # fi
      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $f" -- rm -rf "$f"
      else
        print "deleting... $f"
        rm -rf "$f"
      fi
      if (( $? == 0 )); then
        print "${magenta_cor} deleted${blue_cor} $f ${reset_cor}"
      fi

    done

    unsetopt dot_glob null_glob
    return 0;
  fi
  
  unsetopt dot_glob null_glob
}

# muti-task functions =========================================================
function refix() {
  eval "$(parse_flags_ "refix_" "q" "$@")"
  (( refix_is_d )) && set -x

  if (( refix_is_h )); then
    print "  ${yellow_cor}refix${reset_cor} : to reset last commit then run fix lint and format then re-push"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi
  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  last_commit_msg=$(git --no-pager log -1 --pretty=format:'%s' | xargs -0)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " last commit is a merge commit, won't do, create a new commit instead" >&2 
    return 1;
  fi
  
  if ! git reset --soft HEAD~1 1>/dev/null; then return 1; fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="refixing \"$last_commit_msg\"..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  $CURRENT_PUMP_PACKAGE_MANAGER run format &>/dev/null
  $CURRENT_PUMP_PACKAGE_MANAGER run lint &>/dev/null
  $CURRENT_PUMP_PACKAGE_MANAGER run format &>/dev/null

  print "   refixing \"$last_commit_msg\"..."

  echo "done" > "$pipe_name" &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  setopt notify
  setopt monitor

  git add .
  
  if ! git commit --message="$last_commit_msg" "$@"; then return 1; fi

  if [[ -n "$CURRENT_PUMP_PUSH_ON_REFIX" && $CURRENT_PUMP_PUSH_ON_REFIX -eq 0 ]]; then
    return 0;
  fi

  if [[ -z "$CURRENT_PUMP_PUSH_ON_REFIX" ]]; then
    if confirm_from_ "fix done, push now?"; then
      if confirm_from_ "save this preference and don't ask again?"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
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
  eval "$(parse_flags_ "covc_" "" "$@")"
  (( covc_is_d )) && set -x

  if (( covc_is_h )); then
    print "  ${yellow_cor}covc <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " covc requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi
  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if [[ -z "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    print " project is not set, use ${yellow_cor}pro${reset_cor} to set project" >&2
    return 1;
  fi

  local i=0
  for i in {1..9}; do
    if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$CURRENT_PUMP_PROJECT_SHORT_NAME" "${PUMP_PROJECT_REPO[$i]}"; then
        return 1;
      fi

      if ! check_proj_repo_ -s $i "$CURRENT_PUMP_PROJECT_REPO" "$CURRENT_PUMP_PROJECT_FOLDER" "$CURRENT_PUMP_PROJECT_SHORT_NAME"; then
        return 1;
      fi
      break;
    fi
  done

  if [[ -z "$CURRENT_PUMP_COV" || -z "$CURRENT_PUMP_SETUP" ]]; then
    print " CURRENT_PUMP_COV or CURRENT_PUMP_SETUP is missing for ${blue_cor}${CURRENT_PUMP_PROJECT_SHORT_NAME}${reset_cor} - edit your pump.zshenv then run ${yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch="$1"

  if [[ -z "$branch" ]]; then
    covc -h
    return 0;
  fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ "$branch" == "$my_branch" ]]; then
    print " trying to compare with the same branch" >&2
    return 1;
  fi

  branch_status_ "$branch" 1>/dev/null

  if (( $CURRENT_PUMP_PROJECT_SINGLE_MODE )); then
    cov_folder=".$CURRENT_PUMP_PROJECT_FOLDER-coverage"
  else
    cov_folder="$CURRENT_PUMP_PROJECT_FOLDER/.coverage"
  fi

  local RET=1

  if is_git_repo_ "$cov_folder" &>/dev/null; then
    pushd "$cov_folder" &>/dev/null

    reseta --quiet &>/dev/null
    git switch "$branch" --quiet &>/dev/null
    RET=$?
  else
    rm -rf "$cov_folder" &>/dev/null
    
    if gum spin --title="running test coverage on $branch..." -- git clone $CURRENT_PUMP_PROJECT_REPO "$cov_folder" --quiet; then
      pushd "$cov_folder" &>/dev/null

      if [[ -n "$_clone" ]]; then
        eval "$_clone" &>/dev/null;
      fi

      git switch "$branch" --quiet &>/dev/null
      RET=$?
    else
      RET=1
    fi
  fi

  if (( RET == 0 )); then
    pull --quiet
    RET=$?
  fi

  if (( RET != 0 )); then
    print " did not match any branch known to git: $branch" >&2

    return 1;
  fi

  unsetopt monitor
  unsetopt notify

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage on $branch..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$CURRENT_PUMP_SETUP" &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  if ! eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
  fi

  echo "   running test coverage on $branch..."

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
    print " did not match any branch known to git: $branch" >&2
    return 1;
  fi

  pipe_name=$(mktemp -u)
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage on $my_branch..." -- sh -c "read < $pipe_name" &
  spin_pid=$!

  eval "$CURRENT_PUMP_SETUP" &>/dev/null

  if ! eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$CURRENT_PUMP_COV" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
  fi

  echo "   running test coverage on $my_branch..."

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
  display_line_ "coverage" "${gray_cor}" 67
  display_line_ "${1:0:22}" "${gray_cor}" 32 "${my_branch:0:22}" 32
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
  eval "$(parse_flags_ "test_" "" "$@")"
  (( test_is_d )) && set -x

  if (( test_is_h )); then
    print "  ${yellow_cor}test${reset_cor} : to run PUMP_TEST"
    return 0;
  fi

  trap 'print ""; return 130' INT

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  (eval "$CURRENT_PUMP_TEST" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print "\033[32m✅ test passed on first run\033[0m"
    return 0
  fi

  (eval "$CURRENT_PUMP_TEST" $@)
  RET=$?

  if (( RET == 0 )); then
    print "\033[32m✅ test passed on second run\033[0m"
    return 0;
  fi
    
  print "\033[31m❌ test failed\033[0m"
  return 1
  
  trap - INT
}

function cov() {
  eval "$(parse_flags_ "cov_" "" "$@")"
  (( cov_is_d )) && set -x

  if (( cov_is_h )); then
    print "  ${yellow_cor}cov${reset_cor} : to run PUMP_COV"
    print "  ${yellow_cor}cov <branch>${reset_cor} : to compare test coverage with another branch of the same project"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  if [[ -n "$1" && $1 != -* ]]; then
    covc $@
    return $?;
  fi

  trap 'print ""; return 130' INT

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  (eval "$CURRENT_PUMP_COV" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print "\033[32m✅ test coverage passed on first run\033[0m"
    return 0
  fi

  (eval "$CURRENT_PUMP_COV" $@)
  RET=$?

  if (( RET == 0 )); then
    print "\033[32m✅ test coverage passed on second run\033[0m"
    
    if [[ -n "$CURRENT_PUMP_OPEN_COV" ]]; then
      eval "$CURRENT_PUMP_OPEN_COV"
    fi

    return 0;
  fi
    
  print "\033[31m❌ test coverage failed\033[0m"
  return 1
  
  trap - INT
}

function testw() {
  eval "$(parse_flags_ "testw_" "" "$@")"
  (( testw_is_d )) && set -x

  if (( testw_is_h )); then
    print "  ${yellow_cor}testw${reset_cor} : to run PUMP_TEST_WATCH"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  eval "$CURRENT_PUMP_TEST_WATCH" $@
}

function e2e() {
  eval "$(parse_flags_ "e2e_" "" "$@")"
  (( e2e_is_d )) && set -x

  if (( e2e_is_h )); then
    print "  ${yellow_cor}e2e${reset_cor} : to run PUMP_E2E"
    print "  ${yellow_cor}e2e <e2e_project>${reset_cor} : to run PUMP_E2E --project <e2e_project>"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2E" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2E" $@
  fi
}

function e2eui() {
  eval "$(parse_flags_ "e2eui_" "" "$@")"
  (( e2eui_is_d )) && set -x

  if (( e2eui_is_h )); then
    print "  ${yellow_cor}e2eui${reset_cor} : to run PUMP_E2EUI"
    print "  ${yellow_cor}e2eui ${solid_yellow_cor}<project>${reset_cor} : to run PUMP_E2EUI --project"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2EUI" --project="$1" ${@:2}
  else
    eval "$CURRENT_PUMP_E2EUI" $@
  fi
}

# github functions =========================================================
function add() {
  eval "$(parse_flags_ "add_" "" "$@")"
  (( add_is_d )) && set -x

  if (( add_is_h )); then
    print "  ${yellow_cor}add${reset_cor} : to add all files to index"
    print "  ${yellow_cor}add <glob>${reset_cor} : to add files to index"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if [[ -n "$1" && $1 != -*  ]]; then
    git add "$1" ${@:2}
  else
    git add . $@
  fi
}
  
local pr_commit_msgs=()
local pr_title=""

function read_commit_() {
  local line="$1"
  local my_branch="$2"
  local default_branch="$3"
  local remote_origin="$4"

  local commit_hash="$(echo "$line" | cut -d'|' -f1 | xargs)"
  local commit_message="$(echo "$line" | cut -d'|' -f2- | xargs)"

  # check if the commit belongs to the current branch
  if ! git branch --contains "$commit_hash" | grep -q "\b${my_branch}\b"; then
    break;
  fi

  # add the commit hash and message to the list
  pr_commit_msgs+=("- $commit_hash - $commit_message")

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
    pr_title="$(echo "$pr_title" | xargs)"
  fi

  local head_commit_hash=$(git rev-parse "${remote_origin}/${default_branch}")

  # stop if the commit is the origin/HEAD commit
  if [[ "$commit_hash" == "$head_commit_hash" ]]; then
    break;
  fi
}

function read_commits_() {
  local my_branch="$1"
  local default_branch="$2"
  local remote_origin="$3"
  local remote_branch="$4"

  if [[ -n "$remote_branch" ]]; then
    git --no-pager log --pretty=format:'%H | %s' \
      "${remote_origin}/${default_branch}..${remote_origin}/${my_branch}" | xargs -0 | while IFS= read -r line; do
      read_commit_ "$line" "$my_branch" "$default_branch" "$remote_origin"
    done
  else
    git --no-pager log --no-merges --pretty=format:'%H | %s' \
      $(git merge-base HEAD "${default_branch}")..HEAD | xargs -0 | while IFS= read -r line; do
      read_commit_ "$line" "$my_branch" "$default_branch" "$remote_origin"
    done
  fi
}

function pr() {
  eval "$(parse_flags_ "pr_" "tl" "$@")"
  (( pr_is_d )) && set -x

  if (( pr_is_h )); then
    print "  ${yellow_cor}pr${reset_cor} : to create a pull request"
    print "  ${yellow_cor}pr -l${reset_cor} : to create a pull request and select labels if any"
    print "  ${yellow_cor}pr -t${reset_cor} : to create a pull request only if tests pass"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " pr requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -n "$git_status" ]]; then
    print " uncommitted changes detected, cannot create pull request" >&2;
    return 1;
  fi

  local my_branch="$(git branch --show-current)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot create pull request" >&2
    return 1;
  fi

  fetch --quiet

  local default_branch="$(git config --get init.defaultBranch)"
  local remote_origin="$(get_remote_origin_ "$my_branch")"
  local remote_branch="$(git ls-remote --heads "$remote_origin" "$my_branch" | awk '{print $2}')"

  pr_commit_msgs=()
  pr_title=""

  read_commits_ "$my_branch" "$default_branch" "$remote_origin" "$remote_branch"

  if [[ -z "$pr_commit_msgs" || -z "$pr_title" ]]; then
    print " no commits found, cannot create pull request" >&2
    return 1;
  fi

  local pr_body=""

  for commit in "${pr_commit_msgs[@]}"; do
    pr_body+="${commit}\n"
  done

  if [[ -n "$CURRENT_PUMP_PR_REPLACE" && -f "$CURRENT_PUMP_PR_TEMPLATE" ]]; then
    local pr_template="$(cat $CURRENT_PUMP_PR_TEMPLATE)"

    if (( CURRENT_PUMP_PR_APPEND )); then
      # Append commit msgs right after CURRENT_PUMP_PR_REPLACE in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/(\Q$CURRENT_PUMP_PR_REPLACE\E)/\1\n\n$pr_body\n/")
    else
      # Replace CURRENT_PUMP_PR_REPLACE with commit msgs in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/\Q$CURRENT_PUMP_PR_REPLACE\E/$pr_body/g")
    fi
  fi

  if [[ -z "$CURRENT_PUMP_PR_RUN_TEST" ]]; then
    if confirm_from_ "run tests before pull request?"; then
      if confirm_from_ "save this preference and don't ask again?"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_PR_RUN_TEST" 1
            break;
          fi
        done
        print ""
      fi
      test || return 1;
    fi
  elif (( CURRENT_PUMP_PR_RUN_TEST || pr_is_t )); then
    test || return 1;
  fi

  ## debugging purposes
  # print " pr_title:$pr_title"
  # print ""
  # print "$pr_body"
  # return 0;

  push || return 1;

  local my_branch="$(git branch --show-current)"

  if (( pr_is_l )); then
    local proj_repo=""

    local i=0
    for i in {1..9}; do
      if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if check_proj_repo_ -s $i "${PUMP_PROJECT_REPO[$i]}" "${PUMP_PROJECT_FOLDER[$i]}" "$CURRENT_PUMP_PROJECT_SHORT_NAME"; then
          proj_repo="${PUMP_PROJECT_REPO[$i]}"
        fi
        break;
      fi
    done

    if [[ -n "$proj_repo" ]]; then
      local labels=("${(@f)$(gh label list --repo "$proj_repo" --limit 25 | awk '{print $1}')}")
      
      if [[ -n "$labels" ]]; then
        local choose_labels=$(choose_multiple_ 0 "choose labels" 20 "none ${labels[@]}")

        if [[ "$choose_labels" == "none" ]]; then
          gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
        elif [[ -n "$choose_labels" ]]; then
          local choose_labels_comma="${(j:,:)${(f)choose_labels}}"
          gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$choose_labels_comma"
        fi
      fi
      return 0;
    fi
  fi

  gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
}

function run() {
  eval "$(parse_flags_ "run_" "" "$@")"
  (( run_is_d )) && set -x

  if (( run_is_h )); then
    print "  ${yellow_cor}run${reset_cor} : to run dev in current folder"
    print "  --"
    print "  ${yellow_cor}run dev${reset_cor} : to run dev in current folder"
    print "  ${yellow_cor}run stage${reset_cor} : to run stage in current folder"
    print "  ${yellow_cor}run prod${reset_cor} : to run prod in current folder"
    print "  --"
    if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      print "  ${yellow_cor}run <folder>${reset_cor} : to run a folder on dev environment for $CURRENT_PUMP_PROJECT_SHORT_NAME"
      print "  ${yellow_cor}run${solid_yellow_cor} [<folder>] [<env>]${reset_cor} : to run a folder on environment for $CURRENT_PUMP_PROJECT_SHORT_NAME"
      print "  --"
    fi
    print "  ${yellow_cor}run <pro>${solid_yellow_cor} [<folder>] [<env>]${reset_cor} : to run a folder on environment for a project"
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
    local i=$(get_proj_index_ $1)
    if [[ -n $i ]]; then
      proj_arg="${1:-$CURRENT_PUMP_PROJECT_SHORT_NAME}"
      if [[ "$2" == "dev" || "$2" == "stage" || "$2" == "prod" ]]; then
        local single_mode=$PUMP_PROJECT_SINGLE_MODE[$i]

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
    if is_project_ $1; then
      proj_arg="$1"
    elif [[ "$1" == "dev" || "$1" == "stage" || "$1" == "prod" ]]; then
      _env="$1"
    else
      folder_arg="$1"
    fi
  fi

  # Validate environment
  if [[ "$_env" != "dev" && "$_env" != "stage" && "$_env" != "prod" ]]; then
    print " env is incorrect, valid options: dev, stage or prod" >&2
    print " ${yellow_cor} run -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local proj_folder=""
  local _run="$CURRENT_PUMP_RUN"
  local found=0

  if [[ "$_env" == "stage" ]]; then
    _run="$CURRENT_PUMP_RUN_STAGE"
  elif [[ "$_env" == "prod" ]]; then
    _run="$CURRENT_PUMP_RUN_PROD"
  fi

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        found=$i

        if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "${PUMP_PROJECT_REPO[$i]}"; then
          return 1;
        fi
        proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

        _run="${PUMP_RUN[$i]}"

        if [[ "$_env" == "stage" ]]; then
          _run="${PUMP_RUN_STAGE[$i]}"
        elif [[ "$_env" == "prod" ]]; then
          _run="${PUMP_RUN_PROD[$i]}"
        fi
        break;
      fi
    done
  else
    proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
  fi

  if [[ -z "$_run" ]]; then
    print " missing PUMP_RUN_$found" >&2
    print " edit your pump.zshenv config, refresh then try again" >&2
    return 1;
  fi

  local folder_to_run=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    if ! is_proj_folder_ "${proj_folder}/${folder_arg}" &>/dev/null; then return 2; fi

    folder_to_run="${proj_folder}/${folder_arg}"
  elif [[ -n "$proj_folder" ]]; then
    if is_proj_folder_ "$proj_folder" &>/dev/null; then
      folder_to_run="$proj_folder"
    else
      local dirs=($(get_folders_ "$proj_folder"))
      if (( ${#dirs[@]} )); then
        folder_to_run=($(choose_one_ 1 "choose folder to run" 20 "${dirs[@]}"))
        if [[ -z "$folder_to_run" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    if ! is_proj_folder_ "$folder_arg" &>/dev/null; then return 2; fi

    folder_to_run="$folder_arg"
  else
    if ! is_proj_folder_ "$(pwd)" &>/dev/null; then return 2; fi

    folder_to_run="."
  fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "_env=$_env"
  # print "folder_to_run=$folder_to_run"
  # print " --------"

  pushd "$folder_to_run" &>/dev/null

  print " run $_env on ${gray_cor}$(shorten_path_ "$folder_to_run") ${reset_cor}:${pink_cor} $_run ${reset_cor}"
  
  if ! eval "$_run"; then
    print " failed to run PUMP_RUN_${found}" >&2
  fi
}

function setup() {
  eval "$(parse_flags_ "setup_" "" "$@")"
  (( setup_is_d )) && set -x

  if (( setup_is_h )); then
      print "  ${yellow_cor}setup${reset_cor} : to setup current folder"
      if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
        print "  ${yellow_cor}setup <folder>${reset_cor} : to setup a folder for $CURRENT_PUMP_PROJECT_SHORT_NAME"
      fi
      print "  --"
    print "  ${yellow_cor}setup <pro>${solid_yellow_cor} [<folder>]${reset_cor} : to setup a folder for a project"
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
  fi

  local proj_folder="";
  local _setup=${CURRENT_PUMP_SETUP:-$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}
  local found=0

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        found=$i

        if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "${PUMP_PROJECT_REPO[$i]}"; then
          return 1;
        fi
        proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

        _setup="${PUMP_SETUP[$i]:-${PUMP_PACKAGE_MANAGER[$i]} $([[ ${PUMP_PACKAGE_MANAGER[$i]} == "yarn" ]] && echo "" || echo "run ")setup}"
        break;
      fi
    done

    if [[ -z "$proj_folder" ]]; then
      print " not a valid project: $proj_arg" >&2
      print " ${yellow_cor} setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$_setup" ]]; then
    print " missing PUMP_SETUP_$found" >&2
    print " edit your pump.zshenv config, refresh then try again" >&2
    return 1;
  fi

  local folder_to_setup=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    if ! is_proj_folder_ "$proj_folder/$folder_arg" &>/dev/null; then return 2; fi

    folder_to_setup="$proj_folder/$folder_arg"
  elif [[ -n "$proj_folder" ]]; then
    if is_proj_folder_ "$proj_folder" &>/dev/null; then
      folder_to_setup="$proj_folder"
    else
      local dirs=($(get_folders_ "$proj_folder"))
      if (( ${#dirs[@]} )); then
        folder_to_setup=($(choose_one_ 1 "choose folder to setup" 20 "${dirs[@]}"))
        if [[ -z "$folder_to_setup" ]]; then
          return 0;
        fi
      fi
    fi
  elif [[ -n "$folder_arg" ]]; then
    if ! is_proj_folder_ "$folder_arg" &>/dev/null; then return 2; fi

    folder_to_setup="$folder_arg"
  else
    if ! is_proj_folder_ "$(pwd)" &>/dev/null; then return 2; fi

    folder_to_setup="."
  fi

  # debugging
  # print "proj_arg=$proj_arg"
  # print "folder_arg=$folder_arg"
  # print "folder_to_setup=$folder_to_setup"
  # print " --------"

  pushd "$folder_to_setup" &>/dev/null

  print " setup on ${gray_cor}$(shorten_path_ "$(pwd)") ${reset_cor}:${pink_cor} $_setup ${reset_cor}"

  if ! eval "$_setup"; then
    print " failed to run PUMP_SETUP_${found}" >&2
  fi
}

function revs() {
  eval "$(parse_flags_ "revs_" "" "$@")"
  (( revs_is_d )) && set -x

  if (( revs_is_h )); then
    if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      print "  ${yellow_cor}revs${reset_cor} : to list reviews from $CURRENT_PUMP_PROJECT_SHORT_NAME"
    fi
    print "  ${yellow_cor}revs <pro>${reset_cor} : to list reviews from project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " revs requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi
  
  local proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"

  if [[ -n "$1" ]]; then
    local valid_project=0
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="${1:-$CURRENT_PUMP_PROJECT_SHORT_NAME}"
        valid_project=1
        break;
      fi
    done

    if (( valid_project == 0 )); then
      print " not a valid project: $1" >&2
      print " ${yellow_cor} pro${reset_cor} to see options" >&2
      return 1;
    fi
  fi

  local proj_folder=""
  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "${PUMP_PROJECT_REPO[$i]}"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"
      break;
    fi
  done

  if [[ -z $proj_folder ]]; then
    print " not a valid project: $proj_arg" >&2
    print " ${yellow_cor} revs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local _pwd="$(pwd)";
  local revs_folder="$proj_folder/revs"

  if [[ -d "$revs_folder" ]]; then
    cd "$revs_folder"
  else
    revs_folder=".$proj_folder-revs"
    if [[ -d "$revs_folder" ]]; then
      cd "$revs_folder"
    else
      print " no revs for $proj_folder" >&2
      print " ${yellow_cor} rev${reset_cor} to open a review" >&2
      return 1; 
    fi
  fi

  local rev_choices=$(ls -d rev* | xargs -0 | sort -fu)

  cd "$_pwd"

  if [[ -z "$rev_choices" ]]; then
    print " no revs for $proj_folder" >&2
    print " ${yellow_cor} rev${reset_cor} to open a review" >&2
    return 1;
  fi

  local choice=$(echo "$rev_choices" | gum choose --limit=1 --header " choose review to open:")

  if [[ -n "$choice" ]]; then
    rev "$proj_arg" "${choice//rev./}"
  fi
}

function rev() {
  eval "$(parse_flags_ "rev_" "eb" "$@")"
  (( rev_is_d )) && set -x

  if (( rev_is_h )); then
    print "  ${yellow_cor}rev${reset_cor} : open review by pull requests"
    print "  ${yellow_cor}rev -b${reset_cor} : open review by branches"
    print "  ${yellow_cor}rev -e <branch>${reset_cor} : open review by an exact branch"
    print "  ${yellow_cor}rev <pro>${solid_yellow_cor} [<branch>]${reset_cor} : to open a review for a project"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " rev requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
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

  local proj_repo=""
  local proj_folder=""
  local _setup=""
  local _clone=""
  local code_editor="$CURRENT_PUMP_PROJECT_REPO"
  local single_mode=""

  local found=0
  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      found=1

      if ! check_proj_repo_ -s $i "${PUMP_PROJECT_REPO[$i]}" "$proj_folder" "$proj_arg"; then
        return 1;
      fi
      proj_repo="${PUMP_PROJECT_REPO[$i]}"

      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "$proj_repo"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      _setup="${PUMP_SETUP[$i]}"
      _clone="${PUMP_CLONE[$i]}"
      code_editor="${PUMP_CODE_EDITOR[$i]}"
      single_mode=$PUMP_PROJECT_SINGLE_MODE[$i]
      break;
    fi
  done

  if (( found == 0 )); then
    print " not a valid project or no project is set" >&2
    print " ${yellow_cor} clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -z "$proj_repo" ]]; then
    print " missing repository uri for: $proj_arg" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    print " missing project folder for: $proj_arg" >&2
    return 1;
  fi

  local _pwd="$(pwd)";
  local branch="";

  #if ! open_proj_for_git_ "$proj_folder"; then return 2; fi

  if (( rev_is_e )); then
    branch="$branch_arg"
  elif (( rev_is_b )); then
    fetch --quiet
    branch="$(select_branch_ 1 -r "$branch_arg")"
  else
    local pr=("${(@s:|:)$(select_pr_ "$branch_arg")}")
    branch="${pr[2]}"
  fi

  if [[ -z "$branch" ]]; then
    print " branch is required" >&2
    cd "$_pwd"

    return 1;
  fi

  local branch_folder="${branch//\\/-}";
  branch_folder="${branch_folder//\//-}";

  local revs_folder=""
  if (( single_mode )); then
    revs_folder=".$proj_folder-revs"
  else
    revs_folder="$proj_folder/revs"
  fi

  local full_rev_folder="$revs_folder/rev.$branch_folder"

  local is_open_editor=1

  if [[ -d "$full_rev_folder" ]]; then
    print " opening review: ${green_cor}$(basename "$full_rev_folder")${reset_cor} and pulling latest changes..."
  else
    local remote_origin="$(get_remote_origin_ "$branch")"
    local remote_branch=$(git ls-remote --heads "$remote_origin" "$branch" | awk '{print $2}')

    if [[ -z "$remote_branch" ]]; then
      print " branch not found in $remote_origin: $branch" >&2
      print " ${yellow_cor} rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    print " creating review for pull request: ${green_cor}${pr[3]}${reset_cor}..."

    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo" -- git clone $proj_repo "$full_rev_folder"; then return 1; fi
    else
      print " cloning... $proj_repo";
      if ! git clone $proj_repo "$full_rev_folder" --quiet; then return 1; fi
    fi
  fi

  pushd "$full_rev_folder" &>/dev/null
  
  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -n "$git_status" ]]; then
    if ! confirm_from_ "uncommitted changes detected, discard all changes and pull?"; then
      return 1;
    fi
    reseta
  fi

  git checkout "$branch" --quiet
  
  local warn_msg=""
  
  if ! pull --quiet; then
    is_open_editor=0
    warn_msg="${yellow_cor} warn: could not pull latest changes, probably already merged ${reset_cor}"
  fi

  if [[ -n "$_setup" ]]; then
    print "${pink_cor} $_setup ${reset_cor}"
    if eval "$_setup"; then
      if (( is_open_editor )); then
        eval $code_editor .
      fi
    fi
  fi

  if [[ -n "$warn_msg" ]]; then
    print ""
    print "$warn_msg"
    print ""
  fi
}

function clone() {
  eval "$(parse_flags_ "clone_" "" "$@")"
  (( clone_is_d )) && set -x

  if (( clone_is_h )); then
    if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      print "  ${yellow_cor}clone <branch>${reset_cor} : to clone $CURRENT_PUMP_PROJECT_SHORT_NAME branch"
      print "  ${yellow_cor}clone $CURRENT_PUMP_PROJECT_SHORT_NAME${solid_yellow_cor} [<branch>]${reset_cor} : to clone $CURRENT_PUMP_PROJECT_SHORT_NAME branch"
    fi
      print "  ${yellow_cor}clone <pro>${solid_yellow_cor} [<branch>]${reset_cor} : to clone another project"
    return 0;
  fi

  if [[ $1 == -* ]]; then
    clone -h
    return 0;
  fi

  local proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
  local branch_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    branch_arg="$2"
  elif [[ -n "$1" ]]; then
    valid_project=0
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        valid_project=1
        break;
      fi
    done
    if [[ $valid_project -eq 0 ]]; then
      branch_arg="$1"
    fi
  else
    pro_choices=()
    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        pro_choices+=("${PUMP_PROJECT_SHORT_NAME[$i]}")
      fi
    done

    proj_arg=$(choose_one_ 1 "choose project to clone" 20 "${pro_choices[@]}")
    if [[ -z "$proj_arg" ]]; then
      return 1;
    fi
  fi

  local proj_repo=""
  local proj_folder=""
  local _clone=""
  local default_branch=""
  local print_readme=1
  local single_mode=""
  local found=0

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      found=$i

      if ! check_proj_repo_ -s $i "$PUMP_PROJECT_REPO[$i]" "$proj_folder" "$proj_arg"; then
        return 1;
      fi
      proj_repo="${PUMP_PROJECT_REPO[$i]}"

      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "$proj_repo"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      if ! save_proj_mode_ $i "$proj_folder" "${PUMP_PROJECT_SINGLE_MODE[$i]}"; then return 1; fi

      single_mode="${PUMP_PROJECT_SINGLE_MODE[$i]}"
      _clone="${PUMP_CLONE[$i]}"
      default_branch="${PUMP_DEFAULT_BRANCH[$i]}"
      print_readme="${PUMP_PRINT_README[$i]}"
      break;
    fi
  done

  if (( found == 0 )); then
    print " not a valid project or no project is set" >&2
    print " ${yellow_cor} clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -z "$proj_repo" ]]; then
    print " missing repository uri for: $proj_arg" >&2
    return 1;
  fi

  if [[ -z "$proj_folder" ]]; then
    print " missing project folder for: $proj_arg" >&2
    return 1;
  fi

  if (( single_mode )) && [[ -n "$(ls -A "$proj_folder" 2>/dev/null)" ]]; then
    print "${solid_blue_cor} $proj_arg${reset_cor} is already cloned in single mode: $proj_folder" >&2
    print "" >&2
    print " to switch to multiple mode, remove the project then add it again:" >&2
    print "  1. ${yellow_cor}pro -r ${proj_arg}${reset_cor}" >&2
    print "  2. ${yellow_cor}pro -a ${proj_arg}${reset_cor} and choose multiple mode" >&2
    return 1;
  fi

  if (( single_mode )); then
    branch_arg=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg");
    if [[ -z "$branch_arg" ]]; then
      return 0;
    fi

    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo on $branch_arg" -- git clone "$proj_repo" "$proj_folder" --quiet; then return 1; fi
      print "   cloning... $proj_repo on $branch_arg"
    else
      print "  cloning... $proj_repo on $branch_arg"
      if ! git clone --quiet "$proj_repo" "$proj_folder"; then return 1; fi
    fi

    if ! pushd "$proj_folder" &>/dev/null; then return 1; fi

    git checkout "$branch_arg" --quiet &>/dev/null

    # if (( $? == 0 )); then
    #   save_pump_working_ "$proj_arg"
    # fi

    if [[ -n "$_clone" ]]; then
      print "  ${pink_cor}$_clone ${reset_cor}"
      if ! eval "$_clone"; then
        print " failed to run PUMP_CLONE_${found}" >&2
      fi
    fi

    if [[ $print_readme -eq 1 ]]; then
      # find readme file
      local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
      if [[ -n "$readme_file" ]]; then
        if command -v glow &>/dev/null; then
          glow "$readme_file"
        else
          cat "$readme_file"
        fi
      fi
    fi

    print ""
    print "  default branch is ${bright_green_cor}$(git config --get init.defaultBranch) ${reset_cor}"

    if [[ "$proj_arg" != "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      pro $proj_arg
    fi

    return 0;
  fi
  # end of (( single_mode ))

  # multiple mode (requires passing a branch name)

  local branch_to_clone=""
  
  if [[ -z "$branch_arg" ]]; then
    local folders=($(get_folders_ "$proj_folder"))
    if [[ -z "$folders" ]]; then # first time user is cloning
      branch_arg=$(get_clone_default_branch_ "$proj_repo" "$proj_folder");
    fi

    if [[ -z "$branch_arg" ]]; then
      branch_arg=$(input_branch_name_ "type the name of the branch");
    fi

    if [[ -z "$branch_arg" ]]; then
      return 0;
    fi
  fi

  if [[ -z "$default_branch" ]]; then
    default_branch=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg");

    if [[ -z "$default_branch" ]]; then
      return 0;
    fi

    if confirm_from_ "save "$'\e[94m'$default_branch$'\e[0m'" as the default branch and don't ask again?"; then
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$found]}" ]]; then
        update_setting_ $found "PUMP_DEFAULT_BRANCH" "$default_branch"
      fi
      print ""
    fi
  fi

  local branch_to_clone_folder="${branch_arg//\\/-}"
  branch_to_clone_folder="${branch_to_clone_folder//\//-}"

  if command -v gum &>/dev/null; then
    if ! gum spin --title="cloning... $proj_repo on $branch_arg" -- git clone "$proj_repo" "${proj_folder}/${branch_to_clone_folder}" --quiet; then return 1; fi
    print "   cloning... $proj_repo on $branch_arg"
  else
    print "  cloning... $proj_repo on $branch_arg"
    if ! git clone --quiet "$proj_repo" "${proj_folder}/${branch_to_clone_folder}"; then return 1; fi
  fi

  # multiple mode

  local past_folder="$(pwd)"

  pushd "${proj_folder}/${branch_to_clone_folder}" &>/dev/null

  # if (( $? == 0 )); then
  #   save_pump_working_ "$proj_arg"
  # fi
  
  git config init.defaultBranch $default_branch

  local my_branch="$(git branch --show-current)"

  if [[ "$branch_arg" != "$my_branch" ]]; then
    # check if branch exist
    local remote_origin="$(get_remote_origin_ "$my_branch")"
    local remote_branch="$(git ls-remote --heads "$remote_origin" "$branch_arg" | awk '{print $2}')"
    local local_branch=$(git branch --list "$branch_arg" | head -n 1)

    if [[ -z "$remote_branch" && -z "$local_branch" ]]; then
      git checkout -b "$branch_arg" --quiet
    else
      git checkout "$branch_arg" --quiet
    fi
  fi

  # multiple mode

  if [[ -n "$_clone" ]]; then
    print "  ${pink_cor}$_clone ${reset_cor}"
    if ! eval "$_clone"; then
      print " failed to run PUMP_CLONE_${found}" >&2
    fi
  fi

  if [[ $print_readme -eq 1 ]]; then
    # find readme file
    local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
    if [[ -n "$readme_file" ]]; then
      if command -v glow &>/dev/null; then
        glow "$readme_file"
      else
        cat "$readme_file"
      fi
    fi
  fi

  print ""
  print "  default branch is ${bright_green_cor}$(git config --get init.defaultBranch) ${reset_cor}"

  if [[ "$proj_arg" != "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    pro "$proj_arg"
  fi
}

function abort() {
  eval "$(parse_flags_ "abort_" "" "$@")"
  (( abort_is_d )) && set -x

  if (( abort_is_h )); then
    print "  ${yellow_cor}abort${reset_cor} : to abort any in progress rebase, merge and cherry-pick"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  GIT_EDITOR=true git rebase --abort &>/dev/null
  GIT_EDITOR=true git merge --abort  &>/dev/null
  GIT_EDITOR=true git cherry-pick --abort &>/dev/null
}

function renb() {
  eval "$(parse_flags_ "renb_" "" "$@")"
  (( renb_is_d )) && set -x

  if (( renb_is_h )); then
    print "  ${yellow_cor}renb <branch>${reset_cor} : to rename a branch"
    return 0;
  fi

  local new_name="$1"

  if [[ -z "$new_name" ]]; then
    renb -h
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local current_name="$(git symbolic-ref --short HEAD 2>/dev/null)"
  local base_branch="$(git config --get "branch.${current_name}.gh-merge-base" 2>/dev/null)"

  git branch -m "$new_name" ${@:2}

  if (( $? == 0 )); then
    git config "branch.${new_name}.gh-merge-base" "$base_branch" &>/dev/null
    git config --remove-section "branch.${current_name}" &>/dev/null
  fi

}

function chp() {
  eval "$(parse_flags_ "chp_" "" "$@")"
  (( chp_is_d )) && set -x

  if (( chp_is_h )); then
    print "  ${yellow_cor}chp <commit>${reset_cor} : to cherry-pick a commit"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    chp -h
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  
  git cherry-pick "$1" ${@:2}
}

function chc() {
  eval "$(parse_flags_ "chc_" "" "$@")"
  (( chc_is_d )) && set -x

  if (( chc_is_h )); then
    print "  ${yellow_cor}chc${reset_cor} : to continue in progress cherry-pick"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  GIT_EDITOR=true git merge --continue &>/dev/null
}

function mc() {
  eval "$(parse_flags_ "mc_" "" "$@")"
  (( mc_is_d )) && set -x

  if (( mc_is_h )); then
    print "  ${yellow_cor}mc${reset_cor} : to continue in progress merge"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git add .

  GIT_EDITOR=true git merge --continue &>/dev/null
}

function rc() {
  eval "$(parse_flags_ "rc_" "" "$@")"
  (( rc_is_d )) && set -x

  if (( rc_is_h )); then
    print "  ${yellow_cor}rc${reset_cor} : to continue in progress rebase"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git add .

  GIT_EDITOR=true git rebase --continue &>/dev/null
}

function cont() {
  eval "$(parse_flags_ "cont_" "" "$@")"
  (( conti_is_d )) && set -x

  if (( conti_is_h )); then
    print "  ${yellow_cor}cont${reset_cor} : to continue any in progress rebase, merge or cherry-pick"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git add .
  local RET=$?

  if (( RET == 0 )); then
    GIT_EDITOR=true git rebase --continue &>/dev/null
    GIT_EDITOR=true git merge --continue &>/dev/null
    GIT_EDITOR=true git cherry-pick --continue &>/dev/null
  fi

  return $RET;
}

function reset1() {
  eval "$(parse_flags_ "reset1_" "" "$@")"
  (( reset1_is_d )) && set -x

  if (( reset1_is_h )); then
    print "  ${yellow_cor}reset1${reset_cor} : to reset last commit"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git --no-pager log -1 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~1
}

function reset2() {
  eval "$(parse_flags_ "reset2_" "" "$@")"
  (( reset2_is_d )) && set -x

  if (( reset2_is_h )); then
    print "  ${yellow_cor}reset2${reset_cor} : to reset 2 last commits"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git --no-pager log -2 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~2
}

function reset3() {
  eval "$(parse_flags_ "reset3_" "" "$@")"
  (( reset3_is_d )) && set -x

  if (( reset3_is_h )); then
    print "  ${yellow_cor}reset3${reset_cor} : to reset 3 last commits"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git --no-pager log -3 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~3
}

function reset4() {
  eval "$(parse_flags_ "reset4_" "" "$@")"
  (( reset4_is_d )) && set -x

  if (( reset4_is_h )); then
    print "  ${yellow_cor}reset4${reset_cor} : to reset 4 last commits"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git --no-pager log -4 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~4
}

function reset5() {
  eval "$(parse_flags_ "reset5_" "" "$@")"
  (( reset5_is_d )) && set -x

  if (( reset5_is_h )); then
    print "  ${yellow_cor}reset5${reset_cor} : to reset 5 last commits"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git --no-pager log -5 --oneline
  git log -1 --pretty=format:'%s' | pbcopy
  
  git reset --quiet --soft HEAD~5
}

function repush() {
  eval "$(parse_flags_ "repush_" "s" "$@")"
  (( repush_is_d )) && set -x

  if (( repush_is_h )); then
    print "  ${yellow_cor}repush${reset_cor} : to reset last commit without losing your changes then re-push all changes using the same message"
    print "  ${yellow_cor}repush -s${reset_cor} : only staged changes"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if (( repush_is_s )); then
    if ! recommit -s --quiet 1>/dev/null; then return 1; fi
  else
    if ! recommit --quiet 1>/dev/null; then return 1; fi
  fi
  
  pushf $@
}

function recommit() {
  eval "$(parse_flags_ "recommit_" "sq" "$@")"
  (( recommit_is_d )) && set -x

  if (( recommit_is_h )); then
    print "  ${yellow_cor}recommit${reset_cor} : to reset last commit without losing your changes then re-commit all changes using the same message"
    print "  ${yellow_cor}recommit -s${reset_cor} : only staged changes"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -z "$git_status" ]]; then
    print " nothing to do, working tree clean"
    return 0;
  fi

  local last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0 2>/dev/null)
  
  if [[ "$last_commit_msg" == Merge* ]]; then
    print " cannot recommit, last commit is a merge commit" >&2
    return 1;
  fi

  if (( recommit_is_s )); then
    if git diff --cached --quiet; then
      print " nothing to recommit, no staged changes" >&2
      print " run${yellow_cor} recommit${reset_cor} to re-commit all changes" >&2
      return 1;
    else
      if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi
    fi
  else
    if ! git reset --quiet --soft HEAD~1 1>/dev/null; then return 1; fi

    if [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
      if confirm_from_ "add all changes to commit: "$'\e[94m'$last_commit_msg$'\e[0m'" ?"; then
        git add .

        if confirm_from_ "save this preference and don't ask again?"; then
          local i=0
          for i in {1..9}; do
            if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
              update_setting_ $i "PUMP_COMMIT_ADD" 1
              break;
            fi
          done

          print ""
        fi
      fi
    elif (( CURRENT_PUMP_COMMIT_ADD )); then
      git add .
    fi
  fi

  if git commit --message="$last_commit_msg" $@; then
    if (( ! ${argv[(Ie)--quiet]} )); then
      print ""
      git --no-pager log -1 --oneline
      #git log -1 --pretty=format:'%H %s' | pbcopy
    fi
  fi
}

function fetch() {
  set +x
  eval "$(parse_flags_ "fetch_" "" "$@")"
  # (( fetch_is_d )) && set -x

  if (( fetch_is_h )); then
    print "  ${yellow_cor}fetch${reset_cor} : to fetch all branches and reachable tags"
    print "  ${yellow_cor}fetch <branch>${reset_cor} : to fetch a branch"
    print "  ${yellow_cor}fetch -t${reset_cor} : to fetch all tags along with branches"
    print "  ${yellow_cor}fetch -to${reset_cor} : to fetch all tags only"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local RET=0

  if (( fetch_is_t )); then 
    git fetch --all --tags --prune-tags --force
    RET=$?
    if (( fetch_is_o )); then
      return $RET;
    fi
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    local remote_origin="$(get_remote_origin_ "$1")"

    git fetch "$remote_origin" "$1" --prune ${@:2}
    RET=$?
  else
    git fetch --all --prune $@
    RET=$?
  fi

  local current_branches=$(git branch --format '%(refname:short)')

  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    if ! echo "$current_branches" | grep -q "^${branch_name}$"; then
      git config --remove-section "branch.${branch_name}" &>/dev/null
    fi
  done

  return $RET;
}

function gconf() {
  print "${solid_yellow_cor} Username:${reset_cor} $(git config --get user.name)"
  print "${solid_yellow_cor} Email:${reset_cor} $(git config --get user.email)"
  print "${solid_yellow_cor} Default branch:${reset_cor} $(git config --get init.defaultBranch)"
}

function glog() {
  eval "$(parse_flags_ "glog_" "" "$@")"
  (( glog_is_d )) && set -x

  if (( glog_is_h )); then
    print "  ${yellow_cor}glog${reset_cor} : to log all commits"
    print "  ${yellow_cor}glog ${solid_yellow_cor}-n${reset_cor} : to log n commits"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  print ""
  git --no-pager log main HEAD --oneline --graph --date=relative $@
  local RET=$?

  print ""
  cd "$_pwd"

  return $RET;
}

function push() {
  eval "$(parse_flags_ "push_" "" "$@")"
  (( push_is_d )) && set -x

  if (( push_is_h )); then
    print "  ${yellow_cor}push${reset_cor} : to push with no-verify"
    print "  ${yellow_cor}push -f${reset_cor} : to force push with lease no-verify"
    print "  ${yellow_cor}push -t${reset_cor} : to push tags"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  fetch --quiet

  if (( push_is_t && push_is_f )); then
    git push --no-verify --tags --force $@
    return $?;
  fi

  if (( push_is_t )); then
    git push --no-verify --tags $@
    return $?;
  fi
  
  if (( push_is_f )); then
    pushf $@
    return $?;
  fi

  local my_branch="$(git branch --show-current)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot push" >&2
    return 1;
  fi

  local remote_origin="$(get_remote_origin_ "$my_branch")"
  local remote_branch="$(git ls-remote --heads "$remote_origin" "$my_branch" | awk '{print $2}')"

  local RET=0

  if [[ -z "$remote_branch" ]]; then
    git push --no-verify --set-upstream "$remote_origin" "$my_branch" $@
    RET=$?
  else
    git push --no-verify $@
    RET=$?
  fi

  if (( RET != 0 && quiet == 0 )); then
    if confirm_from_ "failed, try push force with lease?"; then
      pushf $@
      return $?;
    fi
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    if [[ -n "$my_branch" ]]; then
      print ""
      git --no-pager log "${remote_origin}/${my_branch}@{1}..${remote_origin}/${my_branch}" --oneline
      # git log -1 --pretty=format:'%H %s' | pbcopy
    fi
  fi

  return $RET;
}

function pushf() {
  eval "$(parse_flags_ "pushf_" "" "$@")"
  (( pushf_is_d )) && set -x

  if (( pushf_is_h )); then
    print "  ${yellow_cor}pushf${reset_cor} : to force push with lease no-verify"
    print "  ${yellow_cor}pushf -f${reset_cor} : to regular push with force"
    print "  ${yellow_cor}pushf -t${reset_cor} : to push tags"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local RET=0

  if (( pushf_is_t && pushf_is_f )); then
    git push --no-verify --tags --force $@
    RET=$?
  fi

  if (( pushf_is_t )); then
    git push --no-verify --tags $@
    RET=$?
  fi

  local my_branch="$(git branch --show-current)"
  local remote_origin="$(get_remote_origin_ "$my_branch")"

  if [[ -z "$my_branch" || -z "$remote_origin" ]]; then
    print " branch is detached or not tracking a remote branch, cannot force push" >&2
    return 1;
  fi

  if (( pushf_is_f )); then
    git push --no-verify --force "${remote_origin}" "$my_branch" $@
    RET=$?
  else
    git push --no-verify --force-with-lease "${remote_origin}" "$my_branch" $@
    RET=$?
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    if [[ -n "$my_branch" ]]; then
      print ""
      git --no-pager log "${remote_origin}/${my_branch}@{1}..${remote_origin}/${my_branch}" --oneline
      # git log -1 --pretty=format:'%H %s' | pbcopy
    fi
  fi

  return $RET;
}

function dtag() {
  eval "$(parse_flags_ "dtag_" "" "$@")"
  (( dtag_is_d )) && set -x

  if (( dtag_is_h )); then
    print "  ${yellow_cor}dtag ${solid_yellow_cor}[<name>]${reset_cor} : to delete a tag"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  
  prune

  local remote_origin="$(get_remote_origin_)"

  if [[ -z "$1" ]]; then
    # list all tags suing tags command then use choose_multiple_ to select tags, then delete all selected tags
    local tags=$(tags 2>/dev/null)
    if [[ -z "$tags" ]]; then
      print " no tags found to delete" >&2
      cd "$_pwd"
      return 0;
    fi
    local selected_tags=($(choose_multiple_ 0 "select tags to delete" 20 $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then
      cd "$_pwd"
      return 1;
    fi
    for tag in $selected_tags; do
      git tag "$remote_origin" --delete "$tag" 2>/dev/null
      git push "$remote_origin" --delete "$tag" ${@:2} 2>/dev/null
    done
    cd "$_pwd"
    return 0;
  fi

  git tag "$remote_origin" --delete "$1" 2>/dev/null
  git push "$remote_origin" --delete "$1" 2>/dev/null

  cd "$_pwd"

  return 0; # don't care if it fails to delete, considered success
}

function pull() {
  eval "$(parse_flags_ "pull_" "" "$@")"
  (( pull_is_d )) && set -x

  if (( pull_is_h )); then
    print "  ${yellow_cor} pull ${solid_yellow_cor}[<branch>]${reset_cor} : to pull from origin branch"
    print "  ${yellow_cor} pull -t${reset_cor} : to pull all tags along with branches"
    print "  ${yellow_cor} pull -to${reset_cor} : to pull all tags only"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local remote_origin="$(get_remote_origin_)"

  local RET=0

  if (( pull_is_t )); then
    git pull "$remote_origin" --tags $@
    RET=$?
    if (( pull_is_o )); then
      return $RET;
    fi
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    git pull "$remote_origin" "$1" --rebase --autostash ${@:2}
    RET=$?
  else
    git pull "$remote_origin" --rebase --autostash $@
    RET=$?
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    print ""
    git --no-pager log -1 --oneline
    # no pbcopy for pulling
  fi

  return $RET;
}

# tagging functions ===============================================
function drelease() {
  eval "$(parse_flags_ "drelease_" "" "$@")"
  (( drelease_is_d )) && set -x

  if (( drelease_is_h )); then
    print "  ${yellow_cor}drelease ${solid_yellow_cor}[<tag>]${reset_cor} : to delete a release"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " drelease requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  local tag="$1"

  if [[ -z "$tag" ]]; then
    local tags=$(tags 2>/dev/null)
    if [[ -z "$tags" ]]; then
      print " no tags found to delete" >&2
      return 0;
    fi
    local selected_tags=($(choose_multiple_ 0 "select tags to delete" 20 $(echo "$tags" | tr '\n' ' ')))
    if [[ -z "$selected_tags" ]]; then
      return 1;
    fi

    for tag in $selected_tags; do
      if command -v gum &>/dev/null; then
        if ! gum spin --title="deleting release: $tag" -- gh release delete "$tag" --cleanup-tag -y 1>/dev/tty; then continue; fi
      else
        print " deleting release: $tag"
        if ! gh release delete "$tag" --cleanup-tag -y; then continue; fi
      fi
      print " deleted release: $tag"
    done
    return 0;
  fi

  gh release delete "$tag" --cleanup-tag -y
}

function release() {
  eval "$(parse_flags_ "release_" "mnps" "$@")"
  (( release_is_d )) && set -x

  if (( release_is_h )); then
    print "  ${yellow_cor}release ${solid_yellow_cor}[<version>]${reset_cor} : to create a new release, version format: <major>.<minor>.<patch> i.e: 1.0.0"
    print "  ${yellow_cor}release -s${reset_cor} : to skip confirmation"
    print "  --"
    print "  ${yellow_cor}release -m${reset_cor} : to create a major release"
    print "  ${yellow_cor}release -n${reset_cor} : to create a minor release"
    print "  ${yellow_cor}release -p${reset_cor} : to create a patch release"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " release requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi

  if [[ -n "$(git status --porcelain)" ]]; then
    print " uncommitted changes detected, cannot create release" >&2
    st
    return 1
  fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  # check if name is conventional
  if ! [[ "$my_branch" =~ ^(main|master|stage|staging|pro|production|release)$ || "$my_branch" == release* ]]; then
    print " warning: unconventional branch to release: $my_branch"
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
          print " not able to bump version: $release_type" >&2
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
    if ! confirm_from_ "create release: $tag ?"; then
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
  
  if gh release view "$tag" >/dev/null 2>&1; then
    if (( ! release_is_s )); then
      if ! confirm_from_ "$tag has already been released, delete and release again?"; then
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
      if ! confirm_from_ "$tag already exists, delete and release again?"; then
        return 1;
      fi
    fi
    if ! dtag "$tag" --quiet; then return 1; fi
  fi

  if ! tag "$tag"; then return 1; fi
  if ! push --quiet; then return 1; fi
  if ! push --tags --quiet; then return 1; fi

  gh release create "$tag" --title="$tag" --generate-notes
}

function tag() {
  eval "$(parse_flags_ "tag_" "" "$@")"
  (( tag_is_d )) && set -x

  if (( tag_is_h )); then
    print " release_ = ${yellow_cor}tag ${solid_yellow_cor}[<name>]${reset_cor} : to create a new tag"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi
  
  prune &>/dev/null

  local tag="$1"

  if [[ -z "$tag" ]]; then
    tag=$(get_from_pkg_json_ "version")
    if [[ -n "$tag" ]]; then
      if ! confirm_from_ "create tag: $tag ?"; then
        tag=""
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    tag=$(input_path_ "type the tag name");
  fi

  if [[ -z "$tag" ]]; then
    cd "$_pwd"
    return 1;
  fi

  git tag --annotate "$tag" --message="$tag" ${@:2}
  local RET=$?

  if (( RET == 0 )); then
    git push --no-verify --tags
    RET=$?
  fi

  cd "$_pwd"

  return $RET;
}

function tags() {
  eval "$(parse_flags_ "tags_" "" "$@")"
  (( tags_is_d )) && set -x

  if (( tags_is_h )); then
    print "  ${yellow_cor}tags${reset_cor} : to list all tags"
    print "  ${yellow_cor}tags <x>${reset_cor} : to list x number of tags"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  prune &>/dev/null

  local n="${1-100}"
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
    cd "$_pwd"
    return 1;
  fi
  
  print "$tags"
  cd "$_pwd"
}
# end of tagging functions ===============================================

function restore() {
  eval "$(parse_flags_ "restore_" "" "$@")"
  (( restore_is_d )) && set -x

  if (( restore_is_h )); then
    print "  ${yellow_cor}restore${reset_cor} : to undo edits in tracked files"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git restore --quiet .
}

function clean() {
  eval "$(parse_flags_ "clean_" "" "$@")"
  (( clean_is_d )) && set -x

  if (( clean_is_h )); then
    print "  ${yellow_cor}clean${reset_cor} : to delete all untracked files and directories and undo edits in tracked files"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  
  git clean -fd --quiet
  local RET=$?

  if (( RET == 0 )); then
    restore
    RET=$?
  fi

  return $RET;
}

function discard() {
  eval "$(parse_flags_ "discard_" "" "$@")"
  (( discard_is_d )) && set -x

  if (( discard_is_h )); then
    print "  ${yellow_cor}discard${reset_cor} : to undo everything that have not been committed"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  reseta
  local RET=$?

  if (( RET == 0 )); then
    clean
    RET=$?
  fi

  return $RET;
}

function reseta() {
  eval "$(parse_flags_ "reseta_" "" "$@")"
  (( reseta_is_d )) && set -x

  if (( reseta_is_h )); then
    print "  ${yellow_cor}reseta${reset_cor} : to erase everything and match HEAD to origin"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local my_branch="$(git branch --show-current)"
  local remote_origin="$(get_remote_origin_ "$my_branch")"
  local remote_branch="$(git ls-remote --heads "$remote_origin" "$my_branch" | awk '{print $2}')"

  local RET=0
  
  fetch --quiet

  if [[ -n "$remote_branch" ]]; then
    git reset --hard "${remote_origin}/${my_branch}" $@
    RET=$?
  else
    git reset "$remote_origin" --hard $@
    RET=$?
  fi

  if (( RET == 0 )); then
    clean
    RET=$?
  fi

  return $RET;
}

function glr() {
  eval "$(parse_flags_ "glr_" "" "$@")"
  (( glr_is_d )) && set -x

  if (( glr_is_h )); then
    print "  ${yellow_cor}gll${reset_cor} : to list remote branches"
    print "  ${yellow_cor}gll <branch>${reset_cor} : to list remote branches matching branch"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  fetch --quiet

  git branch -r --list "*$1*" --sort=authordate --format='%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=3)' | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^\ ]*\)$/\x1b[34m\x1b]8;;https:\/\/github.com\/wmgtech\/wmg2-one-app\/tree\/\1\x1b\\\1\x1b]8;;\x1b\\\x1b[0m/'
  local RET=$?
  
  cd "$_pwd"

  return $RET;
}

function gll() {
  eval "$(parse_flags_ "gll_" "" "$@")"
  (( gll_is_d )) && set -x

  if (( gll_is_h )); then
    print "  ${yellow_cor}gll${reset_cor} : to list branches"
    print "  ${yellow_cor}gll <branch>${reset_cor} : to list branches matching <branch>"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  git branch --list "*$1*" --sort=authordate --format="%(authordate:format:%m-%d-%Y) %(align:17,left)%(authorname)%(end) %(refname:strip=2)" | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'
  local RET=$?
  
  cd "$_pwd"

  return $RET;
}

function gha_() {
  local workflow="$1"

  if [[ -z "$workflow" ]]; then
    print " no workflow name provided" >&2
    print " ${yellow_cor} gha -h${reset_cor} to see usage" >&2

    return 1;
  fi

  local workflow_id="$(gh run list --workflow="${workflow}" --limit 1 --json databaseId --jq '.[0].databaseId')"

  if [[ -z "$workflow_id" ]]; then
    #print "⚠️${yellow_cor} workflow not found ${reset_cor}" >&2
    return 1;
  fi

  local workflow_status="$(gh run list --workflow="${workflow}" --limit 1 --json conclusion --jq '.[0].conclusion')"

  if [[ -z "$workflow_status" ]]; then
    print " ⏳\e[90m workflow is still running ${reset_cor}" >&2
    return 0; # this nust be zero for auto mode
  fi

  # Output status with emoji
  if [[ "$workflow_status" == "success" ]]; then
    print " ✅${green_cor} workflow passed: $workflow ${reset_cor}"
  else
    print "\a ❌${red_cor} workflow failed (status: $workflow_status) ${reset_cor}"

    local remote_origin="$(get_remote_origin_)"
    local repo="$(get_repo_name_ "$(git remote get-url "$remote_origin")")"

    if [[ -n "$repo" ]]; then
      repo="${repo%.git}"
      print "  check out${blue_cor} https://github.com/$repo/actions/runs/$workflow_id ${reset_cor}"
    fi
  fi
  
  return 0;
}

function gha() {
  eval "$(parse_flags_ "gha_" "" "$@")"
  (( gha_is_d )) && set -x

  if (( gha_is_h )); then
    print "  ${yellow_cor}gha${solid_yellow_cor} [<workflow>]${reset_cor} : to check status of workflow in current project"
    print "  ${yellow_cor}gha <pro>${solid_yellow_cor} [<workflow>]${reset_cor} : to check status of a workflow for a project"
    print "  ${yellow_cor}gha -a${reset_cor} : to run in auto mode"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " gha requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  local workflow_arg=""
  local proj_arg=""

  # Parse arguments
  if [[ -n "$2" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        break;
      fi
    done
    if [[ -n "$proj_arg" ]]; then
      workflow_arg="$2"
    fi
  elif [[ -n "$1" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$1" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        proj_arg="$1"
        break;
      fi
    done
    if [[ -z "$proj_arg" ]]; then
      workflow_arg="$1"
      proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
    fi
  else
    proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
  fi

  local proj_folder="$(pwd)"  # default is current folder
  local gha_interval=""
  local gha_workflow=""
  local found=0

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      found=$i

      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg" "${PUMP_PROJECT_REPO[$i]}"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      gha_interval="${PUMP_GHA_INTERVAL[$i]}"
      gha_workflow="${PUMP_GHA_WORKFLOW[$i]}"
      break;
    fi
  done

  local _pwd="$(pwd)";

  if [[ -n "$proj_folder" ]]; then
    if ! open_proj_for_git_ "$proj_folder"; then return 2; fi
    proj_folder="$(pwd)";
  else
    print " no project folder found" >&2
    cd "$_pwd"
    return 1;
  fi

  local ask_save=0

  if [[ -z "$workflow_arg" && -z "$gha_workflow" ]]; then
    local workflow_choices=$(gh workflow list | cut -f1)
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      cd "$_pwd"
      print " no workflows found" >&2
      return 1;
    fi
    
    local chosen_workflow=$(gh workflow list | cut -f1 | gum choose --header " choose workflow:");
    if [[ -z "$chosen_workflow" ]]; then
      cd "$_pwd"
      return 1;
    fi

    workflow_arg="$chosen_workflow"
    ask_save=1
  elif [[ -n "$workflow_arg" ]]; then
    ask_save=1
  elif [[ -n "$gha_workflow" ]]; then
    workflow_arg="$gha_workflow"
    ask_save=0    
  fi

  if [[ -z "$workflow_arg" ]]; then
    print " no workflow name provided" >&2
    print " ${yellow_cor} gha -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local RET=0

  if (( ! gha_is_a )); then
    print " checking workflow..."
    gha_ "$workflow_arg"
    RET=$?
  else
    if [[ -z "$gha_interval" ]]; then
      gha_interval=10
    fi

    print " running every $gha_interval minutes, press cmd+c to stop"
    print ""

    while true; do
      print " checking workflow..."

      gha_ "$workflow_arg"
      RET=$?

      if (( RET != 0 )); then
        return $RET;
      fi
      
      print ""
      print " sleeping $gha_interval minutes..."
      sleep $(($gha_interval * 60))
    done
  fi

  if (( RET == 0 && ask_save )); then
    # ask to save the workflow
    if confirm_from_ "would you like to save \"$workflow_arg\" as the default workflow for this project?"; then
      update_setting_ $found "PUMP_GHA_WORKFLOW" "\"$workflow_arg\""
    fi
    return 0;
  fi
}

function co() {
  eval "$(parse_flags_ "co_" "alprexbcq" "$@")"
  (( co_is_d )) && set -x

  if (( co_is_h )); then
    print "  ${yellow_cor}co ${solid_yellow_cor}[<branch>]${reset_cor} : to switch to a branch, displays local branches only"
    print "  ${yellow_cor}co -a${reset_cor} : to switch to a branch, displays all branches"
    print "  ${yellow_cor}co -l${reset_cor} : to switch to a branch, displays local branches only"
    print "  ${yellow_cor}co -pr${reset_cor} : to select from pull requests instead of branches and detach HEAD"
    print "  --"
    print "  ${yellow_cor}co -e <branch>${reset_cor} : to switch to an exact branch"
    print "  ${yellow_cor}co -b <branch>${reset_cor} : to create branch off of current branch or detached HEAD"
    print "  ${yellow_cor}co <branch> <base_branch>${reset_cor} : to create branch off of base branch"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " co requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  # co pr
  if (( co_is_p || co_is_r )); then
    local pr=("${(@s:|:)$(select_pr_ "$1")}")
    
    if [[ -z "${pr[1]}" ]]; then return 1; fi
    
    gum spin --title="detaching pull request: ${pr[3]}" -- \
      gh pr checkout --force --detach "${pr[1]}"
    RET=$?

    if (( RET == 0 )); then
      print " detached pull request: ${green_cor}${pr[3]}${reset_cor}"
      print " HEAD is now at $(git log -1 --pretty=format:'%h %s')"
      print " branch is detached, type ${yellow_cor}co -b <branch>${reset_cor} to create branch"
    fi

    return $RET;
  fi

  # co -a all branches
  if (( co_is_a )); then
    fetch --quiet
    local auto=$([[ -n "$1" ]] && echo 1 || echo 0)
    local branch_choice="$(select_branch_ $auto --all "$1")"
    
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
    fetch --quiet
    local auto=$([[ -n "$1" ]] && echo 1 || echo 0)
    local branch_choice="$(select_branch_ $auto --list "$1")"
    
    if [[ -z "$branch_choice" ]]; then return 1; fi

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

    if [[ -z "$branch" ]]; then
      print " branch is required" >&2
      return 1;
    fi

    base_branch="$(git branch --show-current)"
    
    local remote_origin="$(get_remote_origin_ "$base_branch")"

    fetch --quiet
    local RET=$?

    if [[ -n "$base_branch" ]]; then
      git checkout -b "$branch" "${remote_origin}/$base_branch" ${@:2}
      RET=$?
    else
      git checkout -b "$branch" ${@:2}
      RET=$?
      if (( RET == 0 )); then
        base_branch="$(git config --get init.defaultBranch)"
      fi
    fi

    if (( RET != 0 )); then return 1; fi

    ll_add_node_
    
    local remote_branch="$(git ls-remote --heads "$remote_origin" "$base_branch" | awk '{print $2}')"

    if [[ -n "$remote_branch" ]]; then
      git config "branch.${branch}.gh-merge-base" "$remote_branch"
      print " base branch is: $remote_branch"
    else
      git config "branch.${branch}.gh-merge-base" "$base_branch"
      print " base branch is: $base_branch"
    fi

    return 0;
  fi

  # co -e branch just checkout, do not create branch
  if (( co_is_e || co_is_x )); then
    local branch="$1"

    if [[ -z "$branch" ]]; then
      print " branch is required" >&2
      return 1;
    fi
    
    local current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    local _past_folder="$(pwd)"

    git switch "$branch" ${@:2}
    local RET=$?

    if (( RET == 0 )); then
      ll_add_node_
    fi

    return $RET;
  fi

  # co $1 or co (no arguments)
  if [[ -z "$2" || "$2" == --* ]]; then
    co -l $@
    return $?;
  fi

  # co branch BASE_BRANCH (creating branch)
  local branch="$1"
  
  fetch --quiet

  local base_branch="$(select_branch_ 1 --all "$2" 0 "choose a base branch")"
  if [[ -z "$base_branch" ]]; then
    return 1;
  fi

  if ! git checkout -b "$branch" "$base_branch" ${@:3}; then return 1; fi

  ll_add_node_
  
  local remote_origin="$(get_remote_origin_ "$base_branch")"
  local remote_branch="$(git ls-remote --heads "$remote_origin" "$base_branch" | awk '{print $2}')"

  if [[ -n "$remote_branch" ]]; then
    git config "branch.${branch}.gh-merge-base" "$remote_branch"
    print " base branch is: $remote_branch"
  else
    git config "branch.${branch}.gh-merge-base" "$base_branch"
    print " base branch is: $base_branch"
  fi

  return 0;
}

function next() {
  eval "$(parse_flags_ "next_" "" "$@")"
  (( next_is_d )) && set -x

  if (( next_is_h )); then
    print "  ${yellow_cor}next${reset_cor} : to go the next folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " no next folder or branch found" >&2
    return 1;
  fi

  $head=$ll_next[$head]
  open_working_
}

function prev() {
  eval "$(parse_flags_ "prev_" "" "$@")"
  (( prev_is_d )) && set -x

  if (( prev_is_h )); then
    print "  ${yellow_cor}prev${reset_cor} : to go the previous folder and branch"
    return 0;
  fi

  if [[ -z "$head" ]]; then
    print " no previous folder or branch found" >&2
    return 1;
  fi

  $head=$ll_prev[$head]
  open_working_
}

function back() {
  eval "$(parse_flags_ "back_" "" "$@")"
  (( back_is_d )) && set -x

  if (( back_is_h )); then
    print "  ${yellow_cor}back${reset_cor} : to go back the previous branch"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git switch -

  # if (( $? == 0 )); then
  #   $head=$ll_prev[$head]
  #   open_working_
  # fi
}

function dev() {
  # checkout dev or develop branch
  eval "$(parse_flags_ "dev_" "" "$@")"
  (( dev_is_d )) && set -x

  if (( dev_is_h )); then
    print "  ${yellow_cor}dev${reset_cor} : to switch to dev or develop in current project"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if [[ -n "$(git branch --all | grep -w dev)" ]]; then
    co -e dev
  elif [[ -n "$(git branch --all | grep -w develop)" ]]; then
    co -e develop
  else
    print " did not match a dev or develop branch known to git: dev or develop" >&2
    return 1;
  fi
}

function main() {
  # checkout main branch
  eval "$(parse_flags_ "main_" "" "$@")"
  (( main_is_d )) && set -x

  if (( main_is_h )); then
    print "  ${yellow_cor}main${reset_cor} : to switch to main in current project"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if [[ -n "$(git branch --all | grep -w main)" ]]; then
    co -e main
  elif [[ -n "$(git branch --all | grep -w master)" ]]; then
    co -e master
  else
    print " did not match a main branch known to git: main or master" >&2
    return 1;
  fi
}

function stage() {
  # checkout stage branch
  eval "$(parse_flags_ "stage_" "" "$@")"
  (( stage_is_d )) && set -x

  if (( stage_is_h )); then
      print "  ${yellow_cor}main${reset_cor} : to switch to stage or staging in current project"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if [[ -n "$(git branch --all | grep -w stage)" ]]; then
    co -e stage
  elif [[ -n "$(git branch --all | grep -w staging)" ]]; then
    co -e staging
  else
    print " did not match a stage or staging branch known to git: stage or staging" >&2
    return 1;
  fi
}

function rebase() {
  eval "$(parse_flags_ "rebase_" "pi" "$@")"
  (( rebase_is_d )) && set -x

  if (( rebase_is_h )); then
    print "  ${yellow_cor}rebase${reset_cor} : to apply the commits from your branch on top of the HEAD commit of $(git config --get init.defaultBranch)"
    print "  ${yellow_cor}rebase${solid_yellow_cor} [<branch>]${reset_cor} : to apply the commits from your branch on top of the HEAD commit of a branch"
    print "  ${yellow_cor}rebase -p${reset_cor} : push after rebase succeeds with no conflicts"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local rebase_branch=""

  if [[ -n "$1" && $1 != -* ]]; then
    rebase_branch="$1"
  else
    rebase_branch="$(git config --get init.defaultBranch)"
  fi

  local my_branch="$(git branch --show-current)"

  if [[ "$my_branch" == "$rebase_branch" ]]; then
    print " cannot rebase, branches are the same" >&2
    return 1;
  fi
  
  local remote_origin="$(get_remote_origin_ "$rebase_branch")"

  if [[ -z "$remote_origin" ]]; then
    print " cannot find remote origin for branch: $rebase_branch" >&2
    return 1;
  fi

  fetch --quiet
  local RET=$?

  if [[ -n "$1" && $1 != -* ]]; then
    git rebase "${remote_origin}/${rebase_branch}" ${@:2}
    RET=$?
  else
    git rebase "${remote_origin}/${rebase_branch}" $@
    RET=$?
  fi

  if (( RET == 0 && rebase_is_p )); then
    pushf
    RET=$?
  fi

  return $RET;
}

function merge() {
  eval "$(parse_flags_ "merge_" "p" "$@")"
  (( merge_is_d )) && set -x

  if (( merge_is_h )); then
    print "  ${yellow_cor}merge${reset_cor} : to create a new merge commit from $(git config --get init.defaultBranch)"
    print "  ${yellow_cor}merge${solid_yellow_cor} [<branch>]${reset_cor} : to create a new merge commit from a branch"
    print "  ${yellow_cor}merge -p${reset_cor} : push after merge succeeds with no conflicts"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi
  
  local merge_branch=""

  if [[ -n "$1" && $1 != -* ]]; then
    merge_branch="$1"
  else
    merge_branch="$(git config --get init.defaultBranch)"
  fi

  local my_branch="$(git branch --show-current)"

  if [[ "$my_branch" == "$merge_branch" ]]; then
    print " cannot merge, branches are the same" >&2
    return 1;
  fi
  
  local remote_origin="$(get_remote_origin_ "$merge_branch")"

  if [[ -z "$remote_origin" ]]; then
    print " cannot find remote origin for branch: $merge_branch" >&2
    return 1;
  fi

  fetch --quiet
  local RET=$?

  if [[ -n "$1" && $1 != -* ]]; then
    git merge "${remote_origin}/${merge_branch}" --no-edit ${@:2}
    RET=$?
  else
    git merge "${remote_origin}/${merge_branch}" --no-edit $@
    RET=$?
  fi

  if (( RET == 0 && merge_is_p )); then
    push
    RET=$?
  fi

  return $RET;
}

function prune() {
  eval "$(parse_flags_ "prune_" "" "$@")"
  (( prune_is_d )) && set -x

  if (( prune_is_h )); then
    print "  ${yellow_cor}prune${reset_cor} : to clean up unreachable or orphaned git branches and tags"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local default_main_branch="$(git config --get init.defaultBranch)"

  # delete all local tags
  # git tag -l | xargs git tag -d 1>/dev/null

  # Get all local tags
  local local_tags=("${(@f)$(git tag)}")

  # Get all remote tags (strip refs/tags/)
  local remote_tags=("${(@f)$(git ls-remote --tags origin)}")
  local remote_tag_names=()
  for line in "${remote_tags[@]}"; do
    [[ $line =~ refs/tags/(.+)$ ]] && remote_tag_names+=("${match[1]}")
  done

  local tag=""
  # Remove local tags not in remote
  for tag in "${local_tags[@]}"; do
    if ! [[ "${remote_tag_names[@]}" == *"$tag"* ]]; then
      git tag -d "$tag"
    fi
  done

  # fetch tags that exist in the remote
  fetch -t --quiet
  
  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches="$(git branch --merged | grep -v "^\*\\|${default_main_branch}" | sed 's/^[ *]*//')"

  for branch in $branches; do
    git branch -D "$branch"
    git config --remove-section "branch.${branch}" &>/dev/null
  done

  local current_branches=$(git branch --format '%(refname:short)')

  # Loop through all Git config sections to find old branches
  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    # Check if the branch exists locally
    if ! echo "$current_branches" | grep -q "^$branch_name\$"; then
      git config --remove-section "branch."$branch_name"" &>/dev/null
    fi
  done

  git prune $@
}

function delb() {
  eval "$(parse_flags_ "delb_" "sra" "$@")"
  (( delb_is_d )) && set -x

  if (( delb_is_h )); then
    print "  ${yellow_cor}delb${solid_yellow_cor} [<branch>]${reset_cor} : to find branches to delete"
    print "  ${yellow_cor}delb -r${solid_yellow_cor} [<branch>]${reset_cor} : to also delete remotely"
    print "  ${yellow_cor}delb -a${reset_cor} : to find all branches"
    print "  ${yellow_cor}delb -s${reset_cor} : to skip confirmation"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local branch_arg="$1"
  local deleted_branches=();

  local filter=$((( delb_is_r )) && echo "-r" || echo "--list")
  local selected_branches=($(select_branch_ 0 $filter "$branch_arg" 1 "choose branches" $delb_is_a))
  
  if [[ -z "$selected_branches" ]]; then
    return 1;
  fi

  local excluded_branches=("main" "master")

  if (( ! delb_is_a )); then
    excluded_branches+=("dev" "develop" "stage" "staging")
  fi

  local RET=0

  for branch in ${selected_branches[@]}; do
    if (( ! delb_is_s || delb_is_r )); then
      local origin="$((( delb_is_r )) && echo "remote" || echo "local")"
      confirm_from_ "delete ${origin} branch: "$'\e[0;95m'$branch$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi

    git config --remove-section "branch.${branch}" &>/dev/null

    if (( delb_is_r )); then
      local remote_origin="$(get_remote_origin_)"

      git branch -D "$branch" &>/dev/null
      git push --delete "$remote_origin" "$branch"
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
  eval "$(parse_flags_ "st_" "" "$@")"
  (( st_is_d )) && set -x

  if (( st_is_h )); then
    print "  ${yellow_cor}st${reset_cor} : to show git status"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  git status -sb $@
}

function pro() {
  # f is to suggest adding a project for $(pwd)
  eval "$(parse_flags_ "pro_" "aerucfis" "$@")"
  (( pro_is_d )) && set -x

  if (( pro_is_h )); then
    print "  ${yellow_cor}pro <name>${reset_cor} : to set a project"
    print "  ${yellow_cor}pro -c ${solid_yellow_cor}[<name>]${reset_cor} : to show project config"
    print "  ${yellow_cor}pro -a ${solid_yellow_cor}[<name>]${reset_cor} : to add a new project"
    print "  --"
    print "  ${yellow_cor}pro -e <name>${reset_cor} : to edit a project"
    print "  ${yellow_cor}pro -r <name>${reset_cor} : to remove a project"
    # print "  ${yellow_cor}pro -u <name>${reset_cor} : to unset project"
    print "  ${yellow_cor}pro -i <name>${reset_cor} : to display the project's readme"
    
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[*]}" ]]; then
      print ""
      print -n " projects: | ${blue_cor}"
      local i=0
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          print -n "${PUMP_PROJECT_SHORT_NAME[$i]}"
          print -n "${reset_cor} | ${blue_cor}"
        fi
      done
      print "${reset_cor}"
    fi
    return 0;
  fi

  local proj_arg="$1"

  if (( pro_is_i )); then
    # display readme file of project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to display readme" >&2
      print " ${yellow_cor} pro -i <name>${reset_cor}" >&2
      return 1;
    fi

    local _pwd="$(pwd)"

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if ! open_proj_for_pkg_ "${PUMP_PROJECT_FOLDER[$i]}" "readme.md"; then
          print " project readme file not found" >&2
          return 1;
        fi

        # find readme file
        local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
        if [[ -n "$readme_file" ]]; then
          if command -v glow &>/dev/null; then
            glow "$readme_file"
          else
            cat "$readme_file"
          fi
        fi
        cd "$_pwd"
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    return 1;
  fi

  if (( pro_is_c )); then
    # show project config
    if [[ -z "$proj_arg" ]]; then
      print_current_proj_ 0
      return $?;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        print_current_proj_ $i
        return $?;
      fi
    done

    print " project not found: $proj_arg" >&2
    return 1;
  fi

  # CRUD operations
  if (( pro_is_e )); then
    # edit project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to edit" >&2
      print " ${yellow_cor} pro -e <name>${reset_cor}" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        save_proj_ -e $i "$proj_arg"
        return $?;
      fi
    done
    
    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -a ${proj_arg}${reset_cor} to add project" >&2
    return 1;
  fi
  
  if (( pro_is_a )); then
    # add project
    local i=0
    for i in {1..9}; do
      if [[ -z "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if [[ -n "$proj_arg" ]]; then
          if ! check_proj_cmd_ $i "$proj_arg"; then return 1; fi
        fi
        save_proj_ -a $i "$proj_arg"
        return $?;
      fi
    done

    print " no more slots available, please remove one to add a new one" >&2
    return 1;
  fi

  if (( pro_is_r )); then
    # remove project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to delete" >&2
      print " ${yellow_cor} pro -r <name>${reset_cor}" >&2
      return 1;
    fi

    local re_activate=0;

    if [[ "$proj_arg" == "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]] && ! is_proj_folder_ "$(pwd)" &>/dev/null; then
      re_activate=1
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if remove_prj_ $i; then
          print " project removed: $proj_arg"
          
          if (( re_activate )); then
            activate_pro_ 0
            return $?;
          fi
  
          return 0;
        fi
      fi
    done

    print " project not found: $proj_arg" >&2
    return 1;
  fi # end of remove project

  if [[ -z "$proj_arg" ]]; then
    if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      print -n " project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJECT_SHORT_NAME}${reset_cor}"
      if [[ -n "$CURRENT_PUMP_PACKAGE_MANAGER" ]]; then
        print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PACKAGE_MANAGER}${reset_cor}"
      fi
      print ""
    else
      print " provide a project name" >&2
    fi
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # pro pwd
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(which_pro_pwd_);

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      if ! is_proj_folder_ "$(pwd)" &>/dev/null; then return 1; fi
      
      local pkg_name="$(get_from_pkg_json_ "name")"
      local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")

      local remote_origin="$(get_remote_origin_)"
      local proj_repo="$(git remote get-url "$remote_origin" 2>/dev/null)"

      local i=0 foundI=0 emptyI=0
      for i in {1..9}; do
        if [[ $foundI -eq 0 ]] && [[ "$proj_repo" == "${PUMP_PROJECT_REPO[$i]}" || "$proj_cmd" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          foundI=$i
        fi
        if [[ $emptyI -eq 0 && -z "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          emptyI=$i
        fi
      done

      local action="add"; (( foundI )) && action="edit"

      if confirm_from_ "would you like to $action this project: "$'\e[38;5;201m'"$pkg_name"$'\e[0m'" ?"; then
        if (( foundI )); then
          save_proj_ -fe $foundI "$pkg_name"
        else
          save_proj_ -fa $emptyI "$pkg_name"
        fi
        return $?;
      fi
    fi
  fi

  local found=0
  # Check if the project name matches one of the configured projects
  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      found=$i
      break;
    fi
  done

  if (( ! found )); then
    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi
  
  local is_refresh=0

  if (( pro_is_s )) || [[ "$proj_arg" != "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    is_refresh=1
  fi

  # set the current project
  load_config_entry_ $found
  save_current_proj_ $found

  if (( is_refresh )); then
    print -n " project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJECT_SHORT_NAME}${reset_cor}"
    if [[ -n "$CURRENT_PUMP_PACKAGE_MANAGER" ]]; then
      print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PACKAGE_MANAGER}${reset_cor}"
    fi
    print ""

    echo "$CURRENT_PUMP_PROJECT_SHORT_NAME" > "$PUMP_PRO_FILE"
    
    export CURRENT_PUMP_PROJECT_SHORT_NAME="$CURRENT_PUMP_PROJECT_SHORT_NAME"

    if [[ -n "$CURRENT_PUMP_PRO" ]]; then
      if ! eval "$CURRENT_PUMP_PRO"; then
        print " failed to run PUMP_PRO_${found}" >&2
      fi
    fi

    unset_aliases_
    set_aliases_ $found
  fi

  return 0;
}

function proj_handler_() {
  # project functions =========================================================
  # pump() project()
  local i="$1"
  shift

  eval "$(parse_flags_ "proj_handler_" "lme" "$@")"
  (( proj_handler_is_d )) && set -x

  local proj_cmd="${PUMP_PROJECT_SHORT_NAME[$i]}"

  if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_cmd" "${PUMP_PROJECT_REPO[$i]}"; then
    return 1;
  fi

  local proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

  if [[ -z "$proj_folder" ]]; then return 1; fi

  local working="${PUMP_WORKING[$i]}"
  local single_mode="${PUMP_PROJECT_SINGLE_MODE[$i]:-1}"

  if (( proj_handler_is_h )); then
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd ${reset_cor}: to set project to $proj_cmd and open a folder"
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd -l${reset_cor}: to list all folders in $proj_cmd"
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd -m${reset_cor}: to set project to $proj_cmd and open the default folder"
    (( ! single_mode )) && print "  ${yellow_cor}$proj_cmd <folder> ${reset_cor}: to set project to $proj_cmd and open the folder"
    
    (( single_mode )) && print "  ${yellow_cor}$proj_cmd ${reset_cor}: to set project to $proj_cmd"
    (( single_mode )) && print "  ${yellow_cor}$proj_cmd <branch> ${reset_cor}: to set project to $proj_cmd and switch to branch"
    print "  --"
    print "  ${yellow_cor}$proj_cmd -e ${reset_cor}: to edit the project"
    return 0;
  fi
  
  if (( proj_handler_is_e )); then
    pro -e "$proj_cmd"
    return $?
  fi

  if (( proj_handler_is_l )); then
    local dirs=($(get_folders_ "$proj_folder"))
    if (( ${#dirs[@]} )); then
      local dir=""
      for dir in "${dirs[@]}"; do
        print "${pink_cor} $dir ${reset_cor}"
      done
    else
      print " no folders"
    fi
    return 0;
  fi

  local folder_arg=""
  local branch_arg=""

  local use_default_folder=0

  if [[ -n "$2" ]]; then
    (( single_mode )) && branch_arg="$2"
    folder_arg="$1"

  elif [[ -n "$1" ]]; then
    if [[ -d "$proj_folder/$1" ]] || (( ! single_mode )); then
      folder_arg="$1"
    else
      branch_arg="$1"
    fi

  elif (( proj_handler_is_m )); then
    if (( ! single_mode )); then
      use_default_folder=1
      folder_arg="$(get_default_folder_ "$proj_folder")"
    fi
  fi

  local resolved_folder=""

  # resolve folder_arg
  if (( single_mode )); then
    resolved_folder="$proj_folder"
  else
    if [[ -n "$folder_arg" && -d "${proj_folder}/${folder_arg}" ]]; then
      if (( ! use_default_folder )); then
        resolved_folder="${proj_folder}/${folder_arg}"
      fi
    else
      resolved_folder="$proj_folder"
      
      local dirs=($(get_folders_ "$proj_folder"))
      
      if (( ${#dirs[@]} )); then
        local chosen_folder=($(choose_one_ 1 "choose folder to open" 20 "${dirs[@]}"))
        
        if [[ -n "$chosen_folder" ]]; then
          resolved_folder="${proj_folder}/${chosen_folder}"
        fi
      fi
    fi
  fi

  pro "$proj_cmd"

  if [[ -z "$resolved_folder" ]]; then return 1; fi
  if ! pushd "$resolved_folder" &>/dev/null; then return 1; fi

  if [[ -z "$(ls -A "$resolved_folder")" ]]; then
    print " now type ${yellow_cor}clone ${proj_cmd}${reset_cor} to get started by cloning your first project"
    return 0;
  fi

  if (( ! single_mode )); then return 0; fi
  if [[ -z "$branch_arg" ]]; then return 0; fi

  co "$branch_arg"
}

function stash() {
  eval "$(parse_flags_ "stash_" "vl" "$@")"
  (( stash_is_d )) && set -x

  if (( stash_is_h )); then
    print "  ${yellow_cor}stash [<name>]${reset_cor} : to stash files"
    print "  ${yellow_cor}stash -v ${solid_yellow_cor}[n]${reset_cor} : to view latest nth stash"
    print "  ${yellow_cor}stash -l ${solid_yellow_cor}[n]${reset_cor} : to list stashes, limit by n"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

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
  eval "$(parse_flags_ "pop_" "a" "$@")"
  (( pop_is_d )) && set -x

  if (( pop_is_h )); then
    print "  ${yellow_cor}pop${reset_cor} : to pop and apply latest stash"
    print "  ${yellow_cor}pop -a${reset_cor} : to pop and apply all stashes"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if (( pop_is_a )); then
    local stashes=()
    local stash

    # Collect stash refs in an array
    while IFS= read -r line; do
      stash="${line%%:*}"  # strip everything after the first colon
      stashes+=("$stash")
    done < <(git stash list)

    # Pop in reverse order (so indices don’t shift)
    for (( i=${#stashes[@]}-1; i>=0; i-- )); do
      echo "Popping ${stashes[i]}..."
      git stash pop --index "${stashes[i]}" || break;
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

eval "
  function ${COMMIT1}() {
    __commit \"\$@\"
  }
"

if [[ -n "$COMMIT2" ]]; then
  eval "
    function ${COMMIT2}() {
      __commit \"\$@\"
    }
  "
fi

function __commit() {
  eval "$(parse_flags_ "commit_" "" "$@")"
  (( commit_is_d )) && set -x

  if (( commit_is_h )); then
    print "  ${yellow_cor}${COMMIT1}${reset_cor} : to open commit wizard"
    print "  ${yellow_cor}${COMMIT1} -a${reset_cor} : to open wizard and commit all files"
    print "  ${yellow_cor}${COMMIT1} <message>${reset_cor} : to commit with message"
    print "  ${yellow_cor}${COMMIT1} -a <message>${reset_cor} : to commit all files with message"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if (( commit_is_a || CURRENT_PUMP_COMMIT_ADD )); then
    git add .
  elif [[ -z "$CURRENT_PUMP_COMMIT_ADD" ]]; then
    if confirm_from_ "commit all changes?"; then
      git add .

      if confirm_from_ "save this preference and don't ask again?"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
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
      print " commit wizard requires gum" >&2
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

    local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    
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
    gum style --border=rounded --margin=0 --padding="1 16" --border-foreground=212 --width=69 \
      --align=center "welcome to $(gum style --foreground 212 "fab1o's pump my shell! v$PUMP_VERSION")" 2>/dev/tty
  else
    display_line_ "fab1o's pump my shell!" "${purple_cor}"
    print ""
  fi

  local remote_origin="$(get_remote_origin_)"

  if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    print ""
    print -n "   project set to: ${solid_blue_cor}${CURRENT_PUMP_PROJECT_SHORT_NAME}${reset_cor}"
    if [[ -n "$CURRENT_PUMP_PACKAGE_MANAGER" ]]; then
      print -n " with ${solid_magenta_cor}${CURRENT_PUMP_PACKAGE_MANAGER}${reset_cor}"
    fi
    print ""
  else
    pro -a
    return $?;
  fi

  print ""
  display_line_ "get started" "${blue_cor}"
  print ""
  print "  1. set a project, type:${solid_blue_cor} pro${reset_cor}"
  print "  2. clone project, type:${blue_cor} clone${reset_cor}"
  print "  3. setup project, type:${blue_cor} setup${reset_cor}"
  print "  4. run a project, type:${blue_cor} run${reset_cor}"

  print ""
  display_line_ "project selection" "${solid_blue_cor}"
  print ""
  print " ${solid_blue_cor} pro ${reset_cor}\t\t = project management"

  local i=0
  for i in {1..9}; do
    if [[ -n "${PUMP_PROJECT_FOLDER[$i]}" && -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      local short="${PUMP_PROJECT_SHORT_NAME[$i]}"
      local folder="${PUMP_PROJECT_FOLDER[$i]}"
      local shortened_path=$(shorten_path_ "$folder" 1)
      local tab=$([[ ${#short} -lt 5 ]] && echo -e "\t\t" || echo -e "\t")
      
      print " ${solid_blue_cor} $short ${reset_cor}${tab} = set project and cd $shortened_path"
    fi
  done

  print ""
  display_line_ "setup and run" "${blue_cor}"
  print ""
  print " ${blue_cor} clone ${reset_cor}\t = clone project or branch"
  
  local _setup=${CURRENT_PUMP_SETUP:-$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")setup}
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

  print ""
  display_line_ "code review" "${cyan_cor}"
  print ""
  print " ${cyan_cor} rev ${reset_cor}\t\t = open a pull request for review"
  print " ${cyan_cor} revs ${reset_cor}\t\t = list existing reviews"
  print " ${cyan_cor} prune revs ${reset_cor}\t = delete merged reviews"

  if ! pause_output_; then return 0; fi

  display_line_ "$CURRENT_PUMP_PACKAGE_MANAGER" "${solid_magenta_cor}"
  print ""
  print " ${solid_magenta_cor} build ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")build"
  print " ${solid_magenta_cor} deploy ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")deploy"
  print " ${solid_magenta_cor} fix ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format + lint"
  print " ${solid_magenta_cor} format ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")format"
  print " ${solid_magenta_cor} i ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install"
  print " ${solid_magenta_cor} ig ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")install global"
  print " ${solid_magenta_cor} lint ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")lint"
  print " ${solid_magenta_cor} rdev ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")dev"
  print " ${solid_magenta_cor} sb ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook"
  print " ${solid_magenta_cor} sbb ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")storybook:build"
  print " ${solid_magenta_cor} start ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")start"
  print " ${solid_magenta_cor} tsc ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")tsc"
  
  print ""
  display_line_ "test $CURRENT_PUMP_PROJECT_SHORT_NAME" "${magenta_cor}"
  print ""
  if [[ "$CURRENT_PUMP_COV" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage" ]]; then
    print " ${solid_magenta_cor} ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}cov ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:coverage"
  fi
  if [[ "$CURRENT_PUMP_E2E" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e" ]]; then
    print " ${solid_magenta_cor} ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}e2e ${reset_cor}\t\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e"
  fi
  if [[ "$CURRENT_PUMP_E2EUI" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui" ]]; then
    print " ${solid_magenta_cor} ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}e2eui ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:e2e-ui"
  fi
  if [[ "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test" ]]; then
    print " ${solid_magenta_cor} ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}test ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test"
  fi
  if [[ "$CURRENT_PUMP_TEST_WATCH" != "$CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch" ]]; then
    print " ${solid_magenta_cor} ${CURRENT_PUMP_PACKAGE_MANAGER:0:1}testw ${reset_cor}\t = $CURRENT_PUMP_PACKAGE_MANAGER $([[ $CURRENT_PUMP_PACKAGE_MANAGER == "yarn" ]] && echo "" || echo "run ")test:watch"
  fi
  print " ${magenta_cor} cov ${reset_cor}\t\t = $CURRENT_PUMP_COV"
  print " ${magenta_cor} e2e ${reset_cor}\t\t = $CURRENT_PUMP_E2E"
  print " ${magenta_cor} e2eui ${reset_cor}\t = $CURRENT_PUMP_E2EUI"
  print " ${magenta_cor} test ${reset_cor}\t\t = $CURRENT_PUMP_TEST"
  print " ${magenta_cor} testw ${reset_cor}\t = $CURRENT_PUMP_TEST_WATCH"

  print ""
  display_line_ "git" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} gconf ${reset_cor}\t = git config"
  print " ${solid_cyan_cor} gha ${reset_cor}\t\t = view last workflow run"
  print " ${solid_cyan_cor} st ${reset_cor}\t\t = git status"
  
  if ! pause_output_; then return 0; fi

  display_line_ "git branch" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} back ${reset_cor}\t\t = go back to previous branch in the current folder"
  print " ${solid_cyan_cor} co ${reset_cor}\t\t = branch management"
  print " ${solid_cyan_cor} dev ${reset_cor}\t\t = switch to dev or develop"
  print " ${solid_cyan_cor} main ${reset_cor}\t\t = switch to main"
  print " ${solid_cyan_cor} next ${reset_cor}\t\t = go to the next working folder/branch"
  print " ${solid_cyan_cor} prev ${reset_cor}\t\t = go to the previous working folder/branch"
  print " ${solid_cyan_cor} renb <b>${reset_cor}\t = rename branch"
  print " ${solid_cyan_cor} stage ${reset_cor}\t = switch to stage or staging"

  print ""
  display_line_ "git clean" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} clean${reset_cor}\t\t = clean + restore"
  print " ${solid_cyan_cor} delb ${reset_cor}\t\t = delete branches"
  print " ${solid_cyan_cor} discard ${reset_cor}\t = reset local changes"
  print " ${solid_cyan_cor} prune ${reset_cor}\t = prune branches and tags"
  print " ${solid_cyan_cor} reset1 ${reset_cor}\t = reset soft 1 commit"
  print " ${solid_cyan_cor} reset2 ${reset_cor}\t = reset soft 2 commits"
  print " ${solid_cyan_cor} reset3 ${reset_cor}\t = reset soft 3 commits"
  print " ${solid_cyan_cor} reset4 ${reset_cor}\t = reset soft 4 commits"
  print " ${solid_cyan_cor} reset5 ${reset_cor}\t = reset soft 5 commits"
  print " ${solid_cyan_cor} reseta ${reset_cor}\t = reset hard $remote_origin + clean"
  print " ${solid_cyan_cor} restore ${reset_cor}\t = undo edits since last commit"
  
  print ""
  display_line_ "git log" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} glog ${reset_cor}\t\t = git log"
  print " ${solid_cyan_cor} gll ${reset_cor}\t\t = list branches"
  print " ${solid_cyan_cor} glr ${reset_cor}\t\t = list remote branches"

  if ! pause_output_; then return 0; fi

  display_line_ "git pull" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} fetch ${reset_cor}\t = fetch from $remote_origin"
  print " ${solid_cyan_cor} pull ${reset_cor}\t\t = pull all branches from $remote_origin"

  print ""
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
  print " ${solid_cyan_cor} push ${reset_cor}\t\t = push all no-verify to $remote_origin"
  print " ${solid_cyan_cor} pushf ${reset_cor}\t = push force all to $remote_origin"
  
  print ""
  display_line_ "git rebase" "${solid_cyan_cor}"
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
  
  display_line_ "git stash" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} pop ${reset_cor}\t\t = apply stash then remove from list"
  print " ${solid_cyan_cor} stash ${reset_cor}\t = stash files"

  print ""
  display_line_ "git release" "${solid_cyan_cor}"
  print ""
  print " ${solid_cyan_cor} dtag ${reset_cor}\t\t = delete a tag"
  print " ${solid_cyan_cor} drelease ${reset_cor}\t = delete a release"
  print " ${solid_cyan_cor} release ${reset_cor}\t = create a release"
  print " ${solid_cyan_cor} tag ${reset_cor}\t\t = create a tag"
  print " ${solid_cyan_cor} tags ${reset_cor}\t\t = list latest tags"
  print " ${solid_cyan_cor} tags 1 ${reset_cor}\t = display latest tag"

  print ""
  display_line_ "general" "${solid_cyan_cor}"
  print ""
  print " ${solid_yellow_cor} cl ${reset_cor}\t\t = clear"
  print " ${solid_yellow_cor} del ${reset_cor}\t\t = delete utility"
  print " ${solid_yellow_cor} help ${reset_cor}\t\t = display this help"
  print " ${solid_yellow_cor} hg <text> ${reset_cor}\t = history | grep text"
  print " ${solid_yellow_cor} kill <port> ${reset_cor}\t = kill port"
  print " ${solid_yellow_cor} ll ${reset_cor}\t\t = ls -laF"
  print " ${solid_yellow_cor} nver ${reset_cor}\t\t = node version"
  print " ${solid_yellow_cor} nlist ${reset_cor}\t = npm list global"
  print " ${solid_yellow_cor} path ${reset_cor}\t\t = print \$PATH"
  print " ${solid_yellow_cor} refresh ${reset_cor}\t = source .zshrc"
  print " ${solid_yellow_cor} upgrade ${reset_cor}\t = upgrade pump + zsh + omp"
  print ""
  display_line_ "multi-step task" "${pink_cor}"
  print ""
  print " ${pink_cor} cov <b> ${reset_cor}\t = compare test coverage with another branch"
  print " ${pink_cor} refix ${reset_cor}\t = reset last commit, run fix then re-commit/push"
  print " ${pink_cor} recommit ${reset_cor}\t = reset last commit then re-commit changes to index"
  print " ${pink_cor} release ${reset_cor}\t = bump version and create a release in github"
  print " ${pink_cor} repush ${reset_cor}\t = reset last commit then re-push changes to index"
  print " ${pink_cor} rev ${reset_cor}\t\t = open a pull request for review on $CURRENT_PUMP_CODE_EDITOR"
  print ""
  print "  to learn more, visit:${blue_cor} https://github.com/fab1o/pump-zsh/wiki ${reset_cor}"
}

function validate_proj_cmd_strict_() {
  eval "$(parse_flags_ "validate_proj_cmd_strict_" "" "$@")"
  (( validate_proj_cmd_strict_is_d )) && set -x

  local proj_cmd="$1"
  local qty="$2"

  if ! validate_proj_cmd_ "$proj_cmd" $qty; then
    return 1;
  fi

  if (( ! validate_proj_cmd_strict_is_e )); then
    local reserved=""
    reserved="$(whence -w "$proj_cmd" 2>/dev/null)"

    if (( $? == 0 )); then
      if [[ $reserved =~ ": command" ]]; then
        if confirm_from_ "project name is reserved, $reserved - use it anyway?"; then
          return 0;
        else
          return 1;
        fi
      fi
      print " project name is reserved, $reserved" 2>/dev/tty >&2
      return 1;
    fi
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
  else
    # check for duplicates across other indices
    for j in {1..10}; do
      if [[ $j -ne $i && "${PUMP_PROJECT_SHORT_NAME[$j]}" == "$proj_cmd" ]]; then
        error_msg="project name already in use: $proj_cmd"
        break;
      fi
    done
  fi

  if [[ -n "$error_msg" ]]; then
    print " $error_msg" 2>/dev/tty >&2
    return 1;
  fi

  return 0;
}

typeset -gA PUMP_PROJECT_SHORT_NAME
typeset -gA PUMP_PROJECT_FOLDER
typeset -gA PUMP_PROJECT_REPO
typeset -gA PUMP_PROJECT_SINGLE_MODE
typeset -gA PUMP_PACKAGE_MANAGER
typeset -gA PUMP_CODE_EDITOR
typeset -gA PUMP_CLONE
typeset -gA PUMP_SETUP
typeset -gA PUMP_RUN
typeset -gA PUMP_RUN_STAGE
typeset -gA PUMP_RUN_PROD
typeset -gA PUMP_PRO
typeset -gA PUMP_TEST
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
typeset -gA PUMP_DEFAULT_BRANCH
typeset -gA PUMP_GHA_WORKFLOW
typeset -gA PUMP_PUSH_ON_REFIX
typeset -gA PUMP_PRINT_README

# ========================================================================
typeset -g CURRENT_PUMP_PROJECT_SHORT_NAME=""
typeset -g CURRENT_PUMP_PROJECT_FOLDER=""
typeset -g CURRENT_PUMP_PROJECT_REPO=""
typeset -g CURRENT_PUMP_PROJECT_SINGLE_MODE=""
typeset -g CURRENT_PUMP_PACKAGE_MANAGER=""
typeset -g CURRENT_PUMP_CODE_EDITOR=""
typeset -g CURRENT_PUMP_CLONE=""
typeset -g CURRENT_PUMP_SETUP=""
typeset -g CURRENT_PUMP_RUN=""
typeset -g CURRENT_PUMP_RUN_STAGE=""
typeset -g CURRENT_PUMP_RUN_PROD=""
typeset -g CURRENT_PUMP_PRO=""
typeset -g CURRENT_PUMP_TEST=""
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
typeset -g CURRENT_PUMP_DEFAULT_BRANCH=""
typeset -g CURRENT_PUMP_PRINT_README=""

typeset -g MULTIPLE_MODE=0
typeset -g SINGLE_MODE=1

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g TEMP_PUMP_PROJECT_SHORT_NAME=""

export CURRENT_PUMP_PROJECT_SHORT_NAME=""
# ========================================================================

# General
alias hg="history | grep" # $1
alias ll="ls -lAF"
alias nver="node -e 'console.log(process.version, process.arch, process.platform)'"
alias nlist="npm list --global --depth=0"
alias path="echo $PATH"

load_config_

local i=0
for i in {1..9}; do
  if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
    eval "function ${PUMP_PROJECT_SHORT_NAME[$i]}() { proj_handler_ $i \"\$@\"; }"
  fi
done

activate_pro_ 1 # set project


# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs