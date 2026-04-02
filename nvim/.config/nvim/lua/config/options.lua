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
opt.swapfile = false
opt.clipboard = "unnamedplus"
