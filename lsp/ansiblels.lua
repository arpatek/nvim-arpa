-- Surfaces ansible-lint, so nvim-lint does not run it again.
-- Attaches to the yaml.ansible filetype, which the detection rules in
-- lua/arpatek/options.lua assign by path.
return {
    cmd = { 'ansible-language-server', '--stdio' },
    filetypes = { 'yaml.ansible' },
    root_markers = { 'ansible.cfg', '.ansible-lint', '.git' },
    settings = {
        ansible = {
            validation = {
                lint = { enabled = true, path = 'ansible-lint' },
            },
            python = { interpreterPath = 'python3' },
        },
    },
}
