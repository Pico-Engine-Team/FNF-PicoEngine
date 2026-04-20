
--ACT START LITE MADE BY SNAKYJOEL

	local allowCountdown = false
function onStartCountdown()
	if not allowCountdown then
		runTimer('startText', 0);
		allowCountdown = true;
		startCountdown();
		return Function_Stop;
	end
	return Function_Continue;
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'startText' then
		---BG
		makeLuaSprite('blackscreen', '', 0, 0)
		makeGraphic('blackscreen',1300,750,'000000')
		setObjectCamera('blackscreen', 'other');
		addLuaSprite('blackscreen', true)
		--CIRCLE
		makeLuaSprite('circle', 'scripts/images/exe/Act/ActLite/template', 777, 0);
		setObjectCamera('circle', 'other');
		doTweenColor('circleColorTween', 'circle', '3045D7', 0.01, 'linear')
		addLuaSprite('circle', true);
		--TEXT BACK
		makeLuaText("titlecardback", 'ENDLESS', 1000 , -994, 305);
		setTextAlignment('titlecardback', 'right');
		scaleObject('titlecardback', 1, 1.2)
		setTextFont('titlecardback', 'ACT.ttf');
		setTextSize('titlecardback', 110);
		setObjectCamera('titlecardback', 'other');
		setTextBorder('titlecardback', 0, '0x0')
		doTweenColor('titlecardback', 'titlecardback', '000000', 0.01, 'linear')
		addLuaText("titlecardback")
		--TEXT
		makeLuaText("titlecard", 'ENDLESS', 1000 , -1000, 300);
		setTextAlignment('titlecard', 'right');
		scaleObject('titlecard', 1, 1.2)
		setTextFont('titlecard', 'ACT.ttf');
		setTextSize('titlecard', 110);
		setObjectCamera('titlecard', 'other');
		setTextBorder('titlecard', 0, '0x0')
		addLuaText("titlecard")
		--ENCORE BACK
		makeLuaText("ENCOREB", '(Pico Mix)', 1000 , 360, 164);
		scaleObject('ENCOREB', 1, 1.1)
		setTextFont('ENCOREB', 'ACT.ttf');
		setTextSize('ENCOREB', 80);
		setObjectCamera('ENCOREB', 'other');
		setTextBorder('ENCOREB', 0, '0x0')
		doTweenColor('ENCOREB', 'ENCOREB', '000000', 0.01, 'linear')
		setProperty('ENCOREB.angle', 90)
		--addLuaText('ENCOREB')
		--ENCORE
		makeLuaText("ENCORE", '(Pico Mix)', 1000 , 360, 170);
		scaleObject('ENCORE', 1, 1.1)
		setTextFont('ENCORE', 'ACT.ttf');
		setTextSize('ENCORE', 80);
		setObjectCamera('ENCORE', 'other');
		setTextBorder('ENCORE', 0, '0x0')
		doTweenColor('ENCORE', 'ENCORE', 'ffea00', 0.01, 'linear')
		setProperty('ENCORE.angle', 90)
		--addLuaText('ENCORE')

		--RUN TIMERS AND TWEENS (DO NOT TOUCH)
		runTimer('appear', 0.2, 1);
		runTimer('fadeout', 2.2, 2);
	elseif tag == 'appear' then
		--CIRCLE
		doTweenX('circletween', 'circle', 0, 0.5, 'CubeOut');
		--TEXT
		doTweenX('titlecardback', 'titlecardback', -184, 0.5, 'CubeOut');
		doTweenX('titlecard', 'titlecard', -190, 0.5, 'CubeOut');
		--ENCORE
		doTweenY('ENCOREB', 'ENCOREB', 325, 0.5, 'CubeOut');
		doTweenY('ENCORE', 'ENCORE', 320, 0.5, 'CubeOut');
	elseif tag == 'fadeout' then
		--CIRCLE
		doTweenAlpha('circlefade', 'circle', 0, 0.5, 'linear');
		--BG
		doTweenAlpha('blackfade', 'blackscreen', 0, 0.5, 'linear');
		--TEXT
		doTweenAlpha('titlecardbackfade', 'titlecardback', 0, 0.5, 'linear');
		doTweenAlpha('titlecardfade', 'titlecard', 0, 0.5, 'linear');
		--ENCORE
		doTweenAlpha('ENCOREB', 'ENCOREB', 0, 0.5, 'linear');
		doTweenAlpha('ENCORE', 'ENCORE', 0, 0.5, 'linear');
	end
end