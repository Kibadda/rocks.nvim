local create_command = require "me.git.class"

local function git_command(cmd)
  table.insert(cmd, 1, "git")
  table.insert(cmd, 2, "--no-pager")

  local result = vim.system(cmd):wait()

  return vim.split(result.stdout, "\n")
end

local function select_commit()
  local commits = {}
  for _, commit in ipairs(git_command { "log", "--pretty=%h|%s" }) do
    table.insert(commits, vim.split(commit, "|"))
  end

  local commit

  vim.ui.select(commits, {
    prompt = "Commit",
    format_item = function(item)
      return item[2]
    end,
  }, function(item)
    commit = item and item[1] or nil
  end)

  return commit
end

local function select_branch(remote)
  local cmd = { "branch", "--column=plain" }

  if remote then
    table.insert(cmd, "-r")
  end

  local branches = {}
  for _, branch in ipairs(git_command(cmd)) do
    if not branch:find "HEAD" then
      table.insert(branches, vim.trim(branch:gsub("*", "")))
    end
  end

  local branch

  vim.ui.select(branches, {
    prompt = "Branch",
  }, function(item)
    branch = item
  end)

  return branch
end

local M = {}

M.commit = create_command {
  cmd = { "commit" },
  available_opts = { "amend", "no-edit" },
}

M.fixup = create_command {
  cmd = { "commit", "--fixup" },
  pre_run = function(_, cmd)
    local commit = select_commit()

    if not commit then
      return false
    end

    table.insert(cmd, commit)
  end,
}

M.rebase = create_command {
  cmd = { "rebase" },
  available_opts = { "interactive", "autosquash", "abort", "skip", "continue" },
  pre_run = function(_, cmd)
    local commit = select_commit()

    if not commit then
      return false
    end

    table.insert(cmd, commit .. "^")
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
  cmd = { "log", "--pretty=%h - %s (%cr)" },
  post_run = function(_, stdout)
    local lines = {}
    local extmarks = {}

    for i, line in ipairs(vim.split(stdout, "\n")) do
      local full_line, _, hash, date = line:find "^([^%s]+) - .* (%([^%)]+%))$"

      if not full_line then
        break
      end

      table.insert(extmarks, { line = i, col = 1, end_col = #hash, hl = "RedSign" })
      table.insert(extmarks, { line = i, col = #line - #date, end_col = #line, hl = "GreenSign" })
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

      local difflines = git_command { "diff", string.format("%s^..%s", hash, hash) }

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
  pre_run = function(_, cmd)
    local branch
    if vim.tbl_contains(cmd, "--create") then
      vim.ui.input({
        prompt = "Enter branch name: ",
      }, function(input)
        branch = input
      end)
    else
      branch = select_branch(false)
    end

    if not branch then
      return false
    end

    table.insert(cmd, branch)
  end,
}

M.merge = create_command {
  cmd = { "merge" },
  pre_run = function(_, cmd)
    local branch = select_branch(true)

    if not branch then
      return false
    end

    table.insert(cmd, branch)
  end,
}

M.stash = create_command {
  cmd = { "stash" },
  available_opts = { "staged", "include-untracked" },
}

return M
