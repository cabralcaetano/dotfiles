-- Gerado por theme-set.sh — NÃO editar à mão, sobrescrito a cada troca de tema.
local M = {}

function M.apply()
  vim.o.termguicolors = true
  local groups = {
    Normal = { fg = "#deddda", bg = "#0f0f10" },
    NormalNC = { fg = "#deddda", bg = "#0f0f10" },
    NormalFloat = { fg = "#deddda", bg = "#18181b" },
    FloatBorder = { fg = "#8a8a8d", bg = "#18181b" },
    Cursor = { fg = "#0f0f10", bg = "#deddda" },
    Visual = { bg = "#303030" },
    Search = { fg = "#0f0f10", bg = "#8a8a8d" },
    IncSearch = { fg = "#0f0f10", bg = "#ffa348" },
    LineNr = { fg = "#9a9996", bg = "#0f0f10" },
    CursorLineNr = { fg = "#8a8a8d", bg = "#18181b", bold = true },
    CursorLine = { bg = "#18181b" },
    SignColumn = { fg = "#f0f0f0", bg = "#0f0f10" },
    FoldColumn = { fg = "#9a9996", bg = "#0f0f10" },
    EndOfBuffer = { fg = "#0f0f10", bg = "#0f0f10" },
    StatusLine = { fg = "#f0f0f0", bg = "#18181b" },
    StatusLineNC = { fg = "#9a9996", bg = "#18181b" },
    VertSplit = { fg = "#252529", bg = "#0f0f10" },
    WinSeparator = { fg = "#252529", bg = "#0f0f10" },
    Pmenu = { fg = "#f0f0f0", bg = "#18181b" },
    PmenuSel = { fg = "#0f0f10", bg = "#8a8a8d" },
    Directory = { fg = "#99c1f1" },
    Comment = { fg = "#9a9996", italic = true },
    String = { fg = "#8ff0a4" },
    Function = { fg = "#99c1f1" },
    Identifier = { fg = "#5bc8af" },
    Statement = { fg = "#dc8add" },
    Keyword = { fg = "#dc8add", italic = true },
    Type = { fg = "#ffa348" },
    Constant = { fg = "#f66151" },
    Error = { fg = "#9c5b5f" },
    DiagnosticError = { fg = "#9c5b5f" },
    DiagnosticWarn = { fg = "#ffa348" },
    DiagnosticInfo = { fg = "#99c1f1" },
    DiagnosticHint = { fg = "#5bc8af" },

    NeoTreeNormal = { fg = "#deddda", bg = "#0f0f10" },
    NeoTreeNormalNC = { fg = "#deddda", bg = "#0f0f10" },
    NeoTreeWinSeparator = { fg = "#252529", bg = "#0f0f10" },
    NeoTreeEndOfBuffer = { fg = "#0f0f10", bg = "#0f0f10" },
    NeoTreeCursorLine = { bg = "#18181b" },
    NeoTreeDirectoryName = { fg = "#99c1f1" },
    NeoTreeDirectoryIcon = { fg = "#99c1f1" },
    NeoTreeFileName = { fg = "#deddda" },
    NeoTreeFileIcon = { fg = "#deddda" },
    NeoTreeRootName = { fg = "#8a8a8d", bold = true },

    NvimTreeNormal = { fg = "#deddda", bg = "#0f0f10" },
    NvimTreeNormalNC = { fg = "#deddda", bg = "#0f0f10" },
    NvimTreeEndOfBuffer = { fg = "#0f0f10", bg = "#0f0f10" },
    NvimTreeWinSeparator = { fg = "#252529", bg = "#0f0f10" },
    NvimTreeCursorLine = { bg = "#18181b" },

    SnacksNormal = { fg = "#deddda", bg = "#0f0f10" },
    SnacksNormalNC = { fg = "#deddda", bg = "#0f0f10" },
    SnacksWin = { fg = "#deddda", bg = "#0f0f10" },
    SnacksWinBar = { fg = "#8a8a8d", bg = "#0f0f10" },
    SnacksPicker = { fg = "#deddda", bg = "#0f0f10" },
    SnacksPickerInput = { fg = "#deddda", bg = "#18181b" },
    SnacksPickerList = { fg = "#deddda", bg = "#0f0f10" },
    SnacksPickerPreview = { fg = "#deddda", bg = "#0f0f10" },
    SnacksPickerBorder = { fg = "#252529", bg = "#0f0f10" },
    SnacksPickerTree = { fg = "#9a9996", bg = "#0f0f10" },
  }
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
