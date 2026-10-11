local PathStage = 'week3/images/philly/erect/'
local PathExtra = 'week3/images/philly/'

precacheSound('train_passes')

function onCreate()
    if lowQuality == false then
        makeLuaSprite('sky', PathStage .. 'sky', -100, 0)
        setScrollFactor('sky', 0.1, 0.1)
        addLuaSprite('sky')
    end

    makeLuaSprite('city', PathStage .. 'city', -10, 0)
    scaleObject('city', 0.85, 0.85)
    setScrollFactor('city', 0.3, 0.3)
    addLuaSprite('city')

    makeLuaSprite('window', PathExtra .. 'window', -10, 0)
    scaleObject('window', 0.85, 0.85)
    setScrollFactor('window', 0.3, 0.3)
    addLuaSprite('window')
    setProperty('window.alpha', 0)

    if lowQuality == false then
        makeLuaSprite('behindTrain', PathStage .. 'behindTrain', -40, 50)
        addLuaSprite('behindTrain')
    end

    makeLuaSprite('train', PathStage ..'train', 2000, 360)
    addLuaSprite('train')

    makeLuaSprite('street', PathStage .. 'street', -40, 50)
    addLuaSprite('street')
end