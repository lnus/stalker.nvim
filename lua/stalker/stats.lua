local M = {}

local stats = {
  session_start = os.time(),
  mode_switches = {},
  current_mode = 'n', -- default to normal mode
}

local function track_mode_change()
  local new_mode = vim.api.nvim_get_mode().mode

  -- increment the raw mode count
  stats.mode_switches[new_mode] = (stats.mode_switches[new_mode] or 0) + 1

  -- create the transition and increment that
  if new_mode ~= stats.current_mode then
    local transition = stats.current_mode .. '_to_' .. new_mode
    stats.mode_switches[transition] = (stats.mode_switches[transition] or 0) + 1
    stats.current_mode = new_mode
  end
end

function M.start()
  local group = vim.api.nvim_create_augroup('Stalker', { clear = true })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = '*',
    callback = track_mode_change,
  })
end

function M.get_stats()
  return stats
end

return M
