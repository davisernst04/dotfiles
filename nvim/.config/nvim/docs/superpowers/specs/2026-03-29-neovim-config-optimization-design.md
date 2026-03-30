# Neovim Config Optimization Design Spec

## 1. Goal
Build a minimal, fast, and maintainable Neovim configuration based on the user's current `lazy.nvim` setup. The configuration will prioritize performance (startup time < 30ms) while retaining essential IDE-like features for Python, Web Development, DevOps, and Scala.

## 2. Architecture & File Structure
The project will adopt an **Optimized Custom Config** architecture, utilizing strict lazy-loading.

*   `init.lua`: Minimal bootstrap for `lazy.nvim` and basic option loading.
*   `lua/config/options.lua`: Core Neovim options (loads immediately).
*   `lua/config/keymaps.lua`: Global keymaps (loads immediately).
*   `lua/config/autocmds.lua`: (New) Autocommands for yank highlighting, format-on-save, and window resizing (loads immediately).
*   `lua/plugins/*.lua`: Logical groupings of plugins.

## 3. Aggressive Lazy Loading Strategy
To achieve near-zero startup time, plugins will be loaded based on specific triggers:

*   **UI Plugins** (`tokyonight`, `lualine`, `which-key`, `indent-blankline`, `colorizer`): Load on `VeryLazy` or `UIEnter`.
*   **Editor Navigation & Search** (`telescope`, `neo-tree`, `harpoon`, `flash`, `spectre`, `lazygit`, `undotree`): Load *only* on their respective commands (`cmd`) or keys (`keys`).
*   **Coding & Completion** (`nvim-cmp`, `autopairs`, `copilot`): Load strictly on `InsertEnter`.
*   **Language Intelligence** (`nvim-lspconfig`, `nvim-treesitter`, `mason`): Load on `BufReadPre` and `BufNewFile`.
*   **Formatting & Linting** (`conform`, `nvim-lint`): Trigger specifically on `BufWritePre` or by filetype (`ft`).

## 4. Optimizations
*   **Dependency Pruning**: Ensure `mason-tool-installer` only installs the essential tools for the selected stack:
    *   *Python*: `pyright`, `black`, `isort`, `pylint`.
    *   *Web Dev*: `html-lsp`, `css-lsp`, `tailwindcss-language-server`, `typescript-language-server`, `json-lsp`, `emmet-language-server`, `prettierd`, `eslint_d`.
    *   *DevOps*: `dockerls`, `docker-compose-language-service`, `dockerfile-language-server`, `bashls`.
    *   *Scala*: `metals` (via `nvim-metals` or basic `lspconfig`).
    *   *Core*: `stylua`, `lua-language-server`.
*   **Keymap Isolation**: Move all plugin-specific keymaps from `keymaps.lua` into their respective `lazy.nvim` definitions under the `keys` table, preventing plugins from loading just to define keymaps.
*   **Module Review**: Refine configurations for `mini.nvim` modules to ensure they don't break the `VeryLazy` boundary.

## 5. Success Criteria
*   The `init.lua` is clean and declarative.
*   The `lazy.nvim` profiler shows a startup time of < 30ms (excluding the time to load the first buffer).
*   LSP, autocompletion, formatting, and linting work out of the box for the specified languages.
