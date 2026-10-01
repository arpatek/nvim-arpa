-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - yazi as the file explorer                          │
-- │ No plugin. A floating terminal and yazi's --chooser-file.     │
-- └──────────────────────────────────────────────────────────────┘
--
-- yazi is already in the Brewfile, so the editor does not need its own file
-- manager. The whole integration is yazi's documented contract: it writes the
-- selected paths to --chooser-file and exits. Everything here is opening a
-- float, running it, and reading that file back.
--
--   <leader>e   yazi at the current file's directory, cursor on that file
--   <leader>E   yazi at the current working directory
--   -           same as <leader>e, the habit netrw and oil both trained
--
-- Inside yazi, its own keymaps apply. The ones that matter here:
--   <Enter>     choose (writes to the chooser file and quits)
--   <Space>     add to the selection; choosing opens all selected
--   q           quit without choosing
--   ~           yazi's own help

local M = {}

-- ──[ Float ]──────────────────────────────────────────────────────────────────
local function open_float()
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.85)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2) - 1,
        col = math.floor((vim.o.columns - width) / 2),
        style = 'minimal',
        border = 'rounded',
        title = ' yazi ',
        title_pos = 'center',
    })
    -- 'minimal' already drops numbers and signs; this stops the float
    -- inheriting a cursorline highlight over the TUI.
    vim.wo[win].cursorline = false
    return buf, win
end

-- ──[ Open ]───────────────────────────────────────────────────────────────────
-- target: a file (yazi opens its directory and hovers it) or a directory.
function M.open(target)
    if vim.fn.executable('yazi') == 0 then
        vim.notify('yazi not found on PATH (brew install yazi)', vim.log.levels.ERROR)
        return
    end

    target = target or vim.api.nvim_buf_get_name(0)
    if target == '' or vim.bo.buftype ~= '' then
        target = vim.fn.getcwd()
    end

    local chooser = vim.fn.tempname()
    local buf, win = open_float()

    -- jobstart with term=true, because termopen() is deprecated since 0.11.
    -- The job attaches to the current buffer, which is why the float has to
    -- be focused before this runs.
    vim.fn.jobstart({ 'yazi', target, '--chooser-file', chooser }, {
        term = true,
        on_exit = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end

            -- readfile on a missing file throws; quitting yazi with q never
            -- creates it.
            local ok, lines = pcall(vim.fn.readfile, chooser)
            pcall(vim.fn.delete, chooser)
            if not ok or not lines or #lines == 0 then
                return
            end

            for _, path in ipairs(lines) do
                if path ~= '' then
                    vim.cmd.edit(vim.fn.fnameescape(path))
                end
            end
        end,
    })

    vim.cmd.startinsert()
end

function M.open_cwd()
    M.open(vim.fn.getcwd())
end

vim.api.nvim_create_user_command('Yazi', function(opts)
    M.open(opts.args ~= '' and opts.args or nil)
end, { nargs = '?', complete = 'dir', desc = 'Open yazi as the file explorer' })

return M
