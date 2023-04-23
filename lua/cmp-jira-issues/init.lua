local M = {}

local registered = false

function M.setup(opts)
  local source = {}

  source.new = function()
    local self = setmetatable({ cache = {} }, { __index = source })
    return self
  end

  source.get_trigger_characters = opts.get_trigger_characters or function()
    return { '[' }
  end

  source.is_available = opts.is_available or function()
    return vim.bo.filetype == 'gitcommit' or
        (vim.bo.filetype == 'markdown' and vim.fs.basename(vim.api.nvim_buf_get_name(0)) == 'CHANGELOG.md')
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

  source.complete = require('cmp-jira-issues.complete').get_complete_fn(opts.complete_opts)

  if not registered then
    require('cmp').register_source(opts.source_name or 'jira_issues', source.new())
    registered = true
  end
end

return M
