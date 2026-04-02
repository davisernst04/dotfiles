return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = {
					"lua",
					"javascript",
					"typescript",
					"tsx",
					"html",
					"css",
					"json",
					"python",
					"bash",
					"scala",
					"csv",
					"http",
				},
				auto_install = true,
				highlight = { enable = true },
				indent = {
					enable = true,
					disable = { "python" },
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
						},
					},
				},
			})
		end,
	},
}
