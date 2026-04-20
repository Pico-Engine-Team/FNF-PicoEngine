-- script By Lucas sanches
function onCreatePost()
    if songName == 'Tutorial' then
        for i = 0, getProperty('opponentStrums.length') - 1 do
            setPropertyFromGroup('opponentStrums', i, 'texture', 'noteSkins/data/characters/gf/GF-Notes')
            setPropertyFromGroup('opponentStrums', i, 'useRGBShader', false)
        end
    end
end
function onSpawnNote(i, noteData, noteType, isSustainNote)
    if songName == 'Tutorial' then
        if not getPropertyFromGroup('notes', i, 'mustPress') then
            setPropertyFromGroup('notes', i, 'texture', 'noteSkins/data/characters/gf/GF-Notes')
            setPropertyFromGroup('notes', i, 'useRGBShader', false)
        end
    end
end