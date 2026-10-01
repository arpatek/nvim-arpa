return {
    cmd = { 'terraform-ls', 'serve' },
    filetypes = { 'terraform', 'terraform-vars' },
    -- .terraform first: it marks the initialized module root, which is where
    -- provider schemas live. Falling back to .git would index the whole repo.
    root_markers = { '.terraform', '.terraform.lock.hcl', '.git' },
}
