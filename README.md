# Neovim config

This repository contains my personal neovim configs.  
Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

---

## Preview
![Screenshot_2022-12-08-14-54-32_1920x1080](https://user-images.githubusercontent.com/84301852/206449394-ebcb42c7-42b3-4fc4-88d0-d5050f46f4e4.png)


![Screenshot_2022-12-08-14-56-45_1920x1080](https://user-images.githubusercontent.com/84301852/206449401-10aaf2f3-55e5-4a12-b1c9-4ef6761f5566.png)


![Screenshot_2022-12-08-14-57-14_1920x1080](https://user-images.githubusercontent.com/84301852/206449411-2f2a1d0a-0288-45a0-80a4-447c24e64d51.png)

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
