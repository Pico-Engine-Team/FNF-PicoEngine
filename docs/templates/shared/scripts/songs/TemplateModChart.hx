// Template ModChart HScript
// Copy this file to one of these paths:
// assets/shared/scripts/songs/modchart.hx or modchart.hxc
// assets/shared/scripts/songs/<song-id>/modchart.hx or modchart.hxc
// assets/shared/scripts/stages/<stage-id>/modchart.hx or modchart.hxc
// mods/<your-mod>/scripts/songs/<song-id>/modchart.hx or modchart.hxc

function onCreate()
{
	// Called before the HUD is fully created.
}

function onCreatePost()
{
	// Called after PlayState finishes create().
}

function onUpdate(elapsed:Float)
{
	// Called near the start of PlayState.update().
}

function onUpdatePost(elapsed:Float)
{
	// Called near the end of PlayState.update().
}

function onModChartPushed(name:String, value1:String, value2:String, strumTime:Float)
{
	// Called once for every event note while the chart loads.
	// Use this to precache assets or prepare data before the event triggers.
}

function eventEarlyTrigger(name:String, value1:String, value2:String, strumTime:Float):Float
{
	// Return a positive value to trigger an event earlier.
	return 0;
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	// Called when an event note triggers.
}

function onDestroy()
{
	// Called when the script is destroyed.
}