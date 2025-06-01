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

To enable the pump theme with Git prompt enhancements:

1. Set the theme in your `~/.zshrc`:

   ```zsh
   ZSH_THEME="pump"
   ```

2. Add `pump` and `git-prompt` to your list of plugins:

   ```zsh
   plugins=(git-prompt pump)
   ```

---

### 3. Pump Hybrid (Oh My Zsh Theme)

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

To use Pump with **Oh My Posh**:

1. Add the following to your `~/.zshrc`:

   ```zsh
   if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
     eval "$(oh-my-posh init zsh --config $ZSH/plugins/pump/pump.omp.json)"
   fi
   ```

2. Add `pump` (and optionally `git-prompt`) to your plugins:

   ```zsh
   plugins=(git-prompt pump)
   ```

---

### 4. Customize Your Own Theme

Pump-zsh exports an environment variable called:

```sh
PUMP_PROJECT
```

This indicates the currently selected project and can be used in your prompt customization.

To build your own theme:

* Explore how Pump's [built-in themes](/lib/themes) use this variable.
* Adapt their logic to fit your custom style or prompt framework.

Be sure to include `pump` in your plugins list:

```zsh
plugins=(git-prompt pump)
```
