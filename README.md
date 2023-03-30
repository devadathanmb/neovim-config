# My neovim configs

This repository contains my personal neovim configs.  
  
Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

---

## Preview
![2023-01-03_17-47](https://user-images.githubusercontent.com/84301852/210356013-16e12f92-42b3-4c3a-bbbd-ac57c0126dcc.png)


![2023-01-03_17-48](https://user-images.githubusercontent.com/84301852/210356032-26b1d20a-c469-44c8-9e03-39565ac281de.png)


![2023-01-03_17-48_1](https://user-images.githubusercontent.com/84301852/210356037-502f58ff-e894-449b-a16e-15dc0da1bcfb.png)

---

## Quick setup
1. Make sure `neovim` version `0.7` or greater is installed by using `nvim --version`.  

2. Backup your current `neovim` configurations using  
```bash
mkdir ~/.config/nvimbackup
mv ~/.config/nvim ~/.config/nvimbackup
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
