---@class me.git.Cmd
---@field cmd string[]
---@field opts? string[]
---@field extra? fun(cmd: string[]): string?
---@field show_output? boolean

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

---@type table<string, me.git.Cmd>
return {
  commit = {
    cmd = { "commit" },
    opts = { "amend", "no-edit" },
  },

  fixup = {
    cmd = { "commit", "--fixup" },
    extra = select_commit,
  },

  rebase = {
    cmd = { "rebase" },
    opts = { "interactive", "autosquash", "abort", "skip", "continue" },
    extra = function(opts)
      for _, opt in ipairs(opts) do
        if vim.tbl_contains({ "--abort", "--skip", "--continue" }, opt) then
          return nil
        end
      end

      return select_commit() .. "^"
    end,
  },

  push = {
    cmd = { "push" },
    opts = { "force-with-lease" },
  },

  pull = {
    cmd = { "pull" },
    show_output = true,
  },

  status = {
    cmd = { "status" },
    show_output = true,
  },

  fetch = {
    cmd = { "fetch" },
    opts = { "prune" },
    show_output = true,
  },
}
