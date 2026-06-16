return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		keys = {
			{ "gd", vim.lsp.buf.definition, desc = "Goto Definition" },
			{ "gr", vim.lsp.buf.references, desc = "References" },
			{ "<leader>rn", vim.lsp.buf.rename, desc = "Rename" },
			{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action" },
			{ "K", vim.lsp.buf.hover, desc = "Hover" },
			{ "[d", vim.diagnostic.goto_prev, desc = "Prev Diagnostic" },
			{ "]d", vim.diagnostic.goto_next, desc = "Next Diagnostic" },
		},
		config = function()
			vim.notify("nvim-lspconfig config called", vim.log.levels.INFO)
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local on_attach = function(_, bufnr) end

			require("mason-tool-installer").setup({
				ensure_installed = {
					"html-lsp",
					"css-lsp",
					"tailwindcss-language-server",
					"pyright",
					"black",
					"isort",
					"pylint",
					"typescript-language-server",
					"json-lsp",
					"prettierd",
					"eslint_d",
					"lua-language-server",
					"stylua",
					"dockerls",
					"docker-compose-language-service",
					"dockerfile-language-server",
					"bash-language-server",
				},
			})

			require("mason-lspconfig").setup({
				automatic_enable = false,
			})

			local lspconfig = require("lspconfig")

			local servers = {
				"html",
				"cssls",
				"tailwindcss",
				"pyright",
				"ts_ls",
				"jsonls",
				"lua_ls",
				"dockerls",
				"docker_compose_language_service",
				"bashls",
			}

			local server_configs = {
				pyright = {
					root_dir = function(fname)
						return vim.fn.expand("~")
					end,
					before_init = function(_, config)
						vim.notify("before_init called", vim.log.levels.INFO)
						config.settings.python = {
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "openFilesOnly",
								typeCheckingMode = "off",
							}
						}
					end,
				},
			}

			local deprecate = vim.deprecate
			vim.deprecate = function(name, ...)
				if name:match("lspconfig") then
					return
				end
				return deprecate(name, ...)
			end
			for _, server in ipairs(servers) do
				local config = server_configs[server] or {}
				config.capabilities = capabilities
				config.on_attach = on_attach
				lspconfig[server].setup(config)
			end
			vim.deprecate = deprecate
		end,
	},
}
