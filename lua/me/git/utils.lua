local M = {}

---@param cmd string[]
function M.git_command(cmd)
  local result = vim.system(vim.list_extend({ "git", "--no-pager" }, cmd)):wait()

  return vim.split(result.stdout, "\n")
end

---@class me.git.CompleteCache
---@field unstaged_filenames string[]
---@field staged_filenames string[]

---@type me.git.CompleteCache
local cache = setmetatable({}, {
  ---@param self table
  ---@param key "unstaged_filenames"|"staged_filenames"
  ---@return string[]
  __index = function(self, key)
    if key == "unstaged_filenames" then
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
    for key in pairs(cache) do
      cache[key] = nil
    end
  end,
})

---@return string?
function M.select_commit()
  local commits = {}
  for _, commit in ipairs(M.git_command { "log", "--pretty=%h|%s" }) do
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

---@return string?
function M.select_branch(remote)
  local cmd = { "branch", "--column=plain" }

  if remote then
    table.insert(cmd, "-r")
  end

  local branches = {}
  for _, branch in ipairs(M.git_command(cmd)) do
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

---@param scope "add"|"reset"
---@return fun(_: me.git.Command, arg_lead: string): string[]
function M.complete_filenames(scope)
  return function(_, arg_lead)
    local split = vim.split(arg_lead, "%s+")

    local complete = vim.tbl_filter(function(opt)
      if vim.tbl_contains(split, opt) then
        return false
      end

      return string.find(opt, "^" .. split[#split]:gsub("%-", "%%-")) ~= nil
    end, scope == "add" and cache.unstaged_filenames or cache.staged_filenames)

    table.sort(complete)

    return complete
  end
end

return M
