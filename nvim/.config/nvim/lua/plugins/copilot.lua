return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = {
				auto_trigger = true,
				keymap = {
					accept = "<C-l>",
					accept_word = false,
					accept_line = false,
					next = "<M-n>",
					prev = "<M-p>",
					dismiss = "<C-e>",
				},
			},
		},
	},
}
