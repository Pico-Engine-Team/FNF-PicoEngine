package funkin.modding.scripting.psychlua;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import funkin.utils.Controls;
import funkin.utils.InputFormatter;
import openfl.utils.Assets;

class ExtraFunctions
{
	public static function implement(funk:FunkinLuaProgramming)
	{
		var lua:State = funk.lua;
		
		// Keyboard & Gamepads
		Lua_helper.add_callback(lua, "keyboardJustPressed", function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		Lua_helper.add_callback(lua, "keyboardPressed", function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		Lua_helper.add_callback(lua, "keyboardReleased", function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		Lua_helper.add_callback(lua, "anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name));
		Lua_helper.add_callback(lua, "anyGamepadPressed", function(name:String) return FlxG.gamepads.anyPressed(name));
		Lua_helper.add_callback(lua, "anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name));

		Lua_helper.add_callback(lua, "gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		Lua_helper.add_callback(lua, "gamepadJustPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadPressed", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		Lua_helper.add_callback(lua, "gamepadReleased", function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_P;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_P;
				case 'up': return PlayState.instance.controls.NOTE_UP_P;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_P;
				default: return controlJustPressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyPressed", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT;
				case 'down': return PlayState.instance.controls.NOTE_DOWN;
				case 'up': return PlayState.instance.controls.NOTE_UP;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT;
				default: return controlPressed(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "keyReleased", function(name:String = '') {
			name = name.toLowerCase().trim();
			switch(name) {
				case 'left': return PlayState.instance.controls.NOTE_LEFT_R;
				case 'down': return PlayState.instance.controls.NOTE_DOWN_R;
				case 'up': return PlayState.instance.controls.NOTE_UP_R;
				case 'right': return PlayState.instance.controls.NOTE_RIGHT_R;
				default: return controlJustReleased(name);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getControlKeyName", function(name:String = '', ?alt:Int = 0) {
			return getControlKeyName(name, alt);
		});
		Lua_helper.add_callback(lua, "getControlGamepadName", function(name:String = '', ?alt:Int = 0) {
			return getControlGamepadName(name, alt);
		});
		Lua_helper.add_callback(lua, "getControlBindName", function(name:String = '', ?alt:Int = 0) {
			var keyboard:String = getControlKeyName(name, alt);
			var gamepad:String = getControlGamepadName(name, alt);
			if(gamepad != null && gamepad.length > 0 && gamepad != 'NONE')
				return keyboard + ' / ' + gamepad;
			return keyboard;
		});

		// Save data management
		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods') {
			var variables = MusicBeatState.getVariables();
			if(!variables.exists('save_$name'))
			{
				var save:FlxSave = new FlxSave();
				// folder goes unused for flixel 5 users. @BeastlyGhost
				save.bind(name, CoolUtil.getSavePath() + '/' + folder);
				variables.set('save_$name', save);
				return;
			}
			FunkinLuaProgramming.luaTrace('initSaveData: Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				variables.get('save_$name').flush();
				return;
			}
			FunkinLuaProgramming.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				var saveData = variables.get('save_$name').data;
				if(Reflect.hasField(saveData, field))
					return Reflect.field(saveData, field);
				else
					return defaultValue;
			}
			FunkinLuaProgramming.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return defaultValue;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic) {
			var variables = MusicBeatState.getVariables();
			if(variables.exists('save_$name'))
			{
				Reflect.setField(variables.get('save_$name').data, field, value);
				return;
			}
			FunkinLuaProgramming.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "eraseSaveData", function(name:String)
		{
			var variables = MusicBeatState.getVariables();
			if (variables.exists('save_$name'))
			{
				variables.get('save_$name').erase();
				return;
			}
			FunkinLuaProgramming.luaTrace('eraseSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		// File management
		Lua_helper.add_callback(lua, "checkFileExists", function(filename:String, ?absolute:Bool = false) {
			#if MODS_ALLOWED
			if(absolute) return FileSystem.exists(filename);

			return FileSystem.exists(Paths.getPath(filename, TEXT));

			#else
			if(absolute) return Assets.exists(filename, TEXT);

			return Assets.exists(Paths.getPath(filename, TEXT));
			#end
		});
		Lua_helper.add_callback(lua, "saveFile", function(path:String, content:String, ?absolute:Bool = false)
		{
			try {
				#if MODS_ALLOWED
				if(!absolute)
					File.saveContent(Paths.mods(path), content);
				else
				#end
					File.saveContent(path, content);

				return true;
			} catch (e:Dynamic) {
				FunkinLuaProgramming.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "deleteFile", function(path:String, ?ignoreModFolders:Bool = false, ?absolute:Bool = false)
		{
			try {
				var lePath:String = path;
				if(!absolute) lePath = Paths.getPath(path, TEXT, !ignoreModFolders);
				if(FileSystem.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			} catch (e:Dynamic) {
				FunkinLuaProgramming.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});
		Lua_helper.add_callback(lua, "directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		// String tools
		Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});
		Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});
		Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String) {
			return str.split(split);
		});
		Lua_helper.add_callback(lua, "stringTrim", function(str:String) {
			return str.trim();
		});

		// Randomization
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				if (exclude == '') break;
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});
	}

	static function normalizeControlName(name:String):String
	{
		return name == null ? '' : name.toLowerCase().trim();
	}

	static function controlsInstance():Controls
	{
		if(PlayState.instance != null && PlayState.instance.controls != null)
			return PlayState.instance.controls;
		return Controls.instance;
	}

	static function controlJustPressed(name:String):Bool
	{
		name = normalizeControlName(name);
		var controls:Controls = controlsInstance();
		if(controls != null && (Preferences.keyBinds.exists(name) || Preferences.gamepadBinds.exists(name)))
			return controls.justPressed(name);
		return rawKeyboardInput(name, 'justPressed') || FlxG.gamepads.anyJustPressed(name);
	}

	static function controlPressed(name:String):Bool
	{
		name = normalizeControlName(name);
		var controls:Controls = controlsInstance();
		if(controls != null && (Preferences.keyBinds.exists(name) || Preferences.gamepadBinds.exists(name)))
			return controls.pressed(name);
		return rawKeyboardInput(name, 'pressed') || FlxG.gamepads.anyPressed(name);
	}

	static function controlJustReleased(name:String):Bool
	{
		name = normalizeControlName(name);
		var controls:Controls = controlsInstance();
		if(controls != null && (Preferences.keyBinds.exists(name) || Preferences.gamepadBinds.exists(name)))
			return controls.justReleased(name);
		return rawKeyboardInput(name, 'justReleased') || FlxG.gamepads.anyJustReleased(name);
	}

	static function rawKeyboardInput(name:String, field:String):Bool
	{
		if(name.length < 1)
			return false;

		var input:Dynamic = Reflect.getProperty(FlxG.keys, field);
		return Reflect.getProperty(input, name) == true || Reflect.getProperty(input, name.toUpperCase()) == true;
	}

	static function getControlKeyName(name:String, alt:Int = 0):String
	{
		name = normalizeControlName(name);
		var keys:Array<Null<FlxKey>> = Preferences.keyBinds.get(name);
		if(keys == null || keys.length < 1)
		{
			var rawKey:FlxKey = FlxKey.fromString(name.toUpperCase());
			return InputFormatter.getKeyName(rawKey);
		}

		var index:Int = clampBindIndex(keys.length, alt);
		return InputFormatter.getKeyName(keys[index] != null ? keys[index] : NONE);
	}

	static function getControlGamepadName(name:String, alt:Int = 0):String
	{
		name = normalizeControlName(name);
		var buttons:Array<Null<FlxGamepadInputID>> = Preferences.gamepadBinds.get(name);
		if(buttons == null || buttons.length < 1)
			return '';

		var index:Int = clampBindIndex(buttons.length, alt);
		return InputFormatter.getGamepadName(buttons[index] != null ? buttons[index] : NONE);
	}

	static function clampBindIndex(length:Int, alt:Int):Int
	{
		if(length < 1 || alt < 0)
			return 0;
		if(alt >= length)
			return length - 1;
		return alt;
	}
}
