# Check for Lua 5.1 and LuaRocks dependencies
check-dependencies:
	@if ! type cmake >/dev/null 2>&1; then \
		echo "cmake is required for one of the dependencies"; \
		exit 1; \
  fi
	@if ! type luarocks >/dev/null 2>&1; then \
		echo "LuaRocks is required, but not found."; \
		exit 1; \
  fi
	@lua_version=$(shell lua -v 2>&1 | awk '{print $$2}'); \
  if ! type lua >/dev/null 2>&1; then \
		echo "Lua 5.1 is required, no lua installation found"; \
		exit 1; \
  elif [ "$$lua_version" != "5.1" ]; then \
		echo "Lua 5.1 is required, but found $$lua_version."; \
		exit 1; \
  fi

# Update the LuaRocks path
update-luarocks-path:
	@if [ "$SHELL" = "/bin/zsh" ]; then \
		luarocks path >> ~/.zshrc;\
	else \
		luarocks path >> ~/.bashrc; \
	fi
		


# Install LuaRocks packages
install-packages:
	@luarocks install cqueues --local
	@luarocks install luv --local
	@luarocks install lua-cjson --local
	@luarocks install http --local

all: check-dependencies update-luarocks-path install-packages

