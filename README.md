# neovim-config

My personal Neovim config, built on [lazy.nvim](https://github.com/folke/lazy.nvim).

## Requirements

- Neovim 0.12+
- `git`, [`ripgrep`](https://github.com/BurntSushi/ripgrep), [`fd`](https://github.com/sharkdp/fd)
- Node.js and Python 3
- A C compiler
- A [Nerd Font](https://www.nerdfonts.com/)
- Optional: [`gh`](https://cli.github.com/)

## Install

```sh
git clone -b v2 https://github.com/devadathanmb/neovim-config ~/.config/nvim
nvim
```

The first start installs plugins and language tools.

Keybindings are in [KEYMAPS.md](KEYMAPS.md).

## Credits

Colorscheme data from [primer/github-vscode-theme](https://github.com/primer/github-vscode-theme)
(MIT, see [theme/upstream/LICENSE.txt](theme/upstream/LICENSE.txt)). Everything else is
[GPL-3.0](LICENSE).
