function onCreate()
	for i = 0, getProperty('unspawnNotes.length')-1 do
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'Bullet Note' then
			setPropertyFromGroup('unspawnNotes', i, 'texture', 'mechanics/BULLET'); --Change texture
			setPropertyFromGroup('unspawnNotes', i, 'multSpeed', 1.2); --Change note speed (holy shit 0.6 is good)
			setPropertyFromGroup('unspawnNotes', i, 'missHealth', 0.6); --Change amount of health to take when you miss like a fucking moron
		end
	end
end

ShotsAnimations = {'singUP-Shot', 'singDOWN-Shot', 'singLEFT-Shot', 'singRIGHT-Shot'}
function goodNoteHit(id, noteData, noteType, isSustainNote)
	if noteType == 'Bullet Note' then
		characterPlayAnim('boyfriend', dodgeAnimations[noteData+1], true);
		setProperty('boyfriend.specialAnim', true);

		characterPlayAnim('dad',  ShotsAnimations[noteData+1], true);
		setProperty('dad.specialAnim', true);

		playSound('Notes/gunshot', 0.7, 'shot');
		soundFadeOut('shot', 0.3, 0);
	end
end

local healthDrain = 0;
function noteMiss(id, noteData, noteType, isSustainNote)
	if noteType == 'Bullet Note' then
		playSound('gunshotPierce', 0.7, 'shotmiss');
		soundFadeOut('shotmiss', 0.8, 0.3);

		characterPlayAnim('boyfriend', 'hurt', true);
		setProperty('boyfriend.specialAnim', true);
		healthDrain = healthDrain + 0.6;
	end
end

function onUpdate(elapsed)
	if healthDrain > 0 then
		healthDrain = healthDrain - 0.2 * elapsed;
		setProperty('health', getProperty('health') - 0.2 * elapsed);
		if healthDrain < 0 then
			healthDrain = 0;
		end
	end
end