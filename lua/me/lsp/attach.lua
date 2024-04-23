local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local clear = vim.api.nvim_clear_autocmds

autocmd("LspAttach", {
  group = augroup("LspAttach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { desc = desc, buffer = bufnr })
    end

    local groups = {
      highlight = augroup("LspAttachHighlight", { clear = false }),
      -- codelens = augroup("LspAttachHighlight", { clear = false }),
      -- inlay = augroup("LspAttachHighlight", { clear = false }),
    }

    local methods = vim.lsp.protocol.Methods

    if client.supports_method(methods.textDocument_documentHighlight) then
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
    end

    if client.supports_method(methods.textDocument_rename) then
      map("crr", vim.lsp.buf.rename, "Rename")
    end

    if client.supports_method(methods.textDocument_signatureHelp) then
      map("<C-s>", vim.lsp.buf.signature_help, "Signature Help", "i")
    end

    if client.supports_method(methods.textDocument_formatting) and not vim.b[bufnr].formatter then
      vim.b[bufnr].formatter = vim.lsp.buf.format
    end

    if client.supports_method(methods.textDocument_definition) then
      map("gd", vim.lsp.buf.definition, "Go to Definition")
    end

    if client.supports_method(methods.textDocument_documentSymbol) then
      map("<Leader>ls", vim.lsp.buf.document_symbol, "Symbols")
    end

    map("<Leader>lj", vim.diagnostic.goto_next, "Next Diagnostic")
    map("<Leader>lk", vim.diagnostic.goto_prev, "Prev Diagnostic")
  end,
})
