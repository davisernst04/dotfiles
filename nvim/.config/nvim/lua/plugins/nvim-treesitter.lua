return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			local ts_filetypes = {
				"lua",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"html",
				"css",
				"json",
				"python",
				"bash",
				"scala",
				"csv",
				"http",
			}

			local function enable_treesitter(bufnr)
				vim.treesitter.start(bufnr)
				vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = ts_filetypes,
				callback = function(args)
					enable_treesitter(args.buf)
				end,
			})

			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function(args)
					local buf = args.buf
					if vim.bo[buf].filetype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
						return
					end
					local ft = vim.filetype.match({ buf = buf })
					if ft and ft ~= "" then
						vim.bo[buf].filetype = ft
					end
				end,
			})

			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
					selection_modes = {
						["@parameter.outer"] = "v",
						["@function.outer"] = "V",
					},
					include_surrounding_whitespace = false,
				},
			})

			vim.keymap.set({ "x", "o" }, "af", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end)
		end,
	},
}
