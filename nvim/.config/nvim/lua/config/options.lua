if vim.loader then
	vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.laststatus = 3
opt.expandtab = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2

opt.autoindent = true
opt.smartindent = false

opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.scrolloff = 8
opt.termguicolors = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true
opt.swapfile = true
opt.clipboard = "unnamedplus"

-- Neovim 0.11+ disables inline diagnostics by default, leaving only sign-column
-- marks. Show the message for the cursor line; ]d and [d move between them.
vim.diagnostic.config({
	virtual_text = { current_line = true },
	severity_sort = true,
	float = { border = "rounded" },
})
-- Over SSH there is no X11/Wayland clipboard tool, and Neovim only auto-enables
-- OSC 52 when 'clipboard' is empty, so unnamedplus would leave no provider at all.
-- Opt in explicitly so yank/paste reach the local Kitty clipboard. Inside tmux,
-- Neovim's tmux provider already relays through tmux's set-clipboard.
if vim.env.SSH_TTY and not vim.env.TMUX then
	vim.g.clipboard = "osc52"
end
