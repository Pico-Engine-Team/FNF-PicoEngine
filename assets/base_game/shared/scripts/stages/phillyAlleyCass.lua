makeLuaSprite('sky','stages/weeks/weekend2/sky',500,-130)
scaleObject('sky',1.8,1.8)
setScrollFactor('sky',0.7,0.7)
addLuaSprite('sky')

makeAnimatedLuaSprite('car','stages/weeks/weekend2/cars',3590,400)
scaleObject('car',1.5,1.5)
setProperty('car.flipX',true)
setScrollFactor('car',0.85,0.85)
addAnimationByPrefix('car','car1','Van',24,false)
addAnimationByPrefix('car','car2','car_normal',24,false)
addAnimationByPrefix('car','car3','caravan',24,false)
playAnim('car','car1',true)
addLuaSprite('car')

makeLuaSprite('sign post','stages/weeks/weekend2/billboard',2090,-32)
scaleObject('sign post',1.6,1.6)
setScrollFactor('sign post',0.9,0.9)
addLuaSprite('sign post')

makeLuaSprite('ground','stages/weeks/weekend2/stage',880,-215)
scaleObject('ground',1.7,1.7)
addLuaSprite('ground')

makeLuaSprite('foreground','stages/weeks/weekend2/foreground',-600,-302)
scaleObject('foreground',1.7,1.7)
setScrollFactor('foreground',1.1,1.1)
addLuaSprite('foreground',true)

local timeElap = 0
local scale = screenHeight / 200
local startIntensity = 0.1
local endIntensity = 0.2
local function remapToRange(value, fromMin, toMin, fromMax, toMax)
return fromMax+(value-fromMin)*((toMax-fromMax)/(toMin-fromMin))
end

function onCreatePost()
if shadersEnabled then
local h,s,c,b=-7,-7,-6,-12
for _,char in pairs({'dad','gf','boyfriend'}) do
setSpriteShader(char, 'adjustColor')
setShaderFloat(char,'hue',h)
setShaderFloat(char,'saturation',s)
setShaderFloat(char,'contrast',c)
setShaderFloat(char,'brightness',b)
end

createInstance('rain','shaders.RainShader')
setProperty('rain.scale', scale)
callMethod('rain.updateViewInfo', {screenWidth, screenHeight, instanceArg('camGame')})
runHaxeCode([[
game.camGame.setFilters([new ShaderFilter(getVar("rain"))]);
]])
end
end

function onUpdate(elapsed)
timeElap = timeElap + elapsed
callMethod('rain.update', {timeElap})
local remapIntensity = remapToRange(getSongPosition(), 0, getProperty('inst.length'), startIntensity, endIntensity)
setProperty('rain.intensity', remapIntensity)
end

function onEvent(n,v1,v2)
if n=='Play Animation' then
if v2=='Dad' then
if getProperty('dad.animation.name')=='shoot' then
local props={'sky','car','sign post','ground','foreground'}
for i=1,#props do
setProperty(props[i]..'.color',0x606060)
doTweenColor(props[i]..'Shoot',props[i],'FFFFFF',0.6)
end
end
end

if v1=='killCass' then
setProperty('dad.visible',false)
end

end
end

function onBeatHit()
if curBeat%getRandomInt(35,45)==0 then
playAnim('car','car'..getRandomInt(1,3),true)
doTweenX('carTween','car',getProperty('car.x')-2500,getRandomInt(3,4),'sineOut')
end
end

function onTweenCompleted(tag)
if tag=='carTween'then
setProperty('car.x',3590)
end
end