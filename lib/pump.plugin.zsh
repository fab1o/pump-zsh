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
  RET=$?

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
    [[ "$id" == "$head" ]] && break
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
    [[ "$id" == "$head" ]] && break
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
    [[ "$id" == "$head" ]] && break
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

  # clear_last_line_
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
      echo "$(gum choose --select-if-one --no-limit --header="${purple} $header ${cor}(use spacebar)${purple}:${reset}" --height="$height" "${@:4}" 2>/dev/tty)"
    else
      echo "$(gum choose --no-limit --header="${purple} $header ${cor}(use spacebar)${purple}:${reset}" --height="$height" "${@:4}" 2>/dev/tty)"
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
      echo "$(gum filter --height 20 --limit=1 --select-if-one --indicator=">" --placeholder=" $3" "${@:4}")"
    else
      echo "$(gum filter --height 20 --limit=1 --indicator=">" --placeholder=" $3" "${@:4}")"
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
      choice="$(gum choose --limit=1 --select-if-one --header="${purple} $header:${reset}" --height="$height" "${@:4}" 2>/dev/tty)"
    else
      choice="$(gum choose --limit=1 --header="${purple} $header:${reset}" --height="$height" "${@:4}" 2>/dev/tty)"
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

  eval "${proj_cmd[$i]}() { proj_handler_ $i \"\$@\"; }"

  update_setting_ $i "PUMP_PROJECT_SHORT_NAME" "$proj_cmd"
  
  print "  ${pink_cor}project name:${reset_cor} $proj_cmd" >&1
}

