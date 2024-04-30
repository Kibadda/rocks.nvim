local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local clear = vim.api.nvim_clear_autocmds

local groups = {
  highlight = augroup("LspAttachHighlight", { clear = false }),
  codelens = augroup("LspAttachCodelens", { clear = false }),
  inlay = augroup("LspAttachInlay", { clear = false }),
}

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
        rhs = vim.lsp.buf.definition,
        desc = "Definition",
      },
      {
        method = methods.textDocument_references,
        lhs = "gr",
        rhs = function()
          vim.lsp.buf.references {
            includeDeclaration = false,
          }
        end,
        desc = "References",
      },
      {
        method = methods.textDocument_implementation,
        lhs = "gI",
        rhs = vim.lsp.buf.implementation,
        desc = "Implementations",
      },
      {
        method = methods.textDocument_declaration,
        lhs = "gD",
        rhs = vim.lsp.buf.declaration,
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
        rhs = vim.lsp.buf.document_symbol,
        desc = "Document Symbols",
      },
      {
        method = methods.workspace_symbol,
        lhs = "gS",
        rhs = vim.lsp.buf.workspace_symbol,
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
