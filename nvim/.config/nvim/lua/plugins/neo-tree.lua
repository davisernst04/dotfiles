return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		keys = { { "\\", "<cmd>Neotree toggle<cr>", desc = "NeoTree" } },
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {
			filesystem = {
				filtered_items = { visible = true, hide_gitignored = true },
				hijack_netrw_behavior = "open_current",
			},
		},
	},
}
