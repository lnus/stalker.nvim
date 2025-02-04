local M = {}

local util = require 'stalker.util'
local config = require('stalker.config').config
local data_path = tostring(vim.fn.stdpath 'data')
local storage_path = vim.fs.joinpath(data_path, 'stalker')
local sessions_path = vim.fs.joinpath(storage_path, 'sessions')
local totals_path = vim.fs.joinpath(storage_path, 'totals.json')

local MAX_RETRIES = 3
local sync_failures = 0
local halt_sync = false
local last_sync = os.time()
local current_session_id =
  string.format('%s_%s', os.date '%Y%m%d_%H%M%S', vim.fn.getpid())

local function ensure_dirs()
  for _, path in ipairs { storage_path, sessions_path } do
    if not vim.uv.fs_stat(path) then
      util.debug('Creating directory: ' .. path)

      local ok = pcall(function()
        vim.fn.mkdir(path, 'p')
      end)
      local exists = vim.uv.fs_stat(path) ~= nil

      util.debug(string.format('mkdir result: ok=%s, exists=%s', ok, exists))

      if not ok then
        util.error(string.format('Failed to create directory %s', path))
      end
    end
  end
end

function M.reset_sync_state(notify)
  if not config.sync_endpoint then
    util.warn 'No sync_endpoint set, please configure'
    return
  end

  halt_sync = false
  sync_failures = 0

  if notify then
    util.info 'Sync state reset, will attempt syncing again'
  end
end

function M.sync_to_endpoint(data)
  if not config.sync_endpoint or halt_sync then
    return
  end

  halt_sync = true -- prevent parallel attempts

  local function attempt_sync(retry_count)
    local job_id = vim.fn.jobstart({
      'curl',
      '-X',
      'POST',
      '-H',
      'Content-Type: application/json',
      '-d',
      vim.json.encode(data),
      config.sync_endpoint,
    }, {
      on_exit = function(_, code)
        if code ~= 0 then
          sync_failures = sync_failures + 1

          if sync_failures >= MAX_RETRIES then
            halt_sync = true
            util.error(
              string.format(
                'Sync failed %d times, disabling (%s)',
                MAX_RETRIES,
                config.sync_endpoint
              )
            )
            return
          end

          -- exponential backoff
          local delay = math.pow(2, retry_count) * 1000
          util.warn(
            string.format(
              'Sync attempt %d failed (%d), retrying in %dms...',
              retry_count + 1,
              code,
              delay
            )
          )

          vim.defer_fn(function()
            attempt_sync(retry_count + 1)
          end, delay)
        else
          M.reset_sync_state(false)
        end
      end,
    })

    if job_id <= 0 then
      util.error 'Failed to start sync job'
      M.reset_sync_state(false)
    end
  end

  attempt_sync(0)
end

local function sync_stats(stats, event_type)
  if config.store_locally then
    M.save_session(stats)
  end

  if config.sync_endpoint then
    M.sync_to_endpoint {
      timestamp = os.time(),
      stats = stats,
      event_type = event_type,
    }
  end
end

function M.init()
  ensure_dirs()

  -- Periodic sync timer
  vim.defer_fn(function()
    local timer = vim.uv.new_timer()
    if not timer then
      util.error 'Failed to create timer'
      return
    end

    local interval = (config.sync_interval or 30) * 1000
    local success, err = pcall(function()
      timer:start(
        interval,
        interval,
        vim.schedule_wrap(function()
          local current_stats = require('stalker.stats').get_stats()
          sync_stats(current_stats, 'periodic_sync')
        end)
      )
    end)

    if not success then
      util.error('Failed to start timer: ' .. tostring(err))
    end
  end, 0)

  return M.load_totals()
end

function M.save_session(stats)
  local filename = vim.fs.joinpath(sessions_path, current_session_id .. '.json')

  local file, err = io.open(filename, 'w')
  if not file then
    util.error(string.format('Failed to save session: %s', err))
    return
  end

  file:write(vim.json.encode(stats))
  file:close()
end

function M.load_totals()
  if vim.uv.fs_stat(totals_path) then
    util.debug('Found totals at ' .. totals_path)
    local file, err = io.open(totals_path, 'r')
    if not file then
      util.error(string.format('Failed to open totals (READ): %s', err))
      return
    end

    local content = file:read '*all'
    file:close()
    return vim.json.decode(content)
  end

  util.debug 'No totals found, returning default shape'
  return vim.deepcopy(require('stalker.stats').stats_shape)
end

function M.update_totals(stats, totals)
  for mode, count in pairs(stats.mode_switches) do
    totals.mode_switches[mode] = (totals.mode_switches[mode] or 0) + count
  end

  for category, motions in pairs(stats.motions) do
    totals.motions[category] = totals.motions[category] or {}
    for motion, count in pairs(motions) do
      totals.motions[category][motion] = (totals.motions[category][motion] or 0)
        + count
    end
  end

  totals.total_sessions = (totals.total_sessions or 0) + 1
  totals.total_time = (totals.total_time or 0)
    + (os.time() - stats.session_start)

  local file, err = io.open(totals_path, 'w')
  if not file then
    util.error(string.format('Failed to open totals (WRITE): %s', err))
    return
  end

  file:write(vim.json.encode(totals))
  file:close()
end

return M
