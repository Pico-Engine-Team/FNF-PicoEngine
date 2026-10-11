function onCreate()
    addLuaScript('Game/extra/extraCharacter')
    addCharacterToList('pico-err','gf')
end
function onCreatePost()
    if not hideHud then
        addLuaScript('Game/extra/extraIcon')
        extraIcon('addExtraIcon',{'gfIcon'})
        setProperty('gfIcon.offset.x',-15)
        setProperty('gfIcon.offset.y',not downscroll and -500 or 500)
    end
    setProperty('gf.x',810)
    setProperty('gf.y',1500)
end
function extraCharacter(func,vars)
    callScript('Game/extra/extraCharacter',func,vars)
end
function extraIcon(func,vars)
    callScript('Game/extra/extraIcon',func,vars)
end
function onSectionHit()
    if curSection == 46 and not hideHud then
        doTweenY('gfIconY','gfIcon.offset',0,2,'cubeOut')
    end
end
function onEvent(name,v1,v2)
    if name == 'Triggers Demonical Massacre' then
        if v1 == '0' and not hideHud then
            callScript('Game/extra/extraIcon','setIconProperty',{'gfIcon','followAlpha',false})
            doTweenAlpha('gfIconAlpha','gfIcon',0,2,'cubeIn')
            setProperty('gfIcon.alpha',0)
            triggerEvent('Change Character','gf','pico-err')
        end
    end
end