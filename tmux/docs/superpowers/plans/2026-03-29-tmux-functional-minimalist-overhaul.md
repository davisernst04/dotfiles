# Functional Minimalist Tmux Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a clean, Modern Minimalist tmux configuration that prioritizes essentials while being highly functional, as specified in the [design spec](../specs/2026-03-29-tmux-functional-minimalist-design.md).

**Architecture:** The overhaul will be implemented by modifying `.tmux.conf` to clean up existing configurations and add new plugins via TPM. The status bar will be redesigned using Catppuccin themes and custom formatting to achieve the "Modern" look.

**Tech Stack:** `tmux`, `tpm`, `Catppuccin Macchiato`, `tmux-resurrect`, `tmux-continuum`, `tmux-yank`, `vim-tmux-navigator`.

---

### Task 1: Backup Current Configuration

**Files:**
- Create: `/home/davis/dotfiles/tmux/.tmux.conf.bak`

- [ ] **Step 1: Backup `.tmux.conf`**

Run: `cp /home/davis/dotfiles/tmux/.tmux.conf /home/davis/dotfiles/tmux/.tmux.conf.bak`

- [ ] **Step 2: Verify backup exists**

Run: `ls -la /home/davis/dotfiles/tmux/.tmux.conf.bak`
Expected: File exists and has same size as `.tmux.conf`

- [ ] **Step 3: Commit backup**

```bash
git add /home/davis/dotfiles/tmux/.tmux.conf.bak
git commit -m "chore: backup current tmux configuration before overhaul"
```

---

### Task 2: Configure Core Options and Intuitive Key Bindings

**Files:**
- Modify: `/home/davis/dotfiles/tmux/.tmux.conf`

- [ ] **Step 1: Add intuitive split bindings (`|` and `-`)**

Modify `.tmux.conf`:
```tmux
# Split windows using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
# Keep existing v and s as well
bind v split-window -h -c "#{pane_current_path}"
bind s split-window -v -c "#{pane_current_path}"
```

- [ ] **Step 2: Add automatic window renumbering and base index**

Modify `.tmux.conf` (ensure these are present):
```tmux
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
```

- [ ] **Step 3: Test key bindings**

Run: `tmux source-file /home/davis/dotfiles/tmux/.tmux.conf` and manually test `Prefix + |` and `Prefix + -`.
Expected: Horizontal and vertical splits work in the current path.

- [ ] **Step 4: Commit core changes**

```bash
git add /home/davis/dotfiles/tmux/.tmux.conf
git commit -m "feat: add intuitive split bindings and core options"
```

---

### Task 3: Implement "The Modern" Status Bar Layout

**Files:**
- Modify: `/home/davis/dotfiles/tmux/.tmux.conf`

- [ ] **Step 1: Clean up old status bar configuration**

Remove the following lines/blocks from `.tmux.conf`:
- The entire `set -g @custom_choose_tree_format` block.
- All `set -ga status-right` and `set -ga status-left` calls.
- Old window status formats.

- [ ] **Step 2: Implement "The Modern" status bar layout**

Add to `.tmux.conf`:
```tmux
# Status bar appearance
set -g status-position top
set -g status-justify centre
set -g status-left-length 80
set -g status-right-length 80

# Status Left: Session and current command
set -g status-left "#[fg=#{@thm_green},bg=default,bold]  #S #[fg=#{@thm_overlay_0},none]| #[fg=#{@thm_maroon},bg=default]  #{pane_current_command} "

# Status Right: Current path (truncated)
set -g status-right "#[fg=#{@thm_blue},bg=default]  #{=/24/...:#{b:pane_current_path}} "

# Window Status Format (Centered)
set -gF window-status-separator "#[fg=#{@thm_overlay_0}] "
set -g window-status-format " #I:#W "
set -g window-status-style "fg=#{@thm_rosewater},bg=default"
set -g window-status-last-style "fg=#{@thm_peach}"
set -g window-status-current-format " #I:#W "
set -g window-status-current-style "fg=#{@thm_peach},bold,reverse"
```

- [ ] **Step 3: Reload and verify status bar**

Run: `tmux source-file /home/davis/dotfiles/tmux/.tmux.conf`
Expected: Status bar is at the top, window list is centered, session/command on the left, path on the right.

- [ ] **Step 4: Commit status bar changes**

```bash
git add /home/davis/dotfiles/tmux/.tmux.conf
git commit -m "feat: implement modern minimalist status bar layout"
```

---

### Task 4: Add and Configure Functional Plugins

**Files:**
- Modify: `/home/davis/dotfiles/tmux/.tmux.conf`

- [ ] **Step 1: Add Resurrect, Continuum, and Yank to plugin list**

Modify the plugin list in `.tmux.conf`:
```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
```

- [ ] **Step 2: Configure Resurrect and Continuum**

Add to `.tmux.conf`:
```tmux
# Resurrect/Continuum configuration
set -g @continuum-restore 'on'
set -g @resurrect-strategy-nvim 'session'
```

- [ ] **Step 3: Install plugins via TPM**

Run: `~/.tmux/plugins/tpm/bin/install_plugins` (or press `Prefix + I` in tmux).
Expected: Plugins are downloaded and installed in `~/.tmux/plugins/`.

- [ ] **Step 4: Commit plugin changes**

```bash
git add /home/davis/dotfiles/tmux/.tmux.conf
git commit -m "feat: add resurrect, continuum, and yank plugins"
```

---

### Task 5: Final Cleanup and Validation

**Files:**
- Modify: `/home/davis/dotfiles/tmux/.tmux.conf`

- [ ] **Step 1: Remove redundant bindings and formatting**

Check for any remaining bindings that conflict with the new plan (like the old `choose-tree` format which is no longer used).

- [ ] **Step 2: Final reload and end-to-end test**

Run: `tmux source-file /home/davis/dotfiles/tmux/.tmux.conf`
Test:
- `Prefix + |` splits horizontally.
- `Prefix + -` splits vertically.
- Centered status bar looks correct.
- `y` in copy-mode yanks to system clipboard (requires `tmux-yank`).
- Session info is displayed on the left.

- [ ] **Step 3: Commit final cleanup**

```bash
git add /home/davis/dotfiles/tmux/.tmux.conf
git commit -m "chore: final cleanup and validation of minimalist overhaul"
```
