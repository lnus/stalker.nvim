local M = {}

local config = require('stalker.config').config
local PLUGIN_NAME = 'Stalker'

local function notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify(msg, level, { title = PLUGIN_NAME })
end

function M.info(msg)
  notify(msg, vim.log.levels.INFO)
end

function M.error(msg)
  notify(msg, vim.log.levels.ERROR)
end

function M.warn(msg)
  notify(msg, vim.log.levels.WARN)
end

function M.debug(msg)
  if config.verbose then
    notify(msg, vim.log.levels.DEBUG)
  end
end

return M
