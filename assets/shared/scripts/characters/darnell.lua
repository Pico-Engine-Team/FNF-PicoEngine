local skinPath = 'noteSkins/data/characters/darnell/Darnell-Notes'

function onCreatePost()
    for i = 0, getProperty('playerStrums.length') - 1 do
        setPropertyFromGroup('playerStrums', i, 'texture', skinPath)
        setPropertyFromGroup('playerStrums', i, 'useRGBShader', false)
    end
end

function onSpawnNote(id, noteData, noteType, isSustainNote)
    if getPropertyFromGroup('notes', id, 'mustPress') then
        if noteType == '' or noteType == 'Default Note' then
            setPropertyFromGroup('notes', id, 'texture', skinPath)
            setPropertyFromGroup('notes', id, 'useRGBShader', false)
        end
    end
end