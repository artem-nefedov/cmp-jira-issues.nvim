local source = {}

local cache

-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function source.new(opts)
  local self = setmetatable({}, { __index = source })

  if opts.get_trigger_characters ~= false then
    source.get_trigger_characters = opts.get_trigger_characters or function(_)
      return { '[' }
    end
  end

  if opts.enabled ~= false then
    source.enabled = opts.enabled or function(_)
      return vim.bo.filetype == 'gitcommit' or
          (vim.bo.filetype == 'markdown' and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'CHANGELOG.md')
    end
  end

  local clear_cache = opts.clear_cache ~= nil and opts.clear_cache or function()
    cache = nil
  end

  if opts.complete_opts == nil then
    opts.complete_opts = {}
  end

  opts.complete_opts.curl_config = vim.fn.expand(opts.complete_opts.curl_config or '~/.jira-curl-config')

  if opts.complete_opts.get_cache == nil then
    opts.complete_opts.get_cache = function(_, _)
      return cache
    end
  end

  if opts.complete_opts.set_cache == nil then
    opts.complete_opts.set_cache = function(_, _, items)
      cache = items
    end
  end

  if opts.complete_opts.fields == nil then
    opts.complete_opts.fields = 'summary,description'
  end

  if opts.complete_opts.items == nil then
    opts.complete_opts.items = {
      { '[%s] ',   { { 'key' } } },
      { '[%s] %s', { { 'key' }, { 'fields', 'summary' } } },
    }
  end

  source.get_completions = require('cmp-jira-issues.complete').get_complete_fn(opts.complete_opts)

  if clear_cache ~= false then
    vim.api.nvim_create_user_command('JiraClearCache', clear_cache, { desc = 'Clear cache for Jira issue completion' })
  end

  self.opts = opts
  return self
end

return source
