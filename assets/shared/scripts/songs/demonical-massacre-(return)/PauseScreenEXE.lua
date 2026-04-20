-- Made by Gavman22 [v2.4.0]
-- Modified By Pico Engine Team [2.26.5 Update]

local fakePaused = false
local cSelected = false
local rSelected = false
local eSelected = false
local canFakePause = true
local unpausingRn = false
local isGrayscale = false
local canMovePauseMenu = false
local songStarted = false
function onCreate()
	if getPropertyFromClass('PlayState', 'chartingMode') == false then
		precacheSound('PauseMenu/pause')
		precacheSound('PauseMenu/pauseScrollMenu')
		precacheSound('PauseMenu/unpause')
		if shadersEnabled == true then
			initLuaShader('Grayscale')

			makeLuaSprite("grapshad")
			makeGraphic("grapshad", screenWidth, screenHeight)
			setSpriteShader("grapshad", 'Grayscale')
		else
			makeLuaSprite('blackness of black', nil, 0, 0)
			makeGraphic('blackness of black', screenWidth, screenHeight, '000000')
			setProperty('blackness of black.visible', false)
			setProperty('blackness of black.alpha', 0.35)
			setObjectCamera('blackness of black', 'camOther')
			addLuaSprite('blackness of black', true)
		end
		makeLuaSprite('pauseRight', 'PauseMenu/pauseRight', 800, 0)
		addLuaSprite('pauseRight', true)
		setObjectCamera('pauseRight', 'camOther')
		makeLuaSprite('pauseLeft', 'PauseMenu/pauseLeft', -800, 0)
		addLuaSprite('pauseLeft', true)
		setObjectCamera('pauseLeft', 'camOther')
		makeLuaSprite('fakeTimeBar', '', -1007, 203)
		makeGraphic('fakeTimeBar', 390, 11, 'FF0000')
		addLuaSprite('fakeTimeBar', true)
		setObjectCamera('fakeTimeBar', 'camOther')
		makeLuaSprite('continue', 'PauseMenu/Continue', 800, 0)
		addLuaSprite('continue', true)
		setObjectCamera('continue', 'camOther')
		makeLuaSprite('restart', 'PauseMenu/Restart', 800, 0)
		addLuaSprite('restart', true)
		setObjectCamera('restart', 'camOther')
		makeLuaSprite('exist', 'PauseMenu/Exit', 800, 0)
		addLuaSprite('exist', true)
		setObjectCamera('exist', 'camOther')
	end
end
function onCreatePost()
	if getPropertyFromClass('PlayState', 'chartingMode') == false then
		makeAnimatedLuaSprite('pauseIcon', nil, -800, 140)
		if checkFileExists('images/icons/icon-'..getProperty('boyfriend.healthIcon')..'.png') then
			loadGraphic('pauseIcon', 'icons/icon-'..getProperty('boyfriend.healthIcon'), 150)
		elseif checkFileExists('images/icons/'..getProperty('boyfriend.healthIcon')..'.png') then
			loadGraphic('pauseIcon', 'icons/'..getProperty('boyfriend.healthIcon'), 150)
		else
			loadGraphic('pauseIcon', 'icons/icon-face', 150)
			debugPrint("Couldn't find images/icons/icon-"..getProperty('boyfriend.healthIcon')..'.png or images/icons/'..getProperty('boyfriend.healthIcon')..'.png! Do they exist?')
		end
		addAnimation('pauseIcon', 'uwu', {0, 1}, 0, true)
		setObjectCamera('pauseIcon', 'camOther')
		addLuaSprite('pauseIcon')
		setProperty('pauseIcon.angle', 180)
	end
end
function onSongStart()
	songStarted = true
	canFakePause = true
end
function onUpdatePost()
	if getPropertyFromClass('PlayState', 'chartingMode') == false then
		if keyJustPressed('pause') and fakePaused == false and canFakePause == true and unpausingRn == false then
			openCustomSubstate('pauseMenu', true)
		end
		if getProperty('inCutscene') and not songStarted then
			canFakePause = false
		end
		if getProperty('inGameover') then
			canFakePause = false
		end
	end
end
function onCustomSubstateCreate(tag)
	if tag == 'pauseMenu' then
		playSound('PauseMenu/pause', 1, 'pause')
		doTweenX('pauseRightTween', 'pauseRight', 0, 0.2, 'linear')
		doTweenX('pauseLeftTween', 'pauseLeft', 0, 0.2, 'linear')
		doTweenX('fakeTimeBarTween', 'fakeTimeBar', 207, 0.2, 'linear')
		doTweenX('pauseIconTween7', 'pauseIcon', 65, 1, 'circInOut')
		doTweenAngle('pauseIconTweenAng', 'pauseIcon', 0, 1, 'circInOut')
		doTweenX('cTween', 'continue', 0, 0.2, 'linear')
		doTweenX('rTween', 'restart', 0, 0.2, 'linear')
		doTweenX('eTween', 'exist', 0, 0.2, 'linear')
		toggleGrayscale()
		cSelected = false
		rSelected = false
		eSelected = false
		fakePaused = true
	end
