-- ┌──────────────────────────────────────────────────────────────┐
-- │ arpatek - Linting                                            │
-- └──────────────────────────────────────────────────────────────┘
--
-- Only linters that no language server already runs.
--   shellcheck    skipped, bash-language-server runs it
--   ansible-lint  skipped, ansible-language-server runs it
--   ruff          skipped, it is a language server here
-- Running any of those twice produces duplicate diagnostics on the same line.

local lint = require('lint')

lint.linters_by_ft = {
    dockerfile = { 'hadolint' },
    markdown = { 'markdownlint-cli2' },
}

-- tflint is deliberately absent: it needs a third-party Homebrew tap, and
-- terraform-ls already reports `terraform validate` diagnostics. If the three
-- files in terraform-xo ever grow into something that needs rule-based
-- linting:  brew tap terraform-linters/tap && brew install tflint
-- then add  terraform = { 'tflint' }  above.

-- ──[ Trigger ]────────────────────────────────────────────────────────────────
-- On write and on entering a buffer, not on every keystroke: these are all
-- external processes, and tflint in particular is slow enough to notice.
vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('arpatek.lint', { clear = true }),
    callback = function()
        -- try_lint is a no-op when the linter binary is missing, so a box
        -- without hadolint installed stays quiet instead of erroring.
        lint.try_lint()
    end,
})

vim.api.nvim_create_user_command('Lint', function()
    lint.try_lint()
end, { desc = 'Run linters for this buffer now' })
