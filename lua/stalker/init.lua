local M = {}

local ui = require 'stalker.ui'
local util = require 'stalker.util'
local stats = require 'stalker.stats'
local storage = require 'stalker.storage'
local config = require('stalker.config').config

local totals = nil

local function setup_commands()
  vim.api.nvim_create_user_command('Stalker', function()
    ui.show_session_stats(stats.get_stats())
  end, { desc = 'Show stalker.nvim statistics' })

  vim.api.nvim_create_user_command('StalkerTotals', function()
    ui.show_total_stats(totals)
  end, { desc = 'Show stalker.nvim total stats' })

  vim.api.nvim_create_user_command('StalkerResetSync', function()
    storage.reset_sync_state(true)
  end, { desc = 'Reset stalker sync state after failures' })
end

local function setup_autocmds()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local current_stats = stats.get_stats()

      if config.store_locally then
        storage.save_session(current_stats)
        storage.update_totals(current_stats, totals)
      end

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
        util.debug_log "i'm watching you... (⊙_⊙)"
      end, 200)
    end,
  })
end

function M.setup(opts)
  require('stalker.config').set_defaults(opts or {})

  if not config.enabled then
    return
  end

  totals = storage.init()
  stats.start()
  setup_commands()
  setup_autocmds()
end

return M
