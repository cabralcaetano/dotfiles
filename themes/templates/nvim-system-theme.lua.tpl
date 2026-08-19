-- Gerado por theme-set.sh — NÃO editar à mão, sobrescrito a cada troca de tema.
local M = {}

function M.apply()
  vim.o.termguicolors = true
  local groups = {
    Normal = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NormalNC = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NormalFloat = { fg = "{{ term_foreground }}", bg = "{{ surface }}" },
    FloatBorder = { fg = "{{ accent }}", bg = "{{ surface }}" },
    Cursor = { fg = "{{ background }}", bg = "{{ term_cursor }}" },
    Visual = { bg = "{{ term_selection_background }}" },
    Search = { fg = "{{ background }}", bg = "{{ accent }}" },
    IncSearch = { fg = "{{ background }}", bg = "{{ color11 }}" },
    LineNr = { fg = "{{ color8 }}", bg = "{{ background }}" },
    CursorLineNr = { fg = "{{ accent }}", bg = "{{ surface }}", bold = true },
    CursorLine = { bg = "{{ surface }}" },
    SignColumn = { fg = "{{ foreground }}", bg = "{{ background }}" },
    FoldColumn = { fg = "{{ color8 }}", bg = "{{ background }}" },
    EndOfBuffer = { fg = "{{ background }}", bg = "{{ background }}" },
    StatusLine = { fg = "{{ foreground }}", bg = "{{ surface }}" },
    StatusLineNC = { fg = "{{ color8 }}", bg = "{{ surface }}" },
    VertSplit = { fg = "{{ surface_hover }}", bg = "{{ background }}" },
    WinSeparator = { fg = "{{ surface_hover }}", bg = "{{ background }}" },
    Pmenu = { fg = "{{ foreground }}", bg = "{{ surface }}" },
    PmenuSel = { fg = "{{ background }}", bg = "{{ accent }}" },
    Directory = { fg = "{{ color12 }}" },
    Comment = { fg = "{{ color8 }}", italic = true },
    String = { fg = "{{ color10 }}" },
    Function = { fg = "{{ color12 }}" },
    Identifier = { fg = "{{ color6 }}" },
    Statement = { fg = "{{ color13 }}" },
    Keyword = { fg = "{{ color13 }}", italic = true },
    Type = { fg = "{{ color11 }}" },
    Constant = { fg = "{{ color9 }}" },
    Error = { fg = "{{ error }}" },
    DiagnosticError = { fg = "{{ error }}" },
    DiagnosticWarn = { fg = "{{ color11 }}" },
    DiagnosticInfo = { fg = "{{ color12 }}" },
    DiagnosticHint = { fg = "{{ color6 }}" },

    NeoTreeNormal = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NeoTreeNormalNC = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NeoTreeWinSeparator = { fg = "{{ surface_hover }}", bg = "{{ background }}" },
    NeoTreeEndOfBuffer = { fg = "{{ background }}", bg = "{{ background }}" },
    NeoTreeCursorLine = { bg = "{{ surface }}" },
    NeoTreeDirectoryName = { fg = "{{ color12 }}" },
    NeoTreeDirectoryIcon = { fg = "{{ color12 }}" },
    NeoTreeFileName = { fg = "{{ term_foreground }}" },
    NeoTreeFileIcon = { fg = "{{ color7 }}" },
    NeoTreeRootName = { fg = "{{ accent }}", bold = true },

    NvimTreeNormal = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NvimTreeNormalNC = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    NvimTreeEndOfBuffer = { fg = "{{ background }}", bg = "{{ background }}" },
    NvimTreeWinSeparator = { fg = "{{ surface_hover }}", bg = "{{ background }}" },
    NvimTreeCursorLine = { bg = "{{ surface }}" },

    SnacksNormal = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksNormalNC = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksWin = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksWinBar = { fg = "{{ accent }}", bg = "{{ background }}" },
    SnacksPicker = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksPickerInput = { fg = "{{ term_foreground }}", bg = "{{ surface }}" },
    SnacksPickerList = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksPickerPreview = { fg = "{{ term_foreground }}", bg = "{{ background }}" },
    SnacksPickerBorder = { fg = "{{ surface_hover }}", bg = "{{ background }}" },
    SnacksPickerTree = { fg = "{{ color8 }}", bg = "{{ background }}" },
  }
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
