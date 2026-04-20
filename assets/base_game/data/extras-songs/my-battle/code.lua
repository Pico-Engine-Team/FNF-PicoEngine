function onEvent(name, value1, value2)
    if name == 'Play Animation' then
        if value1 == '1' then
		    doTweenAlpha('byehud', 'camHUD', 0, 0.01, 'linear')
        end
		if value1 == '2' then
			doTweenAlpha('heyhud', 'camHUD', 1, 1, 'linear')
        end
    end
end