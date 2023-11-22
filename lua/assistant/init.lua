-- lua/yourplugin/init.lua
local M = {}

function M.setup(opts)
    require('assistant.config').setup(opts)
end
function M.run()
    require('assistant.run').run()
    require('assistant.chat_window').open()
end
return M
