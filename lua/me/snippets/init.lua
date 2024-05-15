local M = {}

---@param params cmp.SourceCompletionApiParams
---@param callback function
function M:complete(params, callback)
  local ok, items = pcall(require, "me.snippets." .. params.context.filetype)
  if not ok then
    return {}
  end

  local result = {}

  for trigger, item in pairs(items) do
    table.insert(result, {
      word = trigger,
      label = trigger,
      kind = require("cmp").lsp.CompletionItemKind.Snippet,
      data = {
        snippet = item,
      },
    })
  end

  callback(result)
end

---@param item lsp.CompletionItem
---@param callback function
function M:execute(item, callback)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  col = col - #item.word
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col + #item.word, { "" })
  vim.snippet.expand(item.data.snippet)
  callback(item)
end

return M
