package funkin.modding.scripting.psychlua;

using StringTools;

class DeprecatedFunctions
{
	public static function implement(funk:FunkinLuaProgramming)
	{
		var lua:State = funk.lua;
		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLuaProgramming.luaTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, true);
			return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			FunkinLuaProgramming.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance != null && PlayState.instance.getLuaObject(obj) != null) {
				var lo = PlayState.instance.getLuaObject(obj);
				if(lo.animation != null) lo.animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(spr != null && spr.animation != null) {
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			FunkinLuaProgramming.luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance == null || character == null || anim == null) return;
			switch(character.toLowerCase()) {
				case 'dad':
					if(PlayState.instance.dad != null && PlayState.instance.dad.hasAnimation(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if(PlayState.instance.boyfriend != null && PlayState.instance.boyfriend.hasAnimation(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			FunkinLuaProgramming.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(MusicBeatState.getVariables().exists(tag))
				MusicBeatState.getVariables().get(tag).makeGraphic(width, height, CoolUtil.colorFromString(color));
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			FunkinLuaProgramming.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var cock:ModchartSprite = MusicBeatState.getVariables().get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			FunkinLuaProgramming.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(MusicBeatState.getVariables().exists(tag) && indices != null) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					var n:Null<Int> = Std.parseInt(strIndices[i]);
					die.push(n != null ? n : 0);
				}
				var spr:ModchartSprite = MusicBeatState.getVariables().get(tag);
				if(spr != null && spr.animation != null) {
					spr.animation.addByIndices(name, prefix, die, '', framerate, false);
					if(spr.animation.curAnim == null) {
						spr.animation.play(name, true);
					}
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			FunkinLuaProgramming.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '') {
			FunkinLuaProgramming.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).cameras = [LuaUtils.cameraFromString(camera)];
				return true;
			}
			FunkinLuaProgramming.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			FunkinLuaProgramming.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				MusicBeatState.getVariables().get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			FunkinLuaProgramming.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var shit:ModchartSprite = MusicBeatState.getVariables().get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String) {
			FunkinLuaProgramming.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(MusicBeatState.getVariables().get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			FunkinLuaProgramming.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(MusicBeatState.getVariables().exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(MusicBeatState.getVariables().get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
					return true;
				}
				Reflect.setProperty(MusicBeatState.getVariables().get(tag), variable, value);
				return true;
			}
			FunkinLuaProgramming.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(FlxG.sound.music != null)
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			FunkinLuaProgramming.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0) {
			if(FlxG.sound.music != null)
				FlxG.sound.music.fadeOut(duration, toValue);
			FunkinLuaProgramming.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			FunkinLuaProgramming.luaTrace('updateHitboxFromGroup is deprecated! Use updateHitbox instead.', false, true);
		});
	}
}