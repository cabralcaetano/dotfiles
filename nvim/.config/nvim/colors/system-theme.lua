vim.g.colors_name = "system-theme"
vim.o.termguicolors = true

package.loaded["config.system_theme_generated"] = nil
local ok, theme = pcall(require, "config.system_theme_generated")
if ok and type(theme.apply) == "function" then
  theme.apply()
end
