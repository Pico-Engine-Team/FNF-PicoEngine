function onCreatePost()
    if not shadersEnabled then return end
    initLuaShader('Light_Shader')

    local characters = {
        boyfriend = {
            angle = 160,
            color = {0.52, 1.1, 0.68},  -- Cyan/teal light
            brightness = -6,
            hue = 0,
            contrast = 0,
            saturation = 0
        },
        gf = {
            angle = 90,
            color = {0.87, 0.87, 0.7}, 
            brightness = 0,
            hue = 0,
            contrast = 0,
            saturation = 0
        },
        dad = {
            angle = 40,
            color = {1.2, 1.2, 1.2}, 
            brightness = -6,
            hue = 0,
            contrast = 0,
            saturation = 0
        }
    }

    for char, data in pairs(characters) do
        setSpriteShader(char, 'Light_Shader')

        setShaderFloat(char, 'thr', 0.1)
        setShaderFloat(char, 'thr2', 0.1)
        setShaderFloat(char, 'ang', math.rad(data.angle))
        setShaderBool(char, 'useMask', true)
        setShaderFloat(char, 'dist', 15)
        setShaderFloat(char, 'AA_STAGES', 2)
        setShaderFloat(char, 'str', 0.8)
        
        setShaderFloatArray(char, 'dropColor', data.color)
        setShaderFloat(char, 'brightness', data.brightness)
        setShaderFloat(char, 'hue', data.hue)
        setShaderFloat(char, 'contrast', data.contrast)
        setShaderFloat(char, 'saturation', data.saturation)
        setShaderFloat(char, 'lightOpacity', 0.8)
        updateFrameInfo(char)
    end
end

function onUpdatePost()
    if not shadersEnabled then return end
    for char in pairs({boyfriend=true, gf=true, dad=true}) do
        updateFrameInfo(char)
    end
end

function updateFrameInfo(s)
    if getProperty(s..'.pixel') then return end
    setShaderFloatArray(s, 'uFrameBounds', {
        getProperty(s..'.frame.uv.x'),
        getProperty(s..'.frame.uv.y'),
        getProperty(s..'.frame.uv.width'),
        getProperty(s..'.frame.uv.height')
    })
end