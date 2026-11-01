local M = {}

local PICK_CHARS = 'asdfghjkl'

local function is_picker_window(win)
  local picker_state = require('fff.picker_ui.picker_ui_state').state
  if not picker_state.active then return false end
  local picker_wins = {
    picker_state.input_win,
    picker_state.list_win,
    picker_state.preview_win,
    picker_state.file_info_win,
  }
  for _, pw in ipairs(picker_wins) do
    if pw == win then return true end
  end
  return false
end

--- Show a window picker overlay and return the selected window id.
--- Returns nil if the user cancels ( presses a non-matching key ).
--- @param main_win? number The window that was focused before the picker opened
--- @return number|nil winid
function M.pick_win(main_win)
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_picker_window(win) and vim.api.nvim_win_get_config(win).relative == '' then wins[#wins + 1] = win end
  end

  if #wins == 0 then return nil end
  if #wins == 1 then return wins[1] end

  local overlays = {}
  local chars = PICK_CHARS

  for _, win in ipairs(wins) do
    local c = chars:sub(1, 1)
    chars = chars:sub(2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '   ', ' ' .. c .. ' ', '   ' })

    local overlay = vim.api.nvim_open_win(buf, false, {
      relative = 'win',
      win = win,
      width = 3,
      height = 3,
      row = math.floor((vim.api.nvim_win_get_height(win) - 3) / 2),
      col = math.floor((vim.api.nvim_win_get_width(win) - 3) / 2),
      style = 'minimal',
      border = 'rounded',
      focusable = false,
      noautocmd = true,
      zindex = 1000,
    })

    local hl = (win == main_win) and 'FFFWinPickerCurrent' or 'FFFWinPicker'
    vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:' .. hl .. ',FloatBorder:' .. hl, { win = overlay })

    overlays[c] = { win = win, buf = buf, overlay = overlay }
  end

  vim.cmd('redraw!')

  local char = vim.fn.getcharstr()

  for _, o in pairs(overlays) do
    if vim.api.nvim_win_is_valid(o.overlay) then vim.api.nvim_win_close(o.overlay, true) end
    if vim.api.nvim_buf_is_valid(o.buf) then vim.api.nvim_buf_delete(o.buf, { force = true }) end
  end

  if char == '\13' then return main_win end -- <CR> picks the main window
  if overlays[char] then return overlays[char].win end

  return nil
end

return M
