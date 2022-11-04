local M = {}

local utils = require("classy.utils")

M.get_attr_query = function(lang)
  local query_text = utils.is_jsx(lang)
      and [[
    ;; jsx
    ((property_identifier) @attr_name (#eq? @attr_name "className") [(jsx_expression (_)?) (string)] @attr_value) 
  ]]
    or [[
    ;; html
   ((attribute_name) @attr_name (#eq? @attr_name "class") (quoted_attribute_value) @attr_value)
  ]]

  local query = vim.treesitter.query.parse_query(lang, query_text)

  return query
end

M.get_tag_query = function(lang)
  local query_text = utils.is_jsx(lang)
      and [[
    ;; jsx
    ([( jsx_self_closing_element ) ( jsx_opening_element ) ] @open )
    ]]
    or [[
    ;; html
    ([( start_tag ) ( self_closing_tag ) ] @tag)
    ]]

  local query = vim.treesitter.query.parse_query(lang, query_text)

  return query
end

return M
