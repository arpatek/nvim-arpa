-- Only matters for editing this config, which is the point of owning it.
return {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { { '.luarc.json', '.luarc.jsonc', 'stylua.toml', '.stylua.toml' }, '.git' },
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            -- Without this, every vim.* call is an undefined-global warning.
            workspace = {
                library = vim.api.nvim_get_runtime_file('lua', true),
                checkThirdParty = false,
            },
            diagnostics = { globals = { 'vim' } },
            telemetry = { enable = false },
            format = { enable = false },   -- stylua owns formatting
        },
    },
}