function update_setting_() {
  check_config_file_

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then return 1; fi

  local i="$1"
  local general_key="$2" 
  local value="$3"

  if [[ $i -eq 0 || "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
    eval "CURRENT_${general_key}=\"$value\""
  fi

  if (( i > 0 )); then
    eval "${general_key}[$i]=\"$value\""
  fi

  local key="${general_key}_${i}"

  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS (BSD sed) requires correct handling of patterns
    sed -i '' "s|^$key=[^[:space:]]*|$key=$value|" "$PUMP_CONFIG_FILE"
  else
    # Linux (GNU sed)
    sed -i "s|^$key=[^[:space:]]*|$key=$value|" "$PUMP_CONFIG_FILE"
  fi

  if (( $? != 0 )); then
    print "  warn: failed to update $key in $PUMP_CONFIG_FILE" >&2
  fi

  if [[ "$general_key" == "PUMP_PROJECT_SHORT_NAME" && -n "$PUMP_PROJECT_SHORT_NAME" ]]; then
    eval "${PUMP_PROJECT_SHORT_NAME[$i]}() { proj_handler_ $i \"\$@\"; }"
  fi

  return 0;
}

function input_branch_name_() {
  local header="$1"

  while true; do
    local typed_value=""
    typed_value="$(input_from_ "$header")"
    if (( $? != 0 )); then
      return 1;
    fi
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
    if (( $? != 0 )); then
      return 1;
    fi
    if [[ -z "$typed_value" ]]; then
      if [[ -n "$placeholder" ]] && command -v gum &>/dev/null; then
        typed_value="$placeholder"
      fi
    fi
    if [[ -n "$typed_value" ]]; then
      if validate_proj_cmd_ "$typed_value"; then
        echo "$typed_value"
        return 0;
      fi
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

  print " ${purple_cor} ${header}:${reset_cor}" 1>/dev/tty

  cd "${HOME:-/}" # start from home

  while true; do
    if [[ -n "$folder_path" ]]; then
      local new_folder=""

      if (( folder_exists )); then
        new_folder="$folder_path"
      else
        new_folder="${folder_path}/$folder_name"
      fi

      confirm_between_ "do you want to use: "$'\e[94m'${new_folder}$'\e[0m'" or keep browsing?" "use" "browse"
      RET=$?
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
              print "  project folder already in use, choose another one" >&2
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
    RET=$?
    if (( RET == 130 )); then return 1; fi

    if (( RET == 0 )); then
      local gh_owner=""
      gh_owner=$(input_from_ "type the github owner account (user or organization)")
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
    if (( $? != 0 )); then
      return 1;
    fi
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
        break
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
  eval "$(parse_flags_ "check_proj_cmd_" "s" "$@")"
  (( check_proj_cmd_is_d )) && set -x

  local i="$1"
  local proj_cmd="$2"

  if ! validate_proj_cmd_ "$proj_cmd"; then
    if (( check_proj_cmd_is_s )); then
      if save_proj_cmd_ $i "$proj_cmd"; then return 0; fi
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
        gum spin --timeout=7s --title="checking repository uri..." -- git ls-remote "${proj_repo}" --quiet
      else
        print " checking repository uri..."
        git ls-remote "${proj_repo}" --quiet 1>/dev/tty
      fi
      if (( $? != 0 )); then
        error_msg="repository uri is invalid or no access rights: $proj_repo"
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    print "  $error_msg" 2>/dev/tty >&2

    if (( check_proj_repo_is_s )); then
      if save_proj_repo_ $i "$proj_folder"; then return 0; fi
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

  local error_msg=""

  if [[ -z "$proj_folder" ]]; then
    error_msg="project folder is missing"
  fi

  if [[ -n "$error_msg" ]]; then
    print "  $error_msg" 2>/dev/tty >&2

    if (( check_proj_folder_is_s )); then
      if save_proj_folder_ $i "$pkg_name"; then return 0; fi
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
      if save_pkg_manager_ $i; then return 0; fi
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
  eval "$(parse_flags_ "save_proj_cmd_" "ae" "$@")"
  (( save_proj_cmd_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"
  
  local pkg_name_sanitized=$(sanitize_pkg_name_ "$pkg_name" 2>/dev/tty)

  local typed_name=$(input_name_ "type your project command name" "$pkg_name_sanitized")
  if [[ -z "$typed_name" ]]; then return 1; fi
  # clear_last_line_

  if ! check_proj_cmd_ $i "$typed_name"; then return 1; fi

  update_proj_cmd_ $i "$typed_name"
}

function choose_mode_() {
  local proj_folder=".../$(basename "$1")"

  print ""

  local multiple_title=$(gum style --align=center --margin=0 --align=left --padding="0 9" --border=none --width=40 "example of multiple")
  local single_title=$(gum style --align=center --margin=0 --align=left --padding="0 11" --border=none --width=40 "example of single")

  local titles=$(gum join --align=center --horizontal "$multiple_title" "$single_title")

  local multiple=$'
  '"$proj_folder"'/
      ├── main/
      ├── dev/
      ├── feature-branch/
      └── revs/
          ├── pr-branch/
          └── another-pr/'

  local single=$'
  . \
  ├── '"$proj_folder"'/ 
  └── '"$proj_folder"'-revs/'


  multiple=$(gum style --margin=0 --align=left --padding "1" --border=normal --width=40 --border-foreground 212 "$multiple")
  single=$(gum style --margin=0 --align=left --padding "3" --border=normal --width=40 --border-foreground 57 "$single")

  local examples=$(gum join  --align=center --horizontal "$multiple" "$single")
  
  gum join --align=center --vertical "$titles" "$examples"

  confirm_between_ "how do you prefer to manage the project: "$'\e[38;5;212m'multiple$'\e[0m'" or "$'\e[38;5;99m'single$'\e[0m'" mode? "$'\n'"\
      "$'\e[0m'"See the example above: "$'\n\e[0m'"       • Multiple mode creates a separate folder for each branch. "$'\n\e[0m'"       • Single mode manages all branches within a single folder." "multiple" "single" $2

}

function save_proj_mode_() {
  eval "$(parse_flags_ "save_proj_mode_" "ae" "$@")"
  (( save_proj_mode_is_d )) && set -x

  local i="$1"
  local proj_folder="$2"
  local single_mode="${PUMP_PROJECT_SINGLE_MODE[$i]}"

  if [[ -n "$single_mode" ]] && (( single_mode == 0 || single_mode == 1 )); then return 0; fi
    
  choose_mode_ "$proj_folder"
  RET=$?
  if (( RET == 130 )); then return 130; fi

  update_setting_ $i "PUMP_PROJECT_SINGLE_MODE" "$RET"

  if (( RET )); then
    print "  ${pink_cor}project mode:${reset_cor} single" >&1
  else
    print "  ${pink_cor}project mode:${reset_cor} multiple" >&1
  fi
}

function save_proj_folder_() {
  eval "$(parse_flags_ "save_proj_folder_" "are" "$@")"
  (( save_proj_folder_is_d )) && set -x

  local i="$1"
  local proj_repo="$2"

  local pkg_name=""

  if [[ -n "$proj_repo" ]]; then
    pkg_name="$(get_repo_name_ "$proj_repo" 1 2>/dev/tty)"
  fi

  local pkg_name_sanitized=$(sanitize_pkg_name_ "$pkg_name" 2>/dev/tty)

  local proj_folder=""
  local folder_exists=0
  local RET=0

  if (( save_proj_folder_is_e )); then
    if [[ -n "${PUMP_PROJECT_FOLDER[$i]}" ]]; then
      confirm_from_ "do you want to keep using project folder: "$'\e[94m'${PUMP_PROJECT_FOLDER[$i]}$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 0 )); then return 0; fi
    fi
    
    confirm_between_ "would you like create a new folder or use an existing folder?" "create new folder" "use existing folder"
    RET=$?
  elif [[ -z "$pkg_name_sanitized" ]]; then
    confirm_between_ "would you like to start from scratch or use an existing project?" "start from scratch" "use existing project"
    RET=$?
  fi

  if (( RET == 130 )); then return 1; fi
  if (( RET == 1 )); then
    folder_exists=1
    header="select the folder"
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

  if ! check_proj_folder_ $i "$proj_folder" "$pkg_name_sanitized"; then return 1; fi
  # clear_last_line_

  if (( folder_exists == 0 )); then
    proj_folder="${proj_folder}/$pkg_name_sanitized"

    if [[ ! -d "$proj_folder" ]]; then
      mkdir -p "$proj_folder"
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
  
  local proj_repo=""
  local RET=0

  if (( save_proj_repo_is_e )) && [[ -n "${PUMP_PROJECT_REPO[$i]}" ]]; then
    confirm_from_ "do you want to keep using repository: "$'\e[94m'${PUMP_PROJECT_REPO[$i]}$'\e[0m'" ?"
    RET=$?
    if (( RET == 130 )); then return 1; fi
    if (( RET == 0 )); then return 0; fi
  fi

  if is_git_repo_ "$proj_folder" &>/dev/null; then
    local _pwd="$(pwd)"
    cd "$proj_folder"
    remote_repo="$(git remote get-url origin 2>/dev/null)"
    RET=$?
    cd "$_pwd"

    if (( RET == 0 )) && [[ -n "$remote_repo" ]]; then
      confirm_from_ "do you want to use repository: "$'\e[94m'${remote_repo}$'\e[0m'" ?"
      RET=$?
      if (( RET == 130 )); then return 1; fi
      if (( RET == 0 )); then
        update_setting_ $i "PUMP_PROJECT_REPO" "$remote_repo"
        print "  ${pink_cor}project repository:${reset_cor} ${remote_repo}" >&1
        return 0;
      fi
    fi
  fi

  proj_repo=$(input_repo_ "type the repository uri (ssh or https)" "$proj_repo")
  if [[ -z "$proj_repo" ]]; then return 1; fi
  
  if ! check_proj_repo_ -s $i "$proj_repo" "$proj_folder";  then return 1; fi
  # clear_last_line_

  update_setting_ $i "PUMP_PROJECT_REPO" "$proj_repo"

  print "  ${pink_cor}project repository:${reset_cor} ${proj_repo}" >&1
}

function save_pkg_manager_() {
  eval "$(parse_flags_ "save_pkg_manager_" "ae" "$@")"
  (( save_pkg_manager_is_d )) && set -x

  local i="$1"
  local pkg_manager="$2"

  pkg_manager=($(choose_one_ 0 "choose package manager" 10 "npm" "yarn" "pnpm" "bun" "poe"))
  if [[ -z "$pkg_manager" ]]; then return 1; fi

  if ! check_proj_pkg_manager_ $i "$pkg_manager"; then return 1; fi
  # clear_last_line_

  update_setting_ $i "PUMP_PACKAGE_MANAGER" "$pkg_manager"
  
  print "  ${pink_cor}package manager:${reset_cor} ${pkg_manager}" >&1
}

function detect_pkg_manager_() {
  local folder="$1"

  local manager=""
  local pkg_json="package.json"
  local pyproject="pyproject.toml"

  folder=$(get_proj_folder_ "$folder" 2>/dev/null)
  
  if [[ -z "$folder" ]]; then
    return 1
  fi

  local _pwd="$(pwd)"

  cd "$folder"

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

  # 2. Parse `packageManager` field in package.json (npm >= v7)
  if [[ -z "$manager" && -f "$pkg_json" ]]; then
    # Grep for "packageManager" line and extract name before '@'
    local line
    line=$(grep -E '"packageManager"\s*:\s*"' "$pkg_json" | head -n 1)
    if [[ $line =~ \"packageManager\"\s*:\s*\"([^\"]+)\" ]]; then
      manager="${match[1]%%@*}"  # e.g., "pnpm@7.0.0" → "pnpm"
    fi
  fi

  if [[ -z "$manager" && -f "$pyproject" ]]; then
    if grep -qE '^\s*\[tool\.poe\.tasks\]' "$pyproject"; then
      manager="poe"
    fi
  fi

  # # 3. Fallback: check available binaries in system PATH
  # if [[ -z "$manager" ]]; then
  #   for bin in bun pnpm yarn npm; do
  #     if command -v "$bin" &>/dev/null; then
  #       manager="$bin"
  #       break
  #     fi
  #   done
  # fi

  cd "$_pwd"

  if [[ -z "$manager" ]]; then
    return 1
  fi

  echo "$manager"
}

function save_proj_() {
  # a - add, f - force, e - edit
  eval "$(parse_flags_ "save_proj_" "afe" "$@")"
  (( save_proj_is_d )) && set -x

  local i="$1"
  local pkg_name="$2"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    print " fatal: save_proj_ project index is invalid: $i"
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

  local proj_folder=""
  local proj_repo=""
  local pkg_manager=""
  local single_mode=""

  if (( save_proj_is_f )); then
    # for pro pwd, all the settings come from the pwd
    proj_folder="$(pwd)"
    update_setting_ $i "PUMP_PROJECT_FOLDER" "$proj_folder"
    
    if is_git_repo_ "$proj_folder" &>/dev/null; then
      proj_repo="$(git remote get-url origin 2>/dev/null)"
    else
      if ! save_proj_repo_ -a $i "$proj_folder"; then return 1; fi
      proj_repo="${PUMP_PROJECT_REPO[$i]}"
    fi
    update_setting_ $i "PUMP_PROJECT_REPO" "$proj_repo"

    pkg_manager="$(detect_pkg_manager_ "$proj_folder")"

    if [[ -n "$proj_repo" && -n "$pkg_manager" ]]; then
      update_setting_ $i "PUMP_PACKAGE_MANAGER" "$pkg_manager"
      single_mode=1
    fi

    update_setting_ $i "PUMP_PROJECT_SINGLE_MODE" "$single_mode"

  else
   if (( save_proj_is_a )); then
      PUMP_PROJECT_REPO[$i]=""
      PUMP_PROJECT_FOLDER[$i]=""

      while [[ -z "$PUMP_PROJECT_FOLDER[$i]" && -z "$PUMP_PROJECT_REPO[$i]" ]]; do
        if ! save_proj_repo_ -a $i "${PUMP_PROJECT_FOLDER[$i]}"; then return 1; fi
        if ! save_proj_folder_ -a $i "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi
      done
    else # edit
      if ! save_proj_repo_ -e $i "${PUMP_PROJECT_FOLDER[$i]}"; then return 1; fi
      if ! save_proj_folder_ -e $i "${PUMP_PROJECT_REPO[$i]}"; then return 1; fi
    fi
  
    if ! save_pkg_manager_ $i; then return 1; fi
    if ! save_proj_mode_ $i "${PUMP_PROJECT_FOLDER[$i]}"; then return 1; fi
  fi

  if ! save_proj_cmd_ $i "$pkg_name"; then return 1; fi

  display_line_ "" "${cor}"
  print "  ${cor}project saved!${reset_cor}" >&1

  if (( save_proj_is_f )); then
    eval "pro $PUMP_PROJECT_SHORT_NAME[$i]"
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
  check_proj_pkg_manager_ 0 "$CURRENT_PUMP_PACKAGE_MANAGER"
  if [[ -z "$CURRENT_PUMP_PACKAGE_MANAGER" ]]; then
    return 1;
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
  unset -f "$proj_arg" &>/dev/null

  update_setting_ $i "PUMP_PROJECT_SHORT_NAME" ""
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

function clear_curr_prj_() {
  load_config_entry_
  
  save_current_proj_ 0
}

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
  print "${solid_magenta_cor} PUMP_GHA_WORKFLOW_$i=${reset_cor}\"${PUMP_GHA_WORKFLOW[$i]}\""
  display_line_ "" "$dark_gray_cor"
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
  print "${pink_cor} CURRENT_PUMP_GHA_WORKFLOW=${reset_cor}\"$CURRENT_PUMP_GHA_WORKFLOW\""
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

  if ! get_proj_folder_ "$folder" 1>/dev/null; then return 2; fi

  return 0;
}

function get_proj_folder_() {
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

  if [[ -z "$1" ]]; then
    print " fatal: no argument provided" >&2
    return 2;
  fi

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

  if is_git_repo_ "$proj_folder/$default_folder" &>/dev/null; then    
    echo "$proj_folder/$default_folder"
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

function open_proj_for_git_() {
  local proj_folder="$1"

  if [[ -z "$1" ]]; then
    print " fatal: no argument provided" >&2
    return 1;
  fi

  local git_folder=$(get_proj_for_git_ "$proj_folder")

  if [[ -z "$git_folder" ]]; then
    print " not a git repository (or any of the parent directories): $proj_folder" >&2
    return 1;
  fi

  cd "$git_folder"
}

function get_proj_for_git_() {
  local proj_folder="$1"

  if is_git_repo_ "$proj_folder"; then
    print "$proj_folder"
    return 0;
  fi

  if [[ ! -d "$proj_folder" ]]; then
    return 1;
  fi

  local _pwd="$(pwd)"

  cd "$proj_folder"

  local folder=""
  local folders=("main" "master" "stage" "staging" "prod" "production" "release" "dev" "develop")

  # Loop through each folder name
  for defaultFolder in "${folders[@]}"; do
    if [[ -d "$defaultFolder" ]]; then
      if is_git_repo_ "$defaultFolder" &>/dev/null; then
        folder="$proj_folder/$defaultFolder"
        break;
      fi
    fi
  done

  # this is not a good idea, it could cause going into other projects
  # if [[ -z "$folder" ]]; then
  #   setopt null_glob
  #   local i=0
  #   for i in */; do
  #     if is_git_repo_ "${i%/}"; then
  #       folder="$proj_folder/${i%/}"
  #       break;
  #     fi
  #   done
  #   unsetopt null_glob
  # fi

  cd "$_pwd"

  if [[ -z "$folder" ]]; then
    return 1;
  fi

  echo "$folder"
}

function select_branch_() {
  # select_branch_ -a <search_text>
  local auto=${1:-0}
  local filter="$2"
  local searchText="$3"
  local multiple=${4:-0}
  local label=${5:-"choose a branch"}

  # $2 are flag options
  # $3 is the search string
  local branch_choices=""

  if [[ "$filter" == "--all" || "$filter" == "-a" ]]; then
    branch_choices=$(git branch --all --format="%(refname:short)" \
      | grep -v 'origin/' \
      | grep -v 'detached' \
      | grep -i "$searchText" \
      | sort -fu
    )
  elif [[ "$filter" == "-r" ]]; then
    branch_choices=$(git for-each-ref --format='%(refname:short)' refs/remotes \
      | grep -v '^origin/HEAD$' \
      | sed 's/^origin\///' \
      | grep -i "$searchText" \
      | sort -fu
    )
  else
    branch_choices=$(git branch --list --format="%(refname:short)" \
      | grep -v 'origin/' \
      | grep -v 'detached' \
      | grep -i "$searchText" \
      | sort -fu
    )
  fi
  
  if [[ -z "$branch_choices" ]]; then
    print " did not match any branch known to git: $3" >&2
    return 1;
  fi

  #$branch_choices=$(echo "$branch_choices" | sed -e 's/^[* ]*//g' | sed -e 's/HEAD//' | sed -e 's/remotes\///' | sed -e 's/HEAD -> origin\///' | sed -e 's/origin\///' | sort -fu)

  local select_branch_choice=""

  if (( multiple )); then
    select_branch_choice=$(choose_multiple_ 0 "choose branches" 20 $(echo "$branch_choices" | tr ' ' '\n'))
  else
    local branch_choices_count=$(echo "$branch_choices" | wc -l)
    
    if [[ $branch_choices_count -gt 20 ]]; then
      select_branch_choice=$(filter_one_ $auto "$label" "type to filter" $(echo "$branch_choices" | tr ' ' '\n'))
    else
      select_branch_choice=$(choose_one_ $auto "$label" 20 $(echo "$branch_choices" | tr ' ' '\n'))
    fi
  fi

  echo "$select_branch_choice"
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

  echo "$select_pr_choice|$select_pr_branch|$select_pr_title"

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
  
  local pkg_json="package.json"

  if [[ -f "$pkg_json" ]]; then
    local pkg_name;
    if command -v jq &>/dev/null; then
      pkg_name=$(jq -r --arg key "$key_name" '.[$key]' "$pkg_json")
    else
      pkg_name=$(grep "\"$key_name\"" "$pkg_json" | head -1 | sed -E "s/.*\"$key_name\": *\"([^\"]+)\".*/\1/")
    fi
    if [[ -n "$pkg_name" ]]; then
      echo "$pkg_name"
      return 0;
    fi
  fi
}

function load_config_entry_() {
  local i=${1:-0}

  keys=(
    PUMP_PROJECT_REPO
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

  for key in "${keys[@]}"; do
    value=$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")

    # If the value is not set, provide default values for specific keys
    if [[ -z "$value" ]]; then
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
          value="${PUMP_PACKAGE_MANAGER[$i]} run dev"
          ;;
        PUMP_RUN_STAGE)
          value="${PUMP_PACKAGE_MANAGER[$i]} run stage"
          ;;
        PUMP_RUN_PROD)
          value="${PUMP_PACKAGE_MANAGER[$i]} run prod"
          ;;
        PUMP_TEST)
          value="${PUMP_PACKAGE_MANAGER[$i]} run test"
          ;;
        PUMP_COV)
          value="${PUMP_PACKAGE_MANAGER[$i]} run test:coverage"
          ;;
        PUMP_TEST_WATCH)
          value="${PUMP_PACKAGE_MANAGER[$i]} run test:watch"
          ;;
        PUMP_E2E)
          value="${PUMP_PACKAGE_MANAGER[$i]} run test:e2e"
          ;;
        PUMP_E2EUI)
          value="${PUMP_PACKAGE_MANAGER[$i]} run test:e2e-ui"
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
      PUMP_PROJECT_REPO)
        PUMP_PROJECT_REPO[$i]="$value"
        ;;
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
      continue
    fi

    [[ -z "$proj_cmd" ]] && continue  # skip if not defined

    if ! check_proj_cmd_ $i "$proj_cmd"; then
      print "  in config data at PUMP_PROJECT_SHORT_NAME_${i}" >&2
      continue;
    fi

    PUMP_PROJECT_SHORT_NAME[$i]="$proj_cmd"

    # Set project folder path
    local proj_folder=""
    proj_folder=$(sed -n "s/^PUMP_PROJECT_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE")
    if (( $? != 0 )); then
      print " something is wrong with your config data at PUMP_PROJECT_FOLDER_${i}" >&2
      continue
    fi

    if [[ -n "$proj_folder" ]]; then
      if ! check_proj_folder_ $i "$proj_folder" "$proj_cmd"; then
        print "  error in config data at PUMP_PROJECT_FOLDER_${i}" >&2
      fi
    fi

    PUMP_PROJECT_FOLDER[$i]="$proj_folder"

    load_config_entry_ $i
  done
}