end
function onCustomSubstateUpdate(tag)
	if tag == 'pauseMenu' then
		if keyJustPressed('accept') and fakePaused == true and canFakePause == true and unpausingRn == false and canMovePauseMenu == true then
			plsHelp()
		end
		if cSelected == false then
			setProperty('continue.y', 0)
		end
		if cSelected == true then
			doTweenY('cTweenY', 'continue', -15, 0.07, 'circInOut')
		end
		if rSelected == false then
			setProperty('restart.y', 0)
		end
		if rSelected == true then
			doTweenY('rTweenY', 'restart', -15, 0.07, 'circInOut')
		end
		if eSelected == false then
			setProperty('exist.y', 0)
		end
		if eSelected == true then
			doTweenY('eTweenY', 'exist', -15, 0.07, 'circInOut')
		end
		scaleObject('fakeTimeBar', 1 * getProperty("songPercent"), 1)
		setProperty('pauseIcon.animation.curAnim.curFrame', getProperty('iconP1.animation.curAnim.curFrame'))
		if getProperty('pauseIcon.animation.curAnim.curFrame') > 1 then
			if getProperty('healthBar.percent') < 20 then
				setProperty('pauseIcon.animation.curAnim.curFrame', 1)
			else
				setProperty('pauseIcon.animation.curAnim.curFrame', 0)
			end
		end
		damnIWannaDie()
	end
end
function damnIWannaDie()
	if keyJustPressed('down') and fakePaused == true and canMovePauseMenu == true then
		if cSelected == true then
			cSelected = false
			rSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		elseif rSelected == true then
			rSelected = false
			eSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		elseif eSelected == true then
			eSelected = false
			cSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		end
	elseif keyJustPressed('up') and fakePaused == true and canMovePauseMenu == true then
		if cSelected == true then
			cSelected = false
			eSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		elseif rSelected == true then
			rSelected = false
			cSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		elseif eSelected == true then
			eSelected = false
			rSelected = true
			playSound('PauseMenu/pauseScrollMenu', 1, 'pausescroll')
		end
	end
end
function plsHelp()
	if cSelected == true then
		cancelTween('pauseIconTween7')
		cancelTween('pauseIconTweenAng')
		playSound('PauseMenu/unpause', 1, 'unpause')
		doTweenX('pauseRightTween2', 'pauseRight', 800, 0.2, 'linear')
		doTweenX('pauseLeftTween2', 'pauseLeft', -800, 0.2, 'linear')
		doTweenX('fakeTimeBarTween2', 'fakeTimeBar', -800, 0.2, 'linear')
		doTweenX('cTween2', 'continue', 800, 0.2, 'linear')
		doTweenX('rTween', 'restart', 800, 0.2, 'linear')
		doTweenX('eTween', 'exist', 800, 0.2, 'linear')
		doTweenX('pauseIconTween', 'pauseIcon', -800, 1, 'circInOut')
		doTweenAngle('pauseIconTweenAng', 'pauseIcon', 180, 1, 'circInOut')
		cSelected = false
		rSelected = false
		eSelected = false
	elseif rSelected == true then
		playSound('PauseMenu/unpause', 1, 'unpause')
		restartSong(true)
	elseif eSelected == true then
		playSound('PauseMenu/unpause', 1, 'unpause')
		exitSong(true)
	end
end
function onPause()
	if getPropertyFromClass('PlayState', 'chartingMode') == false then
		return Function_Stop
	else
		return Function_Continue
	end
end
function onTweenCompleted(tag)
	if tag == 'pauseIconTween' then
		unpausingRn = false
		fakePaused = false
		toggleGrayscale()
		canMovePauseMenu = false
		closeCustomSubstate()
	end
	if tag == 'cTween' then
		canMovePauseMenu = true
		cSelected = true
	end
end
function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'startDialogue' then
		canFakePause = false
	end
end
function toggleGrayscale()
	if shadersEnabled == true then
		if isGrayscale == false then
			addHaxeLibrary("ShaderFilter", "openfl.filters")
			runHaxeCode([[
				var game = PlayState.instance;
				game.camGame.setFilters([new ShaderFilter(game.getLuaObject("grapshad").shader)]);
				game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("grapshad").shader)]);
			]])  
			isGrayscale = true
		else
			addHaxeLibrary("ShaderFilter", "openfl.filters")
			runHaxeCode([[
				var game = PlayState.instance;
				game.camGame.setFilters([]);
				game.camHUD.setFilters([]);
			]])  
			isGrayscale = false
		end
	else
		if isGrayscale == false then
			setProperty('blackness of black.visible', true) 
			isGrayscale = true
		else
			setProperty('blackness of black.visible', false) 
			isGrayscale = false
		end
	end
end
function onGameOverStart()
	closeCustomSubstate()
end