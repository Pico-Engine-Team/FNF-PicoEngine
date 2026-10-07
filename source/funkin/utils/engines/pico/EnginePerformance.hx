package funkin.utils.engines.pico;

import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.NoteSplash;
import funkin.data.objects.game.notes.NoteData;

import openfl.system.System;
import flixel.FlxG;

/**
 * Performance + memory helpers for Pico Engine.
 *
 * IMPORTANT: Never call Paths.clearUnusedMemory() while sprites are still
 * on screen / being drawn — that causes Null Object Reference in
 * FlxDrawQuadsItem (bitmap/graphic already destroyed).
 *
 * Call sites:
 *   applyBootHints()       → TitleState after Preferences.loadPrefs
 *   beginSongLoad/endSongLoad
 *   onExitSong()           → PlayState destroy
 *   flushPendingCleanup()  → MainMenu / Freeplay create
 *   updateAutoGc(elapsed)  → menu update only
 */
class EnginePerformance
{
	public static var lastLoadMs:Float = 0;
	public static var lastCleanupMs:Float = 0;
	static var lastAutoGcTime:Float = 0;
	static var bootHintsApplied:Bool = false;
	public static var pendingMenuCleanup:Bool = false;

	public static function isDevMode():Bool
	{
		try { return Preferences.data.devMode == true; }
		catch(e:Dynamic) { return false; }
	}

	public static function wantClearOnSongLoad():Bool
	{
		try { return Preferences.data.clearMemoryOnSongLoad == true; }
		catch(e:Dynamic) { return false; }
	}

	public static function wantClearOnExitSong():Bool
	{
		try { return Preferences.data.clearMemoryOnExitSong != false; }
		catch(e:Dynamic) { return true; }
	}

	public static function isAggressive():Bool
	{
		try { return Preferences.data.aggressiveMemory == true; }
		catch(e:Dynamic) { return false; }
	}

	public static function isLowQuality():Bool
	{
		try
		{
			var q:Dynamic = Reflect.field(Preferences.data, 'Quality');
			if(q == true || q == 'Low' || q == 'low') return true;
		}
		catch(e:Dynamic) {}
		return false;
	}

	public static function getAutoGcInterval():Float
	{
		try
		{
			var v:Dynamic = Reflect.field(Preferences.data, 'autoGcInterval');
			if(v == null) return 0;
			var n:Float = Std.parseFloat(Std.string(v));
			return Math.isNaN(n) ? 0 : n;
		}
		catch(e:Dynamic) { return 0; }
	}

	/** One-shot after Preferences load */
	public static function applyBootHints():Void
	{
		if(bootHintsApplied) return;
		bootHintsApplied = true;
		#if desktop
		try
		{
			var fps:Int = Preferences.data.framerate;
			if(fps > 0)
			{
				FlxG.updateFramerate = fps;
				FlxG.drawFramerate = fps;
			}
		}
		catch(e:Dynamic) {}
		#end
		if(isDevMode())
			trace('[Perf] applyBootHints | lowQuality=${isLowQuality()} | mem=${getMemoryMB()} MB');
	}

	public static function beginSongLoad():Void
	{
		lastLoadMs = haxe.Timer.stamp() * 1000;
		try
		{
			if(wantClearOnSongLoad())
				Paths.clearStoredMemory();
		}
		catch(e:Dynamic) {}
		if(isDevMode())
			trace('[Perf] beginSongLoad | mem=${getMemoryMB()} MB');
	}

	public static function endSongLoad():Void
	{
		lastLoadMs = (haxe.Timer.stamp() * 1000) - lastLoadMs;
		if(isDevMode())
			trace('[Perf] Song load took ${Math.round(lastLoadMs)} ms | mem=${getMemoryMB()} MB');
	}

	public static function onExitSong():Void
	{
		try
		{
			if(Note.noteSkinConfigs != null)
				Note.noteSkinConfigs.clear();
		}
		catch(e:Dynamic) {}

		try { Note.globalRgbShaders = []; } catch(e:Dynamic) {}

		try { NoteData.clearCache(); } catch(e:Dynamic) {}

		if(wantClearOnExitSong())
			pendingMenuCleanup = true;

		if(isDevMode())
			trace('[Perf] onExitSong | pendingCleanup=$pendingMenuCleanup | mem=${getMemoryMB()} MB');
	}

	public static function flushPendingCleanup():Void
	{
		if(!pendingMenuCleanup) return;
		pendingMenuCleanup = false;
		cleanup(isAggressive(), 'menu-after-song');
	}

	public static function cleanup(aggressive:Bool = false, ?reason:String = null):Void
	{
		var t0:Float = haxe.Timer.stamp() * 1000;
		try
		{
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}
		catch(e:Dynamic)
		{
			if(isDevMode())
				trace('[Perf] Paths cleanup error: $e');
		}

		try
		{
			if(NoteSplash.configs != null)
				NoteSplash.configs.clear();
		}
		catch(e:Dynamic) {}

		#if (cpp || hl)
		try { System.gc(); } catch(e:Dynamic) {}
		if(aggressive)
			try { System.gc(); } catch(e:Dynamic) {}
		#end

		lastCleanupMs = (haxe.Timer.stamp() * 1000) - t0;
		if(isDevMode())
			trace('[Perf] cleanup($reason) ${Math.round(lastCleanupMs)} ms | mem=${getMemoryMB()} MB');
	}

	public static function updateAutoGc(elapsed:Float):Void
	{
		var interval:Float = getAutoGcInterval();
		if(interval <= 0) return;
		try { if(PlayState.instance != null) return; } catch(e:Dynamic) {}

		lastAutoGcTime += elapsed;
		if(lastAutoGcTime < interval) return;
		lastAutoGcTime = 0;

		#if (cpp || hl)
		try { System.gc(); } catch(e:Dynamic) {}
		#end
	}

	public static function allowNoteFx():Bool
		return !isLowQuality();

	public static function getMemoryMB():Float
	{
		#if (cpp || hl)
		return Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100) / 100);
		#else
		return 0;
		#end
	}

	public static function formatDevHudLine():String
	{
		if(!isDevMode()) return '';
		return 'MEM: ${getMemoryMB()} MB | load ${Math.round(lastLoadMs)}ms';
	}
}
