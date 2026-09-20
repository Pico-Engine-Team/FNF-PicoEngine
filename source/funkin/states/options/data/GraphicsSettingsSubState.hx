package funkin.states.options.data;

import funkin.data.objects.game.characters.Character;
import funkin.states.options.config.*;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var antialiasingOption:Int;
	var boyfriend:Character = null;
	public function new()
	{
		title = Language.getPhrase('graphics_menu', 'Graphics Settings');
		rpcTitle = 'Graphics Settings Menu';

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.9));
		boyfriend.updateHitbox();
		boyfriend.dance();
		boyfriend.animation.finishCallback = function (name:String) boyfriend.dance();
		boyfriend.visible = false;

		var option:Option = new Option('Quality',
			'If checked, disables some background details,\ndecreases loading times and improves performance.',
			'Quality',
			STRING,
			['Low', 'High']);
		addOption(option);

		var option:Option = new Option('Anti Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'antialiasing',
			BOOL);
		option.onChange = onChangeAntiAliasing;
		addOption(option);
		antialiasingOption = optionsArray.length - 1;

		var option:Option = new Option('Shaders',
			"If unchecked, disables shaders.\nIt's used for some visual effects, and also CPU intensive for weaker PCs.",
			'shaders',
			BOOL);
		addOption(option);

		var option:Option = new Option('GPU Caching',
			"If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon't turn this on if you have a shitty Graphics Card.",
			'cacheOnGPU',
			BOOL);
		addOption(option);

		var option:Option = new Option('Asset Preload',
			"Pre-load assets to reduce hitching.\nOff = minimal\nSong = music, png/xml, stage, characters when entering a song\nFull = also preload common menu/UI on boot",
			'assetPreload',
			STRING,
			['Off', 'Song', 'Full']);
		addOption(option);

		#if !html5
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			INT);
		addOption(option);

		final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		option.minValue = 30;
		option.maxValue = 1000;
		option.defaultValue = Std.int(FlxMath.bound(refreshRate, option.minValue, option.maxValue));
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		var option:Option = new Option('VSync',
			"Synchronizes the game's frame rate with your monitor's refresh rate.\nOn = Always on\nOff = Always off\nAdaptive = Turns on only when FPS is high enough.",
			'vsync',
			STRING,
			['Adaptive', 'ON', 'OFF']);
		option.onChange = onChangeVSync;
		addOption(option);

		super();
		insert(1, boyfriend);
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var castedSprite:FlxSprite = cast sprite;
			if(castedSprite != null && (castedSprite is FlxSprite) && !(castedSprite is FlxText)) {
				castedSprite.antialiasing = ClientPrefs.data.antialiasing;
			}
		}
	}

	function onChangeVSync()
	{
		#if desktop
		var displayRefresh:Int = 60;
		if (FlxG.stage != null && FlxG.stage.application != null && FlxG.stage.application.window != null)
		{
			try {
				if (FlxG.stage.application.window.displayMode != null)
					displayRefresh = FlxG.stage.application.window.displayMode.refreshRate;
				switch (ClientPrefs.data.vsync)
				{
					case 'On' | 'ON':
						FlxG.stage.application.window.frameRate = displayRefresh;
					case 'Adaptive':
						FlxG.stage.application.window.frameRate = Std.int(Math.max(ClientPrefs.data.framerate, displayRefresh));
					default:
						FlxG.stage.application.window.frameRate = ClientPrefs.data.framerate;
				}
			} catch (e:Dynamic) {
				trace('Error applying VSync/frameRate: ' + e);
			}
		}
		#end
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		boyfriend.visible = (antialiasingOption == curSelected);
	}
}
