## .copy and paste into your .zshrc file just before line "source $ZSH/oh-my-zsh.sh"
## and uncomment the lines below
# ZSH_THEME=pump-git
# PROMPT=➜
# plugins=(git-prompt pump)

function pump_git_super_status() {
  precmd_update_git_vars
  
  if [[ -n "$__CURRENT_GIT_STATUS" ]]; then
    local COLOR="$ZSH_THEME_GIT_PROMPT_CLEAN"
    local SYMBOL="✗"
    local PUMP_PROJ=""

    if [[ "$GIT_BEHIND" -ne "0" && "$GIT_AHEAD" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_BRANCH_BEHIND_AND_AHEAD"
    elif [[ "$GIT_AHEAD" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_BRANCH_AHEAD"
    elif [[ "$GIT_BEHIND" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_BRANCH_BEHIND"
    elif [[ "$GIT_CONFLICTS" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_CONFLICTS"
    elif [[ "$GIT_STAGED" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_BRANCH_STAGED"
    elif [[ "$GIT_STAGED" -ne "0" || "$GIT_CHANGED" -ne "0" || "$GIT_DELETED" -ne "0" || "$GIT_UNTRACKED" -ne "0" ]]; then
      COLOR="$ZSH_THEME_GIT_PROMPT_BRANCH_DIRTY"
    else
      SYMBOL=":"
    fi

    if [[ -n "$CURRENT_PUMP_SHORT_NAME" ]]; then
      PUMP_PROJ="%{$fg[blue]%}$CURRENT_PUMP_SHORT_NAME⟣%{$reset_color%}"
    fi

    echo " ${PUMP_PROJ}${ZSH_THEME_GIT_PROMPT_PREFIX_COLOR}${COLOR}${SYMBOL}${ZSH_THEME_GIT_PROMPT_PREFIX}${GIT_BRANCH}${ZSH_THEME_GIT_PROMPT_SUFFIX_COLOR}${ZSH_THEME_GIT_PROMPT_SUFFIX}%{${reset_color}%}"
  fi
}

PROMPT="%(?:%{$fg_bold[green]%}%1{$PROMPT%}:%{$fg_bold[red]%}%1{$PROMPT%}) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+='$(pump_git_super_status) '

ZSH_THEME_GIT_PROMPT_PREFIX_COLOR=""
ZSH_THEME_GIT_PROMPT_SUFFIX_COLOR=""
ZSH_THEME_GIT_PROMPT_PREFIX="(" # don't enter color here
ZSH_THEME_GIT_PROMPT_SUFFIX=")" # don't enter color here

ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[blue]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_BEHIND_AND_AHEAD="%{$fg_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_AHEAD="%{$fg_bold[cyan]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_BEHIND="%{$fg_bold[magenta]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_CHANGED="%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_STAGED="%{$fg_bold[red]%}"
ZSH_THEME_GIT_PROMPT_BRANCH_DIRTY="%{$fg_bold[red]%}"

# ZSH_THEME_GIT_PROMPT_CACHE=1

RPROMPT=''
