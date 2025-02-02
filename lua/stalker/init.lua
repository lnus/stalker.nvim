local M = {}

local storage = require 'stalker.storage'
local stats = require 'stalker.stats'
local totals = nil

M.config = { enabled = true }

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})

  if M.config.enabled then
    totals = storage.init()

    -- Set up VimLeavePre to save session and update totals
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        local current_stats = stats.get_stats()
        storage.save_session(current_stats)
        storage.update_totals(current_stats, totals)
      end,
    })

    stats.start()

    vim.api.nvim_create_user_command('Stalker', function()
      M.show_stats()
    end, { desc = 'Show stalker.nvim statistics' })

    vim.api.nvim_create_user_command('StalkerTotals', function()
      M.show_totals()()
    end, { desc = 'Show stalker.nvim total stats' })

    vim.defer_fn(function()
      vim.notify('stalker.nvim is watching you... (⊙_⊙)', vim.log.levels.INFO)
    end, 100) -- ensure ui is ready
  end
end

function M.show_stats()
  local current_stats = stats.get_stats()

  local lines = {
    'stalker.nvim session stats',
    '--------------------------',
  }

  local stats_lines = vim.split(vim.inspect(current_stats), '\n', { plain = true })
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

function M.show_totals()
  if totals then
    local lines = {
      'stalker.nvim total stats',
      '----------------------',
    }

    local stats_lines = vim.split(vim.inspect(totals), '\n', { plain = true })
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
end

return M
