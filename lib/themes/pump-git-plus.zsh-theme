## .copy and paste into your .zshrc file just before line "source $ZSH/oh-my-zsh.sh"
## and uncomment the lines below
# ZSH_THEME=pump-git-plus
# PROMPT=➜
# plugins=(git-prompt pump)

PROMPT="%(?:%{$fg_bold[green]%}%1{$PROMPT%}:%{$fg_bold[red]%}%1{$PROMPT%}) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' %{$fg[blue]%}$CURRENT_PUMP_SHORT_NAME⟣%{$reset_color%}$(git_super_status) ' 

ZSH_THEME_GIT_PROMPT_SEPARATOR="%{$fg_bold[blue]%}|%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[blue]%}"
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}:(%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_bold[blue]%})%{$reset_color%}"
# ZSH_THEME_GIT_PROMPT_CACHE=1

RPROMPT='%B%F${PUMP_TIME_TOOK}%f%b'
