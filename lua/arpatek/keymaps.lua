-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Keymaps                                            │
-- └──────────────────────────────────────────────────────────────┘
--
-- Leader is <Space>. LSP keymaps are buffer-local and live in lsp.lua, so
-- they only exist where a server is attached.

local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

-- ──[ Registers ]──────────────────────────────────────────────────────────────
-- Replacing yanky. The whole yank-ring feature already exists in vi:
--
--   "0p    last yank, never clobbered by a delete
--   "1p    last delete; "2p the one before it, up to "9
--   "+p    system clipboard
--   ""p    the unnamed register, what a bare p uses
--   "ayy   yank into register a; "Ayy appends to it
--
-- These work on every RHEL box you will ever SSH into, which is the reason
-- for learning them rather than a plugin's keymaps.
map('n', '<leader>"', '<Cmd>registers<CR>', 'Show registers')
-- Paste over a selection without losing the yank: send the replaced text to
-- the black hole register first.
map('x', '<leader>p', '"_dP', 'Paste over selection, keep register')
map({ 'n', 'x' }, '<leader>d', '"_d', 'Delete without touching registers')

-- ──[ Files & Search ]─────────────────────────────────────────────────────────
-- Routed through arpatek.finder so fzf-lua configures itself on first use.
local find = require('arpatek.finder').pick
map('n', '<leader><space>', find('files'), 'Find files')
map('n', '<leader>ff', find('files'), 'Find files')
map('n', '<leader>fg', find('live_grep'), 'Grep project')
map('n', '<leader>fr', find('oldfiles'), 'Recent files')
map('n', '<leader>fb', find('buffers'), 'Buffers')
map('n', '<leader>fh', find('helptags'), 'Help tags')
map('n', '<leader>fk', find('keymaps'), 'Keymaps')
map('n', '<leader>fd', find('diagnostics_document'), 'Document diagnostics')
-- Grep the word under the cursor, the one search you run most often.
map('n', '<leader>fw', find('grep_cword'), 'Grep word under cursor')

-- ──[ Explorer ]───────────────────────────────────────────────────────────────
-- yazi in a float. Keys inside it are yazi's own: <Enter> chooses, <Space>
-- multi-selects, q quits, ~ opens its help.
local yazi = require('arpatek.yazi')
map('n', '-', yazi.open, 'Explorer at current file')
map('n', '<leader>e', yazi.open, 'Explorer at current file')
map('n', '<leader>E', yazi.open_cwd, 'Explorer at cwd')

-- ──[ Windows ]────────────────────────────────────────────────────────────────
map('n', '<C-h>', '<C-w>h', 'Window left')
map('n', '<C-j>', '<C-w>j', 'Window down')
map('n', '<C-k>', '<C-w>k', 'Window up')
map('n', '<C-l>', '<C-w>l', 'Window right')
map('n', '<leader>-', '<Cmd>split<CR>', 'Split below')
map('n', '<leader>|', '<Cmd>vsplit<CR>', 'Split right')

-- ──[ Buffers ]────────────────────────────────────────────────────────────────
-- No bufferline. :bnext and :bprev with a finder covers it.
map('n', '<S-h>', '<Cmd>bprevious<CR>', 'Previous buffer')
map('n', '<S-l>', '<Cmd>bnext<CR>', 'Next buffer')
map('n', '<leader>bd', '<Cmd>bdelete<CR>', 'Delete buffer')

