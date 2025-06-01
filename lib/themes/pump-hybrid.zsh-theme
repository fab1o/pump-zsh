PROMPT="%(?:%{$fg_bold[green]%}%1{➜%}:%{$fg_bold[red]%}%1{➜%}) %{$fg[cyan]%}%c%{$reset_color%} %{$fg[blue]%}$PUMP_PROJECT%{$reset_color%}"
PROMPT+=' $(git_super_status)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}) "
ZSH_THEME_GIT_PROMPT_CACHE=1

RPROMPT=''
