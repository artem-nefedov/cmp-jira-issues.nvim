local M = {}

local registered = false

function M.setup(opts)
  local config = require('cmp-jira-issues.config')

  if opts.is_available ~= nil then
    config.source.is_available = opts.is_available
  end

  if opts.get_trigger_characters ~= nil then
    config.source.get_trigger_characters = opts.get_trigger_characters
  end

  if opts.complete_opts == nil then
    opts.complete_opts = {}
  end

  opts.complete_opts.curl_config = vim.fn.expand(opts.complete_opts.curl_config or '~/.jira-curl-config')

  if opts.complete_opts.item_format == nil then
    opts.complete_opts.item_format = '[%s] '
  end

  if opts.complete_opts.get_cache == nil then
    opts.complete_opts.get_cache = function(self, bufnr)
      return self.cache[bufnr] or vim.t.cached_jira_issues
    end
  end

  if opts.complete_opts.set_cache == nil then
    opts.complete_opts.set_cache = function(self, bufnr, items)
      self.cache[bufnr] = items
      vim.t.cached_jira_issues = items
    end
  end

  config.source.complete = config.get_complete_fn(opts.complete_opts)

  if not registered then
    require('cmp').register_source(opts.source_name or 'jira_issues', config.source.new())
    registered = true
  end
end

return M
