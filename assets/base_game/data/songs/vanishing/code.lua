function onCreate()
addCharacterToList('jerryangry','dad')
addCharacterToList('picododge', 'boyfriend');
precacheImage('noteSplashes/jerrynoteSplashes')
precacheSound('BURP')
end

function onEvent(name, value1, value2)
    if name == 'Play Animation' then
        if value1 == '1' then
		doTweenAlpha('byehud', 'camHUD', 0, 1, 'linear')
        end
		if value1 == '2' then
		doTweenAlpha('heyhud', 'camHUD', 1, 0.5, 'linear')
        end
    end
end