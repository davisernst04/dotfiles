local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>m", "<cmd>Mason<cr>", { desc = "Mason Manager" })

-- Better split navigation
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move Left" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move Right" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move Down" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move Up" })

-- Resize splits with arrow keys
map("n", "<Up>", ":resize +2<CR>", { desc = "Resize Up" })
map("n", "<Down>", ":resize -2<CR>", { desc = "Resize Down" })
map("n", "<Left>", ":vertical resize -2<CR>", { desc = "Resize Left" })
map("n", "<Right>", ":vertical resize +2<CR>", { desc = "Resize Right" })

-- Move lines
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Terminal Exit
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
