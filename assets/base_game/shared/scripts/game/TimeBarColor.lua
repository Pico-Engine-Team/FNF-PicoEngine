-- Script By xdCallMeBOYFRIEND + Mrpolo
-- Customized For [PE 1.0.4]
-- Customized For [Pico Engine 2.3.3h]

dadColor = true;
bfColor = false;
gfColor = false;

function onUpdate()
    if dadColor == true and bfColor == true and gfColor == true then

    elseif dadColor == true then
        dadColR = getProperty('dad.healthColorArray[0]')
        dadColG = getProperty('dad.healthColorArray[1]')
        dadColB = getProperty('dad.healthColorArray[2]')
        dadColFinal = string.format('%02x%02x%02x', dadColR, dadColG, dadColB)
        setTimeBarColors(dadColFinal, "000000")

    elseif bfColor == true then
        bfColR = getProperty('boyfriend.healthColorArray[0]')
        bfColG = getProperty('boyfriend.healthColorArray[1]')
        bfColB = getProperty('boyfriend.healthColorArray[2]')
        bfColFinal = string.format('%02x%02x%02x', bfColR, bfColG, bfColB)
        setTimeBarColors(bfColFinal, "000000")

    elseif gfColor == true then
        gfColR = getProperty('gf.healthColorArray[0]')
        gfColG = getProperty('gf.healthColorArray[1]')
        gfColB = getProperty('gf.healthColorArray[2]')
        gfColFinal = string.format('%02x%02x%02x', gfColR, gfColG, gfColB)
        setTimeBarColors(gfColFinal, "000000")
    end
end