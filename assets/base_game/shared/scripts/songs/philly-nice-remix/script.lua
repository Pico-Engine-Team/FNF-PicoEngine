local EXTRA_CHARACTER_SCRIPT = 'game/extra/extraCharacter'
local EXTRA_ICON_SCRIPT = 'game/extra/extraIcon'

local neneTag = 'neneExtra'
local darnellTag = 'darnellExtra'
local singAnims = {'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'}

function onCreate()
	if not isRunning(EXTRA_CHARACTER_SCRIPT) then
		addLuaScript(EXTRA_CHARACTER_SCRIPT)
	end
	if not isRunning(EXTRA_ICON_SCRIPT) then
		addLuaScript(EXTRA_ICON_SCRIPT)
	end
end

function onCreatePost()
	extraCharacter(neneTag, 'nene-dot', 325, 702, false)
	extraCharacter(darnellTag, 'darnell-dot', 830, 703, false)

	extraIcon('neneExtraIcon', 'nene', false, true)
	extraIcon('darnellExtraIcon', 'darnell', false, true)

	callScript(EXTRA_ICON_SCRIPT, 'setIconProperty', {'neneExtraIcon', 'scale', 0.85})
	callScript(EXTRA_ICON_SCRIPT, 'setIconProperty', {'darnellExtraIcon', 'scale', 0.85})
	callScript(EXTRA_ICON_SCRIPT, 'setIconProperty', {'neneExtraIcon', 'lerpSpeed', 0.2})
	callScript(EXTRA_ICON_SCRIPT, 'setIconProperty', {'darnellExtraIcon', 'lerpSpeed', 0.2})
end

function extraCharacter(tag, character, x, y, isPlayer)
	callScript(EXTRA_CHARACTER_SCRIPT, 'createCharacter', {tag, character, x, y, isPlayer == true, false})
	setProperty(tag..'.visible', true)
end

function extraIcon(tag, icon, isPlayer, addBehind)
	callScript(EXTRA_ICON_SCRIPT, 'addExtraIcon', {tag, icon, isPlayer == true, addBehind ~= false})
end

function playPhillyExtraBySide(isPlayer, direction, isSustainNote)
	if isSustainNote then return end

	local tag = isPlayer and neneTag or darnellTag
	playPhillyExtra(tag, direction)
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if noteType == 'GF Sing' then
		playPhillyExtraBySide(true, direction, isSustainNote)
	end
end

function playPhillyExtra(tag, direction)
	local anim = singAnims[(direction or 0) + 1] or 'idle'
	if getProperty(tag..'.animation.curAnim') ~= nil then
		playAnim(tag, anim, true)
	end
end

function onBeatHit()
	danceExtraIfIdle(neneTag)
	danceExtraIfIdle(darnellTag)
end

function danceExtraIfIdle(tag)
	runHaxeCode([[
		var char = getVar("]]..tag..[[");
		if(char != null && !char.specialAnim && char.holdTimer == 0 && char.animation != null && char.animation.curAnim != null && !StringTools.startsWith(char.animation.curAnim.name, "sing")){
			char.dance();
		}
	]])
end
