# My neovim configs

This repository contains my personal neovim configs.

Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

**NOTE : These configs now use the latest and greatest [LazyNvim](https://github.com/folke/lazy.nvim)**

---

## Preview

![Home](https://i.imgur.com/1vV7QdD.png)

![First](https://i.imgur.com/M3tI3cw.png)

![Second](https://i.imgur.com/CKFAcxi.png)

![Third](https://i.imgur.com/7YxQS07.png)

---

## Quick setup

1. Make sure `neovim` version `0.9` or greater is installed by using `nvim --version`.

2. Backup your current `neovim` configurations using

```bash
mkdir ~/.config/nvimbackup
mv ~/.config/nvim ~/.config/nvimbackup
rm -rf ~/.local/share/nvim ~/.cache/nvim # This gets rid of all your before installed plugins
```

3. Check the health status of neovim using

- Open `neovim` and enter the command `:checkhealth`.
- If you find that you do not support for copy/paste make sure to install `xsel` for X11 users and `wl-clipboard` for Wayland users.
- If python and node has not been setup for neovim, then do

```bash
pip install neovim # For python
npm install -g neovim # For node
```

4. Clone the repository and run neovim

```bash
git clone https://github.com/devadathanmb/entevim.git ~/.config/nvim
```

## Uninstallation and cleanup

```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
```
