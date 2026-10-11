--[[
	MaxCombo.lua — Pico Engine
	HUD: Combo (Max) | Total Notes Hits (hit / total) | Misses

	When Preferences.data.comboEnabled is true:
	  - this HUD is shown
	  - PlayState scoreTxt hides "Misses" (Misses live here)

	Total Notes Hits format: 22 / 30  (pressed / total non-sustain notes)
]]

local combo = 0
local maxComb = 0
local misses = 0
local totalHits = 0
local totalNotes = 0
local comboEnabled = true

local function refreshComboEnabled()
	local ok, value = pcall(function()
		return getPropertyFromClass('Preferences', 'data.comboEnabled')
	end)
	if ok and value ~= nil then
		comboEnabled = (value == true or value == 'true' or value == 1 or value == '1')
		return
	end

	ok, value = pcall(function()
		return getProperty('comboEnabled')
	end)
	if ok and value ~= nil then
		comboEnabled = (value == true or value == 'true' or value == 1 or value == '1')
		return
	end

	comboEnabled = true
end

local function countGroupNotes(groupName)
	local count = 0
	local ok, len = pcall(function()
		return getProperty(groupName .. '.length')
	end)
	if not ok or len == nil then
		return 0
	end
	len = tonumber(len) or 0
	for i = 0, len - 1 do
		local isSus = false
		local ok2, sus = pcall(function()
			return getPropertyFromGroup(groupName, i, 'isSustainNote')
		end)
		if ok2 then isSus = (sus == true) end
		if not isSus then
			count = count + 1
		end
	end
	return count
end

local function recountTotalNotes()
	-- All non-sustain notes still in the song (unspawn + active)
	local n = countGroupNotes('unspawnNotes') + countGroupNotes('notes')
	if n > 0 then
		totalNotes = n
	end
	-- If we already hit some, total = hits so far + remaining is better:
	-- remaining unspawn+notes + totalHits already counted
	local remaining = countGroupNotes('unspawnNotes') + countGroupNotes('notes')
	-- notes currently on screen include ones not yet hit; unspawn are future
	-- total chart notes ≈ remaining non-sustain mustPress? User wants all notes.
	-- Safer: first recount at song start only once with unspawnNotes length
	if totalHits == 0 and remaining > 0 then
		totalNotes = remaining
	elseif remaining + totalHits > totalNotes then
		totalNotes = remaining + totalHits
	end
end

local function setHudVisible(visible)
	setProperty('comboText.alpha', visible and 1 or 0)
	setProperty('hitsText.alpha', visible and 1 or 0)
	if visible then
		setProperty('miss.alpha', misses > 0 and 1 or 0.8)
	else
		setProperty('miss.alpha', 0)
	end
end

local function updateTexts()
	setTextString('comboText', 'Combo: ' .. combo .. ' (Max: ' .. maxComb .. ')')
	setTextString('hitsText', 'Total Notes Hits: ' .. totalHits .. ' / ' .. totalNotes)
	setTextString('miss', 'Misses: ' .. misses)

	if misses > 0 then
		setTextColor('miss', 'ff0000')
		if comboEnabled then
			setProperty('miss.alpha', 1)
		end
	else
		setTextColor('miss', '0x36eaf7')
		if comboEnabled then
			setProperty('miss.alpha', 0.8)
		end
	end
end

function onCreate()
	refreshComboEnabled()

	makeLuaText('comboText', 'Combo: 0 (Max: 0)', 280, -8, 259)
	setObjectCamera('comboText', 'hud')
	setTextColor('comboText', '0xfff700')
	setTextSize('comboText', 20)
	setTextFont('comboText', 'vcr.ttf')
	setTextAlignment('comboText', 'center')
	addLuaText('comboText')

	makeLuaText('hitsText', 'Total Notes Hits: 0 / 0', 280, getProperty('comboText.x'), getProperty('comboText.y') + 30)
	setObjectCamera('hitsText', 'hud')
	setTextColor('hitsText', '0xffffff')
	setTextSize('hitsText', 20)
	setTextFont('hitsText', 'vcr.ttf')
	setTextAlignment('hitsText', 'center')
	addLuaText('hitsText')

	makeLuaText('miss', 'Misses: 0', 280, getProperty('hitsText.x'), getProperty('hitsText.y') + 30)
	setObjectCamera('miss', 'hud')
	setTextColor('miss', '0x36eaf7')
	setTextSize('miss', 20)
	setTextFont('miss', 'vcr.ttf')
	setTextAlignment('miss', 'center')
	setProperty('miss.alpha', 0.8)
	addLuaText('miss')

	setHudVisible(comboEnabled)
end

function onCreatePost()
	combo = 0
	maxComb = 0
	misses = 0
	totalHits = 0
	totalNotes = 0
	refreshComboEnabled()
	recountTotalNotes()
	setHudVisible(comboEnabled)
	updateTexts()
end

function onSongStart()
	-- Notes are fully generated here
	recountTotalNotes()
	updateTexts()
end

function onUpdate(elapsed)
	refreshComboEnabled()
	setHudVisible(comboEnabled)

	if not comboEnabled then
		return
	end

	if maxComb < combo then
		maxComb = combo
	end

	updateTexts()
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if not comboEnabled then
		return
	end

	if isSustainNote then
		return
	end

	combo = combo + 1
	totalHits = totalHits + 1
	if maxComb < combo then
		maxComb = combo
	end
	-- keep totalNotes >= totalHits
	if totalNotes < totalHits then
		totalNotes = totalHits
	end
	updateTexts()
end

function noteMiss(id, direction, noteType, isSustainNote)
	if not comboEnabled then
		return
	end

	combo = 0
	misses = misses + 1
	updateTexts()
end

function onEvent(name, value1, value2)
	if name == 'Toggle Combo HUD' or name == 'ToggleComboHUD' then
		local v = tostring(value1 or ''):lower()
		if v == '0' or v == 'false' or v == 'off' then
			comboEnabled = false
		elseif v == '1' or v == 'true' or v == 'on' then
			comboEnabled = true
		else
			comboEnabled = not comboEnabled
		end
		setHudVisible(comboEnabled)
		updateTexts()
	end
end
