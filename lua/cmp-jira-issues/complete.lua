local M = {}

local Job = require('plenary.job')

local enabled = true

M.get_complete_fn = function(complete_opts)
  return function(self, _, callback)
    if not enabled then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()

    local cached = complete_opts.get_cache(self, bufnr)
    if cached ~= nil then
      callback({ items = cached, isIncomplete = false })
      return
    end

    Job:new({
      'curl',
      '--silent',
      '--get',
      '--header',
      'Content-Type: application/json',
      '--data-urlencode',
      'fields=summary,description',
      '--config',
      complete_opts.curl_config,
      on_exit = function(job)
        local result = job:result()
        local ok, parsed = pcall(vim.json.decode, table.concat(result, ''))

        if not ok then
          enabled = false
          print('bad response from curl after querying jira')
          return
        end

        if parsed == nil then -- make linter happy
          enabled = false
          return
        end

        local items = {}
        for _, issue in ipairs(parsed.issues) do
          issue.body = string.gsub(issue.body or '', '\r', '')

          table.insert(items, {
            label = string.format(complete_opts.item_format, issue.key),
            documentation = {
              kind = 'plaintext',
              value = string.format('[%s] %s\n\n%s', issue.key, issue.fields.summary,
                issue.fields.description),
            },
          })
        end

        callback({ items = items, isIncomplete = false })

        complete_opts.set_cache(self, bufnr, items)
      end,
    }):start()
  end
end

return M
