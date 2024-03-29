# AI Assistant Neovim plugin
## Installation
This plugin requires some external lua modules and rely on luarocks to install them.
### Install [luarocks](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix):
I guess this is a bit hacky.

#### other prerequisites
```
sudo apt -y install libssl-dev
sudo apt install libreadline-dev
sudo apt install m4
```
#### lua 
```bash
curl -R -O https://www.lua.org/ftp/lua-5.1.tar.gz
tar -zxf lua-5.1.tar.gz
cd lua-5.1
make linux test
sudo make install
cd ..
rm -rf lua-5.1 lua-5.1.tar.gz
```
#### luarocks
```bash
curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-3.11.0.tar.gz
tar -zxf luarocks-3.11.0.tar.gz
cd luarocks-3.11.0
./configure --with-lua-include=/usr/local/include
make
sudo make install
cd ..
rm -rf luarocks-3.11.0.tar.gz luarocks-3.11.0
```
#### cmake
```bash
sudo apt get install cmake
```
#### other requirements
```bash
wget https://github.com/wahern/cqueues/archive/refs/tags/rel-20200726.tar.gz
tar -xzf rel-20200726.tar.gz
cd cqueues-rel-20200726
make LUA_APIS="5.1"
cd ..
rm -rf cqueues-rel-20200726 rel-20200726.tar.gz
```

## lazy
```lua
return {
  "mrlys/assistant.nvim",
    opts = {
      api_key = "<ANTHROPIC_CLAUDE_API_KEY>",
      sleep_ms = 25,
      move_to_input_key = "<c-j>",
      move_to_chat_key = "<c-k>",
    },
    cmd = {
      "AssistantToggle",
      "AssistantChat",
      "AssistantInput",
    },
    build = "make all",
    keys = {
      {
        "<leader>t",
        "<cmd>AssistantToggle<cr>",
        desc = "Toggle assistant chat window",
      },
      {
        "<leader>th",
        "<cmd>AssistantHide<cr>",
        desc = "Hide assistant chat window",
      },
    },
  },
}
```
The api key can also be passed as a function. This makes for a lot of fun initializations.
E.g:
```lua
return {
  "mrlys/assistant.nvim",
  opts = {
    api_key = function() return os.getenv("OPENAI_API_KEY")end,
    sleep_ms = 25,
    render_hook = function(...) end,
  },
  build = "make all"
  keys = {
    {
      "<leader>t",
      mode = { "n", "x", "o" },
      function()
        require("assistant"):AssistantToggle()
      end,
      desc = "Open or close Assistant chat window",
    },
  },
}
```
or

```lua
return {
  "mrlys/assistant.nvim",
  opts = {
    api_key = function() 
      return vim.fn.systemlist('op read "op://Private/OPENAI_API_KEY/credential"')[1]
    end,
    sleep_ms = 25,
    render_hook = function(...) end,
  },
  build = "make all"
  keys = {
    {
      "<leader>t",
      mode = { "n", "x", "o" },
      function()
        require("assistant"):ToggleAssistant()
      end,
      desc = "Open or close Assistant chat window",
    },
  },
}
```
You can also use a render_hook to modify the output of the assistant. This is useful for adding custom formatting or for adding custom commands to the assistant. The render_hook is a function that takes the assistant input and output window id argument. You can for instance trigger a markdown rendering plugin to render the assistant output in markdown. E.g: 
```lua
render_hook = function(input_winid, chat_winid, _)
  local success, ui = pcall(require, "render-markdown.ui")
  if success then
    vim.api.nvim_set_current_win(chat_winid)
    ui.refresh()
    vim.api.nvim_set_current_win(input_winid)
  end
end,


