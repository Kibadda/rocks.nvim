local whichkey = require "which-key"

whichkey.setup {
  plugins = {
    spelling = {
      enabled = true,
      suggestions = 20,
    },
  },
  window = {
    border = "single",
  },
}

whichkey.register {
  ["<Leader>"] = {
    name = "<Leader>",
    s = { name = "Search" },
    S = { name = "Session" },
  },
}
