return {
  "stevearc/conform.nvim",
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("ConformAutoFormat", { clear = true }),
      callback = function(args)
        local conform = require "conform"
        if #conform.list_formatters(args.buf) > 0 then
          vim.b[args.buf].formatter = conform.format
          vim.bo[args.buf].formatexpr = "v:lua.require'conform'.formatexpr()"
        end
      end,
    })
  end,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
    },
    notify_on_error = true,
  },
}
