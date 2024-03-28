local http = require("http.request")
local json = require("cjson")
local uv = require("luv")
local co = coroutine
local api_key = os.getenv("ASSISTANT_NVIM_API_KEY")
assert(api_key ~= nil and api_key ~= "", "ASSISTANT_NVIM_API_KEY must be set!")
local data_path = os.getenv("NVIM_DATA_PATH")
assert(data_path ~= nil and data_path ~= "", "NVIM_DATA_PATH must be set!")
local sleep_ms
if os.getenv("ASSISTANT_NVIM_SLEEP_MS") == nil then
	sleep_ms = 50
else
	sleep_ms = tonumber(os.getenv("ASSISTANT_NVIM_SLEEP_MS"))
end

local consume_chunk = function(chunk)
	local result = {}
	result.text = ""
	result.done = false
	if chunk then
		local entry = {}
		for line in string.gmatch(chunk, "[^\r\n]+") do
			local field, value = string.match(line, "^(%w+): (.+)$")
			if field then
				field = field:gsub("%s+", "")
				if field == "event" then
					value = value:gsub("%s+", "")
					entry.event = value
				end
				if field == "data" then
					entry.data = json.decode(value)
					if entry.data.type == "content_block_delta" then
						result.text = result.text .. entry.data.delta.text
					end
					if entry.data.type == "message_stop" then
						result.done = true
						return result
					end
				end
			else
				print("line is empty" .. line)
			end
		end
		result.done = false
		return result
	end
end
local make_request = function(messages, sender)
	local anthropic_url = "https://api.anthropic.com/v1/messages"

	local request = http.new_from_uri(anthropic_url)
	request.headers:delete(":method")
	request.headers:upsert(":method", "POST")
	-- hack to make sure the headers with starting with `:` is first
	-- as that is a requirement for this library
	request.headers:sort()
	request.headers:append("anthropic-version", "2023-06-01")
	request.headers:append("x-api-key", api_key)
	request.headers:append("accept", "text/event-stream")
	request.headers:append("content-type", "application/json")
	local body = {
		max_tokens = 1024,
		model = "claude-3-haiku-20240307",
		messages = messages,
		stream = true,
	}

	request:set_body(json.encode(body))

	local headers, stream = assert(request:go(5))
	if headers:get(":status") ~= "200" then
		local error_body = assert(stream:get_body_as_string())
		local json_body = json.decode(error_body)
		stream:shutdown()
		local error_message = json_body.error.message
		co.yield(error_message)
		sender(error_message)
		uv.sleep(sleep_ms)
		local done_message = "*--- ... DONE! ... ---*"
		co.yield(done_message)
		sender(done_message)
		return
	end
	local done = false
	local response = ""
	while not done do
		local chunk = stream:get_next_chunk()
		if chunk ~= nil then
			local res = consume_chunk(chunk)
			local x = co.yield(res.text)
			response = response .. res.text
			sender(x)
			uv.sleep(sleep_ms)
			if res.done then
				stream:shutdown()
				sender("*--- ... DONE! ... ---*")
				return
			end
		end
	end
end
local thread = co.create(function()
	local file = io.open(data_path .. ".chat", "r")
	if file ~= nil then
		local res = file:read("*all")
		local success, exitcode, code = file:close()
		if not success then
			print("Error reading chat")
			return
		end
		local messages = {}
		if res:len() > 2 then
			local status, result = pcall(function()
				return json.decode(res)
			end)
			if status then
				messages = result
			else
				print("chat is empty")
			end
		end
		make_request(messages, function(value)
			if value == "" then
				return
			end
			io.write(value)
			io.flush()
		end)
	end
end)
local p = function(t)
	local nxt = nil
	nxt = function(cont, ...)
		if not cont then
			return ...
		else
			return nxt(co.resume(t, ...))
		end
	end
	return nxt(co.resume(t))
end
p(thread)
