local M = {}

local opts
local Add = {}
local Remove = {}
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

-- Place the cursor at the end of the class attribute in a tag.
-- If the class attribute is not present, then add one.
local traverse_tree = function(method)
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")

  -- astro uses "class" insated of "classname"
  -- but the syntax is close to tsx
  -- so it needs a dedicated boolean flag to check it
  local is_astro = ft == "astro"

  -- Check whether a parser for the language is installed
  local parser_lang = parsers.ft_to_lang(ft)
  local installed = vim.treesitter.language.require_language(
    parser_lang,
    nil,
    true
  )

  if not installed then
    vim.notify(
      "No Treesitter parser was found for " .. parser_lang,
      vim.log.levels.ERROR
    )
    return
  end

  if ft == "markdown.mdx" then
    ft = "markdown"
  end

  -- get cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local range = {
    cursor[1],
    cursor[2],
    cursor[1],
    cursor[2],
  }

  local lang_tree = vim.treesitter.get_parser(bufnr, parser_lang)

  -- get lang information of current position
  local current_tree = lang_tree:language_for_range(range)
  local lang_at_cursor = current_tree:lang()

  local lang = parsers.ft_to_lang(lang_at_cursor)

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

  -- Get the first captured nodes from the iterator
  local get_tag = queries.get_tag_query(lang):iter_captures(node, bufnr)
  local get_value = queries.get_attr_query(lang, is_astro):iter_captures(
    node,
    bufnr
  )

  local _, tag = get_tag()
  local _, class = get_value()
  local _, value = get_value()

  -- Save the range of each nodes
  get_range("class", class)
  get_range("tag", tag)

  if tag:named_child(0) ~= nil then
    get_range("tag_name", tag:named_child(0))
  end

  if not class and method == ADD then
    Add.new_attribute(
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

  -- if the captured node is not from the outermost tag,
  -- add a new class attribute
  -- or notify the user that no attribute was found
  if
    (
      ranges["value"].start_row < ranges["tag"].start_row
      or ranges["value"].end_row > ranges["tag"].end_row
    )
    or (
      utils.is_same_line(ranges["value"].end_row, ranges["tag"].end_row)
      and ranges["value"].start_col > ranges["tag"].end_col
    )
  then
    if method == ADD then
      Add.new_attribute(
        bufnr,
        lang,
        ranges["tag_name"].start_row,
        ranges["tag_name"].end_row,
        ranges["tag_name"].start_col,
        ranges["tag_name"].end_col
      )
    elseif method == REMOVE then
      vim.notify("No class attribute was found", vim.log.levels.WARN)
    end
    return
  end

  if value ~= nil then
    if method == ADD then
      local no_content_len = 2
      -- handle template string cases
      if
        value:named_child(0) ~= nil
        and value:named_child(0):type() == "template_string"
      then
        ranges["value"].end_col = ranges["value"].end_col - 1
        no_content_len = 4
      end

      -- if the attribute value is just an empty string (""),
      -- no need to add a space
      local has_value = string.len(utils.get_node_text(value)) > no_content_len
      local inject_str = has_value and " " or ""
      ranges["value"].end_col = has_value and ranges["value"].end_col
        or ranges["value"].end_col - 1

      Add.more_classes(
        bufnr,
        ranges["value"].start_row,
        ranges["value"].end_row,
        ranges["value"].start_col,
        ranges["value"].end_col,
        inject_str
      )
    elseif method == REMOVE then
      Remove.class(
        bufnr,
        ranges["value"].start_row,
        ranges["value"].end_row + 1,
        ranges["class"].start_col - 1, -- -1 for removing trailing space
        ranges["value"].end_col,
        ""
      )
    end
  end
end

-- add a new class attribute
Add.new_attribute =
  function(bufnr, lang, start_row, end_row, start_col, end_col)
    local inject_str = utils.is_jsx(lang)
        and [[ className=]] .. utils.get_quotes(0)
      or [[ class=]] .. utils.get_quotes(0)

    -- use "class" if the filetype is astro
    local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
    if ft == "astro" then
      inject_str = [[ class=]] .. utils.get_quotes(0)
    end

    utils.set_line(bufnr, start_row, end_row + 1, end_col, end_col, inject_str)

    vim.api.nvim_win_set_cursor(0, {
      end_row + 1,
      end_col + string.len(inject_str) - 1,
    })

    vim.cmd("startinsert")
  end

Add.more_classes = function(bufnr, start_row, end_row, start_col, end_col, str)
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

Remove.class = function(bufnr, start_row, end_row, start_col, end_col, str)
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
