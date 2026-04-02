local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

map("n", "<Up>", ":resize +2<CR>", { desc = "Resize Up" })
map("n", "<Down>", ":resize -2<CR>", { desc = "Resize Down" })
map("n", "<Left>", ":vertical resize -2<CR>", { desc = "Resize Left" })
map("n", "<Right>", ":vertical resize +2<CR>", { desc = "Resize Right" })

map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
