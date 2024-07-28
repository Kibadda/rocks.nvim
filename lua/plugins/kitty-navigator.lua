return {
  "knubie/vim-kitty-navigator",
  build = "cp ./*.py ~/.config/kitty/",
  keys = {
    { "<C-h>", "<Cmd>KittyNavigateLeft<CR>", desc = "Kitty Left" },
    { "<C-j>", "<Cmd>KittyNavigateDown<CR>", desc = "Kitty Down" },
    { "<C-k>", "<Cmd>KittyNavigateUp<CR>", desc = "Kitty Up" },
    { "<C-l>", "<Cmd>KittyNavigateRight<CR>", desc = "Kitty Right" },
  },
}
