# Neovim Configuration Optimization Design

## Goal
Perform a targeted surgical refactor of the Neovim configuration to fix latent bugs, resolve keymap conflicts, and prune redundant configurations while keeping the existing structure intact.

## Proposed Changes

### 1. Fix Neotest Configuration for Python
**Problem:** The `neotest` configuration in `lua/plugins/testing.lua` incorrectly attempts to load the `neotest-python` adapter by passing a table instead of invoking the required module.
**Solution:**
Update the `adapters` table in `testing.lua` to correctly require and initialize the `neotest-python` plugin:
```lua
adapters = {
  require("neotest-python")({
    dap = { justMyCode = false },
  }),
}
```

### 2. Modernize Commenting and Fix Dependency Errors
**Problem:** `mini.comment` is configured in `lua/plugins/editor.lua` to use `ts_context_commentstring`, but the `ts_context_commentstring` plugin is not installed. This causes evaluation errors. Furthermore, Neovim 0.10+ includes native commenting (`gc`).
**Solution:**
- Remove `mini.comment` from the `mini.nvim` configuration in `editor.lua`.
- Add `JoosepAlviste/nvim-ts-context-commentstring` as a standalone plugin in `coding.lua` (or `editor.lua`).
- Configure `nvim-ts-context-commentstring` to integrate with Neovim's native commenting (`vim.g.skip_ts_context_commentstring_module = true` and `require('ts_context_commentstring').setup { enable_autocmd = false }`).

### 3. Resolve Window Navigation Keymap Conflict
**Problem:** `lua/config/keymaps.lua` maps `<C-h/j/k/l>` to native Neovim split navigation, conflicting with the exact same mappings defined for `vim-tmux-navigator` in `lua/plugins/editor.lua`.
**Solution:**
Remove the redundant split navigation keymaps from `lua/config/keymaps.lua`. `vim-tmux-navigator` is already configured in `editor.lua` to handle these keystrokes for both Neovim splits and Tmux panes.

## Success Criteria
- Neotest can successfully discover and run Python tests without adapter initialization errors.
- Context-aware commenting works natively (e.g., in JSX/TSX) without `mini.comment` errors.
- Window navigation using `<C-h/j/k/l>` behaves predictably, seamlessly moving between Neovim splits (and Tmux panes).
