local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Object = require("nui.object")
local json = require("cjson")
local config = require("assistant.config")
local utils = require("assistant.utils")

---@class Chat
---@field ns_id integer
---@field messages {}
---@field shown boolean
Chat = Object("Chat")
function Chat:init(ns_id)
	self.ns_id = ns_id
	self:create_layout()
	self.messages = {}
	self.shown = false
end

function Chat:get_message()
	local message = vim.trim(table.concat(vim.api.nvim_buf_get_lines(self.bottom_input.bufnr, 0, -1, true), "\n"))
	self:clear_input()
	return message
end

function Chat:clear_input()
	vim.api.nvim_buf_set_lines(self.bottom_input.bufnr, 0, -1, false, { "" })
end

function Chat:add_user_prompt_to_chat()
	local message = self:get_message()
	local buffer_message = ""
	if #self.messages ~= 0 then
		buffer_message = buffer_message .. "\n"
	end
	table.insert(self.messages, { role = "user", content = message })
	buffer_message = buffer_message .. "## You:" .. "\n" .. message .. "\n"
	local message_as_lines = vim.split(buffer_message, "\n")
	utils.write_lines_to_buffer(self.top_popup.winid, self.top_popup.bufnr, message_as_lines)
	utils.async_write_to_stddata(".chat", json.encode(self.messages))
end

function Chat:input_enter_fn()
	local first = true
	local assistant_response = ""
	self:add_user_prompt_to_chat()
	local _ = vim.fn.jobstart(config.options.cmd, {
		pty = true,
		stdout_buffered = false,
		stderr_buffered = false,
		cwd = utils.get_path_to_query(),
		on_stdout = function(_, data, _)
			local response = ""
			for _, line in ipairs(data) do
				if line == "\r" then
					response = response .. "\n"
				elseif line ~= "" then
					response = response .. line
				end
			end
			if response == "" or response:len() == 0 then
				-- skip empty responses
				return
			end
			if response == "*--- ... DONE! ... ---*" then
				table.insert(self.messages, {
					role = "assistant",
					content = assistant_response,
				})
				utils.async_write_to_stddata(".chat", json.encode(self.messages))
				return
			end
			assistant_response = assistant_response .. response
			local chat_content = ""
			if first then
				chat_content = "## Assistant:" .. "\n" .. response
				first = false
				local lines = vim.split(chat_content, "\r")
				utils.write_lines_to_buffer(self.top_popup.winid, self.top_popup.bufnr, lines)
			else
				chat_content = response
				local text = chat_content:gsub("\r", "\n")
				if string.match(text, "[^\n]") ~= nil then
					utils.write_to_buffer(self.top_popup.winid, self.top_popup.bufnr, text)
				end
			end
		end,
		on_stderr = function(_, data, _)
			error(data)
		end,
		on_exit = function(_, _) end,
	})
end

function Chat:input_quit()
	self.layout:unmount()
end

function Chat:create_layout()
	local map_options = { noremap = true, nowait = true }
	self.top_popup = Popup({
		enter = false,
		border = "rounded",
		buf_options = {
			modifiable = false,
			filetype = "markdown",
		},
	})

	self.bottom_input = Popup({
		enter = true,
		relative = "cursor",
		border = "rounded",
		buf_options = {
			modifiable = true,
			filetype = "markdown",
		},
		prompt = "> ",
	})
	self.layout = Layout(
		{
			position = "100%",
			size = {
				width = "50%",
				height = "90%",
			},
			border = {
				style = "rounded",
			},
		},
		Layout.Box({
			Layout.Box(self.top_popup, { size = "50%" }),
			Layout.Box(self.bottom_input, { size = "50%" }),
		}, { dir = "col" })
	)
	self.bottom_input:map("i", "<c-cr>", "<esc><cr>", { nowait = true })
	self.bottom_input:map("n", "<c-x>", function()
		self:input_quit()
	end, map_options)
	self.bottom_input:map("i", "<c-x>", function()
		self:input_quit()
	end, map_options)
	self.bottom_input:map("n", "<cr>", function()
		self:input_enter_fn()
	end, map_options)
end

function Chat:hide()
	self.layout:hide()
end
function Chat:mount()
	if self.layout == nil then
		self:create_layout()
		self.layout:mount()
		self.layout:show()
		vim.api.nvim_win_set_option(self.top_popup.winid, "wrap", true)
		vim.api.nvim_win_set_option(self.bottom_input.winid, "wrap", true)
		vim.api.nvim_win_set_option(self.top_popup.winid, "linebreak", true)
		vim.api.nvim_win_set_option(self.bottom_input.winid, "linebreak", true)
	else
		self.layout:mount()
		self.layout:show()
		vim.api.nvim_win_set_option(self.top_popup.winid, "wrap", true)
		vim.api.nvim_win_set_option(self.bottom_input.winid, "wrap", true)
		vim.api.nvim_win_set_option(self.top_popup.winid, "linebreak", true)
		vim.api.nvim_win_set_option(self.bottom_input.winid, "linebreak", true)
	end
end

return Chat
