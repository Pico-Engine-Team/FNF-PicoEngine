package funkin.utils.windows;

import haxe.io.Path;

/**
 * Points OpenAL Soft at a config file next to the executable (desktop only).
 * Windows: alsoft.ini
 * Other desktop: alsoft.conf
 */
@:keep class ALSoftConfig
{
	#if desktop
	static function __init__():Void
	{
		try
		{
			var origin:String = #if hl
				Sys.getCwd()
			#else
				Sys.programPath()
			#end;

			if (origin == null || origin.length < 1)
				origin = Sys.getCwd();

			var configPath:String = Path.directory(Path.withoutExtension(origin));
			if (configPath == null || configPath.length < 1)
				configPath = Sys.getCwd();

			#if windows
			configPath += "/alsoft.ini";
			#else
			configPath += "/alsoft.conf";
			#end

			Sys.putEnv("ALSOFT_CONF", configPath);
		}
		catch (e:Dynamic)
		{
			// Ignore — OpenAL will use defaults
		}
	}
	#end
}
