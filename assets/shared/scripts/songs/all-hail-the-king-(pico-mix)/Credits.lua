-- Script By NEOVERS
-- Modified By Pico Engine Team
-- Icon support added

local songName         = "All Hail The King"
local originalComposer = "Hooda"
local coverCreator     = "Cover: ?"
local codeCreator      = "Code: ?"
local iconName         = "face"       -- Nome do healthicon (ex: bf, pico, face, tankman)
local iconScale        = 0.5          -- Tamanho do ícone (1 = tamanho original)

local offsetY      = 200
local fadeInTime   = 1
local stayTime     = 3
local slideTime    = 1.2
local appearStep   = 128
local hasAppeared  = false
local startX       = -420
local centerX      = 0

local bgHeight     = 140
local iconSize     = 150

function onCreate()
    makeLuaSprite('creditBG', '', startX, 30 + offsetY)
    makeGraphic('creditBG', 400, bgHeight, '000000')
    setProperty('creditBG.alpha', 0.6)
    setObjectCamera('creditBG', 'hud')
    addLuaSprite('creditBG', true)

    local iconX = startX + (400 / 2) - (iconSize * iconScale / 2)
    local iconY = 30 + offsetY - (iconSize * iconScale) + 10
    makeLuaSprite('creditIcon', 'icons/icon-' .. iconName, iconX, iconY)
    setProperty('creditIcon.scale.x', iconScale)
    setProperty('creditIcon.scale.y', iconScale)
    setProperty('creditIcon.antialiasing', true)
    setObjectCamera('creditIcon', 'hud')
    addLuaSprite('creditIcon', true)

    makeLuaText('songNameText', songName, 400, startX + 10, 40 + offsetY)
    setTextSize('songNameText', 24)
    setTextColor('songNameText', 'FFFFFF')
    setTextAlignment('songNameText', 'center')
    setObjectCamera('songNameText', 'hud')
    addLuaText('songNameText', true)

    makeLuaText('composerText', "Original: " .. originalComposer, 400, startX + 10, 72 + offsetY)
    setTextSize('composerText', 18)
    setTextColor('composerText', 'AAAAAA')
    setTextAlignment('composerText', 'center')
    setObjectCamera('composerText', 'hud')
    addLuaText('composerText', true)

    makeLuaText('creatorText', coverCreator .. " | " .. codeCreator, 400, startX + 10, 98 + offsetY)
    setTextSize('creatorText', 16)
    setTextColor('creatorText', 'AAAAAA')
    setTextAlignment('creatorText', 'center')
    setObjectCamera('creatorText', 'hud')
    addLuaText('creatorText', true)
end

function onStepHit()
    if curStep == appearStep and not hasAppeared then
        hasAppeared = true

        local iconCenterX = centerX + (400 / 2) - (iconSize * iconScale / 2)

        doTweenX('bgSlideIn',      'creditBG',     centerX,        fadeInTime, 'sineOut')
        doTweenX('iconSlideIn',    'creditIcon',   iconCenterX,    fadeInTime, 'sineOut')
        doTweenX('songSlideIn',    'songNameText', centerX + 10,   fadeInTime, 'sineOut')
        doTweenX('compSlideIn',    'composerText', centerX + 10,   fadeInTime, 'sineOut')
        doTweenX('creatorSlideIn', 'creatorText',  centerX + 10,   fadeInTime, 'sineOut')

        runTimer('slideAway', fadeInTime + stayTime)
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'slideAway' then
        local iconStartX = startX + (400 / 2) - (iconSize * iconScale / 2)

        doTweenX('bgSlideOut',      'creditBG',     startX,       slideTime, 'sineIn')
        doTweenX('iconSlideOut',    'creditIcon',   iconStartX,   slideTime, 'sineIn')
        doTweenX('songSlideOut',    'songNameText', startX + 10,  slideTime, 'sineIn')
        doTweenX('compSlideOut',    'composerText', startX + 10,  slideTime, 'sineIn')
        doTweenX('creatorSlideOut', 'creatorText',  startX + 10,  slideTime, 'sineIn')
    end
end
