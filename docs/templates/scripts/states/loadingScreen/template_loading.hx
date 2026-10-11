/**
 * LoadingScreen HScript template
 * Path: scripts/states/loadingScreen/template_loading.hx
 *       (shared assets or mods/<mod>/scripts/states/loadingScreen/)
 *
 * Loaded by LoadingScreenState (must define onCreate).
 * Injected helpers (from engine):
 *   getLoaded():Int   — items already loaded
 *   getLoadMax():Int  — total items to load
 *   barBack, bar      — progress bar sprites (if default UI still created)
 */

function onCreate():Void
{
	// Required: LoadingScreenState looks for this function
	// trace('Loading HScript: onCreate');

	// Example: custom text
	// var t = new FlxText(0, 40, FlxG.width, 'Loading...', 24);
	// t.setFormat(Paths.font('vcr.ttf'), 24, 0xFFFFFFFF, 'center');
	// add(t);
}

function onUpdate(elapsed:Float):Void
{
	// var loaded:Int = getLoaded();
	// var max:Int = getLoadMax();
	// var percent:Float = max > 0 ? loaded / max : 0;
}

function onDestroy():Void
{
}
