--[[
  PauseMenuState Lua template
  Path: scripts/states/pauseMenu/template_pause.lua
        (shared assets or mods/<mod>/scripts/states/pauseMenu/)

  Common callbacks used by PauseMenuState:
    onCreate / onCreatePost / onUpdate / onDestroy
    onPause / onResume (if the state forwards them)
]]

function onCreate()
	-- Runs when the pause menu opens
	-- debugPrint('Pause Lua: onCreate')
end

function onCreatePost()
	-- Runs after default pause UI is built
end

function onUpdate(elapsed)
	-- Called every frame while paused
	-- elapsed = delta time in seconds
end

function onDestroy()
	-- Pause menu is closing / leaving
end

-- Optional: react to menu selection (if PauseMenuState calls these)
function onPauseMenuSelect(option)
	-- option = string, e.g. "Resume", "Restart Song", "Exit to menu"
end

function onPauseMenuConfirm(option)
end
