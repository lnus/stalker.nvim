local M = {}

local config = require('stalker.config').config

local stats = {
  session_start = os.time(),
  mode_switches = {},
  current_mode = 'n', -- default to normal mode

  motions = {
    basic = {}, -- w,b,e,ge
    find = {}, -- f,F,t,T
    scroll = {}, -- ctrl-d, ctrl-u, etc
    search = {}, -- n,N,*,#
  },
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

-- helper to track usage for key
local function track_motion(motion_type, key)
  stats.motions[motion_type][key] = (stats.motions[motion_type][key] or 0) + 1
end

-- preserve config when injecting stalker keybinds
local function get_existing_mapping(lhs, mode)
  local map = vim.fn.maparg(lhs, mode, false, true)
  if map and map.rhs then
    return map.rhs
  end
  return lhs
end

-- set up tracking and preserve current mapping
local function track_and_preserve(motion_type, key, mode)
  mode = mode or 'n' -- default to normal mode
  local existing = get_existing_mapping(key, mode)

  vim.keymap.set(mode, key, function()
    if config.spam_me then
      vim.notify(config.config_value)
    end

    track_motion(motion_type, key)
    return existing
  end, { expr = true })
end

local function setup_motion_tracking()
  -- Basic word motions
  for _, motion in ipairs { 'w', 'b', 'e', 'ge' } do
    track_and_preserve('basic', motion)
  end

  -- Scrolling
  for _, motion in ipairs { '<C-d>', '<C-u>', '<C-f>', '<C-b>' } do
    track_and_preserve('scroll', motion)
  end

  -- Find/till
  for _, motion in ipairs { 'f', 'F', 't', 'T' } do
    track_and_preserve('find', motion)
  end

  -- Search
  for _, motion in ipairs { '*', '#', 'n', 'N' } do
    track_and_preserve('search', motion)
  end

  -- TODO: track more motions
  -- Paragraph
  -- Line
  -- Window movement
  -- Marks
  -- Tags
  -- Jumps
end

-- TODO: Remove this
-- It's just debug config stuff for now
function M.test_config()
  -- Access the config directly through the local reference
  vim.notify(
    string.format('spam_me is: %s\nconfig_value is: %s', tostring(config.spam_me), tostring(config.config_value)),
    vim.log.levels.INFO
  )
end

function M.start()
  local group = vim.api.nvim_create_augroup('Stalker', { clear = true })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = '*',
    callback = track_mode_change,
  })

  vim.api.nvim_create_user_command('StalkerTestConfig', function()
    M.test_config()
  end, { desc = 'Test stalker config persistence' })

  setup_motion_tracking()
end

function M.get_stats()
  return stats
end

return M
