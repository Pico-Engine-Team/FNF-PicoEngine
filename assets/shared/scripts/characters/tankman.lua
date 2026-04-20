-- script By Lucas Sanches

function onCreatePost()
    for i = 0, getProperty('opponentStrums.length') - 1 do
        setPropertyFromGroup('opponentStrums', i, 'texture', 'noteSkins/data/characters/tankman/Tankman-Notes')
        setPropertyFromGroup('opponentStrums', i, 'useRGBShader', false)
    end
end
function onSpawnNote(i, noteData, noteType, isSustainNote)
    if not getPropertyFromGroup('notes', i, 'mustPress') then
        setPropertyFromGroup('notes', i, 'texture', 'noteSkins/data/characters/tankman/Tankman-Notes')
        setPropertyFromGroup('notes', i, 'useRGBShader', false)
    end
end