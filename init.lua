-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Neovim config                                      │
-- │ Requires nvim >= 0.12: built-in plugin manager (vim.pack),   │
-- │ built-in LSP config (vim.lsp.config) and LSP completion.     │
-- └──────────────────────────────────────────────────────────────┘
--
-- Installs to ~/.config/nvim. To run it side by side with another config,
-- clone it elsewhere and set NVIM_APPNAME to that directory name.
-- Plugin lockfile lives next to this file, as nvim-pack-lock.json.

-- ──[ Startup Timer ]──────────────────────────────────────────────────────────
-- Read back by the dashboard footer. Cheap enough to always leave on, and it
-- is the number that tells you whether a new plugin was worth adding.
vim.g.arpatek_start = vim.uv.hrtime()

-- ──[ Leader ]─────────────────────────────────────────────────────────────────
-- Set before any plugin loads, or plugin keymaps bind to the old leader.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- ──[ Modules ]────────────────────────────────────────────────────────────────
-- Order matters: options before plugins (some read 'termguicolors'),
-- plugins before lsp/lint (they require plugin modules).
require('arpatek.options')
require('arpatek.vault')
require('arpatek.plugins')
require('arpatek.lsp')
require('arpatek.lint')
require('arpatek.statusline')
require('arpatek.dashboard')
require('arpatek.keymaps')
