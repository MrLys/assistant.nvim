local M = {}

M.to_cmd_line_props = function(...)
	local args = { ... }
	local prop_string = ""
	assert(#args % 2 == 0, "An even number of entries needs to be passed")
	for i, arg in ipairs(args) do
		if i % 2 ~= 0 or i == 0 then
			prop_string = prop_string .. " " .. arg
		else
			prop_string = prop_string .. arg
		end
	end
	return prop_string
end
M.async_write_to_stddata = function(filename, data)
	local status = true
	local msg = ""
	filename = vim.fn.stdpath("data") .. filename
	local fd, omsg, _ = vim.loop.fs_open(filename, "w", 438)
	if not fd then
		status, msg = false, ("Failed to open: %s\n%s"):format(filename, omsg)
	else
		local ok, wmsg, _ = vim.loop.fs_write(fd, data, 0)
		if not ok then
			status, msg = false, ("Failed to write: %s\n%s"):format(filename, wmsg)
		end
		assert(vim.loop.fs_close(fd))
	end
	if not status then
		print(msg)
	end
	return status, msg
end

M.write_lines_to_buffer = function(winid, bufnr, lines, render_hook)
	local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local current_winid = vim.api.nvim_get_current_win()
	local last_row = #all_lines
	local last_row_content = all_lines[last_row]
	local last_col = string.len(last_row_content)

	local text = table.concat(lines or {}, "\n")

	local split_lines = vim.split(text, "\n")
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_text(bufnr, last_row - 1, last_col, last_row - 1, last_col, split_lines)
	local new_last_row = last_row + #split_lines - 1
	vim.api.nvim_win_set_cursor(winid, { new_last_row, 0 })
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	render_hook(current_winid, winid, bufnr)
end

M.write_to_buffer = function(winid, bufnr, text, render_hook)
	if text == "" or text:len() == 0 then
		return
	end
	local all_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current_winid = vim.api.nvim_get_current_win()

	local last_row = #all_lines
	local last_row_content = all_lines[last_row]
	local last_col = string.len(last_row_content)

	text = vim.split(text, "\n")
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_text(bufnr, last_row - 1, last_col, last_row - 1, last_col, text)
	--vim.api.nvim_buf_set_lines(bufnr, last_row, last_row, true, text)
	-- Move the cursor to the end of the new lines
	local new_last_row = last_row + #text - 1
	vim.api.nvim_win_set_cursor(winid, { new_last_row, 0 })
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	render_hook(current_winid, winid, bufnr)
end

M.get_path_to_query = function()
	local path = debug.getinfo(1).source:sub(2)
	local path_to_script = path:sub(0, path:len() - (("utils.lua"):len()))
	return path_to_script
end

return M
