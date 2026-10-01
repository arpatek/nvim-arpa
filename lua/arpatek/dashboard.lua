-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Startup screen                                     │
-- │ No plugin. A scratch buffer, highlight groups and one          │
-- │ VimEnter autocmd.                                             │
-- └──────────────────────────────────────────────────────────────┘
--
-- Banner and gradient come from arpatek.dev's curl output
-- (app/content/ascii.py) so the editor and the site render the same logo.
--
-- Menu layout follows snacks.dashboard: icon on the left, description, key
-- right-aligned. Glyph codepoints were taken from the snacks source in
-- ~/.local/share/nvim/lazy/snacks.nvim and verified present in
-- JetBrainsMonoNerdFontMono-Regular.ttf.
--
-- There is deliberately NO selection highlight. snacks sets cursorline=false
-- and lets the real terminal cursor mark the current item, parked on the
-- first letter of the description. Anything else looks wrong next to it.
--
-- Unlike snacks, which uses a fixed 60-column pane, the menu width scales
-- with the window and re-renders on VimResized.
--
-- ASCII banners cannot shrink, so the largest one that fits is picked from
-- the window size, falling back through smaller forms:
--
--   big     78x7 banner + subtitle    needs 78 cols, 20 rows
--   small   33x5 banner               needs 35 cols, 15 rows
--   text    A R P A T E K             needs 15 cols, 11 rows
--   none    menu only                 anything smaller
--
-- The footer is added independently whenever two rows are left over. A narrow
-- tmux split degrades through these rather than wrapping a banner into noise.
--
-- <Up>/<Down>, k/j, <Tab>/<S-Tab> move and wrap. <CR> runs the selection.
-- Clicking a row selects it; double-click runs it. The letter keys still work
-- directly.

local M = {}

-- ──[ Banner ]─────────────────────────────────────────────────────────────────
local logo = {
    '         :::     :::::::::  :::::::::     ::: ::::::::::: :::::::::: :::    :::',
    '       :+: :+:   :+:    :+: :+:    :+:  :+: :+:   :+:     :+:        :+:   :+:',
    '     +:+   +:+  +:+    +:+ +:+    +:+ +:+   +:+  +:+     +:+        +:+  +:+',
    '   +#++:++#++: +#++:++#:  +#++:++#+ +#++:++#++: +#+     +#++:++#   +#++:++',
    '  +#+     +#+ +#+    +#+ +#+       +#+     +#+ +#+     +#+        +#+  +#+',
    ' #+#     #+# #+#    #+# #+#       #+#     #+# #+#     #+#        #+#   #+#',
    '###     ### ###    ### ###       ###     ### ###     ########## ###    ###',
}

