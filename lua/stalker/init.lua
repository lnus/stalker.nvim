local M = {}

local ui = require 'stalker.ui'
local util = require 'stalker.util'
local stats = require 'stalker.stats'
local storage = require 'stalker.storage'
local config = require('stalker.config').config
local realtime = require 'stalker.realtime'

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

  -- TODO: better commands for ws
  vim.api.nvim_create_user_command('WsClose', function()
    realtime.stop_sync()
  end, { desc = 'Close the websocket channel' })

  vim.api.nvim_create_user_command('WsOpen', function()
    if realtime.ws_chan then
      util.warn 'Websocket channel already open'
      return
    end

    realtime.start_sync()
  end, { desc = 'Open the websocket channel' })
end

-- TODO: Put into augroup as in stats.lua+86
local function setup_autocmds()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local current_stats = stats.get_stats()

      realtime.stop_sync()

      storage.sync_stats(current_stats, 'session_end')

      if config.store_locally then
        storage.update_totals(current_stats, totals)
      end
    end,
  })

  vim.api.nvim_create_autocmd('UIEnter', {
    callback = function()
      vim.defer_fn(function()
        realtime.start_sync()
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
