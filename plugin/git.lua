if vim.g.loaded_git then
  return
end

vim.g.loaded_git = 1

local running = false

local function buf_set_git(buf, git)
  vim.b[buf].git = git

  running = false

  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", {
      pattern = "GitUpdate",
      data = { buf = buf },
    })
  end)
end

vim.g.git_head = "no git"

vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufEnter", "FocusGained" }, {
  group = vim.api.nvim_create_augroup("Git", { clear = true }),
  callback = vim.schedule_wrap(function(args)
    if running or not vim.api.nvim_buf_is_valid(args.buf) or vim.bo[args.buf].buftype ~= "" then
      return
    end

    running = true

    local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":.")
    local changed = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")

    vim.system({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, { text = true }, function(obj1)
      local git = {
        added = 0,
        changed = 0,
        removed = 0,
      }

      if obj1.code ~= 0 or not obj1.stdout then
        buf_set_git(args.buf, git)
        return
      end

      local branch = vim.trim(obj1.stdout)

      if #branch == 0 then
        buf_set_git(args.buf, git)
        return
      end

      vim.g.git_head = branch

      vim.system({ "git", "show", (":%s"):format(bufname) }, { text = true }, function(obj2)
        if
          (obj2.code ~= 0 or not obj2.stdout)
          and (obj2.code ~= 128 or not obj2.stderr or not obj2.stderr:find "but not in the index")
        then
          buf_set_git(args.buf, git)
          return
        end

        vim.diff(obj2.code == 0 and obj2.stdout or "", changed, {
          ignore_whitespace_change = true,
          on_hunk = function(_, c1, _, c2)
            if c1 == 1 and c2 > 1 then
              git.added = git.added + c2
            elseif c1 > 1 and c2 == 1 then
              git.removed = git.removed + c1
            else
              local delta = math.min(c1, c2)
              git.changed = git.changed + delta
              git.added = git.added + c2 - delta
              git.removed = git.removed + c1 - delta
            end
          end,
        })

        buf_set_git(args.buf, git)
      end)
    end)
  end),
})

vim.keymap.set("n", "gH", function()
  local remote = vim.trim(vim.system({ "git", "remote" }):wait().stdout)

  if #remote == 0 then
    vim.notify("no remote found", vim.log.levels.WARN)

    return
  end

  local result = vim.system({ "git", "config", "--get", ("remote.%s.url"):format(remote) }):wait()

  if result.code ~= 0 then
    vim.notify("no url found for remote " .. remote, vim.log.levels.WARN)

    return
  end

  local url = vim.trim(result.stdout)

  if vim.startswith(url, "git@") then
    url = url:gsub("%.git", ""):gsub(":", "/"):gsub("git@", "https://")
  end

  vim.ui.open(url)
end, { desc = "Open Current Remote" })
