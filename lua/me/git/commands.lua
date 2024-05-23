local create_command = require "me.git.class"
local utils = require "me.git.utils"

local M = {}

M.commit = create_command {
  cmd = { "commit" },
  pre_run = function(_, fargs)
    if #fargs == 1 and fargs[1] == "--fixup" then
      local commit = utils.select_commit()

      if not commit then
        return false
      end

      table.insert(fargs, commit)
    end
  end,
  completions = function(fargs)
    if vim.tbl_contains(fargs, "--fixup") then
      return {}
    else
      if #fargs > 1 then
        return { "--amend", "--no-edit" }
      else
        return { "--amend", "--no-edit", "--fixup" }
      end
    end
  end,
}

M.rebase = create_command {
  cmd = { "rebase" },
  pre_run = function(_, fargs)
    local should_select_commit = true

    for _, arg in ipairs(fargs) do
      if arg == "--abort" or arg == "--skip" or arg == "--continue" then
        should_select_commit = false
        break
      end
    end

    if should_select_commit then
      local commit = utils.select_commit()

      if not commit then
        return false
      end

      table.insert(fargs, commit .. "^")
    end
  end,
  completions = function(fargs)
    if vim.fn.isdirectory ".git/rebase-apply" == 1 or vim.fn.isdirectory ".git/rebase-merge" == 1 then
      if #fargs > 1 then
        return {}
      else
        return { "--abort", "--skip", "--continue" }
      end
    else
      return { "--interactive", "--autosquash" }
    end
  end,
}

M.push = create_command {
  cmd = { "push" },
  show_output = true,
  completions = { "--force-with-lease" },
}

M.pull = create_command {
  cmd = { "pull" },
  show_output = true,
}

M.status = create_command {
  cmd = { "status" },
  show_output = true,
}

M.fetch = create_command {
  cmd = { "fetch" },
  show_output = true,
  completions = { "--prune" },
}

M.log = create_command {
  cmd = { "log", "--pretty=%h -%C()%d%Creset %s (%cr)" },
  post_run = function(_, stdout)
    local lines = {}
    local extmarks = {}

    for i, line in ipairs(vim.split(stdout, "\n")) do
      local full_line, hash, branch, date

      full_line, _, hash, branch, date = line:find "^([^%s]+) %- (%([^%)]+%)).*(%([^%)]+%))$"

      if not full_line then
        full_line, _, hash, date = line:find "^([^%s]+) %-.*(%([^%)]+%))$"
      end

      if not full_line then
        break
      end

      table.insert(extmarks, { line = i, col = 1, end_col = #hash, hl = "Red" })
      if branch then
        table.insert(extmarks, { line = i, col = #hash + 3, end_col = #hash + 3 + #branch, hl = "Yellow" })
      end
      table.insert(extmarks, { line = i, col = #line - #date, end_col = #line, hl = "Green" })
      table.insert(lines, line)
    end

    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(bufnr, "GIT LOG")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].modified = false

    local ns = vim.api.nvim_create_namespace "git-log"

    for _, extmark in ipairs(extmarks) do
      vim.api.nvim_buf_set_extmark(bufnr, ns, extmark.line - 1, extmark.col - 1, {
        end_col = extmark.end_col,
        hl_group = extmark.hl,
      })
    end

    vim.keymap.set("n", "q", function()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { buffer = bufnr })

    local win = vim.api.nvim_open_win(bufnr, true, {
      split = "below",
      win = 0,
      height = 20,
    })

    vim.keymap.set("n", "<CR>", function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
      local hash = line:match "^([^%s]+)"

      local difflines = utils.git_command { "diff", string.format("%s^..%s", hash, hash) }

      local diffbufnr = vim.api.nvim_create_buf(false, false)
      vim.api.nvim_buf_set_lines(diffbufnr, 0, -1, false, difflines)
      vim.bo[diffbufnr].bufhidden = "wipe"
      vim.bo[diffbufnr].modifiable = false
      vim.bo[diffbufnr].modified = false
      vim.bo[diffbufnr].filetype = "diff"

      vim.keymap.set("n", "q", function()
        vim.api.nvim_win_set_buf(win, bufnr)
      end, { buffer = diffbufnr })

      vim.keymap.set("n", "<CR>", function()
        vim.api.nvim_win_set_buf(win, bufnr)
      end, { buffer = diffbufnr })

      vim.api.nvim_win_set_buf(win, diffbufnr)
    end, { buffer = bufnr })
  end,
}

M.switch = create_command {
  cmd = { "switch" },
  pre_run = function(_, opts)
    if #opts == 0 then
      local branch

      vim.ui.input({
        prompt = "Enter branch name: ",
      }, function(input)
        branch = input
      end)

      if not branch or branch == "" then
        return false
      end

      table.insert(opts, "--create")
      table.insert(opts, branch)
    end
  end,
  completions = function(fargs)
    if #fargs > 1 then
      return {}
    end

    return utils.cache.short_branches
  end,
}

M.merge = create_command {
  cmd = { "merge" },
  pre_run = function(_, opts)
    return #opts == 0
  end,
  completions = function(fargs)
    if #fargs > 1 then
      return {}
    end

    return utils.cache.full_branches
  end,
}

M.stash = create_command {
  cmd = { "stash" },
  completions = { "--staged", "--include-untracked" },
}

M.add = create_command {
  cmd = { "add" },
  pre_run = function(_, opts)
    if #opts == 0 then
      table.insert(opts, ".")
    end
  end,
  completions = function()
    return utils.cache.unstaged_filenames
  end,
}

M.reset = create_command {
  cmd = { "reset" },
  completions = function()
    return utils.cache.staged_filenames
  end,
}

return M
