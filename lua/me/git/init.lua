local M = {}

function M.commit()
  vim.fn.jobstart({ "git", "commit" }, {
    cwd = vim.fn.getcwd(),
    env = {
      GIT_EDITOR = "nvim --headless --clean --noplugin -n -R -u "
        .. vim.fs.joinpath(vim.fn.stdpath "config" --[[@as string]], "lua", "me", "git", "client.lua"),
    },
    pty = true,
    width = 80,
  })
end

return M
