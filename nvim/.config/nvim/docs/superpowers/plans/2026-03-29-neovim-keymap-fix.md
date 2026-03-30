# Neovim Keymap Fixes

**Goal:** Resolve overlapping prefix keymap conflicts.

### Task 1: Fix Harpoon vs GitSigns Conflict
**Files:** `lua/plugins/editor.lua`
- [ ] Change Harpoon menu from `<leader>h` to `<C-e>`

### Task 2: Fix Conform vs Telescope Conflict
**Files:** `lua/plugins/coding.lua`
- [ ] Change Conform format from `<leader>f` to `<leader>cf`

### Task 3: Fix Mason vs Scala Metals Conflict
**Files:** `lua/plugins/coding.lua`
- [ ] Remove Mason mapping `<leader>m`
