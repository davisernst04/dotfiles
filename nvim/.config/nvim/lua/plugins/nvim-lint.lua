return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local lint = require("lint")
			-- Stop the ESLint daemon when this editor exits.
			vim.env.ESLINT_D_PPID = tostring(vim.fn.getpid())
			lint.linters_by_ft = {
				javascript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescript = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				python = { "ruff" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					if vim.bo.buftype ~= "" or not vim.bo.modifiable then
						return
					end
					local names = lint.linters_by_ft[vim.bo.filetype]
					if not names then
						return
					end
					-- skip linters whose binary is not installed to avoid ENOENT errors
					local available = vim.tbl_filter(function(name)
						local linter = lint.linters[name]
						if type(linter) == "function" then
							linter = linter()
						end
						local cmd = linter.cmd
						if type(cmd) == "function" then
							cmd = cmd()
						end
						return type(cmd) == "string" and vim.fn.executable(cmd) == 1
					end, names)
					if #available > 0 then
						lint.try_lint(available)
					end
				end,
			})
		end,
	},
}