-- Small banner for narrow windows: 33x5, against the big one's 78x7.
local logo_small = {
    [[                     __      __  ]],
    [[ ___ ________  ___ _/ /____ / /__]],
    [[/ _ `/ __/ _ \/ _ `/ __/ -_)  '_/]],
    [[\_,_/_/ / .__/\_,_/\__/\__/_/\_\ ]],
    [[       /_/]],
}

local gradient = {
    '#b9746f', '#cd9b98', '#c3b283', '#9db9b2', '#79be9a', '#a2d2b9', '#dcd6d6',
}

-- ──[ Menu ]───────────────────────────────────────────────────────────────────
local menu = {
    { icon = '\u{f002}',  key = 'f', desc = 'Find File',      action = function() require('arpatek.finder').pick('files')() end },
    { icon = '\u{f15b}',  key = 'n', desc = 'New File',       action = function() vim.cmd('ene | startinsert') end },
    { icon = '\u{f022}',  key = '/', desc = 'Find Text',      action = function() require('arpatek.finder').pick('live_grep')() end },
    { icon = '\u{f0c5}',  key = 'r', desc = 'Recent Files',   action = function() require('arpatek.finder').pick('oldfiles')() end },
    { icon = '\u{f024b}', key = 'e', desc = 'Explorer',       action = function() require('arpatek.yazi').open_cwd() end },
    { icon = '\u{f423}',  key = 'c', desc = 'Config',         action = function() require('arpatek.yazi').open(vim.fn.stdpath('config')) end },
    { icon = '\u{f04b2}', key = 'u', desc = 'Update Plugins', action = function() vim.pack.update() end },
    { icon = '\u{f05e1}', key = 'h', desc = 'Checkhealth',    action = function() vim.cmd('checkhealth') end },
    { icon = '\u{f426}',  key = 'q', desc = 'Quit',           action = function() vim.cmd('qa!') end },
}

-- Menu width, in columns from the icon to the right-aligned key. Scales with
-- the window, with a floor so it does not crush at 80 columns and a ceiling of
-- the banner's own width so the block never grows wider than the logo above
-- it. snacks hardcodes 60 and does not scale at all.
-- Measured from the art, not hardcoded. The widest big-banner line is 79, not
-- the 78 it looks like, and guessing it wrong drew the banner one column wider
-- than the window.
-- nvim_strwidth, NOT strdisplaywidth. The latter is window-relative and
-- breakindent-aware: a 79-cell line in an 80-column window reports 88,
-- because it adds the wrapped continuation's breakindent. That made the
-- layout depend on the window width it was supposed to be measured against.
local function block_width(art)
    local w = 0
    for _, line in ipairs(art) do
        w = math.max(w, vim.api.nvim_strwidth(line))
    end
    return w
end

local BANNER_WIDTH = block_width(logo)

local function menu_width(win_width)
    local ideal = math.floor(win_width * 0.72)
    local capped = math.min(ideal, BANNER_WIDTH)        -- never wider than the logo
    local floored = math.max(capped, 56)                -- comfortable minimum
    -- ...but never wider than the window, keeping a 2-column gutter. Below
    -- about 20 columns the longest entry ('Update Plugins') cannot fit and
    -- gets clipped by 'nowrap', which is still better than wrapping.
    return math.min(floored, math.max(20, win_width - 4))
end

-- ──[ Layout ]─────────────────────────────────────────────────────────────────
local SMALL_WIDTH = block_width(logo_small)

-- Rows each section costs, including the blank line that follows it.
local COST = {
    big = #logo + 1 + 2,            -- banner, blank, subtitle, blank
    small = #logo_small + 1,        -- banner, blank
    text = 2,                       -- title, blank
    footer = 2,                     -- blank, footer
}

-- Returns the banner form to draw, and whether the footer fits. Height is the
-- WINDOW height: a global statusline and the cmdline cost two rows, so an
-- 80x24 terminal is an 80x22 window.
local function pick_layout(width, height)
    local banner = 'none'
    if width >= BANNER_WIDTH and height >= #menu + COST.big then
        banner = 'big'
    elseif width >= SMALL_WIDTH + 2 and height >= #menu + COST.small then
        banner = 'small'
    elseif width >= 15 and height >= #menu + COST.text then
        banner = 'text'
    end
    local used = banner ~= 'none' and COST[banner] or 0
    local footer = width >= 34 and height >= #menu + used + COST.footer
    return banner, footer
end

local ns = vim.api.nvim_create_namespace('arpatek.dashboard')

local state = {
    buf = nil,
    win = nil,
    first = nil,        -- 0-based buffer row of the first menu entry
    index = 1,
    desc_cols = {},     -- byte column of each entry's description
    mode = nil,         -- banner form: 'big' | 'small' | 'text' | 'none'
    saved_wo = nil,     -- window options to put back when the buffer is wiped
    syncing = false,
}

-- ──[ Selection ]──────────────────────────────────────────────────────────────
-- The cursor IS the selection. snacks finds the first word character on the
-- row with a pattern; the byte column of each description is already known
-- from render time, so it is used directly.
local function set_cursor()
    if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
        return
    end
    state.syncing = true
    -- state.first is a 0-based buffer row; nvim_win_set_cursor takes a 1-based
    -- row, so entry i sits at state.first + i.
    vim.api.nvim_win_set_cursor(state.win, {
        state.first + state.index,
        state.desc_cols[state.index] or 0,
    })
    state.syncing = false
end

local function move(delta)
    state.index = ((state.index - 1 + delta) % #menu) + 1
    set_cursor()
end

-- Any cursor movement this module did not initiate — a mouse click, gg, G,
-- <C-d> — is clamped back onto a menu row and the selection follows it. That
-- is cheaper and less surprising than mapping every motion to <Nop>.
local function sync_from_cursor()
    if state.syncing or not (state.win and vim.api.nvim_win_is_valid(state.win)) then
        return
    end
    local pos = vim.api.nvim_win_get_cursor(state.win)
    local row = pos[1] - 1
    local index = math.min(#menu, math.max(1, row - state.first + 1))
    state.index = index
    -- Re-park whenever the cursor is off a menu row, or on the right row but
    -- the wrong column (a click lands wherever it was pressed).
    if row ~= state.first + index - 1 or pos[2] ~= (state.desc_cols[index] or 0) then
        set_cursor()
    end
end

-- ──[ Render ]─────────────────────────────────────────────────────────────────
function M.open()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_get_current_win()

    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local banner, show_footer = pick_layout(width, height)
    state.mode = banner

    local lines, marks = {}, {}

    local function centered(text, group)
        local col = math.max(0, math.floor((width - vim.api.nvim_strwidth(text)) / 2))
        table.insert(lines, string.rep(' ', col) .. text)
        table.insert(marks, { row = #lines - 1, group = group })
        return col
    end

    -- Vertical centering, counting only the sections this mode renders.
    local content_height = #menu
        + (banner ~= 'none' and COST[banner] or 0)
        + (show_footer and COST.footer or 0)
    for _ = 1, math.max(0, math.floor((height - content_height) / 2)) do
        table.insert(lines, '')
    end

    -- Draws an ASCII block centred as a block, not line by line, so it does
    -- not shear. The gradient is stretched across however many rows it has.
    local function draw_logo(art)
        local art_width = 0
        for _, line in ipairs(art) do
            art_width = math.max(art_width, vim.api.nvim_strwidth(line))
        end
        local pad = string.rep(' ', math.max(0, math.floor((width - art_width) / 2)))
        for i, line in ipairs(art) do
            table.insert(lines, pad .. line)
            -- Stretch the 7 stops over however many rows the art has, hitting
            -- both ends: a plain ceil(i/#art * #gradient) skips stop 1.
            local stop = 1 + math.floor(
                (i - 1) / math.max(1, #art - 1) * (#gradient - 1) + 0.5)
            table.insert(marks, { row = #lines - 1, group = 'ArpatekLogo' .. stop })
        end
    end

    if banner == 'big' then
        draw_logo(logo)
        table.insert(lines, '')
        local host = vim.fn.hostname():gsub('%..*', '')
        centered('Juan Garcia  ·  automation engineer  ·  ' .. host, 'ArpatekSubtitle')
        table.insert(lines, '')
    elseif banner == 'small' then
        draw_logo(logo_small)
        table.insert(lines, '')
    elseif banner == 'text' then
        -- One line carrying the same seven gradient stops, one per letter, so
        -- the identity survives in a narrow split.
        local title = 'A R P A T E K'
        local col = centered(title, nil)
        local row = #lines - 1
        for i = 1, 7 do
            local at = col + (i - 1) * 2
            table.insert(marks, {
                row = row, col = at, end_col = at + 1,
                group = 'ArpatekLogo' .. i,
            })
        end
        table.insert(lines, '')
    end

    -- Menu block, left-aligned inside a centred box. Byte columns for each
    -- field are recorded as the line is built, because a Nerd Font glyph is
    -- multi-byte and display width is not byte length.
    local inner = menu_width(width)
    local menu_pad = string.rep(' ', math.max(0, math.floor((width - inner) / 2)))
    state.first = #lines
    state.desc_cols = {}
    for i, item in ipairs(menu) do
        local head = item.icon .. '  ' .. item.desc
        local used = vim.api.nvim_strwidth(head) + vim.api.nvim_strwidth(item.key)
        local line = menu_pad .. head .. string.rep(' ', math.max(2, inner - used)) .. item.key
        table.insert(lines, line)

        local row = #lines - 1
        local icon_start = #menu_pad
        local desc_start = icon_start + #item.icon + 2
        state.desc_cols[i] = desc_start
        table.insert(marks, { row = row, col = icon_start, end_col = icon_start + #item.icon, group = 'ArpatekDashIcon' })
        table.insert(marks, { row = row, col = desc_start, end_col = desc_start + #item.desc, group = 'ArpatekDashDesc' })
        table.insert(marks, { row = row, col = #line - #item.key, end_col = #line, group = 'ArpatekDashKey' })
    end

    if show_footer then
        table.insert(lines, '')
        local ms = vim.g.arpatek_start
            and string.format('%.1f ms', (vim.uv.hrtime() - vim.g.arpatek_start) / 1e6)
            or '?'
        centered(string.format('⚡ %d plugins loaded in %s', #vim.pack.get(), ms), 'ArpatekFooter')
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    for _, mark in ipairs(marks) do
        if mark.group then
        vim.api.nvim_buf_set_extmark(buf, ns, mark.row, mark.col or 0, {
            end_row = mark.end_col and mark.row or mark.row + 1,
            end_col = mark.end_col,
            hl_group = mark.group,
        })
        end
    end

    -- ──[ Buffer behaviour ]───────────────────────────────────────────────────
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'arpatek-dashboard'
    vim.api.nvim_win_set_buf(win, buf)

    -- These are WINDOW-local, so they outlive the dashboard buffer: pressing
    -- 'n' runs :ene in the same window and the new file would inherit
    -- number=false, signcolumn=no and the rest. Capture the originals once and
    -- put them back when this buffer is wiped.
    local WO_KEYS = { 'number', 'relativenumber', 'cursorline', 'list', 'wrap',
                      'signcolumn', 'fillchars' }
    if not state.saved_wo then
        state.saved_wo = {}
        for _, k in ipairs(WO_KEYS) do
            state.saved_wo[k] = vim.wo[win][k]
        end
    end
    vim.api.nvim_create_autocmd('BufWipeout', {
        group = vim.api.nvim_create_augroup('arpatek.dashboard.wo', { clear = true }),
        buffer = buf,
        callback = function()
            if not (state.saved_wo and vim.api.nvim_win_is_valid(win)) then
                return
            end
            for k, v in pairs(state.saved_wo) do
                vim.wo[win][k] = v
            end
            state.saved_wo = nil
        end,
    })

    local wo = vim.wo[win]
    wo.number = false
    wo.relativenumber = false
    wo.cursorline = false       -- the selection extmark does this job
    wo.list = false
    wo.wrap = false         -- snacks sets this too; without it the banner
                            -- wraps into noise in any window under 78 columns
    wo.signcolumn = 'no'
    wo.fillchars = 'eob: '

    -- The index survives a VimResized re-render; a fresh open starts at 1.
    state.buf, state.win = buf, win
    state.index = math.min(state.index or 1, #menu)

    -- ──[ Keymaps ]────────────────────────────────────────────────────────────
    local function bmap(lhs, rhs)
        vim.keymap.set('n', lhs, rhs, { buffer = buf, nowait = true, silent = true })
    end

    for i, item in ipairs(menu) do
        bmap(item.key, function()
            state.index = i
            item.action()
        end)
    end

    bmap('<Down>', function() move(1) end)
    bmap('j', function() move(1) end)
    bmap('<Tab>', function() move(1) end)
    bmap('<Up>', function() move(-1) end)
    bmap('k', function() move(-1) end)
    bmap('<S-Tab>', function() move(-1) end)
    bmap('<CR>', function() menu[state.index].action() end)
    bmap('<2-LeftMouse>', function() menu[state.index].action() end)
    bmap('<Esc>', function() vim.cmd('qa!') end)

    vim.api.nvim_create_autocmd('CursorMoved', {
        group = vim.api.nvim_create_augroup('arpatek.dashboard.cursor', { clear = true }),
        buffer = buf,
        callback = sync_from_cursor,
    })

    set_cursor()
end

-- ──[ Highlight Groups ]───────────────────────────────────────────────────────
local function set_highlights()
    for i, colour in ipairs(gradient) do
        vim.api.nvim_set_hl(0, 'ArpatekLogo' .. i, { fg = colour, bold = true })
    end
    vim.api.nvim_set_hl(0, 'ArpatekSubtitle', { fg = '#dcd6d6' })
    vim.api.nvim_set_hl(0, 'ArpatekDashIcon', { fg = '#c3b283' })  -- site gold
    vim.api.nvim_set_hl(0, 'ArpatekDashDesc', { fg = '#cdd6f4' })  -- mocha text
    vim.api.nvim_set_hl(0, 'ArpatekDashKey', { fg = '#6c7086' })   -- mocha overlay0
    vim.api.nvim_set_hl(0, 'ArpatekFooter', { fg = '#6c7086', italic = true })
end

set_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('arpatek.dashboard.hl', { clear = true }),
    callback = set_highlights,
})

-- ──[ Trigger ]────────────────────────────────────────────────────────────────
-- Only on a bare `nvim`. An argument or piped stdin means something specific
-- was asked for. This is also why `ansible-vault edit` never sees the
-- dashboard: it always passes a filename.
vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('arpatek.dashboard', { clear = true }),
    once = true,
    callback = function()
        if vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1 then
            return
        end
        M.open()
    end,
})

-- ──[ Resize ]─────────────────────────────────────────────────────────────────
-- The banner is fixed-width ASCII and the menu scales, so both need
-- recentering when the terminal changes size. Only acts while the dashboard
-- is the current buffer.
vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('arpatek.dashboard.resize', { clear = true }),
    callback = function()
        if state.buf and vim.api.nvim_get_current_buf() == state.buf then
            M.open()
        end
    end,
})

-- Reports the layout decision for the current window. The thresholds depend
-- on measured art widths and on window (not terminal) height, so when the
-- banner is not the one expected, this says why.
vim.api.nvim_create_user_command('DashboardInfo', function()
    local w = vim.api.nvim_win_get_width(0)
    local h = vim.api.nvim_win_get_height(0)
    local banner, footer = pick_layout(w, h)
    print(string.format(
        'window=%dx%d  banner=%s  footer=%s\n'
            .. 'widths: big=%d small=%d menu=%d\n'
            .. 'needs:  big>=%dx%d  small>=%dx%d  text>=%dx%d',
        w, h, banner, tostring(footer),
        BANNER_WIDTH, SMALL_WIDTH, menu_width(w),
        BANNER_WIDTH, #menu + COST.big,
        SMALL_WIDTH + 2, #menu + COST.small,
        15, #menu + COST.text))
end, { desc = 'Report the dashboard layout decision' })

vim.api.nvim_create_user_command('Dashboard', function()
    state.index = 1
    M.open()
end, { desc = 'Open the startup screen' })

return M
