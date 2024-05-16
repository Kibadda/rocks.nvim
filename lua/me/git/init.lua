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

local commands = require "me.git.commands"

local function git(args)
  local subcmd = table.remove(args.fargs, 1)

  local command = commands[subcmd]

  if command then
    local opts = args.fargs or {}

    local cmd = { "git", "--no-pager" }

    for _, c in ipairs(command.cmd) do
      table.insert(cmd, c)
    end

    if command.opts then
      for _, opt in ipairs(command.opts) do
        if vim.tbl_contains(opts, opt) then
          table.insert(cmd, "--" .. opt)
        end
      end
    end

    if command.extra then
      local opt = command.extra(cmd)

      if opt then
        table.insert(cmd, opt)
      end
    end

    jobstart(cmd, command.show_output)
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
