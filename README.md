# Pump-zsh

It's a 3 in 1:

- an **Oh My Zsh** plugin & theme
- and an **Oh My Posh** theme

with a configurable set of aliases and functions to **supercharge your terminal experience**

Oh My Posh screenhsot:
![screenshot](https://github.com/fab1o/pump-zsh/blob/main/docs/prompt-shot.png?raw=true)

## Install

Pump-zsh plugin comes with its own install script, which is the recommended method of install:

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh
```

## Dependencies

Pump-zsh comes with a script to install all the dependencies, but it requires [Homebrew](https://brew.sh/).

Run the script below once you have Homebrew:

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install_deps.zsh | zsh && zsh
```

If you prefer to install dependencies manually, here’s the list:

- **Mandatory**:
  - [Oh My Zsh](https://ohmyz.sh/)
- **Required**:
  - [Oh My Posh](https://ohmyposh.dev/)  
    → Works best with [Nerd Fonts](https://ohmyposh.dev/docs/installation/fonts)
  - [jq](https://jqlang.org/) - for config crud
  - [gum](https://github.com/charmbracelet/gum) – for enhanced UX
  - [glow](https://github.com/charmbracelet/glow) – for enhanced UX
  - [Github CLI](https://cli.github.com/) – for some functions such as `pr`

- **Recommended (not installed by the script)**:
  - [iTerm2](https://iterm2.com/)
  - [Gruvbox iTerm2 palette](https://github.com/herrbischoff/iterm2-gruvbox) — customize terminal colors

---

## Themes

To set **Oh My Zsh** theme to pump, set the following in your ~/.zshrc file:
```sh
ZSH_THEME="pump"
```

To set **Oh My Posh** theme to pump, add the following to your `~/.zshrc` file:
```sh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
   eval "$(oh-my-posh init zsh --config $HOME/.oh-my-zsh/plugins/pump/pump.omp.json)"
fi
```

### Customize Your Own Theme

Pump exports an environment variable called `PUMP_PROJECT`, which represents the currently selected project.

You can use this variable to customize your own theme. To see how this works in practice, take a look at how Pump’s built-in themes implement this feature, you can adapt a similar approach in your own theme.

---

## Support

Explore the full documentation to make the most out of `pump-zsh`:

- [Wiki](https://github.com/fab1o/pump-zsh/wiki/Home)

For additional help, run on your terminal:

```sh
help
```
