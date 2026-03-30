# Neovim Config Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal, fast, and maintainable Neovim configuration prioritizing a startup time of < 30ms while retaining essential IDE-like features.

**Architecture:** Optimized Custom Config using `lazy.nvim` with aggressive lazy-loading triggers (`event`, `cmd`, `keys`, `ft`).

**Tech Stack:** Neovim, Lua, lazy.nvim.

---

### Task 1: Core Initialization & Autocommands

**Files:**
- Modify: `init.lua`
- Modify: `lua/config/options.lua`
- Modify: `lua/config/keymaps.lua`
- Create: `lua/config/autocmds.lua`

- [ ] **Step 1: Create `lua/config/autocmds.lua`**

```lua
-- lua/config/autocmds.lua
local function augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})
```

- [ ] **Step 2: Update `init.lua` to load autocommands**

```lua
-- init.lua
require("config.options")
require("config.keymaps")
require("config.autocmds")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  ui = { border = "rounded" },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

- [ ] **Step 3: Update `lua/config/options.lua` (keep existing, just verify syntax)**
*(No code changes required for options unless stripping non-minimal ones, but we will keep the user's base options. We just ensure it's clean).*

- [ ] **Step 4: Clean up `lua/config/keymaps.lua`**
Remove plugin-specific keymaps (like `<leader>m` for Mason). Keep only core keymaps.

```lua
-- lua/config/keymaps.lua
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- Better split navigation
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move Left" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move Right" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move Down" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move Up" })

-- Resize splits with arrow keys
map("n", "<Up>", ":resize +2<CR>", { desc = "Resize Up" })
map("n", "<Down>", ":resize -2<CR>", { desc = "Resize Down" })
map("n", "<Left>", ":vertical resize -2<CR>", { desc = "Resize Left" })
map("n", "<Right>", ":vertical resize +2<CR>", { desc = "Resize Right" })

