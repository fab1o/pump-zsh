# Pump-zsh

**Pump-zsh** is an unofficial "Oh My Zsh" plugin that provides a configurable set of aliases, functions, and themes to supercharge your terminal workflow.

MacOS or Linux only (not tested on Linux however).

## Requirements

Install [Oh My Zsh](https://ohmyz.sh/)

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/fab1o/pump-zsh/refs/heads/main/scripts/install.zsh | zsh && zsh
```

After installation, to get started with Pump-zsh, run:

```sh
help
```

## Dependencies

On MacOS, install [Homebrew](https://brew.sh/)

|          | MacOS                                                            | Linux                                                                                     |
| -------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **jq**   | <pre>brew install jq</pre>                                       | [jqlang.org](https://jqlang.org/download)                                                 |
| **gum**  | <pre>brew install gum</pre>                                      | [charmbracelet](https://github.com/charmbracelet/gum#installation)                        |
| **gh**   | <pre>brew install gh</pre>                                       | [github.com/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)             |
| **acli** | <pre>brew tap atlassian/homebrew-acli<br>brew install acli</pre> | [developer.atlassian.com](https://developer.atlassian.com/cloud/acli/guides/install-acli) |

## Also Recommend Install

- [nvm](https://github.com/nvm-sh/nvm#installing-and-updating) — allows you to quickly install and use different versions of Node.js
- [iTerm2](https://iterm2.com/) — a better Terminal app
- [Gruvbox iTerm2 color palette](https://github.com/herrbischoff/iterm2-gruvbox) — for a better Terminal appearance

## Themes

In addition, Pump-zsh includes a collection of [built-in themes](https://github.com/fab1o/pump-zsh/wiki/Themes).

It also exports an environment variable called `CURRENT_PUMP_SHORT_NAME`, which represents the currently selected project. This can be used to customize your own theme.

- Install [Oh My Posh](https://ohmyposh.dev/)
- Install [Nerd Fonts](https://ohmyposh.dev/docs/installation/fonts)

## Help

See [Wiki](https://github.com/fab1o/pump-zsh/wiki) for more information.
