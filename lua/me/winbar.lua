local ok, devicons = pcall(require, "nvim-web-devicons")

return function()
  if vim.bo.buftype ~= "" then
    return ""
  end

  local path = vim.fn.fnamemodify(vim.fn.expand "%", ":.")

  if path:len() == 0 then
    return ""
  end

  local filename = vim.fs.basename(path)
  path = vim.fs.dirname(path)

  if path:sub(1, 1) ~= "/" and path ~= "." then
    path = "./" .. path
  end

  path = path .. "/%#WinBarFilename#" .. filename .. "%*"

  local modified = vim.bo.modified and " %#WinBarModified#●︎%*" or ""

  if not ok then
    return path .. ":%L" .. modified
  end

  local icon, hl = devicons.get_icon(vim.fn.fnamemodify(vim.fn.expand "%", ":t"), nil, { default = false })

  icon = type(icon) == "string" and (icon .. " ") or ""

  if type(hl) == "string" then
    icon = "%#" .. hl .. "#" .. icon .. "%*"
  end

  return " " .. icon .. path .. ":%L" .. modified
end
