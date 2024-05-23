---@class me.git.Command
---@field cmd string[]
---@field available_opts? string[]
---@field pre_run? fun(self: me.git.Command, opts: string[]): boolean?
---@field post_run? fun(self: me.git.Command, stdout: string)
---@field show_output? boolean
---@field complete? fun(self: me.git.Command, arg_lead: string): string[]
---@field additional_opts? boolean
local Command = {}

Command.__index = Command

function Command:run(fargs)
  local stdout = ""

  local cmd = vim.list_extend({ "git", "--no-pager" }, self.cmd)
  local opts = {}

  if self.available_opts then
    for _, opt in ipairs(self.available_opts) do
      if vim.tbl_contains(fargs, opt) then
        table.insert(opts, "--" .. opt)
      end
    end
  elseif self.additional_opts then
    vim.list_extend(opts, fargs)
  end

  if self.pre_run then
    if self:pre_run(opts) == false then
      return
    end
  end

  vim.fn.jobstart(vim.list_extend(cmd, opts), {
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

    return string.find(opt, "^" .. split[#split]) ~= nil
  end, self.available_opts or {})

  table.sort(complete)

  return complete
end

function Command:post_run(stdout)
  local output = {
    { "Done: " .. table.concat(self.cmd, " "), "WarningMsg" },
  }

  if self.show_output and stdout ~= "" then
    local skips = {
      "Compressing objects",
      "Counting objects",
      "Resolving deltas",
      "Unpacking objects",
      "Writing objects",
      "Receiving objects",
    }

    local highlight = "Green"
    for _, line in ipairs(vim.split(stdout, "\n")) do
      local skip = false

      for _, find in ipairs(skips) do
        if line:find(find) then
          skip = true
          break
        end
      end

      if not skip then
        if line:find "Changes not staged for commit" or line:find "Untracked files" then
          highlight = "Red"
        end

        if vim.startswith(line, "\t") then
          table.insert(output, { "\n" .. line, highlight })
        else
          local cstart, cend, branch = line:find "('%w+/%w+')"
          if cstart then
            table.insert(output, { "\n" .. line:sub(1, cstart - 1) })
            table.insert(output, { branch, "Blue" })
            table.insert(output, { line:sub(cend + 1) })
          else
            table.insert(output, { "\n" .. line })
          end
        end
      end
    end
  end

  if #output > 1 then
    table.insert(output, 1, { string.rep("─", vim.o.columns) })
  end

  vim.api.nvim_echo(output, true, {})
end

---@param opts me.git.Command
return function(opts)
  setmetatable(opts, Command)

  return opts
end
