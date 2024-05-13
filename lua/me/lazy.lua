local M = {
  ---@type table<string, function>
  lazy_loaders = {},
}

---@class me.lazy.EventOpts
---@field event string
---@field pattern? string
---@field group? integer
---@field callback? function
---@field loader? function

---@class me.lazy.KeyOpts
---@field mode string|string[]
---@field lhs string
---@field rhs? string|function
---@field desc? string
---@field loader? function

---@class me.lazy.CmdOpts
---@field name string
---@field command? function
---@field opts? vim.api.keyset.user_command
---@field loader? function

---@param opts me.lazy.EventOpts
local function on_event(opts)
  vim.api.nvim_create_autocmd(opts.event, {
    group = opts.group,
    pattern = opts.pattern,
    callback = function(args)
      opts.loader(args)

      vim.api.nvim_exec_autocmds(opts.event, {
        buffer = args.buf,
      })
    end,
  })
end

---@param opts me.lazy.KeyOpts
local function on_key(opts)
  vim.keymap.set(opts.mode, opts.lhs, function()
    opts.loader()

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(opts.lhs, true, false, true), "m", false)
  end, { desc = opts.desc })
end

---@param opts me.lazy.CmdOpts
local function on_cmd(opts)
  vim.api.nvim_create_user_command(opts.name, function(args)
    opts.loader()

    vim.cmd(opts.name .. " " .. args.args)
  end, opts.opts or {})
end

---@param name string
---@param opts { by_events?: me.lazy.EventOpts[], by_keys?: me.lazy.KeyOpts[], by_cmds?: me.lazy.CmdOpts[] }
---@param callback function
function M.on(name, opts, callback)
  local group = vim.api.nvim_create_augroup("LazyLoad" .. name, { clear = true })

  local function loader()
    if opts.by_keys then
      for _, key in ipairs(opts.by_keys) do
        vim.keymap.del(key.mode, key.lhs)

        if key.rhs then
          vim.keymap.set(key.mode, key.lhs, key.rhs, { desc = key.desc })
        end
      end
    end

    vim.api.nvim_del_augroup_by_id(group)

    if opts.by_cmds then
      for _, cmd in ipairs(opts.by_cmds) do
        vim.api.nvim_del_user_command(cmd.name)

        if cmd.command then
          vim.api.nvim_create_user_command(cmd.name, cmd.command, cmd.opts)
        end
      end
    end

    M.lazy_loaders[name] = nil

    callback()
  end

  if opts.by_events then
    for _, event in ipairs(opts.by_events) do
      event.group = group
      event.loader = loader
      on_event(event)
    end
  end

  if opts.by_keys then
    for _, key in ipairs(opts.by_keys) do
      key.loader = loader
      on_key(key)
    end
  end

  if opts.by_cmds then
    for _, cmd in ipairs(opts.by_cmds) do
      cmd.loader = loader
      on_cmd(cmd)
    end
  end

  M.lazy_loaders[name] = loader
end

---@param name string
function M.load(name)
  if M.lazy_loaders[name] then
    M.lazy_loaders[name]()
  end
end

return M
