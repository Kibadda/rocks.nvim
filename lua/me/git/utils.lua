local M = {}

---@param cmd string[]
function M.git_command(cmd)
  local result = vim.system(vim.list_extend({ "git", "--no-pager" }, cmd)):wait()

  return vim.split(result.stdout, "\n")
end

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

    local complete = vim.tbl_filter(
      function(opt)
        if vim.tbl_contains(split, opt) then
          return false
        end

        return string.find(opt, "^" .. split[#split]) ~= nil
      end,
      scope == "add"
          and vim.list_extend(
            M.git_command { "diff", "--name-only" },
            M.git_command { "ls-files", "--others", "--exclude-standard" }
          )
        or M.git_command { "diff", "--cached", "--name-only" }
    )

    table.sort(complete)

    return complete
  end
end

return M
