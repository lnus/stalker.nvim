local M = {}

M.config = {
  verbose = false, -- Enable debug logging
  sync_endpoint = nil, -- Optional sync endpoint (send data here)
  store_locally = true, -- Should save stats to file
  sync_interval = 30, -- How often to save to file/send to endpoint
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
