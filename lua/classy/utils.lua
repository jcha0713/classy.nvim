local M = {}

M.set_line = function(bufnr, start_row, end_row, col, inject_str)
  local line = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
  local new_line = M.replace_line(line[1], col, inject_str)
  vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, { new_line })
end

M.replace_line = function(line, replace_col, insert_str)
  local new_line = line:sub(0, replace_col)
    .. insert_str
    .. line:sub(replace_col + 1)
  return new_line
end

M.get_node_text = function(node)
  return vim.treesitter.query.get_node_text(node, 0)
end

M.is_jsx = function(lang)
  return (lang == "javascript" or lang == "typescript" or lang == "tsx")
end

M.is_not_element = function(node, lang)
  if M.is_jsx(lang) then
    return node:type() ~= "jsx_element"
      and node:type() ~= "jsx_self_closing_element"
  else
    return node:type() ~= "element"
  end
end

return M
