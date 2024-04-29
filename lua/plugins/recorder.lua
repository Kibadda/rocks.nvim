require("me.lazy").on({
  by_keys = {
    { mode = "n", lhs = "q" },
    { mode = "n", lhs = "Q" },
  },
}, function()
  ---@diagnostic disable-next-line: missing-fields
  require("recorder").setup {
    lessNotifications = true,
  }
end)
