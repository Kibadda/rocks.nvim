if vim.fn.argc() ~= 0 then
  return
end

local starter = require "mini.starter"

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("MiniStarter", { clear = true }),
  pattern = "MiniStarterOpened",
  callback = function(args)
    vim.keymap.set("n", "<C-j>", function()
      starter.update_current_item "next"
    end, { desc = "Select Next", buffer = args.buf })
    vim.keymap.set("n", "<C-k>", function()
      starter.update_current_item "prev"
    end, { desc = "Select Prev", buffer = args.buf })
    vim.keymap.set("n", "<C-w>", function()
      starter.set_query(nil, args.buf)
    end, { desc = "Reset Query", buffer = args.buf })
  end,
})

starter.setup {
  header = function()
    local weekday = os.date "%w"
    local day = table.concat(require("me.data.weekdays")[tonumber(weekday == "0" and 7 or weekday)], "\n")

    return day:gsub("AAAAAAAAAA", os.date "%d.%m.%Y")
  end,
  items = {
    function()
      return {
        {
          name = "quit",
          action = "q",
          section = "",
        },
        {
          name = "edit new buffer",
          action = "enew",
          section = "",
        },
      }
    end,
    function()
      local items = {}

      for name, type in vim.fs.dir(vim.g.session_dir) do
        if type == "file" then
          table.insert(items, {
            name = name,
            action = function()
              vim.g.session_load(name)
            end,
            section = "sessions",
          })
        end
      end

      return items
    end,
  },
  footer = function()
    return ""
  end,
  content_hooks = {
    function(...)
      return starter.gen_hook.adding_bullet("| ", true)(...)
    end,
    function(content, bufnr)
      local win = vim.fn.bufwinid(bufnr)
      if not win or win < 0 then
        return
      end

      local split = {
        header = {
          lines = {},
          width = 0,
          pad = 0,
        },
        items = {
          lines = {},
          width = 0,
          pad = 0,
        },
      }

      for _, c in ipairs(content) do
        if c[1].type == "header" then
          table.insert(split.header.lines, c)
        else
          table.insert(split.items.lines, c)
        end
      end

      for _, val in pairs(split) do
        for _, l in ipairs(starter.content_to_lines(val.lines)) do
          val.width = math.max(val.width, vim.fn.strdisplaywidth(l))
        end

        val.pad = math.max(math.floor(0.5 * (vim.api.nvim_win_get_width(win) - val.width)), 0)
      end

      local bottom_space = vim.api.nvim_win_get_height(win) - #content
      local top_pad = math.max(math.floor(0.5 * bottom_space), 0)

      content = starter.gen_hook.padding(split.header.pad, top_pad)(split.header.lines)
      for _, c in ipairs(starter.gen_hook.padding(split.items.pad, 0)(split.items.lines)) do
        table.insert(content, c)
      end

      return content
    end,
  },
}
