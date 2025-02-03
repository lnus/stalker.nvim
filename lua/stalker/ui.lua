local M = {}

local function create_stats_window(title, content)
  local lines = {
    'Stalker ' .. title,
    string.rep('-', #title + 8),
  }

  local stats_lines = vim.split(vim.inspect(content), '\n', { plain = true })
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

function M.show_session_stats(stats)
  create_stats_window('session stats', stats)
end

function M.show_total_stats(totals)
  if totals then
    create_stats_window('total stats', totals)
  end
end

return M
