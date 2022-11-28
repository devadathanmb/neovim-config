# Neovim config

This repository contains my personal neovim configs.  
Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

---

## Preview

![Screenshot from 2022-11-28 12-14-46](https://user-images.githubusercontent.com/84301852/204218379-8847fb06-9767-48d7-9d9a-800d0da7ae35.png)  

![Screenshot from 2022-11-28 12-16-50](https://user-images.githubusercontent.com/84301852/204218394-71cb4a04-fef0-4f01-82c0-9da22880530a.png)  

![Screenshot from 2022-11-28 12-19-29](https://user-images.githubusercontent.com/84301852/204218404-7e7c7b70-bb0e-4b81-a090-6a36b84d880d.png)  

![Screenshot from 2022-11-28 12-21-23](https://user-images.githubusercontent.com/84301852/204218411-2ea440de-1610-4abb-9652-7c2858d193ca.png)  

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
git clone https://www.github.com/devadathanmb/entevim ~/.config/nvim
```

## Uninstallation and cleanup
```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
```
