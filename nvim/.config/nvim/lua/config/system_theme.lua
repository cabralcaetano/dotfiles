local M = {}

function M.apply()
  local ok, theme = pcall(require, "config.system_theme_generated")
  if ok and type(theme.apply) == "function" then
    theme.apply()
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  group = vim.api.nvim_create_augroup("SystemTheme", { clear = true }),
  callback = function()
    vim.schedule(M.apply)
  end,
})

M.apply()

return M
