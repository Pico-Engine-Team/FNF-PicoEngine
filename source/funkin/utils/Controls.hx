package funkin.utils;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

class Controls
{
	//Keeping same use cases on stuff for it to be easier to understand/use
	//I'd have removed it but this makes it a lot less annoying to use in my opinion

	//You do NOT have to create these variables/getters for adding new keys,
	//but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP

	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	public var PAGE_UP(get, never):Bool;
	public var PAGE_DOWN(get, never):Bool;
	public var CUTSCENES_SKIP(get, never):Bool;
	public var DIALOGUE_SKIP(get, never):Bool;
	public var RELOAD_STATE(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');
	private function get_RELOAD_STATE() return justPressed('reload_state');
	private function get_CUTSCENES_SKIP() return justPressed('accept_cutscene');
	private function get_DIALOGUE_SKIP() return justPressed('key_dialogue');
	private function get_PAGE_UP() return justPressed('page_up');
	private function get_PAGE_DOWN() return justPressed('page_down');

	//Gamepad & Keyboard stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;

	public function justPressed(key:String):Bool
	{
		if (key == null) return false;
		var keys:Array<FlxKey> = keyboardBinds != null ? keyboardBinds.get(key) : null;
		var result:Bool = (keys != null && keys.length > 0 && FlxG.keys.anyJustPressed(keys) == true);
		if (result) controllerMode = false;

		return result || _myGamepadJustPressed(gamepadBinds != null ? gamepadBinds.get(key) : null);
	}

	public function pressed(key:String):Bool
	{
		if (key == null) return false;
		var keys:Array<FlxKey> = keyboardBinds != null ? keyboardBinds.get(key) : null;
		var result:Bool = (keys != null && keys.length > 0 && FlxG.keys.anyPressed(keys) == true);
		if (result) controllerMode = false;

		return result || _myGamepadPressed(gamepadBinds != null ? gamepadBinds.get(key) : null);
	}

	public function justReleased(key:String):Bool
	{
		if (key == null) return false;
		var keys:Array<FlxKey> = keyboardBinds != null ? keyboardBinds.get(key) : null;
		var result:Bool = (keys != null && keys.length > 0 && FlxG.keys.anyJustReleased(keys) == true);
		if (result) controllerMode = false;

		return result || _myGamepadJustReleased(gamepadBinds != null ? gamepadBinds.get(key) : null);
	}

	public var controllerMode:Bool = false;

	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustReleased(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	// IGNORE THESE
	public static var instance:Controls;
	public function new()
	{
		keyboardBinds = Preferences.keyBinds != null ? Preferences.keyBinds : new Map<String, Array<FlxKey>>();
		gamepadBinds = Preferences.gamepadBinds != null ? Preferences.gamepadBinds : new Map<String, Array<FlxGamepadInputID>>();
	}
}
