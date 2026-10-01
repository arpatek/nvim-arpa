# Architecture

Neovim config targeting **0.12+**, built on built-ins rather than the plugin
stack a distro would pull in. Runs alongside an existing config via
`NVIM_APPNAME`.

```
~/.config/nvim-arpatek/
├── init.lua                 entry point: timer, leader, module order
├── nvim-pack-lock.json           plugin revisions, written by vim.pack
├── lsp/                     one file per language server
│   ├── ansiblels.lua        bashls.lua      jsonls.lua
│   ├── lua_ls.lua           marksman.lua    pyright.lua
│   └── ruff.lua             terraformls.lua yamlls.lua
├── lua/arpatek/
│   ├── options.lua          vim.opt, filetype detection, indent per ft
│   ├── vault.lua            ansible-vault hardening (loaded before plugins)
│   ├── plugins.lua          vim.pack.add + setup for 7 plugins
│   ├── finder.lua           fzf-lua, configured on first use
│   ├── yazi.lua             file explorer: float + yazi --chooser-file
│   ├── lsp.lua              enable list, diagnostics, LspAttach keymaps
│   ├── lint.lua             hadolint, markdownlint-cli2
│   ├── statusline.lua       hand-rolled, no lualine
│   ├── dashboard.lua        ARPATEK banner + snacks-style menu, no plugin
│   └── keymaps.lua          global maps, right-click PopUp menu
└── docs/
```

## What comes from Neovim rather than a plugin

| Capability | Provider | Replaces |
|---|---|---|
| Plugin management | `vim.pack.add` | lazy.nvim |
| Server config | `vim.lsp.config` + `lsp/*.lua` | nvim-lspconfig |
| Completion | `vim.lsp.completion` `autotrigger` | blink.cmp, nvim-cmp |
| Server install | Homebrew via `Brewfile` | mason.nvim |
| Diagnostics UI | `vim.diagnostic` | trouble.nvim |
| Project grep | `:grep` with `grepprg=rg` | part of telescope |
| Folds, indent | `vim.treesitter.foldexpr` | nvim-treesitter modules |
| File explorer | `yazi.lua`, 100 lines, wraps `yazi` | neo-tree, oil, snacks.explorer |
| Startup screen | `dashboard.lua`, 447 lines | snacks.dashboard, alpha |
| Statusline | `statusline.lua`, 140 lines | lualine.nvim |
| Keymap discovery | `<leader>fk` (fzf-lua keymaps) | which-key.nvim |
| Right-click menu | `:anoremenu PopUp.*` | — |

## The seven plugins

Each is present because Neovim has no built-in equivalent.

| Plugin | Why it cannot be dropped |
|---|---|
| nvim-treesitter | Parsers are not shipped with Neovim |
| nvim-treesitter-context | Sticky header for the enclosing block |
| fzf-lua | Live-preview fuzzy finding; `:find` has no preview |
| mini.icons | Icon provider fzf-lua's pickers expect |
| conform.nvim | Runs shfmt/ruff/stylua, not just the LSP formatter |
| nvim-lint | Runs hadolint/markdownlint as diagnostics |
| gitsigns.nvim | Hunk signs, staging, blame |

Catppuccin is an eighth entry in `vim.pack.add` but is a colorscheme, not
behavior. The file explorer is not in this table because it is not a plugin:
`yazi` is a Brewfile entry and `lua/arpatek/yazi.lua` is the glue.

## Layout modes

The banner is fixed-width ASCII that cannot shrink, so the dashboard picks one
of three layouts from the window size and re-renders on `VimResized`.

| Banner | Needs | Art |
|---|---|---|
| `big` | 79 cols, 19 rows | 79x7 block, plus the subtitle |
| `small` | 35 cols, 15 rows | 33x5 block |
| `text` | 15 cols, 11 rows | `A R P A T E K` |
| `none` | anything smaller | menu only |

Widths are measured from the art with `nvim_strwidth`, not hardcoded. The
footer is added independently whenever two rows are left over. The gradient's
seven stops are stretched across whatever row count the chosen art has, hitting
both ends. `:DashboardInfo` prints the decision for the current window.

Window height, not terminal height: a global statusline and the cmdline cost
two rows, so an 80x24 terminal is a 80x22 window.

## Load order

`options` → `vault` → `plugins` → `lsp` → `lint` → `statusline` →
`dashboard` → `keymaps`.

`vault` runs before `plugins` so its filetype rules are registered before
anything reads a buffer. `keymaps` runs last because it requires both `finder`
and `yazi`.
