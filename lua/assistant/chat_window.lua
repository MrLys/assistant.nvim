local Path = require("plenary.path")
local utils = require("assistant.utils")
local M = {}
M.chat_window_mounted = false
M.input_field_mounted = false
M.submit_multiline_input = function ()
    local lines = vim.api.nvim_buf_get_lines(M.input_field.bufnr, 0, -1, false)
    local input_text = table.concat(lines, "\n")
    local content = {">>>:"}
    local split_lines = utils.splitStringOnNewlines(input_text)
    print(split_lines)
    table.insert(content, split_lines)
    print(content)
    table.insert(M.chat_content, content)
    -- Update chat buffer with the new message
    -- local line_count = vim.api.nvim_buf_line_count(M.chat_buffer)
    utils.writeToChat(M.chat_window.bufnr, M.chat_content)
    -- vim.api.nvim_buf_set_lines(M.chat_buffer, line_count, line_count, false, content)
    vim.api.nvim_buf_set_lines(M.input_field.bufnr, 0, -1, false, { '' })
end

M.focus_chat = function ()
    vim.api.nvim_set_current_win(M.chat_window.winid)
end
M.focus_input_field = function ()
    vim.api.nvim_set_current_win(M.input_field.winid)
end
M.unmount = function ()
    M.unmount_chat_window()
    M.unmount_input_field()
end

M.mount_chat_window = function ()
    if M.chat_window_mounted then
        print('already mounted')
        return
    end
    M.chat_window_mounted = true
    vim.api.nvim_buf_set_keymap(M.chat_window.bufnr, 'n', '<C-J>', '<cmd> lua require("assistant.chat_window").focus_input_field()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.chat_window.bufnr, 'n', '<C-K>', '<cmd> lua require("assistant.chat_window").focus_input_field()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.chat_window.bufnr, 'n', '<C-X>', '<cmd> lua require("assistant.chat_window").focus_chat()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.chat_window.bufnr, 'i', '<C-X>', '<cmd> lua require("assistant.chat_window").unmount()<CR>', { noremap = true })
    M.chat_window:mount()
end

M.mount_input_field = function()
    if M.input_field_mounted then
        return
    end
    M.input_field_mounted = true

    vim.api.nvim_buf_set_option(M.input_field.bufnr, 'buftype', 'prompt')
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'i', '<C-Enter>', '<C-o>o', { noremap = true })
    -- vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'i', '<Enter>', '<C-o>o', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'n', '<Enter>', '<cmd> lua require("assistant.chat_window").submit_multiline_input()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'n', '<C-K>', '<cmd> lua require("assistant.chat_window").focus_chat()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'n', '<C-J>', '<cmd> lua require("assistant.chat_window").focus_chat()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'n', '<C-X>', '<cmd> lua require("assistant.chat_window").unmount()<CR>', { noremap = true })
    vim.api.nvim_buf_set_keymap(M.input_field.bufnr, 'i', '<C-X>', '<cmd> lua require("assistant.chat_window").unmount()<CR>', { noremap = true })
    M.input_field:mount()
end

M.unmount_chat_window = function ()
    if not M.chat_window_mounted then
        return
    end
    M.chat_window_mounted = false
    M.chat_window:unmount()
    M.chat_window = nil
end

M.unmount_input_field = function ()
    if not M.input_field_mounted then
        return
    end
    M.input_field_mounted = false
    M.input_field:unmount()
    M.input_field = nil
end

M.open = function()
    -- Mount the chat window if it's not already
    local nui_popup = require('nui.popup')
    local event = require('nui.utils.autocmd').event

    -- Chat message buffer and display window.
    M.chat_buffer = vim.api.nvim_create_buf(false, true)
    M.chat_content = {}

    local chat_history_file_path = ".chat_history_cache"
    local chat_window_height = "60%"
    local chat_window_width = "80%"


    local input_field_height = 10
    local input_field_width = "80%"
    M.chat_window = nui_popup({
        enter = false,
        focusable = true,
        zindex = 20,  -- ensure the window stack order
        border = {
            style = "single",
            text = {
                top = " Chat ",
                top_align = "center",
            },
        },
        position = "50%",
        size = {
            width = chat_window_width,
            height = chat_window_height,
        },
        on_close = function()
            print('closing chat_window')
            M.unmount_chat_window()
            M.unmount_input_field()
        end,
        bufnr = M.chat_buffer
    })



    -- Input field for typing messages.
    M.input_field = nui_popup({
        enter = true,
        position = {
            row = "89%",  -- position the input field below the chat window
            col = "30%",
        },
        size = {
            width = input_field_width,
            height = input_field_height,
        },
        zindex = 10,  -- ensure the window stack order
        border = {
            style = "single",
            text = {
                bottom = " Type here ",
                bottom_align = "center",
            },
        },
        on_close = function ()
            print('closing chat_window from input_field from input_field')
            M.unmount_chat_window()
            M.unmount_input_field()
        end
    })


    M.input_field:on(event.BufLeave, function()
        -- Run logic to store chat history before deleting the buffer
        Path:new(chat_history_file_path):write(vim.fn.json_encode(M.chat_content), "w+")
        M.input_field:unmount()
    end, { once = true })

    M.mount_chat_window()

    -- Only attempt to access the window ID if the window is actually mounted
    if M.chat_window_mounted then
        local chat_win_height = vim.api.nvim_win_get_height(M.chat_window.winid)
        local chat_win_row = vim.api.nvim_win_get_position(M.chat_window.winid)[1]
        -- Position the input right below the chat window
        local input_row_position = chat_win_row + chat_win_height + 2  -- 2 for the border

        M.input_field:set_position({ row = input_row_position, col = "50%" })
    end
    M.mount_input_field()

    M.chat_content = utils.readHistory()
    utils.writeToChat(M.chat_window.bufnr, M.chat_content)

end
return M
