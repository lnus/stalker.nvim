local M = {}

local config = require('stalker.config').config

function M.debug_log(message)
  if not config.spam_me then
    return
  end
  vim.notify('Stalker: ' .. message, vim.log.levels.INFO)
end

return M
