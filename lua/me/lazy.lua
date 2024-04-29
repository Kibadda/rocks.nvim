local M = {}

---@alias me.lazy.EventOpts { group?: integer, event: string, pattern?: string, callback: function }
---@alias me.lazy.KeyOpts { mode: string|string[], lhs: string, callback: function }

---@param opts me.lazy.EventOpts
local function on_event(opts)
  vim.api.nvim_create_autocmd(opts.event, {
    group = opts.group,
    pattern = opts.pattern,
    callback = function(args)
      opts.callback(args)

      return true
    end,
  })
end

---@param opts me.lazy.KeyOpts
local function on_key(opts)
  vim.keymap.set(opts.mode, opts.lhs, function()
    opts.callback()

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(opts.lhs, true, false, true), "m", false)
  end)
end

---@param opts { by_events?: me.lazy.EventOpts[], by_keys?: me.lazy.KeyOpts[] }
---@param callback function
function M.on(opts, callback)
  local group = vim.api.nvim_create_augroup("LazyLoad" .. math.ceil(math.random() * 1000), { clear = true })

  local function handler()
    if opts.by_keys then
      for _, key in ipairs(opts.by_keys) do
        vim.keymap.del(key.mode, key.lhs)
      end
    end

    vim.api.nvim_del_augroup_by_id(group)

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
end

return M
