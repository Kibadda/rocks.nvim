return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "classic",
    win = {
      border = "single",
    },
    spec = {
      { "<Leader>", group = "<Leader>" },
      { "<Leader>S", group = "Session" },
      { "<Leader>l", group = "Lsp" },
      { "<Leader>s", group = "Search" },
    },
  },
}
