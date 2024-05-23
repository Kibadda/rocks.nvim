local M = {}

---@param cmd string[]
function M.git_command(cmd)
  local result = vim.system(vim.list_extend({ "git", "--no-pager" }, cmd)):wait()

  return vim.split(result.stdout, "\n")
end

---@class me.git.CompleteCache
---@field short_branches string[]
---@field full_branches string[]
---@field unstaged_filenames string[]
---@field staged_filenames string[]

---@type me.git.CompleteCache
M.cache = setmetatable({}, {
  ---@param self table
  ---@param key "short_branches"|"full_branches"|"unstaged_filenames"|"staged_filenames"
  ---@return string[]
  __index = function(self, key)
    if key:find "branches" then
      local branches = {}

      for _, branch in ipairs(M.git_command { "branch", "--column=plain", "--all" }) do
        if not branch:find "HEAD" and branch ~= "" then
          branch = vim.trim(branch:gsub("*", ""))

          if key == "short_branches" then
            branch = branch:gsub("remotes/[^/]+/", "")
          elseif key == "full_branches" then
            branch = branch:gsub("remotes/", "")
          end

          branches[branch] = true
        end
      end

      self[key] = vim.tbl_keys(branches)
    elseif key == "unstaged_filenames" then
      local files = {}

      for _, file in ipairs(M.git_command { "diff", "--name-only" }) do
        files[file] = true
      end
      for _, file in ipairs(M.git_command { "ls-files", "--others", "--exclude-standard" }) do
        files[file] = true
      end

      self[key] = vim.tbl_keys(files)
    elseif key == "staged_filenames" then
      self[key] = M.git_command { "diff", "--cached", "--name-only" }
    end

    return self[key]
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = vim.api.nvim_create_augroup("GitCmdlineLeave", { clear = true }),
  callback = function()
    for key in pairs(M.cache) do
      M.cache[key] = nil
    end
  end,
})

---@return string?
function M.select_remote()
  local remotes = {}
  for _, remote in ipairs(M.git_command { "remote" }) do
    if remote ~= "" then
      table.insert(remotes, remote)
    end
  end

  local remote

  vim.ui.select(remotes, {
    prompt = "Remote",
  }, function(item)
    remote = item
  end)

  return remote
end

---@return string?
function M.select_commit()
  local commits = {}
  for _, commit in ipairs(M.git_command { "log", "--pretty=%h|%s" }) do
    if commit ~= "" then
      table.insert(commits, vim.split(commit, "|"))
    end
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

return M
