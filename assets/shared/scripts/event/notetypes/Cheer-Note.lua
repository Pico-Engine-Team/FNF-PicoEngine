local HIT_HEALTH  = 0.010  -- HP ganho ao acertar (padrão: 0.023)
local MISS_HEALTH = 0.000  -- HP perdido ao errar  (padrão: 0.0475)
local CHEER_ANIM  = 'hey-alt' -- Animação tocada ao acertar

function onCreate()
	for i = 0, getProperty('unspawnNotes.length') - 1 do
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'Cheer-Note' then
			-- HP ao acertar e ao errar
			setPropertyFromGroup('unspawnNotes', i, 'hitHealth',  CHEER_ANIM and HIT_HEALTH  or 0);
			setPropertyFromGroup('unspawnNotes', i, 'missHealth', MISS_HEALTH);

			-- Só aplica no player, não no oponente
			if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
				setPropertyFromGroup('unspawnNotes', i, 'ignoreNote', false);
			end
		end
	end
end

function goodNoteHit(id, direction, noteType, isSustainNote)
	if noteType == 'Cheer-Note' and not isSustainNote then
		-- Corrigido: 'hey-alt' com aspas
		characterPlayAnim('boyfriend', CHEER_ANIM, true);
		setProperty('boyfriend.specialAnim', true);

		-- Garante que o HP não passa de 100%
		local currentHP = getProperty('health');
		if currentHP + HIT_HEALTH > 2 then
			setProperty('health', 2); -- 2 = HP máximo no Psych Engine
		end
	end
end

function noteMiss(id, direction, noteType, isSustainNote)
	if noteType == 'Cheer-Note' then
		-- Garante que não perde HP ao errar
		setProperty('missHealth', MISS_HEALTH);
	end
end