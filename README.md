# Neovim Configuration

Personal Neovim configuration built on [LazyVim](https://github.com/LazyVim/LazyVim).

## Getting Started

1. Install [Neovim](https://neovim.io) (>= 0.8.0)
2. Clone this repository to `~/.config/nvim`
3. Launch Neovim — plugins auto-install on first run

## Customizations

### Fuzzy Finder

- **[fff.nvim](https://github.com/dmtrKovalenko/fff.nvim)** replaces the default Telescope/Snacks picker
- Snacks picker is re-enabled for LazyVim's own buffer, git, and explorer keymaps
- Keybindings:
  - `<leader>ff` — Find files
  - `<leader>fg` — Live grep
  - `<leader>fw` — Grep word under cursor / selection

### Colorscheme

- **Rose Pine** ([neovim](https://github.com/rose-pine/neovim)) replaces the default theme
- Tokyonight fallback is disabled

### Linting

- Dynamic linter selection per project (`lua/plugins/oxlint.lua`):
  - `biomejs` if `biome.json`/`biome.jsonc` exists
  - `eslint_d` if ESLint config exists (upward search)
  - `oxlint` as fallback
- Config files are discovered via `vim.fs.find` (walks up from the buffer's directory)

### Formatting

- Cascading formatters: **oxfmt** → **biome** → **prettier**
- Each formatter only activates when its config file is detected in the project root
- `oxfmt` config files: `.oxfmtrc.json`, `.oxfmtrc.jsonc`, `oxfmt.config.ts`
- Prettier requires a config file to activate (`lazyvim_prettier_needs_config = true`)

### UI

- **Bufferline** disabled (tab pages used instead)
- **Lualine** simplified — only `location` shown in the status bar
- **Snacks** scroll disabled, notifier set to `minimal` style
- **Noice** cmdline and messages routed to the bottom `cmdline` view (no popups)
- Animations disabled (`g.snacks_animate = false`)
- Inline diagnostics (`virtual_text`) hidden; only `virtual_lines` shown for the current line
- Tab pages capped at 5 (new tabs beyond the limit are auto-closed)

### Languages

- **Rust**: `rustaceanvim` for LSP (instead of rust_analyzer standalone)
- **PHP**: `intelephense` (instead of phpactor)
- Enabled LazyVim extras: `lang.go`, `lang.php`, `lang.rust`, `lang.astro`, `lang.typescript`, `lang.vue`, `lang.markdown`
- Enabled LazyVim extra: `formatting.prettier`

### Keybindings

- `<D-/>` mapped to `gcc`/`gc` for macOS Command+/- commenting
- `<leader>yf` yanks the current buffer's relative path to the system clipboard
- Command-line typo aliases: `:Q` → `:q`, `:QA`/`:Qa` → `:qa`, `:QW` → `:qw`, etc.
- `X` restored to native behavior (delete char before cursor)
- See [`KEYMAPS.md`](KEYMAPS.md) for the full reference

## Documentation

- [LazyVim Docs](https://lazyvim.github.io/installation)
- [`KEYMAPS.md`](KEYMAPS.md) — full keymap reference
- Run `:help` in Neovim for built-in help
