-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Bufferline tabs: Alt+1..9 jumps to the visible buffer tab number.
-- Works with the top tab bar shown by bufferline.nvim, not with splits/windows.
for i = 1, 9 do
  vim.keymap.set({ "n", "i" }, "<A-" .. i .. ">", "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>", {
    desc = "Go to bufferline tab " .. i,
  })

  vim.keymap.set("t", "<A-" .. i .. ">", "<C-\\><C-n><Cmd>BufferLineGoToBuffer " .. i .. "<CR>", {
    desc = "Go to bufferline tab " .. i,
  })
end

-- Split/window focus: Alt+h/j/k/l or Alt+arrows moves between Neovim splits.
local split_directions = {
  h = "h",
  j = "j",
  k = "k",
  l = "l",
  Left = "h",
  Down = "j",
  Up = "k",
  Right = "l",
}

for key, direction in pairs(split_directions) do
  vim.keymap.set({ "n", "i" }, "<A-" .. key .. ">", "<Cmd>wincmd " .. direction .. "<CR>", {
    desc = "Focus split " .. direction,
  })

  vim.keymap.set("t", "<A-" .. key .. ">", "<C-\\><C-n><Cmd>wincmd " .. direction .. "<CR>", {
    desc = "Focus split " .. direction,
  })
end
