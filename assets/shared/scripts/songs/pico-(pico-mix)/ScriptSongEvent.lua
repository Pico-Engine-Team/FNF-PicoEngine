function onEvent(name,v1,v2)
    if name == 'Triggers Pico (Pico Mix)' then
        if v1 == '1' and not hideHud then
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