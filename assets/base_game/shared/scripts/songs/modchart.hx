// Global PlayState HScript.
// Put shared modchart/state logic here, or copy this file into a mod at:
// mods/<your-mod>/scripts/songs/modchart.hx
// mods/<your-mod>/scripts/songs/<song-id>/modchart.hx
// mods/<your-mod>/scripts/stages/<stage-id>/modchart.hx

var initialized:Bool = false;

function onCreate()
{
	// Called before the HUD is fully created.
	// This script is loaded early enough to receive onModChartPushed while the chart is generated.
}

function onCreatePost()
{
	initialized = true;
}

function onUpdate(elapsed:Float)
{
	// Runs near the start of PlayState.update().
}

function onUpdatePost(elapsed:Float)
{
	// Runs near the end of PlayState.update().
}

function onModChartPushed(name:String, value1:String, value2:String, strumTime:Float)
{
	// Called once for every event note while the chart loads.
	// Use this for precaching assets or preparing data before the event triggers.
	switch(name)
	{
		case 'Play Sound':
			if(value1 != null && StringTools.trim(value1).length > 0)
				Paths.sound(value1);
	}
}

function eventEarlyTrigger(name:String, value1:String, value2:String, strumTime:Float):Float
{
	// Return a positive value to trigger an event earlier.
	// Example:
	// if(name == 'My Event') return 120;
	return 0;
}

function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{
	// Called when an event note actually triggers.
}

function onDestroy()
{
	initialized = false;
}
