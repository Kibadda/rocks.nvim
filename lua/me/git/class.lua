---@class me.git.Command
---@field cmd string[]
---@field available_opts? string[]
---@field pre_run? fun(self: me.git.Command, cmd: string[]): boolean?
---@field post_run? fun(self: me.git.Command, stdout: string)
---@field show_output? boolean
---@field complete? fun(self: me.git.Command, arg_lead: string): string[]
local Command = {}

Command.__index = Command

function Command:run(opts)
  local stdout = ""

  local cmd = { "git", "--no-pager" }

  for _, part in ipairs(self.cmd) do
    table.insert(cmd, part)
  end

  if self.available_opts then
    for _, opt in ipairs(self.available_opts) do
      if vim.tbl_contains(opts, opt) then
        table.insert(cmd, "--" .. opt)
      end
    end
  end

  if self.pre_run then
    if self:pre_run(cmd) == false then
      return
    end
  end

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
        self:post_run(stdout)
      end
    end,
    on_stdout = function(_, data)
      for _, chunk in ipairs(data) do
        stdout = stdout .. chunk
      end
    end,
  })
end

function Command:complete(arg_lead)
  local split = vim.split(arg_lead, "%s+")

  local complete = vim.tbl_filter(function(opt)
    if vim.tbl_contains(split, opt) then
      return false
    end

    return string.match(opt, "^" .. split[#split]) ~= nil
  end, self.available_opts or {})

  table.sort(complete)

  return complete
end

function Command:post_run(stdout)
  local output = {
    { "Done: " .. table.concat(self.cmd, " "), "WarningMsg" },
  }

  if self.show_output and stdout ~= "" then
    table.insert(output, { "\n" .. stdout })
  end

  vim.api.nvim_echo(output, true, {})
end

---@param opts me.git.Command
return function(opts)
  setmetatable(opts, Command)

  return opts
end
