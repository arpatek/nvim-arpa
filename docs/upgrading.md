# Upgrading

## Plugins

```sh
nvim
:lua vim.pack.update()
```

Opens a buffer showing the incoming commit range per plugin. Review, then `:w`
to confirm or `:q` to discard. Revisions are recorded in `nvim-pack-lock.json` —
commit it after an update so other machines get the same revisions.

Offline listing of what is installed:

```
:lua vim.pack.update(nil, { offline = true })
```

Pin a plugin to its current revision by copying its `rev` out of
`nvim-pack-lock.json` into that entry's `version` in `lua/arpatek/plugins.lua`,
then `:restart`.

## Language servers and tools

```sh
brew bundle --file ~/Git/dotfiles/Brewfile      # install anything missing
brew upgrade                                     # update what is installed
```

Nothing in the config pins a server version. `vim.lsp.enable` starts whatever
is on `PATH` and silently skips what is not, so an uninstalled server degrades
to no diagnostics rather than an error.

## Treesitter parsers

Added by editing the `parsers` list in `lua/arpatek/plugins.lua`; missing ones
compile on the next start. To update the ones already built:

```
:lua require('nvim-treesitter').update()
```

## Neovim itself

```sh
brew upgrade neovim
```

This config requires 0.12+ for `vim.pack`, and 0.11+ for `vim.lsp.config` and
`vim.lsp.completion`. On a box with an older Neovim, use the zero-dependency
fallback instead:

```sh
nvim -u ~/.config/nvim/init.vim
```

## Adding a language server

1. `brew install <server>` and add it to the Brewfile
2. Create `lsp/<name>.lua` returning `{ cmd, filetypes, root_markers }`
3. Add `'<name>'` to the `vim.lsp.enable` list in `lua/arpatek/lsp.lua`
4. `:checkhealth vim.lsp` to confirm it is enabled and attached

## Adding a plugin

1. Add `{ src = 'https://github.com/...' }` to `vim.pack.add`
2. Call its `setup()` in `lua/arpatek/plugins.lua` — or behind a lazy wrapper
   like `arpatek.finder` if setup costs more than a millisecond or two
3. `:restart`
4. Check the dashboard footer; if load time moved, decide whether it earned it
