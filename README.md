# Pump-zsh

Pump-zsh is a plugin with a configurable set of aliases and functions to **supercharge your terminal experience**.

It also includes a few [themes](docs/themes.md)

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
  - [Github CLI](https://cli.github.com/) – required for some functions such as `pr`, `release`, `co`, `delb` etc...

- **Recommended (not installed by the script)**:
  - [iTerm2](https://iterm2.com/)
  - [Gruvbox iTerm2 palette](https://github.com/herrbischoff/iterm2-gruvbox) — customize terminal colors

---

## Support

Explore the full documentation to make the most out of `pump-zsh`:

- [Wiki](https://github.com/fab1o/pump-zsh/wiki/Home)

For additional help, run on your terminal:

```sh
help
```
