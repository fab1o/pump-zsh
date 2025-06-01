# Pump-zsh

## Themes

To set **Oh My Zsh** theme to pump, update the following in your `~/.zshrc` file:
```sh
ZSH_THEME="pump"
```

To set **Oh My Posh** theme to pump, add the following to your `~/.zshrc` file:
```sh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
   eval "$(oh-my-posh init zsh --config $ZSH/plugins/pump/pump.omp.json)"
fi
```

### Customize Your Own Theme

Pump exports an environment variable called `PUMP_PROJECT`, which represents the currently selected project.

You can use this variable to customize your own theme. To see how this works in practice, take a look at how Pump’s [built-in themes](/lib/themes) implement this feature, you can adapt a similar approach in your own theme.
