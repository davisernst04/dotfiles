return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-neotest/neotest-python",
		},
		opts = {
			adapters = {
				["neotest-python"] = {
					dap = { justMyCode = false },
				},
			},
		},
		config = function(_, opts)
			local neotest = require("neotest")
			neotest.setup(opts)

			-- Keymaps
			vim.keymap.set("n", "<leader>tt", function()
				neotest.run.run()
			end, { desc = "Run Nearest Test" })
			vim.keymap.set("n", "<leader>ts", function()
				neotest.summary.toggle()
			end, { desc = "Toggle Test Summary" })
			vim.keymap.set("n", "<leader>to", function()
				neotest.output.open({ enter = true })
			end, { desc = "Show Test Output" })
		end,
	},
}
