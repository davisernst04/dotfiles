return {
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

			lint.linters.pylint.args = {
				"--from-stdin",
				vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"),
				"--output-format",
				"json",
				"--disable",
				"import-error,import-self,redefined-outer-name,unused-import,missing-module-docstring,missing-function-docstring",
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
}
