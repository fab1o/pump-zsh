# Pump-zsh

Pump-zsh provides lightweight, customizable themes for Zsh — including options for **Oh My Zsh** and **Oh My Posh**.

---

## Available Themes

1. [Pump (Oh My Zsh)](#1-pump-oh-my-zsh-theme)
2. [Pump Git Prompt (Oh My Zsh)](#2-pump-git-prompt-oh-my-zsh-theme)
3. [Pump Hybrid (Oh My Zsh)](#3-pump-hybrid-oh-my-zsh-theme)
4. [Pump (Oh My Posh)](#4-pump-oh-my-posh-theme)
5. [Customize Your Own Theme](#5-customize-your-own-theme)

---

### 1. Pump (Oh My Zsh Theme)

![pump](https://github.com/fab1o/pump-zsh/blob/main/assets/pump.png?raw=true)

To enable this theme:

1. Set the theme in your `~/.zshrc`:

   ```zsh
   ZSH_THEME="pump"
   ```

2. Add `pump` to your list of plugins:

   ```zsh
   plugins=(pump)
   ```

---

### 2. Pump Git Prompt (Oh My Zsh Theme)

![pump-git-prompt](https://github.com/fab1o/pump-zsh/blob/main/assets/pump-git-prompt.png?raw=true)

To enable the pump theme with Git prompt enhancements:

1. Set the theme in your `~/.zshrc`:

   ```zsh
   ZSH_THEME="pump-git-prompt"
   ```

2. Add `pump` and `git-prompt` to your list of plugins:

   ```zsh
   plugins=(git-prompt pump)
   ```

---

### 3. Pump Hybrid (Oh My Zsh Theme)

![pump-hybrid](https://github.com/fab1o/pump-zsh/blob/main/assets/pump-hybrid.png?raw=true)

To enable the pump theme with Git prompt enhancements:

1. Set the theme in your `~/.zshrc`:

   ```zsh
   ZSH_THEME="pump-hybrid"
   ```

2. Add `pump` and `git-prompt` to your list of plugins:

   ```zsh
   plugins=(git-prompt pump)
   ```

---

### 4. Pump (Oh My Posh Theme)

![pump-posh](https://github.com/fab1o/pump-zsh/blob/main/assets/pump-posh.png?raw=true)

To use Pump with **Oh My Posh**:

1. Add the following to your `~/.zshrc`:

   ```zsh
   if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
     eval "$(oh-my-posh init zsh --config $ZSH/plugins/pump/pump.omp.json)"
   fi
   ```

2. Add `pump` to your plugins:

   ```zsh
   plugins=(pump)
   ```

---

### 4. Customize Your Own Theme

Pump-zsh exports environment variables that can be used in your prompt customization:

```sh
CURRENT_PUMP_SHORT_NAME # indicates the current set project
PUMP_TIME_TOOK # time took to run last command
```

To build your own theme:

* Explore how Pump's [built-in themes](/lib/themes) use these variables.
* Adapt the logic to fit your custom style or prompt framework.

Be sure to include `pump` in your plugins list:

```zsh
plugins=(pump)
```
