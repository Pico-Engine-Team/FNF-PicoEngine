local middlePositions = {412, 524, 636, 748}
local spinAngle = 360
local defaultDuration = 1.0
local easeType = 'expoOut'

function onEvent(name, value1, value2)
    if name ~= 'Middlescroll' then
        return
    end

    local target = normalizeTarget(value1)
    local duration = getDuration(value2)

    if target == 'player' then
        movePlayerToMiddle(duration)
    elseif target == 'opponent' then
        moveOpponentToMiddle(duration)
    elseif target == 'default' then
        resetStrums(duration)
    end
end

function normalizeTarget(value)
    if value == nil or value == '' then
        return 'default'
    end

    return string.lower(tostring(value))
end

function getDuration(value)
    local duration = tonumber(value)

    if duration == nil or duration < 0 then
        return defaultDuration
    end

    return duration
end

function movePlayerToMiddle(duration)
    for i = 0, 3 do
        local opponentNote = i
        local playerNote = i + 4

        prepareSpin(playerNote)
        noteTweenX('middlePlayerX'..i, playerNote, middlePositions[i + 1], duration, easeType)
        noteTweenAngle('middlePlayerSpin'..i, playerNote, spinAngle, duration, easeType)
        noteTweenAlpha('showPlayer'..i, playerNote, 1, duration, easeType)
        noteTweenAlpha('hideOpponent'..i, opponentNote, 0, duration, easeType)
    end
end

function moveOpponentToMiddle(duration)
    for i = 0, 3 do
        local opponentNote = i
        local playerNote = i + 4

        prepareSpin(opponentNote)
        noteTweenX('middleOpponentX'..i, opponentNote, middlePositions[i + 1], duration, easeType)
        noteTweenAngle('middleOpponentSpin'..i, opponentNote, spinAngle, duration, easeType)
        noteTweenAlpha('showOpponent'..i, opponentNote, 1, duration, easeType)
        noteTweenAlpha('hidePlayer'..i, playerNote, 0, duration, easeType)
    end
end

function resetStrums(duration)
    local defaultOpponentX = {
        defaultOpponentStrumX0,
        defaultOpponentStrumX1,
        defaultOpponentStrumX2,
        defaultOpponentStrumX3
    }

    local defaultPlayerX = {
        defaultPlayerStrumX0,
        defaultPlayerStrumX1,
        defaultPlayerStrumX2,
        defaultPlayerStrumX3
    }

    for i = 0, 3 do
        local opponentNote = i
        local playerNote = i + 4

        noteTweenX('resetOpponentX'..i, opponentNote, defaultOpponentX[i + 1], duration, easeType)
        noteTweenAngle('resetOpponentAngle'..i, opponentNote, 0, duration, easeType)
        noteTweenAlpha('resetOpponentAlpha'..i, opponentNote, 1, duration, easeType)

        noteTweenX('resetPlayerX'..i, playerNote, defaultPlayerX[i + 1], duration, easeType)
        noteTweenAngle('resetPlayerAngle'..i, playerNote, 0, duration, easeType)
        noteTweenAlpha('resetPlayerAlpha'..i, playerNote, 1, duration, easeType)
    end
end

function prepareSpin(noteIndex)
    setPropertyFromGroup('strumLineNotes', noteIndex, 'angle', 0)
end
