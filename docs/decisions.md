# Decisions

## Why not kickstart.nvim as written

kickstart is built on lazy.nvim, mason.nvim, nvim-lspconfig and a completion
plugin. On 0.12 all four have built-in equivalents. Copying kickstart verbatim
means adopting four dependencies to do what the editor already does. This
config is kickstart's *structure* — single-purpose files, every line
commented — on 0.12's own primitives.

## Why servers come from Homebrew, not Mason

Mason is a package manager inside the editor. It installed 24 binaries into
`~/.local/share/nvim/mason/bin`, none of them on `PATH`, none of them known to
`Brewfile` or `ipkg-macos`. A new machine provisioned from the dotfiles repo
would have had no language servers at all, and `which pyright` answered
nothing while Neovim used it daily.

Homebrew already owns package installation on this machine. One manifest.

## Why `yamlvault` is its own filetype

`ansible-vault edit` decrypts a secret into `~/.ansible/tmp/…yml`, opens
`$EDITOR` on it, re-encrypts on exit and deletes the temp file. That path
accounted for 10 of the last 19 files opened in Neovim.

Treating it as `yaml` would mean:

- `yaml-language-server` receives the plaintext via `textDocument/didOpen`
- `schemaStore` makes an outbound request while the secret is in the buffer
- `undofile` writes the edit history to disk, outliving the deleted temp file

The filetype is `yamlvault` precisely because nothing in `lsp/` claims it.
`vim.treesitter.language.register('yaml', 'yamlvault')` restores highlighting
with no server involved.

## Why registers instead of a yank-ring plugin

`"0p` is the last yank, `"1p` through `"9p` the delete ring, `"+p` the system
clipboard. This works on every RHEL box reachable over SSH. A plugin's keymaps
do not, and building the habit matters more during RHCSA study than the
convenience does.

## Why yazi rather than a Neovim file explorer

`yazi` was already a Brewfile entry, so the machine had a file manager before
the editor needed one. Its `--chooser-file` contract is the entire
integration: it writes the chosen paths and exits, so the Neovim side is a
float, a job, and a `readfile`. No plugin, and no second set of navigation
keymaps to learn — inside the float, yazi's own keys apply.

This replaced oil.nvim, which was the earlier choice. oil's model (edit the
directory as a buffer, `:w` to apply) is good for bulk renames but is a third
mental model on top of yazi and netrw. One explorer, already familiar, wins.

## Why the dashboard has no selection highlight

Because snacks.dashboard has none. Its window options set
`cursorline = false` and it draws no highlight for the current item — the real
terminal cursor is the indicator, parked on the first word character of the
row. An earlier version here painted a full-width background bar, which read
as wrong next to the thing it was imitating.

The cursor column comes from `state.desc_cols`, recorded at render time, where
snacks finds it with a `find("[%w%d%p]")` scan. Same landing spot, one less
pattern match.

## Why the menu width scales and snacks' does not

snacks hardcodes `width = 60` and centers the pane. Here the menu is
`clamp(window_width * 0.72, 56, 78)` and the whole screen re-renders on
`VimResized`, which keeps the fixed-width ASCII banner centered too. This is a
deliberate departure, not an imitation gap.

The ceiling of 78 is `BANNER_WIDTH`, the logo's own width. Capping there means
the menu block never grows wider than the art above it: at 120 columns both
end on the same screen column. Raising the cap past 78 strands the key column
out past the banner's right edge and the two stop reading as one object.

## Which vimrc options were ported, and which were not

`options.lua` matches every option set in `~/.config/vim/vimrc` and
`~/.config/nvim/init.vim`, verified by diffing them against the running
config. Four were deliberately left out:

| Not ported | Why |
|---|---|
| `noerrorbells`, `visualbell` | Neovim defaults to `belloff=all`; no bell rings either way |
| `laststatus=2` | `3` here — one global statusline, not one per split |
| `nocompatible`, `filetype`, `syntax on` | Always on in Neovim |
| the `undodir` mkdir block | Neovim already defaults inside `stdpath('state')` |

`showmatch` and `matchtime=2` were genuinely missing and are now set; Neovim
defaults them to off and 5.

## Why mini.icons

fzf-lua's health check asks for `nvim-web-devicons` or `mini.icons`, and a
picker with no filetype icons reads as broken rather than minimal.
`mini.icons` over devicons because it does no patched-font probing at startup,
and `MiniIcons.mock_nvim_web_devicons()` makes it answer to the name fzf-lua
looks for.

## Why the providers are disabled

`vim.g.loaded_node_provider = 0` and its three siblings. Those providers exist
to host remote plugins written in node, perl, python or ruby. Nothing here is
one, so they produced six `:checkhealth` warnings about interpreters that
would never be used, plus executable probing at every start.

## Why fzf-lua configures itself lazily

`vim.pack` has no lazy-loading. `require('fzf-lua').setup()` is ~14ms of a
~53ms startup and is not needed until a picker opens — which for an
`ansible-vault edit` is never. `arpatek.finder` defers it behind a wrapper.

## Why the dashboard and statusline are hand-written

Both are under 160 lines and neither needs to be general. The banner and its
seven-stop gradient are lifted from `arpatek.dev/app/content/ascii.py`, so the
site and the editor render the same logo.

## Why nvim-treesitter is pinned to `main`

The `main` branch does parser installation only and hands highlighting back to
core via `vim.treesitter.start()`. Pinned explicitly because the repo default
branch is the older implementation with a different API.

## What was cut, and why

| Cut | Reason |
|---|---|
| DAP (6 plugins) | No breakpoint-debugging habit; adding back is 3 lines |
| dadbod, sqlfluff | Zero `.sql` files across all 15 repos; `psql` is the better tool |
| yanky | Registers do this, and they travel |
| dockerls, docker-compose-langserver | Four Docker files; `yamlls` covers compose, hadolint does the useful part |
| black | `ruff format` replaces it |
| tflint | Needs a third-party tap; `terraform-ls` reports `terraform validate` |
| noice, snacks, bufferline, trouble, which-key | Built-ins or unused |
