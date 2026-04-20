function onCreatePost()
    for i = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', i, 'texture', 'noteSkins/data/characters/pico/Pico-Notes')
        setPropertyFromGroup('playerStrums', i, 'useRGBShader', false)
    end
    setProperty('playerStrums.useNoteSplash', true)
end
function onSpawnNote(i, noteData, noteType, isSustainNote)
     if getPropertyFromGroup('notes', i, 'mustPress') then
        setPropertyFromGroup('notes', i, 'texture', 'noteSkins/data/characters/pico/Pico-Notes')
        setPropertyFromGroup('notes', i, 'useRGBShader', false)
    end
end