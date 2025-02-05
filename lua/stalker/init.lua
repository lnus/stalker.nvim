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

  -- Kinda janky command, but it's just for use if live sync fails.
  vim.api.nvim_create_user_command('StalkerResetRlSync', function()
    if config.realtime.sync_endpoint then
      config.realtime.enabled = true
    end
  end, { desc = 'Reset stalker sync state after failures' })
end

-- TODO: Put into augroup as in stats.lua+86
local function setup_autocmds()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local current_stats = stats.get_stats()

      storage.sync_stats(current_stats, 'session_end')

      if config.store_locally then
        storage.update_totals(current_stats, totals)
      end
    end,
  })

  vim.api.nvim_create_autocmd('UIEnter', {
    callback = function()
      vim.defer_fn(function()
        util.debug "i'm watching you... (⊙_⊙)"
      end, 200)
    end,
  })
end

function M.setup(opts)
  require('stalker.config').set_defaults(opts or {})

  totals = storage.init()
  stats.start()
  setup_commands()
  setup_autocmds()
end

return M
