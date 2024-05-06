local M = {}

---@alias me.lazy.EventOpts { group?: integer, event: string, pattern?: string, callback: function }
---@alias me.lazy.KeyOpts { mode: string|string[], lhs: string, rhs?: string|function, callback: function, desc?: string }
---@alias me.lazy.CmdOpts { name: string, opts?: vim.api.keyset.user_command, command?: function, callback: function }

---@param opts me.lazy.EventOpts
local function on_event(opts)
  vim.api.nvim_create_autocmd(opts.event, {
    group = opts.group,
    pattern = opts.pattern,
    callback = function(args)
      opts.callback(args)

      vim.api.nvim_exec_autocmds(opts.event, {
        buffer = args.buf,
      })
    end,
  })
end

---@param opts me.lazy.KeyOpts
local function on_key(opts)
  vim.keymap.set(opts.mode, opts.lhs, function()
    opts.callback()

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(opts.lhs, true, false, true), "m", false)
  end, { desc = opts.desc })
end

---@param opts me.lazy.CmdOpts
local function on_cmd(opts)
  vim.api.nvim_create_user_command(opts.name, function(args)
    opts.callback()

    vim.cmd(opts.name .. " " .. args.args)
  end, opts.opts or {})
end

---@param opts { by_events?: me.lazy.EventOpts[], by_keys?: me.lazy.KeyOpts[], by_cmds?: me.lazy.CmdOpts[] }
---@param callback function
function M.on(opts, callback)
  local group = vim.api.nvim_create_augroup("LazyLoad" .. math.ceil(math.random() * 1000), { clear = true })

  local function handler()
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

    callback()
  end

  if opts.by_events then
    for _, event in ipairs(opts.by_events) do
      event.group = group
      event.callback = handler
      on_event(event)
    end
  end

  if opts.by_keys then
    for _, key in ipairs(opts.by_keys) do
      key.callback = handler
      on_key(key)
    end
  end

  if opts.by_cmds then
    for _, cmd in ipairs(opts.by_cmds) do
      cmd.callback = handler
      on_cmd(cmd)
    end
  end
end

return M
