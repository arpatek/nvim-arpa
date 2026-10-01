-- Markdown link completion and jump-to-heading. Earns its place on the
-- Obsidian vault and the docs/ trees, where [[wikilinks]] and relative links
-- break silently.
return {
    cmd = { 'marksman', 'server' },
    filetypes = { 'markdown' },
    root_markers = { '.marksman.toml', '.obsidian', '.git' },
}
