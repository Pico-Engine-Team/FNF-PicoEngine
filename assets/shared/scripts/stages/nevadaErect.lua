makeLuaSprite('sky','stages/weeks/bonus/hank/erect/sky',-600,-500)
scaleObject('sky',1.85,1.85)
setScrollFactor('sky',0.65,1)
addLuaSprite('sky')

makeAnimatedLuaSprite('lightning','stages/weeks/bonus/hank/erect/lightning',300,-500)
addAnimationByPrefix('lightning','strike','lightning0',24,false)
scaleObject('lightning',3,3)
setScrollFactor('lightning',0.7,1)
setProperty('lightning.visible',false)
addLuaSprite('lightning')

makeLuaSprite('buildings','stages/weeks/bonus/hank/erect/buildings',-150,0)
scaleObject('buildings',1.9,1.9)
setScrollFactor('buildings',0.7,1)
addLuaSprite('buildings')

makeLuaSprite('mountains','stages/weeks/bonus/hank/erect/mountains',-850,-100)
scaleObject('mountains',2.2,2.2)
setScrollFactor('mountains',0.8,1)
addLuaSprite('mountains')

makeLuaSprite('topBar','stages/weeks/bonus/hank/erect/topBar',-230,-230)
scaleObject('topBar',2,2)
addLuaSprite('topBar')

makeAnimatedLuaSprite('fatass','stages/weeks/bonus/hank/erect/fatfuck',1500,-50)
addAnimationByPrefix('fatass','i','hotdoggrunt',24,true)
scaleObject('fatass',2,2)
addLuaSprite('fatass')

makeAnimatedLuaSprite('agent','stages/weeks/bonus/hank/erect/agent',-100,300)
addAnimationByPrefix('agent','e','agent',24,true)
scaleObject('agent',2,2)
addLuaSprite('agent')

makeLuaSprite('ground','stages/weeks/bonus/hank/erect/ground',-884,500)
scaleObject('ground',2,2)
addLuaSprite('ground')

makeLuaSprite('overlay','stages/weeks/bonus/hank/erect/overlay',-500,-300)
scaleObject('overlay',1.35,1.35)
setProperty('overlay.alpha',0.3)
setBlendMode('overlay','add')
addLuaSprite('overlay',true)

makeAnimatedLuaSprite('foreground gruntL','stages/weeks/bonus/hank/erect/grunt',-800,400)
addAnimationByPrefix('foreground gruntL','id','foreground grunts',24,true)
scaleObject('foreground gruntL',2,2)
setProperty('foreground gruntL.flipX',true)
setScrollFactor('foreground gruntL',1.1,1.1)
addLuaSprite('foreground gruntL',true)

makeAnimatedLuaSprite('foreground gruntR','stages/weeks/bonus/hank/erect/grunt',2000,400)
addAnimationByPrefix('foreground gruntR','xd','foreground grunts',24,true)
scaleObject('foreground gruntR',2,2)
setScrollFactor('foreground gruntR',1.1,1.1)
addLuaSprite('foreground gruntR',true)

lightningTimer=3.0
lightningActive=true
stages={'boyfriend','dad','gf','topBar','fatass','agent','sky','buildings','mountains','ground','foreground gruntR','foreground gruntL'}

function onUpdatePost(elapsed)
if lightningActive then
lightningTimer=lightningTimer-elapsed
if lightningTimer<=0 then
applyLightning()
lightningTimer=getRandomFloat(7,15)
end
end
end

function applyLightning()
playAnim('lightning','strike',true)
setProperty('lightning.x',getRandomBool(65) and getRandomInt(-250,280) or getRandomInt(780,900))

for i=1,#stages do
setProperty(stages[i]..'.color',0x606060)
doTweenColor(stages[i]..'Color',stages[i],'FFFFFF',1.5)
end

setProperty('overlay.alpha',0)
doTweenAlpha(_,'overlay',0.3,1)
playSound('Lightning'..getRandomInt(1,3))
end

function onSongStart()
setProperty('lightning.visible',true)
end