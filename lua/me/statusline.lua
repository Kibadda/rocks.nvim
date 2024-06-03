local mode_mapping = {
  n = { text = "NORMAL", hl = "StatusLineNormal" },
  v = { text = "VISUAL", hl = "StatusLineVisual" },
  V = { text = "VISUAL", hl = "StatusLineVisual" },
  ["\22"] = { text = "VISUAL", hl = "StatusLineVisual" },
  s = { text = "SELECT", hl = "StatusLineSelect" },
  S = { text = "SELECT", hl = "StatusLineSelect" },
  ["\19"] = { text = "SELECT", hl = "StatusLineSelect" },
  i = { text = "INSERT", hl = "StatusLineInsert" },
  R = { text = "REPLACE", hl = "StatusLineReplace" },
  c = { text = "COMMAND", hl = "StatusLineCommand" },
  r = { text = "CONFIRM", hl = "StatusLineConfirm" },
  ["!"] = { text = "TERMINAL", hl = "StatusLineTerminal" },
  t = { text = "TERMINAL", hl = "StatusLineTerminal" },
}

local function mode()
  local mod = mode_mapping[vim.fn.mode()]

  return "%#" .. mod.hl .. "# " .. mod.text .. " %*", #mod.text + 2
end

local function git()
  local function diff()
    local status = vim.b.git or {}

    return " %#diffAdded#+"
      .. (status.added or 0)
      .. "%#diffRemoved#-"
      .. (status.removed or 0)
      .. "%#diffChanged#~"
      .. (status.changed or 0)
  end

  return "%#StatusLineGitHead# " .. vim.g.git_head .. (vim.g.git_head ~= "no git" and diff() or "") .. "%*"
end

local function diagnostics()
  local d = vim.diagnostic.count(0)

  local error = d[1] and (d[1] < 10 and d[1] or "#") or 0
  local warning = d[2] and (d[2] < 10 and d[2] or "#") or 0
  local info = d[3] and (d[3] < 10 and d[3] or "#") or 0
  local hint = d[4] and (d[4] < 10 and d[4] or "#") or 0

  return "%#DiagnosticSignError#E"
    .. error
    .. "%#DiagnosticSignWarn#W"
    .. warning
    .. "%#DiagnosticSignInfo#I"
    .. info
    .. "%#DiagnosticSignHint#H"
    .. hint
    .. "%*"
end

local function filename()
  return vim.fs.basename(vim.api.nvim_buf_get_name(0))
end

local function filetype()
  local ok, devicons = pcall(require, "nvim-web-devicons")

  local icon, hl

  if ok then
    icon, hl = devicons.get_icon_by_filetype(vim.bo.filetype)
  end

  return (icon and ("%#" .. hl .. "#" .. icon .. "%* ") or "") .. vim.bo.filetype
end

local function clients()
  local names = {}

  for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
    table.insert(names, client.name .. "[" .. client.id .. "]")
  end

  local ok, conform = pcall(require, "conform")

  if ok then
    for _, source in ipairs(conform.list_formatters(0)) do
      table.insert(names, source.name)
    end
  end

  return "%#StatusLineClients#" .. (#names > 0 and table.concat(names, ", ") or "LS inactive") .. "%*"
end

local function format()
  return "%#"
    .. (vim.g.AutoFormat == 1 and "StatusLineFormatOn" or "StatusLineFormatOff")
    .. "#"
    .. (vim.g.AutoFormat == 1 and "✓" or "✗")
    .. "%*"
end

local function position()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local total = vim.api.nvim_buf_line_count(0)
  local percentage

  if cursor[1] == 1 then
    percentage = "Top"
  elseif cursor[1] == total then
    percentage = "Bot"
  else
    percentage = ("%02d"):format(math.floor((cursor[1] / total) * 100)) .. "%%"
  end

  return "%#"
    .. mode_mapping[vim.fn.mode()].hl
    .. "#"
    .. (" %03d:%03d | %s "):format(cursor[1], cursor[2] + 1, percentage)
    .. "%*"
end

return function()
  return ("%s %s | %s | %s%%=%s | %s | %s %s"):format(
    mode(),
    git(),
    diagnostics(),
    filename(),
    filetype(),
    clients(),
    format(),
    position()
  )
end
