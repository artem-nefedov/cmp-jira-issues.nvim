# cmp-jira-issues

Auto-complete Jira issue keys based on arbitrary query.

## Prerequisites

- Using NeoVim (tested with 0.9.0 on unix-like environment)
- Access to Jira-Server REST API (not tested with Jira-Cloud)
- [curl](https://curl.se/) is installed and is available in `$PATH`
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) are installed
  (both must be loaded before `setup` is called)

## Installation

Use plugin manager of your choice.
Minimal installation example for [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require('lazy').setup({
  {
    'artem-nefedov/cmp-jira-issues.nvim',
    dependencies = { -- this is not required if you already install those plugins
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
  },
})
```
## Curl config

You must have a curl config file (default: `~/.jira-curl-config`), which must
contain at least the following options:

- `url` - value must point to your Jira server's `/rest/api/2/search` endpoint
- `data-urlencode` - value must have `jql=<your issue search query>`
- any other options required to authenticate to your Jira server (`cookie`, `user`, etc.)

The file will be passed to curl's `--config` option as-is.

### Example curl config contents

This example shows how to get issues assigned to you for completion:

```
url = "https://your-jira-server/rest/api/2/search"
data-urlencode = "jql=assignee = \"your-acc-name\" and resolution = unresolved"
user = "username:password"
# instead of "user", you can use any other option that can control authentication
```

## Setup

Make sure to call `setup` when plenary and nvim-cmp are already loaded.

### Default configuration

Create/update ".lua" file in `~/.config/nvim/after/plugin/` with contents:

```lua
require('cmp-jira-issues').setup({})
```

Don't forget to add completion source (default: `jira_issues`) to cmp `setup`, e.g.:

```lua
local cmp = require('cmp')

cmp.setup({
  -- other options
  sources = {
    { name = 'jira_issues' },
    -- other sources
  },
})
```

### Custom custom configuration

Below you can see available fields (shown with values set to match defaults):

```lua
require('cmp-jira-issues').setup({
  source_name = 'jira_issues',
  get_trigger_characters = function() -- on which characters completion is triggered
    return { '[' }
  end,
  is_available = function() -- determine whether source is available for current buffer
    return vim.bo.filetype == 'gitcommit' or
        (vim.bo.filetype == 'markdown' and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'CHANGELOG.md')
  end,
  complete_opts = {
    curl_config = '~/.jira-curl-config', -- value is passed to `:h expand()`
    item_format = '[%s] ', -- must contain exactly one %s in the string
    get_cache = function(self, bufnr)
      return self.cache[bufnr] or vim.t.cached_jira_issues
    end,
    set_cache = function(self, bufnr, items)
      self.cache[bufnr] = items
      vim.t.cached_jira_issues = items
    end,
  },
})
```

## Caching

By default, response from server is cached for both current buffer and current tab,
meaning if you open another window in the same tab, or if you open same buffer anywhere,
you will get pre-fetched issue list. There is no cache invalidation.

You can change the behavior by implementing your own caching mechanics using
`get_cache` and `set_cache` callbacks. To disable cache completely, pass
`get_cache` function that always returns `nil`.
