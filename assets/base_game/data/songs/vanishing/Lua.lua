local allowCountdown = false

function onCreate()
  makeAnimatedLuaSprite('start', 'mobilebuttons/virtualbuttons', 0, 582.5);
  addAnimationByPrefix('start', 'anonPress', 'anonPress', 24, false);
  addAnimationByPrefix('start', 'aPressed', 'aPressed', 12, false);
  setObjectOrder('start', 10000)
  addLuaSprite('start', true);
  setObjectCamera('start', 'other');
  
  makeLuaSprite('blackScreenn', 'nil', 0, 0)
  setObjectOrder('blackScreenn', 8);
  makeGraphic('blackScreenn', screenWidth, screenHeight, '000000')
  addLuaSprite('blackScreenn', true)
  setProperty('blackScreenn.alpha', 1)
  setObjectCamera('blackScreenn', 'other')
  
  makeLuaSprite('warning', 'warning', 0, 0)
  local screenW = getPropertyFromClass('flixel.FlxG', 'width')
  local screenH = getPropertyFromClass('flixel.FlxG', 'height')
  setGraphicSize('warning', screenW, screenH)
  setObjectOrder('warning', 10)
  addLuaSprite('warning', true)
  setProperty('warning.alpha', 1)
  setObjectCamera('warning', 'other')
  end

function showBlackScreen(duration)
    doTweenAlpha('blackFadeIn', 'blackScreenn', 1, duration, 'linear')
end

function hideBlackScreen(duration)
    doTweenAlpha('blackFadeOut', 'blackScreenn', 0, duration, 'linear')
end

function onStartCountdown()
    if not allowCountdown then
	setProperty('warning.alpha', 1)
    return Function_Stop
	else
	return Function_Continue
end
end

function onSongStart()
hideBlackScreen(1)
end

function onEvent(name,v1,v2)
    if name == 'Play Animation' then
        if v1 == 'black' then
            showBlackScreen(1)
		elseif v1 == 'bye' then
		    hideBlackScreen(0.01)
		elseif v1 == 'byea' then
		    hideBlackScreen(2)
		elseif v1 == 'blacki' then
		    showBlackScreen(0.01)
		elseif v1 == 'blackii' then
		    showBlackScreen(5)
			end
		end
	end
	
function onUpdate()
if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.SPACE') and allowCountdown == false then
        allowCountdown = true
	    startCountdown()
		playSound('clickText', 1)
		doTweenAlpha('byewarning', 'warning' , 0, 1, 'linear')
		doTweenAlpha('byebutton', 'start' , 0, 1, 'linear')
		runTimer('removethisshit', 1)
    end
	if (getMouseX('camHUD') > 0 and getMouseX('camHUD') < 128) and (getMouseY('camHUD') > 582.5 and getMouseY('camHUD') < 720 and mousePressed('left')) then
	if allowCountdown == false then
		objectPlayAnimation('start', 'aPressed', false);
		allowCountdown = true
	    startCountdown()
		playSound('clickText', 1)
		doTweenAlpha('byewarning', 'warning' , 0, 1, 'linear')
		doTweenAlpha('byebutton', 'start' , 0, 1, 'linear')
		runTimer('removethisshit', 1)
	else
		objectPlayAnimation('start', 'anonPress', false);
	end
end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'removethisshit' then
        removeLuaSprite('warning')
	end
end