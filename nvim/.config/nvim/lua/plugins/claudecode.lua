-- Claude Code IDE integration. Claude keeps running in its own tmux pane or
-- kitty window; this plugin gives it the editor side of the protocol: it sees
-- the current file and selection and opens proposed edits as Neovim diffs.
-- Loads on first use. Start it with <leader>ai, then run /ide in Claude.
return {
	{
		"coder/claudecode.nvim",
		cmd = {
			"ClaudeCodeStart",
			"ClaudeCodeStop",
			"ClaudeCodeStatus",
			"ClaudeCodeAdd",
			"ClaudeCodeSend",
			"ClaudeCodeTreeAdd",
			"ClaudeCodeDiffAccept",
			"ClaudeCodeDiffDeny",
			"ClaudeCodeCloseAllDiffs",
		},
		keys = {
			{ "<leader>a", nil, desc = "Claude Code" },
			{ "<leader>ai", "<cmd>ClaudeCodeStart<cr>", desc = "Start Claude IDE link (then /ide in Claude)" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to Claude" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
			{ "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add file to Claude", ft = { "neo-tree" } },
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude diff" },
		},
		opts = {
			-- Claude runs outside Neovim, so manage no terminal here.
			terminal = { provider = "none" },
		},
	},
}
