local config = require("assistant.config")

local Chat = require("assistant.chat")
local M = {}

M.namespace = 0
M.assistantToggled = false

M.setup = function(opts)
	config.setup(opts)
end

function M.ToggleAssistant()
	if M.namespace == 0 then
		M.chat = Chat(M.namespace)
		M.chat:mount()
		M.assistantToggled = true
	elseif M.assistantToggled then
		M.chat:hide()
		M.assistantToggled = false
	else
		M.chat:mount()
		M.assistantToggled = true
	end
end
return M
