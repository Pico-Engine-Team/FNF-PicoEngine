-- Script by NEOVERS
-- Modified by Pico Engine Team
-- CreditsState-style icon and background color support

local songName         = 'All Hail The King'
local originalComposer = 'Hooda'
local coverCreator     = 'Cover: ?'
local codeCreator      = 'Code: ?'

-- Use an image from images/credits, just like CreditsState.hx.
-- Example: credits/psychEngine/shadowmario
local iconCreditsPath = 'credits/picoEngine/default/missing_icon'
local iconScale       = 0.65

-- Hex color without #. You can also call changeCreditBGColor('RRGGBB', duration).
local creditBGColor = 'F9393F'
local creditBGAlpha = 0.75

local offsetY     = 200
local fadeInTime  = 1
local stayTime    = 3
local slideTime   = 1.2
local appearStep  = 128
local hasAppeared = false

local startX      = -440
local centerX     = 0
local panelWidth  = 420
local bgHeight    = 140
local iconSize    = 100
local textXOffset = 100

local function normalizeImagePath(path)
    path = path or ''
    path = string.gsub(path, '^images/', '')
    path = string.gsub(path, '%.png$', '')
    return path
end

local function resolveIconCredits(path)
    path = normalizeImagePath(path)
    if path ~= '' and checkFileExists('images/' .. path .. '.png') then
        return path
    end
    return 'credits/picoEngine/default/missing_icon'
end

function changeCreditBGColor(color, duration)
    color = string.gsub(color or creditBGColor, '#', '')
    creditBGColor = color
    duration = tonumber(duration) or 0

    if duration > 0 then
        doTweenColor('creditBGColorTween', 'creditBG', color, duration, 'sineInOut')
    else
        setProperty('creditBG.color', getColorFromHex(color))
    end
end

function onCreate()
    callOnScripts('setDisplayNameSongs', {songName, originalComposer})

    makeLuaSprite('creditBG', '', startX, 30 + offsetY)
    makeGraphic('creditBG', panelWidth, bgHeight, 'FFFFFF')
    setProperty('creditBG.color', getColorFromHex(creditBGColor))
    setProperty('creditBG.alpha', creditBGAlpha)
    setObjectCamera('creditBG', 'camHud')
    addLuaSprite('creditBG', true)

    local iconX = startX + 12
    local iconY = 30 + offsetY + (bgHeight - iconSize * iconScale) / 2
    makeLuaSprite('IconCredits', resolveIconCredits(iconCreditsPath), iconX, iconY)
    scaleObject('IconCredits', iconScale, iconScale)
    setProperty('IconCredits.antialiasing', true)
    setObjectCamera('IconCredits', 'camHud')
    addLuaSprite('IconCredits', true)

    local textWidth = panelWidth - textXOffset - 10
    local textStartX = startX + textXOffset

    makeLuaText('songNameText', songName, textWidth, textStartX, 40 + offsetY)
    setTextSize('songNameText', 24)
    setTextColor('songNameText', 'FFFFFF')
    setTextAlignment('songNameText', 'left')
    setObjectCamera('songNameText', 'camHud')
    addLuaText('songNameText', true)

    makeLuaText('composerText', 'Original: ' .. originalComposer, textWidth, textStartX, 72 + offsetY)
    setTextSize('composerText', 18)
    setTextColor('composerText', 'FFFFFF')
    setTextAlignment('composerText', 'left')
    setObjectCamera('composerText', 'camHud')
    addLuaText('composerText', true)

    makeLuaText('creatorText', coverCreator .. ' | ' .. codeCreator, textWidth, textStartX, 98 + offsetY)
    setTextSize('creatorText', 16)
    setTextColor('creatorText', 'FFFFFF')
    setTextAlignment('creatorText', 'left')
    setObjectCamera('creatorText', 'camHud')
    addLuaText('creatorText', true)
end

function onStepHit()
    if curStep == appearStep and not hasAppeared then
        hasAppeared = true

        doTweenX('bgSlideIn', 'creditBG', centerX, fadeInTime, 'sineOut')
        doTweenX('iconSlideIn', 'IconCredits', centerX + 12, fadeInTime, 'sineOut')
        doTweenX('songSlideIn', 'songNameText', centerX + textXOffset, fadeInTime, 'sineOut')
        doTweenX('compSlideIn', 'composerText', centerX + textXOffset, fadeInTime, 'sineOut')
        doTweenX('creatorSlideIn', 'creatorText', centerX + textXOffset, fadeInTime, 'sineOut')

        runTimer('slideAway', fadeInTime + stayTime)
    end
end

function onTimerCompleted(tag)
    if tag == 'slideAway' then
        doTweenX('bgSlideOut', 'creditBG', startX, slideTime, 'sineIn')
        doTweenX('iconSlideOut', 'IconCredits', startX + 12, slideTime, 'sineIn')
        doTweenX('songSlideOut', 'songNameText', startX + textXOffset, slideTime, 'sineIn')
        doTweenX('compSlideOut', 'composerText', startX + textXOffset, slideTime, 'sineIn')
        doTweenX('creatorSlideOut', 'creatorText', startX + textXOffset, slideTime, 'sineIn')
    end
end
