# cmp-jira-issues

Extend blink.cmp to auto-complete Jira issue keys.

## Prerequisites

- Using NeoVim (tested with 0.11.x on unix-like environment)
- Access to Jira-Server REST API (not tested with Jira-Cloud)
- [curl](https://curl.se/) is installed and is available in `$PATH`
- [blink.cmp](https://github.com/saghen/blink.cmp) is installed

## Installation

Use plugin manager of your choice.
Minimal installation example for [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
require('lazy').setup({
  {
    'saghen/blink.cmp',
    dependencies = {
      'artem-nefedov/cmp-jira-issues.nvim',
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

Below is the example how to add the source to blink.cmp.

```lua
require('blink.cmp').setup({
  sources = {
    default = { 'lsp', 'path', 'snippets', 'lazydev', 'buffer', 'jira' }, -- specify here...
    providers = {
      lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      jira = { -- and here
        name = 'Jira',
        module = 'cmp-jira-issues',
        opts = {},
        should_show_items = function(ctx) -- show results only after specific character
          return ctx.trigger.initial_character == '['
        end,
      },
    },
  },
  -- ... other fields for blink.cmp setup
})
```

### Available options

Below are all available options with their respective default values.

```lua
opts = {
  get_trigger_characters = function() -- on which characters completion is triggered
    return { '[' }
  end,
  enabled = function() -- determine whether source is available for current buffer
    return vim.bo.filetype == 'gitcommit' or
        (vim.bo.filetype == 'markdown' and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'CHANGELOG.md')
  end,
  clear_cache = function() -- set to boolean false value to disable user command creation
    cache = nil -- plugin-local var
  end,
  complete_opts = {
    curl_config = '~/.jira-curl-config', -- value is passed to `:h expand()`
    fields = 'summary,description', -- what fields to fetch from jira api
    items = { -- what fields to lookup in response and how to format them
      { '[%s] ',   { { 'key' } } }, -- key only
      { '[%s] %s', { { 'key' }, { 'fields', 'summary' } } }, -- key + summary
    },
    get_cache = function(_)
      return cache
    end,
    set_cache = function(_, items)
      cache = items
    end,
  },
}
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

- `complete_opts.get_cache` receives 1 argument: `self` table
- `complete_opt.set_cache` receives 2 arguments: `self` table and `items` table
- `clear_cache` doesn't receive anything and gets called by `JiraClearCache` command

To disable cache completely, pass `complete_opts.get_cache` function that always returns `nil`.

## Troubleshooting

If curl doesn't return correct results, debug it by running it in local shell
with the same arguments as seen in [complete.lua](lua/cmp-jira-issues/complete.lua).
