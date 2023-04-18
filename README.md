# My neovim configs

This repository contains my personal neovim configs.  
  
Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

---

## Preview
![2023-04-18T17:33:23,361288256+05:30](https://user-images.githubusercontent.com/84301852/232771466-a1c2ed18-6b19-4fb1-be58-23aec7099450.png)

![2023-04-18T17:27:57,554177303+05:30](https://user-images.githubusercontent.com/84301852/232771527-b4f15aeb-1abc-414d-b7ec-0cce3c64556b.png)

![2023-04-18T17:28:26,947123597+05:30](https://user-images.githubusercontent.com/84301852/232771565-10780815-ff7c-45c9-bfdb-e2654b1431ca.png)

![2023-04-18T17:28:48,451955406+05:30](https://user-images.githubusercontent.com/84301852/232771573-9a0ca623-734b-4ed6-8366-b5493e9a99d7.png)

---

## Quick setup
1. Make sure `neovim` version `0.8` or greater is installed by using `nvim --version`.  

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
