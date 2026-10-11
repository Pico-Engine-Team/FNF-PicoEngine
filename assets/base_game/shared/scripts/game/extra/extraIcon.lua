local iconsCreated = {}
local curDadIcon = ''
local curBfIcon = ''

function addExtraIcon(tag,imagePath,isPlayer,addBehind)--Must be used on create post function
    if not hideHud then
        local target = 'iconP2'
        if imagePath == nil then
            if tag == 'gfIcon' then
                imagePath = getProperty('gf.healthIcon')
            elseif tag == 'dadIcon' then
                imagePath = getProperty('dad.healthIcon')
            elseif tag == 'bfIcon' then
                imagePath = getProperty('boyfriend.healthIcon')
            else
                imagePath = 'face'
            end
        end
        makeLuaSprite(tag,nil,0,0)
        setObjectCamera(tag,'hud')
        setProperty(tag..'.flipX',isPlayer == true)
        --addLuaSprite(tag,true)
        if isPlayer then
            target = 'iconP1'
        end
        setProperty(tag..'.x',getProperty(target..'.x'))
        setProperty(tag..'.y',getProperty(target..'.y'))
        setProperty(tag..'.visible',not hideHud)
        iconsCreated[tag] = {
            scale = 1,
            isPlayer = (isPlayer == true),
            activated = true,
            imageFile = '',
            lerpScale = false,
            lerpPos = false,
            followScale = true,
            followPos = true,
            followAlpha = true,
            lerpSpeed = 0.2,
            followCharacterImage = true
        }
        loadIconGraphic(tag,imagePath)
        if version >= '0.7' then
            if addBehind then
                runHaxeCode(
                    [[
                        game.uiGroup.members.insert(game.uiGroup.members.indexOf(game.]]..target..[[),game.getLuaObject("]]..tag..[["));
                        
                    ]]
                )
            else
                runHaxeCode(
                    [[
                        game.uiGroup.members.insert(game.uiGroup.members.indexOf(game.]]..target..[[) + 2,game.getLuaObject("]]..tag..[["));
                        
                    ]]
                )
            end

        else
            if addBehind then
                runHaxeCode(
                    [[
                        game.insert(game.members.indexOf(game.]]..target..[[) + 1,game.getLuaObject("]]..tag..[["));
                        
                    ]]
                )
            else
                runHaxeCode(
                    [[
                        game.insert(game.members.indexOf(game.]]..target..[[) + 2,game.getLuaObject("]]..tag..[["));
                        
                    ]]
                )
            end
        end
    end

end

function getIconImage(image)
    local imagePath = 'icons/icon-face'
    if not checkFileExists('images/'..image..'.png') then
        imagePath = 'icons/baseGame/'..image
    end
    if not checkFileExists('images/icons/baseGame/'..image..'.png') then
        if checkFileExists('images/icons/baseGame/icon-'..image..'.png') then
            imagePath = 'icons/baseGame/icon-'..image
        end
    else
        imagePath = 'icons/'..image
    end
    return imagePath
end

function loadIconGraphic(icon,image)
    image = getIconImage(image)
    makeLuaSprite('imageIcon',image)
    loadGraphic(icon,image,getProperty('imageIcon.width')/2,getProperty('imageIcon.height'))
    addAnimation(icon,'anim',{0,1},0,false)
    removeLuaSprite('imageIcon',true)
    
    iconsCreated[icon].imageFile = image
end

function doExtraIntroTween(tag,type)
    if tag ~= 'all' then
        if iconsCreated[tag] ~= nil then
            if type == 'exit'  then
                cancelTween(tag..'IconExtraIntro')
                doTweenY(tag..'IconExtraExitY',tag..'.offset',not downscroll and 400 or -400,1,'circIn')
            else
                cancelTween(tag..'IconExtraExitY')
                setProperty(tag..'offset.y',not downscroll and 400 or -400)
                doTweenY(tag..'IconExtraIntro',tag..'.offset',0,2,'circIn')
            end
        end
    else
        for icons,i in pairs(iconsCreated) do
            if type == 'exit' then
                cancelTween(icons..'IconExtraIntro')
                doTweenY(icons..'IconExtraExitY',icons..'.offset',not downscroll and 400 or -400,1,'circIn')
            else
                cancelTween(icons..'IconExtraExitY')
                setProperty(icons..'offset.y',not downscroll and 400 or -400)
                doTweenY(icons..'IconExtraIntro',tag..'.offset',0,2,'circIn')
            end
        end
    end
end

function removeExtraIcon(tag,removeImageFromMemory)
    if tag ~= 'all' then
        if iconsCreated[tag] ~= nil then
            removeLuaSprite(tag,true)
            if removeImageFromMemory then
                --if version >= '0.7' then
                    --callOnHScript('removeFromMemory',{iconsCreated[tag].imageFile})
                --else
                callScript('scripts/optimization','removeFromMemory',{iconsCreated[tag].imageFile})
                --end
                
            end
            iconsCreated[tag] = nil
        end
    else
        for icons,i in pairs(iconsCreated) do
            removeLuaSprite(icons,true)
            if removeImageFromMemory then
                --if version >= '0.7' then
                    --callOnHScript('removeFromMemory',{i.imageFile})
                --else
                callScript('scripts/otimization','removeFromMemory',{i.imageFile})
                --end
                
            end
            iconsCreated[icons] = nil
        end
    end
end

