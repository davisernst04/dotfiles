return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = { theme = "tokyonight", globalstatus = true, component_separators = "|" },
			sections = { lualine_c = { { "filename", path = 1 } } },
		},
	},
}
