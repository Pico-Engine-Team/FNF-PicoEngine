package funkin;

import funkin.states.TitleMenuState;
import funkin.utils.windows.Main;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

@:structInit class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var framerate:Int = 60;
	public var fpsDisplay:String = 'FPS Only'; // Pico Engine feature
	public var debugDisplayBG:Float = 0.6; // Pico Engine feature
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var Quality:String = 'Low';
	public var vsync:String = 'Off'; // Pico Engine feature
	public var splashAlpha:Float = 0.6;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = #if !switch false #else true #end;
	public var camZooms:Bool = true;
	public var comboCam:String = 'camHud'; // Pico Engine feature By Betadciu Engine
	public var hideHud:Bool = false;
	public var useCombo:Bool = true; // Pico Engine feature 
	public var useHoldCover:Bool = false; // Pico Engine feature
	public var useHoldAnimation:Bool = false; // Pico Engine feature 
	public var modcharts:Bool = false; // Pico Engine feature
	public var useCharacterNoteStyle:String = 'Both'; // Pico Engine feature
	public var devMode:Bool = false; // Pico Engine feature
	public var showMemory:Bool = false; // Pico Engine feature
	public var clearMemoryOnSongLoad:Bool = true; // Pico Engine feature
	public var clearMemoryOnExitSong:Bool = true; // Pico Engine feature
	public var aggressiveMemory:Bool = false; // Pico Engine feature
	public var autoGcInterval:Int = 0; // seconds, 0 = off - Pico Engine feature

	public var noteOffset:Int = 0;
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]];

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Disabled';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'None';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;

	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'opponentplay' => false, // Pico Engine feature
		'botplay' => false
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public var useEpicRankings:Bool = true; // Pico Engine feature
	public var ScoreTextAccuracy:String = 'Accuracy'; // Pico Engine feature
	public var epicRankings:Float = 20.0; // Pico Engine feature
	public var marvelousWindow:Float = 20.0; // Pico Engine feature
	public var sickWindow:Float = 45.0;
	public var goodWindow:Float = 90.0;
	public var badWindow:Float = 135.0;
	public var safeFrames:Float = 10.0;
	public var guitarHeroSustains:Bool = true;
	public var discordRPC:Bool = true;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';
}

class Preferences
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	static final FPS_DISPLAY_VALUES:Array<String> = ['Disabled', 'FPS Only', 'FPS and Memory', 'Everything'];

	public static var isLowQuality(get, never):Bool;
	static function get_isLowQuality():Bool
		return data.Quality == 'Low';

	public static var isHighQuality(get, never):Bool;
	static function get_isHighQuality():Bool
		return data.Quality == 'High';

	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],
		'mechanic_dodge' => [SPACE], // Pico Engine feature
		'hey_ui'		=> [Q], // Pico Engine feature

		// CUTSCENE/DIALOGUE SKIPS
		'accept_cutscene' => [ENTER], // Pico Enigne Feature
		'key_dialogue' => [Z], // Pico Enigne Feature
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [ENTER],
		'back'			=> [BACKSPACE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'reload_state'	=> [F4], // Pico Engine feature
		'screenshot'    => [F5], // Pico Engine feature
		'fps_display_toggle' => [F3], // Pico Engine feature
		'page_up' => [FlxKey.PAGEUP],
		'page_down' => [FlxKey.PAGEDOWN],
		
		'master_menu_Key'	=> [E], // Pico Engine feature
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT],
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],

		'dodge_ui'		=> [Y],
		'hey_ui'		=> [X],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'screenshot'    => [DPAD_DOWN],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK],
		'reload_state'	=> [NONE]
	];
	
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;
	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function saveSettings():Void
	{
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function toggleFPSDisplay():Void
	{
		var index:Int = FPS_DISPLAY_VALUES.indexOf(data.fpsDisplay);
		index = FlxMath.wrap(index + 1, 0, FPS_DISPLAY_VALUES.length - 1);
		data.fpsDisplay = FPS_DISPLAY_VALUES[index];
		saveSettings();

		if(Main.fpsVar != null)
		{
			Main.fpsVar.visible = (data.fpsDisplay != 'Disabled');
			Main.fpsVar.updateDebugType(data.fpsDisplay);
			Main.fpsVar.updateBackgroundAlpha(data.debugDisplayBG);
		}
	}

	public static function loadPrefs() {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

		normalizeDebugDisplayBG();
		normalizeComboCamera();
		
		if(Main.fpsVar != null) {
			Main.fpsVar.visible = (data.fpsDisplay != 'Disabled');
			Main.fpsVar.updateDebugType(Preferences.data.fpsDisplay);
			Main.fpsVar.updateBackgroundAlpha(Preferences.data.debugDisplayBG);
		}

		#if (!html5 && !switch)
		FlxG.autoPause = Preferences.data.autoPause;

		if(FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if(data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if(save != null)
		{
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	static function normalizeDebugDisplayBG()
	{
		if(data.debugDisplayBG > 1)
			data.debugDisplayBG *= 0.01;
		data.debugDisplayBG = FlxMath.bound(data.debugDisplayBG, 0, 1);
	}

	static function normalizeComboCamera():Void
	{
		var value:Dynamic = Reflect.field(data, 'comboCam');
		if(Std.isOfType(value, Bool))
			data.comboCam = value ? 'camGame' : 'camHud';
		else
		{
			var text:String = value != null ? Std.string(value).toLowerCase().trim() : 'camhud';
			data.comboCam = (text == 'game' || text == 'camgame') ? 'camGame' : 'camHud';
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleMenuState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleMenuState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleMenuState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = turnOn ? TitleMenuState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? TitleMenuState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? TitleMenuState.volumeUpKeys : emptyArray;
	}
}