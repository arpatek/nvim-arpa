-- ruff as a language server: lint, quickfix code actions, and formatting.
-- Replaces black, flake8 and isort with one Rust binary.
return {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    init_options = {
        settings = {
            -- Nothing here overrides a pyproject.toml or ruff.toml in the
            -- project. Repo config always wins.
            lineLength = 88,
        },
    },
}
