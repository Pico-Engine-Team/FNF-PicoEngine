function onCreatePost()
    -- This is to make sure that the hardcoded WeekEnd 1 stages don't have a duplicate.
    if curStage == 'phillyStreets' or curStage == 'phillyBlazin' then
        if gfName == 'nene' then
            setCharacterX('gf', getCharacterX('gf') - 60)
            setCharacterY('gf', getCharacterY('gf') + 200)
            callMethod('stages[0].abot.destroy')
        end
    elseif curStage == 'tankErect' then
        -- Temporary fix to make Nene centered in this stage.
        if gfName == 'nene' then
            setCharacterX('gf', getCharacterX('gf') + 115)
        end
    end
    
    addLuaScript('scripts/characters/nene/Abots/Default/Abot')
    callScript('scripts/characters/nene/Abots/Default/Abot', 'createSpeaker', {'nene', 0, 0})

    -- Some extra code to set up the speaker's shader in the 'tankErect' stage.
    if curStage == 'tankErect' then
        setVar('trackShader', false) -- Check line 30 of 'abot-speaker' to know its use.
        if shadersEnabled == true then
            initLuaShader('adjustColor')
            for _, object in ipairs({'AbotSpeaker', 'AbotSpeakerBG', 'AbotPupils', 'AbotEyes'}) do
                setSpriteShader(object, 'adjustColor')
                setShaderFloat(object, 'hue', -10)
                setShaderFloat(object, 'saturation', -20)
                setShaderFloat(object, 'contrast', -25)
                setShaderFloat(object, 'brightness', -30)
            end

            for bar = 1, 7 do
                setSpriteShader('AbotSpeakerVisualizer'..bar, 'adjustColor')
                setShaderFloat('AbotSpeakerVisualizer'..bar, 'hue', -30)
                setShaderFloat('AbotSpeakerVisualizer'..bar, 'saturation', -10)
                setShaderFloat('AbotSpeakerVisualizer'..bar, 'contrast', 0)
                setShaderFloat('AbotSpeakerVisualizer'..bar, 'brightness', -12)
            end
        end
	end
end

function onUpdatePost(elapsed)
    if songName ~= "Blazin'" then
        transitionAnim()
    end
end

local animTrans = 0
local blinkDelay = 3
local trainStartedMoving = nil
function transitionAnim()
    checkHairBlowState()
    if animTrans == 0 then -- Nene noticed the player being low on health.
        if getHealth() <= 0.5 then
            animTrans = 1
        else
            animTrans = 0
        end
    elseif animTrans == 1 then -- Nene stops bopping her head and raises her knife.
        if getHealth() > 0.5 then
            animTrans = 0
        elseif getProperty('gf.animation.name') == 'danceLeft' then
            comboAnimActive = false
            setProperty('gf.specialAnim', true)
            if getProperty('gf.animation.finished') then
                animTrans = 2
                playAnim('gf', 'raiseKnife')
                setProperty('gf.specialAnim', true)
                changedBeat = curBeat
            end
        end
    elseif animTrans == 2 then -- Nene keeps raising her knife while randomly blinking on beat, or lowers her knife.
        if getHealth() > 0.5 then
            animTrans = 3
            playAnim('gf', 'lowerKnife')
            setProperty('gf.specialAnim', true)
        elseif getProperty('gf.animation.finished') then
            if getProperty('gf.animation.name') ~= 'idleKnife' or curBeat - changedBeat == blinkDelay then
                blinkDelay = getRandomInt(3, 7)
                changedBeat = curBeat
                playAnim('gf', 'idleKnife')
                setProperty('gf.specialAnim', true)
            else
                lastFrame = getProperty('gf.animation.numFrames')
                playAnim('gf', 'idleKnife', false, false, lastFrame)
                setProperty('gf.specialAnim', true)
            end
        end
    elseif animTrans == 3 then -- Nene goes back to bopping her head.
        if getProperty('gf.animation.finished') then
            animTrans = 0
            comboAnimActive = true
            setProperty('gf.danced', false)
            characterDance('gf')
        end   
    elseif animTrans == 4 then -- Nene's hair is blown by the train.
        if trainStartedMoving == false then
            animTrans = 0
            playAnim('gf', 'hairFallNormal')
            setProperty('gf.specialAnim', true)
        else
            playAnim('gf', 'hairBlowNormal')
            setProperty('gf.specialAnim', true)
        end
    elseif animTrans == 5 then -- Nene's hair is blown by the train while she has her knife raised. 
        if trainStartedMoving == false then
            animTrans = 2
            playAnim('gf', 'hairFallKnife')
            setProperty('gf.specialAnim', true)
        else
            playAnim('gf', 'hairBlowKnife')
            setProperty('gf.specialAnim', true)
        end
    end
end

--[[ 
    This is how the function above detects if Nene has her hair blown by the passing train or not.
    Only works when the current stage is either 'philly' or 'phillyErect', else it'll do nothing.
]]
function checkHairBlowState()
    if curStage == 'philly' then
        trainStartedMoving = getProperty('stages[0].phillyTrain.startedMoving')
    elseif curStage == 'phillyErect' then
        trainStartedMoving = getVar('startedMoving')
    else
        return -- Nothing lol
    end

    if trainStartedMoving == true and animTrans < 4 then
        if animTrans == 2 then
            animTrans = 5
        else
            animTrans = 4
        end
    end
end