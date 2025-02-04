<h1 align='center'>
    stalker.nvim
</h1>

<p align='center'>
    Statistics for NeoVim usage
</p>

<!-- TODO: Add usage gif or something -->

<p align='center'>
    <a href="https://github.com/neovim/neovim/releases/v0.9.0">
        <img src="https://img.shields.io/badge/Neovim-0.9.0-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=white"/>
    </a>
    <a href="https://github.com/lnus/stalker.nvim/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/lnus/stalker.nvim?style=flat-square"/>
    </a>
</p>

## Features

- Live tracking for mode switching
- Live tracking for (some) motions
- Store usage statistics to disk
- Send real-time data to a web endpoint

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

### Troubleshooting

- If web sync fails, use `:StalkerResetSync` to reset the sync state
- Check `:messages` for debug output when `verbose = true`

## TODO: Requirements

- NeoVim >= v0.9.0 (i need to double check this)

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

## Customization

These options can all be passed through `opts` if using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
require('stalker').setup{
    -- These are the default config values
    verbose = false, -- Enable debug logging

    -- Storage
    store_locally = true, -- Should save stats to file
    sync_interval = 30, -- Interval for saving to file/send to endpoint
    sync_endpoint = nil, -- Optional web sync endpoint

    -- Enable or disable specific tracking options
    tracking = {
        motions = true,
        modes = true,
    },
}
```

## Data

### Local storage

Local data will be stored within `vim.fn.stdpath 'data'`
in the `stalker` directory.

Session stats and the total of all session stats will be
stored in the `json` format.

### Web endpoint

> Note to self: Add config to pass additional headers, for auth etc.

Data will be curled to the endpoint following.

```bash
curl
    -X POST
    -H 'Content-Type: application/json'
    -d json.encode(data)
```

#### Example endpoint (FastAPI)

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

## License

MIT
