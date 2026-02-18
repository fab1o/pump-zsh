#!/usr/bin/env zsh

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
typeset -g purple_cor=$'\e[38;5;105m'
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
typeset -g bold_orange_cor=$'\e[1;38;5;208m'

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
typeset -g script_cor="$pink_cor"

typeset -g TAB=$'\x1F'

typeset -g PUMP_VERSION="0.0.0"
typeset -g PUMP_VERSION_FILE="$(dirname -- "$0")/.version"
typeset -g PUMP_CONFIG_FILE="$(dirname -- "$0")/config/pump.zshenv"
typeset -g PUMP_SETTINGS_FILE="$(dirname -- "$0")/config/pump.set.zshenv"

typeset -g invalid_opts is_debug is_invalid

if [[ -f "$PUMP_VERSION_FILE" ]]; then
  PUMP_VERSION="$(<"$PUMP_VERSION_FILE")"
fi

function parse_flags_proj_handler_() {
  if [[ -n "$4" && $4 != -* ]]; then    
    parse_flags__ "$1" "$2$3" "all" "" "${@:4}"
  else
    parse_flags__ "$1" "$2" "all" "" "${@:4}"
  fi
}

function parse_flags_() {
  parse_flags__ "$1" "$2$3" "$3" "" "${@:4}"
}

function parse_flags_hidden_() {
  parse_flags__ "$1" "$2$3" "$3" "$4" "${@:5}"
}

function parse_flags_all_() {
  parse_flags__ "$1" "$2" "all" "" "${@:3}"
}

function parse_flags__() {
  set +x

  if [[ -z "$1" ]]; then
    print " ${red_cor}internal error: parse_flags__ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix_arg="$1"
  local valid_flags="h$2"
  local valid_flags_pass_along="$3"
  local hidden_flags="$4"

  shift 4

  typeset -g is_debug

  local internal_func=0

  if [[ "$prefix_arg" =~ _$ ]]; then
    internal_func=1
    prefix="${prefix_arg%_}"
  else
    invalid_opts=()
    prefix="${prefix_arg}"
  fi

  if [[ -n "$hidden_flags" ]]; then
    valid_flags_pass_along="all"
  fi

  local double_flags=()
  local flags=()
  local non_flags=()
  local flags_double_dash=()

  if (( is_debug )); then
    echo "is_debug=1"
    echo "${prefix}_is_debug=1"
  else
    echo "${prefix}_is_debug=0"
  fi

  local opt=""
  for opt in {a..z}; do
    echo "${prefix}_is_$opt=0"
    echo "${prefix}_is_${opt}_${opt}=0"
  done
  for opt in {A..Z}; do
    echo "${prefix}_is_$opt=0"
    echo "${prefix}_is_${opt}_${opt}=0"
  done

  local stop_parsing=0

  local evaluated_flags=""

  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
      break;
    fi

    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"
      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        if [[ -n "$hidden_flags" && $hidden_flags != *$opt* ]]; then
          evaluated_flags+="$opt"
        fi
      done
    fi
  done

  # getopts is not ideal because it doesn't support flags after the arguments, only before them
  # example: `mycommand arg1 arg2 -a -b` does not work with getopts
  local arg=""
  for arg in "$@"; do
    if (( stop_parsing )) || [[ "$arg" == "--" ]]; then
      if (( stop_parsing )); then
        non_flags+=("$arg")
      fi
      stop_parsing=1
      continue;
    fi

    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"

      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        echo "${prefix}_is_$opt=1"

        # check if $opt exists in double_flags
        if [[ " ${double_flags[@]} " =~ " $opt " ]]; then
          echo "${prefix}_is_${opt}_${opt}=1"
        fi

        double_flags+=("$opt")

        if [[ $valid_flags != *$opt* && "$valid_flags_pass_along" != "all" ]] && [[ -z "$hidden_flags" || $hidden_flags != *$opt* || -z "$evaluated_flags" ]]; then
          flags+=("-$opt")

          if [[ ! " ${invalid_opts[@]} " =~ " $opt " ]]; then
            invalid_opts+=("-$opt")
            echo "invalid_option+=(\"-$opt\")"

            if (( ! internal_func || ! is_invalid )); then
              print "  ${red_cor}fatal: invalid option: -$opt${reset_cor}" >&2
              print "  --" >&2
              echo "is_invalid=1"
            else
              echo "is_invalid=0"
            fi
          fi

          echo "${prefix}_is_h=1"
        elif [[ $valid_flags_pass_along == *$opt* || "$valid_flags_pass_along" == "all" ]]; then
          flags+=("-$opt")
        fi
      done
    elif [[ "$arg" == --* ]]; then
      if [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}_is_debug=1"
      else
        flags_double_dash+=("$arg")
      fi
    else
      non_flags+=("$arg")
    fi
  done

  if [[ ${#non_flags} -gt 0 ]]; then
    print -r -- set -- "${(q)non_flags[@]}" "${(q)flags[@]}" "${(q)flags_double_dash[@]}"
  else
    print -r -- set -- "${(q)flags[@]}" "${(q)flags_double_dash[@]}"
  fi
}

function parse_single_flags_() {
  set +x

  if [[ -z "$1" ]]; then
    print " ${red_cor}internal error: parse_single_flags_ requires a prefix${reset_cor}" >&2
    return 1;
  fi

  local prefix_arg="$1"
  local valid_flags="h$2"
  local hidden_flags="$3"

  prefix="${prefix_arg%_}"

  shift 3

  typeset -g is_debug

  local non_flags=()

  if (( is_debug )); then
    echo "is_debug=1"
    echo "${prefix}_is_debug=1"
  else
    echo "${prefix}_is_debug=0"
  fi

  local opt=""
  for opt in {a..z}; do
    echo "${prefix}_is_$opt=0"
  done
  for opt in {A..Z}; do
    echo "${prefix}_is_$opt=0"
  done

  local evaluated_flags=""

  local arg=""
  for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
      break;
    fi

    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"
      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        if [[ -n "$hidden_flags" && $hidden_flags != *$opt* ]]; then
          evaluated_flags+="$opt"
        fi
      done
    fi
  done

  local stop_parsing=0

  # getopts is not ideal because it doesn't support flags after the arguments, only before them
  # example: `mycommand arg1 arg2 -a -b` does not work with getopts
  arg=""
  for arg in "$@"; do
    if (( stop_parsing )) || [[ "$arg" == "--" ]]; then
      if (( stop_parsing )); then
        non_flags+=("$arg")
      fi
      stop_parsing=1
      continue;
    fi

    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"
      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        echo "${prefix}_is_$opt=1"

        if [[ -n "$valid_flags" ]]; then
          if [[ $valid_flags != *$opt* ]] && [[ -z "$hidden_flags" || $hidden_flags != *$opt* || -z "$evaluated_flags" ]]; then
            print "  ${red_cor}fatal: invalid option: -$opt${reset_cor}" >&2
            print "  --" >&2
            echo "${prefix}_is_h=1"
          fi
        else
          non_flags+=("$arg")
        fi
      done
    elif [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}_is_debug=1"
    else
      non_flags+=("$arg")
    fi
  done

  print -r -- set -- "${(q)non_flags[@]}"
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
  # (( confirm_is_debug )) && set -x

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
      flags+=("--default=no")
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
    return 0;
  fi
  
  if [[ "${mode:l}" == "${opt2:l}" ]]; then
    return 1;
  fi

  return 130;
}

function upgrade_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( upgrade_is_debug )) && set -x

  local release_tag="https://api.github.com/repos/fab1o/pump-zsh/releases/latest"
  local latest_version="$(curl -s $release_tag | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"

  if [[ -n "$latest_version" && "$PUMP_VERSION" != "$latest_version" ]]; then
    print " new version available for pump-zsh: ${magenta_cor}${PUMP_VERSION}${reset_cor} -> ${purple_cor}${latest_version}${reset_cor}"

    if (( ! upgrade_is_f )); then
      if ! confirm_ "install new version?" "install" "abort"; then
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

    PUMP_VERSION="$(<"$PUMP_VERSION_FILE")"
    
    local version="${purple_cor}$(printf "%-7s %s" "$PUMP_VERSION")${pink_cor}"

    local x="${green_cor}*${hi_cyan_cor}"
    local spaulo="${green_cor}S.Paulo${hi_cyan_cor}"
    local brasilpais="${green_cor}B ${hi_yellow_cor}R ${green_cor}A ${hi_yellow_cor}S ${green_cor}I ${hi_yellow_cor}L${hi_cyan_cor}"

    print ""
    print " version installed successfully!"
    echo "${pink_cor}  _ __  _   _ _ __ ___  _ ___    "
    echo " | '_ \| | | | '_ \` _ \\| \'_ \ "
    echo " | |_) | |_| | | | | | | |_) |   "
    echo " | .__/${hi_cyan_cor}.${pink_cor}\__,_|_| |_| |_| .__/    "
    echo " | | ${hi_cyan_cor})                 \" ${pink_cor}|${hi_cyan_cor}._    "
    echo "${pink_cor} |_|${hi_cyan_cor}.\"                      \   "
    echo "   ${hi_cyan_cor}(       $brasilpais       )   "
    echo "    \                       /    "
    echo "      \__                  (     "
    echo "         \_                )     "
    echo "           \_.            /      "
    echo "              \  $spaulo /       "
    echo "               \     $x _/       "
    echo "                \    _/          "
    echo "               /    /            "
    echo "              <    /             "
    echo "               \"^./             "
    echo "${reset_cor}"

    zsh # restart zsh to load the new version

    return 0;
  else
    if (( upgrade_is_f )); then
      print " no update available for pump-zsh: ${purple_cor}${PUMP_VERSION}${reset_cor}"
    fi
  fi
}

function input_type_() {
  local header="$1"
  local placeholder="$2"
  local max="${3:-255}"
  local value="$4"

  local _input=""

  # >&2 needs to display because this is called from a subshell
  if [[ -n "$header" ]]; then
    print " ${purple_cor}$header:${reset_cor}" >&2
  fi

  if command -v gum &>/dev/null; then
    _input="$(gum input --placeholder="$placeholder" --char-limit="$max" --value="$value")"
    if (( $? == 130 )); then return 130; fi
  else
    trap 'print ""; return 130' INT
    stty -echoctl
    read "?> " _input
    stty echoctl
    trap - INT
  fi

  _input="$(printf '%s' "$_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  if [[ -n "$_input" ]]; then
    echo "$_input"
    return 0;
  fi

  return 1;
}

function write_from_() {
  local header="$1"
  local placeholder="$2"

  local _input=""

  # >&2 needs to display because this is called from a subshell
  if [[ -n "$header" ]]; then
    print " ${purple_cor}$header:${reset_cor}" >&2
  fi

  if command -v gum &>/dev/null; then
    _input="$(gum write --placeholder="$placeholder")"
    if (( $? != 0 )); then return 130; fi
  else
    trap 'print ""; return 130' INT
    stty -echoctl
    read "?> " _input
    stty echoctl
    trap - INT
  fi

  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  if [[ -n "$_input" ]]; then
    echo "$_input"
    return 0;
  fi

  return 1;
}

function filter_one_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( filter_one_is_debug )) && set -x

  local header="$1"

  if ! command -v gum &>/dev/null; then
    choose_one_ $@
    return $?;
  fi

  if [[ -n "$header" ]]; then
    print " ${purple_cor}choose $header: ${reset_cor}" >&2
  fi

  local flags=()

  if (( filter_one_is_a )); then
    flags+=("--timeout=3s")
  fi

  if (( filter_one_is_i )); then
    flags+=("--select-if-one")
  fi

  local choice=""
  choice="$(gum filter --height="25" --limit=1 --indicator=">" --placeholder=" type to filter" ${flags[@]} -- ${@:2})"
  local RET=$?
  if (( RET != 0 )); then return $RET; fi
  
  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  if (( filter_one_is_t )) && [[ -n "$choice" ]]; then
    choice="${choice%%[$'\t ']*}"
    choice="${choice%%[[:space:]]#}"
  fi

  echo "$choice"
}

function choose_one_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( choose_one_is_debug )) && set -x

  if (( ${#@:2} > 25 )) && command -v gum &>/dev/null; then
    filter_one_ $@
    return $?;
  fi

  local header="$1"

  if command -v gum &>/dev/null; then
    local flags=()

    if (( choose_one_is_a )); then
      flags+=("--timeout=3s")
    fi

    if (( choose_one_is_i )); then
      flags+=("--select-if-one")
    fi

    local choice=""
    choice="$(gum choose --height="25" --limit=1 --header=" choose $header:${reset_cor}" ${flags[@]} -- ${@:2} 2>/dev/tty)"
    local RET=$?
    if (( RET != 0 )); then return $RET; fi

    if (( choose_one_is_t )) && [[ -n "$choice" ]]; then
      choice="${choice%%[$'\t ']*}"
      choice="${choice%%[[:space:]]#}"
    fi

    echo "$choice"

    return 0;
  fi

  trap 'print ""; return 130' INT

  PS3="${purple_cor}choose $header: ${reset_cor}"

  select choice in "${@:2}" "quit"; do
    case $choice in
      "quit")
        return 1;
        ;;
      *)
        if (( choose_one_is_t )); then
          choice="${choice%%[$'\t ']*}"
          choice="${choice%%[[:space:]]#}"
        fi
        echo "$choice"
        return 0;
        ;;
    esac
  done

  trap - INT
}

function filter_multiple_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( filter_multiple_is_debug )) && set -x

  local header="$1"

  if ! command -v gum &>/dev/null; then
    choose_multiple_ $@
    return $?;
  fi

  if [[ -n "$header" ]]; then
    print " ${purple_cor}choose $header: ${reset_cor}" >&2
  fi

  local flags=()

  if (( filter_multiple_is_a )); then
    flags+=("--timeout=3s")
  fi

  if (( filter_multiple_is_i )); then
    flags+=("--select-if-one")
  fi
  
  local choices
  choices="$(gum filter --height="25" --no-limit --placeholder=" type to filter" ${flags[@]} -- ${@:2})"
  local RET=$?
  if (( RET != 0 )); then return $RET; fi
  
  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  local choice=""
  for choice in "${(@f)choices}"; do
    if (( filter_multiple_is_t )) && [[ -n "$choice" ]]; then
      choice="${choice%%[$'\t ']*}"
      choice="${choice%%[[:space:]]#}"
    fi
    echo "$choice"
  done
}

function choose_multiple_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( choose_multiple_is_debug )) && set -x

  if (( ${#@:2} > 25 )) && command -v gum &>/dev/null; then
    filter_multiple_ $@
    return $?
  fi

  local header="$1"

  if command -v gum &>/dev/null; then
    local flags=()

    if (( choose_multiple_is_a )); then
      flags+=("--timeout=3s")
    fi

    if (( choose_multiple_is_i )); then
      flags+=("--select-if-one")
    fi

    local choices
    choices="$(gum choose --height="25" --no-limit --header=" choose multiple $header ${purple_cor}(use spacebar to select)${purple_cor}:${reset_cor}" ${flags[@]} -- ${@:2})"
    local RET=$?
    if (( RET != 0 )); then return $RET; fi

    local choice=""
    for choice in "${(@f)choices}"; do
      if (( choose_multiple_is_t )) && [[ -n "$choice" ]]; then
        choice="${choice%%[$'\t ']*}"
        choice="${choice%%[[:space:]]#}"
      fi
      echo "$choice"
    done

    # echo "$choices"

    return 0;
  fi

  trap 'print ""; return 130' INT

  local choices=()
  PS3="${purple_cor}choose multiple $header, then choose \"done\" to finish ${choices[*]}${reset_cor}"

  local choice=""
  select choice in "${@:2}" "done"; do
    case $choice in
      "done")
        echo "${choices[@]}"
        return 0;
        ;;
      *)
        if (( choose_multiple_is_t )) && [[ -n "$choice" ]]; then
          choice="${choice%%[$'\t ']*}"
          choice="${choice%%[[:space:]]#}"
        fi
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
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( check_settings_file_is_debug )) && set -x

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
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( check_config_file_is_debug )) && set -x

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
  local value="$2"
  local old_value="$3"

  if [[ -z "$old_value" ]]; then
    if (( i > 0 )); then
      old_value="${PUMP_SHORT_NAME[$i]}"
    else
      old_value="$CURRENT_PUMP_SHORT_NAME"
    fi
  fi

  # set and unset proj_handler function
  if [[ -n "$old_value" && "$value" == "$old_value" ]]; then
    return 0;
  fi

  if [[ -n "$old_value" ]]; then
    unset -f "$old_value" &>/dev/null
  fi

  if [[ -n "$value" ]]; then
    functions[$value]="proj_handler $i \"\$@\";"
  fi
}

function get_pump_value_() {
  local key="$1"
  local proj_folder="${2:-$PWD}"

  local file="${proj_folder}/.pump"

  if [[ -f "$file" ]]; then
    echo "$(sed -n "s/^${key}=\\([^ ]*\\)/\\1/p" "$file" 2>/dev/null)"

    # echo $(sed -n 's/^JIRA_KEY[[:space:]]*="\(.*\)"/\1/p' "$file" 2>/dev/null)
  fi
}

function update_pump_file_() {
  local key="$1"
  local value="$2"
  local proj_folder="${3:-$PWD}"

  local file="${proj_folder}/.pump"

  if [[ -f "$file" ]]; then
    local current_value="$(sed -n "s/^${key}=\\([^ ]*\\)/\\1/p" "$file" 2>/dev/null)"

    if [[ "$current_value" == "$value" ]]; then
      return 1;
    fi
  fi

  update_file_ "$key" "$value" "$file" &>/dev/null
}

function update_config_file_() {
  local i="$1"
  local key="$2"
  local value="$3"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    return 0;
  fi

  local key_i="${key}_${i}"

  local current_value="$(sed -n "s/^${key_i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"

  if [[ "$current_value" == "$value" ]]; then
    return 1;
  fi

  update_file_ "$key_i" "$value" "$PUMP_CONFIG_FILE"
}

function update_file_() {
  local key="$1"
  local value="$2"
  local file="$3"

  if [[ ! -f "$file" ]]; then
    touch "$file"
  fi

  value="$(echo $value | xargs 2>/dev/null)"
  if [[ -z "$value" ]]; then value="$(echo $value | xargs -0 2>/dev/null)"; fi

  if grep -q "^${key}=" "$file"; then
    if sed --version >/dev/null 2>&1; then
      # Linux (GNU sed)
      sed -i "s|^$key=.*|$key=$value|" "$file"
    else
      # macOS (BSD sed) requires correct handling of patterns
      sed -i '' "s|^$key=.*|$key=$value|" "$file"
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
  local disclaimer="${3:-0}"

  eval "${key}=\"$value\""

  update_file_ "$key" "$value" "$PUMP_SETTINGS_FILE" "$disclaimer"
  local RET=$?

  if (( disclaimer )) && [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print " ${gray_cor}run: ${hi_gray_cor}${CURRENT_PUMP_SHORT_NAME} -u${reset_cor}${gray_cor} to reset settings${reset_cor}" >&2
  fi

  return $RET;
}

function update_config_() {
  set +x
  eval "$(parse_flags_ "$0" "ne" "" "$@")"
  (( update_config_is_debug )) && set -x

  if ! check_config_file_; then
    print " ${red_cor}fatal: config file is invalid, cannot update config: $PUMP_CONFIG_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local i="$1"
  local key="$2"
  local value="$3"
  local disclaimer="${4:-0}"

  value="$(trim_ "$value")"

  if [[ "$key" == "PUMP_SHORT_NAME" ]]; then
    update_config_short_name_ $i "$value"
  fi

  if (( ! update_config_is_n && ! update_config_is_e  )); then
    # set the key variable
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" && -n "${PUMP_SHORT_NAME[$i]}" && "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
      if [[ -z "$value" ]]; then
        eval "CURRENT_${key}=\"\${${key}[0]}\""
      else
        eval "CURRENT_${key}=\"$value\""
      fi
    fi

    # Check if "$value" is equal to the current value of ${key}_[$i]
    if [[ "$value" != "${(P)${key}[$i]}" ]]; then
      eval "${key}[$i]=\"$value\""
    fi
  fi

  if update_config_file_ $i "$key" "$value"; then
    if (( disclaimer )) && [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
      print " ${gray_cor}run: ${hi_gray_cor}${PUMP_SHORT_NAME[$i]} -u${reset_cor}${gray_cor} to reset config${reset_cor}" >&2
    fi
  fi
}

function update_proj_repo_() {
  local i="$1"
  local proj_repo="$2"
  local proj_folder="$3"
  local single_mode="$4"

  local dirs

  if (( single_mode )); then
    dirs=("$proj_folder")
  else
    local dirs_output=""
    dirs_output="$(get_folders_ $i "$proj_folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    dirs=("${(@f)dirs_output}")
  fi

  local folder=""
  for folder in "${dirs[@]}"; do
    if ! is_proj_folder_empty_ "$folder"; then
      if ! is_folder_git_ "$folder" &>/dev/null; then
        git -C "$folder" init
        git -C "$folder" remote add origin "$proj_repo"
      else
        git -C "$folder" remote set-url origin "$proj_repo"
      fi
    fi
  done
}

function is_branch_name_valid_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_branch_name_valid_is_debug )) && set -x

  local branch="$1"

  # doesn't require -C "$folder" because it only checks the format
  if ! git check-ref-format --branch "$branch" &>/dev/null; then
    print " fatal: invalid branch name: $(truncate_ "$branch")" >&2
    return 1;
  fi
}

function input_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
  (( input_branch_name_is_debug )) && set -x

  local header="$1"
  local placeholder="$2"
  local folder="${3:-$PWD}"

  while true; do
    local typed_value=""
    typed_value="$(input_type_ "$header" "$placeholder" 200)"
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$typed_value" ]] && is_branch_name_valid_ "$typed_value" &>/dev/null; then
      if (( input_branch_name_is_r )); then
        if is_remote_branch_ "$typed_value" "$folder" &>/dev/null || is_local_branch_ "$typed_value" "$folder" &>/dev/null; then
          echo "$typed_value"          
          return 0;
        else
          print " branch name not found locally or remotely: $(truncate_ "$typed_value")" >&2
        fi
      else
        echo "$typed_value"
        return 0;
      fi
    fi
  done

  return 1;
}

function input_command_() {
  local header="$1"
  local value="$2"

  while true; do
    local typed_value=""
    typed_value="$(input_type_ "$header" "" 100 "$value")"
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$typed_value" && "$typed_value" != *" "* ]]; then
      if command -v $typed_value &>/dev/null; then
        echo "$typed_value"
        return 0;
      fi
    fi
  done

  return 1;
}

function input_type_mandatory_() {
  set +x
  eval "$(parse_flags_ "$0" "km" "" "$@")"
  (( input_type_mandatory_is_debug )) && set -x

  local header="$1"
  local placeholder="$2"
  local max="${3:-255}"
  local value="$4"

  while true; do
    if [[ -n "$placeholder" && "${#placeholder}" -gt "$max" ]]; then
      placeholder="${placeholder:0:$max}"
    fi
    if [[ -n "$value" && "${#value}" -gt "$max" ]]; then
      value="${value:0:$max}"
    fi

    local typed_value=""
    typed_value="$(input_type_ "$header" "$placeholder" "$max" "$value")"
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if (( ! input_type_mandatory_is_k )) && [[ -z "$typed_value" && -n "$placeholder" ]] && command -v gum &>/dev/null; then
      typed_value="$placeholder"
    fi

    if [[ -n "$typed_value" ]]; then
      if (( input_type_mandatory_is_m )) && [[ ! "$typed_value" =~ ^[a-zA-Z]{1,2}$ ]]; then
        print " value must be 1-2 characters and contain letters only" >&2
        continue;
      fi
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
    typed_value="$(input_type_ "$header" "$placeholder" "$max" "$value")"
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
    folder_path="$(input_path_ "type the folder path")"
    if (( $? != 0 )); then return 1; fi

    echo "$folder_path"
    return 0;
  fi

  # >&2 needs to display because this is called from a subshell
  # print " ${header}:" >&2
  print " ${purple_cor}${header}:${reset_cor}" >&2
  print "" >&2

  add-zsh-hook -d chpwd pump_chpwd_ &>/dev/null
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

      if [[ -d "$folder_path" ]]; then
        if (( find_proj_folder_is_e )); then
          if is_folder_pkg_ "$new_folder_a" &>/dev/null || is_folder_git_ "$new_folder_a" &>/dev/null; then
            RET=0
          elif [[ "${new_folder_a:t}" == "Developer" ]]; then
            RET=1
          else
            confirm_ "set project folder to: ${blue_cor}${new_folder_a}${reset_cor} or continue to browse?" "set folder" "browse"
            RET=$?
            if (( RET == 130 || RET == 2 )); then break; fi
          fi
        else
          confirm_ "set project folder to: ${blue_cor}${new_folder_a}${reset_cor} or continue to browse?" "set folder" "browse"
          RET=$?
          if (( RET == 130 || RET == 2 )); then break; fi
        fi

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
    
    if [[ -z "$(get_folders_ 0 "$folder_path" 2>/dev/null)" ]]; then
      cd "${HOME:-/}"
    fi

    rm -rf -- ".DS_Store" &>/dev/null

    chose_folder="$(gum file --directory --height 14)"
    RET=$?
    if (( RET == 130 || RET == 2 )); then break; fi

    if [[ -n "$chose_folder" ]]; then
      folder_path="$chose_folder"
    else
      break;
    fi
  done

  add-zsh-hook chpwd pump_chpwd_ &>/dev/null

  if (( RET == 130 || RET == 2 )); then
    return 130;
  fi

  if [[ -n "$chosen_folder" ]]; then
    echo "$chosen_folder"
    RET=0
  else
    RET=1
  fi

  clear_last_line_2_
  clear_last_line_2_
  return $RET;
}

function find_proj_script_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( find_proj_script_folder_is_debug )) && set -x

  local i="$1"
  local header="$2"
  local proj_folder="$3"

  ######################################################
  # VERY IMPORTANT: Cannot use 'path' as variable name
  #####################################################
  local folder_path="" 

  if ! command -v gum &>/dev/null; then
    folder_path="$(input_path_ "type the folder path")"
    if (( $? != 0 )); then return 1; fi

    echo "$folder_path"
    return 0;
  fi

  # >&2 needs to display because this is called from a subshell
  # print " ${header}:" >&2
  print " ${purple_cor}${header}:${reset_cor}" >&2
  print "" >&2

  add-zsh-hook -d chpwd pump_chpwd_ &>/dev/null
  cd "${proj_folder:-/}" # start from proj_folder

  local RET=0
  local chosen_folder=""

  while true; do
    if [[ -n "$folder_path" ]]; then
      local new_folder_a="${folder_path:A}"

      if [[ -d "$folder_path" ]]; then
        confirm_ "set scripts folder to: ${blue_cor}${new_folder_a}${reset_cor} or continue to browse?" "set folder" "browse"
        RET=$?
        if (( RET == 130 || RET == 2 )); then break; fi
        if (( RET == 1 )); then
          cd "$folder_path"
        else
          chosen_folder="$folder_path"
          break;
        fi
      fi
    fi
    
    if [[ -z "$(get_folders_ 0 "$folder_path" 2>/dev/null)" ]]; then
      cd "${proj_folder:-/}"
    fi

    rm -rf -- ".DS_Store" &>/dev/null

    chose_folder="$(gum file --all --directory --height 14)"
    RET=$?
    if (( RET == 130 || RET == 2 )); then break; fi

    if [[ -n "$chose_folder" ]]; then
      folder_path="$chose_folder"
    else
      break;
    fi
  done

  add-zsh-hook chpwd pump_chpwd_ &>/dev/null

  if (( RET == 130 || RET == 2 )); then
    return 130;
  fi

  if [[ -n "$chosen_folder" ]]; then
    echo "$chosen_folder"
    RET=0
  else
    RET=1
  fi

  clear_last_line_2_
  clear_last_line_2_
  return $RET;
}

function input_path_() {
  local header="$1"

  while true; do
    local typed_value=""
    typed_value="$(input_type_ "$header")"
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
      gh_owner="$(input_type_ "type the Github owner account (username or organization) skip if not on Github" "" 50)"
      # if (( $? == 130 || $? == 2 )); then return 130; fi
      if [[ -n "$gh_owner" ]]; then
        local list_repos="$(gh repo list $gh_owner --limit 100 --json nameWithOwner -q '.[].nameWithOwner' | sort -f 2>/dev/null)"
        local repos=("${(@f)list_repos}")
        
        if (( $? == 0 && ${#repos[@]} > 1 )); then
          local selected_repo=""
          selected_repo="$(choose_one_ "repository" "${repos[@]}")"
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
    typed_value="$(input_type_ "$header" "$placeholder")"
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

  local total_width1="$(( total_width / 2 - 2 ))"

  local padding="$(( total_width1 - 2 ))"
  local word_length1=${#word1}

  local padding1="$(( ( total_width1 > word_length1 ? total_width1 - word_length1 - 2 : word_length1 - total_width1 - 2 ) / 2 ))"
  local line1="$(printf '%*s' "$padding1" '' | tr ' ' '─') $word1 $(printf '%*s' "$padding1" '' | tr ' ' '─')"

  if (( ${#line1} < total_width1 )); then
    local pad_len1="$(( total_width1 - ${#line1} ))"

    padding1="$(printf '%*s' $pad_len1 '' | tr ' ' '-')"
    line1="${line1}${padding1}"
  fi

  local total_width2="$(( total_width / 2 - 2 ))"
  local word_length2=${#word2}

  local padding2="$(( ( total_width2 > word_length2 ? total_width2 - word_length2 - 2 : word_length2 - total_width2 - 2 ) / 2 ))"
  local line2="$(printf '%*s' "$padding2" '' | tr ' ' '─') $word2 $(printf '%*s' "$padding2" '' | tr ' ' '─')"

  local total_lines="$( (( ${#line1} + ${#line2} )) )"

  if (( total_lines < total_width )); then
    local pad_len2="$( (( total_width - total_lines )) )"

    padding2="$(printf '%*s' $pad_len2 '' | tr ' ' '-')"
    line2="${line2}${padding2}"
  fi

  local line="$line1 | ${color2}$line2"

  print "${color} $line ${reset_cor}"
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

  local padding="$(( total_width - factor ))"
  local line="$(printf '%*s' "$padding" '' | tr ' ' '─')"

  if [[ -n "$word1" ]]; then
    local word_length1=${#word1}

    local padding1="$(( ( total_width > word_length1 ? total_width - word_length1 - factor : word_length1 - total_width - factor ) / 2 ))"
    local line1="$(printf '%*s' "$padding1" '' | tr ' ' '─') ${word_color}$word1 ${color}$(printf '%*s' "$padding1" '' | tr ' ' '─')"

    local count="$(( ${#line1} - ${#color} - ${#word_color} ))"
    if (( count < total_width )); then
      local pad_len1="$(( total_width - count ))"
      padding1="$(printf '%*s' $pad_len1 '' | tr ' ' '-')"
      line1="${line1}${padding1}"
    fi
    
    line="$line1"
  fi

  print "${color} $line ${reset_cor}"
}

function sanitize_pkg_name_() {
  local pkg_name="$1"

  if [[ -z "$pkg_name" ]]; then
    echo ""
    return 0;
  fi

  # convert to lowercase
  local sanitized="${pkg_name:l}"

  # remove all characters before the first slash
  sanitized="${sanitized#*/}"

  # remove all characters except lowercase letters, digits, and dashes
  sanitized="${sanitized//[^a-z0-9-]/}"

  # remove invalid leading characters until it starts with a-z or 0-9
  while [[ -n "$sanitized" && ! "$sanitized" =~ ^[a-z0-9] ]]; do
    sanitized="${sanitized:1}"
  done

  # remove trailing characters that aren't a-z or 0-9
  while [[ -n "$sanitized" && ! "$sanitized" =~ [a-z0-9]$ ]]; do
    sanitized="${sanitized%?}"
  done

  echo "$sanitized"
}

# data checkers =========================================================
function check_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "fmeprg" "qv" "$@")"
  (( check_proj_is_debug )) && set -x

  local i="$1"

  if [[ -z "$i" || $i -lt 1 || $i -gt 9 ]]; then
    return 1;
  fi

  shift

  if (( check_proj_is_f )); then
    if ! check_proj_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "${PUMP_REPO[$i]}" $@; then return 1; fi

    if [[ -z "${PUMP_FOLDER[$i]}" || ! -d "${PUMP_FOLDER[$i]}" ]]; then
      if (( ! check_proj_is_q )); then
        print " ${red_cor}project folder is missing for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
        print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      fi
      return 1;
    fi
  fi

  if (( check_proj_is_e )); then
    if ! check_proj_script_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SCRIPT_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" $@; then return 1; fi
  fi

  if (( check_proj_is_m )); then
    if ! save_proj_mode_ -q $i "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}" $@; then return 1; fi
  fi

  if (( check_proj_is_p )); then
    if ! check_proj_pkg_manager_ -q $i "${PUMP_PKG_MANAGER[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_REPO[$i]}" $@; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PKG_MANAGER[$i]}" ]]; then
      print " ${red_cor}missing package manager for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_r )); then
    if ! check_proj_repo_ -sq $i "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" $@; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_REPO[$i]}" ]]; then
      print " ${red_cor}missing repository uri for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_g )); then
    if [[ -z "${PUMP_PR_APPROVAL_MIN[$i]}" ]]; then
      local pr_approval_min=""
      pr_approval_min="$(input_number_ "minimum number of approvals for pull requests" 2 1)"
      if (( $? == 130 )); then return 130; fi

      update_config_ $i "PUMP_PR_APPROVAL_MIN" "$pr_approval_min"
    fi
  fi
}

function check_jira_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( check_jira_proj_is_debug )) && set -x

  local i="$1"
  local jira_proj="${2:-$PUMP_JIRA_PROJECT[$i]}"
  local proj_cmd="${3:-$PUMP_SHORT_NAME[$i]}"

  if [[ -n "$jira_proj" ]]; then
    if gum spin --title="checking project..." -- acli jira project view --key "$jira_proj" >/dev/null 2>&1; then
      return 0;
    fi

    if [[ -n "$jira_proj" ]]; then
      print " ${yellow_cor}warning: unable to validate jira project: ${bold_cor}$jira_proj${reset_cor}" >&2
    fi
  fi

  jira_proj="$(select_jira_proj_ $i "$proj_cmd")"
  if [[ -z "$jira_proj" ]]; then return 1; fi

  update_config_ $i "PUMP_JIRA_PROJECT" "$jira_proj" 1>&2
  PUMP_JIRA_PROJECT[$i]="$jira_proj"
}

function get_all_statuses_() {
  local i="$1"
  
  local jira_statuses="$(load_config_entry_ $i "PUMP_JIRA_STATUSES")"

  if [[ -n "$jira_statuses" ]]; then
    echo "$jira_statuses" | sed "s/$TAB/\n/g"
  fi
}

function select_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( select_jira_status_is_debug )) && set -x

  local i="$1"
  local header="$2"
  local default_status="$3"

  local jira_statuses="$(get_all_statuses_ $i)"
  if [[ -z "$jira_statuses" ]]; then return 1; fi

  local chosen_status=""

  # check if status in in jira_statuses and chooose that one
  if [[ -n "$default_status" ]]; then
    local s=""
    for s in "${(@f)jira_statuses}"; do
      if [[ "$s" == "$default_status" ]]; then
        chosen_status="$s"
        break;
      fi
    done
  fi

  if [[ -z "$chosen_status" ]]; then
    chosen_status="$(choose_one_ "status $header" "${(@f)jira_statuses}")"
    if (( $? == 130 )); then return 130; fi
  fi

  echo "$chosen_status"
}

function select_multiple_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( select_multiple_jira_status_is_debug )) && set -x

  local i="$1"
  local header="$2"

  local jira_statuses="$(get_all_statuses_ $i)"
  if [[ -z "$jira_statuses" ]]; then return 1; fi

  local chosen_statuses=()
  chosen_statuses=($(choose_multiple_ "statuses $header" "${(@f)jira_statuses}"))
  if (( $? == 130 )); then return 130; fi

  echo "${chosen_statuses[@]}"
}

function check_jira_statuses_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "" "$@")"
  (( check_jira_statuses_is_debug )) && set -x

  local i="$1"
  local jira_proj="${2:-$PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${3:-$PUMP_JIRA_API_TOKEN[$i]}"
  local jira_statuses=("${4:-$PUMP_JIRA_STATUSES[$i]}")

  if [[ -n "$jira_statuses" ]]; then
    return 0;
  fi

  local current_user="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"
  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local jira_boards="$(gum spin --title="pulling boards..." -- curl -s \
    -u "$current_user:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/agile/1.0/board?projectKeyOrId=${jira_proj}" \
    | jq -r '.values[] | "\(.id)\t\(.type)\t\(.name)"'
  )"

  if [[ -z "$jira_boards" ]]; then return 1; fi

  local boards=("${(@f)$(echo "$jira_boards" | cut -f3)}")
  local board_name=""
  board_name="$(choose_one_ "jira board" "${boards[@]}")"
  if (( $? == 130 )); then return 130; fi

  if [[ -z "$board_name" ]]; then return 1; fi

  local board_id="$(echo "$jira_boards" | awk -v name="$board_name" -F'\t' '$3 == name {print $1}' | xargs 2>/dev/null)"

  jira_statuses="$(gum spin --title="pulling configuration..." -- curl -s \
    -u "$current_user:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/agile/1.0/board/${board_id}/configuration" \
    | jq -r '.columnConfig.columns[].statuses.[].self' \
    | while read -r self; do
      curl -s -u "$current_user:$jira_api_token" "$self" \
      | jq -r '.name'
    done #| awk -v sep="$TAB" '{ printf "%s%s", (NR>1?sep:""), $0 } END { print "" }'
  )"

  if (( check_jira_statuses_is_s )); then
    update_config_ $i "PUMP_JIRA_STATUSES" "${jira_statuses//$'\n'/$TAB}" &>/dev/null
  else
    echo "${jira_statuses//$'\n'/$TAB}"
  fi
}

function select_jira_proj_() {
  local i="$1"
  local proj_cmd="$2"
  local jira_proj="$3"

  local projects=($(gum spin --title="pulling projects..." -- acli jira project list --recent --json | jq -r '.[].key' 2>/dev/null))

  if [[ -z "$projects" ]]; then
    if [[ -n "$proj_cmd" ]]; then
      print " no jira projects found for ${blue_cor}$proj_cmd${reset_cor}" >&2
    else
      print " no jira projects found" >&2
    fi
    return 1;
  fi

  #see if jira_proj is in projects
  if [[ -n "$jira_proj" ]]; then
    local proj=""
    for proj in "${projects[@]}"; do
      if [[ "$proj" == "$jira_proj" ]]; then
        echo "$proj"
        return 0;
      fi
    done

    jira_proj=""
  fi

  local header="jira project"

  if [[ -n "$proj_cmd" ]]; then
    header="${header} in $proj_cmd"
  fi

  jira_proj="$(choose_one_ "$header" "${projects[@]}")"
  if (( $? == 130 )); then return 130; fi

  echo "$jira_proj"
}

function check_work_types_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "" "$@")"
  (( check_work_types_is_debug )) && set -x

  local i="$1"
  local jira_proj="${2:-${PUMP_JIRA_PROJECT[$i]}}"
  local work_types="${3:-${PUMP_JIRA_WORK_TYPES[$i]}}"

  local default_work_types=(bug story feature sync chore task epic improvement)
  local new_work_types=()

  local is_add=1

  if [[ -n "$work_types" && "${PUMP_JIRA_PROJECT[$i]}" == "$jira_proj" ]]; then
    new_work_types=(${(z)work_types})

    if (( check_work_types_is_s )); then
      is_add=0
    fi

  elif [[ -n "$jira_proj" ]]; then
    if check_jira_ -iw $i; then
      local jira_work_types="$(gum spin --title="pulling issue types..." -- acli jira workitem search --jql "project=\"$jira_proj\"" --fields=issuetype --json | jq -r '.[].fields.issuetype.name' | sort -u 2>/dev/null)"
      new_work_types=("${(@f)jira_work_types}")
    fi
  fi

  if (( is_add )); then
    local wt=""
    for wt in "${default_work_types[@]}"; do
      local exists=0
      local existing=""
      for existing in "${new_work_types[@]}"; do
        if [[ "${existing:l}" == "${wt:l}" ]]; then
          exists=1
          break
        fi
      done
      if (( ! exists )); then
        new_work_types+=("$wt")
      fi
    done
  fi

  local new_work_types_str="$(echo "${${new_work_types[*]}:l}" | sort -u | xargs)"

  if (( check_work_types_is_s )); then
    if (( i )); then
      update_config_ $i "PUMP_JIRA_WORK_TYPES" "$new_work_types_str" &>/dev/null
      PUMP_JIRA_WORK_TYPES[$i]="$new_work_types_str"
      return 0;
    fi
  else
    echo "$new_work_types_str"
  fi
}

function get_jira_releases_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_jira_releases_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local jira_api_token="$3"

  if [[ -z "$jira_proj" ]]; then
    jira_proj="$(load_config_entry_ $i "PUMP_JIRA_PROJECT")"
  fi

  if [[ -z "$jira_api_token" ]]; then
    jira_api_token="$(load_config_entry_ $i "PUMP_JIRA_API_TOKEN")"
  fi

  local current_user="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"
  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local jira_releases="$(gum spin --title=" releases..." -- curl -s \
    -u "$current_user:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/api/3/project/${jira_proj}/versions" \
    | jq -r 'map(select(.released == false and .archived == false)) 
          | sort_by(.releaseDate // "9999-12-31", .name)
          | .[].name'
  )"

  if [[ -z "$jira_releases" ]]; then
    print " no unreleased releases found in jira project: $jira_proj" >&2
    return 1;
  fi

  echo "$jira_releases"
}

function select_proj_release_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( select_proj_release_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local jira_api_token="$3"

  local jira_releases="$(get_jira_releases_ $i "$jira_proj" "$jira_api_token")"

  if [[ -z "$jira_releases" ]]; then
    return 1;
  fi

  local release=""
  release=$(choose_one_ "jira release" "${(@f)jira_releases}")
  if (( $? == 130 )); then return 130; fi

  echo "$release"
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
  local proj_cmd="$3"
  local proj_repo="$4"

  local error_msg=""

  if [[ -z "$proj_folder" ]]; then
    if [[ -n "$proj_cmd" ]]; then
      error_msg="project folder is missing for $proj_cmd"
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
    local real_proj_folder="$(realpath -- "$proj_folder" 2>/dev/null)"
    
    if [[ -z "$real_proj_folder" ]]; then
      if (( check_proj_folder_is_v )); then
        mkdir -p -- "$proj_folder" &>/dev/null
        real_proj_folder="$(realpath -- "$proj_folder" 2>/dev/null)"

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
      if save_proj_folder_ $i "$proj_cmd" "$proj_repo" "" ${@:5}; then return 0; fi
    fi

    return 1;
  fi

  return 0;
}

function check_proj_script_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "" "$@")"
  (( check_proj_script_folder_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_script_folder="$3"
  local proj_cmd="$4"
  
  local is_error=0

  if [[ -z "$proj_script_folder" ]]; then
    is_error=1
  else
    local real_proj_folder="$(realpath -- "$proj_script_folder" 2>/dev/null)"
    
    if [[ -z "$real_proj_folder" ]]; then
      mkdir -p -- "$proj_script_folder" &>/dev/null
      real_proj_folder="$(realpath -- "$proj_script_folder" 2>/dev/null)"

      if [[ -z "$real_proj_folder" ]]; then
        print "  ${red_cor}script folder is invalid: $proj_script_folder${reset_cor}" >&2
        is_error=1
      fi
    fi
  fi

  if (( is_error )); then
    if (( check_proj_script_folder_is_s )); then
      if save_proj_script_folder_ $i "$proj_folder" "$proj_cmd" ${@:5}; then return 0; fi
    fi
    return 1;
  fi
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

    local multiple_title="$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 212 "multiple mode")"
    local single_title="$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 99 "single mode")"

    local titles="$(gum join --align=center --horizontal "$multiple_title" "$single_title")"

    local multiple=$'  '/"$parent_folder_name"'
   └─ '/"$folder_name"'
      ├─ /main
      ├─ /feature-1
      └─ /feature-2'

    local single=$'  '/"$parent_folder_name"'
   └─ '/"$folder_name"'


    '

    multiple="$(gum style --align=left --margin="0" --padding="0" --border=normal --width=30 --border-foreground 212 "$multiple")"
    single="$(gum style --align=left --margin="0" --padding="0" --border=normal --width=30 --border-foreground 99 "$single")"

    local examples="$(gum join  --align=center --horizontal "$multiple" "$single")"
    
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
  eval "$(parse_flags_ "$0" "brcts" "" "$@")"
  (( get_proj_special_folder_is_debug )) && set -x

  local i="$1"
  local proj_cmd="${2:-$PUMP_SHORT_NAME[$i]}"
  local proj_folder="${3:-$PUMP_FOLDER[$i]}"

  if [[ -z "$i" || -z "$proj_cmd" || -z "$proj_folder" ]]; then
    print " fatal: get_proj_special_folder_ missing arguments" >&2
    return 1;
  fi

  local category=""

  if (( get_proj_special_folder_is_r )); then
    category=".revs"
  elif (( get_proj_special_folder_is_b )); then
    category=".backups"
  elif (( get_proj_special_folder_is_c )); then
    category=".cov"
  elif (( get_proj_special_folder_is_t )); then
    category=".temp"
  elif (( get_proj_special_folder_is_s )); then
    category=".scripts"
  else
    print " fatal: get_proj_special_folder_ missing category flag" >&2
    return 1;
  fi

  local parent_folder="$(dirname -- "$proj_folder")"

  echo "${parent_folder}/${category}/${proj_cmd}"
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
    local package_json="$(gh api "${url}/package.json" --jq .download_url // empty 2>/dev/null)"

    if [[ -n "$package_json" ]]; then
      if command -v jq &>/dev/null; then
        pkg_name="$(curl -fs "$package_json" | jq -r --arg key "$field" '.[$key] // empty')"
      else
        pkg_name="$(curl -fs "$package_json" | grep -E '"'$field'"\s*:\s*"' | head -1 | sed -E "s/.*\"$field\": *\"([^\"]+)\".*/\1/")"
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
      pkg_name="$(curl -fs "${url}/package.json" | jq -r --arg key "$field" '.[$key] // empty')"
      if [[ -n "$pkg_name" ]]; then break; fi
    done
  else
    for url in "${urls[@]}"; do
      pkg_name="$(curl -fs "${url}/package.json" | grep -E '"'$field'"\s*:\s*"' | head -1 | sed -E "s/.*\"$field\": *\"([^\"]+)\".*/\1/")"
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
    local package_json="$(gh api "${url}/package.json" --jq .download_url // empty 2>/dev/null)"

    if [[ -n "$package_json" ]]; then
      if command -v jq &>/dev/null; then
        manager="$(curl -fs "$package_json" | jq -r '.packageManager // empty')"
      else
        manager="$(curl -fs "$package_json" | grep -E '"'packageManager'"\s*:\s*"' | head -1 | sed -E "s/.*\"packageManager\": *\"([^\"]+)\".*/\1/")"
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
      manager="$(curl -fs "${url}/package.json" | jq -r '.packageManager // empty')"
      if [[ -n "$manager" ]]; then
        manager="${manager%%@*}"
        break;
      fi
    done
  else
    for url in "${urls[@]}"; do
      manager="$(curl -fs "${url}/package.json" | grep -E '"'packageManager'"\s*:\s*"' | head -1 | sed -E "s/.*\"packageManager\": *\"([^\"]+)\".*/\1/")"
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

  folder="$(get_proj_for_pkg_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  if [[ -f "${folder}/package.json" ]]; then
    local line="$(get_from_package_json_ "packageManager" "$folder")"
    
    if [[ $line =~ ([^\"]+) ]]; then
      manager="${match[1]%%@*}"

      echo "${manager:l}"
      return 0;
    fi
  fi

  # 1. Lockfile-based detection (most reliable)
  if [[ -f "${folder}/bun.lockb" ]]; then
    manager="bun"
  elif [[ -f "${folder}/pnpm-lock.yaml" ]]; then
    manager="pnpm"
  elif [[ -f "${folder}/yarn.lock" ]]; then
    manager="yarn"
  elif [[ -f "${folder}/package-lock.json" ]]; then
    manager="npm"
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  # local pyproject_file="${folder}/pyproject.toml"

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
  typed_proj_cmd="$(input_type_mandatory_ "type your project name" "$pkg_name" 13 2>/dev/tty)"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$typed_proj_cmd" ]]; then return 1; fi
  
  if ! check_proj_cmd_ -s $i "$typed_proj_cmd" "$old_proj_cmd"; then
    return 1;
  fi

  if [[ -z "$TEMP_PUMP_SHORT_NAME" ]]; then    
    TEMP_PUMP_SHORT_NAME="$typed_proj_cmd"

    if (( save_proj_cmd_is_x )); then
      print "  ${hi_gray_cor}project name: ${TEMP_PUMP_SHORT_NAME}${reset_cor}"
    else
      print "  ${SAVE_COR}project name:${reset_cor} ${TEMP_PUMP_SHORT_NAME}${reset_cor}"
    fi
  fi
}

function get_proj_mode_from_folder_() {
  local proj_folder="$1"
  local single_mode="$2"

  if [[ -z "$proj_folder" || ! -d "$proj_folder" ]]; then
    echo "$single_mode"
    return 0;
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

  local current_single_mode="$(get_proj_mode_from_folder_ "$proj_folder" "$single_mode")"

  if (( save_proj_mode_is_e || save_proj_mode_is_a )); then
    single_mode="$(choose_mode_ "$current_single_mode" "$proj_folder")"

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
  
  local mode_label="$( (( single_mode )) && echo "single" || echo "multiple" )"

  if (( save_proj_mode_is_x )); then
    print "  ${hi_gray_cor}project mode: ${mode_label}${reset_cor}"
  else
    print "  ${SAVE_COR}project mode:${reset_cor} ${mode_label}${reset_cor}"
  fi
}

function save_proj_script_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( save_proj_script_folder_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_cmd="$3"

  local proj_script_folder=""

  local folder_exists=0

  if [[ -z "$proj_script_folder" ]]; then
    confirm_ "would you like to use an existing scripts folder?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      proj_script_folder="$(find_proj_script_folder_ $i "select an existing project folder" "$proj_folder")"
    else
      proj_script_folder="$(get_proj_special_folder_ -s $i "$proj_cmd" "$proj_folder")"
    fi
  fi

  if [[ -n "$proj_script_folder" ]]; then
    if ! check_proj_script_folder_ $i "$proj_folder" "$proj_script_folder" "$proj_cmd" ${@:4}; then return 1; fi
  fi

  if [[ -z "$proj_script_folder" ]]; then return 1; fi

  update_config_ $i "PUMP_SCRIPT_FOLDER" "$proj_script_folder"
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

    if ( is_folder_pkg_ "$PWD" &>/dev/null || is_folder_git_ "$PWD" &>/dev/null ) && ! find_proj_by_folder_ "$PWD" &>/dev/null; then
      # ask to use pwd
      confirm_ "set project folder to: ${blue_cor}${PWD}${reset_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        proj_folder="$PWD"
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
    confirm_ "would you like to create a new folder or use an existing one?" "create new folder" "use existing folder"
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
      local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"
      
      proj_cmd="$(sanitize_pkg_name_ "${repo_name:t}")"
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
      proj_folder="$(find_proj_folder_ -e $i "$header" "$proj_cmd")"
    else
      proj_folder="$(find_proj_folder_ $i "$header" "$proj_cmd")"
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

  print "  ${SAVE_COR}project folder:${reset_cor} ${TEMP_PUMP_FOLDER}${reset_cor}"
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
      local git_folder="$(get_proj_for_git_ "$proj_folder" 2>/dev/null)"
      if [[ -n "$git_folder" ]]; then
        proj_repo="$(get_repo_ "$git_folder" 2>/dev/null)"
      fi
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
  fi

  if (( save_proj_repo_is_q )); then
    if update_config_ $i "PUMP_REPO" "$proj_repo" &>/dev/null; then
      update_proj_repo_ $i "$proj_repo" "$proj_folder" "${PUMP_SINGLE_MODE[$i]}"
    fi

    return 0;
  fi

  TEMP_PUMP_REPO="$proj_repo"

  print "  ${SAVE_COR}project repository:${reset_cor} ${TEMP_PUMP_REPO}${reset_cor}"
}

function save_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "q" "$@")"
  (( save_pkg_manager_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  local pkg_folder="$(get_proj_for_pkg_ "$proj_folder" 2>/dev/null)"
  if [[ -z "$pkg_folder" ]]; then pkg_folder="$proj_folder"; fi

  local pkg_manager="$(detect_pkg_manager_ "$pkg_folder")"

  if [[ -z "$pkg_manager" && -n "$proj_repo" ]]; then
    pkg_manager="$(detect_pkg_manager_online_ "$pkg_folder")"
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
    pkg_manager="$(choose_one_ "package manager" "npm" "yarn" "pnpm" "bun")"
    if [[ -z "$pkg_manager" ]]; then return 1; fi

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder" "$proj_repo" ${@:4}; then return 1; fi
  fi
  
  if [[ -z "$pkg_manager" ]]; then return 1; fi

  TEMP_PUMP_PKG_MANAGER="$pkg_manager"

  if (( save_pkg_manager_is_q )); then
    return 0;
  fi

  print "  ${SAVE_COR}package manager:${reset_cor} ${TEMP_PUMP_PKG_MANAGER}${reset_cor}"
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

  local proj_repo="$(get_repo_ "$PWD" 2>/dev/null)"

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  # all the config setting comes from $PWD
  if (( save_proj_f_is_e )); then
    if ! save_pkg_manager_ -fq $i "$PWD" "$proj_repo"; then return 1; fi
  else
    remove_proj_ -f $i

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo"; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -f $i "$PWD" "$proj_repo"; then return 1; fi
    if ! save_proj_cmd_ -f $i "$proj_cmd"; then return 1; fi
  fi
  
  remove_proj_ -uf $i  

  update_config_ $i "PUMP_FOLDER" "$PWD" &>/dev/null
  update_config_ $i "PUMP_SINGLE_MODE" 1 &>/dev/null
  if update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then
    update_proj_repo_ $i "$TEMP_PUMP_REPO" "$PWD" 1 &>/dev/null
  fi
  update_config_ $i "PUMP_PKG_MANAGER" "$TEMP_PUMP_PKG_MANAGER" &>/dev/null

  update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null

  if (( save_proj_f_is_e )); then
    update_config_ $i "PUMP_SHORT_NAME" "$proj_cmd" &>/dev/null
  else
    update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null
    
    print ""
    print "  ${SAVE_COR}project saved!${reset_cor}"
    display_line_ "" "${SAVE_COR}"
  fi

  print " new command is available: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"

  load_config_index_ $i

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
    i=""
    local j=0
    for j in {1..9}; do
      # find an empty slot
      if [[ -z "${PUMP_SHORT_NAME[$j]}" ]]; then
        i=$j
        break;
      fi
    done
  fi

  if [[ -z "$i" ]]; then
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
  
  local old_single_mode="$(get_proj_mode_from_folder_ "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}")"
  local is_refresh=0

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  if (( save_proj_is_e )); then
    # editing a project
    if [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      is_refresh=1
    fi

    if ! save_proj_cmd_ -e $i "$proj_name" "${PUMP_SHORT_NAME[$i]}"; then return 1; fi

    if ! save_proj_folder_ -e $i "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}"; then return 1; fi
    if ! save_proj_repo_ -e $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}"; then return 1; fi
    
    if ! save_proj_mode_ -e $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
  else
    # adding a new project
    remove_proj_ -f $i

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
  
  remove_proj_ -uf $i

  update_config_ $i "PUMP_FOLDER" "$TEMP_PUMP_FOLDER" &>/dev/null
  update_config_ $i "PUMP_SINGLE_MODE" "$TEMP_SINGLE_MODE" &>/dev/null
  if update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then
    update_proj_repo_ $i "$TEMP_PUMP_REPO" "$TEMP_PUMP_FOLDER" "$TEMP_SINGLE_MODE" &>/dev/null
  fi
  update_config_ $i "PUMP_PKG_MANAGER" "$TEMP_PUMP_PKG_MANAGER" &>/dev/null
  update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null

  local pkg_name="$(get_pkg_name_ "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO" 2>/dev/null)"
  if [[ -n "$pkg_name" ]]; then
    update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null
  fi

  print ""
  print "  ${SAVE_COR}project saved!${reset_cor}"
  display_line_ "" "${SAVE_COR}"

  load_config_index_ $i

  PUMP_SHORT_NAME[$i]="$(load_config_entry_ $i "PUMP_SHORT_NAME")"
  PUMP_FOLDER[$i]="$(load_config_entry_ $i "PUMP_FOLDER")"
  PUMP_SINGLE_MODE[$i]="$(load_config_entry_ $i "PUMP_SINGLE_MODE")"

  if [[ ! -d "${PUMP_FOLDER[$i]}" ]]; then
    mkdir -p -- "${PUMP_FOLDER[$i]}"
  fi

  local display_msg=1

  if [[ -n "$old_single_mode" ]] && (( old_single_mode != ${PUMP_SINGLE_MODE[$i]} )); then
    local git_proj_folder="$(get_proj_for_git_ "${PUMP_FOLDER[$i]}" 2>/dev/null)"
    local pkg_proj_folder="$(get_proj_for_pkg_ "${PUMP_FOLDER[$i]}" 2>/dev/null)"
    
    if [[ -n "$git_proj_folder" || -n "$pkg_proj_folder" ]]; then
      if create_backup_ -sd $i "${PUMP_FOLDER[$i]}"; then
        print " project must be cloned again as mode has changed" >&2
        print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} clone${reset_cor}" >&2
        display_msg=0
      fi
    fi
  fi

  if (( is_refresh )) || [[ "$PWD" == "${PUMP_FOLDER[$i]}" ]]; then
    set_current_proj_ $i
    display_msg=0
  fi

  if (( display_msg )); then
    print " now run command: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"
  fi
}
# end of save project data to config file =========================================

function unset_aliases_() {
  set +x

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
  alias rstart="$pkg_manager start"
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
  eval "$(parse_flags_ "$0" "urf" "" "$@")"
  (( remove_proj_is_debug )) && set -x

  local i="$1"

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  if (( ! remove_proj_is_f )) && ! confirm_ "are you sure you want to remove project: ${blue_cor}$proj_cmd${reset_cor}?"; then
    return 1;
  fi

  unset_aliases_
  update_config_short_name_ $i ""

  PUMP_SHORT_NAME[$i]=""
  PUMP_FOLDER[$i]=""
  PUMP_REPO[$i]=""
  PUMP_SINGLE_MODE[$i]=""
  PUMP_PKG_MANAGER[$i]=""
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
  PUMP_PR_TITLE_FORMAT[$i]=""
  PUMP_PR_REPLACE[$i]=""
  PUMP_PR_APPEND[$i]=""
  PUMP_PR_APPROVAL_MIN[$i]=""
  PUMP_COMMIT_SIGNOFF[$i]=""
  PUMP_PKG_NAME[$i]=""
  PUMP_JIRA_PROJECT[$i]=""
  PUMP_JIRA_API_TOKEN[$i]=""
  PUMP_JIRA_STATUSES[$i]=""
  PUMP_JIRA_TODO[$i]=""
  PUMP_JIRA_IN_PROGRESS[$i]=""
  PUMP_JIRA_IN_REVIEW[$i]=""
  PUMP_JIRA_IN_TEST[$i]=""
  PUMP_JIRA_ALMOST_DONE[$i]=""
  PUMP_JIRA_DONE[$i]=""
  PUMP_JIRA_CANCELED[$i]=""
  PUMP_JIRA_PULL_SUMMARY[$i]=""
  PUMP_JIRA_WORK_TYPES[$i]=""
  PUMP_SKIP_DETECT_NODE[$i]=""
  PUMP_NVM_USE_V[$i]=""
  PUMP_SCRIPT_FOLDER[$i]=""

  if (( remove_proj_is_u )); then
    update_config_ $i "PUMP_SHORT_NAME" "" 1>/dev/null # let this one
    update_config_ $i "PUMP_FOLDER" "" &>/dev/null
    update_config_ $i "PUMP_REPO" "" &>/dev/null
    update_config_ $i "PUMP_SINGLE_MODE" "" &>/dev/null
    update_config_ $i "PUMP_PKG_MANAGER" "" &>/dev/null
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
    update_config_ $i "PUMP_PR_TITLE_FORMAT" "" &>/dev/null
    update_config_ $i "PUMP_PR_REPLACE" "" &>/dev/null
    update_config_ $i "PUMP_PR_APPEND" "" &>/dev/null
    update_config_ $i "PUMP_PR_APPROVAL_MIN" "" &>/dev/null
    update_config_ $i "PUMP_COMMIT_SIGNOFF" "" &>/dev/null
    update_config_ $i "PUMP_PKG_NAME" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_PROJECT" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_API_TOKEN" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_STATUSES" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_TODO" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_IN_PROGRESS" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_IN_REVIEW" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_IN_TEST" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_ALMOST_DONE" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_DONE" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_CANCELED" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_PULL_SUMMARY" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_WORK_TYPES" "" &>/dev/null
    update_config_ $i "PUMP_SKIP_DETECT_NODE" "" &>/dev/null
    update_config_ $i "PUMP_NVM_USE_V" "" &>/dev/null
    update_config_ $i "PUMP_SCRIPT_FOLDER" "" &>/dev/null
  fi

  if (( remove_proj_is_r )); then
    local proj_folder="${PUMP_FOLDER[$i]}"

    if [[ -n "$proj_folder" ]]; then
      local revs_folder="$(get_proj_special_folder_ -r $i "$proj_cmd" "$proj_folder")"
      local cov_folder="$(get_proj_special_folder_ -c $i "$proj_cmd" "$proj_folder")"
      local temp_folder="$(get_proj_special_folder_ -t $i "$proj_cmd" "$proj_folder")"

      if command -v gum &>/dev/null; then
        gum spin --title="removing project folders..." -- rm -rf -- "$revs_folder" "$cov_folder" "$temp_folder"
      else
        print " removing project folders..."
        rm -rf -- "$revs_folder" "$cov_folder" "$temp_folder"
      fi
    fi
  fi
}

function set_current_proj_() {
  set +x

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
  CURRENT_PUMP_PR_TITLE_FORMAT="${PUMP_PR_TITLE_FORMAT[$i]}"
  CURRENT_PUMP_PR_REPLACE="${PUMP_PR_REPLACE[$i]}"
  CURRENT_PUMP_PR_APPEND="${PUMP_PR_APPEND[$i]}"
  CURRENT_PUMP_PR_APPROVAL_MIN="${PUMP_PR_APPROVAL_MIN[$i]}"
  CURRENT_PUMP_COMMIT_SIGNOFF="${PUMP_COMMIT_SIGNOFF[$i]}"
  CURRENT_PUMP_PKG_NAME="${PUMP_PKG_NAME[$i]}"
  CURRENT_PUMP_JIRA_PROJECT="${PUMP_JIRA_PROJECT[$i]}"
  CURRENT_PUMP_JIRA_API_TOKEN="${PUMP_JIRA_API_TOKEN[$i]}"
  CURRENT_PUMP_JIRA_STATUSES="${PUMP_JIRA_STATUSES[$i]}"
  CURRENT_PUMP_JIRA_TODO="${PUMP_JIRA_TODO[$i]}"
  CURRENT_PUMP_JIRA_IN_PROGRESS="${PUMP_JIRA_IN_PROGRESS[$i]}"
  CURRENT_PUMP_JIRA_IN_REVIEW="${PUMP_JIRA_IN_REVIEW[$i]}"
  CURRENT_PUMP_JIRA_IN_TEST="${PUMP_JIRA_IN_TEST[$i]}"
  CURRENT_PUMP_JIRA_DONE="${PUMP_JIRA_DONE[$i]}"
  CURRENT_PUMP_JIRA_CANCELED="${PUMP_JIRA_CANCELED[$i]}"
  CURRENT_PUMP_JIRA_ALMOST_DONE="${PUMP_JIRA_ALMOST_DONE[$i]}"
  CURRENT_PUMP_JIRA_PULL_SUMMARY="${PUMP_JIRA_PULL_SUMMARY[$i]}"
  CURRENT_PUMP_JIRA_WORK_TYPES="${PUMP_JIRA_WORK_TYPES[$i]}"
  CURRENT_PUMP_SKIP_DETECT_NODE="${PUMP_SKIP_DETECT_NODE[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"
  CURRENT_PUMP_SCRIPT_FOLDER="${PUMP_SCRIPT_FOLDER[$i]}"

  set_aliases_ $i

  # do not need to refresh because themes were fixed
  # if [[ -n "$ZSH_THEME" ]]; then
  #   source "$ZSH/themes/${ZSH_THEME}.zsh-theme"
  # fi
}

# function get_major_version_() {
#   local version="$1"

#   local major_version="$version"

#   if [[ -n "$version" ]]; then
#     major_version="$(npx --yes semver -v "$version" | cut -d. -f1 2>/dev/null)"
#   fi

#   echo "$major_version"
# }

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
   
#   local padded_version="$(get_padded_version_ "$version" 0)"
#   local major_version="$(get_major_version_ "$padded_version")"

#   echo "$(get_padded_version_ "$major_version")"
# }

# function get_padded_version_() {
#   local version="$1"
#   local replacer="${2:-x}"
  
#   local parts=("${(s:.:)version}")
  
#   echo "${parts[1]:-$replacer}.${parts[2]:-$replacer}.${parts[3]:-$replacer}"
# }

# function get_node_version_() {
#   local folder="${1:-$PWD}"
#   local sort_by="${2:-latest}"
#   local node_engine="$3"

#   if ! command -v nvm &>/dev/null; then return 1; fi

#   if [[ -z "$node_engine" ]]; then
#     local proj_folder="$(get_proj_for_pkg_ "$folder" "package.json" 2>/dev/null)"
#     if [[ -z "$proj_folder" ]]; then return 1; fi

#     local package_json="${proj_folder}/package.json"
#     if [[ ! -f $package_json ]]; then return 1; fi

#     if ! command -v nvm &>/dev/null; then return 1; fi

#     if command -v jq &>/dev/null; then
#       node_engine="$(jq -r '.engines.node // empty' "$package_json")"
#     else
#       node_engine="$(grep -o '"node"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_json" | sed -E 's/.*"node"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')"
#     fi
    
#     if [[ -z "$node_engine" ]]; then return 1; fi
#   fi

#   # setopt shwordsplit
#   # get list of installed versions from nvm
#   local installed_versions=()
#   installed_versions=($(
#     nvm ls --no-colors \
#       | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' \
#       | sed 's/^[-> ]*//' \
#       | sed 's/^v//' \
#       | sed 's/ *\*$//'
#   ))
#   # unsetopt shwordsplit

#   if (( ${#installed_versions[@]} == 0 )); then return 1; fi

#   local matching_versions=()

#   # find matching versions
#   for version in "${installed_versions[@]}"; do
#     if npx --yes semver -r "$node_engine" "$version" &>/dev/null; then
#       matching_versions+=("$version")
#     fi
#   done

#   if (( ${#matching_versions[@]} == 0 )); then return 1; fi

#   # sort versions and pick the latest
#   local best_version=""
  
#   if [[ "$sort_by" == "latest" ]]; then
#     best_version="$(printf "%s\n" "${matching_versions[@]}" | sort -V | tail -n 1)"
#   else
#     best_version="$(printf "%s\n" "${matching_versions[@]}" | sort -V | head -n 1)"
#   fi

#   echo "$best_version"
# }

function is_version_higher_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_version_higher_is_debug )) && set -x

  # do not use npx semver because some versions of node do not support it well
  local version1="$1"
  local version2="$2"

  if [[ -z "$version1" || -z "$version2" ]]; then
    return 1;
  fi

  if [[ "$version1" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    local version1_major="${version1%%.*}"
    local version1_rest="${version1#*.}"
    # if there was no dot, version1_rest equals version1, so minor should be 0
    if [[ "$version1_rest" == "$version1" ]]; then
      local version1_minor="0"
    else
      local version1_minor="${version1_rest%%.*}"
    fi

    if [[ "$version2" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
      local version2_major="${version2%%.*}"
      local version2_rest="${version2#*.}"
      # if there was no dot, version2_rest equals version2, so minor should be 0
      if [[ "$version2_rest" == "$version2" ]]; then
        local version2_minor="0"
      else
        local version2_minor="${version2_rest%%.*}"
      fi

      if (( version1_major > version2_major || version1_major == version2_major && version1_minor >= version2_minor )); then
        return 0;
      fi

      return 1;
    fi
  fi

  return 1;
}

function get_node_versions_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_node_versions_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if ! command -v nvm &>/dev/null; then return 1; fi

  # get list of installed versions from nvm
  set +x
  local installed_versions=($(nvm ls --no-colors | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^[-> ]*//' | sed 's/ *\*$//' | sort -V)) # | sed 's/^v//'
  (( get_node_versions_is_debug )) && set -x

  if [[ -z "$installed_versions" ]]; then return 1; fi

  local yes=""

  local npx_version="$(npx --version 2>/dev/null)"
  if [[ "$npx_version" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    local npx_major="${npx_version%%.*}"
    if (( npx_major >= 7 )); then
      yes="--yes"
    fi
  fi

  local node_engine="$(get_from_package_json_ "engines.node" "$folder")"

  # find matching versions
  local version=""
  for version in "${installed_versions[@]}"; do
    if npx $yes semver "$version" -r "$node_engine" &>/dev/null; then
      print -r -- "$version"
    fi
  done
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
    print " [${hi_magenta_cor}PUMP_COV_$i=${reset_cor}${hi_gray_cor}${PUMP_COV[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_OPEN_COV_$i=${reset_cor}${hi_gray_cor}${PUMP_OPEN_COV[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RETRY_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_RETRY_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_WATCH_$i=${reset_cor}${hi_gray_cor}${PUMP_TEST_WATCH[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2E_$i=${reset_cor}${hi_gray_cor}${PUMP_E2E[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2EUI_$i=${reset_cor}${hi_gray_cor}${PUMP_E2EUI[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_TEMPLATE_FILE_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_TEMPLATE_FILE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_TITLE_FORMAT_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_TITLE_FORMAT[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_REPLACE_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_REPLACE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPEND_$i=${reset_cor}${hi_gray_cor}${PUMP_PR_APPEND[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPROVAL_MIN$i=${reset_cor}${hi_gray_cor}${PUMP_PR_APPROVAL_MIN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COMMIT_SIGNOFF_$i=${reset_cor}${hi_gray_cor}${PUMP_COMMIT_SIGNOFF[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_NAME_$i=${reset_cor}${hi_gray_cor}${PUMP_PKG_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_PROJECT_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_PROJECT[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PUMP_JIRA_API_TOKEN_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_API_TOKEN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_STATUSES_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_STATUSES[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_TODO_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_TODO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_PROGRESS_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_PROGRESS[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_TEST_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_REVIEW_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_IN_REVIEW[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_ALMOST_DONE_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_ALMOST_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_DONE_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_CANCELED_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_CANCELED[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_PULL_SUMMARY_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_PULL_SUMMARY[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_WORK_TYPES_$i=${reset_cor}${hi_gray_cor}${PUMP_JIRA_WORK_TYPES[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SKIP_NVM_LOOKUP_$i=${reset_cor}${hi_gray_cor}${PUMP_SKIP_DETECT_NODE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_NVM_USE_V_$i=${reset_cor}${hi_gray_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SCRIPT_FOLDER_$i=${reset_cor}${hi_gray_cor}${PUMP_SCRIPT_FOLDER[$i]}${reset_cor}]"

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
  print " [${hi_magenta_cor}CURRENT_PUMP_COV=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_OPEN_COV=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_OPEN_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RETRY_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_RETRY_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST_WATCH=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_TEST_WATCH}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2E=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_E2E}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2EUI=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_E2EUI}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_TEMPLATE_FILE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_TEMPLATE_FILE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_TITLE_FORMAT=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_TITLE_FORMAT}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_REPLACE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_REPLACE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPEND=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_APPEND}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPROVAL_MIN=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PR_APPROVAL_MIN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COMMIT_SIGNOFF=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_COMMIT_SIGNOFF}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_NAME=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_PKG_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_PROJECT=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_PROJECT}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_API_TOKEN=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_API_TOKEN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_STATUSES=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_STATUSES}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_TODO=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_TODO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_PROGRESS=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_PROGRESS}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_REVIEW=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_REVIEW}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_TEST=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_ALMOST_DONE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_ALMOST_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_DONE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_CANCELED=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_CANCELED}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_PULL_SUMMARY=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_JIRA_PULL_SUMMARY}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SKIP_DETECT_NODE=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_SKIP_DETECT_NODE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_USE_V=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_NVM_USE_V}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SCRIPT_FOLDER=${reset_cor}${hi_gray_cor}${CURRENT_PUMP_SCRIPT_FOLDER}${reset_cor}]"
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

function is_proj_folder_empty_() {
  local folder="$1"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    return 0;
  fi

  rm -rf -- "${folder}/.DS_Store" &>/dev/null

  if [[ -z "$(ls -A -- "$folder" 2>/dev/null)" ]]; then
    return 0;
  fi

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
    print " ${red_cor}fatal: not a valid project: $proj_cmd${reset_cor}" >&2
    return 1;
  fi
}

# when project is unknown, it's a proj_arg
function find_proj_index_() {
  set +x
  eval "$(parse_flags_ "$0" "zoex" "" "$@")"
  # (( find_proj_index_is_debug )) && set -x

  local proj_arg="$1"
  local header="${2:-project}"
  local default_index="${3:-0}"

  if [[ -z "$proj_arg" ]]; then
    if (( find_proj_index_is_x )); then
      echo "$default_index"
      return 0;
    fi

    if (( find_proj_index_is_o )); then
      local projects=($(get_projects_ "$PWD"))
      
      if [[ -z "$projects" ]]; then
        print " no projects found" >&2
        print " run: ${hi_yellow_cor}pro -a${reset_cor} to add a project" >&2

        echo "0"
        return 0;
      fi

      proj_arg="$(choose_one_ "$header" "${projects[@]}")"
      if [[ -z "$proj_arg" ]]; then return 130; fi
    else

      print " missing project argument" >&2

      echo "0"
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
    local projects=($(get_projects_ "$PWD"))
    
    if [[ -z "$projects" ]]; then
      print " fatal: no projects found" >&2
      print " run: ${hi_yellow_cor}pro -a${reset_cor} to add a project" >&2

      echo "0"
      return 1;
    fi

    proj_arg="$(choose_one_ "$header" "${projects[@]}")"
    if [[ -z "$proj_arg" ]]; then
      echo "0"
      return 1;
    fi

    i=0
    for i in {1..9}; do
      if [[ "$proj_arg" == "${PUMP_SHORT_NAME[$i]}" ]]; then
        echo "$i"
        return 0;
      fi
    done
  fi

  echo "0"
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

function find_package_json_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  local fil="package.json"

  local pattern="$(printf "%q" "$file")"
  local found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}" \) -prune -o -maxdepth 1 -iname "${pattern}*" -print -quit 2>/dev/null)"

  if [[ -z "$found_file" ]]; then
    return 1;
  fi

  echo "$found_file"
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
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_proj_for_pkg_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local file="${2:-"package.json"}"

  folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    print " fatal: not a project folder: $folder" >&2
    return 1;
  fi

  local proj_folder=""

  if [[ -e "${folder}/${file}" ]]; then
    proj_folder="$folder"
  fi

  if [[ -z "$proj_folder" ]]; then
    local git_folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"

    if [[ -f "${git_folder}/${file}" ]]; then
      proj_folder="$git_folder"
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

  echo "$proj_folder"
}

function get_proj_for_git_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_proj_for_git_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local proj_cmd="$2"

  local real_folder="$(realpath -- "$folder" 2>/dev/null)"

  if [[ -z "$real_folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    if [[ -n "$proj_cmd" ]]; then
      print " run: ${hi_yellow_cor}$proj_cmd -e${reset_cor} to edit project" >&2
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
    print " run: ${hi_yellow_cor}$proj_cmd clone${reset_cor} to clone project" >&2
  fi

  return 1;
}

function is_folder_git_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_folder_git_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " fatal: not a git repository (or any of the parent directories): .git" >&2 
    return 1;
  fi

  if ! git -C "$folder" rev-parse --is-inside-work-tree &>/dev/null; then
    print " fatal: not a git repository (or any of the parent directories): .git" >&2 
    return 1;
  fi
}

function get_remote_name_() {
  local folder="${1:-$PWD}"
  
  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    echo "origin";
    return 1;
  fi

  local name="$(git -C "$folder" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null | cut -d/ -f1)"

  if [[ -z "$name" || "$name" == "@{u}" ]]; then
    name="$(git -C "$folder" remote 2>/dev/null | head -n1)";
  fi

  if [[ -z "$name" ]]; then
    for name in refs/remotes/{origin,upstream}/{HEAD,main,master,stage,staging,prod,production,release,dev,develop,trunk,mainline,default,stable}; do
      if git -C "$folder" show-ref --verify --quiet "$name"; then
        name="${${name:h}:t}"
      fi
    done
  fi

  if [[ -z "$name" ]]; then
    echo "origin"
    return 1;
  fi

  echo "$name"
}

function determine_target_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "dbmyte" "" "$@")"
  (( determine_target_branch_is_debug )) && set -x

  local branch_arg="$1"
  local folder="${2:-$PWD}"
  local proj_cmd="$3"
  local extra_branch="$4"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  local is_pwd=0;
  
  if [[ "$folder" == "$folder" ]]; then
    is_pwd=1
  else
    local proj_pwd="$(find_proj_by_folder_ "$folder" 2>/dev/null)"
    if [[ -n "$proj_cmd" && "$proj_pwd" == "$proj_cmd" ]]; then
      is_pwd=1
    fi
  fi
  
  local default_branch=""
  local base_branch=""
  local main_branch=""
  local my_branch=""
  local target_branch=""

  if (( determine_target_branch_is_d )); then
    default_branch="$(get_default_branch_ "$folder" 2>/dev/null)"
  fi
  
  if (( determine_target_branch_is_b )); then
    base_branch="$(find_base_branch_ "$folder" "$branch_arg" 2>/dev/null)"
  fi

  if (( determine_target_branch_is_t )); then
    target_branch="$(get_base_branch_ "$branch_arg" "$folder" 2>/dev/null)"
  fi

  if (( determine_target_branch_is_m )); then
    main_branch="$(get_main_branch_ "$folder" 2>/dev/null)"
  fi

  if (( is_pwd )); then
    if (( determine_target_branch_is_y )); then
      my_branch="$(get_my_branch_ 2>/dev/null)"
    fi
    if [[ -z "$default_branch" ]]; then
      default_branch="$(get_default_branch_ 2>/dev/null)"
    fi
    if [[ -z "$base_branch" ]]; then
      base_branch="$(find_base_branch_ "" "$branch_arg" 2>/dev/null)"
    fi
  else
    if (( determine_target_branch_is_y )); then
      my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    fi
  fi

  if [[ "$branch_arg" == "$default_branch" ]]; then default_branch=""; fi
  if [[ "$branch_arg" == "$base_branch" ]]; then base_branch=""; fi
  if [[ "$branch_arg" == "$target_branch" ]]; then target_branch=""; fi
  if [[ "$branch_arg" == "$main_branch" ]]; then main_branch=""; fi
  if [[ "$branch_arg" == "$extra_branch" ]]; then extra_branch=""; fi

  local output="$(printf "%s\n" "$default_branch" "$base_branch" "$my_branch" "$target_branch" "$main_branch" "$extra_branch" | grep -v '^$' | sort -u)"

  local branches=()

  if [[ -n "$output" ]]; then
    branches+=("${(@f)output}")
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local output_releases="$(git -C "$folder" branch --all --list "${remote_name}/release*" -i --no-column --format="%(refname:short)" \
    | sed "s#^$remote_name/##" \
    | grep -v 'detached' \
    | grep -v 'HEAD' \
    | sort -fur \
    | head -7
  )"

  if [[ -n "$output_releases" ]]; then
    branches+=("${(@f)output_releases}")
  fi
  
  if (( determine_target_branch_is_e )); then
    if (( ${#branches[@]} > 1 )); then
      branches+=("<enter manually>")
    fi
  elif (( ${#branches[@]} == 0 )); then
    branches+=("<enter manually>")
  fi

  local label=""
  if [[ -n "$branch_arg" ]]; then
    label="target branch for $branch_arg"
  else
    label="target branch"
  fi

  local selected_branch=""
  if (( determine_target_branch_is_e )); then
    selected_branch="$(choose_one_ -i "$label" "${branches[@]}")"
  else
    selected_branch="$(choose_one_ -ai "$label" "${branches[@]}")"
  fi

  if (( $? == 124 )); then
    selected_branch="${branches[1]}"
  fi

  if [[ "$selected_branch" == "<enter manually>" ]]; then
    selected_branch=""
    selected_branch="$(input_branch_name_ -r "type the target branch" "" "$folder")"
    if (( $? == 130 )); then return 130; fi
  fi

  echo "$selected_branch"
}

function is_branch_existing_local_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch_arg="$1"
  local proj_folder="$2"

  if get_local_branch_ "$branch_arg" "$proj_folder" &>/dev/null; then
    return 0;
  fi

  return 1;
}

function is_branch_existing_remote_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch_arg="$1"
  local proj_folder="$2"

  if get_remote_branch_ "$branch_arg" "$proj_folder" &>/dev/null; then
    return 0;
  fi

  return 1;
}

function is_branch_existing_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch_arg="$1"
  local proj_folder="$2"

  if get_remote_branch_ "$branch_arg" "$proj_folder" &>/dev/null || get_local_branch_ "$branch_arg" "$proj_folder" &>/dev/null; then
    return 0;
  fi

  return 1;
}

function get_local_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( get_local_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local short_branch="$(get_short_name_ "$branch" "$folder")"

  if git -C "$folder" show-ref --verify --quiet "refs/heads/${short_branch}"; then
    if (( get_local_branch_is_f )); then
      echo "refs/heads/${short_branch}"
    else
      echo "$short_branch"
    fi
    return 0;
  fi

  return 1;
}

function get_remote_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( get_remote_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local remote_name="$(get_remote_name_ "$folder")"
  local short_branch="$(get_short_name_ "$branch" "$folder")"

  if git -C "$folder" show-ref --verify --quiet "refs/remotes/${remote_name}/${short_branch}"; then
    if (( get_remote_branch_is_f )); then
      echo "${remote_name}/${short_branch}"
    else
      echo "$short_branch"
    fi
    return 0;
  fi

  return 1;
}

function get_main_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( get_main_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  
  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{main,master,trunk,mainline,default,stable}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      if (( get_main_branch_is_f )); then
        echo "${remote_name}/${ref:t}"
      else
        echo "${ref:t}"
      fi
      return 0;
    fi
  done

  echo "main"
}

function get_my_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "ef" "" "$@")"
  (( get_my_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if ! is_folder_git_ "$folder" &>/dev/null; then return 1; fi
  
  local my_branch="$(git -C "$folder" branch --show-current 2>/dev/null)"
  
  if [[ -z "$my_branch" ]] && (( get_my_branch_is_e )); then
    # this gives off "HEAD" when in detached state
    my_branch="$(git -C "$folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  fi

  if [[ -z "$my_branch" ]]; then
    print " fatal: current branch is detached or not tracking an upstream branch" >&2
    return 1;
  fi

  if (( get_my_branch_is_f )); then
    echo "$(get_remote_branch_ -f "$my_branch" "$folder")"
  else
    echo "$my_branch"
  fi
}

function find_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( find_base_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local my_branch="$2"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local candidate_bases=("main" "master" "stage" "staging" "dev" "develop" "devel" "prod" "production" "release" "trunk" "mainline" "default" "stable")

  if [[ -z "$my_branch" ]]; then
    my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$my_branch" ]]; then return 1; fi
  fi

  local remote_name="$(get_remote_name_ "$folder")"

  local best_ref=""
  local most_recent_time=0

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local ref=""
  local base=""
  for base in "${candidate_bases[@]}"; do
    # Skip if base doesn't exist
    local found=0

    local ref=""
    for ref in refs/{remotes/${remote_name},heads}/$base; do
      if git -C "$folder" show-ref --verify --quiet "$ref"; then
        found=1
        break;
      fi
    done
    if (( ! found )); then
      continue;
    fi

    # Find the common ancestor
    local ancestor_commit="$(git -C "$folder" merge-base "$my_branch" "$ref" 2>/dev/null)"
    if [[ -z "$ancestor_commit" ]]; then
      continue;
    fi

    # Get commit timestamp
    local commit_time="$(git -C "$folder" show -s --format=%ct "$ancestor_commit")"

    # Track the most recent ancestor
    if (( commit_time > most_recent_time )); then
      most_recent_time=$commit_time
      best_ref="$ref"
    fi
  done

  if [[ -n "$best_ref" ]]; then
    if (( find_base_branch_is_f )); then
      echo "$best_ref"
    else
      echo "$(get_short_name_ "$best_ref" "$folder")"
    fi

    return 0;
  fi

  return 1;
}

function is_local_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_local_branch_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then
    print " fatal: branch name is empty" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  if [[ "$branch" == "refs/heads/"* ]] || ! is_remote_branch_name_ "$branch" "$folder"; then
    echo 1 # 1 means true when put into a variable
    return 0;
  fi

  echo 0
  return 1;
}

function is_remote_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_remote_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then
    print " fatal: branch name is empty" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local remote_name="$(get_remote_name_ "$folder")"

  # check if branch has remote_name
  if [[ "$branch" == "$remote_name/"* || "$branch" == "refs/remotes/"* ]]; then
    echo 1 # 1 means true when put into a variable
    return 0;
  fi

  echo 0
  return 1;
}

function is_local_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_local_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then
    print " fatal: branch name is empty" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  # check if branch is listed in local branches
  if git -C "$folder" show-ref --verify --quiet "refs/heads/${branch#refs/heads/}"; then
    echo 1 # 1 means true when put into a variable
    return 0;
  fi

  echo 0
  return 1;
}

function is_remote_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_remote_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then
    print " fatal: branch name is empty" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local short_name="$(get_short_name_ "$branch" "$folder")"

  local ref=""
  for ref in refs/remotes/{origin,upstream}/${short_name}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      echo 1 # 1 means true when put into a variable
      return 0;
    fi
  done

  echo 0
  return 1;
}

function get_short_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_short_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then
    print " fatal: branch name is empty" >&2
    return 1;
  fi

  local remote_name="$(get_remote_name_ "$folder")"

  local short_branch="${branch#refs/}"

  short_branch="${short_branch#remotes/}"
  short_branch="${short_branch#heads/}"
  short_branch="${short_branch#HEAD/}"

  short_branch="${short_branch#$remote_name/}"

  echo "$short_branch"
}

function get_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( get_base_branch_is_debug )) && set -x

  local my_branch="$1"
  local folder="${2:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local short_base_branch=""

  if [[ -n "$my_branch" ]]; then
    local short_my_branch="$(get_short_name_ "$my_branch" "$folder")"

    local base_branch="$(git -C "$folder" config --get branch.$my_branch.gh-merge-base)"
    short_base_branch="$(get_short_name_ "$base_branch" "$folder" 2>/dev/null)"

    if [[ -z "$base_branch" || "$short_my_branch" == "$short_base_branch" ]]; then
      base_branch="$(git -C "$folder" config --get branch.$my_branch.vscode-merge-base)"
      short_base_branch="$(get_short_name_ "$base_branch" "$folder" 2>/dev/null)"

      if [[ -z "$base_branch" || "$short_my_branch" == "$short_base_branch" ]]; then
        base_branch="$(git -C "$folder" config --get branch.$my_branch.gk-merge-target)"
        short_base_branch="$(get_short_name_ "$base_branch" "$folder" 2>/dev/null)"
      fi
    fi
  fi

  if [[ -z "$short_base_branch" ]]; then
    local remote_name="$(get_remote_name_ "$folder")"

    local base_branch="$(git -C "$folder" symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null)"
    short_base_branch="$(get_short_name_ "$base_branch" "$folder" 2>/dev/null)"
  fi

  if [[ -n "$short_base_branch" ]]; then
    if (( get_base_branch_is_f )); then
      echo "$(get_remote_branch_ -f "$short_base_branch" "$folder")"
    else
      echo "$short_base_branch"
    fi
    return 0;
  fi

  print " fatal: could not determine base branch" >&2
  return 1;
}

function get_default_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  # (( get_default_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local default_branch="$(git -C "$folder" symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null)"

  if [[ -z "$default_branch" ]]; then
    default_branch="$(git -C "$folder" config --get init.defaultBranch 2>/dev/null)"
  fi
  
  if [[ -z "$default_branch" ]]; then
    default_branch="$(get_main_branch_ -f "$folder")"
  fi

  if [[ -n "$default_branch" ]]; then
    local short_default_branch="$(get_short_name_ "$default_branch" "$folder")"

    if (( get_default_branch_is_f )); then  
      echo "$(get_remote_branch_ -f "$short_default_branch" "$folder")"
    else
      echo "$short_default_branch"
    fi
    return 0;
  fi

  print " fatal: could not determine default branch" >&2
  return 1;
}

function get_repo_() {
  local folder="${1:-$PWD}"

  if ! is_folder_git_ "$folder" &>/dev/null; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local remote_repo="$(git -C "$folder" remote get-url "$remote_name" 2>/dev/null)"

  if [[ -n "$remote_repo" && "$remote_repo" != "$remote_name" ]]; then
    echo "$remote_repo"
    return 0;
  fi

  print " fatal: could not determine repository" >&2
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
  eval "$(parse_flags_ "$0" "alrixom" "" "$@")"
  (( select_branches_is_debug )) && set -x

  local search_arg="$1"
  local header="$2"
  local folder="${3:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  local exclude_branches=("${@:4}")

  local remote_name="$(get_remote_name_ "$folder")"
  local short_search_arg="$(get_short_name_ "$search_arg" "$folder" 2>/dev/null)"

  local search_text="*$short_search_arg*"
  local grep="-i"

  if (( select_branches_is_r || select_branches_is_x )); then
    search_text="$short_search_arg"
  fi

  if (( select_branches_is_x )); then
    grep="-iFx"
  fi

  local sort=""
  
  if (( select_branches_is_r )); then
    sort="-committerdate"
    if (( select_branches_is_o )); then
      sort="committerdate"
    fi
  else
    sort="-fu"
    if (( select_branches_is_o )); then
      sort="-fur"
    fi
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  # | grep -vFx "$remote_name" - removes "origin" from results, sometimes it shows up

  local output

  if (( select_branches_is_a )); then
    header="remote and local branches $header"

    if (( select_branches_is_x )); then # co command
      output="$(git -C "$folder" branch --all --list "${remote_name}/${search_text}" --list "${search_text}" -i --no-column --format="%(refname:short)" \
        | sed "s#^$remote_name/##" \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | grep -vFx "$remote_name" \
        | LC_ALL=C sort $sort
      )"
    else
      output="$(git -C "$folder" branch --all --list "${remote_name}/${search_text}" --list "${search_text}" -i --no-column --format="%(refname:short)" \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | grep -vFx "$remote_name" \
        | LC_ALL=C sort $sort
      )"
    fi
  elif (( select_branches_is_r )); then
    header="remote branches $header"
    if [[ -n "$search_text" ]]; then
      output="$(git -C "$folder" for-each-ref refs/remotes --sort=$sort --format='%(refname:short)' \
        | grep $grep "$search_text" \
        | grep -vFx "$remote_name"
      )"
    else
      output="$(git -C "$folder" for-each-ref refs/remotes --sort=$sort --format='%(refname:short)' \
        | grep -vFx "$remote_name"
      )"
    fi
  else
    header="local branches $header"
    output="$(git -C "$folder" branch --list "$search_text" -i --no-column --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | LC_ALL=C sort $sort
    )"
  fi

  local branch_results=("${(@f)output}")

  local branches_excluded=("$exclude_branches")

  if (( select_branches_is_m )); then
    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

    if [[ -n "$my_branch" ]]; then
      branches_excluded+=("${my_branch}")
      branches_excluded+=("${remote_name}/${my_branch}")
    fi
  fi

  # if (( ! select_branches_is_a )); then
  #   branches_excluded+=("main" "master")
  #   if (( select_branches_is_r )); then
  #     branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
  #   fi
  # fi

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
    print -n " fatal: did not find " >&2

    if (( select_branches_is_a )); then
      print -n "any remote or local branch" >&2
    elif (( select_branches_is_r )); then
      print -n "a remote branch" >&2
    else
      print -n "a local branch" >&2
    fi

    print -n " known to git" >&2

    if [[ -n "$search_arg" ]]; then
      if (( select_branches_is_x )); then
        print -n ": $search_arg" >&2
      else
        print -n " matching: $search_arg" >&2
      fi
    fi

    print "" >&2
    return 1;
  fi

  local branch_choices=""
  if (( select_branches_is_i )); then
    branch_choices="$(choose_multiple_ -i "$header" "${filtered_branches[@]}")"
  elif (( ${#filtered_branches[@]} == 1 )); then
    if [[ "${filtered_branches[@]}" == */"$short_search_arg" || "${filtered_branches[@]}" == "$short_search_arg" ]]; then
      branch_choices="${filtered_branches[@]}"
    else
      branch_choices="$(choose_one_ "$header" "${filtered_branches[@]}")"
    fi
  else
    branch_choices="$(choose_multiple_ "$header" "${filtered_branches[@]}")"
  fi
  if (( $? == 130 )); then return 130; fi

  echo "${branch_choices[@]}"
}

function select_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "alrixscmjo" "" "$@")"
  (( select_branch_is_debug )) && set -x

  local search_arg="$1"
  local header="$2"
  local folder="${3:-$PWD}"

  folder="$(get_proj_for_git_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  local remote_name="$(get_remote_name_ "$folder")"
  local short_search_arg="$(get_short_name_ "$search_arg" "$folder" 2>/dev/null)"

  local search_text="*$short_search_arg*"
  local grep="-i"

  if (( select_branch_is_r || select_branch_is_x )); then
    search_text="$short_search_arg"
  fi

  if (( select_branch_is_x )); then
    grep="-iFx"
  fi

  local sort=""
  
  if (( select_branch_is_r )); then
    sort="-committerdate"
    if (( select_branch_is_o )); then
      sort="committerdate"
    fi
  else
    sort="-fu"
    if (( select_branch_is_o )); then
      sort="-fur"
    fi
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  # | grep -vFx "$remote_name" - removes "origin" from results, sometimes it shows up

  local output

  if (( select_branch_is_a )); then
    header="remote or local branch $header"

    if (( select_branch_is_c || select_branch_is_x )); then # co command
      output="$(git -C "$folder" branch --all --list "${remote_name}/${search_text}" --list "${search_text}" -i --no-column --format="%(refname:short)" \
        | sed "s#^$remote_name/##" \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | grep -vFx "$remote_name" \
        | LC_ALL=C sort $sort
      )"
    else
      output="$(git -C "$folder" branch --all --list "${remote_name}/${search_text}" --list "${search_text}" -i --no-column --format="%(refname:short)" \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | grep -vFx "$remote_name" \
        | LC_ALL=C sort $sort
      )"
    fi

  elif (( select_branch_is_r )); then
    header="remote branch $header"
    if [[ -n "$search_arg" ]]; then
      output="$(git -C "$folder" for-each-ref refs/remotes --sort=$sort --format='%(refname:short)' \
        | grep $grep "$search_text" \
        | grep -vFx "$remote_name"
      )"
    else
      output="$(git -C "$folder" for-each-ref refs/remotes --sort=$sort --format='%(refname:short)' \
        | grep -vFx "$remote_name"
      )"
    fi
  else
    header="local branch $header"
    output="$(git -C "$folder" branch --list "$search_text" -i --no-column --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | LC_ALL=C sort $sort
    )"
  fi
  
  local branch_results=("${(@f)output}")

  local branches_excluded=()

  if (( select_branch_is_m )); then
    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -n "$my_branch" ]]; then
      branches_excluded+=("${my_branch}")
      branches_excluded+=("${remote_name}/${my_branch}")
    fi
  fi

  if (( select_branch_is_s )); then
    branches_excluded+=("main" "master" "dev" "develop" "stage" "staging" "prod" "production" "release")
    if (( select_branch_is_r )); then
      branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
    fi
  fi

  local filtered_branches=()

  if [[ -n "$branch_results" ]]; then
    local branch=""
    for branch in "${branch_results[@]}"; do
      # exclude branches in branches_excluded
      if [[ -n "$branches_excluded" && " ${branches_excluded[*]} " == *" $branch "* ]]; then
        continue;
      fi

      # only include branches with a JIRA key
      if (( select_branch_is_j )); then
        if [[ -n "$(extract_jira_key_ "$branch")" ]]; then
          filtered_branches+=("$branch")
        fi
      else
        filtered_branches+=("$branch")
      fi
    done
  fi

  if [[ -z "$filtered_branches" ]]; then
    if (( select_branch_is_s )); then
      print -n " fatal: excluding special branches, " >&2
    else
      print -n " fatal: " >&2
    fi

    print -n "did not find " >&2

    if (( select_branch_is_a )); then
      print -n "any remote or local branch" >&2
    elif (( select_branch_is_r )); then
      print -n "a remote branch" >&2
    else
      print -n "a local branch" >&2
    fi

    print -n " known to git" >&2

    if [[ -n "$search_arg" ]]; then
      # search_text="${search_text//\*/}"
      if (( select_branch_is_x )); then
        print -n ": $search_arg" >&2
      else
        print -n " matching: $search_arg" >&2
      fi
    fi

    print "" >&2
    return 1;
  fi

  # current branch if found and it's the only one
  if (( select_branch_is_c )); then
    local current_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if (( ${#filtered_branches[@]} == 1 )) && [[ -n "$current_branch" ]]; then
      local remote_branch="$remote_name/${current_branch}"

      if [[ "${filtered_branches[1]}" == "$remote_branch" || "${filtered_branches[1]}" == "$current_branch" ]]; then
        echo "$current_branch"
        return 0;
      fi
    fi
  fi

  local branch_choice=""

  if (( ${#filtered_branches[@]} > 25 )); then
    branch_choice="$(filter_one_ "$header" "${filtered_branches[@]}")"
  else
    if (( select_branch_is_i )) && [[ -n "$search_arg" ]]; then
      branch_choice="$(choose_one_ -i "$header" "${filtered_branches[@]}")"
    elif (( ${#filtered_branches[@]} == 1 )); then
      if [[ "${filtered_branches[@]}" == */"$search_arg" || "${filtered_branches[@]}" == "$search_arg" ]]; then
        branch_choice="${filtered_branches[@]}"
      else
        branch_choice="$(choose_one_ "$header" "${filtered_branches[@]}")"
      fi
    else
      branch_choice="$(choose_one_ "$header" "${filtered_branches[@]}")"
    fi
  fi
  if (( $? == 130 )); then return 130; fi

  echo "$branch_choice"
}

function select_release_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "x" "" "$@")"
  (( select_release_branch_is_debug )) && set -x

  local branch_arg="$1"
  local type="$2"
  local folder="$3"
  local header="$4"

  if [[ -n "$branch_arg" && $branch_arg =~ ^([0-9]+)(\.([0-9]+))?(\.([0-9]+))?$ ]]; then
    local major=${match[1]}
    local minor=${match[3]}
    local patch=${match[5]}

    if [[ -n "$minor" && -n "$patch" ]]; then
      branch_arg="release/${major}.${minor}.${patch}"
    elif [[ -n "$minor" ]]; then
      branch_arg="release/${major}.${minor}"
    else
      branch_arg="release/${major}"
    fi
  elif [[ -z "$branch_arg" ]]; then
    if (( select_release_branch_is_x )); then
      branch_arg="release/"
    elif [[ -z "$branch_arg" ]] && [[ "$type" == "prod" || "$type" == "pre" ]]; then
      branch_arg="release/"
    elif [[ -n "$type" ]]; then
      branch_arg="$type"
    fi
  fi

  local branch=""
  branch="$(select_branch_ -rix "$branch_arg" "$header" "$folder")"
  if (( $? == 130 )); then return 130; fi

  echo "$(get_short_name_ "$branch" "$folder")"
}

function get_from_package_json_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_from_package_json_is_debug )) && set -x

  local key_path="$1"
  local folder="${2:-$PWD}"

  if ! is_folder_pkg_ "$folder" &>/dev/null; then return 1; fi

  local section=""
  local key_name="$key_path"

  # check if key_path contains a dot
  if [[ "$key_path" == *.* ]]; then
    section="${key_path%%.*}"
    key_name="${key_path#*.}"
  fi

  local value=""

  local npm_version="$(npm --version 2>/dev/null)"
  if is_version_higher_ "$npm_version" 7.20; then
    if [[ -n "$section" ]]; then key_name="$section.$key_name"; fi
    value="$(npm --prefix "$folder" pkg get $key_name --workspaces=false | tr -d '"' 2>/dev/null)"

    if [[ "$value" == "{}" ]]; then value=""; fi

    echo "$value"
    return 0;
  fi

  local real_file="$(realpath -- "${folder}/package.json" 2>/dev/null)"
  if [[ -z "$real_file" ]]; then return 1; fi

  if command -v jq &>/dev/null; then
    if [[ -n "$section" ]]; then
      value="$(jq -r --arg section "$section" --arg key "$key_name" '.[$section][$key] // empty' "$real_file" 2>/dev/null)"
    else
      value="$(jq -r --arg key "$key_name" '.[$key] // empty' "$real_file" 2>/dev/null)"
    fi
  else
    # Escape the key for safe regex matching
    local escaped_key="$(printf '%s\n' "$key_name" | sed 's/[][\.*^$/]/\\&/g')"

    # Use grep with improved quoting and fallback to sed
    value=$(grep -E "\"$escaped_key\"[[:space:]]*:[[:space:]]*\"" "$real_file" | \
      head -1 | \
      sed -E "s/.*\"$escaped_key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/"
    2>/dev/null)
  fi

  if [[ "$value" == "{}" ]]; then value=""; fi

  echo "$value"
}

function load_config_entry_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  # (( load_config_entry_is_debug )) && set -x

  local i="$1"
  local key="$2"

  local value=""

  if (( i > 0 && i < 10 )); then
    value="$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    value="$(trim_ "$value")"
  fi

  # if value is not provided, use default value for specific keys
  if (( load_config_entry_is_d )) && [[ -z "$value" ]]; then
    case "$key" in
      SINGLE_MODE)
        value=1
        ;;
      PUMP_PKG_MANAGER)
        value="$(detect_pkg_manager_ "$PWD")"
        if [[ -z "$value" ]]; then value="npm"; fi
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
      PUMP_PR_TEMPLATE_FILE)
        value=".github/pull_request_template.md"
        ;;
      PUMP_PR_TITLE_FORMAT)
        value="<jira_key> <jira_title>"
        ;;
      PUMP_JIRA_TODO)
        value="To do"
        ;;
      PUMP_JIRA_IN_PROGRESS)
        value="In Progress"
        ;;
      PUMP_JIRA_IN_REVIEW)
        value="Code Review"
        ;;
      PUMP_JIRA_IN_TEST)
        value="Ready for Test"
        ;;
      PUMP_JIRA_ALMOST_DONE)
        value="Ready for Production"
        ;;
      PUMP_JIRA_DONE)
        value="Done"
        ;;
      PUMP_JIRA_CANCELED)
        value="Canceled"
        ;;
      PUMP_SKIP_DETECT_NODE)
        value="0"
        ;;
    esac
  fi

  echo "$value"
}

function load_config_index_() {
  set +x

  local i="$1"

  if [[ -z "$i" ]]; then return 1; fi

  local keys=(
    PUMP_SINGLE_MODE
    PUMP_PKG_MANAGER # make sure pkg_manager is before anything
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
    PUMP_PR_TITLE_FORMAT
    PUMP_PR_REPLACE
    PUMP_PR_APPEND
    PUMP_PR_APPROVAL_MIN
    PUMP_COMMIT_SIGNOFF
    PUMP_PKG_NAME
    PUMP_JIRA_PROJECT
    PUMP_JIRA_API_TOKEN
    PUMP_JIRA_STATUSES
    PUMP_JIRA_TODO
    PUMP_JIRA_IN_PROGRESS
    PUMP_JIRA_IN_REVIEW
    PUMP_JIRA_IN_TEST
    PUMP_JIRA_ALMOST_DONE
    PUMP_JIRA_DONE
    PUMP_JIRA_CANCELED
    PUMP_JIRA_PULL_SUMMARY
    PUMP_JIRA_WORK_TYPES
    PUMP_SKIP_DETECT_NODE
    PUMP_NVM_USE_V
    PUMP_SCRIPT_FOLDER
  )

  local key=""
  for key in "${keys[@]}"; do
    local value="$(load_config_entry_ -d $i "$key")"

    # store the value
    case "$key" in
      PUMP_SINGLE_MODE)
        PUMP_SINGLE_MODE[$i]="$value"
        ;;
      PUMP_PKG_MANAGER)
        PUMP_PKG_MANAGER[$i]="$value"
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
        if [[ "$value" != <-> ]]; then value=0; fi
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
      PUMP_PR_TITLE_FORMAT)
        PUMP_PR_TITLE_FORMAT[$i]="$value"
        ;;
      PUMP_PR_REPLACE)
        PUMP_PR_REPLACE[$i]="$value"
        ;;
      PUMP_PR_APPEND)
        if [[ "$value" != <-> ]]; then value=0; fi
        PUMP_PR_APPEND[$i]="$value"
        ;;
      PUMP_PR_APPROVAL_MIN)
        if [[ "$value" != <-> ]]; then value=0; fi
        PUMP_PR_APPROVAL_MIN[$i]="$value"
        ;;
      PUMP_COMMIT_SIGNOFF)
        if [[ "$value" != <-> ]]; then value=0; fi
        PUMP_COMMIT_SIGNOFF[$i]="$value"
        ;;
      PUMP_PKG_NAME)
        PUMP_PKG_NAME[$i]="$value"
        ;;
      PUMP_JIRA_PROJECT)
        PUMP_JIRA_PROJECT[$i]="$value"
        ;;
      PUMP_JIRA_API_TOKEN)
        PUMP_JIRA_API_TOKEN[$i]="$value"
        ;;
      PUMP_JIRA_STATUSES)
        PUMP_JIRA_STATUSES[$i]="$value"
        ;;
      PUMP_JIRA_TODO)
        PUMP_JIRA_TODO[$i]="$value"
        ;;
      PUMP_JIRA_IN_PROGRESS)
        PUMP_JIRA_IN_PROGRESS[$i]="$value"
        ;;
      PUMP_JIRA_IN_REVIEW)
        PUMP_JIRA_IN_REVIEW[$i]="$value"
        ;;
      PUMP_JIRA_IN_TEST)
        PUMP_JIRA_IN_TEST[$i]="$value"
        ;;
      PUMP_JIRA_ALMOST_DONE)
        PUMP_JIRA_ALMOST_DONE[$i]="$value"
        ;;
      PUMP_JIRA_DONE)
        PUMP_JIRA_DONE[$i]="$value"
        ;;
      PUMP_JIRA_CANCELED)
        PUMP_JIRA_CANCELED[$i]="$value"
        ;;
      PUMP_JIRA_PULL_SUMMARY)
        if [[ "$value" != <-> ]]; then value=0; fi
        PUMP_JIRA_PULL_SUMMARY[$i]="$value"
        ;;
      PUMP_JIRA_WORK_TYPES)
        PUMP_JIRA_WORK_TYPES[$i]="$value"
        ;;
      PUMP_SKIP_DETECT_NODE)
        if [[ "$value" != <-> ]]; then value=0; fi
        PUMP_SKIP_DETECT_NODE[$i]="$value"
        ;;
      PUMP_NVM_USE_V)
        PUMP_NVM_USE_V[$i]="$value"
        ;;
      PUMP_SCRIPT_FOLDER)
        PUMP_SCRIPT_FOLDER[$i]="$value"
        ;;
    esac
    # print "$i - key: [$key], value: [$value]"
  done
}

function load_settings_() {
  check_settings_file_

  PUMP_AUTO_DETECT_NODE="$(sed -n "s/^PUMP_AUTO_DETECT_NODE=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_AUTO_DETECT_NODE" -ne 0 && "$PUMP_AUTO_DETECT_NODE" -ne 1 ]]; then
    PUMP_AUTO_DETECT_NODE=1
  fi

  PUMP_CODE_EDITOR="$(sed -n "s/^PUMP_CODE_EDITOR=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_CODE_EDITOR" -ne 0 && "$PUMP_CODE_EDITOR" -ne 1 ]]; then
    PUMP_CODE_EDITOR=""
  fi

  PUMP_MERGE_TOOL="$(sed -n "s/^PUMP_MERGE_TOOL=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_MERGE_TOOL" -ne 0 && "$PUMP_MERGE_TOOL" -ne 1 ]]; then
    PUMP_MERGE_TOOL=""
  fi

  PUMP_PUSH_NO_VERIFY="$(sed -n "s/^PUMP_PUSH_NO_VERIFY=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_PUSH_NO_VERIFY" -ne 0 && "$PUMP_PUSH_NO_VERIFY" -ne 1 ]]; then
    PUMP_PUSH_NO_VERIFY=""
  fi

  PUMP_PUSH_SET_UPSTREAM="$(sed -n "s/^PUMP_PUSH_SET_UPSTREAM=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_PUSH_SET_UPSTREAM" -ne 0 && "$PUMP_PUSH_SET_UPSTREAM" -ne 1 ]]; then
    PUMP_PUSH_SET_UPSTREAM=""
  fi

  PUMP_RUN_OPEN_COV="$(sed -n "s/^PUMP_RUN_OPEN_COV=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ "$PUMP_RUN_OPEN_COV" -ne 0 && "$PUMP_RUN_OPEN_COV" -ne 1 ]]; then
    PUMP_RUN_OPEN_COV=""
  fi

  PUMP_USE_MONOGRAM="$(sed -n "s/^PUMP_USE_MONOGRAM=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ ! "$PUMP_USE_MONOGRAM" =~ ^[a-zA-Z]{1,2}$ ]]; then
    PUMP_USE_MONOGRAM=""
  fi

  PUMP_INTERVAL="$(sed -n 's/^PUMP_INTERVAL[[:space:]]*="\(.*\)"/\1/p' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  if [[ -z "$PUMP_INTERVAL" ]]; then
    PUMP_INTERVAL=20
  fi
}

function load_config_() {
  load_config_index_ 0

  # Iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    proj_cmd="$(sed -n "s/^PUMP_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    proj_cmd="$(trim_ "$proj_cmd")"
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi
    
    # skip if not defined
    if [[ -z "$proj_cmd" ]]; then continue; fi

    if ! validate_proj_cmd_strict_ $i "$proj_cmd"; then
      print "  ${red_cor}in config: PUMP_SHORT_NAME_${i}${reset_cor}" 2>/dev/tty
      print "  edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project repo
    local proj_repo=""
    proj_repo="$(sed -n "s/^PUMP_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    proj_repo="$(trim_ "$proj_repo")"
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_REPO_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # Set project folder path
    local proj_folder=""
    proj_folder="$(sed -n "s/^PUMP_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    proj_folder="$(trim_ "$proj_folder")"
    
    if (( $? != 0 )); then
      print " ${red_cor}error in config: PUMP_FOLDER_${i}${reset_cor}" 2>/dev/tty
      print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
      continue;
    fi

    # skip if not defined
    if [[ -z "$proj_folder" ]]; then continue; fi

    proj_folder="${proj_folder%/}"

    PUMP_SHORT_NAME[$i]="$proj_cmd"
    PUMP_FOLDER[$i]="$proj_folder"
    PUMP_REPO[$i]="$proj_repo"

    load_config_index_ $i
  done
}

function get_my_branch_status_() {
  local my_branch="$1"
  local base_branch="$2"
  local folder="${3:-$PWD}"

  local behind=0
  local ahead=0
  
  read behind ahead < <(git -C "$folder" rev-list --left-right --count ${base_branch}...${my_branch} 2>/dev/null)

  print -r -- "${behind}${TAB}${ahead}"
}

function del_file_() {
  set +x
  eval "$(parse_single_flags_ "$0" "f" "" "$@")"
  (( del_file_is_debug )) && set -x

  local file="$1"
  local count="$2"
  local total="$3"

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
    if (( ! del_file_is_f )) || [[ "$type" == "folder" && -n "$(ls -A -- "$file" 2>/dev/null)" ]]; then
      confirm_ "delete $type: ${green_cor}$file${reset_cor} ?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET != 0 )); then
        if (( total > 1 )); then
          print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
        fi
        return 1;
      fi
    fi
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... ${green_cor}$file${reset_cor}" -- rm -rf -- "$file"
    RET=$?
  else
    print " deleting... ${green_cor}$file${reset_cor}"
    rm -rf -- "$file"
    RET=$?
  fi

  if (( RET == 0 )); then
    if [[ "$file" == "$PWD" ]]; then
      print -l -- " ${yellow_cor}deleted${reset_cor} $file"
      cd ..
    else
      print -l -- " ${magenta_cor}deleted${reset_cor} $file"
    fi
    return 0;
  fi

  print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  return 1;
}

function del_files_() {
  set +x
  eval "$(parse_single_flags_ "$0" "f" "x" "$@")"
  (( del_files_is_debug )) && set -x

  local files=("$@")

  local dont_ask=0
  local count=0
  local delete_all=0

  local RET=0

  local file=""
  for file in "${files[@]}"; do
    if (( RET == 0 && ! del_files_is_f )); then
      ((count++))
    fi

    local a_file="" # abolute file path

    if [[ -L "$file" ]]; then
      a_file="$(realpath -- "$file" 2>/dev/null)"
    else
      file="$(realpath -- "$file" 2>/dev/null)"
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
      if (( delete_all || del_files_is_f )); then
        del_file_ -f -- "$file" "${#files[@]}"
      else
        del_file_ -- "$file" "$count" "${#files[@]}"
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi

    if [[ -n "$a_file" ]]; then
      if (( delete_all || del_files_is_f )); then
        del_file_ -f -- "$file" "${#files[@]}"
      else
        del_file_ -- "$file" "$count" "${#files[@]}"
      fi
      RET=$?
      if (( RET == 130 )); then break; fi
    fi
  done

  return $RET;
}

function del() {
  set +x
  eval "$(parse_single_flags_ "$0" "f" "x" "$@")"
  (( del_is_debug )) && set -x

  if (( del_is_h )); then
    print "  ${hi_yellow_cor}del ${yellow_cor}[<glob>]${reset_cor} : delete files/folders"
    print "  --"
    print "  ${hi_yellow_cor}del -f${reset_cor} : skip confirmation (files only)"
    return 0;
  fi

  rm -rf -- ".DS_Store"

  if [[ -n "$1" ]]; then
    local check_arg="${1//\/}";
    if [[ -z "$check_arg" ]]; then
      return 1;
    fi
  fi

  local files

  if [[ -z "$1" ]]; then
    if (( del_is_f )); then
      print " fatal: del -f requires at least 1 file" >&2
      print " run: ${hi_yellow_cor}del -h${reset_cor} to see usage" >&2
      return 1;
    fi

    setopt null_glob
    setopt dot_glob
    # setopt no_dot_glob

    # capture all files in current folder
    files=(*)

    # unsetopt null_glob
    # unsetopt dot_glob
    # unsetopt no_dot_glob

    if (( ${#files[@]} > 1 )); then
      files="$(choose_multiple_ "files to delete" "${files[@]}")"
      if (( $? == 130 )); then return 130; fi
      files=("${(@f)files}")
    fi
  else
    # capture all arguments (quoted or not) as a single pattern
    local pattern="$*"
    # expand the pattern — if it's a glob, this expands to matches
    files=(${(z)~pattern})

    # if (( del_is_f && ! del_is_x )); then
    #   local f=""
    #   for f in "${files[@]}"; do
    #     if [[ "$f" != -[a-zA-Z] && -d "$f" ]]; then
    #       print " fatal: del -f cannot be used to delete folders: $f" >&2
    #       print " run: ${hi_yellow_cor}del -h${reset_cor} to see usage" >&2
    #       return 1;
    #     fi
    #   done
    # fi
  fi

  # print "files[1] = ${files[1]}"
  # print "pattern $pattern"
  # print "qty ${#files[@]}"
  # print "files @ ${files[@]}"
  # print "files * ${files[*]}"
  # return 0;

  if (( ${#files[@]} == 0 )); then
    return 0;
  fi

  if (( del_is_f || del_is_x )); then
    if (( del_is_x )); then
      del_files_ -f -x -- "${files[@]}"
    else
      del_files_ -f -- "${files[@]}"
    fi
    return $?;
  fi

  del_files_ -- "${files[@]}"
  return $?;
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

  local options="$(softwareupdate --list-full-installers 2>/dev/null | grep -E '^\* Title:' | sed -E 's/^\* Title: (.*), Size:.*/\1/' 2>/dev/null)"

  if [[ -z "$options" ]]; then
    options="$(sudo softwareupdate --list-full-installers 2>/dev/null | grep -E '^\* Title:' | sed -E 's/^\* Title: (.*), Size:.*/\1/' 2>/dev/null)"
    
    if [[ -z "$options" ]]; then
      print " fatal: no macOS updates available, try again later" >&2
      return 1;
    fi
  fi

  local choice=""
  choice="$(choose_one_ "macOS version to install" "${(@f)options}")"
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
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( upgrade_is_debug )) && set -x

  if (( upgrade_is_h )); then
    print "  ${hi_yellow_cor}upgrade${reset_cor} : upgrade pump and Oh My Zsh!"
    return 0;
  fi

  upgrade_ -f
  omz update
}

function fix() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( fix_is_debug )) && set -x

  if (( fix_is_h )); then
    print "  ${hi_yellow_cor}fix ${yellow_cor}[<folder>]${reset_cor} : run fix script or format + lint"
    print "  --"
    print "  ${hi_yellow_cor}fix -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run: ${hi_yellow_cor}fix -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_pkg_ "$folder"; then return 1; fi

  if ! fix_it_ "$folder" $@; then
    print " ${red_cor}fatal: fix failed${reset_cor}" >&2
    return 1;
  fi
}

function fix_it_() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( fix_it_is_debug )) && set -x

  local folder="$1"

  local _pwd="$PWD"

  add-zsh-hook -d chpwd pump_chpwd_ &>/dev/null
  cd "$folder"

  local pump_fix="$CURRENT_PUMP_FIX"
  local RET=0

  if [[ -n "$pump_fix" ]]; then
    if (( fix_it_is_q )) && command -v gum &>/dev/null; then
      unsetopt monitor
      unsetopt notify
      local pipe_name="$(mktemp -u)"
      mkfifo "$pipe_name" &>/dev/null
      gum spin --title="${script_cor}${pump_fix}${reset_cor}" -- sh -c "read < $pipe_name" &
      local spin_pid=$!

      eval "$pump_fix" &>/dev/null
      RET=$?
      
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null
      setopt notify
      setopt monitor
    elif (( fix_it_is_q )); then
      eval "$pump_fix" &>/dev/null
      RET=$?
    else
      print " ${script_cor}${pump_fix}${reset_cor}"
      eval "$pump_fix"
      RET=$?
    fi
  else
    RET=1
    if format_ "$folder" $@; then
      if lint_ "$folder" $@; then
        if format_ "$folder" $@; then
          RET=0
        fi
      fi
    fi
  fi

  cd "$_pwd"
  add-zsh-hook chpwd pump_chpwd_ &>/dev/null

  return $RET;
}

function format_() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( format_is_debug )) && set -x

  local folder="$1"

  if [[ -z "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local pkg_manager="$CURRENT_PUMP_PKG_MANAGER$([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo " run")"

  local _prettierfix="$(get_from_package_json_ "scripts.prettier:fix" "$folder")"
  local _formatfix="$(get_from_package_json_ "scripts.format:fix" "$folder")"
  local _prettier="$(get_from_package_json_ "scripts.prettier" "$folder")"
  local _format="$(get_from_package_json_ "scripts.format" "$folder")"

  local script=""

  if [[ -n "$_prettierfix" ]]; then
    script="$pkg_manager prettier:fix"
  elif [[ -n "$_formatfix" ]]; then
    script="$pkg_manager format:fix"
  elif [[ -n "$_prettier" ]]; then
    script="$pkg_manager prettier"
  elif [[ -n "$_format" ]]; then
    script="$pkg_manager format"
  else
    print " fatal: missing formatting scripts in package.json: \"prettier:fix\", \"prettier\", \"format:fix\" or \"format\"" >&2
    return 1;
  fi

  eval_script_ "$script" $@
}

function lint_() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"

  local folder="$1"

  if [[ -z "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local pkg_manager="$CURRENT_PUMP_PKG_MANAGER$([[ $CURRENT_PUMP_PKG_MANAGER == "yarn" ]] && echo "" || echo " run")"

  local _lintfix="$(get_from_package_json_ "scripts.lint:fix" "$folder")"
  local _lint="$(get_from_package_json_ "scripts.lint" "$folder")"
  local _eslintfix="$(get_from_package_json_ "scripts.eslint:fix" "$folder")"
  local _eslint="$(get_from_package_json_ "scripts.eslint" "$folder")"

  local script=""

  if [[ -n "$_lintfix" ]]; then
    script="$pkg_manager lint:fix"
  elif [[ -n "$_eslintfix" ]]; then
    script="$pkg_manager eslint:fix"
  elif [[ -n "$_lint" ]]; then
    script="$pkg_manager lint"
  elif [[ -n "$_eslint" ]]; then
    script="$pkg_manager eslint"
  else
    print " fatal: missing linting scripts in package.json: \"lint:fix\", \"lint\", \"eslint:fix\" or \"eslint\"" >&2
    return 1;
  fi

  eval_script_ "$script" $@
}

function eval_script_() {
  set +x
  eval "$(parse_flags_ "$0" "q" "" "$@")"

  local script="$1"

  local RET=0

  if (( eval_script_is_q )) && command -v gum &>/dev/null; then
    unsetopt monitor
    unsetopt notify
    local pipe_name="$(mktemp -u)"
    mkfifo "$pipe_name" &>/dev/null
    gum spin --title="${script_cor}${script}${reset_cor}" -- sh -c "read < $pipe_name" &
    local spin_pid=$!

    eval "$script" &>/dev/null
    RET=$?
    
    echo "done" > "$pipe_name" &>/dev/null
    rm "$pipe_name"
    wait $spin_pid &>/dev/null
    setopt notify
    setopt monitor

  elif (( eval_script_is_q )); then
    eval "$script" &>/dev/null
    RET=$?

  else
    print " ${script_cor}${script}${reset_cor}"
    eval "$script"
    RET=$?
  fi

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
      print " run: ${hi_yellow_cor}refix -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  if ! is_folder_pkg_ "$folder"; then return 1; fi

  if ! fix "$folder" $@; then
    print " ${red_cor}refix aborted${reset_cor}" >&2
    return 1;
  fi

  if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( ! refix_is_q )); then
      print " nothing to commit, working tree clean" >&2
    fi
    return 1;
  fi

  local amend=0
  local cannot_amend=0
  local commit_msg="style: lint and format"

  if (( ! refix_is_n )); then
    amend=1
  fi

  if (( amend )); then
    local last_commit_msg="$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs 2>/dev/null)"
    if [[ -z "$last_commit_msg" ]]; then
      last_commit_msg="$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' | xargs -0 2>/dev/null)"
    fi

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

  local folder="$PWD"

  if ! is_folder_pkg_ "$folder"; then return 1; fi
  if ! is_folder_git_ "$folder"; then return 1; fi

  local i="$(find_proj_index_ -x "$CURRENT_PUMP_SHORT_NAME")"
  (( i )) || return 1;

  if ! check_proj_ -frvmp $i; then return 1; fi 

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  local proj_repo="${PUMP_REPO[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"
  local pump_cov="${PUMP_COV[$i]}"
  local pump_setup="${PUMP_SETUP[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " ${red_cor}PUMP_REPO_$i is missing${reset_cor}" >&2
    print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  if [[ -z "$pump_cov" ]]; then
    print " ${red_cor}PUMP_COV_$i is missing${reset_cor}" >&2
    print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch_arg="$1"

  if [[ -n "$branch_arg" ]]; then
    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi
  fi

  local short_branch_arg="$(get_short_name_ "$branch_arg" "$folder")"
  local remote_branch_arg="$(get_remote_branch_ -f "$branch_arg" "$folder")"

  if [[ -z "$remote_branch_arg" ]]; then
    print " fatal: not a valid branch argument" >&2
    print " run: ${hi_yellow_cor}cov -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
  if [[ -z "$repo_name" ]]; then
    print " fatal: invalid repository url: $proj_repo" >&2
    return 1;
  fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  if [[ "$short_branch_arg" == "$my_branch" ]]; then
    print " branch argument is current branch: $my_branch" >&2
    return 1;
  fi

  local branch_behind=0
  local branch_ahead=0

  local output="$(get_my_branch_status_ "$my_branch" "$remote_branch_arg" "$folder")"
  IFS=$TAB read -r branch_behind branch_ahead <<<"$output"

  if (( branch_behind )); then
    print " ${yellow_cor}warning:${reset_cor} your branch is behind $branch_arg by ${bold_cor}$branch_behind${reset_cor} commits" >&2
    if ! confirm_ "continue anyway?" "continue" "abort"; then
      return 1;
    fi
  fi

  local cov_folder="$(get_proj_special_folder_ -c $i "$proj_cmd" "$proj_folder")"

  unsetopt monitor
  unsetopt notify

  local pipe_name="$(mktemp -u)"
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${my_branch}" -- sh -c "read < $pipe_name" &
  local spin_pid=$!

  if ! eval "$pump_setup" &>/dev/null; then
    echo "done" > "$pipe_name" &>/dev/null
    rm "$pipe_name"
    wait $spin_pid &>/dev/null

    print " ${red_cor}fatal: could not run setup script: $pump_setup${reset_cor}" >&2
    return 1;
  fi

  if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
    # run twice just in case the first run fails
    if ! eval "$pump_cov" --coverageReporters=text-summary > "coverage-summary.txt" 2>&1; then
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null

      print " ${red_cor}fatal: could not run coverage script PUMP_COV_${i}${reset_cor}" >&2
      return 1;
    fi
  fi

  print "   running test coverage... ${my_branch}"

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  local summary2="$(grep -A 4 "Coverage summary" "coverage-summary.txt")"

  # extract each coverage percentage
  local statements2="$(echo "$summary2" | grep "Statements" | awk '{print $3}' | tr -d '%')"
  local branches2="$(echo "$summary2" | grep "Branches" | awk '{print $3}' | tr -d '%')"
  local funcs2="$(echo "$summary2" | grep "Functions" | awk '{print $3}' | tr -d '%')"
  local lines2="$(echo "$summary2" | grep "Lines" | awk '{print $3}' | tr -d '%')"

  rm -f -- "coverage-summary.txt" &>/dev/null

  pipe_name="$(mktemp -u)"
  mkfifo "$pipe_name" &>/dev/null

  gum spin --title="running test coverage... ${branch_arg}" -- sh -c "read < $pipe_name" &
  spin_pid=$!

  if is_folder_git_ "$cov_folder" &>/dev/null; then
    reseta -o "$cov_folder" --quiet &>/dev/null
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  fi

  if git -C "$cov_folder" switch "$branch_arg" --quiet &>/dev/null; then
    if ! pullr "$cov_folder" --quiet &>/dev/null; then
      rm -rf -- "$cov_folder" &>/dev/null
      git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
      if (( $? != 0 )); then
        print " fatal: failed to clone ${repo_name}" >&2
        return 1;
      fi
    fi
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  fi

  add-zsh-hook -d chpwd pump_chpwd_ &>/dev/null
  pushd "$cov_folder" &>/dev/null
  
  if [[ -n "$pump_clone" ]]; then
    eval "$pump_clone" &>/dev/null;
  fi

  if [[ -z "$pump_setup" ]]; then
    pump_setup="$(get_from_package_json_ "scripts.setup" "$cov_folder")"
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
    add-zsh-hook chpwd pump_chpwd_ &>/dev/null
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
      add-zsh-hook chpwd pump_chpwd_ &>/dev/null
      return 1;
    fi
  fi

  print "   running test coverage... ${branch_arg}"

  echo "done" > "$pipe_name" &>/dev/null
  # kill $spin_pid &>/dev/null
  rm "$pipe_name"
  wait $spin_pid &>/dev/null

  local summary1="$(grep -A 4 "Coverage summary" "coverage-summary.txt")"

  # extract each coverage percentage
  local statements1="$(echo "$summary1" | grep "Statements" | awk '{print $3}' | tr -d '%')"
  local branches1="$(echo "$summary1" | grep "Branches" | awk '{print $3}' | tr -d '%')"
  local funcs1="$(echo "$summary1" | grep "Functions" | awk '{print $3}' | tr -d '%')"
  local lines1="$(echo "$summary1" | grep "Lines" | awk '{print $3}' | tr -d '%')"

  rm -f -- "coverage-summary.txt" &>/dev/null

  popd &>/dev/null
  add-zsh-hook chpwd pump_chpwd_ &>/dev/null

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

  trap 'print ""; return 130' INT

  if ! is_folder_pkg_; then return 1; fi

  if [[ -z "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  if [[ -n "$CURRENT_PUMP_TEST" && "$CURRENT_PUMP_TEST" != "$CURRENT_PUMP_PKG_MANAGER test" ]]; then
    test_script="$CURRENT_PUMP_TEST"
  else
    test_script="$(get_from_package_json_ "scripts.test")"
  fi

  (eval "$CURRENT_PUMP_TEST" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test passed on first run${reset_cor}"
    return 0;
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

  if [[ -z "$PUMP_RUN_OPEN_COV" && -n "$CURRENT_PUMP_OPEN_COV" ]]; then
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
    print "  ${hi_yellow_cor}cov <branch>${reset_cor} : compare test coverage of current local branch with a given branch"
    print "  ${hi_yellow_cor}cov${reset_cor} : run $(truncate_ "$CURRENT_PUMP_COV")"
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

  trap 'print ""; return 130' INT

  if ! is_folder_pkg_; then return 1; fi

  (eval "$CURRENT_PUMP_COV" $@)
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test coverage passed on first run${reset_cor}"

    if (( PUMP_RUN_OPEN_COV && ! cov_is_o )) || (( ! PUMP_RUN_OPEN_COV && cov_is_o )); then
      if [[ -z "$CURRENT_PUMP_OPEN_COV" ]]; then
        print " PUMP_OPEN_COV is not set" >&2
        print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
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
          print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
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
  eval "$(parse_flags_ "$0" "tasb" "" "$@")"
  (( add_is_debug )) && set -x

  if (( add_is_h )); then
    print "  ${hi_yellow_cor}add ${yellow_cor}[<glob>]${reset_cor} : add files to index"
    print "  --"
    print "  ${hi_yellow_cor}add -a${reset_cor} : add all tracked and untracked files"
    print "  ${hi_yellow_cor}add -t${reset_cor} : add only tracked files"
    print "  ${hi_yellow_cor}add -ta${reset_cor} : add all tracked files (not untracked)"
    print "  ${hi_yellow_cor}add -sb${reset_cor} : show git status in short-format"
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  local files

  if [[ -z "$1" ]]; then
    setopt null_glob
    setopt dot_glob

    # add -t
    if (( add_is_t )); then
      files="$(git -C "$folder" diff --name-only)"
    else
      files="$(git -C "$folder" status --porcelain | awk '$1 == "??" || $1 == "M" { print $2 }')"
    fi
    files=("${(@f)files}")

    if (( ! add_is_a && ${#files[@]} > 1 )); then
      files="$(choose_multiple_ "files to add" "${files[@]}" "$folder")"
      if (( $? == 130 )); then return 130; fi

      files=("${(@f)files}")
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

  git -C "$folder" add -- "${files[@]}"

  if (( add_is_s && add_is_b )); then
    st -sb "$folder"
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

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  local files=()

  if [[ -z "$1" ]]; then
    setopt null_glob
    setopt dot_glob

    # rem -t
    local output
    if (( rem_is_t )); then
      output="$(git -C "$folder" diff --name-only)"
    else
      output="$(git -C "$folder" diff --name-only --cached)"
    fi
    files=("${(@f)output}")

    if (( ! rem_is_a && ${#files[@]} > 1 )); then
      output="$(choose_multiple_ "files to remove" "${files[@]}")"
      if (( $? == 130 )); then return 130; fi
      
      files=("${(@f)output}")
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
    if git -C "$folder" ls-files --error-unmatch -- "$file" &>/dev/null; then
      git -C "$folder" rm --cached -- "$file"
    else
      git -C "$folder" restore --staged -- "$file"
    fi
  done

  if (( ! rem_is_q )); then
    if (( rem_is_s && rem_is_b )); then
      st -sb "$folder"
    else
      st "$folder"
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
      print " run: ${hi_yellow_cor}reset1 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -1
  git -C "$folder" reset --soft --quiet HEAD~1 $@
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
      print " run: ${hi_yellow_cor}reset2 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -2
  git -C "$folder" reset --soft --quiet HEAD~2 $@
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
      print " run: ${hi_yellow_cor}reset3 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -3
  git -C "$folder" reset --soft --quiet HEAD~3 $@
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
      print " run: ${hi_yellow_cor}reset4 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -4
  git -C "$folder" reset --soft --quiet HEAD~4 $@
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
      print " run: ${hi_yellow_cor}reset5 -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -5
  git -C "$folder" reset --soft --quiet HEAD~5 $@
}

function read_commits_() {
  set +x
  eval "$(parse_flags_ "$0" "t" "" "$@")"
  (( read_commits_is_debug )) && set -x
  
  local my_branch="$1"
  local target_branch="$2"
  local folder="${3:-$PWD}"

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -z "$my_branch" ]]; then
    local my_branch="$(get_my_branch_ -e "$folder" 2>/dev/null)"
  fi

  if [[ -z "$target_branch" ]]; then
    local target_branch="$(find_base_branch_ -f "$folder" 2>/dev/null)"
    if [[ -z "$target_branch" ]]; then
      print " fatal: cannot read commits with no target branch" >&2
      return 1;
    fi
  else
    local short_base_branch="$(get_short_name_ "$target_branch" "$folder")"
    target_branch="$(get_remote_branch_ -f "$short_base_branch" "$folder")"
  fi

  local short_my_branch="$(get_short_name_ "$my_branch" "$folder")"
  local short_target_branch="$(get_short_name_ "$target_branch" "$folder")"

  if [[ "$short_my_branch" == "$short_target_branch" ]]; then
    return 1;
  fi

  local pr_title_jira_key=""
  local pr_title_rest=""
  local commit_message=""

  git -C "$folder" --no-pager log --no-graph --oneline --no-merges --reverse --pretty=format:'%H%x1F%s%x00' \
    "${target_branch}..${my_branch}" | while IFS= read -r -d '' line; do
    
    local commit_hash="${line%%$'\x1F'*}"
    commit_hash="${commit_hash//$'\n'/}"
    
    commit_message="${line#*$'\x1F'}"

    commit_message="$(trim_ "$commit_message")"

    if [[ -z "$commit_message" ]]; then
      continue;
    fi

    local commit_message_rest="$commit_message"
    local commit_jira_key="$(extract_jira_key_ "$commit_message")"
    
    if [[ -n "$commit_jira_key" ]]; then
      if [[ -z "$pr_title_jira_key" ]]; then
        pr_title_jira_key="$commit_jira_key"
      fi

      commit_message_rest="$(trim_ "${commit_message//$commit_jira_key/}")"

      if [[ -z "$pr_title_rest" ]]; then
        pr_title_rest="$commit_message_rest"

        local types="fix|feat|docs|refactor|test|chore|style|revert"
        if [[ $commit_message_rest =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}})(\([^)]*\))?!?:[[:space:]]*(.*)" ]]; then
          pr_title_rest="${match[3]}"
        fi
      fi
    else
      if [[ -z "$pr_title_rest" ]]; then
        pr_title_rest="$commit_message"
      fi
    fi

    if (( ! read_commits_is_t )); then
      print -r -- "- $commit_hash - $commit_message_rest"
    fi
  done

  if (( read_commits_is_t )); then
    if [[ -z "$pr_title_rest" ]]; then return 1; fi

    print -r -- "${pr_title_jira_key}${TAB}${pr_title_rest}"
  fi
}

function extract_jira_key_() {
  local text="$1"
  local folder="$2" # do not default to $PWD

  if [[ -n $text ]]; then
    # Match the last JIRA key, optionally preceded by another key + / or -
    if [[ $text =~ '.*(^|[^A-Z0-9])([A-Z][A-Z0-9]*-[0-9]+)([^A-Z0-9]|$)' ]]; then
      echo "${match[2]}"
      return 0;
    fi
  fi

  if [[ -n "$folder" ]]; then
    echo "$(extract_jira_key_ "$folder")"
    return $?;
  fi

  return 1;
}

function pr() {
  set +x
  eval "$(parse_flags_ "$0" "tlsbfdecrx" "" "$@")"
  (( pr_is_debug )) && set -x

  if (( pr_is_h )); then
    print "  ${hi_yellow_cor}pr ${yellow_cor}[<title>] [<folder>]${reset_cor} : create pull request"
    print "  --"
    print "  ${hi_yellow_cor}pr -t${reset_cor} : run tests before creating pull request"
    print "  ${hi_yellow_cor}pr -x${reset_cor} : skip jira status transition"
    print "  ${hi_yellow_cor}pr -f${reset_cor} : skip confirmation"
    print "  --"
    print "  ${hi_yellow_cor}pr -l${reset_cor} : set labels"
    print "  ${hi_yellow_cor}pr -lb${reset_cor} : set label type: bug or bugfix"
    print "  ${hi_yellow_cor}pr -ls${reset_cor} : set label type: story or feature"
    print "  ${hi_yellow_cor}pr -lr${reset_cor} : set label type: release"
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

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi

  if ! command -v perl &>/dev/null; then
    print " fatal: command requires perl" >&2
    print " install perl: ${blue_cor}https://learn.perl.org/installing/${reset_cor}" >&2
    return 1;
  fi

  local folder="$PWD"
  local title=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}pr -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      title="$1"
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      title="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local proj_repo="$(get_repo_ "$folder" 2>/dev/null)"
  local remote_name="$(get_remote_name_ "$folder")"

  if [[ -z "$proj_repo" ]]; then
    print " fatal: cannot determine github repo for this folder" >&2
    print " command failed: git remote get-url $remote_name" >&2
    return 1;
  fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  local my_remote_branch="$(get_remote_branch_ -f "$my_branch" "$folder")"
  
  if [[ -z "$my_remote_branch" ]]; then
    print " no remote branch found for local branch: $my_branch" >&2
    if ! confirm_ "push branch to ${remote_name}?"; then
      return 1;
    fi
    git -C "$folder" push -u "$remote_name" "$my_branch"
  fi

  local branch_behind=0
  local branch_ahead=0

  local output="$(get_my_branch_status_ "$my_branch" "$my_remote_branch" "$folder")"
  IFS=$TAB read -r branch_behind branch_ahead <<<"$output"

  if (( branch_behind || branch_ahead )); then
    print " fatal: new commits are not pushed yet" >&2
    print " run: ${hi_yellow_cor}push${reset_cor}" >&2
    return 1;
  fi

  local proj_cmd="$(find_proj_by_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$proj_cmd" ]]; then proj_cmd="$CURRENT_PUMP_SHORT_NAME"; fi

  local i="$(find_proj_index_ -x "$proj_cmd" 2>/dev/null)"

  local pump_pr_template_file="${PUMP_PR_TEMPLATE_FILE[$i]:-$CURRENT_PUMP_PR_TEMPLATE_FILE}"
  local pump_pr_replace="${PUMP_PR_REPLACE[$i]:-$CURRENT_PUMP_PR_REPLACE}"
  local pump_pr_title_format="${PUMP_PR_TITLE_FORMAT[$i]:-$CURRENT_PUMP_PR_TITLE_FORMAT}"
  local pump_test="${PUMP_TEST[$i]:-$CURRENT_PUMP_TEST}"
  local pump_pkg_manager="${PUMP_PKG_MANAGER[$i]:-$CURRENT_PUMP_PKG_MANAGER}"
  local pump_pr_append="${PUMP_PR_APPEND[$i]:-$CURRENT_PUMP_PR_APPEND}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"Code Review"}"

  local open_pr_link="$(get_pr_link_ -o "$my_branch" "$proj_repo")"

  if [[ -n "$open_pr_link" ]]; then
    gh pr view  --repo "$proj_repo" --web $open_pr_link &>/dev/null
    print " pull request is up: ${blue_cor}$open_pr_link${reset_cor}" >&2
    return 0;
  fi

  if [[ -n "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( pr_is_t )); then
      print " fatal: uncommitted changes detected, cannot create pull request" >&2
      return 1;
    fi

    if (( ! pr_is_f )); then
      confirm_ "uncommitted changes detected, abort or continue anyway?" "abort" "continue"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then return 0; fi
    fi
  fi

  if (( pr_is_t )); then
    local test_script=""

    if [[ -z "$pump_pkg_manager" ]]; then
      print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi

    if [[ -n "$pump_test" && "$pump_test" != "$pump_pkg_manager test" ]]; then
      test_script="$pump_test"
    else
      test_script="$(get_from_package_json_ "scripts.test" "$folder")"
    fi

    if [[ -n "$test_script" ]]; then
      if test "$folder"; then
        return 1;
      fi
    fi
  fi

  local target_branch="$(get_base_branch_ "$my_branch" "$folder" 2>/dev/null)"

  if [[ -n "$target_branch" ]] && (( ! pr_is_f )); then
    confirm_ "target branch: ${pink_cor}$target_branch${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then
      target_branch=""
    fi
  fi

  if [[ -z "$target_branch" ]]; then
    if (( pr_is_f )); then
      target_branch="$(find_base_branch_ "$folder" 2>/dev/null)"
      if [[ -z "$target_branch" ]]; then
        print " fatal: cannot determine target branch for pr" >&2
        return 1;
      fi
    else
      target_branch="$(determine_target_branch_ -dbtme "$my_branch" "$folder" 2>/dev/null)"
      if [[ -z "$target_branch" ]]; then return 1; fi
    fi
  fi

  if [[ "$my_branch" == "$target_branch" ]]; then
    print " fatal: cannot create pull request to the same branch: $my_branch" >&2
    return 1;
  fi

  local remote_target_branch="$(get_remote_branch_ -f "$target_branch" "$folder")"

  output="$(get_my_branch_status_ "$my_branch" "$remote_target_branch" "$folder")"
  IFS=$TAB read -r branch_behind branch_ahead <<<"$output"

  if (( ! branch_ahead )); then
    print " fatal: no new commits found, cannot create pull request" >&2
    return 1;
  fi

  if (( branch_behind )); then
    print " ${yellow_cor}warning:${reset_cor} your branch is behind ${bold_cor}$target_branch${reset_cor} by ${bold_cor}$branch_behind${reset_cor} commits" >&2

    if ! confirm_ "continue anyway?"; then
      return 1;
    fi
  fi

  local jira_key="$(get_pump_value_ "JIRA_KEY" "$folder")"
  local jira_title="$(get_pump_value_ "JIRA_TITLE" "$folder")"

  if [[ -z "$jira_key" ]]; then
    jira_key="$(extract_jira_key_ "$my_branch" "$folder")"
  fi

  if [[ -z "$jira_key" ]] || { [[ -z "$jira_title" ]] && [[ -z "$title" ]]; }; then
    local commit_key=""
    local commit_title=""
    local output="$(read_commits_ -t "$my_branch" "$target_branch" "$folder")"
    IFS=$TAB read -r commit_key commit_title <<<"$output"

    if [[ -z "$jira_key" && -n "$commit_key" ]]; then
      jira_key="$commit_key"
    fi

    if [[ -z "$jira_title" && -n "$commit_title" ]]; then
      jira_title="$commit_title"
    fi
  fi

  if [[ -z "$title" ]]; then
    # replace title with pump_pr_title_format's {jira_key} {jira_title} variables
    if [[ -n "$pump_pr_title_format" ]]; then
      title="${pump_pr_title_format//\<jira_key\>/$jira_key}"
      title="${title//\<jira_title\>/$jira_title}"
    else
      if [[ -n "$jira_key" ]]; then
        title="$jira_key $jira_title"
      else
        title="$jira_title"
      fi
    fi
  fi

  print " ${purple_cor}target branch:${reset_cor} $target_branch" >&2

  # if not skip confirmation
  if (( ! pr_is_f )); then
    title="$(input_type_ "pull request title" "" 255 "$title")"
    if (( $? == 130 || $? == 2 )); then return 130; fi
  fi

  if [[ -n "$title" ]]; then
    print " ${purple_cor}pull request:${reset_cor} $title" >&2
  else
    print " ${purple_cor}pull request:${reset_cor} (auto fill)" >&2
  fi

  local all_labels=()
  local pr_labels=""

  # pr -l
  if (( pr_is_l )); then
    local labl="$(gh label list --repo "$proj_repo" --json=name | jq -r '.[].name' | sort -rf)"
    all_labels=("${(@f)labl}")
  fi
  
  if [[ -n "$all_labels" ]]; then
    local choose_labels=()
    local label=""
    for label in "${all_labels[@]}"; do
      # pr -lb
      if (( pr_is_b )) && [[ "$label" == "bug" || "$label" == "bugfix" || "$label" == "bug_fix" ]]; then
        choose_labels+=("$label")
      fi
      # pr -ls
      if (( pr_is_s )) && [[ "$label" == "feature" || "$label" == "feat" || "$label" == "story" ]]; then
        choose_labels+=("$label")
      fi
      # pr -lr
      if (( pr_is_r )) && [[ "$label" == "release" ]]; then
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
    
    if (( ! pr_is_f )) && [[ -z "$choose_labels" ]]; then
      local choose_labels_out=""
      choose_labels_out="$(choose_multiple_ "labels" "${all_labels[@]}")"
      if (( $? == 130 )); then return 130; fi
      choose_labels=("${(@f)choose_labels_out}")
    fi

    if [[ -n "$choose_labels" ]]; then
      pr_labels="${(j:,:)choose_labels}"
      print " ${purple_cor}pr labels:${reset_cor} $choose_labels"
    fi
  fi

  local pr_body=""

  if [[ -n "$pump_pr_template_file" && -f "$pump_pr_template_file" ]]; then
    local pr_commit_msgs="$(read_commits_ "$my_branch" "$target_branch" "$folder")"
    
    pr_body="${(F)pr_commit_msgs}"

    local pr_template="$(cat "$pump_pr_template_file" 2>/dev/null)"

    if (( ! pr_is_f )) && [[ -z "$pump_pr_replace" ]]; then
      if command -v gum &>/dev/null; then
        gum style --align=left --margin="0" --padding="0" --border=normal --width=72 --border-foreground 99 "$pr_template"
      else
        print ""
        print " ${purple_cor}pull request template:${reset_cor}"
        print " ${cyan_cor}${pr_template}${reset_cor}"
      fi

      local pr_replace=""
      pr_replace="$(input_type_mandatory_ "placeholder text in the template where you want the body to be inserted")"
      if (( $? == 130 )); then return 130; fi
      
      if (( i )) && [[ -n "$pr_replace" ]]; then
        confirm_ "replace it or append after it?" "replace" "append"
        local RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi

        update_config_ $i "PUMP_PR_REPLACE" "$pr_replace"
        update_config_ $i "PUMP_PR_APPEND" "$RET"
        
        pump_pr_replace="$pr_replace"
        pump_pr_append=$RET
      fi
    fi

    if [[ -n "$pump_pr_replace" && -n "$pr_body" ]]; then
      if (( pump_pr_append )); then
        # print "\$(env MARKER=\"$pump_pr_replace\" BODY=\"$pr_body\" perl -pe '
        #   BEGIN {
        #     \$marker = \$ENV{\"MARKER\"};
        #     \$insert = \$ENV{\"BODY\"};
        #   }
        #   s/\\\\Q\$marker\\E/\\\$marker\\\\n\\\\n\$insert\\\\n/;
        # ' <<< \"$pr_template\")"

        pr_body="$(env MARKER="$pump_pr_replace" BODY="$pr_body" perl -pe '
          BEGIN {
            $marker = $ENV{"MARKER"};
            $insert = $ENV{"BODY"};
          }
          s/\Q$marker\E/$marker\n\n$insert\n/;
        ' <<< "$pr_template")"
      else
        pr_body="$(env MARKER="$pump_pr_replace" BODY="$pr_body" perl -pe '
          BEGIN {
            $marker = $ENV{"MARKER"};
            $insert = $ENV{"BODY"};
          }
          s/^\Q$marker\E\s*$/$insert/;
        ' <<< "$pr_template")"
      fi
    else
      pr_body="$pr_template"
    fi

    # replace the jira key in pr_body
    if [[ -n "$jira_key" ]]; then
      # find where the jira key is in pr_body based on the alpha code before the dash in jira_key
      local jira_alpha="${jira_key%%-*}"

      pr_body="$(echo "$pr_body" | perl -pe "
        s/($jira_alpha-[^[:space:]]+)/$jira_key/g;
      ")"
    fi
  fi

  local short_base_branch="$(get_short_name_ "$target_branch" "$folder")"

  local pr_flags=()

  if (( ! pr_is_f )); then
    pr_flags+=("--web")
  fi

  if [[ -z "$pr_body" ]]; then
    pr_flags+=("--fill")
  fi

  if gh pr create --repo "$proj_repo" --assignee="@me" --title="$title" --body="$pr_body" --head="$my_branch" --base="$short_base_branch" --label="$pr_labels" ${pr_flags[@]}; then
    if (( ! pr_is_x )); then
      if (( pr_is_f )); then
        update_status_ -rf $i "$jira_key" "$jira_in_review"
      else
        update_status_ -r $i "$jira_key" "$jira_in_review"
      fi
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
    if [[ -n "$CURRENT_PUMP_RUN" ]]; then # if it has CURRENT_PUMP_RUN, then it has CURRENT_PUMP_SHORT_NAME
      print "  ${hi_yellow_cor}run${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_RUN in current folder"
    else
      print "  ${hi_yellow_cor}run${reset_cor} : run current folder's dev or start script"
    fi
    print "  --"
    if [[ -n "$CURRENT_PUMP_RUN_STAGE" ]]; then
      print "  ${hi_yellow_cor}run stage ${ellow_cor}[<folder>]${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_RUN_STAGE in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
    fi
    if [[ -n "$CURRENT_PUMP_RUN_PROD" ]]; then
      print "  ${hi_yellow_cor}run prod ${ellow_cor}[<folder>]${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_RUN_PROD in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
    fi
    print "  ${hi_yellow_cor}run <script>${reset_cor} : run any current folder's script"  
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${hi_yellow_cor}run <script> ${ellow_cor}[<folder>]${reset_cor} : run any ${CURRENT_PUMP_SHORT_NAME}'s folder's script"
    else
      print "  ${hi_yellow_cor}run <script> ${yellow_cor}[<folder>]${reset_cor} : run any folder's script"
    fi
    return 0;
  fi

  proj_run_ $@
}

function proj_run_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_run_is_debug )) && set -x

  if (( proj_run_is_h )); then
    proj_print_help_ "$proj_cmd" "run"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""
  local script_arg=""

  if [[ -n "$3" ]]; then
    proj_arg="$1"
    script_arg="$2"
    folder_arg="$3"

  elif [[ -n "$2" ]]; then
    if is_project_ "$1"; then
      # second argument could be a folder or script, figure out later
      proj_arg="$1"
    else
      script_arg="$1"
      folder_arg="$2"
    fi

  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    else
      script_arg="$1"
    fi
  fi

  local proj_cmd=""
  local proj_folder=""
  local single_mode=""
  local pkg_manager=""

  local i=0

  if [[ -n "$proj_arg" ]]; then
    i="$(find_proj_index_ -o "$proj_arg" "project to run")"
    if (( ! i )); then
      print " run: ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"

    if ! check_proj_ -fmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"
    pkg_manager="${PUMP_PKG_MANAGER[$i]}"

  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    proj_folder="$CURRENT_PUMP_FOLDER"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"
    pkg_manager="$CURRENT_PUMP_PKG_MANAGER"
    
    i="$(find_proj_index_ -x "$proj_cmd")"
  fi

  local folder_to_execute=""

  if [[ -n "$proj_arg" ]]; then
    if (( single_mode )); then
      if [[ -n "$2" && -z "$folder_arg" ]]; then
        script_arg="$2"
      fi

      folder_to_execute="$proj_folder"
    else
      if [[ -n "$2" && -z "$folder_arg" ]]; then
        if [[ -d "${proj_folder}/$2" ]]; then
          folder_arg="$2"
        else
          script_arg="$2"
        fi
      fi

      local dirs_output=""
      dirs_output="$(get_folders_ -ijp $i "$proj_folder" "$folder_arg" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      if [[ -z "$dirs_output" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder_arg" >&2
        print " run: ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local dirs=("${(@f)dirs_output}")
      local folder="$(choose_one_ -it "folder in $proj_cmd to run" "${dirs[@]}")"
      if [[ -z "$folder" ]]; then return 1; fi

      folder_to_execute="${proj_folder}/${folder}"
    fi
  else
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run: ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  folder_to_execute="$(realpath -- "$folder_to_execute")"

  if ! is_folder_pkg_ "$folder_to_execute"; then return 1; fi

  local script="${script_arg:-dev}"
  
  local pump_run=""

  if [[ "$script" == "stage" ]]; then
    pump_run="${PUMP_RUN_STAGE[$i]}"
  elif [[ "$script" == "prod" ]]; then
    pump_run="${PUMP_RUN_PROD[$i]}"
  else
    pump_run="${PUMP_RUN[$i]}"
  fi

  print " running $script on ${cyan_cor}${folder_to_execute}${reset_cor}"

  local RET=0

  if [[ -z "$pump_run" ]]; then
    local pump_run_script="$(get_from_package_json_ "scripts.${script}" "$folder_to_execute")"

    if [[ -z "$pkg_manager" ]]; then
      print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi

    if [[ -n "$pump_run_script" ]]; then
      pump_run="$pkg_manager run $script"
    
    elif [[ "$script" == "dev" && -z "$script_arg" ]]; then
      local pump_run_start="$(get_from_package_json_ "scripts.start" "$folder_to_execute")"

      if [[ -n "$pump_run_start" ]]; then
        pump_run="$pkg_manager start"
      else
        print " fatal: no '$script' or 'start' script in package.json"
        return 1;
      fi
    else
      print " fatal: no '$script' script in package.json"
      return 1;
    fi
    print " ${script_cor}${pump_run}${reset_cor}"
    
    ( cd "$folder_to_execute" && eval "$pump_run" )
    RET=$?

  else
    print " ${script_cor}${pump_run}${reset_cor}"

    ( cd "$folder_to_execute" && eval "$pump_run" )
    RET=$?

    if (( RET )); then
      if [[ "$script" == "stage" || "$script" == "prod" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_${script:U}_$i ${reset_cor}" >&2
        print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      elif [[ "$script" == "dev" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_$i ${reset_cor}" >&2
        print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      else
        print " ${red_cor}failed to run script '$script'${reset_cor}" >&2
      fi
    fi
  fi

  return $RET;
}

function setup() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( setup_is_debug )) && set -x

  if (( setup_is_h )); then
    if [[ -n "$CURRENT_PUMP_SETUP" ]]; then
      print "  ${hi_yellow_cor}setup${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_SETUP in current folder"
    else
      print "  ${hi_yellow_cor}setup${reset_cor} : run current folder's setup script or package manager install"
    fi
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      if [[ -n "$CURRENT_PUMP_SETUP" ]]; then
        print "  ${hi_yellow_cor}setup <folder>${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_SETUP in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
      else
        print "  ${hi_yellow_cor}setup <folder>${reset_cor} : run a ${CURRENT_PUMP_SHORT_NAME}'s folder's setup script or package manager install"
      fi
    else
      print "  ${hi_yellow_cor}setup <folder>${reset_cor} : run a folder's setup script or package manager install"
    fi
    return 0;
  fi

  proj_setup_ $@
}

function proj_setup_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_setup_is_debug )) && set -x

  if (( proj_setup_is_h )); then
    proj_print_help_ "$proj_cmd" "setup"
    return 0;
  fi

  local proj_arg=""
  local folder_arg=""

  if [[ -n "$2" ]]; then
    proj_arg="$1"
    folder_arg="$2"
  elif [[ -n "$1" ]]; then
    if is_project_ "$1"; then
      proj_arg="$1"
    else
      folder_arg="$1"
    fi
  fi

  local proj_cmd=""
  local proj_folder=""
  local single_mode=""
  local pkg_manager=""
  local pump_setup=""

  local i=0

  if [[ -n "$proj_arg" ]]; then
    i="$(find_proj_index_ -o "$proj_arg" "project to setup")"
    if (( ! i )); then
      print " run: ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_cmd="${PUMP_SHORT_NAME[$i]}"
    
    if ! check_proj_ -fmp $i; then return 1; fi

    proj_folder="${PUMP_FOLDER[$i]}"
    single_mode="${PUMP_SINGLE_MODE[$i]}"
    pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    pump_setup="${PUMP_SETUP[$i]}"

  else
    proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    proj_folder="$CURRENT_PUMP_FOLDER"
    single_mode="$CURRENT_PUMP_SINGLE_MODE"
    pkg_manager="$CURRENT_PUMP_PKG_MANAGER"
    pump_setup="$CURRENT_PUMP_SETUP"

    i="$(find_proj_index_ -x "$proj_cmd")"
  fi

  local folder_to_execute=""

  if [[ -n "$proj_arg" ]]; then
    if (( single_mode )); then
      folder_to_execute="$proj_folder"
    else
      local dirs_output=""
      dirs_output="$(get_folders_ -ijp $i "$proj_folder" "$folder_arg" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      if [[ -z "$dirs_output" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder_arg" >&2
        print " run: ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi
      
      local dirs=("${(@f)dirs_output}")
      local folder="$(choose_one_ -it "folder in $proj_cmd to setup" "${dirs[@]}")"
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    fi
  else
    if [[ -n "$folder_arg" ]]; then
      if [[ -d "$folder_arg" ]]; then
        folder_to_execute="$folder_arg"
      else
        print " fatal: not a valid folder argument: $folder_arg" >&2
        print " run: ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  folder_to_execute="$(realpath -- "$folder_to_execute")"

  if ! is_folder_pkg_ "$folder_to_execute"; then
    print " run: ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
    return 1;
  fi

  print " setting up... ${cyan_cor}${folder_to_execute}${reset_cor}"

  if [[ -z "$pump_setup" ]]; then
    pump_setup="$(get_from_package_json_ "scripts.setup" "$folder_to_execute")"
    
    if [[ -z "$pkg_manager" ]]; then
      print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi

    if [[ -n "$pump_setup" ]]; then
      pump_setup="$pkg_manager run setup"
    else
      pump_setup="$pkg_manager install"
    fi
  fi

  print " ${script_cor}${pump_setup}${reset_cor}"

  ( cd "$folder_to_execute" && eval "$pump_setup" )
  local RET=$?

  if (( RET )); then
    if [[ "$pump_setup" == "${PUMP_SETUP[$i]}" ]]; then
      print " ${red_cor}failed to run PUMP_SETUP_$i ${reset_cor}" >&2
      print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    fi
  fi

  print ""
  print " next thing to do:"

  local run_dev="$(get_from_package_json_ "scripts.dev" "$folder_to_execute")"
  local run_start="$(get_from_package_json_ "scripts.start" "$folder_to_execute")"

  if [[ -n "$run_dev" && -n "$pkg_manager" ]]; then
    print "  • ${hi_yellow_cor}run${reset_cor} (alias for \"$pkg_manager run dev\")"
  elif [[ -n "$run_start" && -n "$pkg_manager" ]]; then
    print "  • ${hi_yellow_cor}run${reset_cor} (alias for \"$pkg_manager start\")"
  fi

  local pkg_json="package.json"
  if [[ -f $pkg_json && -n "$pkg_manager" ]]; then
    local scripts="$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' "$pkg_json")"

    local entry=""
    for entry in "${(f)scripts}"; do
      local name="${entry%%=*}"
      local cmd="${entry#*=}"

      if [[ "$name" == "build" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}build${reset_cor} (alias for \"$pkg_manager run build\")"; fi
      if [[ "$name" == "deploy" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}deploy${reset_cor} (alias for \"$pkg_manager run deploy\")"; fi
      if [[ "$name" == "fix" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}fix${reset_cor} (alias for \"$pkg_manager run fix\")"; fi
      if [[ "$name" == "format" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}format${reset_cor} (alias for \"$pkg_manager run format\")"; fi
      if [[ "$name" == "lint" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}lint${reset_cor} (alias for \"$pkg_manager run lint\")"; fi
      if [[ "$name" == "test" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}test${reset_cor} (alias for \"$pkg_manager test\")"; fi
      if [[ "$name" == "tsc" && -n "$cmd" ]]; then print "  • ${hi_yellow_cor}tsc${reset_cor} (alias for \"$pkg_manager run tsc\")"; fi
    done
    print "  --"
  fi

  if [[ -n "$proj_cmd" ]]; then
    print "  • ${hi_yellow_cor}$proj_cmd -h${reset_cor} for your project options"
  fi

  print "  • ${hi_yellow_cor}pro -h${reset_cor} for project management options"
  print "  • ${hi_yellow_cor}help${reset_cor} for more help"
}

function proj_revs_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  (( proj_revs_is_debug )) && set -x

  local proj_cmd="$1"

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument" >&2
    print " run: ${hi_yellow_cor}$proj_cmd revs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # this is not an accessible command anymore
  if (( proj_revs_is_h )); then
    proj_print_help_ "$proj_cmd" "revs"
    return 0;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r $i "$proj_cmd" "$proj_folder")"
  local rev_options=(${~revs_folder}/rev.*(N/om))

  if (( ${#rev_options[@]} == 0 )); then
    print " no reviews in $proj_cmd" >&2
    return 0;
  fi

  # proj_revs_ -dd
  if (( proj_revs_is_d_d )); then
    confirm_ "delete all reviews?" "abort" "delete"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then return 0; fi

    local empty_folder="${revs_folder}/.empty"
    mkdir -p -- "$empty_folder"

    if command -v gum &>/dev/null; then
      gum spin --title="deleting... $revs_folder" -- rsync -a --delete -- "$empty_folder/" "$revs_folder/"
    else
      print " deleting... $revs_folder"
      rsync -a --delete -- "$empty_folder/" "$revs_folder/"
    fi

    if (( $? == 0 )); then
      if [[ "$revs_folder" == "$PWD" ]]; then
        print -l -- " ${yellow_cor}deleted${reset_cor} $revs_folder"
        cd ..
      else
        print -l -- " ${magenta_cor}deleted${reset_cor} $revs_folder"
      fi
    else
      print -l -- " ${red_cor}not deleted${reset_cor} $revs_folder" >&2
    fi

    rm -rf -- "$revs_folder"
    rm -rf -- "$empty_folder"

    return $?;
  fi


  # proj_revs_ -d
  if (( proj_revs_is_d )); then
    local rev_choices
    local oots="$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')"

    rev_choices="$(choose_multiple_ "reviews to delete" "${(@f)oots}")"
    rev_choices=("${(@f)rev_choices}")

    if [[ -z "$rev_choices" ]]; then return 1; fi

    local empty_folder="${revs_folder}/.empty"
    mkdir -p -- "$empty_folder"

    local rev=""
    for rev in "${rev_choices[@]}"; do
      local rev_folder="${revs_folder}/${rev}"
  
      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $rev" -- rsync -a --delete -- "$empty_folder/" "$rev_folder/"
      else
        print " deleting... $rev"
        rsync -a --delete -- "$empty_folder/" "$rev_folder/"
      fi

      if (( $? == 0 )); then
        if [[ "$rev_folder" == "$PWD" ]]; then
          print -l -- " ${yellow_cor}deleted${reset_cor} $rev"
          cd ..
        else
          print -l -- " ${magenta_cor}deleted${reset_cor} $rev"
        fi
      else
        print -l -- " ${red_cor}not deleted${reset_cor} $rev" >&2
      fi

      rm -rf -- "$rev_folder"
    done

    rm -rf -- "$empty_folder"

    return 0;
  fi

  local rev_choices=()
  local rev_map=()

  rev=""
  for rev in "${rev_options[@]}"; do
    local pr_number="$(get_pump_value_ "PR_NUMBER" "$rev")"
    local pr_title="$(get_pump_value_ "PR_TITLE" "$rev")"
    local pr_branch="$(get_pump_value_ "PR_BRANCH" "$rev")"

    local rev_name="${rev##*/}"
    rev_name="${rev_name#rev.}"

    if [[ -n "$pr_number" && -n "$pr_title" && -n "$pr_branch" ]]; then
      rev_map+=("${pr_number}${TAB}${pr_title}${TAB}${pr_branch}")
      rev_choices+=("$pr_title")
    
    elif [[ -n "$pr_branch" ]]; then
      rev_map+=("0${TAB}${rev_name}${TAB}${pr_branch}")
      rev_choices+=("$rev_name")

    else
      rev_map+=("0${TAB}${rev_name}${TAB}${rev_name}")
      rev_choices+=("$rev_name")
    fi
  done

  local select_pr_title=""
  select_pr_title="$(choose_one_ "review to open" "${rev_choices[@]}")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$select_pr_title" ]]; then return 1; fi

  local select_pr_number=""
  local select_pr_branch_or_folder=""
  # lookup number and branch using actual tabs
  read select_pr_number select_pr_branch_or_folder <<<"$(printf "%s\n" "${rev_map[@]}" | awk -F$TAB -v title="$select_pr_title" '$2 == title {print $1, $3}')"

  proj_rev_ -x "$proj_cmd" "$select_pr_branch_or_folder"
}

function attempt_switch_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( attempt_switch_branch_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  local do_nothing=0

  if ! is_folder_git_ "$folder" &>/dev/null; then return 1; fi

  local local_branch="$(git -C "$folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"

  if [[ "$branch" != "$local_branch" ]]; then
    print " current branch is not correct: ${yellow_cor}$local_branch${yellow_cor}" >&2
    
    local git_status="$(git -C "$folder" status --porcelain 2>/dev/null)"
    if [[ -n "$git_status" && -z "$(echo "$git_status" | grep '\.pump$')" ]]; then
      if ! confirm_ "switch to pull request branch? ${bold_cor}$branch${reset_cor}" "switch" "abort"; then
        do_nothing=1
      fi
    fi
  fi

  echo "$do_nothing"
}

function proj_rev_() {
  set +x
  eval "$(parse_flags_ "$0" "ebjdxr" "" "$@")"
  (( proj_rev_is_debug )) && set -x

  local proj_cmd="$1"

  local branch_arg=""

  if [[ -n "$2" && "$2" != -* ]]; then
    branch_arg="$2"
  fi

  if (( proj_rev_is_h )); then
    proj_print_help_ "$proj_cmd" "rev"
    return 0;
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

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fr $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  local pump_clone="${PUMP_CLONE[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r $i "$proj_cmd" "$proj_folder")"

  local branch=""
  local pr_number=""
  local pr_title=""
  local pr_link=""
  local jira_key=""

  local full_rev_folder=""

  # proj_rev_ -x exact branch
  if (( proj_rev_is_x )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch is required for -x flag" >&2
      print " run: ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local branch_folder="${branch_arg//\\/-}"
    branch_folder="${branch_folder//\//-}"

    full_rev_folder="${revs_folder}/rev.${branch_folder}"

    if is_branch_existing_ "$branch_arg" "$proj_folder"|| is_branch_existing_ "$branch_arg" "${full_rev_folder}"; then
      branch="$branch_arg"
    else
      # try to get from .pump file
      local pr_branch="$(get_pump_value_ "PR_BRANCH" "${full_rev_folder}")"
      if [[ -n "$pr_branch" ]]; then
        if is_branch_existing_ "$pr_branch" "$proj_folder" || is_branch_existing_ "$pr_branch" "${full_rev_folder}"; then
          branch="$pr_branch"
        else
          # try to get from pr
          local output="$(get_pr_ -omc "$pr_branch" "$proj_repo")"
          IFS=$TAB read -r pr_number pr_title pr_link _ <<<"$output"

          if [[ -n "$pr_number" && -n "$pr_title" && -n "$pr_link" ]]; then
            branch="$pr_branch"
          fi
        fi
      fi
    fi

  # proj_rev_ -j select jira key
  elif (( proj_rev_is_j )); then
    local output=""
    output="$(select_jira_key_ -yQ $i "$branch_arg" "" "to review")"
    if (( $? == 130 )); then return 130; fi
    IFS=$TAB read -r jira_key _ <<< "$output"

    if [[ -z "$jira_key" ]]; then return 1; fi

    branch="$(select_pr_by_jira_key_ -omQ "$jira_key" "$proj_repo")"
    if (( $? == 130 )); then return 130; fi

  # proj_rev_ -r select by jira key in release
  elif (( proj_rev_is_r )); then
    local output=""
    output="$(select_jira_key_by_release_ -yQ $i "$branch_arg" "" "to review")"
    if (( $? == 130 )); then return 130; fi
    IFS=$TAB read -r jira_key _ <<< "$output"

    if [[ -z "$jira_key" ]]; then return 1; fi

    branch="$(select_pr_by_jira_key_ -omQ "$jira_key" "$proj_repo")"
    if (( $? == 130 )); then return 130; fi

  # proj_rev_ -b select branch
  elif (( proj_rev_is_b )); then
    branch="$(select_branch_ -ris "$branch_arg" "to review" "$proj_folder")"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$branch" ]]; then return 1; fi

  else
    # check if branch arg was given and it's a branch
    if [[ -n "$branch_arg" ]]; then
      if is_branch_existing_ "$branch_arg" "$proj_folder"; then
        branch="$branch_arg"
      fi
    fi

    if [[ -z "$branch" ]]; then
      if command -v gh &>/dev/null; then
        local output=""
        output="$(select_pr_ "$branch_arg" "$proj_repo" "pull request to review")"
        if (( $? == 130 )); then return 130; fi
        IFS=$TAB read -r pr_number branch pr_title pr_link <<<"$output"

        if [[ -z "$pr_title" || -z "$branch" ]]; then return 1; fi
      else
        $proj_cmd rev -b $branch_arg
        return $?;
      fi
    fi
  fi

  if [[ -z "$branch" ]]; then
    if [[ -n "$full_rev_folder" ]]; then
      if [[ -d "$full_rev_folder" ]]; then
        print " fatal: cannot determine branch for folder-only review: $branch_arg" >&2
        cd "$full_rev_folder"
      else
        print " fatal: review folder does not exist: $full_rev_folder" >&2
      fi
    else
      print " fatal: cannot determine branch to review" >&2
    fi
    print " run: ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
    return 1;
  fi

  branch="$(get_short_name_ "$branch" "$proj_folder")"
  
  if [[ -z "$full_rev_folder" ]]; then
    local branch_folder="${branch//\\/-}"
    branch_folder="${branch_folder//\//-}"

    full_rev_folder="${revs_folder}/rev.${branch_folder}"
  fi

  if [[ -z "$pr_number" || -z "$pr_title" || -z "$pr_link" ]]; then
    local output="$(get_pr_ -omc "$branch" "$proj_repo")"
    IFS=$TAB read -r pr_number pr_title pr_link _ <<<"$output"

    if [[ -z "$pr_number" ]]; then
      pr_number="$(get_pump_value_ "PR_NUMBER" "$full_rev_folderv")"
      pr_title="$(get_pump_value_ "PR_TITLE" "$full_rev_folderv")"
      pr_link="$(get_pump_value_ "PR_LINK" "$full_rev_folder")"
    fi
  fi

  local skip_setup=0
  local already_merged=0;

  if [[ -n "$pr_link" ]]; then
    print " opening pull request branch... ${blue_cor}$pr_link${reset_cor}"
  else
    print " opening branch... ${green_cor}$branch${reset_cor}"
  fi

  if is_folder_git_ "$full_rev_folder" &>/dev/null; then
    # already cloned before
    local do_nothing="$(attempt_switch_branch_ "$branch" "$full_rev_folder")"

    if (( do_nothing )); then
      cd "$full_rev_folder"
      return 1;
    fi

    git -C "$full_rev_folder" fetch --quiet &>/dev/null

    local git_status="$(git -C "$full_rev_folder" status --porcelain 2>/dev/null)"
    local local_branch="$(git -C "$full_rev_folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ -n "$git_status" ]]; then
      local files=$(echo "$git_status" | awk '{print $2}')

      if [[ $(echo "$files" | wc -l) -eq 1 && "$files" =~ \.pump$ ]]; then
        skip_setup=1
      else
        st -sb "$full_rev_folder" >&2

        print " uncommitted changes detected in branch: ${yellow_cor}$local_branch${reset_cor}" >&2
        if confirm_ "erase changes and reset branch?" "reset" "abort"; then
          if reseta "$full_rev_folder" --quiet; then
            clean "$full_rev_folder" --quiet
          fi
          if (( $? )); then
            print " ${red_cor}failed to clean branch${reset_cor}" >&2
            do_nothing=1
          fi
        else
          do_nothing=1
        fi
      fi
    fi

    if (( do_nothing )); then
      cd "$full_rev_folder"
      return 0;
    fi

    if [[ "$branch" != "$local_branch" ]]; then
      skip_setup=1

      if git -C "$full_rev_folder" switch "$branch" --discard-changes --quiet; then
        skip_setup=0
      else
        print " failed to switch to branch: ${orange_cor}$branch${reset_cor}" >&2
        already_merged=1
      fi
    fi

    if [[ "$branch" == "$local_branch" ]]; then
      local latest_commit="$(git -C "$full_rev_folder" rev-parse HEAD 2>/dev/null)"

      if pull "$full_rev_folder"; then
        local new_latest_commit="$(git -C "$full_rev_folder" rev-parse HEAD 2>/dev/null)"

        if [[ "$latest_commit" == "$new_latest_commit" ]]; then
          skip_setup=1
        fi
      else
        skip_setup=1
        already_merged=1

        local remote_branch="$(get_remote_branch_ -f "$branch" "$full_rev_folder")"
        local branch_behind=0
        local output="$(get_my_branch_status_ "$branch" "$remote_branch" "$full_rev_folder")"
        IFS=$TAB read -r branch_behind _ <<<"$output"

        if (( branch_behind )); then
          print " local branch is behind remote branch by ${bold_cor}$branch_behind${reset_cor} commits" >&2
        fi
      fi
    fi

    if (( do_nothing )); then
      cd "$full_rev_folder"
      return 1;
    fi

  else

    local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

    if command -v gum &>/dev/null; then
      gum spin --title="git clone... $repo_name" -- rm -rf -- "$full_rev_folder"
      if ! gum spin --title="git clone... $repo_name" -- git clone --filter=blob:none "$proj_repo" "$full_rev_folder"; then
        print " fatal: failed to clone ${repo_name}" >&2
        return 1;
      fi
    else
      print " git clone... $repo_name"
      rm -rf -- "$full_rev_folder"
      if ! git clone --filter=blob:none "$proj_repo" "$full_rev_folder"; then
        return 1;
      fi
    fi

    if ! git -C "$full_rev_folder" switch "$branch" --quiet &>/dev/null; then
      print " ${yellow_cor}warning: failed to switch to branch: ${branch}${reset_cor}"
      already_merged=1
    fi

    if command -v gh &>/dev/null; then
      local pr_target_branch="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json state,baseRefName --jq 'select(.state == "OPEN") | .baseRefName' 2>/dev/null)"
      if [[ -n "$pr_target_branch" ]]; then
        git -C "$full_rev_folder" config branch.$branch.gh-merge-base $pr_target_branch
      fi
    fi

    cd "$full_rev_folder"

    if [[ -n "$pump_clone" ]]; then
      print " ${script_cor}${pump_clone}${reset_cor}"
      if ! eval "$pump_clone"; then
        print " ${yellow_cor}warning: failed to run PUMP_CLONE_$i ${reset_cor}"
        print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}"
      fi
    fi

  fi # end of clone if

  update_pump_file_ "PR_BRANCH" "$branch" "$full_rev_folder"

  if [[ -n "$pr_number" && -n "$pr_title" && -n "$pr_link" ]]; then
    update_pump_file_ "PR_NUMBER" "$pr_number" "$full_rev_folder"
    update_pump_file_ "PR_TITLE" "$pr_title" "$full_rev_folder"
    update_pump_file_ "PR_LINK" "$pr_link" "$full_rev_folder"
  fi

  if (( already_merged  )); then
    if [[ -n "$pr_link" ]]; then
      print " ${red_cor}pull request is already merged or closed${reset_cor}"
    else
      print " ${yellow_cor}pull request is not available${reset_cor}"
    fi

    cd "$full_rev_folder"
    return $?;
  fi

  if (( skip_setup )); then
    cd "$full_rev_folder"
    return $?;
  fi

  setup "$full_rev_folder"

  print "  --"
  print "  • ${hi_yellow_cor}$proj_cmd revs${reset_cor} to check out local code reviews"

  cd "$full_rev_folder"

  if [[ -z "$PUMP_CODE_EDITOR" ]]; then
    PUMP_CODE_EDITOR="$(input_command_ "type the command of your code editor" "code")"

    if [[ -n "$PUMP_CODE_EDITOR" ]]; then
      update_setting_ "PUMP_CODE_EDITOR" "$PUMP_CODE_EDITOR"
    fi
  fi

  if [[ -n "$PUMP_CODE_EDITOR" ]]; then
    if command -v $PUMP_CODE_EDITOR &>/dev/null; then
      if confirm_ "open code editor?"; then

        $PUMP_CODE_EDITOR -- "$full_rev_folder"

        if (( $? )); then
          update_setting_ "PUMP_CODE_EDITOR" "" &>/dev/null
        fi
      fi
    else
      print " code editor command not found:  ${yellow_cor}$PUMP_CODE_EDITOR${reset_cor}" >&2
      update_setting_ "PUMP_CODE_EDITOR" "" &>/dev/null
    fi
  fi
}

function get_pr_link_() {
  set +x
  eval "$(parse_flags_ "$0" "omc" "" "$@")"
  (( get_pr_link_is_debug )) && set -x

  local branch="$1"
  local proj_repo="$2"

  local pr_link=""

  if command -v gh &>/dev/null; then
    if (( get_pr_link_is_o )); then
      pr_link="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "OPEN") | .url' 2>/dev/null)"
    fi

    if [[ -z "$pr_link" ]]; then
      if (( get_pr_link_is_m )); then
        pr_link="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "MERGED") | .url' 2>/dev/null)"
      fi
      if [[ -z "$pr_link" ]] && (( get_pr_link_is_c )); then
        pr_link="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "CLOSED") | .url' 2>/dev/null)"
      fi
    fi
  fi

  echo "$pr_link"
}

function get_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "omc" "" "$@")"
  (( get_pr_is_debug )) && set -x

  local branch="$1"
  local proj_repo="$2"

  local pr_number=""
  local pr_title=""
  local pr_branch=""
  local pr_link=""

  if ! command -v gh &>/dev/null; then return 1; fi

  if (( get_pr_is_o )); then
    IFS=$'\t' read -r pr_number pr_title pr_link <<<"$(
      gh pr view "${(q)branch}" \
        --repo "$proj_repo" \
        --json number,title,state,url \
        --jq 'select(.state == "OPEN") | [.number, .title, .url] | @tsv' \
        2>/dev/null || :
    )"
  fi

  if [[ -z "$pr_number" ]]; then
    if (( get_pr_is_m )); then
      IFS=$'\t' read -r pr_number pr_title pr_link <<<"$(
        gh pr view "${(q)branch}" \
          --repo "$proj_repo" \
          --json number,title,state,url \
          --jq 'select(.state == "MERGED") | [.number, .title, .url] | @tsv' \
          2>/dev/null || :
      )"
    fi

    if [[ -z "$pr_number" ]] && (( get_pr_is_c )); then
      IFS=$'\t' read -r pr_number pr_title pr_link  <<<"$(
        gh pr view "${(q)branch}" \
          --repo "$proj_repo" \
          --json number,title,state,url \
          --jq 'select(.state == "CLOSED") | [.number, .title, .url] | @tsv' \
          2>/dev/null || :
      )"
    fi
  fi

  print -r -- "${pr_number}${TAB}${pr_title}${TAB}${pr_link}"
}

function truncate_() {
  local str="$1"
  local max="${2:-30}"

  if (( ${#str} > max )); then
    print -r -- "${str[1,max]}..."
  else
    print -r -- "$str"
  fi
}

function proj_clone_() {
  set +x
  eval "$(parse_flags_ "$0" "j" "" "$@")"
  (( proj_clone_is_debug )) && set -x

  local proj_cmd="$1"
  local branch_arg="$2"
  local target_branch_arg="$3"
  local work_type="$4"

  if (( proj_clone_is_h )); then
    proj_print_help_ "$proj_cmd" "clone"
    return 0;
  fi

  if ! command -v git &>/dev/null; then
    print " fatal: command requires git" >&2
    print " install git: ${blue_cor}https://git-scm.com/downloads/${reset_cor}" >&2
    return 1;
  fi

  if (( single_mode )) && [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -frmv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local pump_clone="${PUMP_CLONE[$i]}"

  if [[ -n "$branch_arg" ]]; then
    branch_arg="$(get_short_name_ "$branch_arg" "$proj_folder")"

    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi
  else
    if [[ -n "$target_branch_arg" ]]; then
      print " fatal: branch name is required when setting target branch" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -n "$target_branch_arg" ]]; then
    target_branch_arg="$(get_short_name_ "$target_branch_arg" "$proj_folder")"

    if ! is_branch_name_valid_ "$target_branch_arg"; then
      return 1;
    fi
  fi

  local target_branch="$target_branch_arg"

  if [[ -n "$target_branch" ]]; then
    if [[ -n "$branch_arg" && "$branch_arg" == "$target_branch" ]]; then
      print " fatal: branch cannot be the same as target branch: ${yellow_cor}$(truncate_ "$branch_arg")${reset_cor}" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local remote_target_branch="$(get_remote_branch_ "$target_branch" "$proj_folder")"
    
    if [[ -z "$remote_target_branch" ]]; then
      print " fatal: target branch does not exist: ${yellow_cor}$target_branch${reset_cor}" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  local folder_to_clone=""

  if (( single_mode )); then
    folder_to_clone="$proj_folder"

    if (( ! proj_clone_is_j )) && ! is_proj_folder_empty_ "$folder_to_clone"; then
      confirm_ "project folder is not empty, create backup and re-clone?" "re-clone" "abort"; 
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 1 )); then
        print " fatal: cannot clone $proj_cmd because it's set to ${purple_cor}single mode${reset_cor}" >&2
        print " run: ${hi_yellow_cor}$proj_cmd -e${reset_cor} to switch to ${pink_cor}multiple mode${reset_cor}" >&2

        return 1;
      fi

      # create backup and delete project folder
      if ! create_backup_ -s $i "$folder_to_clone"; then
        return 1;
      fi
    fi
  else
    local git_folder="$(get_proj_for_git_ "$proj_folder" 2>/dev/null)"

    if [[ -n "$git_folder" ]]; then
     # if there is a cloned repo, clone another one

      if [[ -z "$branch_arg" ]]; then
        branch_arg="$(input_branch_name_ "$work_type branch name")"
        if (( $? == 130 )); then return 130; fi
        if [[ -z "$branch_arg" ]]; then return 1; fi
      fi

      if [[ -n "$target_branch" && "$branch_arg" == "$target_branch" ]]; then
        print " fatal: branch cannot be the same as target branch: $(truncate_ "$branch_arg")" >&2
        print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
        return 1;
      fi

      if [[ -z "$work_type" ]]; then
        work_type="$(choose_work_type_ $i "$branch_arg")"
        if (( $? == 130 )); then return 130; fi
      fi

      if [[ -n "$work_type" ]]; then
        if [[ "$branch_arg" != "$work_type/"* ]]; then
          folder_to_clone="${proj_folder}/${work_type}/${branch_arg}"
          branch_arg="${work_type}/${branch_arg}"
        else
          folder_to_clone="${proj_folder}/${branch_arg}"
        fi
      else
        folder_to_clone="${proj_folder}/${branch_arg}"
      fi

      if is_folder_git_ "$folder_to_clone" &>/dev/null; then
        print " warning: folder already exists!" >&2
        local base_branch="$(get_base_branch_ "$branch_arg" "$folder_to_clone" 2>/dev/null)"

        if [[ -n "$base_branch" ]]; then
          print " target branch: ${hi_cyan_cor}$base_branch${reset_cor}" >&2
        fi

        cd "$folder_to_clone"
        return 0;
      fi

    else
      # if there is no cloned repo, clone into temporary folder first to get branch, then move to project folder
      local temp_folder="$(get_proj_special_folder_ -t $i "$proj_cmd" "$proj_folder")"

      if command -v gum &>/dev/null; then
        gum spin --title="preparing to clone... $repo_name" -- rm -rf -- "$temp_folder"
        if ! gum spin --title="preparing to clone... $repo_name" -- git clone --filter=blob:none "$proj_repo" "$temp_folder"; then
          print " fatal: failed to clone ${repo_name}" >&2
          return 1;
        fi
      else
        print " preparing to clone... $repo_name" >&2
        rm -rf -- "$temp_folder"
        if ! git clone --filter=blob:none "$proj_repo" "$temp_folder"; then return 1; fi
      fi

      local first_branch="$(get_my_branch_ "$temp_folder" 2>/dev/null)"

      folder_to_clone="${proj_folder}/${first_branch}"
    fi
  fi # if (( single_mode )); then

  if [[ -z "$folder_to_clone" ]]; then
    print " fatal: could not determine folder to clone into" >&2
    return 1;
  fi

  local jira_key=""

  if [[ -n "$branch_arg" ]]; then
    jira_key="$(extract_jira_key_ "$branch_arg")"
    if [[ -n "$jira_key" ]]; then
      branch_arg="$(get_monogram_branch_name_ "$branch_arg")"
      if (( $? == 130 )); then return 130; fi
    fi
  fi

  local RET=0

  rm -rf -- "${folder_to_clone}/.DS_Store" &>/dev/null

  if is_proj_folder_empty_ "$folder_to_clone"; then
    if command -v gum &>/dev/null; then
      if ! gum spin --title="git clone... $repo_name" -- git clone --filter=blob:none "$proj_repo" "$folder_to_clone"; then
        print " fatal: failed to clone ${repo_name}" >&2
        return 1;
      fi
    else
      print " git clone... $repo_name" >&2
      if ! git clone --filter=blob:none "$proj_repo" "$folder_to_clone"; then return 1; fi
    fi
  fi

  if ! is_folder_git_ "$folder_to_clone"; then
    print " ${red_cor}fatal: folder is not a git repository: ${bold_cor}$folder_to_clone${reset_cor}" >&2
    return 1;
  fi

  local first_branch="$(get_my_branch_ "$folder_to_clone" 2>/dev/null)"

  if [[ -z "$first_branch" ]]; then
    print " ${red_cor}fatal: failed to determine local branch${reset_cor}" >&2
    return 1;
  fi

  if [[ -n "$jira_key" ]]; then
    local pump_jira_key="$(get_pump_value_ "JIRA_KEY" "$folder_to_clone")"

    if [[ -z "$pump_jira_key" ]]; then
      update_pump_file_ "JIRA_KEY" "$jira_key" "$folder_to_clone"
    fi
    
    local pump_jira_title="$(get_pump_value_ "JIRA_TITLE" "$folder_to_clone")"

    if [[ -z "$pump_jira_title" ]]; then
      if command -v acli &>/dev/null; then
        jira_title="$(acli jira workitem view "$jira_key" --fields=summary --json | jq -r '.fields.summary' 2>/dev/null)"

        update_pump_file_ "JIRA_TITLE" "$jira_title" "$folder_to_clone"
      fi
    fi
  fi

  if [[ -n "$branch_arg" && "$first_branch" != "$target_branch" && "$branch_arg" != "$first_branch" && "$branch_arg" != "main" && "$branch_arg" != "master" ]]; then
    if [[ -z "$target_branch" ]] && command -v gh &>/dev/null; then
      local pr_target_branch="$(gh pr view "${(q)branch_arg}" --repo "$proj_repo" --json state,baseRefName --jq 'select(.state == "OPEN") | .baseRefName' 2>/dev/null)"

      # if there's an open pr, let's use that target branch
      if [[ -n "$pr_target_branch" ]]; then
        target_branch="$pr_target_branch"
      fi
    fi

    if [[ -z "$target_branch" ]]; then
      # if work type is release, then target branch is always main branch
      if [[ "$work_type" == "release" ]]; then
        target_branch="$(get_main_branch_ "$folder_to_clone" 2>/dev/null)"
      fi

      if [[ -z "$target_branch" ]]; then
        target_branch="$(determine_target_branch_ -dbem "$branch_arg" "$folder_to_clone" "$proj_cmd" "$first_branch")"
        # if (( $? == 130 )); Do not cancel here
        if [[ -z "$target_branch" ]]; then
          target_branch="$first_branch";
        fi
      fi
    fi

    if [[ -n "$target_branch" ]]; then
      local remote_name="$(get_remote_name_ "$folder_to_clone")"

      git -C "$folder_to_clone" config branch.$branch_arg.gh-merge-base $target_branch
      git -C "$folder_to_clone" config branch.$branch_arg.vscode-merge-base $remote_name/$target_branch
    fi
  fi

  if [[ -n "$target_branch" ]]; then
    if git -C "$folder_to_clone" switch "$target_branch" &>/dev/null; then
      if git -C "$folder_to_clone" switch "$branch_arg" &>/dev/null; then
        if [[ -n "$target_branch_arg" ]]; then
          print " ${yellow_cor}warning: branch already exists: ${hi_yellow_cor}$branch_arg${reset_cor}" >&2

          confirm_ "continue?" "continue" "abort"
          local _RET=$?
          if (( _RET == 130 || _RET == 2 )); then return 130; fi
          if (( _RET == 1 )); then
            del -fx -- "$folder_to_clone"
            return 1;
          fi

          print "" >&2
          print " if you meant to create a new branch with the same name, follow the steps below:" >&2
          print "  • run: ${hi_yellow_cor}delb -r $branch_arg${reset_cor} to delete the old branch" >&2
          print "  • run: ${hi_yellow_cor}del .${reset_cor} to delete this folder" >&2
          print "  • then try again" >&2
          print "" >&2
        fi
      else
        if ! git -C "$folder_to_clone" switch -c "$branch_arg" &>/dev/null; then
          print " ${red_cor}fatal: failed to create branch: ${bold_cor}$branch_arg${reset_cor}" >&2
          RET=1
        fi
      fi
    else
      print " ${red_cor}fatal: failed to switch to target branch: ${bold_cor}$target_branch${reset_cor}" >&2
      RET=1
    fi
  fi

  if [[ -n "$branch_arg" ]]; then
    local remote_branch_arg="$(get_remote_branch_ -f "$branch_arg" "$folder_to_clone")"

    if [[ -z "$remote_branch_arg" ]]; then
      local remote_name="$(get_remote_name_ "$folder_to_clone")"
      print " branch create: ${hi_yellow_cor}${branch_arg}${reset_cor} but not in $remote_name"
    else
      print " branch cloned: ${hi_green_cor}${remote_branch_arg}${reset_cor}"
    fi

    if [[ -n "$target_branch" && "$target_branch" != "$branch_arg" ]]; then
      local remote_name="$(get_remote_name_ "$folder_to_clone")"
      local existing_target_branch="$(git -C "$folder_to_clone" ls-remote --heads "$remote_name" "$target_branch" 2>/dev/null)"

      if [[ -z "$existing_target_branch" ]] && [[ "$target_branch" != "$target_branch_arg" ]]; then
        print " target branch: ${yellow_cor}$target_branch${reset_cor} but not in $remote_name"
      else
        print " target branch: ${hi_cyan_cor}$target_branch${reset_cor}"
      fi
    fi
    print ""
  fi

  print " next thing to do:"

  if [[ -n "${PUMP_SETUP[$i]}" ]]; then
    print "  • ${hi_yellow_cor}setup${reset_cor} (runs PUMP_SETUP_$i)"
  else
    local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    local setup_script="$(get_from_package_json_ "scripts.setup" "$folder_to_clone")"

    if [[ -n "$setup_script" && -n "$pkg_manager" ]]; then
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager run setup\")"
    elif [[ -n "$pkg_manager" ]]; then
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager install\")"
    fi
    print "    ${white_cor}edit PUMP_SETUP_$i in your pump.zshenv file to customize the setup script${reset_cor}"
  fi

  if [[ -n "$branch_arg" ]]; then
    print "  --"
    
    local d_branch="$(get_default_branch_ "$folder_to_clone" 2>/dev/null)"
    
    if [[ -n "$d_branch" ]]; then
      print "  • ${hi_yellow_cor}main${reset_cor} (alias for \"git switch $d_branch\")"
    fi
    if [[ -n "$target_branch" ]]; then
      print "  • ${hi_yellow_cor}base${reset_cor} (alias for \"git switch $b_branch\")"
    fi
  fi

  print "  --"
  print "  • ${hi_yellow_cor}$proj_cmd -h${reset_cor} for your project options"
  print "  • ${hi_yellow_cor}pro -h${reset_cor} for project management options"
  print "  • ${hi_yellow_cor}help${reset_cor} for more help"
  print ""

  if ! cd "$folder_to_clone"; then
    print " ${red_cor}fatal: failed to cd into cloned folder: ${bold_cor}$folder_to_clone${reset_cor}" >&2
    return 1;
  fi

  if [[ -n "$pump_clone" ]]; then
    print " ${script_cor}${pump_clone}${reset_cor}"

    if ! eval "$pump_clone"; then
      print " ${yellow_cor}warning: failed to run PUMP_CLONE_$i ${reset_cor}" >&2
      print " edit config: $PUMP_CONFIG_FILE then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    fi
  fi

  return $RET;
}

function proj_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "alsrfx" "" "$@")"
  (( proj_prs_is_debug )) && set -x

  local proj_cmd="$1"
  local search_term=""

  if (( proj_prs_is_h )); then
    proj_print_help_ "$proj_cmd" "prs"
    return 0;
  fi

  if [[ -n "$2" && $2 != -* ]]; then
    search_term="$2"
  fi

  if (( ! proj_prs_is_a && ! proj_prs_is_l )) && [[ -n "$search_term" ]]; then
    print " fatal: search term can only be used with -a and -l flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd prs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_prs_is_x && ! proj_prs_is_r )); then
    print " fatal: -x flag can only be used with -r flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd prs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_prs_is_f && ! proj_prs_is_a_a )); then
    print " fatal: -f flag can only be used with -aa flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd prs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -frg $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local pr_approval_min="${PUMP_PR_APPROVAL_MIN[$i]}"

  if [[ -z "$proj_repo" ]]; then
    print " fatal: no repository configured for project: $proj_cmd" >&2
    print " run: ${hi_yellow_cor}$proj_cmd -e${reset_cor} to set the repository" >&2
    return 1;
  fi

  local current_user="$(gh api user -q .login 2>/dev/null)"
  if [[ -z "$current_user" ]]; then
    print " fatal: failed to fetch current github username" >&2
    return 1;
  fi

  if (( proj_prs_is_s )); then
    local RET=0

    while true; do
      proj_prs_s_ "$proj_repo"
      RET=$?
      # if (( RET != 0 )); then break; fi

      if (( proj_prs_is_a )); then
        print "sleeping for $PUMP_INTERVAL minutes..."
        sleep $(( 60 * PUMP_INTERVAL ))
      fi
    done

    return $RET;
  fi

  if (( proj_prs_is_a_a )); then
    local RET=0

    while true; do
      proj_prs_aa_ -f "$proj_repo" "$search_term" "$pr_approval_min" "$current_user"
      RET=$?
      # if (( RET != 0 )); then break; fi

      print "sleeping for $PUMP_INTERVAL minutes..."
      sleep $(( 60 * PUMP_INTERVAL ))
    done

    return $RET;
  fi

  if (( proj_prs_is_a )); then
    # user select prs to approve based on search term, then approve them one by one
    local prs_output=""
    prs_output="$(select_prs_ -d "$search_term" "$proj_repo" "prs to approve")"
    if (( $? == 130 )); then return 130; fi
    
    prs=("${(@f)prs_output}")
    if [[ -z "$prs" ]]; then return 1; fi

    local pr
    for pr in "${prs[@]}"; do
      local pr_number=""
      local pr_branch=""
      local pr_title=""

      IFS=$TAB read -r pr_number pr_branch pr_title <<<"$pr"

      if [[ -z "$pr_number" || -z "$pr_title" ]]; then return 1; fi

      approve_pr_ -sf "$pr_number" "$pr_branch" "$pr_title" "$proj_repo" "$pr_approval_min" "$current_user"
      if (( $? == 130 )); then return 130; fi
    done

    return $?;
  fi

  if (( proj_prs_is_r )); then
    # rebase/merge all users open pull requests
    if (( proj_prs_is_x )); then
      proj_prs_r_ -x $i "$proj_cmd"
    else
      proj_prs_r_ $i "$proj_cmd"
    fi

    return $?;
  fi

  if (( proj_prs_is_l_l )); then
    # label prs by release, user select release, then label all prs in that release
    if ! check_jira_ -ip $i; then return 1; fi

    local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
    local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

    local releases_out="$(get_jira_releases_ $i "$jira_proj" "$jira_api_token")"
    local releases=("${(@f)releases_out}")

    if [[ -z "$releases" ]]; then
      print " fatal: no releases found for project: $jira_proj" >&2
      return 1;
    fi

    local release=""
    for release in "${releases[@]}"; do
      proj_prs_l_ -f $i "$release" "$search_term"
      print " ---"
    done

    return $?;
  fi

  if (( proj_prs_is_l )); then
    proj_prs_l_ $i "" "$search_term"

    return $?;
  fi

  # list prs that need reviews from you
  while true; do
    proj_pr_ "$proj_repo" "$pr_approval_min" "$current_user"

    print "sleeping for $PUMP_INTERVAL minutes..."
    sleep $(( 60 * PUMP_INTERVAL ))
  done

  return $?;
}

function proj_prs_l_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( proj_prs_l_is_debug )) && set -x

  local i="$1"
  local jira_release="$2"
  local search_key="$3"

  local proj_repo="${PUMP_REPO[$i]}"

  if ! check_jira_ -ipss $i; then return 1; fi

  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  if [[ -z "$jira_release" ]]; then
    jira_release="$(select_proj_release_ $i "$jira_proj" "$jira_api_token")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$jira_release" ]]; then return 1; fi
  fi

  print " ${purple_cor}release:${reset_cor} $jira_release"

  local choose_labels=()
  local is_version_label=0

  if [[ "$jira_release" =~ ([0-9]+)(\.[0-9]+)?(\.[0-9]+)? ]]; then
    local release_version="${match[1]}${match[2]:-".0"}${match[3]:-".0"}"

    if (( ! proj_prs_l_is_f )); then
      confirm_ "use release version as label: ${pink_cor}$release_version${reset_cor}?"
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi;
      if (( _RET == 0 )); then
        choose_labels+=("$release_version")
        is_version_label=1
      fi
    else
      choose_labels+=("$release_version")
      is_version_label=1
    fi
  fi

  if (( ! proj_prs_l_is_f )); then
    confirm_ "add more labels?" "yes" "no" "no"
    local _RET=$?
    if (( _RET == 130 || _RET == 2 )); then return 130; fi;
    if (( _RET == 0 )); then
      local all_labels_out="$(gh label list --repo "$proj_repo" --json=name | jq -r '.[].name' | sort -rf)"
      local all_labels=("<new label...>" "${(@f)all_labels_out}")
      
      local choose_labels_out=""
      choose_labels_out="$(choose_one_ "labels" "${all_labels[@]}")"
      if (( $? == 130 )); then return 130; fi
      if [[ -n "$choose_labels_out" ]]; then
        choose_labels+=("${(@f)choose_labels_out}");
      fi
    fi
  fi

  local is_remove_labels=0

  if (( ! proj_prs_l_is_f )); then
    if (( is_version_label )); then
      confirm_ "remove other existing labels from prs if they are version labels?" "yes" "no" "no"
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi;
      if (( _RET == 0 )); then
        is_remove_labels=1
      fi
    fi
  elif (( is_version_label )); then
    is_remove_labels=1
  fi
  
  # if one of choose_labels is "new label...", prompt for new label
  if [[ " ${choose_labels[*]} " == *" <new label...> "* ]]; then
    local new_label=""
    new_label="$(input_type_mandatory_ "type new label name")"
    if (( $? == 130 )); then return 130; fi

    choose_labels=("${(@)choose_labels:#'<new label...>'}" "$new_label")
  fi

  # loop each label in choose_labels and run the following:
  local label=""
  for label in "${choose_labels[@]}"; do
    if [[ -z "$(gh label list --repo "$proj_repo" --search "$label" 2>/dev/null)" ]]; then
      if gh label create --repo "$proj_repo" "$label" &>/dev/null; then
        print " ${green_cor}✓ label created:${reset_cor} ${blue_cor}$label${reset_cor}"
      else
        print " ${red_cor}✗ label failed:${reset_cor} ${blue_cor}$label${reset_cor}"
        return 1;
      fi
    fi
  done

  if [[ -n "${choose_labels[@]}" ]]; then
    print " ${purple_cor} labels:${reset_cor} $choose_labels"
  else
    if (( ! is_remove_labels )); then return 1; fi
  fi

  local tickets="$(filter_jira_keys_by_release_ $i "$jira_proj" "$jira_release" "$search_key")"
  local tickets=("${(@f)tickets}")

  local ticket=""
  for ticket in "${tickets[@]}"; do
    local key="$(echo $ticket | awk '{print $1}')"
    
    local output="$(find_prs_by_jira_key_ -om "$key" "$proj_repo" 2>/dev/null)"
    local prs=("${(@f)output}")
    
    if [[ -z "$prs" ]]; then
      continue;
    fi

    local line=""
    for line in "${prs[@]}"; do
      local pr_number=""
      local pr_link=""
      IFS=$TAB read -r pr_number pr_link _ <<<"$line"

      # check if pr has labels and if a label is in the format of <major>.<minor>.<patch>, remove it
      local existing_labels_out="$(gh pr view "$pr_number" --repo "$proj_repo" --json labels --jq '.labels[].name' 2>/dev/null)"
      local existing_labels=("${(@f)existing_labels_out}")

      # remove labels
      if (( is_remove_labels )); then
        for label in "${existing_labels[@]}"; do
          if [[ "$label" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            if [[ " ${choose_labels[*]} " == *" $label "* ]]; then
              print " ${green_cor}✓ label exist:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
              continue;
            fi

            if gh pr edit "$pr_number" --repo "$proj_repo" --remove-label "$label" &>/dev/null; then
              print " ${magenta_cor}✓ label remov:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
            else
              print " ${red_cor}✗ label error:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
            fi
          fi
        done
      fi

      for label in "${choose_labels[@]}"; do
        if [[ " ${existing_labels[*]} " != *" $label "* ]]; then
          if gh pr edit "$pr_number" --repo "$proj_repo" --add-label "$label" &>/dev/null; then
            print " ${green_cor}✓ label added:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
          else
            print " ${red_cor}✗ label error:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
          fi
        elif (( ! is_remove_labels )); then
          print " ${green_cor}✓ label exist:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_link${reset_cor}"
        fi
      done

    done
  done

}

function proj_prs_r_() {
  set +x
  eval "$(parse_flags_ "$0" "x" "" "$@")"
  (( proj_prs_r_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  if ! command -v gum &>/dev/null; then
    print " fatal: command requires gum" >&2
    print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
    return 1;
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
  if [[ -z "$repo_name" ]]; then
    print " fatal: invalid repository url: $proj_repo" >&2
    return 1;
  fi

  local current_user="$(gh api user -q .login 2>/dev/null)"
  if [[ -z "$current_user" ]]; then
    print " fatal: failed to fetch current github username" >&2
    return 1;
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
  if [[ -z "$repo_name" ]]; then
    print " fatal: invalid repository url: $proj_repo" >&2
    return 1;
  fi

  local folder="$(get_proj_special_folder_ -t $i "$proj_cmd" "$proj_folder")"
  
  if command -v gum &>/dev/null; then
    gum spin --title="preparing for rebasing prs..." -- rm -rf -- "$folder"
    if ! gum spin --title="preparing for rebasing prs..." -- git clone --filter=blob:none "$proj_repo" "$folder"; then
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  else
    print " preparing for rebasing prs..." >&2
    rm -rf -- "$folder"
    if ! git clone --filter=blob:none "$proj_repo" "$folder"; then
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  fi

  local remote_name="$(get_remote_name_ "$folder")"

  # get a list of all open PRs for the current user
  local pr_list=$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" \
    --limit 100 --state open \
    --author $current_user \
    --json number,title,isDraft,headRefName,baseRefName \
    --jq '.[] | {number, title, isDraft, headRefName, baseRefName} // empty' \
  )

  if [[ -z "$pr_list" ]]; then
    print " no open pull requests on: $repo_name" >&2
    return 1;
  fi

  echo "$pr_list" | jq -c '.' | while read -r pr; do
    local pr_number="$(jq -r '.number' <<<"$pr")"
    local pr_title="$(jq -r '.title' <<<"$pr")"
    local pr_is_draft="$(jq -r '.isDraft' <<<"$pr")"
    local pr_branch="$(jq -r '.headRefName' <<<"$pr")"
    local pr_base_branch="$(jq -r '.baseRefName' <<<"$pr")"

    # local pr_number="$(echo $pr | jq -r '.number')"
    # local pr_title="$(echo $pr | jq -r '.title')"
    # local pr_is_draft="$(echo $pr | jq -r '.isDraft')"
    # local pr_branch="$(echo $pr | jq -r '.headRefName')"
    # local pr_base_branch="$(echo $pr | jq -r '.baseRefName')"
    

    local pr_link="$(gh pr view "$pr_number" --repo "$proj_repo" --json url -q .url 2>/dev/null)"
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'
    local pr_desc="${blue_cor}$pr_number_link${reset_cor} ${hi_gray_cor}$pr_title${reset_cor}"

    # for each pr, check if the last commit message contains "Merge" if so, merge, otherwise, rebase
    local pr_commits="$(gh pr view "$pr_number" --repo "$proj_repo" --json commits --jq '.commits[].oid' 2>/dev/null)"
    local pr_commits=("${(@f)pr_commits}")
    if [[ -z "$pr_commits" ]]; then
      print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
      continue;
    fi

    local is_merge_commit=0

    # check if any commit in $pr_commits is a Merge commit
    for commit in "${pr_commits[@]}"; do
      local commit_message="$(gh api repos/$repo_name/commits/$commit --jq '.commit.message' 2>/dev/null)"
      if [[ -n "$commit_message" && "$commit_message" == Merge* ]]; then
        is_merge_commit=1
      fi
    done

    local label_work="$( (( is_merge_commit )) && echo "merge" || echo "rebase" )"

    if [[ "$pr_is_draft" == "true" ]]; then
      confirm_ "pr is on draft, confirm ${label_work}? ${pr_desc}" "${label_work}" "skip"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then
        print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
        continue;
      fi
    fi

    if ! git -C "$folder" switch "$pr_branch" --quiet &>/dev/null; then
      print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
      continue;
    fi

    gum spin --title="cleaning... " -- git -C "$folder" clean -fd --quiet &>/dev/null
    gum spin --title="cleaning... " -- git -C "$folder" restore --quiet --worktree . &>/dev/null
    gum spin --title="cleaning... " -- git -C "$folder" reset --hard --quiet $remote_name/$pr_branch &>/dev/null
    gum spin --title="cleaning... " -- git -C "$folder" pull --quiet $remote_name $pr_branch &>/dev/null

    if (( proj_prs_r_is_x )); then
      if (( is_merge_commit )); then
        if ! gum spin --title="merging... $pr_desc" -- git -C "$folder" merge "$remote_name/$pr_base_branch" --no-edit; then
          git -C "$folder" merge --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
          continue;
        fi
      else
        if ! gum spin --title="rebasing... $pr_desc" -- git -C "$folder" rebase "$remote_name/$pr_base_branch"; then
          git -C "$folder" rebase --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
          continue;
        fi
      fi

      unsetopt monitor
      unsetopt notify
      local pipe_name="$(mktemp -u)"
      mkfifo "$pipe_name" &>/dev/null
      gum spin --title="running fix... $pr_branch" -- sh -c "read < $pipe_name" &
      local spin_pid=$!

      refix "$folder" &>/dev/null
      
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null
      setopt notify
      setopt monitor

      if git -C "$folder" push $remote_name $pr_branch --force --quiet &>/dev/null; then
        if (( is_merge_commit )); then
          print " ${cyan_cor} merged:${reset_cor} $pr_desc" >&2
        else
          print " ${cyan_cor}rebased:${reset_cor} $pr_desc" >&2
        fi
      else
        print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
      fi
    else
      if (( is_merge_commit )); then
        if gum spin --title="merging... $pr_desc" -- zsh -c '
          git -C "$1" merge "$2/$3" --no-edit &&
          git -C "$1" push $2 $4 --quiet' \
          _ "$folder" "$remote_name" "$pr_base_branch" "$pr_branch"; then
          print " ${cyan_cor} merged:${reset_cor} $pr_desc" >&2
        else
          git -C "$folder" merge --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
        fi
      else
        if gum spin --title="rebasing... $pr_desc" -- zsh -c '
          git -C "$1" rebase "$2/$3" &&
          git -C "$1" push $2 $4 --force --quiet' \
          _ "$folder" "$remote_name" "$pr_base_branch" "$pr_branch"; then
          print " ${cyan_cor}rebased:${reset_cor} $pr_desc" >&2
        else
          git -C "$folder" rebase --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
        fi
      fi
    fi
  done

  gum spin --title="cleaning..." -- rm -rf -- "$folder"
}

function proj_prs_aa_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( proj_prs_aa_is_debug )) && set -x

  local proj_repo="$1"
  local search_term="$2"
  local pr_approval_min="$3"
  local current_user="$4"

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"
  
  local pr_list

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" --draft=false --json number,title,headRefName --jq ".[] | select(.title | test(\"$search_term\"; \"i\")) | \"\(.number)${TAB}\(.title)${TAB}\(.headRefName)\"" 2>/dev/null)"
    pr_list=("${(@f)pr_list}")
  else
    print " fetching prs... $repo_name"
    pr_list="$(gh pr list --repo "$proj_repo" --draft=false --json number,title,headRefName --jq ".[] | select(.title | test(\"$search_term\"; \"i\")) | \"\(.number)${TAB}\(.title)${TAB}\(.headRefName)\"" 2>/dev/null)"
    pr_list=("${(@f)pr_list}")
  fi

  if [[ -z "$pr_list" ]]; then
    if [[ -n $search_term ]]; then
      print " no prs found with '$search_term' in repository: $repo_name" >&2
    else
      print " no prs found in repository: $repo_name" >&2
    fi
    return 1;
  fi

  # declare an associative array to track approved PRs
  typeset -A approved_prs

  local pr
  for pr in "${pr_list[@]}"; do
    local pr_number=""
    local pr_title=""
    local pr_branch=""

    IFS=$TAB read -r pr_number pr_title pr_branch <<<"$pr"

    # skip if this PR has already been approved or not-approved
    if [[ -n "${approved_prs[$pr_number]}" ]]; then
      continue;
    fi

    if (( proj_prs_aa_is_f )); then
      approve_pr_ -f "$pr_number" "$pr_branch" "$pr_title" "$proj_repo" "$pr_approval_min" "$current_user"
    else
      approve_pr_ "$pr_number" "$pr_branch" "$pr_title" "$proj_repo" "$pr_approval_min" "$current_user"
    fi
    local RET=$?
    if (( RET == 130 )); then return 130; fi

    # save the approved status for this PR
    approved_prs[$pr_number]=$RET
  done
}

function approve_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "slf" "" "$@")"
  (( approve_pr_is_debug )) && set -x

  local pr_number="$1"
  local pr_branch="$2"
  local pr_title="$3"
  local proj_repo="$4"
  local pr_approval_min="$5"
  local current_user="$6"

  print " checking pr... ${cyan_cor}$pr_title${reset_cor}"

  local pr_link="$(gh pr view "$pr_number" --repo "$proj_repo" --json url -q .url 2>/dev/null)"
  local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

  # check if title. has words wip, draft, do not merge
  if [[ "$pr_title" =~ (WIP|DRAFT|DO NOT MERGE) ]]; then
    clear_last_line_1_
    print " ${hi_gray_cor}pr $pr_number_link has 0 ✓ and is drafted, skipping${reset_cor}"
    continue;
  fi

  # check if labels has "do not merge" (case insensitive)
  local pr_labels="$(gh pr view "$pr_number" --repo "$proj_repo" --json labels --jq '.labels[].name' 2>/dev/null)"
  if [[ "$pr_labels" =~ (DO NOT MERGE|Do Not Merge|do not merge) ]]; then
    clear_last_line_1_
    print " ${hi_gray_cor}pr $pr_number_link has label do not merge, skipping${reset_cor}"
    continue;
  fi

  # fetch full PR info including draft status and reviews
  local is_draft="$(gh pr view "$pr_number" --repo "$proj_repo" --json isDraft -q . | jq -r '.isDraft' 2>/dev/null)"
  if [[ "$is_draft" == "true" ]]; then
    clear_last_line_1_
    print " ${hi_gray_cor}pr $pr_number_link has 0 ✓ and is drafted, skipping${reset_cor}"
    continue;
  fi

  local from_branch="$(gh pr view "${(q)pr_branch}" --repo "$proj_repo" --json headRefName --jq '.headRefName' 2>/dev/null)"

  # count valid approvals (not dismissed), using latest review per user
  local approval_count=$(gh pr view "$pr_number" --repo "$proj_repo" --json reviews \
    | jq '.reviews
    | reverse
    | unique_by(.author.login)
    | map(select(.state == "APPROVED" and (.dismissed == false or .dismissed == null)))
    | length' 2>/dev/null
  )

  # check if current user has already approved
  local user_has_approved=$(gh pr view "$pr_number" --repo "$proj_repo" --json reviews \
    | jq --arg user "$current_user" '.reviews
    | reverse
    | unique_by(.author.login)
    | map(select(.author.login == $user and .state == "APPROVED" and (.dismissed == false or .dismissed == null)))
    | length' 2>/dev/null
  )

  local pr_author="$(gh pr view "$pr_number" --repo "$proj_repo" --json author -q .author.login 2>/dev/null)"

  clear_last_line_1_

  local is_authorized=0

  if (( approval_count < pr_approval_min )) || (( approve_pr_is_s )); then
    if (( user_has_approved )); then
      print " pr $pr_number_link has $approval_count ✓ and you also approved it"
    else
      local is_main=0;

      if [[ "$pr_author" != "$current_user" ]]; then
        if (( ! approve_pr_is_f && ! approve_pr_is_l )) && [[ "$from_branch" != "main" ]]; then
          confirm_ "pr $pr_number_link $pr_title has $approval_count ✓, approve it?" "approve" "skip"
          local RET=$?
          if (( RET == 130 || RET == 2 )); then return 130; fi
          if (( RET == 0 )); then
            is_authorized=1;
          fi
        else
          is_main=1;
          is_authorized=1;
        fi
      fi

      if (( is_authorized || approve_pr_is_f )) && (( ! approve_pr_is_l )) && [[ "$pr_author" != "$current_user" ]]; then
        if gh pr review $pr_number --approve --repo "$proj_repo" &>/dev/null; then
          (( approval_count++ ))
          if (( is_main )); then
            print " ${green_cor}pr $pr_number_link has $approval_count ✓ and you auto approved it${reset_cor}"
          else
            print " ${green_cor}pr $pr_number_link has $approval_count ✓ and you just approved it${reset_cor}"
          fi
        else
          print " ${red_cor}pr $pr_number_link has $approval_count ✗ but failed to be approve${reset_cor}"
        fi
      elif [[ "$pr_author" != "$current_user" ]]; then
        print " ${red_cor}pr $pr_number_link has $approval_count ✗ and you did not approve!${reset_cor}"
      else
        print " pr $pr_number_link has $approval_count ✗ but you authored this pr"
      fi

    fi
  else
    if (( user_has_approved )); then
      print " pr $pr_number_link has $approval_count ✓ and you also approved it"
    else
      if [[ "$pr_author" == "$current_user" ]]; then
        print " pr $pr_number_link has $approval_count ✗ and you authored this pr"
      else
        print " ${yellow_cor}pr $pr_number_link has $approval_count ✗ but you did not approve!${reset_cor}"
      fi
    fi
  fi

  return $is_authorized;
}

function proj_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_pr_is_debug )) && set -x

  local proj_repo="$1"
  local pr_approval_min="$2"
  local current_user="$3"

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  local pr_list

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" --draft=false --state open --json number,title,url,isDraft,labels,author,reviews --jq '.[] | {number, title, url, isDraft, labels, author} // empty' --jq '.[] | .reviews |= map({ author: .author.login, state, dismissed }) // empty' 2>/dev/null)"
  else
    print " fetching prs... $repo_name"
    pr_list="$(gh pr list --repo "$proj_repo" --draft=false --state open --json number,title,url,isDraft,labels,author,reviews --jq '.[] | {number, title, url, isDraft, labels, author} // empty' --jq '.[] | .reviews |= map({ author: .author.login, state, dismissed }) // empty' 2>/dev/null)"
  fi

  if [[ -z "$pr_list" ]]; then
    print " no ready pull requests on: $repo_name" >&2
    return 1;
  fi

  echo "$pr_list" | jq -c '.' | while read -r pr; do
    local pr_number="$(jq -r '.number' <<<"$pr")"
    local pr_title="$(jq -r '.title' <<<"$pr")"
    local pr_link="$(jq -r '.url' <<<"$pr")"
    local pr_author="$(jq -r '.author.login' <<<"$pr")"
    local is_draft="$(jq -r '.isDraft' <<<"$pr")"

    local has_dnm_label=$(jq -r '
      [.labels[].name | ascii_downcase] |
      any(. == "do not merge")
    ' <<<"$pr")

    # build clickable link
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

    # title-based skip
    if [[ "$pr_title" =~ (WIP|DRAFT|DO NOT MERGE) ]] || [[ "$has_dnm_label" == "true" ]] || [[ "$is_draft" == "true" ]]; then
      print " ${hi_gray_cor}pr $pr_number_link has 0 ✓ and is drafted, skipping${reset_cor}"
      continue;
    fi

    # approvals (latest review per user)
    approval_count=$(jq '
      .reviews
      | reverse
      | unique_by(.author)
      | map(select(
          .state == "APPROVED"
          and (.dismissed == false or .dismissed == null)
        ))
      | length
    ' <<<"$pr")

    user_has_approved=$(jq --arg user "$current_user" '
      .reviews
      | reverse
      | unique_by(.author)
      | any(
          .author == $user
          and .state == "APPROVED"
          and (.dismissed == false or .dismissed == null)
        )
    ' <<<"$pr")

    if (( approval_count < pr_approval_min )); then
      if [[ "$user_has_approved" == "true" ]]; then
        print " pr $pr_number_link has $approval_count ✓ and you also approved it"
      else
        if [[ "$pr_author" != "$current_user" ]]; then
          print " ${red_cor}pr $pr_number_link has $approval_count ✗ and you did not approve!${reset_cor}"
        else
          print " pr $pr_number_link has $approval_count ✗ but you authored this pr"
        fi
      fi
    else
      if [[ "$user_has_approved" == "true" ]]; then
        print " pr $pr_number_link has $approval_count ✓ and you also approved it"
      else
        if [[ "$pr_author" == "$current_user" ]]; then
          print " pr $pr_number_link has $approval_count ✗ and you authored this pr"
        else
          print " ${yellow_cor}pr $pr_number_link has $approval_count ✗ but you did not approve!${reset_cor}"
        fi
      fi
    fi

  done
}

function proj_prs_s_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_prs_s_is_debug )) && set -x

  local proj_repo="$1"

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  local pr_list

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" --limit 100 --state open --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')"
  else
    print " fetching prs... $repo_name"
    pr_list="$(gh pr list --repo "$proj_repo" --limit 100 --state open --json number,author,assignees --jq '.[] | {number, author: .author.login, assignees} // empty')"
  fi

  if (( $? != 0 )); then return 1; fi

  echo "$pr_list" | jq -c '.' | while read -r pr; do
    local pr_number="$(echo $pr | jq -r '.number')"
    local author="$(echo $pr | jq -r '.author')"
    local assignees="$(echo "$pr" | jq -r '[.assignees[]? | (if .name != "" and .name != null then .name else .login end)] | join(", ")')"

    if [[ "$author" == "app/dependabot" ]]; then
      # print " ${yellow_cor}PR #$pr_number is from Dependabot, skipping${reset_cor}"
      continue;
    fi

    local pr_link="$(gh pr view "$pr_number" --repo "$proj_repo" --json url -q .url 2>/dev/null)"
    local pr_number_link=$'\e]8;;'"$pr_link"$'\a'"$pr_number"$'\e]8;;\a'

    if [[ -z "$assignees" ]]; then
      if gh pr edit "$pr_number" --add-assignee "$author" --repo "$proj_repo" &>/dev/null; then
        print " ${green_cor}pr $pr_number_link is assigned to $author${reset_cor}"
      else
        print " ${red_cor}pr $pr_number_link is not assigned${reset_cor}"
      fi
    else
      print " pr $pr_number_link is assigned to $assignees"
    fi
  done
}

function select_pr_() {
  local search_text="$1"
  local proj_repo="$2"
  local header="${3:-"pull request"}"

  if ! command -v gh &>/dev/null; then return 1; fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  local pr_list=""

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" --search="$search_text" --limit 100 --state open --json number,title,headRefName,url --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)\t\(.url)"' 2>/dev/null)"
  else
    pr_list="$(gh pr list --repo "$proj_repo" --search="$search_text" --limit 100 --state open --json number,title,headRefName,url --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)\t\(.url)"' 2>/dev/null)"
  fi

  if [[ -z "$pr_list" ]]; then
    print " no prs found in: $repo_name" >&2
    return 130;
  fi

  local titles=("${(@f)$(echo "$pr_list" | cut -f2)}")

  local select_pr_title=""
  select_pr_title="$(choose_one_ "$header" "${titles[@]}")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$select_pr_title" ]]; then return 1; fi

  local pr_number="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}' | xargs 2>/dev/null)"
  local pr_branch="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}' | xargs 2>/dev/null)"
  local pr_link="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $4}' | xargs 2>/dev/null)"

  print -r -- "${pr_number}${TAB}${pr_branch}${TAB}${select_pr_title}${TAB}${pr_link}"
}

function select_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  (( select_prs_is_debug )) && set -x

  local search_text="$1"
  local proj_repo="$2"
  local header="${3:-"pull requests"}"

  if ! command -v gh &>/dev/null; then return 1; fi

  local cli_params=()

  if (( select_prs_is_d )); then
    cli_params+=("--draft=false")
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  local pr_list=""

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list --repo "$proj_repo" --limit 100 --state open ${cli_params[@]} --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)"
  else
    print " fetching prs... $repo_name"
    pr_list="$(gh pr list --repo "$proj_repo" --limit 100 --state open ${cli_params[@]} --json number,title,headRefName --jq '.[] | "\(.number)\t\(.title)\t\(.headRefName)"' | grep -i "$search_text" 2>/dev/null)"
  fi

  if [[ -z "$pr_list" ]]; then
    if [[ -n $search_text ]]; then
      print " no prs found with '$search_text' in repository: $repo_name" >&2
    else
      print " no prs found in repository: $repo_name" >&2
    fi
    return 1;
  fi

  # local count="$(echo "$pr_list" | wc -l)"
  local titles=("${(@f)$(echo "$pr_list" | cut -f2)}")

  local select_pr_titles=""
  select_pr_titles="$(choose_multiple_ "$header" "${titles[@]}")"
  if (( $? == 130 )); then return 130; fi

  local select_pr_titles=("${(@f)select_pr_titles}")
  if [[ -z "$select_pr_titles" ]]; then return 1; fi

  local select_pr_title=""
  for select_pr_title in "${select_pr_titles[@]}"; do
    local select_pr_choice="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $1}' | xargs 2>/dev/null)"
    local select_pr_branch="$(echo "$pr_list" | awk -v title="$select_pr_title" -F'\t' '$2 == title {print $3}' | xargs 2>/dev/null)"

    print -r -- "${select_pr_choice}${TAB}${select_pr_branch}${TAB}${select_pr_title}"
  done
}

function proj_bkp_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpsd" "" "$@")"
  (( proj_bkp_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_bkp_is_h )); then
    proj_print_help_ "$proj_cmd" "bkp"
    return 0;
  fi

  if (( proj_bkp_is_d )); then
    proj_dbkp_ $@
    return $?;
  fi

  if [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run: ${hi_yellow_cor}$proj_cmd bkp -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fmv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local folder_to_backup="$proj_folder"

  if (( ! single_mode )); then
    local dirs_output=""
    dirs_output="$(get_folders_ -ijp $i "$proj_folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$dirs_output" ]]; then
      print " there is no folder to backup" >&2
      return 0;
    fi
  
    local dirs=("${(@f)dirs_output}")
    local folder="$(choose_one_ -t "folder" "${dirs[@]}")"
    if [[ -z "$folder" ]]; then return 1; fi

    folder_to_backup="${proj_folder}/${folder}"
  fi

  if [[ -z "$(ls -- "$folder_to_backup")" ]]; then
    print " project folder is empty" >&2
    return 0;
  fi

  local node_modules=0

  if [[ -d "$folder_to_backup/node_modules" ]]; then
    node_modules=1
  fi

  create_backup_ $i "$folder_to_backup"

  if (( node_modules )); then
    print " ${yellow_cor}warning: node_modules is not included in backup to reduce size${reset_cor}" >&2
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

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  local backups_folder="$(get_proj_special_folder_ -b $i "$proj_cmd" "$proj_folder")"
  
  if [[ -n "$folder_arg" ]]; then
    if [[ "$folder_arg" == "$backups_folder"* ]]; then
      del -s -- "$folder_arg"
      return $?;
    fi
    print " fatal: not a valid backup folder for: $proj_cmd" >&2
    return 1;
  fi

  if [[ ! -d "$backups_folder" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  local dirs_output=""
  dirs_output="$(get_folders_ -p $i "$backups_folder" 2>/dev/null)"
  if (( $? == 130 )); then return 130; fi

  if [[ -z "$dirs_output" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  local dirs=("${(@f)dirs_output}")

  dirs_output="$(choose_multiple_ "folders" "${dirs[@]}")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$dirs_output" ]]; then return 1; fi

  local folders=("${(@f)dirs_output}")

  local RET=0

  local folder=""
  for folder in "${folders[@]}"; do
    local clean_folder="$(echo "$folder" | awk -F'\t' '{print $1}')"
    del -s -- "${backups_folder}/${clean_folder}"
    RET=$?
  done

  if [[ -z "$(ls -- "$backups_folder")" ]]; then
    rm -rf -- "$backups_folder"
  fi

  local parent_folder="$(dirname -- "$backups_folder")"
  if [[ -z "$(ls -- "$parent_folder")" ]]; then
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

  local backups_folder="$(get_proj_special_folder_ -b $i "$proj_cmd" "$proj_folder")"

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
      print " ${hi_gray_cor}backup created: ${gray_cor}${proj_backup_folder}${reset_cor}"
    else
      print " ${hi_gray_cor}backup created: ${proj_backup_folder}${reset_cor}"
    fi
    return 0;
  fi

  print " ${red_cor}failed to backup${reset_cor}" >&2
  return 1;
}

function proj_exec_() {
  set +x
  eval "$(parse_flags_all_ "$0" "" "$@")"
  (( proj_exec_is_debug )) && set -x
  
  local proj_cmd="$1"
  local script=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    script="$2"
    (( arg_count++ ))
  fi

  shift $arg_count
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -e $i; then return 1; fi

  local proj_script_folder="${PUMP_SCRIPT_FOLDER[$i]}"

  local files=()

  if [[ -n "$script" ]]; then
    files=("$proj_script_folder/$script".*)
  else
    files=(
      "$proj_script_folder"/*.sh(N)
      "$proj_script_folder"/*.zsh(N)
      "$proj_script_folder"/*.bash(N)
      "$proj_script_folder"/*.ksh(N)
    )
  fi

  if [[ -z "$script" ]] && (( proj_exec_is_h )); then
    proj_print_help_ "$proj_cmd" "exec"
    print "  --"
    print "  available scripts in: ${green_cor}$proj_script_folder${reset_cor}"
    print " "
    local file
    for file in "${files[@]:t}"; do
      print "  ${hi_yellow_cor}$proj_cmd exec ${file%.*}${reset_cor}"
    done

    # find a readme file in proj_script_folder
    local readme=$(find "$proj_script_folder" -maxdepth 1 -type f -iname "readme*" | head -n 1)
    
    if [[ -n "$readme" ]]; then
      if command -v glow &>/dev/null; then
        glow "$readme" 
      elif command -v gum &>/dev/null; then
        gum style --margin "1 2" --border rounded "$(cat "$readme")"
      else
        print ""
        cat "$readme" | sed 's/^/  /'
      fi
    fi

    return 0;
  fi

  if [[ -z "$files" ]]; then
    print " no shell scripts found" >&2
    print " create them in: ${green_cor}$proj_script_folder${reset_cor}" >&2
    return 1;
  fi

  local file
  file=$(choose_one_ -i "script" "${files[@]:t}")
  if [[ -z "$file" ]]; then return 1; fi

  local script="$proj_script_folder/$file"

  if [[ ! -f "$script" ]]; then
    print " execution script not found: $script" >&2
    print " run: ${hi_yellow_cor}$proj_cmd exec -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # decide shell based on extension
  local shell
  case "$file" in
    *.zsh)  shell=zsh ;;
    *.bash) shell=bash ;;
    *.ksh)  shell=ksh ;;
    *.sh)   shell=sh ;;
    *)
      print " unknown shell type: $file" >&2
      print " run: ${hi_yellow_cor}$proj_cmd exec -h${reset_cor} to see usage" >&2
      return 1;
      ;;
  esac

  # print " ${script_cor}$shell $script $i $@${reset_cor}"
  # run script
  $shell $script $i $@
  return $?;
}

function proj_tag_() {
  set +x
  eval "$(parse_flags_ "$0" "fd" "" "$@")"
  (( proj_tag_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_tag_is_h )); then
    proj_print_help_ "$proj_cmd" "tag"
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
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${3:-${PUMP_FOLDER[$i]}}"

  local folder="$(get_proj_for_git_ "$proj_folder" "$proj_cmd")"
  if [[ -z "$folder" ]]; then return 1; fi

  if ! is_folder_pkg_ "$folder"; then return 1; fi
  
  prune "$folder" &>/dev/null

  if [[ -z "$tag" ]]; then
    tag="$(get_from_package_json_ "version" "$folder")"
    if [[ -n "$tag" ]]; then
      if (( ! proj_tag_is_f )) && ! confirm_ "create new tag: ${pink_cor}$tag${reset_cor}?"; then
        return 1;
      fi
    fi
  fi

  if [[ -z "$tag" ]]; then
    if (( ! proj_tag_is_f )); then
      tag="$(input_type_mandatory_ "tag name")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$tag" ]]; then return 1; fi

      print " ${purple_cor}tag name:${reset_cor} $tag"
    else
      return 1;
    fi
  fi

  git -C "$folder" tag --annotate "$tag" --message "$tag"
  
  if (( $? == 0 )); then
    git -C "$folder" push --no-verify --tags
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
    proj_print_help_ "$proj_cmd" "tags"
    return 0;
  fi

  local n=20

  if [[ -n "$2" ]]; then
    if [[ $2 == <-> ]]; then
      n=$2
    else
      print " fatal: not a valid argument: $2" >&2
      print " run: ${hi_yellow_cor}$proj_cmd tags -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  local folder="$(get_proj_for_git_ "$proj_folder" "$proj_cmd")"
  if [[ -z "$folder" ]]; then return 1; fi

  prune "$folder" &>/dev/null

  git -C "$folder" for-each-ref refs/tags --sort=-creatordate --format='%(creatordate:short) - %(refname:short)' --count="$n"
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

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${3:-${PUMP_FOLDER[$i]}}"

  local folder="$(get_proj_for_git_ "$proj_folder" "$proj_cmd")"
  if [[ -z "$folder" ]]; then return 1; fi

  local remote_name="$(get_remote_name_ "$folder")"

  if [[ -z "$tag" ]]; then
    local tags="$(git -C "$folder" tag)"
    local tags=("${(@f)tags}")
    
    if [[ -z "$tags" ]]; then
      print " no tag found in $proj_cmd"
      return 0;
    fi

    local selected_tags="$(choose_multiple_ "tags to delete" "${tags[@]}")"
    local selected_tags=("${(@f)selected_tags}")
    if [[ -z "$selected_tags" ]]; then return 1; fi

    for tag in "${selected_tags[@]}"; do
      git -C "$folder" tag $remote_name --delete "$tag"  2>/dev/null
      git -C "$folder" push $remote_name --no-verify --delete "$tag" 2>/dev/null
    done

    return 0;
  fi

  git -C "$folder" tag $remote_name --delete "$tag" 2>/dev/null
  git -C "$folder" push $remote_name --no-verify --delete "$tag" 2>/dev/null

  return $?;
}

function increment_version_() {
  set +x
  eval "$(parse_flags_ "$0" "mnp" "" "$@")"
  (( increment_version_is_debug )) && set -x

  local tag="$1"

  local is_v=0

  if [[ "$tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
    is_v=1
    tag="${tag#v}"
  fi

  local major_version minor_version patch_version

  if [[ "$tag" =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
    IFS='.' read -r major_version minor_version patch_version <<< "$tag"

    if (( increment_version_is_m )); then
      ((major_version++))
      minor_version=0
      patch_version=0
    elif (( increment_version_is_n )); then
      ((minor_version++))
      patch_version=0
    elif (( increment_version_is_p )); then
      ((patch_version++))
    fi

    if (( is_v )); then
      tag="v${major_version}.${minor_version}.${patch_version}"
    else
      tag="${major_version}.${minor_version}.${patch_version}"
    fi
  fi

  echo "$tag"
}

function proj_rel_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpfdb" "" "$@")"
  (( proj_rel_is_debug )) && set -x
  
  local proj_cmd="$1"

  shift

  if (( proj_rel_is_h )); then
    proj_print_help_ "$proj_cmd" "rel"
    return 0;
  fi
  
  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi

  if (( proj_rel_is_d )); then
    proj_drel_ $@
    return $?;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fr $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

  local branch=""
  local tag=""
  local title=""

  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    branch="$1"
    tag="$2"
    title="$3"

    arg_count=3

  elif [[ -n "$2" && $2 != -* ]]; then
    if is_branch_existing_ "$1" "$proj_folder"; then
      branch="$1"
      tag="$2"
    else
      tag="$1"
      title="$2"
    fi

    arg_count=2

  elif [[ -n "$1" && $1 != -* ]]; then
    if is_branch_existing_ "$1" "$proj_folder"; then
      branch="$1"
    else
      tag="$1"
    fi

    arg_count=1
  fi

  shift $arg_count

  local proj_pwd="$(find_proj_by_folder_ 2>/dev/null)"

  if (( ! proj_rel_is_f )) && [[ "$proj_cmd" != "$proj_pwd" || "$proj_cmd" != "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print " fatal: ${hi_yellow_cor}$proj_cmd rel${reset_cor} can only be run from the project folder" >&2
    return 1;
  fi

  if (( proj_rel_is_f )) && [[ -z "$branch" ]] || { [[ -z "$branch" ]] && ! is_folder_git_ &>/dev/null }; then
    print " fatal: branch argument is required" >&2
    print " run: ${hi_yellow_cor}$proj_cmd rel -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local lbl_release=""
  if (( proj_rel_is_b )); then
    lbl_release="pre-release"
  else
    lbl_release="release"
  fi

  local folder="$(get_proj_special_folder_ -t $i "$proj_cmd" "$proj_folder")"
  
  if command -v gum &>/dev/null; then
    gum spin --title="preparing... $lbl_release" -- rm -rf -- "$folder"
    if ! gum spin --title="preparing... $lbl_release" -- git clone --filter=blob:none "$proj_repo" "$folder"; then
      local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  else
    print " preparing... $lbl_release" >&2
    rm -rf -- "$folder"
    if ! git clone --filter=blob:none "$proj_repo" "$folder"; then
      local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  fi
  
  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$PWD")"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  if ! is_branch_name_valid_ "$branch"; then
    print " fatal: not a valid branch name: $branch" >&2
    return 1;
  fi

  branch="$(get_short_name_ "$branch" "$folder")"
  
  local remote_branch="$(get_remote_branch_ "$branch" "$folder")"

  if [[ -z "$remote_branch" ]]; then
    print " fatal: not a valid branch: $branch" >&2
    print " run: ${hi_yellow_cor}$proj_cmd rel -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # check if name is conventional
  if [[ "$branch" =~ ^(main|master|stage|staging|prod|production|release)$ || "$branch" == release* ]]; then
    print " preparing $lbl_release of ${blue_cor}$proj_cmd${reset_cor} from ${yellow_cor}$branch${reset_cor} branch..."
  else
    print " ${yellow_cor}preparing $lbl_release of ${blue_cor}$proj_cmd${yellow_cor} from ${orange_cor}$branch${reset_cor}${yellow_cor} branch..."
  fi

  local my_branch="$(get_my_branch_ "$PWD")"
  
  if [[ "$my_branch" == "$branch" && -n "$(git -C "$PWD" status --porcelain 2>/dev/null)" ]]; then
    print " fatal: working branch is not clean" >&2
    return 1;
  fi

  local is_version_bumped=0

  if [[ -z "$tag" ]]; then
    if ! is_folder_pkg_ "$folder"; then return 1; fi

    if command -v npm &>/dev/null; then
      local release_type=""
      if (( proj_rel_is_m )); then
        release_type="major"
      elif (( proj_rel_is_n )); then
        release_type="minor"
      elif (( proj_rel_is_p )); then
        release_type="patch"
      fi

      if [[ -n "$release_type" ]]; then
        if ! npm --prefix "$folder" version "$release_type" --no-commit-hooks --no-git-tag-version &>/dev/null; then
          print " fatal: not able to bump version: $release_type" >&2
          return 1;
        fi
        is_version_bumped=1
      fi

      tag="$(get_from_package_json_ "version" "$folder")"
    fi

    if [[ -z "$tag" ]]; then
      local latest_tag="$(tags 1 2>/dev/null)"
      local pkg_tag=""

      pkg_tag="$(get_from_package_json_ "version" "$folder")"

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
  fi

  if (( ! proj_rel_is_f )) && ! confirm_ "create ${lbl_release}: ${pink_cor}$tag${reset_cor}?"; then
    return 0;
  fi

  if (( is_version_bumped )); then
    # [[ -n "$(git -C "$folder" status --porcelain 2>/dev/null)" ]] also works
    if ! git -C "$folder" add .; then return 1; fi
    if ! git -C "$folder" commit --no-verify --message="chore: bump version $tag"; then return 1; fi
    if ! git -C "$folder" push --no-verify --quiet; then return 1; fi
  fi

  if gh release view "$tag" --repo "$proj_repo" &>/dev/null; then
    if (( ! proj_rel_is_f )) && ! confirm_ "it already exists, attempt to $lbl_release ${pink_cor}$tag${reset_cor} again?"; then
      return 1;
    fi

    proj_drel_single_ "$proj_cmd" "$tag" "" "$proj_repo" 1>/dev/null
    if (( $? != 0 )); then return 1; fi
  fi

  local flags=()

  if (( proj_rel_is_b )); then
    flags+=("--prerelease")
  fi
  # if (( proj_rel_is_r )); then
  #   flags+=("--draft")
  # fi

  if [[ -z "$title" ]]; then
    title="$tag"
  fi

  if gh release create "$tag" --repo "$proj_repo" --title="$title" --target "$branch" --fail-on-no-commits --generate-notes ${flags[@]}; then
    if (( is_version_bumped )); then
      local my_branch="$(get_my_branch_ "$PWD" 2>/dev/null)"
      if [[ "$my_branch" == "$branch" ]]; then
        print " version was bumped on your branch, run: ${hi_yellow_cor}pull${reset_cor} or ${hi_yellow_cor}pullr${reset_cor} to update it"
      elif [[ -n "$my_branch" ]]; then
        # if my_branch exists, that means we are in the project folder
        print " version was bumped on $branch branch"
      fi
    fi
    return 0;
  fi

  return 1;
}

function proj_rels_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_rels_is_debug )) && set -x
  
  local proj_cmd="$1"

  if (( proj_rels_is_h )); then
    proj_print_help_ "$proj_cmd" "rels"
    return 0;
  fi
  
  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -r $i; then return 1; fi
  
  local proj_repo="${PUMP_REPO[$i]}"

  gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}'
}

# delete release
function proj_drel_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_drel_is_debug )) && set -x

  local proj_cmd="$1"

  shift

  local tag=""
  local type=""

  if [[ -n "$2" && $2 != -* ]]; then
    tag="$2"
    if [[ -n "$3" && $3 != -* ]]; then
      type="$3"
    fi
  fi
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -r $i; then return 1; fi
  
  local proj_repo="${PUMP_REPO[$i]}"

  if [[ -n "$tag" ]]; then
    proj_drel_single_ "$proj_cmd" "$tag" "$type" "$proj_repo"
    return $?;
  fi

  local tags="$(gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}')"
  local tags=("${(@f)tags}")

  if [[ -z "$tags" ]]; then
    print " no release found in $proj_cmd"
    return 0;
  fi
  
  local selected_tags="$(choose_multiple_ "tags to delete" "${tags[@]}")"
  local selected_tags=("${(@f)selected_tags}")
  if [[ -z "$selected_tags" ]]; then return 1; fi

  local selected_tag
  for selected_tag in "${selected_tags[@]}"; do
    tag="$(echo -e "$selected_tag" | awk -F '\t' '{print $1}')"
    local type="$(echo -e "$selected_tag" | awk -F '\t' '{print $2}')"
    
    proj_drel_single_ "$proj_cmd" "$tag" "$type" "$proj_repo"
  done
}

function proj_drel_single_() {
  local proj_cmd="$1"
  local tag="$2"
  local type="$3"
  local proj_repo="$4"

  local display_tag="$([[ -n "$type" ]] && echo "$tag $type" || echo "$tag")"

  if ! gh release view "$tag" --repo "$proj_repo" &>/dev/null; then
    print " release not found: $display_tag" >&2
    return 1;
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... $display_tag" -- \
      gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
  else
    print " deleting... $display_tag"
    gh release delete "$tag" --repo "$proj_repo" --cleanup-tag --yes
  fi

  if (( $? == 0 )); then
    print " ${magenta_cor}deleted${reset_cor} $display_tag"
    return 0;
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null || echo "$proj_repo")"

  print " fatal: failed to delete release $display_tag, check if release immutability is enabled for repository: $repo_name" >&2
  return 1;
}

function proj_jira_find_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_jira_find_folder_is_debug )) && set -x

  local i="$1"
  local search_key="$2"
  local proj_jira_is_e="$3"
  local prompt_label="$4"

  local proj_folder="${PUMP_FOLDER[$i]}"

  local dirs=()

  if (( ! proj_jira_is_e )); then
    dirs+=("other...")
  fi

  local single_mode=0

  dirs+=("${(f)"$(get_maybe_jira_tickets_ -aij $i "$single_mode" "$proj_folder" "$search_key" 2>/dev/null)"}")
  if [[ -z "$dirs" ]]; then return 1; fi
  
  local chosen_folder=""

  if (( ${#dirs[*]} == 2 )); then;
    chosen_folder="${dirs[2]}"
  fi

  if [[ -z "$chosen_folder" ]]; then
    if [[ -n "$search_key" ]]; then
      chosen_folder="$(choose_one_ -it "work item $prompt_label" "${dirs[@]}")"
    else
      chosen_folder="$(choose_one_ -t "work item $prompt_label" "${dirs[@]}")"
    fi
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$chosen_folder" ]]; then return 1; fi
  fi
  
  echo "$chosen_folder"
}

function proj_jira_find_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_jira_find_branch_is_debug )) && set -x

  local jira_key="$1"
  local proj_jira_is_e="$2"
  local prompt_label="$3"

  local proj_folder="${PUMP_FOLDER[$i]}"

  local branch_found=""
  if (( proj_jira_is_e )); then
    branch_found="$(select_branch_ -jl "$jira_key" "$prompt_label" "$proj_folder")"
  else
    branch_found="$(select_branch_ -jli "$jira_key" "$prompt_label" "$proj_folder" 2>/dev/null)"
  fi
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$branch_found" ]]; then return 1; fi

  echo "$branch_found"
}

function get_jira_work_type_() {
  local i="$1"
  local jira_key="$2"

  if [[ -z "$jira_key" ]]; then
    print " fatal: jira key is required" >&2
    return 1;
  fi

  local work_type="$(gum spin --title=" work type..." -- acli jira workitem view "$jira_key" --fields=issuetype --json | jq -r '.fields.issuetype.name' 2>/dev/null)"

  echo "${work_type:l}"
}

function proj_print_help_() {
  local proj_cmd="$1"
  local input="$2"

  local sub_cmd=""
  local sub_sub_cmd=""

  # split sub_cmd n two if it contains space
  if [[ "$input" == *" "* ]]; then
    sub_cmd="${input%% *}"
    sub_sub_cmd=" ${input#* }"
  else
    sub_cmd="$input"
  fi
  
  # if [[ -n "$sub_sub_cmd" ]]; then
  #   $proj_cmd -h | grep --color=never -E "\\b${sub_cmd}${sub_sub_cmd}\\b"  
  # else
  # $proj_cmd -h | grep --color=never -E "\\b${sub_cmd}\\b"
  # fi
  # $proj_cmd -h | sed -n "
  # /${proj_cmd} ${sub_cmd}/{
  #   :a
  #   n
  #   /^[[:space:]]\\{2\\}--$/q
  #   p
  #   ba
  # }
  # "
  $proj_cmd -h | sed -n "
    /${proj_cmd} ${sub_cmd}/{
      p
      :a
      n
      /^[[:space:]]\\{2\\}--$/q
      p
      ba
    }
    "
  return 0;
}

function proj_jira_() {
  set +x
  eval "$(parse_flags_ "$0" "" "adcsvrtefx" "$@")"
  (( proj_jira_is_debug )) && set -x

  local proj_cmd="$1"
  local search_key=""
  local jira_status=""

  if (( proj_jira_is_h )); then
    proj_print_help_ "$proj_cmd" "jira"
    return 0;
  fi

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    jira_status="$3"

    if (( ! proj_jira_is_x )); then
      print " fatal: not a valid argument: $jira_status" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi

    # check if jira_status is one of jira statuses
    local jira_statuses="$(get_all_statuses_ $i)"
    if [[ -n "$jira_statuses" ]]; then
      if ! echo "$jira_statuses" | grep -Fxq "$jira_status"; then
        print " fatal: not a valid jira status for you project: $jira_status" >&2
        print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    (( arg_count++ ))
  fi

  shift $arg_count

  if (( proj_jira_is_c || proj_jira_is_a || proj_jira_is_r || proj_jira_is_t || proj_jira_is_d || proj_jira_is_e )) && (( ! proj_jira_is_s )); then
    print " fatal: -a, -c, -d, -e, -r, -t flags must be used with -s flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_jira_is_s && ! proj_jira_is_s_s && ! proj_jira_is_a && ! proj_jira_is_c && ! proj_jira_is_d && ! proj_jira_is_e && ! proj_jira_is_r && ! proj_jira_is_t )); then
    print " fatal: did you mean -ss flag?" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_jira_is_s_s )) && (( proj_jira_is_t || proj_jira_is_r || proj_jira_is_a || proj_jira_is_c || proj_jira_is_d || proj_jira_is_e )); then
    print " fatal: -ss flag cannot be used with -a, -c, -d, -e, -r, -t flags" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -n "$jira_status" ]] && (( ! proj_jira_is_s_s && ! proj_jira_is_a && ! proj_jira_is_c && ! proj_jira_is_d && ! proj_jira_is_e && ! proj_jira_is_r && ! proj_jira_is_t )); then
    print " fatal: status argument can only be used with -ss, -sa, -sc, -sd, -se, -sr, -st flags" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fm $i; then return 1; fi
  if ! check_jira_ -ipwss $i; then return 1; fi

  local label="$(get_label_for_status_ $i "$jira_status" $@)"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"

  if (( proj_jira_is_v_v )); then
    # view all work item status
    if [[ -n "$search_key" ]]; then
      print " fatal: not a valid argument for -v -v: $search_key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local branch_or_folders=("${(f)"$(get_maybe_jira_tickets_ -afj $i "$single_mode" "$proj_folder" "" 2>/dev/null)"}")

    # for each jira_key in jira_keys, view status
    local branch_or_folder=""
    for branch_or_folder in "${branch_or_folders[@]}"; do
      local key="$(extract_jira_key_ "$branch_or_folder")"

      update_status_ -v $i "$key" "" "$branch_or_folder"
    done

    return 0;
  fi

  local jira_key=""

  # resolve jira_key from a branch or folder
  if (( proj_jira_is_v || proj_jira_is_c || proj_jira_is_a || proj_jira_is_e || proj_jira_is_r || proj_jira_is_t || proj_jira_is_s || proj_jira_is_d )); then

    if (( single_mode && ! proj_jira_is_x )); then
      local branch_found=""
      branch_found="$(proj_jira_find_branch_ "$search_key" "$proj_jira_is_e" "$label" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      jira_key="$(extract_jira_key_ "$branch_found")"
      
      if (( proj_jira_is_e )); then
        if [[ -z "$branch_found" || -z "$jira_key" ]]; then return 1; fi

        if check_jira_ -i $i; then
          local jira_base_url="$(gum spin --title="closing work item..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

          if [[ -n "$jira_base_url" ]]; then
            local jira_link="https://${jira_base_url}/browse/${jira_key}"
            print " closing work item... ${blue_cor}$jira_link${reset_cor}"
          else
            print " closing work item... ${blue_cor}$jira_key${reset_cor}"
          fi
        else
          print " closing work item... ${blue_cor}$jira_key${reset_cor}"
        fi

        main "$proj_folder"
        if (( proj_jira_is_f )); then
          delb -f "$branch_found" "$proj_folder"
        else
          delb -e "$branch_found" "$proj_folder"
        fi
        if (( $? == 130 )); then return 130; fi
      fi

    elif (( ! proj_jira_is_x )); then

      local choosen_folder=""
      choosen_folder="$(proj_jira_find_folder_ $i "$search_key" "$proj_jira_is_e" "$label" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi
      
      jira_key="$(extract_jira_key_ "$choosen_folder")"
      
      if (( proj_jira_is_e )); then
        if [[ -z "$choosen_folder" || -z "$jira_key" ]]; then return 1; fi

        if check_jira_ -i $i; then
          local jira_base_url="$(gum spin --title="closing work item..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

          if [[ -n "$jira_base_url" ]]; then
            local jira_link="https://${jira_base_url}/browse/${jira_key}"
            print " closing work item... ${blue_cor}$jira_link${reset_cor}"
          else
            print " closing work item... ${blue_cor}$jira_key${reset_cor}"
          fi
        else
          print " closing work item... ${blue_cor}$jira_key${reset_cor}"
        fi

        print " deleting folder... ${blue_cor}$choosen_folder${reset_cor}"

        local folders="$(find "$proj_folder" -maxdepth 2 -type d -name "$choosen_folder" ! -path "*/.*" -print 2>/dev/null)"

        print " folders found... ${blue_cor}${(@f)folders}${reset_cor}"

        # if (( proj_jira_is_f )); then
        #   del -fx  -- "${(@f)folders}"
        # else
        #   del -- "${(@f)folders}"
        # fi
        if (( $? == 130 )); then return 130; fi
      fi

    elif (( proj_jira_is_x )); then
      jira_key="$search_key"
    fi

    if [[ -z "$jira_key" ]] && (( ! proj_jira_is_c && ! proj_jira_is_e )); then
      local jira_status=""
      local output=""
      output="$(select_jira_key_ $i "$search_key" "$jira_status" "$label" $@)"
      if (( $? == 130 )); then return 130; fi
      IFS=$TAB read -r jira_key jira_status <<< "$output"

      if [[ -z "$jira_key" ]]; then return 1; fi
    fi

    update_status_ $i "$jira_key" "$jira_status" $@

    return $?;
  fi

  # jira -x - open an exact work item

  if (( proj_jira_is_x )); then
    if [[ -z "$search_key" ]]; then
      print " fatal: jira key is required for -x flag" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi
    if ! gum spin --title="opening work item..." --  acli jira workitem view "$search_key" &>/dev/null; then
      print " fatal: not a valid work item: $search_key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi
  else
    local output=""
    output="$(select_jira_key_ -o $i "$search_key" "" "$label")"
    if (( $? == 130 )); then return 130; fi
    IFS=$TAB read -r jira_key _ <<< "$output"
    if [[ -z "$jira_key" ]]; then return 1; fi
  fi

  local jira_base_url="$(gum spin --title="opening work item..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  if [[ -n "$jira_base_url" ]]; then
    local jira_link="https://${jira_base_url}/browse/${jira_key}"
    print " opening work item... ${blue_cor}$jira_link${reset_cor}"
  else
    print " opening work item... ${blue_cor}$jira_key${reset_cor}"
  fi

  if (( single_mode )); then
    if ! is_folder_git_ "$proj_folder" &>/dev/null; then
      if ! proj_clone_ -j "$proj_cmd"; then
        return 1;
      else
        proj_folder="${PUMP_FOLDER[$i]}"
      fi
    fi

    local branch_found="$(select_branch_ -jli "$jira_key" "" "$proj_folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -n "$branch_found" ]]; then
      if ! co -e "$proj_folder" "$branch_found"; then
        return 1;
      fi
    else
      local work_type="$(get_jira_work_type_ $i "$jira_key" 2>/dev/null)"

      if [[ -z "$work_type" ]]; then
        work_type="$(choose_work_type_ $i)"
        if (( $? == 130 )); then return 130; fi
      fi

      local final_branch="$(get_monogram_branch_name_ "$jira_key")"
      if (( $? == 130 )); then return 130; fi

      if [[ -n "$work_type" ]]; then
        final_branch="${work_type}/${final_branch}"
      fi

      if ! co -b "$proj_folder" "$final_branch"; then
        return 1;
      fi
    fi

  else # multiple_mode

    local found_proj_folder="$(find "$proj_folder" \( -path "*/.*" -a ! -name "$jira_key" \) -prune -o -maxdepth 2 -type d -name "$jira_key" -print -quit 2>/dev/null)"

    if [[ -n "$found_proj_folder" ]] && is_folder_git_ "$found_proj_folder" &>/dev/null; then
      cd "$found_proj_folder"
    else
      local work_type="$(get_jira_work_type_ $i "$jira_key" 2>/dev/null)"

      if [[ -z "$work_type" ]]; then
        work_type="$(choose_work_type_ $i)"
        if (( $? == 130 )); then return 130; fi
      fi

      if ! proj_clone_ -j "$proj_cmd" "$jira_key" "" "$work_type"; then
        return 1;
      fi
    fi
  fi

  if (( proj_jira_is_f )); then
    update_status_ -of $i "$jira_key" "$jira_in_progress"
  else
    update_status_ -o $i "$jira_key" "$jira_in_progress"
  fi

  return 0;
}

function check_jira_cli_() {
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

  if ! gum spin --title="checking jira..." -- acli jira auth status >/dev/null 2>&1; then
    print " jira user not authenticated, run: " >&2
    print "  • ${hi_yellow_cor}acli jira auth status${reset_cor} to check" >&2
    print "  • ${hi_yellow_cor}acli jira auth login${reset_cor} to login" >&2
    print "  • or try again later" >&2
    return 1;
  fi
}

function check_jira_() {
  set +x
  eval "$(parse_flags_ "$0" "ipwsadcorte" "" "$@")"
  (( check_jira_is_debug )) && set -x

  local i="$1"

  shift

  if (( check_jira_is_i )); then
    # setopt NO_NOTIFY
    # {
    #   gum spin --title="loading jira..." -- bash -c 'sleep 1'
    # } >&2
    if ! check_jira_cli_; then return 1; fi

    if [[ -z "${PUMP_JIRA_API_TOKEN[$i]}" ]]; then
      local typed_base=""
      typed_base="$(input_type_mandatory_ "type your jira api token" "" 255 "")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$typed_base" ]]; then return 1; fi

      update_config_ -ne $i "PUMP_JIRA_API_TOKEN" "$typed_base" &>/dev/null
      PUMP_JIRA_API_TOKEN[$i]="$typed_base"
    fi
  fi

  if (( check_jira_is_p )); then
    if ! check_jira_proj_ $i "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_SHORT_NAME[$i]}"; then
      return 1;
    fi
  fi

  if (( check_jira_is_w )); then
    if ! check_work_types_ -s $i "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_JIRA_WORK_TYPES[$i]}"; then
      return 1;
    fi
  fi

  if (( check_jira_is_s )); then
    check_jira_statuses_ -s $i "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_JIRA_API_TOKEN[$i]}" "${PUMP_JIRA_STATUSES[$i]}"
    if (( $? == 130 )); then return 130; fi

    local colors=("${bold_yellow_cor}" "${bold_blue_cor}" "${bold_magenta_cor}" "${bold_green_cor}" "${bold_cyan_cor}" "${bold_orange_cor}")
    
    # PUMP_JIRA_TODO
    if (( check_jira_is_d || check_jira_is_s_s )); then
      local jira_todo="$(load_config_entry_ $i "PUMP_JIRA_TODO")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_todo" ]]; then
        jira_todo="$(select_jira_status_ $i "to mark issue ${cor}\"To Do\"${reset_cor}" "To Do")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_todo" ]]; then
        jira_todo="$(input_type_mandatory_ "jira status to mark issue ${cor}\"To Do\"${reset_cor}" "To Do" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_TODO" "$jira_todo" 1>&2
    fi

    # PUMP_JIRA_IN_PROGRESS
    if (( check_jira_is_o || check_jira_is_s_s )); then
      local jira_in_progress="$(load_config_entry_ $i "PUMP_JIRA_IN_PROGRESS")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_in_progress" ]]; then
        jira_in_progress="$(select_jira_status_ $i "to mark issue ${cor}\"In Progress\"${reset_cor}" "In Progress")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_in_progress" ]]; then
        jira_in_progress="$(input_type_mandatory_ "jira status to mark issue ${cor}\"In Progress\"${reset_cor}" "In Progress" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_in_progress" 1>&2
    fi

    # PUMP_JIRA_IN_REVIEW
    if (( check_jira_is_r || check_jira_is_s_s )); then
      local jira_in_review="$(load_config_entry_ $i "PUMP_JIRA_IN_REVIEW")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_in_review" ]]; then
        jira_in_review="$(select_jira_status_ $i "to mark issue ${cor}\"Code Review\"${reset_cor}" "Code Review")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_in_review" ]]; then
        jira_in_review="$(input_type_ "jira status to mark issue ${cor}\"Code Review\"${reset_cor}" "Code Review" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_in_review" 1>&2
    fi

    # PUMP_JIRA_IN_TEST
    if (( check_jira_is_t || check_jira_is_s_s )); then
      local jira_in_test="$(load_config_entry_ $i "PUMP_JIRA_IN_TEST")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_in_test" ]]; then
        jira_in_test="$(select_jira_status_ $i "to mark issue ${cor}\"Ready for Test\"${reset_cor}" "Ready for Test")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_in_test" ]]; then
        jira_in_test="$(input_type_ "jira status to mark issue ${cor}\"Ready for Test\"${reset_cor}" "Ready for Test" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_IN_TEST" "$jira_in_test" 1>&2
    fi

    # PUMP_JIRA_ALMOST_DONE
    if (( check_jira_is_a || check_jira_is_s_s )); then
      local jira_almost_done="$(load_config_entry_ $i "PUMP_JIRA_ALMOST_DONE")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_almost_done" ]]; then
        jira_almost_done="$(select_jira_status_ $i "to mark issue ${cor}\"Ready for Production\"${reset_cor}" "Ready for Production")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_almost_done" ]]; then
        jira_almost_done="$(input_type_ "jira status to mark issue ${cor}\"Ready for Production\"${reset_cor}" "Ready for Production" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_ALMOST_DONE" "$jira_almost_done" 1>&2
    fi

    # PUMP_JIRA_DONE
    if (( check_jira_is_e || check_jira_is_s_s )); then
      local jira_done="$(load_config_entry_ $i "PUMP_JIRA_DONE")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_done" ]]; then
        jira_done="$(select_jira_status_ $i "to mark issue ${cor}\"Done\"${reset_cor}" "Done")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_done" ]]; then
        jira_done="$(input_type_mandatory_ "jira status to mark issue ${cor}\"Done\"${reset_cor}" "Done" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_DONE" "$jira_done" 1>&2
    fi

    # PUMP_JIRA_CANCELED
    if (( check_jira_is_c || check_jira_is_s_s )); then
      local jira_canceled="$(load_config_entry_ $i "PUMP_JIRA_CANCELED")"
      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ -z "$jira_canceled" ]]; then
        jira_canceled="$(select_jira_status_ $i "to mark issue ${cor}\"Canceled\"${reset_cor}" "Canceled")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_canceled" ]]; then
        jira_canceled="$(input_type_mandatory_ "jira status to mark issue ${cor}\"Canceled\"${reset_cor}" "Canceled" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      update_config_ $i "PUMP_JIRA_CANCELED" "$jira_canceled" 1>&2
    fi
    
  fi
}

function find_prs_by_jira_key_() {
  set +x
  eval "$(parse_flags_ "$0" "ocm" "" "$@")"
  (( find_prs_by_jira_key_is_debug )) && set -x

  local jira_key="$1"
  local proj_repo="$2"

  if [[ -z "$jira_key" ]]; then
    print " fatal: jira key is required" >&2
    return 1;
  fi

  if [[ -z "$proj_repo" ]]; then
    proj_repo="$(get_repo_ "$PWD")"
  fi

  local states=()

  if (( find_prs_by_jira_key_is_o )); then states+=('"OPEN"'); fi
  if (( find_prs_by_jira_key_is_m )); then states+=('"MERGED"'); fi
  if (( find_prs_by_jira_key_is_c )); then states+=('"CLOSED"'); fi

  if (( ${#states[@]} == 0 )); then
    states=('"OPEN"' '"MERGED"' '"CLOSED"')
  fi

  local states_in="${(j:,:)states}"

  local jq_filter=".[] | select(.state | IN($states_in))"

  local pr_info="$(gh pr list --repo "$proj_repo" ${flags[@]} --state=all --search "$jira_key in:title" --json=title,number,url,headRefName,state | jq -r "$jq_filter" | jq -r '"\(.title)\t#\(.number)\t\(.headRefName)\t\(.url)"' 2>/dev/null)"

  local pr_title=()
  local pr_number=()
  local pr_links=()
  local pr_branch=()

  # split each line into arrays
  while IFS=$'\t' read -r title number branch url; do
    pr_title+=("$title")
    pr_number+=("$number")
    pr_branch+=("$branch")
    pr_links+=("$url")
  done <<< "$pr_info"

  # echo all of this
  local idx=1
  local pr_count="${#pr_links[@]}"

  while (( idx <= pr_count )); do
    print -r -- "${pr_number[$idx]}${TAB}${pr_links[$idx]}${TAB}${pr_title[$idx]}${TAB}${pr_branch[$idx]}"
    (( idx++ ))
  done
}

function get_label_for_status_() {
  set +x
  eval "$(parse_flags_ "$0" "adcsvrteS" "" "$@")"
  (( get_label_for_status_is_debug )) && set -x

  local i="$1"
  local jira_status="$2"

  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"

  local colors=("${bold_yellow_cor}" "${bold_blue_cor}" "${bold_magenta_cor}" "${bold_green_cor}" "${bold_cyan_cor}" "${bold_orange_cor}")
  local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

  local flag=""
  local label="to transition to ${cor}\"$jira_in_progress\"${reset_cor}"

  if (( get_label_for_status_is_c )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_canceled"; fi
    label="to transition to ${bold_red_cor}\"$jira_status\"${reset_cor}"

  elif (( get_label_for_status_is_s_s )); then
    if [[ -z "$jira_status" ]]; then
      jira_status="$(select_jira_status_ $i "to transition to")"
      # if (( $? == 130 )); then return 130; users to define when cancelling options
      if [[ -z "$jira_status" ]]; then
        jira_status="$(input_type_ "enter status to transition to, as seen in jira" "" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      if [[ -z "$jira_status" ]]; then return 1; fi
    fi

    label="to transition to ${cor}\"$jira_status\"${reset_cor}"

  elif (( get_label_for_status_is_d )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_todo"; fi
    label="to transition to ${cor}\"$jira_status\"${reset_cor}"
  
  elif (( get_label_for_status_is_e )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_done"; fi
    label="to transition to ${cor}\"$jira_status\"${reset_cor}"
  
  elif (( get_label_for_status_is_r )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_in_review"; fi
    label="to transition to ${cor}\"$jira_status\"${reset_cor}"

  elif (( get_label_for_status_is_t )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_in_test"; fi
    label="to transition to ${cor}\"$jira_status\"${reset_cor}"

  elif (( get_label_for_status_is_a )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_almost_done"; fi
    label="to transition to ${cor}\"$jira_status\"${reset_cor}"
  
  elif (( get_label_for_status_is_v )); then
    jira_status=""
    label="to ${cor}view${reset_cor}"
  fi

  if (( get_label_for_status_is_S )); then
    echo "$jira_status"
  else
    echo "$label"
  fi
}

function proj_jira_release_() {
  set +x
  eval "$(parse_flags_ "$0" "" "adcsvrtfex" "$@")"
  (( proj_jira_release_is_debug )) && set -x

  local proj_cmd="$1"
  local search_key=""
  local jira_status=""

  if (( proj_jira_release_is_h )); then
    proj_print_help_ "$proj_cmd" "jira release"
    return 0;
  fi

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    jira_status="$3"
    (( arg_count++ ))
  fi

  shift $arg_count

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if (( proj_jira_release_is_c || proj_jira_release_is_a || proj_jira_release_is_r || proj_jira_release_is_t || proj_jira_release_is_d )) && (( ! proj_jira_release_is_s )); then
    print " fatal: -a, -c, -r, -t flags must be used with -s flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_jira_release_is_s && ! proj_jira_release_is_s_s && ! proj_jira_release_is_t && ! proj_jira_release_is_r && ! proj_jira_release_is_a && ! proj_jira_release_is_c && ! proj_jira_release_is_d )); then
    print " fatal: did you mean -ss flag?" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( proj_jira_release_is_s_s )) && (( proj_jira_release_is_t || proj_jira_release_is_r || proj_jira_release_is_a || proj_jira_release_is_c || proj_jira_release_is_d )); then
    print " fatal: -ss flag cannot be used with -a, -c, -r, -t flags" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -frm $i; then return 1; fi
  if ! check_jira_ -ipwss $i; then return 1; fi

  local label="$(get_label_for_status_ $i "$jira_status" $@)"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  if (( proj_jira_release_is_v_v )); then
    # view all work item in a release
    if [[ -n "$search_key" ]]; then
      print " fatal: not a valid argument: $search_key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local jira_release=""
    jira_release="$(select_proj_release_ $i "$jira_proj" "$jira_api_token")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$jira_release" ]]; then return 1; fi

    print " ${purple_cor}release:${reset_cor} $jira_release"

    local tickets="$(filter_jira_keys_by_release_ $i "$jira_proj" "$jira_release" "$search_key" "$jira_status" $@)"
    local tickets=("${(@f)tickets}")

    local ticket=""
    for ticket in "${tickets[@]}"; do
      local key="$(echo $ticket | awk '{print $1}')"

      update_status_ -v $i "$key"
    done

    print ""

    if ! check_proj_ -g $i; then return 1; fi

    local pr_approval_min="${PUMP_PR_APPROVAL_MIN[$i]}"

    local is_any_pr_found=0

    for ticket in "${tickets[@]}"; do
      local key="$(echo $ticket | awk '{print $1}')"

      local output="$(find_prs_by_jira_key_ -o "$key" "$proj_repo" 2>/dev/null)"
      local prs=("${(@f)output}")
      
      if [[ -z "$prs" ]]; then
        continue;
      fi

      local line=""
      for line in "${prs[@]}"; do
        local pr_number=""
        local pr_link=""
        IFS=$TAB read -r pr_number pr_link _ <<<"$line"

        local approval_count=$(gh pr view "$pr_number" --repo "$proj_repo" --json reviews \
          | jq '.reviews
          | reverse
          | unique_by(.author.login)
          | map(select(.state == "APPROVED" and (.dismissed == false or .dismissed == null)))
          | length' 2>/dev/null
        )

        if (( approval_count < pr_approval_min )); then
          if (( is_any_pr_found == 0 )); then
            print " remaining prs to be approved for \"$jira_release\""
          fi
          printf "- %s\n" "${pr_link}"
          is_any_pr_found=1
        fi
      done
    done

    if (( is_any_pr_found == 0 )); then
      print " all pull requests are approved or merged for \"$jira_release\""
    fi

    return 0;
  fi

  local jira_status=""
  local jira_key=""
  local output=""
  output="$(select_jira_key_by_release_ $i "$search_key" "$jira_status" "$label" $@)"
  if (( $? == 130 )); then return 130; fi
  IFS=$TAB read -r jira_key jira_status <<< "$output"

  if [[ -z "$jira_key" ]]; then return 1; fi

  proj_jira_ -x ${flags[@]} "$proj_cmd" "$jira_key" "$jira_status"
}

function select_jira_key_by_release_() {
  set +x
  eval "$(parse_flags_ "$0" "p" "adcsrtvey" "$@")"
  (( select_jira_key_by_release_is_debug )) && set -x

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  local i="$1"
  local search_key=""
  local status_filter=""
  local label=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    status_filter="$3"
    (( arg_count++ ))
  fi

  if [[ -n "$4" && $4 != -* ]]; then
    label="$4"
    (( arg_count++ ))
  fi

  shift $arg_count

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  local jira_release=""
  jira_release="$(select_proj_release_ $i "$jira_proj" "$jira_api_token")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$jira_release" ]]; then return 1; fi

  local tickets="$(filter_jira_keys_by_release_ -n $i "$jira_proj" "$jira_release" "$search_key" "$status_filter" $@)"

  local ticket=""
  if (( $(echo "$tickets" | wc -l) > 25 )); then
    ticket="$(filter_one_ "work item $label" "${(@f)tickets}")"
  elif [[ -n "$tickets" ]]; then
    ticket="$(choose_one_ "work item $label" "${(@f)tickets}")"
  fi
  if (( $? == 130 )); then return 130; fi

  local jira_key=""

  if [[ -z "$ticket" ]]; then
    if [[ -n "$search_key" ]]; then
      local output=""
      output="$(select_jira_key_by_release_ $i "" "$status_filter" "$label" $@)"
      if (( $? == 130 )); then return 130; fi
      IFS=$TAB read -r jira_key _ <<< "$output"
    else
      print " no work item found in jira release: ${cyan_cor}$jira_release${reset_cor}" >&2
    fi
    return 1;
  fi

  if [[ -z "$jira_key" ]]; then
    jira_key="$(echo $ticket | awk '{print $1}')"
  fi

  jira_key="$(trim_ "$jira_key")"

  echo "${jira_key}${TAB}${status_filter}"
}

function filter_jira_keys_by_release_() {
  set +x
  eval "$(parse_flags_ "$0" "" "nadcsvrtfexy" "$@")"
  (( filter_jira_keys_by_release_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local jira_release="$3"
  local search_key="$4"
  local status_filter="$5"

  local jira_todo="${PUMP_JIRA_TODO[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"

  local query_status="status!=\"$jira_canceled\""

  if (( filter_jira_keys_by_release_is_d )); then
    query_status+=" AND status!=\"$jira_todo\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"$jira_done\""
    fi

  elif (( filter_jira_keys_by_release_is_c )); then
    query_status+=" AND status!=\"$jira_done\""

  elif (( filter_jira_keys_by_release_is_e )); then
    query_status+=" AND status!=\"$jira_done\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"${jira_todo}\""
    fi

  elif (( filter_jira_keys_by_release_is_r )); then
    query_status+=" AND status!=\"$jira_in_review\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"${jira_todo}\""
      query_status+=" AND status!=\"$jira_done\""
    fi

  elif (( filter_jira_keys_by_release_is_t )); then
    query_status+=" AND status!=\"$jira_in_test\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"${jira_todo}\""
      query_status+=" AND status!=\"$jira_done\""
    fi

  elif (( filter_jira_keys_by_release_is_a )); then

    query_status+=" AND status!=\"$jira_almost_done\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"${jira_todo}\""
      query_status+=" AND status!=\"$jira_done\""
    fi

  elif (( filter_jira_keys_by_release_is_e )); then
    query_status+=" AND status!=\"${jira_todo}\""
    query_status+=" AND status!=\"$jira_done\""

  elif (( filter_jira_keys_by_release_is_s )); then
    query_status+=" AND status!=\"${status_filter}\""
    query_status+=" AND status!=\"$jira_done\""

  elif (( filter_jira_keys_by_release_is_y )); then
    query_status+=" AND status!=\"${jira_todo}\""
    query_status+=" AND status!=\"${jira_almost_done}\""
    query_status+=" AND status!=\"${jira_done}\""

  fi

  local jira_search="$([[ -n "$search_key" ]] && echo "AND key ~ \"*$search_key*\"" || echo "")"

  local tickets=$(gum spin --title="pulling work items..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND fixVersion = \"$jira_release\" AND $query_status ORDER BY priority DESC" \
      --fields="key,summary,status,assignee" \
      --limit 1000 \
      --json | jq -r '
        .[]
        | [
            .key,
            (.fields.status.name // empty),
            (.fields.assignee.displayName // "Unassigned"),
            (
              if (.fields.summary | length) > 60
              then .fields.summary[0:60] + "…"
              else .fields.summary
              end
            )
          ]
        | @tsv
      ' | column -t -s $'\t' 2>/dev/null
    )

  echo "${tickets}"
}

function choose_work_type_() {
  local i="$1"
  local branch="$2"

  branch="${branch:l}"

  local branches_excluded=("main" "master" "dev" "develop" "stage" "staging" "prod" "production")

  if [[ " ${branches_excluded[*]} " == *" $branch "* ]]; then
    return 0;
  fi

  if [[ "$branch" == release/* ]]; then
    echo "release"
    return 0;
  fi

  local work_types=($(check_work_types_ $i))
  local wt=""

  if [[ -n "$branch" ]]; then
    for wt in "${work_types[@]}"; do
      if [[ "$branch" == "${wt:l}/"* ]]; then
        echo "${wt:l}"
        return 0;
      fi
    done
  fi

  if [[ -n "$branch" ]]; then
    for wt in "${work_types[@]}"; do
      if [[ "$branch" == "${wt:l}"* ]]; then
        if [[ "$wt" == "bug" && "$branch" == *"/"* && "$branch" == bug*/* ]]; then
          echo "${branch%%/*}"
          return 0;
        fi
        echo "${wt:l}"
        return 0;
      fi
    done
  fi

  if [[ -n "$branch" ]]; then
    for wt in "${work_types[@]}"; do
      if [[ "$branch" == *"${wt:l}"* ]]; then
        echo "$wt"
        return 0;
      fi
    done
  fi

  work_types+=("none")

  local work_type=""
  work_type="$(choose_one_ -i "type of work" "${work_types[@]}")"
  if (( $? == 130 )); then return 130; fi

  if [[ "${work_type:l}" == "none" ]]; then
    return 1;
  fi
  
  echo "${work_type:l}"
}

function select_pr_by_jira_key_() {
  set +x
  eval "$(parse_flags_ "$0" "" "ocm" "$@")"
  (( select_pr_by_jira_key_is_debug )) && set -x

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  local jira_key="$1"
  local proj_repo=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    proj_repo="$2"
    (( arg_count++ ))
  fi

  shift $arg_count
  
  local branch=""

  local output="$(find_prs_by_jira_key_ "$jira_key" "$proj_repo" $@ 2>/dev/null)"
  local prs=("${(@f)output}")

  if [[ -z "$prs" ]]; then
    print " no pull requests found for jira key: $jira_key" >&2
    return 1;
  fi

  # let user choose
  local pr_choices=()
  local pr_map=()
  
  local pr=""
  for pr in "${prs[@]}"; do
    local pr_number=""
    local pr_link=""
    local pr_title=""
    local pr_branch=""
    IFS=$TAB read -r pr_number pr_link pr_title pr_branch <<<"$pr"
    pr_choices+=("$pr_title")
    pr_map+=("${pr_title}${TAB}${pr_number}${TAB}${pr_link}${TAB}${pr_branch}")
  done

  if [[ -z "$pr_choices" ]]; then
    print " no pull requests found for jira key: $jira_key" >&2
    return 1;
  fi
  
  local select_pr_title=""
  select_pr_title="$(choose_one_ -i "pull request to review for $jira_key" "${pr_choices[@]}")"
  if (( $? == 130 )); then return 130; fi
  
  if [[ -z "$select_pr_title" ]]; then return 1; fi
  
  read pr_number pr_link pr_branch <<<"$(printf "%s\n" "${pr_map[@]}" | awk -F$TAB -v title="$select_pr_title" '$1 == title {print $2, $3, $4}')"
  
  if [[ -n "$pr_number" && -n "$pr_link" && -n "$pr_branch" ]]; then
    branch="$pr_branch"
  fi

  echo "$branch"
}

function get_jira_status_() {
  local jira_key="$1"

  gum spin --title=" jira status... $jira_key" -- acli jira workitem view "$jira_key" --fields=issuetype,status,assignee,summary --json | jq -r --arg sep "$TAB" '
    [
      (.fields.status.name // empty),
      (.fields.issuetype.name // empty | ascii_downcase),
      (.fields.assignee.emailAddress // "Unassigned"),
      (.fields.assignee.displayName // "Unassigned"),
      (.fields.summary // empty)
    ] | join($sep)
  '
}

function update_status_() {
  set +x
  eval "$(parse_flags_ "$0" "adcsvrtefxo" "" "$@")"
  (( update_status_is_debug )) && set -x

  local i="$1"
  local jira_key=""
  local jira_status=""
  local folder=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    jira_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    jira_status="$3"
    (( arg_count++ ))
  fi

  if [[ -n "$4" && $4 != -* ]]; then
    folder="$4"
    (( arg_count++ ))
  fi

  shift $arg_count

  if [[ -z "$i" || -z "$jira_key" ]]; then return 1; fi

  # $i could be zero 0
  local output="$(get_jira_status_ "$jira_key")"

  if [[ -z "$output" ]] then
    if ! check_jira_cli_; then return 1; fi

    print " fatal: cannot retrieve work item status for: $jira_key" >&2
    print " $output" >&2
    return 1;
  fi

  local current_status work_type current_jira_assignee assignee summary
  IFS=$TAB read -r current_status work_type current_jira_assignee assignee summary <<<"$output"

  if (( update_status_is_v )); then
    if ! check_proj_ -fm $i; then return 1; fi

    local proj_folder="${PUMP_FOLDER[$i]}"
    local single_mode="${PUMP_SINGLE_MODE[$i]}"

    # if check_jira_ -ss $i; then return 1; fi

    # local jira_statuses="$(get_all_statuses_ $i)"
    # local jira_statuses=("${(@f)jira_statuses}")
    # if [[ -z "$jira_statuses" ]]; then return 1; fi

    # # create a map of status -> color using array
    # typeset -A status_color_map
    # local idx=1
    # local colors=("${bold_yellow_cor}" "${bold_blue_cor}" "${bold_magenta_cor}" "${bold_green_cor}" "${bold_cyan_cor}" "${bold_orange_cor}")
    
    # local statuss=""
    # for statuss in "${jira_statuses[@]}"; do
    #   if (( idx <= ${#colors[@]} )); then
    #     status_color_map[${statuss:u}]="${colors[$idx]}"
    #     (( idx++ ))
    #   fi
    # done

    # # default color for unmatched statuses
    # local cor="${status_color_map[${current_status:u}]:-${red_cor}}"

    local colors=("${bold_yellow_cor}" "${bold_blue_cor}" "${bold_magenta_cor}" "${bold_green_cor}" "${bold_cyan_cor}" "${bold_orange_cor}")
    local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
    
    print " ${cyan_cor}ticket: ${reset_cor}$jira_key"
    print " ${cyan_cor} title: ${reset_cor}$summary"
    print " ${cyan_cor}  type: ${reset_cor}$work_type"
    print " ${cyan_cor}assign: ${reset_cor}$assignee"
    print " ${cyan_cor}aemail: ${reset_cor}$current_jira_assignee"
    print " ${cyan_cor}status: ${cor}$current_status${reset_cor}"
    
    if [[ -n "$folder" ]]; then
      print " ${cyan_cor}folder: ${reset_cor}${folder}"
    else
      if (( single_mode )); then
        print " ${cyan_cor}folder: ${reset_cor}${proj_folder}"
      else
        local folders="$(find "$proj_folder" -maxdepth 2 -type d -name "$jira_key" ! -path "*/.*" -print 2>/dev/null)"
        local found_proj_folder=("${(@f)folders}")

        for folder in "${found_proj_folder[@]}"; do
          if [[ -n "$folder" ]]; then
            print " ${cyan_cor}folder: ${reset_cor}${folder}"
          fi
        done
      fi
    fi

    local proj_repo="${PUMP_REPO[$i]}"

    local output_lines="$(find_prs_by_jira_key_ -omc "$jira_key" "$proj_repo" 2>/dev/null)"
    local output_lines=("${(@f)output_lines}")

    if [[ -z "$prs" ]]; then
      print "  --"
      return 0;
    fi
    
    local line=""
    for line in "${output_lines[@]}"; do
      local pr_number=""
      local pr_link=""
      IFS=$TAB read -r pr_number pr_link _ <<<"$line"
      
      if [[ -n "$pr_link" ]]; then
        print " ${cyan_cor}pull r: ${blue_cor}$pr_link${reset_cor}"
      fi
    done

    print "  --"
    return 0;
  fi # if (( update_status_is_v )); then

  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"

  local is_assigned=1

  local current_user="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"

  if (( update_status_is_o || update_status_is_r )); then
    if [[ "$current_jira_assignee" != "$current_user" ]]; then
      local output=""
      if [[ -n "$current_jira_assignee" ]]; then
        local RET=0
        if (( ! update_status_is_f )); then
          confirm_ "work item ${jira_key} is assigned to ${yellow_cor}$current_jira_assignee${reset_cor} - re-assign it to you?"
          RET=$?
        fi
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 0 )); then
          output=$(gum spin --title="re-assigning work item..." -- acli jira workitem assign --key="$jira_key" --assignee="@me" --yes)
        else
          is_assigned=0
        fi
      else
        output=$(gum spin --title="assigning work item..." -- acli jira workitem assign --key="$jira_key" --assignee="@me" --yes)
      fi
      print " $output" | grep -w "$jira_key" >&2
    fi
  fi

  if [[ "${current_status:u}" == "${jira_status:u}" ]]; then
    print " work item $jira_key is already in status: $current_status"
    return 0;
  fi

  if (( update_status_is_e )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_CANCELED[0]:u}" || "${current_status:u}" == "${jira_canceled:u}" ]]; then
      print " work item $jira_key cannot be closed because it's canceled" >&2
      return 1;
    fi
  elif (( update_status_is_r )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_IN_REVIEW[0]:u}" || "${current_status:u}" == "IN REVIEW" || "${current_status:u}" == "CODE REVIEW" ]]; then
      print " work item $jira_key is already in status: $current_status"
      return 0;
    fi
  elif (( update_status_is_t )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_IN_TEST[0]:u}" || "${current_status:u}" == "IN TEST" || "${current_status:u}" == "IN TESTING" || "${current_status:u}" == "READY FOR TEST" || "${current_status:u}" == "IN QA" ]]; then
      print " work item $jira_key is already in status: $current_status"
      return 0;
    fi
  elif (( update_status_is_a )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_ALMOST_DONE[0]:u}" || "${current_status:u}" == "READY FOR PRODUCTION" || "${current_status:u}" == "READY TO DEPLOY" || "${current_status:u}" == "PRODUCT REVIEW" ]]; then
      print " work item $jira_key is already in status: $current_status"
      return 0;
    fi
  elif (( update_status_is_o )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_IN_PROGRESS[0]:u}" || "${current_status:u}" == "OPEN" || "${current_status:u}" == "IN PROGRESS" ]]; then
      print " work item $jira_key is already in status: $current_status"
      return 0;
    fi
  elif (( update_status_is_c )); then
    if [[ "${current_status:u}" == "${PUMP_JIRA_CANCELED[0]:u}" || "${current_status:u}" == "CANCELED" ]]; then
      print " work item $jira_key is already in status: $current_status"
      return 0;
    fi
  fi

  if [[ -n "$current_jira_assignee" && "$current_jira_assignee" != "$current_user" ]]; then
    if [[ "${current_status:u}" == "${jira_done:u}" || "${current_status:u}" == "${jira_canceled:u}" ]]; then
      print " work item $jira_key cannot transition a closed or canceled work item assigned to $current_jira_assignee" >&2
      return 1;
    fi
  fi

  if (( ! is_assigned )); then
    local RET=0
    if (( ! update_status_is_f )); then
      confirm_ "transition of work item ${jira_key} (assigned to $current_jira_assignee) to status: ${cyan_cor}${jira_status}${reset_cor}?"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then return 1; fi
  else
    # confirmation before changing status
    if (( ! update_status_is_f )); then
      if (( update_status_is_e )); then
        if ! confirm_ "close work item: ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      elif (( update_status_is_o )); then
        if [[ "${current_status:u}" == "${jira_todo:u}" ]]; then
          if ! confirm_ "move work item to \"${jira_in_progress}\": ${pink_cor}$jira_key${reset_cor}?"; then
            return 1;
          fi
        else
          if ! confirm_ "work item in \"${current_status}\", move to \"${jira_in_progress}\": ${pink_cor}$jira_key${reset_cor}?"; then
            return 1;
          fi
        fi
      elif (( update_status_is_d )); then    
        if ! confirm_ "work item in \"${current_status}\", move to \"${jira_todo}\": ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      
      elif (( update_status_is_r )); then    
        if ! confirm_ "work item in \"${current_status}\", move to \"${jira_in_review}\": ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      
      elif (( update_status_is_t )); then    
        if ! confirm_ "work item in \"${current_status}\", move to \"${jira_in_test}\": ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      
      elif (( update_status_is_a )); then    
        if ! confirm_ "work item in \"${current_status}\", move to \"${jira_almost_done}\": ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      elif (( update_status_is_c )); then
        if ! confirm_ "cancel work item in \"${current_status}\": ${pink_cor}$jira_key${reset_cor}?"; then
          return 1;
        fi
      fi
    fi
  fi

  local output=""
  output=$(gum spin --title="transitioning work item..." -- acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)

  if echo "$output" | grep -qiE "failure" && ! echo "$output" | grep -qiE "story points is required"; then
    jira_status="$(input_type_ "enter correct status for \"$jira_status\", as seen in jira" "$jira_status" 40)"
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$jira_status" ]] && ; then
      output=$(gum spin --title="transitioning work item..." -- acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)
      if echo "$output" | grep -qiE "failure"; then
        print " work item $jira_key cannot be transitioned to status $jira_status" >&2
        print " $output" | grep -w "$jira_key" >&2
        return 1;
      fi
    fi
  fi

  print " $output" | grep -w "$jira_key"

  if (( update_status_is_d )) && [[ "${jira_status:u}" != "${jira_todo:u}" ]]; then
    update_config_ $i "PUMP_JIRA_TODO" "$jira_status"

  elif (( update_status_is_o )) && [[ "${jira_status:u}" != "${jira_in_progress:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_status"

  elif (( update_status_is_r )) && [[ "${jira_status:u}" != "${jira_in_review:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_status"

  elif (( update_status_is_t )) && [[ "${jira_status:u}" != "${jira_in_test:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_TEST" "$jira_status"

  elif (( update_status_is_a )) && [[ "${jira_status:u}" != "${jira_almost_done:u}" ]]; then
    update_config_ $i "PUMP_JIRA_ALMOST_DONE" "$jira_status"

  elif (( update_status_is_e )) && [[ "${jira_status:u}" != "${jira_done:u}" ]]; then
    update_config_ $i "PUMP_JIRA_DONE" "$jira_status"

  elif (( update_status_is_c )) && [[ "${jira_status:u}" != "${jira_canceled:u}" ]]; then
    update_config_ $i "PUMP_JIRA_CANCELED" "$jira_status"

  fi
}

function select_jira_key_() {
  set +x
  eval "$(parse_flags_ "$0" "" "oadcsvrtfexyQ" "$@")"
  (( select_jira_key_is_debug )) && set -x

  local i="$1"
  local search_key=""
  local status_filter=""
  local label=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    status_filter="$3"
    (( arg_count++ ))
  fi

  if [[ -n "$4" && $4 != -* ]]; then
    label="$4"
    (( arg_count++ ))
  fi

  shift $arg_count

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  if (( select_jira_key_is_q )); then
    if ! check_jira_ -ipsedc $i; then return 1; fi
  fi

  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"

  local query_status="status!=\"$jira_canceled\" AND status!=\"$jira_done\""

  if (( select_jira_key_is_a )); then
    query_status+=" AND status!=\"$jira_almost_done\" AND status!=\"${jira_todo}\""

  elif (( select_jira_key_is_r )); then
    query_status+=" AND status!=\"$jira_in_review\" AND status!=\"${jira_todo}\""

  elif (( select_jira_key_is_t )); then
    query_status+=" AND status!=\"$jira_in_test\" AND status!=\"${jira_todo}\""

  elif (( select_jira_key_is_s )); then
    query_status+=" AND status!=\"$status_filter\""

  elif (( select_jira_key_is_y )); then
    query_status+=" AND status!=\"${jira_todo}\""
  fi

  local jira_search="$([[ -n "$search_key" ]] && echo "AND key ~ \"*$search_key*\"" || echo "")"

  local tickets=""

  if (( select_jira_key_is_o )); then
    # search for work items assigned to current user or not assigned and in "To Do" status
    tickets=$(gum spin --title="pulling work items..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND $query_status AND (assignee=currentUser() OR (assignee IS EMPTY AND status=\"${jira_todo}\")) AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
      --fields="key,summary,status,assignee" \
      --limit 1000 \
      --json | jq -r '
        .[]
        | [
            .key,
            (.fields.status.name // empty),
            (.fields.assignee.displayName // "Unassigned"),
            (
              if (.fields.summary | length) > 60
              then .fields.summary[0:60] + "…"
              else .fields.summary
              end
            )
          ]
        | @tsv
      ' | column -t -s $'\t' 2>/dev/null
    )

  elif (( select_jira_key_is_c || select_jira_key_is_s )); then
    # search for work items not assigned to current user
    tickets=$(gum spin --title="pulling work items..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND assignee=currentUser() AND $query_status AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
      --fields="key,summary,status,assignee" \
      --limit 1000 \
      --json | jq -r '
        .[]
        | [
            .key,
            (.fields.status.name // empty),
            (.fields.assignee.displayName // "Unassigned"),
            (
              if (.fields.summary | length) > 60
              then .fields.summary[0:60] + "…"
              else .fields.summary
              end
            )
          ]
        | @tsv
      ' | column -t -s $'\t' 2>/dev/null
    )

  elif (( select_jira_key_is_y )); then
    # opening a rev
    # search for work items not assigned to current user
    tickets=$(gum spin --title="pulling work items..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND assignee!=currentUser() AND $query_status AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
      --fields="key,summary,status,assignee" \
      --limit 1000 \
      --json | jq -r '
        .[]
        | [
            .key,
            (.fields.status.name // empty),
            (.fields.assignee.displayName // "Unassigned"),
            (
              if (.fields.summary | length) > 60
              then .fields.summary[0:60] + "…"
              else .fields.summary
              end
            )
          ]
        | @tsv
      ' | column -t -s $'\t' 2>/dev/null
    )
  else
    # search for all work items in the project
    tickets=$(gum spin --title="pulling work items..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND $query_status AND Sprint IS NOT EMPTY ORDER BY priority DESC" \
      --fields="key,summary,status,assignee" \
      --limit 1000 \
      --json | jq -r '
        .[]
        | [
            .key,
            (.fields.status.name // empty),
            (.fields.assignee.displayName // "Unassigned"),
            (
              if (.fields.summary | length) > 60
              then .fields.summary[0:60] + "…"
              else .fields.summary
              end
            )
          ]
        | @tsv
      ' | column -t -s $'\t' 2>/dev/null
    )
  fi

  local ticket=""
  ticket="$(choose_one_ -i "work item $label" "${(@f)$(printf "%s\n" "$tickets")}")"
  if (( $? == 130 )); then return 130; fi

  local jira_key=""

  if [[ -z "$ticket" ]]; then
    if [[ -n "$search_key" ]]; then
      local output=""
      output="$(select_jira_key_ $i "" "$status_filter" "$label" $@)"
      if (( $? == 130 )); then return 130; fi
      IFS=$TAB read -r jira_key _ <<< "$output"
    else
      print " no work item found in jira project: ${cyan_cor}$jira_proj${reset_cor}" >&2
    fi

    return 1;
  fi

  if [[ -z "$jira_key" ]]; then
    jira_key="$(echo $ticket | awk '{print $1}')"
  fi

  jira_key="$(trim_ "$jira_key")"

  echo "${jira_key}${TAB}${status_filter}"
}

function get_branch_name_with_monogram_() {
  local branch_name="$1"
  local monogram="$2"

  local branch_name_monogram=""

  if [[ "$branch_name" == */*/* ]]; then
    local prefix="${branch_name%/*}"
    local last="${branch_name##*/}"

    branch_name_monogram="${prefix}/${monogram}-${last}"
  
  elif [[ "$branch_name" == */* ]]; then
    local prefix="${branch_name%%/*}"
    local suffix="${branch_name#*/}"

    branch_name_monogram="${prefix}/${monogram}-${suffix}"
  
  else
    branch_name_monogram="${monogram}-${branch_name}"
  fi

  echo "$branch_name_monogram"
}

function get_monogram_branch_name_() {
  local branch_name="$1"

  local branch_name_monogram=""

  if [[ -n "$PUMP_USE_MONOGRAM" ]]; then
    branch_name_monogram="$(get_branch_name_with_monogram_ "$branch_name" "$PUMP_USE_MONOGRAM")"
    echo "$branch_name_monogram"
    return 0;
  fi

  local initials="${USER:0:1}"

  while true; do
    branch_name_monogram="$(get_branch_name_with_monogram_ "$branch_name" "$initials")"

    confirm_ "use branch name with initials: ${cyan_cor}$branch_name_monogram${reset_cor} ?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_USE_MONOGRAM" "$initials" &>/dev/null
      echo "$branch_name_monogram"
      return 0;
    fi

    initials="$(input_type_mandatory_ -m "enter initials to use in branch name" "" 2 "${USER:0:1}")"
    if [[ -z "$initials" ]]; then
      echo "$branch_name"
      return 1;
    fi
  done

  echo "$branch_name_monogram"
}

function is_folder_in_revs_() {
  local folder="${1:-$PWD}"

  local abs_folder="$(cd "$folder" 2>/dev/null && pwd -P)"
  if [[ -z "$abs_folder" ]]; then
    print " fatal: cannot determine absolute path of folder: $folder" >&2
    return 1;
  fi

  if [[ "$abs_folder" == */.revs/* ]]; then
    return 0;
  fi

  return 1;
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
      print " run: ${hi_yellow_cor}abort -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local operation="$(get_current_git_operation_ "$folder")"

  if [[ "$operation" == "rebase" ]]; then
    if ! GIT_EDITOR=true git -C "$folder" rebase --abort $@ &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      GIT_EDITOR=true git -C "$folder" rebase --abort $@ &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "merge" ]]; then
    if ! GIT_EDITOR=true git -C "$folder" merge --abort $@ &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      GIT_EDITOR=true git -C "$folder" merge --abort $@ &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "revert" ]]; then
    if ! GIT_EDITOR=true git -C "$folder" revert --abort $@ &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      GIT_EDITOR=true git -C "$folder" revert --abort $@ &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "cherry-pick" ]]; then
    if ! GIT_EDITOR=true git -C "$folder" cherry-pick --abort $@ &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      GIT_EDITOR=true git -C "$folder" cherry-pick --abort $@ &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "am" ]]; then
    if ! GIT_EDITOR=true git -C "$folder" am --abort $@ &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      GIT_EDITOR=true git -C "$folder" am --abort $@ &>/dev/null
    fi

    return $?;
  fi

  return 1;
}

function get_current_git_operation_() {
  local folder="${1:-$PWD}"

  local git_dir=$(git -C "$folder" rev-parse --git-dir 2>/dev/null)
  
  if (( $? )); then
    print " fatal: not a git repository" >&2
    return 1;
  fi

  if [[ -f "$git_dir/MERGE_HEAD" ]]; then
    echo "merge"
    return 0;
  fi

  if [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
    echo "cherry-pick"
    return 0;
  fi

  if [[ -f "$git_dir/REVERT_HEAD" ]]; then
    echo "revert"
    return 0;
  fi

  if [[ -d "$git_dir/rebase-apply" && -f "$git_dir/rebase-apply/applying" ]]; then
    echo "am"
    return 0;
  fi

  if [[ -d "$git_dir/rebase-apply" || -d "$git_dir/rebase-merge" ]]; then
    echo "rebase"
    return 0;
  fi

  echo "none"
}

function renb() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( renb_is_debug )) && set -x

  if (( renb_is_h )); then
    print "  ${hi_yellow_cor}renb ${yellow_cor}[<new_branch_name>] [<folder>]${reset_cor} : rename current branch"
    print "  --"
    print "  ${hi_yellow_cor}renb -f${reset_cor} : skip confirmation"
    return 0;
  fi

  local new_branch=""
  local folder="$PWD"

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      (( arg_count++ ))
      if [[ -n "$1" && $1 != -* ]]; then
        new_branch="$1"
        (( arg_count++ ))
      fi
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}renb -h${reset_cor} to see usage" >&2
      return 1;
    fi
  elif [[ -n "$1" && $1 != -* ]]; then
    new_branch="$1"
    (( arg_count++ ))
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  if [[ -z "$new_branch" ]]; then
    new_branch="$(input_branch_name_ "enter new branch name")"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$new_branch" ]]; then
      print " fatal: not a valid branch argument" >&2
      print " run: ${hi_yellow_cor}renb -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if ! is_branch_name_valid_ "$new_branch"; then
    return 1;
  fi

  if [[ "$my_branch" == "$new_branch" ]]; then
    print " fatal: new branch name is the same as current branch name: $my_branch" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  if ! git -C "$folder" branch -m $new_branch $@; then
    return 1;
  fi

  local new_remote_branch="$(get_remote_branch_ "$new_branch" "$folder")"
  local my_remote_branch="$(get_remote_branch_ "$my_branch" "$folder")"

  local remote_name="$(get_remote_name_ "$folder")"
  
  git -C "$folder" branch --unset-upstream --quiet &>/dev/null

  if [[ -z "$new_remote_branch" && -n "$my_remote_branch" ]]; then
    if (( ! renb_is_f )); then
      confirm_ "branch ${bold_cor}${new_branch}${reset_cor} does not exist remotely, push and set upstream?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
    fi

    # new branch doesnt exist in remote
    if ! git -C "$folder" push --no-verify --set-upstream $remote_name $new_branch; then
      return 1
    fi
  
  elif [[ -n "$new_remote_branch" ]]; then
    if (( ! renb_is_f )); then
      confirm_ "branch ${bold_cor}${new_branch}${reset_cor} already exists remotely, set as upstream?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
    fi

    # new branch already exist in remote, just set upstream to it
    git -C "$folder" branch --set-upstream-to="${remote_name}/${new_branch}"
  fi

  if [[ -n "$my_remote_branch" ]]; then
    if (( ! renb_is_f )); then
      confirm_ "your old branch ${bold_cor}${my_branch}${reset_cor} exists remotely, delete it?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
    fi
    # old branch exist in remote, delete it
    git -C "$folder" push --no-verify --delete $remote_name $my_branch
  fi

  if (( $? == 0 )); then
    git -C "$folder" remote prune $remote_name
  fi
  # if git -C "$folder" push $remote_name :$my_branch --no-verify --quiet; then
  #   git -C "$folder" push --no-verify --set-upstream $remote_name $new_branch
  # fi
  return 1;
}

function chp() {
  set +x
  eval "$(parse_flags_ "$0" "anmcs" "" "$@")"
  (( chp_is_debug )) && set -x

  if (( chp_is_h )); then
    print "  ${hi_yellow_cor}chp ${yellow_cor}[<commit_hash>] [<folder>]${reset_cor} : cherry-pick commit"
    print "  --"
    print "  ${hi_yellow_cor}chp -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}chp -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}chp -m <parent_number>${reset_cor} : the parent number (default is 1)"
    print "  ${hi_yellow_cor}chp -n${reset_cor} : --no-commit"
    print "  ${hi_yellow_cor}chp -s${reset_cor} : --signoff"
    return 0;
  fi

  local folder="$PWD"
  local hash_arg=""
  local num=1
  local arg_count=0

  local arg=""
  for arg in "$@"; do
    if [[ -n "$arg" ]]; then
      if [[ $arg =~ ^[0-9]+$ ]]; then
        if (( chp_is_m )) then
          num="$arg"
        else
          print " fatal: not a valid parent number argument: $arg" >&2
          print " run: ${hi_yellow_cor}chp -h${reset_cor} to see usage" >&2
          return 1;
        fi
        (( arg_count++ ))
      elif [[ -d "$arg" ]]; then
        folder="$arg"
        (( arg_count++ ))
      elif [[ $arg =~ ^[0-9a-f]{7,40}$ ]]; then
        hash_arg="$arg"
        (( arg_count++ ))
      fi
    fi
  done
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( chp_is_a )); then
    git -C "$folder" cherry-pick --abort $@ &>/dev/null
    return $?;
  fi

  if (( chp_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    if (( chp_is_n )); then
      GIT_EDITOR=true git -C "$folder" cherry-pick --continue --no-commit $@ &>/dev/null
    else
      GIT_EDITOR=true git -C "$folder" cherry-pick --continue $@ &>/dev/null
    fi
    return $?;
  fi

  local commit=""

  # get commit message by hash
  if [[ -z "$hash_arg" ]]; then
    # get a list of commits to revert
    local commits="$(git -C "$folder" --no-pager log --no-merges --oneline -100)"
    local commits=("${(@f)commits}")

    # use choose_multiple so user can select mutliple commits to revert
    commit=($(filter_one_ "commit to cherry-pick" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    # get the hash of the commit to cherry-pick
    local hash_arg="$(echo "$commit" | awk '{print $1}')"
  else
    commit="$(git -C "$folder" --no-pager log -1 --pretty=format:'%s' $hash_arg 2>/dev/null)"
  fi

  local flags=(-m $num)

  if (( chp_is_s )); then
    flags+=(--signoff)
  fi

  if (( chp_is_n )); then
    flags+=(--no-commit)
  fi

  if git -C "$folder" cherry-pick $hash_arg ${flags[@]} $@; then
    print "${green_cor}commit cherry-picked${reset_cor} $commit"
  fi
}

function revert() {
  set +x
  eval "$(parse_flags_ "$0" "ancms" "" "$@")"
  (( revert_is_debug )) && set -x

  if (( revert_is_h )); then
    print "  ${hi_yellow_cor}revert ${yellow_cor}[<commit_hash>] [<folder>]${reset_cor} : revert commit"
    print "  --"
    print "  ${hi_yellow_cor}revert -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}revert -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}revert -m <parent_number>${reset_cor} : the parent number (default is 1)"
    print "  ${hi_yellow_cor}revert -n${reset_cor} : --no-commit"
    print "  ${hi_yellow_cor}revert -s${reset_cor} : --signoff"
    return 0;
  fi

  local folder="$PWD"
  local hash_arg=""
  local num=1
  local arg_count=0

  local arg=""
  for arg in "$@"; do
    if [[ -n "$arg" ]]; then
      if [[ $arg =~ ^[0-9]+$ ]]; then
        if (( revert_is_m )) then
          num="$arg"
        else
          print " fatal: not a valid parent number argument: $arg" >&2
          print " run: ${hi_yellow_cor}revert -h${reset_cor} to see usage" >&2
          return 1;
        fi
        (( arg_count++ ))
      elif [[ -d "$arg" ]]; then
        folder="$arg"
        (( arg_count++ ))
      elif [[ $arg =~ ^[0-9a-f]{7,40}$ ]]; then
        hash_arg="$arg"
        (( arg_count++ ))
      fi
    fi
  done
  
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( revert_is_a )); then
    git -C "$folder" revert --abort $@ &>/dev/null
    return $?;
  fi

  if (( revert_is_c && ! revert_is_n )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" revert 3 $@ &>/dev/null
    return $?;
  fi

  if [[ -z "$hash_arg" ]]; then
    local commits="$(git -C "$folder" --no-pager log --no-merges --oneline -100)"
    local commits=("${(@f)commits}")

    local commit=($(filter_one_ "commit to revert" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    hash_arg="$(echo "$commit" | awk '{print $1}')"
  
  elif ! git -C "$folder" cat-file -e "${hash_arg}^{commit}" 2>/dev/null; then
    print " fatal: not a valid commit hash: $hash_arg" >&2
    return 1;
  fi

  local flags=(-m $num)

  if (( revert_is_s )); then
    flags+=(--signoff)
  fi

  if (( revert_is_n )); then
    flags+=(--no-commit)
  fi

  if git -C "$folder" revert $hash_arg ${flags[@]} $@; then
      print "${green_cor}commit reverted${reset_cor} $commit"
  fi
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
      print " run: ${hi_yellow_cor}conti -h${reset_cor} to see usage" >&2
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
      print " run: ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* && $1 != <-> ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument: $1" >&2
      print " run: ${hi_yellow_cor}fetch -h${reset_cor} to see usage" >&2
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
      print " run: ${hi_yellow_cor}fetch -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  local remote_name="$(get_remote_name_ "$folder")"

  if [[ -n "$branch_arg" ]]; then
    branch_arg="$(get_short_name_ "$branch_arg" "$folder")"

    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi

    if [[ "$branch_arg" == "$remote_name" ]]; then
      branch_arg=""
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
  
  git -C "$folder" fetch $remote_name $branch_arg ${flags[@]} $@
}

function gconf() {
  set +x
  eval "$(parse_flags_ "$0" "aergls" "" "$@")"
  (( gconf_is_debug )) && set -x

  if (( gconf_is_h )); then
    print "  ${hi_yellow_cor}gconf ${yellow_cor}[<entry>] [<folder>]${reset_cor} : display git configuration"
    print "  --"
    print "  ${hi_yellow_cor}gconf -a${reset_cor} : display all scopes (system, global, local)"
    print "  ${hi_yellow_cor}gconf -e${reset_cor} : display current effective configuration"
    print "  ${hi_yellow_cor}gconf -g${reset_cor} : display global scope configuration"
    print "  ${hi_yellow_cor}gconf -l${reset_cor} : display global local configuration"
    print "  ${hi_yellow_cor}gconf -r${reset_cor} : remove an entry from the configuration"
    print "  ${hi_yellow_cor}gconf -s${reset_cor} : display global system configuration"
    return 0;
  fi

  local folder="$PWD"
  local entry_arg=""

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      entry_arg="$1"
    fi
  
  elif [[ -n "$1" && $1 != -* ]] && [[ ! $1 =~ '^[0-9]+$' ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      entry_arg="$1"
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  local scope_arg="global"

  if (( gconf_is_l )); then
    if (( gconf_is_e || gconf_is_a || gconf_is_s )); then
      print " fatal: cannot use -l with -e or -a or -s" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    scope_arg="local"
  fi

  if (( gconf_is_s )); then
    if (( gconf_is_e || gconf_is_a || gconf_is_l )); then
      print " fatal: cannot use -s with -e or -a or -l" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    scope_arg="system"
  fi

  if (( gconf_is_r )); then
    if [[ -z "$entry_arg" ]]; then
      entry_arg="$(input_type_ "enter config key to remove in ${scope_arg} config" "" 100)"
      if (( $? == 130 || $? == 2 )); then return 130; fi
    fi

    if [[ -z "$entry_arg" ]]; then
      print " fatal: not a valid config key" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if ! git -C "$folder" config --${scope_arg} --unset-all "$entry_arg" &>/dev/null; then
      if ! git -C "$folder" config --${scope_arg} --unset "$entry_arg" &>/dev/null; then
        if ! git -C "$folder" config --${scope_arg} --remove-section "$entry_arg" &>/dev/null; then
          print " fatal: unable to remove config key: $entry_arg" >&2
          return 1;
        fi
      fi
    fi

    print " config key removed: ${orange_cor}$entry_arg${reset_cor}"
    return 0;
  fi

  if (( gconf_is_a )); then
    for scope in system global local; do
      print " ${hi_yellow_cor}== ${scope} config ==${reset_cor}"

      git -C "$folder" config --${scope} --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
        printf "  ${cyan_cor}%-40s${reset_cor} = ${cyan_cor}%s${reset_cor}\n" "$key" "$value"
      done

      print ""
    done

    return 0;
  fi

  if (( gconf_is_e )); then
    print " ${hi_yellow_cor}== current effective config ==${reset_cor}"

    git -C "$folder" config --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
      printf "  ${cyan_cor}%-44s${reset_cor} = ${cyan_cor}%s${reset_cor}\n" "$key" "$value"
    done

    print ""
    return 0;
  fi

  print " ${hi_yellow_cor}== ${scope_arg} config ==${reset_cor}"

  git -C "$folder" config --${scope_arg} --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
    printf "  ${cyan_cor}%-44s${reset_cor} = ${cyan_cor}%s${reset_cor}\n" "$key" "$value"
  done

  print ""
}

function glog() {
  set +x
  eval "$(parse_flags_ "$0" "abcmrfgtR" "" "$@")"
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
    print "  ${hi_yellow_cor}glog -r${reset_cor} : --reverse"
    print "  ${hi_yellow_cor}glog -R${reset_cor} : --remotes"
    print "  ${hi_yellow_cor}glog -f${yellow_cor} [<format>]${reset_cor} : --pretty=format:'<format>' default: \"%h %s\""
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""
  local format=""

  local base_branch=""
  local arg_count=0

  local is_error=0

  if [[ -n "$3" && $3 != -* ]]; then
    if (( ! glog_is_f )); then
      print " fatal: not a valid arguments: $@" >&2
      print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -d "$3" ]]; then
      folder="$3"
      if [[ -n "$1" && $1 != -* ]]; then
        if is_branch_name_valid_ "$1"; then
          branch_arg="$1"
          format="$2"
        else
          format="$1"
          branch_arg="$2"
        fi
      elif [[ -n "$2" && $2 != -* ]]; then
        if is_branch_name_valid_ "$2"; then
          branch_arg="$2"
          format="$1"
        else
          format="$2"
          branch_arg="$1"
        fi
      else
        is_error=1
      fi
    elif [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 != -* ]]; then
        if is_branch_name_valid_ "$1"; then
          branch_arg="$1"
          format="$3"
        else
          format="$1"
          branch_arg="$3"
        fi
      elif [[ -n "$3" && $3 != -* ]]; then
        if is_branch_name_valid_ "$3"; then
          branch_arg="$3"
          format="$1"
        else
          format="$3"
          branch_arg="$1"
        fi
      else
        is_error=1
      fi
    else
      is_error=1
    fi

    arg_count=3
  
  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 != -* ]]; then
        if is_branch_name_valid_ "$1"; then
          branch_arg="$1"
          format="$3"
        else
          format="$1"
          branch_arg="$3"
        fi
      else
        is_error=1
      fi
    else
      is_error=1
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if is_branch_name_valid_ "$1"; then
      branch_arg="$1"
    else
      format="$1"
    fi

    arg_count=1
  fi

  if (( is_error )); then
    print " fatal: not a valid argument: $1" >&2
    print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
    return 1;
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$format" ]] && (( ! glog_is_f )); then
    print " fatal: not a valid argument, did you miss -f flag?" >&2
    print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
    return 1;
  fi
  
  if [[ -n "$branch_arg" ]]; then
    if ! is_branch_name_valid_ "$branch_arg"; then
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

  if (( glog_is_R )); then
    flags+=("--remotes")
  fi

  if (( glog_is_r )); then
    flags+=("--reverse")
  fi

  if (( ! glog_is_t && ! glog_is_f )) && [[ -z "$format" ]]; then
    flags+=("--oneline")
  fi

  if [[ -z "$format" ]]; then
    format="%h %s"
    if (( glog_is_f )); then
      flags+=("--abbrev=7")
    fi
  fi

  if (( glog_is_b || glog_is_c || glog_is_m )); then

    local my_branch="$(get_my_branch_ -e "$folder" 2>/dev/null)"
    if [[ -z "$my_branch" ]]; then return 1; fi

    if (( glog_is_b && glog_is_c )) || (( glog_is_b && glog_is_m )) || (( glog_is_m && glog_is_c )); then
      print " fatal: cannot use -b, -c and -m cannot be used together" >&2
      print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( glog_is_b || glog_is_m )) && [[ -n "$branch_arg" ]]; then
      print " fatal: branch argument is not valid with -b or -m" >&2
      print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( glog_is_b )); then
      branch_arg="$(get_base_branch_ -f "$my_branch" "$folder")"
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if (( glog_is_m )); then
      branch_arg="$(get_main_branch_ -f "$folder")"
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if (( glog_is_c )); then
      if [[ -z "$branch_arg" ]]; then
        print " fatal: branch argument is required" >&2
        print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local remote_branch="$(get_remote_branch_ -f "$branch_arg" "$folder" 2>/dev/null)"
      if [[ -n "$remote_branch" ]]; then
        branch_arg="$remote_branch"
      fi
    fi

    print " showing commits of ${cyan_cor}${my_branch}${reset_cor} after head of ${hi_cyan_cor}${branch_arg}${reset_cor}"
    print ""

  if [[ -n "$format" ]] && (( glog_is_f )); then
      git -C "$folder" --no-pager log $branch_arg..$my_branch --no-merges --decorate --pretty=format:"$format" ${flags[@]} $@
    else
      git -C "$folder" --no-pager log $branch_arg..$my_branch --no-merges --decorate ${flags[@]} $@
    fi

    return $?;
  fi

  if [[ -n "$format" ]] && (( glog_is_f )); then
    git -C "$folder" --no-pager log $branch_arg --decorate --pretty=format:"$format" ${flags[@]} $@
  else
    git -C "$folder" --no-pager log $branch_arg --decorate ${flags[@]} $@
  fi
}

function push() {
  set +x
  eval "$(parse_flags_ "$0" "tfnvu" "q" "$@")"
  (( push_is_debug )) && set -x

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
    print "  ${hi_yellow_cor}push -u${reset_cor} : --set-upstream"
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
      print " run: ${hi_yellow_cor}push -h${reset_cor} to see usage" >&2
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
    branch_arg="$(get_short_name_ "$branch_arg" "$folder")"

    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi  
  else
    branch_arg="$(get_my_branch_ "$folder")"
    if [[ -z "$branch_arg" ]]; then return 1; fi
  fi

  # check if my branch is already upstreamed
  # local upstream_branch="$(git -C "$folder" config --get "branch.${branch_arg}.remote" 2>/dev/null)"
  
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

  local remote_name="$(get_remote_name_ "$folder")"

  git -C "$folder" push "$remote_name" "$branch_arg" "${flags[@]}" $@
  local RET=$?

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || push_is_q )) && echo 1 || echo 0)"

  if (( RET != 0 && is_quiet == 0 )); then
    print ""
    if (( ! push_is_f )); then
      if confirm_ "push failed, try push --force-with-lease?"; then
        pushf "$branch_arg" "$folder" "${flags[@]}" $@
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
      print " run: ${hi_yellow_cor}pushf -h${reset_cor} to see usage" >&2
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
    branch_arg="$(get_short_name_ "$branch_arg" "$folder")"

    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi    
  else
    branch_arg="$(get_my_branch_ "$folder")"
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

  local remote_name="$(get_remote_name_ "$folder")"

  git -C "$folder" push "$remote_name" "$branch_arg" "${flags[@]}" $@
  local RET=$?

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || pushf_is_q )) && echo 1 || echo 0)"

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --graph --decorate -1
    # no pbcopy
  fi

  return $RET;
}

function repush() {
  set +x
  eval "$(parse_flags_ "$0" "" "iq" "$@")"
  (( repush_is_debug )) && set -x

  if (( repush_is_h )); then
    print "  ${hi_yellow_cor}repush ${yellow_cor}[<folder>]${reset_cor} : reset last commit without losing your changes then re-push changes using the same commit message"
    print "  --"
    print "  ${hi_yellow_cor}repush -i${reset_cor} : only repush currently staged changes"
    print "  ${hi_yellow_cor}repush -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run: ${hi_yellow_cor}repush -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if ! recommit "$folder" $@; then return 1; fi

  pushf "$folder" $@
}

function pullr() {
  set +x
  eval "$(parse_flags_ "$0" "" "foptmq" "$@")"
  (( pullr_is_debug )) && set -x

  if (( pullr_is_h )); then
    print "  ${hi_yellow_cor}pullr ${yellow_cor}[<folder>]${reset_cor} : update current branch with its configured upstream, using rebase"
    print "  ${hi_yellow_cor}pullr <branch> ${yellow_cor}[<folder>]${reset_cor} : update from this exact branch using rebase, no guessing"
    print "  --"
    print "  ${hi_yellow_cor}pullr -fo${reset_cor} : --ff-only"
    print "  ${hi_yellow_cor}pullr -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor}pullr -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}pullr -m${reset_cor} : --rebase=merges"
    print "  ${hi_yellow_cor}pullr -q${reset_cor} : --quiet"
    return 0;
  fi

  pull -r "$@"
}

function pull() {
  set +x
  eval "$(parse_flags_ "$0" "trmf" "opq" "$@")"
  (( pull_is_debug )) && set -x

  if (( pull_is_h )); then
    print "  ${hi_yellow_cor}pull ${yellow_cor}[<folder>]${reset_cor} : update current branch with its configured upstream"
    print "  ${hi_yellow_cor}pull <branch> ${yellow_cor}[<folder>]${reset_cor} : update from this exact branch, no guessing"
    print "  --"
    print "  ${hi_yellow_cor}pull -ff${reset_cor} : --force"
    print "  ${hi_yellow_cor}pull -fo${reset_cor} : --ff-only"
    print "  ${hi_yellow_cor}pull -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor}pull -r${reset_cor} : --rebase"
    print "  ${hi_yellow_cor}pull -rm${reset_cor} : --rebase=merges"
    print "  ${hi_yellow_cor}pull -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}pull -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder="$PWD"
  local remote_name=""
  local branch_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
      if [[ -n "$1" && $1 != -* ]]; then
        branch_arg="$1"
      fi
    elif [[ "$1" == "origin" || "$1" == "upstream" ]]; then
      remote_name="$1"
      branch_arg="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    elif [[ "$1" == "origin" || "$1" == "upstream" ]]; then
      remote_name="$1"
    else
      branch_arg="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$branch_arg" ]]; then
    branch_arg="$(get_short_name_ "$branch_arg" "$folder")"

    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi

    if [[ -z "$remote_name" ]]; then
      remote_name="$(get_remote_name_ "$folder")"
    fi
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

  if (( pull_is_f_f )); then
    flags+=("--force")
  fi

  if (( pull_is_f && pull_is_o )); then
    flags+=("--ff-only")
  fi

  if (( pull_is_p )); then
    flags+=("--prune")
  fi

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || pull_is_q )) && echo 1 || echo 0)"

  git -C "$folder" pull $remote_name $branch_arg ${flags[@]} $@  
  local RET=$?

  if (( RET != 0 )); then
    if (( ! pull_is_r )); then
      if (( ! is_quiet )); then
        print ""
        if confirm_ "pull failed, try pull rebase?"; then
          pullr "$@"
          return $?;
        fi
      fi
    else
      setup_git_merge_tool_

      local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

      if [[ -n "$files" && -n "$PUMP_MERGE_TOOL" ]]; then
        git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
        RET=$?
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1
    # no pbcopy
  fi

  return $RET;
}

function print_clean_() {
  local softer_color=$'\e[38;5;214m'
  local soft_color=$'\e[38;5;208m'
  local medium_color=$'\e[38;5;202m'
  local hard_color=$'\e[38;5;1m'
  local harder_color=$'\e[38;5;88m'

  print "  all options:"
  print "  --"
  print "  ${hi_yellow_cor}discard${reset_cor} : ${medium_color}softer${reset_cor} : $(discard -hq 2>/dev/null | sed 's/^[^:]*: //' | head -n 1)"
  print "  ${hi_yellow_cor}restore${reset_cor} : ${softer_color}soft${reset_cor}   : $(restore -hq 2>/dev/null | sed 's/^[^:]*: //' | head -n 1)"
  print "  ${hi_yellow_cor}clean${reset_cor}   : ${soft_color}medium${reset_cor} : $(clean -hq 2>/dev/null | sed 's/^[^:]*: //' | head -n 1)"
  print "  ${hi_yellow_cor}reseta${reset_cor}  : ${hard_color}hard${reset_cor}   : $(reseta -hq 2>/dev/null | sed 's/^[^:]*: //' | head -n 1)"
  print "  ${hi_yellow_cor}reseto${reset_cor}  : ${harder_color}harder${reset_cor} : $(reseto -hq 2>/dev/null | sed 's/^[^:]*: //' | head -n 1)"
}

function restore() {
  set +x
  eval "$(parse_single_flags_ "$0" "i" "q" "$@")"
  (( restore_is_debug )) && set -x

  if (( restore_is_h )); then
    print "  ${hi_yellow_cor}restore ${yellow_cor}[<glob>]${reset_cor} : discard unstaged changes in working tree"
    print "  --"
    print "  ${hi_yellow_cor}restore -i${reset_cor} : unstage currently staged changes (same as ${hi_yellow_cor}discard${reset_cor})"
    if (( ! restore_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -z "$1" ]]; then
    set -- "."
  fi

  if (( restore_is_i )); then
    git -C "$folder" fetch --all --prune --quiet &>/dev/null

    if ! git -C "$folder" rev-parse --verify HEAD >/dev/null 2>&1; then
      print " cannot discard changes in index, there is no commit yet"
      return 1;
    fi

    git -C "$folder" restore --staged -- $@
  else
    git -C "$folder" restore --worktree -- $@
  fi
}

function clean() {
  set +x
  eval "$(parse_single_flags_ "$0" "" "q" "$@")"
  (( clean_is_debug )) && set -x

  if (( clean_is_h )); then
    print "  ${hi_yellow_cor}clean${reset_cor} : delete untracked files and folders from working tree"
    if (( ! clean_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  git -C "$folder" clean -fd $@
}

function discard() {
  set +x
  eval "$(parse_single_flags_ "$0" "q" "" "$@")"
  (( discard_is_debug )) && set -x

  if (( discard_is_h )); then
    print "  ${hi_yellow_cor}discard ${yellow_cor}[<glob>]${reset_cor} : unstage staged changes, leaving working tree untouched"
    print "  --"
    print "  ${hi_yellow_cor}discard -q${reset_cor} : --quiet"
    if (( ! discard_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  # does this repository already have at least one commit? check before to avoid errors
  if ! git -C "$folder" rev-parse --verify HEAD >/dev/null 2>&1; then
    print " cannot discard changes, there is no commit yet"
    return 1;
  fi

  # if [[ -z "$1" ]]; then
  #   print " fatal: you must specify path(s) to discard" >&2
  #   print " run: ${hi_yellow_cor}discard -h${reset_cor} to see usage" >&2
  # fi

  git -C "$folder" reset HEAD -- $@
}

function reseta() {
  set +x
  eval "$(parse_flags_ "$0" "om" "q" "$@")"
  (( reseta_is_debug )) && set -x

  if (( reseta_is_h )); then
    print "  ${hi_yellow_cor}reseta ${yellow_cor}[<branch_or_commit>] [<folder>]${reset_cor} : erase every change and match HEAD to local branch or commit"
    print "  --"
    print "  ${hi_yellow_cor}reseta -o${reset_cor} : erase every change and match HEAD to remote branch or commit"
    print "  ${hi_yellow_cor}reseta -m${reset_cor} : --mixed"
    print "  ${hi_yellow_cor}reseta -q${reset_cor} : --quiet"
    if (( ! reseta_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  local folder="$PWD"
  local branch_or_commit=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}pull -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_or_commit="$1"
    fi
    
    arg_count=2
  
  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_or_commit="$1"
    fi
    
    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  if [[ -n "$branch_or_commit" ]]; then
    # check if branch_or_commit is a commit hash
    if [[ $branch_or_commit =~ ^[0-9a-f]{7,40}$ ]]; then
      if ! git -C "$folder" cat-file -e "${branch_or_commit}^{commit}" 2>/dev/null; then
        print " fatal: not a valid commit hash: $branch_or_commit" >&2
        return 1;
      else
        if (( reseta_is_o )); then
          print " fatal: cannot use -o with a commit hash: $branch_or_commit" >&2
          return 1;
        fi
      fi
      # it's a valid commit hash
      if (( reseta_is_m )); then
        git -C "$folder" reset --mixed "${branch_or_commit}" $@
      else
        git -C "$folder" reset --hard "${branch_or_commit}" $@
      fi
      return $?;
    fi
    
    branch_or_commit="$(get_short_name_ "$branch_or_commit" "$folder")"

    if ! is_branch_name_valid_ "$branch_or_commit"; then
      return 1;
    fi
  else
    branch_or_commit="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$branch_or_commit" ]]; then return 1; fi
  fi

  git -C "$folder" clean -fd --quiet

  if (( reseta_is_o )); then
    local remote_name="$(get_remote_name_ "$folder")"
    
    git -C "$folder" fetch --all --prune --quiet &>/dev/null

    git -C "$folder" reset --hard "${remote_name}/${branch_or_commit}" $@
  else
    git -C "$folder" reset --hard "${branch_or_commit}" $@
  fi
}

function reseto() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( reseto_is_debug )) && set -x

  if (( reseto_is_h )); then
    print "  ${hi_yellow_cor}reseto ${yellow_cor}[<branch_or_commit>] [<folder>]${reset_cor} : erase every change and match HEAD to remote branch or commit"
    print "  --"
    print "  ${hi_yellow_cor}reseto -q${reset_cor} : --quiet"
    if (( ! reseto_is_q )); then
      print "  --"
      print_clean_
    fi
    return 0;
  fi

  reseta -o $@
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

  fetch "$folder" --quiet

  local proj_repo="$(get_repo_ "$folder" 2>/dev/null)"
  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"

  if [[ -z "$repo_name" ]]; then
    print " fatal: invalid repository folder: $folder" >&2
    return 1;
  fi
  
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
    proj_print_help_ "$proj_cmd" "gha"
    return 0;
  fi

  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -r $i; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"

  local gha_workflow=""
  local ask_save=0

  local RET=0

  if [[ -z "$workflow_arg" ]]; then
    local workflow_choices=""
    if command -v gum &>/dev/null; then
      workflow_choices="$(gum spin --title="loading workflows..." -- gh workflow list --repo "$proj_repo" | cut -f1)"
    else
      workflow_choices="$(gh workflow list --repo "$proj_repo" | cut -f1)"
    fi
    
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      print " no workflows found in $proj_cmd"
      return 0;
    fi
    
    local workflow_choices_sorted="$(printf "%s\n" "$workflow_choices" | sort -f)"
    
    workflow_arg="$(choose_one_ "workflow" "${(@f)workflow_choices_sorted}")"
    if (( $? == 130 )); then return 130; fi

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
    
    print "sleeping for $PUMP_INTERVAL minutes..."
    sleep $(( 60 * PUMP_INTERVAL ))
  done

  return $RET;
}

function co() {
  set +x
  eval "$(parse_flags_ "$0" "bcelpruax" "q" "$@")"
  (( co_is_debug )) && set -x

  if (( co_is_h )); then
    print "  ${hi_yellow_cor}co ${yellow_cor}[<branch>]${reset_cor} : switch to a branch"
    print "  ${hi_yellow_cor}co <branch> <base_branch>${reset_cor} : create new branch off of base branch"
    print "  --"
    print "  ${hi_yellow_cor}co -a ${yellow_cor}[<branch>]${reset_cor} : switch to remote branch"
    print "  ${hi_yellow_cor}co -l ${yellow_cor}[<branch>]${reset_cor} : switch to local branch"
    print "  --"
    print "  ${hi_yellow_cor}co -pr ${yellow_cor}[<pr>]${reset_cor} : switch to pull request (detached branch)"
    print "  --"
    print "  ${hi_yellow_cor}co -b <branch> ${yellow_cor}[<base_branch>]${reset_cor} : create new branch off of chosen base branch"
    print "  ${hi_yellow_cor}co -c <branch> ${yellow_cor}[<base_branch>]${reset_cor} : create new branch off of current branch"
    print "  ${hi_yellow_cor}co -e <branch> ${yellow_cor}[<base_branch>]${reset_cor} : switch to an exact branch, no lookup"
    print "  --"
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

  local branch_arg=""
  local base_branch_arg=""
  local folder="${folder_arg:-$PWD}"
  local arg_count=0

  if [[ -n "$1" && $1 != -* ]]; then
    branch_arg="$1"
    (( arg_count++ ))
  fi

  if [[ -n "$2" && $2 != -* ]]; then
    base_branch_arg="$2"
    (( arg_count++ ))
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then; return 1; fi

  if [[ -n "$branch_arg" ]]; then
    branch_arg="$(get_short_name_ "$branch_arg" "$folder")"
    
    if [[ "$branch_arg" == "co" ]] || ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi
  fi

  if [[ -n "$base_branch_arg" ]]; then
    base_branch_arg="$(get_short_name_ "$base_branch_arg" "$folder")"

    if [[ "$base_branch_arg" == "co" ]] || ! is_branch_name_valid_ "$base_branch_arg"; then
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  # co -pr switch by pull request
  if (( co_is_p && co_is_r )); then
    if [[ -n "$base_branch_arg" ]]; then
      print " fatal: co -pr does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    if ! command -v gh &>/dev/null; then
      print " fatal: command requires gh" >&2
      print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
      return 1;
    fi

    local proj_repo="$(get_repo_ "$folder")"
    if [[ -z "$proj_repo" ]]; then return 1; fi

    local pr_number=""
    local pr_branch=""
    local pr_title=""

    local output=""
    output="$(select_pr_ "$branch_arg" "$proj_repo" "pull request to detach")"
    if (( $? == 130 )); then return 130; fi
    IFS=$TAB read -r pr_number pr_branch pr_title _ <<<"$output"
    
    if [[ -z "$pr_number" ]]; then return 1; fi

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
      print "  ${red_cor}fatal: invalid option: co -p${reset_cor}" >&2
    else
      print "  ${red_cor}fatal: invalid option: co -r${reset_cor}" >&2
    fi
    print "  --"
    co -h
    return 1;
  fi

  # co -u set upstream branch
  if (( co_is_u )); then
    if [[ -z "$branch_arg" ]]; then
      branch_arg="$(get_my_branch_ "$folder")"
      if [[ -z "$branch_arg" ]]; then return 1; fi
    fi

    if [[ -n "$base_branch_arg" ]]; then
      print " fatal: co -u does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local remote_name="$(get_remote_name_ "$folder")"

    git -C "$folder" branch --set-upstream-to=$remote_name/$branch_arg $@

    return $?;
  fi

    # co -a list all branches
  if (( co_is_a )); then
    if [[ -n "$base_branch_arg" ]]; then
      print " fatal: co -a does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local branch_choice=""

    if [[ -n "$branch_arg" ]]; then
      branch_choice="$(select_branch_ -aic "$branch_arg" "branch to switch" "$folder")"
    else
      branch_choice="$(select_branch_ -am "" "branch to switch" "$folder")"
    fi
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$branch_choice" ]]; then return 1; fi

    branch_choice="$(get_short_name_ "$branch_choice" "$folder")"

    co -e "$folder" "$branch_choice" $@

    return $?;
  fi

  # co -l list local branches only
  if (( co_is_l )); then
    if [[ -n "$base_branch_arg" ]]; then
      print " fatal: co -l does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local branch_choice=""

    if [[ -n "$branch_arg" ]]; then
      branch_choice="$(select_branch_ -lic "$branch_arg" "local branch to switch" "$folder")"
    else
      branch_choice="$(select_branch_ -lm "" "local branch to switch" "$folder" 2>/dev/null)"
    fi
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$branch_choice" ]]; then
      if [[ -z "$branch_arg" ]]; then
        print " no other local branches found" >&2
      fi
      print " try ${hi_yellow_cor}co -a${reset_cor} to list remote branches" >&2
      return 1;
    fi
    if [[ -z "$branch_choice" ]]; then return 1; fi

    co -e "$folder" "$branch_choice" $@

    return $?;
  fi

  # co -c or co -b branch base_branch
  if (( co_is_b || co_is_c )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

    if [[ -n "$my_branch" && "$branch_arg" == "$my_branch" ]]; then
      print " fatal: branch already exists: $branch_arg" >&2
      return 1;
    fi

    if [[ -z "$base_branch_arg" ]]; then
      if (( co_is_b )); then
        local base_branch="$(determine_target_branch_ -dbe "$branch_arg" "$folder")"
        if [[ -z "$base_branch" ]]; then return 1; fi
      else
        base_branch_arg="$my_branch"
      fi
      co -xe "$folder" "$branch_arg" "$base_branch_arg" $@
    else
      co -x "$folder" "$branch_arg" "$base_branch_arg" $@
    fi

    return $?;
  fi

  # co -x branch BASE_BRANCH (creating branch)
  if (( co_is_x )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -z "$base_branch_arg" ]]; then
      print " fatal: base branch argument is required" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( ! co_is_e )); then
      base_branch_arg="$(select_branch_ -aix "$base_branch_arg" "" "$folder")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$base_branch_arg" ]]; then
        print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
        return 1;
      fi
      base_branch_arg="$(get_short_name_ "$base_branch_arg" "$folder")"
    fi

    local my_branch="$(get_my_branch_ "$folder")"
    
    if [[ "$base_branch_arg" != "$my_branch" ]]; then
      if [[ -n "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
        print " fatal: your working tree has uncommitted changes" >&2
        return 1;
      fi
    fi

    if git -C "$folder" switch "$base_branch_arg" --quiet &>/dev/null; then
      if ! git -C "$folder" switch -c "$branch_arg" $@; then
        return 1;
      fi
      del -f "${folder}/.pump" &>/dev/null
    else
      print " fatal: could not switch to base branch: $base_branch_arg" >&2
      return 1;
    fi

    local remote_name="$(get_remote_name_ "$folder")"

    git -C "$folder" config branch.$branch_arg.gh-merge-base $base_branch_arg
    git -C "$folder" config branch.$branch_arg.vscode-merge-base $remote_name/$base_branch_arg

    print " created branch ${hi_cyan_cor}${branch_arg}${reset_cor} off of ${cyan_cor}${base_branch_arg}${reset_cor}"

    return 0;
  fi

  # co -e branch just switch, do not create branch
  if (( co_is_e && ! co_is_x )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: missing branch or commit argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    git -C "$folder" fetch --all --prune --quiet &>/dev/null

    if ! git -C "$folder" switch "$branch_arg" $@; then
      if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
        if confirm_ "create new branch: ${pink_cor}${branch_arg}${reset_cor}?"; then
          co -c "$folder" "$branch_arg" $@
          return $?;
        fi
      fi
    fi

    return 0;
  fi

  # co branch_arg BASE_BRANCH (no arguments) (creating branch)
  if [[ -n "$base_branch_arg" ]]; then
    co -x "$folder" "$branch_arg" "$base_branch_arg" $@
    return $?;
  fi

  # co branch_arg or co (no arguments)
  local branch_choice=""

  # if branch arg was given, list all branches
  # if no branch arg was given, list local branches
  if [[ -n "$branch_arg" ]]; then
    branch_choice="$(select_branch_ -aic "$branch_arg" "branch to switch" "$folder")"
  else
    branch_choice="$(select_branch_ -lm "" "local branch to switch" "$folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$branch_choice" ]]; then
      branch_choice="$(select_branch_ -am "" "remote branch to switch" "$folder")"
    fi
  fi
  if (( $? == 130 )); then return 130; fi

  if [[ -n "$branch_choice" ]]; then
    branch_choice="$(get_short_name_ "$branch_choice" "$folder")"

    co -e "$folder" "$branch_choice" $@
    return $?;
  else
    if [[ -n "$branch_arg" ]]; then
      if confirm_ "create new branch: ${pink_cor}${branch_arg}${reset_cor}?"; then
        co -c "$folder" "$branch_arg" $@
        return $?;
      fi
    fi
  fi

  return 1;
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
      print " run: ${hi_yellow_cor}back -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if git -C "$folder" switch -; then
    fetch "$folder" --quiet
    return $?;
  fi
}

function develop() {
  dev $@
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
      print " run: ${hi_yellow_cor}dev -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{dev,develop,devel,development}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      if git -C "$folder" switch "${ref:t}"; then
        git -C "$folder" fetch --quiet
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: dev, develop, devel or development" >&2
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
      print " run: ${hi_yellow_cor}base -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  local base_branch="$(get_base_branch_ "$my_branch" "$folder")"
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
      print " run: ${hi_yellow_cor}main -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local main_branch="$(get_main_branch_ "$folder")"
  if [[ -z "$main_branch" ]]; then return 1; fi

  if git -C "$folder" switch "$main_branch"; then
    git -C "$folder" fetch --quiet
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
      print " run: ${hi_yellow_cor}prod -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{prod,production,product}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      if git -C "$folder" switch "${ref:t}"; then
        git -C "$folder" fetch --quiet
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: prod, production or product" >&2
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
      print " run: ${hi_yellow_cor}stage -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local remote_name="$(get_remote_name_ "$folder")"

  git -C "$folder" fetch --all --prune --quiet &>/dev/null

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{stage,staging}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      if git -C "$folder" switch "${ref:t}"; then
        git -C "$folder" fetch --quiet
        return $?;
      fi
    fi
  done

  print " fatal: did not match any branch known to git: stage or staging" >&2
  return 1;
}

function rebase() {
  set +x
  eval "$(parse_flags_ "$0" "cwfi" "amplXotq" "$@")"
  (( rebase_is_debug )) && set -x

  if (( rebase_is_h )); then
    print "  ${hi_yellow_cor}rebase ${yellow_cor}[<base_branch>] [<strategy>] [<folder>]${reset_cor} : apply the commits from your branch on top of base branch with strategy"
    print "  --"
    print "  ${hi_yellow_cor}rebase -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}rebase -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}rebase -f${reset_cor} : skip confirmation (base branch must be defined)"
    print "  ${hi_yellow_cor}rebase -i${reset_cor} : --interactive"
    print "  ${hi_yellow_cor}rebase -m${reset_cor} : --merge"
    print "  ${hi_yellow_cor}rebase -l${reset_cor} : rebase on top of local branch instead of base branch"
    print "  ${hi_yellow_cor}rebase -p${reset_cor} : push if rebase succeeds, abort if conflicts"
    print "  ${hi_yellow_cor}rebase -w${reset_cor} : multiple branches"
    print "  --"
    print "  ${hi_yellow_cor}rebase -Xo${reset_cor} : auto solve conflicts using 'ours' strategy"
    print "  ${hi_yellow_cor}rebase -Xt${reset_cor} : auto solve conflicts using 'theirs' strategy"
    return 0;
  fi

  local folder="$PWD"
  local base_branch_arg=""
  local strategy=""

  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    if [[ -d "$3" ]]; then
      folder="$3"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi
    base_branch_arg="$1"
    strategy="$2"

    arg_count=3
  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      base_branch_arg="$1"
      strategy="$2"
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

  if (( rebase_is_X && rebase_is_o && rebase_is_t )); then
    print " fatal: cannot use both -Xo and -Xt options together" >&2
    print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! rebase_is_p )) && (( rebase_is_a || ${argv[(Ie)--abort]} )); then
    git -C "$folder" rebase --abort &>/dev/null
    return $?;
  fi

  if (( ! rebase_is_p )) && (( rebase_is_c || ${argv[(Ie)--continue]} )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" rebase --continue &>/dev/null
    return $?;
  fi

  if [[ -n "$strategy" ]] && (( rebase_is_X )); then
    if [[ "$strategy" == "ours" ]]; then
      rebase_is_o=1
    elif [[ "$strategy" == "theirs" ]]; then
      rebase_is_t=1
    else
      print " fatal: cannot use -X options with custom strategy" >&2
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local my_branch="$(get_my_branch_ -e "$folder")"

  if [[ -z "$my_branch" ]]; then return 1; fi

  if (( rebase_is_p )) && [[ "$my_branch" == "HEAD" ]]; then
    print " fatal: cannot push a detached HEAD branch" >&2
    print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local base_branch="$base_branch_arg"

  if [[ -n "$base_branch" ]]; then
    if (( rebase_is_d || rebase_is_c )); then
      print " fatal: base branch cannot be defined with option" >&2
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( rebase_is_l )); then
      base_branch="$(get_short_name_ "$base_branch" "$folder")"
    fi

    local found_base_branch="$(select_branch_ -aix "$base_branch" "base branch" "$folder")"

    if [[ -z "$found_base_branch" ]]; then
      return 1;
    fi

    base_branch="$found_base_branch"
  else
    if (( rebase_is_f )); then
      print " fatal: base branch must be defined with -f option" >&2
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi

    base_branch="$(get_base_branch_ -f "$my_branch" "$folder")"

    if [[ -z "$base_branch" ]]; then
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local short_base_branch="$(get_short_name_ "$base_branch" "$folder")"

  if [[ "$my_branch" == "$short_base_branch" ]]; then
    print " fatal: your branch cannot be the same as base branch: $short_base_branch" >&2
    print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi
  
  local RET=0

  if (( rebase_is_w )); then
    local selected_branches=($(select_branches_ -l "" "to rebase" "$folder"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if git -C "$folder" switch "$branch" --quiet &>/dev/null; then
        rebase "$base_branch" "$strategy" "$folder" $@
        RET=$?
        if (( RET == 130 )); then return 130; fi
      else
        print " fatal: failed to switch to branch: $branch" >&2
        RET=1
      fi
    done

    return $RET;
  fi

  local msg="rebasing "
  if (( rebase_is_p && ! rebase_is_X )); then
    msg+="then pushing ";
  fi
  msg+="branch on top of ${hi_cyan_cor}${base_branch}${reset_cor}: ${green_cor}${my_branch}${reset_cor}"

  # rebase always ask for confirmation even if [[ -z "$base_branch_arg" ]] unless -f is given
  if (( ! rebase_is_f )); then
    confirm_ "$msg" "rebase" "abort"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then return 1; fi
  fi

  print " $msg"

  local is_staged=0
  local is_unstaged=0

  # check if working tree is not empty
  if [[ -n "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    # check if the number of staged files is more than zero and the number of unstaged files is more than zero and these numbers are different
    local staged_files_count="$(git -C "$folder" diff --cached --name-only | wc -l)"
    local unstaged_fil_count="$(git -C "$folder" diff --name-only | wc -l)"

    if (( staged_files_count > 0 && unstaged_fil_count > 0 )); then
      if ! confirm_ "you have unstaged changes, do you want to stage all before rebasing?" "stage" "abort"; then
        return 1;
      fi
    fi

    if ! git -C "$folder" add .; then return 1; fi
    if ! git -C "$folder" commit --no-gpg-sign --no-verify -m "WIP: auto commit" &>/dev/null; then return 1; fi

    if (( staged_files_count > 0 )); then
      is_staged=1
    else
      is_unstaged=1
    fi
  fi

  local flags=()

  if (( rebase_is_i )); then
    flags+=("--interactive")
  fi
  if (( rebase_is_m )); then
    flags+=("--merge")
  fi
  if (( rebase_is_q )); then
    flags+=("--quiet")
  fi
  if [[ -n "$strategy" ]]; then
    flags+=("--strategy-option=$strategy")
  fi
  if (( rebase_is_X && rebase_is_o )); then
    flags+=("--strategy-option=patience")
    flags+=("--strategy-option=ours")
  fi
  if (( rebase_is_X && rebase_is_t )); then
    flags+=("--strategy-option=patience")
    flags+=("--strategy-option=theirs")
  fi

  setup_git_merge_tool_

  if ! git -C "$folder" rebase $base_branch "${flags[@]}"; then
    local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

    if [[ -n "$files" && -n "$PUMP_MERGE_TOOL" ]]; then
      git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
      RET=$?
    fi
  fi

  if (( RET )); then
    if (( rebase_is_a )); then
      git -C "$folder" rebase --abort
    fi
  else
    if [[ "$my_branch" != "HEAD" ]]; then
      git -C "$folder" config branch.$my_branch.gh-merge-base $base_branch
    fi

    if (( is_staged || is_unstaged )); then
      # undo the auto commit
      git -C "$folder" reset --soft HEAD~1 &>/dev/null

      if (( is_unstaged )); then
        # unstage all files
        git -C "$folder" reset &>/dev/null
      fi
    fi

    if (( rebase_is_p && ! rebase_is_X )); then
      pushf "$my_branch" "$folder"
      RET=$?
    fi
  fi

  return $RET;
}

function setup_git_merge_tool_() {
  if [[ -z "$PUMP_MERGE_TOOL" ]]; then
    PUMP_MERGE_TOOL="$(input_command_ "type the command of your merge tool" "${PUMP_CODE_EDITOR:-code}")"
    
    if [[ -n "$PUMP_MERGE_TOOL" ]]; then
      update_setting_ "PUMP_MERGE_TOOL" "$PUMP_MERGE_TOOL"
    fi
  fi

  if [[ -n "$PUMP_MERGE_TOOL" ]]; then
    if command -v $PUMP_MERGE_TOOL &>/dev/null; then
      # git config --global diff.tool $PUMP_MERGE_TOOL
      # git config --global diff.guitool $PUMP_MERGE_TOOL
      # git config --global diff.$PUMP_MERGE_TOOL.cmd "$PUMP_MERGE_TOOL --new-window --wait --diff \"\$LOCAL\" \"\$REMOTE\""
      
      git config --global merge.tool $PUMP_MERGE_TOOL
      # git config --global merge.guitool $PUMP_MERGE_TOOL

      git config --global mergetool.$PUMP_MERGE_TOOL.cmd "$PUMP_MERGE_TOOL --new-window --wait --merge \"\$LOCAL\" \"\$REMOTE\" \"\$BASE\" \"\$MERGED\""
      git config --global mergetool.prompt false
      git config --global mergetool.keepBackup false
    fi
  fi
}

function merge() {
  set +x
  eval "$(parse_flags_ "$0" "cwf" "aplXotq" "$@")"
  (( merge_is_debug )) && set -x

  if (( merge_is_h )); then
    print "  ${hi_yellow_cor}merge ${yellow_cor}[<base_branch>] [<strategy>] [<folder>]${reset_cor} : merge from base branch with strategy"
    print "  --"
    print "  ${hi_yellow_cor}merge -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}merge -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}merge -f${reset_cor} : skip confirmation (base branch must be defined)"
    print "  ${hi_yellow_cor}merge -l${reset_cor} : merge from local branch instead of base branch"
    print "  ${hi_yellow_cor}merge -p${reset_cor} : push if merge succeeds, abort if conflicts"
    print "  ${hi_yellow_cor}merge -w${reset_cor} : multiple branches"
    print "  --"
    print "  ${hi_yellow_cor}merge -Xo${reset_cor} : auto solve conflicts using 'ours' strategy"
    print "  ${hi_yellow_cor}merge -Xt${reset_cor} : auto solve conflicts using 'theirs' strategy"
    return 0;
  fi

  local folder="$PWD"
  local base_branch_arg=""
  local strategy=""

  local arg_count=0

  if [[ -n "$3" && $3 != -* ]]; then
    if [[ -d "$3" ]]; then
      folder="$3"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
    base_branch_arg="$1"
    strategy="$2"

    arg_count=3
  elif [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      base_branch_arg="$1"
      strategy="$2"
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

  if (( merge_is_X && merge_is_o && merge_is_t )); then
    print " fatal: cannot use both -Xo and -Xt options together" >&2
    print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! merge_is_p )) && (( merge_is_a || ${argv[(Ie)--abort]} )); then
    git -C "$folder" merge --abort &>/dev/null
    return $?;
  fi

  if (( ! merge_is_p )) && (( merge_is_c || ${argv[(Ie)--continue]} )); then
    if ! git -C "$folder" add .; then return 1; fi
    GIT_EDITOR=true git -C "$folder" merge --continue &>/dev/null
    return $?;
  fi

  if [[ -n "$strategy" ]]; then
    if [[ "$strategy" == "ours" ]]; then
      merge_is_o=1
    elif [[ "$strategy" == "theirs" ]]; then
      merge_is_t=1
    else
      print " fatal: cannot use -X options with custom strategy" >&2
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
    strategy=""
  fi

  local my_branch="$(get_my_branch_ -e "$folder")"

  if [[ -z "$my_branch" ]]; then return 1; fi

  if (( merge_is_p )) && [[ "$my_branch" == "HEAD" ]]; then
    print " fatal: cannot push a detached HEAD branch" >&2
    print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local base_branch="$base_branch_arg"

  if [[ -n "$base_branch" ]]; then
    if (( merge_is_d || merge_is_c )); then
      print " fatal: base branch cannot be defined with option" >&2
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( merge_is_l )); then
      base_branch="$(get_short_name_ "$base_branch" "$folder")"
    fi

    local found_base_branch="$(select_branch_ -aix "$base_branch" "base branch" "$folder")"

    if [[ -z "$found_base_branch" ]]; then
      return 1;
    fi

    base_branch="$found_base_branch"
  else
    if (( merge_is_f )); then
      print " fatal: base branch must be defined with -f option" >&2
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi

    base_branch="$(get_base_branch_ -f "$my_branch" "$folder")"

    if [[ -z "$base_branch" ]]; then
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local short_base_branch="$(get_short_name_ "$base_branch" "$folder")"

  if [[ "$my_branch" == "$short_base_branch" ]]; then
    print " fatal: your branch cannot be the same as base branch: $short_base_branch" >&2
    print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local RET=0

  if (( merge_is_w )); then
    local selected_branches=($(select_branches_ -l "" "to merge" "$folder"))
    if [[ -z "$selected_branches" ]]; then return 1; fi

    local branch=""
    for branch in "${selected_branches[@]}"; do
      if git -C "$folder" switch "$branch" --quiet &>/dev/null; then
        merge "$base_branch_arg" "$strategy" "$folder" $@
        RET=$?
        if (( RET == 130 )); then return 130; fi
      else
        print " fatal: failed to switch to branch: $branch" >&2
        RET=1
      fi
    done

    return $RET;
  fi

  local msg="merging "
  if (( merge_is_p && ! merge_is_X )); then
    msg+="then pushing ";
  fi
  msg+="branch from ${hi_cyan_cor}${base_branch}${reset_cor}: ${green_cor}${my_branch}${reset_cor}"

  # merge asks only if base_branch was not given and -f is not given
  if (( ! merge_is_f )) && [[ -z "$base_branch_arg" ]]; then
    confirm_ "$msg" "merge" "abort"
    RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 1 )); then return 1; fi
  fi

  print " $msg"

  local flags=()

  if (( merge_is_q )); then
    flags+=("--quiet")
  fi
  if [[ -n "$strategy" ]]; then
    flags+=("--strategy-option=$strategy")
  fi
  if (( merge_is_X && merge_is_o )); then
    flags+=("--strategy-option=patience")
    flags+=("--strategy-option=ours")
  fi
  if (( merge_is_X && merge_is_t )); then
    flags+=("--strategy-option=patience")
    flags+=("--strategy-option=theirs")
  fi

  setup_git_merge_tool_

  if ! git -C "$folder" merge $base_branch --no-edit --ff-only "${flags[@]}" 2>/dev/null; then
    if ! git -C "$folder" merge $base_branch --no-edit "${flags[@]}"; then      
      local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

      if [[ -n "$files" && -n "$PUMP_MERGE_TOOL" ]]; then
        git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
        RET=$?
      fi
    fi
  fi

  if (( RET )); then
    if (( merge_is_a )); then
      git -C "$folder" merge --abort
    fi
  else
    if [[ "$my_branch" != "HEAD" ]]; then
      git -C "$folder" config branch.$my_branch.gh-merge-base $base_branch
    fi

    if (( merge_is_p && ! merge_is_X )); then
      push "$my_branch" "$folder"
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
      print " run: ${hi_yellow_cor}prune -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  local remote_name="$(get_remote_name_ "$folder")"

  local local_tags="$(git -C "$folder" tag)"
  local local_tags=("${(@f)local_tags}")

  local remote_tags="$(git -C "$folder" ls-remote --tags $remote_name)"
  local remote_tags=("${(@f)remote_tags}")
  
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
  git -C "$folder" fetch --tags --quiet

  local default_branch="$(get_default_branch_ "$folder")"
  if [[ -z "$default_branch" ]]; then return 1; fi

  # lists all branches that have been merged into the currently checked-out branch
  # that can be safely removed without losing any unmerged work and filters out the default branch
  local branches="$(git -C "$folder" branch --merged | grep -v "^\*\\|${default_branch}" | sed 's/^[ *]*//')"
  if [[ -n "$branches" ]]; then
    for branch in "$branches"; do
      git -C "$folder" branch -D $branch
      # git already does that
      # git -C "$folder" config --remove-section branch.$branch &>/dev/null
    done
  fi

  local current_branches="$(git -C "$folder" branch --format '%(refname:short)')"
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
  eval "$(parse_single_flags_ "$0" "fedra" "x" "$@")"
  (( delb_is_debug )) && set -x

  if (( delb_is_h )); then
    print "  ${hi_yellow_cor}delb ${yellow_cor}[<branch>] [<folder>]${reset_cor} : delete local branches"
    print "  --"
    print "  ${hi_yellow_cor}delb -e <branch>${reset_cor} : delete an exact branch, no lookup"
    print "  ${hi_yellow_cor}delb -r${reset_cor} : delete remote branches"
    print "  ${hi_yellow_cor}delb -a${reset_cor} : delete both local and remote branches"
    print "  ${hi_yellow_cor}delb -f${reset_cor} : skip confirmation (cannot use with -r or -a)"
    print "  ${hi_yellow_cor}delb -d${reset_cor} : --dry-run"
    return 0;
  fi

  local folder="$PWD"
  local branch_arg=""
  
  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    
    if [[ -n "$1" && $1 != -* ]]; then
      branch_arg="$1"
    else
      print " fatal: not a valid branch argument" >&2
      print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi

  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      branch_arg="$1"
    fi
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( delb_is_e || delb_is_f )); then
    if [[ -z "$branch_arg" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    if ! is_branch_name_valid_ "$branch_arg"; then
      return 1;
    fi
  fi

  if [[ -n "$branch_arg" ]]; then
    if (( ! delb_is_a )) && is_remote_branch_name_ "$branch_arg" "$folder" >/dev/null; then
      delb_is_r=1
    fi
  fi

  if (( delb_is_a && delb_is_r )); then
    print " fatal: cannot use -a with -r option" >&2
    print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if { (( delb_is_f && delb_is_r )) || (( delb_is_f && delb_is_a )) } && (( ! delb_is_x )); then
    print " fatal: cannot use -f with remote branch deletion" >&2
    print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local flags=""
  
  if (( delb_is_a )); then
    if (( delb_is_e || delb_is_x )); then
      flags="-aix"
    else
      flags="-am"
    fi
  elif (( delb_is_r )); then
    if (( delb_is_e || delb_is_x )); then
      flags="-rix"
    else
      flags="-rm"
    fi
  else
    if (( delb_is_e || delb_is_x )); then
      flags="-lix"
    else
      flags="-lm"
    fi
  fi

  selected_branches=($(select_branches_ "${flags}" "$branch_arg" "to delete" "$folder"))

  if [[ -z "$selected_branches" ]]; then
    if [[ -n "$branch_arg" ]]; then
      print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
    fi
    return 1;
  fi

  local RET=0
  local count=0
  local dont_ask=0

  local branch=""
  for branch in "${selected_branches[@]}"; do
    if (( ! delb_is_f && ! delb_is_r )) && (( ! delb_is_x )); then
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
        delb_is_f=1
      fi
    fi
    
    local remote_name="$(get_remote_name_ "$folder")"

    if (( ! delb_is_f )); then
      if [[ "$branch" == "$remote_name/"* ]]; then
        confirm_ "delete remote branch: ${magenta_cor}${branch}${reset_cor} ?"
      else
        confirm_ "delete local branch: ${magenta_cor}${branch}${reset_cor} ?"
      fi
      RET=$?
      if (( RET == 130 || RET == 2 )); then break; fi
      if (( RET == 1 )); then continue; fi
    fi

    # # if branch has remote_name in it
    if [[ "$branch" == "$remote_name/"* ]]; then
      branch="${branch#$remote_name/}"

      if (( delb_is_d )); then
        print "git -C '$folder' push --no-verify --delete $remote_name $branch"
      else
        git -C "$folder" push --no-verify --delete $remote_name $branch
      fi
      if (( delb_is_a )); then
        if (( delb_is_d )); then
          print "git -C '$folder' branch -D $branch &>/dev/null"
        else
          git -C "$folder" branch -D $branch &>/dev/null
        fi
      fi
    else
      if (( delb_is_d )); then
        print "git -C '$folder' branch -D $branch"
      else
        git -C "$folder" branch -D $branch
      fi
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
      print " run: ${hi_yellow_cor}st -h${reset_cor} to see usage" >&2
      return 1;
    fi
    shift
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  # -sb is equivalent to git status -sb
  git -C "$folder" status $@
}
  
function get_pkg_name_() {
  local folder="${1:-$PWD}"
  local repo="$2"

  if [[ -z "$repo" ]]; then
    if is_folder_git_ "$folder" &>/dev/null; then
      repo="$(get_repo_ "$folder" 2>/dev/null)"
    fi
  fi

  if [[ -n "$folder" ]]; then
    local pkg_name="$(get_from_package_json_ "name" "$folder")"
  
    if [[ -z "$pkg_name" && -n "$repo" ]]; then
      pkg_name="$(get_pkg_field_online_ "name" "$repo" 2>/dev/null)"
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
  eval "$(parse_flags_ "$0" "ax" "" "$@")"
  (( detect_node_version_is_debug )) && set -x

  local node_v_arg="$1"
  local folder="${2:-$PWD}"

  if ! command -v nvm &>/dev/null; then return 1; fi
  if ! command -v node &>/dev/null; then return 1; fi

  if ! is_folder_pkg_ "$folder" &>/dev/null; then return 1; fi

  if (( detect_node_version_is_x )); then
    if [[ -z "$node_v_arg" ]]; then
      node_v_arg="$(node --version 2>/dev/null)"
    fi
  fi

  local nvm_use_v=""

  if (( detect_node_version_is_x )); then
    local nvm_version="$(cat "$folder/.nvmrc" 2>/dev/null)"
    
    nvm_version="${nvm_version//[[:space:]]/}"

    if [[ -n "$nvm_version" ]]; then
      nvm_use_v="$(nvm version $nvm_version 2>/dev/null)"

      if [[ "$nvm_use_v" == "N/A" ]]; then
        print " ${yellow_cor}warning: node version in your .nvmrc file not found: ${bold_yellow_cor}${nvm_version}${reset_cor}" >&2
        print " run: ${hi_yellow_cor}nvm install ${nvm_version}${reset_cor} to install node" >&2

        nvm_use_v=""
      fi

      if [[ -n "$nvm_use_v" ]]; then
        echo "$nvm_use_v"
        return 0;
      fi
    fi
  fi

  if (( detect_node_version_is_a && ! PUMP_AUTO_DETECT_NODE )); then
    return 0;
  fi

  local versions=($(get_node_versions_ "$folder"))

  if [[ -z "$versions" ]]; then
    print " ${yellow_cor}warning: no matching node version in nvm for engine: ${bold_yellow_cor}${node_engine}${reset_cor}" >&2
    print " run: ${hi_yellow_cor}nvm install <version>${reset_cor} to install node" >&2
  else
    if [[ " ${versions[*]} " == *" $node_v_arg "* ]]; then
      nvm_use_v="$node_v_arg"
    elif (( detect_node_version_is_a )); then
      nvm_use_v="${versions[-1]}"
    else
      nvm_use_v="$(choose_one_ -i "node version to use with engine $node_engine" "${versions[@]}")"
    fi
  fi

  if [[ -n "$nvm_use_v" ]]; then
    echo "$nvm_use_v"
    return 0;
  fi

  return 1;
}

function get_maybe_jira_tickets_() {
  set +x
  eval "$(parse_flags_ "$0" "" "afij" "$@")"
  (( get_maybe_jira_tickets_is_debug )) && set -x

  local i="$1"
  local single_mode="$2"
  local folder="$3"
  local search_key="$4"

  local branches=()

  if (( single_mode )); then
    # get all local branches within the project's folder and store to a list
    branches=($(gum spin --title="getting branches..." -- git -C "$folder" branch --list "*$search_key*" -i --no-column --format="%(refname:short)" \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sort -fu
    ))

    local jira_pull_summary="${PUMP_JIRA_PULL_SUMMARY[$i]}"

    local key=""
    for key in "${branches[@]}"; do
      if [[ -n "$(extract_jira_key_ "$key")" ]]; then
        print -r -- "$key"
      fi
    done
  else
    # get all folders within the project's folder and store to a list
    get_folders_ $i "$folder" "$search_key" "${@:5}" 2>/dev/null
  fi
}

function pro() {
  set +x
  eval "$(parse_flags_ "$0" "aeruflnxdisc" "" "$@")"
  (( pro_is_debug )) && set -x

  if (( pro_is_h )); then
    print "  ${hi_yellow_cor}pro ${yellow_cor}[<name>]${reset_cor} : set project"
    print "  --"
    print "  ${hi_yellow_cor}pro -c ${yellow_cor}[<name>]${reset_cor} : clean project, remove old folders"
    print "  ${hi_yellow_cor}pro -a ${yellow_cor}[<name>]${reset_cor} : add new project"
    print "  ${hi_yellow_cor}pro -e ${yellow_cor}[<name>]${reset_cor} : edit project"
    print "  ${hi_yellow_cor}pro -r ${yellow_cor}[<name>]${reset_cor} : remove projects"
    print "  --"
    print "  ${hi_yellow_cor}pro -n ${yellow_cor}[<version>]${reset_cor} : set the node version with nvm"
    print "  ${hi_yellow_cor}pro -u ${yellow_cor}[<name>] [<setting>]${reset_cor} : reset config settings"
    print "  --"
    print "  ${hi_yellow_cor}pro -i${reset_cor} : display main config settings for all projects"
    print "  ${hi_yellow_cor}pro -l${reset_cor} : display all projects"
    return 0;
  fi

  if (( pro_is_l )); then
    # pro -l display projects
    local spaces="14s"

    local count=0

    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_FOLDER[$i]}" && -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        printf "  ${blue_cor}%-$spaces${reset_cor} ${hi_gray_cor}%s${reset_cor} \n" "${PUMP_SHORT_NAME[$i]}" "${PUMP_FOLDER[$i]}"
        (( count++ ))
      fi
    done

    if (( count == 0 )); then
      print " no projects found, add a project with: ${hi_yellow_cor}pro -a <name>${reset_cor}"
    fi

    return 0;
  fi

  local proj_arg="$1"

  # pro -c [<name>] clean project
  if (( pro_is_c )); then
    pro_c_ "$proj_arg" $@
    
    return $?;
  fi

  # pro -i [<name>] display project's settings
  if (( pro_is_i )); then

    local i=0
    for i in {1..9}; do
      if [[ -n "${PUMP_FOLDER[$i]}" && -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        local single_mode=""

        if [[ -n "${PUMP_SINGLE_MODE[$i]}" ]]; then
          single_mode="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "single" || echo "multiple" )"
        fi

        local spaces="10s"
        local mode_cor="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "$purple_cor" || echo "$pink_cor" )"

        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "name:" "${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"
        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "folder:" "${hi_gray_cor}${PUMP_FOLDER[$i]}${reset_cor}"
        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "mode:" "${mode_cor}${single_mode}${reset_cor}"
        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "manager:" "${hi_magenta_cor}${PUMP_PKG_MANAGER[$i]}${reset_cor}"
        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "node v.:" "${hi_cyan_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}"
        printf "  ${cyan_cor}%-$spaces${reset_cor} %s \n" "repo:" "${gray_cor}${PUMP_REPO[$i]}${reset_cor}"
        print "  --"
      fi
    done

    return 0;
  fi

  # pro -u [<name>] reset project settings
  if (( pro_is_u )); then
    local i="$(find_proj_index_ -oe "$proj_arg"  "project to reset settings for")"
    (( i )) || return 1;
    
    proj_arg="${PUMP_SHORT_NAME[$i]}"

    local setting_arg="$2"

    local all_settings=(
      "PUMP_AUTO_DETECT_NODE  =${PUMP_AUTO_DETECT_NODE}"
      "PUMP_CODE_EDITOR       =${PUMP_CODE_EDITOR}"
      "PUMP_PUSH_NO_VERIFY    =${PUMP_PUSH_NO_VERIFY}"
      "PUMP_PUSH_SET_UPSTREAM =${PUMP_PUSH_SET_UPSTREAM}"
      "PUMP_RUN_OPEN_COV      =${PUMP_RUN_OPEN_COV}"
      "PUMP_USE_MONOGRAM      =${PUMP_USE_MONOGRAM}"
    )

    local all_config_settings=(
      "PUMP_COMMIT_SIGNOFF    =$(load_config_entry_ $i "PUMP_COMMIT_SIGNOFF")"
      "PUMP_JIRA_ALMOST_DONE  =$(load_config_entry_ $i "PUMP_JIRA_ALMOST_DONE")"
      "PUMP_JIRA_API_TOKEN    =$(load_config_entry_ $i "PUMP_JIRA_API_TOKEN")"
      "PUMP_JIRA_CANCELED     =$(load_config_entry_ $i "PUMP_JIRA_CANCELED")"
      "PUMP_JIRA_DONE         =$(load_config_entry_ $i "PUMP_JIRA_DONE")"
      "PUMP_JIRA_IN_PROGRESS  =$(load_config_entry_ $i "PUMP_JIRA_IN_PROGRESS")"
      "PUMP_JIRA_IN_REVIEW    =$(load_config_entry_ $i "PUMP_JIRA_IN_REVIEW")"
      "PUMP_JIRA_IN_TEST      =$(load_config_entry_ $i "PUMP_JIRA_IN_TEST")"
      "PUMP_JIRA_PROJECT      =$(load_config_entry_ $i "PUMP_JIRA_PROJECT")"
      "PUMP_JIRA_PULL_SUMMARY =$(load_config_entry_ $i "PUMP_JIRA_PULL_SUMMARY")"
      "PUMP_JIRA_STATUSES     =$(load_config_entry_ $i "PUMP_JIRA_STATUSES")"
      "PUMP_JIRA_TODO         =$(load_config_entry_ $i "PUMP_JIRA_TODO")"
      "PUMP_JIRA_WORK_TYPES   =$(load_config_entry_ $i "PUMP_JIRA_WORK_TYPES")"
      "PUMP_NVM_USE_V         =$(load_config_entry_ $i "PUMP_NVM_USE_V")"
      "PUMP_PR_APPEND         =$(load_config_entry_ $i "PUMP_PR_APPEND")"
      "PUMP_PR_APPROVAL_MIN   =$(load_config_entry_ $i "PUMP_PR_APPROVAL_MIN")"
      "PUMP_PR_REPLACE        =$(load_config_entry_ $i "PUMP_PR_REPLACE")"
      "PUMP_SCRIPT_FOLDER     =$(load_config_entry_ $i "PUMP_SCRIPT_FOLDER")"
      "PUMP_SKIP_DETECT_NODE  =$(load_config_entry_ $i "PUMP_SKIP_DETECT_NODE")"
    )

    local filtered_settings=()
    local setting=""
    for setting in "${all_settings[@]}"; do
      local value="${setting#*=}"
      value="${value##[[:space:]]}"
      if [[ -n "$value" ]]; then
      filtered_settings+=("$setting")
      fi
    done

    local settings=("${filtered_settings[@]}")

    local filtered_config_settings=()
    local cfg=""
    for cfg in "${all_config_settings[@]}"; do
      local value="${cfg#*=}"
      value="${value##[[:space:]]}"
      if [[ -n "$value" ]]; then
      filtered_config_settings+=("$cfg")
      fi
    done

    local config_settings=("${filtered_config_settings[@]}")

    if [[ -n "$setting_arg" && " ${settings[*]} " != *" $setting_arg "* && " ${config_settings[*]} " != *" $setting_arg "* ]]; then
      print " fatal: invalid setting argument" >&2
      print " run: ${hi_yellow_cor}$proj_arg -u${reset_cor} to see available options" >&2
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

    local selected_settings_output=""
    selected_settings_output="$(choose_multiple_ "settings to reset" "${settings[@]}" "${config_settings[@]}")"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$selected_settings_output" ]]; then
      print " nothing chosen to reset" >&2
      return 1;
    fi
    
    local selected_settings=("${(@f)selected_settings_output}")

    local sett=""
    for sett in "${selected_settings[@]}"; do
      pro -u "$proj_arg" "$(echo "$sett" | cut -d= -f1 | xargs)"
    done
    
    return $?;
  fi

  # pro -d [<name>] display project config
  if (( pro_is_d )); then
    local i="$(find_proj_index_ -x "$proj_arg")"
    [[ -n "$i" ]] || return 1;
    
    print_current_proj_ $i
    return $?;
  fi

  # pro -e <name> edit project
  if (( pro_is_e )); then
    local i="$(find_proj_index_ -oe "$proj_arg" "project to edit")"
    (( i )) || return 1;

    proj_arg="${PUMP_SHORT_NAME[$i]}"

    save_proj_ -e $i "$proj_arg"
    return $?;
  fi

  # pro -a <name> add project
  if (( pro_is_a )); then
    local i=0
    for i in {1..9}; do
      # find an empty slot
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

        pro -s pwd
        return $?;
      fi
    done

    print " no more slots available, remove a project to add a new one" >&2
    print " run: ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
    
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

    local i="$(find_proj_index_ "$proj_arg"  "project to remove")"
    (( i )) || return 1;

    local is_refresh=0;
    if [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      is_refresh=1;
    fi

    if ! remove_proj_ -ur $i; then
      print " failed to remove: ${proj_arg}" >&2
      print " run: ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
      return 1;
    fi

    print " ${magenta_cor}removed project${reset_cor} $proj_arg"

    if (( is_refresh )); then
      set_current_proj_ 0
    fi

    return $?;
  fi

  # pro -n <version> set node version for a project
  if (( pro_is_n )); then
    pro_n_ "$proj_arg" $@

    return $?;
  fi

  # pro pwd project based on current working directory
  if [[ "$proj_arg" == "pwd" ]]; then
    proj_arg="$(find_proj_by_folder_ 2>/dev/null)"

    if [[ -z "$proj_arg" ]]; then # didn't find project based on pwd
      local folder_name="$(dirname -- "$PWD")"
      local parent_folder_name="$(basename -- "$folder_name")"

      if [[ "$parent_folder_name" == ".backups" || "$parent_folder_name" == ".revs" || "$parent_folder_name" == ".cov" ]]; then
        return 1;
      fi

      if ! is_folder_pkg_ &>/dev/null && ! is_folder_git_ &>/dev/null; then
        return 1;
      fi

      local pkg_name="$(get_pkg_name_ 2>/dev/null)"
      local proj_cmd="$(sanitize_pkg_name_ "$pkg_name")"
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
        if (( pro_is_s )) || confirm_ "add new project: ${bold_pink_cor}${pkg_name}${reset_cor} ?" "add" "no"; then
          save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name" 2>/dev/tty
        else
          pump_chpwd_pwd_ 2>/dev/tty
        fi
      fi

      return $?;
    else
      if (( pro_is_s )); then
        save_proj_ -a
        return $?;
      fi
    fi
  fi

  # pro (no name) - setting a project without providing a name will show a list of projects to choose from
  if [[ -z "$proj_arg" ]]; then
    local projects=()
    for i in {1..9}; do
      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        if validate_proj_cmd_strict_ $i "${PUMP_SHORT_NAME[$i]}" "${PUMP_SHORT_NAME[$i]}" &>/dev/null; then
          projects+=("${PUMP_SHORT_NAME[$i]}")
        fi
      fi
    done

    if (( ${#projects[@]} == 0 )); then
      print " no projects available" >&2
      print " run: ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
      
      return 1;
    fi
    
    proj_arg="$(choose_one_ "project to set" "${projects[@]}")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$proj_arg" ]]; then return 1; fi

    pro "$proj_arg"
    return $?;
  fi

  # pro <name> - setting a project with a name will set the project if it exists, otherwise it will show an error
  local i="$(find_proj_index_ -o "$proj_arg" "project to set")"
  if (( ! i )); then
    print " run: ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  proj_arg="${PUMP_SHORT_NAME[$i]}"

  # load the project config settings
  load_config_index_ $i

  CURRENT_PUMP_PKG_VERSION="$(get_from_package_json_ "version")"

  local jira_key="$(get_pump_value_ "JIRA_KEY")"
  local jira_title="$(get_pump_value_ "JIRA_TITLE")"

  if (( ! pro_is_f )) && [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
    pro_n_ -x "$proj_arg"

    if [[ -n "$jira_key" && -n "$jira_title" ]]; then
      print " ${gray_cor}${jira_key}${reset_cor} ${hi_gray_cor}${jira_title}${reset_cor}" 1>/dev/tty
    fi

    return 0;
  fi

  # change project

  set_current_proj_ $i

  print -n " project set to: ${blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}" 1>/dev/tty
  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print -n " with ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" 1>/dev/tty
  fi
  print "" 1>/dev/tty

  # cd into folder if PWD is not already within it
  if [[ "$PWD/" != "$CURRENT_PUMP_FOLDER/"* ]]; then
    cd "$CURRENT_PUMP_FOLDER"
  fi
 
  pro_n_ -x "$proj_arg"

  if [[ -n "$jira_key" && -n "$jira_title" ]]; then
    print " ${gray_cor}${jira_key}${reset_cor} ${hi_gray_cor}${jira_title}${reset_cor}" 1>/dev/tty
  fi

  if [[ -n "$CURRENT_PUMP_PRO" ]]; then
    eval "$CURRENT_PUMP_PRO"
  fi
}

function nvm_use_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  # (( nvm_use_is_debug )) && set -x

  if ! command -v nvm &>/dev/null; then return 1; fi

  local node_v_arg="$1"

  if [[ -z "$node_v_arg" ]]; then
    return 1;
  fi

  if (( ! nvm_use_is_f )); then
    local current_v="$(node --version 2>/dev/null)"

    if [[ "$current_v" == "$node_v_arg" ]]; then return 0; fi
  fi

  if ! nvm use "$node_v_arg" 1>/dev/null; then
    return 1;
  fi

  local current_v="$(node --version 2>/dev/null)"
  local npm_v="$(npm --version 2>/dev/null)"

  print " now using node ${hi_magenta_cor}$current_v${reset_cor} (npm v${npm_v})" 2>/dev/tty
}

# pro -n [<version>] set the node version for a project, if version is not provided, it will try to detect the version from the project's package.json engines field or .nvmrc file
function pro_n_() {
  set +x
  eval "$(parse_flags_ "$0" "x" "" "$@")"
  (( pro_n_is_debug )) && set -x

  if ! command -v nvm &>/dev/null; then
    if (( ! pro_n_is_x )); then
      print " fatal: nvm is required to set node version" >&2
      print " install nvm: ${blue_cor}https://github.com/nvm-sh/nvm${reset_cor}" >&2
    fi
    return 1;
  fi

  local i="$(find_proj_index_ -oe "$1" "project to set node version for")"
  (( i )) || return 1;

  shift
  
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  if ! check_proj_ -f $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  # check if $PWD is inside proj_folder path
  if [[ "$PWD/" == "$proj_folder/"* ]]; then
    proj_folder="$PWD"
  fi

  proj_folder="$(get_proj_for_pkg_ "$proj_folder" 2>/dev/null)"

  local node_v_arg=""

  if [[ -n "$2" && $2 != -* ]]; then
    node_v_arg="$2"
    shift
  fi

  local nvm_skip_lookup="${PUMP_SKIP_DETECT_NODE[$i]}"
  local current_nvm_use_v="${PUMP_NVM_USE_V[$i]}"

  local skip_lookup=0

  if (( pro_n_is_x && nvm_skip_lookup )); then
    skip_lookup=1

    if [[ -n "$current_nvm_use_v" ]]; then
      if ! nvm_use_ "$current_nvm_use_v"; then
        skip_lookup=0
      fi
    elif is_folder_pkg_ &>/dev/null || [[ -f "$proj_folder/.nvmrc" ]]; then
      skip_lookup=0
    fi
  fi

  if (( skip_lookup == 0 )); then
    local new_nvm_use_v="$(detect_node_version_ "$node_v_arg" "$proj_folder" $@)"

    if [[ -n "$new_nvm_use_v" ]]; then

      if nvm_use_ -f "$new_nvm_use_v"; then

        if [[ "$current_nvm_use_v" != "$new_nvm_use_v" ]]; then
          update_config_ $i "PUMP_NVM_USE_V" "$new_nvm_use_v"
          update_config_ $i "PUMP_SKIP_DETECT_NODE" 1
        else
          update_config_ $i "PUMP_SKIP_DETECT_NODE" 1 &>/dev/null
        fi
      fi

    else

      if [[ -n "$current_nvm_use_v" ]] && nvm_use_ "$current_nvm_use_v"; then
        update_config_ $i "PUMP_SKIP_DETECT_NODE" 1

      elif [[ -z "$nvm_skip_lookup" ]]; then
        print " ${yellow_cor}warning: could not find \"engines.node\" in ${blue_cor}$proj_cmd${yellow_cor} to detect node version in package.json${reset_cor}" >&2
        print " for more info: https://docs.npmjs.com/cli/v11/configuring-npm/package-json#engines" >&2
        print "" >&2
  
        if confirm_ "skip detection next time?" "skip" "no"; then
          update_config_ $i "PUMP_SKIP_DETECT_NODE" 1
        fi
      fi
    fi
  fi
}

# pro -c [<name>] clean project, remove old branches/folders
function pro_c_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( pro_c_is_debug )) && set -x

  if ! command -v acli &>/dev/null; then
    print " fatal: command requires acli" >&2
    print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2
    return 1;
  fi

  local i="$(find_proj_index_ -oe "$1"  "project to clean")"
  (( i )) || return 1;
  
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"

  if ! check_proj_ -fm $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  if ! check_jira_ -iss $i; then return 1; fi

  local label=""
  if (( single_mode )); then
    label="branches"
  else
    label="folders"
  fi

  local chosen_statuses=""
  chosen_statuses="$(select_multiple_jira_status_ $i "to delete ${label} locally")"
  if (( $? == 130 )); then return 130; fi

  local branch_or_folders=("${(f)"$(get_maybe_jira_tickets_ -afj $i "$single_mode" "$proj_folder" "" 2>/dev/null)"}")

  local branch_or_folder=""
  for branch_or_folder in "${branch_or_folders[@]}"; do
    local key="$(extract_jira_key_ "$branch_or_folder")"

    if [[ -n "$key" ]]; then
      local jira_status=""

      local output="$(get_jira_status_ "$key")"
      IFS=$TAB read -r jira_status _ <<<"$output"

      if [[ -z "$jira_status" ]] then
        return 1;
      fi

      if [[ " ${chosen_statuses[*]} " == *" ${jira_status:u} "* ]]; then
        if (( single_mode )); then
          if (( pro_c_is_f )); then
            delb -eif "$branch_or_folder" "${proj_folder}"
          else
            delb -ei "$branch_or_folder" "${proj_folder}"
          fi
        else
          if (( pro_c_is_f )); then
            del -fx -- "$branch_or_folder"
          else
            del -- "$branch_or_folder"
          fi
        fi

      fi
    fi
  done
}

# pro handler =========================================================
# pump()
function proj_handler() {
  local i="$1"
  shift

  set +x
  eval "$(parse_flags_proj_handler_ "$0" "meinudcof" "fcoprvdsmnbjaelxt" "$@")"
  (( proj_handler_is_debug )) && set -x

  if ! check_proj_ -m $i; then return 1; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local sub_cmds=("bkp" "clone" "gha" "jira" "prs" "rel" "rels" "rev" "revs" "run" "setup" "tag" "tags" "exec")

  if [[ " ${sub_cmds[*]} " != *" $1 "* ]]; then
    if (( proj_handler_is_h )); then
      print "  ${hi_yellow_cor}${proj_cmd}${yellow_cor} [<folder>]${reset_cor} : open project folder"
      (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} -of${yellow_cor} [<folder>]${reset_cor} : open project folder"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} -of <folder>${reset_cor} : open project folder"
      (( single_mode )) && print "  ${hi_yellow_cor}  -c${reset_cor} : clean project, remove old branches"
      (( ! single_mode )) && print "  ${hi_yellow_cor}  -c${reset_cor} : clean project, remove old folders"
      print "  ${hi_yellow_cor}  -e${reset_cor} : edit project"
      print "  ${hi_yellow_cor}  -i${reset_cor} : display project settings"
      (( ! single_mode )) && print "  ${hi_yellow_cor}  -m${reset_cor} : open main folder"
      print "  ${hi_yellow_cor}  -n${reset_cor} : set the node version with nvm"
      print "  ${hi_yellow_cor}  -u${yellow_cor} [<setting>]${reset_cor} : reset settings"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} bkp${reset_cor} : create backup of the project"
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<folder>]${reset_cor} : delete backup folders"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} clone${reset_cor} : clone project"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} clone <branch> [<target_branch>]${reset_cor} : clone branch"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} exec${yellow_cor} [<name>]${reset_cor} : execute an extension shell script"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} gha${yellow_cor} [<workflow>]${reset_cor} : check status of workflow"
      print "  ${hi_yellow_cor}  -a${yellow_cor} [<workflow>]${reset_cor} : check status of workflow every $PUMP_INTERVAL min"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} jira${yellow_cor} [<key>]${reset_cor} : open work item"
      print "  ${hi_yellow_cor}${proj_cmd} jira release${yellow_cor} [<key>]${reset_cor} : open work item in release"
      print "  ${hi_yellow_cor}  -sd${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_TODO}\""
      print "  ${hi_yellow_cor}  -sr${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_IN_REVIEW}\""
      print "  ${hi_yellow_cor}  -st${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_IN_TEST}\""
      print "  ${hi_yellow_cor}  -sa${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_ALMOST_DONE}\""
      print "  ${hi_yellow_cor}  -se${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_DONE}\""
      print "  ${hi_yellow_cor}  -sc${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to \"${CURRENT_PUMP_JIRA_CANCELED}\""
      print "  ${hi_yellow_cor}  -ss${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to a custom status"
      print "  ${hi_yellow_cor}  -v${yellow_cor} [<key>]${reset_cor} : view info on work item"
      print "  ${hi_yellow_cor}  -vv${reset_cor} : view info on all work items"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  ${hi_yellow_cor}  -x${reset_cor} : exact key, no lookup"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} prs${reset_cor} : list all pull requests"
      print "  ${hi_yellow_cor}  -l${yellow_cor} [<search>]${reset_cor} : label pull requests based on jira release"
      print "  ${hi_yellow_cor}  -ll${yellow_cor} [<search>]${reset_cor} : label pull requests based on all jira releases"
      print "  ${hi_yellow_cor}  -a${yellow_cor} [<search>]${reset_cor} : approve pull requests"
      print "  ${hi_yellow_cor}  -aa${yellow_cor} [<search>]${reset_cor} : approve prs every $PUMP_INTERVAL min"
      print "  ${hi_yellow_cor}  -r${reset_cor} : rebase/merge all your open pull requests"
      print "  ${hi_yellow_cor}  -rx${reset_cor} : rebase/merge and re-fix all your open pull requests"
      print "  ${hi_yellow_cor}  -s${reset_cor} : set assignee for all pull requests"
      print "  ${hi_yellow_cor}  -sa${reset_cor} : set assignee for all prs every $PUMP_INTERVAL min"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"

      if [[ "$proj_cmd" == "$CURRENT_PUMP_SHORT_NAME" ]] && is_folder_git_ &>/dev/null; then
        print "  ${hi_yellow_cor}${proj_cmd} rel${yellow_cor} [<branch>] [<tag>] [<title>]${reset_cor} : create new release"
      else
        print "  ${hi_yellow_cor}${proj_cmd} rel <branch>${yellow_cor} [<tag>] [<title>]${reset_cor} : create new release"
      fi
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<tag>]${reset_cor} : delete release"
      print "  ${hi_yellow_cor}  -m${reset_cor} : create major release"
      print "  ${hi_yellow_cor}  -n${reset_cor} : create minor release"
      print "  ${hi_yellow_cor}  -p${reset_cor} : create patch release"
      print "  ${hi_yellow_cor}  -b${reset_cor} : create beta release (mark the release as pre-release)"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} rels${reset_cor} : display releases"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} rev${yellow_cor} [<pr_or_branch>]${reset_cor} : open code review by pr or branch"
      print "  ${hi_yellow_cor}  -b${yellow_cor} [<branch>]${reset_cor} : open code review by branch only"
      print "  ${hi_yellow_cor}  -x${yellow_cor} [<branch>]${reset_cor} : exact branch, no lookup"
      print "  ${hi_yellow_cor}  -j${yellow_cor} [<jira_key>]${reset_cor} : open code review by work item"
      print "  ${hi_yellow_cor}  -r${yellow_cor} [<jira_key>]${reset_cor} : open code review by jira release"
      print "  ${hi_yellow_cor}  -e${reset_cor} : check out local code reviews"
      print "  ${hi_yellow_cor}  -d${reset_cor} : delete local code reviews"
      print "  ${hi_yellow_cor}  -dd${reset_cor} : delete all local code reviews"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} revs${reset_cor} : same as ${proj_cmd} rev -e"
      print "  --"

      if [[ -n "${PUMP_RUN[$i]}" ]]; then
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run${reset_cor} : run ${proj_cmd}'s PUMP_RUN in ${proj_cmd}'s folder"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run <folder>${reset_cor} : run ${proj_cmd}'s PUMP_RUN in a ${proj_cmd}'s folder"
      else
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run${reset_cor} : run ${proj_cmd}'s dev or start script"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run <folder>${reset_cor} : run a ${proj_cmd}'s folder's dev or start script"
      fi
      if [[ -n "${PUMP_RUN_STAGE[$i]}" ]]; then
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run stage${reset_cor} : run ${proj_cmd}'s PUMP_RUN_STAGE in ${proj_cmd}'s folder"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run stage <folder>${reset_cor} : run ${proj_cmd}'s PUMP_RUN_STAGE in a ${proj_cmd}'s folder"
      fi
      if [[ -n "${PUMP_RUN_PROD[$i]}" ]]; then
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run prod${reset_cor} : run ${proj_cmd}'s PUMP_RUN_PROD in ${proj_cmd}'s folder"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run prod <folder>${reset_cor} : run ${proj_cmd}'s PUMP_RUN_PROD in a ${proj_cmd}'s folder"
      fi
      (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run <script>${reset_cor} : run any ${proj_cmd}'s script"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run <script> <folder>${reset_cor} : run any ${proj_cmd}'s folder's script"
      print "  --"

      if [[ -n "${PUMP_SETUP[$i]}" ]]; then
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} setup${reset_cor} : run ${proj_cmd}'s PUMP_SETUP in ${proj_cmd}'s folder"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} setup <folder>${reset_cor} : run ${proj_cmd}'s PUMP_SETUP in a ${proj_cmd}'s folder"
      else
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} setup${reset_cor} : run ${proj_cmd}'s setup script or package manager install"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} setup <folder>${reset_cor} : run a ${proj_cmd}'s folder's setup script or package manager install"
      fi
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} tag${yellow_cor} [<name>]${reset_cor} : create tag"
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<name>]${reset_cor} : delete tag"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} tags${yellow_cor} [<n>]${reset_cor} : display n number of tags"

      return 0;
    fi

    # proj_handler -c
    if (( proj_handler_is_c )); then
      pro -c "$proj_cmd"
      return $?;
    fi

    # proj_handler -d
    if (( proj_handler_is_d )); then
      pro -d "$proj_cmd"
      return $?;
    fi

    # proj_handler -e
    if (( proj_handler_is_e )); then
      pro -e "$proj_cmd"
      return $?;
    fi

    # proj_handler -i
    if (( proj_handler_is_i )); then
      pro -i "$proj_cmd"
      return $?;
    fi

    # proj_handler -m
    if (( proj_handler_is_m )); then
      if (( single_mode )); then
        print "  ${red_cor}fatal: invalid option: $proj_cmd -m${reset_cor}" >&2
        print "  --"
        $proj_cmd -h
        return 0;
      fi

      if ! check_proj_ -fv $i; then return 1; fi
      local proj_folder="${PUMP_FOLDER[$i]}"
      
      local folder="$(get_proj_for_git_ "$proj_folder" 2>/dev/null)"

      if [[ -n "$folder" ]]; then
        folder="$(basename -- "$folder")"
      fi

      proj_handler_open_ -- $i "${proj_folder}/${folder}"
      return $?;
    fi

    # proj_handler -n [<version>]
    if (( proj_handler_is_n )); then
      pro -n "$proj_cmd" "$1"
      return $?;
    fi

    # proj_handler -u [<setting>]
    if (( proj_handler_is_u )); then
      pro -u "$proj_cmd" "$1"
      return $?;
    fi
  fi

  # proj_handler -of [<folder>] if single_mode
  # proj_handler -of <folder> if multiple mode
  if (( proj_handler_is_o && proj_handler_is_f )); then
    local folder_arg="$1"
    local choosen_folder=""

    if (( ! single_mode )) && [[ -z "$folder_arg" ]]; then
      print " fatal: folder argument is required" >&2
      print " run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_handler_folder_ -of $i "$@"
    return $?;
  fi

  # proj_handler <sub_cmd>
  if [[ " ${sub_cmds[*]} " == *" $1 "* ]]; then
    local sub_cmd="$1"

    local args=("${@:2}")
    local sub_args=("${@:3}")

    if (( proj_handler_is_h )); then
      args+=("-h")
      sub_args+=("-h")
    fi

    if [[ "$sub_cmd" == "bkp" ]]; then
      proj_bkp_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "clone" ]]; then
      proj_clone_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "exec" ]]; then
      proj_exec_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "gha" ]]; then
      proj_gha_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "jira" ]]; then
      local sub_sub_cmd="$2"
      
      if (( proj_handler_is_h )); then
        args+=("-h")
      fi

      if [[ -n "$sub_sub_cmd" ]]; then
        if [[ "$sub_sub_cmd" == "release" ]]; then
          proj_jira_release_ $proj_cmd "${sub_args[@]}"
          return $?;
        fi
      fi

      proj_jira_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "prs" ]]; then
      proj_prs_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "rel" ]]; then
      proj_rel_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "rels" ]]; then
      proj_rels_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "rev" ]]; then
      proj_rev_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "revs" ]]; then
      proj_revs_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "run" ]]; then
      proj_run_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "setup" ]]; then
      proj_setup_ "$proj_cmd" "${args[@]}"
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

  if (( proj_handler_is_o || proj_handler_is_f )); then
    local flag=""
    if (( proj_handler_is_o )); then
      flag="-o"
    else
      flag="-f"
    fi

    print " fatal: invalid option: $proj_cmd $flag${reset_cor}" >&2
    print " --"
    $proj_cmd -h

    return 0;
  fi

  if [[ $# -gt 1 ]]; then
    print " fatal: too many arguments" >&2
    print " run: ${hi_yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2

    return 0;
  fi

  proj_handler_folder_ $i "$@"
}

function proj_handler_folder_() {
  set +x
  eval "$(parse_single_flags_ "$0" "of" "" "$@")"
  (( proj_handler_folder_is_debug )) && set -x

  local i="$1"
  local folder_arg="$2"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"

  rm -rf -- "${proj_folder}/.DS_Store" &>/dev/null

  if [[ -n "$folder_arg" && -z "${folder_arg//\/}" ]]; then
    cd "$proj_folder"
    return $?;
  fi

  local is_of=0
  if (( proj_handler_folder_is_f && proj_handler_folder_is_o )); then
    is_of=1
  fi

  local folder_to_open="$proj_folder"
  local choosen_folder=""

  if (( single_mode )); then
    local RET=0
  
    if [[ -n "$folder_arg" ]] || (( is_of )); then
      if (( is_of )) && [[ -n "$folder_arg" ]]; then
        if [[ ! -d "${proj_folder}/${folder_arg}" ]]; then
          print " fatal: not a valid folder in ${proj_cmd}: $folder_arg" >&2
          print " run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage" >&2
          return 1;
        fi

        choosen_folder="$folder_arg"
      else
        local dirs_output=""
        dirs_output="$(get_folders_ -p $i "$proj_folder" "$folder_arg" 2>/dev/null)"
        if (( $? == 130 )); then return 130; fi
        
        local dirs=("${(@f)dirs_output}")

        if [[ -z "$dirs" && -n "$folder_arg" ]]; then
          print " not a valid folder: $folder_arg" >&2

          dirs_output="$(get_folders_ -p $i "$proj_folder" 2>/dev/null)"
          if (( $? == 130 )); then return 130; fi

          dirs=("${(@f)dirs_output}")
        fi

        if [[ -n "$dirs" ]]; then
          choosen_folder="$(choose_one_ -i "folder in $proj_cmd" "${dirs[@]}")"
          RET=$?
          if (( RET == 130 )); then return 1; fi
        fi
      fi
    fi

    folder_to_open="${proj_folder}/${choosen_folder}"

    if (( RET != 0 )); then
      cd "$folder_to_open"
      return $RET;
    fi

  else # multiple mode

    if (( is_of )) && [[ -n "$folder_arg" ]]; then
      # always will have $folder_arg here
      if [[ -d "${proj_folder}/${folder_arg}" ]]; then
        cd "${proj_folder}/${folder_arg}"
        return $?;
      fi

      print " fatal: not a valid folder in ${proj_cmd}: $folder_arg" >&2
      print " run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local dirs_output=""
    dirs_output="$(get_folders_ -ijp $i "$proj_folder" "$folder_arg" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi
    
    local dirs=("${(@f)dirs_output}")

    if [[ -z "$dirs" && -n "$folder_arg" ]]; then
      print " not a valid folder: $folder_arg" >&2

      dirs_output="$(get_folders_ -ip $i "$proj_folder" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      dirs=("${(@f)dirs_output}")
    fi

    local RET=0

    if [[ -n "$dirs" ]]; then
      choosen_folder="$(choose_one_ -it "folder in $proj_cmd" "${dirs[@]}")"
      RET=$?
      # we don't want to exit if user skips prompt when multiple mode,
      # we want to open root folder in this case
      # if (( RET == 130 || RET == 2 )); then return 1; fi
      if [[ -n "$choosen_folder" ]]; then
        folder_to_open="${proj_folder}/${choosen_folder}"

        if [[ -n "$folder_arg" ]]; then
          local folders="$(find "$proj_folder" -maxdepth 2 -type d -name "$choosen_folder" ! -path "*/.*" -print 2>/dev/null)"
          local found_proj_folder=("${(@f)folders}")

          found_proj_folder=("${found_proj_folder[@]/#$proj_folder\//}")          

          choosen_folder="$(choose_one_ -i "folder in $proj_cmd" "${found_proj_folder[@]}")"

          if [[ "$folder_to_open" != "${proj_folder}/${choosen_folder}" ]]; then
            folder_to_open="${proj_folder}/${choosen_folder}"

            cd "$folder_to_open"
            return $?;
          fi
        fi
      else
        # if already inside a project folder, exit to avoid cd to root folder
        if is_folder_git_ "$PWD" &>/dev/null; then
          return 0;
        fi
      fi
    fi

    if (( RET != 0 )); then
      cd "$folder_to_open"
      return 0;
    fi
  fi

  proj_handler_open_ -- $i "$folder_to_open"
}

function proj_handler_open_() {
  set +x
  eval "$(parse_single_flags_ "$0" "" "" "$@")"
  (( proj_handler_open_is_debug )) && set -x

  local i="$1"

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"

  local folder_to_open="${2:-$proj_folder}"

  if [[ ! -d "$folder_to_open" || -z "$(ls -- "$folder_to_open")" ]]; then
    print " project folder is empty!" >&2
    print " run: ${hi_yellow_cor}${proj_cmd} clone${reset_cor}" >&2
    return 1;
  fi

  local is_proj_folder=0

  local fsample="$(find "$folder_to_open" \( -path "*/.*" -a ! -name ".git" \) -prune -o -maxdepth 1 -type d -name ".git" -print -quit 2>/dev/null)"

  if [[ -n "$fsample" ]]; then
    is_proj_folder=1
  elif is_folder_pkg_ "$folder_to_open" &>/dev/null; then
    is_proj_folder=1
  elif is_folder_git_ "$folder_to_open" &>/dev/null; then
    is_proj_folder=1
  else
    local files_count="$(find "$folder_to_open" -maxdepth 1 \( -name '.*' -prune \) -o -type f -print | wc -l)"
    if (( files_count > 1 )); then
      is_proj_folder=1
    fi
  fi

  if (( ! is_proj_folder )); then
    local dirs_output=""
    dirs_output="$(get_folders_ -ijp $i "$folder_to_open" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi
    local dirs=("${(@f)dirs_output}")

    if [[ -n "$dirs" ]]; then
      local choosen_folder=""
      # choosen_folder has to be declared first so that RET can be captured
      choosen_folder="$(choose_one_ -it "folder in /$(basename -- "$folder_to_open")" "${dirs[@]}")"

      if (( $? != 0 )); then
        if is_folder_git_ "$PWD" &>/dev/null; then
          return 0;
        fi

        rm -rf -- "${folder_to_open}/.DS_Store"
        cd "$folder_to_open"
        return 1;
      fi

      if [[ -n "$choosen_folder" ]]; then
        choosen_folder="$(echo "$choosen_folder" | awk -F'\t' '{print $1}')"

        proj_handler_open_ -- $i "${folder_to_open}/${choosen_folder}"
        return $?;
      fi
    fi
  fi

  rm -rf -- "${folder_to_open}/.DS_Store"
  cd "$folder_to_open"
}

# commit functions ====================================================
function commit() {
  set +x
  eval "$(parse_flags_ "$0" "amsjcfn" "q" "$@")"
  (( commit_is_debug )) && set -x

  if (( commit_is_h )); then
    print "  ${hi_yellow_cor}commit ${yellow_cor}[-m] [<message>]${reset_cor} : commit wizard"
    print "  --"
    print "  ${hi_yellow_cor}commit -a${reset_cor} : add all files to index before commit"
    print "  ${hi_yellow_cor}commit -c${reset_cor} : create message using conventional commits standard"
    print "  ${hi_yellow_cor}commit -j${reset_cor} : create message using jira info if available"
    print "  ${hi_yellow_cor}commit -n${reset_cor} : prompt for a bigger commit message"
    print "  ${hi_yellow_cor}commit -f${reset_cor} : skip confirmation and prompts"
    (( CURRENT_PUMP_COMMIT_SIGNOFF )) && print "  ${hi_yellow_cor}commit -s${reset_cor} : --signoff (by default)"
    (( ! CURRENT_PUMP_COMMIT_SIGNOFF )) && print "  ${hi_yellow_cor}commit -s${reset_cor} : --signoff"
    return 0;
  fi

  local folder="$PWD"
  local commit_msg_arg=""

  local arg_count=0

  if [[ -n "$2" && $2 != -* ]]; then
    if [[ -d "$2" ]]; then
      folder="$2"
    else
      print " fatal: not a valid folder argument: $2" >&2
      print " run: ${hi_yellow_cor}commit -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -n "$1" && $1 != -* ]]; then
      commit_msg_arg="$1"
    fi

    arg_count=2

  elif [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      commit_msg_arg="$1"
    fi

    arg_count=1
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || commit_is_q )) && echo 1 || echo 0)"

  if [[ -z "$(git -C "$folder" status --porcelain 2>/dev/null)" ]]; then
    if (( ! is_quiet )); then
      print " nothing to commit, working tree clean" >&2
    fi
    return 1;
  fi

  if (( commit_is_f )) && (( commit_is_c || commit_is_n )); then
    print " fatal: option -f cannot be used together with -c or -n" >&2
    print " run: ${hi_yellow_cor}commit -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local proj_cmd="$(find_proj_by_folder_ "$folder" 2>/dev/null)"
  local i="$(find_proj_index_ -x "${proj_cmd:-$CURRENT_PUMP_SHORT_NAME}" 2>/dev/null)"

  local pump_commit_signoff="${PUMP_COMMIT_SIGNOFF[$i]:-$CURRENT_PUMP_COMMIT_SIGNOFF}"
  local pump_pr_title_format="${PUMP_PR_TITLE_FORMAT[$i]:-$CURRENT_PUMP_PR_TITLE_FORMAT}"

  if (( commit_is_a )); then
    if ! git -C "$folder" add .; then return 1; fi
  fi

  local flags=()

  if (( commit_is_s || pump_commit_signoff )); then
    flags=("--signoff")
  elif [[ -z "$pump_commit_signoff" ]]; then
    local RET=0
    if (( commit_is_f )); then
      RET=1
    else
      confirm_ "sign off commit?"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      flags=("--signoff")
  
      if (( i )); then
        update_config_ $i "PUMP_COMMIT_SIGNOFF" 1
      fi
    else
      if (( i && ! commit_is_f )); then
        update_config_ $i "PUMP_COMMIT_SIGNOFF" 0
      fi
    fi
  fi

  local commit_msg=""

  local jira_key="$(get_pump_value_ "JIRA_KEY" "$folder")"
  local jira_title="$(get_pump_value_ "JIRA_TITLE" "$folder")"

  jira_title="${commit_msg_arg:-$jira_title}"

  if [[ -z "$jira_key" || -z "$jira_title" ]] && (( ! commit_is_f )); then
    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    jira_key="$(extract_jira_key_ "$my_branch" "$folder")"

    if [[ -z "$jira_key" || -z "$jira_title" && "$my_branch" != *sync* ]]; then
      local commit_key=""
      local commit_title=""
      local output="$(read_commits_ -t "$my_branch" "$target_branch" "$folder")"
      IFS=$TAB read -r commit_key commit_title <<<"$output"

      if [[ -z "$jira_key" && -n "$commit_key" ]]; then
        jira_key="$commit_key"
      fi

      if [[ -z "$jira_title" && -n "$commit_title" ]]; then
        jira_title="$commit_title"
      fi
    fi
  fi

  local type_commit=""

  if (( commit_is_c )); then
    # types="fix|feat|docs|refactor|test|chore|style|revert"
    type_commit="$(choose_one_ "commmit type" "fix" "feat" "test" "build" "chore" "ci" "docs" "perf" "refactor" "revert" "style")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$type_commit" ]]; then return 1; fi

    # scope is optional
    local scope_commit=""
    scope_commit="$(input_type_ "" "scope")"
    if (( $? == 130 || $? == 2 )); then return 130; fi
    
    if [[ -n "$scope_commit" ]]; then
      type_commit="${type_commit}($scope_commit)"
    fi

    confirm_ "breaking change?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      type_commit="${type_commit}!"
    fi
  fi

  if (( commit_is_f )); then
    commit_msg="$commit_msg_arg"
  else
    if (( commit_is_j )) || [[ -n "$jira_key" ]]; then
      local commit_with_jira=""

      if [[ -n "$pump_pr_title_format" ]]; then
        local temp_commit_msg="${pump_pr_title_format//\<jira_key\>/$jira_key}"

        if [[ -n "$type_commit" ]]; then
          commit_with_jira="${type_commit}: ${jira_title}"
        else
          commit_with_jira="${jira_title}"
        fi
        # if commit_msg already has a jira_key then do not add another one
        local extract_jira_msg="$(extract_jira_key_ "$commit_with_jira")"

        if [[ -z "$extract_jira_msg" ]]; then
          commit_with_jira="${temp_commit_msg//\<jira_title\>/$commit_with_jira}"
        fi

      elif [[ -n "$jira_key" ]]; then
        if [[ -n "$type_commit" ]]; then
          commit_with_jira="${jira_key} ${type_commit}: ${jira_title}"
        else
          commit_with_jira="${jira_key} ${jira_title}"
        fi
      elif [[ -n "$type_commit" ]]; then
        commit_with_jira="${type_commit}: "
      fi

      if [[ "$commit_with_jira" != "$commit_msg_arg" ]]; then
        commit_msg="$(input_type_mandatory_ -k "" "commit message" 255 "$commit_with_jira")"
      fi
    else
      if [[ -n "$type_commit" ]]; then
        commit_msg="$(input_type_mandatory_ -k "" "commit message" 255 "${type_commit}: $commit_msg_arg")"
      elif [[ -n "$commit_msg_arg" ]]; then
        commit_msg="$commit_msg_arg"
      else
        commit_msg="$(input_type_mandatory_ -k "" "commit message" 255)"
      fi
    fi
    if (( $? == 130 )); then return 130; fi
  fi

  commit_msg="${commit_msg%.}"
  commit_msg="${commit_msg%%[[:space:]]#}"

  if [[ -z "$commit_msg" ]]; then
    print " fatal: commit message is not determined" >&2
    print " run: ${hi_yellow_cor}commit -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local details=""

  if (( commit_is_n )); then
    details="$(write_from_ "more details")"
    if (( $? == 130 )); then return 130; fi
  fi

  git -C "$folder" commit --no-verify -m "$commit_msg" -m "$details" ${flags[@]} $@
  local RET=$?
  if (( RET != 0 )); then return $RET; fi

  if (( ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1
  fi
}

function recommit() {
  set +x
  eval "$(parse_flags_ "$0" "i" "q" "$@")"
  (( recommit_is_debug )) && set -x

  if (( recommit_is_h )); then
    print "  ${hi_yellow_cor}recommit ${yellow_cor}[<folder>]${reset_cor} : reset last commit then re-commit all changes with the same message"
    print "  --"
    print "  ${hi_yellow_cor}recommit -i${reset_cor} : only recommit currently staged changes"
    print "  ${hi_yellow_cor}recommit -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder="$PWD"

  if [[ -n "$1" && $1 != -* ]]; then
    if [[ -d "$1" ]]; then
      folder="$1"
    else
      print " fatal: not a valid folder argument: $1" >&2
      print " run: ${hi_yellow_cor}recommit -h${reset_cor} to see usage" >&2
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
  
  if (( ! recommit_is_i )); then
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
# end of commit functions =============================================

function help() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( help_is_debug )) && set -x

  if (( help_is_h )); then
    print "  ${hi_yellow_cor}help${reset_cor} : display help"
    return 0;
  fi

  if command -v gum &>/dev/null; then
    gum style --border=rounded --margin=0 --padding="1 22" --border-foreground 212 --width=71 \
      --align=center --bold "welcome to $(gum style --foreground 212 --bold "pump my shell! $PUMP_VERSION")"
  else
    display_line_ "" "${bold_pink_cor}"
    display_line_ "pump my shell!" "${bold_pink_cor}" 72 "${reset_cor}"
    display_line_ "$PUMP_VERSION" "${bold_pink_cor}" 72 "${reset_cor}"
    display_line_ "" "${bold_pink_cor}"
  fi

  local node_version="not installed";
  
  if command -v node &>/dev/null; then
    node_version="$(node -v 2>/dev/null)"
  fi

  print ""
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print "  project: ${bold_blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}"
  fi
  print "  node v.: ${bold_cyan_cor}${node_version#v}${reset_cor}"
  if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
    print "  manager: ${bold_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}"
    
    if [[ "$CURRENT_PUMP_PKG_MANAGER" == "yarn" ]]; then
      if command -v yarn &>/dev/null; then
        local yarn_version="$(yarn -v 2>/dev/null)"
        print "  yarn v.: ${bold_yellow_cor}${yarn_version}${reset_cor}"
      else
        print "  yarn v.: ${bold_yellow_cor}not installed${reset_cor}"
      fi
    elif [[ "$CURRENT_PUMP_PKG_MANAGER" == "npm" ]]; then
      if command -v npm &>/dev/null; then
        local npm_version="$(npm -v 2>/dev/null)"
        print "  npm  v.: ${bold_yellow_cor}${npm_version}${reset_cor}"
      else
        print "  npm  v.: ${bold_yellow_cor}not installed${reset_cor}"
      fi
    elif [[ "$CURRENT_PUMP_PKG_MANAGER" == "pnpm" ]]; then
      if command -v pnpm &>/dev/null; then
        local pnpm_version="$(pnpm -v 2>/dev/null)"
        print "  pnpm v.: ${bold_yellow_cor}${pnpm_version}${reset_cor}"
      else
        print "  pnpm v.: ${bold_yellow_cor}not installed${reset_cor}"
      fi
    fi

  fi

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
  print "  type ${hi_yellow_cor}-h${reset_cor} after any command to see more usage, for example: ${hi_yellow_cor}pro -h${reset_cor}"
  print ""
  print "  more info: https://github.com/fab1o/pump-zsh/wiki"
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
      printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "${PUMP_SHORT_NAME[$i]}" "open project ${PUMP_SHORT_NAME[$i]}"
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

  local pkg_manager="$CURRENT_PUMP_PKG_MANAGER"
  
  print ""
  display_line_ "most popular" "${pink_cor}"
  print ""
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME" "open project $CURRENT_PUMP_SHORT_NAME"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "$CURRENT_PUMP_SHORT_NAME -h" "see more usage"
  else
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pro" "manage projects"
    printf "  ${blue_cor}%-$spaces${reset_cor} = %s \n" "pro -h" "see more usage"
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

  if [[ -n "$pkg_manager" ]]; then
    local _fix="${CURRENT_PUMP_FIX:-"$pkg_manager run fix (format + lint)"}"
    local _run="${CURRENT_PUMP_RUN:-"$pkg_manager run dev or $pkg_manager start"}"
    local _setup="${CURRENT_PUMP_SETUP:-"$pkg_manager run setup or $pkg_manager install"}"

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
  fi
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
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "clean" "delete untracked files and folders from working tree"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "delb" "delete branches"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "discard" "unstage staged changes, leaving working tree untouched"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "prune" "prune branches and tags"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset1" "reset soft 1 commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset2" "reset soft 2 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset3" "reset soft 3 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset4" "reset soft 4 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reset5" "reset soft 5 commits"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseta" "erase every change and match HEAD to local branch or commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseto" "erase every change and match HEAD to remote branch or commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "restore" "discard unstaged changes in working tree"

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
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "chp" "cherry-pick commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "conti" "continue rebase/merge/revert/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "revert" "revert commit"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git pull" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "fetch" "fetch from upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch from upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pullr" "pull rebase"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git push" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request in github"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push branch to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pushf" "force push branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"
}

function help_pkg_manager_() {
  local spaces="14s"
  local max=53 # the perfect number for the spaces
  
  local pkg_manager="$CURRENT_PUMP_PKG_MANAGER"

  if [[ -z "$pkg_manager" ]]; then return 1; fi

  print ""
  display_line_ "$pkg_manager" "${hi_magenta_cor}"
  print ""
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "build" "$pkg_manager run build"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "deploy" "$pkg_manager run deploy"
  
  if [[ -n "$CURRENT_PUMP_FIX" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "run PUMP_FIX"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "fix" "$pkg_manager run fix (format + lint)"
  fi

  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "format" "$pkg_manager run format"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "lint" "$pkg_manager run lint"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "rdev" "$pkg_manager run dev"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "rstart" "$pkg_manager run start"

  if [[ -n "$CURRENT_PUMP_RUN" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "run PUMP_RUN"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run" "$pkg_manager run dev or $pkg_manager start"
  fi
  if [[ -n "$CURRENT_PUMP_RUN_STAGE" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run stage" "run PUMP_RUN_STAGE"
  fi
  if [[ -n "$CURRENT_PUMP_RUN_PROD" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run prod" "run PUMP_RUN_PROD"
  fi
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "sb" "$pkg_manager run storybook"
  printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "sbb" "$pkg_manager run storybook:build"
  
  if [[ -n "$CURRENT_PUMP_SETUP" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "run PUMP_SETUP"
  else
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "setup" "$pkg_manager run setup or $pkg_manager install"
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

  local invalid_values=("pwd" "quit" "done" "path" "bkp" "clone" "gha" "jira" "prs" "rel" "rels" "rev" "revs" "run" "setup" "tag" "tags" "exec")

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
  eval "$(parse_flags_ "$0" "apejif" "" "$@")"
  (( get_folders_is_debug )) && set -x

  local i="$1"
  local folder="${2:-$PWD}"
  local name_search="$3"

  if [[ ! -d "$folder" ]]; then
    print " fatal: invalid folder argument: ${folder}" >&2
    return 1;
  fi

  local jira_pull_summary="${PUMP_JIRA_PULL_SUMMARY[$i]}"

  if (( get_folders_is_j )) && [[ -z "$jira_pull_summary" ]] && command -v acli &>/dev/null; then
    confirm_ "attempt to pull folder descriptions from work items?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      update_config_ $i "PUMP_JIRA_PULL_SUMMARY" 1 &>/dev/null
      jira_pull_summary=1
    else
      update_config_ $i "PUMP_JIRA_PULL_SUMMARY" 0 &>/dev/null
      jira_pull_summary=0
    fi
  fi

  # setopt NO_NOTIFY
  # {
  #   gum spin --title="preparing folders..." -- bash -c 'sleep 1'
  # } 2>/dev/tty

  local dirs=()

  # m	sort by modification time
  # n	sort by name
  # o	sort in ascending order (default)
  # O	sort in reverse order
  # N an array, not a string

  unsetopt dot_glob

  if (( get_folders_is_e )); then
    dirs+=("$folder"/"${name_search}"*(N/On))

    if (( get_folders_is_a )) || [[ -n "$name_search" ]]; then
      local work_types=($(check_work_types_ $i))

      local wt=""
      for wt in "${work_types[@]}"; do
        dirs+=("$folder"/$wt/"${name_search}"*(N/On))
      done
      dirs+=("$folder"/release/*"${name_search}"*(N/On))
    fi
  else
    dirs+=("$folder"/*"${name_search}"*(N/On))

    if (( get_folders_is_a )) || [[ -n "$name_search" ]]; then
      local work_types=($(check_work_types_ $i))

      local wt=""
      for wt in "${work_types[@]}"; do
        dirs+=("$folder"/$wt/*"${name_search}"*(N/On))
      done
      dirs+=("$folder"/release/*"${name_search}"*(N/On))
    fi
  fi

  local exclude_folders=("node_modules")
  local filtered_folders=()

  if (( get_folders_is_p )); then
    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ -z "$(extract_jira_key_ "$dir")" && " ${exclude_folders[@]} " != *" ${dir:t} "* && " ${exclude_folders[@]} " != *" $dir "* ]]; then
        if [[ -z "$(ls -- "$dir")" ]]; then
          continue;
        fi

        if (( get_folders_is_f )); then
          filtered_folders+=("$dir")
        else
          filtered_folders+=("${dir:t}")
        fi
      fi
    done

    local local_dirs=("$folder"/"${name_search}"*(N/On))
    dirs=("${local_dirs[@]}" "${dirs[@]}")

    # now work items
    dir=""
    for dir in "${dirs[@]}"; do
      if [[ -n "$(extract_jira_key_ "$dir")" && " ${filtered_folders[@]} " != *" $dir "* && " ${filtered_folders[@]} " != *" ${dir:t} "* ]]; then
        if [[ -z "$(ls -- "$dir")" ]]; then
          continue;
        fi
        
        if (( get_folders_is_i )); then
          local name="$(get_folders_i_ "$jira_pull_summary" "$dir" 2>/dev/null)";
          filtered_folders+=("$name")
        else
          if (( get_folders_is_f )); then
            filtered_folders+=("$dir")
          else
            filtered_folders+=("${dir:t}")
          fi
        fi
      fi
    done

  else

    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ " ${filtered_folders[@]} " != *" ${dir:t} "* && " ${filtered_folders[@]} " != *" $dir "* ]]; then
        if (( get_folders_is_j )) && [[ -z "$(extract_jira_key_ "$dir")" ]]; then
          continue;
        fi
        if [[ -z "$(ls -- "$dir")" ]]; then
          continue;
        fi

        if (( get_folders_is_i )); then
          local name="$(get_folders_i_ "$jira_pull_summary" "$dir" 2>/dev/null)";
          filtered_folders+=("$name")
        else
          if (( get_folders_is_f )); then
            filtered_folders+=("$dir")
          else
            filtered_folders+=("${dir:t}")
          fi
        fi
      fi
    done
  fi

  printf "%s\n" "${filtered_folders[@]}"
}

function get_folders_i_() {
  # run this function only for multiple_mode projects
  local jira_pull_summary="$1"
  local dir="$2"

  local name_display="$dir"

  local pump_jira_title="$(get_pump_value_ "JIRA_TITLE" "$dir")"
  local pump_jira_key="$(extract_jira_key_ "$dir")"

  local dirname="$(basename -- "$dir")"

  if (( jira_pull_summary )) && [[ -z "$pump_jira_title" ]]; then
    if [[ -n "$pump_jira_key" ]]; then
      if command -v acli &>/dev/null; then
        pump_jira_title="$(acli jira workitem view "$pump_jira_key" --fields=summary --json | jq -r '.fields.summary' 2>/dev/null)"
      fi
      # save in file even if could not get value because we dont want to do this all the time
      update_pump_file_ "JIRA_KEY" "$pump_jira_key" "$dir"
      update_pump_file_ "JIRA_TITLE" "$pump_jira_title" "$dir"
    fi
  fi
  
  if [[ -z "$pump_jira_title" ]]; then
    pump_jira_title="$(git -C "$dir" log -1 --pretty=%s 2>/dev/null)"
    if [[ -n "$pump_jira_title" && -z "$pump_jira_key" ]]; then
      pump_jira_key="$(extract_jira_key_ "$pump_jira_title")"
    fi
  fi

  if [[ -n "$pump_jira_title" ]]; then
    if [[ -n "$pump_jira_key" ]]; then
      pump_jira_title="${pump_jira_title//$pump_jira_key/}"
    fi

    pump_jira_title="$(echo "$pump_jira_title" | sed -E 's/^-+//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/^(.{99}).*/\1/' 2>/dev/null)"
    
    local spaces="$( [[ "$(basename -- "$folder")" == "release" ]] && echo "8s" || echo "11s" )"
    name_display="$(printf "%-$spaces %s" "$dirname")\t${pump_jira_title}";
  fi

  echo "$name_display"
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
    print "  ${hi_yellow_cor}kill <port>${reset_cor} : kill port number"
    return 0;
  fi

  if [[ -z "$1" ]]; then
    print " fatal: port number is required" >&2
    print " run: ${hi_yellow_cor}kill -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if ! command -v npx &>/dev/null; then
    print " fatal: npx is not installed" >&2
    print " run: ${hi_yellow_cor}sudo npm install -g npx${reset_cor} to install npx" >&2
    return 1;
  fi

  local yes=""

  local npx_version="$(npx --version 2>/dev/null)"
  if [[ "$npx_version" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    local npx_major="${npx_version%%.*}"
    if (( npx_major >= 7 )); then
      yes="--yes"
    fi
  fi

  npx $yes kill-port "$1"
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
typeset -g PUMP_AUTO_DETECT_NODE
typeset -g PUMP_CODE_EDITOR
typeset -g PUMP_MERGE_TOOL
typeset -g PUMP_PUSH_NO_VERIFY
typeset -g PUMP_PUSH_SET_UPSTREAM
typeset -g PUMP_RUN_OPEN_COV
typeset -g PUMP_USE_MONOGRAM
typeset -g PUMP_INTERVAL

# project config settinhs
typeset -gA PUMP_SHORT_NAME
typeset -gA PUMP_FOLDER
typeset -gA PUMP_REPO
typeset -gA PUMP_SINGLE_MODE
typeset -gA PUMP_PKG_MANAGER
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
typeset -gA PUMP_OPEN_COV
typeset -gA PUMP_TEST_WATCH
typeset -gA PUMP_E2E
typeset -gA PUMP_E2EUI
typeset -gA PUMP_PR_TEMPLATE_FILE
typeset -gA PUMP_PR_TITLE_FORMAT
typeset -gA PUMP_PR_REPLACE
typeset -gA PUMP_PR_APPEND
typeset -gA PUMP_PR_APPROVAL_MIN
typeset -gA PUMP_COMMIT_SIGNOFF
typeset -gA PUMP_PKG_NAME
typeset -gA PUMP_JIRA_PROJECT
typeset -gA PUMP_JIRA_API_TOKEN
typeset -gA PUMP_JIRA_STATUSES
typeset -gA PUMP_JIRA_TODO
typeset -gA PUMP_JIRA_IN_PROGRESS
typeset -gA PUMP_JIRA_IN_REVIEW
typeset -gA PUMP_JIRA_IN_TEST
typeset -gA PUMP_JIRA_ALMOST_DONE
typeset -gA PUMP_JIRA_DONE
typeset -gA PUMP_JIRA_CANCELED
typeset -gA PUMP_JIRA_WORK_TYPES
typeset -gA PUMP_JIRA_PULL_SUMMARY
typeset -gA PUMP_SKIP_DETECT_NODE
typeset -gA PUMP_NVM_USE_V
typeset -gA PUMP_SCRIPT_FOLDER

# ========================================================================

export CURRENT_PUMP_SHORT_NAME=""
export CURRENT_PUMP_PKG_VERSION=""

typeset -g CURRENT_PUMP_FOLDER=""
typeset -g CURRENT_PUMP_REPO=""
typeset -g CURRENT_PUMP_SINGLE_MODE=""
typeset -g CURRENT_PUMP_PKG_MANAGER=""
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
typeset -g CURRENT_PUMP_PR_TITLE_FORMAT=""
typeset -g CURRENT_PUMP_PR_REPLACE=""
typeset -g CURRENT_PUMP_PR_APPEND=""
typeset -g CURRENT_PUMP_PR_APPROVAL_MIN=""
typeset -g CURRENT_PUMP_COMMIT_SIGNOFF=""
typeset -g CURRENT_PUMP_PKG_NAME=""
typeset -g CURRENT_PUMP_JIRA_PROJECT=""
typeset -g CURRENT_PUMP_JIRA_API_TOKEN=""
typeset -g CURRENT_PUMP_JIRA_STATUSES=""
typeset -g CURRENT_PUMP_JIRA_TODO=""
typeset -g CURRENT_PUMP_JIRA_IN_PROGRESS=""
typeset -g CURRENT_PUMP_JIRA_IN_REVIEW=""
typeset -g CURRENT_PUMP_JIRA_IN_TEST=""
typeset -g CURRENT_PUMP_JIRA_ALMOST_DONE=""
typeset -g CURRENT_PUMP_JIRA_DONE=""
typeset -g CURRENT_PUMP_JIRA_CANCELED=""
typeset -g CURRENT_PUMP_JIRA_PULL_SUMMARY=""
typeset -g CURRENT_PUMP_SKIP_DETECT_NODE=""
typeset -g CURRENT_PUMP_NVM_USE_V=""
typeset -g CURRENT_PUMP_SCRIPT_FOLDER=""

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g TEMP_PUMP_SHORT_NAME=""
typeset -g TEMP_PUMP_FOLDER=""
typeset -g TEMP_PUMP_REPO=""
typeset -g TEMP_SINGLE_MODE=""
typeset -g TEMP_PUMP_PKG_MANAGER=""

typeset -g SAVE_COR=""
typeset -g CHPWD_SILENT=1
# ========================================================================

function preexec() {
  timer="$(print -P %D{%s%3.})"
}

function precmd() {
  local time_took=""

  if [[ $timer ]]; then;
    local now="$(print -P %D{%s%3.})"
    local d_ms="$(($now - $timer))"
    local d_s="$((d_ms / 1000))"
    local ms="$((d_ms % 1000))"
    local s="$((d_s % 60))"
    local m="$(((d_s / 60) % 60))"
    local h="$((d_s / 3600))"

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
  PUMP_SHORT_NAME[0]=""
  PUMP_FOLDER[0]="$PWD"
  PUMP_REPO[0]="$(get_repo_ "$PWD" 2>/dev/null)"

  set_current_proj_ 0 # set to default values

  if is_folder_pkg_ &>/dev/null; then
    CURRENT_PUMP_NVM_USE_V="$(detect_node_version_ -a 2>/dev/null)"

    if [[ -n "$CURRENT_PUMP_NVM_USE_V" ]]; then
      if (( CHPWD_SILENT )); then
        nvm_use_ -f "$CURRENT_PUMP_NVM_USE_V"
      else
        nvm_use_ "$CURRENT_PUMP_NVM_USE_V"
      fi
    fi

    CURRENT_PUMP_PKG_VERSION="$(get_from_package_json_ "version")"
    CHPWD_SILENT=0

    return 0;
  fi

  CURRENT_PUMP_PKG_VERSION=""
  CHPWD_SILENT=0

  return 1;
}

# cd pro pwd
function pump_chpwd_() {
  set +x
  local proj="$(find_proj_by_folder_ 2>/dev/null)"

  if [[ -n "$proj" ]]; then
    if pro "$proj"; then
      git fetch --all --prune --quiet &>/dev/null
    fi
  elif pump_chpwd_pwd_; then
    git fetch --all --prune --quiet &>/dev/null
  fi

  if [[ -n "$PWD" ]]; then
    rm -rf -- "$PWD/.DS_Store"
  fi
  return 0;
}

function trim_() {
  local val="$1"

  if [[ -n "$val" ]]; then
    val="$(echo "$val" | xargs 2>/dev/null)"
    # if [[ -z "$val" ]]; then
    #   val="$(echo "$val" | xargs -0 2>/dev/null)";
    # fi
    if [[ -z "$val" ]]; then
      val="$1"
    fi

    val="${${val##[[:space:]]}%%[[:space:]]}"
  fi

  echo "$val"
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

pro -f pwd 2>/dev/null
add-zsh-hook chpwd pump_chpwd_ &>/dev/null

if [[ "$(date +%u)" == "5" ]]; then upgrade_; fi
# ==========================================================================
# 1>/dev/null or >/dev/null	  Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null	                Hide both stdout and stderr outputs
