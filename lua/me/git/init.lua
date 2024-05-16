local commands = require "me.git.commands"

local function git(args)
  local subcmd = table.remove(args.fargs, 1)

  local command = commands[subcmd]

  if command then
    command:run(args.fargs or {})
  end
end

---@param cmdline string
local function git_complete(_, cmdline, _)
  local subcmd, subcmd_arg_lead = cmdline:match "^Git%s+(%S+)%s+(.*)$"

  if subcmd and commands[subcmd] and subcmd_arg_lead then
    return commands[subcmd]:complete(subcmd_arg_lead)
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
