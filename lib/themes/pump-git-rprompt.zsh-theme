## .copy and paste into your .zshrc file just before line "source $ZSH/oh-my-zsh.sh"
## and uncomment the lines below
# ZSH_THEME=pump-git-rprompt
# PROMPT=➜
# plugins=(git-prompt pump)

PROMPT="%(?:%{$fg_bold[green]%}%1{$PROMPT%}:%{$fg_bold[red]%}%1{$PROMPT%}) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' %{$fg[blue]%}$CURRENT_PUMP_SHORT_NAME⟣%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""
# ZSH_THEME_GIT_PROMPT_CACHE=1
