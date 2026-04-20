function onCreate()
	for i = 0, getProperty('unspawnNotes.length') - 1 do
		if getPropertyFromGroup('unspawnNotes', i, 'noteType') == 'Recharge-Note' then
			setPropertyFromGroup('unspawnNotes', i, 'texture', 'notes/mechanics/RechargeNote')
			if getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
			setPropertyFromGroup('unspawnNotes', i, 'ignoreNote', false)
			end
		end
	end
end
function opponentNoteHit(id, direction, noteType)
    if noteType == 'Recharge-Note' then
        triggerEvent('Play Animation', 'Reload', 'dad')
    end
end