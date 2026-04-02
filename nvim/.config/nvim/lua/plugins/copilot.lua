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
					next = "<C-n>",
					prev = "<C-p>",
					dismiss = "<C-e>",
				},
			},
		},
	},
}
