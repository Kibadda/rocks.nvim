local M = {}

local path = require "plenary.path"

function M.open(file, client)
  local t = vim.fn.sockconnect("pipe", client, { rpc = true })

  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(bufnr, file)

  local filetype
  if file:find "COMMIT_EDITMSG$" then
    filetype = "gitcommit"
  elseif file:find "git%-rebase%-todo" then
    filetype = "git_rebase"
  end

  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = filetype

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, path:new(file):readlines())
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd.w { bang = true }
  end)

  local aborted = false

  vim.api.nvim_buf_attach(bufnr, false, {
    on_detach = function()
      pcall(vim.treesitter.stop, bufnr)

      if aborted then
        vim.rpcnotify(t, "nvim_command", "cq")
      else
        vim.rpcnotify(t, "nvim_command", "qall")
      end

      vim.fn.chanclose(t)
    end,
  })

  vim.keymap.set({ "i", "n" }, "<C-c>", function()
    aborted = true
    vim.cmd.stopinsert()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  local ok = pcall(vim.treesitter.language.inspect, filetype)
  if ok then
    vim.treesitter.start(bufnr, filetype)
  end

  vim.api.nvim_open_win(bufnr, true, {
    split = "below",
    win = 0,
    height = 20,
  })
end

return M
