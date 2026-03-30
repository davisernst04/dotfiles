return {
	-- Colorscheme
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			require("tokyonight").setup({ style = "night" })
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = { theme = "tokyonight", globalstatus = true, component_separators = "|" },
			sections = { lualine_c = { { "filename", path = 1 } } },
		},
	},
	-- Indent Guides (Lazy Loaded now)
	{
		"lukas-reineke/indent-blankline.nvim",
		event = { "BufReadPost", "BufNewFile" },
		main = "ibl",
		opts = { indent = { char = "│" }, scope = { enabled = false } },
	},
	-- Key Helper
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},
	-- Color Highlighting
	{
		"NvChad/nvim-colorizer.lua",
		ft = { "css", "scss", "html", "javascript", "typescriptreact" },
		opts = { user_default_options = { tailwind = true, css = true } },
	},
}
