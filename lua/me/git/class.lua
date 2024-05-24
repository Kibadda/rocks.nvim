---@class me.git.Command
---@field cmd string[]
---@field pre_run? fun(self: me.git.Command, fargs: string[]): boolean?
---@field post_run? fun(self: me.git.Command, stdout: string[])
---@field show_output? boolean
---@field complete? fun(self: me.git.Command, arg_lead: string): string[]
---@field completions? string[]|fun(fargs: string[]): string[]
local Command = {}

Command.__index = Command

function Command:run(fargs)
  local cmd = vim.list_extend({
    "git",
    "--no-pager",
    "-c",
    "color.ui=never",
  }, self.cmd)

  if self.pre_run then
    if self:pre_run(fargs) == false then
      return
    end
  end

  local line = ""
  local stdout = {}

  vim.fn.jobstart(vim.list_extend(cmd, fargs), {
    cwd = vim.fn.getcwd(),
    env = {
      GIT_EDITOR = "nvim --headless --clean --noplugin -n -R -u "
        .. vim.fs.joinpath(vim.fn.stdpath "config" --[[@as string]], "lua", "me", "git", "client.lua"),
    },
    pty = true,
    width = 80,
    height = 24,
    on_stdout = function(_, lines)
      line = line .. lines[1]:gsub("\r", "")

      for i = 2, #lines do
        table.insert(stdout, line)
        line = lines[i]:gsub("\r", "")
      end
    end,
    on_exit = function(_, code)
      if line ~= "" then
        table.insert(stdout, line)
      end

      if code ~= 0 then
        vim.notify(table.concat(stdout, "\n"), vim.log.levels.ERROR)
      else
        self:post_run(stdout)
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

    return string.find(opt, "^" .. split[#split]:gsub("%-", "%%-")) ~= nil
  end, self.completions and self.completions(split) or {})

  table.sort(complete)

  return complete
end

function Command:post_run(stdout)
  local output = {
    { "Done: " .. table.concat(self.cmd, " "), "WarningMsg" },
  }

  if self.show_output then
    local skips = {
      "Compressing objects",
      "Counting objects",
      "Resolving deltas",
      "Unpacking objects",
      "Writing objects",
      "Receiving objects",
    }

    local highlight = "Green"
    for _, line in ipairs(stdout) do
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
          local cstart, cend, branch = line:find "('[a-zA-z%-]+/[a-zA-z%-]+')"
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
