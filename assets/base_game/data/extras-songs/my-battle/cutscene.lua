local allowCountdown = false
local makingdecision = false
local addnene = getModSetting("AddNene")

function onCreatePost()
    precacheSound("picosmoke")
    precacheSound("picoooh")
    precacheSound("picoGasp")
end

function onStartCountdown()
    if not allowCountdown then
		if isStoryMode then
			addCharacterToList('pico-doppelganger', 'boyfriend');
			setPropertyFromClass('flixel.FlxG', 'mouse.visible', false)
			setProperty('dad.alpha', 1)
			doTweenAlpha('heyeyey', 'camHUD', 0, 0.01, 'linear')
			-- setProperty('gf.visible', false)
			runTimer('camerapico', 0.01)
			runTimer('picosmoke', 0.5)
			runTimer('picoooh', 4)
			return Function_Stop
		else
			allowCountdown = true
		end
    else
        return Function_Continue
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'camerapico' then
        setProperty('cameraSpeed', 100)
        triggerEvent('Camera Follow Pos', 1200, 600)
        setProperty('camera.zoom', 1.5)
        playSound('picosmoke', 1)
        setProperty('boyfriend.animation.curAnim.curFrame', 0)
        runTimer('picocome', 200)
    end
    if tag == 'picosmoke' then
        triggerEvent('Change Character', 'BF', 'pico-doppelganger')
        playAnim('boyfriend', 'casilomatannerves', true)
    end
    if tag == 'picoooh' then
        playAnim('boyfriend', 'disparaooh', true)
        playSound('picoooh', 1)
        runTimer('cameratotabi', 1)
        setProperty('cameraSpeed', 1.3)
    end
    if tag == 'cameratotabi' then
        triggerEvent('Camera Follow Pos', 500, 500)
        doTweenZoom('zoomIn', 'camGame', 0.8, 1, 'sineInOut')
        runTimer('tabizoomin', 2)
    end
    if tag == 'tabizoomin' then
        doTweenZoom('zoomIn', 'camGame', 1.5, 0.01, 'sineInOut')
        setProperty('cameraSpeed', 100)
        triggerEvent('Camera Follow Pos', 300, 400)
        runTimer('cameratopicoman', 1.5)
    end
    if tag == 'getout' then
        runTimer('cameratopicoman', 1.5)
        setProperty('cameraSpeed', 100)
    end
    if tag == 'cameratopicoman' then
        triggerEvent('Camera Follow Pos', 1200, 600)
        runTimer('decisiontime', 2)
    end
    if tag == 'decisiontime' then
        setProperty('cameraSpeed', 1.1)
        makeLuaSprite('rap', 'tabi/decision/rap', 0, 150)
        setObjectOrder('rap', 5)
        addLuaSprite('rap', true)
        setProperty('rap.alpha', 0)
        setObjectCamera('rap', 'other')
        setProperty('rap.scale.x', 0.6)
        setProperty('rap.scale.y', 0.6)
        doTweenAlpha('rap', 'rap', 1, 1, 'linear')

        makeLuaSprite('leave', 'tabi/decision/leave', 500, 100)
        setObjectOrder('leave', 5)
        addLuaSprite('leave', true)
        setProperty('leave.alpha', 0)
        setObjectCamera('leave', 'other')
        setProperty('leave.scale.x', 0.6)
        setProperty('leave.scale.y', 0.6)
        doTweenAlpha('leave', 'leave', 1, 1, 'linear')

        makeLuaSprite('viggenete', 'tabi/decision/viggnete', 0, 0)
        setGraphicSize('viggenete', 1286, 730)
        setObjectCamera('viggenete', 'other')
        setProperty('viggenete.alpha', 0)
        setObjectOrder('viggenete', 4)
        doTweenAlpha('viggenete', 'viggenete', 1, 1, 'linear')
        addLuaSprite('viggenete', true)
        setPropertyFromClass('flixel.FlxG', 'mouse.visible', true)

        makeLuaText('MakeDecision', 'MAKE YOUR DECISION', 1000, 150, 600)
        setTextSize('MakeDecision', 50)
        setTextFont('MakeDecision', 'fnfbelike.ttf')
        setObjectOrder('MakeDecision', 10);
        setProperty('MakeDecision.alpha', 0)
        doTweenAlpha('MakeDecision', 'MakeDecision', 1, 1, 'linear')
        addLuaText('MakeDecision')
        setObjectCamera('MakeDecision', 'other')

        makingdecision = true
        triggerEvent('Add Camera Zoom', nil, nil)
    end
    if tag == 'START' then
        setPropertyFromClass('flixel.FlxG', 'mouse.visible', false)
        allowCountdown = true
        startCountdown()
        doTweenAlpha('heyy', 'camHUD', 1, 1, 'linear')
        triggerEvent('Camera Follow Pos', nil, nil)
        playSound('clickText', 1)
        doTweenAlpha('rap', 'rap', 0, 1, 'linear')
        runTimer('byeblack', 0.2)
		if addnene then
			setProperty('gf.visible', true)
		end
        doTweenAlpha('leave', 'leave', 0, 1, 'linear')
        doTweenAlpha('viggenete', 'viggenete', 0, 1, 'linear')
        doTweenAlpha('MakeDecision', 'MakeDecision', 0, 1, 'linear')
    end
    if tag == 'leave' then
        setProperty('cameraSpeed', 1)
        triggerEvent('Camera Follow Pos', 1200, 600)
        doTweenAlpha('rap', 'rap', 0, 1, 'linear')
        doTweenAlpha('leave', 'leave', 0, 1, 'linear')
        doTweenAlpha('viggenete', 'viggenete', 0, 1, 'linear')
        doTweenAlpha('MakeDecision', 'MakeDecision', 0, 1, 'linear')
        runTimer('byebye', 1)
    end
    if tag == 'byebye' then
        playSound('bye', 1)
        doTweenAlpha('byepico', 'boyfriend', 0, 2.5, 'linear')
        runTimer('tabi', 3)
    end
    if tag == 'tabi' then
        triggerEvent('Camera Follow Pos', 400, 500)
        runTimer('endescape', 2)
        doTweenZoom('zoomIn', 'camGame', 0.9, 1, 'sineInOut')
    end
    if tag == 'endescape' then
        makeLuaSprite('LEAVEENDING', 'tabi/decision/LEAVEENDING', 0, 0)
        setGraphicSize('LEAVEENDING', 1286, 730)
        setObjectCamera('LEAVEENDING', 'other')
        setProperty('LEAVEENDING.alpha', 0)
        setObjectOrder('LEAVEENDING', 4)
        doTweenAlpha('LEAVEENDING', 'LEAVEENDING', 1, 0.01, 'linear')
        addLuaSprite('LEAVEENDING', true)
        setProperty('camera.zoom', 0.8)
        playSound('Crickets', 1)
        runTimer('leavegame', 3)
    end
    if tag == 'leavegame' then
        loadSong('', 'freeplay', true)
    end
    if tag == 'lol' then
        triggerEvent('Camera Follow Pos', 500, 500)
        runTimer('PICODANCE', 1.5)
    end
    if tag == 'PICODANCE' then
        triggerEvent('Camera Follow Pos', 1000, 600)
        doTweenAngle('picospin', 'boyfriend', 5000, 2, 'linear')
        runTimer('burp', 2)
    end
