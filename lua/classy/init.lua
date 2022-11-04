-- TODO: JSX or HTML tag query table로 처리
-- TODO: JSX일 때 template_string 핸들링

local M = {}

local opts
local add = {}
local remove = {}
local ranges = {}
local ADD = "add"
local REMOVE = "remove"

local utils = require("classy.utils")
local config = require("classy.config")
local queries = require("classy.queries")
local parsers = require("nvim-treesitter.parsers")
local ts_utils = require("nvim-treesitter.ts_utils")

local get_range = function(name, node)
  if not node then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()
  ranges[name] = {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local get_query = function(lang)
  local query_text = utils.is_jsx(lang)
      and [[
    ;; jsx
      ((property_identifier) @attr_name (#eq? @attr_name "className") [(jsx_expression (_)?) (string)] @attr_value (#offset! @attr_value)) 
    ]]
    or [[
    ;; html
     ((attribute_name) @attr_name (#eq? @attr_name "class") (quoted_attribute_value) @attr_value (#offset! @attr_value))
    ]]

  local query = vim.treesitter.query.parse_query(lang, query_text)

  return query
end

-- Place the cursor at the end of the class attribute in a tag.
-- If the class attribute is not present, then add one.
local traverse_tree = function(method)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = unpack(cursor_pos)
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  local lang = parsers.ft_to_lang(ft)

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

  local has_class_attr = true

  local get_tag = vim.treesitter.query.parse_query(
    lang,
    -- [[ ([( jsx_self_closing_element ) ( jsx_opening_element ) ] @open (#offset! @open)) ]]
    [[([( start_tag ) ( self_closing_tag ) ] @tag (#offset! @tag))]]
  ):iter_captures(node, bufnr)

  local get_value = get_query(lang):iter_captures(node, bufnr)

  local _, tag = get_tag()
  local _, class = get_value()
  local _, value = get_value()

  get_range("class", class)
  get_range("tag", tag)

  if tag:named_child(0) ~= nil then
    get_range("tag_name", tag:named_child(0))
  end

  if not class then
    add.new_attribute(
      bufnr,
      lang,
      ranges["tag_name"].start_row,
      ranges["tag_name"].end_row,
      ranges["tag_name"].start_col,
      ranges["tag_name"].end_col
    )
    return
  else
    get_range("value", value)
  end

  if
    ranges["value"].start_row < ranges["tag"].start_row
    or ranges["value"].end_row > ranges["tag"].end_row
  then
    add.new_attribute(
      bufnr,
      lang,
      ranges["tag_name"].start_row,
      ranges["tag_name"].end_row,
      ranges["tag_name"].start_col,
      ranges["tag_name"].end_col
    )
    return
  end

  if method == ADD then
    local no_content_len = 2
    if value ~= nil then
      local has_value = string.len(utils.get_node_text(value)) > no_content_len
      local inject_str = has_value and " " or ""
      ranges["value"].end_col = has_value and ranges["value"].end_col
        or ranges["value"].end_col - 1

      add.more_classes(
        bufnr,
        ranges["value"].start_row,
        ranges["value"].end_row,
        ranges["value"].start_col,
        ranges["value"].end_col,
        inject_str
      )
    end
  elseif method == REMOVE then
    remove.class(
      bufnr,
      ranges["value"].start_row,
      ranges["value"].end_row + 1,
      ranges["class"].start_col - 1, -- -1 for removing trailing space
      ranges["value"].end_col,
      ""
    )
  end

  --   if method == ADD then
  --     local no_content_len = 2
  --     if
  --       capture:named_child(0) ~= nil
  --       and capture:named_child(0):type() == "template_string"
  --     then
  --       capture_end_col = capture_end_col - 1
  --       no_content_len = 4
  --     end
  --   elseif method == REMOVE then
  --     remove.class(
  --       bufnr,
  --       capture_start_row,
  --       capture_end_row + 1,
  --       attr_name_start_col - 1, -- -1 for removing trailing space
  --       capture_end_col,
  --       ""
  --     )
  --   end
end

add.new_attribute =
  function(bufnr, lang, start_row, end_row, start_col, end_col)
    local inject_str = utils.is_jsx(lang)
        and [[ className=]] .. utils.get_quotes(0)
      or [[ class=]] .. utils.get_quotes(0)

    add.class(bufnr, start_row, end_row, end_col, end_col, inject_str)
  end

add.more_classes = function(bufnr, start_row, end_row, start_col, end_col, str)
  local quote_offset = 1
  utils.set_line(
    bufnr,
    start_row,
    end_row + 1,
    end_col - quote_offset,
    end_col - quote_offset,
    str
  )

  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })

  vim.cmd("startinsert")
end

add.class = function(bufnr, start_row, end_row, start_col, end_col, str)
  utils.set_line(bufnr, start_row, end_row + 1, start_col, end_col, str)

  vim.api.nvim_win_set_cursor(0, {
    end_row + 1,
    end_col + string.len(str) - 1,
  })

  vim.cmd("startinsert")
end

remove.class = function(bufnr, start_row, end_row, start_col, end_col, str)
  utils.set_line(bufnr, start_row, end_row, start_col, end_col, str)

  if opts.move_cursor_after_remove or opts.insert_after_remove then
    vim.api.nvim_win_set_cursor(0, {
      end_row,
      start_col,
    })
  end

  if opts.insert_after_remove then
    vim.cmd("startinsert")
  end
end

M.add_class = function()
  traverse_tree(ADD)
end

M.remove_class = function()
  traverse_tree(REMOVE)
end

M.setup = function(user_config)
  config.setup(user_config)
  opts = config.get()
end

M.setup({})

return M
