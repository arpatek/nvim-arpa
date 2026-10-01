# Gotchas

## nvim-treesitter needs the `tree-sitter` CLI

The `main` branch shells out to `tree-sitter` to compile each parser. Without
it every install fails with:

```
Error during "tree-sitter build": ENOENT: no such file or directory (cmd): 'tree-sitter'
```

`:checkhealth` does not catch this. `brew install tree-sitter-cli` (it is in
the Brewfile). Note the formula is `tree-sitter-cli`, not `tree-sitter` — the
latter is the library Neovim links and does not provide the binary.

## `jsonc` is not a valid parser name on the `main` branch

It resolves to the `json` parser. Listing it produces
`warning: skipping unsupported language: jsonc`.

## Parsers are per-`NVIM_APPNAME`

They install to `stdpath('data')/site/parser`, which `NVIM_APPNAME` changes.
Parsers compiled under the LazyVim config are invisible here; this config
built its own 23. Expect a few minutes on first launch.

## HCL formatting needs a terraform or tofu binary

`terraform-ls` advertises `documentFormattingProvider = true` but returns no
edits without the CLI, because it shells out to `terraform fmt`. `conform`
only lists `tofu_fmt`/`terraform_fmt` when a binary exists — listing a missing
formatter makes conform report "Formatters unavailable" instead of falling
back to the LSP. Install `opentofu` (MPL-2.0) or `terraform` and it starts
working with no config change.

## `vim.pack` has no lazy-loading

Every `vim.pack.add` entry loads at startup. There is no `event` or `keys`
spec. Anything expensive has to defer itself, as `arpatek.finder` does. Watch
the dashboard footer: it prints config load time on every start.

## Plugin `plugin/` files still load during `init.lua`

`vim.pack.add`'s `load` option defaults to `false` *during* `init.lua`
sourcing, but Neovim sources `plugin/` directories from `runtimepath` after
init regardless. So `:FzfLua` and `:Oil` exist even though nothing calls
`setup()` at startup. Deferring the *setup call* is what saves time, not
deferring the load.

## pyright is slow to attach

~6–10s on a cold start, because it scans the workspace. `ruff` attaches almost
immediately, so a Python buffer briefly has one client and then two. Not a
fault.

## `marksman` pulls in dotnet@9

~620MB of .NET runtime for markdown link completion. If that trade is wrong,
`brew uninstall marksman dotnet@9` and drop `'marksman'` from the
`vim.lsp.enable` list in `lua/arpatek/lsp.lua`.

## `vim.opt.shada = ''` in a vault buffer is global

`vault.lua` clears `shada` rather than setting it buffer-local, because there
is no buffer-local `shada`. The effect lasts for that Neovim session. Since
`ansible-vault edit` spawns a dedicated short-lived instance, that is the
correct scope — but do not expect it to reset if you open a vault file inside
a long-running session.

## `rg` can look installed when it is not

`command -v rg` reported success in an interactive shell while
`vim.fn.executable('rg')` returned 0 and no `rg` binary existed anywhere on
`PATH`. The `grepprg` block in `options.lua` is guarded by
`vim.fn.executable('rg') == 1`, so the config silently kept plain `grep`
instead of erroring — correct behavior, but it hides the problem.

`:checkhealth` is the reliable check: `vim.health` reports
`WARNING ripgrep not available`. Both `ripgrep` and `fd` are in the Brewfile
now; fzf-lua prefers `fd` over `find`, and its health check errors with
`find: illegal option -- -` on macOS because BSD `find` has no `--version`.

## yazi's float needs to be focused before the job starts

`vim.fn.jobstart(..., { term = true })` attaches the terminal to the *current*
buffer, so `open_float()` has to create and focus the float first. Reordering
those two calls puts a yazi terminal into whatever file you were editing.

## Quitting yazi with `q` writes no chooser file

`vim.fn.readfile` throws on a missing file, so the `on_exit` handler wraps it
in `pcall`. An empty or absent chooser file means "no selection" and is not an
error.

## Never measure art with `strdisplaywidth`

