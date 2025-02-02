local M = {}

-- Default config (TODO: expand)
M.config = {
  enabled = true,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  vim.defer_fn(function()
    vim.notify('stalker.nvim is watching you... (⊙_⊙)', vim.log.levels.INFO)
  end, 100) -- ensure ui is ready
end

-- Command line test
function M.test_stalk()
  print '👀 I see what you did there...'
end

return M
