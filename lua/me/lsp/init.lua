local M = {
  ---@type table<string, me.lsp.ServerConfig>
  servers = {},
  augroup = vim.api.nvim_create_augroup("LspServers", { clear = true }),
}

---@class me.lsp.ServerConfig
---@field filetypes string[]
---@field root_markers string[]
---@field config vim.lsp.ClientConfig
---@field client? vim.lsp.Client

---@param server me.lsp.ServerConfig
local function start(server, buf)
  if server.root_markers then
    server.config.root_dir = vim.fs.root(buf, server.root_markers)
    vim.fn.chdir(server.config.root_dir)
  end

  local id = vim.lsp.start(server.config)

  if id then
    server.client = vim.lsp.get_client_by_id(id)
  end
end

---@param server me.lsp.ServerConfig
function M.register(server)
  server.config.name = server.config.name or server.config.cmd[1]

  server.config.capabilities =
    vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), server.config.capabilities or {})

  M.servers[server.config.name] = server

  vim.api.nvim_create_autocmd("FileType", {
    group = M.augroup,
    pattern = server.filetypes,
    callback = function(args)
      start(server, args.buf)
    end,
  })
end

function M.server_names()
  local names = vim.tbl_keys(M.servers)

  table.sort(names)

  return names
end

function M.start(name)
  if not M.servers[name] then
    return
  end

  start(M.servers[name], 0)
end

function M.stop(name)
  local server = M.servers[name]

  if not server then
    return
  end

  server.client.stop()
  server.client = nil
end

local commands = {
  start = {
    command = function(names)
      for _, name in ipairs(names) do
        M.start(name)
      end
    end,
    complete = function(names)
      names = vim.split(names, "%s+")

      return vim.tbl_filter(function(name)
        if M.servers[name].client then
          return false
        end

        if vim.tbl_contains(names, name) then
          return false
        end

        return string.find(name, names[#names]) ~= nil
      end, M.server_names())
    end,
  },
  stop = {
    command = function(names)
      for _, name in ipairs(names) do
        M.stop(name)
      end
    end,
    complete = function(names)
      names = vim.split(names, "%s+")

      return vim.tbl_filter(function(name)
        if not M.servers[name].client then
          return false
        end
        --
        if vim.tbl_contains(names, name) then
          return false
        end

        return string.find(name, names[#names]) ~= nil
      end, M.server_names())
    end,
  },
}

local function lsp(args)
  local cmd = table.remove(args.fargs, 1)

  if commands[cmd] then
    commands[cmd].command(args.fargs)
  end
end

---@param cmdline string
local function lsp_complete(_, cmdline, _)
  local subcmd, subcmd_arg_lead = cmdline:match "^Lsp%s+(%S+)%s+(.*)$"
  if subcmd and subcmd_arg_lead and commands[subcmd].complete then
    return commands[subcmd].complete(subcmd_arg_lead)
  end

  subcmd = cmdline:match "^Lsp%s+(.*)$"

  local cmds = vim.tbl_keys(commands)
  table.sort(cmds)
  if subcmd then
    return vim.tbl_filter(function(cmd)
      return string.find(cmd, subcmd) ~= nil
    end, cmds)
  end
end

vim.api.nvim_create_user_command("Lsp", lsp, {
  desc = "Lsp",
  nargs = "+",
  bang = false,
  bar = false,
  complete = lsp_complete,
})

return M
