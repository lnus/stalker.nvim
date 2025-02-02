local M = {}

-- Default config (TODO: expand)
M.config = { enabled = true }

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  if M.config.enabled then
    require('stalker.stats').start()

    -- Create user command
    vim.api.nvim_create_user_command('Stalker', function()
      M.show_stats()
    end, { desc = 'Show stalker.nvim statistics' })

    vim.defer_fn(function()
      vim.notify('stalker.nvim is watching you... (⊙_⊙)', vim.log.levels.INFO)
    end, 100) -- ensure ui is ready
  end
end

function M.show_stats()
  local stats = require('stalker.stats').get_stats()

  local lines = {
    'stalker.nvim session stats',
    '--------------------------',
  }

  local stats_lines = vim.split(vim.inspect(stats), '\n', { plain = true })
  vim.list_extend(lines, stats_lines)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 60
  local height = #lines
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    border = 'rounded',
  })

  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf })
  vim.keymap.set('n', '<esc>', '<cmd>close<CR>', { buffer = buf })
end

return M
