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
    { event = "BufEnter", pattern = "*/" },
  },
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

  function pick.registry.emoji()
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

  function pick.registry.buffers()
    pick.builtin.buffers({}, {
      mappings = {
        wipeout = {
          char = "<C-d>",
          func = function()
            local bufnr = pick.get_picker_matches().current.bufnr
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_delete(bufnr, {})
            end
          end,
        },
        files = {
          char = "<C-t>",
          func = function()
            pick.registry.files()
          end,
        },
      },
    })
  end

  function pick.registry.files(opts)
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
          pick.set_picker_query(query)
        end,
      })
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
        show = function(bufnr, items, que)
          pick.default_show(bufnr, items, que, { show_icons = true })
        end,
      },
      mappings = {
        toggle = {
          char = "<C-t>",
          func = function()
            pick.registry.files { vcs = not vcs, query = query }
          end,
        },
      },
    })
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("DirectoryEdit", { clear = true }),
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

        pick.registry.files { query = path }
      end
    end,
  })
end)