function setIconAsPrincipal(tag,lerp)
    if iconsCreated[tag] ~= nil and (iconsCreated[tag].isPlayer and tag ~= curBfIcon or not iconsCreated[tag].isPlayer and tag ~= curDadIcon) then
        if iconsCreated[tag].isPlayer then
            curBfIcon = tag
        else
            curDadIcon = tag
        end

        if lerp then
            for icons, i in pairs(iconsCreated) do
                if iconsCreated[icons].isPlayer == (iconsCreated[tag].isPlayer == true) then
                    doIconLerp(icons,0.25,0.25)
                end
            end
        end
    end
end

function doIconLerp(icon,lerpTime,speed)
    if iconsCreated[icon] ~= nil then
        if lerpTime ~= nil then
            runTimer('disableIconLerp'..icon,0.2)
        end
        if speed == nil then
            speed = 0.1
        end
        iconsCreated[icon].lerpScale = true
        iconsCreated[icon].lerpPos = true
        iconsCreated[icon].lerpSpeed = speed
    end
end

function changeIconDir(icon,toPlayer,lerpDuration,lerpSpeed)
    if iconsCreated[icon] ~= nil and iconsCreated[icon].isPlayer ~= toPlayer then
        doIconLerp(icon,lerpDuration,lerpSpeed)
        setProperty(icon..'.flipX',toPlayer)
    end
end

function onTimerCompleted(tag)
    if string.find(tag,'disableIconLerp',0,true) then
        local icon = string.gsub(tag,'disableIconLerp','')
        iconsCreated[icon].lerpPos = false
        iconsCreated[icon].lerpScale = false
    end
end

function onUpdatePost()
    local iconDadPos = 0
    local iconBfPos = 0


    for icon, iconFiles in pairs(iconsCreated) do
        if iconsCreated[icon] ~= nil and iconsCreated[icon].activated and luaSpriteExists(icon) then
            local followIcon = 'iconP2'
            if iconFiles.isPlayer then
                followIcon = 'iconP1'
            end
            local x = getProperty(followIcon..'.x')
            local y = getProperty(followIcon..'.y')
            local scale = iconFiles.scale

            if not iconFiles.isPlayer and icon ~= curDadIcon or iconFiles.isPlayer and icon ~= curBfIcon then
                local offsetX = 0
                local offsetY = 0
                if iconFiles.isPlayer then
                    offsetX = 60
                    iconBfPos = iconBfPos + 1
                    if iconBfPos == 1 then
                        offsetY = -60
                    elseif iconBfPos == 2 then
                        offsetY = 125
                    end
                else
                    offsetX = -90
                    iconDadPos = iconDadPos + 1
                    if iconDadPos == 1 then
                        offsetY = -70
                    elseif iconDadPos == 2 then
                        offsetY = 50
                    end
                end
                

                --y = y + (offsetY*scale)
                scale = math.max(0,scale - 0.2)
                x = x + (offsetX*scale)
                y = y + offsetY
            end
            if iconFiles.followScale then
                if iconFiles.lerpScale then -- Used on Unbeatable
                    setProperty(icon..'.scale.x',lerp(getProperty(icon..'.scale.x'),scale * getProperty(followIcon..'.scale.x'),iconFiles.lerpSpeed))
                    setProperty(icon..'.scale.y',lerp(getProperty(icon..'.scale.y'),scale * getProperty(followIcon..'.scale.y'),iconFiles.lerpSpeed))
                else
                    setProperty(icon..'.scale.x',(scale * getProperty(followIcon..'.scale.x')))
                    setProperty(icon..'.scale.y',(scale * getProperty(followIcon..'.scale.y')))
                end
            end
            if iconFiles.followPos then
                if iconFiles.lerpPos then
                    setProperty(icon..'.x',lerp(getProperty(icon..'.x'),x,iconFiles.lerpSpeed))
                    setProperty(icon..'.y',lerp(getProperty(icon..'.y'),y,iconFiles.lerpSpeed))
                else
                    setProperty(icon..'.x',x)
                    setProperty(icon..'.y',y)
                end
            end
            if iconFiles.followAlpha then
                setProperty(icon..'.alpha',getProperty(followIcon..'.alpha'))
            end
            setProperty(icon..'.animation.curAnim.curFrame',getProperty(followIcon..'.animation.curAnim.curFrame'))
        end
    end
end

function lerp(a,b,c)
    return a + (b-a)*c
end

function onEvent(name,v1,v2)
    if name == 'Change Character' then
        local char = string.lower(v1)
        if (char == 'dad' or v1 == '1') and luaSpriteExists('dadIcon') then
            char = 'dad'
        elseif (char == 'bf' or v1 == '0') and luaSpriteExists('bfIcon') then
            char = 'boyfriend'
        elseif (char == 'gf' or v1 == '2') and luaSpriteExists('gfIcon') then
            char = 'gf'
        else
            return
        end
        if iconsCreated[char..'Icon'].followCharacterImage then
            loadIconGraphic(char..'Icon',getProperty(char..'.healthIcon'))
        end
    end
end
function setIconProperty(tag,var,value)
    if iconsCreated[tag] == nil then
        iconsCreated[tag] = {}
    end
    iconsCreated[tag][var] = value
end
--[[function focusIcon(icon,isPlayer,insert)
    if luaSpriteExists(icon) then
        local array = {}
        if insert ~= false then
            if isPlayer then
                array = bfIconsFocus
            else
                array = dadIconFocus
            end
            if type(icon) == 'string' then
                if not table.find(array,icon) then
                    table.insert(array,icon)
                end
            elseif type(icon) == "table" then
                for i, icons in pairs(icon) do
                    if not table.find(array,icons) then
                        table.insert(array,icons)
                    end
                end
            end
        else
            if type(icon) == "table" then
                array = icon
            else
                array = {icon}
            end
        end
        if isPlayer then
            bfIconsFocus = array
        else
            dadIconFocus = array
        end
    end
end]]--