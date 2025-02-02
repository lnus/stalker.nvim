local M = {}

local storage_path = vim.fs.normalize(vim.fn.stdpath 'data' .. '/stalker')
local sessions_path = vim.fs.joinpath(storage_path, 'sessions')
local totals_path = vim.fs.joinpath(storage_path, 'totals.json')

local function ensure_dirs()
  for _, path in ipairs { storage_path, sessions_path } do
    if vim.uv.fs_stat(path) then
      vim.fn.mkdir(path, 'p')
    end
  end
end

function M.init()
  ensure_dirs()
  return M.load_totals()
end

function M.save_session(stats)
  local session_id = os.date '%Y%m%d_%H%M%S'
  local filename = vim.fs.joinpath(sessions_path, session_id .. '.json')

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
  -- TODO: Make more dynamic?
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

function M.update_totals(stats, totals)
  for mode, count in pairs(stats.mode_switches) do
    totals.mode_switches[mode] = (totals.mode_switches[mode] or 0) + count
  end

  for category, motions in pairs(stats.motions) do
    totals.motions[category] = totals.motions[category] or {}
    for motion, count in pairs(motions) do
      totals.motions[category][motion] = (totals.motions[category][motion] or 0) + count
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
