#!/usr/bin/env zsh

# regular colors
typeset -g red_cor=$'\e[0;31m'
typeset -g green_cor=$'\e[0;32m'
typeset -g yellow_cor=$'\e[0;33m'
typeset -g blue_cor=$'\e[0;34m'
typeset -g magenta_cor=$'\e[0;35m'
typeset -g cyan_cor=$'\e[0;36m'
typeset -g gray_cor=$'\e[38;5;240m'

# special colors
typeset -g dark_green_cor=$'\e[38;5;22m'
typeset -g orange_cor=$'\e[38;5;208m'
typeset -g purple_cor=$'\e[38;5;105m'
typeset -g pink_cor=$'\e[38;5;212m'

# bold (bright) colors
typeset -g bold_red_cor=$'\e[1;31m'
typeset -g bold_green_cor=$'\e[1;32m'
typeset -g bold_yellow_cor=$'\e[1;33m'
typeset -g bold_blue_cor=$'\e[1;34m'
typeset -g bold_magenta_cor=$'\e[1;35m'
typeset -g bold_cyan_cor=$'\e[1;36m'
typeset -g bold_gray_cor=$'\e[1;38m'

typeset -g bold_dark_green_cor=$'\e[1;38;5;22m'
typeset -g bold_orange_cor=$'\e[1;38;5;208m'
typeset -g bold_purple_cor=$'\e[1;38;5;105m'
typeset -g bold_pink_cor=$'\e[1;38;5;212m'

# high-intensity colors (90–97)
typeset -g hi_red_cor=$'\e[0;91m'
typeset -g hi_green_cor=$'\e[0;92m'
typeset -g hi_yellow_cor=$'\e[0;93m'
typeset -g hi_blue_cor=$'\e[0;94m'
typeset -g hi_magenta_cor=$'\e[0;95m'
typeset -g hi_cyan_cor=$'\e[0;96m'
typeset -g hi_gray_cor=$'\e[38;5;244m'

# bold high-intensity colors display the same as regular bold colors 

typeset -g bold_cor=$'\e[1m'
typeset -g reset_cor=$'\e[0m'
typeset -g new_line=$'\n '
typeset -g script_cor="$pink_cor"

typeset -g TAB=$'\x1F'
typeset -g NUL=$'\0'
typeset -ga BRANCHES=(main master stage staging prod production release dev develop trunk mainline default stable)

typeset -g PUMP_VERSION="0.0.0"
typeset -g PUMP_VERSION_FILE="$(dirname -- "$0")/.version"
typeset -g PUMP_CONFIG_FILE="$(dirname -- "$0")/config/pump.zshenv"
typeset -g PUMP_SETTINGS_FILE="$(dirname -- "$0")/config/pump.set.zshenv"

typeset -g invalid_opts is_debug is_invalid

typeset -g colors=("${bold_yellow_cor}" "${bold_blue_cor}" "${bold_magenta_cor}" "${bold_green_cor}" "${bold_dark_green_cor}" "${bold_orange_cor}" "${bold_pink_cor}" "${bold_red_cor}" "${bold_cyan_cor}")

if [[ -f "$PUMP_VERSION_FILE" ]]; then
  PUMP_VERSION="$(<"$PUMP_VERSION_FILE")"
fi

function parse_flags_proj_handler_() {
  if [[ -n "$4" && $4 != -* ]]; then    
    parse_flags__ "$1" "$2$3" "all" "" "${@:4}"
  else
    if [[ -n "$2" && $2 != -* ]]; then    
      parse_flags__ "$1" "$2" "" "" "${@:4}"
    else
      parse_flags__ "$1" "$2" "all" "" "${@:4}"
    fi
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

  # if [[ "$1" == "glog" ]]; then set -x; fi

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
  for opt in {0..9}; do
    echo "${prefix}_is_$opt=0"
    echo "${prefix}_is_${opt}_${opt}=0"
  done
  for opt in {A..Z}; do
    echo "${prefix}_is_$opt=0"
    echo "${prefix}_is_${opt}_${opt}=0"
  done

  local stop_parsing=0

  local evaluated_flags=""

  if [[ -n "$hidden_flags" ]]; then
    local arg=""
    for arg in "$@"; do
      if [[ "$arg" == "--" ]]; then
        break;
      fi

      if [[ "$arg" == -[a-zA-Z0-9]* ]]; then
        local letters="${arg#-}"
        local i=0
        for (( i=0; i < ${#letters}; i++ )); do
          local opt="${letters:$i:1}"

          if [[ $hidden_flags != *$opt* ]]; then
            evaluated_flags+="${opt}"
          fi
        done
      fi
    done
  fi

  # set -x

  # getopts is not ideal because it doesn't support flags after the arguments, only before them
  # example: `mycommand arg1 arg2 -a -b` does not work with getopts
  local arg=""
  for arg in "$@"; do
    if (( stop_parsing )) || [[ "$arg" == "--" ]]; then
      if (( stop_parsing )); then
        non_flags+=("${arg}")
      fi
      stop_parsing=1
      continue;
    fi

    if [[ "$arg" == -[a-zA-Z0-9]* ]]; then
      local letters="${arg#-}"

      local number=""
      local i=0
      for (( i=0; i < ${#letters}; i++ )); do
        local opt="${letters:$i:1}"

        if [[ $opt == <-> ]]; then
          if [[ $valid_flags_pass_along == *$opt* || "$valid_flags_pass_along" == "all" ]] || { [[ -n "$hidden_flags" || $hidden_flags == *$opt* ]] && [[ -n "$evaluated_flags" ]] }; then
            number+="$opt"
            continue;
          fi
        fi

        if [[ -n "$number" ]] && ! [[ " ${flags[@]} " =~ " -${number} " ]]; then
          flags+=("-${number}")
          number=""
        fi

        if [[ $valid_flags != *$opt* && "$valid_flags_pass_along" != "all" ]] && [[ -z "$hidden_flags" || $hidden_flags != *$opt* || -z "$evaluated_flags" ]]; then
          flags+=("-${opt}")

          if [[ ! " ${invalid_opts[@]} " =~ " -${opt} " ]]; then
            invalid_opts+=("-${opt}")
            echo "invalid_option+=(\"-${opt}\")"

            if (( ! internal_func || ! is_invalid )); then
              print " ${red_cor}fatal: invalid option: -${opt}${reset_cor}" >&2
              print "  --" >&2
              # echo "is_invalid=1"
            else
              # echo "is_invalid=0"
            fi
          fi

          echo "${prefix}_is_h=1"
        elif [[ $valid_flags_pass_along == *$opt* || "$valid_flags_pass_along" == "all" ]]; then
          flags+=("-${opt}")
        fi

        if ! [[ " ${invalid_opts[@]} " =~ " -${opt} " ]]; then
          echo "${prefix}_is_${opt}=1"

          # check if $opt exists in double_flags
          if [[ " ${double_flags[@]} " =~ " $opt " ]]; then
            echo "${prefix}_is_${opt}_${opt}=1"
          fi

          double_flags+=("$opt")
        fi
      done

      if [[ -n "$number" ]] && ! [[ " ${flags[@]} " =~ " -${number} " ]]; then
        flags+=("-${number}")
        number=""
      fi

    elif [[ "$arg" == --* ]]; then
      if [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}_is_debug=1"
      else
        flags_double_dash+=("${arg}")
      fi
    else
      non_flags+=("${arg}")
    fi
  done

  set +x

  if [[ ${#non_flags} -gt 0 ]]; then
    print -r -- set -- "${(q)non_flags[@]}" "${(q)flags[@]}" "${(q)flags_double_dash[@]}"
  else
    print -r -- set -- "${(q)flags[@]}" "${(q)flags_double_dash[@]}"
  fi
}

function parse_simple_flags_() {
  set +x

  if [[ -z "$1" ]]; then
    print " ${red_cor}internal error: parse_simple_flags_ requires a prefix${reset_cor}" >&2
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
          evaluated_flags+="${opt}"
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
        non_flags+=("${arg}")
      fi
      stop_parsing=1
      continue;
    fi

    if [[ "$arg" == -[a-zA-Z]* ]]; then
      local letters="${arg#-}"
      local i=0
      for (( i=0; i < "${#letters}"; i++ )); do
        opt="${letters:$i:1}"

        echo "${prefix}_is_${opt}=1"

        if [[ -n "$valid_flags" ]]; then
          if [[ $valid_flags != *$opt* ]] && [[ -z "$hidden_flags" || $hidden_flags != *$opt* || -z "$evaluated_flags" ]]; then
            print " ${red_cor}fatal: invalid option: -${opt}${reset_cor}" >&2
            print "  --" >&2
            echo "${prefix}_is_h=1"
          fi
        else
          non_flags+=("${arg}")
        fi
      done
    elif [[ "$arg" == "--debug" ]]; then
        echo "is_debug=1"
        echo "${prefix}_is_debug=1"
    else
      non_flags+=("${arg}")
    fi
  done

  print -r -- set -- "${(q)non_flags[@]}"
}

function parse_args_() {
  set +x
  eval "$(parse_flags_all_ "$0" "" "$@")"
  (( parse_args_is_debug )) && set -x

  # generic argument parser for positional arguments
  #
  # types:
  #   a  = array (list of texts)
  #   b  = branch (non-flag string, validated as branch name)
  #   p  = project (non-flag string, validated as project name)
  #   f  = folder (non-flag string, validated as folder path)
  #   r  = remote (non-flag string, validated as remote name)
  #   t  = text (any non-flag string)
  #   n  = number (numeric string)
  #   j  = Jira issue key (validated as JIRA key format)
  #   h  = hash (validated as git hash)
  #
  #     o = for optional: bo, po, fo, ro, so, no
  #     k = for optional, but if a value was passed, it becomes required
  #     z = for default:
  #        nz:20 = use 20 if no value was passed
  #        bz = branch, use current branch
  #        fz = use current folder
  #
  # arguments are matched in order. If an argument looks like a flag (-*)
  # it stops matching positional args. Optional args can be skipped.
  #
  # output: TAB-separated values followed by original_arg_count
  #   value1<TAB>value2<TAB>...<TAB>original_arg_count

  local original_arg_count=""
  local cmd=""
  local spec=""

  if [[ $1 == <-> ]]; then
    original_arg_count="$1"
    cmd="$2"
    spec="$3"
    shift 3
  else
    cmd="$1"
    spec="$2"
    shift 2
  fi

  # replace __EMPTY__ markers with actual empty strings
  local real_args=()
  local _a=""
  for _a in "$@"; do
    if [[ "$_a" == "__EMPTY__" ]]; then
      real_args+=("")
    elif [[ "$_a" != -* ]]; then
      real_args+=("$_a")
    fi
  done
  set -- "${real_args[@]}"

  # count non-flag arguments
  local arg_count=0
  _a=""
  for _a in "$@"; do
    if [[ -z "$_a" || "$_a" != -* ]]; then
      arg_count=$(( arg_count + 1 ))
    else
      break;
    fi
  done

  if [[ -z "$original_arg_count" ]]; then
    original_arg_count="$arg_count"
  fi

  local proj_cmd="${cmd%% *}"

  local has_array=0
  local has_folder=0

  # parse the spec into arrays
  local specs=("${(@s/,/)spec}")

  local names=()
  local types=()
  local sub_types=()
  local is_optionals=()
  local is_maybe_requireds=()
  local default_values=()

  local s=""
  for s in "${specs[@]}"; do
    local name="${s%%:*}"
    local type="${s#*:}"
    local type_char="${type[1]}"
    local type_okz="${type[2]}"

    local is_optional=0
    local is_maybe_required=0
    local default_value=""

    local sub_type="${type#*:}"
    local sub_type_char="${sub_type[1]}"
    local sub_type_okz="${sub_type[2]}"

    if [[ "$type" != *:* ]]; then
      sub_type="";
      sub_type_char="";
      sub_type_okz="";
    fi

    if [[ -n "$type_okz" ]]; then
      if [[ "$type_char" == "f" ]]; then
        has_folder=1

      elif [[ "$type_char" == "a" ]]; then
        has_array=1

        local last_type="${${specs[-1]}#*:}"

        if [[ "$type_char" != "${last_type[1]}" ]]; then
          echo "print \" ${red_cor}fatal: parse_args_ array type must be the last argument in the spec${reset_cor}\" >&2"
          echo "return 1"
          return 1;
        fi

        if [[ -z "$sub_type_char" ]]; then
          echo "print \" ${red_cor}fatal: parse_args_ array type must have a subtype specified after a second colon (e.g. a:t or a:b)${reset_cor}\" >&2"
          echo "return 1"
          return 1;
        fi

        if [[ "$type_okz" == ":" ]]; then
          type_okz="$sub_type_okz"
        fi
      else
        sub_type_char=""
      fi

      if [[ "$type_okz" == "o" ]]; then
        is_optional=1
      elif [[ "$type_okz" == "k" ]]; then
        is_optional=1
        is_maybe_required=1
      elif [[ "$type_okz" == "z" ]]; then
        is_optional=1

        case "$type_char" in
          b)
            default_value="$(get_my_branch_ 2>/dev/null)"
            ;;
          f)
            default_value="$(pwd)"
            ;;
          n)
            default_value="$sub_type"

            if [[ "$name" == "interval" ]]; then
              if [[ -z "$PUMP_INTERVAL" ]]; then
                PUMP_INTERVAL="$(input_number_ -o "type the interval in minutes" "20" 2)"
                if (( $? == 130 )); then return 130; fi
                update_setting_ -f "PUMP_INTERVAL" "$PUMP_INTERVAL"
                echo "PUMP_INTERVAL=$PUMP_INTERVAL"
              fi
              default_value="$PUMP_INTERVAL"
            fi
            ;;
          *)
            default_value="$sub_type"
            ;;
        esac
      fi
    fi

    names+=("$name")
    types+=("$type_char")
    sub_types+=("$sub_type_char")
    is_optionals+=("$is_optional")
    is_maybe_requireds+=("$is_maybe_required")
    default_values+=("$default_value")
  done

  local max_arg="${#names[@]}"

  # allow extra arguments if the last spec is of type 'a' (array)
  local last_type="${types[-1]}"

  if [[ "$last_type" == "a" ]] && (( arg_count > max_arg )); then
    local last_name="${names[-1]}"
    local last_sub_type="${sub_types[-1]}"
    local last_default_value="${default_values[-1]}"
    # if the last type is an array, it can consume all remaining arguments, so add to the list of names and types
    # create a for loop from max_arg to arg_count to add names and types for the remaining arguments
    local j=0
    for (( j = max_arg; j <= arg_count; j++ )); do
      names+=("$last_name")
      types+=(a)
      sub_types+=("$last_sub_type")
      is_optionals+=(1)
      is_maybe_requireds+=(0)
      default_values+=("$last_default_value")
    done

    max_arg="$arg_count"
  fi

  # check if too many arguments (unless last spec is an array type that consumes remaining args)
  if (( arg_count > max_arg )); then
    echo "print \" fatal: too many arguments\" >&2"
    echo "print \" run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage\" >&2"
    echo "return 1"
    return 1;
  fi

  local spec_idx=1

  local values=()
  typeset -A name_values

  parse_args_add_value_() {
    local key=$1
    local value=$2
    local arr_name="name_values_$key"

    # create the array if it doesn't exist
    typeset -ga "$arr_name"

    # append value if not already present
    local _existing=(${(P)arr_name})
    if (( ! ${_existing[(Ie)$value]} )); then
      eval "$arr_name+=(\"\$value\")"
    fi

    # store the array name in the assoc
    name_values[$key]="${arr_name}"
  }

  # match arguments to specs

  local arg_idx=1
  while (( spec_idx <= max_arg )); do
    local name="${names[$spec_idx]}"
    local value="${(P)arg_idx}" # $1, $2, $3 ...
    local type="${types[$spec_idx]}"
    local sub_type="${sub_types[$spec_idx]}"
    local optional="${is_optionals[$spec_idx]}"
    local maybe_required="${is_maybe_requireds[$spec_idx]}"
    local default_value="${default_values[$spec_idx]}"

    # no more positional args available
    if (( arg_idx > $# )) || [[ "${value}" == -* ]]; then
      if (( ! optional )); then
        echo "print \" fatal: $name argument is required\" >&2"
        echo "print \" run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage\" >&2"
        echo "return 1"
        return 1;
      fi

      value="$default_value"
      values+=("$value")
      spec_idx=$(( spec_idx + 1 ))

      parse_args_add_value_ "$name" "$value"
      continue;
    fi

    # validate by type
    local is_valid=1
    local is_usable=1

    local output=""
    output="$(parse_arg_ "$value" "$type" "$sub_type" "$is_default" "$default_value" "$has_array" "$has_folder" "$arg_count" "$max_arg")"
    IFS=$NUL read -r is_valid is_usable value <<< "$output"

    if (( ! is_valid || maybe_required )) && (( ! is_usable )); then
      echo "print \" fatal: not a valid $name argument: $value\" >&2" 
      echo "print \" run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage\" >&2"
      echo "return 1"
      return 1
    fi

    if (( ! is_usable )); then
      # move argument values down the line, so this argument becomes optional and empty
      local empty_args=()

      # print "arg_idx = [$arg_idx]"
      # print "values  = [${#values[@]}]"

      local repeat_count=$(( arg_idx - ${#values[@]} ))

      for ((j = 1; j <= repeat_count; j++)); do
        local nam="${names[$j]}"

        if [[ -n "${name_values[$nam]}" ]]; then
          local _vals=(${(P)name_values[$nam]})

          if [[ -n "$_vals" ]]; then
            local _v=""
            for _v in "${_vals[@]}"; do
              if [[ -n "$_v" ]]; then
                empty_args+=("$_v")
              else
                empty_args+=("__EMPTY__")
              fi
            done
          else
            empty_args+=("__EMPTY__")
          fi
        else
          empty_args+=("__EMPTY__")
        fi
      done
      
      echo "$(parse_args_ "${original_arg_count}" "$cmd" "$spec" "${values[@]}" "${empty_args[@]}" "${@:$arg_idx}")"
      return $?;
    fi

    parse_args_add_value_ "$name" "$value"

    arg_idx=$(( arg_idx + 1 ))
    spec_idx=$(( spec_idx + 1 ))
  done

  # echo every value in name_values
  for name in "${(@k)name_values}"; do
    # if each name has only one value, set it as a scalar, otherwise keep it as an array
    local vals=(${(P)name_values[$name]})

    if (( ${#vals[@]} <= 1 )); then
      echo "${name}=\"${vals[1]}\""
    else
      echo "${name}=(${(j: :)vals[@]})"
    fi
  done

  echo "arg_count=$original_arg_count"
}

function parse_arg_() {
  local value="$1"
  local type="$2"
  local sub_type="$3"
  local is_default="$4"
  local default_value="$5"
  local has_array="$6"
  local has_folder="$7"
  local arg_count="$8"
  local max_arg="$9"

  local is_valid=1
  local is_usable=1

  value="$(trim_ "$value")"

  case "$type" in
    a)
      # array of texts
      if [[ -z "$value" ]]; then
        is_valid=0
      else
        local output=""
        output="$(parse_arg_ "$value" "$sub_type" "" "$is_default" "$default_value" "$has_array" "$has_folder" "$arg_count" "$max_arg")"
        IFS=$NUL read -r is_valid is_usable value <<< "$output"
      fi
      ;;
    b)
      # branch
      if [[ -z "$value" ]]; then
        is_valid=0
        if (( is_default )); then value="$(get_my_branch_ 2>/dev/null)"; fi
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif ! normalize_branch_name_ "$value" &>/dev/null; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      else
        value="$(normalize_branch_name_ "$value" 2>/dev/null)"
      fi
      ;;
    h)
      # git hash
      if [[ -z "$value" ]]; then
        is_valid=0
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif ! [[ $value =~ ^[0-9a-f]{7,40}$ ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    f)
      # folder
      if [[ -z "$value" ]]; then
        is_valid=0
        if (( is_default )); then value="$PWD"; fi
      elif (( has_folder )) && [[ ! -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    j)
      # jira key
      if [[ -z "$value" ]]; then
        is_valid=0
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif ! is_valid_jira_key_ "$value" &>/dev/null; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    n)
      # number
      if [[ -z "$value" ]]; then
        is_valid=0
        if (( is_default )); then value="$default_value"; fi
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    p)
      # project
      if [[ -z "$value" ]]; then
        is_valid=0
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif ! is_project_ "$value" &>/dev/null; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    r)
      # remote
      if [[ -z "$value" ]]; then
        is_valid=0
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      elif [[ "$value" != "origin" && "$value" != "upstream" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
    t)
      # text
      if [[ -z "$value" ]]; then
        is_valid=0
      elif (( has_folder )) && [[ -e "$value" ]]; then
        is_usable=0
        if (( ! has_array && arg_count == max_arg )); then is_valid=0; fi
      fi
      ;;
  esac

  echo "${is_valid}${NUL}${is_usable}${NUL}${value}"
}

function clear_last_line_1_() {
  print -n -- "\033[1A\033[2K" >&1
}

function clear_last_line_2_() {
  print -n -- "\033[1A\033[2K" >&2
}

function clear_last_line_tty_() {
  print -n -- "\033[1A\033[2K" 2>/dev/tty
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
    local cor=""

    if (( confirm_is_a )); then
      flags+=(--timeout=4s)
      cor="${bold_red_cor}"
    fi

    if [[ -n "$default" && "$default" == "$option2" ]]; then
      flags+=(--default=no)
    fi

    # VERY IMPORTANT: 2>/dev/tty to display on VSCode Terminal and on refresh
    gum confirm "${cor}confirm:${reset_cor} $question" \
      --no-show-help \
      --affirmative="$option1" "${flags[@]}" \
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

  _input="$(trim_ $_input)"

  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  if [[ -n "$_input" ]]; then
    print -r -- "$_input"
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
    print -r -- "$_input"
    return 0;
  fi

  return 1;
}

function filter_one_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( filter_one_is_debug )) && set -x

  if [[ -z "${@:2}" ]]; then return 1; fi

  if ! command -v gum &>/dev/null; then
    local flags=()
    if (( filter_one_is_a )); then flags+=(-a); fi
    if (( filter_one_is_i )); then flags+=(-i); fi
    if (( filter_one_is_t )); then flags+=(-t); fi

    choose_one_ "${flags[@]}" "$@"
    return $?;
  fi

  local header="$1"

  if [[ -n "$header" ]]; then
    print " ${purple_cor}choose $header: ${reset_cor}" >&2
  fi

  local flags=()

  if (( filter_one_is_a )); then
    flags+=(--timeout=3s)
  fi

  if (( filter_one_is_i )); then
    flags+=(--select-if-one)
  fi

  local choice=""
  choice="$(gum filter --height="25" --limit=1 --indicator=">" --placeholder=" type to filter" "${flags[@]}" -- "${@:2}")"
  local RET=$?
  if (( RET != 0 )); then return $RET; fi
  
  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  if (( filter_one_is_t )) && [[ -n "$choice" ]]; then
    choice="${choice%%[$'\t ']*}"
    choice="$(trim_ $choice)"
  fi

  print -r -- "$choice"
}

function choose_one_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( choose_one_is_debug )) && set -x

  if [[ -z "${@:2}" ]]; then return 1; fi

  if (( ${#@:2} > 25 )) && command -v gum &>/dev/null; then
    local flags=()
    if (( choose_one_is_a )); then flags+=(-a); fi
    if (( choose_one_is_i )); then flags+=(-i); fi
    if (( choose_one_is_t )); then flags+=(-t); fi

    filter_one_ "${flags[@]}" "$@"
    return $?;
  fi

  local header="$1"

  if command -v gum &>/dev/null; then
    local flags=()

    if (( choose_one_is_a )); then
      flags+=(--timeout=5s)
    fi

    if (( choose_one_is_i )); then
      flags+=(--select-if-one)
    fi

    local choice=""
    choice="$(gum choose --height="25" --limit=1 --header=" choose $header:${reset_cor}" "${flags[@]}" -- "${@:2}" 2>/dev/tty)"
    local RET=$?
    if (( RET != 0 )); then return $RET; fi

    if (( choose_one_is_t )) && [[ -n "$choice" ]]; then
      choice="${choice%%[$'\t ']*}"
      choice="$(trim_ $choice)"
    fi

    print -r -- "$choice"

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
          choice="$(trim_ $choice)"
        fi
        print -r -- "$choice"
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

  if [[ -z "${@:2}" ]]; then return 1; fi

  if ! command -v gum &>/dev/null; then
    local flags=()
    if (( filter_multiple_is_a )); then flags+=(-a); fi
    if (( filter_multiple_is_i )); then flags+=(-i); fi
    if (( filter_multiple_is_t )); then flags+=(-t); fi

    choose_multiple_ "${flags[@]}" "$@"
    return $?;
  fi

  local header="$1"

  if [[ -n "$header" ]]; then
    print " ${purple_cor}choose $header: ${reset_cor}" >&2
  fi

  local flags=()

  if (( filter_multiple_is_a )); then
    flags+=(--timeout=3s)
  fi

  if (( filter_multiple_is_i )); then
    flags+=(--select-if-one)
  fi
  
  local choices
  choices="$(gum filter --height="25" --no-limit --placeholder=" type to filter" "${flags[@]}" -- "${@:2}")"
  local RET=$?
  if (( RET != 0 )); then return $RET; fi
  
  if [[ -n "$header" ]]; then
    clear_last_line_2_
  fi

  local choice=""
  for choice in "${(@f)choices}"; do
    if (( filter_multiple_is_t )) && [[ -n "$choice" ]]; then
      choice="${choice%%[$'\t ']*}"
      choice="$(trim_ $choice)"
    fi
    print -r -- "$choice"
  done
}

function choose_multiple_() {
  set +x
  eval "$(parse_flags_ "$0" "ait" "" "$@")"
  (( choose_multiple_is_debug )) && set -x

  if [[ -z "${@:2}" ]]; then return 1; fi

  local flags=()
  if (( choose_multiple_is_a )); then flags+=(-a); fi
  if (( choose_multiple_is_i )); then flags+=(-i); fi
  if (( choose_multiple_is_t )); then flags+=(-t); fi

  if (( ${#@:2} > 25 )) && command -v gum &>/dev/null; then

    filter_multiple_ "${flags[@]}" "$@"
    return $?
  
  elif (( ${#@:2} == 1 )); then

    choose_one_ "${flags[@]}" "$@"
    return $?
  fi

  local header="$1"

  if command -v gum &>/dev/null; then
    local flags=()

    if (( choose_multiple_is_a )); then
      flags+=(--timeout=3s)
    fi

    if (( choose_multiple_is_i )); then
      flags+=(--select-if-one)
    fi

    local choices
    choices="$(gum choose --height="25" --no-limit --header=" choose multiple $header ${purple_cor}(use spacebar to select)${purple_cor}:${reset_cor}" "${flags[@]}" -- "${@:2}")"
    local RET=$?
    if (( RET != 0 )); then return $RET; fi

    local choice=""
    for choice in "${(@f)choices}"; do
      if (( choose_multiple_is_t )) && [[ -n "$choice" ]]; then
        choice="${choice%%[$'\t ']*}"
        choice="$(trim_ $choice)"
      fi
      print -r -- "$choice"
    done

    # print -r -- "$choices"

    return 0;
  fi

  trap 'print ""; return 130' INT

  local choices=()
  PS3="${purple_cor}choose multiple $header, then choose \"done\" to finish ${choices[*]}${reset_cor}"

  local choice=""
  select choice in "${@:2}" "done"; do
    case $choice in
      "done")
        print -r -- "${choices[@]}"
        return 0;
        ;;
      *)
        if (( choose_multiple_is_t )) && [[ -n "$choice" ]]; then
          choice="${choice%%[$'\t ']*}"
          choice="$(trim_ $choice)"
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

function check_file_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( check_file_is_debug )) && set -x

  local file="$1"

  if ! command -v jq &>/dev/null; then
    print " ${red_cor}error: jq is required to update JSON config${reset_cor}" >&2
    print " install jq: ${hi_yellow_cor}brew install jq${reset_cor} (macOS) or ${hi_yellow_cor}sudo apt-get install jq${reset_cor} (Linux)" >&2
    return 1
  fi

  local file_dir="$(dirname -- "$file")"

  if [[ ! -d "$file_dir" ]]; then
    mkdir -p -- "$file_dir"
  fi

  # validate and fix JSON if needed
  if [[ ! -f "$file" || ! -s "$file" ]]; then
    touch "$file" &>/dev/null
    echo "{}" > "$file"
    # give read & write permissions to the user, read permissions to the group and others
    chmod 644 "$file" &>/dev/null
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

function get_pump_jira_title_() {
  local jira_key="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$jira_key" ]]; then
    return 1;
  fi

  local branch="$(get_my_branch_ "$folder" 2>/dev/null)"
  if [[ -z "$branch" ]]; then return 1; fi

  local pump_jira_key="$(read_pump_value_ "JIRA_KEY" "$folder" "$branch")"

  if [[ -z "$pump_jira_key" || "$pump_jira_key" != "$jira_key" ]]; then
    update_pump_file_ "JIRA_KEY" "$jira_key" "$folder" "$branch"
  fi

  local jira_title="$(read_pump_value_ "JIRA_TITLE" "$folder" "$branch")"

  if [[ -z "$jira_title" ]] || [[ -n "$pump_jira_key" && "$pump_jira_key" != "$jira_key" ]]; then
    if command -v acli &>/dev/null; then
      jira_title="$(acli jira workitem view "$jira_key" --fields=summary --json 2>/dev/null | jq -r '.fields.summary' 2>/dev/null)"

      update_pump_file_ "JIRA_TITLE" "$jira_title" "$folder" "$branch"
    fi
  fi
  
  print -r -- "$jira_title"
}

function read_pump_value_() {
  local key="$1"
  local folder="${2:-$PWD}"
  local branch="$3"

  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local file="${folder}/.pump/${branch}.pump"

  if [[ -f "$file" ]]; then
    print -r -- "$(sed -n "s/^${key}=\\([^ ]*\\)/\\1/p" "$file" 2>/dev/null)"

    # echo $(sed -n 's/^JIRA_KEY[[:space:]]*="\(.*\)"/\1/p' "$file" 2>/dev/null)
  fi
}

function update_pump_file_() {
  local key="$1"
  local value="$2"
  local folder="${3:-$PWD}"
  local branch="$4"

  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local file="${folder}/.pump/${branch}.pump"

  if [[ -f "$file" ]]; then
    local current_value="$(sed -n "s/^${key}=\\([^ ]*\\)/\\1/p" "$file" 2>/dev/null)"

    if [[ "$current_value" == "$value" ]]; then
      return 1;
    fi
  fi

  value="$(trim_ $value)"

  update_file_ "$key" "$value" "$file" &>/dev/null
}

function update_config_json_() {
  local i="$1"
  local key="$2"
  local value="$3"

  if [[ -z "$i" ]]; then
    return 0;
  fi
  
  local array_idx=$((i - 1))  # JSON arrays are 0-indexed
  
  # Check current value
  local current_value="$(jq -r ".projects[$array_idx].$key // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
  if [[ "$current_value" == "null" ]]; then
    current_value=""
  fi
  
  if [[ -n "$value" && "$current_value" == "$value" ]]; then
    return 1;
  fi
  
  # Update the value
  local temp_file="${PUMP_CONFIG_FILE}.tmp"
  
  # Check if value is a number (including 0)
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    # Numeric value - pass directly without quoting
    jq ".projects[$array_idx].$key = $value" "$PUMP_CONFIG_FILE" > "$temp_file" 2>/dev/null
  else
    # String value - use --arg to properly escape
    jq --arg val "$value" ".projects[$array_idx].$key = \$val" "$PUMP_CONFIG_FILE" > "$temp_file" 2>/dev/null
  fi
  
  if (( $? == 0 )); then
    mv "$temp_file" "$PUMP_CONFIG_FILE"
    print " ${gray_cor}updated: ${key}_${i}=${value}${reset_cor}" >&2
    return 0
  else
    rm -f "$temp_file"
    print "  ${hi_yellow_cor}warning: failed to update ${key}_${i} in file${reset_cor}" >&2
    return 1
  fi
}

function update_json_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( update_json_is_debug )) && set -x

  local key="$1"
  local value="$2"
  local file="$3"

  if ! command -v jq &>/dev/null; then
    print " ${red_cor}error: jq is required to update JSON config${reset_cor}" >&2
    print " install jq: ${hi_yellow_cor}brew install jq${reset_cor} (macOS) or ${hi_yellow_cor}sudo apt-get install jq${reset_cor} (Linux)" >&2
    return 1
  fi

  # validate and fix JSON if needed
  if [[ ! -f "$file" || ! -s "$file" ]]; then
    touch "$file" &>/dev/null
    echo "{}" > "$file"
    # give read & write permissions to the user, read permissions to the group and others
    chmod 644 "$file" &>/dev/null
  fi

  value="$(trim_ $value)"

  local temp_file="${file}.tmp"
  
  # use jq to update the value
  if [[ "$value" =~ ^[0-9]+$ ]]; then
    # numeric value
    jq ".$key = $value" "$file" > "$temp_file" 2>/dev/null
  else
    # string value
    jq --arg val "$value" ".$key = \$val" "$file" > "$temp_file" 2>/dev/null
  fi

  if (( $? == 0 )); then
    mv "$temp_file" "$file"
    print " ${gray_cor}updated: ${key}=${value}${reset_cor}" >&2
    return 0
  else
    rm -f -- "$temp_file"
    print "  ${hi_yellow_cor}warning: failed to update ${key} in file${reset_cor}" >&2
    print "   • check if you have write permissions to: $file" >&2
    return 1
  fi
}

function update_file_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( update_file_is_debug )) && set -x

  local key="$1"
  local value="$2"
  local file="$3"

  if [[ ! -f "$file" ]]; then
    local dirname="$(dirname -- "$file")"
    mkdir -p "$dirname" &>/dev/null
    touch "$file"
  fi

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
    print " ${gray_cor}updated: ${key}=${value}${reset_cor}" >&2
  fi
}

function update_setting_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( update_setting_is_debug )) && set -x

  if ! check_file_ "$PUMP_SETTINGS_FILE"; then
    print " ${red_cor}fatal: settings file is invalid, cannot update config: $PUMP_SETTINGS_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local key="$1"
  local value="$2"
  local disclaimer="${3:-0}"

  value="$(trim_ $value)"

  if (( ! update_setting_is_f )) && [[ -n "$value" && "$value" == "${(P)key}" ]]; then
    return 1;
  fi

  eval "${key}=\"$value\""

  if ! update_file_ "$key" "$value" "$PUMP_SETTINGS_FILE"; then
    return 1;
  fi

  if (( disclaimer )) && [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
    print " ${gray_cor}run: ${hi_gray_cor}${CURRENT_PUMP_SHORT_NAME} -u${gray_cor} to reset settings${reset_cor}" >&2
  fi
}

function update_config_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( update_config_is_debug )) && set -x

  if ! check_file_ "$PUMP_CONFIG_FILE"; then
    print " ${red_cor}fatal: config file is invalid, cannot update config: $PUMP_CONFIG_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local i="$1"
  local key="$2"
  local value="$3"
  local disclaimer="${4:-0}"

  value="$(trim_ $value)"

  if [[ "$key" == "PUMP_SHORT_NAME" ]]; then
    update_config_short_name_ $i "$value"
  fi

  local current_key="CURRENT_${key}"

  # set the key variable
  if [[ -n "$CURRENT_PUMP_SHORT_NAME" && -n "${PUMP_SHORT_NAME[$i]}" && "$CURRENT_PUMP_SHORT_NAME" == "${PUMP_SHORT_NAME[$i]}" ]]; then
    if [[ "$value" != "${(P)current_key}" ]]; then
      if [[ -z "$value" ]]; then
        eval "${current_key}=\"${${(P)key}[0]}\""
      else
        eval "${current_key}=\"$value\""
      fi
    fi
  fi

  # # # Check if "$value" is not equal to the current value 
  if [[ "$value" == "${${(P)key}[$i]}" ]]; then
    if [[ -n "$value" ]]; then return 1; fi
  fi

  eval "${key}[$i]=\"$value\""

  if ! update_file_ "${key}_${i}" "$value" "$PUMP_CONFIG_FILE"; then
    return 1;
  fi

  if (( disclaimer )) && [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
    print " ${gray_cor}run: ${hi_gray_cor}${PUMP_SHORT_NAME[$i]} -u${gray_cor} to reset config${reset_cor}" >&2
  fi
}

function update_repo_() {
  set +x
  eval "$(parse_flags_ "$0" "au" "" "$@")"
  (( update_repo_is_debug )) && set -x

  local proj_repo="$1"
  local folder="${2:-$PWD}"

  if is_folder_git_ "$folder" &>/dev/null; then
    if (( ! update_repo_is_u )); then
      return 0;
    fi

    local remote=$(get_remote_name_ "$folder")
    local current_repo="$(git -C "$folder" remote get-url $remote 2>/dev/null)"

    # only update if is different
    if [[ "$current_repo" != "$proj_repo" ]]; then
      git -C "$folder" remote set-url $remote "$proj_repo" 2>/dev/null || {
        print " ${red_cor}failed to update remote $remote${reset_cor}" >&2
        return 1
      }
    fi

  elif [[ -d "$folder" ]]; then
    if (( ! update_repo_is_a )); then
      return 0;
    fi

    # init repo
    git -C "$folder" init 2>/dev/null || {
      print " ${red_cor}failed to initialize git repository${reset_cor}" >&2
      return 1
    }

    # add remote origin
    git -C "$folder" remote add origin "$proj_repo" 2>/dev/null || {
      print " ${red_cor}failed to add remote origin${reset_cor}" >&2
      return 1
    }
  fi
}

function update_proj_repo_() {
  local proj_repo="$1"
  local proj_folder="$2"
  local single_mode="$3"

  if (( single_mode )); then
    # add and update
    update_repo_ -au "$proj_repo" "$proj_folder"
  else
    local folders=($(find "$proj_folder" -mindepth 1 -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null))

    local folder=""
    for folder in "${folders[@]}"; do
      # update only
      update_repo_ -u "$proj_repo" "$folder"
    done
  fi
}

function normalize_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( normalize_branch_name_is_debug )) && set -x

  local branch="$1"
  local cor="$2"

  if [[ -z "$branch" ]]; then
    print " ${cor}fatal: branch name cannot be empty${reset_cor}" >&2
    return 1;
  fi

  local normalized_branch="$(git check-ref-format --normalize "$branch" 2>/dev/null)"

  if [[ -n "$normalized_branch" ]]; then
    branch="$normalized_branch"
  fi

  # doesn't require -C "$folder" because it only checks the format
  if ! git check-ref-format --branch "$branch" &>/dev/null; then
    print " ${cor}fatal: invalid branch name: $(truncate_ $branch)${reset_cor}" >&2
    return 1;
  fi

  echo "$branch"
}

function input_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( input_branch_name_is_debug )) && set -x

  local header="$1"

  while true; do
    local typed_value=""
    typed_value="$(input_type_ "$header" "" 200)"
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$typed_value" ]]; then
      typed_value="$(normalize_branch_name_ "$typed_value" "${red_cor}")"
      
      if [[ -n "$typed_value" ]]; then
        print -r -- "$typed_value"
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
        print -r -- "$typed_value"
        return 0;
      fi
    fi
  done

  return 1;
}

function input_type_mandatory_() {
  set +x
  eval "$(parse_flags_ "$0" "kmox" "" "$@")"
  (( input_type_mandatory_is_debug )) && set -x

  local header="$1"
  local placeholder="$2"
  local max="${3:-255}"
  local value="$4"
  local cor="$5"

  while true; do
    if [[ -n "$placeholder" && "${#placeholder}" -gt "$max" ]]; then
      placeholder="${placeholder:0:$max}"
    fi
    if [[ -n "$value" && "${#value}" -gt "$max" ]]; then
      value="${value:0:$max}"
    fi

    local typed_value=""
    typed_value="$(input_type_ "$header" "$placeholder" "$max" "$value")"
    local RET=$?

    if (( input_type_mandatory_is_o )) && [[ -z "$typed_value" && -n "$placeholder" ]]; then
      typed_value="$placeholder"
    fi

    if (( RET == 130 || RET == 2 )); then
      print -r -- "$typed_value"
      return 130;
    fi
    
    if (( ! input_type_mandatory_is_k )) && [[ -z "$typed_value" && -n "$placeholder" ]] && command -v gum &>/dev/null; then
      print -r -- "$placeholder"
      return 0;
    fi

    if [[ -n "$typed_value" ]]; then
      if (( input_type_mandatory_is_x )) && [[ "$typed_value" == "$value" ]]; then
        continue;
      fi
      if (( input_type_mandatory_is_m )) && [[ ! "$typed_value" =~ ^[a-zA-Z]{1,2}$ ]]; then
        print " ${cor}value must be 1-2 characters and contain letters only${reset_cor}" >&2
        continue;
      fi
      print -r -- "$typed_value"
      return 0;
    fi
  done

  return 1;
}

function input_number_() {
  set +x
  eval "$(parse_flags_ "$0" "" "ko" "$@")"
  (( input_number_is_debug )) && set -x

  local header=""
  local placeholder=""
  local max=""

  eval "$(parse_args_ "$0" "header:to,placeholder:to,max:nz:3" "$@")"
  shift $arg_count

  local typed_value=""
  typed_value="$(input_type_mandatory_ "$header" "$placeholder" "$max" "" "$@")"
  local RET=$?
  
  # if [[ -z "$typed_value" && -n "$placeholder" ]] && command -v gum &>/dev/null; then
  #   typed_value="$placeholder"
  # fi

  if [[ -n "$typed_value" && $typed_value == <-> ]]; then
    print -r -- "$typed_value"
  fi
  
  return $RET;
}

function find_proj_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "e" "" "$@")"
  (( find_proj_folder_is_debug )) && set -x

  local i="$1"
  local header="$2"
  local proj_cmd="$3"

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

      if [[ -n "$proj_cmd" ]]; then
        new_folder="${folder_path}/${proj_cmd}"
      else
        new_folder="$folder_path"
      fi

      local new_folder_a="${new_folder:A}"

      if [[ -d "$folder_path" ]]; then
        local j=0 found=0
        for j in {1..10}; do
          if [[ $j -ne $i && -n "${PUMP_FOLDER[$j]}" && -n "${PUMP_SHORT_NAME[$j]}" ]]; then
            local folder_a="${PUMP_FOLDER[$j]:A}"

            if [[ "$new_folder_a" == "$folder_a" ]]; then
              found=$j
              print "  ${hi_yellow_cor}folder in use by another project, select another folder${reset_cor}" >&2
              cd "$HOME"
            fi
          fi
        done

        if (( found == 0 )); then
          if (( find_proj_folder_is_e )); then
            if is_folder_pkg_ "$new_folder_a" &>/dev/null || is_folder_git_ "$new_folder_a" &>/dev/null; then
              RET=0
            elif [[ "${new_folder_a:t}" == "Developer" ]]; then
              RET=1
            else
              confirm_ "set project folder to: ${blue_cor}$new_folder_a${reset_cor} or continue to browse?" "set folder" "browse"
              RET=$?
              if (( RET == 130 || RET == 2 )); then break; fi
            fi
          else
            confirm_ "set project folder to: ${blue_cor}$new_folder_a${reset_cor} or continue to browse?" "set folder" "browse"
            RET=$?
            if (( RET == 130 || RET == 2 )); then break; fi
          fi

          if (( RET == 1 )); then
            cd "$folder_path"
          else
            chosen_folder="$folder_path"
            break;
          fi
        fi
      fi
    fi
    
    local folders=(*(N/^D))
    local qty_folders="${#folders[@]}"

    if (( ! qty_folders )); then
      cd "${HOME:-/}"
    fi

    rm -rf -- ".DS_Store" &>/dev/null

    chose_folder="$(gum file --directory)" # --height="$qty_folders"
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

  # clear_last_line_2_
  # clear_last_line_2_
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
  local placeholder="$1"

  local typed_value=""

  if command -v gh &>/dev/null; then
    ############################################
    # VERY IMPORTANT to display the prompt: >&2
    ############################################
    confirm_ "is there a git repository for this project somewhere?"
    local RET=$?
    if (( RET == 1 )); then return 1; fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      typed_value="$(input_type_ "type the git repository uri (ssh or https) or Github owner account (username or organization)" "" 50)"
      if (( $? == 130 || $? == 2 )); then return 130; fi

      if [[ -n "$typed_value" ]]; then
        # check if gh_owner is a valid git repository uri
        if ! validate_repo_ "$typed_value"; then
          local gh_owner="$typed_value"
          local list_repos=""

          if command -v gum &>/dev/null; then
            list_repos="$(gum spin --title="getting repositories..." -- gh repo list $gh_owner --source --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' | sort -f)"
          else
            list_repos="$(gh repo list $gh_owner --source --limit 1000 --json nameWithOwner -q '.[].nameWithOwner' | sort -f 2>/dev/null)"
          fi

          if (( $? == 0 )); then
            local selected_repo=""
            selected_repo="$(choose_one_ "repository" "${(@f)list_repos}")"
            # if (( $? == 130 || $? == 2 )); then return 130; fi
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
  fi

  while true; do
    if [[ -z "$typed_value" ]] || ! validate_repo_ "$typed_value"; then
      typed_value="$(input_type_ "type the git repository uri (ssh or https)" "$placeholder")"
      if (( $? == 130 || $? == 2 )); then return 130; fi
    fi

    if [[ -z "$typed_value" ]]; then
      if [[ -n "$placeholder" ]] && command -v gum &>/dev/null; then
        typed_value="$placeholder"
      fi
    fi

    if [[ -n "$typed_value" ]]; then
      if validate_repo_ "$typed_value"; then
        print -r -- "$typed_value"
        return 0;
      fi
    else
      # it's okay if repository is left empty because the project may not have a git repository yet
      print -r -- "$typed_value"
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
  local color="$2"
  local total_width=${3:-70}
  local word_color="$4"

  if [[ -z "$color" ]]; then
    color="${gray_cor}"
  fi

  if [[ -z "$word_color" ]]; then
    word_color="$color"
  fi

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

  sanitized="$(trim_ $sanitized)"

  echo "$sanitized"
}

# data checkers =========================================================
function check_gh_() {
  if ! command -v gh &>/dev/null; then
    print " fatal: command requires gh" >&2
    print " install gh: ${blue_cor}https://github.com/cli/cli/${reset_cor}" >&2
    return 1;
  fi

  if ! gh auth status &>/dev/null; then
    print " fatal: gh is not authenticated, run: ${hi_yellow_cor}gh auth login${reset_cor}" >&2
    return 1;
  fi
}

function check_gum_() {
  if ! command -v gum &>/dev/null; then
    print " fatal: command requires gum" >&2
    print " install gum: ${blue_cor}https://github.com/charmbracelet/gum/${reset_cor}" >&2
    return 1;
  fi
}

function check_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "fmeprg" "qv" "$@")"
  # (( check_proj_is_debug )) && set -x

  local i="$1"

  if [[ -z "$i" ]]; then
    print " fatal: project index is required" >&2
    return 1;
  fi

  if [[ -z "${PUMP_SHORT_NAME[$i]}" ]]; then
    print " fatal: project index does not exist: $i" >&2
    return 1;
  fi

  shift

  if (( check_proj_is_f )); then
    if ! check_proj_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "${PUMP_REPO[$i]}" "$@"; then return 1; fi

    if [[ -z "${PUMP_FOLDER[$i]}" || ! -d "${PUMP_FOLDER[$i]}" ]]; then
      if (( ! check_proj_is_q )); then
        print " ${red_cor}project folder is missing for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
        print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      fi
      return 1;
    fi
  fi

  if (( check_proj_is_e )); then
    if ! check_proj_script_folder_ -s $i "${PUMP_FOLDER[$i]}" "${PUMP_SCRIPT_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "$@"; then return 1; fi
  fi

  if (( check_proj_is_m )); then
    if ! save_proj_mode_ -q $i "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}" "$@"; then return 1; fi
  fi

  if (( check_proj_is_p )); then
    if ! check_proj_pkg_manager_ -sq $i "${PUMP_PKG_MANAGER[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_REPO[$i]}" "$@"; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_PKG_MANAGER[$i]}" ]]; then
      print " ${red_cor}missing package manager for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_r )); then
    if ! check_proj_repo_ -sq $i "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}" "${PUMP_SHORT_NAME[$i]}" "${PUMP_SINGLE_MODE[$i]}" "$@"; then return 1; fi

    if (( ! check_proj_is_q )) && [[ -z "${PUMP_REPO[$i]}" ]]; then
      print " ${red_cor}missing repository uri for ${PUMP_SHORT_NAME[$i]}${reset_cor}" >&2
      print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} -e${reset_cor} to edit project" >&2
      return 1;
    fi
  fi

  if (( check_proj_is_g )); then
    if [[ -z "${PUMP_PR_APPROVAL_MIN[$i]}" ]]; then
      local pr_approval_min=""
      pr_approval_min="$(input_number_ "minimum number of approvals for pull requests" "2" 1)"
      if (( $? == 130 )); then return 130; fi

      update_config_ $i "PUMP_PR_APPROVAL_MIN" "$pr_approval_min"
      PUMP_PR_APPROVAL_MIN[$i]="$pr_approval_min"
    fi
  fi
}

function select_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( select_jira_status_is_debug )) && set -x

  local i="$1"
  local header="$2"
  local default_status="$3"

  local jira_statuses="$(check_jira_statuses_ $i)"
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

  print -r -- "$chosen_status"
}

function select_multiple_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( select_multiple_jira_status_is_debug )) && set -x

  local i="$1"
  local header="$2"

  local jira_statuses="$(check_jira_statuses_ $i)"
  if [[ -z "$jira_statuses" ]]; then return 1; fi

  local chosen_statuses=()
  chosen_statuses=($(choose_multiple_ "statuses $header" "${(@f)jira_statuses}"))
  if (( $? == 130 )); then return 130; fi

  print -r -- "${chosen_statuses[@]}"
}

function get_jira_board_() {
  set +x
  eval "$(parse_flags_ "$0" "c" "" "$@")"
  (( get_jira_board_is_debug )) && set -x

  local i="$1"
  local jira_proj="${2:-$PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${3:-$PUMP_JIRA_API_TOKEN[$i]}"

  local current_jira_user_email="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"
  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local jira_boards="$(gum spin --title="pulling boards..." -- curl -s \
    -u "$current_jira_user_email:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/agile/1.0/board?projectKeyOrId=${jira_proj}" \
    | jq -r '.values[] | "\(.id)\t\(.type)\t\(.name)"'
  )"

  if [[ -z "$jira_boards" ]]; then
    print " no boards found for project: ${jira_proj}" >&2
    return 1;
  fi

  # if (( get_jira_board_is_c )); then
  #   # get the current board
  #   local current_board_id="$(gum spin --title="preparing jira..." -- curl -s \
  #     -u "$current_jira_user_email:$jira_api_token" \
  #     -H "Accept: application/json" \
  #     "https://${jira_base_url}/rest/agile/1.0/board?projectKeyOrId=${jira_proj}&filter=active&maxResults=1" \
  #     | jq -r '.values[0].id // empty')"

  #   print -r -- "$current_board_id"

  #   return;
  # fi

  local boards=("${(@f)$(echo "$jira_boards" | cut -f3)}")
  local board_name=""
  board_name="$(choose_one_ "jira board" "${boards[@]}")"
  if (( $? == 130 )); then return 130; fi

  if [[ -z "$board_name" ]]; then return 1; fi

  local board_id="$(echo "$jira_boards" | awk -v name="$board_name" -F'\t' '$3 == name {print $1}' | xargs 2>/dev/null)"

  echo "$board_id"
}

function select_jira_proj_() {
  local i="$1"
  local proj_cmd="${2:-$PUMP_SHORT_NAME[$i]}"
  local jira_proj="$3"

  if ! command -v acli &>/dev/null; then
    if [[ -z "$jira_proj" ]]; then
      jira_proj="${proj_cmd:u}"
    fi
    echo "$jira_proj"
    return 0;
  fi

  local output="$(gum spin --title="pulling projects..." -- acli jira project list --recent --json | jq -r '.[].key')"
  local projects=("${(@f)output}")

  if [[ -z "$projects" ]]; then
    if [[ -z "$jira_proj" ]]; then
      jira_proj="${proj_cmd:u}"
    fi
    echo "$jira_proj"
    return 0;
  fi

  #see if jira_proj is in projects
  if [[ -n "$jira_proj" ]]; then
    local proj=""
    for proj in "${projects[@]}"; do
      if [[ "${proj:u}" == "${jira_proj:u}" ]]; then
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

function get_work_types_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  (( get_work_types_is_debug )) && set -x

  local i="$1"

  local pump_jira_work_types=""
  
  if (( ! get_work_types_is_d )); then
    pump_jira_work_types="${PUMP_JIRA_WORK_TYPES[$i]}"
  fi

  if [[ -z "$pump_jira_work_types" ]]; then
    pump_jira_work_types="bug chore story"
  fi

  local wt=""
  for wt in "${(z)pump_jira_work_types}"; do
    print -r -- "${wt:l}"
  done
}

function check_work_types_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "" "$@")"
  (( check_work_types_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local work_types="$3"

  local default_jira_work_types=($(get_work_types_ -d $i))
  local new_work_types=()

  local is_add=1

  if [[ -n "$work_types" && "${PUMP_JIRA_PROJECT[$i]}" == "$jira_proj" ]]; then
    new_work_types=(${(z)work_types})

    if (( check_work_types_is_s )); then
      is_add=0
    fi

  elif [[ -n "$jira_proj" ]] && (( check_work_types_is_s )) && command -v acli &>/dev/null; then
    local jira_work_types="$(gum spin --title="pulling work types..." -- acli jira workitem search --jql "project=\"$jira_proj\"" --fields=issuetype --json | jq -r '.[].fields.issuetype.name' | sort -u)"
    new_work_types=("${(@f)jira_work_types}")
  fi

  if (( is_add )); then
    local wt=""
    for wt in "${default_jira_work_types[@]}"; do
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

  local new_work_types_str="$(echo "${${new_work_types[*]}:l}" | xargs | sort -u)"

  if (( check_work_types_is_s )); then
    update_config_ $i "PUMP_JIRA_WORK_TYPES" "$new_work_types_str"
    PUMP_JIRA_WORK_TYPES[$i]="$new_work_types_str"
  fi
}

function select_jira_release_() {
  set +x
  eval "$(parse_flags_ "$0" "" "r" "$@")"
  (( select_jira_release_is_debug )) && set -x

  select_jira_releases_ -1 "$@"
}

function select_jira_releases_() {
  set +x
  eval "$(parse_flags_ "$0" "1r" "" "$@")"
  (( select_jira_releases_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local search_term="$3"
  local jira_api_token="$4"

  if [[ -z "$jira_proj" ]]; then
    jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  fi

  if [[ -z "$jira_api_token" ]]; then
    jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"
  fi

  local select=".archived == false"

  if (( select_jira_releases_is_r )); then
    select+=" and .released == true"
  else
    select+=" and .released == false"
  fi

  local current_jira_user_email="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"
  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local jira_releases="$(gum spin --title="pulling releases..." -- curl -s \
    -u "$current_jira_user_email:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/api/3/project/${jira_proj}/versions" \
    | jq -r --arg search "$search_term" "map(select($select and (.name | test(\$search; \"i\")))) 
        | sort_by(.releaseDate // \"9999-12-31\", .name)
        | .[].name"
  )"

  if [[ -z "$jira_releases" ]]; then
    print " no unreleased releases found in jira project: $jira_proj" >&2
    return 1;
  fi

  if (( select_jira_releases_is_1 )); then
    local release=""
    release="$(choose_one_ "jira release" "${(@f)jira_releases}")"
    if (( $? == 130 )); then return 130; fi

    echo "$release"
    return 0;
  fi

  local releases=""
  releases="$(choose_multiple_ "jira releases" "${(@f)jira_releases}")"
  if (( $? == 130 )); then return 130; fi

  echo "${branch_choices[@]}"
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
    if save_proj_cmd_ $i "${old_proj_cmd:-$proj_cmd}" "$old_proj_cmd" "${@:4}"; then
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
  local single_mode="$5"

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
        if command -v gum &>/dev/null; then
          # so that the spinner can display, add to the end: 2>/dev/tty
          gum spin --title="checking repository uri..." -- git -C "/" ls-remote "$proj_repo" --quiet --exit-code 2>/dev/tty
        else
          print " checking repository uri..." >&2
          git -C "/" ls-remote "${proj_repo}" --quiet --exit-code
        fi

        if (( $? != 0 )); then
          error_msg="projet repository uri is invalid or no access rights: $proj_repo"
          error_msg+="\n  • check if the uri is valid"
          error_msg+="\n  • check if you have access rights to the repository"
          error_msg+="\n  • check if the repository is private and you have set up SSH keys or access tokens"
          error_msg+="\n  • wait a moment and try again"
        fi
      fi
    fi
  fi

  if [[ -n "$error_msg" ]]; then
    if (( ! check_proj_repo_is_q )); then
      print " ${red_cor}${error_msg}${reset_cor}" >&2
    fi

    if (( check_proj_repo_is_s )); then
      save_proj_repo_ $i "$proj_folder" "$pkg_name" "" "$single_mode" "${@:6}"
      local RET=$?
      if (( RET == 130 )); then return 130; fi
      if (( RET == 0 )); then return 0; fi
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
          error_msg="in use, please select another folder"
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
      print " ${red_cor}${error_msg}${reset_cor}" >&2
    fi

    if (( check_proj_folder_is_s )); then
      save_proj_folder_ $i "$proj_cmd" "$proj_repo" "" "${@:5}"
      local RET=$?
      if (( RET == 130 )); then return 130; fi
      if (( RET == 0 )); then return 0; fi
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
        print " ${red_cor}script folder is invalid: $proj_script_folder${reset_cor}" >&2
        is_error=1
      fi
    fi
  fi

  if (( is_error )); then
    if (( check_proj_script_folder_is_s )); then
      if save_proj_script_folder_ $i "$proj_folder" "$proj_cmd" "${@:5}"; then return 0; fi
    fi
    return 1;
  fi
}

function check_proj_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "q" "$@")"
  (( check_proj_pkg_manager_is_debug )) && set -x

  local i="$1"
  local pkg_manager="$2"
  local proj_folder="$3"
  local proj_repo="$4"

  local is_error=0

  if [[ -z "$pkg_manager" ]]; then
    is_error=1
  else
    local valid_pkg_managers=("npm" "yarn" "pnpm" "bun")

    if ! [[ " ${valid_pkg_managers[@]} " =~ " $pkg_manager " ]]; then
      is_error=1
    fi
  fi

  if (( is_error )); then
    if (( check_proj_pkg_manager_is_s )); then
      if save_pkg_manager_ $i "$proj_folder" "$proj_repo" "${@:5}"; then return 0; fi
    fi
    return 1;
  fi

  return 0;
}
# end of data checkers

function choose_mode_() {
  local current_mode="$1"
  local proj_folder="$2"

  if [[ -n "$proj_folder" ]] && command -v gum &>/dev/null; then
    local parent_folder_name="$(basename -- "$(dirname -- "$proj_folder")")"
    parent_folder_name="${parent_folder_name[1,46]}"

    local folder_name="$(basename -- "$proj_folder")"
    folder_name="${folder_name[1,46]}"

    local multiple_title="$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 212 "multiple mode")"
    local single_title="$(gum style --align=center --margin="0" --padding="0" --border=none --width=30 --foreground 99 "single mode")"

    local titles="$(gum join --align=center --horizontal "$multiple_title" "$single_title")"

    local multiple=$'  '/"$(truncate_ $parent_folder_name 22)"'
   └─ '/"$(truncate_ $folder_name 18)"'
      ├─ /main
      ├─ /feature-1
      └─ /feature-2'

    local single=$'  '/"$(truncate_ $parent_folder_name 22)"'
   └─ '/"$(truncate_ $folder_name 18)"'


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

  echo "$RET"
}

function get_proj_special_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "brctsd" "" "$@")"
  (( get_proj_special_folder_is_debug )) && set -x

  local proj_cmd="$1"
  local proj_folder="$2"

  if [[ -z "$proj_cmd" || -z "$proj_folder" ]]; then
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

  local folder=""

  if (( get_proj_special_folder_is_t && ! get_proj_special_folder_is_d )); then
    folder="${parent_folder}/${category}/${proj_cmd}/$(date +%Y%m%d-%H%M%S)"
  else
    folder="${parent_folder}/${category}/${proj_cmd}"
  fi

  if (( ! get_proj_special_folder_is_d )); then
    mkdir -p -- "$folder" &>/dev/null
  fi

  echo "$folder"
}

function get_pkg_field_online_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_pkg_field_online_is_debug )) && set -x

  local field="$1"
  local branch="$2"
  local repo="$3"
  local folder="${4:-$PWD}"

  if [[ -z "$field" ]]; then
    print " fatal: get_pkg_field_online_ missing field argument" >&2
    return 1;
  fi

  if ! check_gh_; then return 1; fi

  if [[ -z "$repo" && -n "$folder" ]]; then
    folder="$(find_git_folder_ "$folder" 2>/dev/null)"
    repo="$(get_repo_ "$folder" 2>/dev/null)"
  fi
  if [[ -z "$repo" ]]; then return 1; fi

  local repo_name="$(get_repo_name_ "$repo")"

  local url="repos/${repo_name}/contents"
  local package_json=""

  if [[ -n "$branch" ]]; then
    package_json="$(gh api ${url}/package.json\?ref=$branch 2>/dev/null)"
  else
    package_json="$(gh api ${url}/package.json 2>/dev/null)"
  fi

  if [[ -n "$package_json" ]]; then
    local pkg_name=""
    local package_json_url="$(printf "%s" "$package_json" | jq -r '.download_url // empty')"

    if command -v jq &>/dev/null; then
      pkg_name="$(curl -fs "$package_json_url" 2>/dev/null | jq -r --arg key "$field" '.[$key] // empty')"
    else
      pkg_name="$(curl -fs "$package_json_url" 2>/dev/null | grep -E '"'$field'"\s*:\s*"' | head -1 | sed -E "s/.*\"$field\": *\"([^\"]+)\".*/\1/")"
    fi

    if [[ -n "$pkg_name" ]]; then
      echo "$pkg_name"
      return 0;
    fi
  fi

  return 1;
}

function detect_pkg_manager_online_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( detect_pkg_manager_online_is_debug )) && set -x

  local branch="$1"
  local repo="$2"
  local folder="${3:-$PWD}"

  if ! check_gh_ &>/dev/null; then return 1; fi

  folder="$(find_pkg_folder_ "$folder" 2>/dev/null)"

  if [[ -z "$repo" ]]; then
    repo="$(get_repo_ "$folder" 2>/dev/null)"
  fi
  if [[ -z "$repo" ]]; then return 1; fi

  local repo_name="$(get_repo_name_ "$repo")"

  local manager=""

  local url="repos/${repo_name}/contents"
  local package_json=""

  if [[ -n "$branch" ]]; then
    package_json="$(gh api ${url}/package.json\?ref=$branch 2>/dev/null)"
  else
    package_json="$(gh api ${url}/package.json 2>/dev/null)"
  fi

  if [[ -n "$package_json" ]]; then
    local package_json_url="$(printf "%s" "$package_json" | jq -r '.download_url // empty')"

    if command -v jq &>/dev/null; then
      manager="$(curl -fs "$package_json" 2>/dev/null | jq -r '.packageManager // empty')"
    else
      manager="$(curl -fs "$package_json" 2>/dev/null | grep -E '"'packageManager'"\s*:\s*"' | head -1 | sed -E "s/.*\"packageManager\": *\"([^\"]+)\".*/\1/")"
    fi

    if [[ -n "$manager" ]]; then
      manager="${manager%%@*}"
      echo "$manager"
      return 0;
    fi

    if [[ -n "$branch" ]]; then
      if gh api $url/yarn.lock?ref=$branch --silent &>/dev/null; then
        manager="yarn"
      elif gh api $url/pnpm-lock.yaml?ref=$branch --silent &>/dev/null; then
        manager="pnpm"
      elif gh api $url/bun.lockb?ref=$branch --silent &>/dev/null; then
        manager="bun"
      elif gh api $url/package-lock.json?ref=$branch --silent &>/dev/null; then
        manager="npm"
      fi
    else
      if gh api $url/yarn.lock --silent &>/dev/null; then
        manager="yarn"
      elif gh api $url/pnpm-lock.yaml --silent &>/dev/null; then
        manager="pnpm"
      elif gh api $url/bun.lockb --silent &>/dev/null; then
        manager="bun"
      elif gh api $url/package-lock.json --silent &>/dev/null; then
        manager="npm"
      fi
    fi
  fi

  if [[ -n "$manager" ]]; then
    echo "$manager"
    return 0;
  fi

  return 1;
}

function detect_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( detect_pkg_manager_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local repo="$2"

  local manager=""

  local line="$(get_from_package_json_ "packageManager" "$folder" 2>/dev/null)"
  
  if [[ -n "$line" ]]; then
    if [[ $line =~ ([^\"]+) ]]; then
      manager="${${match[1]%%@*}:l}"
    else
      manager="${line%%@*}"
      manager="${manager//[\", ]/}"
      manager="${manager:l}"
    fi
  fi

  if [[ -z "$manager" ]]; then
    if [[ -f "${folder}/yarn.lock" ]]; then
      manager="yarn"
    elif [[ -f "${folder}/pnpm-lock.yaml" ]]; then
      manager="pnpm"
    elif [[ -f "${folder}/bun.lockb" ]]; then
      manager="bun"
    elif [[ -f "${folder}/package-lock.json" ]]; then
      manager="npm"
    fi
  fi

  if [[ -n "$repo" ]]; then
    manager="$(detect_pkg_manager_online_ "" "$repo" "$folder" 2>/dev/null)"
  fi

  if [[ -z "$manager" ]]; then
    if command -v yarn &>/dev/null; then
      manager="yarn"
    elif command -v pnpm &>/dev/null; then
      manager="pnpm"
    elif command -v bun &>/dev/null; then
      manager="bun"
    elif command -v npm &>/dev/null; then
      manager="npm"
    fi
  fi

  echo "$manager"
}

function save_proj_cmd_() {
  set +x
  eval "$(parse_flags_ "$0" "fae" "" "$@")"
  (( save_proj_cmd_is_debug )) && set -x

  local i="$1"
  local pkg_name="$2"
  local old_proj_cmd="$3"

  while true; do
    local typed_proj_cmd=""
    typed_proj_cmd="$(input_type_mandatory_ "type your project name" "$pkg_name" 13 "$pkg_name" 2>/dev/tty)"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$typed_proj_cmd" ]]; then return 1; fi
    
    if check_proj_cmd_ $i "$typed_proj_cmd" "$old_proj_cmd"; then
      break;
    fi
  done

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
  elif find_git_folder_ "$proj_folder" &>/dev/null || find_pkg_folder_ "$proj_folder" &>/dev/null; then
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
      PUMP_SINGLE_MODE[$i]="$single_mode"
    fi
    return 0;
  fi

  TEMP_PUMP_SINGLE_MODE="$single_mode"
  
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
      proj_script_folder="$(get_proj_special_folder_ -s "$proj_cmd" "$proj_folder")"
    fi
  fi

  if [[ -n "$proj_script_folder" ]]; then
    if ! check_proj_script_folder_ $i "$proj_folder" "$proj_script_folder" "$proj_cmd" "${@:4}"; then
      return 1;
    fi
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

  while true; do
    local folder_exists=0

    if (( save_proj_folder_is_a )); then
      if [[ -n "$proj_folder" && "$proj_folder" == "${PUMP_FOLDER[$i]}" ]]; then
        return 0;
      fi

      if { is_folder_pkg_ &>/dev/null || is_folder_git_ &>/dev/null; } && ! find_proj_by_folder_ &>/dev/null; then
        # ask to use pwd
        confirm_ "set project folder to: ${blue_cor}$PWD${reset_cor}?"
        RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 0 )); then
          proj_folder="$PWD"
        fi
      fi
    fi

    local RET=0

    if (( save_proj_folder_is_e )) && [[ -n "$proj_folder" ]]; then
      confirm_ "keep using project folder: ${blue_cor}${proj_folder}${reset_cor}?"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then
        proj_folder=""
        folder_exists=1
      fi
    fi

    if (( count == 0 )) && [[ -z "$proj_folder" ]]; then
      confirm_ "create a new folder or use an existing one?" "create new folder" "use existing folder"
      RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 0 )); then
        return 0;
      fi
      if (( RET == 1 )); then
        confirm_ "set project folder to: ${blue_cor}$PWD${reset_cor} or continue to browse?" "set folder" "browse"
        RET=$?
        if (( RET == 130 || RET == 2 )); then return 130; fi
        if (( RET == 0 )); then
          proj_folder="$PWD"
        fi
        if (( RET == 1 )); then
          folder_exists=1
        fi
      fi
    fi

    if [[ -z "$proj_folder" ]]; then
      if [[ -n "$proj_repo" ]]; then
        local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
        
        proj_cmd="$(sanitize_pkg_name_ "${repo_name:t}")"
      fi

      if (( folder_exists )); then
        proj_folder="$(find_proj_folder_ -e $i "select an existing project folder")"
      else
        proj_folder="$(find_proj_folder_ $i "choose the parent folder where the project folder will exist" "$proj_cmd")"
      fi

      if [[ -z "$proj_folder" ]]; then return 1; fi

      if (( ! folder_exists )); then
        proj_folder="${proj_folder}/${proj_cmd}"
      fi

      if check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo"; then
        break;
      else
        proj_folder=""
      fi
    else
      if check_proj_folder_ $i "$proj_folder" "$proj_cmd" "$proj_repo" "${@:6}"; then
        break;
      else
        proj_folder=""
      fi
    fi
  done

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
  local single_mode="$5"
  local count="${6:-0}"

  if (( count )); then
    return 0;
  fi

  if [[ -z "$proj_repo" ]]; then
    while true; do
      if [[ -n "$proj_folder" ]]; then
        local git_folder="$(find_git_folder_ "$proj_folder" 2>/dev/null)"
        if [[ -n "$git_folder" ]]; then
          proj_repo="$(get_repo_ "$git_folder" 2>/dev/null)"
        fi
      fi

      if (( ! save_proj_repo_is_f )); then
        if [[ -z "$proj_repo" ]]; then
          proj_repo="$(find_repo_ "$proj_repo")"
          if (( $? == 130 || $? == 2 )); then return 130; fi
          # if proj_repo is not typed, it's fine to skip
          if [[ -z "$proj_repo" ]]; then
            break;
          fi
        fi

        if [[ "$proj_repo" == "." ]]; then
          proj_repo=""
        else
          # don't pass $proj_folder to check_proj_repo_ so it doesn't ask again if we want to use the same repo
          if check_proj_repo_ -v $i "$proj_repo" "$proj_folder" "$proj_cmd" "$single_mode" "${@:7}"; then
            break;
          else
            proj_repo=""
          fi
        fi
      fi
    done
  fi

  if (( save_proj_repo_is_q )); then
    if update_config_ $i "PUMP_REPO" "$proj_repo" &>/dev/null; then
      if (( save_proj_repo_is_e )); then
        update_proj_repo_ "$proj_repo" "$proj_folder" "$single_mode"
      fi
    fi

    return 0;
  fi

  TEMP_PUMP_REPO="$proj_repo"

  if [[ -n "$TEMP_PUMP_REPO" ]]; then
    print "  ${SAVE_COR}project repository:${reset_cor} ${TEMP_PUMP_REPO}${reset_cor}"
  fi
}

function save_pkg_manager_() {
  set +x
  eval "$(parse_flags_ "$0" "f" "q" "$@")"
  (( save_pkg_manager_is_debug )) && set -x

  local i="$1"
  local proj_folder="$2"
  local proj_repo="$3"

  local pkg_manager="$(detect_pkg_manager_ "$proj_folder" "$proj_repo")"

  local RET=0

  if [[ -n "$pkg_manager" ]] && (( ! save_pkg_manager_is_f || ! save_pkg_manager_is_q )); then
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

    if ! check_proj_pkg_manager_ $i "$pkg_manager" "$proj_folder" "$proj_repo" "${@:4}"; then
      return 1;
    fi
  fi
  
  if [[ -z "$pkg_manager" ]]; then return 1; fi

  if (( save_pkg_manager_is_q )); then
    return 0;
  fi

  TEMP_PUMP_PKG_MANAGER="$pkg_manager"

  print "  ${SAVE_COR}package manager:${reset_cor} ${TEMP_PUMP_PKG_MANAGER}${reset_cor}"
}

function save_proj_f_() {
  set +x
  eval "$(parse_flags_ "$0" "ae" "" "$@")"
  (( save_proj_f_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"
  local pkg_name="$3"

  if [[ -z "$i" ]]; then
    print " fatal: save_proj_f_ index is invalid: $i" >&2
    return 1;
  fi

  if (( save_proj_f_is_a )); then
    SAVE_COR="${hi_blue_cor}"
    display_line_ "add new project" "${SAVE_COR}"
  else
    SAVE_COR="${hi_yellow_cor}"
  fi

  local proj_repo="$(get_repo_ "$PWD" 2>/dev/null)"

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_PUMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  local old_proj_folder="${PUMP_FOLDER[$i]}"

  # all the config setting comes from $PWD
  if (( save_proj_f_is_e )); then
    if ! save_pkg_manager_ -fq $i "$PWD" "$proj_repo"; then return 1; fi
  else
    remove_proj_ $i

    if ! save_proj_repo_ -f $i "$PWD" "$proj_cmd" "$proj_repo" 1; then return 1; fi
    if ! save_proj_folder_ -f $i "$proj_cmd" "$proj_repo" "$PWD"; then return 1; fi

    if ! save_pkg_manager_ -f $i "$PWD" "$proj_repo"; then return 1; fi
    if ! save_proj_cmd_ -f $i "$proj_cmd"; then return 1; fi
  fi

  if [[ "$PWD" != "$old_proj_folder" ]]; then
    remove_proj_ -u $i
  fi

  update_config_ $i "PUMP_FOLDER" "$PWD" &>/dev/null
  update_config_ $i "PUMP_SINGLE_MODE" 1 &>/dev/null
  update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null
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

  PUMP_SHORT_NAME[$i]="$TEMP_PUMP_SHORT_NAME"
  PUMP_FOLDER[$i]="$TEMP_PUMP_FOLDER"
  PUMP_REPO[$i]="$TEMP_PUMP_REPO"
  PUMP_SINGLE_MODE[$i]="$TEMP_PUMP_SINGLE_MODE"
  PUMP_PKG_MANAGER[$i]="$TEMP_PUMP_PKG_MANAGER"
  PUMP_PKG_NAME[$i]="$pkg_name"

  print " new command is available: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"

  pro -f "${PUMP_SHORT_NAME[$i]}"
  # rm -f "$PUMP_PRO_PWD_FILE" &>/dev/null
}

function save_proj_() {
  set +x
  eval "$(parse_flags_ "$0" "ae" "" "$@")"
  (( save_proj_is_debug )) && set -x

  local i="$1"
  local proj_name="$2"

  if [[ -z "$i" ]]; then
    local j=0
    for j in {1..9}; do
      # find an empty slot
      if [[ -z "${PUMP_SHORT_NAME[$j]}" ]]; then
        i="$j"
        break;
      fi
    done
  fi

  if [[ -z "$i" ]]; then
    print " no more slots available, remove a project to add a new one" >&2
    print " run: ${hi_yellow_cor}pro -h${reset_cor} to see usage" >&2
    return 1;
  fi

  # display header
  if (( save_proj_is_a )); then
    SAVE_COR="${hi_cyan_cor}"
    display_line_ "add new project" "${SAVE_COR}"
  else
    SAVE_COR="${hi_yellow_cor}"
    display_line_ "edit project: ${proj_name}" "${SAVE_COR}"
  fi

  local old_single_mode=""

  TEMP_PUMP_SHORT_NAME=""
  TEMP_PUMP_FOLDER=""
  TEMP_PUMP_REPO=""
  TEMP_PUMP_SINGLE_MODE=""
  TEMP_PUMP_PKG_MANAGER=""

  local old_proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local old_proj_folder="${PUMP_FOLDER[$i]}"

  if (( save_proj_is_e )); then
    old_single_mode="$(get_proj_mode_from_folder_ "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}")"

    # editing a project
    if ! save_proj_cmd_ -e $i "$proj_name" "${PUMP_SHORT_NAME[$i]}"; then return 1; fi

    if ! save_proj_folder_ -e $i "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}" "${PUMP_FOLDER[$i]}"; then return 1; fi
    if ! save_proj_repo_ -e $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "${PUMP_REPO[$i]}" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
    
    if ! save_proj_mode_ -e $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi

  else
    # adding a new project
    remove_proj_ $i

    if ! save_proj_cmd_ -a $i "$proj_name"; then return 1; fi

    local count=0
    while [[ -z "$TEMP_PUMP_FOLDER" ]]; do
      save_proj_folder_ -a $i "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO" "$TEMP_PUMP_FOLDER" "$count"
      local RET=$?
      if (( RET == 130 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
      
      save_proj_repo_ -a $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SHORT_NAME" "$TEMP_PUMP_REPO" "${PUMP_SINGLE_MODE[$i]}" "$count"
      RET=$?
      if (( RET == 130 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
      (( count++ ))
    done

    old_single_mode="$(get_proj_mode_from_folder_ "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}")"

    if ! save_proj_mode_ -a $i "$TEMP_PUMP_FOLDER" "${PUMP_SINGLE_MODE[$i]}"; then return 1; fi
  fi

  if [[ "$TEMP_PUMP_FOLDER" != "$old_proj_folder" ]]; then
    remove_proj_ -u $i
  fi

  if ! save_pkg_manager_ $i "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO"; then return 1; fi

  update_config_ $i "PUMP_FOLDER" "$TEMP_PUMP_FOLDER" &>/dev/null
  update_config_ $i "PUMP_SINGLE_MODE" "$TEMP_PUMP_SINGLE_MODE" &>/dev/null

  update_config_ $i "PUMP_PKG_MANAGER" "$TEMP_PUMP_PKG_MANAGER" &>/dev/null
  update_config_ $i "PUMP_SHORT_NAME" "$TEMP_PUMP_SHORT_NAME" &>/dev/null

  local pkg_name="$(get_pkg_name_ "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_REPO" "$TEMP_PUMP_SINGLE_MODE")"
  update_config_ $i "PUMP_PKG_NAME" "$pkg_name" &>/dev/null

  if update_config_ $i "PUMP_REPO" "$TEMP_PUMP_REPO" &>/dev/null; then
    if (( save_proj_is_e )); then
      update_proj_repo_ "$TEMP_PUMP_REPO" "$TEMP_PUMP_FOLDER" "$TEMP_PUMP_SINGLE_MODE" &>/dev/null
    fi
  fi

  print ""
  print "  ${SAVE_COR}project saved!${reset_cor}"
  display_line_ "" "${SAVE_COR}"

  PUMP_SHORT_NAME[$i]="$TEMP_PUMP_SHORT_NAME"
  PUMP_FOLDER[$i]="$TEMP_PUMP_FOLDER"
  PUMP_REPO[$i]="$TEMP_PUMP_REPO"
  PUMP_SINGLE_MODE[$i]="$TEMP_PUMP_SINGLE_MODE"
  PUMP_PKG_MANAGER[$i]="$TEMP_PUMP_PKG_MANAGER"
  PUMP_PKG_NAME[$i]="$pkg_name"

  # load_default_config_ $i

  if [[ -n "$old_single_mode" && "$old_single_mode" -ne "${PUMP_SINGLE_MODE[$i]}" ]]; then
    local mode_cor="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "$purple_cor" || echo "$pink_cor" )"

    print " project mode has changed from $( (( old_single_mode )) && echo "single" || echo "multiple" ) to ${mode_cor}$( (( PUMP_SINGLE_MODE[$i] )) && echo "single" || echo "multiple" )${reset_cor}"

    if convert_mode_ $i "${PUMP_FOLDER[$i]}" "$old_single_mode"; then
      print " now run command: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"
    else
      # print " attempting to create a backup of project and change mode" >&2

      # if create_backup_ -sd $i "${PUMP_FOLDER[$i]}" "$old_single_mode"; then
      #   print " project must be cloned again as mode has changed" >&2
      #   print " run: ${hi_yellow_cor}${PUMP_SHORT_NAME[$i]} clone${reset_cor}" >&2
      # else
        PUMP_SINGLE_MODE[$i]="$(get_proj_mode_from_folder_ "${PUMP_FOLDER[$i]}" "${PUMP_SINGLE_MODE[$i]}")"
        update_config_ $i "PUMP_SINGLE_MODE" "${PUMP_SINGLE_MODE[$i]}" &>/dev/null
      # fi
    fi
  else
    if [[ -n "$old_proj_cmd" && "${PUMP_SHORT_NAME[$i]}" != "$old_proj_cmd" && "${PUMP_SHORT_NAME[$i]}" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      refresh
    elif [[ "${PUMP_SHORT_NAME[$i]}" != "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print " now run command: ${blue_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}"
    fi
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
  eval "$(parse_flags_ "$0" "u" "" "$@")"
  (( remove_proj_is_debug )) && set -x

  local i="$1"

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
  PUMP_RUN_QA[$i]=""
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
  PUMP_JIRA_READY_FOR_TEST[$i]=""
  PUMP_JIRA_ALMOST_DONE[$i]=""
  PUMP_JIRA_DONE[$i]=""
  PUMP_JIRA_CANCELED[$i]=""
  PUMP_JIRA_BLOCKED[$i]=""
  PUMP_JIRA_WORK_TYPES[$i]=""
  PUMP_NVM_USE_V[$i]=""
  PUMP_SCRIPT_FOLDER[$i]=""
  PUMP_GHA_DEPLOY[$i]=""
  PUMP_GO_BACK[$i]=""
  PUMP_VERSION_WEB[$i]=""
  PUMP_VERSION_CMD[$i]=""

  if (( remove_proj_is_u )); then
    update_config_ $i "PUMP_SHORT_NAME" "" &>/dev/null
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
    update_config_ $i "PUMP_RUN_QA" "" &>/dev/null
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
    update_config_ $i "PUMP_JIRA_READY_FOR_TEST" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_ALMOST_DONE" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_DONE" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_CANCELED" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_BLOCKED" "" &>/dev/null
    update_config_ $i "PUMP_JIRA_WORK_TYPES" "" &>/dev/null
    update_config_ $i "PUMP_NVM_USE_V" "" &>/dev/null
    update_config_ $i "PUMP_SCRIPT_FOLDER" "" &>/dev/null
    update_config_ $i "PUMP_GHA_DEPLOY" "" &>/dev/null
    update_config_ $i "PUMP_GO_BACK" "" &>/dev/null
    update_config_ $i "PUMP_VERSION_WEB" "" &>/dev/null
    update_config_ $i "PUMP_VERSION_CMD" "" &>/dev/null
  fi
}

function remove_proj_folders_() {
  set +x
  eval "$(parse_flags_ "$0" "rctf" "" "$@")"
  (( remove_proj_folders_is_debug )) && set -x

  local proj_cmd="$1"
  local proj_folder="$2"

  if [[ -z "$proj_cmd" || -z "$proj_folder" ]]; then
    print " fatal: remove_proj_folders_ missing arguments" >&2
    return 1;
  fi

  local revs_folder=""
  local cov_folder=""
  local temp_folder=""

  local RET=0

  if (( remove_proj_folders_is_r )) || (( ! remove_proj_folders_is_c && ! remove_proj_folders_is_t )); then
    if (( remove_proj_folders_is_f )); then
      RET=0
    else
      confirm_ "remove ${bold_yellow_cor}reviews${reset_cor} folder from ${blue_cor}$proj_cmd${reset_cor}?"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      revs_folder="$(get_proj_special_folder_ -rd "$proj_cmd" "$proj_folder")"
    fi
  fi

  if (( remove_proj_folders_is_c )) || (( ! remove_proj_folders_is_r && ! remove_proj_folders_is_t )); then
    if (( remove_proj_folders_is_f )); then
      RET=0
    else
      confirm_ "remove ${bold_yellow_cor}coverage${reset_cor} folder from ${blue_cor}$proj_cmd${reset_cor}?"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      cov_folder="$(get_proj_special_folder_ -cd "$proj_cmd" "$proj_folder")"
    fi
  fi

  if (( remove_proj_folders_is_t )) || (( ! remove_proj_folders_is_r && ! remove_proj_folders_is_c )); then
    if (( remove_proj_folders_is_f )); then
      RET=0
    else
      confirm_ "remove ${bold_yellow_cor}temporary${reset_cor} folders from ${blue_cor}$proj_cmd${reset_cor}?"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi
    if (( RET == 0 )); then
      temp_folder="$(get_proj_special_folder_ -td "$proj_cmd" "$proj_folder")"
    fi
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="removing project folders..." -- rm -rf -- "$revs_folder" "$cov_folder" "$temp_folder"
  else
    print " removing project folders..."
    rm -rf -- "$revs_folder" "$cov_folder" "$temp_folder"
  fi

  return $?;
}

function set_current_proj_() {
  set +x

  local i="$1"

  if [[ -z "$i" ]]; then return 1; fi

  unset_aliases_

  load_default_config_ $i

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
  CURRENT_PUMP_RUN_QA="${PUMP_RUN_QA[$i]}"
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
  CURRENT_PUMP_JIRA_READY_FOR_TEST="${PUMP_JIRA_READY_FOR_TEST[$i]}"
  CURRENT_PUMP_JIRA_DONE="${PUMP_JIRA_DONE[$i]}"
  CURRENT_PUMP_JIRA_CANCELED="${PUMP_JIRA_CANCELED[$i]}"
  CURRENT_PUMP_JIRA_BLOCKED="${PUMP_JIRA_BLOCKED[$i]}"
  CURRENT_PUMP_JIRA_ALMOST_DONE="${PUMP_JIRA_ALMOST_DONE[$i]}"
  CURRENT_PUMP_JIRA_WORK_TYPES="${PUMP_JIRA_WORK_TYPES[$i]}"
  CURRENT_PUMP_NVM_USE_V="${PUMP_NVM_USE_V[$i]}"
  CURRENT_PUMP_SCRIPT_FOLDER="${PUMP_SCRIPT_FOLDER[$i]}"
  CURRENT_PUMP_GHA_DEPLOY="${PUMP_GHA_DEPLOY[$i]}"
  CURRENT_PUMP_GO_BACK="${PUMP_GO_BACK[$i]}"
  CURRENT_PUMP_WEB_URL="${PUMP_VERSION_WEB[$i]}"
  CURRENT_PUMP_VERSION_CMD="${PUMP_VERSION_CMD[$i]}"

  set_aliases_ $i
}

function is_version_higher_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_version_higher_is_debug )) && set -x

  local version1="${1#v}"
  local version2="${2#v}"

  if [[ -z "$version1" || -z "$version2" ]]; then
    return 1;
  fi

  if [[ "$version1" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    local version1_major="${version1%%.*}"
    local version1_rest="${version1#*.}"
    local version1_minor=0
    # if there was no dot, version1_rest equals version1, so minor should be 0
    if [[ "$version1_rest" != "$version1" ]]; then
      version1_minor="${version1_rest%%.*}"
    fi

    if [[ "$version2" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
      local version2_major="${version2%%.*}"
      local version2_rest="${version2#*.}"
      local version2_minor=0
      # if there was no dot, version2_rest equals version2, so minor should be 0
      if [[ "$version2_rest" != "$version2" ]]; then
        version2_minor="${version2_rest%%.*}"
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

  local node_engine="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$node_engine" ]]; then return 1; fi
  if ! command -v nvm &>/dev/null; then return 1; fi

  # get list of installed versions from nvm
  local RET=0
  local output=""
  set +x
  if command -v gum &>/dev/null; then
    output="$(gum spin --title="detecting node versions..." -- zsh -ic "nvm ls --no-colors | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^[-> ]*//' | sed 's/ *\*$//' | sort -V 2>/dev/null" 2>/dev/tty)"
    RET=$?
  else
    output="$(nvm ls --no-colors | grep -E '^[-> ]+\s+v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^[-> ]*//' | sed 's/ *\*$//' | sort -V 2>/dev/null)"
    RET=$?
  fi
  (( get_node_versions_is_debug )) && set -x
  
  if (( RET != 0 )) || [[ -z "$output" ]]; then
    print " no node version found" >&2
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

  # find matching versions
  local version=""
  for version in "${(@f)output}"; do
    if npx $yes semver "$version" -r "$node_engine" &>/dev/null; then
      echo "$version"
    fi
  done
}

function print_current_proj_() {
  set +x
  local i="$1"
  
  display_line_ "" "${hi_gray_cor}"

  if (( i > 0 )); then
    print " [${hi_magenta_cor}PUMP_SHORT_NAME_${i}=${hi_gray_cor}${PUMP_SHORT_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_FOLDER_${i}=${hi_gray_cor}${PUMP_FOLDER[${hi_magenta_cor}$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_REPO_${i}=${hi_gray_cor}${PUMP_REPO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SINGLE_MODE_${i}=${hi_gray_cor}${PUMP_SINGLE_MODE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_MANAGER_${i}=${hi_gray_cor}${PUMP_PKG_MANAGER[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_${i}=${hi_gray_cor}${PUMP_RUN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_STAGE_${i}=${hi_gray_cor}${PUMP_RUN_STAGE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_PROD_${i}=${hi_gray_cor}${PUMP_RUN_PROD[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RUN_QA_${i}=${hi_gray_cor}${PUMP_RUN_QA[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SETUP_${i}=${hi_gray_cor}${PUMP_SETUP[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_FIX_${i}=${hi_gray_cor}${PUMP_FIX[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_CLONE_${i}=${hi_gray_cor}${PUMP_CLONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PRO_${i}=${hi_gray_cor}${PUMP_PRO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_USE_${i}=${hi_gray_cor}${PUMP_USE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COV_${i}=${hi_gray_cor}${PUMP_COV[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_OPEN_COV_${i}=${hi_gray_cor}${PUMP_OPEN_COV[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_${i}=${hi_gray_cor}${PUMP_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_RETRY_TEST_${i}=${hi_gray_cor}${PUMP_RETRY_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_TEST_WATCH_${i}=${hi_gray_cor}${PUMP_TEST_WATCH[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2E_${i}=${hi_gray_cor}${PUMP_E2E[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_E2EUI_${i}=${hi_gray_cor}${PUMP_E2EUI[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_TEMPLATE_FILE_${i}=${hi_gray_cor}${PUMP_PR_TEMPLATE_FILE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_TITLE_FORMAT_${i}=${hi_gray_cor}${PUMP_PR_TITLE_FORMAT[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_REPLACE_${i}=${hi_gray_cor}${PUMP_PR_REPLACE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPEND_${i}=${hi_gray_cor}${PUMP_PR_APPEND[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PR_APPROVAL_MIN$i=${hi_gray_cor}${PUMP_PR_APPROVAL_MIN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_COMMIT_SIGNOFF_${i}=${hi_gray_cor}${PUMP_COMMIT_SIGNOFF[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_PKG_NAME_${i}=${hi_gray_cor}${PUMP_PKG_NAME[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_PROJECT_${i}=${hi_gray_cor}${PUMP_JIRA_PROJECT[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_API_TOKEN_${i}=${hi_gray_cor}${PUMP_JIRA_API_TOKEN[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_STATUSES_${i}=${hi_gray_cor}${PUMP_JIRA_STATUSES[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_TODO_${i}=${hi_gray_cor}${PUMP_JIRA_TODO[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_PROGRESS_${i}=${hi_gray_cor}${PUMP_JIRA_IN_PROGRESS[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_TEST_${i}=${hi_gray_cor}${PUMP_JIRA_IN_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_READY_FOR_TEST_${i}=${hi_gray_cor}${PUMP_JIRA_READY_FOR_TEST[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_IN_REVIEW_${i}=${hi_gray_cor}${PUMP_JIRA_IN_REVIEW[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_ALMOST_DONE_${i}=${hi_gray_cor}${PUMP_JIRA_ALMOST_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_DONE_${i}=${hi_gray_cor}${PUMP_JIRA_DONE[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_CANCELED_${i}=${hi_gray_cor}${PUMP_JIRA_CANCELED[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_BLOCKED_${i}=${hi_gray_cor}${PUMP_JIRA_BLOCKED[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_JIRA_WORK_TYPES_${i}=${hi_gray_cor}${PUMP_JIRA_WORK_TYPES[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_NVM_USE_V_${i}=${hi_gray_cor}${PUMP_NVM_USE_V[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_SCRIPT_FOLDER_${i}=${hi_gray_cor}${PUMP_SCRIPT_FOLDER[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_GHA_DEPLOY_${i}=${hi_gray_cor}${PUMP_GHA_DEPLOY[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_GO_BACK_${i}=${hi_gray_cor}${PUMP_GO_BACK[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_WEB_URL_${i}=${hi_gray_cor}${PUMP_VERSION_WEB[$i]}${reset_cor}]"
    print " [${hi_magenta_cor}PUMP_VERSION_CMD_${i}=${hi_gray_cor}${PUMP_VERSION_CMD[$i]}${reset_cor}]"

    return 0;
  fi

  print " [${hi_magenta_cor}CURRENT_PUMP_SHORT_NAME=${hi_gray_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_FOLDER=${hi_gray_cor}${CURRENT_PUMP_FOLDER}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_REPO=${hi_gray_cor}${CURRENT_PUMP_REPO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SINGLE_MODE=${hi_gray_cor}${CURRENT_PUMP_SINGLE_MODE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_MANAGER=${hi_gray_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN=${hi_gray_cor}${CURRENT_PUMP_RUN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN_STAGE=${hi_gray_cor}${CURRENT_PUMP_RUN_STAGE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN_PROD=${hi_gray_cor}${CURRENT_PUMP_RUN_PROD}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RUN_QA=${hi_gray_cor}${CURRENT_PUMP_RUN_QA}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SETUP=${hi_gray_cor}${CURRENT_PUMP_SETUP}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_FIX=${hi_gray_cor}${CURRENT_PUMP_FIX}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_CLONE=${hi_gray_cor}${CURRENT_PUMP_CLONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PRO=${hi_gray_cor}${CURRENT_PUMP_PRO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_USE=${hi_gray_cor}${CURRENT_PUMP_USE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COV=${hi_gray_cor}${CURRENT_PUMP_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_OPEN_COV=${hi_gray_cor}${CURRENT_PUMP_OPEN_COV}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST=${hi_gray_cor}${CURRENT_PUMP_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_RETRY_TEST=${hi_gray_cor}${CURRENT_PUMP_RETRY_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_TEST_WATCH=${hi_gray_cor}${CURRENT_PUMP_TEST_WATCH}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2E=${hi_gray_cor}${CURRENT_PUMP_E2E}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_E2EUI=${hi_gray_cor}${CURRENT_PUMP_E2EUI}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_TEMPLATE_FILE=${hi_gray_cor}${CURRENT_PUMP_PR_TEMPLATE_FILE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_TITLE_FORMAT=${hi_gray_cor}${CURRENT_PUMP_PR_TITLE_FORMAT}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_REPLACE=${hi_gray_cor}${CURRENT_PUMP_PR_REPLACE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPEND=${hi_gray_cor}${CURRENT_PUMP_PR_APPEND}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PR_APPROVAL_MIN=${hi_gray_cor}${CURRENT_PUMP_PR_APPROVAL_MIN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_COMMIT_SIGNOFF=${hi_gray_cor}${CURRENT_PUMP_COMMIT_SIGNOFF}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_PKG_NAME=${hi_gray_cor}${CURRENT_PUMP_PKG_NAME}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_PROJECT=${hi_gray_cor}${CURRENT_PUMP_JIRA_PROJECT}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_API_TOKEN=${hi_gray_cor}${CURRENT_PUMP_JIRA_API_TOKEN}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_STATUSES=${hi_gray_cor}${CURRENT_PUMP_JIRA_STATUSES}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_TODO=${hi_gray_cor}${CURRENT_PUMP_JIRA_TODO}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_PROGRESS=${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_PROGRESS}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_REVIEW=${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_REVIEW}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_IN_TEST=${hi_gray_cor}${CURRENT_PUMP_JIRA_IN_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_READY_FOR_TEST=${hi_gray_cor}${CURRENT_PUMP_JIRA_READY_FOR_TEST}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_ALMOST_DONE=${hi_gray_cor}${CURRENT_PUMP_JIRA_ALMOST_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_DONE=${hi_gray_cor}${CURRENT_PUMP_JIRA_DONE}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_CANCELED=${hi_gray_cor}${CURRENT_PUMP_JIRA_CANCELED}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_BLOCKED=${hi_gray_cor}${CURRENT_PUMP_JIRA_BLOCKED}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_JIRA_WORK_TYPES=${hi_gray_cor}${CURRENT_PUMP_JIRA_WORK_TYPES}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_NVM_USE_V=${hi_gray_cor}${CURRENT_PUMP_NVM_USE_V}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_SCRIPT_FOLDER=${hi_gray_cor}${CURRENT_PUMP_SCRIPT_FOLDER}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_GHA_DEPLOY=${hi_gray_cor}${CURRENT_PUMP_GHA_DEPLOY}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_GO_BACK=${hi_gray_cor}${CURRENT_PUMP_GO_BACK}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_WEB_URL=${hi_gray_cor}${CURRENT_PUMP_WEB_URL}${reset_cor}]"
  print " [${hi_magenta_cor}CURRENT_PUMP_VERSION_CMD=${hi_gray_cor}${CURRENT_PUMP_VERSION_CMD}${reset_cor}]"

  return 0;
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

  rm -rf -- "${folder}/.DS_Store" &>/dev/null || true

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
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( get_proj_index_is_debug )) && set -x

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
  local header="${2:-"project"}"
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

function find_pkg_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
  (( find_pkg_folder_is_debug )) && set -x

  local folder_arg="${1:-$PWD}"

  local folder="$(realpath -- "$folder_arg" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    print " fatal: not a project folder: $folder_arg" >&2
    return 1;
  fi

  local file="package.json"
  local proj_folder=""

  if [[ -f "${folder}/${file}" ]]; then
    echo "$folder"
    return 0;
  fi

  if (( find_pkg_folder_is_r )); then
    local found_pkg="$(find_up_ "$file" "$folder")"

    if [[ -n "$found_pkg" ]]; then
      echo "$found_pkg"
      return 0;
    fi
  else
    local dir=""
    for dir in "${BRANCHES[@]}"; do
      if [[ -f "${folder}/${dir}/${file}" ]]; then
        echo "${folder}/${dir}"
        return 0;
      fi
    done

    local pattern="$(printf "%q" "$file")"
    local found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}*" \) -prune -o -maxdepth 2 -type f -iname "${pattern}*" -print -quit 2>/dev/null)"

    if [[ -z "$found_file" ]]; then
      found_file="$(find "$folder" \( -path "*/.*" -a ! -iname "${pattern}*" \) -prune -o -type f -iname "${pattern}*" -print -quit 2>/dev/null)"
    fi

    if [[ -n "$found_file" ]]; then
      echo "$(dirname -- "$found_file")"
      return 0;
    fi
  fi

  print " fatal: not a project folder: $folder_arg" >&2
  
  return 1;
}

function find_up_() {
  local file="$1"
  local path="${2:-$PWD}"

  while [[ "$path" != "" && "$path" != "/" && ! -e "${path}/${file}" ]]; do
    path="${path%/*}"
  done

  echo "$path"
}

function find_git_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "m" "" "$@")"
  (( find_git_folder_is_debug )) && set -x

  local folder_arg="${1:-$PWD}"

  local folder="$(realpath -- "$folder_arg" 2>/dev/null)"

  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder_arg" >&2
    return 1;
  fi

  if is_folder_git_ "$folder" &>/dev/null; then
    echo "$folder"
    return 0;
  fi

  local dir=""
  for dir in "${BRANCHES[@]}"; do
    if is_folder_git_ "${folder}/${dir}" &>/dev/null; then
      echo "${folder}/${dir}"
      return 0;
    fi
  done

  if (( find_git_folder_is_m )); then
    return 1;
  fi

  local found_git="$(find "$folder" \( -path "*/.*" -a ! -name ".git" \) -prune -o -maxdepth 2 -type d -name ".git" -print -quit 2>/dev/null)"

  if [[ -n "$found_git" ]]; then
    local dir="$(dirname -- "$found_git")"

    if is_folder_git_ "$dir" &>/dev/null; then
      echo "$dir"
      return 0;
    fi
  fi

  print " fatal: not a git repository: $folder_arg" >&2

  return 1;
}

function is_upstream_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_upstream_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if ! git -C "$folder" rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
    print " fatal: no upstream configured for the current branch" >&2
    return 1;
  fi
}

function is_folder_git_() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
  # (( is_folder_git_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if [[ -z "$folder" || ! -d "$folder" ]]; then
    print " fatal: not a git repository (or any of the parent directories): .git" >&2 
    return 1;
  fi

  if ! command -v git &>/dev/null; then
    print " fatal: git command not found" >&2 
    return 1;
  fi

  if git -C "$folder" rev-parse --is-inside-work-tree &>/dev/null; then
    if (( is_folder_git_is_r )); then
      if [[ ! -d "$folder/.git" ]]; then
        print " fatal: not a git repository root: .git" >&2 
        return 1;
      fi
    fi
    return 0;
  fi
  
  print " fatal: not a git repository (or any of the parent directories): .git" >&2 
  return 1;
}

function get_remote_name_() {
  local folder="${1:-$PWD}"
  
  folder="$(find_git_folder_ "$folder" 2>/dev/null)"

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
  eval "$(parse_flags_ "$0" "dbmyteq" "" "$@")"
  (( determine_target_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"
  local proj_cmd="$3"
  local extra_branch="$4"

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
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
  local main_branch="$(get_main_branch_ "$folder" 2>/dev/null)"
  local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

  local pump_merge=""
  local gh_merge_base=""
  local vscode_merge_base=""
  local gk_merge_target=""

  if (( determine_target_branch_is_d )); then
    default_branch="$(get_default_branch_ "$folder" 2>/dev/null)"
  fi

  if [[ -n "$my_branch" ]]; then
    pump_merge="$(get_short_name_ "$(git -C "$folder" config --get branch.$my_branch.pump-merge)" "$folder")"
    gh_merge_base="$(get_short_name_ "$(git -C "$folder" config --get branch.$my_branch.gh-merge-base)" "$folder")"
    vscode_merge_base="$(get_short_name_ "$(git -C "$folder" config --get branch.$my_branch.vscode-merge-base)" "$folder")"
    gk_merge_target="$(get_short_name_ "$(git -C "$folder" config --get branch.$my_branch.gk-merge-target)" "$folder")"
  fi

  if (( is_pwd )); then
    if (( determine_target_branch_is_y )); then
      my_branch="$(get_my_branch_ "$PWD" 2>/dev/null)"
    else
      my_branch=""
    fi
    if [[ -z "$default_branch" ]]; then
      default_branch="$(get_default_branch_ "$PWD" 2>/dev/null)"
    fi
  else
    if (( determine_target_branch_is_y )); then
      my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
    else
      my_branch=""
    fi
  fi

  if (( ! determine_target_branch_is_m )); then
    main_branch=""
  fi

  if [[ "$branch" == "$default_branch" ]]; then default_branch=""; fi
  if [[ "$branch" == "$main_branch" ]]; then main_branch=""; fi
  if [[ "$branch" == "$extra_branch" ]]; then extra_branch=""; fi

  local branches=()
  local output="$(printf "%s\n" "$pump_merge" "$gh_merge_base" "$vscode_merge_base" "$gk_merge_target" "$default_branch" "$my_branch" "$main_branch" "$extra_branch" 2>/dev/null | grep -v '^$' | sort -u)"

  if (( $? == 0 )); then
    branches+=("${(@f)output}")
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local output_releases="$(git -C "$folder" branch --all --list "${remote_name}/release*" --sort="-committerdate" -i --no-column --format="%(refname:short)" \
    | sed "s#^$remote_name/##" \
    | grep -v 'detached' \
    | grep -v 'HEAD' \
    | head -7
  )"
  # | sort -fur \

  if [[ -n "$output_releases" ]]; then
    branches+=("${(@f)output_releases}")
  fi
  
  # if (( determine_target_branch_is_e )); then
    # if (( ${#branches[@]} > 1 )); then
      # branches+=("<enter manually>")
    # fi
  # elif (( ${#branches[@]} == 0 )); then
    branches+=("<enter manually>")
  # fi

  local label=""
  if [[ -n "$branch" ]]; then
    label="target branch for ${green_cor}$branch${reset_cor}"
  else
    label="target branch"
  fi

  while true; do
    if [[ -z "$branches" ]]; then
      if (( ! determine_target_branch_is_q )); then
        print " ${red_cor}fatal: no branches found to select as target${reset_cor}" >&2
      fi
      break;
    fi

    local selected_branch=""
    selected_branch="$(choose_one_ -i "$label" "${branches[@]}")"
    if (( $? != 0 )); then
      break;
    fi

    if [[ "$selected_branch" == "<enter manually>" ]]; then
      selected_branch="$(input_branch_name_ "type the target branch")"
      if [[ -z "$selected_branch" ]]; then
        if (( ${#branches[@]} > 1 )); then
          continue;
        else
          break;
        fi
      fi
    fi

    local remote_name="$(get_remote_branch_ "$selected_branch" "$folder")"

    if [[ -n "$remote_name" ]]; then
      echo "$remote_name"
      return 0;
    else
      print " ${red_cor}fatal: branch not found remotely: $(truncate_ $selected_branch)${reset_cor}" >&2

      # remove the branch that was not found remotely from the options and prompt again
      branches=("${branches[@]:0:$(( ${branches[(i)$selected_branch]} - 1 ))}" "${branches[@]:${branches[(i)$selected_branch]}}")
    fi
  done

  echo "$extra_branch"
  return 1;
}

function is_branch_existing_local_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  if get_local_branch_ "$branch" "$folder" &>/dev/null; then
    return 0;
  fi

  return 1;
}

function is_branch_existing_remote_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  if get_remote_branch_ "$branch" "$folder" &>/dev/null; then
    return 0;
  fi

  return 1;
}

function is_branch_existing_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( is_branch_existing_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  if get_remote_branch_ "$branch" "$folder" &>/dev/null || get_local_branch_ "$branch" "$folder" &>/dev/null; then
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

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

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

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

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
  eval "$(parse_flags_ "$0" "l" "" "$@")"
  (( get_main_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"
  
  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{main,master,mainline,default,stable,prod,production,trunk}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      if (( get_main_branch_is_l )); then
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
  eval "$(parse_flags_ "$0" "el" "" "$@")"
  (( get_my_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if ! is_folder_git_ "$folder" &>/dev/null; then return 1; fi
  
  local my_branch="$(git -C "$folder" branch --show-current 2>/dev/null)"
  
  if [[ -z "$my_branch" ]] && (( get_my_branch_is_e )); then
    # this gives off "HEAD" when in detached state
    my_branch="$(git -C "$folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  fi

  if [[ -z "$my_branch" ]]; then
    print " fatal: current branch is detached or not tracking an upstream" >&2
    return 1;
  fi

  if (( get_my_branch_is_l )); then
    echo "$(get_long_name_ "$my_branch" "$folder")"
  else
    echo "$my_branch"
    # echo "$(get_short_name_ "$my_branch" "$folder")"
  fi
}

function is_local_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_local_branch_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"
  local remote_name="$3"

  if [[ -z "$branch" ]]; then return 1; fi

  if [[ "$branch" == "refs/heads/"* ]] || ! is_remote_branch_name_ "$branch" "$folder" "$remote_name"; then
    # echo "1" # 1 means true when put into a variable
    return 0;
  fi

  # echo "0"
  return 1;
}

function is_remote_branch_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_remote_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"
  local remote_name="$3"

  if [[ -z "$branch" ]]; then return 1; fi

  if [[ -z "$remote_name" ]]; then
    remote_name="$(get_remote_name_ "$folder")"
  fi

  # check if branch has remote_name
  if [[ "$branch" == "${remote_name}/"* || "$branch" == "refs/remotes/"* ]]; then
    # echo "1" # 1 means true when put into a variable
    return 0;
  fi

  # echo "0"
  return 1;
}

function is_local_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_local_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  # check if branch is listed in local branches
  if git -C "$folder" show-ref --verify --quiet "refs/heads/${branch#refs/heads/}"; then
    # echo "1" # 1 means true when put into a variable
    return 0;
  fi

  # echo "0"
  return 1;
}

function is_remote_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( is_remote_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  if [[ -z "$branch" ]]; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  local short_name="$(get_short_name_ "$branch" "$folder")"

  local ref=""
  for ref in refs/remotes/{origin,upstream}/${short_name}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      # echo "1" # 1 means true when put into a variable
      return 0;
    fi
  done

  # echo "0"
  return 1;
}

function get_long_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_long_name_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"
  local remote_name="$3"

  if [[ -z "$branch" ]]; then return 1; fi

  if [[ -z "$remote_name" ]]; then
    remote_name="$(get_remote_name_ "$folder")"
  fi

  if is_remote_branch_name_ "$branch" "" "$remote_name" &>/dev/null; then
    echo "$branch"
    return 0;
  fi

  local long_branch="${branch#refs/}"

  long_branch="${long_branch#remotes/}"
  long_branch="${long_branch#heads/}"
  long_branch="${long_branch#HEAD/}"

  long_branch="${long_branch#$remote_name/}"

  echo "${remote_name}/${long_branch}"
}

function get_short_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_short_name_is_debug )) && set -x

  local branch="$1"
  local folder="$2"
  local remote_name="$3"

  if [[ -z "$branch" ]]; then return 1; fi

  if [[ -z "$remote_name" ]]; then
    remote_name="$(get_remote_name_ "$folder")"
  fi

  local short_branch="${branch#refs/}"

  short_branch="${short_branch#remotes/}"
  short_branch="${short_branch#heads/}"
  short_branch="${short_branch#HEAD/}"

  short_branch="${short_branch#$remote_name/}"

  echo "$short_branch"
}

function find_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "l" "" "$@")"
  (( find_base_branch_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  local base_branch=""

  if command -v gum &>/dev/null; then
    if (( find_base_branch_is_l )); then
      base_branch="$(gum spin --title="finding base branch..." -- zsh -ic "get_base_branch_ -l \"$branch\" \"$folder\" 2>/dev/null")"
    else
      base_branch="$(gum spin --title="finding base branch..." -- zsh -ic "get_base_branch_ \"$branch\" \"$folder\" 2>/dev/null")"
    fi
  else
    if (( find_base_branch_is_l )); then
      base_branch="$(get_base_branch_ -l "$branch" "$folder" 2>/dev/null)"
    else
      base_branch="$(get_base_branch_ "$branch" "$folder" 2>/dev/null)"
    fi
  fi

  if (( $? != 0 )); then
    print " fatal: could not determine base branch" >&2
    return 1;
  fi

  echo "$base_branch"
}

function get_base_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "l" "" "$@")"
  (( get_base_branch_is_debug )) && set -x

  local branch="$1"
  local folder="${2:-$PWD}"

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  if [[ -z "$branch" ]]; then
    branch="$(get_my_branch_ "$folder")"
    if [[ -z "$branch" ]]; then return 1; fi
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local short_my_branch="$(get_short_name_ "$branch" "" "$remote_name")"

  local short_base_branch=""
  local base_branch=""

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  if [[ -n "$short_my_branch" ]]; then
    local base_branch="$(git -C "$folder" config --get branch.$branch.pump-merge)"
    short_base_branch="$(get_short_name_ "$base_branch" "" "$remote_name")"

    if ! git -C "$folder" show-ref --verify --quiet "refs/remotes/${remote_name}/${short_base_branch}" || [[ "$short_my_branch" == "$short_base_branch" ]]; then
      base_branch="$(git -C "$folder" config --get branch.$branch.gh-merge-base)"
      short_base_branch="$(get_short_name_ "$base_branch" "" "$remote_name")"

      if ! git -C "$folder" show-ref --verify --quiet "refs/remotes/${remote_name}/${short_base_branch}" || [[ "$short_my_branch" == "$short_base_branch" ]]; then
        base_branch="$(git -C "$folder" config --get branch.$branch.vscode-merge-base)"
        short_base_branch="$(get_short_name_ "$base_branch" "" "$remote_name")"

        if ! git -C "$folder" show-ref --verify --quiet "refs/remotes/${remote_name}/${short_base_branch}" || [[ "$short_my_branch" == "$short_base_branch" ]]; then
          base_branch="$(git -C "$folder" config --get branch.$branch.gk-merge-target)"
          short_base_branch="$(get_short_name_ "$base_branch" "" "$remote_name")"
        fi
      fi
    fi

    base_branch="$short_base_branch"
  fi

  if [[ -z "$base_branch" ]] || ! git -C "$folder" show-ref --verify --quiet "refs/remotes/${remote_name}/${base_branch}"; then
    base_branch="$(git -C "$folder" symbolic-ref refs/remotes/$remote_name/HEAD 2>/dev/null)"
  fi

  if [[ -n "$base_branch" ]]; then
    if (( get_base_branch_is_l )); then
      echo "$(get_long_name_ "$base_branch" "" "$remote_name")"
    else
      echo "$(get_short_name_ "$base_branch" "" "$remote_name")"
    fi
    return 0;
  fi

  return 1;
}

# function find_base_branch_() {
#   set +x
#   eval "$(parse_flags_ "$0" "f" "" "$@")"
#   (( find_base_branch_is_debug )) && set -x

#   local folder="${1:-$PWD}"
#   local my_branch="$2"

#   folder="$(find_git_folder_ "$folder" 2>/dev/null)"
#   if [[ -z "$folder" ]]; then
#     print " fatal: not a git repository: $folder" >&2
#     return 1;
#   fi

#   if [[ -z "$my_branch" ]]; then
#     my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
#     if [[ -z "$my_branch" ]]; then return 1; fi
#   fi

#   local remote_name="$(get_remote_name_ "$folder")"

#   local best_ref=""
#   local most_recent_time=0

#   git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

#   local ref=""
#   local base=""
#   for base in "${BRANCHES[@]}"; do
#     # Skip if base doesn't exist
#     local found=0

#     local ref=""
#     for ref in refs/{remotes/${remote_name},heads}/$base; do
#       if git -C "$folder" show-ref --verify --quiet "$ref"; then
#         found=1
#         break;
#       fi
#     done
#     if (( ! found )); then
#       continue;
#     fi

#     # Find the common ancestor
#     local ancestor_commit="$(git -C "$folder" merge-base "$my_branch" "$ref" 2>/dev/null)"
#     if [[ -z "$ancestor_commit" ]]; then
#       continue;
#     fi

#     # Get commit timestamp
#     local commit_time="$(git -C "$folder" show -s --format=%ct "$ancestor_commit")"

#     # Track the most recent ancestor
#     if (( commit_time > most_recent_time )); then
#       most_recent_time=$commit_time
#       best_ref="$ref"
#     fi
#   done

#   if [[ -n "$best_ref" ]]; then
#     if (( find_base_branch_is_f )); then
#       echo "$best_ref"
#     else
#       echo "$(get_short_name_ "$best_ref" "$folder")"
#     fi

#     return 0;
#   fi

#   return 1;
# }

function get_default_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "l" "" "$@")"
  # (( get_default_branch_is_debug )) && set -x

  local folder="${1:-$PWD}"

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then
    print " fatal: not a git repository: $folder" >&2
    return 1;
  fi

  local remote_name="$(get_remote_name_ "$folder")"
  local default_branch="$(git -C "$folder" symbolic-ref refs/remotes/${remote_name}/HEAD 2>/dev/null)"

  if [[ -z "$default_branch" ]]; then
    default_branch="$(git -C "$folder" config --get init.defaultBranch 2>/dev/null)"
  fi
  
  if [[ -z "$default_branch" ]]; then
    default_branch="$(get_main_branch_ "$folder")"
  fi

  if [[ -n "$default_branch" ]]; then
    if (( get_default_branch_is_l )); then
      echo "$(get_long_name_ "$default_branch" "" "$remote_name")"
    else
      echo "$(get_short_name_ "$default_branch" "" "$remote_name")"
    fi
    return 0;
  fi

  print " fatal: could not determine default branch" >&2
  return 1;
}

function get_repo_() {
  local folder="${1:-$PWD}"

  if [[ -z "$folder" ]]; then
    print " fatal: could not determine repository" >&2
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

  if [[ -z "$uri" ]]; then
    uri="$(get_repo_ "$PWD" 2>/dev/null)"
    if [[ -z "$uri" ]]; then return 1; fi
  fi
  
  uri="${uri%.git}"

  if [[ "$uri" == git@*:* ]]; then
    echo "${uri##*:}"
    return 0;
  fi
  
  if [[ "$uri" == http*://* ]]; then
    echo "${uri#*://*/}"
    return 0;
  fi

  echo "$uri"
}

function select_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "" "alrixscjo" "$@")"
  (( select_branch_is_debug )) && set -x

  select_branches_ -1 "$@"
}

function select_branches_() {
  set +x
  eval "$(parse_flags_ "$0" "1alrixscjo" "" "$@")"
  (( select_branches_is_debug )) && set -x

  local search_arg="$1"
  local header="$2"
  local folder="${3:-$PWD}"
  local branches_excluded=("${@:4}")

  folder="$(find_git_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$folder" ]]; then return 1; fi

  local sort_git="-committerdate"
  local sed_sort="-fu"

  if (( select_branches_is_o )); then
    sort_git="committerdate"
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  local remote_name="$(get_remote_name_ "$folder")"
  local short_search_arg="$(get_short_name_ "$search_arg" "" "$remote_name")"

  local local_search_text=""
  local remote_search_text=""

  if (( select_branches_is_x )); then
    local_search_text="$short_search_arg"
    remote_search_text="${remote_name}/${short_search_arg}"
  else
    local_search_text="*${short_search_arg}*"

    if is_remote_branch_name_ "$search_arg" "" "$remote_name"; then
      remote_search_text="${remote_name}/${short_search_arg}*"
    else
      remote_search_text="${remote_name}/*${short_search_arg}*"
    fi
  fi
  
  local output=""
  if (( select_branches_is_a )); then
    if is_local_branch_name_ "$search_arg" "" "$remote_name"; then
      output="$(git -C "$folder" branch --list "$local_search_text" --sort="$sort_git" -i --no-column --format='%(refname:short)' 2>/dev/null \
        | grep -v 'detached' \
        | grep -v 'HEAD' \
        | sed '/^$/d'
      )"
    fi

    local output2="$(git -C "$folder" branch --all --list "$remote_search_text" --sort="$sort_git" -i --no-column --format='%(refname:short)' 2>/dev/null)"

    if [[ -n "$output2" ]]; then
      if [[ -n "$output" ]]; then output+=$'\n'; fi
      output+="$output2"
    fi

  elif (( select_branches_is_r )); then

    output="$(git -C "$folder" branch --all --list "$remote_search_text" --sort="$sort_git" -i --no-column --format='%(refname:short)' 2>/dev/null)"

  else # -l

    output="$(git -C "$folder" branch --list "$local_search_text" --sort="$sort_git" -i --no-column --format='%(refname:short)' 2>/dev/null \
      | grep -v 'detached' \
      | grep -v 'HEAD' \
      | sed '/^$/d'
    )"
  fi

  # always return in short branch name format for commands such as: co
  if (( select_branches_is_c )); then # co command
    output="$(echo "$output" | sed "s#^$remote_name/##" | sort $sed_sort)"
  fi

  local branch_results=("${(@f)output}")

  if (( select_branches_is_s )); then
    branches_excluded+=("${BRANCHES[@]}")
    branches_excluded+=("${remote_name}/main" "${remote_name}/master" "${remote_name}/dev" "${remote_name}/develop" "${remote_name}/stage" "${remote_name}/staging" "${remote_name}/prod" "${remote_name}/production" "${remote_name}/release")
  fi

  local filtered_branches=()

  if (( select_branches_is_j )) || [[ -n "$branches_excluded" ]]; then
    if [[ -n "$branch_results" ]]; then
      local branch=""
      for branch in "${branch_results[@]}"; do
        # exclude branches in branches_excluded
        if [[ -n "$branches_excluded" && " ${branches_excluded[*]} " == *" $branch "* ]]; then
          continue;
        fi

        # only include branches with a JIRA key
        if (( select_branches_is_j )); then
          if [[ -n "$(extract_jira_key_ "$branch")" ]]; then
            filtered_branches+=("$branch")
          fi
        else
          filtered_branches+=("$branch")
        fi
      done
    fi
  else
    filtered_branches=("${branch_results[@]}")
  fi

  if [[ -z "$filtered_branches" ]]; then
    if (( select_branches_is_s )); then
      print -n " excluding special branches, " >&2
    else
      print -n " " >&2
    fi

    print -n "did not " >&2

    if [[ -n "$search_arg" ]]; then
      if (( select_branches_is_x )); then
        print -n "exactly match " >&2
      else
        print -n "match " >&2
      fi
    else
      print -n "find " >&2
    fi

    if [[ -n "$branches_excluded" ]]; then
      print -n "another " >&2
    else
      print -n "a " >&2
    fi

    if (( select_branches_is_a )); then
      print -n "remote or local branch" >&2
    elif (( select_branches_is_r )); then
      print -n "remote branch" >&2
    else
      print -n "local branch" >&2
    fi

    print -n " known to git" >&2

    if [[ -n "$search_arg" ]]; then
      print -n ": $search_arg" >&2
    fi

    print "" >&2
    return 1;
  fi

  # current branch if found and it's the only one
  if (( select_branches_is_c )); then
    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

    if (( ${#filtered_branches[@]} == 1 )) && [[ -n "$my_branch" ]]; then
      local my_remote_branch="${remote_name}/${my_branch}"

      if [[ "${filtered_branches[1]}" == "$my_remote_branch" || "${filtered_branches[1]}" == "$my_branch" ]]; then
        echo "$my_branch"
        return 0;
      fi
    fi
  fi

  # if (( ! select_branches_is_c && ${#filtered_branches[@]} == 1 )); then
  #   echo "${filtered_branches[@]}"

  #   return;
  # fi

  if (( select_branches_is_1 )); then
    local branch_choice=""

    if [[ "$header" == to* ]]; then
      header="branch $header"
    fi

    if (( select_branches_is_i )) && [[ -n "$search_arg" ]]; then
      branch_choice="$(choose_one_ -i "$header" "${filtered_branches[@]}")"
    else
      branch_choice="$(choose_one_ "$header" "${filtered_branches[@]}")"
    fi
    if (( $? == 130 )); then return 130; fi

    echo "$branch_choice"
    return 0;
  fi

  local branch_choices=""

  if [[ "$header" == to* ]]; then
    header="branches $header"
  fi

  if (( select_branches_is_i )) && [[ -n "$search_arg" ]]; then
    branch_choices="$(choose_multiple_ -i "$header" "${filtered_branches[@]}")"
  else
    branch_choices="$(choose_multiple_ "$header" "${filtered_branches[@]}")"
  fi
  if (( $? == 130 )); then return 130; fi

  echo "${branch_choices[@]}"
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

  # slow method using npm
  # local npm_version="$(npm --version 2>/dev/null)"
  # if is_version_higher_ "$npm_version" 7.20; then
  #   if [[ -n "$section" ]]; then key_name="$section.$key_name"; fi
  #   value="$(npm --prefix "$folder" pkg get $key_name --workspaces=false 2>/dev/null | tr -d '"')"

  #   if [[ "$value" == "{}" ]]; then value=""; fi

  #   echo "$value"
  #   return 0;
  # fi

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
    value="$(grep -E "\"$escaped_key\"[[:space:]]*:[[:space:]]*\"" "$real_file" | \
      head -1 | \
      sed -E "s/.*\"$escaped_key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/"
    2>/dev/null)"
  fi

  if [[ "$value" == "{}" ]]; then
    value="";
  fi

  echo "$value"
}


function load_default_config_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( load_default_config_is_debug )) && set -x

  local i="$1"

  if (( i == 0 )); then
    PUMP_SHORT_NAME[0]=""
    PUMP_FOLDER[0]="$PWD"
    PUMP_REPO[0]="$(get_repo_ "$PWD" 2>/dev/null)"
    PUMP_SINGLE_MODE[0]="1"
    PUMP_PKG_MANAGER[0]="$(detect_pkg_manager_ "${PUMP_FOLDER[0]}")"
    PUMP_PKG_NAME[0]="$(get_pkg_name_ "${PUMP_FOLDER[0]}" "" 1)"
  fi

  if [[ -n "${PUMP_PKG_MANAGER[$i]}" ]]; then
    PUMP_TEST[$i]="${PUMP_PKG_MANAGER[$i]} test" # important to be "npm test" and not "npm run test" (checking in pr)
    PUMP_COV[$i]="${PUMP_PKG_MANAGER[$i]} run test:coverage"
    PUMP_TEST_WATCH[$i]="${PUMP_PKG_MANAGER[$i]} run test:watch"
    PUMP_E2E[$i]="${PUMP_PKG_MANAGER[$i]} run test:e2e"
    PUMP_E2EUI[$i]="${PUMP_PKG_MANAGER[$i]} run test:e2e-ui"
  else
    PUMP_TEST[$i]=""
    PUMP_COV[$i]=""
    PUMP_TEST_WATCH[$i]=""
    PUMP_E2E[$i]=""
    PUMP_E2EUI[$i]=""
  fi
}

function read_config_entry_json_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  # (( read_config_entry_json_is_debug )) && set -x

  local i="$1"
  local key="$2"

  if [[ -z "$i" || -z "$key" ]]; then return 1; fi
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then return 1; fi
  if ! command -v jq &>/dev/null; then fi

  local value=""

  if (( i > 0 && i < 10 )); then
    local array_idx=$((i - 1))  # JSON arrays are 0-indexed
    value="$(jq -r ".projects[$array_idx].$key // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    if (( $? != 0 )); then return 1; fi
    
    # jq returns empty string for null/missing values
    if [[ "$value" == "null" ]]; then
      value=""
    fi

    value="$(trim_ $value)"
  fi

  # if value is not provided, use default value for specific keys
  if (( read_config_entry_json_is_d )) && [[ -z "$value" ]]; then
    case "$key" in
      PUMP_USE)
        value="node"
        ;;
      PUMP_PR_TEMPLATE_FILE)
        value=".github/pull_request_template.md"
        ;;
      PUMP_PR_TITLE_FORMAT)
        value="<jira_key> <jira_title>"
        ;;
    esac
  fi

  print -r -- "$value"
}

function read_config_entry_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  # (( read_config_entry_is_debug )) && set -x

  local i="$1"
  local key="$2"

  if [[ -z "$i" || -z "$key" ]]; then return 1; fi
  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then return 1; fi

  local value=""

  if (( i > 0 && i < 10 )); then
    value="$(sed -n "s/^${key}_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    if (( $? != 0 )); then return 1; fi

    value="$(trim_ $value)"
  fi

  # if value is not provided, use default value for specific keys
  if (( read_config_entry_is_d )) && [[ -z "$value" ]]; then
    case "$key" in
      PUMP_USE)
        value="node"
        ;;
      PUMP_PR_TEMPLATE_FILE)
        value=".github/pull_request_template.md"
        ;;
      PUMP_PR_TITLE_FORMAT)
        value="<jira_key> <jira_title>"
        ;;
    esac
  fi

  print -r -- "$value"
}

function load_config_() {
  set +x

  local i="$1"

  if [[ -z "$i" ]]; then return 1; fi

  local keys=(
    PUMP_PKG_MANAGER # make sure pkg_manager is before anything
    PUMP_CLONE
    PUMP_SETUP
    PUMP_FIX
    PUMP_RUN
    PUMP_RUN_STAGE
    PUMP_RUN_PROD
    PUMP_RUN_QA
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
    PUMP_JIRA_READY_FOR_TEST
    PUMP_JIRA_ALMOST_DONE
    PUMP_JIRA_DONE
    PUMP_JIRA_CANCELED
    PUMP_JIRA_BLOCKED
    PUMP_JIRA_WORK_TYPES
    PUMP_NVM_USE_V
    PUMP_SCRIPT_FOLDER
    PUMP_GHA_DEPLOY
    PUMP_GO_BACK
    PUMP_VERSION_WEB
    PUMP_VERSION_CMD
  )

  local key=""
  for key in "${keys[@]}"; do
    local value=""
    value="$(read_config_entry_ -d $i "$key" 2>/dev/null)"
    if (( $? != 0 )); then continue; fi

    # store the value
    case "$key" in
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
      PUMP_RUN_QA)
        PUMP_RUN_QA[$i]="$value"
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
        if [[ "$value" != <-> ]]; then value=""; fi
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
        if [[ "$value" != <-> ]]; then value=""; fi
        PUMP_PR_APPEND[$i]="$value"
        ;;
      PUMP_PR_APPROVAL_MIN)
        if [[ "$value" != <-> ]]; then value=""; fi
        PUMP_PR_APPROVAL_MIN[$i]="$value"
        ;;
      PUMP_COMMIT_SIGNOFF)
        if [[ "$value" != <-> ]]; then value=""; fi
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
      PUMP_JIRA_READY_FOR_TEST)
        PUMP_JIRA_READY_FOR_TEST[$i]="$value"
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
      PUMP_JIRA_BLOCKED)
        PUMP_JIRA_BLOCKED[$i]="$value"
        ;;
      PUMP_JIRA_WORK_TYPES)
        PUMP_JIRA_WORK_TYPES[$i]="$value"
        ;;
      PUMP_NVM_USE_V)
        PUMP_NVM_USE_V[$i]="$value"
        ;;
      PUMP_SCRIPT_FOLDER)
        PUMP_SCRIPT_FOLDER[$i]="$value"
        ;;
      PUMP_GHA_DEPLOY)
        PUMP_GHA_DEPLOY[$i]="$value"
        ;;
      PUMP_GO_BACK)
        PUMP_GO_BACK[$i]="$value"
        ;;
      PUMP_VERSION_WEB)
        PUMP_VERSION_WEB[$i]="$value"
        ;;
      PUMP_VERSION_CMD)
        PUMP_VERSION_CMD[$i]="$value"
        ;;
    esac
    # print "$i - key: [$key], value: [$value]"
  done
}

function load_global_settings_() {
  # set +x
  # eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( load_global_settings_is_debug )) && set -x

  if ! check_file_ "$PUMP_SETTINGS_FILE"; then
    print " ${red_cor}fatal: settings file is invalid, cannot update config: $PUMP_SETTINGS_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  if ! command -v jq &>/dev/null; then
    print " ${red_cor}error: jq is required to read JSON config${reset_cor}" >&2
    print " install jq: ${hi_yellow_cor}brew install jq${reset_cor} (macOS) or ${hi_yellow_cor}sudo apt-get install jq${reset_cor} (Linux)" >&2
    return 1
  fi

  PUMP_SKIP_DETECT_NODE="$(sed -n "s/^PUMP_SKIP_DETECT_NODE=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_SKIP_DETECT_NODE="$(trim_ $PUMP_SKIP_DETECT_NODE)"
  if [[ "$PUMP_SKIP_DETECT_NODE" != "0" && "$PUMP_SKIP_DETECT_NODE" != "1" ]]; then
    PUMP_SKIP_DETECT_NODE=""
    update_setting_ -f "PUMP_SKIP_DETECT_NODE" "$PUMP_SKIP_DETECT_NODE" &>/dev/null
  fi

  PUMP_NODE_REQ_SAME_MINOR="$(sed -n "s/^PUMP_NODE_REQ_SAME_MINOR=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_NODE_REQ_SAME_MINOR="$(trim_ $PUMP_NODE_REQ_SAME_MINOR)"
  if [[ "$PUMP_NODE_REQ_SAME_MINOR" != "0" && "$PUMP_NODE_REQ_SAME_MINOR" != "1" ]]; then
    PUMP_NODE_REQ_SAME_MINOR=""
    update_setting_ -f "PUMP_NODE_REQ_SAME_MINOR" "$PUMP_NODE_REQ_SAME_MINOR" &>/dev/null
  fi

  PUMP_CODE_EDITOR="$(sed -n "s/^PUMP_CODE_EDITOR=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_CODE_EDITOR="$(trim_ $PUMP_CODE_EDITOR)"

  PUMP_MERGE_TOOL="$(sed -n "s/^PUMP_MERGE_TOOL=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_MERGE_TOOL="$(trim_ $PUMP_MERGE_TOOL)"

  PUMP_PUSH_NO_VERIFY="$(sed -n "s/^PUMP_PUSH_NO_VERIFY=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_PUSH_NO_VERIFY="$(trim_ $PUMP_PUSH_NO_VERIFY)"
  if [[ "$PUMP_PUSH_NO_VERIFY" != "0" && "$PUMP_PUSH_NO_VERIFY" != "1" ]]; then
    PUMP_PUSH_NO_VERIFY=""
  fi

  PUMP_RUN_OPEN_COV="$(sed -n "s/^PUMP_RUN_OPEN_COV=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_RUN_OPEN_COV="$(trim_ $PUMP_RUN_OPEN_COV)"
  if [[ "$PUMP_RUN_OPEN_COV" != "0" && "$PUMP_RUN_OPEN_COV" != "1" ]]; then
    PUMP_RUN_OPEN_COV=""
  fi

  PUMP_USE_MONOGRAM="$(sed -n "s/^PUMP_USE_MONOGRAM=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_USE_MONOGRAM="$(trim_ $PUMP_USE_MONOGRAM)"
  if [[ ! "$PUMP_USE_MONOGRAM" =~ ^[a-zA-Z]{1,2}$ && "$PUMP_USE_MONOGRAM" != 0 ]]; then
    PUMP_USE_MONOGRAM=""
  fi

  PUMP_INTERVAL="$(sed -n "s/^PUMP_INTERVAL=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_INTERVAL="$(trim_ $PUMP_INTERVAL)"
  if [[ -z "$PUMP_INTERVAL" || ! "$PUMP_INTERVAL" =~ ^[0-9]+$ ]]; then
    PUMP_INTERVAL=""
  fi

  PUMP_JIRA_ALERT="$(sed -n "s/^PUMP_JIRA_ALERT=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_JIRA_ALERT="$(trim_ $PUMP_JIRA_ALERT)"
  if [[ -z "$PUMP_JIRA_ALERT" || ! "$PUMP_JIRA_ALERT" =~ ^[0-9]+$ ]]; then
    PUMP_JIRA_ALERT=0
  fi

  PUMP_UPDATE_DAY="$(sed -n "s/^PUMP_UPDATE_DAY=\\([^ ]*\\)/\\1/p" "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_UPDATE_DAY="$(trim_ $PUMP_UPDATE_DAY)"
  if [[ -z "$PUMP_UPDATE_DAY" || ! "$PUMP_UPDATE_DAY" =~ ^[0-9]+$ ]] || (( PUMP_UPDATE_DAY < 1 || PUMP_UPDATE_DAY > 7 )); then
    PUMP_UPDATE_DAY="$(( (RANDOM % 7) + 1 ))"
    update_setting_ -f "PUMP_UPDATE_DAY" "$PUMP_UPDATE_DAY"
  fi
}

function load_project_config_() {
  load_config_ 0

  if [[ ! -f "$PUMP_CONFIG_FILE" ]]; then return 1; fi

  local error_msgs=()

  # iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    proj_cmd="$(sed -n "s/^PUMP_SHORT_NAME_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=("$(grep "^PUMP_SHORT_NAME_${i}=" "$PUMP_CONFIG_FILE" 2>/dev/null)")
      print " "
      continue;
    fi

    proj_cmd="$(trim_ $proj_cmd)"
    
    # skip if not defined
    if [[ -z "$proj_cmd" ]]; then continue; fi

    if ! validate_proj_cmd_strict_ $i "$proj_cmd"; then
      error_msgs+=("$(grep "^PUMP_SHORT_NAME_${i}=" "$PUMP_CONFIG_FILE" 2>/dev/null)")
      continue;
    fi

    # project folder path
    local proj_folder=""
    proj_folder="$(sed -n "s/^PUMP_FOLDER_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=("$(grep "^PUMP_FOLDER_${i}=" "$PUMP_CONFIG_FILE" 2>/dev/null)")
      continue;
    fi

    proj_folder="$(trim_ $proj_folder)"
    proj_folder="${proj_folder%/}"

    # skip if not defined
    if [[ -z "$proj_folder" ]]; then continue; fi

    # project repo
    local proj_repo=""
    proj_repo="$(sed -n "s/^PUMP_REPO_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=("$(grep "^PUMP_REPO_${i}=" "$PUMP_CONFIG_FILE" 2>/dev/null)")
      continue;
    fi

    proj_repo="$(trim_ $proj_repo)"

    # set single_mode
    local single_mode=""
    single_mode="$(sed -n "s/^PUMP_SINGLE_MODE_${i}=\\([^ ]*\\)/\\1/p" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=("$(grep "^PUMP_SINGLE_MODE_${i}=" "$PUMP_CONFIG_FILE" 2>/dev/null)")
      continue;
    fi

    single_mode="$(trim_ $single_mode)"

    if [[ "$single_mode" != "0" && "$single_mode" != "1" ]]; then
      single_mode=1
    fi

    single_mode="$(get_proj_mode_from_folder_ "$proj_folder" "$single_mode")"

    update_config_ $i "PUMP_SINGLE_MODE" "$single_mode" &>/dev/null

    PUMP_SHORT_NAME[$i]="$proj_cmd"
    PUMP_FOLDER[$i]="$proj_folder"
    PUMP_REPO[$i]="$proj_repo"
    PUMP_SINGLE_MODE[$i]="$single_mode"

    load_config_ $i
  done

  if [[ -n "$error_msgs" ]]; then
    print " ${orange_cor}error in setting:${reset_cor}" 2>/dev/tty
    printf " ${orange_cor}  • %s\n" "${error_msgs[@]}${reset_cor}" 2>/dev/tty
    print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
  fi
}

function load_global_settings_json_() {
  if ! check_file_ "$PUMP_SETTINGS_FILE"; then
    print " ${red_cor}fatal: settings file is invalid, cannot update config: $PUMP_SETTINGS_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  if ! command -v jq &>/dev/null; then
    print " ${red_cor}error: jq is required to read JSON config${reset_cor}" >&2
    print " install jq: ${hi_yellow_cor}brew install jq${reset_cor} (macOS) or ${hi_yellow_cor}sudo apt-get install jq${reset_cor} (Linux)" >&2
    return 1
  fi

  PUMP_SKIP_DETECT_NODE="$(jq -r '.PUMP_SKIP_DETECT_NODE // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_SKIP_DETECT_NODE="$(trim_ $PUMP_SKIP_DETECT_NODE)"
  if [[ "$PUMP_SKIP_DETECT_NODE" != "0" && "$PUMP_SKIP_DETECT_NODE" != "1" ]]; then
    PUMP_SKIP_DETECT_NODE=""
    update_setting_ -f "PUMP_SKIP_DETECT_NODE" "$PUMP_SKIP_DETECT_NODE" &>/dev/null
  fi

  PUMP_NODE_REQ_SAME_MINOR="$(jq -r '.PUMP_NODE_REQ_SAME_MINOR // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_NODE_REQ_SAME_MINOR="$(trim_ $PUMP_NODE_REQ_SAME_MINOR)"
  if [[ "$PUMP_NODE_REQ_SAME_MINOR" != "0" && "$PUMP_NODE_REQ_SAME_MINOR" != "1" ]]; then
    PUMP_NODE_REQ_SAME_MINOR="1"
    update_setting_ -f "PUMP_NODE_REQ_SAME_MINOR" "$PUMP_NODE_REQ_SAME_MINOR" &>/dev/null
  fi

  PUMP_CODE_EDITOR="$(jq -r '.PUMP_CODE_EDITOR // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_CODE_EDITOR="$(trim_ $PUMP_CODE_EDITOR)"

  PUMP_MERGE_TOOL="$(jq -r '.PUMP_MERGE_TOOL // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_MERGE_TOOL="$(trim_ $PUMP_MERGE_TOOL)"

  PUMP_PUSH_NO_VERIFY="$(jq -r '.PUMP_PUSH_NO_VERIFY // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_PUSH_NO_VERIFY="$(trim_ $PUMP_PUSH_NO_VERIFY)"
  if [[ "$PUMP_PUSH_NO_VERIFY" != "0" && "$PUMP_PUSH_NO_VERIFY" != "1" ]]; then
    PUMP_PUSH_NO_VERIFY=""
  fi

  PUMP_RUN_OPEN_COV="$(jq -r '.PUMP_RUN_OPEN_COV // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_RUN_OPEN_COV="$(trim_ $PUMP_RUN_OPEN_COV)"
  if [[ "$PUMP_RUN_OPEN_COV" != "0" && "$PUMP_RUN_OPEN_COV" != "1" ]]; then
    PUMP_RUN_OPEN_COV=""
  fi

  PUMP_USE_MONOGRAM="$(jq -r '.PUMP_USE_MONOGRAM // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_USE_MONOGRAM="$(trim_ $PUMP_USE_MONOGRAM)"
  if [[ ! "$PUMP_USE_MONOGRAM" =~ ^[a-zA-Z]{1,2}$ && "$PUMP_USE_MONOGRAM" != "0" ]]; then
    PUMP_USE_MONOGRAM=""
  fi

  PUMP_INTERVAL="$(jq -r '.PUMP_INTERVAL // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_INTERVAL="$(trim_ $PUMP_INTERVAL)"
  if [[ -z "$PUMP_INTERVAL" || ! "$PUMP_INTERVAL" =~ ^[0-9]+$ ]]; then
    PUMP_INTERVAL=""
  fi

  PUMP_UPDATE_DAY="$(jq -r '.PUMP_UPDATE_DAY // empty' "$PUMP_SETTINGS_FILE" 2>/dev/null)"
  PUMP_UPDATE_DAY="$(trim_ $PUMP_UPDATE_DAY)"
  if [[ -z "$PUMP_UPDATE_DAY" || ! "$PUMP_UPDATE_DAY" =~ ^[0-9]+$ ]] || (( PUMP_UPDATE_DAY < 1 || PUMP_UPDATE_DAY > 7 )); then
    PUMP_UPDATE_DAY="$(( (RANDOM % 7) + 1 ))"
    update_setting_ -f "PUMP_UPDATE_DAY" "$PUMP_UPDATE_DAY" &>/dev/null
  fi
}

function load_project_config_json_() {
  if ! check_file_ "$PUMP_CONFIG_FILE"; then
    print " ${red_cor}fatal: config file is invalid, cannot update config: $PUMP_CONFIG_FILE${reset_cor}" >&2
    print " re-install pump:" >&2
    print " curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh" >&2
    return 1;
  fi

  local error_msgs=()

  # iterate over the first 10 project configurations
  local i=0
  for i in {1..9}; do
    local proj_cmd=""
    local array_idx=$((i - 1))  # JSON arrays are 0-indexed
    
    proj_cmd="$(jq -r ".projects[$array_idx].PUMP_SHORT_NAME // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=(".projects[$array_idx].PUMP_SHORT_NAME")
      print " "
      continue;
    fi

    proj_cmd="$(trim_ $proj_cmd)"
    
    # skip if not defined
    if [[ -z "$proj_cmd" ]]; then continue; fi

    if ! validate_proj_cmd_strict_ $i "$proj_cmd"; then
      error_msgs+=(".projects[$array_idx].PUMP_SHORT_NAME = \"$proj_cmd\"")
      continue;
    fi

    # project folder path
    local proj_folder=""
    proj_folder="$(jq -r ".projects[$array_idx].PUMP_FOLDER // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=(".projects[$array_idx].PUMP_FOLDER")
      continue;
    fi

    proj_folder="$(trim_ $proj_folder)"
    proj_folder="${proj_folder%/}"

    # skip if not defined
    if [[ -z "$proj_folder" ]]; then continue; fi

    # project repo
    local proj_repo=""
    proj_repo="$(jq -r ".projects[$array_idx].PUMP_REPO // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=(".projects[$array_idx].PUMP_REPO")
      continue;
    fi

    proj_repo="$(trim_ $proj_repo)"

    # set single_mode
    local single_mode=""
    single_mode="$(jq -r ".projects[$array_idx].PUMP_SINGLE_MODE // empty" "$PUMP_CONFIG_FILE" 2>/dev/null)"
    
    if (( $? != 0 )); then
      error_msgs+=(".projects[$array_idx].PUMP_SINGLE_MODE")
      continue;
    fi

    single_mode="$(trim_ $single_mode)"

    if [[ "$single_mode" != "0" && "$single_mode" != "1" ]]; then
      single_mode=0
    fi

    single_mode="$(get_proj_mode_from_folder_ "$proj_folder" "$single_mode")"

    update_config_ $i "PUMP_SINGLE_MODE" "$single_mode" &>/dev/null

    PUMP_SHORT_NAME[$i]="$proj_cmd"
    PUMP_FOLDER[$i]="$proj_folder"
    PUMP_REPO[$i]="$proj_repo"
    PUMP_SINGLE_MODE[$i]="$single_mode"

    load_config_ $i
  done

  if [[ -n "$error_msgs" ]]; then
    print " ${orange_cor}error in setting:${reset_cor}" 2>/dev/tty
    printf " ${orange_cor}  • %s\n" "${error_msgs[@]}${reset_cor}" 2>/dev/tty
    print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" 2>/dev/tty
  fi
}

function get_my_branch_status_() {
  local my_branch="$1"
  local base_branch="$2"
  local folder="${3:-$PWD}"

  if [[ -z "$my_branch" || -z "$base_branch" ]]; then
    echo "0${TAB}0"
    return 1;
  fi

  local behind=0
  local ahead=0

  read behind ahead < <(git -C "$folder" rev-list --left-right --count ${base_branch}...${my_branch} 2>/dev/null)

  echo "${behind}|${ahead}"
}

function del_file_() {
  set +x
  eval "$(parse_simple_flags_ "$0" "f" "" "$@")"
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

  pre_delete_folder_ "$file"

  if command -v gum &>/dev/null; then
    gum spin --title="deleting... ${green_cor}$file${reset_cor}" -- rm -rf -- "$file"
  else
    print " deleting... ${green_cor}$file${reset_cor}"
    rm -rf -- "$file"
  fi
  RET=$?

  if (( RET == 0 )); then
    print -l -- " ${magenta_cor}deleted${reset_cor} $file"
    return 0;
  fi

  print -l -- " ${red_cor}not deleted${reset_cor} $file" >&2
  return 1;
}

function pre_delete_folder_() {
  local folder="$1"

  if [[ -d "$folder" ]]; then
    add-zsh-hook -d chpwd pump_chpwd_ &>/dev/null
    while [[ "${PWD:A}/" == "${folder:A}/"* ]]; do
      cd ..
    done
    add-zsh-hook chpwd pump_chpwd_ &>/dev/null
  fi
}

function del_files_() {
  set +x
  eval "$(parse_simple_flags_ "$0" "f" "x" "$@")"
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
  eval "$(parse_simple_flags_ "$0" "f" "x" "$@")"
  (( del_is_debug )) && set -x

  if (( del_is_h )); then
    print "  ${hi_yellow_cor}del ${yellow_cor}[<glob>]${reset_cor} : delete files/folders"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation (files only)"
    return 0;
  fi

  rm -rf -- ".DS_Store"

  if [[ -n "$1" && -z "${1//\/}" ]]; then
    return 1;
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

if [[ "$(uname)" == "Darwin" ]] && command -v softwareupdate &>/dev/null; then
function macdown() {
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( macdown_is_debug )) && set -x

  if (( macdown_is_h )); then
    print "  ${hi_yellow_cor}macdown${reset_cor} : download full installers of macos"
    return 0;
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
fi

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
    print "  ${hi_yellow_cor}  -q${reset_cor} : quiet, no output"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_pkg_ "$folder"; then return 1; fi

  if ! fix_it_ "$folder" "$@"; then
    print " ${red_cor}fatal: fix failed${reset_cor}" >&2
    return 1;
  fi
}

function fix_it_() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( fix_it_is_debug )) && set -x

  local folder="$1"

  local _pwd="$(pwd)"

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
    if format_ "$folder" "$@"; then
      if lint_ "$folder" "$@"; then
        if format_ "$folder" "$@"; then
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

  local _prettierfix="$(get_from_package_json_ "scripts.prettier:fix" "$folder" 2>/dev/null)"
  local _formatfix="$(get_from_package_json_ "scripts.format:fix" "$folder" 2>/dev/null)"
  local _prettier="$(get_from_package_json_ "scripts.prettier" "$folder" 2>/dev/null)"
  local _format="$(get_from_package_json_ "scripts.format" "$folder" 2>/dev/null)"

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

  eval_script_ "$script" "$@"
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

  local _lintfix="$(get_from_package_json_ "scripts.lint:fix" "$folder" 2>/dev/null)"
  local _lint="$(get_from_package_json_ "scripts.lint" "$folder" 2>/dev/null)"
  local _eslintfix="$(get_from_package_json_ "scripts.eslint:fix" "$folder" 2>/dev/null)"
  local _eslint="$(get_from_package_json_ "scripts.eslint" "$folder" 2>/dev/null)"

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

  eval_script_ "$script" "$@"
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
    print "  ${hi_yellow_cor}  -n${reset_cor} : create a new commit instead of amending"
    print "  ${hi_yellow_cor}  -p${reset_cor} : push after commit"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  if ! is_folder_pkg_ "$folder"; then return 1; fi

  if ! fix "$@"; then
    print "" >&2
    print " ${red_cor}refix aborted${reset_cor}" >&2
    return 1;
  fi

  if is_branch_status_clean_ "$folder"; then
    print "" >&2
    print " ${green_cor}nothing to commit, working tree clean${reset_cor}" >&2
    return 0; # nothing to push
  fi

  if (( refix_is_n )); then
    if ! commit -afq "style: lint and format" "$folder" "$@"; then
      return 1;
    fi
  else
    if ! commit -eafq "" "$folder" "$@"; then
      if ! commit -afq "style: lint and format" "$folder" "$@"; then
        return 1;
      fi
    fi
  fi

  if (( refix_is_p )); then
    pushf "$folder" "$@"
  fi
}

function covc_() {
  eval "$(parse_flags_ "$0" "x" "" "$@")"

  local folder="$PWD"

  if ! check_gum_; then return 1; fi
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
    print " ${red_cor}setting is missing: PUMP_REPO_${i}${reset_cor}" >&2
    print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  if [[ -z "$pump_cov" ]]; then
    print " ${red_cor}setting is missing: PUMP_COV_${i}${reset_cor}" >&2
    print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    return 1;
  fi

  local branch="$1"

  if [[ -n "$branch" ]]; then
    if ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi
  fi

  local short_branch="$(get_short_name_ "$branch" "$folder")"
  local remote_branch="$(get_remote_branch_ -f "$branch" "$folder")"

  if [[ -z "$remote_branch" ]]; then
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

  if [[ "$short_branch" == "$my_branch" ]]; then
    print " branch argument is current branch: $my_branch" >&2
    return 1;
  fi

  local branch_behind=0 branch_ahead=0
  local output=""
  output="$(get_my_branch_status_ "$my_branch" "$remote_branch" "$folder")"
  if (( $? == 0 )); then
    IFS="|" read -r branch_behind branch_ahead <<< "$output"
  fi

  if (( branch_behind )); then
    print " ${yellow_cor}warning:${reset_cor} your branch is behind $branch by ${bold_cor}$branch_behind${reset_cor} commits" >&2
    if ! confirm_ "continue anyway?" "continue" "abort"; then
      return 1;
    fi
  fi

  local cov_folder="$(get_proj_special_folder_ -c "$proj_cmd" "$proj_folder")"

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

  gum spin --title="running test coverage... ${branch}" -- sh -c "read < $pipe_name" &
  spin_pid=$!

  if is_folder_git_ "$cov_folder" &>/dev/null; then
    reseto "$cov_folder" --quiet &>/dev/null
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git -C "/" clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
    if (( $? != 0 )); then
      print " fatal: failed to clone ${repo_name}" >&2
      return 1;
    fi
  fi

  if git -C "$cov_folder" switch "$branch" --quiet &>/dev/null; then
    if ! pull -r "$cov_folder" --quiet &>/dev/null; then
      rm -rf -- "$cov_folder" &>/dev/null
      git -C "/" clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
      if (( $? != 0 )); then
        print " fatal: failed to clone ${repo_name}" >&2
        return 1;
      fi
    fi
  else
    rm -rf -- "$cov_folder" &>/dev/null
    git -C "/" clone --filter=blob:none "$proj_repo" "$cov_folder" --quiet &>/dev/null
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
    pump_setup="$(get_from_package_json_ "scripts.setup" "$cov_folder" 2>/dev/null)"
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

  print "   running test coverage... ${branch}"

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
    print " did not match any branch known to git: $branch" >&2
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
    "| \`${branch}\` | \`${my_branch}\` |"
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
    test_script="$(get_from_package_json_ "scripts.test" "$PWD" 2>/dev/null)"
  fi

  (eval "$CURRENT_PUMP_TEST" "$@")
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test passed on first run${reset_cor}"
    return 0;
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_TEST" "$@")
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
      PUMP_RUN_OPEN_COV=1
    else
      update_setting_ "PUMP_RUN_OPEN_COV" 0
      PUMP_RUN_OPEN_COV=0
    fi
  fi

  if (( cov_is_h )); then
    print "  ${hi_yellow_cor}cov <branch>${reset_cor} : compare test coverage of current local branch with a given branch"
    print "  ${hi_yellow_cor}cov${reset_cor} : run $(truncate_ $CURRENT_PUMP_COV)"
    (( PUMP_RUN_OPEN_COV )) && print "  ${hi_yellow_cor}  -o${reset_cor} : do not run PUMP_OPEN_COV script after coverage is done"
    (( ! PUMP_RUN_OPEN_COV )) && print "  ${hi_yellow_cor}  -o${reset_cor} : to run PUMP_OPEN_COV script after coverage is done"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    covc_ "$@"
    return $?;
  fi

  trap 'print ""; return 130' INT

  if ! is_folder_pkg_; then return 1; fi

  (eval "$CURRENT_PUMP_COV" "$@")
  local RET=$?
  
  if (( RET == 0 )); then
    print " ${green_cor}✓ test coverage passed on first run${reset_cor}"

    if (( PUMP_RUN_OPEN_COV && ! cov_is_o )) || (( ! PUMP_RUN_OPEN_COV && cov_is_o )); then
      if [[ -z "$CURRENT_PUMP_OPEN_COV" ]]; then
        print " ${red_cor}setting is missing: PUMP_OPEN_COV${reset_cor}" >&2
        print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
        return 1;
      fi
      eval "$CURRENT_PUMP_OPEN_COV"
    fi
    return 0;
  fi

  if (( CURRENT_PUMP_RETRY_TEST )); then
    (eval "$CURRENT_PUMP_COV" "$@")
    RET=$?

    if (( RET == 0 )); then
      print " ${green_cor}✓ test coverage passed on second run${reset_cor}"
      
      if (( PUMP_RUN_OPEN_COV && ! cov_is_o )) || (( ! PUMP_RUN_OPEN_COV && cov_is_o )); then
        if [[ -z "$CURRENT_PUMP_OPEN_COV" ]]; then
          print " ${red_cor}setting is missing: PUMP_OPEN_COV${reset_cor}" >&2
          print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
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

  eval "$CURRENT_PUMP_TEST_WATCH" "$@"
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
    eval "$CURRENT_PUMP_E2E" --project="$1" "${@:2}"
  else
    eval "$CURRENT_PUMP_E2E" "$@"
  fi
}

function e2eui() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( e2eui_is_debug )) && set -x

  if (( e2eui_is_h )); then
    print "  ${hi_yellow_cor}e2eui${reset_cor} : run PUMP_E2EUI"
    print "  ${hi_yellow_cor}e2eui <e2e_project>${reset_cor} : run PUMP_E2EUI --project <e2e_project>"
    return 0;
  fi

  if ! is_folder_pkg_; then return 1; fi

  if [[ -n "$1" && $1 != -* ]]; then
    eval "$CURRENT_PUMP_E2EUI" --project="$1" "${@:2}"
  else
    eval "$CURRENT_PUMP_E2EUI" "$@"
  fi
}

# github functions =========================================================
function add() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( add_is_debug )) && set -x

  if (( add_is_h )); then
    print "  ${hi_yellow_cor}add ${yellow_cor}[<glob>]${reset_cor} : add files to index"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  local selected_files=()

  if [[ -z "$1" ]]; then
    local files=($(get_branch_status_ -u "$folder" 2>/dev/null))

    if (( add_is_f )); then
      selected_files=("${files[@]}")
    else
      selected_files=($(choose_multiple_ -i "files to add to commit" "${files[@]}"))
      if (( $? == 130 )); then return 130; fi
    fi
  else
    local pattern="$*"

    selected_files=(${(z)~pattern})
  fi

  if [[ -z "$selected_files" ]]; then return 0; fi

  git -C "$folder" add -- "${selected_files[@]}"
}

# remove files from index
function rem() {
  set +x
  eval "$(parse_flags_ "$0" "f" "" "$@")"
  (( rem_is_debug )) && set -x

  if (( rem_is_h )); then
    print "  ${hi_yellow_cor}rem ${yellow_cor}[<glob>]${reset_cor} : remove files from index"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
    return 0;
  fi

  local folder="$PWD"

  if ! is_folder_git_ "$folder"; then return 1; fi

  local selected_files=()

  if [[ -z "$1" ]]; then
    local files=($(get_branch_status_ -i "$folder" 2>/dev/null))

    if (( rem_is_f )); then
      selected_files=("${files[@]}")
    else
      selected_files=($(choose_multiple_ -i "files to remove from commit" "${files[@]}"))
      if (( $? == 130 )); then return 130; fi
    fi
  else
    local pattern="$*"

    selected_files=(${(z)~pattern})
  fi

  if [[ -z "$selected_files" ]]; then return 0; fi

  local file=""
  for file in "${selected_files[@]}"; do
    git -C "$folder" restore --staged -- "$file"
  done
}

function reset1() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset1_is_debug )) && set -x

  if (( reset1_is_h )); then
    print "  ${hi_yellow_cor}reset1 ${yellow_cor}[<folder>]${reset_cor} : reset last commit"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -1 || true
  git -C "$folder" reset --soft --quiet HEAD~1 "$@"
}

function reset2() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset2_is_debug )) && set -x

  if (( reset2_is_h )); then
    print "  ${hi_yellow_cor}reset2 ${yellow_cor}[<folder>]${reset_cor} : reset 2 last commits"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -2 || true
  git -C "$folder" reset --soft --quiet HEAD~2 "$@"
}

function reset3() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset3_is_debug )) && set -x

  if (( reset3_is_h )); then
    print "  ${hi_yellow_cor}reset3 ${yellow_cor}[<folder>]${reset_cor} : reset 3 last commits"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -3 || true
  git -C "$folder" reset --soft --quiet HEAD~3 "$@"
}

function reset4() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset4_is_debug )) && set -x

  if (( reset4_is_h )); then
    print "  ${hi_yellow_cor}reset4 ${yellow_cor}[<folder>]${reset_cor} : reset 4 last commits"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -4 || true
  git -C "$folder" reset --soft --quiet HEAD~4 "$@"
}

function reset5() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( reset5_is_debug )) && set -x

  if (( reset5_is_h )); then
    print "  ${hi_yellow_cor}reset5 ${yellow_cor}[<folder>]${reset_cor} : reset 5 last commits"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" --no-pager log --oneline --decorate -5 || true
  git -C "$folder" reset --soft --quiet HEAD~5 "$@"
}

function read_commits_() {
  set +x
  eval "$(parse_flags_ "$0" "tj" "" "$@")"
  (( read_commits_is_debug )) && set -x
  
  local target_branch="$1"
  local my_branch="$2"
  local folder="${3:-$PWD}"

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -z "$my_branch" ]]; then
    my_branch="HEAD"
  fi

  if [[ -z "$target_branch" ]]; then
    local target_branch="$(get_base_branch_ -l "$my_branch" "$folder" 2>/dev/null)"
    if [[ -z "$target_branch" ]]; then
      print " fatal: cannot read commits with no target branch" >&2
      return 1;
    fi
  else
    local short_base_branch="$(get_short_name_ "$target_branch" "$folder")"
    target_branch="$(get_remote_branch_ -f "$short_base_branch" "$folder")"
  fi

  local pr_title_jira_key=""
  local pr_title_rest=""
  local commit_message=""

  local flags=()

  if (( ! read_commits_is_t )); then
    flags+=(--reverse)
  fi

  git -C "$folder" log --no-graph --oneline --no-merges -100 --pretty=format:'%H%x1F%s%x00' "${flags[@]}" \
    "${target_branch}..${my_branch}" | while IFS= read -r -d '' line; do

    local commit_hash="${line%%$'\x1F'*}"
    commit_hash="${commit_hash//$'\n'/}"
    
    commit_message="${line#*$'\x1F'}"

    commit_message="$(trim_ $commit_message)"

    if [[ -z "$commit_message" ]]; then
      continue;
    fi

    local commit_message_rest="$commit_message"
    local commit_jira_key="$(extract_jira_key_ "$commit_message")"
    
    if [[ -n "$commit_jira_key" ]]; then
      # save pr title
      if [[ -z "$pr_title_jira_key" ]]; then
        pr_title_jira_key="$commit_jira_key"
      fi

      commit_message_rest="$(trim_ ${commit_message//$commit_jira_key/})"

      if [[ -z "$pr_title_rest" ]]; then
        pr_title_rest="$commit_message_rest"

        local types="fix|feat|test|build|chore|ci|docs|perf|refactor|revert|style"
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
      # echo "- $commit_hash - $commit_message_rest"
      echo "- $commit_message_rest"
    fi
  done

  if (( read_commits_is_t )); then
    if [[ -z "$pr_title_jira_key" ]] && (( read_commits_is_j )); then
      return 1;
    fi

    echo "${pr_title_jira_key}${TAB}${pr_title_rest}"
  fi
}

function is_valid_jira_status_() {
  local i="$1"
  local value="$2"

  local statuses="$(check_jira_statuses_ -r $i)"

  if [[ -n "$statuses" ]]; then
    if ! echo "$statuses" | grep -Fxq "$value"; then
      print " fatal: not a valid jira status: $value" >&2
      return 1;
    fi
  fi

  return 0;
}

function is_valid_jira_key_() {
  local text="$1"

  if [[ $text =~ '^([A-Z][A-Z0-9]*(-[0-9]+)?|[0-9]+)$' ]]; then
    return 0;
  fi

  return 1;
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
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
    print "  ${hi_yellow_cor}  -l${reset_cor} : set labels"
    print "  ${hi_yellow_cor}  -lb${reset_cor} : set label type: bug or bugfix"
    print "  ${hi_yellow_cor}  -lc${reset_cor} : set label type: devops or ci or chore"
    print "  ${hi_yellow_cor}  -ld${reset_cor} : set label type: documentation"
    print "  ${hi_yellow_cor}  -le${reset_cor} : set label type: enhancement"
    print "  ${hi_yellow_cor}  -lr${reset_cor} : set label type: release"
    print "  ${hi_yellow_cor}  -ls${reset_cor} : set label type: story or feature"
    print "  ${hi_yellow_cor}  -t${reset_cor} : run tests before creating pull request"
    print "  ${hi_yellow_cor}  -x${reset_cor} : skip jira status transition"
    return 0;
  fi

  if ! check_gh_; then return 1; fi

  local title=""
  local folder=""

  eval "$(parse_args_ "$0" "title:to,folder:fz" "$@")"
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
    print " no upstream found for local branch: $my_branch" >&2
    if ! confirm_ -a "push branch to ${remote_name}?"; then
      return 1;
    fi
    push "$folder"
  fi

  local branch_behind=0 branch_ahead=0
  local output=""
  output="$(get_my_branch_status_ "$my_branch" "$my_remote_branch" "$folder")"
  if (( $? == 0 )); then
    IFS="|" read -r branch_behind branch_ahead <<< "$output"
  fi

  if (( branch_behind || branch_ahead )); then
    print " new commits are not pushed yet" >&2
    if ! confirm_ -a "push branch to ${remote_name}?"; then
      return 1;
    fi
    push "$folder"
  fi

  local proj_cmd="$CURRENT_PUMP_SHORT_NAME"
  local i="$(find_proj_index_ -x "$proj_cmd" 2>/dev/null)"

  local pump_pr_template_file="${PUMP_PR_TEMPLATE_FILE[$i]:-$CURRENT_PUMP_PR_TEMPLATE_FILE}"
  local pump_pr_replace="${PUMP_PR_REPLACE[$i]:-$CURRENT_PUMP_PR_REPLACE}"
  local pump_pr_title_format="${PUMP_PR_TITLE_FORMAT[$i]:-$CURRENT_PUMP_PR_TITLE_FORMAT}"
  local pump_test="${PUMP_TEST[$i]:-$CURRENT_PUMP_TEST}"
  local pump_pkg_manager="${PUMP_PKG_MANAGER[$i]:-$CURRENT_PUMP_PKG_MANAGER}"
  local pump_pr_append="${PUMP_PR_APPEND[$i]:-$CURRENT_PUMP_PR_APPEND}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"Code Review"}"

  if [[ -z "$pump_pr_title_format" ]]; then
    pump_pr_title_format="<jira_key> <jira_title>"
  fi

  local open_pr_url="$(get_pr_url_ -o "$my_branch" "$proj_repo")"

  if [[ -n "$open_pr_url" ]]; then
    gh pr view  --repo "$proj_repo" --web $open_pr_url &>/dev/null
    print " pull request is up: ${blue_cor}$open_pr_url${reset_cor}" >&2
    return 0;
  fi

  if get_branch_status_ "$folder" 1>/dev/null; then
    if (( pr_is_t )); then
      print " cannot create pull request with -t option because there are unstaged changes" >&2
      return 1;
    fi

    if (( ! pr_is_f )); then
      confirm_ -a "abort or continue anyway?" "abort" "continue"
      local _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 0 )); then return 0; fi
    fi
  fi

  if (( pr_is_t )); then
    local test_script=""

    if [[ -z "$pump_pkg_manager" ]]; then
      pump_pkg_manager="$(detect_pkg_manager_ "$folder")"
      if [[ -z "$pump_pkg_manager" ]]; then
        print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
        return 1;
      fi
    fi

    if [[ -n "$pump_test" && "$pump_test" != "$pump_pkg_manager test" ]]; then
      test_script="$pump_test"
    else
      test_script="$(get_from_package_json_ "scripts.test" "$folder" 2>/dev/null)"
    fi

    if [[ -n "$test_script" ]]; then
      if test "$folder"; then
        return 1;
      fi
    fi
  fi

  local is_read_commits=1
  local target_branch="$(get_base_branch_ "$my_branch" "$folder" 2>/dev/null)"

  if [[ -n "$target_branch" ]] && (( ! pr_is_f )); then
    confirm_ -a "target branch: ${pink_cor}$target_branch${reset_cor}?"
    local _RET=$?
    if (( _RET == 130 || _RET == 2 )); then return 130; fi
    if (( _RET == 1 )); then
      target_branch=""
      is_read_commits=0
    fi
  fi

  if [[ -z "$target_branch" ]]; then
    if (( pr_is_f )); then
      if [[ -z "$target_branch" ]]; then
        print " fatal: cannot determine target branch for pr" >&2
        return 1;
      fi
    else
      target_branch="$(determine_target_branch_ -dbtm "$my_branch" "$folder")"
      if [[ -z "$target_branch" ]]; then return 1; fi
    fi
  fi

  if [[ "$my_branch" == "$target_branch" ]]; then
    print " fatal: cannot create pull request to the same branch: $my_branch" >&2
    return 1;
  fi

  local remote_target_branch="$(get_remote_branch_ -f "$target_branch" "$folder")"
  local branch_behind=0 branch_ahead=0
  output="$(get_my_branch_status_ "$my_branch" "$remote_target_branch" "$folder")"
  if (( $? == 0 )); then
    IFS="|" read -r branch_behind branch_ahead <<< "$output"
  fi

  if (( ! branch_ahead )); then
    print " fatal: no new commits found, cannot create pull request" >&2
    return 1;
  fi

  if (( branch_behind )); then
    print " ${yellow_cor}warning:${reset_cor} your branch is behind ${bold_cor}$remote_target_branch${reset_cor} by ${bold_cor}$branch_behind${reset_cor} commits" >&2

    if ! confirm_ -a "continue anyway?"; then
      return 1;
    fi
  fi

  local jira_key="$(read_pump_value_ "JIRA_KEY" "$folder")"
  local jira_title="$(read_pump_value_ "JIRA_TITLE" "$folder")"

  if [[ -z "$jira_key" ]]; then
    jira_key="$(extract_jira_key_ "$my_branch" "$folder")"
  fi

  if [[ -z "$jira_key" ]] || { [[ -z "$jira_title" ]] && [[ -z "$title" ]]; }; then
    local commit_key="" commit_title=""
    local output=""
    output="$(read_commits_ -t "$target_branch" "$my_branch" "$folder")"
    if (( $? == 0 )); then
      IFS=$TAB read -r commit_key commit_title <<< "$output"
    fi

    if [[ -z "$jira_key" && -n "$commit_key" ]]; then
      jira_key="$commit_key"
    fi

    if (( is_read_commits )) && [[ -z "$jira_title" && -n "$commit_title" ]]; then
      jira_title="$commit_title"
    fi
  fi

  if [[ -z "$title" ]]; then
    title="${pump_pr_title_format//\<jira_key\>/$jira_key}"
    title="${title//\<jira_title\>/$jira_title}"
  fi

  print " ${purple_cor}target branch:${reset_cor} $target_branch" >&2

  # if not skip confirmation
  if (( ! pr_is_f )); then
    title="$(input_type_mandatory_ "pull request title" "" 255 "$title")"
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
    local labl=""
    if command -v gum &>/dev/null; then
      labl="$(gum spin --title="pulling pull request labels..." -- gh label list --repo "$proj_repo" --json=name | jq -r '.[].name' | sort -rf 2>/dev/null)"
    else
      labl="$(gh label list --repo "$proj_repo" --json=name | jq -r '.[].name' | sort -rf 2>/dev/null)"
    fi
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
      if (( pr_is_c )) && [[ "$label" == "devops" || "$label" == "ci" || "$label" == "chore" ]]; then
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
    local commit_messages=""

    if (( is_read_commits )); then
      commit_messages="$(read_commits_ "$target_branch" "$my_branch" "$folder")"
    fi

    pr_body="${(F)commit_messages}"

    local pr_template="$(cat "$pump_pr_template_file" 2>/dev/null)"

    if (( ! pr_is_f )) && [[ -z "$pump_pr_replace" ]]; then
      if command -v gum &>/dev/null; then
        gum style --align=left --margin="0" --padding="0" --border=normal --width=70 --border-foreground 99 "$pr_template"
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
        local _RET=$?

        if (( _RET == 130 || _RET == 2 )); then return 130; fi

        update_config_ $i "PUMP_PR_REPLACE" "$pr_replace"
        update_config_ $i "PUMP_PR_APPEND" "$_RET"
        
        PUMP_PR_REPLACE[$i]="$pr_replace"
        PUMP_PR_APPEND[$i]="$_RET"
        
        pump_pr_replace="$pr_replace"
        pump_pr_append="$_RET"
      fi
    fi

    if [[ -n "$pump_pr_replace" && -n "$pr_body" ]] && command -v perl &>/dev/null; then
      if (( pump_pr_append )); then
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
    if [[ -n "$jira_key" ]] && command -v perl &>/dev/null; then
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
    pr_flags+=(--web)
  fi

  if [[ -z "$pr_body" ]]; then
    pr_flags+=(--fill)
  fi

  if gh pr create --repo "$proj_repo" --assignee="@me" --title="$title" --body="$pr_body" --head="$my_branch" --base="$short_base_branch" --label="$pr_labels" ${pr_flags[@]}; then
    if (( ! pr_is_x )); then
      if (( pr_is_f )); then
        update_jira_status_ -rf $i "$jira_key" "$jira_in_review"
      else
        update_jira_status_ -r $i "$jira_key" "$jira_in_review"
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
    if [[ -n "$CURRENT_PUMP_RUN_QA" ]]; then
      print "  ${hi_yellow_cor}run qa ${ellow_cor}[<folder>]${reset_cor} : run ${CURRENT_PUMP_SHORT_NAME}'s PUMP_RUN_QA in a ${CURRENT_PUMP_SHORT_NAME}'s folder"
    fi
    print "  ${hi_yellow_cor}run <script>${reset_cor} : run any current folder's script"  
    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      print "  ${hi_yellow_cor}run <script> ${ellow_cor}[<folder>]${reset_cor} : run any ${CURRENT_PUMP_SHORT_NAME}'s folder's script"
    else
      print "  ${hi_yellow_cor}run <script> ${yellow_cor}[<folder>]${reset_cor} : run any folder's script"
    fi
    return 0;
  fi

  proj_run_ "$@"
}

function proj_run_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_run_is_debug )) && set -x

  local proj=""
  local script=""
  local folder=""

  eval "$(parse_args_ "run" "proj:po,script:to,folder:fz" "$@")"
  shift $arg_count

  if (( proj_run_is_h )); then
    proj_print_help_ "$proj run"
    return 0;
  fi

  local proj_folder=""
  local single_mode=""
  local pkg_manager=""

  local i=0

  if [[ -n "$proj" ]]; then
    i="$(find_proj_index_ -o "$proj" "project to run")"
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

  if [[ -n "$proj" ]]; then
    if (( single_mode )); then
      if [[ -n "$2" && -z "$folder" ]]; then
        script="$2"
      fi

      folder_to_execute="$proj_folder"
    else
      if [[ -n "$2" && -z "$folder" ]]; then
        if [[ -d "${proj_folder}/$2" ]]; then
          folder="$2"
        else
          script="$2"
        fi
      fi

      local dirs=""
      dirs="$(get_folders_ -ijp $i "$proj_folder" "$folder" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      if [[ -z "$dirs" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder" >&2
        print " run: ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder="$(choose_one_ -it "folder in $proj_cmd to run" "${(@f)dirs}")"
      if [[ -z "$folder" ]]; then return 1; fi

      folder_to_execute="${proj_folder}/${folder}"
    fi
  else
    if [[ -n "$folder" ]]; then
      if [[ -d "$folder" ]]; then
        folder_to_execute="$folder"
      else
        print " fatal: not a valid folder argument: $folder" >&2
        print " run: ${hi_yellow_cor}run -h${reset_cor} to see usage" >&2
        return 1;
      fi
    else
      folder_to_execute="$PWD"
    fi
  fi

  folder_to_execute="$(realpath -- "$folder_to_execute")"

  if ! is_folder_pkg_ "$folder_to_execute"; then return 1; fi

  local run_script="${script:-dev}"
  
  local pump_run=""

  if [[ "$run_script" == "stage" ]]; then
    pump_run="${PUMP_RUN_STAGE[$i]}"
  elif [[ "$run_script" == "prod" ]]; then
    pump_run="${PUMP_RUN_PROD[$i]}"
  elif [[ "$run_script" == "qa" ]]; then
    pump_run="${PUMP_RUN_QA[$i]}"
  else
    pump_run="${PUMP_RUN[$i]}"
  fi

  print " running $run_script on ${cyan_cor}${folder_to_execute}${reset_cor}"

  local RET=0

  if [[ -z "$pump_run" ]]; then
    local pump_run_script="$(get_from_package_json_ "scripts.${run_script}" "$folder_to_execute" 2>/dev/null)"

    if [[ -z "$pkg_manager" ]]; then
      print " fatal: missing package manager, run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      return 1;
    fi

    if [[ -n "$pump_run_script" ]]; then
      pump_run="$pkg_manager run $run_script"
    
    elif [[ "$run_script" == "dev" && -z "$script" ]]; then
      local pump_run_start="$(get_from_package_json_ "scripts.start" "$folder_to_execute" 2>/dev/null)"

      if [[ -n "$pump_run_start" ]]; then
        pump_run="$pkg_manager start"
      else
        print " fatal: no '$run_script' or 'start' script in package.json"
        return 1;
      fi
    else
      print " fatal: no '$run_script' script in package.json"
      return 1;
    fi
    print " ${script_cor}${pump_run}${reset_cor}"
    
    ( cd "$folder_to_execute" && eval "$pump_run" )
    RET=$?

  else
    print " ${script_cor}${pump_run}${reset_cor}"

    ( cd "$folder_to_execute" && eval "$pump_run" )
    RET=$?

    if (( RET != 0 )); then
      if [[ "$run_script" == "stage" || "$run_script" == "prod" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_${run_script:U}_${i}${reset_cor}" >&2
        print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      elif [[ "$run_script" == "dev" ]]; then
        print " ${red_cor}failed to run PUMP_RUN_${i}${reset_cor}" >&2
        print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
      else
        print " ${red_cor}failed to run script: '$run_script'${reset_cor}" >&2
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

  proj_setup_ "$@"
}

function proj_setup_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_setup_is_debug )) && set -x

  local proj=""
  local folder=""

  eval "$(parse_args_ "run" "proj:po,folder:fz" "$@")"
  shift $arg_count

  if (( proj_setup_is_h )); then
    proj_print_help_ "$proj setup"
    return 0;
  fi

  local proj_folder=""
  local single_mode=""
  local pkg_manager=""
  local pump_setup=""

  local i=0

  if [[ -n "$proj" ]]; then
    i="$(find_proj_index_ -o "$proj" "project to setup")"
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

  if [[ -n "$proj" ]]; then
    if (( single_mode )); then
      folder_to_execute="$proj_folder"
    else
      local dirs=""
      dirs="$(get_folders_ -ijp $i "$proj_folder" "$folder" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi

      if [[ -z "$dirs" ]]; then
        print " fatal: no folder found in $proj_cmd: $folder" >&2
        print " run: ${hi_yellow_cor}setup -h${reset_cor} to see usage" >&2
        return 1;
      fi

      local folder="$(choose_one_ -it "folder in $proj_cmd to setup" "${(@f)dirs}")"
      if [[ -z "$folder" ]]; then return 1; fi
      
      folder_to_execute="${proj_folder}/${folder}"
    fi
  else
    if [[ -n "$folder" ]]; then
      if [[ -d "$folder" ]]; then
        folder_to_execute="$folder"
      else
        print " fatal: not a valid folder argument: $folder" >&2
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
    if (( i )); then
      # asks if user wants to customize setup script and save it to config, if not, continue here
      confirm_ "customize setup script and save it to config?"
      local _RET=$?
      
      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 0 )); then
        local custom_setup=""
        custom_setup="$(write_from_ "type your custom setup script")"
        if (( $? == 130 )); then return 130; fi

        if [[ -n "$custom_setup" ]]; then
          update_config_ $i "PUMP_SETUP" "$custom_setup" &>/dev/null
          PUMP_SETUP[$i]="$custom_setup"
          pump_setup="$custom_setup"
        fi
      fi
    fi

    if [[ -z "$pump_setup" ]]; then
      pump_setup="$(get_from_package_json_ "scripts.setup" "$folder_to_execute" 2>/dev/null)"
      
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
  fi

  print " ${script_cor}${pump_setup}${reset_cor}"

  ( cd "$folder_to_execute" && eval "$pump_setup" )
  local RET=$?

  if (( RET != 0 )); then
    if [[ "$pump_setup" == "${PUMP_SETUP[$i]}" ]]; then
      print " ${yellow_cor}warning: failed to run PUMP_SETUP_${i}${reset_cor}" >&2
      print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    fi
  fi

  print ""
  print " next thing to do:"

  local run_dev="$(get_from_package_json_ "scripts.dev" "$folder_to_execute" 2>/dev/null)"
  local run_start="$(get_from_package_json_ "scripts.start" "$folder_to_execute" 2>/dev/null)"

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

  # this is not an accessible command anymore
  if (( proj_revs_is_h )); then
    proj_print_help_ "$proj_cmd revs"
    proj_print_help_ "$proj_cmd rev"
    return 0;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder")"
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
    
    pre_delete_folder_ "$revs_folder"

    if command -v gum &>/dev/null; then
      gum spin --title="deleting... $revs_folder" -- rm -rf -- "$revs_folder"
    else
      print " deleting... $revs_folder"
      rm -rf -- "$revs_folder"
    fi
    # rsync -a --delete is slower

    if (( $? == 0 )); then
      print -l -- " ${magenta_cor}deleted${reset_cor} $revs_folder"
    else
      print -l -- " ${red_cor}not deleted${reset_cor} $revs_folder" >&2
    fi

    return $?;
  fi


  # proj_revs_ -d
  if (( proj_revs_is_d )); then
    local rev_choices
    local oots="$(printf "%s\n" "${rev_options[@]}" | sed 's|.*/||')"

    rev_choices="$(choose_multiple_ "reviews to delete" "${(@f)oots}")"
    rev_choices=("${(@f)rev_choices}")

    if [[ -z "$rev_choices" ]]; then return 1; fi

    local rev=""
    for rev in "${rev_choices[@]}"; do
      local rev_folder="${revs_folder}/${rev}"
  
      pre_delete_folder_ "$rev_folder"

      if command -v gum &>/dev/null; then
        gum spin --title="deleting... $rev_folder" -- rm -rf -- "$rev_folder"
      else
        print " deleting... $rev_folder"
        rm -rf -- "$rev_folder"
      fi

      if (( $? == 0 )); then
        print -l -- " ${magenta_cor}deleted${reset_cor} $rev"
      else
        print -l -- " ${red_cor}not deleted${reset_cor} $rev" >&2
      fi
    done

    return $?;
  fi

  local rev_choices=()
  local rev_map=()

  rev=""
  for rev in "${rev_options[@]}"; do
    local pr_number="$(read_pump_value_ "PR_NUMBER" "$rev")"
    local pr_title="$(read_pump_value_ "PR_TITLE" "$rev")"
    local pr_branch="$(read_pump_value_ "PR_BRANCH" "$rev")"

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
    
    local git_status="$(get_branch_status_ "$folder" 2>/dev/null)"
    if [[ -n "$git_status" && -z "$(echo "$git_status" | grep '\.pump$')" ]]; then
      if ! confirm_ "switch to pull request branch? ${bold_cor}$branch${reset_cor}" "switch" "abort"; then
        do_nothing=1
      fi
    fi
  fi

  echo "$do_nothing"
}

function clone_repo_() {
  set +x
  eval "$(parse_flags_ "$0" "bo" "" "$@")"
  (( clone_repo_is_debug )) && set -x

  local repo="$1"
  local folder="$2"
  local header="$3"

  if [[ -z "$repo" || -z "$folder" ]]; then
    print " fatal: clone_repo_ repo and folder are required arguments" >&2
    return 1;
  fi

  if ! command -v git &>/dev/null; then
    print " fatal: git command not found" >&2 
    return 1;
  fi

  local flags=()
  
  if (( ! clone_repo_is_b )); then
    flags+=(--filter=blob:none)
  fi

  if (( ! clone_repo_is_o )); then # overwrite
    if ! is_proj_folder_empty_ "$folder"; then return 0; fi
  fi

  local repo_name="$(get_repo_name_ "$repo" 2>/dev/null)"

  if [[ -z "$header" ]]; then
    header="cloning... ${blue_cor}$repo_name${reset_cor}"
  fi

  if command -v gum &>/dev/null; then
    if (( clone_repo_is_o )); then
      gum spin --title="$header" -- rm -rf -- "$folder"
    fi
    mkdir -p -- "$folder"
    gum spin --title="$header" -- git -C "/" clone "$repo" "$folder" "${flags[@]}"
  else
    print " $header"
    if (( clone_repo_is_o )); then
      rm -rf -- "$folder" &>/dev/null
    fi

    mkdir -p -- "$folder"
    git -C "/" clone "$repo" "$folder" "${flags[@]}" &>/dev/null
  fi

  if ! is_folder_git_ "$folder" &>/dev/null; then
    return 1;
  fi
}

function proj_rev_() {
  set +x
  eval "$(parse_flags_ "$0" "ebjdxr" "" "$@")"
  (( proj_rev_is_debug )) && set -x

  local proj_cmd="$1"
  local branch=""

  if (( proj_rev_is_h )); then
    proj_print_help_ "$proj_cmd rev"
    return 0;
  fi

  if (( proj_rev_is_d_d )); then
    proj_revs_ -dd "$@"
    return $?;
  fi

  if (( proj_rev_is_d )); then
    proj_revs_ -d "$@"
    return $?;
  fi

  if (( proj_rev_is_e )); then
    proj_revs_ "$@"
    return $?;
  fi

  shift 1

  eval "$(parse_args_ "$proj_cmd rev" "branch:bo" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fr $i; then return 1; fi
  if ! check_gh_; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local pump_clone="${PUMP_CLONE[$i]}"

  local branch_user="" jira_key="" pr_link="" pr_number="" pr_title="" pr_url="" pr_state=""

  local revs_folder="$(get_proj_special_folder_ -r "$proj_cmd" "$proj_folder")"
  local full_rev_folder=""

  # proj_rev_ -x exact branch_user
  if (( proj_rev_is_x )); then
    if [[ -z "$branch" ]]; then
      print " fatal: branch_user is required for -x flag" >&2
      print " run: ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local branch_folder="${branch//\\/-}"
    branch_folder="${branch_folder//\//-}"

    full_rev_folder="${revs_folder}/rev.${branch_folder}"

    if is_branch_existing_ "$branch" "$proj_folder"|| is_branch_existing_ "$branch" "${full_rev_folder}"; then
      branch_user="$branch"
    else
      # try to get from .pump file
      local pr_branch="$(read_pump_value_ "PR_BRANCH" "${full_rev_folder}")"
      if [[ -n "$pr_branch" ]]; then
        if is_branch_existing_ "$pr_branch" "$proj_folder" || is_branch_existing_ "$pr_branch" "${full_rev_folder}"; then
          branch_user="$pr_branch"
        else
          # try to get from pr
          local output=""
          output="$(get_pr_ -omc "$pr_branch" "$proj_repo")"
          if (( $? == 0 )); then
            IFS=$TAB read -r pr_number pr_title pr_url pr_state _ <<< "$output"
          fi

          if [[ -n "$pr_number" && -n "$pr_title" && -n "$pr_url" ]]; then
            branch_user="$pr_branch"
          fi
        fi
      fi
    fi

  # proj_rev_ -j select jira key
  elif (( proj_rev_is_j )); then
    if ! check_jira_ -ipss $i; then return 1; fi

    local output=""
    output="$(select_jira_ticket_ -y $i "$branch" "" "to review")"

    if (( $? == 130 )); then return 130; fi
    if [[ -z "$output" ]]; then return 1; fi
    IFS=$TAB read -r jira_key _ <<< "$output"

    local output="" pr_branch=""
    output="$(select_pr_ -od "$jira_key" "$proj_repo" "pull request to review")"
    if (( $? == 130 )); then return 130; fi
    if (( $? == 0 )); then
      IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state _ <<< "$output"
    fi
    
    branch_user="$pr_branch"

  # proj_rev_ -r select by jira key in release
  elif (( proj_rev_is_r )); then
    if ! check_jira_ -ip $i; then return 1; fi

    jira_key="$(select_jira_key_by_release_ -y $i "$branch" "" "to review")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$jira_key" ]]; then return 1; fi

    local output="" pr_branch=""
    output="$(select_pr_ -od "$jira_key" "$proj_repo" "pull request to review")"
    if (( $? == 130 )); then return 130; fi
    if (( $? == 0 )); then
      IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state _ <<< "$output"
    fi
    
    branch_user="$pr_branch"

  # proj_rev_ -b select branch_user
  elif (( proj_rev_is_b )); then
    branch_user="$(select_branch_ -ris "$branch" "to review" "$proj_folder")"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$branch_user" ]]; then return 1; fi

  else
    # check if branch_user arg was given and it's a branch_user
    if [[ -n "$branch" ]]; then
      if is_branch_existing_ "$branch" "$proj_folder"; then
        branch_user="$branch"
      fi
    fi

    if [[ -z "$branch_user" ]]; then
      if command -v gh &>/dev/null; then
        local output="" pr_branch=""
        output="$(select_pr_ -odg "$branch" "$proj_repo" "pull request to review")"
        if (( $? == 130 )); then return 130; fi
        if (( $? == 0 )); then
          IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state _ <<< "$output"
        fi

        branch_user="$pr_branch"
        if [[ -z "$branch_user" ]]; then return 1; fi
      else
        $proj_cmd rev -b $branch
        return $?;
      fi
    fi
  fi

  if [[ -z "$branch_user" ]]; then
    if [[ -n "$full_rev_folder" ]]; then
      if [[ -d "$full_rev_folder" ]]; then
        print " cannot determine branch_user for folder-only review: $branch" >&2
        cd "$full_rev_folder"
      else
        print " review folder does not exist: $full_rev_folder" >&2
      fi
    else
      print " cannot determine branch_user to review" >&2
    fi
    print " run: ${hi_yellow_cor}$proj_cmd rev -h${reset_cor} to see usage" >&2
    return 1;
  fi

  branch_user="$(get_short_name_ "$branch_user" "$proj_folder")"
  
  if [[ -z "$full_rev_folder" ]]; then
    local branch_folder="${branch_user//\\/-}"
    branch_folder="${branch_folder//\//-}"

    full_rev_folder="${revs_folder}/rev.${branch_folder}"
  fi

  if [[ -z "$pr_number" || -z "$pr_title" || -z "$pr_url" ]]; then
    local output=""
    output="$(get_pr_ -omc "$branch_user" "$proj_repo")"
    if (( $? == 0 )); then
      IFS=$TAB read -r pr_number pr_title pr_url pr_state _ <<< "$output"
    fi

    if [[ -z "$pr_number" ]]; then
      pr_number="$(read_pump_value_ "PR_NUMBER" "$full_rev_folderv" "$branch_user")"
      pr_title="$(read_pump_value_ "PR_TITLE" "$full_rev_folderv" "$branch_user")"
      pr_url="$(read_pump_value_ "PR_LINK" "$full_rev_folder" "$branch_user")"
    fi
  fi

  if [[ -n "$pr_number" ]]; then
    pr_link=$'\e]8;;'"$pr_url"$'\a'"$pr_number"$'\e]8;;\a'
  fi

  local skip_setup=0
  local already_merged=0

  if [[ -n "$pr_link" ]]; then
    print " opening pull request... ${blue_cor}$pr_link${reset_cor} ${hi_cyan_cor}$pr_title${reset_cor}"
  else
    print " opening branch... ${hi_cyan_cor}$branch_user${reset_cor}"
  fi

  if is_folder_git_ "$full_rev_folder" &>/dev/null; then
    # already cloned before

    local do_nothing="$(attempt_switch_branch_ "$branch_user" "$full_rev_folder")"

    if (( do_nothing )); then
      if [[ -n "$pr_state" && -n "$pr_url" ]]; then
        print " ${orange_cor}pull request is ${pr_state:l}${reset_cor}: ${blue_cor}$pr_url${reset_cor}" >&2
      else
        print " ${yellow_cor}pull request is not available${reset_cor}" >&2
      fi
      cd "$full_rev_folder"
      return 1;
    fi

    git -C "$full_rev_folder" fetch --quiet &>/dev/null

    local git_status="$(get_branch_status_ "$full_rev_folder" 2>/dev/null)"
    local local_branch="$(git -C "$full_rev_folder" rev-parse --abbrev-ref HEAD 2>/dev/null)"

    if [[ -n "$git_status" ]]; then
      local files="$(echo "$git_status" | awk '{print $2}')"

      if [[ $(echo "$files" | wc -l) -eq 1 && "$files" =~ \.pump$ ]]; then
        skip_setup=1
      else
        st -sb "$full_rev_folder" >&2

        print " uncommitted changes detected in branch: ${yellow_cor}$local_branch${reset_cor}" >&2
        if confirm_ "erase changes and reset branch?" "reset" "do nothing"; then
          if ! reseto "$full_rev_folder" --quiet; then
            print " ${red_cor}fatal: failed to match HEAD to upstream${reset_cor}" >&2
            do_nothing=1
          fi
        else
          do_nothing=1
        fi
      fi
    fi

    if (( do_nothing )); then
      if [[ -n "$pr_state" && -n "$pr_url" ]]; then
        print " ${orange_cor}pull request is ${pr_state:l}${reset_cor}: ${blue_cor}$pr_url${reset_cor}" >&2
      else
        print " ${yellow_cor}pull request is not available${reset_cor}" >&2
      fi
      cd "$full_rev_folder"
      return 0;
    fi

    if [[ "$branch_user" != "$local_branch" ]]; then
      skip_setup=1

      if ! git -C "$full_rev_folder" switch "$branch_user" --discard-changes --quiet; then
        print " failed to switch to branch: ${orange_cor}$branch_user${reset_cor}" >&2
        already_merged=1
      fi
    fi

    if [[ "$branch_user" == "$local_branch" ]]; then
      local latest_commit="$(git -C "$full_rev_folder" rev-parse HEAD 2>/dev/null)"

      setup_git_merge_tool_

      if pull -r "$full_rev_folder" --quiet; then
        local new_latest_commit="$(git -C "$full_rev_folder" rev-parse HEAD 2>/dev/null)"

        if [[ "$latest_commit" == "$new_latest_commit" ]]; then
          skip_setup=1
        fi
      else
        skip_setup=1
        already_merged=1

        local remote_branch="$(get_remote_branch_ -f "$branch_user" "$full_rev_folder")"
        local branch_behind=0
        local output=""
        output="$(get_my_branch_status_ "$branch_user" "$remote_branch" "$full_rev_folder")"
        if (( $? == 0 )); then
          IFS="|" read -r branch_behind _ <<< "$output"
        fi

        if (( branch_behind )); then
          print " ${yellow_cor}warning:${reset_cor} local branch is behind upstream by ${bold_cor}$branch_behind${reset_cor} commits" >&2
        fi
      fi
    fi

  else

    if ! clone_repo_ -o "$proj_repo" "$full_rev_folder" "cloning... ${green_cor}$branch_user${reset_cor}"; then
      print " ${red_cor}fatal: failed to clone branch: $branch_user${reset_cor}" >&2
      return 1;
    fi

    if ! git -C "$full_rev_folder" switch "$branch_user" --quiet &>/dev/null; then
      print " ${yellow_cor}warning: failed to switch to branch: $branch_user${reset_cor}"
      already_merged=1
    fi

    if command -v gh &>/dev/null; then
      local pr_target_branch="$(gh pr view "${(q)branch_user}" --repo "$proj_repo" --json state,baseRefName --jq 'select(.state == "OPEN") | .baseRefName' 2>/dev/null)"
      if [[ -n "$pr_target_branch" ]]; then
        git -C "$full_rev_folder" config branch.$branch_user.pump-merge $pr_target_branch
      fi
    fi

    cd "$full_rev_folder"

    if [[ -n "$pump_clone" ]]; then
      print " ${script_cor}${pump_clone}${reset_cor}"
      if ! eval "$pump_clone"; then
        print " ${yellow_cor}warning: failed to run PUMP_CLONE_${i}${reset_cor}"
        print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}"
      fi
    fi

  fi # end of clone if

  update_pump_file_ "PR_BRANCH" "$branch_user" "$full_rev_folder" "$branch_user"

  if [[ -n "$pr_number" && -n "$pr_title" && -n "$pr_url" ]]; then
    update_pump_file_ "PR_NUMBER" "$pr_number" "$full_rev_folder" "$branch_user"
    update_pump_file_ "PR_TITLE" "$pr_title" "$full_rev_folder" "$branch_user"
    update_pump_file_ "PR_LINK" "$pr_url" "$full_rev_folder" "$branch_user"
  fi

  if (( already_merged  )); then
    if [[ -n "$pr_state" && -n "$pr_url" ]]; then
      print " ${orange_cor}pull request is ${pr_state:l}${reset_cor}: ${blue_cor}$pr_url${reset_cor}" >&2
    else
      print " ${yellow_cor}pull request is not available${reset_cor}" >&2
    fi

    cd "$full_rev_folder"
    return $?;
  fi

  print " HEAD is now at $(git -C "$full_rev_folder" --no-pager log -1 --pretty=%h) $(truncate_ "$(git -C "$full_rev_folder" --no-pager log -1 --pretty=%s)" 60)"

  if [[ -n "$pr_state" && -n "$pr_url" ]]; then
    print " ${orange_cor}pull request is ${pr_state:l}${reset_cor}: ${blue_cor}$pr_url${reset_cor}" >&2
  else
    print " ${yellow_cor}pull request is not available${reset_cor}" >&2
  fi

  if (( skip_setup )); then
    cd "$full_rev_folder"
    return $?;
  fi

  proj_setup_ "" "$full_rev_folder"

  print "  --"
  print "  • ${hi_yellow_cor}$proj_cmd revs${reset_cor} to check out local code review"

  cd "$full_rev_folder"

  if [[ -z "$PUMP_CODE_EDITOR" ]]; then
    PUMP_CODE_EDITOR="$(input_command_ "type the command of your code editor" "code")"

    if [[ -n "$PUMP_CODE_EDITOR" ]]; then
      PUMP_CODE_EDITOR="$(which $PUMP_CODE_EDITOR 2>/dev/null || echo "$PUMP_CODE_EDITOR")"
      update_setting_ -f "PUMP_CODE_EDITOR" "$PUMP_CODE_EDITOR"
    fi
  fi

  if [[ -n "$PUMP_CODE_EDITOR" ]]; then
    if command -v $PUMP_CODE_EDITOR &>/dev/null; then
      if confirm_ "open code editor?"; then

        $PUMP_CODE_EDITOR -- "$full_rev_folder"

        if (( $? )); then
          update_setting_ "PUMP_CODE_EDITOR" "" &>/dev/null
          PUMP_CODE_EDITOR=""
        fi
      fi
    else
      print " code editor command not found:  ${yellow_cor}$PUMP_CODE_EDITOR${reset_cor}" >&2
      update_setting_ "PUMP_CODE_EDITOR" "" &>/dev/null
      PUMP_CODE_EDITOR=""
    fi
  fi
}

function get_pr_url_() {
  set +x
  eval "$(parse_flags_ "$0" "omc" "" "$@")"
  (( get_pr_url_is_debug )) && set -x

  local branch="$1"
  local proj_repo="$2"

  local pr_url=""

  if command -v gh &>/dev/null; then
    if (( get_pr_url_is_o )); then
      pr_url="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "OPEN") | .url' 2>/dev/null)"
    fi

    if [[ -z "$pr_url" ]]; then
      if (( get_pr_url_is_m )); then
        pr_url="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "MERGED") | .url' 2>/dev/null)"
      fi
      if [[ -z "$pr_url" ]] && (( get_pr_url_is_c )); then
        pr_url="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json url,state --jq 'select(.state == "CLOSED") | .url' 2>/dev/null)"
      fi
    fi
  fi

  echo "$pr_url"
}

function get_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "omc" "" "$@")"
  (( get_pr_is_debug )) && set -x

  local branch="$1"
  local proj_repo="$2"

  local pr_number="" pr_title="" pr_branch="" pr_url="" pr_state=""

  if (( get_pr_is_o )); then
    IFS=$'\t' read -r pr_number pr_title pr_url pr_state <<<"$(
      gh pr view "${(q)branch}" \
        --repo "$proj_repo" \
        --json number,title,url,state \
        --jq 'select(.state == "OPEN") | [.number, .title, .url, .state] | @tsv' \
        2>/dev/null || :
    )"
  fi

  if [[ -z "$pr_number" ]] && (( get_pr_is_m )); then
    IFS=$'\t' read -r pr_number pr_title pr_url pr_state <<<"$(
      gh pr view "${(q)branch}" \
        --repo "$proj_repo" \
        --json number,title,url,state \
        --jq 'select(.state == "MERGED") | [.number, .title, .url, .state] | @tsv' \
        2>/dev/null || :
    )"
  fi

  if [[ -z "$pr_number" ]] && (( get_pr_is_c )); then
    IFS=$'\t' read -r pr_number pr_title pr_url pr_state  <<<"$(
      gh pr view "${(q)branch}" \
        --repo "$proj_repo" \
        --json number,title,url,state \
        --jq 'select(.state == "CLOSED") | [.number, .title, .url, .state] | @tsv' \
        2>/dev/null || :
    )"
  fi

  echo "${pr_number}${TAB}${pr_title}${TAB}${pr_url}${TAB}${pr_state}"
}

function truncate_() {
  local str="$1"
  local max="${2:-40}"

  if (( ${#str} > max )); then
    print -r -- "${str[1,max]}..."
  else
    print -r -- "$str"
  fi
}

function proj_clone_() {
  set +x
  eval "$(parse_flags_ "$0" "jd" "" "$@")"
  (( proj_clone_is_debug )) && set -x

  local proj_cmd="$1"
  local branch=""
  local workflow_run=""
  local target_branch=""
  local work_type=""

  if (( proj_clone_is_h )); then
    proj_print_help_ "$proj_cmd clone"
    return 0;
  fi

  shift 1

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -frmv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"
  local pump_clone="${PUMP_CLONE[$i]}"

  if (( proj_clone_is_d )); then
    eval "$(parse_args_ "$proj_cmd clone" "workflow_run:t" "$@")"

    local workflow="$(proj_gha_ -dw "$proj_cmd")"
    local branch="$(workflow_run_ -b "$proj_repo" "$workflow" "$workflow_run")"

    if [[ -z "$branch" ]]; then
      print " fatal: failed to get branch from workflow run: $workflow_run" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi

    proj_clone_ "$proj_cmd" "$branch"

    return $?;
  fi
  
  eval "$(parse_args_ "$proj_cmd clone" "branch:bk,target_branch:bk,work_type:tk" "$@")"
  shift $arg_count

  if (( single_mode )) && [[ -n "$2" ]]; then
    print " fatal: not a valid argument: ${@:2}" >&2
    print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if [[ -n "$branch" ]]; then
    branch="$(get_short_name_ "$branch" "$proj_folder")"
  else
    if [[ -n "$target_branch" ]]; then
      print " fatal: branch name is required when setting target branch" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  if [[ -n "$target_branch" ]]; then
    target_branch="$(get_short_name_ "$target_branch" "$proj_folder")"
  fi

  local target_branch_user="$target_branch"

  if [[ -n "$target_branch_user" ]]; then
    if [[ -n "$branch" && "$branch" == "$target_branch_user" ]]; then
      print " fatal: branch cannot be the same as target branch: ${yellow_cor}$(truncate_ $branch)${reset_cor}" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local remote_target_branch="$(get_remote_branch_ "$target_branch_user" "$proj_folder")"
    
    if [[ -z "$remote_target_branch" ]]; then
      print " fatal: target branch does not exist: ${yellow_cor}$target_branch_user${reset_cor}" >&2
      print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  local jira_key=""
  local folder_to_clone=""
  local is_first_branch=0

  if (( single_mode )); then
    folder_to_clone="${proj_folder}"
    is_first_branch=1

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
      if ! create_backup_ -s $i "$folder_to_clone" "$single_mode"; then
        return 1;
      fi
    fi
  
  else # multiple_mode

    local git_folder="$(find_git_folder_ "$proj_folder" 2>/dev/null)"

    # there is nothing cloned yet
    if [[ -z "$git_folder" ]]; then
      # clone into temporary folder to get 1st branch
      local temp_folder="$(get_proj_special_folder_ -t "$proj_cmd" "$proj_folder")"

      if ! clone_repo_ -o "$proj_repo" "$temp_folder" "preparing to clone..."; then
        print " ${red_cor}fatal: failed to clone repository: $proj_repo${reset_cor}" >&2
        return 1;
      fi

      local first_branch="$(get_my_branch_ "$temp_folder" 2>/dev/null)"

      if [[ -z "$first_branch" ]]; then
        print " ${red_cor}fatal: failed to get branch name from cloned repository${reset_cor}" >&2
        return 1;
      fi

      if command -v gum &>/dev/null; then
        gum spin --title="cleaning up..." -- rm -rf -- "$temp_folder"
      else
        rm -rf -- "$temp_folder"
      fi
      
      if [[ -n "$branch" ]]; then
        # if user has given a 1st branch to clone, let's clone the 1st branch here
        if [[ "$branch" != "$first_branch" ]]; then
          if ! clone_repo_ -o "$proj_repo" "${proj_folder}/${first_branch}" "cloning your first branch..."; then
            print " ${yellow_cor}warning: failed to clone: ${proj_folder}/${first_branch}${reset_cor}" >&2
          fi
        fi
        # now it's second branch, we can clone it normally below
      else
        # if there is no cloned repo and no branch arg, clone first_branch as normal
        branch="$first_branch"
        is_first_branch=1
      fi
    fi

    if (( is_first_branch )); then
      folder_to_clone="${proj_folder}/${branch}"
    else
      if [[ -z "$branch" ]]; then
        branch="$(input_branch_name_ "branch name")"
        if (( $? == 130 )); then return 130; fi
        if [[ -z "$branch" ]]; then return 1; fi
      fi

      if [[ -n "$target_branch_user" && "$branch" == "$target_branch_user" ]]; then
        print " fatal: branch cannot be the same as target branch: $(truncate_ $branch)" >&2
        print " run: ${hi_yellow_cor}$proj_cmd clone -h${reset_cor} to see usage" >&2
        return 1;
      fi

      if [[ "$branch" == release/* ]]; then
        folder_to_clone="${proj_folder}/${branch}"
        work_type="release"

      elif [[ "$branch" == release-* ]]; then
        local folder_name="${branch#release-}"
        
        folder_to_clone="${proj_folder}/release/${folder_name}"
        work_type="release"

      elif (( ${BRANCHES[(Ie)$branch]} )); then
        folder_to_clone="${proj_folder}/${branch}"

      else
        jira_key="$(extract_jira_key_ "$branch")"

        if [[ -n "$jira_key" ]]; then
          check_jira_ -pw $i
          local jira_proj="${PUMP_JIRA_PROJECT[$i]}"

          if [[ -z "$work_type" ]]; then
            work_type="$(choose_work_type_ $i "$branch")"
            if (( $? == 130 )); then return 130; fi
          fi

          if [[ -n "$work_type" ]]; then
            branch="${work_type}/${branch}"
          fi

          if [[ "${branch:t:u}" == "${jira_key:u}" ]]; then
            branch="$(get_monogram_branch_name_ "$branch")"
            if (( $? == 130 )); then return 130; fi
          fi

          if [[ -n "$work_type" ]]; then
            folder_to_clone="${proj_folder}/${work_type}/${jira_key}"
          else
            folder_to_clone="${proj_folder}/${jira_key}"
          fi
        else
          # work items that do not have a jira associated with them, we will generate a fake jira 
          while true; do
            local fake_jira_proj="${proj_cmd:0:${#jira_proj}}"
            local fake_jira_key="${fake_jira_proj:u}-$(date +%m%S)"

            if [[ -n "$work_type" ]]; then
              folder_to_clone="${proj_folder}/${work_type}/${fake_jira_key}"
            else
              folder_to_clone="${proj_folder}/${fake_jira_key}"
            fi

            if is_folder_git_ "$folder_to_clone" &>/dev/null; then
              if is_branch_existing_ "$branch" "$folder_to_clone" &>/dev/null; then
                break;
              fi
            else
              break;
            fi
          done
        fi

      fi
    fi

    if is_folder_git_ "$folder_to_clone" &>/dev/null; then
      local base_branch="$(get_base_branch_ "$branch" "$folder_to_clone" 2>/dev/null)"

      if [[ -n "$base_branch" ]]; then
        print " target branch: ${hi_cyan_cor}$base_branch${reset_cor}" >&2
      fi

      cd "$folder_to_clone"
      return 0;
    fi
  fi # if (( single_mode )); then

  if [[ -z "$folder_to_clone" ]]; then
    print " fatal: could not determine folder to clone into" >&2
    return 1;
  fi

  local RET=0

  if ! is_folder_git_ "$folder_to_clone" &>/dev/null; then
    if ! clone_repo_ -o "$proj_repo" "$folder_to_clone" "cloning... ${green_cor}$branch${reset_cor}"; then
      print " ${red_cor}fatal: failed to clone repository: $proj_repo${reset_cor}" >&2
      return 1;
    fi
  fi

  local first_branch="$(get_my_branch_ "$folder_to_clone" 2>/dev/null)"

  if [[ -z "$first_branch" ]]; then
    print " ${red_cor}fatal: failed to determine local branch${reset_cor}" >&2
    return 1;
  fi

  get_pump_jira_title_ "$jira_key" "$folder_to_clone" &>/dev/null

  if [[ -n "$branch" && "$first_branch" != "$target_branch_user" && "$branch" != "$first_branch" && "$branch" != "main" && "$branch" != "master" ]]; then
    if [[ -z "$target_branch_user" ]] && command -v gh &>/dev/null; then
      local pr_target_branch="$(gh pr view "${(q)branch}" --repo "$proj_repo" --json state,baseRefName --jq 'select(.state == "OPEN") | .baseRefName' 2>/dev/null)"

      # if there's an open pr, let's use that target branch
      if [[ -n "$pr_target_branch" ]]; then
        target_branch_user="$pr_target_branch"
      fi
    fi

    if [[ -z "$target_branch_user" ]]; then
      # if work type is release, then target branch is always main branch
      if [[ "$work_type" == "release" ]]; then
        target_branch_user="$(get_main_branch_ "$folder_to_clone" 2>/dev/null)"
      fi

      if [[ -z "$target_branch_user" ]]; then
        target_branch_user="$(determine_target_branch_ -dbm "$branch" "$folder_to_clone" "$proj_cmd" "$first_branch")"
      fi
    fi
  fi

  if [[ -n "$target_branch_user" ]]; then
    if is_branch_existing_remote_ "$target_branch_user" "$folder_to_clone"; then
      git -C "$folder_to_clone" config branch.$branch.pump-merge $target_branch_user
    else
      print " ${red_cor}fatal: failed to switch to target branch: ${bold_cor}$target_branch_user${reset_cor}" >&2
      RET=1
    fi
  fi

  if git -C "$folder_to_clone" switch "$branch" &>/dev/null; then
    if [[ -n "$target_branch" ]]; then
      print " ${yellow_cor}warning: branch already exists: ${hi_yellow_cor}$branch${reset_cor}" >&2
      confirm_ "continue?" "continue" "abort"
      local _RET=$?

      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 1 )); then
        del -fx -- "$folder_to_clone"
        return 1;
      fi

      print "" >&2
      print " if you meant to create a new branch with the same name, follow the steps below:" >&2
      print "  • run: ${hi_yellow_cor}delb -r $branch${reset_cor} to delete the old branch" >&2
      print "  • run: ${hi_yellow_cor}del .${reset_cor} to delete this folder" >&2
      print "  • then try again" >&2
      print "" >&2
    fi
  else
    if ! git -C "$folder_to_clone" switch -c "$branch" &>/dev/null; then
      print " ${red_cor}fatal: failed to create branch: ${bold_cor}$branch${reset_cor}" >&2
      RET=1
    fi
  fi

  if [[ -n "$branch" ]]; then
    local remote_branch_arg="$(get_remote_branch_ -f "$branch" "$folder_to_clone")"

    if [[ -z "$remote_branch_arg" ]]; then
      local remote_name="$(get_remote_name_ "$folder_to_clone")"
      print " branch create: ${pink_cor}$branch${reset_cor} but not in $remote_name"
    else
      print " branch cloned: ${hi_green_cor}$remote_branch_arg${reset_cor}"
    fi

    if [[ -n "$target_branch_user" && "$target_branch_user" != "$branch" ]]; then
      local remote_name="$(get_remote_name_ "$folder_to_clone")"
      local existing_target_branch="$(git -C "$folder_to_clone" ls-remote --heads "$remote_name" "$target_branch_user" 2>/dev/null)"

      if [[ -z "$existing_target_branch" ]] && [[ "$target_branch_user" != "$target_branch" ]]; then
        print " target branch: ${yellow_cor}$target_branch_user${reset_cor} but not in $remote_name"
      else
        print " target branch: ${hi_cyan_cor}$target_branch_user${reset_cor}"
      fi
    fi
    print ""
  fi

  print " next thing to do:"

  if [[ -n "${PUMP_SETUP[$i]}" ]]; then
    print "  • ${hi_yellow_cor}setup${reset_cor} (runs PUMP_SETUP_${i})"
  else
    local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
    local setup_script="$(get_from_package_json_ "scripts.setup" "$folder_to_clone" 2>/dev/null)"

    if [[ -n "$setup_script" && -n "$pkg_manager" ]]; then
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager run setup\")"
    elif [[ -n "$pkg_manager" ]]; then
      print "  • ${hi_yellow_cor}setup${reset_cor} (alias for \"$pkg_manager install\")"
    fi
    print "    ${hi_gray_cor}edit PUMP_SETUP_${i} in your pump.json file to customize the setup script${reset_cor}"
    print "  --"
  fi

  if [[ -n "$branch" ]]; then
    local b_branch="$(get_base_branch_ "$branch" "$folder_to_clone" 2>/dev/null)"
    
    if [[ -n "$b_branch" ]]; then
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
      print " ${yellow_cor}warning: failed to run PUMP_CLONE_${i}${reset_cor}" >&2
      print " edit file: ${hi_gray_cor}$PUMP_CONFIG_FILE${reset_cor} then run: ${hi_yellow_cor}refresh${reset_cor}" >&2
    fi
  fi

  return $RET;
}

function proj_pull_() {
  set +x
  eval "$(parse_flags_ "$0" "" "trmfopq" "$@")"
  (( proj_pull_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_pull_is_h )); then
    proj_print_help_ "$proj_cmd pull"
    return 0;
  fi

  shift 1

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fmr $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  setup_git_merge_tool_

  if (( single_mode )); then
    local branches_to_delete=()
    local branch=""
    local folder="$proj_folder"

    if is_folder_git_ -r "$folder" &>/dev/null; then
      if get_branch_status_ "$folder" 1>/dev/null; then return 1; fi

      # get a list of local branches and loop through them to pull each branch
      local branches=($(git -C "$folder" for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null))

      for branch in "${branches[@]}"; do
        # switch to branch
        if ! git -C "$folder" switch "$branch" --quiet &>/dev/null; then
          print " ${yellow_cor}✗${reset_cor} pull skipped: ${hi_yellow_cor}$branch${reset_cor} in folder: ${hi_yellow_cor}$folder${reset_cor}"
          continue;
        fi

        pull -r "$folder" "$@" --quiet &>/dev/null
        local RET=$?
        if (( RET == 130 )); then return 130; fi

        if (( RET == 0 )); then
          print " ${green_cor}✓${reset_cor} pulled branch: ${hi_green_cor}$branch${reset_cor} in folder: ${hi_cyan_cor}$folder${reset_cor}"
        else
          print " ${red_cor}✗${reset_cor} failed to pull: ${hi_red_cor}$branch${reset_cor} in folder: ${hi_red_cor}$folder${reset_cor}"
          
          if ! is_remote_branch_ "$branch" "$folder"; then
            branches_to_delete+=("$branch")
          fi
        fi
      done

      git -C "$folder" switch - &>/dev/null

      if (( ${#branches_to_delete[@]} )); then
        confirm_ "delete local branches that no longer exist in remote?" "delete" "keep"
        local _RET=$?

        if (( _RET == 130 || _RET == 2 )); then return 130; fi
        if (( _RET == 0 )); then
          for branch in "${branches_to_delete[@]}"; do
            delb -fx "$branch"
          done
        fi
      fi

    fi

  else # multiple_mode

    local folders_to_delete=()
    local folders=($(find "$proj_folder" -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null))

    local folder=""
    for folder in "${folders[@]}"; do
      if is_folder_git_ -r "$folder" &>/dev/null; then
        local branch="$(get_my_branch_ "$folder" 2>/dev/null)"
        if [[ -z "$branch" ]]; then continue; fi

        if get_branch_status_ "$folder" 1>/dev/null; then
          print " ${yellow_cor}✗${reset_cor} pull skipped: ${hi_yellow_cor}$branch${reset_cor} in folder: ${hi_yellow_cor}$folder${reset_cor}"
          continue;
        fi

        pull -r "$folder" "$@" --quiet &>/dev/null
        local RET=$?
        
        if (( RET == 130 )); then return 130; fi
        if (( RET == 0 )); then
          print " ${green_cor}✓${reset_cor} pulled branch: ${hi_green_cor}$branch${reset_cor} in folder: ${hi_cyan_cor}$folder${reset_cor}"
        else
          print " ${red_cor}✗${reset_cor} failed to pull: ${hi_red_cor}$branch${reset_cor} in folder: ${hi_red_cor}$folder${reset_cor}"

          local branch_folder="$(basename -- "$(dirname -- "$folder")")/$(basename -- "$folder")"
          
          if [[ "$branch" == "$(basename -- "$folder")" || "$branch" == "$branch_folder" ]] && ! is_remote_branch_ "$branch" "$folder"; then
            folders_to_delete+=("$folder")
          fi
        fi
      fi
    done

    if (( ${#folders_to_delete[@]} )); then
      confirm_ "delete folders with local branches that no longer exist in remote?" "delete" "keep"
      local _RET=$?

      if (( _RET == 130 || _RET == 2 )); then return 130; fi
      if (( _RET == 0 )); then
        for folder in "${folders_to_delete[@]}"; do
          print " deleting folder: ${yellow_cor}$folder${reset_cor} because its local branch no longer exists in remote" >&2
          del -fx -- "$folder"
        done
      fi
    fi

  fi # end if (( single_mode ));
}

function proj_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "als" "xfr" "$@")"
  (( proj_prs_is_debug )) && set -x

  local proj_cmd="$1"
  local search=""
  local interval=""

  if (( proj_prs_is_h )); then
    proj_print_help_ "$proj_cmd prs"
    return 0;
  fi

  shift 1

  eval "$(parse_args_ "$proj_cmd prs" "search:to,interval:nz" "$@")"
  shift $arg_count

  if (( ! proj_prs_is_a && ! proj_prs_is_l )) && [[ -n "$search" ]]; then
    print " fatal: search term can only be used with -a and -l flag" >&2
    print " run: ${hi_yellow_cor}$proj_cmd prs -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local i="$(get_proj_index_ "$proj_cmd")"
  
  if ! check_gum_; then return 1; fi
  if ! check_proj_ -frg $i; then return 1; fi
  if ! check_gh_; then return 1; fi

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
        print ""
        print "sleeping for $interval minutes..."
        sleep $(( 60 * interval ))
      else
        break;
      fi
    done

    return $RET;
  fi

  if (( proj_prs_is_a )); then
    local RET=0

    while true; do
      local pr_list=""
      pr_list="$(list_prs_ -o "$search" "$proj_repo")"
      if (( $? == 130 )); then return 130; fi

      if [[ -n "$pr_list" ]]; then
        typeset -A approved_prs

        local line
        for line in "${(@f)pr_list}"; do
          local pr_number="" pr_title="" pr_url="" pr_branch="" pr_state="" pr_author="" is_draft="" has_dnm_label="" approval_count="" user_has_approved=""
          IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state pr_author is_draft has_dnm_label approval_count user_has_approved _ <<< "$line"

          if [[ -z "$pr_number" ]]; then continue; fi

          # check if approved_prs already has an entry for this PR number
          if (( approved_prs[$pr_number] == 1 )); then continue; fi

          if (( proj_prs_is_a_a )); then
            approve_pr_ -f "$pr_number" "$pr_title" "$pr_url" "$pr_branch" "$pr_state" "$pr_author" "$is_draft" "$has_dnm_label" "$approval_count" "$user_has_approved" "$pr_approval_min" "$@"
          else
            approve_pr_ "$pr_number" "$pr_title" "$pr_url" "$pr_branch" "$pr_state" "$pr_author" "$is_draft" "$has_dnm_label" "$approval_count" "$user_has_approved" "$pr_approval_min" "$@"
          fi
          local RET=$?
          if (( RET == 130 )); then break; fi

          # save the approved status for this PR
          approved_prs[$pr_number]="$RET"
        done
      fi

      if (( ! proj_prs_is_a_a )); then break; fi

      print ""
      print "sleeping for $interval minutes..."
      sleep $(( 60 * interval ))
    done

    return $RET;
  fi

  if (( proj_prs_is_l_l )); then
    # label prs by release, user select release, then label all prs in that release
    if ! check_jira_ -ipss $i; then return 1; fi

    local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
    local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

    local releases="$(select_jira_releases_ $i "$jira_proj" "$search" "$jira_api_token")"

    if [[ -z "$releases" ]]; then
      print " fatal: no releases found for project: $jira_proj" >&2
      return 1;
    fi

    local release=""
    for release in "${(@f)releases}"; do
      proj_prs_l_ -f $i "$release" "$search" "" "$@"

      if (( $? == 130 )); then return 130; fi
      display_line_
    done

    return $?;
  fi

  if (( proj_prs_is_l )); then
    if ! check_jira_ -ipss $i; then return 1; fi

    proj_prs_l_ $i "" "$search" "" "$@"

    return $?;
  fi

  if (( proj_prs_is_r )); then
    # rebase/merge all users open pull requests
    proj_prs_r_ $i "$proj_cmd" "$@"

    return $?;
  fi

  local pr_list="$(list_prs_ -o "" "$proj_repo")"

  if [[ -z "$pr_list" ]]; then
    local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
    print " no open pull requests in repository: $repo_name" >&2
    return 0;
  fi
  
  local line=""
  for line in "${(@f)pr_list}"; do
    local pr_number="" pr_title="" pr_url="" pr_branch="" pr_state="" pr_author="" is_draft="" has_dnm_label="" approval_count="" user_has_approved=""
    IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state pr_author is_draft has_dnm_label approval_count user_has_approved _ <<< "$line"

    if [[ -z "$pr_number" ]]; then continue; fi

    print_pr_status_ "$pr_number" "$pr_title" "$pr_url" "$pr_branch" "$pr_state" "$pr_author" "$is_draft" "$has_dnm_label" "$approval_count" "$user_has_approved" "$pr_approval_min"
  done
}

# -r means filter releases that are already released
function proj_prs_l_() {
  set +x
  eval "$(parse_flags_ "$0" "xf" "r" "$@")"
  (( proj_prs_l_is_debug )) && set -x

  local i="$1"
  local jira_release="$2"
  local search_release="$3"
  local search_key="$4"

  local proj_repo="${PUMP_REPO[$i]}"

  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  if [[ -z "$jira_release" ]]; then
    jira_release="$(select_jira_release_ $i "$jira_proj" "$search_release" "$jira_api_token" "${@:4}")"
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
    local _RET=0
    if (( is_version_label )); then
      confirm_ "add more labels?" "yes" "no" "no"
      _RET=$?
      if (( _RET == 130 || _RET == 2 )); then return 130; fi;
    fi

    if (( _RET == 0 )); then
      local all_labels_out="$(gum spin --title="fetching labels..." -- gh label list --repo "$proj_repo" --limit 100 --json=name | jq -r '.[].name' | sort -rf)"
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
      confirm_ "remove existing version labels from prs?" "yes" "no" "no"
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
    if [[ -z "$key" ]]; then continue; fi

    local pr_list="$(list_prs_ -odm "$key" "$proj_repo")"
    local pr_list2="$(list_prs_ -omb "$release_version" "$proj_repo")"
    if [[ -z "$pr_list" && -z "$pr_list2" ]]; then continue; fi

    if [[ -n "$pr_list" && -n "$pr_list2" ]]; then
      pr_list="$pr_list"$'\n'"$pr_list2"
    elif [[ -z "$pr_list" && -n "$pr_list2" ]]; then
      pr_list="$pr_list2"
    fi

    local line=""
    for line in "${(@f)pr_list}"; do
      local pr_number="" pr_title="" pr_url=""
      IFS=$TAB read -r pr_number pr_title pr_url _ <<< "$line"

      if [[ -z "$pr_number" ]]; then continue; fi

      # check if pr has labels and if a label is in the format of <major>.<minor>.<patch>, remove it
      local existing_labels_out="$(gum spin --title="fetching pull request labels..." -- gh pr view "$pr_number" --repo "$proj_repo" --json labels --jq '.labels[].name' 2>/dev/null)"
      local existing_labels=("${(@f)existing_labels_out}")

      # remove labels
      if (( is_remove_labels )); then
        for label in "${existing_labels[@]}"; do
          if [[ "$label" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            if [[ " ${choose_labels[*]} " == *" $label "* ]]; then
              print " ${green_cor}✓ label exist:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
              continue;
            fi

            if gh pr edit "$pr_number" --repo "$proj_repo" --remove-label "$label" &>/dev/null; then
              print " ${magenta_cor}✓ label remov:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
            else
              print " ${red_cor}✗ label error:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
            fi
          fi
        done
      fi

      for label in "${choose_labels[@]}"; do
        if [[ " ${existing_labels[*]} " != *" $label "* ]]; then
          if gh pr edit "$pr_number" --repo "$proj_repo" --add-label "$label" &>/dev/null; then
            print " ${green_cor}✓ label added:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
          else
            print " ${red_cor}✗ label error:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
          fi
        elif (( ! is_remove_labels )); then
          print " ${green_cor}✓ label exist:${reset_cor} ${pink_cor}$label${reset_cor} from pr:${reset_cor} ${blue_cor}$pr_url${reset_cor}"
        fi
      done

    done
  done

}

function proj_prs_r_() {
  set +x
  eval "$(parse_flags_ "$0" "xfr" "" "$@")"
  (( proj_prs_r_is_debug )) && set -x

  local i="$1"
  local proj_cmd="$2"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

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

  local temp_folder="$(get_proj_special_folder_ -t "$proj_cmd" "$proj_folder")"

  gum spin --title="preparing to rebase pull requests..." -- rm -rf -- "$temp_folder"
  if ! gum spin --title="preparing to rebase pull requests..." -- git -C "/" clone --filter=blob:none "$proj_repo" "$temp_folder"; then
    print " fatal: failed to clone ${repo_name}" >&2
    return 1;
  fi

  local remote_name="$(get_remote_name_ "$temp_folder")"

  # get a list of all open PRs for the current user
  local pr_list="$(gum spin --title="fetching open pull requests... $repo_name" -- gh pr list --repo "$proj_repo" \
    --limit 100 --state open \
    --author $current_user \
    --json number,title,isDraft,headRefName,baseRefName \
    --jq '.[] | {number, title, isDraft, headRefName, baseRefName} // empty'
  )"

  if [[ -z "$pr_list" ]]; then
    print " no open pull requests in repository: $repo_name" >&2
    return 1;
  fi

  echo "$pr_list" | jq -c '.' | while read -r pr; do
    local pr_number="$(jq -r '.number' <<<"$pr")"
    local pr_title="$(jq -r '.title' <<<"$pr")"
    local pr_is_draft="$(jq -r '.isDraft' <<<"$pr")"
    local pr_branch="$(jq -r '.headRefName' <<<"$pr")"
    local pr_base_branch="$(jq -r '.baseRefName' <<<"$pr")"

    pr_is_draft=$([[ "$is_draft" == "true" ]] && echo 1 || echo 0)

    local pr_url="$(gum spin --title="fetching pull request url..." -- gh pr view "$pr_number" --repo "$proj_repo" --json url -q .url 2>/dev/null)"
    local pr_link=$'\e]8;;'"$pr_url"$'\a'"$pr_number"$'\e]8;;\a'
    local pr_desc="${blue_cor}$pr_link${reset_cor} ${hi_gray_cor}$pr_title${reset_cor}"

    # for each pr, check if the last commit message contains "Merge" if so, merge, otherwise, rebase
    local pr_commits="$(gum spin --title="fetching pull request commits..." -- gh pr view "$pr_number" --repo "$proj_repo" --json commits --jq '.commits[].oid' 2>/dev/null)"
    local pr_commits=("${(@f)pr_commits}")
    if [[ -z "$pr_commits" ]]; then
      print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
      continue;
    fi

    local is_merge_commit=0
    
    ### POTENTIAL IMPROVEMENT ****************

    # check if any commit in $pr_commits is a Merge commit
    for commit in "${pr_commits[@]}"; do
      local commit_message="$(gum spin --title="fetching pull request commit message..." -- gh api repos/$repo_name/commits/$commit --jq '.commit.message' 2>/dev/null)"
      if [[ -n "$commit_message" && "$commit_message" == Merge* ]]; then
        is_merge_commit=1
      fi
    done

    local label_work="$( (( is_merge_commit )) && echo "merge" || echo "rebase" )"

    if (( ! proj_prs_r_is_f )) && (( pr_is_draft )); then
      confirm_ "pull request is on draft, confirm ${label_work}? ${pr_desc}" "${label_work}" "skip"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then
        print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
        continue;
      fi
    fi

    if ! git -C "$temp_folder" switch "$pr_branch" --quiet &>/dev/null; then
      print " ${yellow_cor}skipped:${reset_cor} $pr_desc" >&2
      continue;
    fi

    gum spin --title="cleaning... " -- git -C "$temp_folder" clean -fd --quiet &>/dev/null
    gum spin --title="cleaning... " -- git -C "$temp_folder" restore --quiet --worktree . &>/dev/null
    gum spin --title="cleaning... " -- git -C "$temp_folder" reset --hard --quiet $remote_name/$pr_branch &>/dev/null
    gum spin --title="cleaning... " -- git -C "$temp_folder" pull --quiet $remote_name $pr_branch &>/dev/null

    if (( proj_prs_r_is_x )); then
      if (( is_merge_commit )); then
        if ! gum spin --title="merging... $pr_desc" -- git -C "$temp_folder" merge "$remote_name/$pr_base_branch" --no-edit; then
          git -C "$temp_folder" merge --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
          continue;
        fi
      else
        if ! gum spin --title="rebasing... $pr_desc" -- git -C "$temp_folder" rebase "$remote_name/$pr_base_branch"; then
          git -C "$temp_folder" rebase --abort &>/dev/null
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

      refix "$temp_folder" &>/dev/null
      
      echo "done" > "$pipe_name" &>/dev/null
      rm "$pipe_name"
      wait $spin_pid &>/dev/null
      setopt notify
      setopt monitor

      if git -C "$temp_folder" push $remote_name $pr_branch --force --quiet &>/dev/null; then
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
          _ "$temp_folder" "$remote_name" "$pr_base_branch" "$pr_branch"; then
          print " ${cyan_cor} merged:${reset_cor} $pr_desc" >&2
        else
          git -C "$temp_folder" merge --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
        fi
      else
        if gum spin --title="rebasing... $pr_desc" -- zsh -c '
          git -C "$1" rebase "$2/$3" &&
          git -C "$1" push $2 $4 --force --quiet' \
          _ "$temp_folder" "$remote_name" "$pr_base_branch" "$pr_branch"; then
          print " ${cyan_cor}rebased:${reset_cor} $pr_desc" >&2
        else
          git -C "$temp_folder" rebase --abort &>/dev/null
          print " ${red_cor}aborted:${reset_cor} $pr_desc" >&2
        fi
      fi
    fi
  done

  gum spin --title="cleaning..." -- rm -rf -- "$temp_folder"
}

function approve_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "xfr" "" "$@")"
  (( approve_pr_is_debug )) && set -x

  local pr_number="$1"
  local pr_title="$2"
  local pr_url="$3"
  local pr_branch="$4"
  local pr_state="$5"
  local pr_author="$6"
  local is_draft="$7"
  local has_dnm_label="$8"
  local approval_count="$9"
  local user_has_approved="${10}"
  local pr_approval_min="${11}"

  local current_user="$(gh api user -q .login 2>/dev/null)"

  local pr_link=$'\e]8;;'"$pr_url"$'\a'"$pr_number"$'\e]8;;\a'

  if [[ "$pr_title" =~ (WIP|DRAFT|DO NOT MERGE) ]]; then
    print " ${hi_gray_cor}pr $pr_link has 0 ✓ but is draft in progress${reset_cor}"
    return 0;
  fi

  if (( has_dnm_label )); then
    print " ${hi_gray_cor}pr $pr_link has label do not merge, skipping${reset_cor}"
    return 0;
  fi

  if (( is_draft )); then
    print " ${hi_gray_cor}pr $pr_link has 0 ✓ but is draft in progress${reset_cor}"
    return 0;
  fi

  local is_authorized=0

  if (( approval_count < pr_approval_min )) || (( approve_pr_is_x )); then
    if (( user_has_approved )); then
      print " ${green_cor}pr $pr_link has $approval_count ✓ and you also approved it${reset_cor}"
    else
      local is_main=0;

      if [[ "$pr_author" != "$current_user" ]]; then
        if (( ! approve_pr_is_f )) && [[ "$pr_branch" != "main" ]]; then
          confirm_ "pr $pr_link by $pr_author has $approval_count ✓ ($pr_title) approve it?" "approve" "skip"
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

      if (( is_authorized || approve_pr_is_f )) && [[ "$pr_author" != "$current_user" ]]; then
        if gh pr review $pr_number --approve --repo "$proj_repo" &>/dev/null; then
          (( approval_count++ ))
          if (( is_main )); then
            print " ${green_cor}pr $pr_link has $approval_count ✓ and we auto approved it!${reset_cor}"
          else
            print " ${hi_green_cor}pr $pr_link has $approval_count ✓ and you just approved it${reset_cor}"
          fi
        else
          print " ${red_cor}pr $pr_link has $approval_count ✗ but failed to be approve${reset_cor}"
        fi
      elif [[ "$pr_author" != "$current_user" ]]; then
        print " ${red_cor}pr $pr_link has $approval_count ✗ and you did not approve!${reset_cor}"
      else
        print " ${blue_cor}pr $pr_link has $approval_count ✗ but you authored this pr${reset_cor}"
      fi

    fi
  else
    if (( user_has_approved )); then
      print " ${green_cor}pr $pr_link has $approval_count ✓ and you also approved it${reset_cor}"
    else
      if [[ "$pr_author" == "$current_user" ]]; then
        print " ${blue_cor}pr $pr_link has $approval_count ✗ and you authored this pr${reset_cor}"
      else
        print " ${yellow_cor}pr $pr_link has $approval_count ✗ but you did not approve!${reset_cor}"
      fi
    fi
  fi

  return $is_authorized;
}

function print_pr_status_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( print_pr_status_is_debug )) && set -x

  local pr_number="$1"
  local pr_title="$2"
  local pr_url="$3"
  local pr_branch="$4"
  local pr_state="$5"
  local pr_author="$6"
  local is_draft="$7"
  local has_dnm_label="$8"
  local approval_count="$9"
  local user_has_approved="${10}"
  local pr_approval_min="${11}"
  
  local current_user="$(gh api user -q .login 2>/dev/null)"

  if [[ -z "$pr_number" || -z "$pr_title" || -z "$pr_url" ]]; then return 1; fi

  # build clickable link
  local pr_link=$'\e]8;;'"$pr_url"$'\a'"$pr_number"$'\e]8;;\a'

  # title-based skip
  if [[ "$pr_title" =~ (WIP|DRAFT|DO NOT MERGE) ]] || (( has_dnm_label || is_draft )); then
    print " ${hi_gray_cor}pr $pr_link has 0 ✓ but is draft in progress${reset_cor}"
    continue;
  fi

  if (( approval_count < pr_approval_min )); then
    if (( user_has_approved )); then
      print " ${green_cor}pr $pr_link has $approval_count ✓ and you also approved it${reset_cor}"
    else
      if [[ "$pr_author" != "$current_user" ]]; then
        print " ${red_cor}pr $pr_link has $approval_count ✗ and you did not approve!${reset_cor}"
      else
        print " ${blue_cor}pr $pr_link has $approval_count ✗ but you authored this pr${reset_cor}"
      fi
    fi
  else
    if (( user_has_approved )); then
      print " ${green_cor}pr $pr_link has $approval_count ✓ and you also approved it${reset_cor}"
    else
      if [[ "$pr_author" == "$current_user" ]]; then
        print " ${blue_cor}pr $pr_link has $approval_count ✗ and you authored this pr${reset_cor}"
      else
        print " ${yellow_cor}pr $pr_link has $approval_count ✗ but you did not approve!${reset_cor}"
      fi
    fi
  fi
}

# d means including draft prs
# g means grep search text in pr title after fetching prs
function list_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "omc" "gdb" "$@")"
  (( list_prs_is_debug )) && set -x

  local search_text="$1"
  local proj_repo="$2"

  local current_user="$(gh api user -q .login 2>/dev/null)"

  if (( ! list_prs_is_o && ! list_prs_is_m && ! list_prs_is_c )); then
    query_prs_ "$search_text" "$proj_repo" "$current_user" "${@:3}"
  else
    if (( list_prs_is_o )); then
      query_prs_ -o "$search_text" "$proj_repo" "$current_user" "${@:3}"
    fi

    if (( list_prs_is_m )); then
      query_prs_ -m "$search_text" "$proj_repo" "$current_user" "${@:3}"
    fi

    if (( list_prs_is_c )); then
      query_prs_ -c "$search_text" "$proj_repo" "$current_user" "${@:3}"
    fi
  fi
}

function query_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "ocmgdb" "" "$@")"
  (( query_prs_is_debug )) && set -x

  local search_text="$1"
  local proj_repo="$2"
  local current_user="$3"

  local pr_state="all"

  if (( query_prs_is_o )); then pr_state="open"; fi
  if (( query_prs_is_m )); then pr_state="merged"; fi
  if (( query_prs_is_c )); then pr_state="closed"; fi

  if [[ "$pr_state" == "all" && -z "$search_text" ]]; then
    pr_state="open"
  fi

  local flags=()

  if (( ! query_prs_is_d )); then
    flags+=(--draft=false)
  fi

  local grep_search_text=""
  local grep_bump_search_text=""

  if [[ -n "$search_text" ]]; then
    if (( query_prs_is_g )); then
      if (( query_prs_is_b )); then
        grep_bump_search_text="bump"
      fi
      grep_search_text="$search_text"
      search_text=""
    else
      if (( query_prs_is_b )); then
        search_text="\"$search_text\" AND bump"
      fi
    fi
  fi

  if command -v gum &>/dev/null; then
    pr_list="$(gum spin --title="fetching $pr_state pull requests..." -- gh pr list --repo "$proj_repo" \
      --limit 1000 --state="$pr_state" "${flags[@]}" \
      --search "$search_text in:title" \
      --json number,title,url,headRefName,isDraft,labels,author,reviews,state \
      --jq '.[] | {number, title, url, headRefName, author, state, isDraft, labels} // empty' \
      --jq '.[] | .reviews |= map({ author: .author.login, state, dismissed }) // empty'
    )"
  else
    pr_list="$(gh pr list --repo "$proj_repo" \
      --limit 1000 --state="$pr_state" "${flags[@]}" \
      --search "$search_text in:title" \
      --json number,title,url,headRefName,isDraft,labels,author,reviews,state \
      --jq '.[] | {number, title, url, headRefName, author, state, isDraft, labels} // empty' \
      --jq '.[] | .reviews |= map({ author: .author.login, state, dismissed }) // empty'
    )"
  fi

  if (( query_prs_is_g )) && [[ -n "$grep_search_text" ]]; then
    pr_list="$(echo "$pr_list" | grep -i "$grep_search_text")"
    if [[ -n "$grep_bump_search_text" ]]; then
      local pr_list2="$(echo "$pr_list" | grep -i "$grep_bump_search_text")"

      if [[ -n "$pr_list" && -n "$pr_list2" ]]; then
        pr_list="$pr_list"$'\n'"$pr_list2"
      elif [[ -z "$pr_list" && -n "$pr_list2" ]]; then
        pr_list="$pr_list2"
      fi
    fi
  fi

  if [[ -z "$pr_list" ]]; then return 1; fi

  while IFS= read -r pr; do
    local pr_number="$(jq -r '.number' <<<"$pr")"
    local pr_title="$(jq -r '.title' <<<"$pr")"
    local pr_url="$(jq -r '.url' <<<"$pr")"
    local pr_branch="$(jq -r '.headRefName' <<<"$pr")"
    local pr_author="$(jq -r '.author.login' <<<"$pr")"
    local pr_state="$(jq -r '.state' <<<"$pr")"
    local is_draft="$(jq -r '.isDraft' <<<"$pr")"
    local has_dnm_label="$(jq -r '[.labels[].name | ascii_downcase] | any(. == "do not merge")' <<<"$pr")"

    is_draft=$([[ "$is_draft" == "true" ]] && echo 1 || echo 0)
    has_dnm_label=$([[ "$has_dnm_label" == "true" ]] && echo 1 || echo 0)

    # approvals (latest review per user)
    local approval_count="$(jq '
      .reviews
      | reverse
      | unique_by(.author)
      | map(select(.state == "APPROVED" and (.dismissed == false or .dismissed == null)))
      | length
    ' <<<"$pr")"

    local user_has_approved="$(jq --arg user "$current_user" '
      .reviews
      | reverse
      | unique_by(.author)
      | any(.author == $user and .state == "APPROVED" and (.dismissed == false or .dismissed == null))
    ' <<<"$pr")"

    user_has_approved=$([[ "$user_has_approved" == "true" ]] && echo 1 || echo 0)

    print -r -- "$pr_number${TAB}$pr_title${TAB}$pr_url${TAB}$pr_branch${TAB}$pr_state${TAB}$pr_author${TAB}$is_draft${TAB}$has_dnm_label${TAB}$approval_count${TAB}$user_has_approved"
  done < <(echo "$pr_list" | jq -c '.')
}

function proj_prs_s_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_prs_s_is_debug )) && set -x

  local proj_repo="$1"

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"

  local pr_list="$(gum spin --title="fetching prs... $repo_name" -- gh pr list \
    --repo "$proj_repo" \
    --limit 100 --state open \
    --json number,author,assignees \
    --jq '.[] | {number, author: .author.login, assignees} // empty'
  )"

  if [[ -z "$pr_list" ]]; then return 1; fi

  echo "$pr_list" | jq -c '.' | while read -r pr; do
    local pr_number="$(echo $pr | jq -r '.number')"
    local author="$(echo $pr | jq -r '.author')"
    local assignees="$(echo "$pr" | jq -r '[.assignees[]? | (if .name != "" and .name != null then .name else .login end)] | join(", ")')"

    if [[ "$author" == "app/dependabot" ]]; then
      # print " ${yellow_cor}PR #$pr_number is from Dependabot, skipping${reset_cor}"
      continue;
    fi

    local pr_url="$(gum spin --title="fetching pull request url..." -- gh pr view "$pr_number" --repo "$proj_repo" --json url -q .url)"
    local pr_link=$'\e]8;;'"$pr_url"$'\a'"$pr_number"$'\e]8;;\a'

    if [[ -z "$assignees" ]]; then
      if gh pr edit "$pr_number" --add-assignee "$author" --repo "$proj_repo" &>/dev/null; then
        print " ${green_cor}pr $pr_link is assigned to $author${reset_cor}"
      else
        print " ${red_cor}pr $pr_link is not assigned${reset_cor}"
      fi
    else
      print " pr $pr_link is assigned to $assignees"
    fi
  done
}

function select_pr_() {
  set +x
  eval "$(parse_flags_ "$0" "" "pocmdgd" "$@")"
  (( select_pr_is_debug )) && set -x

  local search_text="$1"
  local proj_repo="$2"
  local header="${3:-"pull request"}"

  select_prs_ -1 "$search_text" "$proj_repo" "$header" "${@:4}"
}

function select_prs_() {
  set +x
  eval "$(parse_flags_ "$0" "1" "ocmgd" "$@")"
  (( select_prs_is_debug )) && set -x

  local search_text="$1"
  local proj_repo="$2"
  local header="${3:-"pull requests"}"

  local arg_count=0
  if [[ -n "$1" && $1 != -* ]]; then (( arg_count++ )); fi
  if [[ -n "$2" && $2 != -* ]]; then (( arg_count++ )); fi
  if [[ -n "$3" && $3 != -* ]]; then (( arg_count++ )); fi

  shift $arg_count

  local pr_list="$(list_prs_ "$search_text" "$proj_repo" "$@")"

  if [[ -z "$pr_list" ]]; then
    local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
    if [[ -n "$search_text" ]]; then
      print " no open pull requests with '$search_text' in repository: $repo_name" >&2
    else
      print " no open pull requests in repository: $repo_name" >&2
    fi
    return 1;
  fi

  local pr_choices=()
  typeset -A pr_map

  local line=""
  for line in "${(@f)pr_list}"; do
    local pr_number="" pr_title="" pr_url="" pr_branch="" pr_state="" pr_author="" is_draft="" has_dnm_label="" approval_count="" user_has_approved=""
    IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state pr_author is_draft has_dnm_label approval_count user_has_approved _ <<< "$line"

    pr_choices+=("$pr_number: $pr_title")
    pr_map[$pr_number]="$pr_number${TAB}$pr_title${TAB}$pr_url${TAB}$pr_branch${TAB}$pr_state${TAB}$pr_author${TAB}$is_draft${TAB}$has_dnm_label${TAB}$approval_count${TAB}$user_has_approved"
  done

  local prs=""
  if (( select_prs_is_1 )); then
    prs="$(choose_one_ -i "$header" "${pr_choices[@]}")"
  else
    prs="$(choose_multiple_ -i "$header" "${pr_choices[@]}")"
  fi
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$prs" ]]; then return 1; fi

  local pr=""
  for pr in "${(@f)prs}"; do
    local pr_number="${pr%%:*}"
    local pr_info="${pr_map[$pr_number]}"

    print -r -- "$pr_info"
  done
}

function proj_bkp_() {
  set +x
  eval "$(parse_flags_ "$0" "d" "" "$@")"
  (( proj_bkp_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_bkp_is_h )); then
    proj_print_help_ "$proj_cmd bkp"
    return 0;
  fi

  if (( proj_bkp_is_d )); then
    proj_dbkp_ "$@"
    return $?;
  fi

  shift 1

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fmv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local folder_to_backup=""

  if (( single_mode )); then
    folder_to_backup="$proj_folder"
  else
    local dirs=""
    dirs="$(get_folders_ -ijp $i "$proj_folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$dirs" ]]; then
      print " there is no folder to backup" >&2
      return 0;
    fi

    local folder="$(choose_one_ -t "folder" "${(@f)dirs}")"
    if [[ -z "$folder" ]]; then return 1; fi

    folder_to_backup="${proj_folder}/${folder}"
  fi

  if [[ -z "$(ls -- "$folder_to_backup")" ]]; then
    print " project folder is empty" >&2
    return 0;
  fi

  create_backup_ $i "$folder_to_backup" "$single_mode"
}

function proj_dbkp_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_dbkp_is_debug )) && set -x

  local proj_cmd="$1"
  local folder=""

  shift 1
  
  eval "$(parse_args_ "$proj_cmd bkp" "folder:fz" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${PUMP_FOLDER[$i]}"

  local backups_folder="$(get_proj_special_folder_ -b "$proj_cmd" "$proj_folder")"
  
  if [[ -n "$folder" ]]; then
    if [[ "$folder" == "$backups_folder"* ]]; then
      del -f -- "$folder"
      return $?;
    fi
    print " fatal: not a valid backup folder for: $proj_cmd" >&2
    return 1;
  fi

  if [[ ! -d "$backups_folder" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  local dirs=""
  dirs="$(get_folders_ -p $i "$backups_folder" 2>/dev/null)"
  if (( $? == 130 )); then return 130; fi

  if [[ -z "$dirs" ]]; then
    print " there is no backup" >&2
    return 0;
  fi

  dirs="$(choose_multiple_ "folders" "${(@f)dirs}")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$dirs" ]]; then return 1; fi

  local folders=("${(@f)dirs}")

  local RET=0

  local folder=""
  for folder in "${folders[@]}"; do
    local clean_folder="$(echo "$folder" | awk -F'\t' '{print $1}')"
    del -f -- "${backups_folder}/${clean_folder}"
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

function delete_node_modules_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( delete_node_modules_folder_is_debug )) && set -x

  local folder_to_backup="$1"
  local title="$2"

  local folder_to_backup_name="$(basename -- "$folder_to_backup")"

  if [[ -n "$title" ]]; then
    title="$title $folder_to_backup_name"
  else
    title="detele node_modules folder... $folder_to_backup_name"
  fi

  if command -v gum &>/dev/null; then
    gum spin --title="$title" -- \
      find "$folder_to_backup" -type d -name "node_modules" -prune -exec rm -rf '{}' +
  else
    print "$title"
    find "$folder_to_backup" -type d -name "node_modules" -prune -exec rm -rf '{}' +
  fi
}

function print_convert_help_() {
  local old_proj_folder="$1"
  local old_single_mode="$2"
  local current_step="$3"
  local temp_folder="$4"

  local steps=();
  
  if (( old_single_mode )); then
    steps=(
      "git -C \"$old_proj_folder\" branch --show-current"
      "rsync -a -- \"$old_proj_folder/\" \"$temp_folder/\""
      "rm -rf -- \"$old_proj_folder\""
      "rsync -a -- \"$temp_folder/\" \"$old_proj_folder/$current_branch/\""
      "rm -rf -- \"$temp_folder\""
    )
  else
    steps=(
      "rsync -a -- \"$old_proj_folder/\" \"$temp_folder/\""
      "rsync -a -- \"$old_proj_folder/\" \"$temp_folder/\""
      "rm -rf -- \"$old_proj_folder\""
      "rsync -a -- \"$temp_folder/\" \"$old_proj_folder/\""
      "rm -rf -- \"$temp_folder\""
    )
  fi

  print -n -- "${orange_cor} run manual steps:"

  # print steps based on current_step, print current failed step and remaining steps
  local step=""
  local index=1
  for step in "${steps[@]}"; do
    if (( index < current_step )); then
      # skip completed steps
      (( index++ ))
      continue
    elif (( index == current_step )); then
      print -n -- $'\n'" ${orange_cor}•${yellow_cor} $step"
    else
      print -n -- $'\n'" ${orange_cor}•${yellow_cor} $step"
    fi
    (( index++ ))
  done

  print -n -- "${reset_cor}"
  print ""
}

function convert_mode_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( convert_proj_mode_is_debug )) && set -x

  local i="$1"
  local old_proj_folder="$2"
  local old_single_mode="$3"

  if [[ ! -d "$old_proj_folder" ]]; then return 0; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local new_mode="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "single mode" || echo "multiple mode" )"

  local temp_folder="$(get_proj_special_folder_ -t "$proj_cmd" "$proj_folder")"

  if (( old_single_mode )); then
    # create a folder named $current_branch in the same level of old_proj_folder and move all content to it, then delete old_proj_folder and move the new folder to old_proj_folder
    if ! is_folder_git_ "$old_proj_folder"; then return 0; fi

    local current_branch="$(get_my_branch_ "$old_proj_folder" 2>/dev/null)"

    if [[ -z "$current_branch" ]]; then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to get branch name${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder" "$old_single_mode" 1 "$temp_folder"
      return 1;
    fi

    delete_node_modules_folder_ "$old_proj_folder" "preparing to convert mode to... $new_mode"

    if command -v gum &>/dev/null; then
      gum spin --title="moving files... $current_branch" -- \
        rsync -a -- "$old_proj_folder/" "$temp_folder/"
    else
      print " moving files... $current_branch"
      rsync -a -- "$old_proj_folder/" "$temp_folder/"
    fi

    if (( $? )); then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to move files${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder" "$old_single_mode" 2 "$temp_folder"
      return 1;
    fi

    pre_delete_folder_ "$old_proj_folder"

    if command -v gum &>/dev/null; then
      gum spin --title="removing old project folder... $(basename -- "$old_proj_folder")" -- rm -rf -- "$old_proj_folder"
    else
      print " removing old project folder... $(basename -- "$old_proj_folder")"
      rm -rf -- "$old_proj_folder"
    fi

    if (( $? )); then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to remove old folder${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder" "$old_single_mode" 3 "$temp_folder"
      return 1;
    fi

    if command -v gum &>/dev/null; then
      gum spin --title="moving files to new folder... $current_branch" -- \
        rsync -a -- "$temp_folder/" "$old_proj_folder/$current_branch/"
    else
      print " moving files to new folder... $current_branch"
      rsync -a -- "$temp_folder/" "$old_proj_folder/$current_branch/"
    fi

    if (( $? )); then
      rm -rf -- "$temp_folder" &>/dev/null
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to move files${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder/$current_branch" "$old_single_mode" 4 "$temp_folder"
      return 1;
    fi

  else

    local found_branch_folder=""
    local branch_folder=""
    for branch_folder in "${BRANCHES[@]}"; do
      local folder="$old_proj_folder/$branch_folder"

      if is_folder_git_ -r "$folder" &>/dev/null; then
        found_branch_folder="$folder";
        break;
      fi
    done

    if [[ -z "$found_branch_folder" ]]; then
      # find the first folder in old_proj_folder that is a git folder and use it as branch_folder
      local folders=($(find "$old_proj_folder" -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null))

      local folder=""
      for folder in "${folders[@]}"; do
        if is_folder_git_ -r "$folder" &>/dev/null; then
          found_branch_folder="$folder"
          break;
        fi
      done
    fi

    if [[ -z "$found_branch_folder" ]]; then
      return 0;
    fi

    delete_node_modules_folder_ "$found_branch_folder" "preparing to convert mode..."

    if command -v gum &>/dev/null; then
      gum spin --title="moving files... $(basename -- "$found_branch_folder")" -- \
        rsync -a -- "$found_branch_folder/" "$temp_folder/"
    else
      print " moving files... $(basename -- "$found_branch_folder")"
      rsync -a -- "$found_branch_folder/" "$temp_folder/"
    fi

    if (( $? )); then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to move files${reset_cor}" >&2
      print_convert_help_ "$found_branch_folder" "$old_single_mode" 1 "$temp_folder"
      return 1;
    fi

    # make backup of $old_proj_folder, then move all content from a branch_folder to old_proj_folder

    local backups_folder="$(get_proj_special_folder_ -b "$proj_cmd" "$proj_folder")"
    local old_proj_folder_name="$(basename -- "$found_branch_folder")"
    local proj_backup_folder="${backups_folder}/${old_proj_folder_name}-$(date +%H%M%S)"

    pre_delete_folder_ "$proj_folder"

    if command -v gum &>/dev/null; then
      gum spin --title="creating backup... $old_proj_folder_name" -- \
        rsync -a -- "$proj_folder/" "$proj_backup_folder/"
    else
      print " creating backup... $old_proj_folder_name"
      rsync -a -- "$proj_folder/" "$proj_backup_folder/"
    fi

    if (( $? )); then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to create backup${reset_cor}" >&2
      print_convert_help_ "$proj_folder" "$old_single_mode" 2 "$proj_backup_folder"
      return 1;
    fi

    if command -v gum &>/dev/null; then
      gum spin --title="removing old project folder... $old_proj_folder_name" -- rm -rf -- "$old_proj_folder"
    else
      print " removing old project folder... $old_proj_folder_name"
      rm -rf -- "$old_proj_folder"
    fi

    if (( $? )); then
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to remove old folder${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder" "$old_single_mode" 3 "$temp_folder"
      return 1;
    fi

    if command -v gum &>/dev/null; then
      gum spin --title="moving files to new folder... $old_proj_folder_name" -- \
        rsync -a -- "$temp_folder/" "$old_proj_folder/"
    else
      print " moving files to new folder... $old_proj_folder_name"
      rsync -a -- "$temp_folder/" "$old_proj_folder/"
    fi

    if (( $? )); then
      rm -rf -- "$temp_folder" &>/dev/null
      print " ${red_cor}cannot convert $proj_cmd to $new_mode because it failed to move files${reset_cor}" >&2
      print_convert_help_ "$old_proj_folder" "$old_single_mode" 4 "$temp_folder"
      return 1;
    fi

  fi

  rm -rf -- "$temp_folder" &>/dev/null
}

function create_backup_() {
  set +x
  eval "$(parse_flags_ "$0" "sd" "" "$@")"
  (( create_backup_is_debug )) && set -x

  local i="$1"
  local folder_to_backup="$2"
  local single_mode="$3"

  if [[ ! -d "$folder_to_backup" ]]; then return 1; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"

  local backups_folder="$(get_proj_special_folder_ -b "$proj_cmd" "$proj_folder")"

  local folder_to_backup_name="$(basename -- "$folder_to_backup")"
  local proj_backup_folder="${backups_folder}/${folder_to_backup_name}-$(date +%H%M%S)"
  local proj_backup_folder_name="$(basename -- "$proj_backup_folder")"

  if command -v gum &>/dev/null; then
    gum spin --title="cleaning old backup folder... $proj_backup_folder_name" -- rm -rf -- "$proj_backup_folder"
  else
    print " cleaning old backup folder... $proj_backup_folder_name"
    rm -rf -- "$proj_backup_folder"
  fi

  mkdir -p -- "$proj_backup_folder"

  if (( create_backup_is_d )); then
    pre_delete_folder_ "$folder_to_backup"
  fi

  delete_node_modules_folder_ "$folder_to_backup"

  if (( create_backup_is_d || create_backup_is_s )); then
    if command -v gum &>/dev/null; then
      gum spin --title="creating backup and deleting folder... $folder_to_backup_name" -- mv -- "$folder_to_backup/" "$proj_backup_folder/"
    else
      print " creating backup and deleting folder... $folder_to_backup_name"
      mv -- "$folder_to_backup/" "$proj_backup_folder/"
    fi
  else
    if command -v gum &>/dev/null; then
      gum spin --title="creating backup... $folder_to_backup_name" -- \
        rsync -a -- "$folder_to_backup/" "$proj_backup_folder/"
    else
      print " creating backup... $folder_to_backup_name"
      rsync -a -- "$folder_to_backup/" "$proj_backup_folder/"
    fi
  fi
  local RET=$?

  if (( RET == 0 )); then
    if (( create_backup_is_d )); then
      if command -v gum &>/dev/null; then
        gum spin --title="cleaning folder... $folder_to_backup_name" -- rm -rf -- "$folder_to_backup"
      else
        print " cleaning folder... $folder_to_backup_name"
        rm -rf -- "$folder_to_backup"
      fi
    elif (( create_backup_is_s )); then
      if command -v gum &>/dev/null; then
        gum spin --title="cleaning folder... $folder_to_backup_name" -- find "$folder_to_backup" -mindepth 1 -type d -exec rm -rf {} +
      else
        print " cleaning folder... $folder_to_backup_name"
        find "$folder_to_backup" -mindepth 1 -type d -exec rm -rf {} +
      fi
    fi

    if (( create_backup_is_d || create_backup_is_s )); then
      print " ${hi_gray_cor}backup created: ${gray_cor}$proj_backup_folder${reset_cor}"
    else
      print " ${hi_gray_cor}backup created: $proj_backup_folder${reset_cor}"
    fi

    return 0;
  fi

  print " ${red_cor}failed to create backup: $proj_backup_folder${reset_cor}" >&2

  return $RET;
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
    proj_print_help_ "$proj_cmd exec"
    print "  --"
    print "  available scripts in: ${green_cor}$proj_script_folder${reset_cor}"
    print " "
    local file
    for file in "${files[@]:t}"; do
      print "  ${hi_yellow_cor}$proj_cmd exec ${file%.*}${reset_cor}"
    done

    # find a readme file in proj_script_folder
    local readme="$(find "$proj_script_folder" -maxdepth 1 -type f -iname "readme*" | head -n 1 2>/dev/null)"
    
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

  local file=""
  file="$(choose_one_ -i "script" "${files[@]:t}")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$file" ]]; then return 1; fi

  local script="$proj_script_folder/$file"

  if [[ ! -f "$script" ]]; then
    print " execution script not found: $script" >&2
    print " run: ${hi_yellow_cor}$proj_cmd exec -h${reset_cor} to see usage" >&2
    return 1;
  fi

  zsh -i $script $i "$@"
  return $?;
}

function proj_version_() {
  set +x
  
  local proj_cmd="$1"
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ $i; then return 1; fi

  local web_url="${PUMP_VERSION_WEB[$i]}"
  local version_cmd="${PUMP_VERSION_CMD[$i]}"

  if [[ -n "$web_url" && "$web_url" != "0" ]]; then
    eval "$(parse_flags_ "$0" "w" "" "$@")"
  else
    eval "$(parse_flags_ "$0" "" "" "$@")"
  fi
  (( proj_version_is_debug )) && set -x

  if (( proj_version_is_h )); then
    proj_print_help_ "$proj_cmd version"
    return 0;
  fi

  local meta_name=""
  local RET=0

  if [[ -z "$web_url" ]]; then
    confirm_ "do you want to use a web site to get the version?"
    RET=$?
    if (( RET == 130 )); then return 130; fi

    if (( RET == 0 )); then
      web_url="$(input_type_ "type the url to web site")"
      if (( $? == 130 )); then return 130; fi
      if [[ -n "$web_url" ]]; then
        update_config_ $i "PUMP_VERSION_WEB" "$web_url"
      fi
    else
      update_config_ $i "PUMP_VERSION_WEB" "0" &>/dev/null # must be silent here
    fi
  elif [[ "$web_url" == "0" ]]; then
    web_url=""
  else
    meta_name="$(echo "$web_url" | awk -F"$TAB" '{print $2}')"
    web_url="$(echo "$web_url" | awk -F"$TAB" '{print $1}')"
  fi

  if [[ -n "$web_url" && -z "$meta_name" ]]; then
    meta_name="$(input_type_mandatory_ "type the meta tag name" "application-version" 50)"
    if (( $? == 130 )); then return 130; fi
    if [[ -n "$meta_name" ]]; then
      update_config_ $i "PUMP_VERSION_WEB" "${web_url}${TAB}${meta_name}"
    fi
  fi

  if [[ -z "$version_cmd" ]]; then
    confirm_ "do you want to use a command to get the version?"
    RET=$?
    if (( RET == 130 )); then return 130; fi

    if (( RET == 0 )); then
      version_cmd="$(input_type_ "type the command to get the version")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$version_cmd" ]]; then return 1; fi

      update_config_ $i "PUMP_VERSION_CMD" "$version_cmd"
    else
      if [[ -n "$web_url" ]]; then
        update_config_ $i "PUMP_VERSION_CMD" "0"
      else
        update_config_ $i "PUMP_VERSION_WEB" "" &>/dev/null
        proj_version_ "$proj_cmd" "$@"
        return $?;
      fi
    fi
  elif [[ "$version_cmd" == "0" ]]; then
    version_cmd=""
  fi

  if (( proj_version_is_w )) || [[ -z "$version_cmd" ]]; then
    if [[ -n "$web_url" && -n "$meta_name" ]]; then
      curl -s "$web_url" | grep -o "<meta name=\"$meta_name\" content=\"[^\"]*\"" | sed -E 's/.*content="([^"]*)"/\1/'
      return $?;  
    fi

    return 1;
  fi

  if [[ -n "$version_cmd" ]]; then
    eval "$version_cmd"
    return $?;
  fi
  
  return 1;
}

function proj_tag_() {
  set +x
  eval "$(parse_flags_ "$0" "fd" "" "$@")"
  (( proj_tag_is_debug )) && set -x
  
  local proj_cmd="$1"
  local tag=""

  if (( proj_tag_is_h )); then
    proj_print_help_ "$proj_cmd tag"
    return 0;
  fi

  if (( proj_tag_is_d )); then
    proj_dtag_ "$@"
    return $?;
  fi

  shift 1
  
  eval "$(parse_args_ "$proj_cmd tag" "tag:to" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_folder="${3:-${PUMP_FOLDER[$i]}}"

  local folder="$(find_git_folder_ "$proj_folder")"
  if [[ -z "$folder" ]]; then return 1; fi

  if ! is_folder_pkg_ "$folder"; then return 1; fi
  
  prune "$folder" &>/dev/null

  if [[ -z "$tag" ]]; then
    tag="$(get_from_package_json_ "version" "$folder" 2>/dev/null)"
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
  local n=""

  if (( proj_tags_is_h )); then
    proj_print_help_ "$proj_cmd tags"
    proj_print_help_ "$proj_cmd tag"
    return 0;
  fi

  shift 1
  
  eval "$(parse_args_ "$proj_cmd tags" "n:nz:20" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"

  local folder="$(find_git_folder_ "$proj_folder")"
  if [[ -z "$folder" ]]; then return 1; fi

  prune "$folder" &>/dev/null

  local name="" posted="" author=""
  git -C "$folder" for-each-ref refs/tags --sort=-creatordate --format='%(refname:short)'"$TAB"'%(creatordate:iso8601)'"$TAB"'%(authorname)' --count="$n" | while IFS=$TAB read -r name posted author; do
    posted="$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$posted" "+%m/%d/%Y %H:%M" 2>/dev/null || echo "$posted")"

    printf "%-24s %-24s %-13s %-18s %s\n" "$name" "$posted" "$author"
  done
}

function proj_dtag_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_dtag_is_debug )) && set -x

  local proj_cmd="$1"
  local tag=""

  shift 1
  
  eval "$(parse_args_ "$proj_cmd tag" "tag:to" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fv $i; then return 1; fi
  
  local proj_folder="${3:-${PUMP_FOLDER[$i]}}"

  local folder="$(find_git_folder_ "$proj_folder")"
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

function is_branch_status_clean_() {
  set +x
  eval "$(parse_flags_ "$0" "" "aiu" "$@")"
  (( is_branch_status_clean_is_debug )) && set -x

  local branch_status="$(get_branch_status_ "$@" 2>/dev/null)"

  if [[ -z "$branch_status" ]]; then
    return 0;
  fi

  return 1;
}

function get_branch_status_() {
  set +x
  eval "$(parse_flags_ "$0" "aiu" "" "$@")"
  (( get_branch_status_is_debug )) && set -x

  local folder="${1:-$PWD}"

  if [[ -z "$folder" ]]; then return 1; fi

  if ! is_folder_git_ "$folder" &>/dev/null; then return 1; fi

  local files=()
  local output=""

  if (( get_branch_status_is_a )); then # all files
    output="$(git -C "$folder" diff --name-only --cached 2>/dev/null)"
    if (( $? == 0 )); then files+=("${(@f)output}"); fi

    output="$(git -C "$folder" diff --name-only 2>/dev/null)"
    if (( $? == 0 )); then files+=("${(@f)output}"); fi

    if [[ -n "$files" ]]; then
      print " staged and unstaged files detected in: $folder" >&2
    fi
  
  elif (( get_branch_status_is_i )); then # staged files
    output="$(git -C "$folder" diff --name-only --cached 2>/dev/null)"
    if (( $? == 0 )); then files+=("${(@f)output}"); fi

    if [[ -n "$files" ]]; then
      print " staged files detected in: $folder" >&2
    fi
  
  elif (( get_branch_status_is_u )); then # unstaged files
    output="$(git -C "$folder" diff --name-only 2>/dev/null)"
    if (( $? == 0 )); then files+=("${(@f)output}"); fi

    output="$(git -C "$folder" ls-files --others --exclude-standard 2>/dev/null)"
    files+=("${(@f)output}")

    if [[ -n "$files" ]]; then
      print " unstaged/untracked files detected in: $folder" >&2
    fi
  
  else
    output="$(git -C "$folder" status --porcelain 2>/dev/null | awk '{ print $2 }')"
    if (( $? == 0 )); then files+=("${(@f)output}"); fi

    if [[ -n "$files" ]]; then
      print " uncommitted files detected in: $folder" >&2
    fi
  fi

  if [[ -n "$files" ]]; then
    echo "${files[@]}"
    return 0;
  fi

  return 1;
}

function proj_rel_() {
  set +x
  eval "$(parse_flags_ "$0" "mnpfdbr" "" "$@")"
  (( proj_rel_is_debug )) && set -x
  
  local proj_cmd="$1"
  local branch=""
  local tag=""
  local title=""

  if (( proj_rel_is_h )); then
    proj_print_help_ "$proj_cmd rel"
    return 0;
  fi

  if (( proj_rel_is_d )); then
    proj_drel_ "$@"
    return $?;
  fi

  local params="branch:b,tag:to,title:to"

  if [[ "$proj_cmd" == "$CURRENT_PUMP_SHORT_NAME" ]] && is_folder_git_ &>/dev/null; then
    params="branch:bz,tag:to,title:to"
  fi

  shift 1

  eval "$(parse_args_ "$proj_cmd rel" "$params" "$@")"
  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -fr $i; then return 1; fi
  if ! check_gh_; then return 1; fi
  
  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"

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

  local remote_branch="$(get_remote_branch_ -f "$branch" "$folder")"

  if [[ -z "$remote_branch" ]]; then
    print " fatal: branch not found: $branch" >&2
    print " run: ${hi_yellow_cor}$proj_cmd rel -h${reset_cor} to see usage" >&2
    return 1;
  fi

  local folder="$(get_proj_special_folder_ -t "$proj_cmd" "$proj_folder")"

  if ! clone_repo_ -o "$proj_repo" "$folder" "preparing $lbl_release of ${blue_cor}$proj_cmd${reset_cor} from ${yellow_cor}$remote_branch${reset_cor} branch..."; then
    local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"
    print " fatal: failed to clone ${repo_name}" >&2
    return 1;
  fi

  print "   preparing $lbl_release of ${blue_cor}$proj_cmd${reset_cor} from ${yellow_cor}$remote_branch${reset_cor} branch..."

  local my_branch="$(get_my_branch_ "$PWD")"
  if [[ -z "$my_branch" ]]; then return 1; fi
  
  if [[ "$my_branch" == "$branch" ]] && get_branch_status_ "$PWD" 1>/dev/null; then
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

      tag="$(get_from_package_json_ "version" "$folder" 2>/dev/null)"
    fi

    if [[ -z "$tag" ]]; then
      local latest_tag="$(tags 1 2>/dev/null)"
      local pkg_tag=""

      pkg_tag="$(get_from_package_json_ "version" "$folder" 2>/dev/null)"

      if [[ -n "$latest_tag" && "$latest_tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
        latest_tag="${latest_tag#v}"
      fi
      if [[ -n "$pkg_tag" && "$pkg_tag" =~ ^v[0-9]+.[0-9]+.[0-9]+$ ]]; then
        pkg_tag="${pkg_tag#v}"
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

  if [[ -z "$title" ]]; then
    title="$tag"
  fi

  local flags=()
  
  if (( proj_rel_is_b )); then
    flags+=(--prerelease)
  else
    if (( ! proj_rel_is_r )); then
      flags+=(--fail-on-no-commits)
    fi
  fi

  if (( ! proj_rel_is_f )) && ! confirm_ "create ${lbl_release} title: ${pink_cor}$title${reset_cor} - tag: ${pink_cor}$tag${reset_cor}?"; then
    return 0;
  fi

  if (( is_version_bumped )); then
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

  if gh release create "$tag" --repo "$proj_repo" --title="$title" --target="$remote_branch" --generate-notes "${flags[@]}"; then
    if (( is_version_bumped )); then
      local my_branch="$(get_my_branch_ -l "$PWD")"
      if [[ -z "$my_branch" ]]; then return 1; fi

      if [[ "$my_branch" == "$remote_branch" ]]; then
        print " version was bumped on your branch, run: ${hi_yellow_cor}pull${reset_cor} or ${hi_yellow_cor}pullr${reset_cor} to update it"

      else
        # if my_branch exists, that means we are in the project folder
        print " version was bumped on $remote_branch branch"
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
  local limit=""

  if (( proj_rels_is_h )); then
    proj_print_help_ "$proj_cmd rels"
    proj_print_help_ "$proj_cmd rel"
    return 0;
  fi

  shift 1
  
  eval "$(parse_args_ "$proj_cmd rels" "limit:nz:20" "$@")"
  shift $arg_count
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -r $i; then return 1; fi
  if ! check_gh_; then return 1; fi
  
  local proj_repo="${PUMP_REPO[$i]}"

  local name="" tag="" type="" posted="" is_draft=""
  gh release list --repo "$proj_repo" --limit="$limit" --order desc --json name,tagName,isPrerelease,createdAt,isDraft --jq '.[] | "\(.name)'"$TAB"'\(.tagName)'"$TAB"'\(.isPrerelease | if . then "Pre-release" else "Latest" end)'"$TAB"'\(.createdAt)'"$TAB"'\(.isDraft)"' | while IFS=$TAB read -r name tag type posted is_draft; do
    posted="$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$posted" "+%m/%d/%Y %H:%M" 2>/dev/null || echo "$posted")"
    
    local draft="$( [[ "$is_draft" == "true" ]] && echo "Draft" || echo "Published" )"

    printf "%-24s %-24s %-13s %-18s %s\n" "$tag" "$name" "$type" "$posted" "$draft"
  done
}

# delete release
function proj_drel_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_drel_is_debug )) && set -x

  local proj_cmd="$1"
  local tag=""

  shift 1
  
  eval "$(parse_args_ "$proj_cmd rel" "tag:to" "$@")"
  shift $arg_count
  
  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_proj_ -r $i; then return 1; fi
  if ! check_gh_; then return 1; fi
  
  local proj_repo="${PUMP_REPO[$i]}"

  if [[ -n "$tag" ]]; then
    proj_drel_single_ "$proj_cmd" "$tag" "" "$proj_repo"
    return $?;
  fi

  local tags=""
  if command -v gum &>/dev/null; then
    tags="$(gum spin --title="fetching tags..." -- gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}')"
  else
    print " fetching tags..."
    tags="$(gh release list --repo "$proj_repo" | awk '{print $1 "\t" $2}')"
  fi
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
    print " run: ${hi_yellow_cor}$proj_cmd rel -h${reset_cor} to see usage" >&2
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

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"

  print " failed to delete release: $display_tag" >&2
  print " check if release immutability is enabled in repository: $repo_name" >&2
  return 1;
}

function proj_jira_find_folder_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( proj_jira_find_folder_is_debug )) && set -x

  local i="$1"
  local search_key="$2"
  local prompt_label="$4"
  local proj_folder="$5"

  local single_mode=0
  local dirs+=("other...")

  dirs+=("${(f)"$(get_maybe_jira_tickets_ -aij $i "$single_mode" "$proj_folder" "$search_key" 2>/dev/null)"}")
  if (( $? == 130 )); then return 130; fi
  
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
  local prompt_label="$3"

  local proj_folder="${PUMP_FOLDER[$i]}"

  local branch_found=""
  branch_found="$(select_branch_ -jli "$jira_key" "$prompt_label" "$proj_folder" 2>/dev/null)"
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
  local proj_cmd="${1%% *}"
  local input="${1#* }"

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
  local key=""
  local jira_status=""

  if (( proj_jira_is_h )); then
    proj_print_help_ "$proj_cmd jira"
    return 0;
  fi

  shift 1
  
  eval "$(parse_args_ "$proj_cmd jira" "key:jk,jira_status:to" "$@")"
  shift $arg_count

  if [[ -n "$jira_status" ]] && (( ! proj_jira_is_x )); then
    print " fatal: not a valid argument: $jira_status" >&2
    print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
    return 1;
  fi

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
  
  if ! check_gum_; then return 1; fi
  if ! check_proj_ -fm $i; then return 1; fi
  if ! check_jira_ -ipwss $i; then return 1; fi

  local label="$(get_label_for_status_ $i "$jira_status" "$@")"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  if (( proj_jira_is_v_v )); then
    # view all work item status
    if [[ -n "$key" ]]; then
      print " fatal: not a valid argument for -v -v: $key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local branch_or_folders=("${(f)"$(get_maybe_jira_tickets_ -afj $i "$single_mode" "$proj_folder" "" 2>/dev/null)"}")

    # for each jira_key in jira_keys, view status
    local branch_or_folder=""
    for branch_or_folder in "${branch_or_folders[@]}"; do
      local key="$(extract_jira_key_ "$branch_or_folder")"

      update_jira_status_ -v -- $i "$key" "" "" "" "$branch_or_folder"
    done

    return 0;
  fi

  local jira_key=""
  local jira_title=""
  local current_status=""
  local current_assignee_email=""

  # resolve jira_key from a branch or folder
  if (( proj_jira_is_c || proj_jira_is_a || proj_jira_is_e || proj_jira_is_r || proj_jira_is_t || proj_jira_is_s || proj_jira_is_d )); then

    if (( proj_jira_is_x )); then
      jira_key="$key"
    else
      if (( single_mode )); then
        local branch_found="$(proj_jira_find_branch_ "$key" "$label" 2>/dev/null)"
        if (( $? == 130 )); then return 130; fi

        jira_key="$(extract_jira_key_ "$branch_found")"

      else
        local choosen_folder="$(proj_jira_find_folder_ $i "$key" "$label" "$proj_folder" 2>/dev/null)"
        if (( $? == 130 )); then return 130; fi
        
        jira_key="$(extract_jira_key_ "$choosen_folder")"
      fi
    fi

    if [[ -z "$jira_key" ]]; then
      local output=""
      output="$(select_jira_ticket_ $i "$key" "$jira_status" "$label" "$@")"

      if (( $? == 130 )); then return 130; fi
      if [[ -z "$output" ]]; then return 1; fi
      IFS=$TAB read -r jira_key jira_title current_status current_assignee_email _ <<< "$output"
    fi

    update_jira_status_ $i "$jira_key" "$jira_status" "$current_status" "$current_assignee_email" "$@"

    return $?;
  fi

  if (( proj_jira_is_x )); then
    # jira -x - open exact work item

    if [[ -z "$key" ]]; then
      print " fatal: jira key is required for -x flag" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi
    if ! gum spin --title="opening work item..." --  acli jira workitem view "$key" &>/dev/null; then
      print " fatal: not a valid work item: $key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira -h${reset_cor} to see usage" >&2
      return 1;
    fi
  else
    # open or view an work item
    local output=""
    if (( proj_jira_is_v )); then
      output="$(select_jira_ticket_ -v $i "$key" "" "$label")"
    else
      output="$(select_jira_ticket_ -o $i "$key" "" "$label")"
    fi

    if (( $? == 130 )); then return 130; fi
    if [[ -z "$output" ]]; then return 1; fi
    IFS=$TAB read -r jira_key jira_title current_status current_assignee_email _ <<< "$output"
  fi

  if (( proj_jira_is_v )); then
    update_jira_status_ -v -- $i "$jira_key"
    return $?;
  fi

  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"
  local jira_link="https://${jira_base_url}/browse/$jira_key"
  jira_link=$'\e]8;;'"$jira_link"$'\a'"$jira_key"$'\e]8;;\a'

  print " opening work item... ${blue_cor}$jira_link${reset_cor} $jira_title"

  if (( single_mode )); then
    if ! is_folder_git_ "$proj_folder" &>/dev/null; then
      if ! proj_clone_ -j "$proj_cmd"; then
        return 1;
      else
        proj_folder="${PUMP_FOLDER[$i]}"
      fi
    fi

    local branch_found="$(select_branch_ -jli "$jira_key" "to open" "$proj_folder" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -n "$branch_found" ]]; then
      if ! co -e "$branch_found" "$proj_folder"; then
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

      if ! co -b "$final_branch" "$proj_folder"; then
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

  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"

  if (( proj_jira_is_f )); then
    update_jira_status_ -of $i "$jira_key" "$jira_in_progress" "$current_status" "$current_assignee_email"
  else
    update_jira_status_ -o $i "$jira_key" "$jira_in_progress" "$current_status" "$current_assignee_email"
  fi

  return 0;
}

function check_jira_cli_() {
  if ! command -v acli &>/dev/null; then
    print " fatal: command requires acli" >&2
    print " install acli: ${blue_cor}https://developer.atlassian.com/cloud/acli/guides/install-acli/${reset_cor}" >&2
    return 1;
  fi

  if ! gum spin --title="checking jira..." -- acli jira auth status; then
    print " jira user not authenticated, run: " >&2
    print "  • ${hi_yellow_cor}acli jira auth status${reset_cor} to check" >&2
    print "  • ${hi_yellow_cor}acli jira auth login${reset_cor} to login" >&2
    print "  • or try again later" >&2
    return 1;
  fi
}

function check_jira_() {
  set +x
  eval "$(parse_flags_ "$0" "ipwsadcorteb" "" "$@")"
  (( check_jira_is_debug )) && set -x

  local i="$1"

  if [[ -z "$i" ]]; then
    print " fatal: check_jira_ i is required" >&2
    return 1;
  fi

  shift 1

  if (( check_jira_is_i )); then
    if ! check_jira_cli_; then return 1; fi

    if [[ -z "${PUMP_JIRA_API_TOKEN[$i]}" ]]; then
      local typed_base=""
      typed_base="$(input_type_mandatory_ "type your jira api token" "" 255 "")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$typed_base" ]]; then return 1; fi

      update_config_ $i "PUMP_JIRA_API_TOKEN" "$typed_base" &>/dev/null
      PUMP_JIRA_API_TOKEN[$i]="$typed_base"
    fi
  fi

  if (( check_jira_is_p )); then
    if (( PUMP_JIRA_ALERT < 2 && ! check_jira_is_i )) && ! check_jira_cli_; then
      (( PUMP_JIRA_ALERT++ ))
      update_setting_ -f "PUMP_JIRA_ALERT" "$PUMP_JIRA_ALERT" &>/dev/null
    fi

    if ! check_jira_proj_ $i "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_SHORT_NAME[$i]}"; then return 1; fi
  fi

  if (( check_jira_is_w )); then
    if (( ! check_jira_is_p )) && ! check_jira_ $i -p; then return 1; fi
    if ! check_work_types_ -s $i "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_JIRA_WORK_TYPES[$i]}"; then
      return 1;
    fi
  fi

  if (( check_jira_is_s )); then
    if (( ! check_jira_is_i )) && ! check_jira_cli_; then return 1; fi

    if ! check_jira_statuses_ $i -s "${PUMP_JIRA_PROJECT[$i]}" "${PUMP_JIRA_API_TOKEN[$i]}" "${PUMP_JIRA_STATUSES[$i]}"; then
      return 1;
    fi

    if [[ -z "$STATUS_COLOR_MAP" ]]; then
      local jira_statuses="$(check_jira_statuses_ $i)"
      local jira_statuses=("${(@f)jira_statuses}")
      if [[ -n "$jira_statuses" ]]; then
        local ss=""
        for ss in "${jira_statuses[@]}"; do
          local cor=""

          if [[ "${ss:u}" == "BLOCKED" ]]; then
            cor="${bold_red_cor}"
          elif [[ "${ss:u}" == "CANCELED" || "${ss:u}" == "REJECTED" ]]; then
            cor="${bold_red_cor}"
          elif [[ "${ss:u}" == "DONE" || "${ss:u}" == "CLOSED" ]]; then
            cor="${bold_pink_cor}"
          elif [[ "${ss:u}" == "READY FOR PRODUCTION" || "${ss:u}" == "READY TO DEPLOY" || "${ss:u}" == "PRODUCT REVIEW" || "${ss:u}" == "READY" || "${ss:u}" == "UAT" ]]; then
            cor="${bold_orange_cor}"
          elif [[ "${ss:u}" == "IN TEST" || "${ss:u}" == "IN TESTING" || "${ss:u}" == "IN QA" ]]; then
            cor="${bold_cyan_cor}"
          elif [[ "${ss:u}" == "READY FOR TEST" ]]; then
            cor="${bold_green_cor}"
          elif [[ "${ss:u}" == "IN REVIEW" || "${ss:u}" == "CODE REVIEW" || "${ss:u}" == "IN CODE REVIEW" ]]; then
            cor="${bold_magenta_cor}"
          elif [[ "${ss:u}" == "OPEN" || "${ss:u}" == "IN PROGRESS" ]]; then
            cor="${bold_blue_cor}"
          elif [[ "${ss:u}" == "TO DO" || "${ss:u}" == "TODO" ]]; then
            cor="${bold_yellow_cor}"
          else
            cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
          fi

          STATUS_COLOR_MAP[${ss:u}]="$cor"
        done
      fi
    fi
    
    # PUMP_JIRA_TODO
    if (( check_jira_is_d || check_jira_is_s_s )); then
      local jira_todo="${PUMP_JIRA_TODO[$i]}"
      local cor="${bold_yellow_cor}"

      if [[ -z "$jira_todo" ]]; then
        jira_todo="$(select_jira_status_ $i "to mark issue ${cor}\"To Do\"${reset_cor}" "To Do")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_todo" ]]; then
        jira_todo="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"To Do\"${reset_cor}" "To Do" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_todo:u}]}" ]]; then STATUS_COLOR_MAP[${jira_todo:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_TODO" "$jira_todo"
      PUMP_JIRA_TODO[$i]="$jira_todo"
    fi

    # PUMP_JIRA_IN_PROGRESS
    if (( check_jira_is_o || check_jira_is_s_s )); then
      local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
      local cor="${bold_blue_cor}"

      if [[ -z "$jira_in_progress" ]]; then
        jira_in_progress="$(select_jira_status_ $i "to mark issue ${cor}\"In Progress\"${reset_cor}" "In Progress")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_in_progress" ]]; then
        jira_in_progress="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"In Progress\"${reset_cor}" "In Progress" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_in_progress:u}]}" ]]; then STATUS_COLOR_MAP[${jira_in_progress:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_in_progress"
      PUMP_JIRA_IN_PROGRESS[$i]="$jira_in_progress"
    fi

    # PUMP_JIRA_IN_REVIEW
    if (( check_jira_is_r || check_jira_is_s_s )); then
      local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
      local cor="${bold_magenta_cor}"

      if [[ -z "$jira_in_review" ]]; then
        jira_in_review="$(select_jira_status_ $i "to mark issue ${cor}\"Code Review\"${reset_cor}" "Code Review")"
      fi
      if [[ -z "$jira_in_review" ]]; then
        jira_in_review="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Code Review\"${reset_cor}" "Code Review" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_in_review:u}]}" ]]; then STATUS_COLOR_MAP[${jira_in_review:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_in_review"
      PUMP_JIRA_IN_REVIEW[$i]="$jira_in_review"
    fi

    # PUMP_JIRA_IN_TEST
    if (( check_jira_is_t || check_jira_is_s_s )); then
      local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
      local cor="${bold_cyan_cor}"

      if [[ -z "$jira_in_test" ]]; then
        jira_in_test="$(select_jira_status_ $i "to mark issue ${cor}\"In Testing\"${reset_cor}" "In Testing")"
      fi
      if [[ -z "$jira_in_test" ]]; then
        jira_in_test="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"In Testing\"${reset_cor}" "In Testing" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_in_test:u}]}" ]]; then STATUS_COLOR_MAP[${jira_in_test:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_IN_TEST" "$jira_in_test"
      PUMP_JIRA_IN_TEST[$i]="$jira_in_test"

      # PUMP_JIRA_READY_FOR_TEST
      local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]}"
      local cor="${bold_green_cor}"

      if [[ -z "$jira_ready_for_test" ]]; then
        jira_ready_for_test="$(select_jira_status_ $i "to mark issue ${cor}\"Ready for Test\"${reset_cor}" "Ready for Test")"
      fi
      if [[ -z "$jira_ready_for_test" ]]; then
        jira_ready_for_test="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Ready for Test\"${reset_cor}" "Ready for Test" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_ready_for_test:u}]}" ]]; then STATUS_COLOR_MAP[${jira_ready_for_test:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_READY_FOR_TEST" "$jira_ready_for_test"
      PUMP_JIRA_READY_FOR_TEST[$i]="$jira_ready_for_test"
    fi

    # PUMP_JIRA_ALMOST_DONE
    if (( check_jira_is_a || check_jira_is_s_s )); then
      local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
      local cor="${bold_orange_cor}"

      if [[ -z "$jira_almost_done" ]]; then
        jira_almost_done="$(select_jira_status_ $i "to mark issue ${cor}\"Ready for Production\"${reset_cor}" "Ready for Production")"
      fi
      if [[ -z "$jira_almost_done" ]]; then
        jira_almost_done="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Ready for Production\"${reset_cor}" "Ready for Production" 40)"
        if (( $? == 130 || $? == 2 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_almost_done:u}]}" ]]; then STATUS_COLOR_MAP[${jira_almost_done:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_ALMOST_DONE" "$jira_almost_done"
      PUMP_JIRA_ALMOST_DONE[$i]="$jira_almost_done"
    fi

    # PUMP_JIRA_DONE
    if (( check_jira_is_e || check_jira_is_s_s )); then
      local jira_done="${PUMP_JIRA_DONE[$i]}"
      local cor="${bold_pink_cor}"

      if [[ -z "$jira_done" ]]; then
        jira_done="$(select_jira_status_ $i "to mark issue ${cor}\"Done\"${reset_cor}" "Done")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_done" ]]; then
        jira_done="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Done\"${reset_cor}" "Done" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_done:u}]}" ]]; then STATUS_COLOR_MAP[${jira_done:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_DONE" "$jira_done"
      PUMP_JIRA_DONE[$i]="$jira_done"
    fi

    # PUMP_JIRA_CANCELED
    if (( check_jira_is_c || check_jira_is_s_s )); then
      local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
      local cor="${bold_red_cor}"

      if [[ -z "$jira_canceled" ]]; then
        jira_canceled="$(select_jira_status_ $i "to mark issue ${cor}\"Canceled\"${reset_cor}" "Canceled")"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "$jira_canceled" ]]; then
        jira_canceled="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Canceled\"${reset_cor}" "Canceled" 40)"
        if (( $? == 130 )); then return 130; fi
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_canceled:u}]}" ]]; then STATUS_COLOR_MAP[${jira_canceled:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_CANCELED" "$jira_canceled"
      PUMP_JIRA_CANCELED[$i]="$jira_canceled"
    fi

    # PUMP_JIRA_BLOCKED
    if (( check_jira_is_b || check_jira_is_s_s )); then
      local jira_blocked="${PUMP_JIRA_BLOCKED[$i]}"
      local cor="${bold_red_cor}"

      if [[ -z "$jira_blocked" ]]; then
        jira_blocked="$(select_jira_status_ $i "to mark issue ${cor}\"Blocked\"${reset_cor}" "Blocked")"
      fi
      if [[ -z "$jira_blocked" ]]; then
        jira_blocked="$(input_type_mandatory_ -o "type status to mark issue ${cor}\"Blocked\"${reset_cor}" "Blocked" 40)"
      fi
      if [[ -z "${STATUS_COLOR_MAP[${jira_blocked:u}]}" ]]; then STATUS_COLOR_MAP[${jira_blocked:u}]="$cor"; fi
      update_config_ $i "PUMP_JIRA_BLOCKED" "$jira_blocked"
      PUMP_JIRA_BLOCKED[$i]="$jira_blocked"
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
    if command -v acli &>/dev/null; then
      if acli jira project view --key "$jira_proj" >/dev/null; then
        return 0;
      fi
    else
      return 0;
    fi
  fi

  jira_proj="$(select_jira_proj_ $i "$proj_cmd" "$jira_proj")"
  if [[ -z "$jira_proj" ]]; then return 1; fi

  update_config_ $i "PUMP_JIRA_PROJECT" "$jira_proj"
  PUMP_JIRA_PROJECT[$i]="$jira_proj"
}

function check_jira_statuses_() {
  set +x
  eval "$(parse_flags_ "$0" "sr" "" "$@")"
  (( check_jira_statuses_is_debug )) && set -x

  local i="$1"
  local jira_proj="${2:-$PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${3:-$PUMP_JIRA_API_TOKEN[$i]}"
  local jira_statuses="${4:-$PUMP_JIRA_STATUSES[$i]}"

  if [[ -n "$jira_statuses" ]]; then
    if (( ! check_jira_statuses_is_s )); then
      print -r -- "$jira_statuses" | sed "s/$TAB/\n/g"
    fi
    return 0;
  fi

  if (( check_jira_statuses_is_r )); then
    return 0;
  fi

  local current_jira_user_email="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"
  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local board_id="$(get_jira_board_ $i "$jira_proj" "$jira_api_token")"
  
  if [[ -z "$board_id" ]]; then return 1; fi

  jira_statuses="$(gum spin --title="pulling configuration..." -- curl -s \
    -u "$current_jira_user_email:$jira_api_token" \
    -H "Accept: application/json" \
    "https://${jira_base_url}/rest/agile/1.0/board/${board_id}/configuration" \
    | jq -r '.columnConfig.columns[].statuses.[].self' \
    | while read -r self; do
      curl -s -u "$current_jira_user_email:$jira_api_token" "$self" \
      | jq -r '.name'
    done #| awk -v sep="$TAB" '{ printf "%s%s", (NR>1?sep:""), $0 } END { print "" }'
  )"

  if [[ -z "$jira_statuses" ]]; then
    print " fatal: failed to get the list of jira statuses for project: $jira_proj" >&2
    return 1;
  fi

  if (( check_jira_statuses_is_s )); then
    update_config_ $i "PUMP_JIRA_STATUSES" "${jira_statuses//$'\n'/$TAB}"
    PUMP_JIRA_STATUSES[$i]="$(read_config_entry_ $i "PUMP_JIRA_STATUSES")"
  else
    print -r -- "$jira_statuses"
  fi
}

function get_label_for_status_() {
  set +x
  eval "$(parse_flags_ "$0" "adcsvrtebS" "" "$@")"
  (( get_label_for_status_is_debug )) && set -x

  local i="$1"
  local jira_status="$2"

  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_blocked="${PUMP_JIRA_BLOCKED[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  
  local flag=""

  if (( get_label_for_status_is_c )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_canceled"; fi

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

  elif (( get_label_for_status_is_b )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_blocked"; fi

  elif (( get_label_for_status_is_d )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_todo"; fi

  elif (( get_label_for_status_is_e )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_done"; fi
  
  elif (( get_label_for_status_is_r )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_in_review"; fi

  elif (( get_label_for_status_is_t_t )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_in_test"; fi

  elif (( get_label_for_status_is_t )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_ready_for_test"; fi

  elif (( get_label_for_status_is_a )); then
    if [[ -z "$jira_status" ]]; then jira_status="$jira_almost_done"; fi
  
  elif (( get_label_for_status_is_v )); then
    jira_status=""
    label="to ${cor}view${reset_cor}"
  fi

  local cor="$(get_color_status_ "$jira_status")"
  local label="to transition to ${cor}\"$jira_status\"${reset_cor}"

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
  local key=""
  local jira_status=""

  if (( proj_jira_release_is_h )); then
    proj_print_help_ "$proj_cmd jira release"
    return 0;
  fi

  shift 1
  
  eval "$(parse_args_ "$proj_cmd jira release" "key:jk,jira_status:to" "$@")"
  shift $arg_count

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

  if ! check_gum_; then return 1; fi
  if ! check_proj_ -frm $i; then return 1; fi
  if ! check_jira_ -ipwss $i; then return 1; fi
  if ! check_gh_; then return 1; fi

  local label="$(get_label_for_status_ $i "$jira_status" "$@")"

  local proj_folder="${PUMP_FOLDER[$i]}"
  local proj_repo="${PUMP_REPO[$i]}"
  local single_mode="${PUMP_SINGLE_MODE[$i]}"

  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  if (( proj_jira_release_is_v_v )); then
    # view all work item in a release
    if [[ -n "$key" ]]; then
      print " fatal: not a valid argument: $key" >&2
      print " run: ${hi_yellow_cor}$proj_cmd jira release -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local jira_release=""
    jira_release="$(select_jira_release_ $i "$jira_proj" "" "$jira_api_token")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$jira_release" ]]; then return 1; fi

    print " ${purple_cor}release:${reset_cor} $jira_release"

    local tickets="$(filter_jira_keys_by_release_ $i "$jira_proj" "$jira_release" "$key" "$jira_status" "$@")"
    local tickets=("${(@f)tickets}")

    local ticket=""
    for ticket in "${tickets[@]}"; do
      local key="$(echo $ticket | awk '{print $1}')"

      update_jira_status_ -v $i "$key"
    done

    print ""

    if ! check_proj_ -g $i; then return 1; fi

    local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"
    local pr_approval_min="${PUMP_PR_APPROVAL_MIN[$i]}"
    local is_any_pr_found=0

    if [[ "$jira_release" =~ ([0-9]+)(\.[0-9]+)?(\.[0-9]+)? ]]; then
      local release_version="${match[1]}${match[2]:-".0"}${match[3]:-".0"}"
      print " please review for release \`$release_version\`"
    else
      print " please review for release \`$jira_release\`"
    fi

    for ticket in "${tickets[@]}"; do
      local key="$(echo $ticket | awk '{print $1}')"

      local pr_list="$(list_prs_ -od "$key" "$proj_repo")"
      if [[ -z "$pr_list" ]]; then continue; fi

      local line=""
      for line in "${(@f)pr_list}"; do
        local pr_number="" pr_title="" pr_url="" pr_branch="" pr_state="" pr_author="" is_draft="" has_dnm_label="" approval_count="" user_has_approved=""
        IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state pr_author is_draft has_dnm_label approval_count user_has_approved _ <<< "$line"

        if [[ -z "$pr_url" ]]; then continue; fi

        if (( approval_count < pr_approval_min )); then
          if [[ -n "$jira_base_url" ]]; then
            local jira_url="https://${jira_base_url}/browse/${key}"
            print "- [${key}](${jira_url}) - ${pr_url}"
          else
            print "- ${key} - ${pr_url}"
          fi
          is_any_pr_found=1
        fi
      done
    done

    if (( is_any_pr_found == 0 )); then
      print " all pull requests are approved or merged for \"$jira_release\""
    fi

    return 0;
  fi

  local jira_key="$(select_jira_key_by_release_ $i "$key" "$jira_status" "$label" "$@")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$jira_key" ]]; then return 1; fi

  proj_jira_ -x "${flags[@]}" "$proj_cmd" "$jira_key"
}

function select_jira_key_by_release_() {
  set +x
  eval "$(parse_flags_ "$0" "p" "adcsrtvey" "$@")"
  (( select_jira_key_by_release_is_debug )) && set -x

  local i="$1"
  local search_key=""
  local label=""

  if ! check_gh_; then return 1; fi

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    label="$3"
    (( arg_count++ ))
  fi

  shift $arg_count

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  local jira_api_token="${PUMP_JIRA_API_TOKEN[$i]}"

  local jira_release=""
  jira_release="$(select_jira_release_ $i "$jira_proj" "" "$jira_api_token")"
  if (( $? == 130 )); then return 130; fi
  if [[ -z "$jira_release" ]]; then return 1; fi

  local tickets="$(filter_jira_keys_by_release_ -n $i "$jira_proj" "$jira_release" "$search_key" "$@")"

  local ticket=""
  ticket="$(choose_one_ "work item $label" "${(@f)tickets}")"
  if (( $? == 130 )); then return 130; fi

  local jira_key=""

  if [[ -z "$ticket" ]]; then
    if [[ -n "$search_key" ]]; then
      jira_key="$(select_jira_key_by_release_ $i "" "$label" "$@")"
      if (( $? == 130 )); then return 130; fi
    else
      print " no work item found in jira release: ${cyan_cor}$jira_release${reset_cor}" >&2
    fi
    return 1;
  fi

  if [[ -z "$jira_key" ]]; then
    jira_key="$(echo $ticket | awk '{print $1}')"
  fi

  jira_key="$(trim_ $jira_key)"

  echo "$jira_key"
}

function filter_jira_keys_by_release_() {
  set +x
  eval "$(parse_flags_ "$0" "" "nadcsvrtfexy" "$@")"
  (( filter_jira_keys_by_release_is_debug )) && set -x

  local i="$1"
  local jira_proj="$2"
  local jira_release="$3"
  local search_key="$4"

  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_blocked="${PUMP_JIRA_BLOCKED[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"

  local query_status="status!=\"$jira_canceled\""

  if (( filter_jira_keys_by_release_is_d )); then
    query_status+=" AND status!=\"$jira_todo\""

    if (( filter_jira_keys_by_release_is_n )); then
      query_status+=" AND status!=\"$jira_done\""
    fi

  elif (( filter_jira_keys_by_release_is_b )); then
    query_status+=" AND status!=\"$jira_blocked\""

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
    query_status+=" AND status!=\"$jira_ready_for_test\""

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

  elif (( filter_jira_keys_by_release_is_y )); then
    query_status+=" AND status=\"$jira_in_review\""
  fi

  local jira_search="$([[ -n "$search_key" ]] && echo "AND key ~ \"*$search_key*\"" || echo "")"

  local tickets="$(gum spin --title="pulling work items..." -- \
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
      ' | column -t -s $'\t'
    )"

  echo "${tickets}"
}

function choose_work_type_() {
  local i="$1"
  local branch="$2"

  local work_types=($(get_work_types_ $i))

  if [[ " ${BRANCHES[*]} " == *" $branch "* ]]; then
    return 0;
  fi

  if [[ "$branch" == release/* ]]; then
    echo "release"
    return 0;
  fi

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

function get_jira_status_() {
  local jira_key="$1"

  if [[ -z "$jira_key" ]]; then return 1; fi

  gum spin --title=" jira status... $jira_key" -- acli jira workitem view "$jira_key" --fields=status,summary,assignee,issuetype --json | jq -r --arg sep "$TAB" '
    [
      (.fields.status.name // empty),
      (.fields.summary // empty),
      (.fields.assignee.emailAddress // "Unassigned"),
      (.fields.assignee.displayName // "Unassigned"),
      (.fields.issuetype.name // empty | ascii_downcase)
    ] | join($sep)
  '
}

function get_color_status_() {
  local current_status="$1"
  local default_cor="$2"

  # default color for unmatched statuses
  local cor="${STATUS_COLOR_MAP[${current_status:u}]}"

  if [[ -z "$cor" ]]; then
    cor="$default_cor"
  fi

  if [[ -z "$cor" ]]; then
    # cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
    cor="${bold_gray_cor}"
  fi

  echo "$cor"
}

function update_jira_status_() {
  set +x
  eval "$(parse_flags_ "$0" "adcsvrtebfxo" "" "$@")"
  (( update_jira_status_is_debug )) && set -x

  local i="$1"
  local jira_key=""
  local jira_status=""
  local current_status=""
  local current_assignee_email=""
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
    current_status="$4"
    (( arg_count++ ))
  fi

  if [[ -n "$5" && $5 != -* ]]; then
    current_assignee_email="$5"
    (( arg_count++ ))
  fi

  if [[ -n "$6" && $6 != -* ]]; then
    folder="$6"
    (( arg_count++ ))
  fi

  shift $arg_count

  # $i could be zero 0
  if [[ -z "$i" || -z "$jira_key" ]]; then return 1; fi

  local jira_title=""
  local current_assignee_name=""
  local work_type=""

  if [[ -z "$current_assignee_email" || -z "$current_status" ]]; then
    local _output="" # this must be declared separetly so $? works correctly after command substitution
    _output="$(get_jira_status_ "$jira_key")"

    if (( $? != 0 )) || [[ -z "$_output" ]] then
      if check_jira_cli_ 1>/dev/null; then
        print " fatal: failed to get jira issue details for $jira_key" >&2
        print " try again or check if issue key is correct" >&2
      fi
      return 1;
    fi
    IFS=$TAB read -r current_status jira_title current_assignee_email current_assignee_name work_type _ <<< "$_output"
  fi

  local jira_base_url="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Site:/ { print $2 }')"

  local jira_link="https://${jira_base_url}/browse/${jira_key}"
  jira_link=$'\e]8;;'"$jira_link"$'\a'"$jira_key"$'\e]8;;\a'

  local cor="$(get_color_status_ "$current_status")"

  if (( update_jira_status_is_v )); then
    # view status
    if ! check_proj_ -fgm $i; then return 1; fi

    local proj_folder="${PUMP_FOLDER[$i]}"
    local single_mode="${PUMP_SINGLE_MODE[$i]}"
    local pr_approval_min="${PUMP_PR_APPROVAL_MIN[$i]}"

    jira_title="$(truncate_ $jira_title 70)"
    
    display_line_ "" "${cor}"
    print " ${gray_cor}ticket: ${cor}$jira_link${reset_cor}"
    print " ${gray_cor}status: ${cor}$current_status${reset_cor}"
    print " ${gray_cor} title:${reset_cor} ${bold_cor}$jira_title${reset_cor}"
    print " ${gray_cor}  type:${reset_cor} $work_type"
    print " ${gray_cor}assign:${reset_cor} $current_assignee_name"
    
    if [[ -n "$folder" ]]; then
      print " ${gray_cor}folder:${reset_cor} $folder"
    else
      if (( single_mode )); then
        print " ${gray_cor}folder:${reset_cor} $proj_folder"
      else
        local folders="$(find "$proj_folder" -maxdepth 2 -type d -name "$jira_key" ! -path "*/.*" -print 2>/dev/null)"
        local found_proj_folder=("${(@f)folders}")

        for folder in "${found_proj_folder[@]}"; do
          if [[ -n "$folder" ]]; then
            print " ${gray_cor}folder: ${hi_gray_cor}$folder${reset_cor}"
          fi
        done
      fi
    fi

    local proj_repo="${PUMP_REPO[$i]}"

    local pr_list="$(list_prs_ -odm "$jira_key" "$proj_repo")"
    if [[ -z "$pr_list" ]]; then return 0; fi

    local line=""
    for line in "${(@f)pr_list}"; do
      local pr_number="" pr_title="" pr_url="" pr_branch="" pr_state="" pr_author="" is_draft="" has_dnm_label="" approval_count="" user_has_approved=""
      IFS=$TAB read -r pr_number pr_title pr_url pr_branch pr_state pr_author is_draft has_dnm_label approval_count user_has_approved _ <<< "$line"

      if [[ -z "$pr_number" ]]; then continue; fi

      print " ${gray_cor}pull r: $(print_pr_status_ "$pr_number" "$pr_title" "$pr_url" "$pr_branch" "$pr_state" "$pr_author" "$is_draft" "$has_dnm_label" "$approval_count" "$user_has_approved" "$pr_approval_min")"
    done

    return 0;
  fi # if (( update_jira_status_is_v )); then

  # update status

  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_blocked="${PUMP_JIRA_BLOCKED[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"

  if [[ "${current_status:u}" == "${jira_status:u}" ]]; then
    print " work item $jira_link is already in status: $current_status"
    return 0;
  fi

  if (( update_jira_status_is_b )); then
    if [[ "${current_status:u}" == "${jira_blocked:u}" || "${current_status:u}" == "${PUMP_JIRA_BLOCKED[0]:u}" || "${current_status:u}" == "BLOCKED" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_blocked}"

  elif (( update_jira_status_is_d )); then
    if [[ "${current_status:u}" == "${jira_todo:u}" || "${current_status:u}" == "${PUMP_JIRA_TODO[0]:u}" || "${current_status:u}" == "TO DO" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_todo}"

  elif (( update_jira_status_is_e )); then
    if [[ "${current_status:u}" == "${jira_done:u}" || "${current_status:u}" == "${PUMP_JIRA_DONE[0]:u}" || "${current_status:u}" == "DONE" || "${current_status:u}" == "CLOSED" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_done}"

  elif (( update_jira_status_is_r )); then
    if [[ "${current_status:u}" == "${jira_in_review:u}" || "${current_status:u}" == "${PUMP_JIRA_IN_REVIEW[0]:u}" || "${current_status:u}" == "IN REVIEW" || "${current_status:u}" == "CODE REVIEW" || "${current_status:u}" == "IN CODE REVIEW" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_in_review}"

  elif (( update_jira_status_is_t_t )); then
    if [[ "${current_status:u}" == "${jira_in_test:u}" || "${current_status:u}" == "${PUMP_JIRA_IN_TEST[0]:u}" || "${current_status:u}" == "IN TEST" || "${current_status:u}" == "IN TESTING" || "${current_status:u}" == "READY FOR TEST" || "${current_status:u}" == "IN QA" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_in_test}"

  elif (( update_jira_status_is_t )); then
    if [[ "${current_status:u}" == "${jira_ready_for_test:u}" || "${current_status:u}" == "${PUMP_JIRA_READY_FOR_TEST[0]:u}" || "${current_status:u}" == "IN TEST" || "${current_status:u}" == "IN TESTING" || "${current_status:u}" == "READY FOR TEST" || "${current_status:u}" == "IN QA" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_ready_for_test}"

  elif (( update_jira_status_is_a )); then
    if [[ "${current_status:u}" == "${jira_almost_done:u}" || "${current_status:u}" == "${PUMP_JIRA_ALMOST_DONE[0]:u}" || "${current_status:u}" == "READY FOR PRODUCTION" || "${current_status:u}" == "READY TO DEPLOY" || "${current_status:u}" == "PRODUCT REVIEW" || "${current_status:u}" == "READY" || "${current_status:u}" == "UAT" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi
    
    jira_status="${jira_almost_done}"

  elif (( update_jira_status_is_o )); then
    if [[ "${current_status:u}" == "${jira_in_progress:u}" || "${current_status:u}" == "${PUMP_JIRA_IN_PROGRESS[0]:u}" || "${current_status:u}" == "OPEN" || "${current_status:u}" == "IN PROGRESS" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi

    jira_status="${jira_in_progress}"

  elif (( update_jira_status_is_c )); then
    if [[ "${current_status:u}" == "${jira_canceled:u}" || "${current_status:u}" == "${PUMP_JIRA_CANCELED[0]:u}" || "${current_status:u}" == "CANCELED" || "${current_status:u}" == "REJECTED" ]]; then
      print " work item $jira_link is already in status: $current_status"
      return 0;
    fi
    
    jira_status="${jira_canceled}"
  fi

  if [[ "${current_status:u}" == "${jira_canceled:u}" || "${current_status:u}" == "${PUMP_JIRA_CANCELED[0]:u}" || "${current_status:u}" == "CANCELED" || "${current_status:u}" == "REJECTED" ]]; then
    print " work item $jira_link cannot be transitioned because it's canceled" >&2
    return 1;
  fi

  # if transitioning to done, or canceled status, and the work item is not assigned to self, prevent transition
  if (( ! is_assigned )) && [[ "${current_status:u}" == "${jira_done:u}" || "${current_status:u}" == "${jira_canceled:u}" || "${current_status:u}" == "DONE" || "${current_status:u}" == "CLOSED" || "${current_status:u}" == "CANCELED" || "${current_status:u}" == "REJECTED" ]]; then
    print " work item $jira_link cannot transition a closed or canceled work item assigned to $current_assignee_email" >&2
    return 1;
  fi

  local is_assigned=0
  local current_jira_user_email="$(gum spin --title="preparing jira..." -- acli jira auth status 2>/dev/null | awk -F': ' '/Email:/ { print $2 }')"

  if [[ "$current_assignee_email" == "$current_jira_user_email" ]]; then
    is_assigned=1
  else
    local _RET=0
    if (( ! update_jira_status_is_f )); then
      if [[ "$current_assignee_email" == "Unassigned" ]]; then
        confirm_ "work item ${jira_link} is unassigned, assign it to you?"
      else
        confirm_ "work item ${jira_link} is assigned to ${yellow_cor}$current_assignee_email${reset_cor}, re-assign it to you?"
      fi
      _RET=$?
    fi
    if (( _RET == 130 )); then return 130; fi
    if (( _RET == 0 )); then
      local output="$(gum spin --title="assigning work item..." -- acli jira workitem assign --key="$jira_key" --assignee="@me" --yes)"

      if echo "$output" | grep -qiE "failure"; then
        print " work item $jira_link cannot be re-assigned to: $current_jira_user_email" >&2
        print " $output" | grep -w "$jira_key" >&2

        return 1;
      fi

      print " $output" | grep -w "$jira_key"
      is_assigned=1
    fi
  fi

  local _RET=0
  if (( ! update_jira_status_is_f )); then
    if (( is_assigned )); then
      confirm_ "transition ${jira_link} assigned to you, from status ${hi_gray_cor}${current_status}${reset_cor} to status: ${cor}${jira_status}${reset_cor}?"
    elif [[ "$current_assignee_email" == "Unassigned" ]]; then
      confirm_ "transition ${jira_link} unassigned, from status ${hi_gray_cor}${current_status}${reset_cor} to status: ${cor}${jira_status}${reset_cor}?"
    else
      confirm_ "transition ${jira_link} assigned to ${yellow_cor}$current_assignee_email${reset_cor}, from status ${hi_gray_cor}${current_status}${reset_cor} to status: ${cor}${jira_status}${reset_cor}?"
    fi
    _RET=$?
  fi
  if (( _RET == 130 )); then return 130; fi
  if (( _RET == 1 )); then return 1; fi

  local output="$(gum spin --title="transitioning work item..." -- acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)"

  if echo "$output" | grep -qiE "failure" && ! echo "$output" | grep -qiE "story points is required"; then
    jira_status="$(input_type_ "enter correct status for \"$jira_status\", as seen in jira" "$jira_status" 40)"
    if (( $? == 130 || $? == 2 )); then return 130; fi

    if [[ -n "$jira_status" ]] && ; then
      output="$(gum spin --title="transitioning work item..." -- acli jira workitem transition --key="$jira_key" --status="$jira_status" --yes)"

      if echo "$output" | grep -qiE "failure"; then
        print " work item $jira_link cannot be transitioned to status ${cor}$jira_status${reset_cor}" >&2
        print " $output" | grep -w "$jira_key" >&2

        return 1;
      fi
    fi
  fi

  print " $output" | grep -w "$jira_key"

  if (( update_jira_status_is_d )) && [[ "${jira_status:u}" != "${jira_todo:u}" ]]; then
    update_config_ $i "PUMP_JIRA_TODO" "$jira_status"
    PUMP_JIRA_TODO[$i]="$jira_status"

  elif (( update_jira_status_is_o )) && [[ "${jira_status:u}" != "${jira_in_progress:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_PROGRESS" "$jira_status"
    PUMP_JIRA_IN_PROGRESS[$i]="$jira_status"

  elif (( update_jira_status_is_r )) && [[ "${jira_status:u}" != "${jira_in_review:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_REVIEW" "$jira_status"
    PUMP_JIRA_IN_REVIEW[$i]="$jira_status"

  elif (( update_jira_status_is_t_t )) && [[ "${jira_status:u}" != "${jira_in_test:u}" ]]; then
    update_config_ $i "PUMP_JIRA_IN_TEST" "$jira_status"
    PUMP_JIRA_IN_TEST[$i]="$jira_status"

  elif (( update_jira_status_is_t )) && [[ "${jira_status:u}" != "${jira_in_test:u}" ]]; then
    update_config_ $i "PUMP_JIRA_READY_FOR_TEST" "$jira_status"
    PUMP_JIRA_READY_FOR_TEST[$i]="$jira_status"

  elif (( update_jira_status_is_a )) && [[ "${jira_status:u}" != "${jira_almost_done:u}" ]]; then
    update_config_ $i "PUMP_JIRA_ALMOST_DONE" "$jira_status"
    PUMP_JIRA_ALMOST_DONE[$i]="$jira_status"

  elif (( update_jira_status_is_e )) && [[ "${jira_status:u}" != "${jira_done:u}" ]]; then
    update_config_ $i "PUMP_JIRA_DONE" "$jira_status"
    PUMP_JIRA_DONE[$i]="$jira_status"

  elif (( update_jira_status_is_c )) && [[ "${jira_status:u}" != "${jira_canceled:u}" ]]; then
    update_config_ $i "PUMP_JIRA_CANCELED" "$jira_status"
    PUMP_JIRA_CANCELED[$i]="$jira_status"

  elif (( update_jira_status_is_b )) && [[ "${jira_status:u}" != "${jira_blocked:u}" ]]; then
    update_config_ $i "PUMP_JIRA_BLOCKED" "$jira_status"
    PUMP_JIRA_BLOCKED[$i]="$jira_status"

  fi
}

function select_jira_ticket_() {
  set +x
  eval "$(parse_flags_ "$0" "" "knoadcsvrtfexy" "$@")"
  (( select_jira_ticket_is_debug )) && set -x

  local i="$1"
  local search_key=""
  local label=""

  local arg_count=1

  if [[ -n "$2" && $2 != -* ]]; then
    search_key="$2"
    (( arg_count++ ))
  fi

  if [[ -n "$3" && $3 != -* ]]; then
    label="$3"
    (( arg_count++ ))
  fi

  shift $arg_count

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local jira_proj="${PUMP_JIRA_PROJECT[$i]}"
  
  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]}"
  local jira_blocked="${PUMP_JIRA_BLOCKED[$i]}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]}"
  local jira_done="${PUMP_JIRA_DONE[$i]}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]}"
  local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]}"
  local jira_todo="${PUMP_JIRA_TODO[$i]}"

  local query_status="status!=\"$jira_canceled\" AND status!=\"$jira_done\""

  if (( select_jira_ticket_is_a )); then
    query_status+=" AND status!=\"$jira_almost_done\""
    query_status+=" AND status!=\"${jira_todo}\""

  elif (( select_jira_ticket_is_r )); then
    query_status+=" AND status!=\"$jira_in_review\""
    query_status+=" AND status!=\"${jira_todo}\""

  elif (( select_jira_ticket_is_t )); then
    query_status+=" AND status!=\"$jira_in_test\""
    query_status+=" AND status!=\"${jira_ready_for_test}\""
    query_status+=" AND status!=\"${jira_todo}\""

  elif (( select_jira_ticket_is_y )); then
    query_status+=" AND status=\"$jira_in_review\""
  fi

  local jira_search="$([[ -n "$search_key" ]] && echo "AND key ~ \"*$search_key*\"" || echo "")"
  
  local sprint_query="Sprint IN openSprints()"
  local title="pulling work items in open sprints"

  if (( select_jira_ticket_is_n )); then
    sprint_query="Sprint IS NOT EMPTY"
    title="pulling work items in any sprint"
  fi

  local tickets=""

  if (( select_jira_ticket_is_o )); then
    local cor="$(get_color_status_ "$jira_todo")"
    # local current_board="$(get_jira_board_ $i "$jira_proj" 2>/dev/null)"
    # search for work items assigned to current user or not assigned and in "To Do" status
    tickets="$(gum spin --title="$title with status ${cor}${jira_todo}${reset_cor}..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND $query_status AND $sprint_query AND (assignee=currentUser() OR (assignee IS EMPTY AND status=\"${jira_todo}\")) ORDER BY priority DESC" \
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
      ' | column -t -s $'\t'
    )"

  elif (( select_jira_ticket_is_c || select_jira_ticket_is_e )); then
    # search for work items assigned to current user
    tickets="$(gum spin --title="${title}..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND assignee=currentUser() AND $query_status AND $sprint_query ORDER BY priority DESC" \
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
      ' | column -t -s $'\t'
    )"

  elif (( select_jira_ticket_is_y )); then
    # opening a rev
    # search for work items not assigned to current user
    tickets="$(gum spin --title="${title}..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND assignee!=currentUser() AND $query_status AND $sprint_query ORDER BY priority DESC" \
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
      ' | column -t -s $'\t'
    )"
  else
    # search for all work items in the project
    tickets="$(gum spin --title="${title}..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND $sprint_query ORDER BY priority DESC" \
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
      ' | column -t -s $'\t'
    )"
  fi

  if [[ -z "$tickets" ]]; then
    tickets="$(gum spin --title="pulling work items in the backlog..." -- \
      acli jira workitem search \
      --jql "project=\"$jira_proj\" $jira_search AND $query_status ORDER BY priority DESC" \
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
      ' | column -t -s $'\t'
    )"

    if [[ -z "$tickets" && -n "$jira_search" ]]; then
      tickets="$(gum spin --title="pulling work items in the backlog..." -- \
        acli jira workitem search \
        --jql "project=\"$jira_proj\" $jira_search ORDER BY priority DESC" \
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
        ' | column -t -s $'\t'
      )"
    fi
  else
    local ticket_array=("${(@f)tickets}")

    if (( ! select_jira_ticket_is_n )) && (( ${#ticket_array[@]} > 1 )); then
      tickets+=$'\n'"more..."
    fi
  fi

  local ticket=""
  ticket="$(choose_one_ -i "work item $label" "${(@f)$(printf "%s\n" "$tickets")}")"
  if (( $? == 130 )); then return 130; fi

  local jira_title=""
  local current_jira_status=""
  local current_assignee_email=""

  local jira_key="$(trim_ $(echo "$ticket" | awk '{print $1}'))"

  if [[ "$jira_key" == "more..." ]]; then
    local output=""
    output="$(select_jira_ticket_ -n $i "" "$label" "$@")"
    
    if (( $? == 130 )); then return 130; fi
    IFS=$TAB read -r jira_key jira_title current_jira_status current_assignee_email _ <<< "$output"
    jira_title="$(truncate_ $jira_title 70)"

  elif [[ -n "$jira_key" ]]; then
    local output=""
    output="$(get_jira_status_ "$jira_key")"
  
    if (( $? == 130 )); then return 130; fi
    if [[ -n "$output" ]]; then
      IFS=$TAB read -r current_jira_status jira_title current_assignee_email _ <<< "$output"
      jira_title="$(truncate_ $jira_title 70)"
    fi

  else
    if [[ -n "$search_key" ]]; then
      print " no work item found matching \"$search_key\" in project: ${cyan_cor}$jira_proj${reset_cor}" >&2
      return 1;
    fi

    print " no work item found in project: ${cyan_cor}$jira_proj${reset_cor}" >&2
    return 1;
  fi

  echo "$jira_key${TAB}$jira_title${TAB}$current_jira_status${TAB}$current_assignee_email"
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

  if [[ -n "$PUMP_USE_MONOGRAM" ]]; then
    if (( PUMP_USE_MONOGRAM )); then
      local branch_name_monogram="$(get_branch_name_with_monogram_ "$branch_name" "$PUMP_USE_MONOGRAM")"

      echo "$branch_name_monogram"
    else
      echo "$branch_name"
    fi
    return 0;
  fi

  local initials="${USER:0:1}"
  local branch_name_monogram="$(get_branch_name_with_monogram_ "$branch_name" "$initials")"

  confirm_ "create a branch with initials?" "$branch_name_monogram" "$branch_name"
  local RET=$?
  if (( RET == 130 || RET == 2 )); then return 130; fi
  if (( RET == 0 )); then
    update_setting_ "PUMP_USE_MONOGRAM" "$initials" &>/dev/null
    PUMP_USE_MONOGRAM="$initials"

    echo "$branch_name_monogram"
    return 0;
  fi

  update_setting_ "PUMP_USE_MONOGRAM" 0 &>/dev/null
  PUMP_USE_MONOGRAM=0

  echo "$branch_name"
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local operation="$(get_current_git_operation_ "$folder")"

  if [[ "$operation" == "rebase" ]]; then
    if ! git -C "$folder" rebase --abort "$@" &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      git -C "$folder" rebase --abort "$@" &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "merge" ]]; then
    if ! git -C "$folder" merge --abort "$@" &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      git -C "$folder" merge --abort "$@" &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "revert" ]]; then
    if ! git -C "$folder" revert --abort "$@" &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      git -C "$folder" revert --abort "$@" &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "cherry-pick" ]]; then
    if ! git -C "$folder" cherry-pick --abort "$@" &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      git -C "$folder" cherry-pick --abort "$@" &>/dev/null
    fi

    return $?;
  elif [[ "$operation" == "am" ]]; then
    if ! git -C "$folder" am --abort "$@" &>/dev/null; then
      # try to unstage files, but not disapear them then repeat
      git -C "$folder" reset HEAD . &>/dev/null
      git -C "$folder" am --abort "$@" &>/dev/null
    fi

    return $?;
  fi

  return 1;
}

function get_current_git_operation_() {
  local folder="${1:-$PWD}"

  local git_dir="$(git -C "$folder" rev-parse --git-dir 2>/dev/null)"
  
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
    print "  ${hi_yellow_cor}renb <new_name> ${yellow_cor}[<folder>]${reset_cor} : rename current branch to new name"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
    return 0;
  fi

  local new_name=""
  local folder=""

  eval "$(parse_args_ "$0" "new_name:b,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  if ! normalize_branch_name_ "$new_name" 1>/dev/null; then return 1; fi

  if [[ "$my_branch" == "$new_name" ]]; then
    print " fatal: new branch name is the same as current branch name: $my_branch" >&2
    return 1;
  fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  if ! git -C "$folder" branch -m $new_name; then
    return 1;
  fi

  local new_remote_branch="$(get_remote_branch_ "$new_name" "$folder")"
  local my_remote_branch="$(get_remote_branch_ "$my_branch" "$folder")"

  local remote_name="$(get_remote_name_ "$folder")"
  
  git -C "$folder" branch --unset-upstream --quiet &>/dev/null

  if [[ -z "$new_remote_branch" && -n "$my_remote_branch" ]]; then
    if (( ! renb_is_f )); then
      confirm_ "branch ${bold_cor}${new_name}${reset_cor} does not exist remotely, push and set upstream?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
    fi

    # new branch doesnt exist in remote
    if ! git -C "$folder" push --no-verify --set-upstream $remote_name $new_name; then
      return 1
    fi
  
  elif [[ -n "$new_remote_branch" ]]; then
    if (( ! renb_is_f )); then
      confirm_ "branch ${bold_cor}${new_name}${reset_cor} already exists remotely, set as upstream?"
      local RET=$?
      if (( RET == 130 || RET == 2 )); then return 130; fi
      if (( RET == 1 )); then return 1; fi
    fi

    # new branch already exist in remote, just set upstream to it
    git -C "$folder" branch --set-upstream-to="${remote_name}/${new_name}"
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
  #   git -C "$folder" push --no-verify --set-upstream $remote_name $new_name
  # fi
  return 1;
}

function chp() {
  set +x
  eval "$(parse_flags_ "$0" "amcs" "n" "$@")"
  (( chp_is_debug )) && set -x

  if (( chp_is_h )); then
    print "  ${hi_yellow_cor}chp ${yellow_cor}[<hash>] [<parent_number>] [<folder>]${reset_cor} : cherry-pick commit"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}  -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}  -n${reset_cor} : --no-commit"
    print "  ${hi_yellow_cor}  -s${reset_cor} : --signoff"
    return 0;
  fi

  local hash=""
  local parent_number=""
  local folder=""

  eval "$(parse_args_ "$0" "hash:ho,parent_number:nz:1,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( chp_is_a )); then
    abort "$folder"
    return $?;
  fi

  if (( chp_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    conti "$folder" "$@"
    return $?;
  fi

  local commit=""

  # get commit message by hash
  if [[ -z "$hash" ]]; then
    # get a list of commits to revert
    local commits="$(git -C "$folder" --no-pager log --no-merges --oneline -100)"
    local commits=("${(@f)commits}")

    # use choose_multiple so user can select mutliple commits to revert
    commit=($(filter_one_ "commit to cherry-pick" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    # get the hash of the commit to cherry-pick
    local hash="$(echo "$commit" | awk '{print $1}')"
  else
    commit="$(git -C "$folder" --no-pager log -1 --pretty=%s $hash 2>/dev/null)"
  fi

  local flags=(-m $parent_number)

  if (( chp_is_s )); then
    flags+=(--signoff)
  fi

  if (( chp_is_n )); then
    flags+=(--no-commit)
  fi

  if git -C "$folder" cherry-pick $hash "${flags[@]}" "$@"; then
    print "${green_cor}commit cherry-picked${reset_cor} $commit"
  fi
}

function revert() {
  set +x
  eval "$(parse_flags_ "$0" "acs" "n" "$@")"
  (( revert_is_debug )) && set -x

  if (( revert_is_h )); then
    print "  ${hi_yellow_cor}revert ${yellow_cor}[<hash>] [<parent_number>] [<folder>]${reset_cor} : revert commit"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}  -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}  -n${reset_cor} : --no-commit"
    print "  ${hi_yellow_cor}  -s${reset_cor} : --signoff"
    return 0;
  fi

  local hash=""
  local parent_number=""
  local folder=""

  eval "$(parse_args_ "$0" "hash:ho,parent_number:nz:1,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( revert_is_a )); then
    abort "$folder"
    return $?;
  fi

  if (( revert_is_c )); then
    if ! git -C "$folder" add .; then return 1; fi
    conti "$folder" "$@"
    return $?;
  fi

  if [[ -z "$hash" ]]; then
    local commits="$(git -C "$folder" --no-pager log --no-merges --oneline -100)"
    local commits=("${(@f)commits}")

    local commit=($(filter_one_ "commit to revert" "${commits[@]}"))
    if [[ -z "$commit" ]]; then return 1; fi

    hash="$(echo "$commit" | awk '{print $1}')"
  
  elif ! git -C "$folder" cat-file -e "${hash}^{commit}" 2>/dev/null; then
    print " fatal: not a valid commit hash: $hash" >&2
    return 1;
  fi

  local flags=(-m $parent_number)

  if (( revert_is_s )); then
    flags+=(--signoff)
  fi

  if (( revert_is_n )); then
    flags+=(--no-commit)
  fi

  if git -C "$folder" revert $hash "${flags[@]}" "$@"; then
      print "${green_cor}commit reverted${reset_cor} $commit"
  fi
}

function conti() {
  set +x
  eval "$(parse_flags_ "$0" "" "n" "$@")"
  (( conti_is_debug )) && set -x

  if (( conti_is_h )); then
    print "  ${hi_yellow_cor}conti ${yellow_cor}[<folder>]${reset_cor} : continue rebase, merge, revert or cherry-pick in progress"
    print "  ${hi_yellow_cor}  -n${reset_cor} : --no-commit"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local operation="$(get_current_git_operation_ "$folder")"

  if [[ "$operation" == "none" ]]; then
    print " fatal: no rebase, merge, revert or cherry-pick in progress" >&2
    return 1
  fi

  # check for merge markers in unstaged files for all operations
  local files_with_markers="$(git -C "$folder" diff --check 2>&1 | grep -i "conflict marker" | cut -d':' -f1 | sort -u)"
  
  if [[ -n "$files_with_markers" ]]; then
    print " fatal: unstaged files contain merge conflict markers" >&2
    print " ${gray_cor}files with markers:${reset_cor}" >&2
    echo "$files_with_markers" | while read -r file; do
      print "  • $file" >&2
    done
    return 1
  fi

  if ! git -C "$folder" add .; then return 1; fi

  if [[ "$operation" == "rebase" ]]; then
    HUSKY=0 GIT_EDITOR=true git -C "$folder" rebase --continue "$@" &>/dev/null
  elif [[ "$operation" == "merge" ]]; then
    HUSKY=0 GIT_EDITOR=true git -C "$folder" merge --continue "$@" &>/dev/null
  elif [[ "$operation" == "revert" ]]; then
    HUSKY=0 GIT_EDITOR=true git -C "$folder" revert --continue "$@" &>/dev/null
  elif [[ "$operation" == "cherry-pick" ]]; then
    HUSKY=0 GIT_EDITOR=true git -C "$folder" cherry-pick --continue "$@" &>/dev/null
  fi

  # git -C "$folder" commit --no-edit --no-verify
}

function fetch() {
  set +x
  eval "$(parse_flags_ "$0" "afpt" "qn" "$@")"
  (( fetch_is_debug )) && set -x

  if (( fetch_is_h )); then
    print "  ${hi_yellow_cor}fetch ${yellow_cor}[<branch>] [<folder>]${reset_cor} : fetch upstream changes"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --all"
    print "  ${hi_yellow_cor}  -f${reset_cor} : --force"
    print "  ${hi_yellow_cor}  -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor}  -t${reset_cor} : --tags"
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  local remote_name="$(get_remote_name_ "$folder")"

  if [[ -n "$branch" ]]; then
    branch="$(get_short_name_ "$branch" "" "$remote_name")"

    if ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi

    if [[ "$branch" == "$remote_name" ]]; then
      branch=""
    fi
  fi

  local flags=()
  
  if (( fetch_is_a )); then
    flags+=(--all)
  fi

  if (( fetch_is_t )); then
    flags+=(--tags)
    if (( fetch_is_p )); then
      flags+=(--prune-tags)
    fi
  else
    if (( fetch_is_p )); then
      flags+=(--prune)
    fi
  fi

  if (( fetch_is_f )); then
    flags+=(--force)
  fi

  if (( fetch_is_a )); then
    git -C "$folder" fetch "${flags[@]}" "$@"
    return $?;
  fi
  
  git -C "$folder" fetch $remote_name $branch "${flags[@]}" "$@"
}

function gconf() {
  set +x
  eval "$(parse_flags_ "$0" "aergls" "" "$@")"
  (( gconf_is_debug )) && set -x

  if (( gconf_is_h )); then
    print "  ${hi_yellow_cor}gconf ${yellow_cor}[<entry>] [<folder>]${reset_cor} : display git configuration"
    print "  ${hi_yellow_cor}  -a${reset_cor} : display all scopes (local, global, system)"
    print "  ${hi_yellow_cor}  -e${reset_cor} : display current effective configuration (mix of all)"
    print "  ${hi_yellow_cor}  -g${reset_cor} : global configuration"
    print "  ${hi_yellow_cor}  -l${reset_cor} : local configuration"
    print "  ${hi_yellow_cor}  -r <entry>${reset_cor} : remove an entry from the configuration"
    print "  ${hi_yellow_cor}  -s${reset_cor} : system configuration"
    return 0;
  fi

  local entry=""
  local folder=""

  eval "$(parse_args_ "$0" "entry:to,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  local scope_arg="local"

  if (( gconf_is_g )); then
    if (( gconf_is_e || gconf_is_a || gconf_is_s )); then
      print " fatal: cannot use -g with -e or -a or -s" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    scope_arg="global"
  fi

  if (( gconf_is_l )); then
    if (( gconf_is_e || gconf_is_a || gconf_is_s )); then
      print " fatal: cannot use -l with -e or -a or -s" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    scope_arg="local"
  fi

  # cannot use -r with -a or -e
  if (( gconf_is_r && gconf_is_e )); then
    print " fatal: cannot use -r with -e" >&2
    print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( gconf_is_s )); then
    if (( gconf_is_e || gconf_is_a || gconf_is_l )); then
      print " fatal: cannot use -s with -e or -a or -l" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    scope_arg="system"
  fi

  if (( gconf_is_r && ! gconf_is_a )); then
    if [[ -z "$entry" ]]; then
      print " fatal: entry argument is required for -r" >&2
      print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if ! git -C "$folder" config --${scope_arg} --unset-all "$entry" &>/dev/null; then
      if ! git -C "$folder" config --${scope_arg} --unset "$entry" &>/dev/null; then
        if ! git -C "$folder" config --${scope_arg} --remove-section "$entry" &>/dev/null; then
          local value="$(git -C "$folder" config --${scope_arg} --get "$entry" 2>/dev/null)"
          if [[ -n "$value" ]]; then
            print " ${hi_yellow_cor}== ${scope_arg} config ==${reset_cor}"
            print " fatal: unable to remove entry: $entry" >&2
            print " try a different scope" >&2
            print " run: ${hi_yellow_cor}gconf -h${reset_cor} to see usage" >&2
          else
            print " ${hi_yellow_cor}== ${scope_arg} config ==${reset_cor}"
            print " entry not found: ${yellow_cor}$entry${reset_cor}" >&2
          fi
          return 1;
        fi
      fi
    fi

    print " ${hi_yellow_cor}== ${scope_arg} config ==${reset_cor}"
    print " config key removed: ${orange_cor}$entry${reset_cor}"
    return 0;
  fi

  if (( gconf_is_a )); then
    if (( gconf_is_r )); then
      gconf -rs "$entry" "$folder"
      print ""
      gconf -rg "$entry" "$folder"
      print ""
      gconf -rl "$entry" "$folder"
    else
      gconf -s "$entry" "$folder"
      print ""
      gconf -g "$entry" "$folder"
      print ""
      gconf -l "$entry" "$folder"
    fi

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

  if [[ -z "$entry" ]]; then
    git -C "$folder" config --${scope_arg} --list 2>/dev/null | sort -f | while IFS='=' read -r key value; do
      printf "  ${cyan_cor}%-44s${reset_cor} = ${cyan_cor}%s${reset_cor}\n" "$key" "$value"
    done
  else
    local value="$(git -C "$folder" config --${scope_arg} --get "$entry" 2>/dev/null)"
    if [[ -z "$value" ]]; then
      print " entry not found: ${yellow_cor}$entry${reset_cor}" >&2
      return 1;
    fi

    print "  ${cyan_cor}$entry${reset_cor} = ${cyan_cor}$value${reset_cor}"
  fi
}

function glog() {
  set +x
  eval "$(parse_flags_ "$0" "abcrgtsR" "0123456789" "$@")"
  (( glog_is_debug )) && set -x

  if (( glog_is_h )); then
    print "  ${hi_yellow_cor}glog ${yellow_cor}[<format>] [<branch>] [<folder>]${reset_cor} : see log commits --pretty=<format>"
    print "  ${hi_yellow_cor}  -<number>${reset_cor} : limit log commits e.g.: glog -10"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --all"
    print "  ${hi_yellow_cor}  -b${reset_cor} : see log commits after head of base branch"
    print "  ${hi_yellow_cor}  -c ${yellow_cor}<branch>${reset_cor} : see log commits after head of a given branch"
    print "  ${hi_yellow_cor}  -g${reset_cor} : --graph"
    print "  ${hi_yellow_cor}  -r${reset_cor} : --reverse"
    print "  ${hi_yellow_cor}  -R${reset_cor} : --remotes"
    print "  ${hi_yellow_cor}  -s${reset_cor} : --stat"
    print "  ${hi_yellow_cor}  -t${reset_cor} : display comment details such as timestamp and author"
    return 0;
  fi

  local format=""
  local branch=""
  local folder=""

  if (( glog_is_b )); then
    eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  elif (( glog_is_c )); then
    eval "$(parse_args_ "$0" "branch:b,folder:fz" "$@")"
  else
    eval "$(parse_args_ "$0" "format:to,branch:bo,folder:fz" "$@")"
  fi

  shift $arg_count

  local flags=()

  if (( glog_is_a )); then
    flags+=(--all)
  fi

  if (( glog_is_g )); then
    flags+=(--graph)
  fi

  if (( glog_is_R )); then
    flags+=(--remotes)
  fi

  if (( glog_is_r )); then
    flags+=(--reverse)
  fi

  if (( glog_is_s )); then
    flags+=(--stat)
  fi

  if (( ! glog_is_t )) && [[ -z "$format" ]]; then
    flags+=(--oneline)
  fi

  if [[ -z "$format" ]]; then
    # format="%h %s"
    flags+=(--abbrev=7)
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( glog_is_b || glog_is_c )); then
    if (( glog_is_b && glog_is_c )); then
      print " fatal: cannot use -b and -c together" >&2
      print " run: ${hi_yellow_cor}glog -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local my_branch="$(get_my_branch_ -e "$folder")"
    local short_branch="$(get_short_name_ "$branch" "$folder")"
    
    if [[ -z "$branch" ]]; then
      branch="$(get_base_branch_ -l "$my_branch" "$folder")"
      if [[ -z "$branch" ]]; then
        print " run: ${hi_yellow_cor}glog -h${reset_cor} for other options" >&2
        return 1;
      fi
    fi

    if [[ "$short_branch" == "$my_branch" ]]; then
      print " fatal: branch argument cannot be the same as current branch: ${yellow_cor}$branch${reset_cor}" >&2
      return 1;
    fi

    print " showing commits of ${cyan_cor}$my_branch${reset_cor} after head of ${hi_cyan_cor}$branch${reset_cor}"
    print ""

    if [[ -n "$format" ]]; then
      git -C "$folder" --no-pager log $branch..$my_branch --no-merges --decorate --pretty="$format" "${flags[@]}" "$@"
    else
      git -C "$folder" --no-pager log $branch..$my_branch --no-merges --decorate "${flags[@]}" "$@"
    fi

    return $?;
  fi

  if [[ -n "$format" ]]; then
    git -C "$folder" --no-pager log $branch --decorate --pretty="$format" "${flags[@]}" "$@"
  else
    git -C "$folder" --no-pager log $branch --decorate "${flags[@]}" "$@"
  fi
}

function push() {
  set +x
  eval "$(parse_flags_ "$0" "tfnv" "q" "$@")"
  (( push_is_debug )) && set -x

  if [[ -z "$PUMP_PUSH_NO_VERIFY" ]]; then
    confirm_ "bypass the execution of git hooks on ${hi_yellow_cor}push${reset_cor} and ${hi_yellow_cor}pushf${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_NO_VERIFY" 1
      PUMP_PUSH_NO_VERIFY=1
    else
      update_setting_ "PUMP_PUSH_NO_VERIFY" 0
      PUMP_PUSH_NO_VERIFY=0
    fi
  fi

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( push_is_h )); then
    print "  ${hi_yellow_cor}push ${yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify --set-upstream"
    print "  ${hi_yellow_cor}  -f${reset_cor} : --force-with-lease"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${hi_yellow_cor}  -v${reset_cor} : --verify"
    else
      print "  ${hi_yellow_cor}  -nv${reset_cor} : --no-verify"
    fi
    print "  ${hi_yellow_cor}  -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"

    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$branch" ]]; then
    branch="$(get_short_name_ "$branch" "$folder")"

    if ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi  
  else
    branch="$(get_my_branch_ "$folder")"

    if [[ -z "$branch" ]]; then
      print " please provide a branch argument" >&2
      return 1;
    fi
  fi

  # check if my branch is already upstreamed
  # local upstream_branch="$(git -C "$folder" config --get "branch.${branch}.remote" 2>/dev/null)"
  
  local flags=()

  if (( push_is_f )); then
    flags+=(--force-with-lease)
  fi

  if (( push_is_t )); then
    flags+=(--tags)
  fi

  if (( push_is_n && push_is_v )) || (( PUMP_PUSH_NO_VERIFY && ! push_is_v )); then
    flags+=(--no-verify)
  fi

  local remote_name="$(get_remote_name_ "$folder")"

  git -C "$folder" push "$remote_name" "$branch" --set-upstream "${flags[@]}" "$@"
  local RET=$?

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || push_is_q )) && echo 1 || echo 0)"

  if (( RET != 0 && ! is_quiet )); then
    print ""
    if (( ! push_is_f )); then
      if confirm_ "push failed, try push --force-with-lease?"; then
        pushf "$branch" "$folder" "${flags[@]}" "$@"
        return $?;
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1 || true
    # no pbcopy
  fi

  return $RET;
}

function pushf() {
  set +x
  eval "$(parse_flags_ "$0" "tfnv" "q" "$@")"
  (( pushf_is_debug )) && set -x

  if [[ -z "$PUMP_PUSH_NO_VERIFY" ]]; then
    confirm_ "bypass the execution of git hooks on ${hi_yellow_cor}pushf${reset_cor} and ${hi_yellow_cor}push${reset_cor}?"
    local RET=$?
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      update_setting_ "PUMP_PUSH_NO_VERIFY" 1
      PUMP_PUSH_NO_VERIFY=1
    else
      update_setting_ "PUMP_PUSH_NO_VERIFY" 0
      PUMP_PUSH_NO_VERIFY=0
    fi
  fi

  local no_verify=""

  if (( PUMP_PUSH_NO_VERIFY )); then
    no_verify="--no-verify"
  fi

  if (( pushf_is_h )); then
    print "  ${hi_yellow_cor}pushf ${yellow_cor}[<branch>] [<folder>]${reset_cor} : push $no_verify --set-upstream --force-with-lease"
    print "  ${hi_yellow_cor}  -f${reset_cor} : --force"
    if (( PUMP_PUSH_NO_VERIFY )); then
      print "  ${hi_yellow_cor}  -v${reset_cor} : --verify"
    else
      print "  ${hi_yellow_cor}  -nv${reset_cor} : --no-verify"
    fi
    print "  ${hi_yellow_cor}  -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  
  # print ""
  # print "branch = [$branch]"
  # print "folder = [$folder]"
  # print "arg_count = [$arg_count]"
  # print "[$1]" "[$2]"
  # print "@ = [$@]"
  # return 1;

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if [[ -n "$branch" ]]; then
    branch="$(get_short_name_ "$branch" "$folder")"

    if ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi    
  else
    branch="$(get_my_branch_ "$folder")"

    if [[ -z "$branch" ]]; then
      print " please provide a branch argument" >&2
      return 1;
    fi
  fi

  local flags=()

  if (( pushf_is_f )); then
    flags+=(--force)
  else
    flags+=(--force-with-lease)
  fi

  if (( pushf_is_t )); then
    flags+=(--tags)
  fi

  if (( pushf_is_n && pushf_is_v )) || (( PUMP_PUSH_NO_VERIFY && ! pushf_is_v )); then
    flags+=(--no-verify)
  fi

  local remote_name="$(get_remote_name_ "$folder")"

  git -C "$folder" push "$remote_name" "$branch" --set-upstream "${flags[@]}" "$@"
  local RET=$?

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || pushf_is_q )) && echo 1 || echo 0)"

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1 || true
    # no pbcopy
  fi

  return $RET;
}

function repush() {
  set +x
  eval "$(parse_flags_ "$0" "cji" "tfnvq" "$@")"
  (( repush_is_debug )) && set -x

  if (( repush_is_h )); then
    print "  ${hi_yellow_cor}repush ${yellow_cor}[<message>] [<folder>]${reset_cor} : reset previous commit without losing your changes then re-push all changes"
    print "  ${hi_yellow_cor}  -c${reset_cor} : create message using conventional commits standard"
    print "  ${hi_yellow_cor}  -i${reset_cor} : only repush staged changes"
    print "  ${hi_yellow_cor}  -j${reset_cor} : create message using jira if available"
    print "  ${hi_yellow_cor}  -n${reset_cor} : prompt for a bigger commit message"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"

    return 0;
  fi

  local message=""
  local folder=""

  eval "$(parse_args_ "$0" "message:to,folder:fz" "$@")"
  shift $arg_count

  local flags=()

  if (( repush_is_i )); then
    flags+=(-i)
  fi
  if (( repush_is_j )); then
    flags+=(-j)
  fi
  if (( repush_is_c )); then
    flags+=(-c)
  fi
  if (( repush_is_n )); then
    flags+=(-n)
  fi
  if (( repush_is_q )); then
    flags+=(-q)
  fi

  if ! recommit -q "${flags[@]}" "$message" "$folder"; then return 1; fi

  pushf "$folder" "$@"
}

function pullr() {
  set +x
  eval "$(parse_flags_ "$0" "" "foptimq" "$@")"
  (( pullr_is_debug )) && set -x

  if (( pullr_is_h )); then
    print "  ${hi_yellow_cor}pullr ${yellow_cor}[<folder>]${reset_cor} : pull current branch with its configured upstream, using rebase"
    print "  ${hi_yellow_cor}pullr <branch> ${yellow_cor}[<folder>]${reset_cor} : pull from branch and merge using rebase, no guessing"
    print "  ${hi_yellow_cor}  -fo${reset_cor} : --ff-only"
    print "  ${hi_yellow_cor}  -m${reset_cor} : --rebase=merges"
    print "  ${hi_yellow_cor}  -i${reset_cor} : --rebase=interactive"
    print "  ${hi_yellow_cor}  -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor}  -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    return 0;
  fi

  pull -r "$@"
}

function pull() {
  set +x
  eval "$(parse_flags_ "$0" "trmfopqi" "xw" "$@")"
  (( pull_is_debug )) && set -x

  if (( pull_is_h )); then
    print "  ${hi_yellow_cor}pull ${yellow_cor}[<folder>]${reset_cor} : pull current branch and merge with its configured upstream"
    print "  ${hi_yellow_cor}pull [<origin/upstream>] <branch> ${yellow_cor}[<folder>]${reset_cor} : pull from branch, no guessing"
    print "  ${hi_yellow_cor} -ff${reset_cor} : --force"
    print "  ${hi_yellow_cor} -fo${reset_cor} : --ff-only"
    print "  ${hi_yellow_cor} -p${reset_cor} : --prune"
    print "  ${hi_yellow_cor} -rm${reset_cor} : --rebase=merges"
    print "  ${hi_yellow_cor} -ri${reset_cor} : --rebase=interactive"
    print "  ${hi_yellow_cor} -r${reset_cor} : --rebase"
    print "  ${hi_yellow_cor} -t${reset_cor} : --tags"
    print "  ${hi_yellow_cor} -q${reset_cor} : --quiet"
    return 0;
  fi

  local remote_name=""
  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "remote_name:ro,branch:bo,folder:fz" "$@")" # branch:bo so it stays undefined

  # print ""
  # print "remote_name = [$remote_name]"
  # print "branch = [$branch]"
  # print "folder = [$folder]"
  # print "arg_count = [$arg_count]"
  # print "[$1]" "[$2]" "[$3]" "[$4]" "[$5]" "[$6]"
  # return 1;

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local flags=()

  if (( pull_is_r )); then
    if (( pull_is_m )); then
      flags+=(--rebase=merges)
    elif (( pull_is_i )); then
      flags+=(--rebase=interactive)
    else
      flags+=(--rebase)
    fi
    flags+=(--strategy-option=patience)
  fi

  if (( pull_is_t )); then
    flags+=(--tags)
  fi

  if (( pull_is_f_f )); then
    flags+=(--force)
  fi

  if (( pull_is_f && pull_is_o )); then
    flags+=(--ff-only)
  fi

  if (( pull_is_p )); then
    flags+=(--prune)
  fi

  if (( pull_is_q )); then
    flags+=(--quiet)
  fi

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || pull_is_q )) && echo 1 || echo 0)"

  branch="$(get_short_name_ "$branch" "$folder")"

  if ! is_upstream_ "$folder" &>/dev/null; then
    if [[ -z "$branch" ]]; then
      branch="$(get_my_branch_ "$folder")"
    fi

    if [[ -z "$branch" ]]; then
      print " fatal: cannot pull, there is no current branch and no branch argument provided" >&2
      return 1;
    fi
    
    if [[ -z "$remote_name" ]]; then
      remote_name="$(get_remote_name_ "$folder")"
    fi

    if ! git -C "$folder" branch --set-upstream-to="${remote_name}/${branch}"; then
      return 1;
    fi
  fi

  if [[ -n "$branch" && -z "$remote_name" ]]; then
    remote_name="$(get_remote_name_ "$folder")"
  fi

  git -C "$folder" pull $remote_name $branch "${flags[@]}" "$@"
  local RET=$?

  if (( RET != 0 )); then
    if (( ! pull_is_r )); then
      if (( ! is_quiet )); then
        print ""
        confirm_ -a "pull failed, try ${hi_yellow_cor}pull --rebase${reset_cor}?"
        local _RET=$?

        if (( _RET == 130 || _RET == 2 )); then return 130; fi
        if (( _RET == 0 )); then
          pull -r "$@"
          return $?;
        fi
      fi

      return 1;
    fi

    if (( ! is_quiet )); then
      setup_git_merge_tool_
    fi

    local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

    if [[ -n "$files" ]]; then
      if (( ! is_quiet )) && [[ -n "$PUMP_MERGE_TOOL" ]]; then
        git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
        RET=$?
      fi
    fi
  fi

  if (( RET == 0 && ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1 || true
  fi

  return $RET;
}

function print_clean_() {
  local softer_color=$'\e[38;5;214m'
  local soft_color=$'\e[38;5;208m'
  local medium_color=$'\e[38;5;202m'
  local hard_color=$'\e[38;5;1m'
  local harder_color=$'\e[38;5;88m'

  print ""
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
  eval "$(parse_simple_flags_ "$0" "i" "q" "$@")"
  (( restore_is_debug )) && set -x

  if (( restore_is_h )); then
    print "  ${hi_yellow_cor}restore ${yellow_cor}[<glob>]${reset_cor} : discard unstaged changes in working tree"
    print "  ${hi_yellow_cor}  -i${reset_cor} : unstage staged changes, leaving working tree untouched"
    if (( ! restore_is_q )); then
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
    git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

    if ! git -C "$folder" rev-parse --verify HEAD >/dev/null 2>&1; then
      print " cannot discard changes in index, there is no commit yet"
      return 1;
    fi

    git -C "$folder" restore --staged -- "$@"
  else
    git -C "$folder" restore --worktree -- "$@"
  fi
}

function clean() {
  set +x
  eval "$(parse_simple_flags_ "$0" "" "q" "$@")"
  (( clean_is_debug )) && set -x

  if (( clean_is_h )); then
    print "  ${hi_yellow_cor}clean ${yellow_cor}[<folder>]${reset_cor} : delete untracked files and folders from working tree"
    if (( ! clean_is_q )); then
      print_clean_
    fi
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  git -C "$folder" clean -fd -- "$@"
}

function discard() {
  set +x
  eval "$(parse_simple_flags_ "$0" "q" "" "$@")"
  (( discard_is_debug )) && set -x

  if (( discard_is_h )); then
    print "  ${hi_yellow_cor}discard ${yellow_cor}[<glob>]${reset_cor} : unstage staged changes, leaving working tree untouched"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    if (( ! discard_is_q )); then
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

  git -C "$folder" reset HEAD -- "$@"
}

function reseta() {
  set +x
  eval "$(parse_flags_ "$0" "om" "q" "$@")"
  (( reseta_is_debug )) && set -x

  if (( reseta_is_h )); then
    print "  ${hi_yellow_cor}reseta ${yellow_cor}[<branch_or_commit>] [<folder>]${reset_cor} : erase every change and match HEAD to local branch/commit"
    print "  ${hi_yellow_cor}  -o${reset_cor} : erase every change and match HEAD to upstream"
    print "  ${hi_yellow_cor}  -m${reset_cor} : --mixed"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    if (( ! reseta_is_q )); then
      print_clean_
    fi
    return 0;
  fi

  local branch_or_commit=""
  local folder=""

  eval "$(parse_args_ "$0" "branch_or_commit:to,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi
  
  if [[ -n "$branch_or_commit" ]]; then
    # check if branch_or_commit is a commit hash
    if [[ $branch_or_commit =~ ^[0-9a-f]{7,40}$ ]]; then
      if ! git -C "$folder" cat-file -e "${branch_or_commit}^{commit}" &>/dev/null; then
        print " fatal: not a valid commit hash: $branch_or_commit" >&2
        return 1;
      else
        if (( reseta_is_o )); then
          print " fatal: cannot use -o with a commit hash: $branch_or_commit" >&2
          print " run: ${hi_yellow_cor}reseto -h${reset_cor} to see usage" >&2
          return 1;
        fi
      fi

      # it's a valid commit hash
      if (( reseta_is_m )); then
        git -C "$folder" reset --mixed "${branch_or_commit}" "$@"
      else
        git -C "$folder" reset --hard "${branch_or_commit}" "$@"
      fi
      return $?;
    fi
    
    branch_or_commit="$(get_short_name_ "$branch_or_commit" "$folder")"

    if ! normalize_branch_name_ "$branch_or_commit" 1>/dev/null; then
      return 1;
    fi
  else
    branch_or_commit="$(get_my_branch_ "$folder")"
    if [[ -z "$branch_or_commit" ]]; then return 1; fi
  fi

  if (( reseta_is_o )); then
    local remote_name="$(get_remote_name_ "$folder")"
    
    git -C "$folder" fetch --all --prune --quiet &>/dev/null || true
    if git -C "$folder" reset --hard "${remote_name}/${branch_or_commit}" "$@"; then
      git -C "$folder" clean -fd --quiet
    fi

  else
    if git -C "$folder" reset --hard "${branch_or_commit}" "$@"; then
      git -C "$folder" clean -fd --quiet
    fi
  fi
}

function reseto() {
  set +x
  eval "$(parse_flags_ "$0" "" "q" "$@")"
  (( reseto_is_debug )) && set -x

  if (( reseto_is_h )); then
    print "  ${hi_yellow_cor}reseto ${yellow_cor}[<branch>] [<folder>]${reset_cor} : erase every change and match HEAD to upstream"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    if (( ! reseto_is_q )); then
      print_clean_
    fi
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if [[ $branch =~ ^[0-9a-f]{7,40}$ ]]; then
    print " fatal: invalid branch name: $branch" >&2
    print " run: ${hi_yellow_cor}reseto -h${reset_cor} to see usage" >&2
    return 1;
  fi

  reseta -o "$branch" "$folder" "$@"
}

function glr() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( glr_is_debug )) && set -x

  if (( glr_is_h )); then
    print "  ${hi_yellow_cor}glr ${yellow_cor}[<branch>] [<folder>]${reset_cor} : list upstream branches matching branch"
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder" &>/dev/null; then
    local proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    local i="$(find_proj_index_ -x "$proj_cmd" 2>/dev/null)"

    local proj_folder="${PUMP_FOLDER[$i]}"
  
    folder="$(find_git_folder_ "$proj_folder" 2>/dev/null)"
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
    gum spin --title="loading..." -- git -C "$folder" branch -r --list "*$branch*" --sort=authordate \
      --format='%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=3)' \
      | grep -v 'HEAD' \
      | sed \
      -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
      -e "s/\([^\ ]*\)$/\x1b[34m\x1b]8;;${link//\//\\/}\1\x1b\\\\\1\x1b]8;;\x1b\\\\\x1b[0m/"
  else
    git -C "$folder" branch -r --list "*$branch*" --sort=authordate \
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
    print "  ${hi_yellow_cor}gll ${yellow_cor}[<branch>] [<folder>]${reset_cor} : display local branches matching branch"
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" branch --list "*$branch*" --sort=authordate \
    --format="%(authordate:format:%m-%d-%Y) %(align:22,left)%(authorname)%(end) %(refname:strip=2)" \
    | sed \
    -e 's/\([0-9]*-[0-9]*-[0-9]*\)/\x1b[32m\1\x1b[0m/' \
    -e 's/\([^ ]*\)$/\x1b[34m\1\x1b[0m/'
}

function workflow_run_() {
  set +x
  eval "$(parse_flags_ "$0" "b" "" "$@")"
  (( workflow_run_is_debug )) && set -x

  local proj_repo=""
  local workflow=""
  local arg=""
  local cor=""

  eval "$(parse_args_ "workflow_run_" "proj_repo:t,workflow:t,arg:t,cor:to" "$@")"
  shift $arg_count

  if [[ -z "$cor" ]]; then
    cor="${GHA_COLOR_MAP[${arg:u}]}"
    
    if [[ -z "$cor" ]]; then
      cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
    fi
  fi

  local repo_name="$(get_repo_name_ "$proj_repo" 2>/dev/null)"

  local run_id="" url="" title="" tag="" updated_at="" w_status=""

  local result="$(gum spin --title="checking workflow status... $workflow" -- gh run list --repo "$proj_repo" \
    --workflow="$workflow" --limit 99 \
    --json databaseId,url,displayTitle,headBranch,updatedAt,conclusion \
    --jq "[.[] | select(.displayTitle | contains(\"$arg\"))] | .[0] | \"\(.databaseId)${TAB}\(.url)${TAB}\(.displayTitle)${TAB}\(.headBranch)${TAB}\(.updatedAt)${TAB}\(.conclusion // empty)\""
  )"

  local error=""

  if [[ -z "$result" ]]; then
    if (( workflow_run_is_b )); then
      return 0;
    fi

    error=" could not find any workflows named: $workflow"

    if [[ -n "$arg" ]]; then
      result="$(gum spin --title="checking workflow status... $workflow" -- gh run list --repo "$proj_repo" \
        --workflow="$workflow" --limit 1 \
        --json databaseId,url,displayTitle,headBranch,updatedAt,conclusion \
        --jq ".[0] | \"\(.databaseId)${TAB}\(.url)${TAB}\(.displayTitle)${TAB}\(.headBranch)${TAB}\(.updatedAt)${TAB}\(.conclusion // empty)\""
      )"
      
      if [[ -z "$result" ]]; then
        error+=" with any title"
      else
        error+=$'\n'" with title \"$arg\""
      fi
    fi

    error+=" in: $repo_name"

    gum style --border=rounded --padding="0 1" --margin="0 1" --width="60" --align=left "$error" --border-foreground "$(ansi_to_gum ${hi_gray_cor})" >&2

    if [[ -n "$result" ]]; then
      return 2;
    fi
    
    return 1;
  fi
  IFS=$TAB read -r run_id url title tag updated_at w_status <<< "$result"
  
  local author=""
  # Get triggering actor from workflow run details
  if [[ -n "$run_id" ]]; then
    author="$(gum spin --title="getting run author..." -- gh api repos/$repo_name/actions/runs/$run_id --jq '.actor.login // "unknown"')"
  fi

  local link=$'\e]8;;'"$url"$'\a'"$title"$'\e]8;;\a'
  local stat_cor=""
  local stat=""

  if [[ -z "$w_status" ]]; then
    stat_cor="${bold_yellow_cor}"
    stat="• running"
  elif [[ "$w_status" == "success" ]]; then
    stat_cor="${bold_green_cor}"
    stat="✓ passed"
  else
    stat_cor="${bold_red_cor}"
    stat="✗ failed"
  fi

  # local tag_url="$(gum spin --title="getting tag url..." -- gh release view $tag --repo "$proj_repo" --json url -q .url)"
  local tag_branch="$(gum spin --title="getting tag branch..." -- gh api repos/$repo_name/releases/tags/${tag} --jq '.target_commitish')"
  local pkg_version="$(get_pkg_field_online_ "version" "$tag" "$proj_repo" 2>/dev/null)"

  local formatted_updated_at=""
  if formatted_updated_at="$(date -u -d "$updated_at" "+%m/%d/%Y %H:%M" 2>/dev/null)"; then
    updated_at="$formatted_updated_at"
  elif formatted_updated_at="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" "+%m/%d/%Y %H:%M" 2>/dev/null)"; then
    updated_at="$formatted_updated_at"
  fi

  local box_content=""

  box_content+="${gray_cor}titled: ${cor}$link${reset_cor} @ ${cor}$pkg_version${reset_cor} : ${stat_cor}$stat${reset_cor}"$'\n'
  box_content+="${gray_cor}tagged:${reset_cor} $tag"$'\n'
  box_content+="${gray_cor}branch:${reset_cor} $tag_branch"$'\n'
  box_content+="${gray_cor}posted:${reset_cor} $author @ $updated_at"

  if (( workflow_run_is_b )); then
    echo "$tag_branch"
    return 0;
  fi

  print -r -- "- *$arg* is \`$pkg_version\`"

  gum style --border=rounded --padding="0 1" --margin="0 1" --width="60" --align=left "$box_content" --border-foreground "$(ansi_to_gum ${cor})" >&2
}

function workflow_runs_() {
  local proj_repo="$1"
  local workflow="$2"

  shift 2

  if [[ -z "$@" ]]; then
    local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
    workflow_run_ "$proj_repo" "$workflow" "" "$cor"
    return $?;
  fi

  if [[ -z "$GHA_COLOR_MAP" ]]; then
    local arg=""
    for arg in "$@"; do
      if [[ -z "$arg" ]]; then continue; fi

      local cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"

      if [[ $'\n'"${(F)${(@v)GHA_COLOR_MAP}}"$'\n' == *$'\n'"$cor"$'\n'* ]]; then
        cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
        if [[ $'\n'"${(F)${(@v)GHA_COLOR_MAP}}"$'\n' == *$'\n'"$cor"$'\n'* ]]; then
          cor="${colors[$(( (RANDOM % ${#colors[@]}) + 1 ))]}"
        fi
      fi

      GHA_COLOR_MAP[${arg:u}]="$cor"
    done
  fi

  local arg=""
  for arg in "$@"; do
    if [[ -z "$arg" ]]; then continue; fi

    workflow_run_ "$proj_repo" "$workflow" "$arg"
    local _RET=$?

    if (( _RET == 1 )); then
      return 1;
    fi
  done
}

function proj_gha_() {
  set +x
  eval "$(parse_flags_ "$0" "adfw" "" "$@")"
  (( proj_gha_is_debug )) && set -x

  local proj_cmd="$1"

  if (( proj_gha_is_h )); then
    proj_print_help_ "$proj_cmd gha"
    return 0;
  fi

  local workflow=""
  local interval=""
  local search

  shift 1

  if (( proj_gha_is_d && proj_gha_is_a )); then
    eval "$(parse_args_ "$proj_cmd gha" "interval:nz,search:a:to" "$@")"

  elif (( proj_gha_is_d )); then
    eval "$(parse_args_ "$proj_cmd gha" "search:a:to" "$@")"

  elif (( proj_gha_is_a )); then
    eval "$(parse_args_ "$proj_cmd gha" "workflow:to,interval:nz,search:a:to" "$@")"

  else
    eval "$(parse_args_ "$proj_cmd gha" "workflow:to,search:a:to" "$@")"
  fi

  shift $arg_count

  local i="$(get_proj_index_ "$proj_cmd")"

  if ! check_gum_; then return 1; fi
  if ! check_proj_ -r $i; then return 1; fi
  if ! check_gh_; then return 1; fi

  local proj_repo="${PUMP_REPO[$i]}"

  if (( proj_gha_is_d )); then
    workflow="${PUMP_GHA_DEPLOY[$i]}"
  else
    if (( proj_gha_is_w )); then
      print " fatal: cannot specify -w without -d" >&2
      return 1;
    fi
  fi
  
  local workflow_choices=""

  if [[ -z "$workflow" ]]; then
    workflow_choices="$(gum spin --title="loading workflows..." -- gh workflow list --repo "$proj_repo" | cut -f1 | sort -u)"
    
    if [[ -z "$workflow_choices" || "$workflow_choices" == "No workflows found" ]]; then
      print " no workflows found in $proj_cmd"
      return 0;
    fi

    local label="workflow"
    if (( proj_gha_is_d )); then
      label="deployment workflow"
    fi

    workflow="$(choose_one_ "$label" "${(@f)workflow_choices}")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$workflow" ]]; then return 1; fi

    if (( proj_gha_is_d )); then
      local is_save=1
      if (( ! proj_gha_is_f )); then
        is_save=0
        confirm_ "save \"$workflow\" as the default deployment workflow for ${proj_cmd}?"
        local _RET=$?
  
        if (( _RET == 130 )); then return 130; fi
        if (( _RET == 0 )); then
          is_save=1
        fi
      fi

      if (( is_save )); then
        update_config_ $i "PUMP_GHA_DEPLOY" "$workflow"
      fi
    fi
  fi

  if (( proj_gha_is_w )); then
    echo "$workflow"
    return 0;
  fi

  while true; do
    if ! workflow_runs_ "$proj_repo" "$workflow" "${search[@]}"; then
      if (( proj_gha_is_d )) && [[ -n "$workflow" ]]; then
        PUMP_GHA_DEPLOY[$i]=""
        proj_gha_ -fd "$proj_cmd" "$interval" "${search[@]}"
        return $?;
      else
        return 1;
      fi
    fi

    if (( ! proj_gha_is_a )); then break; fi

    print ""
    print "sleeping for $interval minutes..."
    sleep $(( 60 * interval ))
  done
}

function co() {
  set +x
  eval "$(parse_flags_ "$0" "bcelpruax" "q" "$@")"
  (( co_is_debug )) && set -x

  if (( co_is_h )); then
    print "  ${hi_yellow_cor}co ${yellow_cor}[<branch>] [<folder>]${reset_cor} : switch branch"
    print "  ${hi_yellow_cor}  -a ${reset_cor} : switch to remote branch"
    print "  ${hi_yellow_cor}  -l ${reset_cor} : switch to local branch"
    print "  ${hi_yellow_cor}  -u ${reset_cor} : --set-upstream-to (set up tracking information)"
    print "  --"
    print "  ${hi_yellow_cor}co <branch> ${yellow_cor}[<folder>]${reset_cor} : switch to a branch"
    print "  ${hi_yellow_cor}  -b ${reset_cor} : create new branch off of another branch"
    print "  ${hi_yellow_cor}  -c ${reset_cor} : create new branch off of current branch"
    print "  ${hi_yellow_cor}  -e ${reset_cor} : switch to exact branch, no lookup"
    print "  --"
    print "  ${hi_yellow_cor}co -pr ${yellow_cor}[<pr>] [<folder>]${reset_cor} : switch to pull request (detached branch)"
    print "  --"
    print "  ${hi_yellow_cor}co <branch> <base_branch> ${yellow_cor}[<folder>]${reset_cor} : create new branch off of base branch"
    return 0;
  fi

  local branch=""
  local base_branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,base_branch:bo,folder:fz" "$@")"

  # print ""
  # print "branch = [$branch]"
  # print "base_branch = [$base_branch]"
  # print "folder = [$folder]"
  # print "arg_count = [$arg_count]"
  # print "[$1]" "[$2]" "[$3]" "[$4]" "[$5]" "[$6]"
  # return 1;

  shift $arg_count

  if ! is_folder_git_ "$folder"; then; return 1; fi

  if [[ -n "$branch" ]]; then
    branch="$(get_short_name_ "$branch" "$folder")"
    
    if [[ "$branch" == "co" ]] || ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi
  fi

  if [[ -n "$base_branch" ]]; then
    base_branch="$(get_short_name_ "$base_branch" "$folder")"

    if [[ "$base_branch" == "co" ]] || ! normalize_branch_name_ "$base_branch" 1>/dev/null; then
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi
  fi

  # co -pr by pull request
  if (( co_is_p && co_is_r )); then
    if [[ -n "$base_branch" ]]; then
      print " fatal: co -pr does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local proj_repo="$(get_repo_ "$folder")"
    if [[ -z "$proj_repo" ]]; then return 1; fi

    local pr_number="" pr_branch="" pr_title=""
    local output=""
    output="$(select_pr_ -odg "$branch" "$proj_repo" "pull request to detach")"
    if (( $? == 130 )); then return 130; fi
    if (( $? == 0 )); then
      IFS=$TAB read -r pr_number pr_title pr_url pr_branch _ <<< "$output"
    fi
    
    if [[ -z "$pr_number" ]]; then return 1; fi

    local RET=0

    if command -v gum &>/dev/null; then
      gum spin --title="detaching pull request: ${cyan_cor}$pr_title${reset_cor}" -- gh pr checkout --force --detach $pr_number
      RET=$?
      if (( RET == 0 )); then
        print " detached pull request: ${cyan_cor}$pr_title${reset_cor}"
      fi
    else
      print " detaching pull request: ${cyan_cor}$pr_title${reset_cor}"
      gh pr checkout --force --detach $pr_number &>/dev/null
      RET=$?
    fi

    if (( RET == 0 )); then
      print " HEAD is now at $(git -C "$folder" log -1 --pretty=%h) $(truncate_ $(git -C "$folder" log -1 --pretty=%s) 60)"
      print " run:"
      if [[ -n "$folder" ]]; then
        print "  • ${hi_yellow_cor}co -e \"$folder\" $pr_branch${reset_cor} (alias for \"git switch\")"
        print "  • ${hi_yellow_cor}co -c \"$folder\" ${${USER:0:1}:l}-${pr_branch}${reset_cor} (alias for \"git switch -c\")"
      else
        print "  • ${hi_yellow_cor}co -e $pr_branch${reset_cor} (alias for \"git switch\")"
        print "  • ${hi_yellow_cor}co -c ${${USER:0:1}:l}-${pr_branch}${reset_cor} (alias for \"git switch -c\")"
      fi
    fi

    return $RET;
  fi

  if (( co_is_p || co_is_r )); then
    if (( co_is_p )); then
      print " ${red_cor}fatal: invalid option: -p${reset_cor}" >&2
    else
      print " ${red_cor}fatal: invalid option: -r${reset_cor}" >&2
    fi
    print "  --"
    co -h
    return 1;
  fi

  # co -u set upstream branch
  if (( co_is_u )); then
    if [[ -n "$base_branch" ]]; then
      print " fatal: co -u does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    if [[ -z "$branch" ]]; then
      branch="$(get_my_branch_ "$folder")"
      if [[ -z "$branch" ]]; then return 1; fi
    fi

    local remote_name="$(get_remote_name_ "$folder")"

    git -C "$folder" branch --set-upstream-to="${remote_name}/${branch}" "$@"

    return $?;
  fi

    # co -a list all branches
  if (( co_is_a )); then
    if [[ -n "$base_branch" ]]; then
      print " fatal: co -a does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local branch_choice=""

    if [[ -n "$branch" ]]; then
      branch_choice="$(select_branch_ -aic "$branch" "to switch" "$folder")"
    else
      local my_branch="$(get_my_branch_ -l "$folder" 2>/dev/null)"
      local my_branch_short="$(get_my_branch_ "$folder" 2>/dev/null)"

      branch_choice="$(select_branch_ -ac "" "to switch" "$folder" "$my_branch" "$my_branch_short")"
    fi
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$branch_choice" ]]; then
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    co -e "$branch_choice" "$folder" "$@"

    return $?;
  fi

  # co -l list local branches only
  if (( co_is_l )); then
    if [[ -n "$base_branch" ]]; then
      print " fatal: co -l does not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage"
      return 1;
    fi

    local branch_choice=""

    if [[ -n "$branch" ]]; then
      branch_choice="$(select_branch_ -lic "$branch" "to switch" "$folder")"
    else
      local my_branch="$(get_my_branch_ -l "$folder" 2>/dev/null)"
      local my_branch_short="$(get_my_branch_ "$folder" 2>/dev/null)"
  
      branch_choice="$(select_branch_ -lc "" "to switch" "$folder" "$my_branch" "$my_branch_short")"
    fi
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$branch_choice" ]]; then
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    co -e "$branch_choice" "$folder" "$@"

    return $?;
  fi

  # co -c or co -b branch base_branch
  if (( co_is_b || co_is_c )); then
    if [[ -z "$branch" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if [[ -n "$base_branch" ]]; then
      print " fatal: co -b and co -c do not accept a second argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

    if [[ "$branch" == "$my_branch" ]]; then
      print " fatal: branch already exists: $my_branch" >&2
      return 1;
    fi

    if (( co_is_b )); then
      local base_branch="$(determine_target_branch_ -dbe "$branch" "$folder")"
      if [[ -z "$base_branch" ]]; then return 1; fi
    else
      base_branch="$my_branch"
    fi

    co -xe "$branch" "$base_branch" "$folder" "$@"

    return $?;
  fi

  # co -x branch BASE_BRANCH (creating branch)
  if (( co_is_x )); then
    if [[ -z "$branch" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    if (( ! co_is_e )); then
      base_branch="$(select_branch_ -acix "$base_branch" "base branch" "$folder")"
      if (( $? == 130 )); then return 130; fi
      if [[ -z "$base_branch" ]]; then
        print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
        return 1;
      fi
    fi

    local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

    if [[ -z "$base_branch" ]]; then
      base_branch="$my_branch"
    fi
    
    if [[ "$base_branch" != "$my_branch" ]]; then
      if get_branch_status_ "$folder" 1>/dev/null; then
        return 1;
      fi
    fi

    if [[ -n "$base_branch" ]]; then
      if ! switch_branch_ "$base_branch" "$folder" --quiet &>/dev/null; then
        print " fatal: could not switch to base branch: $base_branch" >&2
        return 1;
      fi
    fi

    if ! switch_branch_ -c "$branch" "$folder" "$@"; then
      return 1;
    fi

    if [[ -n "$base_branch" ]]; then
      git -C "$folder" config branch.$branch.pump-merge $base_branch
      print " created branch ${hi_cyan_cor}${branch}${reset_cor} off of ${cyan_cor}${base_branch}${reset_cor}"
    else
      print " created branch ${hi_cyan_cor}${branch}${reset_cor} off of HEAD${reset_cor}"
    fi

    return 0;
  fi

  # co -e switch to exact branch
  if (( co_is_e )); then
    if [[ -z "$branch" ]]; then
      print " fatal: missing branch or commit argument" >&2
      print " run: ${hi_yellow_cor}co -h${reset_cor} to see usage" >&2
      return 1;
    fi

    # if ! git -C "$folder" switch "$branch" "$@"; then
    #   if is_branch_status_clean_ "$folder" && confirm_ "create new branch: ${pink_cor}${branch}${reset_cor}?"; then
    #     co -c "$branch" "$folder" "$@"
    #     return $?;
    #   fi

    #   return 1;
    # fi

    switch_branch_ "$branch" "$folder" "$@"

    return $?;
  fi

  # co branch BASE_BRANCH (no arguments) (creating branch)
  if [[ -n "$base_branch" ]]; then
    co -x "$branch" "$base_branch" "$folder" "$@"
    return $?;
  fi

  # co branch or co (no arguments)
  local branch_choice=""

  # if branch arg was given, list all branches
  # if no branch arg was given, list local branches
  if [[ -n "$branch" ]]; then
    branch_choice="$(select_branch_ -aic "$branch" "to switch" "$folder")"
  else
    local my_branch="$(get_my_branch_ -l "$folder" 2>/dev/null)"
    local my_branch_short="$(get_my_branch_ "$folder" 2>/dev/null)"

    branch_choice="$(select_branch_ -lc "" "to switch" "$folder" "$my_branch" "$my_branch_short" 2>/dev/null)"
    if (( $?  == 130 )); then return 130; fi
    if [[ -z "$branch_choice" ]]; then
      branch_choice="$(select_branch_ -ac "" "to switch" "$folder" "$my_branch" "$my_branch_short")"
    fi
  fi
  if (( $? == 130 )); then return 130; fi

  if [[ -n "$branch_choice" ]]; then
    co -e "$branch_choice" "$folder" "$@"
    return $?;
  fi

  if [[ -n "$branch" ]]; then
    if confirm_ "create new branch: ${pink_cor}$branch${reset_cor}?"; then
      co -c "$branch" "$folder" "$@"
      return $?;
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if git -C "$folder" switch -; then
    fetch "$folder" --quiet
    return $?;
  fi
}

function develop() {
  dev "$@"
}

function switch_branch_() {
  set +x
  eval "$(parse_flags_ "$0" "c" "" "$@")"
  (( switch_branch_is_debug )) && set -x

  local branch="$1"
  local folder="$2"

  shift 2

  local c_flag=""

  if (( switch_branch_is_c )); then
    c_flag="-c"
  fi

  if git -C "$folder" switch $c_flag "$branch" "$@"; then
    git -C "$folder" fetch --quiet &>/dev/null

    get_pump_jira_title_ "$(extract_jira_key_ "$branch")" "$folder" &>/dev/null

    return 0;
  fi

  return 1;
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{dev,develop,devel,development}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      switch_branch_ "${ref:t}" "$folder"
      return $?;
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local my_branch="$(get_my_branch_ "$folder")"
  if [[ -z "$my_branch" ]]; then return 1; fi

  local base_branch="$(get_base_branch_ "$my_branch" "$folder")"
  if [[ -z "$base_branch" ]]; then return 1; fi

  switch_branch_ "$base_branch" "$folder"
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local main_branch="$(get_main_branch_ "$folder")"
  if [[ -z "$main_branch" ]]; then return 1; fi

  switch_branch_ "$main_branch" "$folder"
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true

  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{prod,production,product}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      switch_branch_ "${ref:t}" "$folder"
      return $?;
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

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  git -C "$folder" fetch --all --prune --quiet &>/dev/null || true
  
  local remote_name="$(get_remote_name_ "$folder")"

  local ref=""
  for ref in refs/{remotes/${remote_name},heads}/{stage,staging}; do
    if git -C "$folder" show-ref --verify --quiet "$ref"; then
      switch_branch_ "${ref:t}" "$folder"
      return $?;
    fi
  done

  print " fatal: did not match any branch known to git: stage or staging" >&2
  return 1;
}

function rebase() {
  set +x
  eval "$(parse_flags_ "$0" "cwfi" "ampXotq" "$@")"
  (( rebase_is_debug )) && set -x

  if (( rebase_is_h )); then
    print "  ${hi_yellow_cor}rebase ${yellow_cor}[<base_branch>] [<strategy>] [<folder>]${reset_cor} : apply the commits from your branch on top of base branch with strategy"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}  -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation (base branch must be defined)"
    print "  ${hi_yellow_cor}  -i${reset_cor} : --interactive"
    print "  ${hi_yellow_cor}  -m${reset_cor} : --merge"
    print "  ${hi_yellow_cor}  -p${reset_cor} : push if rebase succeeds, abort if conflicts"
    print "  ${hi_yellow_cor}  -Xo${reset_cor} : auto solve conflicts using 'ours' strategy"
    print "  ${hi_yellow_cor}  -Xt${reset_cor} : auto solve conflicts using 'theirs' strategy"
    print "  ${hi_yellow_cor}  -w${reset_cor} : multiple branches"
    return 0;
  fi

  local base_branch=""
  local folder=""

  if (( rebase_is_f )); then
    eval "$(parse_args_ "$0" "base_branch:b,folder:fz" "$@")"
  else
    eval "$(parse_args_ "$0" "base_branch:bo,folder:fz" "$@")"
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( rebase_is_X && rebase_is_o && rebase_is_t )); then
    print " fatal: cannot use both -Xo and -Xt options together" >&2
    print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! rebase_is_p )) && (( rebase_is_a || ${argv[(Ie)--abort]} )); then
    abort "$folder"
    return $?;
  fi

  if (( ! rebase_is_p )) && (( rebase_is_c || ${argv[(Ie)--continue]} )); then
    conti "$folder"
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

  if [[ -n "$base_branch" ]]; then
    if (( rebase_is_d || rebase_is_c )); then
      print " fatal: base branch cannot be defined with option" >&2
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local found_base_branch="$(select_branch_ -ai "$base_branch" "base branch" "$folder")"

    if [[ -z "$found_base_branch" ]]; then
      return 1;
    fi

    base_branch="$found_base_branch"

  else

    base_branch="$(get_base_branch_ -l "$my_branch" "$folder")"
    if [[ -z "$base_branch" ]]; then
      print " run: ${hi_yellow_cor}rebase -h${reset_cor} to see usage" >&2
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
        rebase "$base_branch" "$strategy" "$folder" "$@"
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

  # rebase always ask for confirmation even if [[ -z "$base_branch" ]] unless -f is given
  if (( ! rebase_is_f )); then
    confirm_ "$msg" "rebase" "abort"
    local _RET=$?
    if (( _RET == 130 || _RET == 2 )); then return 130; fi
    if (( _RET == 1 )); then return 1; fi
  fi

  print " $msg"

  local is_stashed=0

  # check if working tree is not empty
  if ! is_branch_status_clean_ "$folder"; then
    # stash all changes (including untracked files)
    if ! confirm_ "your working tree has changes, stash them before merging?" "stash" "abort"; then
      return 1;
    fi

    if ! git -C "$folder" stash push --include-untracked --message "auto stash before rebase" &>/dev/null; then
      print " fatal: failed to stash changes before rebasing" >&2
      return 1;
    fi

    is_stashed=1
  else
    # pull latest changes from remote
    git -C "$folder" pull --quiet &>/dev/null || true
  fi

  local flags=()

  if (( rebase_is_i )); then
    flags+=(--interactive)
  fi
  if (( rebase_is_m )); then
    flags+=(--merge)
  fi
  if (( rebase_is_q )); then
    flags+=(--quiet)
  fi
  if [[ -n "$strategy" ]]; then
    flags+=(--strategy-option=$strategy)
  fi
  if (( rebase_is_X && rebase_is_o )); then
    flags+=(--strategy-option=patience)
    flags+=(--strategy-option=ours)
  fi
  if (( rebase_is_X && rebase_is_t )); then
    flags+=(--strategy-option=patience)
    flags+=(--strategy-option=theirs)
  fi

  setup_git_merge_tool_

  if ! git -C "$folder" rebase $base_branch "${flags[@]}"; then
    RET=1
    local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

    if [[ -n "$files" && -n "$PUMP_MERGE_TOOL" ]]; then
      git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
      RET=$?
    fi
  fi

  if (( RET != 0 )); then
    if (( rebase_is_a )); then
      abort "$folder"
    fi
  else
    if [[ "$my_branch" != "HEAD" ]]; then
      git -C "$folder" config branch.$my_branch.pump-merge $base_branch
    fi

    if (( is_stashed )); then
      # restore stashed changes
      if git -C "$folder" stash pop &>/dev/null; then
        print " restored stashed changes"
      else
        print " warning: failed to restore stashed changes" >&2
        print " run: ${hi_yellow_cor}git stash pop${reset_cor}" >&2
      fi
    fi

    if (( rebase_is_p && ! rebase_is_X )); then
      if [[ "$my_branch" == "HEAD" ]]; then
        print " warning: rebase done but cannot push branch because it's detached" >&2
        print " run: ${hi_yellow_cor}pushf${reset_cor} to push manually" >&2
        return 0;
      fi
      pushf "$my_branch" "$folder"
      RET=$?
    fi
  fi

  return $RET;
}

function merge() {
  set +x
  eval "$(parse_flags_ "$0" "cwf" "apXotq" "$@")"
  (( merge_is_debug )) && set -x

  if (( merge_is_h )); then
    print "  ${hi_yellow_cor}merge ${yellow_cor}[<base_branch>] [<strategy>] [<folder>]${reset_cor} : merge from base branch with strategy"
    print "  ${hi_yellow_cor}  -a${reset_cor} : --abort (on conflicts)"
    print "  ${hi_yellow_cor}  -c${reset_cor} : --continue (on conflicts)"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation (base branch must be defined)"
    print "  ${hi_yellow_cor}  -p${reset_cor} : push if merge succeeds, abort if conflicts"
    print "  ${hi_yellow_cor}  -Xo${reset_cor} : auto solve conflicts using 'ours' strategy"
    print "  ${hi_yellow_cor}  -Xt${reset_cor} : auto solve conflicts using 'theirs' strategy"
    print "  ${hi_yellow_cor}  -w${reset_cor} : multiple branches"
    return 0;
  fi

  local base_branch=""
  local strategy=""
  local folder=""

  if (( merge_is_f )); then
    eval "$(parse_args_ "$0" "base_branch:b,strategy:to,folder:fz" "$@")"
  else
    eval "$(parse_args_ "$0" "base_branch:bo,strategy:to,folder:fz" "$@")"
  fi

  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( merge_is_X && merge_is_o && merge_is_t )); then
    print " fatal: cannot use both -Xo and -Xt options together" >&2
    print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( ! merge_is_p )) && (( merge_is_a || ${argv[(Ie)--abort]} )); then
    abort "$folder"
    return $?;
  fi

  if (( ! merge_is_p )) && (( merge_is_c || ${argv[(Ie)--continue]} )); then
    conti "$folder"
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

  if [[ -n "$base_branch" ]]; then
    if (( merge_is_d || merge_is_c )); then
      print " fatal: base branch cannot be defined with option" >&2
      print " run: ${hi_yellow_cor}merge -h${reset_cor} to see usage" >&2
      return 1;
    fi

    local found_base_branch="$(select_branch_ -ai "$base_branch" "base branch" "$folder")"

    if [[ -z "$found_base_branch" ]]; then
      return 1;
    fi

    base_branch="$found_base_branch"

  else

    base_branch="$(get_base_branch_ -l "$my_branch" "$folder")"
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
        merge "$base_branch" "$strategy" "$folder" "$@"
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
  if (( ! merge_is_f )) && [[ -z "$base_branch" ]]; then
    confirm_ "$msg" "merge" "abort"
    local _RET=$?
    if (( _RET == 130 || _RET == 2 )); then return 130; fi
    if (( _RET == 1 )); then return 1; fi
  fi

  print " $msg"

  local is_stashed=0

  # check if working tree is not empty
  if ! is_branch_status_clean_ "$folder"; then
    # stash all changes (including untracked files)
    confirm_ "your working tree has changes, stash them before merging?" "stash" "continue"
    local _RET=$?

    if (( _RET == 130 )); then return 130; fi
    if (( _RET == 0 )); then
      if ! git -C "$folder" stash push --include-untracked --message "auto stash before merge" &>/dev/null; then
        print " fatal: failed to stash changes before merging" >&2
        return 1;
      fi
      is_stashed=1
    fi
  else
    # pull latest changes from remote
    git -C "$folder" pull --quiet &>/dev/null || true
  fi

  local flags=()

  if (( merge_is_q )); then
    flags+=(--quiet)
  fi
  if [[ -n "$strategy" ]]; then
    flags+=(--strategy-option=$strategy)
  fi
  if (( merge_is_X && merge_is_o )); then
    flags+=(--strategy-option=patience)
    flags+=(--strategy-option=ours)
  fi
  if (( merge_is_X && merge_is_t )); then
    flags+=(--strategy-option=patience)
    flags+=(--strategy-option=theirs)
  fi

  setup_git_merge_tool_

  if ! git -C "$folder" merge $base_branch --no-edit --ff-only "${flags[@]}" 2>/dev/null; then
    RET=1
    if ! git -C "$folder" merge $base_branch --no-edit "${flags[@]}"; then
      RET=1
      local files="$(git -C "$folder" diff --name-only --diff-filter=U 2>/dev/null)"

      if [[ -n "$files" ]]; then
        git -C "$folder" mergetool --tool=$PUMP_MERGE_TOOL "$files"
        RET=$?
      fi
    else
      RET=0
    fi
  fi

  if (( RET != 0 )); then
    if (( merge_is_a )); then
      abort "$folder"
    fi
  else
    if [[ "$my_branch" != "HEAD" ]]; then
      git -C "$folder" config branch.$my_branch.pump-merge $base_branch
    fi

    if (( is_stashed )); then
      # restore stashed changes
      if git -C "$folder" stash pop &>/dev/null; then
        print " restored stashed changes"
      else
        print " warning: failed to restore stashed changes" >&2
        print " run: ${hi_yellow_cor}git stash pop${reset_cor}" >&2
      fi
    fi

    if (( merge_is_p && ! merge_is_X )); then
      if [[ "$my_branch" == "HEAD" ]]; then
        print " warning: rebase done but cannot push branch because it's detached" >&2
        print " run: ${hi_yellow_cor}push${reset_cor} to push manually or ${hi_yellow_cor}co -e <branch>${reset_cor} to create a branch before pushing" >&2
        return 0;
      fi
      push "$my_branch" "$folder"
      RET=$?
    fi
  fi

  return $RET;
}

function setup_git_merge_tool_() {
  if [[ -z "$PUMP_MERGE_TOOL" ]]; then
    PUMP_MERGE_TOOL="$(input_command_ "type the command of your merge tool" "${PUMP_CODE_EDITOR:-code}")"
    
    if [[ -n "$PUMP_MERGE_TOOL" ]]; then
      PUMP_MERGE_TOOL="$(which $PUMP_MERGE_TOOL 2>/dev/null || echo "$PUMP_MERGE_TOOL")"
      update_setting_ -f "PUMP_MERGE_TOOL" "$PUMP_MERGE_TOOL"
    fi
  fi

  if [[ -n "$PUMP_MERGE_TOOL" ]]; then
    if command -v $PUMP_MERGE_TOOL &>/dev/null; then
      # git config --global diff.tool $PUMP_MERGE_TOOL
      # git config --global diff.guitool $PUMP_MERGE_TOOL
      # git config --global diff.$PUMP_MERGE_TOOL.cmd "$PUMP_MERGE_TOOL --new-window --wait --diff \"\$LOCAL\" \"\$REMOTE\""
      
      # git config --global merge.tool $PUMP_MERGE_TOOL
      # git config --global merge.guitool $PUMP_MERGE_TOOL

      git config --global mergetool.$PUMP_MERGE_TOOL.cmd "$PUMP_MERGE_TOOL --new-window --wait --merge \"\$LOCAL\" \"\$REMOTE\" \"\$BASE\" \"\$MERGED\""
      git config --global mergetool.prompt false
      git config --global mergetool.keepBackup false
    fi
  fi
}

function prune() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( prune_is_debug )) && set -x

  if (( prune_is_h )); then
    print "  ${hi_yellow_cor}prune ${yellow_cor}[<folder>]${reset_cor} : clean up unreachable or orphaned git branches and tags"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

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

  git -C "$folder" prune --progress "$@"
}

function delb() {
  set +x
  eval "$(parse_simple_flags_ "$0" "fedra" "x" "$@")"
  (( delb_is_debug )) && set -x

  if (( delb_is_h )); then
    print "  ${hi_yellow_cor}delb ${yellow_cor}[<branch>] [<folder>]${reset_cor} : delete local branches only"
    print "  ${hi_yellow_cor}  -a${reset_cor} : find and delete local and remote branches"
    print "  ${hi_yellow_cor}  -d${reset_cor} : --dry-run"
    print "  ${hi_yellow_cor}  -e <branch> ${yellow_cor}[<folder>]${reset_cor} : delete exact branch, no lookup"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation (cannot be used with -r or -a)"
    print "  ${hi_yellow_cor}  -r${reset_cor} : find and delete remote branches"
    return 0;
  fi

  local branch=""
  local folder=""

  eval "$(parse_args_ "$0" "branch:bo,folder:fz" "$@")"
  shift $arg_count

  if (( delb_is_r )) && ! is_folder_git_ "$folder" &>/dev/null; then
    local proj_cmd="$CURRENT_PUMP_SHORT_NAME"
    local i="$(find_proj_index_ -x "$proj_cmd" 2>/dev/null)"

    local proj_folder="${PUMP_FOLDER[$i]}"
  
    folder="$(find_git_folder_ "$proj_folder" 2>/dev/null)"
  fi

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( delb_is_e || delb_is_f )); then
    if [[ -z "$branch" ]]; then
      print " fatal: branch argument is required" >&2
      print " run: ${hi_yellow_cor}delb -h${reset_cor} to see usage" >&2
      return 1;
    fi
    if ! normalize_branch_name_ "$branch" 1>/dev/null; then
      return 1;
    fi
  fi

  if [[ -n "$branch" ]]; then
    if (( ! delb_is_a )) && is_remote_branch_name_ "$branch" "$folder"; then
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

  local flags=()
  local excluded_branches=()

  if (( delb_is_a )); then
    flags+=(-a)
    if (( delb_is_e || delb_is_x )); then
      flags+=(-ix)
    fi
  elif (( delb_is_r )); then
    flags+=(-r)
    if (( delb_is_e || delb_is_x )); then
      flags+=(-ix)
    fi
  else
    flags+=(-l)
    if (( delb_is_e || delb_is_x )); then
      flags+=(-ix)
    fi
  fi

  selected_branches=($(select_branches_ "${flags[@]}" "$branch" "to delete" "$folder"))

  if [[ -z "$selected_branches" ]]; then
    if [[ -n "$branch" ]]; then
      print " run: ${hi_yellow_cor}delb -h${reset_cor} for more options" >&2
    fi
    return 1;
  fi

  local RET=0
  local count=0
  local dont_ask=0

  branch=""
  for branch in "${selected_branches[@]}"; do
    if (( ! delb_is_f && ! delb_is_r && ! delb_is_x )); then
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
    if is_remote_branch_name_ "$branch" "$folder"; then
      local short_branch="$(get_short_name_ "$branch" "$folder")"

      if (( delb_is_d )); then
        print "git -C '$folder' branch --unset-upstream $short_branch"
        print "git -C '$folder' push --no-verify --delete $remote_name $short_branch"
      else
        git -C "$folder" branch --unset-upstream $short_branch &>/dev/null || true
        git -C "$folder" push --no-verify --delete $remote_name $short_branch
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
    print "  ${hi_yellow_cor}  -sb${reset_cor} : display git status in short-format"
    return 0;
  fi

  local folder=""

  eval "$(parse_args_ "$0" "folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  # -sb is equivalent to git status -sb
  git -C "$folder" status "$@"
}

function get_pkg_name_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_pkg_name_is_debug )) && set -x

  local folder="${1:-$PWD}"
  local repo="$2"
  local single_mode="${3:-0}"

  if ! is_folder_pkg_ "$folder" &>/dev/null; then
    if (( single_mode )); then
      return 1;
    fi

    folder="$(find_pkg_folder_ "$folder" 2>/dev/null)"

    if [[ -z "$folder" ]]; then return 1; fi
  fi

  if [[ -n "$folder" ]]; then
    local pkg_name="$(get_from_package_json_ "name" "$folder" 2>/dev/null)"

    if [[ -z "$pkg_name" && -n "$repo" ]]; then
      pkg_name="$(get_pkg_field_online_ "name" "" "$repo" "$folder" 2>/dev/null)"
    fi
  fi
  
  if [[ -z "$pkg_name" ]]; then
    pkg_name="$(basename -- "$folder")"
  fi

  pkg_name="$(trim_ $pkg_name)"

  echo "$pkg_name"
}

function detect_node_version_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( detect_node_version_is_debug )) && set -x

  local i="$1"
  local node_v_arg="$2"
  local folder="${3:-$PWD}"

  folder="$(find_pkg_folder_ -r "$folder" 2>/dev/null)"
  # if ! is_folder_pkg_ "$folder" &>/dev/null; then return 1; fi
  if [[ -z "$folder" ]]; then return 1; fi

  if ! command -v nvm &>/dev/null; then return 1; fi
  if ! command -v node &>/dev/null; then
    if ! nvm use node &>/dev/null; then return 1; fi
  fi

  local nvm_use_v=""
  local label="create a ${hi_yellow_cor}.nvmrc${reset_cor} file"

  local current_node_v="$(node --version 2>/dev/null)"
  local current_node_v_acceptable="${current_node_v#v}"
  
  if [[ -z "$current_node_v_acceptable" ]]; then; return 1; fi

  current_node_v_acceptable="${"${current_node_v#v}"%%.*}"
  if (( PUMP_NODE_REQ_SAME_MINOR )); then current_node_v_acceptable="${"${current_node_v#v}"%.*}"; fi

  local nvm_version="$(trim_ $(cat "${folder}/.nvmrc" 2>/dev/null))"
  local nvm_version_acceptable="${nvm_version#v}"

  if [[ "$nvm_version_acceptable" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    nvm_version_acceptable="${"${nvm_version#v}"%%.*}"
    if (( PUMP_NODE_REQ_SAME_MINOR )); then nvm_version_acceptable="${"${nvm_version#v}"%.*}"; fi

    if [[ "$current_node_v_acceptable" == "$nvm_version_acceptable" ]]; then
      echo "$current_node_v"
      return 0;
    fi

    nvm_use_v="$(nvm version $nvm_version_acceptable 2>/dev/null)"

    if [[ "$nvm_use_v" == "N/A" ]]; then
      print " ${yellow_cor}warning: node version in your ${hi_yellow_cor}.nvmrc${reset_cor} file not found: ${bold_yellow_cor}$nvm_version${reset_cor}" >&2
      print " run: ${hi_yellow_cor}nvm install ${nvm_version_acceptable}${reset_cor}" >&2

      nvm_use_v=""
      label="edit ${hi_yellow_cor}.nvmrc${reset_cor} file"
    fi

    if [[ -n "$nvm_use_v" ]]; then
      echo "$nvm_use_v"
      return 0;
    fi
  fi

  if (( i == 0 && PUMP_SKIP_DETECT_NODE )); then
    echo "$current_node_v"
    return 1;
  fi

  local node_engine="$(get_from_package_json_ "engines.node" "$folder" 2>/dev/null)"

  if [[ -z "$node_engine" ]]; then
    echo "$current_node_v"
    return 1;
  fi

  local output="$(get_node_versions_ "$node_engine" "$folder" 2>/dev/null)"
  local versions=("${(@f)output}")

  if [[ -z "$versions" ]]; then
    if [[ -n "$node_engine" ]]; then
      print " ${yellow_cor}warning: no matching node version in nvm for engine: ${bold_yellow_cor}$node_engine${reset_cor}" >&2
      if [[ -n "$nvm_version_acceptable" ]]; then
        print " run: ${hi_yellow_cor}nvm install ${nvm_version_acceptable}${reset_cor}" >&2
      elif [[ "$node_engine" =~ ([0-9]+)(\.)*$ ]]; then
        print -n -- " run: ${hi_yellow_cor}nvm install ${match[1]}${reset_cor}" >&2
        if [[ "$node_engine" =~ ([0-9]+)(\.[0-9a-z]+)*$ ]]; then
          print -n -- " or ${hi_yellow_cor}${match[1]}${reset_cor} or something in between" >&2
        fi
        print "" >&2
      else
        print " run: ${hi_yellow_cor}nvm install node${reset_cor}" >&2
      fi
    fi

  elif [[ -n "$node_v_arg" ]]; then
    local node_v_arg_acceptable="${${node_v_arg#v}%%.*}"
    if (( PUMP_NODE_REQ_SAME_MINOR )); then node_v_arg_acceptable="${"${node_v_arg#v}"%.*}"; fi

    local version=""
    for version in "${versions[@]}"; do
      local version_acceptable="${${version#v}%%.*}"
      if (( PUMP_NODE_REQ_SAME_MINOR )); then version_acceptable="${"${version#v}"%.*}"; fi

      if [[ "$node_v_arg_acceptable" == "$version_acceptable" ]]; then
        nvm_use_v="$version"
        break;
      fi
    done

    if [[ -z "$nvm_use_v" ]]; then
      nvm_use_v="${versions[-1]}"
    fi

  else
    nvm_use_v="$(choose_one_ -i "node version to use with ${hi_cyan_cor}engine $node_engine${reset_cor}${new_line}current node is ${hi_yellow_cor}$current_node_v${reset_cor}" "${versions[@]}")"
    if (( $? == 130 )); then return 130; fi
  fi

  if (( i == 0 )) && [[ -n "$nvm_use_v" && "$nvm_use_v" != "$nvm_version" ]]; then
    if [[ -n "$nvm_version" ]]; then
      print "node version in .nvmrc ${hi_yellow_cor}$nvm_version${reset_cor} file does not match your current node version: ${yellow_cor}$current_node_v${reset_cor}" >&2
    fi
    confirm_ "$label to define ${bold_yellow_cor}$nvm_use_v${reset_cor} as the node version?"
    local _RET=$?

    if (( _RET == 130 || _RET == 2 )); then return 130; fi
    if (( _RET == 0 )); then
      echo "$current_node_v" > "$folder/.nvmrc"
    else
      print " run: ${hi_yellow_cor}pro -a${reset_cor} to add this project" >&2
    fi
  fi

  if [[ -n "$nvm_use_v" ]]; then
    echo "$nvm_use_v"
    return 0;
  fi

  echo "$current_node_v"
  return 2;
}

function nvm_use_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  # (( nvm_use_is_debug )) && set -x

  local i="$1"
  local new_nvm_use_v="$2"
  local pkg_manager="$3"

  if [[ -z "$new_nvm_use_v" ]]; then return 1; fi

  if ! command -v nvm &>/dev/null; then return 1; fi
  if ! command -v node &>/dev/null; then
    if ! nvm use node &>/dev/null; then return 1; fi
  fi

  local current_node_v="$(node --version 2>/dev/null)"
  local current_node_v_acceptable="${current_node_v#v}"

  if [[ -z "$current_node_v_acceptable" ]]; then; return 1; fi
  
  local new_nvm_use_v_acceptable="${new_nvm_use_v#v}"

  if [[ "$new_nvm_use_v_acceptable" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    new_nvm_use_v_acceptable="${${new_nvm_use_v#v}%%.*}"
    if (( PUMP_NODE_REQ_SAME_MINOR )); then new_nvm_use_v_acceptable="${"${new_nvm_use_v#v}"%.*}"; fi
    
    current_node_v_acceptable="${${current_node_v#v}%%.*}"
    if (( PUMP_NODE_REQ_SAME_MINOR )); then current_node_v_acceptable="${"${current_node_v#v}"%.*}"; fi
  fi

  # if (( ! nvm_use_is_f )) && [[ "$current_node_v_acceptable" == "$new_nvm_use_v_acceptable" ]]; then
  #   return 0;
  # fi

  if ! nvm use "$new_nvm_use_v_acceptable" &>/dev/null; then
    return 1;
  fi

  current_node_v="$(node -v 2>/dev/null)"

  local pkg_v=""

  if [[ -n "$pkg_manager" ]]; then
    pkg_v="$($pkg_manager -v 2>/dev/null)"
    if [[ -z "$pkg_v" ]]; then pkg_v="not installed"; fi
    print -- " now using node ${cyan_cor}$current_node_v${reset_cor} ($pkg_manager ${hi_magenta_cor}${pkg_v}${reset_cor})" 2>/dev/tty
  else
    print -- " now using node ${cyan_cor}$current_node_v${reset_cor}" 2>/dev/tty
  fi

  if (( i )); then
    update_config_ $i "PUMP_NVM_USE_V" "$new_nvm_use_v"
    PUMP_NVM_USE_V[$i]="$new_nvm_use_v"
  fi
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

    local key=""
    for key in "${branches[@]}"; do
      if [[ -n "$(extract_jira_key_ "$key")" ]]; then
        echo "$key"
      fi
    done
  else
    # get all folders within the project's folder and store to a list
    get_folders_ $i "$folder" "$search_key" "${@:5}" 2>/dev/null
  fi
}

# pro -n [<version>] set the node version for a project, if version is not provided, it will try to detect the version from the project's package.json engines field or .nvmrc file
function pro_n_() {
  set +x
  eval "$(parse_flags_ "$0" "r" "" "$@")"
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

  local new_nvm_use_v=""

  if [[ -n "$2" && $2 != -* ]]; then
    new_nvm_use_v="$2"

    if nvm_use_ $i "$new_nvm_use_v" "$pkg_manager"; then
      return 0;
    fi
  fi

  if ! check_proj_ -fm $i; then return 1; fi
  
  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local pkg_manager="${PUMP_PKG_MANAGER[$i]}"
  local nvm_use_v="${PUMP_NVM_USE_V[$i]}"

  if [[ -n "$nvm_use_v" ]] && (( ! pro_n_is_r )); then
    if nvm_use_ $i "$nvm_use_v" "$pkg_manager"; then
      return 0;
    fi
  fi

  new_nvm_use_v="$(detect_node_version_ $i "$nvm_use_v" "$PWD")"
  local RET=$?
  
  if (( RET == 0 )); then
    nvm_use_ $i "$new_nvm_use_v" "$pkg_manager"
    return $?
  fi

  nvm_use_ 0 "$new_nvm_use_v" "$pkg_manager"

  # if (( RET == 2 )); then
  #   if [[ -z "$PUMP_SKIP_DETECT_NODE" ]]; then
  #     confirm_ "do you want to skip auto detecting node versions for every project?" "skip" "continue" "continue"
  #     local _RET=$?
  #
  #     if (( _RET == 0 )); then
  #       update_setting_ "PUMP_SKIP_DETECT_NODE" "1"
  #     elif (( _RET == 1 )); then
  #       update_setting_ "PUMP_SKIP_DETECT_NODE" "0"
  #     fi
  #   fi
  # fi
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

  remove_proj_folders_ "$proj_cmd" "$proj_folder"

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
      local output=""
      output="$(get_jira_status_ "$key")"

      if (( $? != 0 )) || [[ -z "$output" ]]; then
        if ! check_jira_cli_; then return 1; fi
        continue;
      fi
      IFS=$TAB read -r jira_status _ <<< "$output"

      if [[ -z "$jira_status" ]] then continue; fi

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

# pro -i
function pro_i_() {
  set +x
  eval "$(parse_flags_ "$0" "H" "" "$@")"
  (( pro_i_is_debug )) && set -x

  local proj_arg="$1"

  local i=0

  if (( pro_i_is_H )); then
    i="$(find_proj_index_ -oe "$proj_arg" "project to view info")"
    (( i )) || return 1;
  fi

  if [[ -z "$proj_arg" ]]; then
    for i in {1..9}; do
      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        pro -iH "${PUMP_SHORT_NAME[$i]}"
      fi
    done
  fi

  if [[ -n "${PUMP_FOLDER[$i]}" && -n "${PUMP_SHORT_NAME[$i]}" ]]; then
    local new_mode=""

    if [[ -n "${PUMP_SINGLE_MODE[$i]}" ]]; then
      new_mode="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "single" || echo "multiple" )"
    fi

    local mode_cor="$( (( ${PUMP_SINGLE_MODE[$i]} )) && echo "$purple_cor" || echo "$pink_cor" )"

    local name_v="$(truncate_ "${PUMP_SHORT_NAME[$i]}" 70)"
    local folder_v="$(truncate_ "${PUMP_FOLDER[$i]}" 70)"
    local manager_v="$(truncate_ "${PUMP_PKG_MANAGER[$i]}" 70)"
    local node_v="$(truncate_ "${PUMP_NVM_USE_V[$i]}" 70)"
    local repo_v="$(truncate_ "${PUMP_REPO[$i]}" 70)"

    local box_content=""
    box_content+="${blue_cor}${name_v}${reset_cor}"$'\n'
    box_content+="${hi_gray_cor}${folder_v}${reset_cor}"$'\n'
    box_content+="${mode_cor}${new_mode}${reset_cor}"$'\n'
    box_content+="${hi_cyan_cor}node ${node_v}${reset_cor} (${hi_magenta_cor}${manager_v}${reset_cor})"$'\n'
    box_content+="${hi_gray_cor}${repo_v}${reset_cor}"

    if command -v gum &>/dev/null; then
      gum style --border=rounded --padding="0 1" --margin="0 1" --width="75" --align=left "$box_content" --border-foreground 33
    else
      print -r -- "$box_content"
    fi
  fi
}

# pro -u
function pro_u_() {
  set +x
  eval "$(parse_flags_ "$0" "H" "" "$@")"
  (( pro_u_is_debug )) && set -x

  local proj_arg="$1"

  local i=0

  if (( pro_u_is_H )); then
    i="$(find_proj_index_ -oe "$proj_arg" "project to reset settings")"
    (( i )) || return 1;

    proj_arg="${PUMP_SHORT_NAME[$i]}"
  fi

  local all_global_settings=(
    "PUMP_SKIP_DETECT_NODE    =$(truncate_ "${PUMP_SKIP_DETECT_NODE}" 70)"
    "PUMP_CODE_EDITOR         =$(truncate_ "${PUMP_CODE_EDITOR}" 70)"
    "PUMP_INTERVAL            =$(truncate_ "${PUMP_INTERVAL}" 70)"
    "PUMP_JIRA_ALERT          =$(truncate_ "${PUMP_JIRA_ALERT}" 70)"
    "PUMP_MERGE_TOOL          =$(truncate_ "${PUMP_MERGE_TOOL}" 70)"
    "PUMP_NODE_REQ_SAME_MINOR =$(truncate_ "${PUMP_NODE_REQ_SAME_MINOR}" 70)"
    "PUMP_PUSH_NO_VERIFY      =$(truncate_ "${PUMP_PUSH_NO_VERIFY}" 70)"
    "PUMP_RUN_OPEN_COV        =$(truncate_ "${PUMP_RUN_OPEN_COV}" 70)"
    "PUMP_USE_MONOGRAM        =$(truncate_ "${PUMP_USE_MONOGRAM}" 70)"
  )

  local all_project_settings=(
    "PUMP_COMMIT_SIGNOFF      =$(truncate_ "${PUMP_COMMIT_SIGNOFF[$i]}" 70)"
    "PUMP_GHA_DEPLOY          =$(truncate_ "${PUMP_GHA_DEPLOY[$i]}" 70)"
    "PUMP_GO_BACK             =$(truncate_ "${PUMP_GO_BACK[$i]}" 70)"
    "PUMP_JIRA_ALMOST_DONE    =$(truncate_ "${PUMP_JIRA_ALMOST_DONE[$i]}" 70)"
    "PUMP_JIRA_API_TOKEN      =$(truncate_ "${PUMP_JIRA_API_TOKEN[$i]}" 70)"
    "PUMP_JIRA_BLOCKED        =$(truncate_ "${PUMP_JIRA_BLOCKED[$i]}" 70)"
    "PUMP_JIRA_CANCELED       =$(truncate_ "${PUMP_JIRA_CANCELED[$i]}" 70)"
    "PUMP_JIRA_DONE           =$(truncate_ "${PUMP_JIRA_DONE[$i]}" 70)"
    "PUMP_JIRA_IN_PROGRESS    =$(truncate_ "${PUMP_JIRA_IN_PROGRESS[$i]}" 70)"
    "PUMP_JIRA_IN_REVIEW      =$(truncate_ "${PUMP_JIRA_IN_REVIEW[$i]}" 70)"
    "PUMP_JIRA_IN_TEST        =$(truncate_ "${PUMP_JIRA_IN_TEST[$i]}" 70)"
    "PUMP_JIRA_READY_FOR_TEST =$(truncate_ "${PUMP_JIRA_READY_FOR_TEST[$i]}" 70)"
    "PUMP_JIRA_PROJECT        =$(truncate_ "${PUMP_JIRA_PROJECT[$i]}" 70)"
    "PUMP_JIRA_STATUSES       =$(truncate_ "${PUMP_JIRA_STATUSES[$i]}" 70)"
    "PUMP_JIRA_TODO           =$(truncate_ "${PUMP_JIRA_TODO[$i]}" 70)"
    "PUMP_JIRA_WORK_TYPES     =$(truncate_ "${PUMP_JIRA_WORK_TYPES[$i]}" 70)"
    "PUMP_NVM_USE_V           =$(truncate_ "${PUMP_NVM_USE_V[$i]}" 70)"
    "PUMP_PR_APPEND           =$(truncate_ "${PUMP_PR_APPEND[$i]}" 70)"
    "PUMP_PR_APPROVAL_MIN     =$(truncate_ "${PUMP_PR_APPROVAL_MIN[$i]}" 70)"
    "PUMP_PR_REPLACE          =$(truncate_ "${PUMP_PR_REPLACE[$i]}" 70)"
    "PUMP_SCRIPT_FOLDER       =$(truncate_ "${PUMP_SCRIPT_FOLDER[$i]}" 70)"
    "PUMP_SETUP               =$(truncate_ "${PUMP_SETUP[$i]}" 70)"
    "PUMP_VERSION_WEB         =$(truncate_ "${PUMP_VERSION_WEB[$i]}" 70)"
    "PUMP_VERSION_CMD         =$(truncate_ "${PUMP_VERSION_CMD[$i]}" 70)"
  )

  local global_settings=()
  local setting=""
  for setting in "${all_global_settings[@]}"; do
    local value="$(trim_ ${setting#*=})"
    if [[ -n "$value" ]]; then
      global_settings+=("$setting")
    fi
  done

  local project_settings=()
  local project_setting=""
  for project_setting in "${all_project_settings[@]}"; do
    local value="$(trim_ ${project_setting#*=})"
    if [[ -n "$value" ]]; then
      project_settings+=("$project_setting")
    fi
  done

  local selected_settings=""
  if (( i )); then
    if [[ -z "$project_settings" ]]; then
      print " all settings are reset for project: ${blue_cor}${proj_arg}${reset_cor}"
      return 0;
    fi

    selected_settings="$(choose_multiple_ "$proj_arg settings to reset" "${project_settings[@]}")"
  else
    if [[ -z "$global_settings" ]]; then
      print " all global settings are reset"
      return 0;
    fi
    selected_settings="$(choose_multiple_ "global settings to reset" "${global_settings[@]}")"
  fi

  if (( $? == 130 )); then return 130; fi

  if [[ -z "$selected_settings" ]]; then
    print " no setting chosen to reset" >&2
    return 1;
  fi

  local selected_setting=""
  for selected_setting in "${(@f)selected_settings}"; do
    local sett="$(trim_ $(echo "$selected_setting" | cut -d= -f1))"

    if (( i )); then
      update_config_ $i "$sett" ""
    else
      update_setting_ "$sett" ""
    fi
  done
}

# pro -r
function pro_r_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( pro_r_is_debug )) && set -x

  local proj_args=()

  local arg=""
  for arg in "$@"; do
    if [[ -n "$arg" && $arg != -* ]]; then
      proj_args+=("$arg")
    fi
  done

  if [[ -z "$proj_args" ]]; then
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
    
    proj_args=($(choose_multiple_ "projects to remove" "${projects[@]}"))
    if (( $? == 130 )); then return 130; fi
  fi

  if [[ -z "$proj_args" ]]; then return 1; fi

  local is_refresh=0;

  for arg in "${proj_args[@]}"; do
    local i="$(find_proj_index_ "$arg" "project to remove")"
    (( i )) || continue;

    if [[ "$arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
      is_refresh=1;
    fi

    confirm_ "remove project: ${blue_cor}$arg${reset_cor}?"
    local _RET=$?
    if (( _RET == 130 || _RET == 2 )); then return 130; fi
    if (( _RET == 1 )); then continue; fi 

    remove_proj_folders_ "${PUMP_SHORT_NAME[$i]}" "${PUMP_FOLDER[$i]}"

    if ! remove_proj_ -u $i; then
      print " failed to remove: ${arg}" >&2
      print " run: ${hi_yellow_cor}$help_command${reset_cor} to see usage" >&2
      return 1;
    fi

    print " ${magenta_cor}removed project${reset_cor} $arg"
  done

  if (( is_refresh )); then
    refresh
  fi
}

function pro() {
  set +x
  eval "$(parse_flags_ "$0" "aerulndisc" "xH" "$@")"
  (( pro_is_debug )) && set -x

  if (( pro_is_h )); then
    print "  ${hi_yellow_cor}pro -c ${yellow_cor}[<name>]${reset_cor} : remove old project folders"
    print "  ${hi_yellow_cor}pro -a ${yellow_cor}[<name>]${reset_cor} : add new project"
    print "  ${hi_yellow_cor}pro -e ${yellow_cor}[<name>]${reset_cor} : edit project"
    print "  ${hi_yellow_cor}pro -r ${yellow_cor}[<name...>]${reset_cor} : remove projects"
    print "  ${hi_yellow_cor}pro -n ${yellow_cor}[<name>] [<version>]${reset_cor} : reset project node version"
    print "  --"
    print "  ${hi_yellow_cor}pro -u ${reset_cor}: reset global settings"
    print "  ${hi_yellow_cor}pro -i ${reset_cor}: display main config settings for all projects"
    print "  ${hi_yellow_cor}pro -l ${reset_cor}: list all projects"
    return 0;
  fi

  local proj_arg="$1"

  local qty_args=0
  local arg=""
  for arg in "$@"; do
    if [[ -n "$arg" && "$arg" != -* ]]; then
      (( qty_args++ ))
    fi
  done

  local max_arg=0

  if (( pro_is_r )); then
    for i in {1..9}; do
      if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
        (( max_arg++ ))
      fi
    done
  else
    if (( pro_is_l || pro_is_i || pro_is_u )) && (( ! pro_is_H )); then
      max_arg=0
    elif (( pro_is_n )); then
      max_arg=2
    elif [[ -z "$proj_arg" ]]; then
      max_arg=0
    else
      max_arg=1
    fi
  fi

  local help_command="pro -h"
  if (( pro_is_H )); then
    help_command="$1 -h"
  fi

  if (( qty_args > max_arg )); then
    print " fatal: too many arguments" >&2
    
    print " run: ${hi_yellow_cor}$help_command${reset_cor} to see usage" >&2
    return 1;
  fi

  # pro -a <name> add project
  if (( pro_is_a )); then
    if [[ -n "$proj_arg" ]]; then
      save_proj_ -a "" "$proj_arg"
    else
      save_proj_ -a
    fi

    return $?;
  fi

  # pro -c [<name>] clean project
  if (( pro_is_c )); then
    pro_c_ "$proj_arg"
    
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

  # pro -i [<name>] display project's settings
  if (( pro_is_i )); then
    pro_i_ "$@"

    return $?;
  fi

  # pro -l list projects
  if (( pro_is_l )); then
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

  # pro -n <version> set node version for a project
  if (( pro_is_n )); then
    pro_n_ -r "$@"

    return $?;
  fi

  # pro -r <name> remove projects
  if (( pro_is_r )); then
    pro_r_ "$@"

    return $?;
  fi

  # pro -u reset project settings
  # pro -ug reset global settings
  if (( pro_is_u )); then
    pro_u_ "$@"

    return $?;
  fi

  if (( ! pro_is_x )); then
    pro -h
    return 1;
  fi  

  # pro -x <name> - setting a project with a name will set the project if it exists, otherwise it will show an error
  local i="$(find_proj_index_ -x "$proj_arg" 2>/dev/null)"
  if (( ! i )); then
    pro -h
    return 1;
  fi

  proj_arg="${PUMP_SHORT_NAME[$i]}"

  # load the project config settings
  load_config_ $i

  git fetch --all --prune --quiet &>/dev/null || true

  if [[ "$proj_arg" == "$CURRENT_PUMP_SHORT_NAME" ]]; then
    if [[ "$PWD/" != "$OLDPWD/"* && "$OLDPWD/" != "$PWD/"* && "$PWD/" == "$CURRENT_PUMP_FOLDER/"* ]]; then
      local jira_key="$(read_pump_value_ "JIRA_KEY")"
      local jira_title="$(get_pump_jira_title_ "$jira_key")"

      if [[ -n "$jira_key" && -n "$jira_title" ]]; then
        print " ${pink_cor}${jira_key}${reset_cor} ${purple_cor}${jira_title}${reset_cor}" 1>/dev/tty
      fi

      if git rev-parse HEAD &>/dev/null; then
        print -n " " 1>/dev/tty
        git --no-pager log --oneline --decorate -1 2>/dev/null 1>/dev/tty || true
      fi
    fi

    return 0;
  fi

  # change project

  set_current_proj_ $i

  if [[ -t 0 && -o login ]]; then
    print -n -- " project set to: ${blue_cor}${CURRENT_PUMP_SHORT_NAME}${reset_cor}" 1>/dev/tty
    if [[ -n "$CURRENT_PUMP_PKG_MANAGER" ]]; then
      print -n -- " with ${hi_magenta_cor}${CURRENT_PUMP_PKG_MANAGER}${reset_cor}" 1>/dev/tty
    fi
    print "" 1>/dev/tty
  fi

  # # cd into folder if PWD is not already within it
  # if [[ "${PWD:A}/" != "${CURRENT_PUMP_FOLDER:A}/"* ]]; then
  #   cd "$CURRENT_PUMP_FOLDER"
  # fi

  if [[ -t 0 && -o login ]]; then
    pro_n_ "$proj_arg" 1>/dev/tty
  fi

  if [[ "$PWD/" == "$CURRENT_PUMP_FOLDER/"* ]]; then
    local jira_key="$(read_pump_value_ "JIRA_KEY")"
    local jira_title="$(get_pump_jira_title_ "$jira_key")"

    if [[ -n "$jira_key" && -n "$jira_title" ]]; then
      print " ${pink_cor}${jira_key}${reset_cor} ${purple_cor}${jira_title}${reset_cor}" 1>/dev/tty
    fi

    if git rev-parse HEAD &>/dev/null; then
      print -n " " 1>/dev/tty
      git --no-pager log --oneline --decorate -1 2>/dev/null 1>/dev/tty || true
    fi
  fi

  if [[ -n "$CURRENT_PUMP_PRO" && -t 0 && -o login ]]; then
    eval "$CURRENT_PUMP_PRO" 1>/dev/tty
  fi
}

# pro pwd
function pro_pwd_() {
  local proj_arg="$(find_proj_by_folder_ 2>/dev/null)"
  
  if ! [[ -t 0 && -o login ]]; then
    return 1;
  fi

  if [[ -n "$proj_arg" ]]; then
    pro -x "$proj_arg"
    return $?;
  fi

  local parent_folder_name="$(basename -- $(dirname -- "$PWD"))"

  if [[ "$parent_folder_name" == ".backups" || "$parent_folder_name" == ".revs" || "$parent_folder_name" == ".cov" ]]; then
    return 0;
  fi

  if ! is_folder_pkg_ &>/dev/null; then
    set_current_proj_pwd_
    return $?;
  fi

  local pkg_name="$(get_pkg_name_ "$PWD" "" 1)"
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
    if confirm_ "update project ${bold_pink_cor}${pkg_name}${reset_cor} to new folder: ${cyan_cor}$PWD${reset_cor} ?" "update" "ignore"; then
      save_proj_f_ -e $foundI "$proj_cmd" "$pkg_name" 2>/dev/tty
    fi
  elif (( emptyI )); then
    if confirm_ "add new project: ${bold_pink_cor}${pkg_name}${reset_cor} ?" "add" "no"; then
      save_proj_f_ -a $emptyI "$proj_cmd" "$pkg_name" 2>/dev/tty
    else
      set_current_proj_pwd_
    fi
  fi
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

  local jira_almost_done="${PUMP_JIRA_ALMOST_DONE[$i]:-"Ready for Production"}"
  local jira_blocked="${PUMP_JIRA_BLOCKED[$i]:-"Blocked"}"
  local jira_canceled="${PUMP_JIRA_CANCELED[$i]:-"Canceled"}"
  local jira_done="${PUMP_JIRA_DONE[$i]:-"Done"}"
  local jira_in_progress="${PUMP_JIRA_IN_PROGRESS[$i]:-"In Progress"}"
  local jira_in_review="${PUMP_JIRA_IN_REVIEW[$i]:-"In Review"}"
  local jira_in_test="${PUMP_JIRA_IN_TEST[$i]:-"In Test"}"
  local jira_ready_for_test="${PUMP_JIRA_READY_FOR_TEST[$i]:-"Ready for Test"}"
  local jira_todo="${PUMP_JIRA_TODO[$i]:-"To Do"}"

  local sub_cmds=("bkp" "clone" "gha" "jira" "prs" "pull" "rel" "rels" "rev" "revs" "run" "setup" "tag" "tags" "exec" "version")

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
      print "  ${hi_yellow_cor}  -u${reset_cor} : reset settings"
      print "  --"

      (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} bkp${reset_cor} : create backup of the project"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} bkp [<folder>]${reset_cor} : create backup of a project folder"
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<folder>]${reset_cor} : delete backup folders"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} clone${reset_cor} : clone project"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} clone <branch> [<target>]${reset_cor} : clone branch off of target branch"
      (( ! single_mode )) && print "  ${hi_yellow_cor}  -d <workflow_run>${reset_cor} : clone a workflow run branch"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} exec${yellow_cor} [<name>]${reset_cor} : execute shell script"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} gha${yellow_cor} [<workflow>] [<search...>]${reset_cor} : check status of workflow runs"
      print "  ${hi_yellow_cor}  -a${yellow_cor} [<interval>]${reset_cor} : check every interval min"
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<search...>]${reset_cor} : deployment workflow"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} jira${yellow_cor} [<key>]${reset_cor} : open work item"
      print "  ${hi_yellow_cor}${proj_cmd} jira release${yellow_cor} [<key>]${reset_cor} : open work item in release"
      print "  ${hi_yellow_cor}  -sd${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_todo}\""
      print "  ${hi_yellow_cor}  -sb${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_blocked}\""
      print "  ${hi_yellow_cor}  -sr${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_in_review}\""
      print "  ${hi_yellow_cor}  -st${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_ready_for_test}\""
      print "  ${hi_yellow_cor}  -stt${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_in_test}\""
      print "  ${hi_yellow_cor}  -sa${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_almost_done}\""
      print "  ${hi_yellow_cor}  -se${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_done}\""
      print "  ${hi_yellow_cor}  -sc${yellow_cor} [<key>]${reset_cor} : move work item to \"${jira_canceled}\""
      print "  ${hi_yellow_cor}  -ss${yellow_cor} [<key>] [<status>]${reset_cor} : move work item to a custom status"
      print "  ${hi_yellow_cor}  -v${yellow_cor} [<key>]${reset_cor} : view info on work item"
      print "  ${hi_yellow_cor}  -vv${reset_cor} : view info on all work items"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  ${hi_yellow_cor}  -x${reset_cor} : exact key, no lookup"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} prs${reset_cor} : list all pull requests"
      print "  ${hi_yellow_cor}  -l${yellow_cor} [<search>]${reset_cor} : label prs based on unreleased jira releases"
      print "  ${hi_yellow_cor}  -ll${yellow_cor} [<search>]${reset_cor} : label prs based on all unreleased jira releases"
      print "  ${hi_yellow_cor}  -lr${yellow_cor} [<search>]${reset_cor} : label prs based on released jira releases"
      print "  ${hi_yellow_cor}  -a${yellow_cor} [<search>]${reset_cor} : approve pull requests"
      print "  ${hi_yellow_cor}  -ax${yellow_cor} [<search>]${reset_cor} : approve pull requests even with approval min"
      print "  ${hi_yellow_cor}  -aa${yellow_cor} [<search>] [<interval>]${reset_cor} : approve prs every interval min"
      print "  ${hi_yellow_cor}  -r${reset_cor} : rebase/merge all your open pull requests"
      print "  ${hi_yellow_cor}  -rx${reset_cor} : rebase/merge and re-fix all your open pull requests"
      print "  ${hi_yellow_cor}  -s${reset_cor} : set assignee for all pull requests"
      print "  ${hi_yellow_cor}  -sa${yellow_cor} [<interval>]${reset_cor} : set assignee for all prs every interval min"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"
      (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} pull${reset_cor} : update local branches with its configured upstream"
      (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} pull${reset_cor} : update folders with its configured upstream"
      print "  ${hi_yellow_cor}  -ff${reset_cor} : --force"
      print "  ${hi_yellow_cor}  -fo${reset_cor} : --ff-only"
      print "  ${hi_yellow_cor}  -p${reset_cor} : --prune"
      print "  ${hi_yellow_cor}  -t${reset_cor} : --tags"
      print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"

      print "  --"
      if [[ "$proj_cmd" == "$CURRENT_PUMP_SHORT_NAME" ]] && is_folder_git_ &>/dev/null; then
        print "  ${hi_yellow_cor}${proj_cmd} rel${yellow_cor} [<branch>] [<tag>] [<title>]${reset_cor} : publish new release"
      else
        print "  ${hi_yellow_cor}${proj_cmd} rel <branch>${yellow_cor} [<tag>] [<title>]${reset_cor} : publish new release"
      fi
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<tag>]${reset_cor} : delete release by tag"
      print "  ${hi_yellow_cor}  -b${reset_cor} : publish beta release (pre-release)"
      print "  ${hi_yellow_cor}  -m${reset_cor} : publish major release"
      print "  ${hi_yellow_cor}  -n${reset_cor} : publish minor release"
      print "  ${hi_yellow_cor}  -p${reset_cor} : publish patch release"
      print "  ${hi_yellow_cor}  -r${reset_cor} : re-release disable --fail-on-no-commits"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} rels${yellow_cor} [<limit>]${reset_cor} : display a limited number of releases"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} rev${yellow_cor} [<pr_or_branch>]${reset_cor} : open code review by pr or branch"
      print "  ${hi_yellow_cor}  -b${yellow_cor} [<branch>]${reset_cor} : open code review by branch only"
      print "  ${hi_yellow_cor}  -x${yellow_cor} [<branch>]${reset_cor} : exact branch, no lookup"
      print "  ${hi_yellow_cor}  -j${yellow_cor} [<jira_key>]${reset_cor} : open code review by work item"
      print "  ${hi_yellow_cor}  -r${yellow_cor} [<jira_key>]${reset_cor} : open code review by unreleased jira release"
      print "  ${hi_yellow_cor}  -e${reset_cor} : check out local code reviews"
      print "  ${hi_yellow_cor}  -d${reset_cor} : delete local code reviews"
      print "  ${hi_yellow_cor}  -dd${reset_cor} : delete all local code reviews"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} revs${reset_cor} : check out local code reviews"
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
      if [[ -n "${PUMP_RUN_QA[$i]}" ]]; then
        (( single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run qa${reset_cor} : run ${proj_cmd}'s PUMP_RUN_QA in ${proj_cmd}'s folder"
        (( ! single_mode )) && print "  ${hi_yellow_cor}${proj_cmd} run qa <folder>${reset_cor} : run ${proj_cmd}'s PUMP_RUN_QA in a ${proj_cmd}'s folder"
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

      print "  ${hi_yellow_cor}${proj_cmd} tag${yellow_cor} [<name>]${reset_cor} : create annotated tag"
      print "  ${hi_yellow_cor}  -d${yellow_cor} [<name>]${reset_cor} : delete tag"
      print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation"
      print "  --"

      print "  ${hi_yellow_cor}${proj_cmd} tags${yellow_cor} [<limit>]${reset_cor} : display a limited number of tags"
      print "  --"

      if [[ -n "${PUMP_VERSION_CMD[$i]}" && "${PUMP_VERSION_CMD[$i]}" != "0" ]] && [[ -n "${PUMP_VERSION_WEB[$i]}" && "${PUMP_VERSION_WEB[$i]}" != "0" ]]; then
        print "  ${hi_yellow_cor}${proj_cmd} version${reset_cor} : display project version from command output"
        print "  ${hi_yellow_cor}  -w${reset_cor} : from web site meta tag"
      elif [[ -n "${PUMP_VERSION_WEB[$i]}" && "${PUMP_VERSION_WEB[$i]}" != "0" ]]; then
        print "  ${hi_yellow_cor}${proj_cmd} version${reset_cor} : from web site meta tag"
      elif [[ -n "${PUMP_VERSION_CMD[$i]}" && "${PUMP_VERSION_CMD[$i]}" != "0" ]]; then
        print "  ${hi_yellow_cor}${proj_cmd} version${reset_cor} : from command output"
      else
        print "  ${hi_yellow_cor}${proj_cmd} version${reset_cor} : display project version"
      fi
      return 0;
    fi

    # proj_handler -c
    if (( proj_handler_is_c )); then
      pro -cH "$proj_cmd"
      return $?;
    fi

    # proj_handler -d
    if (( proj_handler_is_d )); then
      pro -dH "$proj_cmd"
      return $?;
    fi

    # proj_handler -e
    if (( proj_handler_is_e )); then
      pro -eH "$proj_cmd"
      return $?;
    fi

    # proj_handler -i
    if (( proj_handler_is_i )); then
      pro -iH "$proj_cmd"
      return $?;
    fi

    # proj_handler -n [<version>]
    if (( proj_handler_is_n )); then
      pro -nH "$proj_cmd" "$@"
      return $?;
    fi

    # proj_handler -u [<setting>]
    if (( proj_handler_is_u )); then
      pro -uH "$proj_cmd" "$@"
      return $?;
    fi

    # proj_handler -m
    if (( proj_handler_is_m )); then
      if (( single_mode )); then
        print " ${red_cor}fatal: invalid option: -m${reset_cor}" >&2
        print "  --"
        $proj_cmd -h
        return 0;
      fi

      if ! check_proj_ -fv $i; then return 1; fi
      local proj_folder="${PUMP_FOLDER[$i]}"
      
      local folder="$(find_git_folder_ -m "$proj_folder" 2>/dev/null)"
      local folder_name="$(basename -- "$folder")"

      if [[ -z "$folder" ]]; then
        print " not a valid folder: ${hi_cyan_cor}main${reset_cor}" >&2
      fi

      proj_handler_open_ -- $i "${proj_folder}/${folder_name}"
      return $?;
    fi

    # proj_handler [<folder>]
    # Check if any flags other than -o or -f were set
    local all_flags=(m e i n u d c o f)
    local other_flags_set=0
    
    local flag=""
    for flag in "${all_flags[@]}"; do
      if [[ "$flag" != "o" && "$flag" != "f" ]]; then
        local flag_var="proj_handler_is_${flag}"
        if (( ${(P)flag_var} )); then
          other_flags_set=1
          break
        fi
      fi
    done

    if (( other_flags_set )); then
      print " fatal: invalid option combination" >&2
      print " run: ${hi_yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
      return 1
    fi

    # proj_handler_folder_ $i "$1"
    # return $?

    # if (( proj_handler_is_o || proj_handler_is_f )); then
    #   print " fatal: invalid option: -${$(( proj_handler_is_o )) && echo "o" || echo "f"}${reset_cor}" >&2
    #   print " --"
    #   $proj_cmd -h
    #   return 1
    # fi
    
    # # Check if folder_arg contains only valid characters
    # if [[ -n "$folder_arg" && ! "$folder_arg" =~ ^[a-zA-Z0-9/._-]+$ ]]; then
    #   print " fatal: invalid folder argument: $folder_arg" >&2
    #   print " run: ${hi_yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2
    #   return 1
    # fi

    # print " fatal: too many arguments" >&2
    # print " run: ${hi_yellow_cor}${proj_cmd} -h${reset_cor} to see usage" >&2

    # return 1;
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

    if [[ "$sub_cmd" == "pull" ]]; then
      proj_pull_ "$proj_cmd" "${args[@]}"
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

    if [[ "$sub_cmd" == "exec" ]]; then
      proj_exec_ "$proj_cmd" "${args[@]}"
      return $?;
    fi

    if [[ "$sub_cmd" == "version" ]]; then
      proj_version_ "$proj_cmd" "${args[@]}"
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

    print " fatal: invalid option: $flag${reset_cor}" >&2
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
  eval "$(parse_simple_flags_ "$0" "of" "" "$@")"
  (( proj_handler_folder_is_debug )) && set -x

  local i="$1"
  local folder_arg="$2"

  if ! check_proj_ -fv $i; then return 1; fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"

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
        if [[ -d "${proj_folder}/${folder_arg}" ]]; then
          choosen_folder="$folder_arg"
        # else
          # print " fatal: not a valid folder: ${hi_cyan_cor}$folder_arg${reset_cor}" >&2
          # # print " run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage" >&2
          # # return 1;
        fi
      fi

      if [[ -z "$choosen_folder" ]]; then
        local dirs=""
        dirs="$(get_folders_ -p $i "$proj_folder" "$folder_arg" 2>/dev/null)"
        if (( $? == 130 )); then return 130; fi

        if [[ -z "$dirs" && -n "$folder_arg" ]]; then
          print " not a valid folder: ${hi_cyan_cor}$folder_arg${reset_cor}" >&2

          dirs="$(get_folders_ -p $i "$proj_folder" 2>/dev/null)"
          if (( $? == 130 )); then return 130; fi
        fi

        if [[ -n "$dirs" ]]; then
          choosen_folder="$(choose_one_ -it "folder in $proj_cmd" "${(@f)dirs}")"
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

    if [[ -n "$folder_arg" ]] && (( is_of )); then
      # always will have $folder_arg here
      if [[ -d "${proj_folder}/${folder_arg}" ]]; then
        cd "${proj_folder}/${folder_arg}"
        return $?;
      fi
      # print " fatal: not a valid folder: ${hi_cyan_cor}$folder_arg${reset_cor}" >&2
      # print " run: ${hi_yellow_cor}$proj_cmd -h${reset_cor} to see usage" >&2
      # return 1;
    fi

    local dirs=""
    dirs="$(get_folders_ -ijp $i "$proj_folder" "$folder_arg" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -z "$dirs" && -n "$folder_arg" ]]; then
      print " not a valid folder: ${hi_cyan_cor}$folder_arg${reset_cor}" >&2

      dirs="$(get_folders_ -ip $i "$proj_folder" 2>/dev/null)"
      if (( $? == 130 )); then return 130; fi
    fi

    local RET=0

    if [[ -n "$dirs" ]]; then
      choosen_folder="$(choose_one_ -it "folder in $proj_cmd" "${(@f)dirs}")"
      RET=$?
      # instead of exit, comment this out to open the root folder
      if (( RET == 130 )); then return 1; fi

      # if (( RET == 130 || RET == 2 )); then return 1; fi
      if [[ -n "$choosen_folder" ]]; then
        folder_to_open="${proj_folder}/${choosen_folder}"

        if [[ -n "$folder_arg" ]]; then
          local folders="$(find "$proj_folder" -maxdepth 2 -type d -name "$choosen_folder" ! -path "*/.*" -print 2>/dev/null)"
          local found_proj_folder=("${(@f)folders}")

          found_proj_folder=("${found_proj_folder[@]/#$proj_folder\//}")          

          choosen_folder="$(choose_one_ -it "folder in $proj_cmd" "${found_proj_folder[@]}")"

          if [[ "$folder_to_open" != "${proj_folder}/${choosen_folder}" ]]; then
            folder_to_open="${proj_folder}/${choosen_folder}"

            cd "$folder_to_open"
            return $?;
          fi
        fi
      else
        # if already inside a project folder, exit to avoid cd to root folder
        if is_folder_git_ &>/dev/null; then
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
  eval "$(parse_simple_flags_ "$0" "" "" "$@")"
  (( proj_handler_open_is_debug )) && set -x

  local i="$1"
  local folder_to_open="$2"

  if [[ -z "$folder_to_open" ]]; then
    print " fatal: folder to open is required" >&2
    return 1;
  fi

  local proj_cmd="${PUMP_SHORT_NAME[$i]}"
  local proj_folder="${PUMP_FOLDER[$i]}"
  local go_back="${PUMP_GO_BACK[$i]}"

  if [[ ! -d "$folder_to_open" || -z "$(ls -- "$folder_to_open")" ]]; then
    print " run: ${hi_yellow_cor}${proj_cmd} clone${reset_cor}" >&2

    if [[ -d "$folder_to_open" ]]; then
      cd "$folder_to_open"
    fi
    return 0;
  fi

  local is_proj_folder=0

  # local fsample="$(find "$folder_to_open" \( -path "*/.*" -a ! -name ".git" \) -prune -o -maxdepth 1 -type d -name ".git" -print -quit 2>/dev/null)"

  # if [[ -n "$fsample" ]]; then
  #   is_proj_folder=1
  # el
  if is_folder_pkg_ "$folder_to_open" &>/dev/null; then
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
    local dirs=""
    dirs="$(get_folders_ -ijp $i "$folder_to_open" 2>/dev/null)"
    if (( $? == 130 )); then return 130; fi

    if [[ -n "$dirs" ]]; then
      local choosen_folder=""
      # choosen_folder has to be declared first so that RET can be captured
      choosen_folder="$(choose_one_ -it "folder in /$(basename -- "$folder_to_open")" "${(@f)dirs}")"
      local RET=$?

      if (( RET == 130 )); then
        if [[ "$proj_folder" == "$folder_to_open" ]]; then
          cd "$folder_to_open"
          return $?;
        fi

        if (( go_back )); then
          proj_handler_open_ -- $i "$proj_folder"
          return $?;
        fi

        if [[ -z "$go_back" ]]; then
          confirm_ "open ${hi_green_cor}$folder_to_open${reset_cor}?"
          local _RET=$?
          if (( _RET == 0 )); then
            update_config_ $i "PUMP_GO_BACK" "0"
            cd "$folder_to_open"
            return $?;
          fi
          if (( _RET == 1 )); then
            update_config_ $i "PUMP_GO_BACK" "1"
            proj_handler_open_ -- $i "$proj_folder"
            return $?;
          fi
        fi

        return 130;
      fi

      if (( RET != 0 )); then
        if is_folder_git_ &>/dev/null; then
          return 0;
        fi

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

  cd "$folder_to_open"
}

# commit functions ====================================================
function commit() {
  set +x
  eval "$(parse_flags_ "$0" "amscfjne" "q" "$@")"
  (( commit_is_debug )) && set -x

  if (( commit_is_h )); then
    print "  ${hi_yellow_cor}commit ${yellow_cor}[-m] [<message>] [folder]${reset_cor} : commit wizard"
    print "  ${hi_yellow_cor}  -a${reset_cor} : add all files to index before commit"
    print "  ${hi_yellow_cor}  -c${reset_cor} : create message using conventional commits standard"
    print "  ${hi_yellow_cor}  -e${reset_cor} : --amend"
    print "  ${hi_yellow_cor}  -f${reset_cor} : skip confirmation and prompts"
    print "  ${hi_yellow_cor}  -j${reset_cor} : create message using jira if available"
    print "  ${hi_yellow_cor}  -n${reset_cor} : prompt for a bigger commit message"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    (( CURRENT_PUMP_COMMIT_SIGNOFF )) && print "  ${hi_yellow_cor}  -s${reset_cor} : --signoff (by default)"
    (( ! CURRENT_PUMP_COMMIT_SIGNOFF )) && print "  ${hi_yellow_cor}  -s${reset_cor} : --signoff"
    return 0;
  fi

  local message=""
  local folder=""

  eval "$(parse_args_ "$0" "message:to,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  local is_amend="$( (( ${argv[(Ie)--amend]} || commit_is_e )) && echo 1 || echo 0)"
  local is_quiet="$( (( ${argv[(Ie)--quiet]} || commit_is_q )) && echo 1 || echo 0)"

  if (( commit_is_f && commit_is_n )); then
    print " fatal: option -f cannot be used together with -c or -n" >&2
    print " run: ${hi_yellow_cor}commit -h${reset_cor} to see usage" >&2
    return 1;
  fi

  if (( is_amend )); then
    local last_message="$(git -C "$folder" log -1 --pretty=%s 2>/dev/null)"

    if [[ -z "$last_message" ]]; then
      print " no previous commit, cannot amend" >&2
      return 1;
    fi
  fi

  local proj_cmd="$(find_proj_by_folder_ "$folder" 2>/dev/null)"
  if [[ -z "$proj_cmd" ]]; then proj_cmd="$CURRENT_PUMP_SHORT_NAME"; fi

  local i="$(find_proj_index_ -x "$proj_cmd" 2>/dev/null)"

  local pump_commit_signoff="${PUMP_COMMIT_SIGNOFF[$i]:-$CURRENT_PUMP_COMMIT_SIGNOFF}"
  local pump_pr_title_format="${PUMP_PR_TITLE_FORMAT[$i]:-$CURRENT_PUMP_PR_TITLE_FORMAT}"

  if [[ -z "$pump_pr_title_format" ]]; then
    pump_pr_title_format="<jira_key> <jira_title>"
  fi

  local is_clean_must=1

  if (( is_amend )); then
    if (( commit_is_c || commit_is_j || commit_is_n )) || [[ -n "$message" ]]; then
      is_clean_must=0
    fi
  fi

  if (( is_clean_must )); then
    if is_branch_status_clean_ "$folder"; then
      local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"

      if [[ -n "$my_branch" ]]; then
        print " on branch $my_branch" >&2
      else
        print " HEAD detached at $(git -C "$folder" rev-parse --short HEAD 2>/dev/null)" >&2
      fi
      print " nothing to commit, working tree clean" >&2
      return 1;
    fi
  fi

  if (( ! commit_is_a && is_clean_must )); then
    if is_branch_status_clean_ -i "$folder"; then
      if (( ! is_quiet )); then
        print " no changes added to commit" >&2
        print " run: ${hi_yellow_cor}commit -a${reset_cor} or ${hi_yellow_cor}add${reset_cor} to add files to commit" >&2
      fi
      return 1;
    fi
  fi

  local flags=()

  if (( commit_is_s || pump_commit_signoff )); then
    flags+=(--signoff)
  elif [[ -z "$pump_commit_signoff" ]]; then
    local RET=0
    if (( commit_is_f )); then
      RET=1
    else
      confirm_ "sign off commit?" "yes" "no" "no"
      RET=$?
    fi
    if (( RET == 130 || RET == 2 )); then return 130; fi

    if (( RET == 0 )); then
      flags+=(--signoff)
  
      if (( i )); then
        update_config_ $i "PUMP_COMMIT_SIGNOFF" 1
        PUMP_COMMIT_SIGNOFF[$i]=1
      fi
    else
      if (( i && ! commit_is_f )); then
        update_config_ $i "PUMP_COMMIT_SIGNOFF" 0
        PUMP_COMMIT_SIGNOFF[$i]=0
      fi
    fi
  fi

  local jira_key=""
  local jira_title=""
  local jira_message=""

  local is_extracted_key=0

  if (( ! is_amend || commit_is_j )); then
    if [[ -n "$message" ]]; then
      jira_key="$(extract_jira_key_ "$message")"
      if [[ -n "$jira_key" ]]; then
        is_extracted_key=1
      fi
    fi

    if [[ -z "$jira_key" ]]; then
      jira_key="$(read_pump_value_ "JIRA_KEY" "$folder")"

      if (( commit_is_j )) && { [[ -z "$message" ]] || (( is_amend )) }; then
        jira_title="$(read_pump_value_ "JIRA_TITLE" "$folder")"
      fi
    fi

    if [[ -z "$jira_key" ]]; then
      local my_branch="$(get_my_branch_ "$folder" 2>/dev/null)"
      jira_key="$(extract_jira_key_ "$my_branch" "$folder")"
    fi

    if (( commit_is_j )); then
      if [[ -z "$jira_key" ]] || [[ -z "$jira_title" && -z "$message" ]]; then
        local commit_key="" commit_title=""
        local output=""
        output="$(read_commits_ -tj "$target_branch" "$my_branch" "$folder")"
        if (( $? == 0 )); then
          IFS=$TAB read -r commit_key commit_title <<< "$output"
        fi

        if [[ -z "$jira_key" ]]; then jira_key="$commit_key"; fi
        if [[ -z "$jira_title" ]]; then jira_title="$commit_title"; fi
      fi

      if [[ -z "$jira_key" ]]; then
        print " no jira key found in message, branch name, or recent commits" >&2
        return 1;
      fi
    fi
  fi

  local notes=""
  local type_commit=""
  local commit_types=("fix" "feat" "test" "build" "chore" "ci" "docs" "perf" "refactor" "revert" "style")

  if (( commit_is_c && ! commit_is_f )); then
    type_commit="$(choose_one_ "commmit type" "${commit_types[@]}")"
    if (( $? == 130 )); then return 130; fi
    if [[ -z "$type_commit" ]]; then return 1; fi

    # scope is optional so user can skip
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

  if [[ -z "$message" ]]; then
    if [[ -n "$jira_key" ]]; then
      jira_message="${pump_pr_title_format//\<jira_key\>/$jira_key}"
      jira_message="${jira_message//\<jira_title\>/$jira_title}"

      if [[ -n "$type_commit" ]]; then
        message="${type_commit}: $jira_message"
      else
        message="$jira_message"
      fi
    elif [[ -n "$type_commit" ]]; then
      message="${type_commit}:"
    fi

    if (( is_amend )) && [[ -n "$message" && -z "$jira_key" ]]; then
      local last_message="$(git -C "$folder" log -1 --pretty=%B | head -n 1 2>/dev/null)"

      if [[ -n "$last_message" ]]; then
        # if the last message already contains a type, remove it to avoid duplication (including optional (scope)!:)
        local types="fix|feat|test|build|chore|ci|docs|perf|refactor|revert|style"
        # check if any type of commit_types is already in the message, if found, remove it (including optional (scope)!:)
        local ct=""
        for ct in "${commit_types[@]}"; do
          if [[ $last_message =~ "^[[:space:]]*(${(j:|:)${(s:|:)types}})(\([^)]*\))?!?:[[:space:]]*(.*)" ]]; then
            message="${message} ${match[3]}"
            break;
          fi
        done
      fi
    fi

    if (( ! commit_is_f )); then
      if (( ! is_amend )) || [[ -n "$message" ]]; then
        if [[ -n "$message" ]]; then message="${message} "; fi
        message="$(input_type_mandatory_ -kx "" "commit message" 255 "$message")"
        if (( $? == 130 )); then return 130; fi
      fi
    fi

  elif [[ -n "$type_commit" ]]; then
    if [[ -n "$jira_key" ]] && (( ! is_extracted_key )); then
      jira_message="${pump_pr_title_format//\<jira_key\>/$jira_key}"
      jira_message="${jira_message//\<jira_title\>/$message}"

      message="${type_commit}: $jira_message"
    else
      message="${type_commit}: $message"
    fi
  else
    if [[ -n "$jira_key" ]] && (( ! is_extracted_key )); then
      jira_message="${pump_pr_title_format//\<jira_key\>/$jira_key}"
      jira_message="${jira_message//\<jira_title\>/$message}"
      
      message="$jira_message"
    fi
  fi

  if (( ! is_amend )) && [[ -z "$message" ]]; then
    print " fatal: commit message is not determined" >&2
    print " run: ${hi_yellow_cor}commit -h${reset_cor} to see usage" >&2

    return 1;
  fi

  if (( is_amend )); then
    local last_message="$(git -C "$folder" log -1 --pretty=%B 2>/dev/null)"

    if [[ -z "$last_message" ]]; then
      print " fatal: no previous commit, cannot amend" >&2
      return 1;
    fi

    if [[ $last_message == Merge* ]]; then
      print " fatal: last commit is a merge commit, cannot amend" >&2
      return 1;
    fi

    notes="$(echo "$last_message" | tail -n +2)"
  fi

  if (( commit_is_n )); then
    notes="$(write_from_ "more notes" "$notes")"
    if (( $? == 130 )); then return 130; fi
  fi

  # print " message = $message" >&2

  if (( commit_is_a )); then
    if ! git -C "$folder" add .; then return 1; fi
  fi

  if (( is_amend )) && [[ -z "$message" && -n "$notes" ]]; then
    message="$(git -C "$folder" log -1 --pretty=%s 2>/dev/null)"
  fi

  if (( is_amend )); then
    if [[ -n "$message" && -n "$notes" ]]; then
      git -C "$folder" commit --no-verify --amend --no-edit -m "$message" -m "$notes" "${flags[@]}" "$@"
    elif [[ -n "$message" ]]; then
      git -C "$folder" commit --no-verify --amend --no-edit -m "$message" "${flags[@]}" "$@"
    else
      git -C "$folder" commit --no-verify --amend --no-edit "${flags[@]}" "$@"
    fi
  else
    git -C "$folder" commit --no-verify -m "$message" -m "$notes" "${flags[@]}" "$@"
  fi

  if (( $? != 0 )); then return 1; fi

  if (( ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1 || true
  fi
}

function recommit() {
  set +x
  eval "$(parse_flags_ "$0" "i" "cjnq" "$@")"
  (( recommit_is_debug )) && set -x

  if (( recommit_is_h )); then
    print "  ${hi_yellow_cor}recommit ${yellow_cor}[<message>] [<folder>]${reset_cor} : reset previous commit without losing your changes then re-commit all changes"
    print "  ${hi_yellow_cor}  -c${reset_cor} : create message using conventional commits standard"
    print "  ${hi_yellow_cor}  -i${reset_cor} : only recommit staged changes"
    print "  ${hi_yellow_cor}  -j${reset_cor} : create message using jira if available"
    print "  ${hi_yellow_cor}  -n${reset_cor} : prompt for a bigger commit message"
    print "  ${hi_yellow_cor}  -q${reset_cor} : --quiet"
    return 0;
  fi

  local message=""
  local folder=""

  eval "$(parse_args_ "$0" "message:to,folder:fz" "$@")"
  shift $arg_count

  if ! is_folder_git_ "$folder"; then return 1; fi

  if (( recommit_is_i )); then
    if ! commit -eq "$message" "$folder" "$@"; then
      return 1;
    fi
  else
    if ! commit -eaq "$message" "$folder" "$@"; then
      return 1;
    fi
  fi

  local is_quiet="$( (( ${argv[(Ie)--quiet]} || recommit_is_q )) && echo 1 || echo 0)"

  if (( ! is_quiet )); then
    git -C "$folder" --no-pager log --oneline --decorate -1 || true
  fi
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
    gum style --border=rounded --margin=0 --padding="1" --border-foreground 212 --width=70 \
      --align=center --bold "$(gum style --foreground 212 --bold "pump-zsh v$PUMP_VERSION")"
  else
    display_line_ "" "${bold_pink_cor}"
    display_line_ "pump my shell!" "${bold_pink_cor}" 70 "${reset_cor}"
    display_line_ "$PUMP_VERSION" "${bold_pink_cor}" 70 "${reset_cor}"
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
    
    local pkg_v="$($CURRENT_PUMP_PKG_MANAGER -v 2>/dev/null)"
    if [[ -z "$pkg_v" ]]; then pkg_v="not installed"; fi
    
    printf "  %-4s v.: %s" "$CURRENT_PUMP_PKG_MANAGER" "${bold_magenta_cor}$pkg_v${reset_cor}"
  fi

  local i=0
  local found=0
  for i in {1..9}; do
    if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
      found="$i"
      break;
    fi
  done

  if (( found == 0 )); then
    help_general_
    print ""
    pro -a
    return $?;
  fi
  
  print ""
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
  print "  type ${hi_yellow_cor}-h${reset_cor} after any command to see help, example: ${hi_yellow_cor}pro -h${reset_cor}"
  print ""
  print "  more info: https://github.com/fab1o/pump-zsh/wiki"
  print ""
}

function help_projects_() {
  local spaces="14s"

  print ""
  display_line_ "projects" "${blue_cor}"
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
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete files"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "help" "display this help"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "hg <text>" "history | grep text"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "kill <port>" "kill port"
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "ll" "display all files"
  if [[ "$(uname)" == "Darwin" ]] && command -v softwareupdate &>/dev/null; then
    printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "macdown" "download macos installers"
  fi
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
  printf "  ${yellow_cor}%-$spaces${reset_cor} = %s \n" "del" "delete files"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "push" "push branch to upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "recommit" "amend last commit"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "repush" "recommit + push"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "merge" "merge branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rebase" "rebase branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "abort" "abort rebase/merge/revert/chp"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "conti" "continue rebase/merge/revert/chp"
  print ""

  if [[ -n "$pkg_manager" ]]; then
    local _run="${CURRENT_PUMP_RUN:-"$pkg_manager run dev or $pkg_manager start"}"
    local _setup="${CURRENT_PUMP_SETUP:-"$pkg_manager run setup or $pkg_manager install"}"

    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "refix" "fix + recommit"
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
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseta" "erase all changes to match local branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "reseto" "erase all changes to match remote branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "restore" "discard unstaged changes in working tree"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git commit" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "add" "add files to index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "rem" "remove files from index"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "commit" "add + commit wizard"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "commit <m>" "add + commit message"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "recommit" "amend last commit"

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
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "fetch" "fetch upstream"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pull" "pull branch"
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pullr" "pull branch with rebase"

  if ! pause_output_; then return 0; fi
  
  print ""
  display_line_ "git push" "${hi_cyan_cor}"
  print ""
  printf "  ${hi_cyan_cor}%-$spaces${reset_cor} = %s \n" "pr" "create pull request"
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
  if [[ -n "$CURRENT_PUMP_RUN_QA" ]]; then
    printf "  ${hi_magenta_cor}%-$spaces${reset_cor} = %s \n" "run qa" "run PUMP_RUN_QA"
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
    print " ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  local invalid_values=("pwd" "quit" "done" "path" "bkp" "clone" "gha" "jira" "prs" "pull" "rel" "rels" "rev" "revs" "run" "setup" "tag" "tags" "exec" "version")

  if [[ " ${invalid_values[*]} " == *" $proj_cmd "* ]]; then
    print " ${red_cor}project name is reserved: ${proj_cmd}${reset_cor}" 2>/dev/tty
    return 1;
  fi

  return 0;
}

function validate_proj_cmd_() {
  local i="$1"
  local proj_cmd="$2"
  local max=${3:-10}

  local error_msg=""

  if [[ -z "$proj_cmd" ]]; then
    error_msg="project name is missing"
  elif [[ ${#proj_cmd} -gt $max ]]; then
    error_msg="project name is too big: make it short and memorable: $max characters max"
  elif ! [[ "$proj_cmd" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    error_msg="project name is invalid: no special characters and all lowercase"
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
    print " ${red_cor}${error_msg}${reset_cor}" 2>/dev/tty
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
  eval "$(parse_flags_ "$0" "apjif" "" "$@")"
  (( get_folders_is_debug )) && set -x

  local i="$1"
  local folder="${2:-$PWD}"
  local name_search="$3"

  if [[ ! -d "$folder" ]]; then
    print " fatal: invalid folder argument: ${folder}" >&2
    return 1;
  fi

  local dirs=()

  # m sort by modification time
  # n sort by name
  # o sort in ascending order (default)
  # O sort in reverse order
  # N an array, not a string

  unsetopt dot_glob

  local pump_jira_work_types=($(get_work_types_ $i))
  # pump_jira_work_types+=" release"

  if (( get_folders_is_a )) || [[ -n "$name_search" ]]; then
    local wt=""
    for wt in "${pump_jira_work_types[@]}"; do
      dirs+=("${folder}/${wt}"/*"${name_search}"*(N/on))
    done
    dirs+=("${folder}"/release/*"${name_search}"*(N/on))
  fi

  dirs+=("${folder}"/*"${name_search}"*(N/on))

  local display_folders=()
  local counter=0
  local filtered_folders=()

  if (( get_folders_is_p )); then
    # work types
    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ " ${pump_jira_work_types[@]} " != *" ${dir:t} "* ]]; then
        continue;
      fi
      if [[ -z "$(ls -- "$dir")" ]]; then
        continue;
      fi

      filtered_folders+=("$dir")

      if (( get_folders_is_f )); then
        display_folders+=("$dir")
      elif (( get_folders_is_i )); then
        # local display_dir="$(printf "%-13s %s" "${dir:t}")"$'\t'"${dir:t} work items";
        # display_folders+=("$display_dir")
        display_folders+=("${dir:t}")
      else
        display_folders+=("${dir:t}")
      fi
      counter=$((counter + 1))
    done
    
    if (( counter > 0 )); then
      display_folders+=("--")
      counter=0
    fi

    # non work items
    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ -n "$(extract_jira_key_ "$dir")" || " ${filtered_folders[@]} " == *" $dir "* ]]; then
        continue;
      fi
      if [[ -z "$(ls -- "$dir")" ]] || is_folder_git_ "$dir" &>/dev/null; then
        continue;
      fi

      filtered_folders+=("$dir")

      if (( get_folders_is_f )); then
        display_folders+=("$dir")
      elif (( get_folders_is_i )); then
        display_folders+=("$(get_folders_i_ "$dir" 2>/dev/null)")
        # local display_dir="$(printf "%-13s %s" "${dir:t}")"$'\t'"${dir:t} work items";
        # display_folders+=("$display_dir")
      else
        display_folders+=("${dir:t}")
      fi
      counter=$((counter + 1))
    done

    if (( counter > 0 )); then
      display_folders+=("--")
      counter=0
    fi

    # non work items
    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ -n "$(extract_jira_key_ "$dir")" || " ${filtered_folders[@]} " == *" $dir "* ]]; then
        continue;
      fi
      if [[ -z "$(ls -- "$dir")" ]] || ! is_folder_git_ "$dir" &>/dev/null; then
        continue;
      fi

      filtered_folders+=("$dir")

      if (( get_folders_is_f )); then
        display_folders+=("$dir")
      elif (( get_folders_is_i )); then
        display_folders+=("$(get_folders_i_ "$dir" 2>/dev/null)")
        # local display_dir="$(printf "%-13s %s" "${dir:t}")"$'\t'"${dir:t} work items";
        # display_folders+=("$display_dir")
      else
        display_folders+=("${dir:t}")
      fi
      counter=$((counter + 1))
    done

    if (( counter > 0 )); then
      display_folders+=("--")
      counter=0
    fi
    
    local local_dirs=("$folder"/"${name_search}"*(N/on))
    dirs=("${local_dirs[@]}" "${dirs[@]}")

    # work items
    dir=""
    for dir in "${dirs[@]}"; do
      if [[ -z "$(extract_jira_key_ "$dir")" || " ${filtered_folders[@]} " == *" $dir "* ]]; then
        continue;
      fi
      if [[ -z "$(ls -- "$dir")" ]]; then
        continue;
      fi

      filtered_folders+=("$dir")

      if (( get_folders_is_f )); then
        display_folders+=("$dir")
      elif (( get_folders_is_i )); then
        display_folders+=("$(get_folders_i_ "$dir" 2>/dev/null)")
      else
        display_folders+=("${dir:t}")
      fi
    done

  else

    local dir=""
    for dir in "${dirs[@]}"; do
      if [[ " ${filtered_folders[@]} " == *" $dir "* ]]; then
        continue;
      fi
      if (( get_folders_is_j )) && [[ -z "$(extract_jira_key_ "$dir")" ]]; then
        continue;
      fi
      if [[ -z "$(ls -- "$dir")" ]]; then
        continue;
      fi

      filtered_folders+=("$dir")

      if (( get_folders_is_f )); then
        display_folders+=("$dir")
      elif (( get_folders_is_i )); then
        display_folders+=("$(get_folders_i_ "$dir" 2>/dev/null)")
      else
        display_folders+=("${dir:t}")
      fi
    done
  fi

  printf "%s\n" "${display_folders[@]}"
}

function trim_() {
  set +x
  eval "$(parse_flags_ "$0" "s" "" "$@")"

  local val="$1"

  if [[ -n "$val" ]]; then
    val="$(print -r -- "$val" | xargs 2>/dev/null)"
    # if [[ -z "$val" ]]; then
    #   val="$(echo "$val" | xargs -0 2>/dev/null)";
    # fi
    if [[ -z "$val" ]]; then
      val="$1"
    fi

    # $(printf '%s' "$_input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    val="${${val##[[:space:]]}%%[[:space:]]}"

    # sanitize
    if (( trim_is_s )); then
      val="$(print -r -- "${val//[\"\'\(\)\[\]\{\}\|<>\/]/}")"
    fi
  fi

  print -r -- "$val"
}

function get_folders_i_() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  (( get_folders_i_is_debug )) && set -x

  # run this function only for multiple_mode projects
  local folder="$1"

  local dirname="$(basename -- "$folder")"
  local name_display="$dirname"

  # echo "$name_display"
  # return 0;

  local jira_key="$(extract_jira_key_ "$folder")"
  local jira_title="$(get_pump_jira_title_ "$jira_key" "$folder")"

  if [[ -z "$jira_title" ]]; then
    jira_title="$(git -C "$folder" log -1 --pretty=%s 2>/dev/null)"
    if [[ -n "$jira_title" && -z "$jira_key" ]]; then
      jira_key="$(extract_jira_key_ "$jira_title")"
    fi
  fi

  if [[ -n "$jira_title" ]]; then
    if [[ -n "$jira_key" ]]; then
      jira_title="${jira_title//$jira_key/}"
      jira_title="$(trim_ $jira_title)"
    fi

    jira_title="$(truncate_ "$jira_title" 80)"

    local spaces="$([[ "$(basename -- "$folder")" == "release" ]] && echo "10s" || echo "13s")"

    name_display="$(printf "%-$spaces %s" "$dirname")"$'\t'"${jira_title}";
  fi

  # evaluate this
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

  if ! command -v npx &>/dev/null; then
    print " fatal: npx is not installed" >&2
    print " run: ${hi_yellow_cor}sudo npm install -g npx${reset_cor} to install npx" >&2
    return 1;
  fi
  
  local port=""

  eval "$(parse_args_ "$0" "port:n" "$@")"
  shift $arg_count

  local yes=""

  local npx_version="$(npx --version 2>/dev/null)"
  if [[ "$npx_version" =~ ^([0-9]+)(\.[0-9]+)*$ ]]; then
    local npx_major="${npx_version%%.*}"
    if (( npx_major >= 7 )); then
      yes="--yes"
    fi
  fi

  npx $yes kill-port "$port"
}

function refresh() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"
  #(( refresh_is_debug )) && set -x # do not turn on for refresh

  if (( refresh_is_h )); then
    print "  ${hi_yellow_cor}refresh${reset_cor} : runs 'zsh'"
    return 0;
  fi

  zsh -l
}

function hg() {
  set +x
  eval "$(parse_flags_ "$0" "" "" "$@")"

  if (( hg_is_h )); then
    print "  ${hi_yellow_cor}hg ${yellow_cor}[<search_text>]${reset_cor} : history | grep text"
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
    npm list --global "$@"
  fi
}

# ========================================================================

# general settings
typeset -g PUMP_SKIP_DETECT_NODE
typeset -g PUMP_CODE_EDITOR
typeset -g PUMP_MERGE_TOOL
typeset -g PUMP_PUSH_NO_VERIFY
typeset -g PUMP_RUN_OPEN_COV
typeset -g PUMP_USE_MONOGRAM
typeset -g PUMP_INTERVAL
typeset -g PUMP_JIRA_ALERT

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
typeset -gA PUMP_RUN_QA
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
typeset -gA PUMP_JIRA_READY_FOR_TEST
typeset -gA PUMP_JIRA_ALMOST_DONE
typeset -gA PUMP_JIRA_DONE
typeset -gA PUMP_JIRA_CANCELED
typeset -gA PUMP_JIRA_BLOCKED
typeset -gA PUMP_JIRA_WORK_TYPES
typeset -gA PUMP_NVM_USE_V
typeset -gA PUMP_SCRIPT_FOLDER
typeset -gA PUMP_GHA_DEPLOY
typeset -gA PUMP_GO_BACK
typeset -gA PUMP_VERSION_WEB
typeset -gA PUMP_VERSION_CMD

# ========================================================================

export CURRENT_PUMP_SHORT_NAME=""

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
typeset -g CURRENT_PUMP_RUN_QA=""
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
typeset -g CURRENT_PUMP_JIRA_BLOCKED=""
typeset -g CURRENT_PUMP_NVM_USE_V=""
typeset -g CURRENT_PUMP_SCRIPT_FOLDER=""
typeset -g CURRENT_PUMP_GHA_DEPLOY=""
typeset -g CURRENT_PUMP_GO_BACK=""
typeset -g CURRENT_PUMP_WEB_URL=""

typeset -g PUMP_PAST_FOLDER=""
typeset -g PUMP_PAST_BRANCH=""

typeset -g TEMP_PUMP_SHORT_NAME=""
typeset -g TEMP_PUMP_FOLDER=""
typeset -g TEMP_PUMP_REPO=""
typeset -g TEMP_PUMP_SINGLE_MODE=""
typeset -g TEMP_PUMP_PKG_MANAGER=""

typeset -g SAVE_COR=""

typeset -gA STATUS_COLOR_MAP
typeset -gA GHA_COLOR_MAP
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

# pwd - fired every time the PWD changes, even if its the same folder, and also on terminal open
function set_current_proj_pwd_() {
  set_current_proj_ 0 # set to default values

  if is_folder_pkg_ "$PWD" &>/dev/null; then
    CURRENT_PUMP_NVM_USE_V="$(detect_node_version_ 0 "" "$PWD")"
    local RET=$?

    nvm_use_ 0 "$CURRENT_PUMP_NVM_USE_V" "$CURRENT_PUMP_PKG_MANAGER" 2>/dev/tty

    if (( RET == 2 )); then
      if [[ -z "$PUMP_SKIP_DETECT_NODE" ]]; then
        confirm_ "do you want to skip auto detecting node versions for every project?" "skip" "continue" "continue"
        local _RET=$?

        if (( _RET == 0 )); then
          update_setting_ "PUMP_SKIP_DETECT_NODE" 1
          print " run: ${hi_yellow_cor}pro -a${reset_cor} to add this project" >&2
        elif (( _RET == 1 )); then
          update_setting_ "PUMP_SKIP_DETECT_NODE" 0
        fi
      fi
    fi
  else
    # fix the default node version in nvm
    if ! command -v nvm &>/dev/null; then return 1; fi
    if ! command -v node &>/dev/null; then
      nvm use node #&>/dev/tty || true
      nvm alias default node #&>/dev/tty || true
    fi
  fi

  git fetch --all --prune --quiet &>/dev/null || true
}

# cd pro pwd
function pump_chpwd_() {
  set +x
  rm -rf -- "$PWD/.DS_Store" &>/dev/null || true

  local proj="$(find_proj_by_folder_ 2>/dev/null)"

  if [[ -n "$proj" ]]; then
    pro -x "$proj"
    return $?;
  fi

  set_current_proj_pwd_
}

function ansi_to_gum() {
  local ansi="$1"
  local num

  # 256-color: $'\e[38;5;<n>m' or $'\e[0;38;5;<n>m' or $'\e[1;38;5;<n>m'
  if [[ "$ansi" =~ $'\e'"\\[([0-9]+;)*38;5;([0-9]+)m" ]]; then
    # extract <n> (match[2] because match[1] is the optional leading group)
    num="${match[2]}"

  # Classic 8-color: $'\e[0;3Xm' or $'\e[3Xm'
  elif [[ "$ansi" =~ $'\e'"\\[([0-9;]*)m" ]]; then
    # remove non-digits, take last 2 digits
    local digits="${match[1]//[!0-9]/}"
    local fg="${digits: -2}"
    num=$(( fg - 30 ))  # 0–7
  else
    num=0
  fi

  echo "$num"
}

load_project_config_
load_global_settings_

local i=0
for i in {1..9}; do
  if [[ -n "${PUMP_SHORT_NAME[$i]}" ]]; then
    local func_name="${PUMP_SHORT_NAME[$i]}"
    functions[$func_name]="proj_handler $i \"\$@\";"
  fi
done

pro_pwd_ 2>/dev/tty
add-zsh-hook chpwd pump_chpwd_ &>/dev/null

if [[ "$(date +%u)" == "$PUMP_UPDATE_DAY" ]]; then upgrade_; fi
# ==========================================================================
# 1>/dev/null or >/dev/null   Hide stdout, show stderr
# 2>/dev/null                 show stdout, hide stderr
# &>/dev/null                 Hide both stdout and stderr outputs
# ✓
# ✗
