function onEvent(name,v1,v2)
    if name == 'Triggers Spookeez' then
        if v1 == '1' and not hideHud then
            triggerEvent('Play Animation','hey','bf')
        end
        if v1 == '2' and not hideHud then
            triggerEvent('Play Animation','hey-alt','bf')
        end
    end
end