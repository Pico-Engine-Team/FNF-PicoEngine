package funkin.utils;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
using StringTools;

class CoolUtil {
	public static function checkForUpdates(url:String = null):String {
		if (url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/Pico-Engine-Team/FNF-Pico-Engine/refs/heads/master/gitVersion.txt";

		var version:String = '0.0.0';
		try
		{
			if (funkin.states.menus.MainMenuState.PicoVersion != null)
				version = funkin.states.menus.MainMenuState.PicoVersion.trim();
		}
		catch (e:Dynamic) {}

		var check:Bool = false;
		try
		{
			check = Preferences.data != null && Preferences.data.checkForUpdates;
		}
		catch (e:Dynamic) {}

		if (check) {
			trace('Checking For Engine Update...');
			var http = new haxe.Http(url);
			http.onData = function (data:String)
			{
				if (data == null) return;
				var newVersion:String = data.split('\n')[0].trim();
				trace('version online: $newVersion, your version: $version');
				if (newVersion != version) {
					trace('versions arent matching! please update');
					version = newVersion;
				}
			}
			http.onError = function (error) {
				trace('error: $error');
			}
			try http.request() catch (e:Dynamic) {
				trace('update check failed: $e');
			}
		}
		return version;
	}

	inline public static function quantize(f:Float, snap:Float):Float
	{
		if (snap == 0) return f;
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String):String
	{
		if (text == null || text.length < 1) return '';
		if (text.length == 1) return text.toUpperCase();
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if (path != null && FileSystem.exists(path))
		{
			try daList = File.getContent(path) catch (e:Dynamic) {}
		}
		#else
		if (path != null && Assets.exists(path))
			daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		if (color == null) return FlxColor.WHITE;
		var hideChars = ~/[\t\n\r]/;
		var cleaned:String = hideChars.split(color).join('').trim();
		if (cleaned.startsWith('0x')) cleaned = cleaned.substring(cleaned.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(cleaned);
		if (colorNum == null) colorNum = FlxColor.fromString('#$cleaned');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		if (string == null) return [];
		var daList:Array<String> = string.trim().split('\n');
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		if (sprite == null || sprite.pixels == null) return FlxColor.WHITE;

		var countByColor:Map<Int, Int> = [];
		var fw:Int = sprite.frameWidth;
		var fh:Int = sprite.frameHeight;
		if (fw < 1 || fh < 1) return FlxColor.WHITE;

		for (col in 0...fw)
		{
			for (row in 0...fh)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0;
		countByColor[FlxColor.BLACK] = 0;
		for (key => count in countByColor)
		{
			if (count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);
		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		if (site == null || site.length < 1) return;
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function reloadState(?skipTransition:Bool = false) {
		MusicBeatState.reloadState(skipTransition);
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if (folder == null) return;
			if (!absolute) folder = Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if (folder.endsWith('/')) folder = folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		if (text == null) return;
		if (border == null) border = '';
		switch (border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}
}
