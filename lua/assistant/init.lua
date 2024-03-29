local config = require("assistant.config")

local Chat = require("assistant.chat")
local M = {}

M.namespace = 0
M.assistantToggled = false

M.setup = function(opts)
	M.namespace = vim.api.nvim_create_namespace("assistant.nvim")
	config.setup(opts)
	M.chat = Chat(M.namespace)
	return M
end

function M.hide_assistant()
	if M.assistantToggled then
		M.chat:hide()
		M.assistantToggled = false
	end
end
function M.show_assistant()
	if not M.assistantToggled then
		M.chat:show()
		M.assistantToggled = true
	end
end
function M.toggle_assistant()
	if M.assistantToggled then
		M.hide_assistant()
	else
		M.show_assistant()
	end
end

function M.move_to_chat()
	if M.assistantToggled then
		M.chat:move_to_top_buffer()
	else
		-- noop?
	end
end

function M.move_to_input()
	if M.assistantToggled then
		M.chat:move_to_input_buffer()
	else
		-- noop?
	end
end

return M
