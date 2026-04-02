# AGENTS.md - Neovim Config

## Repository Overview
Neovim configuration written in Lua, managed with [lazy.nvim](https://github.com/folke/lazy.nvim).
Config lives at `~/.config/nvim` (this repo is symlinked or placed there).

## Project Structure
```
init.lua                    # Entry point: loads config, bootstraps lazy.nvim
lua/
  config/
    options.lua             # Vim options (tabstop, numbers, etc.)
    keymaps.lua             # Global key mappings
  plugins/
    plugins.lua             # Plugin specs (lazy.nvim format)
```

## Commands

### Testing / Validation
```bash
# Start nvim and check for errors
nvim

# Headless startup (exits immediately, shows errors)
nvim --headless +quit

# Check health of plugins/LSP
nvim +checkhealth

# Check health of specific component
nvim +checkhealth+lspconfig
nvim +checkhealth+nvim-treesitter

# Update plugins
nvim --headless "+Lazy! sync" +quit
```

### No build/lint/test tools exist
This is a dotfiles repo. Validate by running nvim and ensuring no startup errors.

## Code Style

### Language
- Pure Lua (no LuaJIT-specific features unless necessary)

### Formatting
- **Indentation**: 2 spaces (configured in `options.lua`)
- **No semicolons**
- **No trailing whitespace**
- Max line length: ~100 chars (soft limit)

### Imports / Requires
- Use `require("module.path")` for Lua modules
- Place requires at top of file or inline in `config` functions
- Alias frequently used modules: `local map = vim.keymap.set`

### Naming Conventions
- **Modules**: snake_case file paths matching directory structure (`config.options`)
- **Variables**: snake_case (`local lazypath = ...`)
- **Plugin repos**: `"owner/repo.nvim"` format (include `.nvim` suffix)
- **Keymap descriptions**: Title Case (`desc = "Find Files"`)

### Vim API Usage
- Prefer `vim.opt` over `vim.o`/`vim.bo`/`vim.wo` for options
- Prefer `vim.keymap.set` over `vim.api.nvim_set_keymap`
- Prefer `vim.fn` for Vimscript functions
- Use `vim.uv` or `vim.loop` for libuv (with fallback: `vim.uv or vim.loop`)

### Plugin Spec Format (lazy.nvim)
```lua
return {
  "owner/repo.nvim",
  priority = 1000,          -- if needed (e.g., colorschemes)
  dependencies = { "..." }, -- if needed
  build = ":TSUpdate",      -- if needed
  keys = {                  -- lazy-loaded keymaps
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Description" },
  },
  config = function()       -- setup code
    require("module").setup({ ... })
  end,
}
```

### Error Handling
- Use `vim.fn.has()` or `fs_stat()` for feature/file detection
- Guard plugin bootstrapping with existence checks (see `init.lua:5`)
- LSP servers use generic handler pattern — add per-server overrides as needed

### Keymap Guidelines
- Always include `{ desc = "Description" }` for which-key compatibility
- Use `<cmd>...<CR>` for Ex commands (safer than `:...`)
- Use `<leader>` prefix for custom mappings (leader = space)
- Group related keymaps in `keys` table within plugin specs when lazy-loading

### Adding New Plugins
1. Add spec to `lua/plugins/plugins.lua`
2. Use numbered comments to maintain order
3. Lazy-load with `keys`, `event`, or `ft` when possible
4. Keep `config` functions minimal — extract to separate modules if complex

### Adding New Config
- Options → `lua/config/options.lua`
- Keymaps → `lua/config/keymaps.lua`
- Complex logic → new file under `lua/config/` or `lua/plugins/`
