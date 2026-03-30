# Neovim Configuration Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perform a targeted surgical refactor of the Neovim configuration to fix latent bugs, resolve keymap conflicts, and prune redundant configurations.

**Architecture:** We are updating existing Lua configuration files within a `lazy.nvim` based Neovim setup. We will surgically replace incorrect configurations with their correct counterparts.

**Tech Stack:** Neovim, Lua, lazy.nvim

---

### Task 1: Fix Neotest Configuration for Python

**Files:**
- Modify: `lua/plugins/testing.lua`

- [ ] **Step 1: Update the neotest-python adapter initialization**

In `lua/plugins/testing.lua`, find the `adapters` table within the `opts` section. Replace the incorrect table-based configuration:
```lua
			adapters = {
				["neotest-python"] = {
					dap = { justMyCode = false },
				},
			},
```
with the correct function call:
```lua
			adapters = {
				require("neotest-python")({
					dap = { justMyCode = false },
				}),
			},
```

- [ ] **Step 2: Verify the change (Manual Check)**

Open Neovim and ensure no errors are thrown during startup. You can run `:checkhealth` or open a Python file and run `:Neotest run` to ensure the adapter loads (even if no tests are present).
Run: `nvim --headless "+qa"`
Expected: No errors outputted to stderr.

- [ ] **Step 3: Commit**

```bash
git add lua/plugins/testing.lua
git commit -m "fix(testing): correctly initialize neotest-python adapter"
```

---

### Task 2: Modernize Commenting and Fix Dependency Errors

**Files:**
- Modify: `lua/plugins/editor.lua`
- Modify: `lua/plugins/coding.lua`

- [ ] **Step 1: Remove `mini.comment` from `editor.lua`**

In `lua/plugins/editor.lua`, locate the `mini.nvim` plugin configuration. Remove the `mini.comment` setup block completely:
```lua
			require("mini.comment").setup({
				options = {
					custom_commentstring = function()
						return require("ts_context_commentstring.internal").calculate_commentstring()
							or vim.bo.commentstring
					end,
				},
			})
```

- [ ] **Step 2: Add `nvim-ts-context-commentstring` to `coding.lua`**

In `lua/plugins/coding.lua`, add the new plugin configuration to the `lazy.nvim` spec array. You can place it near the end of the file before the final `}`.
```lua
	-- Context-aware commenting (integrates with native gc)
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		opts = {
			enable_autocmd = false,
		},
		config = function(_, opts)
			vim.g.skip_ts_context_commentstring_module = true
			require("ts_context_commentstring").setup(opts)
		end,
	},
```

- [ ] **Step 3: Verify the change (Manual Check)**

Open Neovim. There should be no errors about missing `ts_context_commentstring`.
Run: `nvim --headless "+qa"`
Expected: No errors outputted to stderr.

- [ ] **Step 4: Commit**

```bash
git add lua/plugins/editor.lua lua/plugins/coding.lua
git commit -m "refactor(coding): replace mini.comment with native gc and ts-context-commentstring"
```

---

### Task 3: Resolve Window Navigation Keymap Conflict

**Files:**
- Modify: `lua/config/keymaps.lua`

- [ ] **Step 1: Remove redundant split navigation keymaps**

In `lua/config/keymaps.lua`, locate and delete the following lines under the "Better split navigation" comment:
```lua
-- Better split navigation
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move Left" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move Right" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move Down" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move Up" })
```
You can also remove the "Better split navigation" comment itself if you prefer.

- [ ] **Step 2: Verify the change (Manual Check)**

Open Neovim. Verify that `<C-h>`, `<C-j>`, `<C-k>`, and `<C-l>` still navigate between splits correctly. Since `vim-tmux-navigator` is configured in `editor.lua` for these keys, the functionality should remain intact without the conflict.
Run: `nvim --headless "+qa"`
Expected: No errors outputted to stderr.

- [ ] **Step 3: Commit**

```bash
git add lua/config/keymaps.lua
git commit -m "fix(keymaps): remove conflicting split navigation maps to favor tmux-navigator"
```