function activate_pro_() {
  # pro pwd
  if ! pro -f "pwd" 2>/dev/null; then
    # Read the current project short name from the PUMP_PRO_FILE if it exists
    pump_pro_file_value=""
    if [[ -f "$PUMP_PRO_FILE" ]]; then
      pump_pro_file_value=$(<"$PUMP_PRO_FILE")

      if [[ -n "$pump_pro_file_value" ]]; then
        local i=0
        for i in {1..9}; do
          if [[ "$pump_pro_file_value" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
            if ! check_proj_cmd_ $i "$pump_pro_file_value" &>/dev/null; then
              rm -f "$PUMP_PRO_FILE" &>/dev/null
              pump_pro_file_value=""
            fi
            break;
          fi
        done
      fi
    fi

    # Create an array of project names to loop through
    project_names=("$pump_pro_file_value")

    # Loop through 1 to 10 to add additional project names to the array
    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if [[ ! " ${project_names[@]} " =~ " ${PUMP_PROJECT_SHORT_NAME[$i]} " ]]; then
          project_names+=("${PUMP_PROJECT_SHORT_NAME[$i]}")
        fi
      fi
    done
    
    # Remove any empty values in the array (e.g., if $pump_pro_file_value is empty)
    project_names=("${project_names[@]/#/}")

    #print "project_names: ${project_names[@]}"

    # Loop over the projects to check and execute them
    for project in "${project_names[@]}"; do
      if [[ -n "$project" ]]; then
        #print " pro project: $project"
        if pro -f "$project" 2>/dev/null; then
          break;
        fi
      fi
    done
  fi
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

  if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc"
  fi
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
    print "  ${yellow_cor}del -a${reset_cor} : include hidden files"
    print "  ${yellow_cor}del -s${reset_cor} : skip confirmation"
    return 0;
  fi

  if ! command -v gum &>/dev/null; then
    print " del requires gum" >&2
    print " install gum:${blue_cor} https://github.com/charmbracelet/gum ${reset_cor}" >&2
    return 1;
  fi

  # local _pro="$PUMP_PROJECT_SHORT_NAME"
  # local proj_folder=""
  # local pump_working_branch=""

  # if [[ -n "$_pro" ]]; then
  #   for i in {1..9}; do
  #     if [[ "$_pro" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
  #       proj_folder="${PUMP_PROJECT_FOLDER[$i]}"
  #       pump_working_branch="${PUMP_WORKING[$i]}"
  #       break
  #     fi
  #   done
  # fi

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
            RET=$?
            if (( RET == 130 )); then
              return 130;
            fi
            if (( RET == 1 )); then
              continue;
            fi
          fi
        fi
  
        gum spin --title="deleting... $file" -- rm -rf "$file"
        print "${magenta_cor} deleted${blue_cor} $file ${reset_cor}"
      done
      #ls
    else
      print " no files"
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
      if (( ! del_is_s && _count < 3 )) && [[ ".DS_Store" != "$f" ]]; then
        if [[ -d "$f" && -n "$(ls -A "$f")" ]] || [[ ! -d "$f" ]]; then
          confirm_from_ "delete "$'\e[94m'$f$'\e[0m'" ?"
          RET=$?
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
          confirm_from_ "delete all $split_pattern"$'\e[0m'" ?"
          RET=$?
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
            confirm_from_ "delete "$'\e[94m'$f$'\e[0m'" ?"
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
  
      gum spin --title="deleting... $f" -- rm -rf "$f"
      print "${magenta_cor} deleted${blue_cor} $f ${reset_cor}"

    done

    unsetopt dot_glob null_glob
    return 0;
  fi
  
  unsetopt dot_glob null_glob

  local file_path=$(realpath "$1" 2>/dev/null) # also works: "${1/#\~/$HOME}"
  if (( $? != 0 )); then return 1; fi

  if [[ -z "$file_path" || ! -e "$file_path" ]]; then
    return 1;
  fi

  local folder_to_move=""

  if (( ! del_is_s )) && [[ ".DS_Store" != "$file_path" ]]; then
    if [[ -d "$file_path" && -n "$(ls -A "$file_path")" ]] || [[ ! -d "$file" ]]; then
      local confirm_msg=""

      if [[ "$file_path" == "$(pwd)" ]]; then
        folder_to_move="$(dirname "$file_path")"
        confirm_msg="delete current path "$'\e[94m'$(pwd)$'\e[0m'"?";
      else
        confirm_msg="delete "$'\e[94m'$file_path$'\e[0m'"?";
      fi

      if ! confirm_from_ $confirm_msg; then
        return 0;
      fi
    fi
  fi

  # local file_path_log=""

  # if [[ "$file_path" == "$(pwd)"* ]]; then # the file_path is inside the current path
  #   file_path_log=$(shorten_path_until_ "$file_path")
  # elif [[ -n "$CURRENT_PUMP_PROJECT_FOLDER" ]]; then
  #   file_path_log=$(shorten_path_until_ "$file_path" $(basename "$CURRENT_PUMP_PROJECT_FOLDER"))
  # fi

  # if [[ -d "$file_path" && -n "$pump_working_branch" && -n "$_pro" ]]; then
  #   delete_pump_working_ "$(basename "$file_path")" "$pump_working_branch" "$_pro"
  # fi

  gum spin --title="deleting... $file_path" -- rm -rf "$file_path"

  # if [[ -z "$file_path_log" ]]; then
  #   file_path_log="$file_path"
  # fi

  print "${magenta_cor} deleted${blue_cor} $file_path ${reset_cor}"

  if [[ -n "$folder_to_move" ]]; then
    cd "$folder_to_move"
  fi
}

# muti-task functions =========================================================
function refix() {
  eval "$(parse_flags_ "refix_" "" "$@")"
  (( refix_is_d )) && set -x

  if (( refix_is_h )); then
    print "  ${yellow_cor}refix${reset_cor} : to reset last commit then run fix lint and format then re-push"
    return 0;
  fi

  if ! is_proj_folder_ "$(pwd)" 1>/dev/null; then return 2; fi
  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  last_commit_msg=$(git log -1 --pretty=format:'%s' | xargs -0)
  
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
            break
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

  # local git_status=$(git status --porcelain 2>/dev/null)
  # if [[ -n "$git_status" ]]; then
  #   print " branch is not clean, cannot switch branches";
  #   return 1;
  # fi

  local proj_cmd="$CURRENT_PUMP_PROJECT_SHORT_NAME"
  local proj_folder=""
  local proj_repo=""
  local _setup=""
  local _clone=""
  local _cov=""
  local single_mode=""

  # find project settings
  if [[ -n "$proj_cmd" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_cmd" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_cmd"; then
          return 1;
        fi
        proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

        if ! check_proj_repo_ -s $i "$PUMP_PROJECT_REPO[$i]" "$proj_folder"; then
          return 1;
        fi
        proj_repo="${PUMP_PROJECT_REPO[$i]}"

        _setup="${PUMP_SETUP[$i]}"
        _clone="${PUMP_CLONE[$i]}"
        _cov="${PUMP_COV[$i]}"
        single_mode="${PUMP_PROJECT_SINGLE_MODE[$i]}"
        break
      fi
    done
  fi

  if [[ -z "$proj_folder" || -z "$proj_cmd" || -z "$proj_repo" ]]; then
    print " project settings are missing, specify a project, type ${yellow_cor}pro${reset_cor}" >&2
    return 1;
  fi

  if [[ -z "$_cov" || -z "$_setup" ]]; then
    print " PUMP_COV or PUMP_SETUP is missing for ${blue_cor}${proj_cmd}${reset_cor} - edit your pump.zshenv then run${yellow_cor} refresh ${reset_cor}" >&2
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

  # default_branch=$(git config --get init.defaultBranch);
  # if [[ -n "$default_branch" ]]; then
  #   git fetch origin $default_branch --quiet
  #   read behind ahead < <(git rev-list --left-right --count origin/$default_branch...HEAD)
  #   if [[ $behind -ne 0 || $ahead -ne 0 ]]; then
  #     print " warning: your branch is behind $default_branch by $behind commits and ahead by $ahead commits";
  #   fi
  # fi

  if (( single_mode )); then
    cov_folder=".$proj_folder-coverage"
  else
    cov_folder="$proj_folder/.coverage"
  fi

  RET=1

  if is_git_repo_ "$cov_folder" &>/dev/null; then
    pushd "$cov_folder" &>/dev/null

    git reset --hard --quiet origin
    git fetch origin --quiet
    git switch "$branch" --quiet &>/dev/null
    RET=$?
  else
    rm -rf "$cov_folder" &>/dev/null
    
    if gum spin --title="running test coverage on $branch..." -- git clone $proj_repo "$cov_folder" --quiet; then
      pushd "$cov_folder" &>/dev/null

      if [[ -n "$_clone" ]]; then
        eval "$_clone" &>/dev/null
      fi

      git switch "$branch" --quiet &>/dev/null
      RET=$?
    else
      RET=1
    fi
  fi

  if (( RET == 0 )); then
    git pull origin --quiet
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

  eval "$_setup" &>/dev/null

  is_delete_cov_folder=0;

  if [[ ! -d "coverage" ]]; then
    is_delete_cov_folder=1;
    mkdir -p coverage &>/dev/null
  fi

  if ! eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
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

  eval "$_setup" &>/dev/null

  if ! eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1; then
    eval "$_cov" --coverageReporters=text-summary > "coverage/coverage-summary.txt" 2>&1
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

  # do not copy to clipboard because it could be problematic since this takes so long to finish
  # {
  #   echo "#### Coverage"
  #   echo "| \`$1\` | \`${my_branch}\` |"
  #   echo "| --- | --- |"
  #   echo "| Statements: $(printf "%.2f" $statements1)% | Statements: $(printf "%.2f" $statements2)% |"
  #   echo "| Branches: $(printf "%.2f" $branches1)% | Branches: $(printf "%.2f" $branches2)% |"
  #   echo "| Functions: $(printf "%.2f" $funcs1)% | Functions: $(printf "%.2f" $funcs2)% |"
  #   echo "| Lines: $(printf "%.2f" $lines1)% | Lines: $(printf "%.2f" $lines2)% |"
  # } | pbcopy

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

function pr() {
  eval "$(parse_flags_ "pr_" "t" "$@")"
  (( pr_is_d )) && set -x

  if (( pr_is_h )); then
    print "  ${yellow_cor}pr${reset_cor} : to create a pull request"
    print "  ${yellow_cor}pr -t${reset_cor} : only if tests pass"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " pr requires gh" >&2
    print " install gh:${blue_cor} https://github.com/cli/cli ${reset_cor}" >&2
    return 1;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  # Initialize an empty string to store the commit details
  local commit_msgs=""
  local pr_title=""

  # Get the current branch name
  # HEAD_COMMIT=$(git merge-base f-WMG1-247-performanceView HEAD)
  # my_branch=$(git branch --show-current)
  # OPTIONS="--abbrev-commit HEAD"

   git log $(git merge-base HEAD $(git config --get init.defaultBranch))..HEAD --no-merges --oneline --pretty=format:'%H | %s' | xargs -0 | while IFS= read -r line; do
    local commit_hash=$(echo "$line" | cut -d'|' -f1 | xargs -0)
    local commit_message=$(echo "$line" | cut -d'|' -f2- | xargs -0)

    # # Check if the commit belongs to the current branch
    # if ! git branch --contains "$commit_hash" | grep -q "\b$my_branch\b"; then
    #   break;
    # fi

    local dirty_pr_title="$commit_message"
    local pattern='.*\b(fix|feat|docs|refactor|test|chore|style|revert)(\s*\([^)]*\))?:\s*'
    if [[ "$dirty_pr_title" =~ $pattern ]]; then
      pr_title="${dirty_pr_title/${match[0]}/}"
    else
      pr_title="$dirty_pr_title"
    fi

    pr_title="$dirty_pr_title"

    if [[ $dirty_pr_title =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then
      local ticket="${match[1]}"

      local trimmed="${ticket#"${str%%[![:space:]]*}"}"
      trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

      pr_title="$trimmed"
      
      if [[ $dirty_pr_title =~ [[:alnum:]]+-[[:digit:]]+(.*) ]]; then
        local rest="${match[1]}"
        trimmed="${rest#"${str%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

        pr_title="$pr_title$trimmed"
      fi
    fi

    # Add the commit hash and message to the list
    commit_msgs+="- $commit_hash - $commit_message"$'\n'

    # # Stop if the commit is the origin/HEAD commit
    # if [[ "$commit_hash" == "$HEAD_COMMIT" ]]; then
    #   break;
    # fi
  done

  if [[ ! -n "$commit_msgs" ]]; then
    print " no commits found, try${yellow_cor} push${reset_cor} first.";
    return 0;
  fi

  local pr_body="$commit_msgs"

  if [[ -f "$CURRENT_PUMP_PR_TEMPLATE" && -n "$CURRENT_PUMP_PR_REPLACE" ]]; then
    local pr_template=$(cat $CURRENT_PUMP_PR_TEMPLATE)

    if [[ $CURRENT_PUMP_PR_APPEND -eq 1 ]]; then
      # Append commit msgs right after CURRENT_PUMP_PR_REPLACE in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/(\Q$CURRENT_PUMP_PR_REPLACE\E)/\1\n\n$commit_msgs\n/")
    else
      # Replace CURRENT_PUMP_PR_REPLACE with commit msgs in pr template
      pr_body=$(echo "$pr_template" | perl -pe "s/\Q$CURRENT_PUMP_PR_REPLACE\E/$commit_msgs/g")
    fi
  fi

  if [[ -z "$CURRENT_PUMP_PR_RUN_TEST" ]]; then
    if confirm_from_ "run tests before pull request?"; then
      if ! test; then
        print "${solid_red_cor} tests are not passing,${reset_cor} did not push" >&2
        return 1;
      fi

      if confirm_from_ "save this preference and don't ask again?"; then
        local i=0
        for i in {1..9}; do
          if [[ "$CURRENT_PUMP_PROJECT_SHORT_NAME" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
            update_setting_ $i "PUMP_PR_RUN_TEST" 1
            break
          fi
        done
        print ""
      fi
    fi
  elif (( $CURRENT_PUMP_PR_RUN_TEST || pr_is_t )); then
    local git_status=$(git status --porcelain 2>/dev/null)
    if [[ -n "$git_status" ]]; then
      print " branch is not clean, cannot create pull request" >&2;
      return 1;
    else
      if ! test; then
        print "${solid_red_cor} tests are not passing,${reset_cor} did not push" >&2
        return 1;
      fi
    fi
  fi

  ## debugging purposes
  # print " pr_title:$pr_title"
  # print ""
  # print "$pr_body"
  # return 0;

  push $2

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ -n "$CURRENT_PUMP_PROJECT_REPO" ]]; then
    if [[ -z "$CURRENT_PUMP_LABEL_PR" || "$CURRENT_PUMP_LABEL_PR" -eq 0 ]]; then
      local labels=("none" "${(@f)$(gh label list --repo "$CURRENT_PUMP_PROJECT_REPO" --limit 25 | awk '{print $1}')}")
      local choose_labels=$(choose_multiple_ 0 "choose labels" 20 "${labels[@]}")
      if [[ -z "$choose_labels" ]]; then
        return 1;
      fi

      if [[ "$choose_labels" == "none" ]]; then
        gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch"
      else
        local choose_labels_comma="${(j:,:)${(f)choose_labels}}"
        gh pr create --assignee="@me" --title="$pr_title" --body="$pr_body" --web --head="$my_branch" --label="$choose_labels_comma"
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

  if [[ "$_env" == "stage" ]]; then
    _run="$CURRENT_PUMP_RUN_STAGE"
  elif [[ "$_env" == "prod" ]]; then
    _run="$CURRENT_PUMP_RUN_PROD"
  fi

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
          return 1;
        fi
        proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

        _run="${PUMP_RUN[$i]}"

        if [[ "$_env" == "stage" ]]; then
          _run="${PUMP_RUN_STAGE[$i]}"
        elif [[ "$_env" == "prod" ]]; then
          _run="${PUMP_RUN_PROD[$i]}"
        fi
        break
      fi
    done
  else
    proj_arg="$CURRENT_PUMP_PROJECT_SHORT_NAME"
  fi

  if [[ -z "$_run" ]]; then
    print " missing PUMP_RUN" >&2
    print " edit your pump.zshenv config, refresh then try again" >&2
    return 1;
  fi

  local folder_to_run=""

  if [[ -n "$folder_arg" && -n "$proj_folder" ]]; then
    if ! is_proj_folder_ "$proj_folder/$folder_arg" &>/dev/null; then return 2; fi

    folder_to_run="$proj_folder/$folder_arg"
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

  print " run $_env on ${gray_cor}$(shorten_path_ "$folder_arg") ${reset_cor}:${pink_cor} $_run ${reset_cor}"
  eval "$_run"
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

  if [[ -n "$proj_arg" ]]; then
    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
          return 1;
        fi
        proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

        _setup="${PUMP_SETUP[$i]:-${PUMP_PACKAGE_MANAGER[$i]} $([[ ${PUMP_PACKAGE_MANAGER[$i]} == "yarn" ]] && echo "" || echo "run ")setup}"
        break
      fi
    done

    if [[ -z "$proj_folder" ]]; then
      print " not a valid project: $proj_arg" >&2
      print " ${yellow_cor} setup -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -z "$_setup" ]]; then
    print " missing PUMP_SETUP" >&2
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
  eval "$_setup"
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
        break
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
      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"
      break
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

  if [[ -z "$rev_choices" ]]; then
    cd "$_pwd"
    print " no revs for $proj_folder" >&2
    print " ${yellow_cor} rev${reset_cor} to open a review" >&2
    return 1;
  fi

  local choice=$(gum choose --limit=1 --header " choose review to open:" $(echo "$rev_choices" | tr ' ' '\n'))

  if [[ -n "$choice" ]]; then
    rev "$proj_arg" "${choice//rev./}" 1>/dev/null
  fi

  cd "$_pwd"

  return 0;
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

      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      if ! check_proj_repo_ -s $i "${PUMP_PROJECT_REPO[$i]}" "$proj_folder"; then
        return 1;
      fi
      proj_repo="${PUMP_PROJECT_REPO[$i]}"

      _setup="${PUMP_SETUP[$i]}"
      _clone="${PUMP_CLONE[$i]}"
      code_editor="${PUMP_CODE_EDITOR[$i]}"
      single_mode=$PUMP_PROJECT_SINGLE_MODE[$i]
      break
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

  if ! open_proj_for_git_ "$proj_folder"; then return 2; fi

  if (( rev_is_e )); then
    if [[ -z "$branch_arg" ]]; then
      print " branch is required" >&2
      return 1;
    fi

    branch="$branch_arg"
  elif (( rev_is_b )); then
    fetch --quiet
    branch=$(select_branch_ 1 -r "$branch_arg");
    if [[ -z "$branch" ]]; then
      cd "$_pwd"
      return 1;
    fi
  else
    local pr=("${(@s:|:)$(select_pr_ "$branch_arg")}")
    if [[ -z "${pr[2]}" ]]; then
      cd "$_pwd"
      return 1;
    fi

    branch="${pr[2]}"
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

  if [[ -d "$full_rev_folder" ]]; then
    print " review already exist, opening${green_cor} $(shorten_path_ "$full_rev_folder") ${reset_cor} and pulling latest changes..."
  else
    local remote_branch=$(git ls-remote --heads origin "$branch" | awk '{print $2}')
    if [[ -z "$remote_branch" ]]; then
      print " branch not found in origin: $branch" >&2
      print " ${yellow_cor} rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    print " creating review for${green_cor} $select_pr_title${reset_cor}..."

    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo" -- git clone $proj_repo "$full_rev_folder" 1>/dev/tty; then return 1; fi
    else
      print " cloning... $proj_repo";
      if ! git clone $proj_repo "$full_rev_folder" --quiet; then return 1; fi
    fi
  fi

  pushd "$full_rev_folder" &>/dev/null
  
  local git_status=$(git status --porcelain 2>/dev/null)
  if [[ -n "$git_status" ]]; then
    if ! confirm_from_ "branch is not clean, discard all changes and pull?"; then
      return 1;
    fi
    reseta
  fi
  
  local warn_msg=""

  git checkout "$branch" --quiet
  
  if ! git pull origin --quiet; then
    is_open_editor=1
    warn_msg="${yellow_cor} warn: could not pull latest changes, probably already merged ${reset_cor}"
  fi

  local is_open_editor=0

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

  return 0;
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
        break
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

      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      if ! check_proj_repo_ -s $i "$PUMP_PROJECT_REPO[$i]" "$proj_folder"; then
        return 1;
      fi
      proj_repo="${PUMP_PROJECT_REPO[$i]}"

      if ! save_proj_mode_ $i "$proj_folder"; then return 1; fi

      single_mode="${PUMP_PROJECT_SINGLE_MODE[$i]}"
      _clone="${PUMP_CLONE[$i]}"
      default_branch="${PUMP_DEFAULT_BRANCH[$i]}"
      print_readme="${PUMP_PRINT_README[$i]}"
      break
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
    print "${solid_blue_cor} $proj_arg${reset_cor} already cloned in 'single mode': $proj_folder" >&2
    print "" >&2
    print " to clone a different branch, edit the project to 'multiple mode':" >&2
    print "  1. ${yellow_cor}pro -e ${proj_arg}${reset_cor}" >&2
    print "  2. then choose 'multiple' and save project" >&2
    return 1;
  fi

  if (( single_mode )); then
    branch_arg=$(get_clone_default_branch_ "$proj_repo" "$proj_folder" "$branch_arg");
    if [[ -z "$branch_arg" ]]; then
      return 0;
    fi

    if command -v gum &>/dev/null; then
      if ! gum spin --title="cloning... $proj_repo on $branch_arg" -- git clone $proj_repo "$proj_folder" --quiet; then return 1; fi
      print "   cloning... $proj_repo on $branch_arg"
    else
      print "  cloning... $proj_repo on $branch_arg"
      if ! git clone --quiet $proj_repo "$proj_folder"; then return 1; fi
    fi

    if ! pushd "$proj_folder" &>/dev/null; then return 1; fi

    git checkout "$branch_arg" --quiet &>/dev/null

    # if (( $? == 0 )); then
    #   save_pump_working_ "$proj_arg"
    # fi

    if [[ -n "$_clone" ]]; then
      print "  ${pink_cor}$_clone ${reset_cor}"
      eval "$_clone"
    fi

    if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
      # find readme file
      local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
      if [[ -n "$readme_file" ]]; then
        glow "$readme_file"
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
    if ! gum spin --title="cloning... $proj_repo on $branch_arg" -- git clone $proj_repo "$proj_folder/$branch_to_clone_folder" --quiet; then return 1; fi
    print "   cloning... $proj_repo on $branch_arg"
  else
    print "  cloning... $proj_repo on $branch_arg"
    if ! git clone --quiet $proj_repo "$proj_folder/$branch_to_clone_folder"; then return 1; fi
  fi

  # multiple mode

  local past_folder="$(pwd)"

  pushd "$proj_folder/$branch_to_clone_folder" &>/dev/null

  # if (( $? == 0 )); then
  #   save_pump_working_ "$proj_arg"
  # fi
  
  git config init.defaultBranch $default_branch

  if [[ "$branch_arg" != "$(git symbolic-ref --short HEAD 2>/dev/null)" ]]; then
    # check if branch exist
    local remote_branch=$(git ls-remote --heads origin "$branch_arg")
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
    eval "$_clone"
  fi

  if [[ $print_readme -eq 1 ]] && command -v glow &>/dev/null; then
    # find readme file
    local readme_file=$(find . -type f \( -iname "README*" -o -iname "readme*" \) | head -n 1);
    if [[ -n "$readme_file" ]]; then
      glow "$readme_file"
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

  if [[ -z "$1" ]]; then
    renb -h
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local old_name="$(git symbolic-ref --short HEAD 2>/dev/null)"

  git config branch."$1".gh-merge-base "$(git config --get branch."$old_name".gh-merge-base)" &>/dev/null
  
  git branch -m "$1" ${@:2}
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
  RET=$?

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

  git log -1 --pretty=format:'%s' | xargs -0
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

  git log -2 --pretty=format:'%s' | xargs -0
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

  git log -3 --pretty=format:'%s' | xargs -0
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

  git log -4 --pretty=format:'%s' | xargs -0
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

  git log -5 --pretty=format:'%s' | xargs -0
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
  eval "$(parse_flags_ "recommit_" "s" "$@")"
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
    print " last commit is a merge commit, won't do, create a new commit instead" >&2
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
              break
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
      git --no-pager log -1 --pretty=format:'%H %s' | xargs -0
      git log -1 --pretty=format:'%H %s' | pbcopy
    fi
  fi
}

function fetch() {
  eval "$(parse_flags_ "fetch_" "" "$@")"
  (( fetch_is_d )) && set -x

  if (( fetch_is_h )); then
    print "  ${yellow_cor}fetch${reset_cor} : to fetch all branches and reachable tags"
    print "  ${yellow_cor}fetch <branch>${reset_cor} : to fetch a branch"
    print "  ${yellow_cor}fetch -t${reset_cor} : to fetch all tags along with branches"
    print "  ${yellow_cor}fetch -to${reset_cor} : to fetch all tags only"
    print "  ${yellow_cor}fetch -a${reset_cor} : to fetch all remotes"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  RET=0;

  if (( fetch_is_t )); then 
    git fetch --all --tags --prune-tags --force
    RET=$?
    if (( pull_is_o )); then
      return $RET;
    fi
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    git fetch origin "$1" --prune ${@:2}
    RET=$?
  elif (( fetch_is_a )); then
    git fetch --all --prune $@
    RET=$?
  else
    git fetch origin
    RET=$?
  fi

  local current_branches=$(git branch --format '%(refname:short)')

  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    if ! echo "$current_branches" | grep -q "^$branch_name$"; then
      git config --remove-section "branch."$branch_name"" &>/dev/null
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
    print "  ${yellow_cor}glog${reset_cor} : to log last 15 commits"
    print "  ${yellow_cor}glog ${solid_yellow_cor}-n${reset_cor} : to log last n commits"
    return 0;
  fi

  local _pwd="$(pwd)";

  if ! open_proj_for_git_ "$(pwd)"; then return 2; fi

  git --no-pager log main HEAD --decorate --oneline --graph --date=relative $@
  RET=$?

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

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot push" >&2
    return 1;
  fi

  git push --no-verify --set-upstream origin "$my_branch" $@
  RET=$?

  if (( RET != 0 && quiet == 0 )); then
    if confirm_from_ "failed, try push force with lease?"; then
      pushf $@
      return $?;
    fi
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    if [[ -n "$my_branch" ]]; then
      print ""
      git --no-pager log "origin/${my_branch}@{1}..origin/${my_branch}" --decorate --oneline
      git log -1 --pretty=format:'%H %s' | pbcopy
    fi
  fi

  return $RET;
}

function pushf() {
  eval "$(parse_flags_ "pushf_" "ft" "$@")"
  (( pushf_is_d )) && set -x

  if (( pushf_is_h )); then
    print "  ${yellow_cor}pushf${reset_cor} : to force push with lease no-verify"
    print "  ${yellow_cor}pushf -f${reset_cor} : to regular push with force"
    print "  ${yellow_cor}pushf -t${reset_cor} : to push tags"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  if (( pushf_is_t && pushf_is_f )); then
    git push --no-verify --tags --force $@
    RET=$?
  fi

  if (( pushf_is_t )); then
    git push --no-verify --tags $@
    RET=$?
  fi

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ -z "$my_branch" ]]; then
    print " branch is detached, cannot push force" >&2
    return 1;
  fi

  if (( pushf_is_f )); then
    git push --no-verify --force origin "$my_branch" $@
    RET=$?
  else
    git push --no-verify --force-with-lease origin "$my_branch" $@
    RET=$?
  fi

  if (( RET == 0 && ! ${argv[(Ie)--quiet]} )); then
    if [[ -n "$my_branch" ]]; then
      print ""
      git --no-pager log "origin/${my_branch}@{1}..origin/${my_branch}" --decorate --oneline
      git log -1 --pretty=format:'%H %s' | pbcopy
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
  
  fetch --quiet

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
      git tag --delete "$tag"
      git push origin --delete "$tag" ${@:2}
      RET=$?
    done
    cd "$_pwd"
    return $RET;
  fi

  if ! git tag --delete "$1"; then
    cd "$_pwd"
    return 1;
  fi

  git push origin --delete "$1"
  RET=$?

  cd "$_pwd"

  return $RET;
}

function pull() {
  eval "$(parse_flags_ "pull_" "to" "$@")"
  (( pull_is_d )) && set -x

  if (( pull_is_h )); then
    print "  ${yellow_cor} pull ${solid_yellow_cor}[<branch>]${reset_cor} : to pull from origin branch"
    print "  ${yellow_cor} pull -t${reset_cor} : to pull all tags along with branches"
    print "  ${yellow_cor} pull -to${reset_cor} : to pull all tags only"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  (( quiet = pull_is_t || ${argv[(Ie)--quiet]} ))

  local RET=0;

  if (( pull_is_t )); then
    git pull origin --tags $@
    RET=$?
    if (( pull_is_o )); then
      return $RET;
    fi
  fi

  if [[ -n "$1" && $1 != -* ]]; then
    git pull origin "$1" --rebase --autostash ${@:2}
    RET=$?
  else
    git pull origin --rebase --autostash $@
    RET=$?
  fi

  if (( RET == 0 && quiet == 0 )); then
    print ""
    git --no-pager log -1 --decorate --oneline
    #git log -1 --pretty=format:'%H' | pbcopy
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
    print "  ${yellow_cor}  -s${reset_cor} : skip confirmation"
    print "  --"
    print "  ${yellow_cor}  -m${reset_cor} : major release"
    print "  ${yellow_cor}  -n${reset_cor} : minor release"
    print "  ${yellow_cor}  -p${reset_cor} : patch release"
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
    print " uncommitted changes detected, cannot proceed" >&2
    st
    return 1
  fi

  local current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  # check if name is conventional
  if ! [[ "$current_branch" =~ ^(main|master|stage|staging|pro|production|release)$ || "$current_branch" == release* ]]; then
    print " warning: unconventional branch to release: $current_branch"
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
    if ! confirm_from_ "create release: \"$tag\" ?"; then
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

  # check if tag already exists
  local tag_exists=$(git tag --list "$tag" 2>/dev/null)
  if [[ -n "$tag_exists" ]]; then
    if (( ! release_is_s )); then
      if ! confirm_from_ "$tag already exists, delete tag and create again?"; then
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
  RET=$?
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
  RET=$?

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

  git reset --hard
  RET=$?

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

  # check if current branch exists in remote
  local remote_branch=$(git ls-remote --heads origin "$(git symbolic-ref --short HEAD 2>/dev/null)")

  RET=0;

  if [[ -n "$remote_branch" ]]; then
    git reset --hard "origin/$(git symbolic-ref --short HEAD 2>/dev/null)"
    RET=$?
  else
    git reset --hard
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
  RET=$?
  
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
  RET=$?
  
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
    print "⚠️${yellow_cor} workflow not found ${reset_cor}" >&2
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

    local repo="$(get_repo_name_ "$(git remote get-url origin)")"

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
        break
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
        break
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

  local i=0
  for i in {1..9}; do
    if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
      if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_arg"; then
        return 1;
      fi
      proj_folder="${PUMP_PROJECT_FOLDER[$i]}"

      gha_interval="${PUMP_GHA_INTERVAL[$i]}"
      gha_workflow="${PUMP_GHA_WORKFLOW[$i]}"
      break
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

  RET=0

  if (( ! gha_is_a )); then
    print " checking workflow${purple_cor} $workflow_arg${reset_cor}..."
    gha_ "$workflow_arg"
    RET=$?
  else
    if [[ -z "$gha_interval" ]]; then
      gha_interval=10
    fi

    print " running every $gha_interval minutes, press cmd+c to stop"
    print ""

    while true; do
      print " checking workflow${purple_cor} $workflow_arg${reset_cor}..."

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
      local i=0
      for i in {1..9}; do
        if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          update_setting_ $i "PUMP_GHA_WORKFLOW" "\"$workflow_arg\""
          break
        fi
      done
    fi
    return 0;
  fi
}

function co() {
  eval "$(parse_flags_ "co_" "aprebxlc" "$@")"
  (( co_is_d )) && set -x

  if (( co_is_h )); then
    print "  ${yellow_cor}co ${solid_yellow_cor}[<branch>]${reset_cor} : to switch to a branch"
    print "  ${yellow_cor}co -l${reset_cor} : to switch to a local branch"
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
    if [[ -n "${pr[1]}" ]]; then
      print " detaching pull request: ${pr[3]}"
      print "  ${yellow_cor}co -b <branch>${reset_cor} to create branch"
      
      gh pr checkout --force --detach ${pr[1]}
      return $?;
    fi

    return 0;
  fi

  # co -a all branches
  if (( co_is_a )); then
    fetch --quiet
    local branch_choice="$(select_branch_ 1 --all "$1")"
    
    if [[ -z "$branch_choice" ]]; then
      return 1;
    fi

    co -e $branch_choice
    return $?
  fi

  # co -l local branches
  if (( co_is_l )); then
    fetch --quiet
    local branch_choice="$(select_branch_ 1 --list "$1")"
    
    if [[ -z "$branch_choice" ]]; then
      return 1;
    fi

    co -e $branch_choice
    return $?
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

    base_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

    fetch --quiet
    
    RET=0;
    if [[ -n "$base_branch" ]]; then
      git checkout -b "$branch" "origin/$base_branch"
      RET=$?
    else
      git checkout -b "$branch"
      RET=$?
      if (( RET == 0 )); then
        base_branch="$(git config --get init.defaultBranch)"
      fi
    fi

    if (( RET != 0 )); then return 1; fi

    ll_add_node_

    local remote_branch=$(git ls-remote --heads origin "$base_branch" | awk '{print $2}')
    if [[ -n "$remote_branch" ]]; then
      git config branch."$branch".gh-merge-base "$remote_branch"
    else
      git config branch."$branch".gh-merge-base "$base_branch"
    fi

    return 0;
  fi

  # co -e branch just checkout, do not create branch
  if (( co_is_e )); then
    local branch="$1"

    if [[ -z "$branch" ]]; then
      print " branch is required" >&2
      return 1;
    fi
    
    local current_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    local _past_folder="$(pwd)"

    git switch "$branch" --quiet
    RET=$?

    if (( RET == 0 )); then
      ll_add_node_
    fi

    return $RET;
  fi

  # co (no arguments)
  if [[ -z "$1" || -z "$2" ]]; then
    co -a "$1"
    return $?;
  fi

  # co branch BASE_BRANCH (creating branch)
  local branch="$1"
  
  fetch --quiet

  local base_branch="$(select_branch_ 1 --all "$2" 0 "choose a base branch")"
  if [[ -z "$base_branch" ]]; then
    return 1;
  fi

  if ! git checkout -b "$branch" "$base_branch"; then return 1; fi

  ll_add_node_

  local remote_branch=$(git ls-remote --heads origin "$base_branch" | awk '{print $2}')
  if [[ -n "$remote_branch" ]]; then
    git config branch."$branch".gh-merge-base "$remote_branch"
  else
    git config branch."$branch".gh-merge-base "$base_branch"
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

function dev() {
  # checkout dev or develop branch
  eval "$(parse_flags_ "dev_" "" "$@")"
  (( dev_is_d )) && set -x

  if (( dev_is_h )); then
    print "  ${yellow_cor}dev${reset_cor} : to switch to dev or develop in current project"
    return 0;
  fi

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
  eval "$(parse_flags_ "rebase_" "p" "$@")"
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

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ "$my_branch" == "$rebase_branch" ]]; then
    print " cannot rebase, branches are the same" >&2
    return 1;
  fi

  git fetch origin --quiet
  RET=$?

  print " rebase on branch${pink_cor} $rebase_branch ${reset_cor}"

  if [[ -n "$1" && $1 != -* ]]; then
    git rebase origin/"$rebase_branch" ${@:2}
    RET=$?
  else
    print "hey: git rebase origin/"$rebase_branch" $@"
    git rebase origin/"$rebase_branch" $@
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

  local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"

  if [[ "$my_branch" == "$merge_branch" ]]; then
    print " cannot merge, branches are the same" >&2
    return 1;
  fi

  git fetch origin --quiet
  RET=$?

  print " merge from branch${pink_cor} $merge_branch ${reset_cor}"

  if [[ -n "$1" && $1 != -* ]]; then
    git merge origin/"$merge_branch" --no-edit ${@:2}
    RET=$?
  else
    git merge origin/"$merge_branch" --no-edit $@
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

  # delets all tags
  git tag -l | xargs git tag -d 1>/dev/null
  # fetch tags that exist in the remote
  git fetch origin --prune --prune-tags --force
  
  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely deleted without losing any unmerged work and filters out the default branch
  local branches=$(git branch --merged | grep -v "^\*\\|$default_main_branch")

  for branch in $branches; do
    git config --remove-section branch."$branch" &>/dev/null
    git branch -D "$branch"
  done

  local current_branches=$(git branch --format '%(refname:short)')

  # Loop through all Git config sections to find old branches
  for config in $(git config --get-regexp "^branch\." | awk '{print $1}'); do
    local branch_name="${config#branch.}"

    # Check if the branch exists locally
    if ! echo "$current_branches" | grep -q "^$branch_name$"; then
      git config --remove-section "branch."$branch_name"" &>/dev/null
    fi
  done

  git prune $@
}

function delb() {
  eval "$(parse_flags_ "delb_" "s" "$@")"
  (( delb_is_d )) && set -x

  if (( delb_is_h )); then
    print "  ${yellow_cor}delb${solid_yellow_cor} [<branch>]${reset_cor} : to find branches to delete"
    print "  ${yellow_cor}delb <branch>${solid_yellow_cor} [<branch>]${reset_cor} : to find branches to delete"
    print "  ${yellow_cor}delb -s${reset_cor} : skip confirmation"
    return 0;
  fi

  if ! is_git_repo_ "$(pwd)"; then return 2; fi

  local branch_arg="$1"
  local is_deleted=1;

  RET=0;

  local selected_branches=($(select_branch_ 0 --list "$branch_arg" 1))
  for branch in ${selected_branches[@]}; do
    if (( ! delb_is_s )); then
      local confirm_msg="delete local branch: "$'\e[0;95m'$branch$'\e[0m'"?"
      confirm_from_ $confirm_msg
      RET=$?
      if (( RET == 130 )); then
        break;
      elif (( RET == 1 )); then
        continue;
      fi
    fi

    git config --remove-section branch."$branch" &>/dev/null
    git branch -D "$branch"
    is_deleted=$?
  done

  if (( ! is_deleted )); then
    delete_pump_workings_ "$pump_working_branch" "$proj_arg" "$selected_branches"
  fi

  cd "$_pwd"

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
  eval "$(parse_flags_ "pro_" "aerusf" "$@")"
  (( pro_is_d )) && set -x

  if (( pro_is_h )); then
    print "  ${yellow_cor}pro <pro>${reset_cor} : to set a project"
    print "  ${yellow_cor}pro -a <pro>${reset_cor} : to add a new project"
    print "  ${yellow_cor}pro -e <pro>${reset_cor} : to edit a project"
    print "  ${yellow_cor}pro -r <pro>${reset_cor} : to remove a project"
    print "  ${yellow_cor}pro -u <pro>${reset_cor} : to unset project"
    print "  ${yellow_cor}pro -s <pro>${reset_cor} : to show project data"
    
    if [[ -n "${PUMP_PROJECT_SHORT_NAME[*]}" ]]; then
      print ""
      print -n " projects: ${blue_cor} "
      local i=0
      for i in {1..9}; do
        if [[ -n "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          print -n "${PUMP_PROJECT_SHORT_NAME[$i]}"
          local j=$(( i + 1 ))
          if [[ -n "${PUMP_PROJECT_SHORT_NAME[$j]}" ]]; then
            print -n ", "
          fi
        fi
      done
      print "${reset_cor}"
    fi
    return 0;
  fi

  local proj_arg="$1"

  if (( pro_is_s )); then
    # show project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to show" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        print_current_proj_ $i
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # CRUD operations
  if (( pro_is_e )); then
    # edit project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to edit" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
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
    print " ${yellow_cor} pro -a $proj_arg${reset_cor} to add project" >&2
    return 1;
  fi
  
  if (( pro_is_a )); then
    # add project
    local i=0
    for i in {1..9}; do
      if [[ -z "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        save_proj_ -a $i "$proj_arg"
        return $?;
      fi
    done

    print " no more slots available, please remove one to add a new one" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    
    return 1;
  fi

  if (( pro_is_r )); then
    # remove project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to delete" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        if remove_prj_ $i; then
          print " project removed: $proj_arg"
        fi
        
        if [[ "$proj_arg" == "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
          clear_curr_prj_
          activate_pro_
        fi
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi # end of delete

  if (( pro_is_u )); then
    # unset project
    if [[ -z "$proj_arg" ]]; then
      print " provide a project name to unset" >&2
      print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
        # unset aliases
        clear_curr_prj_
        return 0;
      fi
    done

    print " project not found: $proj_arg" >&2
    print " ${yellow_cor} pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -z "$proj_arg" ]]; then
    pro -h
    return 0;
  fi

  # pro pwd
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg=$(which_pro_pwd_);

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      if ! is_proj_folder_ "$(pwd)" &>/dev/null; then return 1; fi
      
      local pkg_name="$(get_from_pkg_json_ "name")"
      local proj_cmd=$(sanitize_pkg_name_ "$pkg_name")
      local proj_repo="$(git remote get-url origin 2>/dev/null)"

      local i=0 found=0 empty=0
      for i in {1..9}; do
        if [[ "$proj_repo" == "${PUMP_PROJECT_REPO[$i]}" || "$proj_cmd" == "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          found=$i
        fi
        if [[ $empty -eq 0 && -z "${PUMP_PROJECT_SHORT_NAME[$i]}" ]]; then
          empty=$i
        fi
      done
    
      local action="add"
      if (( found )); then
        action="edit"
      fi

      if confirm_from_ "$action this project: "$'\e[38;5;201m'"$pkg_name"$'\e[0m'" ?"; then
        if (( found )); then
          save_proj_ -fe $found "$pkg_name"
        else
          save_proj_ -fa $empty "$pkg_name"
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
  
  local is_refresh=1

  if [[ "$proj_arg" == "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    is_refresh=0
  fi

  # set the current project
  save_current_proj_ $i

  if (( is_refresh )); then
    print " project set to: ${solid_blue_cor}$CURRENT_PUMP_PROJECT_SHORT_NAME${reset_cor} with ${solid_magenta_cor}$CURRENT_PUMP_PACKAGE_MANAGER${reset_cor}"

    echo "$CURRENT_PUMP_PROJECT_SHORT_NAME" > "$PUMP_PRO_FILE"
    
    export CURRENT_PUMP_PROJECT_SHORT_NAME="$CURRENT_PUMP_PROJECT_SHORT_NAME"

    if [[ -n "$CURRENT_PUMP_PRO" ]]; then
      eval "$CURRENT_PUMP_PRO"
    fi

    unset_aliases_
    set_aliases_
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

  if ! check_proj_folder_ -s $i "${PUMP_PROJECT_FOLDER[$i]}" "$proj_cmd"; then
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

  # resolve folder_arg
  if (( single_mode )); then
    folder_arg="$proj_folder"
  else
    if [[ -n "$folder_arg" && -d "${proj_folder}/${folder_arg}" ]]; then
      (( ! use_default_folder )) && folder_arg="${proj_folder}/${folder_arg}"
    else
      folder_arg="$proj_folder"
      
      local dirs=($(get_folders_ "$proj_folder"))
      
      if (( ${#dirs[@]} )); then
        local chosen_folder=($(choose_one_ 1 "choose folder to open" 20 "${dirs[@]}"))
        
        if [[ -n "$chosen_folder" ]]; then
          folder_arg="${proj_folder}/${chosen_folder}"
        fi
      fi
    fi
  fi

  pro "$proj_cmd"

  if [[ -z "$folder_arg" ]]; then return 1; fi
  
  if ! pushd "$folder_arg" &>/dev/null; then return 1; fi

  local dirs=($(get_folders_ "$proj_folder"))
  if (( ! ${#dirs[@]} )); then
    print " now type ${yellow_cor}clone ${proj_cmd}${reset_cor} to get started by cloning your first project."
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
      git stash pop --index "${stashes[i]}" || break
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
  eval "$(parse_flags_ "commit_" "a" "$@")"
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
            break
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

    local type_commit=$(gum choose "fix" "feat" "docs" "refactor" "test" "chore" "style" "revert")
    if [[ -z "$type_commit" ]]; then
      return 0;
    fi

    # scope is optional
    scope_commit=$(gum input --placeholder "scope")
    if (( $? != 0 )); then
      return 0;
    fi
    if [[ -n "$scope_commit" ]]; then
      scope_commit="($scope_commit)"
    fi

    local msg_arg=""

    msg_arg="$(gum input --value "${type_commit}${scope_commit}: ")"
    if (( $? != 0 )); then
      return 0;
    fi

    local my_branch="$(git symbolic-ref --short HEAD 2>/dev/null)"
    
    if [[ $my_branch =~ ([[:alnum:]]+-[[:digit:]]+) ]]; then # [A-Z]+-[0-9]+
      local ticket="${match[1]} "
      local skip=0;

      git log -n 10 --pretty=format:"%h %s" | while read -r line; do
        commit_hash=$(echo "$line" | awk '{print $1}')
        message=$(echo "$line" | cut -d' ' -f2-)

        if [[ "$message" == "$ticket"* ]]; then
          skip=1;
          break;
        fi
      done

      if [[ $skip -eq 0 ]]; then
        msg_arg="$ticket $commit_msg"
      fi
    fi

    git commit --no-verify --message "$msg_arg" $@
  else
    git commit --no-verify --message "$1" ${@:2}
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

  if [[ -n "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    print ""
    print "  your project is set to:${solid_blue_cor} $CURRENT_PUMP_PROJECT_SHORT_NAME${reset_cor} with${solid_magenta_cor} $CURRENT_PUMP_PACKAGE_MANAGER ${reset_cor}"
    print "  type:${solid_blue_cor} pro${reset_cor} -h for usage"
  fi

  if [[ -z "$CURRENT_PUMP_PROJECT_FOLDER" || -z "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
    print ""
    save_proj_ -a 1

    if [[ -z "$CURRENT_PUMP_PROJECT_FOLDER" || -z "$CURRENT_PUMP_PROJECT_SHORT_NAME" ]]; then
      print ""
      print " configure${solid_yellow_cor} $PUMP_CONFIG_FILE${reset_cor} as shown in the example below:"
      print ""
      print " PUMP_PROJECT_SHORT_NAME_1=${PUMP_PROJECT_SHORT_NAME[1]:-pump}"
      print " PUMP_PROJECT_FOLDER_1=${PUMP_PROJECT_FOLDER[1]:-"$HOME/pump-zsh"}"
      print ""
      print " then restart your terminal, then type${yellow_cor} help${reset_cor} again"
      print ""
    else
      refresh
      print " now run${yellow_cor} help${reset_cor} again"
    fi
    return 0;
  fi
  
  print ""
  display_line_ "get started" "${blue_cor}"
  print ""
  print "  1. set a project, type:${blue_cor} pro${reset_cor}"
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

  max=53
  if (( ${#_setup} > $max )); then
    # print " ${blue_cor} setup ${reset_cor}\t = ${_setup[1,$max]}"
    print " ${blue_cor} setup ${reset_cor}\t = run PUMP_SETUP"
  else
    print " ${blue_cor} setup ${reset_cor}\t = $_setup"
  fi
  if (( ${#CURRENT_PUMP_RUN} > $max )); then
    print " ${blue_cor} run ${reset_cor}\t\t = run PUMP_RUN"
  else
    print " ${blue_cor} run ${reset_cor}\t\t = $CURRENT_PUMP_RUN"
  fi
  if (( ${#CURRENT_PUMP_RUN_STAGE} > $max )); then
    print " ${blue_cor} run stage ${reset_cor}\t = run PUMP_RUN_STAGE"
  else
    print " ${blue_cor} run stage ${reset_cor}\t = $CURRENT_PUMP_RUN_STAGE"
  fi
  if (( ${#CURRENT_PUMP_RUN_PROD} > $max )); then
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
  print " ${solid_cyan_cor} reseta ${reset_cor}\t = reset hard origin + clean"
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
  print " ${solid_cyan_cor} fetch ${reset_cor}\t = fetch from origin"
  print " ${solid_cyan_cor} pull ${reset_cor}\t\t = pull all branches from origin"

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
  print " ${solid_cyan_cor} push ${reset_cor}\t\t = push all no-verify to origin"
  print " ${solid_cyan_cor} pushf ${reset_cor}\t = push force all to origin"
  
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

function validate_proj_cmd_() {
  local proj_cmd="$1"
  local qty=${2:-12}

  local error_msg=""

  if [[ -z "$proj_cmd" ]]; then
    error_msg="project name is missing"
  elif ! [[ "$proj_cmd" =~ ^[a-z0-9][a-z0-9-]*$ && ${#typed_value} -le $qty ]]; then
    error_msg="project name is invalid: no special characters, $qty max"
  else
    local invalid_proj_cmds=(
      "main" "master" "stage" "staging" "prod" "release"
      "yarn" "npm" "pnpm" "bun" "back" "add" "new" "remove" "rm" "install" "cd" "uninstall" "update" "init" "pushd" "popd" "ls" "dir" "ll"
      "pro" "rev" "revs" "clone" "setup" "run" "test" "testw" "covc" "cov" "e2e" "e2eui" "recommit" "refix" "clear"
      "rdev" "dev" "stage" "prod" "gha" "pr" "push" "repush" "pushf" "add" "commit" "build" "i" "ig" "deploy" "fix" "format" "lint"
      "tsc" "start" "sbb" "sb" "renb" "co" "reseta" "clean" "delb" "prune" "discard" "restore"
      "st" "gconf" "fetch" "pull" "glog" "gll" "glr" "reset" "resetw" "reset1" "reset2" "reset3" "reset4" "reset5" "reset6"
      "dtag" "tag" "tags" "pop" "stash" "stashes" "rebase" "merge" "rc" "conti" "mc" "chp" "chc" "abort"
      "cl" "del" "help" "kill" "nver" "nlist" "path" "refresh" "pwd" "empty" "upgrade" "quiet" "skip" "." ".."
    )

    if [[ " ${invalid_proj_cmds[@]} " =~ " $proj_cmd " || "$proj_cmd" == -* ]]; then
      error_msg="project name is invalid"
    else
      # check for duplicates across other indices
      for j in {1..10}; do
        if [[ $j -ne $i && "${PUMP_PROJECT_SHORT_NAME[$j]}" == "$proj_cmd" ]]; then
          error_msg="project name already in use"
          break;
        fi
      done
    fi
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
    eval "${PUMP_PROJECT_SHORT_NAME[$i]}() { proj_handler_ $i \"\$@\"; }"
  fi
done

activate_pro_ # set project


# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs