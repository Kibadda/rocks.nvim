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
local cache = setmetatable({}, {
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

---@param scope "short"|"full"
---@return fun(_: me.git.Command, arg_lead: string): string[]
function M.complete_branches(scope)
  return function(_, arg_lead)
    local split = vim.split(arg_lead, "%s")

    if #split > 1 then
      return {}
    end

    local complete = vim.tbl_filter(function(opt)
      return string.find(opt, "^" .. split[#split]:gsub("%-", "%%-")) ~= nil
    end, scope == "short" and cache.short_branches or cache.full_branches)

    table.sort(complete)

    return complete
  end
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
