vim.rpcrequest(
  vim.fn.sockconnect("pipe", vim.env.NVIM, { rpc = true }),
  "nvim_command",
  string.format(
    'lua require("me.git.server").open("%s", "%s")',
    vim.fn.fnamemodify(vim.fn.argv()[1], ":p"),
    vim.fn.serverstart()
  )
)
