local install_location = vim.fs.joinpath(vim.fn.stdpath "data" --[[@as string]], "rocks")

local rocks_config = {
  rocks_path = vim.fs.normalize(install_location),
  luarocks_binary = vim.fs.joinpath(install_location, "bin", "luarocks"),
}

vim.g.rocks_nvim = rocks_config

local luarocks_path = {
  vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),
  vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
}
package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

local luarocks_cpath = {
  vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),
  vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),
}
package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

vim.opt.runtimepath:append(vim.fs.joinpath(rocks_config.rocks_path, "lib", "luarocks", "rocks-5.1", "rocks.nvim", "*"))

if not pcall(require, "rocks") then
  local rocks_location = vim.fs.joinpath(vim.fn.stdpath "cache" --[[@as string]], "rocks")

  if not vim.uv.fs_stat(rocks_location) then
    vim.fn.system {
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/nvim-neorocks/rocks.nvim",
      rocks_location,
    }
  end

  assert(vim.v.shell_error == 0, "rocks.nvim installation failed")

  vim.cmd.source(vim.fs.joinpath(rocks_location, "bootstrap.lua"))

  vim.fn.delete(rocks_location, "rf")
end
