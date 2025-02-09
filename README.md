<p align='center'>
    <img src='https://c.tenor.com/3MEoufxx7vIAAAAC/tenor.gif' width='200px'/>
</p>

<h1 align='center'>
    stalker.nvim
</h1>

<p align='center'>
    Statistics for NeoVim usage
</p>

<p align='center'>
    <a href="https://github.com/neovim/neovim/releases/v0.9.0">
        <img src="https://img.shields.io/badge/Neovim-0.9.0-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=white"/>
    </a>
    <a href="https://github.com/lnus/stalker.nvim/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/lnus/stalker.nvim?style=flat-square"/>
    </a>
</p>

<p align='center'>
    <strong>
        ⚠️ This is very much a work in progress ⚠️ 
    </strong>
</p>
<p align='center'>
    <strong>
        ⚠️ Breaking changes WILL be pushed to main ⚠️ 
    </strong>
</p>

<!-- TODO: Add usage gif or something -->

## Features

- Live tracking for mode switching
- Live tracking for (some) motions
- Store usage statistics to disk
- Send periodic sync data to a web endpoint
- Send realtime data to a web endpoint

### Tracked data

<!-- TODO: Clean up -->

```
nav = { 'h', 'j', 'k', 'l' },
word = { 'w', 'b', 'e', 'ge' },
scroll = { '<C-d>', '<C-u>', '<C-f>', '<C-b>' },
find = { 'f', 'F', 't', 'T' },
search = { '*', '#', 'n', 'N' },
paragraph = { '{', '}' },
line = { '0', '$', '^', 'g_' },
indent = { '>', '<', '=', '>>', '<<' },
jumps = { 'gi', 'gv', '<C-o>', '<C-i>', 'g;', 'g,' },
```

## Usage

Session tracking should start as soon as NeoVim starts,
along with local storage syncing as well as the
web sync endpoint.

Available commands:

- `:Stalker` - Show current session statistics
- `:StalkerTotals` - Show total statistics
- `:StalkerResetSync` - Reset web sync state after failures
- `:StalkerResetRlSync` - Reset live sync state after failure

### Troubleshooting

- If web sync fails, use `:StalkerResetSync` to reset the sync state
- If live sync fails, use `:StalkerResetRlSync` to reset the sync state
- Check `:messages` for debug output when `verbose = true`

## TODO: Requirements

- NeoVim >= v0.9.0 (I need to double check this)
- cURL, I guess. For some things.

## Installation

### lazy.nvim

```lua
{
    'lnus/stalker.nvim',
    opts = {} -- config goes here
},
```

Alternatively

```lua
{
    'lnus/stalker.nvim',
    config = function()
        require('stalker').setup {} -- config goes here
    end,
},
```

## Configuration

These options can all be passed through `opts` if using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require('stalker').setup{
    -- These are the default config values
    verbose = false, -- Enable debug logging

    -- Storage (Will probably be moved into sub-table)
    store_locally = true, -- Should save stats to file
    sync_interval = 30, -- Interval for saving to file/send to endpoint
    sync_endpoint = nil, -- Optional web sync endpoint

    -- Enable or disable specific tracking options
    tracking = {
        motions = true,
        modes = true,
    },

    -- Realtime
    realtime = {
        enabled = false, -- What it says on the tin
        sync_endpoint = nil, -- Realtime sync endpoint
        sync_delay = 200, -- How often to flush&&send buffer in ms
        max_buffer_size = 10, -- Force flush&&send buffer if this big
    },
}
```

## Data

### Local storage

Local data will be stored within `vim.fn.stdpath 'data'`
in the `stalker` directory.

Session stats and the total of all session stats will be
stored in the `json` format.

### Realtime web endpoint

To set up realtime data syncing, structure config like this:

```lua
require('stalker').setup {
    realtime = {
        enabled = true,
        sync_endpoint = 'http://localhost:8000/live',
        headers = {
            Authorization = 'Secret-Token',
        },
    },
}
```

#### Example consumer endpoint (FastAPI)

```python
@app.post("/live")
async def receive_live(request: Request):
    # Read the raw body data and decode to string
    raw_data = await request.body()
    data_str = raw_data.decode("utf-8", errors="replace").strip()

    # Split the events by delim (newline)
    events = data_str.split("\n") if data_str else []

    print("\n=== Stalker Update ===")
    print(f"Received {len(events)} ({len(raw_data)} bytes) event(s):")
    for event in events:
        print(f"Event: {event}")
    print("======================\n")

    return {"status": "ok"}
```

### Periodic web endpoint

> Note to self: Add config to pass additional headers, for auth etc.

To set up periodic data syncing, structure config like this:

```lua
require('stalker').setup {
    sync_endpoint = 'WEB_ENDPOINT'
}
```

#### Example consumer endpoint (FastAPI)

```python
@app.post("/stalker")
async def receive_stats(request: Request):
    data = await request.json()
    timestamp = datetime.fromtimestamp(data["timestamp"])

    print("\n=== Stalker Update ===")
    print(f"Time: {timestamp}")
    print(f"Event: {data['event_type']}")
    print("Stats:")
    print(json.dumps(data["stats"], indent=2))
    print("===================\n")

    return {"status": "ok"}
```

## TODO

- [ ] feat: Add tracking for all modes
- [ ] feat: Add config for custom tracking
- [ ] feat: Add optional command tracking
  - This could expose data, so:
    - Make it off by default
    - Track only base command?
- [ ] feat: Add event types, and send those as well
  - Change event: Mode changes (Instead of sending n_to_i)
  - Motion event: Motion keys (Currently only event)
  - BufEnter event: When entering a buffer, send filetype?
  - VimEnter/Session start event (just send on plugin init)
  - VimLeave/Session end event (I already autocmd this)
- [ ] perf: Double check the perf of event buffer
  - I feel like just posting to an endpoint over and over isn't... great.
  - If event buffer feels nice to use,
    we can use that for persitent data too, rather than a periodic timer.
    So everything registers as an event and then we match over config to
    decide if to write to file, send realtime data or big sync to endpoint.
- [ ] refactor: Update file structure of repo

## License

MIT
