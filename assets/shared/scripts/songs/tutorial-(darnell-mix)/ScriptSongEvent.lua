function onCreate()
    addCharacterToList('darnell-playable','bf')
    addCharacterToList('nene-opponent','dad')
    addCharacterToList('pico-speaker','gf')
end
function onCreatePost()
    if not hideHud then
        addLuaScript('Game/extra/extraIcon')
        extraIcon('addExtraIcon',{'gfIcon'})
        setProperty('gfIcon.offset.x',-15)
        setProperty('gfIcon.offset.y',not downscroll and -500 or 500)
    end
    setProperty('gf.x',290)
    setProperty('gf.y',75)
end
function extraIcon(func,vars)
    callScript('Game/extra/extraIcon',func,vars)
end
function onSectionHit()
    if curSection == 8 and not hideHud then
        doTweenY('gfIconY','gfIcon.offset',0,2,'cubeOut')
    end
end
function onEvent(name,v1,v2)
    if name == 'Triggers Tutorial (Darnell Mix)' then
        if v1 == '1' and not hideHud then
            callScript('Game/extra/extraIcon','setIconProperty',{'gfIcon','followAlpha',false})
            doTweenAlpha('gfIconAlpha','gfIcon',0,2,'cubeIn')
            setProperty('gfIcon.alpha',0)
            triggerEvent('Change Character','gf','pico-speaker')
        end
        if v1 == '2' and not hideHud then
            triggerEvent('Play Animation','hey','dad')
        end
        if v1 == '3' and not hideHud then
            triggerEvent('Play Animation','hey','bf')
            triggerEvent('Play Animation','hey','gf')
            triggerEvent('Play Animation','hey','dad')
        end
    end
end