-- Move lines
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Terminal Exit
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
```

- [ ] **Step 5: Verify Core Config Loading**
Run: `nvim --headless -c "lua require('config.autocmds'); print('Core loaded')" -c "qa"`
Expected: No errors.

- [ ] **Step 6: Commit**
```bash
git add init.lua lua/config/
git commit -m "refactor(core): optimize init and core configs"
```

---

### Task 2: UI Plugins Optimization

**Files:**
- Modify: `lua/plugins/ui.lua`

- [ ] **Step 1: Set UI Plugins to `event = "VeryLazy"` or `event = "UIEnter"`**

```lua
-- lua/plugins/ui.lua
return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = { theme = "tokyonight", globalstatus = true, component_separators = "|" },
      sections = { lualine_c = { { "filename", path = 1 } } },
    },
  },
  -- Indent Guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    main = "ibl",
    opts = { indent = { char = "│" }, scope = { enabled = false } },
  },
  -- Key Helper
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  -- Color Highlighting
  {
    "NvChad/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = { user_default_options = { tailwind = true, css = true } },
  },
}
```

- [ ] **Step 2: Verify Syntax**
Run: `nvim --headless -c "lua dofile('lua/plugins/ui.lua')" -c "qa"`
Expected: No errors.

- [ ] **Step 3: Commit**
```bash
git add lua/plugins/ui.lua
git commit -m "perf(ui): lazy load ui plugins on VeryLazy"
```

---

### Task 3: Editor Navigation Plugins Optimization

**Files:**
- Modify: `lua/plugins/editor.lua`

- [ ] **Step 1: Ensure strict `cmd` and `keys` loading**

```lua
-- lua/plugins/editor.lua
return {
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fw", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader><leader>", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        extensions = { ["ui-select"] = require("telescope.themes").get_dropdown() },
        defaults = {
          file_ignore_patterns = { "node_modules", ".git" },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case",
          },
        },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
    end,
  },

  -- NeoTree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = { { "\\", "<cmd>Neotree toggle<cr>", desc = "NeoTree" } },
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      filesystem = {
        filtered_items = { visible = true, hide_gitignored = true },
        hijack_netrw_behavior = "open_current",
      },
    },
  },

  -- Spectre
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
  },

  -- Flash Navigation
  {
    "folke/flash.nvim",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "windwp/nvim-ts-autotag",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "javascript", "typescript", "tsx", "html", "css", "json", "python", "bash", "scala", "csv", "http" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true, disable = { "python" } },
        autotag = { enable = true },
      })
    end,
  },

  -- Harpoon
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon Add" },
      { "<leader>h", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon Menu" },
      { "<C-n>", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<C-p>", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
    },
    config = function()
      require("harpoon"):setup()
    end,
  },

  -- GitSigns
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, opts)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = opts.desc })
        end
        map("n", "]h", gs.next_hunk, { desc = "Next Hunk" })
        map("n", "[h", gs.prev_hunk, { desc = "Prev Hunk" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
        map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset Hunk" })
      end,
    },
  },

  -- DAP
  {
    "mfussenegger/nvim-dap",
    keys = { "<F5>", "<F10>", "<F11>", "<F12>", "<leader>b" },
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
    end,
  },

  -- Mini Modules
  {
    "echasnovski/mini.nvim",
    event = { "BufReadPost", "BufNewFile" },
    version = false,
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
      require("mini.surround").setup()
      require("mini.comment").setup({
        options = {
          custom_commentstring = function()
            return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
          end,
        },
      })
    end,
  },

  { "mbbill/undotree", keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "UndoTree" } } },
  { "folke/todo-comments.nvim", event = { "BufReadPost", "BufNewFile" }, dependencies = { "nvim-lua/plenary.nvim" }, opts = {} },
  { "folke/trouble.nvim", cmd = "Trouble", opts = {} },
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    },
  },
}
```

- [ ] **Step 2: Verify Syntax**
Run: `nvim --headless -c "lua dofile('lua/plugins/editor.lua')" -c "qa"`
Expected: No errors.

- [ ] **Step 3: Commit**
```bash
git add lua/plugins/editor.lua
git commit -m "perf(editor): strictly lazy-load editor plugins"
```

---

### Task 4: Coding Tools & LSP Optimization

**Files:**
- Modify: `lua/plugins/coding.lua`

- [ ] **Step 1: Optimize Mason, LSP, CMP, and Formatting**
Update `mason-tool-installer` to strictly include only essential tools. Set formatting/linting on file open. Set Mason keymap directly in the module.

```lua
-- lua/plugins/coding.lua
return {
  { "tpope/vim-sleuth", event = { "BufReadPost", "BufNewFile" } },

  -- 1. MASON
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>m", "<cmd>Mason<cr>", desc = "Mason Manager" } },
    opts = { ui = { border = "rounded" } },
  },

  -- 2. LSP CONFIG
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end
        map("gd", vim.lsp.buf.definition, "Goto Definition")
        map("gr", vim.lsp.buf.references, "References")
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("K", vim.lsp.buf.hover, "Hover")
        map("[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
        map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
      end

      require("mason-tool-installer").setup({
        ensure_installed = {
          "html-lsp", "css-lsp", "tailwindcss-language-server",
          "pyright", "black", "isort", "pylint",
          "typescript-language-server", "json-lsp", "prettierd", "eslint_d",
          "lua-language-server", "stylua",
          "dockerls", "docker-compose-language-service", "dockerfile-language-server", "bash-language-server",
        },
      })

      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            local opts = { capabilities = capabilities, on_attach = on_attach }
            if server_name == "lua_ls" then
              opts.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
            end
            require("lspconfig")[server_name].setup(opts)
          end,
        },
      })
    end,
  },

  -- 3. AUTO PAIRS
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      require("nvim-autopairs").setup({})
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- 4. COMPLETION (CMP)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-path", "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if require("copilot.suggestion").is_visible() then require("copilot.suggestion").accept()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "luasnip", priority = 1000 },
          { name = "nvim_lsp", priority = 750 },
          { name = "path", priority = 500 },
          { name = "buffer", priority = 250 },
        }),
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>f", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format" },
    },
    opts = {
      notify_on_error = true,
      format_on_save = { timeout_ms = 2500, lsp_fallback = true },
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        python = { "isort", "black" },
      },
    },
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "pylint" },
      }
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function() lint.try_lint() end,
      })
    end,
  },

  -- Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = { accept = "<C-l>", accept_word = false, accept_line = false, next = "<C-n>", prev = "<C-p>", dismiss = "<C-e>" },
      },
    },
  },
}
```

- [ ] **Step 2: Verify Syntax**
Run: `nvim --headless -c "lua dofile('lua/plugins/coding.lua')" -c "qa"`
Expected: No errors.

- [ ] **Step 3: Commit**
```bash
git add lua/plugins/coding.lua
git commit -m "perf(coding): refine lsp and coding tools for fast startup"
```
