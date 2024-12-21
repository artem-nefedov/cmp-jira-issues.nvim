local M = {}

M.check = function()
  vim.health.start("cmp-jira-issues")

  if vim.fn.executable("curl") == 0 then
    vim.health.error("curl not found in $PATH")
  else
    vim.health.ok("curl found in $PATH")
  end

  if vim.g.jira_curl_config == nil then
    vim.health.error("Setup was not executed")
  elseif vim.fn.filereadable(vim.g.jira_curl_config) == 0 then
    vim.health.error(vim.g.jira_curl_config .. " does not exist or is not readable")
  else
    vim.health.ok(vim.g.jira_curl_config .. " exists and is readable")
  end
end

return M
