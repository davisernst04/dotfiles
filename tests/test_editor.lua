-- Exercise editor callbacks without installing plugins or starting servers.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local plugins = root .. "/nvim/.config/nvim/lua/plugins/"
local calls = {}
local lint = {
	linters = {
		eslint_d = { cmd = function() return vim.v.progpath end },
		ruff = function() return { cmd = vim.v.progpath } end,
	},
	try_lint = function(names) calls[#calls + 1] = names end,
}
package.loaded.lint = lint
dofile(plugins .. "nvim-lint.lua")[1].config()

local function trigger_lint(ft)
	vim.bo.filetype = ft
	vim.api.nvim_exec_autocmds("InsertLeave", { buffer = 0 })
end

trigger_lint("javascript")
assert(vim.deep_equal(calls[1], { "eslint_d" }), "function-valued ESLint commands must run")
trigger_lint("python")
assert(vim.deep_equal(calls[2], { "ruff" }), "linter factories must run")
lint.linters.eslint_d.cmd = function() return "absent-audit-linter-executable" end
trigger_lint("javascript")
assert(#calls == 2, "missing binaries must be skipped")
vim.bo.buftype = "nofile"
trigger_lint("python")
assert(#calls == 2, "special buffers must be skipped")
vim.bo.buftype = ""

package.loaded["nvim-treesitter"] = { setup = function() end }
package.loaded["nvim-treesitter-textobjects"] = { setup = function() end }
dofile(plugins .. "nvim-treesitter.lua")[1].config()
local started = false
vim.treesitter.get_parser = function() return {} end
vim.treesitter.start = function() started = true end
vim.bo.filetype = "sh"
assert(started, "shell filetype must activate the Bash parser")
vim.bo.indentexpr = ""
started = false
vim.treesitter.get_parser = function() error("parser not installed") end
vim.bo.filetype = "scala"
assert(not started and vim.bo.indentexpr == "", "missing parsers must preserve normal editing")

print("Editor checks passed: dynamic linters, missing tools, special buffers, shell and missing parsers")
