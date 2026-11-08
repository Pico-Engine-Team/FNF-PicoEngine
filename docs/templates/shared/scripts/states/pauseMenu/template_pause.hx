/**
 * PauseMenuState HScript template
 * Path: scripts/states/pauseMenu/template_pause.hx
 *       (shared assets or mods/<mod>/scripts/states/pauseMenu/)
 *
 * Loaded by PauseMenuState.startPauseScripts()
 * Available: FlxG, Paths, PlayState, Preferences, etc. (Iris/HScript globals)
 */

function onCreate():Void
{
	// Runs when the pause menu opens
	// trace('Pause HScript: onCreate');
}

function onCreatePost():Void
{
	// After default pause UI is built
}

function onUpdate(elapsed:Float):Void
{
	// Every frame while paused
}

function onDestroy():Void
{
	// Pause menu is closing
}

// Optional helpers (call only if PauseMenuState forwards them)
function onPauseMenuSelect(option:String):Void
{
	// option e.g. "Resume", "Restart Song", "Exit to menu"
}

function onPauseMenuConfirm(option:String):Void
{
}
