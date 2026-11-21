local function augroup(name)
	return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup("resize_splits"),
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- Agents and other tools edit files that are open here. 'autoread' only acts
-- when Neovim checks the disk, so check on focus, buffer switches, and idle.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.bo.buftype == "" and vim.fn.getcmdwintype() == "" then
			vim.cmd("checktime")
		end
	end,
})

-- check_80.sh-style limits: mark the first column past 80 in C sources.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("c_columns"),
	pattern = { "c", "cpp" },
	callback = function()
		vim.opt_local.colorcolumn = "81"
	end,
})

-- Recover ordinary work after a crash, but never persist secret environment
-- files into swap, undo, or transient backup files.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = augroup("sensitive_files"),
	pattern = { ".env", ".env.*" },
	callback = function()
		vim.opt_local.swapfile = false
		vim.opt_local.undofile = false
		vim.opt_local.backup = false
		vim.opt_local.writebackup = false
	end,
})
