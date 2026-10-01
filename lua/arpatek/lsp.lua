-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - LSP                                                │
-- │ vim.lsp.config + vim.lsp.enable, built in since nvim 0.11.    │
-- │ No nvim-lspconfig. No mason. Servers come from the Brewfile.  │
-- └──────────────────────────────────────────────────────────────┘
--
-- Server definitions are one file each under ../../lsp/. nvim finds them on
-- 'runtimepath' by name, so lsp/pyright.lua defines the 'pyright' config.
--
--   :checkhealth vim.lsp        which configs are enabled and what attached
--   :LspInfo equivalent         :lua =vim.lsp.get_clients()

-- ──[ Enable ]─────────────────────────────────────────────────────────────────
-- A server listed here attaches automatically when a matching filetype opens
-- and a root marker is found. Missing binary means nothing happens, no error.
vim.lsp.enable({
    'bashls',        -- also surfaces shellcheck, so nvim-lint skips shell
    'pyright',       -- types and imports
    'ruff',          -- lint and format, replaces black and flake8
    'terraformls',
    'ansiblels',     -- also surfaces ansible-lint
    'yamlls',
    'lua_ls',
    'marksman',
    'jsonls',
})

-- ──[ Diagnostics ]────────────────────────────────────────────────────────────
vim.diagnostic.config({
    virtual_text = { prefix = '●', spacing = 2, source = 'if_many' },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.INFO] = '',
            [vim.diagnostic.severity.HINT] = '',
        },
    },
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
})

-- ──[ On Attach ]──────────────────────────────────────────────────────────────
-- Buffer-local keymaps and completion, set once per client attach. Keeping
-- them buffer-local means gd does nothing surprising in a buffer with no
-- server, instead of erroring.
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('arpatek.lsp', { clear = true }),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end

        local function map(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = 'LSP: ' .. desc })
        end

        -- nvim 0.12 already binds grn, gra, grr, gri and K by default.
        -- These are the additions, in the g-prefix style core settled on.
        map('gd', vim.lsp.buf.definition, 'definition')
        map('gD', vim.lsp.buf.declaration, 'declaration')
        map('gy', vim.lsp.buf.type_definition, 'type definition')
        map('<leader>cs', vim.lsp.buf.document_symbol, 'document symbols')
        map('<leader>cS', vim.lsp.buf.workspace_symbol, 'workspace symbols')

        -- Built-in completion, driven by the server. Replaces blink.cmp.
        -- autotrigger fires on the server's own trigger characters, so it
        -- pops on '.' in Python without firing on every keypress.
        -- <C-y> accepts. <C-e> dismisses. <C-n>/<C-p> walk the list.
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end

        -- Highlight other references to the symbol under the cursor.
        if client:supports_method('textDocument/documentHighlight') then
            local hl = vim.api.nvim_create_augroup('arpatek.lsp.highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = hl,
                buffer = ev.buf,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                group = hl,
                buffer = ev.buf,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})
