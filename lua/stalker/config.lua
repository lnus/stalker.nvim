local M = {}

M.config = {
  enabled = true, -- Debug option
  spam_me = false, -- Dev mode for notify stuff
  web_hook = nil, -- Optional webhook endpoint
  buffer_size = 50, -- How many events before flushing
  sync_interval = 30, -- Backup flush timer in seconds
  config_value = '', -- Just some testing stuff
  tracking = {
    motions = true,
    modes = true,
    commands = true,
  },
}

-- https://github.com/m4xshen/hardtime.nvim/tree/main
function M.set_defaults(deps)
  for option, value in pairs(deps) do
    if type(value) == 'table' and #value == 0 then
      for k, v in pairs(value) do
        if next(v) == nil then
          M.config[option][k] = nil
        else
          M.config[option][k] = v
        end
      end
    else
      M.config[option] = value
    end
  end
end

return M
