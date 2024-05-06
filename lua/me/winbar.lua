local ok, devicons = pcall(require, "nvim-web-devicons")

return function()
  if vim.bo.buftype ~= "" then
    return ""
  end

  local winbar = vim.fn.fnamemodify(vim.fn.expand "%", ":.") .. ":%L"

  if winbar:sub(1, 1) ~= "/" then
    winbar = "./" .. winbar
  end

  if not ok then
    return winbar
  end

  local icon, hl = devicons.get_icon(vim.fn.fnamemodify(vim.fn.expand "%", ":t"), nil, { default = false })

  icon = type(icon) == "string" and (icon .. " ") or ""

  if type(hl) == "string" then
    icon = "%#" .. hl .. "#" .. icon .. "%*"
  end

  return " " .. icon .. winbar
end
