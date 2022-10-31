-- TODO: Add remove_class that removes class attribute

local M = {}
local add = {}
local remove = {}

local utils = require("classy.utils")
local ts_utils = require("nvim-treesitter.ts_utils")
local parsers = require("nvim-treesitter.parsers")

local get_query = function(lang)
  local query_text = utils.is_jsx(lang)
      and [[
    ;; jsx

    ;; get @tag_name
    [(jsx_element (jsx_opening_element (identifier) @tag_name)) (jsx_self_closing_element (identifier) @tag_name)]

    ;; get class attribute value
    (jsx_element (_ (jsx_attribute (property_identifier) @attr_name (#eq? @attr_name "className") (string) @attr_value))?)

    ;; handle self closing tag (component)
    (jsx_self_closing_element attribute: (jsx_attribute (property_identifier) @attr_name (#eq? @attr_name "className") (string) @attr_value))
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

-- Place the cursor at the end of the class attribute in a tag.
-- If the class attribute is not present, then add one.
M.add_class = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = unpack(cursor_pos)
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  local lang = parsers.ft_to_lang(ft)

  -- treesitter query to capture the tag name of an element,
  -- attribute name,
  -- and attribute value
  local query = get_query(lang)

  -- find the node at current cursor position
  local node = ts_utils.get_node_at_cursor()

  if not node then
    error("No Treesitter parser found.")
    return
  end

  -- Percolate up the lang tree until it reaches the nearest element tag
  while utils.is_not_element(node, lang) do
    if node:parent() == nil then
      return
    end
    node = node:parent()
  end

  local has_class_attr = false
  local tag_name_row = 0
  local tag_name_end_col = 0

  for id, capture, _ in query:iter_captures(node, bufnr, cursor_row - 1, cursor_row) do
    local tag_name = query.captures[1]
    local attr_name = query.captures[2]
    local attr_value = query.captures[3]

    local name = query.captures[id]

    local capture_start_row, capture_start_col, capture_end_row, capture_end_col =
      capture:range()

    -- Store tag name position for future use
    if name == tag_name then
      tag_name_row = capture_end_row
      tag_name_end_col = capture_end_col
    end

    -- If there's already class attribute in captured tag, place the cursor at the end.
    if name == attr_value then
      has_class_attr = true

      local has_value = string.len(utils.get_node_text(capture)) > 2

      local inject_str = has_value and " " or ""
      capture_end_col = has_value and capture_end_col or capture_end_col - 1

      add.more_classes(
        bufnr,
        capture_start_row,
        capture_end_row,
        capture_end_col,
        inject_str
      )
    end
  end

  if not has_class_attr and tag_name_row ~= 0 then
    local inject_str = utils.is_jsx(lang) and [[ className=""]] or [[ class=""]]

    add.class(bufnr, tag_name_row, tag_name_row, tag_name_end_col, inject_str)
  end
end

add.more_classes = function(bufnr, start_row, end_row, end_col, str)
  utils.set_line(bufnr, start_row, end_row + 1, end_col - 1, str)

  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })

  vim.cmd("startinsert")
end

add.class = function(bufnr, start_row, end_row, end_col, str)
  utils.set_line(bufnr, start_row, end_row + 1, end_col, str)

  vim.api.nvim_win_set_cursor(0, {
    end_row + 1,
    end_col + string.len(str) - 1,
  })

  vim.cmd("startinsert")
end

return M
