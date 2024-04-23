math.randomseed(os.time())

local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

local function random(length)
  local map = setmetatable({}, {
    __index = function(self, k)
      self[k] = math.random()
      return self[k]
    end,
  })

  local c = vim.split(chars, "")
  table.sort(c, function(a, b)
    return map[a] < map[b]
  end)

  return table.concat(c, ""):sub(1, length)
end

for _ = 1, 10 do
  vim.print(random(61))
end
