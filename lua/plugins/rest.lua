require("me.lazy").on({
  by_events = {
    { event = "FileType", pattern = "http" },
  },
}, function()
  require("rest-nvim").setup {}
end)
