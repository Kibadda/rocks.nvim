local M = {}

---@param cmd string[]
function M.git_command(cmd)
  local result = vim.system(vim.list_extend({ "git", "--no-pager" }, cmd)):wait()

  return vim.split(result.stdout, "\n")
end

---@class me.git.CompleteCache
---@field short_branches string[]
---@field full_branches string[]
---@field local_branches string[]
---@field unstaged_filenames string[]
---@field staged_filenames string[]

---@type me.git.CompleteCache
M.cache = setmetatable({}, {
  ---@param self table
  ---@param key "short_branches"|"full_branches"|"local_branches"|"unstaged_filenames"|"staged_filenames"
  ---@return string[]
  __index = function(self, key)
    if key:find "branches" then
      local branches = {}

      local cmd = { "branch", "--column=plain" }

      if key ~= "local_branches" then
        table.insert(cmd, "--all")
      end

      for _, branch in ipairs(M.git_command(cmd)) do
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

function M.open_split(opts)
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(bufnr, opts.name or "GIT")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, opts.lines or {})
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].bufhidden = "wipe"

  if opts.ft then
    vim.bo[bufnr].filetype = opts.ft
  end

  local ns = vim.api.nvim_create_namespace("git" .. bufnr)

  for _, extmark in ipairs(opts.extmarks or {}) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, extmark.line - 1, extmark.col - 1, {
      end_col = extmark.end_col,
      hl_group = extmark.hl,
    })
  end

  local win = vim.api.nvim_open_win(bufnr, opts.enter ~= false, {
    split = opts.split or "below",
    win = 0,
    height = (not opts.split or opts.split == "below" or opts.split == "above") and opts.size or nil,
    width = (opts.split == "left" or opts.split == "right") and opts.size or nil,
  })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end, { buffer = bufnr })

  return win, bufnr
end

function M.create_log_buffer(lines)
  local extmarks = {}

  for i, line in ipairs(lines) do
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
  end

  local _, bufnr = M.open_split {
    name = "GIT LOG",
    lines = lines,
    extmarks = extmarks,
  }

  vim.keymap.set("n", "<CR>", function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local hash = line:match "^([^%s]+)"
    local difflines = M.git_command { "diff", string.format("%s^..%s", hash, hash) }

    M.create_diff_buffer(difflines)
  end)
end

function M.create_diff_buffer(lines)
  local _, bufnr = M.open_split {
    name = "GIT DIFF",
    lines = lines,
    ft = "diff",
  }

  vim.keymap.set("n", "<CR>", function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end, { buffer = bufnr })
end

return M
