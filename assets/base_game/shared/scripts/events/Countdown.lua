local eventName = 'Countdown'
local timerTag = 'countdownEventTimer'
local spriteTag = 'countdownEventSprite'
local countdownStep = 0
local countdownStyle = 'funkin'
local countdownInterval = 0.5

local function normalizeStyle(value)
	if value ~= nil and string.lower(value) == 'pixel' then
		return 'pixel'
	end
	return 'funkin'
end

local function imageForStep(step)
	if countdownStyle == 'pixel' then
		if step == 1 then return 'ui/countdown/pixel/ready-pixel' end
		if step == 2 then return 'ui/countdown/pixel/set-pixel' end
		return 'ui/countdown/pixel/date-pixel'
	end

	if step == 1 then return 'ui/countdown/funkin/ready' end
	if step == 2 then return 'ui/countdown/funkin/set' end
	return 'ui/countdown/funkin/go'
end

local function soundForStep(step)
	local suffix = countdownStyle == 'pixel' and '-pixel' or ''
	if step == 0 then return 'intro3' .. suffix end
	if step == 1 then return 'intro2' .. suffix end
	if step == 2 then return 'intro1' .. suffix end
	return 'introGo' .. suffix
end

local function removeCountdownSprite()
	if luaSpriteExists(spriteTag) then
		removeLuaSprite(spriteTag, true)
	end
end

local function showCountdownStep(step)
	playSound(soundForStep(step), 0.6)
	if step == 0 then return end

	removeCountdownSprite()
	makeLuaSprite(spriteTag, imageForStep(step), 0, 0)
	setObjectCamera(spriteTag, 'camHud')
	screenCenter(spriteTag)
	setProperty(spriteTag .. '.alpha', 1)

	if countdownStyle == 'pixel' then
		setProperty(spriteTag .. '.antialiasing', false)
		scaleObject(spriteTag, 6, 6)
		screenCenter(spriteTag)
	end

	addLuaSprite(spriteTag, true)
	doTweenAlpha('countdownEventFade', spriteTag, 0, countdownInterval, 'cubeInOut')
end

function onCreate()
	precacheImage('ui/countdown/funkin/ready')
	precacheImage('ui/countdown/funkin/set')
	precacheImage('ui/countdown/funkin/go')
	precacheImage('ui/countdown/pixel/ready-pixel')
	precacheImage('ui/countdown/pixel/set-pixel')
	precacheImage('ui/countdown/pixel/date-pixel')

	precacheSound('intro3')
	precacheSound('intro2')
	precacheSound('intro1')
	precacheSound('introGo')
	precacheSound('intro3-pixel')
	precacheSound('intro2-pixel')
	precacheSound('intro1-pixel')
	precacheSound('introGo-pixel')
end

function onEvent(name, value1, value2)
	if name ~= eventName then return end

	countdownStyle = normalizeStyle(value1)
	countdownInterval = tonumber(value2)
	if countdownInterval == nil or countdownInterval <= 0 then
		countdownInterval = crochet / 1000
	end
	if playbackRate ~= nil and playbackRate > 0 then
		countdownInterval = countdownInterval / playbackRate
	end

	cancelTimer(timerTag)
	cancelTween('countdownEventFade')
	removeCountdownSprite()

	countdownStep = 0
	showCountdownStep(countdownStep)
	runTimer(timerTag, countdownInterval, 3)
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag ~= timerTag then return end

	countdownStep = countdownStep + 1
	showCountdownStep(countdownStep)
end

function onTweenCompleted(tag)
	if tag == 'countdownEventFade' then
		removeCountdownSprite()
	end
end

function onDestroy()
	cancelTimer(timerTag)
	removeCountdownSprite()
end
