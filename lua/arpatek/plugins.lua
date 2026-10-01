-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Plugins                                            │
-- │ Managed by vim.pack (built in since nvim 0.12). No lazy.nvim.│
-- └──────────────────────────────────────────────────────────────┘
--
-- vim.pack clones missing plugins synchronously on first start, so the first
-- launch is slow and every launch after it is not.
--
--   :lua vim.pack.update()              update all, review the diff, confirm
--   :lua vim.pack.update(nil, { offline = true })   list what is installed
--
-- Versions are recorded in nvim-pack-lock.json next to this config. Commit it.
--
-- Eight plugins. Each one is here because nvim 0.12 has no built-in answer:
--   treesitter          parsers are not shipped with nvim
--   treesitter-context  sticky header showing the enclosing block
--   fzf-lua             live-preview fuzzy finding over rg
--   mini.icons          filetype icons for fzf-lua's pickers
--   conform.nvim        run shfmt/ruff/stylua, not just the LSP formatter
--   nvim-lint           run hadolint/tflint/markdownlint as diagnostics
--   gitsigns.nvim       hunk signs, staging, blame
--   catppuccin          theme, matching tmux and lazygit

vim.pack.add({
    { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
    -- 'main' is the rewritten branch: parser installs only, highlighting is
    -- handed back to core via vim.treesitter.start(). Pinned explicitly
    -- because the repo default branch is still the old implementation.
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
    { src = 'https://github.com/ibhagwan/fzf-lua' },
    { src = 'https://github.com/nvim-mini/mini.icons' },
    { src = 'https://github.com/stevearc/conform.nvim' },
    { src = 'https://github.com/mfussenegger/nvim-lint' },
    { src = 'https://github.com/lewis6991/gitsigns.nvim' },
})

-- ──[ Theme ]──────────────────────────────────────────────────────────────────
-- Mocha, to match .config/lazygit/config.yml and the tmux status line.
require('catppuccin').setup({
    flavour = 'mocha',
    background = { dark = 'mocha' },
    integrations = {
        gitsigns = true,
        treesitter = true,
        treesitter_context = true,
        fzf = true,
        native_lsp = { enabled = true, virtual_text = { errors = { 'italic' } } },
    },
})
vim.cmd.colorscheme('catppuccin')

-- ──[ Treesitter ]─────────────────────────────────────────────────────────────
-- Parsers for what actually lives in ~/Git. sql is here for highlighting only;
-- there is no sql language server configured.
local parsers = {
    'bash', 'python', 'lua', 'luadoc',              -- the daily three
    'hcl', 'terraform',                             -- terraform-xo
    'yaml', 'json', 'toml',                          -- arpa-iac, configs
    'dockerfile',                                   -- arpatek.dev, home.arpa
    'puppet',                                       -- puppet-modules
    'markdown', 'markdown_inline',                  -- docs, vault
    'ssh_config',                                   -- dotfiles
    'sql',                                          -- highlighting only
    'diff', 'gitcommit', 'gitignore',               -- git buffers
    'vim', 'vimdoc', 'query',                       -- editing this config
    'regex', 'printf',                              -- injected into bash
}

local ts = require('nvim-treesitter')
local installed = {}
for _, p in ipairs(ts.get_installed()) do
    installed[p] = true
end
local missing = vim.tbl_filter(function(p)
    return not installed[p]
end, parsers)
if #missing > 0 then
    ts.install(missing)
end

-- On the 'main' branch nothing enables highlighting for you. This is the line
-- that turns it on, and it is worth knowing where it lives.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('arpatek.treesitter', { clear = true }),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if lang and installed[lang] then
            pcall(vim.treesitter.start, ev.buf, lang)
            -- Treesitter-aware folds and indent, also core features.
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})
vim.opt.foldlevel = 99          -- folds exist but start open

require('treesitter-context').setup({
    max_lines = 3,              -- unbounded context eats the window on deeply
                                -- nested Ansible YAML
    trim_scope = 'outer',
})

-- ──[ Finder ]─────────────────────────────────────────────────────────────────
-- Deliberately NOT set up here. fzf-lua's setup() is ~14ms and is only needed
-- once a picker is opened, so it lives behind arpatek.finder instead.

-- ──[ Icons ]──────────────────────────────────────────────────────────────────
-- Only here because fzf-lua's health check asks for an icon provider and a
-- picker with no icons reads as broken. mini.icons over nvim-web-devicons
-- because it needs no patched-font detection at startup.
require('mini.icons').setup()
-- fzf-lua looks for nvim-web-devicons by name; this makes mini.icons answer.
MiniIcons.mock_nvim_web_devicons()

-- ──[ File Explorer ]──────────────────────────────────────────────────────────
-- yazi, via arpatek.yazi. No plugin: yazi is already a Brewfile entry and its
-- --chooser-file contract is the whole integration.

-- ──[ Formatting ]─────────────────────────────────────────────────────────────
-- HCL formatting needs a terraform or tofu binary, and neither is installed
-- on every box this config runs on. Listing a missing formatter makes conform
-- report "Formatters unavailable" instead of falling back, so the entry is
-- only added when the binary is actually there. tofu first: it is the MPL
-- fork, and `tofu fmt` is command-compatible with `terraform fmt`.
local hcl_fmt = nil
if vim.fn.executable('tofu') == 1 then
    hcl_fmt = { 'tofu_fmt' }
elseif vim.fn.executable('terraform') == 1 then
    hcl_fmt = { 'terraform_fmt' }
end

require('conform').setup({
    formatters_by_ft = {
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        python = { 'ruff_format' },
        lua = { 'stylua' },
        -- nil here means conform skips the filetype and lsp_format='fallback'
        -- hands it to terraform-ls, which formats without the CLI.
        terraform = hcl_fmt,
        hcl = hcl_fmt,
    },
    formatters = {
        -- Match the shell style already in dotfiles: 4-space indent, and
        -- indent the bodies of case statements.
        shfmt = { prepend_args = { '-i', '4', '-ci' } },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = 'fallback' },
})

-- ──[ Git ]────────────────────────────────────────────────────────────────────
require('gitsigns').setup({
    signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
    },
    current_line_blame = false, -- toggled with <leader>gb, off by default
    current_line_blame_opts = { delay = 300 },
})
