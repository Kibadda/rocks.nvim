local create_command = require "me.git.class"
local utils = require "me.git.utils"

local M = {}

M.commit = create_command {
  cmd = { "commit" },
  available_opts = { "amend", "no-edit" },
}

M.fixup = create_command {
  cmd = { "commit", "--fixup" },
  pre_run = function(_, opts)
    local commit = utils.select_commit()

    if not commit then
      return false
    end

    table.insert(opts, commit)
  end,
}

M.rebase = create_command {
  cmd = { "rebase" },
  available_opts = { "interactive", "autosquash", "abort", "skip", "continue" },
  pre_run = function(_, opts)
    local commit = utils.select_commit()

    if not commit then
      return false
    end

    table.insert(opts, commit .. "^")
  end,
  complete = function(self, arg_lead)
    local split = vim.split(arg_lead, "%s+")

    local available_opts = self.available_opts or {}

    if vim.tbl_contains(split, "abort") or vim.tbl_contains(split, "skip") or vim.tbl_contains(split, "continue") then
      available_opts = {}
    elseif vim.tbl_contains(split, "interactive") or vim.tbl_contains(split, "autosquash") then
      available_opts = { "interactive", "autosquash" }
    end

    local complete = vim.tbl_filter(function(opt)
      if vim.tbl_contains(split, opt) then
        return false
      end

      return string.find(opt, "^" .. split[#split]) ~= nil
    end, available_opts)

    table.sort(complete)

    return complete
  end,
}

M.push = create_command {
  cmd = { "push" },
  available_opts = { "force-with-lease" },
  show_output = true,
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
  available_opts = { "prune" },
  show_output = true,
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
  available_opts = { "create" },
  pre_run = function(_, opts)
    local branch
    if vim.tbl_contains(opts, "--create") then
      vim.ui.input({
        prompt = "Enter branch name: ",
      }, function(input)
        branch = input
      end)
    else
      branch = utils.select_branch(false)
    end

    if not branch then
      return false
    end

    table.insert(opts, branch)
  end,
}

M.merge = create_command {
  cmd = { "merge" },
  pre_run = function(_, opts)
    local branch = utils.select_branch(true)

    if not branch then
      return false
    end

    table.insert(opts, branch)
  end,
}

M.stash = create_command {
  cmd = { "stash" },
  available_opts = { "staged", "include-untracked" },
}

M.add = create_command {
  cmd = { "add" },
  additional_opts = true,
  pre_run = function(_, opts)
    if #opts == 0 then
      table.insert(opts, ".")
    end
  end,
  complete = utils.complete_filenames "add",
}

M.reset = create_command {
  cmd = { "reset" },
  additional_opts = true,
  complete = utils.complete_filenames "reset",
}

return M
