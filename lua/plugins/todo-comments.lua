require("todo-comments").setup {
  keywords = {
    CRTX = { icon = "C", color = "test" },
  },
  gui_style = {
    fg = "BOLD",
  },
  highlight = {
    multiline = false,
    keyword = "fg",
    pattern = [[(KEYWORDS)]],
    after = "",
  },
}
