---@diagnostic disable: missing-fields
---@diagnostic disable: inject-field
require("heirline").setup {
  statuscolumn = {
    condition = function()
      return vim.bo.buftype == ""
    end,
    {
      static = {
        texts = {
          { symbol = "E ", highlight = "DiagnosticSignError" },
          { symbol = "W ", highlight = "DiagnosticSignWarn" },
          { symbol = "I ", highlight = "DiagnosticSignInfo" },
          { symbol = "H ", highlight = "DiagnosticSignHint" },
        },
      },
      init = function(self)
        local signs = vim.diagnostic.get(vim.api.nvim_get_current_buf(), {
          lnum = vim.v.lnum - 1,
        })

        if #signs == 0 then
          self.sign = nil
        else
          self.sign = signs[1]
        end
      end,
      provider = function(self)
        if self.sign then
          return self.texts[self.sign.severity].symbol
        end

        return "  "
      end,
      hl = function(self)
        if self.sign then
          return self.texts[self.sign.severity].highlight
        end
      end,
    },
    {
      provider = "%=",
    },
    {
      provider = function()
        if vim.v.virtnum > 0 then
          return ""
        end

        if vim.v.relnum == 0 then
          return ("%02d"):format(vim.v.lnum)
        end

        return ("%02d"):format(vim.v.relnum)
      end,
    },
    {
      init = function(self)
        self.namespace = vim.api.nvim_get_namespaces()["gitsitngs_extmark_signs_"]
      end,
      provider = function()
        return " ▏"
      end,
      hl = function(self)
        if self.namespace then
          local extmark = vim.api.nvim_buf_get_extmark_by_id(0, self.namespace, vim.v.lnum, { details = true })

          if extmark and extmark[3] then
            return extmark[3].sign_hl_group
          end
        end

        return "@comment"
      end,
    },
  },
  statusline = {
    init = function(self)
      self.mode = vim.fn.mode()
    end,
    static = {
      modes = {
        names = {
          n = "NORMAL",
          v = "VISUAL",
          V = "VISUAL",
          ["\22"] = "VISUAL",
          s = "SELECT",
          S = "SELECT",
          ["\19"] = "SELECT",
          i = "INSERT",
          R = "REPLACE",
          c = "COMMAND",
          r = "CONFIRM",
          ["!"] = "TERMINAL",
          t = "TERMINAL",
        },
        colors = {
          NORMAL = { bg = "#E8D4B0", fg = "#28304D", bold = true },
          VISUAL = { bg = "#FBC19D", fg = "#28304D", bold = true },
          SELECT = { bg = "#FBC19D", fg = "#28304D", bold = true },
          INSERT = { bg = "#B5E8B0", fg = "#28304D", bold = true },
          REPLACE = { bg = "#28304D", fg = "#9CA3AF", bold = true },
          COMMAND = { bg = "#A5B4FC", fg = "#28304D", bold = true },
          CONFIRM = { bg = "#BF7471", fg = "#28304D", bold = true },
          TERMINAL = { bg = "#E8D4B0", fg = "#28304D", bold = true },
        },
      },
    },
    {
      provider = function(self)
        return (" %s "):format(self.modes.names[self.mode])
      end,
      hl = function(self)
        return self.modes.colors[self.modes.names[self.mode]]
      end,
      update = { "ModeChanged" },
    },
    {
      provider = " ",
    },
    {
      init = function(self)
        self.status = vim.b.git or {}
      end,
      update = {
        "User",
        pattern = "GitUpdate",
        callback = vim.schedule_wrap(function()
          vim.cmd.redrawstatus()
        end),
      },
      {
        provider = function()
          return (" %s"):format(vim.g.git_head)
        end,
        hl = function()
          return { fg = "#A5B4FC" }
        end,
      },
      {
        provider = " ",
      },
      {
        provider = function(self)
          return "+" .. (self.status.added or 0)
        end,
        hl = function()
          return "diffAdded"
        end,
      },
      {
        provider = function(self)
          return "-" .. (self.status.removed or 0)
        end,
        hl = function()
          return "diffRemoved"
        end,
      },
      {
        provider = function(self)
          return "~" .. (self.status.changed or 0)
        end,
        hl = function()
          return "diffChanged"
        end,
      },
      {
        provider = " | ",
      },
    },
    {
      init = function(self)
        for _, severity in ipairs(vim.diagnostic.severity) do
          self[string.lower(severity)] = #vim.diagnostic.get(0, { severity = severity })
        end
      end,
      update = {
        "DiagnosticChanged",
        callback = vim.schedule_wrap(function()
          vim.cmd.redrawstatus()
        end),
      },
      {
        provider = function(self)
          return "E" .. (self.error < 10 and self.error or "#")
        end,
        hl = "DiagnosticSignError",
      },
      {
        provider = function(self)
          return "W" .. (self.warn < 10 and self.warn or "#")
        end,
        hl = "DiagnosticSignWarn",
      },
      {
        provider = function(self)
          return "I" .. (self.info < 10 and self.info or "#")
        end,
        hl = "DiagnosticSignInfo",
      },
      {
        provider = function(self)
          return "H" .. (self.hint < 10 and self.hint or "#")
        end,
        hl = "DiagnosticSignHint",
      },
      {
        provider = " | ",
      },
    },
    {
      init = function(self)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") --[[@as string]]
        if vim.bo.filetype == "term" then
          local split = vim.split(filename, ":", { plain = true })
          filename = split[#split]
        end

        self.filename = filename
      end,
      provider = function(self)
        return #self.filename > 0 and self.filename or vim.bo.filetype
      end,
      update = { "BufEnter" },
    },
    {
      provider = "%=",
    },
    {
      init = function(self)
        local devicons = require "nvim-web-devicons"
        self.icon, self.highlight = devicons.get_icon_by_filetype(vim.bo.filetype)
        if self.icon == nil then
          local default = devicons.get_default_icon()

          self.icon = default.icon
          self.highlight = { fg = default.color }
        end
      end,
      {
        provider = function(self)
          return self.icon
        end,
        hl = function(self)
          return self.highlight
        end,
      },
      {
        provider = function()
          return " " .. vim.bo.filetype
        end,
        hl = { bold = false },
      },
      update = { "FileType", "BufEnter", "BufNew" },
    },
    {
      flexible = 3,
      {
        {
          provider = " | ",
        },
        {
          update = { "LspAttach", "LspDetach", "BufEnter" },
          provider = function()
            local buf_client_names = {}

            for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
              if client.name ~= "null-ls" then
                table.insert(buf_client_names, client.name .. "[" .. client.id .. "]")
              end
            end

            local sources = {}
            if pcall(require, "conform") then
              for _, source in ipairs(require("conform").list_formatters(0)) do
                table.insert(sources, source.name)
              end
            end

            local servers = vim.list_extend(buf_client_names, sources)

            return #servers > 0 and table.concat(servers, ", ") or "LS inactive"
          end,
          hl = { bold = true, fg = nil },
        },
      },
      {
        provider = "",
      },
    },
    {
      flexible = 2,
      {
        {
          provider = " | ",
        },
        {
          provider = function()
            return ("Format: %s"):format(vim.g.AutoFormat == 1 and "✓" or "✗")
          end,
          hl = function()
            return { fg = vim.g.AutoFormat == 1 and "#98BC99" or "#BF7471" }
          end,
        },
      },
      {
        provider = "",
      },
    },
    {
      provider = " ",
    },
    {
      init = function(self)
        self.cursor = vim.api.nvim_win_get_cursor(0)
      end,
      hl = function(self)
        return self.modes.colors[self.modes.names[vim.fn.mode()]]
      end,
      {
        provider = function(self)
          local line = self.cursor[1]
          local total = vim.api.nvim_buf_line_count(0)
          local percentage
          if line == 1 then
            percentage = "Top"
          elseif line == total then
            percentage = "Bot"
          else
            percentage = ("%02d%%%%"):format(math.floor((line / total) * 100))
          end
          return (" %03d:%03d | %s "):format(self.cursor[1], self.cursor[2] + 1, percentage)
        end,
      },
    },
  },
}
