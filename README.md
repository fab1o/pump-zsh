# Pump-zsh

Pump-zsh is an **Oh My Zsh** plugin with a configurable set of aliases and functions to **supercharge your terminal experience** — plus a custom **Oh My Posh** theme for added style and clarity.

![screenshot](https://github.com/fab1o/pump-zsh/blob/main/docs/prompt-shot.png?raw=true)

---

## Installation

Pump-zsh comes with its own install script, which is the recommended method of install.

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh
```
---

## 📦 Install Dependencies

Pump-zsh comes with a script to install all the dependencies, but it requires [Homebrew](https://brew.sh/) to run:

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install_deps.zsh | zsh && zsh
```

If you prefer to install them manually, here’s the list:

- ✅ **Required**:
  - [Oh My Zsh](https://ohmyz.sh/)
  - [jq](https://jqlang.org/)
- 🌟 **Recommended**:
  - [Oh My Posh](https://ohmyposh.dev/)  
    → Works best with [Nerd Fonts](https://ohmyposh.dev/docs/installation/fonts)
  - [gum](https://github.com/charmbracelet/gum) – for enhanced UX
  - [glow](https://github.com/charmbracelet/glow) – for enhanced UX
  - [Github CLI](https://cli.github.com/) – for some functions such as `pr`
- 🎨 **Optional**:
  - [iTerm2](https://iterm2.com/)
  - [Gruvbox iTerm2 palette](https://github.com/herrbischoff/iterm2-gruvbox) — customize terminal colors

---

## 📖 Documentation

Explore the full documentation to make the most out of `pump-zsh`:

- [Wiki](https://github.com/fab1o/pump-zsh/wiki/Home)

For additional help, run on your terminal:

```sh
help
```
