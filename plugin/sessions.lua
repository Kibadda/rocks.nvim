if vim.g.loaded_session then
  return
end

vim.g.loaded_session = 1

vim.g.session_dir = vim.fn.stdpath "data" .. "/session"

---@param session string
local function save(session)
  pcall(vim.cmd.argdelete, "*")

  vim.cmd.mksession {
    args = { session },
    bang = true,
  }
end

local function new()
  local session

  vim.ui.input({ prompt = "Session name: " }, function(input)
    session = input
  end)

  if not session or vim.fn.filereadable(vim.g.session_dir .. "/" .. session) == 1 then
    return
  end

  save(vim.g.session_dir .. "/" .. session)
end

local function update()
  if vim.v.this_session == nil or #vim.v.this_session == 0 or vim.fn.filereadable(vim.v.this_session) == 0 then
    return
  end

  save(vim.v.this_session)
end

---@param session? string
local function load(session)
  if not session or vim.fn.filereadable(vim.g.session_dir .. "/" .. session) == 0 then
    return
  end

  update()

  vim.lsp.stop_client(vim.lsp.get_clients())

  vim.cmd "silent! %bwipeout"
  vim.cmd.source(vim.g.session_dir .. "/" .. session)

  vim.cmd.clearjumps()
end

local function delete()
  if vim.v.this_session == nil or #vim.v.this_session == 0 or vim.fn.filereadable(vim.v.this_session) == 0 then
    return
  end

  if vim.fn.confirm("Delete current session?", "&Yes\n&No", 2) == 1 then
    os.remove(vim.v.this_session)
  end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("Session", { clear = true }),
  callback = update,
})

vim.keymap.set("n", "<Leader>Sn", new, { desc = "New" })
vim.keymap.set("n", "<Leader>Sd", delete, { desc = "Delete" })

vim.g.session_load = load