-- ──[ Diagnostics & Quickfix ]─────────────────────────────────────────────────
map('n', '<leader>cd', vim.diagnostic.open_float, 'Line diagnostics')
map('n', '<leader>cq', vim.diagnostic.setloclist, 'Diagnostics to loclist')
-- ]d and [d are core defaults in 0.11+. These are the severity-filtered ones.
map('n', ']e', function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, 'Next error')
map('n', '[e', function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, 'Previous error')
map('n', '<leader>xq', '<Cmd>copen<CR>', 'Quickfix list')
map('n', '<leader>xl', '<Cmd>lopen<CR>', 'Location list')

-- ──[ Git ]────────────────────────────────────────────────────────────────────
map('n', '<leader>gs', '<Cmd>Gitsigns stage_hunk<CR>', 'Stage hunk')
map('n', '<leader>gr', '<Cmd>Gitsigns reset_hunk<CR>', 'Reset hunk')
map('n', '<leader>gp', '<Cmd>Gitsigns preview_hunk<CR>', 'Preview hunk')
map('n', '<leader>gb', '<Cmd>Gitsigns toggle_current_line_blame<CR>', 'Toggle blame')
map('n', '<leader>gd', '<Cmd>Gitsigns diffthis<CR>', 'Diff this file')
map('n', ']h', '<Cmd>Gitsigns next_hunk<CR>', 'Next hunk')
map('n', '[h', '<Cmd>Gitsigns prev_hunk<CR>', 'Previous hunk')
map('n', '<leader>gg', '<Cmd>terminal lazygit<CR>', 'lazygit')

-- ──[ Formatting ]─────────────────────────────────────────────────────────────
map({ 'n', 'x' }, '<leader>cf', function()
    require('conform').format({ async = true, lsp_format = 'fallback' })
end, 'Format buffer or selection')

-- ──[ Editing ]────────────────────────────────────────────────────────────────
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', 'Clear search highlight')
-- Keep the cursor centred when jumping by half-pages, so you do not lose your
-- place in a long playbook.
map('n', '<C-d>', '<C-d>zz', 'Half page down')
map('n', '<C-u>', '<C-u>zz', 'Half page up')
map('n', 'n', 'nzzzv', 'Next match, centred')
map('n', 'N', 'Nzzzv', 'Previous match, centred')
-- Stay in visual mode when shifting, so > > > works.
map('x', '<', '<gv', 'Shift left')
map('x', '>', '>gv', 'Shift right')
-- Move the selection up and down, re-indenting as it goes.
map('x', 'J', ":m '>+1<CR>gv=gv", 'Move selection down')
map('x', 'K', ":m '<-2<CR>gv=gv", 'Move selection up')
-- Write with sudo, for the times you opened a root-owned config as yourself.
vim.api.nvim_create_user_command('W', 'w !sudo tee % > /dev/null', { desc = 'Write with sudo' })

-- ──[ Config ]─────────────────────────────────────────────────────────────────
map('n', '<leader>uc', function()
    require('arpatek.yazi').open(vim.fn.stdpath('config'))
end, 'Open config directory')
map('n', '<leader>up', function()
    vim.pack.update()
end, 'Update plugins')
map('n', '<leader>uh', '<Cmd>checkhealth<CR>', 'Check health')

-- ──[ Right-Click Menu ]───────────────────────────────────────────────────────
-- 'mousemodel' is set to popup_setpos in options.lua, so right-click moves the
-- cursor and then opens this. Built-in menu system, no plugin.
vim.cmd([[
    silent! aunmenu PopUp
    anoremenu PopUp.Definition      <Cmd>lua vim.lsp.buf.definition()<CR>
    anoremenu PopUp.References      <Cmd>lua vim.lsp.buf.references()<CR>
    anoremenu PopUp.Rename          <Cmd>lua vim.lsp.buf.rename()<CR>
    anoremenu PopUp.Code\ Action    <Cmd>lua vim.lsp.buf.code_action()<CR>
    anoremenu PopUp.Hover           <Cmd>lua vim.lsp.buf.hover()<CR>
    anoremenu PopUp.-sep1-          <Nop>
    anoremenu PopUp.Format          <Cmd>lua require('conform').format()<CR>
    anoremenu PopUp.Diagnostics     <Cmd>lua vim.diagnostic.open_float()<CR>
    anoremenu PopUp.-sep2-          <Nop>
    anoremenu PopUp.Git\ Blame      <Cmd>Gitsigns blame_line<CR>
    anoremenu PopUp.Stage\ Hunk     <Cmd>Gitsigns stage_hunk<CR>
]])
