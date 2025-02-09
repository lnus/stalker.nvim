local M = {}

local util = require 'stalker.util'
local config = require('stalker.config').config

M.ws_chan = nil

---@class Event
M.Event = {
  ModeChange = 'mode_change',
  Motion = 'motion',
  BufEnter = 'buf_enter',
  VimEnter = 'session_start',
  VimLeave = 'session_end',
}

local EventValues = {}
for _, v in pairs(M.Event) do
  EventValues[v] = true
end

function M.start_sync()
  if M.ws_chan then
    util.warn 'Tried opening channel when already exists'
    return
  end

  local cmd = {
    'websocat',
    config.realtime.ws_endpoint,
  }

  -- TODO: Better error handling
  M.ws_chan = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data and #data > 0 then
        -- TODO: Move to util.error? Idk they're very verbose
        util.debug('websocat stderr: ' .. vim.inspect(data))
      end
    end,
    on_exit = function(_, code, signal)
      if code ~= 0 and code ~= 143 then -- 143 happens on clean exit
        util.error(
          'websocat exited with code: '
            .. code
            .. ', signal: '
            .. (signal or 'none')
        )
      end
      M.ws_chan = nil
    end,
  })
end

function M.stop_sync()
  if not M.ws_chan then
    util.warn 'Tried stopping non-existant channel'
    return
  end

  vim.fn.jobstop(M.ws_chan)
end

---@param event string
---@param data string
function M.send_data(event, data)
  if not M.ws_chan then
    return
  end

  if not EventValues[event] then
    util.error('Invalid event type: ' .. event)
    return
  end

  local message = '[' .. event .. '] ' .. data

  vim.fn.chansend(M.ws_chan, message .. '\n')
end

return M
