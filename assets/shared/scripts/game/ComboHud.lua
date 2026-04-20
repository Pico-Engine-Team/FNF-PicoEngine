-- Script de Combo Visual para Psych Engine (sem som)

function onComboMenu(combo)
    -- Verifica se o combo é 20 ou mais e se é múltiplo de 10
    if combo >= 20 and combo % 10 == 0 then
        
        -- Configuração da Imagem
        -- 'combo_pop' deve ser o nome do arquivo .png na pasta mods/images/
        makeLuaSprite('comboPop', 'combo', 400, 250); 
        setObjectCamera('comboPop', 'hud'); -- Faz a imagem ficar fixa na tela (HUD)
        scaleObject('comboPop', 0.8, 0.8); -- Ajusta o tamanho (1.0 é o tamanho original)
        addLuaSprite('comboPop', true);
        
        -- Efeito de Surgimento
        setProperty('comboPop.alpha', 1);
        scaleObject('comboPop', 0.5, 0.5); -- Começa menor para o efeito de "pulo"
        doTweenZoom('zoomIn', 'comboPop', 1.0, 0.1, 'circOut'); -- Aumenta rápido
        
        -- Timer para começar a sumir após meio segundo
        runTimer('esperarParaSumir', 0.5);
    end
end

function onTimerCompleted(tag)
    if tag == 'esperarParaSumir' then
        -- Faz a imagem desaparecer suavemente (Fade out)
        doTweenAlpha('fadeCombo', 'comboPop', 0, 0.3, 'linear');
    end
end

function onTweenCompleted(tag)
    -- Remove o objeto da memória após o fade para não pesar o jogo
    if tag == 'fadeCombo' then
        removeLuaSprite('comboPop', false);
    end
end