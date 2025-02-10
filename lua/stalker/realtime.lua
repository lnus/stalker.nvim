local M = {}

local util = require 'stalker.util'
local config = require('stalker.config').config

M.websocat_pid = nil

---@class Event
M.Event = {
  Motion = 0x01,
  ModeChange = 0x02,
}

local EventValues = {}
for _, v in pairs(M.Event) do
  EventValues[v] = true
end

--- Start the websocket connection using websocat.
function M.start_sync()
  if M.websocat_pid then
    util.warn 'Tried opening channel when already exists'
    return
  end

  local cmd = {
    'websocat',
    '-b',
    config.realtime.ws_endpoint,
  }

  -- TODO: Better error handling
  M.websocat_pid = vim.fn.jobstart(cmd, {
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
      M.websocat_pid = nil
    end,
  })
end

--- Stop the websocket connection.
function M.stop_sync()
  if not M.websocat_pid then
    util.warn 'Tried stopping non-existant channel'
    return
  end

  vim.fn.jobstop(M.websocat_pid)
end

--- Encodes an event into the expected message format.
--- @param opcode number
--- @param payload string
--- @return string
local function encode_event(opcode, payload)
  return string.char(opcode) .. string.char(#payload) .. payload
end

--- Sends an event over the websocket.
--- @param event number (must be one of M.Event values)
--- @param data string
function M.send_event(event, data)
  if not M.websocat_pid then
    util.warn 'Tried sending event without active channel'
    return
  end

  if not EventValues[event] then
    util.error('Invalid event type: ' .. event)
    return
  end

  local message = encode_event(event, data)
  vim.fn.chansend(M.websocat_pid, message)
end

return M
