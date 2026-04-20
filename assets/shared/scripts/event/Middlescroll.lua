function onEvent(name, value1, value2)
    if name == 'Middlescroll' then
        local duration = tonumber(value2)
        if value2 == '' or duration == nil then
            duration = 1.0
        end

        local target = tostring(value1):lower()
        local middlePositions = {412, 524, 636, 748}

        -- Tabela com as posições padrão de cada nota (opponent e player)
        local defaultOppX   = {defaultOpponentStrumX0, defaultOpponentStrumX1, defaultOpponentStrumX2, defaultOpponentStrumX3}
        local defaultPlayerX = {defaultPlayerStrumX0,  defaultPlayerStrumX1,  defaultPlayerStrumX2,  defaultPlayerStrumX3}

        if target == 'player' then
            for i = 0, 3 do
                noteTweenX('movePlayer'..i, i + 4, middlePositions[i+1], duration, 'expoOut')
                noteTweenAlpha('hideOpp'..i, i, 0, duration, 'expoOut')
            end

        elseif target == 'opponent' then
            for i = 0, 3 do
                noteTweenX('moveOpp'..i, i, middlePositions[i+1], duration, 'expoOut')
                noteTweenAlpha('hidePlayer'..i, i + 4, 0, duration, 'expoOut')
            end

        elseif target == 'default' then
            for i = 0, 3 do
                -- Opponent volta para a posição exata de cada nota
                noteTweenX('backOpp'..i,    i,     defaultOppX[i+1],    duration, 'expoOut')
                noteTweenAlpha('showOpp'..i, i,    1,                   duration, 'expoOut')

                -- Player volta para a posição exata de cada nota
                noteTweenX('backPlayer'..i,    i + 4, defaultPlayerX[i+1], duration, 'expoOut')
                noteTweenAlpha('showPlayer'..i, i + 4, 1,                  duration, 'expoOut')
            end
        end
    end
end