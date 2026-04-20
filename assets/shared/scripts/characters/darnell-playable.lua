function onCreatePost()
    for i = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', i, 'texture', 'noteSkins/data/characters/darnell/Darnell-Notes')
        setPropertyFromGroup('playerStrums', i, 'useRGBShader', false)
    end
    setProperty('playerStrums.useNoteSplash', true)
end
function onSpawnNote(i, noteData, noteType, isSustainNote)
     if getPropertyFromGroup('notes', i, 'mustPress') then
        setPropertyFromGroup('notes', i, 'texture', 'noteSkins/data/characters/darnell/Darnell-Notes')
        setPropertyFromGroup('notes', i, 'useRGBShader', false)
    end
end

function onCreate()
    local gameOverSound = getPropertyFromClass('PlayState', 'SONG.gameOverSound') or ''
    local gameOverLoop = getPropertyFromClass('PlayState', 'SONG.gameOverLoop') or ''
    local gameOverEnd = getPropertyFromClass('PlayState', 'SONG.gameOverEnd') or ''
    local gameOverChar = getPropertyFromClass('PlayState', 'SONG.gameOverChar') or ''

    setPropertyFromClass('GameOverSubstate', 'characterName', gameOverChar ~= '' and gameOverChar or 'darnell-dead')
    setPropertyFromClass('GameOverSubstate', 'deathSoundName', gameOverSound ~= '' and gameOverSound or 'gameOver')
    setPropertyFromClass('GameOverSubstate', 'loopSoundName', gameOverLoop ~= '' and gameOverLoop or 'gameOver')
    setPropertyFromClass('GameOverSubstate', 'endSoundName', gameOverEnd ~= '' and gameOverEnd or 'gameOverEnd')
end