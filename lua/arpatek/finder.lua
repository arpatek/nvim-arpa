-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Finder                                             │
-- │ fzf-lua, configured on first use instead of at startup.       │
-- └──────────────────────────────────────────────────────────────┘
--
-- vim.pack has no lazy-loading, so anything expensive has to defer itself.
-- fzf-lua's setup() costs ~14ms of a ~100ms startup and is not needed until
-- a key is actually pressed, which for a `ansible-vault edit` is never.

local M = {}
local configured = false

local function fzf()
    if not configured then
        require('fzf-lua').setup({
            'default-title',
            winopts = {
                height = 0.85,
                width = 0.85,
                preview = { layout = 'vertical' },
            },
            files = { formatter = 'path.filename_first' },
            grep = {
                rg_opts = "--hidden --column --line-number --smart-case --glob '!.git/'",
            },
        })
        configured = true
    end
    return require('fzf-lua')
end

-- Returns a function suitable for a keymap rhs. The picker name is resolved
-- at call time, so a typo here fails loudly on keypress rather than silently
-- at startup.
function M.pick(name)
    return function()
        local picker = fzf()[name]
        if not picker then
            vim.notify('fzf-lua: no picker named ' .. name, vim.log.levels.ERROR)
            return
        end
        picker()
    end
end

return M
