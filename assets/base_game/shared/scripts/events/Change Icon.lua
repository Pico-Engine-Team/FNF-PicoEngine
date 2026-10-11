local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

local function splitIconValue(value)
    local parts = {}
    for part in tostring(value or ''):gmatch('[^,]+') do
        table.insert(parts, trim(part))
    end

    local iconName = parts[1] or ''
    table.remove(parts, 1)

    return iconName, parts
end

local function clampColor(value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    return math.max(0, math.min(255, value))
end

local function parseIconColor(parts)
    if parts == nil or #parts < 1 then return nil end

    if #parts >= 3 then
        local red = tonumber(parts[1])
        local green = tonumber(parts[2])
        local blue = tonumber(parts[3])

        if red ~= nil and green ~= nil and blue ~= nil then
            return {clampColor(red), clampColor(green), clampColor(blue)}
        end
    end

    local colorText = trim(table.concat(parts, ','))
    if colorText == '' then return nil end

    colorText = colorText:gsub('^#', '')
    colorText = colorText:gsub('^0x', '')
    colorText = colorText:gsub('^0X', '')

    if #colorText == 8 then
        colorText = colorText:sub(3)
    end

    if #colorText ~= 6 then return nil end

    local parsed = tonumber(colorText, 16)
    if parsed == nil then return nil end

    return {
        math.floor(parsed / 0x10000) % 0x100,
        math.floor(parsed / 0x100) % 0x100,
        parsed % 0x100
    }
end

local function setHealthColor(character, color)
    if color == nil then return end

    setProperty(character .. '.healthColorArray[0]', color[1])
    setProperty(character .. '.healthColorArray[1]', color[2])
    setProperty(character .. '.healthColorArray[2]', color[3])
end

local function reloadHealthBarColors()
    callMethod('reloadHealthBarColors', {})
end

local function changeIcon(targetIcon, character, iconName, color)
    callMethod(targetIcon .. '.changeIcon', {iconName})
    local changedIcon = callMethod(targetIcon .. '.getCharacter', {})
    setProperty(character .. '.healthIcon', changedIcon or iconName)
    setHealthColor(character, color)
end

function onEvent(name, value1, value2)
    if name ~= 'Change Icon' then return end

    local target = trim(value1):lower()
    local icon, iconColor = splitIconValue(value2)
    local color = parseIconColor(iconColor)

    if icon == '' then
        icon = 'face'
    end

    if target == 'player' or target == 'p1' or target == 'bf' or target == 'boyfriend' or target == '0' then
        changeIcon('iconP1', 'boyfriend', icon, color)
        debugPrint('[Change Icon] Player -> ' .. icon)

    elseif target == 'opponent' or target == 'enemy' or target == 'p2' or target == 'dad' or target == '1' then
        changeIcon('iconP2', 'dad', icon, color)
        debugPrint('[Change Icon] Opponent -> ' .. icon)

    elseif target == 'both' then
        changeIcon('iconP1', 'boyfriend', icon, color)
        changeIcon('iconP2', 'dad', icon, color)
        debugPrint('[Change Icon] Both -> ' .. icon)

    elseif target == 'gf' or target == 'girlfriend' or target == '2' then
        setProperty('gf.healthIcon', icon)
        setHealthColor('gf', color)
        debugPrint('[Change Icon] Girlfriend -> ' .. icon)

    else
        debugPrint('[Change Icon] ERRO: Alvo invalido "' .. target .. '" (use: player/p1/bf, opponent/p2/dad, gf ou both)')
        return
    end

    if color ~= nil then
        reloadHealthBarColors()
    end
end