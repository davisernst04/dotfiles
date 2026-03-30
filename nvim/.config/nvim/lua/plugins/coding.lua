return {
	-- Detect tabstop and shiftwidth automatically
	{ "tpope/vim-sleuth", event = { "BufReadPre", "BufNewFile" } },

	-- 1. MASON
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = { ui = { border = "rounded" } },
	},

	-- 2. LSP CONFIG
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
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
					"html-lsp",
					"css-lsp",
					"tailwindcss-language-server",
					"pyright",
					"typescript-language-server",
					"json-lsp",
					"lua-language-server",
					"emmet-language-server",
					"prettierd",
					"eslint_d",
					"stylua",
					"black",
					"isort",
					"pylint",
					"dockerls",
					"docker-compose-language-service",
					"dockerfile-language-server",
				},
			})

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local opts = { capabilities = capabilities, on_attach = on_attach }
						if server_name == "emmet_language_server" then
							opts.filetypes = {
								"html",
								"typescriptreact",
								"javascriptreact",
								"css",
								"sass",
								"scss",
								"less",
							}
						end
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
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				sorting = {
					priority_weight = 2,
					comparators = {
						-- 1. EMMET SPECIFIC COMPARATOR
						-- This function checks the internal client name.
						-- If it's "emmet_language_server", it forces it to the top.
						function(entry1, entry2)
							local function is_emmet(entry)
								return entry.source.name == "nvim_lsp"
									and entry.source.source.client
									and entry.source.source.client.name == "emmet_language_server"
							end

							if is_emmet(entry1) and not is_emmet(entry2) then
								return true
							end
							if is_emmet(entry2) and not is_emmet(entry1) then
								return false
							end
							return nil
						end,

						-- 2. Standard comparators
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if require("copilot.suggestion").is_visible() then
							require("copilot.suggestion").accept()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),

					["<S-Tab>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
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
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format",
			},
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
		event = { "BufReadPre", "BufNewFile" },
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
				callback = function()
					lint.try_lint()
				end,
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
				keymap = {
					accept = "<C-l>",
					accept_word = false,
					accept_line = false,
					next = "<C-n>",
					prev = "<C-p>",
					dismiss = "<C-e>",
				},
			},
		},
	},
}
