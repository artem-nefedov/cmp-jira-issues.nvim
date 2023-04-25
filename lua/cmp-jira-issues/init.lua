local M = {}

local registered = false

M.setup = function(opts)
  local source = {}

  source.new = function()
    local self = setmetatable({ cache = {} }, { __index = source })
    return self
  end

  -- separate treatment of nil and false
  if opts.get_trigger_characters ~= false then
    source.get_trigger_characters = opts.get_trigger_characters or function()
      return { '[' }
    end
  end

  if opts.is_available ~= false then
    source.is_available = opts.is_available or function()
      return vim.bo.filetype == 'gitcommit' or
          (vim.bo.filetype == 'markdown' and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'CHANGELOG.md')
    end
  end

  local clear_cache = opts.clear_cache ~= nil and opts.clear_cache or function()
    vim.g.cached_jira_issues = nil
  end

  if opts.complete_opts == nil then
    opts.complete_opts = {}
  end

  opts.complete_opts.curl_config = vim.fn.expand(opts.complete_opts.curl_config or '~/.jira-curl-config')

  if opts.complete_opts.get_cache == nil then
    opts.complete_opts.get_cache = function(_, _)
      return vim.g.cached_jira_issues
    end
  end

  if opts.complete_opts.set_cache == nil then
    opts.complete_opts.set_cache = function(_, _, items)
      vim.g.cached_jira_issues = items
    end
  end

  if opts.complete_opts.items == nil then
    opts.complete_opts.items = {
      { '[%s] %s', { root = { 'key' }, fields = { 'summary' } } },
    }
  end

  source.complete = require('cmp-jira-issues.complete').get_complete_fn(opts.complete_opts)

  if not registered then
    require('cmp').register_source(opts.source_name or 'jira_issues', source.new())

    if clear_cache ~= false then
      vim.api.nvim_create_user_command('JiraClearCache', clear_cache, { desc = 'Clear cache for Jira issue completion' })
    end

    registered = true
  end
end

return M
