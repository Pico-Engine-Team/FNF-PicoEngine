package funkin.utils.engines.pico;

/**
 * Boot / menu asset preload controlled by Preferences.data.assetPreload.
 *
 * Off  → skip
 * Song → only used during song LoadingScreen (see LoadingScreenState)
 * Full → also precache common menu/UI on first TitleState
 *
 * Call from TitleState.create() (once):
 *   funkin.utils.engines.pico.AssetBootPreload.runIfEnabled();
 */
class AssetBootPreload
{
	static var didBootPreload:Bool = false;

	public static function isOff():Bool
	{
		try
		{
			var v:String = Std.string(Reflect.field(Preferences.data, 'assetPreload'));
			if(v == null) return false;
			v = v.toLowerCase();
			return v == 'off' || v == 'disabled' || v == 'none';
		}
		catch(e:Dynamic) return false;
	}

	public static function isFull():Bool
	{
		try
		{
			var v:String = Std.string(Reflect.field(Preferences.data, 'assetPreload'));
			return v != null && v.toLowerCase() == 'full';
		}
		catch(e:Dynamic) return false;
	}

	/** Song load preload allowed (Song or Full). */
	public static function allowSongPreload():Bool
	{
		return !isOff();
	}

	public static function runIfEnabled():Void
	{
		if(didBootPreload) return;
		if(!isFull()) return;
		didBootPreload = true;

		try
		{
			preloadImage('logo');
			preloadImage('mainmenu/menuBG');
			preloadImage('mainmenu/menuDesat');
			preloadImage('mainmenu/menuBGMagenta');
			preloadMusic('menu/freakyMenu');
			preloadSound('confirmMenu');
			preloadSound('cancelMenu');
			preloadSound('scrollMenu');
			trace('[AssetBootPreload] Full boot preload done');
		}
		catch(e:Dynamic)
		{
			trace('[AssetBootPreload] ' + e);
		}
	}

	static function preloadImage(key:String):Void
	{
		if(key == null || key.length < 1) return;
		try Paths.image(key) catch(e:Dynamic) {}
	}

	static function preloadMusic(key:String):Void
	{
		if(key == null || key.length < 1) return;
		try Paths.music(key) catch(e:Dynamic) {}
	}

	static function preloadSound(key:String):Void
	{
		if(key == null || key.length < 1) return;
		try Paths.sound(key) catch(e:Dynamic) {}
	}
}
