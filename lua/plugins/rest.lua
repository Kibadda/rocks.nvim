require("me.lazy").on("rest", {
  by_events = {
    { event = "FileType", pattern = "http" },
  },
}, function()
  require("rest-nvim").setup {}
end)
