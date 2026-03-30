# Design Spec: Functional Minimalist Tmux Overhaul

**Date:** 2026-03-29  
**Goal:** Create a clean, Modern Minimalist tmux configuration that prioritizes essentials while being highly functional.

## 1. Core Behavior & Navigation
- **Prefix Key:** Keep `C-z` for prefix consistency.
- **Intuitive Splits:**
  - `|` for horizontal split (side-by-side)
  - `-` for vertical split (top-and-bottom)
  - Keep existing `v` and `s` as fallback bindings.
- **Vim-style Navigation:**
  - Keep `h/j/k/l` for pane selection.
  - Integration with `vim-tmux-navigator` for seamless switching between tmux panes and Vim/Nvim splits.
- **Mouse Support:**
  - Keep `mouse on` but optimize for easier scrolling and selection without jumping into copy-mode prematurely.
- **Indexing:**
  - Windows and panes start at `1` (base-index 1).
  - Enable automatic window renumbering when one is closed.

## 2. Status Bar: "The Modern"
- **Position:** `top` (already in place).
- **Layout:**
  - **Left:** Session name (` #S`) and current command (` #{pane_current_command}`) with subtle separators.
  - **Center:** Centered window list with high-contrast highlight for the active window.
  - **Right:** Truncated current path (` #{b:pane_current_path}`).
- **Theme:** Catppuccin Macchiato.
  - Active Window: `Peach` or `Maroon` (bold/reverse).
  - Inactive Windows: Dimmed `Rosewater` or `Overlay`.
  - Background: `none` (default) to match terminal.

## 3. Functional Plugins
- **tmux-plugins/tpm:** Keep as the plugin manager.
- **tmux-plugins/tmux-resurrect:** Manually save (`Prefix + C-s`) and restore (`Prefix + C-r`) tmux sessions.
- **tmux-plugins/tmux-continuum:** Automatically save sessions every 15 minutes and restore on boot.
- **tmux-plugins/tmux-yank:** Improve system clipboard integration (yank with `y` in copy-mode).
- **christoomey/vim-tmux-navigator:** Keep for seamless Vim/Nvim integration.

## 4. Key Bindings
| Action | Binding |
| :--- | :--- |
| Reload config | `Prefix + r` |
| Split horizontal | `Prefix + |` or `Prefix + v` |
| Split vertical | `Prefix + -` or `Prefix + s` |
| Navigation | `C-h/j/k/l` (with vim-tmux-navigator) |
| Kill window | `Prefix + w` |
| Kill pane | `Prefix + q` |
| Save session | `Prefix + C-s` (resurrect) |
| Restore session | `Prefix + C-r` (resurrect) |
