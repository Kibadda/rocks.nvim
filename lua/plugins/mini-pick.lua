require("me.lazy").on("mini-pick", {
  by_keys = {
    { mode = "n", lhs = "<Leader>f", rhs = "<Cmd>Pick files<CR>", desc = "Find Files" },
    { mode = "n", lhs = "<Leader>F", rhs = "<Cmd>Pick files vcs=false<CR>", desc = "Find All Files" },
    { mode = "n", lhs = "<Leader>b", rhs = "<Cmd>Pick buffers<CR>", desc = "Find Buffer" },
    { mode = "n", lhs = "<Leader>H", rhs = "<Cmd>Pick hunks<CR>", desc = "Git Hunks" },
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

  local minipick_start = MiniPick.start
  ---@diagnostic disable-next-line:duplicate-set-field
  function MiniPick.start(opts)
    opts = opts or {}

    if opts.with_qflist_mapping then
      opts.with_qflist_mapping = nil
      opts.mappings = opts.mappings or {}
      opts.mappings.qflist = {
        char = "<C-q>",
        func = function()
          local items = {}
          for _, item in ipairs(vim.print(MiniPick.get_picker_matches().all)) do
            if type(item) == "table" then
              if not item.filename then
                item.filename = item.path
              end
              table.insert(items, item)
            elseif type(item) == "string" then
              local split = vim.split(item, ":")

              table.insert(items, {
                filename = split[1],
                lnum = split[2],
                col = split[3],
                text = table.concat(split, ":", 4),
              })
            end
          end

          vim.fn.setqflist({}, " ", {
            title = opts.source and opts.source.name or "MiniPick",
            items = items,
          })
          MiniPick.stop()
          vim.cmd.copen()
          vim.cmd.cfirst()
        end,
      }
    end

    if opts.initial_query then
      local query = opts.initial_query

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniPickStart",
        once = true,
        callback = function()
          MiniPick.set_picker_query(query)
        end,
      })

      opts.initial_query = nil
    end

    minipick_start(opts)
  end

  function MiniPick.registry.lsp(opts)
    opts = opts or {}

    MiniPick.start {
      with_qflist_mapping = true,
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
              MiniPick.registry.buffers()
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

  function MiniPick.registry.grep_live()
    MiniPick.builtin.grep_live({}, {
      with_qflist_mapping = true,
    })
  end

  function MiniPick.registry.files(opts)
    opts = opts or {}

    local vcs = opts.vcs ~= false

    local command = { "rg", "--files", "--no-follow", "--color=never", "--hidden" }

    if not vcs then
      table.insert(command, "--no-ignore-vcs")
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
      initial_query = opts.query,
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

  function MiniPick.registry.hunks(opts)
    opts = opts or {}

    local unstaged = opts.unstaged ~= false

    local diff_cmd = { "git", "diff", "--patch", "--unified=1", "--color=never", "--", vim.fn.getcwd() }

    if not unstaged then
      table.insert(diff_cmd, 4, "--cached")
    end

    MiniPick.builtin.cli({
      command = diff_cmd,
      postprocess = function(lines)
        local header_pattern = "^diff %-%-git"
        local hunk_pattern = "^@@ %-%d+,?%d* %+(%d+),?%d* @@"
        local to_path_pattern = "^%+%+%+ b/(.*)$"

        -- Parse diff lines
        local cur_header, cur_path, is_in_hunk = {}, nil, false
        local items = {}
        for _, l in ipairs(lines) do
          -- Separate path header and hunk for better granularity
          if l:find(header_pattern) ~= nil then
            is_in_hunk = false
            cur_header = {}
          end

          local path_match = l:match(to_path_pattern)
          if path_match ~= nil and not is_in_hunk then
            cur_path = path_match
          end

          local hunk_start = l:match(hunk_pattern)
          if hunk_start ~= nil then
            is_in_hunk = true
            local item = { path = cur_path, lnum = tonumber(hunk_start), header = vim.deepcopy(cur_header), hunk = {} }
            table.insert(items, item)
          end

          if is_in_hunk then
            table.insert(items[#items].hunk, l)
          else
            table.insert(cur_header, l)
          end
        end

        -- Correct line number to point at the first change
        local try_correct_lnum = function(item, i)
          if item.hunk[i]:find "^[+-]" == nil then
            return false
          end
          item.lnum = item.lnum + i - 2
          return true
        end
        for _, item in ipairs(items) do
          for i = 2, #item.hunk do
            if try_correct_lnum(item, i) then
              break
            end
          end
        end

        -- Construct aligned text from path and hunk header
        local text_parts, path_width, coords_width = {}, 0, 0
        for i, item in ipairs(items) do
          local coords, title = item.hunk[1]:match "@@ (.-) @@ ?(.*)$"
          coords, title = coords or "", title or ""
          text_parts[i] = { item.path, coords, title }
          path_width = math.max(path_width, vim.fn.strchars(item.path))
          coords_width = math.max(coords_width, vim.fn.strchars(coords))
        end

        local function ensure_text_width(text, width)
          local text_width = vim.fn.strchars(text)
          if text_width <= width then
            return text .. string.rep(" ", width - text_width)
          end
          return "…" .. vim.fn.strcharpart(text, text_width - width + 1, width - 1)
        end

        for i, item in ipairs(items) do
          local parts = text_parts[i]
          local path, coords = ensure_text_width(parts[1], path_width), ensure_text_width(parts[2], coords_width)
          item.text = string.format("%s │ %s │ %s", path, coords, parts[3])
        end

        return items
      end,
    }, {
      initial_query = opts.query,
      with_qflist_mapping = true,
      source = {
        name = string.format("Hunks (%s)", unstaged and "unstaged" or "staged"),
        preview = function(buf_id, item)
          vim.bo[buf_id].syntax = "diff"
          local lines = vim.deepcopy(item.header)
          vim.list_extend(lines, item.hunk)
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
        end,
      },
      mappings = {
        choose_in_tabpage = "",
        refine = "",
        toggle = {
          char = "<C-t>",
          func = function()
            MiniPick.registry.hunks {
              unstaged = not unstaged,
              query = MiniPick.get_picker_query(),
            }
          end,
        },
        apply = {
          char = "<C-space>",
          func = function()
            local current = MiniPick.get_picker_matches().current

            local patch = current.header
            vim.list_extend(patch, current.hunk)

            local apply_cmd = {
              "git",
              "apply",
              "--whitespace=nowarn",
              "--cached",
              "--unidiff-zero",
              "-",
            }

            if not unstaged then
              table.insert(apply_cmd, 4, "--reverse")
            end

            vim
              .system(apply_cmd, {
                cwd = vim.fn.getcwd(),
                stdin = patch,
              })
              :wait()

            MiniPick.registry.hunks {
              unstaged = unstaged,
              query = MiniPick.get_picker_query(),
            }
          end,
        },
      },
    })
  end
end)
