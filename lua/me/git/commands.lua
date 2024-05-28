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
  pre_run = function(_, fargs)
    if #fargs == 1 and fargs[1] == "--set-upstream" then
      local remote = utils.select_remote()

      if not remote then
        return false
      end

      table.insert(fargs, remote)
      table.insert(fargs, utils.git_command({ "branch", "--show-current" })[1])
    end
  end,
  completions = function(fargs)
    if #fargs > 1 then
      return {}
    end

    return { "--force-with-lease", "--set-upstream" }
  end,
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
    utils.create_log_buffer(stdout)
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
    return #opts > 0
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
    return vim.list_extend({ "--hard" }, utils.cache.staged_filenames)
  end,
}

M.delete = create_command {
  cmd = { "branch", "--delete" },
  completions = function()
    return vim.list_extend({ "--force" }, utils.cache.local_branches)
  end,
}

return M
