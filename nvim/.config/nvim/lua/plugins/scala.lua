return {
	{
		"scalameta/nvim-metals",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		ft = { "scala", "sbt", "java" },
		opts = function()
			local metals_config = require("metals").bare_config()

			-- Enable Completions
			metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Settings
			metals_config.settings = {
				showImplicitArguments = true,
				excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
			}

			-- Keymaps
			metals_config.on_attach = function(client, bufnr)
				require("metals").setup_dap()

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
				map("<leader>mc", require("metals").commands, "Metals Commands")
			end

			return metals_config
		end,
		config = function(self, metals_config)
			local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })

			-- 1. Set up the listener for FUTURE files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "scala", "sbt", "java" },
				group = nvim_metals_group,
				callback = function()
					require("metals").initialize_or_attach(metals_config)
				end,
			})

			-- 2. FORCE check the CURRENT file immediately
			-- This fixes the "Not an editor command" error on startup
			local ft = vim.bo.filetype
			if ft == "scala" or ft == "sbt" or ft == "java" then
				require("metals").initialize_or_attach(metals_config)
			end
		end,
	},
}
