function onEvent(name, value1, value2)
    if name ~= 'Change Icon' then return end

    local target = (value1 or ''):lower()
    local icon = value2 or ''

    if icon == '' then
        debugPrint('[Change Icon] ERRO: Nenhum ícone foi especificado!')
        return
    end

    local function changeIcon(targetIcon, iconName)
        callMethod(targetIcon .. '.changeIcon', {iconName})
    end

    if target == 'player' or target == 'p1' then
        changeIcon('iconP1', icon)
        debugPrint('[Change Icon] Player -> ' .. icon)

    elseif target == 'opponent' or target == 'enemy' or target == 'p2' then
        changeIcon('iconP2', icon)
        debugPrint('[Change Icon] Opponent -> ' .. icon)

    else
        debugPrint('[Change Icon] ERRO: Alvo inválido "' .. target .. '" (use: player/p1 ou opponent/p2)')
    end
end