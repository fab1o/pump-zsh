# Pump-zsh

## Themes

1. [pump oh-my-zsh theme]()
2. [pump-git-prompt oh-my-zsh theme]()
3. [pump oh-my-posh theme]()

### pump oh-my-zsh theme

To set this theme, update the following in your `~/.zshrc` file:
```sh
ZSH_THEME="pump"
```

And add pump to the list of plugins in your `~/.zshrc` file:
```sh
plugins=(pump)
```

### pump-git-prompt oh-my-zsh theme

To set this theme, update the following in your `~/.zshrc` file:
```sh
ZSH_THEME="pump"
```

And add git-prompt and pump to the list of plugins in your `~/.zshrc` file:
```sh
plugins=(git-prompt pump)
```

### pump oh-my-posh theme

To set **Oh My Posh** theme to pump, add the following to your `~/.zshrc` file:
```sh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
   eval "$(oh-my-posh init zsh --config $ZSH/plugins/pump/pump.omp.json)"
fi
```

And add pump to the list of plugins in your `~/.zshrc` file:
```sh
plugins=(git-prompt pump)
```

### Customize Your Own Theme

Pump-zsh exports an environment variable called `PUMP_PROJECT`, which represents the currently selected project.

You can use this variable to customize your own theme. To see how this works in practice, take a look at how Pump’s [built-in themes](/lib/themes) implement this feature, you can adapt a similar approach in your own theme.

Make sure pump is added to the list of plugins in your `~/.zshrc` file:
```sh
plugins=(git-prompt pump)
```
