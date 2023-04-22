local M = {}

function M.setup(opts)
  local config = require('jira-commit-cmp.config')

  if opts.is_available ~= nil then
    config.source.is_available = opts.is_available
  end

  if opts.get_trigger_characters ~= nil then
    config.source.get_trigger_characters = opts.get_trigger_characters
  end

  config.source.complete = config.get_complete_fn(opts.complete_opts or {})

  require('cmp').register_source(opts.source_name or 'jira_issues', config.source.new())
end

return M
