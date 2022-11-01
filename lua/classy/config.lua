local M = {}

local defaults = {
  use_double_quote = true,
  insert_after_remove = false,
  move_cursor_after_remove = true,
}

local config = vim.deepcopy(defaults)

M.validate = function(user_config)
  local to_validate, validated = {}, {}
  for key in pairs(user_config) do
    to_validate[key] = { user_config[key], type(defaults[key]) }
    validated[key] = user_config[key]
  end

  vim.validate(to_validate)
  return validated
end

M.get = function()
  return config
end

M.setup = function(user_config)
  user_config = user_config or {}
  local validated = M.validate(user_config)
  config = vim.tbl_extend("force", config, validated)
end

return M
