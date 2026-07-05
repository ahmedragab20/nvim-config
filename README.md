# Neovim Configuration

Personal Neovim configuration built on [LazyVim](https://github.com/LazyVim/LazyVim).

## Getting Started

1. Install [Neovim](https://neovim.io) (>= 0.8.0)
2. Clone this repository to `~/.config/nvim`
3. Launch Neovim — plugins auto-install on first run

## Customizations

### Fuzzy Finder

- **[fff.nvim](https://github.com/dmtrKovalenko/fff.nvim)** replaces the default Snacks/Telescope picker
- Snacks picker is disabled entirely
- Keybindings:
  - `<leader>ff` — Find files
  - `<leader>fg` — Live grep
  - `<leader>fw` — Grep word under cursor / selection

### Colorscheme

- **Nordfox** ([Nightfox](https://github.com/EdenEast/nightfox.nvim)) replaces the default theme

### Linting

- Smart linter selection per project (`lua/plugins/oxlint.lua`):
  - `biome` if `biome.json`/`biome.jsonc` exists
  - `eslint_d` if ESLint config exists
  - `oxlint` as fallback

### Formatting

- Custom **oxfmt** formatter with config file detection (`.oxfmtrc.json`, `.oxfmtrc.jsonc`, `oxfmt.config.ts`)
- Prettier requires a config file to activate

### Keybindings

- `<S-x>` remapped to `:close` (closes current window instead of command palette)

### UI

- Snacks notifier set to `minimal` style

### LazyVim Extras

- `lang.go`, `lang.php`, `lang.rust`, `lang.astro`, `lang.typescript`, `lang.vue`, `lang.markdown`
- `formatting.prettier`

## Documentation

- [LazyVim Docs](https://lazyvim.github.io/installation)
- Run `:help` in Neovim for built-in help
