function onCreate()
makeLuaSprite('sky','stages/weeks/weekend2/Wreckage/sky',-800,-700)
scaleObject('sky',1.7,1.8)
setScrollFactor('sky',0.6,0.6)
addLuaSprite('sky')

makeLuaSprite('buildings','stages/weeks/weekend2/Wreckage/buildings',-1000,-600)
scaleObject('buildings',2,2)
setScrollFactor('buildings',0.7,0.7)
addLuaSprite('buildings')

makeLuaSprite('rightBuildings','stages/weeks/weekend2/Wreckage/rightBuildings',400,-700)
scaleObject('rightBuildings',2,2)
setScrollFactor('rightBuildings',0.8,0.8)
addLuaSprite('rightBuildings')

makeLuaSprite('cappedTruck','stages/weeks/weekend2/Wreckage/cappedTruck',-1400,-600)
scaleObject('cappedTruck',1.7,1.7)
setScrollFactor('cappedTruck',0.9,0.9)
addLuaSprite('cappedTruck')

makeAnimatedLuaSprite('mainground','stages/weeks/weekend2/Wreckage/mainground',-1250,-1050)
scaleObject('mainground',1.8,1.8)
addAnimationByPrefix('mainground','loop','mainground',24,true)
addLuaSprite('mainground')

makeLuaSprite('tape','stages/weeks/weekend2/Wreckage/tape',0,-302)
scaleObject('tape',1.7,1.7)
setScrollFactor('tape',1.1,1.1)
addLuaSprite('tape',true)

makeLuaSprite('fgCar','stages/weeks/weekend2/Wreckage/fgCar',-2000,-480)
scaleObject('fgCar',1.7,1.7)
setScrollFactor('fgCar',1.2,1.2)
addLuaSprite('fgCar')

createInstance('fog', 'flixel.addons.display.FlxBackdrop',{nil, 0x01})
loadGraphic('fog', 'stages/mistMid')
scaleObject('fog',1.2,1.2)
setProperty('fog.blend',0)
setProperty('fog.color',0x808080)
setProperty('fog.y',-700)
setProperty('fog.velocity.x',100)
addInstance('fog',true)

makeLuaSprite('fogGradient','stages/greyGradient',-1000,-400)
scaleObject('fogGradient',4000,1.4)
setProperty('fogGradient.alpha',0.05)
setScrollFactor('fogGradient',0,0)
addLuaSprite('fogGradient',true)
end
function onCreatePost()
if shadersEnabled then
local h,s,c,b=-20,-15,-10,-20
for _,char in pairs({'dad','gf','boyfriend'}) do
setSpriteShader(char, 'adjustColor')
setShaderFloat(char,'hue',h)
setShaderFloat(char,'saturation',s)
setShaderFloat(char,'contrast',c)
setShaderFloat(char,'brightness',b)
end
setShaderFloat('dad','saturation',-5)
end
end