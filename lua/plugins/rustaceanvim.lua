return {
  "mrcjkb/rustaceanvim",
  lazy = false,
  init = function()
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            assist = {
              importEnforceGranularity = true,
              importPrefix = "crate",
            },
            cargo = {
              allFeatures = true,
            },
            inlayHints = {
              locationLinks = false,
            },
            diagnostics = {
              enable = true,
              experimental = {
                enable = true,
              },
            },
          },
        },
      },
    }
  end,
}
