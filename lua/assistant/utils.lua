local Path = require("plenary.path")
local M = {}
local chat_history_file_path = ".chat_history_cache"
M.mapToStructure = function (history)
    for i, message in ipairs(history) do
        print(i, message)
    end
end
M.readHistory = function ()
    local lines = vim.json.decode(Path:new(chat_history_file_path):read())
    local chat_content = {}
    for _, message in ipairs(lines) do
        table.insert(chat_content, message)
    end
    return chat_content
end

M.writeToChat = function (buffer, content)
    local chat_content = {}
    for _, line in ipairs(content) do
        table.insert(chat_content, line[1] .. ": ")
        for _, inner_line in ipairs(line[2]) do
            table.insert(chat_content, inner_line)
        end
        table.insert(chat_content, "") -- Acts as a newline
    end
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, chat_content)
end
M.splitStringOnNewlines = function (str)
    local lines = {}
    for line in str:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    return lines
end

return M
