local M = {}

local utils = require("classy.utils")

M.get_query = function(lang)
  local query_text = utils.is_jsx(lang)
      and [[
    ;; jsx

    ;; get @tag_name
    [(jsx_element (jsx_opening_element name: [( nested_identifier ) ( identifier )] @tag_name)) (jsx_self_closing_element name: [( nested_identifier ) ( identifier )] @tag_name)]

    ;; get class attribute value
    (jsx_element(jsx_opening_element (jsx_attribute (property_identifier) @attr_name (#eq? @attr_name "className") [(jsx_expression (_)?) (string)] @attr_value)))

    ;; handle self closing tag (component)
    (jsx_self_closing_element attribute: (jsx_attribute (property_identifier) @attr_name (#eq? @attr_name "className") [(jsx_expression (_)?) (string)] @attr_value))
    ]]
    or [[
    ;; html

    ;; get @tag_name
    (element [(start_tag (tag_name) @tag_name) (self_closing_tag (tag_name) @tag_name)])

    ;; get class attribute value
    (element (_ (attribute (attribute_name) @attr_name (#eq? @attr_name "class") (quoted_attribute_value) @attr_value)))
    ]]

  local query = vim.treesitter.query.parse_query(lang, query_text)

  return query
end

return M
