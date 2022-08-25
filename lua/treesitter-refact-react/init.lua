local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

-- function
local get_match_index = function(node)
  local nodeText = vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())
  local matchIndexStart, matchIndexEnd = string.find(nodeText,"</")
  return matchIndexStart, matchIndexEnd
end

-- function
local get_main_node = function()

  local node = ts_utils.get_node_at_cursor()
  
  if node == nil then
    error("No Treesitter found.")
  end

  local root = ts_utils.get_root_for_node(node)
  local start_row = node:start()
  local parent = node:parent()

  matchIndexStart, matchIndexEnd = get_match_index(node)

  if(matchIndexStart == 1 and matchIndexEnd == 2) then
    node = parent
    parent = node:parent()
  end

  while(parent ~= nil and parent ~= root and parent:start() == start_row) do
    node = parent
    parent = node:parent()
    matchIndexStart, matchIndexEnd = get_match_index(node)
    if(matchIndexStart == 1 and matchIndexEnd == 2) then
      node = parent
      parent = node:parent()
    end
  end

  return node

end

-- function
local insert_code_into_new_file = function(file_name)

  local node = get_main_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = node:range()
  local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})

  local pre_code = "export function"..file_name.."({}) {\n  return (\n"
  local post_code = "  );\n}"

  local i = 1

  local f = io.open(file_name..".js", "w")
  f:write(pre_code)
  while(text[i]~=nil) do
    f:write(tostring(text[i]).."\n")
    i = i + 1
  end
  f:write(post_code)
  f:close()

end

M.select = function()

  local node = get_main_node()
  local bufnr = vim.api.nvim_get_current_buf()
  ts_utils.update_selection(bufnr, node)

end

M.change = function()

  local file_name = "dummy"
  local node = get_main_node()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = node:range()

  local replaced = "<"..file_name.."/>"
  insert_code_into_new_file(file_name)

  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { replaced })
  
end

return M