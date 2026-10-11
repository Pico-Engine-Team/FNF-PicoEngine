-- Template Stage for Psych Engine (Lua)
-- If you're moving your stage from PlayState to a stage file,
-- you might have to rename some variables if they're missing, for example: camZooming -> game.camZooming

function onCreate()
	-- Spawn your stage sprites here.
	-- Characters are not ready yet on this function, so you can't add things above them yet.
	-- Use onCreatePost() if that's what you want to do.
end

function onCreatePost()
	-- Use this function to layer things above characters!
end

function onUpdate(elapsed)
	-- Code here
end

function onDestroy()
	-- Code here
end

function onCountdownTick(count)
	-- count values: 0 (THREE), 1 (TWO), 2 (ONE), 3 (GO), 4 (START)
	if count == 0 then
		-- THREE
	elseif count == 1 then
		-- TWO
	elseif count == 2 then
		-- ONE
	elseif count == 3 then
		-- GO
	elseif count == 4 then
		-- START
	end
end

function onStartSong()
	-- Code here
end

-- Steps, Beats and Sections:
--    curStep, curDecStep
--    curBeat, curDecBeat
--    curSection
function onStepHit()
	-- Code here
end

function onBeatHit()
	-- Code here
end

function onSectionHit()
	-- Code here
end

-- Substates for pausing/resuming tweens and timers
function onPause()
	-- Code here when paused
end

function onResume()
	-- Code here when resumed
end

-- For events
function onEvent(name, value1, value2)
	if name == "My Event" then
		-- Code here
	end
end

-- Note Hit/Miss
function goodNoteHit(note)
	-- Code here
end

function opponentNoteHit(note)
	-- Code here
end

function noteMiss(note)
	-- Code here
end

function noteMissPress(direction)
	-- Code here
end