return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = function()
    local Rule = require "nvim-autopairs.rule"
    local cond = require "nvim-autopairs.conds"

    return {
      Rule("( ", " )", "-markdown")
        :with_pair(function()
          return false
        end)
        :with_move(function(opts)
          return opts.prev_char:match ".%)" ~= nil
        end)
        :use_key ")",
      Rule("{ ", " }", "-markdown")
        :with_pair(function()
          return false
        end)
        :with_move(function(opts)
          return opts.prev_char:match ".%}" ~= nil
        end)
        :use_key "}",
      Rule("[ ", " ]", "-markdown")
        :with_pair(function()
          return false
        end)
        :with_move(function(opts)
          return opts.prev_char:match ".%]" ~= nil
        end)
        :use_key "]",
      Rule("^%s*if.*then$", "end", "lua"):use_regex(true):end_wise(cond.is_end_line()),
      Rule("do$", "end", "lua"):use_regex(true):end_wise(cond.is_end_line()),
      Rule("function[^%(]*%([^%)]*%)$", "end", "lua"):use_regex(true):end_wise(function(opts)
        return cond.is_end_line() or string.match(opts.next_char, "%s*[%)%]%}].*")
      end),
    }
  end,
  config = function(_, opts)
    require("nvim-autopairs").setup()
    require("nvim-autopairs").add_rules(opts)
  end,
}
