var healthDrain:Float = 0.018;
var minHealth:Float = 0.08;

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	if(name != 'Triggers Tutorial (Darnell Mix)' || Preferences.data.hideHud)
		return;

	switch(value1)
	{
		case '1':
			game.triggerEvent('Change Icon', 'opponent', 'nene, #EB6BA3', strumTime);

		case '2':
			game.triggerEvent('Change Icon', 'gf', 'pico, #B7D855', strumTime);

		case '3':
			game.triggerEvent('Play Animation', 'hey', 'bf', strumTime);
			game.triggerEvent('Play Animation', 'hey', 'gf', strumTime);
			game.triggerEvent('Play Animation', 'hey', 'dad', strumTime);
	}
}

function opponentNoteHit(note:Note)
{
	if(note == null || note.ignoreNote || note.isSustainNote)
		return;

	if(game.health > minHealth)
		game.health = Math.max(minHealth, game.health - healthDrain);
}
