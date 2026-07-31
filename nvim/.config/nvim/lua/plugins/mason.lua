return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		opts = { ui = { border = "rounded" } },
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"html-lsp",
				"css-lsp",
				"tailwindcss-language-server",
				"pyright",
				"ruff",
				"typescript-language-server",
				"json-lsp",
				"prettierd",
				"eslint_d",
				"lua-language-server",
				"stylua",
				"docker-compose-language-service",
				"dockerfile-language-server",
				"bash-language-server",
			},
			run_on_start = false,
		},
	},
}