`vim.fn.strdisplaywidth` is window-relative and breakindent-aware. For the
79-cell first line of the big banner in an 80-column window it returns **88**,
because it adds the `breakindent` of the continuation the line would wrap onto
— 9 cells, the line's own leading whitespace. Lines of 74 cells never reach the
wrap point and measure correctly, which is what made it look like a
character-encoding problem rather than a wrapping one.

Prefixes of the same string up to 70 cells all measure correctly. The jump
appears only once the string crosses the window width.

Use `vim.api.nvim_strwidth`, which measures cells with no display context.
Measuring banner art with `strdisplaywidth` makes the layout depend on the
window width it is being compared against, which silently shifted every
threshold: `BANNER_WIDTH` read as 88 instead of 79, so an 83-column window
fell through to the small banner.

## The dashboard window must restore its options

`number`, `relativenumber`, `cursorline`, `list`, `wrap`, `signcolumn` and
`fillchars` are **window**-local, not buffer-local. The dashboard turns them
off, and pressing `n` runs `:ene` in that same window, so a new file inherited
`number=false` and `signcolumn=no`.

`M.open()` captures the originals once into `state.saved_wo` and a `BufWipeout`
autocmd on the dashboard buffer puts them back. `bufhidden=wipe` is what makes
that fire: replacing the buffer in the window wipes it. Capturing is guarded on
`state.saved_wo` being nil so a `VimResized` re-render does not save the
already-overridden values.

## The dashboard needs the global statusline to opt out

With `laststatus=3` there is one global statusline and window-local
`statusline` values are ignored, so snacks' trick of blanking it per-window
does nothing here. Without a guard, the statusline renders `[Scratch]` from
`%f` and `[-]` from `%m` over the dashboard. `arpatek.statusline.render()`
returns an empty string when the buffer in `vim.g.statusline_winid` has
filetype `arpatek-dashboard`.

## The dashboard menu needs the *Mono* Nerd Font variant

Every menu row is padded to the same display width using
`strdisplaywidth`, which reports 1 for all the glyphs used, including the
4-byte plane-15 ones (`U+F024B`, `U+F04B2`, `U+F05E1`). Ghostty is configured
with `JetBrainsMono Nerd Font Mono`, whose whole point is forcing every glyph
into a single cell, so the columns line up.

Switching to the non-Mono `JetBrainsMono Nerd Font` makes those glyphs render
double-width while Neovim still counts them as one, and the right-aligned keys
shift a column on those rows. The fix would be a trailing space in the icon
string, which is what snacks.dashboard does.

## Dashboard selection follows the cursor, via CursorMoved

`<Up>`/`<Down>`/`j`/`k` call `move()`, but any other motion — a mouse click,
`gg`, `G`, `<C-d>` — is caught by a buffer-local `CursorMoved` autocmd that
clamps the cursor back onto a menu row and moves the selection to match. That
is why those keys are not mapped to `<Nop>`. The clamp also corrects the
column, since a click lands wherever it was pressed.

Note when testing this headlessly: `nvim_feedkeys(..., 'x', false)` does not
fire `CursorMoved`, so the clamp appears broken. `:doautocmd CursorMoved`
confirms it works. The same applies to `VimResized`.

## `state.first` is 0-based, `nvim_win_set_cursor` is 1-based

`state.first` holds the buffer row of the first menu entry as extmarks and
`nvim_buf_get_lines` use it: 0-based. `nvim_win_set_cursor` takes a 1-based
row, so entry `i` is at `state.first + i`, not `state.first + i - 1`. Getting
this wrong parks the cursor on the blank line above the menu, which also
silently clamps the column to 0 because that line is empty.

## A 9-row menu needs a 9-row window

`minimal` mode renders the 9 menu entries and nothing else. In a window
shorter than that — a 24x10 terminal is a 24x8 window — it does not fit and
scrolls. Nothing to be done short of dropping entries, and `:DashboardInfo`
reports the window size and which thresholds applied.

## LazyVim is untouched

It remains at `~/.config/nvim` and runs on a bare `nvim`. This config only
runs under `NVIM_APPNAME=nvim-arpatek`. Removing it is
`rm -rf ~/.config/nvim-arpatek ~/.local/share/nvim-arpatek ~/.local/state/nvim-arpatek`.
