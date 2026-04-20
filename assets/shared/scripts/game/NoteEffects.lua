local holdAnims = {'singLEFT-hold', 'singDOWN-hold', 'singUP-hold', 'singRIGHT-hold'}

function onCreatePost()
    for i = 0, getProperty('unspawnNotes.length') - 1 do
        if getPropertyFromGroup('unspawnNotes', i, 'isSustainNote') then
            setPropertyFromGroup('unspawnNotes', i, 'noAnimation', true)
        end
    end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
    if isSustainNote then
        handleHoldAnim('boyfriend', direction, id, noteType)
    end
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    if isSustainNote then
        local char = 'dad'
        if getPropertyFromGroup('notes', id, 'gfNote') or noteType == 'GF Sing' then
            char = 'gf'
        end
        handleHoldAnim(char, direction, id, noteType)
    end
end

-- Função genérica para lidar com a animação e o loop manual
function handleHoldAnim(char, dir, id, noteType)
    if getPropertyFromGroup('notes', id, 'gfNote') or noteType == 'GF Sing' then
        char = 'gf'
    end

    local anim = holdAnims[dir + 1]
    
    -- Se a animação acabou ou não está tocando a de hold, força o início/loop
    if getProperty(char .. '.animation.curAnim.finished') or getProperty(char .. '.animation.curAnim.name') ~= anim then
        playAnim(char, anim, true)
    end
    
    setProperty(char .. '.holdTimer', 0)
end