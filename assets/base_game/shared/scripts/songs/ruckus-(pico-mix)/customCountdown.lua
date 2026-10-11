function onCreate()
    setProperty('countdownAsset', 'scripts/images/ui/matt') 
end

function onCountdownTick(tick)
    if tick == 1 then
        playSound('scripts/sounds/matt/countdown 1', 1)
    elseif tick == 2 then
        playSound('scripts/sounds/matt/countdown 2', 1)
    end
end