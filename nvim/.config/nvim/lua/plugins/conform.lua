return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				desc = "Format",
			},
		},
		opts = {
			notify_on_error = true,
			format_on_save = function(bufnr)
				-- C and shell files often live in shared or course-provided code.
				-- Format them explicitly with <leader>cf so saving never rewrites
				-- untouched lines; clangd and bashls would otherwise format on save
				-- through the LSP fallback.
				if vim.tbl_contains({ "c", "cpp", "sh", "bash" }, vim.bo[bufnr].filetype) then
					return
				end
				return { timeout_ms = 2500, lsp_format = "fallback" }
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				css = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				python = { "ruff_organize_imports", "ruff_format" },
			},
		},
	},
}
