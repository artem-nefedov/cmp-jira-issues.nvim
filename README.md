# cmp-jira-issues

Extend nvim-cmp to auto-complete Jira issue keys.

Based on [cmp_gh_source](https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/after/plugin/cmp_gh_source.lua)
example by TJ DeVries.

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
- any other options required to authenticate to your Jira server (`header`, `cookie`, `user`, etc.)

The file will be passed to curl's `--config` option as-is.

### Example curl config contents

This example shows how to get open issues assigned to you for completion:

```
url = "https://your-jira-server/rest/api/2/search"
data-urlencode = "jql=assignee = \"your-acc-name\" and resolution = unresolved"
user = "username:password"
# instead of "user", you can use any other option that can control authentication
# e.g. header = "Authorization: Bearer <your-personal-access-token>"
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
  clear_cache = function() -- set to boolean false value to disable user command creation
    vim.g.cached_jira_issues = nil
  end,
  complete_opts = {
    curl_config = '~/.jira-curl-config', -- value is passed to `:h expand()`
    fields = 'summary,description', -- what fields to fetch from jira api
    items = { -- what fields to lookup in response and how to format them
      { '[%s] ',   { { 'key' } } }, -- key only
      { '[%s] %s', { { 'key' }, { 'fields', 'summary' } } }, -- key + summary
    },
    get_cache = function(_, _)
      return vim.g.cached_jira_issues
    end,
    set_cache = function(_, _, items)
      vim.g.cached_jira_issues = items
    end,
  },
})
```

## Customizing returned values

You can change `complete_opts.items` to change what values will be returned,
e.g. this value will make it so only return lines with both issue keys and summary are returned:

```lua
items = {
  { '[%s] %s', { { 'key' }, { 'fields', 'summary' } } },
}
```

Number of `%s` in LHS must match total number of defined elements in RHS.

Note that RHS is a list which itself contains other lists of values that correspond
to structure of returned "issue" JSON object, with arbitrary depth,
e.g. `{ 'fields', 'summary' }` means get value from `issue.fields.summary`.

## Caching

By default, response from server is cached globally for the entire session duration,
and `JiraClearCache` user command is provided to clear cached results.

You can change the behavior by implementing your own caching mechanics using
`complete_opts.get_cache`, `complete_opt.set_cache`, and `clear_cache` callbacks.

- `complete_opts.get_cache` receives 2 arguments: `self` table and `bufnr` integer
- `complete_opt.set_cache` receives 3 arguments: `self` table, `bufnr` integer, and `items` table
- `clear_cache` doesn't receive anything and gets called by `JiraClearCache` command

To implement buffer local cache, use the following definitions
(note that it makes `clear_cache` useless - set it to `false` to disable user command creation):

```lua
get_cache = function(self, bufnr)
  return self.cache[bufnr]
end

set_cache = function(self, bufnr, items)
  self.cache[bufnr] = items
end
```

To disable cache completely, pass `complete_opts.get_cache` function that always returns `nil`.

## Troubleshooting

If curl doesn't return correct results, debug it by running it in local shell
with the same arguments as seen in [complete.lua](lua/cmp-jira-issues/complete.lua).
