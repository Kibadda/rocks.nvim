local conform = require "conform"

conform.setup {
  formatters_by_ft = {
    lua = { "stylua" },
  },
  notify_on_error = false,
}

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("Conform", { clear = true }),
  callback = function(args)
    if #conform.list_formatters(args.buf) > 0 then
      vim.b[args.buf].formatter = conform.format
      vim.bo[args.buf].formatexpr = "v:lua.require'conform'.formatexpr()"
    end
  end,
})