end

function onUpdate(elapsed)

    local mouseX = getMouseX()
    local mouseY = getMouseY()

    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.ESCAPE') then
        exitSong()
    end

    if getPropertyFromClass('flixel.FlxG', 'mouse.justPressed') then
        local leaveX = getProperty('leave.x')
        local leaveY = getProperty('leave.y')
        local leaveWidth = getProperty('leave.width')
        local leaveHeight = getProperty('leave.height')

        local rapX = getProperty('rap.x')
        local rapY = getProperty('rap.y')
        local rapWidth = getProperty('rap.width')
        local rapHeight = getProperty('rap.height')

        if mouseX >= leaveX and mouseX <= (leaveX + leaveWidth) and mouseY >= leaveY and mouseY <=
            (leaveY + leaveHeight) and makingdecision == true then
            runTimer('leave', 0.01)
            makingdecision = false
            setPropertyFromClass('flixel.FlxG', 'mouse.visible', false)
        elseif mouseX >= rapX and mouseX <= (rapX + rapWidth) and mouseY >= rapY and mouseY <= (rapY + rapHeight) and
            makingdecision == true then
            runTimer('START', 0.01)
            doTweenZoom('zoomIn', 'camGame', 1, 1, 'sineInOut')
            triggerEvent('Change Character', 'BF', 'picoall')
            makingdecision = false
        end
    end
end

function onDestroy()
    setPropertyFromClass('flixel.FlxG', 'mouse.visible', false)
end
