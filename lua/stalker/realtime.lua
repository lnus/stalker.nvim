local M = {}

local util = require 'stalker.util'
local config = require('stalker.config').config

M.event_buffer = {}
M.timer = nil

local function reset_timer()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
end

local function flush_events()
  if #M.event_buffer == 0 then
    return
  end

  local payload = ''
  -- TODO: Better delimiting scheme I think
  for _, ev in ipairs(M.event_buffer) do
    payload = payload .. ev .. '\n'
  end

  M.event_buffer = {}
  reset_timer()

  local cmd = {
    'curl',
    '-X',
    'POST',
    '-H',
    'Content-Type: application/octet-stream',
    '--data-binary',
    payload,
    config.realtime.sync_endpoint,
  }

  if config.realtime.headers then
    for key, value in pairs(config.realtime.headers) do
      table.insert(cmd, '-H')
      table.insert(cmd, key .. ': ' .. value)
    end
  end

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        util.error('Realtime sync failed with code ' .. code .. ' disabling.')
        config.realtime.enabled = false
      end
    end,
  })
end

local function schedule_flush()
  reset_timer()
  M.timer = vim.uv.new_timer()
  M.timer:start(
    config.realtime.sync_delay,
    0,
    vim.schedule_wrap(function()
      flush_events()
    end)
  )
end

function M.queue_event(event)
  if not (config.realtime.sync_endpoint and config.realtime.enabled) then
    return
  end

  table.insert(M.event_buffer, event)

  if #M.event_buffer >= config.realtime.max_buffer_size then
    flush_events()
    return
  end

  schedule_flush()
end

return M
