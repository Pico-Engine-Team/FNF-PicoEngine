package funkin.modding.scripting.psychlua;

import flixel.FlxObject;

class CustomSubstate extends MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLuaProgramming)
	{
		if (funk == null || funk.lua == null) return;
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "openCustomSubstate", openCustomSubstate);
		Lua_helper.add_callback(lua, "closeCustomSubstate", closeCustomSubstate);
		Lua_helper.add_callback(lua, "insertToCustomSubstate", insertToCustomSubstate);
	}
	#end

	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if (PlayState.instance == null) return;

		if (pauseGame)
		{
			FlxG.camera.followLerp = 0;
			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();
			if (PlayState.instance.vocals != null)
				PlayState.instance.vocals.pause();
		}
		PlayState.instance.openSubState(new CustomSubstate(name != null ? name : 'unnamed'));
	}

	public static function closeCustomSubstate()
	{
		if (instance != null && PlayState.instance != null)
		{
			PlayState.instance.closeSubState();
			return true;
		}
		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if (instance != null && tag != null)
		{
			var tagObject:FlxObject = cast (MusicBeatState.getVariables().get(tag), FlxObject);

			if (tagObject != null)
			{
				if (pos < 0) instance.add(tagObject);
				else instance.insert(pos, tagObject);
				return true;
			}
		}
		return false;
	}

	override function create()
	{
		instance = this;
		if (PlayState.instance != null)
		{
			PlayState.instance.setOnHScript('customSubstate', instance);
			PlayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		}
		super.create();
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String)
	{
		CustomSubstate.name = name != null ? name : 'unnamed';
		if (PlayState.instance != null)
			PlayState.instance.setOnHScript('customSubstateName', CustomSubstate.name);
		super();
		if (FlxG.cameras != null && FlxG.cameras.list != null && FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		if (PlayState.instance != null)
			PlayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		instance = null;
		name = 'unnamed';

		if (PlayState.instance != null)
		{
			PlayState.instance.setOnHScript('customSubstate', null);
			PlayState.instance.setOnHScript('customSubstateName', name);
		}
		super.destroy();
	}
}
