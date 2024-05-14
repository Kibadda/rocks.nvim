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

local install = {
  "php",
  "php_only",
  "rust",
  "typescript",
  "javascript",
  "html",
  "toml",
  "lua",
  "sql",
  "hyprlang",
  "rust",
  "markdown",
  "markdown_inline",
  "regex",
}

require("nvim-treesitter").setup {
  ensure_install = install,
}

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = vim.list_extend({ "smarty" }, install),
  callback = function(args)
    vim.treesitter.start()
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
