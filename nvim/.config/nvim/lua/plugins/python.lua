-- lang.python extra already wires up pyright, ruff, debugpy, neotest and venv-selector.
-- This file only overrides pyright's default type-checking strictness.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoImportCompletions = true,
              },
            },
          },
        },
      },
    },
  },
}
