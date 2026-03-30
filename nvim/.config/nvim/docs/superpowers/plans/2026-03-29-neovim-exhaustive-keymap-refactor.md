# Neovim Exhaustive Keymap Refactor Implementation Plan

**Goal:** Resolve all keymap conflicts by centralizing LSP mappings and eliminating prefix shadowing.

### Task 1: Move Rest Console Mapping
**Files:** `lua/plugins/rest.lua`
- [ ] Change `<leader>rr` to `<leader>rs` (REST Send) to free up the `<leader>r` prefix.

### Task 2: Refactor LSP Mappings in `coding.lua`
**Files:** `lua/plugins/coding.lua`
- [ ] Remove `on_attach` keymaps for LSP.
- [ ] Add global `keys` to `nvim-lspconfig` for:
    - `gd` (Goto Definition)
    - `gr` (References)
    - `<leader>rn` (Rename)
    - `<leader>ca` (Code Action)
    - `K` (Hover)
    - `[d` / `]d` (Diagnostics)

### Task 3: Clean up Scala LSP Mappings
**Files:** `lua/plugins/scala.lua`
- [ ] Remove duplicate LSP mappings from `on_attach` (gd, gr, rn, ca, K, diagnostics).
- [ ] Keep only metals-specific mappings (e.g., `<leader>mc`).

### Task 4: Final Verification
- [ ] Run `nvim --headless "+qa"` to ensure no errors.
- [ ] Verify `which-key` shows the new structure.
