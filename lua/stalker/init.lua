local M = {}

local storage = require 'stalker.storage'
local stats = require 'stalker.stats'
local config = require('stalker.config').config
local totals = nil

-- TODO: Move to util file or something
function M.debug_log(message)
  if not config.spam_me then
    return
  end

  vim.notify('stalker.nvim: ' .. message, vim.log.levels.INFO)
end

function M.setup(opts)
  require('stalker.config').set_defaults(opts or {})

  if not config.enabled then
    return
  end

  totals = storage.init()

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local current_stats = stats.get_stats()

      if config.store_locally then
        storage.save_session(current_stats)
        storage.update_totals(current_stats, totals)
      end

      -- force sync push if needed
      if config.sync_endpoint then
        storage.sync_to_endpoint {
          timestamp = os.time(),
          stats = current_stats,
          event_type = 'session_end',
        }
      end
    end,
  })

  vim.api.nvim_create_autocmd('UIEnter', {
    callback = function()
      vim.defer_fn(function()
        M.debug_log "i'm watching you... (⊙_⊙)"
      end, 200)
    end,
  })

  stats.start()

  vim.api.nvim_create_user_command('Stalker', function()
    M.show_stats()
  end, { desc = 'Show stalker.nvim statistics' })

  vim.api.nvim_create_user_command('StalkerTotals', function()
    M.show_totals()
  end, { desc = 'Show stalker.nvim total stats' })

  vim.api.nvim_create_user_command('StalkerResetSync', function()
    storage.reset_sync_state(true)
  end, { desc = 'Reset stalker sync state after failures' })
end

function M.show_stats()
  local current_stats = stats.get_stats()

  local lines = {
    'stalker.nvim session stats',
    '--------------------------',
  }

  local stats_lines =
    vim.split(vim.inspect(current_stats), '\n', { plain = true })
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
      '------------------------',
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
