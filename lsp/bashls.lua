-- bash-language-server. Surfaces shellcheck diagnostics itself, which is why
-- nvim-lint does not also run shellcheck.
return {
    cmd = { 'bash-language-server', 'start' },
    filetypes = { 'sh', 'bash' },
    root_markers = { '.git' },
    settings = {
        bashIde = {
            -- Default globPattern misses extensionless scripts. dotfiles has
            -- several (ipkg-linux, ipkg-macos, lpu, mpu), and they need to be
            -- indexed for cross-file jump-to-definition to work.
            globPattern = '*@(.sh|.inc|.bash|.command|.zsh)',
            shellcheckPath = 'shellcheck',
        },
    },
}
