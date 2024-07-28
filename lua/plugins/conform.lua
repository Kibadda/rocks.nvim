local mapping = {
  lua = { "stylua" },
}

return {
  "stevearc/conform.nvim",
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("ConformAutoFormat", { clear = true }),
      pattern = vim.tbl_keys(mapping),
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
    formatters_by_ft = mapping,
    notify_on_error = true,
  },
}
