---@type table<string, boolean|ParserInfo>
local parsers = {
  php = true,
  php_only = true,
  rust = true,
  typescript = true,
  javascript = true,
  html = true,
  toml = true,
  lua = true,
  sql = true,
  hyprlang = true,
  markdown = true,
  markdown_inline = true,
  regex = true,
  smarty = {
    ---@diagnostic disable-next-line:missing-fields
    install_info = {
      path = vim.fn.expand "$HOME/Projects/Personal/tree-sitter-smarty",
      files = { "src/parser.c", "src/scanner.c" },
    },
    tier = 3,
  },
}

local function add_parsers()
  local treesitter_parsers = require "nvim-treesitter.parsers"

  for key, config in pairs(parsers) do
    if type(config) == "table" then
      treesitter_parsers[key] = config

      if not vim.tbl_contains(vim.opt.runtimepath:get(), config.install_info.path) then
        vim.opt.runtimepath:append(config.install_info.path)
      end
    end
  end
end

local group = vim.api.nvim_create_augroup("Treesitter", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "TSUpdate",
  callback = add_parsers,
})

add_parsers()

require("nvim-treesitter").setup {
  ensure_install = vim.iter(parsers):fold({}, function(acc, parser, config)
    if type(config) == "boolean" then
      table.insert(acc, parser)
    end

    return acc
  end),
}

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = vim.tbl_keys(parsers),
  callback = function(args)
    vim.treesitter.start()
    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
