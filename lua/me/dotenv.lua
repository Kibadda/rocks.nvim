local M = {
  loaded = false,
}

function M.load()
  if M.loaded then
    return
  end

  M.loaded = true

  local envfile = vim.fn.stdpath "config" .. "/.env"

  if vim.fn.filereadable(envfile) == 0 then
    return
  end

  vim.cmd.Dotenv(envfile)
end

return M
