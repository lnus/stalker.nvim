local M = {}

local config = require('stalker.config').config
local data_path = tostring(vim.fn.stdpath 'data')
local storage_path = vim.fs.joinpath(data_path, 'stalker')
local sessions_path = vim.fs.joinpath(storage_path, 'sessions')
local totals_path = vim.fs.joinpath(storage_path, 'totals.json')

local last_sync = os.time()
local current_session_id = string.format(
  '%s_%s_%s',
  os.date '%Y%m%d_%H%M%S',
  vim.fn.hostname(),
  vim.fn.getpid()
)

local function ensure_dirs()
  for _, path in ipairs { storage_path, sessions_path } do
    if not vim.uv.fs_stat(path) then
      vim.fn.mkdir(path, 'p')
    end
  end
end

function M.send_to_webhook(data)
  if not config.web_hook then
    return
  end

  local job_id = vim.fn.jobstart({
    'curl',
    '-X',
    'POST',
    '-H',
    'Content-Type: application/json',
    '-d',
    vim.json.encode(data),
    config.web_hook,
  }, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify(
          string.format(
            'Stalker webhook failed (code %d) for %s',
            code,
            config.web_hook
          ),
          vim.log.levels.ERROR
        )
      end
    end,
  })

  if job_id <= 0 then
    vim.notify('Stalker: Failed to start webhook job', vim.log.levels.ERROR)
  end
end

local function maybe_sync(stats, force)
  local current_time = os.time()

  local should_sync = force
    or (current_time - last_sync) >= config.sync_interval

  if should_sync then
    last_sync = current_time

    -- Save to disk
    M.save_session(stats)

    if config.web_hook then
      M.send_to_webhook {
        timestamp = current_time,
        stats = stats,
        event_type = 'periodic_sync',
      }
    end
  end
end

function M.init()
  ensure_dirs()

  -- Periodic sync timer
  vim.defer_fn(function()
    local timer = vim.uv.new_timer()
    if not timer then
      vim.notify('Stalker: Failed to create timer', vim.log.levels.ERROR)
      return
    end

    local interval = (config.sync_interval or 30) * 1000
    local success, err = pcall(function()
      -- TODO: I feel like this makes sense to run until nvim closes
      -- Since we also have a hook to log on VimLeavePre
      -- But maybe I should clean this up? Module ref timer?
      timer:start(
        interval,
        interval,
        vim.schedule_wrap(function()
          local current_stats = require('stalker.stats').get_stats()
          maybe_sync(current_stats, true)
        end)
      )
    end)

    if not success then
      vim.notify(
        'Stalker: Failed to start timer: ' .. tostring(err),
        vim.log.levels.ERROR
      )
    end
  end, 0)

  return M.load_totals()
end

function M.save_session(stats)
  local filename = vim.fs.joinpath(sessions_path, current_session_id .. '.json')

  local file = io.open(filename, 'w')
  if file then
    file:write(vim.json.encode(stats))
    file:close()
  end
end

function M.load_totals()
  if vim.uv.fs_stat(totals_path) then
    local file = io.open(totals_path, 'r')
    if file then
      local content = file:read '*all'
      file:close()
      return vim.json.decode(content)
    end
  end

  -- Return empty stats structure if no totals exist
  -- TODO: Make more dynamic? Two sources of truth for the shape rn
  -- Either that or just return none?
  return {
    mode_switches = {},
    motions = {
      basic = {},
      find = {},
      scroll = {},
      search = {},
    },
    total_sessions = 0,
    total_time = 0,
  }
end

-- TODO: Should this send to webhook as well?
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

  totals.total_sessions = totals.total_sessions + 1
  totals.total_time = totals.total_time + (os.time() - stats.session_start)

  local file = io.open(totals_path, 'w')
  if file then
    file:write(vim.json.encode(totals))
    file:close()
  end
end

return M
