-- Types, imports and jump-to-definition. ruff handles lint and format, so
-- pyright's own linting is left off to avoid two opinions on the same line.
return {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                -- 'basic' reports real type errors without the noise of
                -- 'strict', which flags every untyped function you write
                -- while learning.
                typeCheckingMode = 'basic',
                diagnosticSeverityOverrides = {
                    -- ruff owns these, and duplicate diagnostics are worse
                    -- than none.
                    reportUnusedImport = 'none',
                    reportUnusedVariable = 'none',
                },
            },
        },
    },
}
