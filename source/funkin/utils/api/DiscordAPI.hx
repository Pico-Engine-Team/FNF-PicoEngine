package funkin.utils.api;

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;
import lime.app.Application;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import flixel.util.FlxStringUtil;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "1399999583391715359";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordPresence = new DiscordPresence();
	// hides this field from scripts and reflection in general
	@:unreflective private static var __thread:Thread;

	public static function check()
	{
		var enabled:Bool = false;
		try
		{
			if (Preferences.data != null)
				enabled = Preferences.data.discordRPC == true;
		}
		catch (e:Dynamic) {}

		if (enabled)
			initialize();
		else if (isInitialized)
			shutdown();
	}

	public static function prepare()
	{
		var enabled:Bool = false;
		try
		{
			if (Preferences.data != null)
				enabled = Preferences.data.discordRPC == true;
		}
		catch (e:Dynamic) {}

		if (!isInitialized && enabled)
			initialize();

		try
		{
			if (Application.current != null && Application.current.window != null)
			{
				Application.current.window.onClose.add(function() {
					if (isInitialized) shutdown();
				});
			}
		}
		catch (e:Dynamic) {}
	}

	public dynamic static function shutdown()
	{
		if (!isInitialized)
		{
			isInitialized = false;
			return;
		}
		isInitialized = false;
		try
		{
			Discord.Shutdown();
		}
		catch (e:Dynamic)
		{
			trace('Discord: Shutdown error → ' + e);
		}
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		try
		{
			if (request == null)
			{
				changePresence();
				return;
			}

			final user = cast (request[0].username, String);
			final discriminator = cast (request[0].discriminator, String);

			var message = '(Discord) Connected to User ';
			if (discriminator != null && discriminator != '0') // Old discriminators
				message += '($user#$discriminator)';
			else // New Discord IDs/Discriminator system
				message += '($user)';

			trace(message);
		}
		catch (e:Dynamic)
		{
			trace('Discord: onReady error → ' + e);
		}
		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		try
		{
			trace('Discord: Error ($errorCode: ${cast(message, String)})');
		}
		catch (e:Dynamic)
		{
			trace('Discord: Error ($errorCode)');
		}
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		try
		{
			trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
		}
		catch (e:Dynamic)
		{
			trace('Discord: Disconnected ($errorCode)');
		}
	}

	public static function initialize()
	{
		try
		{
			var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
			discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
			discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
			discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
			Discord.Initialize(clientID != null ? clientID : _defaultID, cpp.RawPointer.addressOf(discordHandlers), 1, null);
		}
		catch (e:Dynamic)
		{
			trace('Discord: Initialize failed → ' + e);
			isInitialized = false;
			return;
		}

		if (!isInitialized) trace("Discord Client initialized");

		if (__thread == null)
		{
			__thread = Thread.create(() ->
			{
				while (true)
				{
					try
					{
						if (isInitialized)
						{
							#if DISCORD_DISABLE_IO_THREAD
							Discord.UpdateConnection();
							#end
							Discord.RunCallbacks();
						}
					}
					catch (e:Dynamic) {}

					// Wait 1 second until the next loop...
					Sys.sleep(1.0);
				}
			});
		}
		isInitialized = true;
	}

	public static function changePresence(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, largeImageKey:String = 'icon')
	{
		if (details == null) details = 'In the Menus';
		if (largeImageKey == null || largeImageKey.length < 1) largeImageKey = 'icon';

		var startTimestamp:Float = 0;
		if (hasStartTimestamp == true) startTimestamp = Date.now().getTime();

		var endTs:Float = 0;
		if (endTimestamp != null && endTimestamp > 0)
			endTs = startTimestamp + endTimestamp;

		presence.state = state;
		presence.details = details;
		presence.smallImageKey = smallImageKey;
		presence.largeImageKey = largeImageKey;

		var versionText:String = 'unknown';
		try
		{
			versionText = funkin.states.menus.MainMenuState.PicoVersion;
		}
		catch (e:Dynamic)
		{
			try
			{
				versionText = funkin.states.menus.MainMenuState.psychEngineVersion;
			}
			catch (e2:Dynamic) {}
		}
		if (versionText == null) versionText = 'unknown';
		presence.largeImageText = 'Version (' + versionText + ')';

		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTs / 1000);
		updatePresence();
	}

	public static function updatePresence()
	{
		if (!isInitialized) return;
		try
		{
			Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));
		}
		catch (e:Dynamic)
		{
			trace('Discord: UpdatePresence failed → ' + e);
		}
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String)
	{
		if (newID == null || newID.length < 1)
			newID = _defaultID;

		var change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		try
		{
			var pack:Dynamic = Mods.getPack();
			if (pack != null)
			{
				var rpc:Dynamic = Reflect.field(pack, 'discordRPC');
				if (rpc != null)
				{
					var id:String = Std.string(rpc);
					if (id.length > 0 && id != clientID)
						clientID = id;
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Discord: loadModRPC failed → ' + e);
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		if (lua == null) return;
		Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String) {
			if (newID == null || newID.length < 1) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}

@:allow(funkin.utils.api.DiscordClient)
private final class DiscordPresence
{
	public var state(get, set):String;
	public var details(get, set):String;
	public var smallImageKey(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var __presence:DiscordRichPresence;

	public function new()
	{
		__presence = DiscordRichPresence.create();
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String
	{
		return __presence.state;
	}

	@:noCompletion inline function set_state(value:String):String
	{
		return __presence.state = value;
	}

	@:noCompletion inline function get_details():String
	{
		return __presence.details;
	}

	@:noCompletion inline function set_details(value:String):String
	{
		return __presence.details = value;
	}

	@:noCompletion inline function get_smallImageKey():String
	{
		return __presence.smallImageKey;
	}

	@:noCompletion inline function set_smallImageKey(value:String):String
	{
		return __presence.smallImageKey = value;
	}

	@:noCompletion inline function get_largeImageKey():String
	{
		return __presence.largeImageKey;
	}

	@:noCompletion inline function set_largeImageKey(value:String):String
	{
		return __presence.largeImageKey = value;
	}

	@:noCompletion inline function get_largeImageText():String
	{
		return __presence.largeImageText;
	}

	@:noCompletion inline function set_largeImageText(value:String):String
	{
		return __presence.largeImageText = value;
	}

	@:noCompletion inline function get_startTimestamp():Int
	{
		return __presence.startTimestamp;
	}

	@:noCompletion inline function set_startTimestamp(value:Int):Int
	{
		return __presence.startTimestamp = value;
	}

	@:noCompletion inline function get_endTimestamp():Int
	{
		return __presence.endTimestamp;
	}

	@:noCompletion inline function set_endTimestamp(value:Int):Int
	{
		return __presence.endTimestamp = value;
	}
}
#end
