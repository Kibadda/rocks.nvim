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

function M.select_remote()
  return M.select {
    cmd = { "remote" },
    prompt = "Remote",
  }
end

function M.select_commit()
  return M.select {
    cmd = { "log", "--pretty=%h|%s" },
    prompt = "Commit",
    decode = function(line)
      return vim.split(line, "|")
    end,
    format = function(item)
      return item[2]
    end,
    choice = function(item)
      return item and item[1] or nil
    end,
  }
end

---@param opts { cmd: string[], prompt: string, decode?: function, format?: function, choice?: function }
---@return string?
function M.select(opts)
  local lines = {}

  for _, line in ipairs(M.git_command(opts.cmd)) do
    if line ~= "" then
      table.insert(lines, opts.decode and opts.decode(line) or line)
    end
  end

  if #lines <= 1 then
    return lines[1]
  end

  local choice

  vim.ui.select(lines, {
    prompt = opts.prompt,
    format_item = opts.format,
  }, function(item)
    choice = opts.choice and opts.choice(item) or item
  end)

  return choice
end

return M
