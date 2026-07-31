return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local on_attach = function(_, bufnr)
				local function map(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
				end
				map("gd", vim.lsp.buf.definition, "Goto Definition")
				map("gr", vim.lsp.buf.references, "References")
				map("<leader>rn", vim.lsp.buf.rename, "Rename")
				map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
				map("K", vim.lsp.buf.hover, "Hover")
				map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous Diagnostic")
				map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")
			end

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
					settings = { python = {
							analysis = {
								autoSearchPaths = true,
								useLibraryCodeForTypes = true,
								diagnosticMode = "openFilesOnly",
								typeCheckingMode = "basic",
							}
						} },
				},
			}
			for _, server in ipairs(servers) do
				local config = server_configs[server] or {}
				config.capabilities = capabilities
				config.on_attach = on_attach
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			end
		end,
	},
}
