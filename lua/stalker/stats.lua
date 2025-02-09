local M = {}

local config = require('stalker.config').config
local realtime = require 'stalker.realtime'

M.stats_shape = {
  mode_switches = {},
  current_mode = 'n',
  motions = {
    nav = {},
    word = {},
    find = {},
    scroll = {},
    search = {},
    paragraph = {},
    line = {},
    indent = {},
    jumps = {},
  },
}

local stats = vim.tbl_deep_extend('force', {
  session_start = os.time(),
}, M.stats_shape)

-- TODO: track more motions
local motion_groups = {
  nav = { 'h', 'j', 'k', 'l' },
  word = { 'w', 'b', 'e', 'ge' },
  scroll = { '<C-d>', '<C-u>', '<C-f>', '<C-b>' },
  find = { 'f', 'F', 't', 'T' },
  search = { '*', '#', 'n', 'N' },
  paragraph = { '{', '}' },
  line = { '0', '$', '^', 'g_' },
  indent = { '>', '<', '=', '>>', '<<' },
  jumps = { 'gi', 'gv', '<C-o>', '<C-i>', 'g;', 'g,' },
}

local function track_mode_change()
  local new_mode = vim.api.nvim_get_mode().mode

  -- increment the raw mode count
  -- TODO: maybe remove this?
  stats.mode_switches[new_mode] = (stats.mode_switches[new_mode] or 0) + 1

  -- create the transition and increment that
  if new_mode ~= stats.current_mode then
    local transition = stats.current_mode .. '_to_' .. new_mode
    realtime.queue_event(transition)
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
    realtime.queue_event(key) -- TODO: Do this cleaner
    track_motion(motion_type, key)
    return existing
  end, { expr = true })
end

local function setup_motion_tracking()
  for group, motions in pairs(motion_groups) do
    for _, motion in ipairs(motions) do
      track_and_preserve(group, motion)
    end
  end
end

function M.start()
  local group = vim.api.nvim_create_augroup('Stalker', { clear = true })

  if config.tracking.motions then
    setup_motion_tracking()
  end

  if config.tracking.modes then
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = group,
      pattern = '*',
      callback = track_mode_change,
    })
  end
end

function M.get_stats()
  return stats
end

return M
