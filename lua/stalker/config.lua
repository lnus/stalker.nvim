local M = {}

M.config = {
  enabled = true, -- Debug option
  spam_me = false, -- Dev mode for notify stuff
  web_hook = nil, -- Optional webhook endpoint
  sync_interval = 10, -- Backup flush timer in seconds
  config_value = '', -- Just some testing stuff
  tracking = {
    motions = true,
    modes = true,
  },
}

-- inspo from https://github.com/m4xshen/hardtime.nvim/tree/main
function M.set_defaults(deps)
  for option, value in pairs(deps) do
    if type(value) == 'table' then
      if type(M.config[option]) ~= 'table' then
        M.config[option] = {}
      end
      for k, v in pairs(value) do
        M.config[option][k] = v
      end
    else
      M.config[option] = value
    end
  end
end

return M
