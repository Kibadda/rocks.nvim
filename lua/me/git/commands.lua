local create_command = require "me.git.class"

local function select_commit()
  local history = vim.split(vim.system({ "git", "log", '--pretty=format:"%h|%s"' }):wait().stdout:gsub('"', ""), "\n")

  local commits = {}
  for _, commit in ipairs(history) do
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

return {
  commit = create_command {
    cmd = { "commit" },
    available_opts = { "amend", "no-edit" },
  },

  fixup = create_command {
    cmd = { "commit", "--fixup" },
    pre_run = function(_, cmd)
      local commit = select_commit()

      if not commit then
        return false
      end

      table.insert(cmd, commit)
    end,
  },

  rebase = create_command {
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

        return string.match(opt, "^" .. split[#split]) ~= nil
      end, available_opts)

      table.sort(complete)

      return complete
    end,
  },

  push = create_command {
    cmd = { "push" },
    available_opts = { "force-with-lease" },
  },

  pull = create_command {
    cmd = { "pull" },
    show_output = true,
  },

  status = create_command {
    cmd = { "status" },
    show_output = true,
  },

  fetch = create_command {
    cmd = { "fetch" },
    available_opts = { "prune" },
    show_output = true,
  },
}
