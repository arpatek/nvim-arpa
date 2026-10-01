-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Neovim options                                     │
-- └──────────────────────────────────────────────────────────────┘

local opt = vim.opt

-- ──[ Providers ]──────────────────────────────────────────────────────────────
-- The node, perl, python3 and ruby providers exist for remote plugins written
-- in those languages. Nothing in this config is one, so they are six
-- :checkhealth warnings about hosts that will never be used. Disabling them
-- also skips the executable probing they do at startup.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- ──[ Line Numbers & Cursor ]──────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 5
opt.sidescrolloff = 8
opt.signcolumn = 'yes'          -- reserve the gutter so text stops shifting
                                -- every time a diagnostic or git sign appears

-- ──[ Indentation ]────────────────────────────────────────────────────────────
-- 4 spaces is the default because Bash and Python are the bulk of the work.
-- Per-filetype overrides live in the FileType autocmd below.
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true          -- wrapped lines keep the indent of their parent

-- ──[ Brackets ]───────────────────────────────────────────────────────────────
-- Both ~/.config/vim/vimrc and ~/.config/nvim/init.vim set these, and Neovim's
-- defaults differ: 'showmatch' is off and 'matchtime' is 5 (half-seconds).
opt.showmatch = true
opt.matchtime = 2

-- Not ported from those files, deliberately:
--   noerrorbells / visualbell  Neovim defaults to belloff=all, so no bell
--                              rings in the first place. Setting them changes
--                              nothing.
--   laststatus=2               laststatus=3 here: one global statusline
--                              instead of one per split.
--   nocompatible, filetype,    always on in Neovim.
--   syntax on
--   undodir                    Neovim already defaults inside stdpath('state'),
--                              so the mkdir dance in the vimrc is unnecessary.

-- ──[ Search ]─────────────────────────────────────────────────────────────────
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true            -- ignorecase alone makes /Foo match foo;
                                -- smartcase restores case sensitivity the
                                -- moment the pattern contains a capital

-- ──[ Grep ]───────────────────────────────────────────────────────────────────
-- Point :grep at ripgrep so the built-in quickfix workflow is usable without
-- a plugin. --vimgrep gives one match per line in the file:line:col:text form
-- that 'grepformat' expects.
if vim.fn.executable('rg') == 1 then
    opt.grepprg = 'rg --vimgrep --smart-case'
    opt.grepformat = '%f:%l:%c:%m'
end

-- ──[ Completion ]─────────────────────────────────────────────────────────────
-- noselect: never auto-insert the first match, so <CR> stays a newline and
--           <C-y> is the deliberate "accept" key
-- popup:    render server-provided docs in a floating window
-- fuzzy:    match subsequences, not just prefixes
opt.completeopt = 'menuone,noselect,popup,fuzzy'
opt.pumheight = 12              -- cap the popup so it stops covering the screen

-- ──[ Windows & Splits ]───────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true
opt.winborder = 'rounded'       -- 0.11+: one setting styles every float,
                                -- including LSP hover and diagnostics

-- ──[ Files & Undo ]───────────────────────────────────────────────────────────
opt.undofile = true             -- undo survives closing the file
opt.swapfile = false            -- undofile covers recovery; swap files just
                                -- produce E325 prompts on vault edits
opt.backup = false
opt.updatetime = 250            -- also how fast CursorHold fires
opt.confirm = true              -- prompt instead of failing on :q with changes

-- ──[ Display ]────────────────────────────────────────────────────────────────
opt.termguicolors = true
opt.showmode = false            -- the statusline already shows the mode
opt.laststatus = 3              -- one global statusline, not one per split
opt.list = true
opt.listchars = { tab = '→ ', trail = '·', nbsp = '␣' }
opt.fillchars = { eob = ' ' }   -- hide the ~ on lines past end of buffer
opt.mouse = 'a'
opt.mousemodel = 'popup_setpos' -- right-click opens the PopUp menu defined
                                -- in keymaps.lua, and moves the cursor first

-- ──[ Clipboard ]──────────────────────────────────────────────────────────────
-- Deferred: querying the clipboard provider costs ~20ms at startup, and it is
-- never needed before the first yank.
vim.schedule(function()
    opt.clipboard = 'unnamedplus'
end)

-- ──[ Per-Filetype Indentation ]───────────────────────────────────────────────
-- YAML in particular: 4-space indent is legal YAML but fights every Ansible
-- example you will ever copy, and 'tabstop' must stay 2 or a stray tab breaks
-- the document outright.
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('arpatek.indent', { clear = true }),
    pattern = { 'yaml', 'yaml.ansible', 'json', 'jsonc', 'terraform', 'hcl', 'lua', 'markdown' },
    callback = function()
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
    end,
})

-- ──[ Yank Highlight ]─────────────────────────────────────────────────────────
-- Brief flash on yank. Useful feedback while building register habits, since
-- it shows exactly what landed in the register.
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('arpatek.yank', { clear = true }),
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

-- ──[ Filetype Detection ]─────────────────────────────────────────────────────
-- nvim ships no rule that distinguishes Ansible YAML from ordinary YAML, so
-- without this the ansible language server never attaches and you get generic
-- YAML diagnostics on a playbook. LazyVim solved this with nvim-ansible; the
-- rules themselves are short enough to own.
vim.filetype.add({
    filename = {
        ['ansible.cfg'] = 'ini',
        ['.ansible-lint'] = 'yaml',
        ['site.yml'] = 'yaml.ansible',
        ['site.yaml'] = 'yaml.ansible',
        ['playbook.yml'] = 'yaml.ansible',
        ['Brewfile'] = 'ruby',
    },
    pattern = {
        -- Lua patterns, not globs. Anchored on the directory names Ansible
        -- itself imposes, which is what makes them reliable.
        ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/roles/.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/roles/.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/roles/.*/meta/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/group_vars/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/host_vars/.*%.ya?ml'] = 'yaml.ansible',
        ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
        ['docker%-compose.*%.ya?ml'] = 'yaml.docker-compose',
        ['compose.*%.ya?ml'] = 'yaml.docker-compose',
        -- Vault temp files are handled in arpatek.vault, not here.
    },
})
