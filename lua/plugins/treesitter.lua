local group = vim.api.nvim_create_augroup("Treesitter", { clear = true })
local path = vim.fn.expand "$HOME/Projects/Personal/tree-sitter-smarty"

local function add_parsers()
  require("nvim-treesitter.parsers").smarty = {
    ---@diagnostic disable-next-line:missing-fields
    install_info = {
      path = path,
      files = { "src/parser.c", "src/scanner.c" },
    },
    tier = 3,
  }
end

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "TSUpdate",
  callback = add_parsers,
})

add_parsers()

vim.opt.runtimepath:append(path)

require("nvim-treesitter").setup()

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "smarty", "php", "typescript", "javascript", "html" },
  callback = function(args)
    vim.treesitter.start()
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
