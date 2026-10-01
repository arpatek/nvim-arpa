return {
    cmd = { 'yaml-language-server', '--stdio' },
    -- No 'yaml.gitlab': nothing defines that filetype here, and listing it
    -- makes :checkhealth vim.lsp warn about an unknown filetype. Gitea is the
    -- forge in use, and its workflow files get the github-workflow schema
    -- below rather than a separate filetype.
    filetypes = { 'yaml', 'yaml.docker-compose' },
    root_markers = { '.git' },
    settings = {
        yaml = {
            -- On by default and almost always wrong: it flags any mapping
            -- whose keys are not alphabetical, which is every compose file
            -- and every playbook ever written.
            keyOrdering = false,
            validate = true,
            schemaStore = { enable = true, url = 'https://www.schemastore.org/api/json/catalog.json' },
            schemas = {
                -- Gitea Actions uses the GitHub workflow schema.
                ['https://json.schemastore.org/github-workflow.json'] = {
                    '.gitea/workflows/*.y*ml',
                    '.github/workflows/*.y*ml',
                },
                ['https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json'] = {
                    'docker-compose*.y*ml',
                    'compose*.y*ml',
                },
            },
        },
    },
}
