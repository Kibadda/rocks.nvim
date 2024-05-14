require("me.lazy").on("mini-pick", {
  by_keys = {
    { mode = "n", lhs = "<Leader>f", rhs = "<Cmd>Pick files<CR>", desc = "Find Files" },
    { mode = "n", lhs = "<Leader>F", rhs = "<Cmd>Pick files vcs=false<CR>", desc = "Find All Files" },
    { mode = "n", lhs = "<Leader>b", rhs = "<Cmd>Pick buffers<CR>", desc = "Find Buffer" },
    { mode = "n", lhs = "<Leader>sg", rhs = "<Cmd>Pick grep_live<CR>", desc = "Live Grep" },
    { mode = "n", lhs = "<Leader>sh", rhs = "<Cmd>Pick help<CR>", desc = "Help" },
    { mode = "n", lhs = "<Leader>sr", rhs = "<Cmd>Pick resume<CR>", desc = "Resume" },
    { mode = "i", lhs = "<M-e>", rhs = "<Cmd>Pick emoji<CR>", desc = "Emoji" },
  },
  by_cmds = {
    {
      name = "E",
      command = function()
        vim.cmd.edit(vim.fn.fnamemodify(vim.fn.expand "%", ":h") .. "/")
      end,
      opts = {
        bang = false,
        nargs = 0,
      },
    },
  },
  by_events = {
    {
      event = "BufEnter",
      pattern = "*/",
      callback = function(args)
        if vim.fn.isdirectory(args.file) == 1 then
          vim.cmd.bwipeout()

          local path

          ---@diagnostic disable-next-line:undefined-field
          if args.file == vim.uv.cwd() then
            path = ""
          else
            path = vim.fn.fnamemodify(args.file, ":.") .. "/"
          end

          path = vim.split(path, "")

          table.insert(path, 1, "^")

          MiniPick.registry.files { query = path }
        end
      end,
    },
  },
}, function()
  require("mini.pick").setup {
    mappings = {
      move_down = "<C-j>",
      move_up = "<C-k>",
    },
  }

  ---@diagnostic disable-next-line:duplicate-set-field
  function vim.ui.select(...)
    MiniPick.ui_select(...)
  end

  function MiniPick.registry.lsp(opts)
    opts = opts or {}

    MiniPick.start {
      source = {
        name = opts.title or "LSP",
        items = vim.tbl_map(function(item)
          item.path = item.filename
          return item
        end, opts.items),
        show = function(bufnr, items, query)
          MiniPick.default_show(bufnr, items, query, { show_icons = true })
        end,
        choose = function(item)
          MiniPick.default_choose(item)
        end,
      },
      mappings = {
        qflist = {
          char = "<C-q>",
          func = function()
            vim.fn.setqflist({}, " ", { title = opts.title, items = pick.get_picker_matches().all })
            pick.stop()
            vim.cmd.copen()
          end,
        },
      },
    }
  end

  function MiniPick.registry.emoji()
    local emojis = require "me.data.emoji"

    for _, r in ipairs(emojis) do
      r.text = r[1] .. " " .. r[2]
    end

    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    MiniPick.start {
      source = {
        name = "Emoji",
        items = emojis,
        show = function(bufnr, items, query)
          MiniPick.default_show(bufnr, items, query, { show_icons = true })
        end,
        choose = function(item)
          vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { item[1] })
        end,
      },
    }
  end

  function MiniPick.registry.buffers()
    MiniPick.builtin.buffers({}, {
      mappings = {
        choose_in_tabpage = "",
        wipeout = {
          char = "<C-d>",
          func = function()
            local bufnr = MiniPick.get_picker_matches().current.bufnr
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_delete(bufnr, {})
            end
          end,
        },
        files = {
          char = "<C-t>",
          func = function()
            MiniPick.registry.files()
          end,
        },
      },
    })
  end

  function MiniPick.registry.files(opts)
    opts = opts or {}

    local vcs = opts.vcs ~= false
    local query = opts.query

    local command = { "rg", "--files", "--no-follow", "--color=never", "--hidden" }

    if not vcs then
      table.insert(command, "--no-ignore-vcs")
    end

    if query then
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniPickStart",
        once = true,
        callback = function()
          MiniPick.set_picker_query(query)
        end,
      })
    end

    MiniPick.builtin.cli({
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
        show = function(bufnr, items, que)
          MiniPick.default_show(bufnr, items, que, { show_icons = true })
        end,
      },
      mappings = {
        choose_in_tabpage = "",
        toggle = {
          char = "<C-t>",
          func = function()
            MiniPick.registry.files { vcs = not vcs, query = MiniPick.get_picker_query() }
          end,
        },
      },
    })
  end
end)
