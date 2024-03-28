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
    api_key = "<api-key-here>",
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

