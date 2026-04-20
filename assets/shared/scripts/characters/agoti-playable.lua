function onCreatePost()
    for i = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', i, 'texture', 'noteSkins/data/characters/NOTE_assets-entity')
        setPropertyFromGroup('playerStrums', i, 'useRGBShader', true)
    end
end
function onSpawnNote(i, noteData, noteType, isSustainNote)
     if getPropertyFromGroup('notes', i, 'mustPress') then
        setPropertyFromGroup('notes', i, 'texture', 'noteSkins/data/characters/NOTE_assets-entity')
        setPropertyFromGroup('notes', i, 'useRGBShader', true)
    end
end