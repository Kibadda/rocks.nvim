local M = {}

local group = vim.api.nvim_create_augroup("LazyLoadin", { clear = true })

local function autocmd(event, opts)
  opts.group = group
  vim.api.nvim_create_autocmd(event, opts)
end

---@param event string|string[]
---@param callback function
function M.on_event(event, callback)
  autocmd(event, {
    callback = function(args)
      callback(args)

      return true
    end,
  })
end

---@param ft string|string[]
---@param callback function
function M.on_ft(ft, callback)
  autocmd("FileType", {
    pattern = ft,
    callback = function(args)
      callback(args)

      return true
    end,
  })
end

---@param keys { mode: string|string[], lhs: string }[]
---@param callback function
function M.on_key(keys, callback)
  local function handler(used_key)
    for _, key in ipairs(keys) do
      vim.keymap.del(key.mode, key.lhs)
    end

    callback()

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(used_key.lhs, true, false, true), "m", false)
  end

  for _, key in ipairs(keys) do
    vim.keymap.set(key.mode, key.lhs, function()
      handler(key)
    end)
  end
end

return M
