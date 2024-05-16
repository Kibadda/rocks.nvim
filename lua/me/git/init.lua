local function jobstart(cmd, show_output)
  local stdout = ""

  vim.fn.jobstart(cmd, {
    cwd = vim.fn.getcwd(),
    env = {
      GIT_EDITOR = "nvim --headless --clean --noplugin -n -R -u "
        .. vim.fs.joinpath(vim.fn.stdpath "config" --[[@as string]], "lua", "me", "git", "client.lua"),
    },
    pty = true,
    width = 80,
    on_exit = function(_, code)
      stdout = stdout:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", ""):gsub("[\04\08]", ""):gsub("\r", "\n")

      if code ~= 0 then
        vim.notify(stdout, vim.log.levels.ERROR)
      else
        local output = {
          { "Done: " .. table.concat(cmd, " "), "WarningMsg" },
        }

        if show_output and stdout ~= "" then
          table.insert(output, { "\n" .. stdout })
        end

        vim.api.nvim_echo(output, true, {})
      end
    end,
    on_stdout = function(_, data)
      for _, chunk in ipairs(data) do
        stdout = stdout .. chunk
      end
    end,
  })
end

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

local commands = {
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

local function git(args)
  local subcmd = table.remove(args.fargs, 1)

  if commands[subcmd] then
    local opts = args.fargs or {}

    local cmd = { "git" }

    for _, c in ipairs(commands[subcmd].cmd) do
      table.insert(cmd, c)
    end

    if commands[subcmd].opts then
      for _, opt in ipairs(commands[subcmd].opts) do
        if vim.tbl_contains(opts, opt) then
          table.insert(cmd, "--" .. opt)
        end
      end
    end

    if commands[subcmd].extra then
      local opt = commands[subcmd].extra(cmd)

      if opt then
        table.insert(cmd, opt)
      end
    end

    jobstart(cmd, commands[subcmd].show_output)
  end
end

---@param cmdline string
local function git_complete(_, cmdline, _)
  local subcmd, subcmd_arg_lead = cmdline:match "^Git%s+(%S+)%s+(.*)$"

  if subcmd and subcmd_arg_lead then
    local opts = vim.split(subcmd_arg_lead, "%s+")

    local comp = vim.tbl_filter(function(opt)
      if vim.tbl_contains(opts, opt) then
        return false
      end

      return string.find(opt, opts[#opts]) ~= nil
    end, commands[subcmd].opts or {})

    table.sort(comp)

    return comp
  end

  subcmd = cmdline:match "^Git%s+(.*)$"

  local cmds = vim.tbl_keys(commands)

  table.sort(cmds)

  if subcmd then
    return vim.tbl_filter(function(cmd)
      return string.find(cmd, subcmd) ~= nil
    end, cmds)
  end
end

vim.api.nvim_create_user_command("Git", git, {
  bang = false,
  bar = false,
  complete = git_complete,
  desc = "Git wrapper",
  nargs = "+",
})
