package funkin.data.objects.game.note.config;

import haxe.Json;
import openfl.utils.Assets;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Extra / character strumlines (NMV-style).
 *
 * Chart field:
 *   "extraStrumline": "1" | true | number of extra lines
 *
 * Files:
 *   assets/songs/<songFileName>/charactersStrumlines/<character>.json
 *
 * Example character strumline JSON:
 * {
 *   "character": "pico",
 *   "strumCount": 4,
 *   "x": 0,
 *   "y": 50,
 *   "scale": 0.7,
 *   "scrollSpeed": 1,
 *   "noteStyle": "pico",
 *   "mustPress": false,
 *   "visible": true,
 *   "lanes": [0, 1, 2, 3]
 * }
 */
typedef ExtraStrumlineFile = {
	@:optional var character:String;
	@:optional var strumCount:Int;
	@:optional var x:Float;
	@:optional var y:Float;
	@:optional var scale:Float;
	@:optional var scrollSpeed:Float;
	@:optional var noteStyle:String;
	@:optional var mustPress:Bool;
	@:optional var visible:Bool;
	@:optional var lanes:Array<Int>;
	@:optional var alpha:Float;
	@:optional var layer:Int;
}

class ExtraStrumlineData
{
	public var character:String = '';
	public var strumCount:Int = 4;
	public var x:Float = 0;
	public var y:Float = 50;
	public var scale:Float = 0.7;
	public var scrollSpeed:Float = 1;
	public var noteStyle:String = null;
	public var mustPress:Bool = false;
	public var visible:Bool = true;
	public var lanes:Array<Int> = [0, 1, 2, 3];
	public var alpha:Float = 1;
	public var layer:Int = 0;
	public var fileName:String = '';

	public function new(?file:ExtraStrumlineFile, ?fileName:String = null)
	{
		if(file != null)
		{
			if(file.character != null) character = Std.string(file.character);
			if(file.strumCount != null && file.strumCount > 0) strumCount = file.strumCount;
			if(file.x != null) x = file.x;
			if(file.y != null) y = file.y;
			if(file.scale != null && file.scale > 0) scale = file.scale;
			if(file.scrollSpeed != null && file.scrollSpeed > 0) scrollSpeed = file.scrollSpeed;
			if(file.noteStyle != null) noteStyle = Std.string(file.noteStyle);
			if(file.mustPress != null) mustPress = file.mustPress == true;
			if(file.visible != null) visible = file.visible != false;
			if(file.lanes != null && file.lanes.length > 0) lanes = file.lanes.copy();
			if(file.alpha != null) alpha = file.alpha;
			if(file.layer != null) layer = file.layer;
		}
		this.fileName = fileName != null ? fileName : character;
		if(character.length < 1 && fileName != null) character = fileName;
	}

	/** How many extra strumlines the chart requests */
	public static function getExtraStrumlineCount(song:Dynamic):Int
	{
		if(song == null) return 0;
		var raw:Dynamic = Reflect.field(song, 'extraStrumline');
		if(raw == null) raw = Reflect.field(song, 'extraStrumlines');
		if(raw == null) return 0;
		if(Std.isOfType(raw, Bool)) return raw ? 1 : 0;
		if(Std.isOfType(raw, Float) || Std.isOfType(raw, Int))
		{
			var n:Int = Std.int(raw);
			return n > 0 ? n : 0;
		}
		var s:String = Std.string(raw).trim().toLowerCase();
		if(s == 'true' || s == 'yes') return 1;
		if(s == 'false' || s == 'no' || s == '0' || s == '') return 0;
		var parsed:Null<Int> = Std.parseInt(s);
		return (parsed != null && parsed > 0) ? parsed : 0;
	}

	/**
	 * Folder: songs/<songFileName>/charactersStrumlines/
	 * Loads every *.json as an ExtraStrumlineData.
	 */
	public static function loadForSong(songFileName:String):Array<ExtraStrumlineData>
	{
		var out:Array<ExtraStrumlineData> = [];
		if(songFileName == null || songFileName.length < 1) return out;

		var folderId:String = Paths.formatToSongPath(songFileName);
		var relFolder:String = 'songs/' + folderId + '/charactersStrumlines/';

		var files:Array<String> = listStrumlineFiles(relFolder);
		for (file in files)
		{
			var data = loadFile(relFolder + file);
			if(data != null) out.push(data);
		}
		return out;
	}

	public static function loadCharacter(songFileName:String, character:String):ExtraStrumlineData
	{
		if(songFileName == null || character == null) return null;
		var folderId:String = Paths.formatToSongPath(songFileName);
		var charId:String = Paths.formatToSongPath(character);
		var path:String = 'songs/' + folderId + '/charactersStrumlines/' + charId + '.json';
		return loadFile(path);
	}

	static function loadFile(relPath:String):ExtraStrumlineData
	{
		if(relPath == null) return null;
		var raw:String = null;
		var full:String = Paths.getPath(relPath, TEXT);
		#if MODS_ALLOWED
		try
		{
			if(FileSystem.exists(full))
				raw = File.getContent(full);
			else if(FileSystem.exists(relPath))
				raw = File.getContent(relPath);
		}
		catch(e:Dynamic) {}
		#end
		if(raw == null)
		{
			try
			{
				if(Assets.exists(full))
					raw = Assets.getText(full);
			}
			catch(e:Dynamic) {}
		}
		if(raw == null || raw.length < 1) return null;

		try
		{
			var json:Dynamic = Json.parse(raw);
			var name:String = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(relPath));
			return new ExtraStrumlineData(cast json, name);
		}
		catch(e:Dynamic)
		{
			trace('[ExtraStrumline] Failed to parse ' + relPath + ': ' + e);
			return null;
		}
	}

	static function listStrumlineFiles(relFolder:String):Array<String>
	{
		var out:Array<String> = [];
		#if MODS_ALLOWED
		try
		{
			for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), relFolder))
			{
				if(folder == null || !FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;
				for (file in FileSystem.readDirectory(folder))
				{
					if(file != null && file.toLowerCase().endsWith('.json') && !out.contains(file))
						out.push(file);
				}
			}
		}
		catch(e:Dynamic) {}
		#end
		return out;
	}
}
