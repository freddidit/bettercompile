local PATTERNS = {
  "([%w_/\\.%-%+]+):(%d*):(%d*)", -- GCC Style (FILE:ROW:COL)
}

local function compile(cmd, namespace, buf) 
  local output = vim.fn.systemlist(cmd)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)

  -- Parse files
  local lines = {} 
  local file_locations = {} 

  for line_number, line in ipairs(output) do
    lines[line_number] = {}
    local last_init = 0
    local init = 0
    while init < #line do
      for _, pattern in ipairs(PATTERNS) do
        local start_pos, end_pos, file, row, col = line:find(pattern, init)
        if not file then
          goto continue 
        end
        init = end_pos

        table.insert(lines[line_number], {            
          name = file,
          row = tonumber(row),
          col = tonumber(col),
          start_pos = start_pos,
          end_pos = end_pos
        })

        table.insert(file_locations, {
          start_pos = start_pos,
          end_pos = end_pos,
          line_number = line_number
        })

        ::continue::
      end

      if init == last_init then break end
      last_init = init
    end
  end

  for _, file_location in ipairs(file_locations) do
    vim.api.nvim_buf_add_highlight(buf, namespace, "String", file_location.line_number - 1, file_location.start_pos - 1, file_location.end_pos)
  end

  vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"[Compilation Done]"})
  vim.api.nvim_buf_add_highlight(buf, namespace, "String", vim.api.nvim_buf_line_count(buf) - 1, 0, -1)
  vim.bo[buf].modifiable = false 

  return lines, file_locations
end

local function switch_to_caller_win(caller)
  if vim.api.nvim_win_is_valid(caller.win) then
    vim.api.nvim_set_current_win(caller.win)
  else
    vim.api.nvim_command("split")
    caller.win = vim.api.nvim_get_current_win()
  end
end

local select_namespace = vim.api.nvim_create_namespace("select_namespace") 
local function move_to_file(buf, file_location)
  vim.api.nvim_win_set_cursor(0, {file_location.line_number, file_location.start_pos - 1})
  vim.api.nvim_buf_clear_namespace(buf, select_namespace, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, select_namespace, "Visual", file_location.line_number - 1, file_location.start_pos - 1, file_location.end_pos)
end

vim.api.nvim_create_user_command("Compile", function()
  local caller = {
    win = vim.api.nvim_get_current_win(),
    buf = vim.api.nvim_get_current_buf(),
    row = vim.api.nvim_win_get_cursor(0)[1],
    col = vim.api.nvim_win_get_cursor(0)[2]
  }

  local ok, cmd = pcall(vim.fn.input, "Compile command: ")
  if not ok then
    print("Cancelled")
    return
  end

  -- Run command
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_command("split")
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_name(buf, "[Compile]")

  local namespace = vim.api.nvim_create_namespace("highlights")
  local lines, file_locations = compile(cmd, namespace, buf) 

  -- Process quickfix 
  vim.keymap.set("n", "<CR>", function()
    local line_number, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    for _, file in pairs(lines[line_number]) do
      if cursor_col + 1 >= file.start_pos and cursor_col <= file.end_pos then
        switch_to_caller_win(caller)
        vim.cmd("edit "..vim.fn.fnameescape(file.name))
        vim.api.nvim_win_set_cursor(0, {file.row or 0, (file.col or 1) - 1})
        return 
      end
    end
  end, { buffer = buf })

  -- cycling
  local location_index = 0

  vim.keymap.set("n", "o", function()
    location_index = location_index + 1
    if location_index > #file_locations then location_index = 1 end
    if #file_locations <= 0 then return end
    local file_location = file_locations[location_index]
    move_to_file(buf, file_location)
  end, { buffer = buf })

  vim.keymap.set("n", "O", function()
    location_index = location_index - 1
    if location_index < 1 then location_index = #file_locations end
    if #file_locations <= 0 then return end
    local file_location = file_locations[location_index]
    move_to_file(buf, file_location)
  end, { buffer = buf })

  vim.keymap.set("n", "x", function()
    switch_to_caller_win(caller)
    vim.api.nvim_set_current_buf(caller.buf)
    vim.api.nvim_win_set_cursor(caller.win, {caller.row, caller.col})
  end, { buffer = buf })
  
  vim.keymap.set("n", "X", function()
    switch_to_caller_win(caller)
    vim.api.nvim_set_current_buf(caller.buf)
    vim.api.nvim_win_set_cursor(caller.win, {caller.row, caller.col})
    vim.api.nvim_buf_delete(buf, { force = false })
  end, { buffer = buf })

  vim.keymap.set("n", "r", function()
    vim.bo[buf].modifiable = true 
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    lines, file_locations = compile(cmd, namespace, buf) 
    location_index = 0
  end, { buffer = buf })

end, {})
