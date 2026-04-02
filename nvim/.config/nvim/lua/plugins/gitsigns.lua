return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(mode, l, r, opts)
					vim.keymap.set(mode, l, r, { buffer = bufnr, desc = opts.desc })
				end
				map("n", "]h", gs.next_hunk, { desc = "Next Hunk" })
				map("n", "[h", gs.prev_hunk, { desc = "Prev Hunk" })
				map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview Hunk" })
				map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset Hunk" })
			end,
		},
	},
}
