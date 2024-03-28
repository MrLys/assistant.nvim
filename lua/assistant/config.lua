local utils = require("assistant.utils")
local M = {}
M.options = {}
M._options = nil
M.api_key_name = "ASSISTANT_NVIM_API_KEY"
M.options.render_hook = function(...) end
M.namespace = vim.api.nvim_create_namespace("ai-assistant")

function M.setup(options)
	M._options = options
	M._setup()
end

function M._setup()
	-- clean content from previous in case of broken chat history
	-- FIXME
	io.open(vim.fn.stdpath("data") .. ".chat", "w"):close()
	if type(M._options.api_key) == "function" then
		M._options.api_key = M._options.api_key()
	end
	M.options = vim.tbl_deep_extend("force", {}, {}, M.options or {}, M._options or {})
	assert(M.options.api_key ~= nil, "Api key  needs to be present!")

	M.options.cmd = utils.to_cmd_line_props(
		"ASSISTANT_NVIM_API_KEY=",
		M.options.api_key,
		"NVIM_DATA_PATH=",
		vim.fn.stdpath("data"),
		"ASSISTANT_NVIM_SLEEP_MS=",
		(M.options.sleep_ms or ""),
		"lua ",
		"query_assistant.lua"
	)
end
--M.setup()
return M
