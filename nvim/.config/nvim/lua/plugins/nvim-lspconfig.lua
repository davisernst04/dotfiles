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
		end,
	},
}
