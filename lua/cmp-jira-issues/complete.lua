local M = {}

local function extract_field(parent, field)
  if #field == 1 then
    return parent[field[1]]
  else
    local t = vim.deepcopy(field)
    table.remove(t, 1)
    return extract_field(parent[field[1]], t)
  end
end

local get_fields = function(issue, items_from)
  local t = {}
  for _, item_key in ipairs(items_from) do
    table.insert(t, extract_field(issue, item_key))
  end
  return t
end

M.get_complete_fn = function(complete_opts)
  return function(self, _, callback)
    local cached = complete_opts.get_cache(self)

    if cached ~= nil then
      callback({ items = cached, is_incomplete_backward = false, is_incomplete_forward = false })
      return
    end

    vim.system({
      'curl',
      '--silent',
      '--get',
      '--header',
      'Content-Type: application/json',
      '--data-urlencode',
      'fields=' .. complete_opts.fields,
      '--config',
      complete_opts.curl_config,
    }, nil, function(obj)
      vim.schedule(function()
        if obj.code ~= 0 then
          print('curl returned ' .. obj.code)
          complete_opts.set_cache(self, {})
          callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
          return
        end

        local ok, parsed = pcall(vim.json.decode, obj.stdout)

        if not ok then
          print('bad response from curl after querying jira')
          complete_opts.set_cache(self, {})
          callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
          return
        end

        if parsed == nil then -- make linter happy
          complete_opts.set_cache(self, {})
          callback({ items = {}, is_incomplete_backward = false, is_incomplete_forward = false })
          return
        end

        local items = {}
        for _, issue in ipairs(parsed.issues) do
          for _, item_format in ipairs(complete_opts.items) do
            table.insert(items, {
              label = string.format(item_format[1], unpack(get_fields(issue, item_format[2]))),
              documentation = {
                kind = 'plaintext',
                value = string.format('[%s] %s\n\n%s', issue.key, (issue.fields or {}).summary or '',
                  string.gsub((issue.fields or {}).description or '', '\r', '')),
              },
            })
          end
        end

        callback({
          items = items,
          -- Whether blink.cmp should request items when deleting characters
          -- from the keyword (i.e. "foo|" -> "fo|")
          -- Note that any non-alphanumeric characters will always request
          -- new items (excluding `-` and `_`)
          is_incomplete_backward = false,
          -- Whether blink.cmp should request items when adding characters
          -- to the keyword (i.e. "fo|" -> "foo|")
          -- Note that any non-alphanumeric characters will always request
          -- new items (excluding `-` and `_`)
          is_incomplete_forward = false,
        })

        complete_opts.set_cache(self, items)
      end)
    end)
  end
end

return M
