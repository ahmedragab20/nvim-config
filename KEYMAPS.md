# Neovim keymap cheat sheet

`<leader>` is the configured leader key. Modes are **Normal**, **Insert**, and
**Visual** unless a table says otherwise.

## Changed and streamlined mappings

| Keymap | Mode | Action now | Change |
| --- | --- | --- | --- |
| `<leader>ff` | Normal | Find files with FFF | Uses the lazy-loaded FFF picker |
| `<leader>fg` | Normal | Live grep with FFF | Uses the lazy-loaded FFF picker |
| `<leader>fw` | Normal / Visual | Search the word or selection with FFF | Uses the lazy-loaded FFF picker |
| `<D-/>` | Normal | Toggle the current line comment | macOS alias for native `gcc` |
| `<D-/>` | Visual | Toggle the selected lines | macOS alias for native `gc` |
| `gc` + motion | Normal | Toggle comments over a motion | Native Neovim behavior |
| `gcc` | Normal | Toggle the current line comment | Native Neovim behavior |
| `<leader>bd` | Normal | Delete the current buffer | LazyVim/Snacks implementation |
| `<leader>wd` | Normal | Close the current window | Replaces the removed `<S-x>` override |
| `X` | Normal | Delete the character before the cursor | Native Vim behavior restored |
| `<S-h>` / `<S-l>` | Normal | Previous / next buffer | LazyVim buffer navigation |
| `[b` / `]b` | Normal | Previous / next buffer | LazyVim buffer navigation |
| `<S-Left>` / `<S-Right>` | Normal | Unmapped | Broken BufferLine mappings removed |
| `<leader>uz` | Normal | Toggle Snacks Zen mode | Replaces the standalone Zen Mode plugin |

`<D-/>` means <kbd>Cmd</kbd>+<kbd>/</kbd>. Terminal emulators do not all send
Command-key combinations to Neovim, so use native `gcc`/`gc` when that mapping
is unavailable.

## Files, search, and explorer

| Keymap | Action |
| --- | --- |
| `<leader>ff` | Find files with FFF |
| `<leader>fg` | Live grep with FFF |
| `<leader>fw` | Search the current word or visual selection with FFF |
| `<leader>,` | Select an open buffer |
| `<leader>fb` | Select an open buffer |
| `<leader>fn` | Create a new file |
| `<leader>yf` | Copy the current buffer path |
| `<leader>sg` | Grep from the project root |
| `<leader>e` | Open the project-root explorer |
| `<leader>E` | Open the explorer at the current working directory |

## Buffers

| Keymap | Action |
| --- | --- |
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `[b` | Previous buffer |
| `]b` | Next buffer |
| `<leader>bb` | Switch to the alternate buffer |
| `` <leader>` `` | Switch to the alternate buffer |
| `<leader>bd` | Delete the current buffer |
| `<leader>bo` | Delete other buffers |
| `<leader>bi` | Delete invisible buffers |
| `<leader>bD` | Delete the buffer and its window |

## Windows and tab pages

| Keymap | Action |
| --- | --- |
| `<C-h>` | Focus the left window |
| `<C-j>` | Focus the lower window |
| `<C-k>` | Focus the upper window |
| `<C-l>` | Focus the right window |
| `<leader>-` | Split the window horizontally |
| `<leader>\|` | Split the window vertically |
| `<leader>wd` | Close the current window |
| `<leader>wm` | Toggle window zoom |
| `<C-Up>` | Increase window height |
| `<C-Down>` | Decrease window height |
| `<C-Left>` | Decrease window width |
| `<C-Right>` | Increase window width |
| `<leader><tab><tab>` | Create a new tab page (maximum five) |
| `<leader><tab>]` | Go to the next tab page |
| `<leader><tab>[` | Go to the previous tab page |
| `<leader><tab>f` | Go to the first tab page |
| `<leader><tab>l` | Go to the last tab page |
| `<leader><tab>d` | Close the current tab page |
| `<leader><tab>o` | Close all other tab pages |

Tab pages are capped at five. Opening a sixth rejects only the newly opened tab;
its buffer remains available.

## Editing

| Keymap | Mode | Action |
| --- | --- | --- |
| `gcc` | Normal | Comment the current line |
| `gc` + motion | Normal | Comment a motion |
| `gc` | Visual | Comment the selection |
| `gco` | Normal | Add a commented line below |
| `gcO` | Normal | Add a commented line above |
| `<D-/>` | Normal / Visual | Comment the line or selection |
| `<A-j>` | Normal / Insert / Visual | Move the line or selection down |
| `<A-k>` | Normal / Insert / Visual | Move the line or selection up |
| `<` / `>` | Visual | Indent while retaining the selection |
| `<C-s>` | Normal / Insert / Visual | Save the file |
| `<Esc>` | Normal / Insert | Escape and clear search highlighting |

## Code and diagnostics

| Keymap | Action |
| --- | --- |
| `<leader>cf` | Format the file or selection |
| `<leader>cd` | Show line diagnostics |
| `]d` / `[d` | Next / previous diagnostic |
| `]e` / `[e` | Next / previous error |
| `]w` / `[w` | Next / previous warning |
| `]c` / `[c` | Next / previous Git hunk |
| `<leader>ud` | Toggle diagnostics |
| `<leader>uh` | Toggle LSP inlay hints |
| `<leader>uf` | Toggle automatic formatting |

## Git

| Keymap | Action |
| --- | --- |
| `<leader>gg` | Open Lazygit at the project root |
| `<leader>gG` | Open Lazygit at the working directory |
| `<leader>gL` | Show the Git log for the working directory |
| `<leader>gl` | Show the Git log for the project root |
| `<leader>gb` | Show Git blame for the current line |
| `<leader>gf` | Show the current file's history |
| `<leader>gB` | Open the current location on the Git host |
| `<leader>gY` | Copy the Git-host URL |
| `<leader>g[` | Restore (reset) the hunk under the cursor |

The Lazygit mappings are available when the `lazygit` executable is installed.

## UI and utilities

| Keymap | Action |
| --- | --- |
| `<leader>uz` | Toggle Zen mode |
| `<leader>wm` | Toggle window zoom |
| `<leader>us` | Toggle spelling |
| `<leader>uw` | Toggle line wrapping |
| `<leader>ul` | Toggle line numbers |
| `<leader>uL` | Toggle relative line numbers |
| `<leader>ub` | Toggle the dark/light background |
| `<leader>l` | Open the Lazy plugin manager |
| `<leader>qq` | Quit Neovim |
| `<C-/>` | Toggle the project-root terminal |
| `<leader>ft` | Open a terminal at the project root |
| `<leader>fT` | Open a terminal at the working directory |

## Exact-command typo aliases

These aliases expand only when the entire Ex command matches. They do not alter
filenames or command arguments.

| Typed | Executes |
| --- | --- |
| `:Q` | `:q` |
| `:QA`, `:Qa` | `:qa` |
| `:QW`, `:Qw` | `:qw` |
| `:QWA`, `:QWa` | `:qwa` |
| `:QWq`, `:Qwq` | `:qwq` |
