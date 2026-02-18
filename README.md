# Pump-zsh

**Pump-zsh** is an unofficial 'Oh My Zsh' plugin that provides a configurable set of aliases, functions, and themes to supercharge your terminal workflow.

See [Wiki](https://github.com/fab1o/pump-zsh/wiki) for more information.

## Installation

The recommended way to install Pump-zsh is via the provided install script:

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh
```

## Themes

In addition, Pump-zsh includes a collection of [built-in themes](https://github.com/fab1o/pump-zsh/wiki/Themes).

It also exports an environment variable called `CURRENT_PUMP_SHORT_NAME`, which represents the currently selected project. This can be used to customize your own theme.

## Dependencies

Pump-zsh includes a helper script to install all required dependencies. This script relies on [Homebrew](https://brew.sh/).

Once Homebrew is installed, run the following:

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install_deps.zsh | zsh && zsh
```

### Manual Installation

If you prefer to install dependencies manually, refer to the lists below:

#### Mandatory

* [Oh My Zsh](https://ohmyz.sh/)

#### Required

* [jq](https://jqlang.org/) — for configuration management
* [gum](https://github.com/charmbracelet/gum) — improves interactive user experience
* [glow](https://github.com/charmbracelet/glow) — for markdown rendering
* [GitHub CLI](https://cli.github.com/) — used in commands: `gha`, `pr`, `release`, `rev`, and others

#### Recommended (not installed by the script)

* [nvm](https://github.com/nvm-sh/nvm) — allows you to quickly install and use different versions of Node.js
* [iTerm2](https://iterm2.com/) — a better Terminal app
* [Gruvbox iTerm2 color palette](https://github.com/herrbischoff/iterm2-gruvbox) — for a better Terminal appearance

#### Optional (not installed by the script)

* [Oh My Posh](https://ohmyposh.dev/) — works best with [Nerd Fonts](https://ohmyposh.dev/docs/installation/fonts)

## Documentation and Support

Refer to the [Pump-zsh Wiki](https://github.com/fab1o/pump-zsh/wiki/Home) for detailed guides, configuration tips, and advanced usage.

To see available commands and help options, run in your Terminal:

```sh
help
```
