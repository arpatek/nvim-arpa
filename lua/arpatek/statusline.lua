-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Statusline                                         │
-- │ No lualine. One function, evaluated on redraw.               │
-- └──────────────────────────────────────────────────────────────┘

local M = {}

-- ──[ Mode ]───────────────────────────────────────────────────────────────────
-- Keys are the raw values of mode(1). The short labels keep the left edge a
-- fixed width so the rest of the line does not jitter on every mode change.
local modes = {
    ['n'] = { 'NORMAL', 'ArpatekStModeN' },
    ['no'] = { 'OP-PEND', 'ArpatekStModeN' },
    ['v'] = { 'VISUAL', 'ArpatekStModeV' },
    ['V'] = { 'V-LINE', 'ArpatekStModeV' },
    ['\22'] = { 'V-BLOCK', 'ArpatekStModeV' },
    ['s'] = { 'SELECT', 'ArpatekStModeV' },
    ['i'] = { 'INSERT', 'ArpatekStModeI' },
    ['ic'] = { 'INSERT', 'ArpatekStModeI' },
    ['R'] = { 'REPLACE', 'ArpatekStModeR' },
    ['c'] = { 'COMMAND', 'ArpatekStModeC' },
    ['t'] = { 'TERMINAL', 'ArpatekStModeC' },
}

local function mode()
    local m = vim.api.nvim_get_mode().mode
    local entry = modes[m] or modes[m:sub(1, 1)] or { m:upper(), 'ArpatekStModeN' }
    return string.format('%%#%s# %s %%*', entry[2], entry[1])
end

-- ──[ Git ]────────────────────────────────────────────────────────────────────
-- gitsigns publishes the branch as a buffer variable, so this costs nothing.
-- No shelling out to git on every redraw.
local function git()
    local head = vim.b.gitsigns_head
    if not head then
        return ''
    end
    local status = vim.b.gitsigns_status_dict or {}
    local out = { '%#ArpatekStGit#  ' .. head }
    if (status.added or 0) > 0 then
        table.insert(out, '%#ArpatekStAdd#+' .. status.added)
    end
    if (status.changed or 0) > 0 then
        table.insert(out, '%#ArpatekStChange#~' .. status.changed)
    end
    if (status.removed or 0) > 0 then
        table.insert(out, '%#ArpatekStDelete#-' .. status.removed)
    end
    return table.concat(out, ' ') .. '%* '
end

-- ──[ Diagnostics ]────────────────────────────────────────────────────────────
local function diagnostics()
    local counts = vim.diagnostic.count(0)
    local severity = vim.diagnostic.severity
    local parts = {}
    local order = {
        { severity.ERROR, '%#DiagnosticError#', '' },
        { severity.WARN, '%#DiagnosticWarn#', '' },
        { severity.INFO, '%#DiagnosticInfo#', '' },
        { severity.HINT, '%#DiagnosticHint#', '' },
    }
    for _, item in ipairs(order) do
        local n = counts[item[1]] or 0
        if n > 0 then
            table.insert(parts, string.format('%s%s %d', item[2], item[3], n))
        end
    end
    if #parts == 0 then
        return ''
    end
    return table.concat(parts, ' ') .. '%* '
end

-- ──[ LSP ]────────────────────────────────────────────────────────────────────
-- Which servers are actually attached. The fastest way to notice a missing
-- binary is to see the name absent from here.
local function lsp()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
        return ''
    end
    local names = {}
    for _, client in ipairs(clients) do
        table.insert(names, client.name)
    end
    return '%#ArpatekStLsp#' .. table.concat(names, ',') .. '%* '
end

-- ──[ Render ]─────────────────────────────────────────────────────────────────
function M.render()
    -- The dashboard draws its own screen, so a statusline reporting [Scratch]
    -- and [-] over it is just noise. snacks blanks its window-local
    -- statusline, but laststatus=3 ignores window-local values, so the global
    -- one has to opt out here. statusline_winid is set by Nvim while the
    -- expression is being evaluated.
    local win = vim.g.statusline_winid
    local buf = win and vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_buf(win)
        or 0
    if vim.bo[buf].filetype == 'arpatek-dashboard' then
        return ''
    end

    return table.concat({
        mode(),
        ' ',
        git(),
        '%#ArpatekStFile#%f%*',     -- path relative to cwd
        '%#ArpatekStFlag#%m%r%*',   -- [+] modified, [RO] readonly
        '%=',                       -- everything after this is right-aligned
        diagnostics(),
        lsp(),
        '%#ArpatekStFt#%{&filetype}%* ',
        '%#ArpatekStPos# %l:%c  %P %*',
    })
end

-- ──[ Highlight Groups ]───────────────────────────────────────────────────────
-- Catppuccin Mocha palette, spelled out rather than pulled from the plugin so
-- the statusline still renders if the colorscheme fails to load.
local function set_highlights()
    local bg = '#313244'    -- surface0
    local hl = {
        ArpatekStModeN = { fg = '#1e1e2e', bg = '#89b4fa', bold = true },   -- blue
        ArpatekStModeI = { fg = '#1e1e2e', bg = '#a6e3a1', bold = true },   -- green
        ArpatekStModeV = { fg = '#1e1e2e', bg = '#cba6f7', bold = true },   -- mauve
        ArpatekStModeR = { fg = '#1e1e2e', bg = '#f38ba8', bold = true },   -- red
        ArpatekStModeC = { fg = '#1e1e2e', bg = '#fab387', bold = true },   -- peach
        ArpatekStGit = { fg = '#f9e2af', bg = bg },
        ArpatekStAdd = { fg = '#a6e3a1', bg = bg },
        ArpatekStChange = { fg = '#f9e2af', bg = bg },
        ArpatekStDelete = { fg = '#f38ba8', bg = bg },
        ArpatekStFile = { fg = '#cdd6f4', bg = bg, bold = true },
        ArpatekStFlag = { fg = '#f38ba8', bg = bg },
        ArpatekStLsp = { fg = '#94e2d5', bg = bg },
        ArpatekStFt = { fg = '#9399b2', bg = bg },
        ArpatekStPos = { fg = '#cdd6f4', bg = '#45475a' },
    }
    for group, spec in pairs(hl) do
        vim.api.nvim_set_hl(0, group, spec)
    end
    vim.api.nvim_set_hl(0, 'StatusLine', { bg = bg, fg = '#cdd6f4' })
end

set_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('arpatek.statusline.hl', { clear = true }),
    callback = set_highlights,
})

vim.o.statusline = "%!v:lua.require'arpatek.statusline'.render()"

return M
