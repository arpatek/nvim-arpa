# nvim-arpa

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│          ___ ________  ___ _/ /____ / /__                    │
│         / _ `/ __/ _ \/ _ `/ __/ -_)  '_/                    │
│         \_,_/_/ / .__/\_,_/\__/\__/_/\_\                     │
│                /_/                                           │
│                                                              │
│      Author: Juan Garcia (arpatek)                           │
│      Description: Neovim config built on 0.12 built-ins      │
│                   instead of the usual plugin stack.         │
└──────────────────────────────────────────────────────────────┘
```

[![built by arpatek](.assets/badge.svg)](https://arpatek.dev)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/neovim-0.12%2B-green.svg)](https://neovim.io)

**nvim-arpa** is a Neovim configuration for Linux, DevOps and automation work
— Bash, Python, Terraform, Ansible, Puppet. It runs on Neovim's own plugin
manager, LSP configuration and completion rather than the four plugins usually
layered on top of them. Eight plugins, every one of which Neovim has no
built-in answer for.

---

### Features

`[No Plugin Manager]` `vim.pack` ships with Neovim 0.12 — no lazy.nvim, and the lockfile is committed.
`[No LSP Framework]` `vim.lsp.config` plus one file per server under `lsp/` — no nvim-lspconfig.
`[No Completion Plugin]` `vim.lsp.completion` with `autotrigger` — no blink.cmp or nvim-cmp.
`[No Second Package Manager]` Language servers come from Homebrew, not Mason, so `which` can see them.
`[Vault-Aware]` Decrypted `ansible-vault` buffers get no language server, no undofile and no shada.
`[Responsive Dashboard]` Four banner sizes chosen from the window, down to a 24-column tmux split.
`[Hand-Rolled UI]` Statusline and startup screen are ~400 commented lines, not plugins.
`[yazi Explorer]` The file manager already on the system, via its `--chooser-file` contract.

---

### Requires

| | Needed for |
|---|---|
| Neovim 0.12+ | `vim.pack`, `vim.lsp.config`, `vim.lsp.completion` |
| `git` | `vim.pack` clones plugins with it |
| `tree-sitter` CLI + a C compiler | nvim-treesitter's `main` branch builds every parser from source |
| `ripgrep` | `:grep`, `grepprg`, and fzf-lua's live grep |
| `fd`, `fzf` | fzf-lua's pickers |
| `yazi` | the file explorer |
| A Nerd Font **Mono** variant | the dashboard menu aligns on single-cell glyphs |

On Homebrew that is `neovim tree-sitter-cli ripgrep fd fzf yazi`, plus
`font-jetbrains-mono-nerd-font` and the Xcode command line tools for `cc`.

Optional. Each of these degrades quietly rather than erroring:

| | Without it |
|---|---|
| `bat` | fzf-lua previews lose syntax highlighting |
| `lazygit` | `<leader>gg` opens an empty terminal |
| `tofu` or `terraform` | no HCL formatting — `terraform-ls` advertises the capability but shells out to the CLI for it |
| `python3` | `ansible-language-server` cannot resolve module paths |
| a language server | that filetype gets no diagnostics or completion |

Language servers and linters are declared in
[`dotfiles/Brewfile`](https://codeberg.org/arpatek/dotfiles): `bash-language-server`,
`pyright`, `ruff`, `terraform-ls`, `ansible-language-server`, `yaml-language-server`,
`lua-language-server`, `marksman`, `vscode-langservers-extracted`, plus `shellcheck`,
`shfmt`, `stylua`, `hadolint`, `markdownlint-cli2` and `ansible-lint`.

No language server is required. `vim.lsp.enable` starts whatever is on `PATH` and
skips what is not, so a missing one costs you diagnostics rather than a startup
error. `git` and `tree-sitter` are the exception — without them the first launch
installs nothing.

---

### Install

```sh
git clone https://codeberg.org/arpatek/nvim-arpa ~/.config/nvim
nvim
```

First launch clones eight plugins and compiles 23 treesitter parsers. Every launch
after that is about 35 ms.

To try it without disturbing an existing config, clone it elsewhere and point
`NVIM_APPNAME` at the directory name instead:

```sh
git clone https://codeberg.org/arpatek/nvim-arpa ~/.config/nvim-test
NVIM_APPNAME=nvim-test nvim
```

Note that plugins and treesitter parsers live under `stdpath('data')`, which
`NVIM_APPNAME` also changes — so a side-by-side clone fetches its own copies.

---

### Keys

Leader is `<Space>`. LSP maps are buffer-local and only exist where a server attached.

| Key | Action |
|---|---|
| `<leader><space>` | find files |
| `<leader>fg` / `<leader>fw` | grep project / word under cursor |
| `<leader>e` / `-` | yazi, at the current file |
| `<leader>cf` | format buffer or selection |
| `<leader>"` | show registers |
| `gd` / `gD` / `gy` | definition / declaration / type definition |
| `]h` / `[h` | next / previous git hunk |
| `]e` / `[e` | next / previous error |
| `<leader>up` | update plugins |

`:DashboardInfo` reports which banner the current window gets and why.

---

### Layout

```
init.lua                 entry point: timer, leader, module order
nvim-pack-lock.json      plugin revisions, committed
lsp/                     one file per language server
lua/arpatek/
├── options.lua          vim.opt, filetype detection, per-ft indent
├── vault.lua            ansible-vault hardening
├── plugins.lua          vim.pack.add + setup
├── finder.lua           fzf-lua, configured on first use
├── yazi.lua             file explorer
├── lsp.lua              enable list, diagnostics, LspAttach maps
├── lint.lua             hadolint, markdownlint-cli2
├── statusline.lua       hand-rolled
├── dashboard.lua        banner + menu
└── keymaps.lua          global maps, right-click menu
docs/
├── architecture.md      what it is and how the pieces fit
├── decisions.md         why it was built this way
├── gotchas.md           things that will trip you up
└── upgrading.md         how to safely update
```

Read [`docs/decisions.md`](docs/decisions.md) first if you want the reasoning, and
[`docs/gotchas.md`](docs/gotchas.md) before debugging anything.

---

### License

MIT — see [LICENSE](LICENSE).
