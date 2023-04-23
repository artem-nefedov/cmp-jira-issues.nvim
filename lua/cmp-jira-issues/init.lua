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

  config.source.complete = config.get_complete_fn(opts.complete_opts or {})

  if not registered then
    require('cmp').register_source(opts.source_name or 'jira_issues', config.source.new())
    registered = true
  end
end

return M
