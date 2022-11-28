# Neovim config

This repository contains my personal neovim configs.  
Heavily inspired from [Neovim from scratch series](link) by [Christian ](link) and [lunar](vim).

---

## Screenshots


---

## Quick setup
1. Make sure `neovim` version `0.7` or greater is installed by using `nvim --version`.  

2. Backup your current `neovim` configurations using  
```bash
mkdir ~/.config/nvimbackup
mv ~/.config/nvim ~/.config/nvimbackup
```
3. Check the health status of neovim using  
Open `neovim` and enter the following commands  
`:checkhealth`.  
- If you find that you do not support for copy/paste make sure to install `xsel` for X11 users and `wl-clipboard` for Wayland users. 
- If python and node has not been setup for neovim, then do  
```bash
pip install neovim # For python
npm install -g neovim # For node
```
4. Clone the repository and run neovim
```bash
git clone <url> ~/.config/nvim
```

## Uninstallation and cleanup
```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
```