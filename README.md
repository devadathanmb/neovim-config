# My neovim configs

This repository contains my personal neovim configs.  
  
Heavily inspired from [Neovim from scratch series](https://www.youtube.com/playlist?list=PLhoH5vyxr6Qq41NFL4GvhFp-WLd5xzIzZ) by [Christian Chiarulli](https://github.com/ChristianChiarulli) and [Lunar Vim](https://github.com/LunarVim).

---

## Preview
![2023-05-10-T-22-19-01](https://github.com/devadathanmb/entevim/assets/84301852/f77e1006-d46a-4350-9532-203ceeef8108)


![2023-05-10-T-22-23-23](https://github.com/devadathanmb/entevim/assets/84301852/c94fba6d-6608-4fef-8b92-cf514eb2ddd7)

![2023-05-10-T-22-24-21](https://github.com/devadathanmb/entevim/assets/84301852/5979e00e-9069-4302-9c8d-10d432312e1f)

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
