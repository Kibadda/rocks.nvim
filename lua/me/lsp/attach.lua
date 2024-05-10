local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local clear = vim.api.nvim_clear_autocmds

local groups = {
  highlight = augroup("LspAttachHighlight", { clear = false }),
  codelens = augroup("LspAttachCodelens", { clear = false }),
  inlay = augroup("LspAttachInlay", { clear = false }),
}

local function on_list(opts)
  require("me.lazy").load "mini-pick"
  require("mini.pick").registry.lsp {
    title = "Lsp " .. vim.split(opts.title, " ")[1],
    items = opts.items,
  }
end

autocmd("LspAttach", {
  group = augroup("LspAttach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    local methods = vim.lsp.protocol.Methods

    ---@type table<string, { method?: string, lhs?: string, rhs?: function, mode?: string, desc?: string, extra?: function }>
    local maps = {
      {
        method = methods.textDocument_definition,
        lhs = "gd",
        rhs = function()
          vim.lsp.buf.definition { on_list = on_list }
        end,
        desc = "Definition",
      },
      {
        method = methods.textDocument_references,
        lhs = "gr",
        rhs = function()
          vim.lsp.buf.references({
            includeDeclaration = false,
          }, { on_list = on_list })
        end,
        desc = "References",
      },
      {
        method = methods.textDocument_implementation,
        lhs = "gI",
        rhs = function()
          vim.lsp.buf.implementation { on_list = on_list }
        end,
        desc = "Implementations",
      },
      {
        method = methods.textDocument_declaration,
        lhs = "gD",
        rhs = function()
          vim.lsp.buf.declaration { on_list = on_list }
        end,
        desc = "Declaration",
      },
      {
        method = methods.textDocument_rename,
        lhs = "crn",
        rhs = vim.lsp.buf.rename,
        desc = "Rename",
      },
      {
        method = methods.textDocument_codeAction,
        lhs = "crr",
        rhs = vim.lsp.buf.code_action,
        desc = "Code Action",
      },
      {
        method = methods.textDocument_signatureHelp,
        lhs = "<C-s>",
        rhs = vim.lsp.buf.signature_help,
        mode = "i",
        desc = "Signature Help",
      },
      {
        method = methods.textDocument_documentSymbol,
        lhs = "gs",
        rhs = function()
          vim.lsp.buf.document_symbol { on_list = on_list }
        end,
        desc = "Document Symbols",
      },
      {
        method = methods.workspace_symbol,
        lhs = "gS",
        rhs = function()
          vim.lsp.buf.workspace_symbol(nil, { on_list = on_list })
        end,
        desc = "Workspace Symbols",
      },
      {
        method = methods.textDocument_codeLens,
        lhs = "gl",
        rhs = vim.lsp.codelens.run,
        desc = "Run Codelens",
        extra = function()
          clear { group = groups.codelens, buffer = bufnr }
          autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            group = groups.codelens,
            buffer = bufnr,
            callback = function()
              vim.lsp.codelens.refresh { bufnr = bufnr }
            end,
          })
        end,
      },
      {
        method = methods.textDocument_documentHighlight,
        extra = function()
          clear { group = groups.highlight, buffer = bufnr }
          autocmd({ "CursorHold", "InsertLeave", "BufEnter" }, {
            group = groups.highlight,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })
          autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
            group = groups.highlight,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end,
      },
      {
        method = methods.textDocument_inlayHint,
        lhs = "gL",
        rhs = function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(bufnr), { bufnr = bufnr })
        end,
        desc = "Toggle Inlay Hint",
      },
      {
        method = methods.textDocument_formatting,
        extra = function()
          vim.b[bufnr].formatter = vim.lsp.buf.format
        end,
      },
      {
        lhs = "<Leader>lj",
        rhs = function()
          vim.diagnostic.goto_next()
        end,
        desc = "Next diagnostic",
      },
      {
        lhs = "<Leader>lk",
        rhs = function()
          vim.diagnostic.goto_prev()
        end,
        desc = "Previous diagnostic",
      },
    }

    for _, mapping in ipairs(maps) do
      if not mapping.method or client.supports_method(mapping.method) then
        if mapping.lhs then
          vim.keymap.set(mapping.mode or "n", mapping.lhs, mapping.rhs, {
            buffer = bufnr,
            desc = mapping.desc,
          })
        end

        if mapping.extra then
          mapping.extra()
        end
      end
    end
  end,
})
