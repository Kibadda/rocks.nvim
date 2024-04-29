require("me.lazy").on_key({
  { mode = "n", lhs = "<Leader>f" },
  { mode = "n", lhs = "<Leader>F" },
  { mode = "n", lhs = "<Leader>b" },
  { mode = "n", lhs = "<Leader>sg" },
  { mode = "n", lhs = "<Leader>sh" },
  { mode = "n", lhs = "<Leader>sr" },
  { mode = "i", lhs = "<M-e>" },
}, function()
  local pick = require "mini.pick"

  ---@diagnostic disable-next-line:duplicate-set-field
  function vim.ui.select(...)
    pick.ui_select(...)
  end

  pick.setup {
    mappings = {
      move_down = "<C-j>",
      move_up = "<C-k>",
    },
  }

  pick.registry.emoji = function()
    local emojis = require "me.data.emoji"

    for _, r in ipairs(emojis) do
      r.text = r[1] .. " " .. r[2]
    end

    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    pick.start {
      source = {
        name = "Emoji",
        items = emojis,
        show = function(bufnr, items, query)
          pick.default_show(bufnr, items, query, { show_icons = true })
        end,
        choose = function(item)
          vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { item[1] })
        end,
      },
    }
  end

  pick.registry.files = function(opts)
    local vcs = not opts or opts.vcs ~= false

    local command = { "rg", "--files", "--no-follow", "--color=never", "--hidden" }

    if not vcs then
      table.insert(command, "--no-ignore-vcs")
    end

    pick.builtin.cli({
      command = command,
      postprocess = function(items)
        items = vim.tbl_filter(function(item)
          return item ~= "" and not vim.startswith(item, ".git/")
        end, items)

        table.sort(items)

        return items
      end,
    }, {
      source = {
        name = vcs and "Files" or "All Files",
        show = function(bufnr, items, query)
          pick.default_show(bufnr, items, query, { show_icons = true })
        end,
      },
      mappings = {
        toggle = {
          char = "<C-t>",
          func = function()
            pick.registry.files { vcs = not vcs }
          end,
        },
      },
    })
  end

  vim.keymap.set("n", "<Leader>f", "<Cmd>Pick files<CR>", { desc = "Find Files" })
  vim.keymap.set("n", "<Leader>F", "<Cmd>Pick files vcs=false<CR>", { desc = "Find All Files" })
  vim.keymap.set("n", "<Leader>b", "<Cmd>Pick buffers<CR>", { desc = "Find Buffer" })
  vim.keymap.set("n", "<Leader>sg", "<Cmd>Pick grep_live<CR>", { desc = "Live Grep" })
  vim.keymap.set("n", "<Leader>sh", "<Cmd>Pick help<CR>", { desc = "Help" })
  vim.keymap.set("n", "<Leader>sr", "<Cmd>Pick resume<CR>", { desc = "Resume" })
  vim.keymap.set("i", "<M-e>", "<Cmd>Pick emoji<CR>", { desc = "Emoji" })
end)

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("DirectoryEdit", { clear = true }),
  callback = function(args)
    if vim.fn.isdirectory(args.file) == 1 then
      vim.cmd.bdelete()

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniPickStart",
        once = true,
        callback = function()
          local path

          ---@diagnostic disable-next-line:undefined-field
          if args.file == vim.uv.cwd() then
            path = ""
          else
            path = vim.fn.fnamemodify(args.file, ":.") .. "/"
          end

          require("mini.pick").set_picker_query { path }
        end,
      })

      require("mini.pick").registry.files()
    end
  end,
})
