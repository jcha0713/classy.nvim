local M = {}

local config = require("classy.config")

M.set_line = function(bufnr, start_row, end_row, start_col, end_col, inject_str)
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
  local new_line = M.replace_line(lines[1], start_col, end_col, inject_str)
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, { new_line })
end

M.replace_line = function(line, start_col, end_col, insert_str)
  local new_line = line:sub(0, start_col) .. insert_str .. line:sub(end_col + 1)
  return new_line
end

M.get_node_text = function(node)
  return vim.treesitter.get_node_text(node, 0)
end

M.is_jsx = function(lang)
  return (lang == "javascript" or lang == "typescript" or lang == "tsx")
end

M.is_same_line = function(end_row1, end_row2)
  return end_row2 - end_row1 == 0
end

-- temporary solution for handling template strings in astro
M.is_template_string = function(value)
  local value_str = M.get_node_text(value)
  return value_str:sub(2, 2) == [[`]] and value_str:sub(-2, -2) == [[`]]
end

M.is_not_element = function(node, lang)
  if M.is_jsx(lang) then
    return node:type() ~= "jsx_element"
      and node:type() ~= "jsx_self_closing_element"
  else
    return node:type() ~= "element"
  end
end

M.get_quotes = function(num)
  num = math.max(num, 0)
  local spaces = ""

  for i = 1, num do
    spaces = spaces .. " "
  end

  local opts = config.get()
  local quote = opts.use_double_quote and [["]] or [[']]
  return quote .. spaces .. quote
end

M.has_lang_parser = function(lang)
  if vim.fn.has("nvim-0.11") == 1 then
    return vim.treesitter.language.add(lang)
  else
    return pcall(vim.treesitter.language.add, lang)
  end
end

return M
