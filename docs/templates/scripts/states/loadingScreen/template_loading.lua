--[[
  LoadingScreen Lua template
  Path: scripts/states/loadingScreen/template_loading.lua
        (shared assets or mods/<mod>/scripts/states/loadingScreen/)

  NOTE: Current LoadingScreenState loads .hx / .hxc by default.
  Lua support depends on your engine build — keep this file for when LUA is enabled
  on the loading screen, or load it from a state script that starts luas.

  Typical helpers (if bound like the HScript side):
    getLoaded() / getLoadMax()  — progress counters
]]

function onCreate()
	-- Runs when loading screen starts
	-- debugPrint('Loading Lua: onCreate')
end

function onUpdate(elapsed)
	-- local loaded = getLoaded and getLoaded() or 0
	-- local max = getLoadMax and getLoadMax() or 1
	-- local percent = max > 0 and (loaded / max) or 0
end

function onDestroy()
end
