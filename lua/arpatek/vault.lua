-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Vault buffers                                      │
-- │ Secrets in plaintext get no language server and no disk      │
-- │ artifacts.                                                   │
-- └──────────────────────────────────────────────────────────────┘
--
-- `ansible-vault edit` decrypts into ~/.ansible/tmp/ansible-local-*/tmp*.yml,
-- opens $EDITOR on it, re-encrypts on exit and deletes the temp file. While
-- that buffer is open it is the plaintext secret.
--
-- Three defaults are wrong for that buffer:
--
--   1. yaml-language-server would receive the full text via didOpen, and its
--      schemaStore option makes an outbound request while it is loaded.
--   2. 'undofile' persists the edit history to ~/.local/state/nvim/undo/.
--      The temp file is deleted; the undo file is not.
--   3. shada records marks and the jumplist, leaking the path at minimum.
--
-- The filetype is 'yamlvault' rather than 'yaml' precisely so that no entry in
-- lsp/ claims it. Highlighting is restored by pointing the yaml parser at the
-- new filetype, which costs nothing and involves no server.

-- ──[ Detection ]──────────────────────────────────────────────────────────────
vim.filetype.add({
    pattern = {
        ['.*/%.ansible/tmp/.*'] = 'yamlvault',
        -- `ansible-vault create` and some wrappers use $TMPDIR instead.
        ['.*/ansible%-local%-.*/.*'] = 'yamlvault',
    },
})

-- Treesitter highlighting without a language server attached.
vim.treesitter.language.register('yaml', 'yamlvault')

-- ──[ Hardening ]──────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('arpatek.vault', { clear = true }),
    pattern = 'yamlvault',
    callback = function(ev)
        vim.bo[ev.buf].undofile = false
        vim.bo[ev.buf].swapfile = false
        vim.opt_local.backup = false
        vim.opt_local.writebackup = false
        -- Keep the path and marks out of shada.
        vim.opt.shada = ''
        vim.bo[ev.buf].tabstop = 2
        vim.bo[ev.buf].shiftwidth = 2
        vim.notify('vault buffer: no LSP, no undofile, no shada', vim.log.levels.WARN)
    end,
})

-- Belt and braces: if some future server does claim this filetype, detach it.
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('arpatek.vault.lsp', { clear = true }),
    callback = function(ev)
        if vim.bo[ev.buf].filetype == 'yamlvault' then
            vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
            vim.notify('detached LSP from a vault buffer', vim.log.levels.WARN)
        end
    end,
})
