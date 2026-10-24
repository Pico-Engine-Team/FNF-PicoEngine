package funkin.data;

import haxe.Json;
using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Pico Engine song preload (scripts/songs/).
 *
 * Preferred paths (first found wins):
 *   scripts/songs/<song>/preload.json
 *   scripts/songs/<song>/preload.lua
 *   mods/.../scripts/songs/<song>/preload.json
 *   mods/.../scripts/songs/<song>/preload.lua
 *
 * Legacy still accepted:
 *   data/songs/<song>/preload.json
 *
 * JSON format (Pico):
 * {
 *   "video_cutscene": { "video": "videos/cutscene" },
 *   "characters_preload": ["bf", "dad", "gf"],
 *   "notetypes_preload": ["Bullet Note", "Beatbox"],
 *   "objects_preload": ["stageback", "stagefront"],
 *   "events_preload": ["songsEvent/MyEvent", "scripts/events/MyEvent"],
 *   "script_preload": ["scripts/characters/bf", "scripts/songs/bopeebo/modchart"]
 * }
 *
 * preload.lua can delay/trigger extra loads via callbacks (see example).
 */
typedef PreloadVideoCutscene = {
	@:optional var video:String;
	@:optional var path:String;
}

typedef PreloadList = {
	@:optional var characters:Array<String>;
	@:optional var noteTypes:Array<String>;
	@:optional var objects:Array<String>;
	@:optional var events:Array<String>;
	@:optional var scripts:Array<String>;
	@:optional var stages:Array<String>;
	@:optional var video:String;
	@:optional var raw:Dynamic;
}

class PreloadData
{
	public static inline var SCRIPT_SONGS_ROOT:String = 'scripts/songs';

	/** Last list loaded for the current song (useful for lua) */
	public static var lastList:PreloadList = null;
	public static var lastSongFolder:String = null;
	public static var lastJsonPath:String = null;
	public static var lastLuaPath:String = null;

	public static function loadForSong(?songFolder:String = null):PreloadList
	{
		var folder:String = songFolder;
		if(folder == null || folder.length < 1)
		{
			try { folder = Song.loadedSongName; } catch(e:Dynamic) { folder = null; }
		}
		if(folder == null && PlayState.SONG != null)
		{
			try { folder = PlayState.SONG.song; } catch(e:Dynamic) { folder = null; }
		}
		if(folder == null || folder.length < 1)
		{
			lastList = empty();
			lastSongFolder = null;
			lastJsonPath = null;
			lastLuaPath = null;
			return lastList;
		}

		try { folder = Paths.formatToSongPath(folder); } catch(e:Dynamic) { folder = folder.trim().toLowerCase().replace(' ', '-'); }
		if(folder == null || folder.length < 1)
		{
			lastList = empty();
			lastSongFolder = null;
			lastJsonPath = null;
			lastLuaPath = null;
			return lastList;
		}
		lastSongFolder = folder;
		lastJsonPath = null;
		lastLuaPath = null;

		var raw:String = readPreloadJson(folder);
		var list:PreloadList = empty();
		if(raw != null && raw.trim().length > 0)
		{
			try
			{
				var data:Dynamic = Json.parse(raw);
				list = parse(data);
			}
			catch(e:Dynamic)
			{
				trace('[PreloadData] Failed to parse preload.json for $folder: $e');
			}
		}

		// Remember if a preload.lua exists (LoadingState / PlayState can run it)
		lastLuaPath = findPreloadLua(folder);
		lastList = list;
		return list;
	}

	public static function empty():PreloadList
	{
		return {
			characters: [],
			noteTypes: [],
			objects: [],
			events: [],
			scripts: [],
			stages: [],
			video: null,
			raw: null
		};
	}

	public static function parse(data:Dynamic):PreloadList
	{
		var list:PreloadList = empty();
		if(data == null) return list;
		list.raw = data;

		// --- Pico structured blocks ---
		var videoBlock:Dynamic = Reflect.field(data, 'video_cutscene');
		if(videoBlock != null)
		{
			var v:Dynamic = Reflect.field(videoBlock, 'video');
			if(v == null) v = Reflect.field(videoBlock, 'path');
			if(v != null && Std.string(v).trim().length > 0)
				list.video = Std.string(v).trim();
		}
		else if(Reflect.hasField(data, 'video'))
		{
			var v2:Dynamic = Reflect.field(data, 'video');
			if(v2 != null) list.video = Std.string(v2).trim();
		}

		list.characters = flexArray(data, [
			'characters_preload', 'characters', 'character_preload'
		]);
		list.noteTypes = flexArray(data, [
			'notetypes_preload', 'noteTypes', 'note_types', 'notetype_preload'
		]);
		list.objects = flexArray(data, [
			'objects_preload', 'oobjects_preload', 'objects', 'stage_objects'
		]);
		list.events = flexArray(data, [
			'events_preload', 'events'
		]);
		list.scripts = flexArray(data, [
			'script_preload', 'scripts_preload', 'scripts'
		]);
		list.stages = flexArray(data, ['stages', 'stage_preload']);

		// Generic arrays

		// images resolved at apply time from objects + characters

		// Legacy Psych map format (only if no structured fields produced anything)
		var hasStructured:Bool =
			list.characters.length > 0 || list.noteTypes.length > 0 ||
			list.objects.length > 0 || list.events.length > 0 ||
			list.scripts.length > 0 ||
			(list.video != null && list.video.length > 0);

		if(!hasStructured)
		{
			for (asset in Reflect.fields(data))
			{
				var filters:Dynamic = Reflect.field(data, asset);
				var path:String = StringTools.trim(asset);
				if(path.length < 1) continue;
				if(path == 'version' || path == 'video_cutscene') continue;

				if(Std.isOfType(filters, Int) || Std.isOfType(filters, Float))
				{
					var f:Int = Std.int(filters);
					if(f >= 0)
					{
						try
						{
							if(!StageData.validateVisibility(f))
								continue;
						}
						catch(e:Dynamic) {}
					}
				}
				else if(Std.isOfType(filters, Array) || Std.isOfType(filters, String) || Reflect.isObject(filters))
				{
					// skip non-legacy blocks already handled
					continue;
				}

				if(StringTools.startsWith(path, 'images/'))
					list.objects.push(path.substr(7));
				else if(StringTools.startsWith(path, 'music/') || StringTools.startsWith(path, 'songs/') || StringTools.startsWith(path, 'sounds/'))
					{ /* ignored in Pico preload v2 */ }
				else
					list.objects.push(path);
			}
		}

		return list;
	}

	/**
	 * Push preload entries into LoadingScreenState + hit Paths.* so assets are cached.
	 *   video_cutscene  → Paths.video
	 *   objects_preload → Paths.image
	 *   characters      → Paths.image (+ character json path)
	 *   noteTypes       → Paths.fileExists / image under notes or scripts
	 *   events/scripts  → Paths.getPath / fileExists
	 */
	public static function applyToLoadingScreenState(list:PreloadList):Void
	{
		if(list == null) return;

		var imgs:Array<String> = [];

		// --- objects_preload → Paths.image ---
		if(list.objects != null)
		{
			for (obj in list.objects)
			{
				if(obj == null || obj.length < 1) continue;
				var path:String = cleanImageKey(obj);
				if(path.length < 1) continue;
				if(!imgs.contains(path))
					imgs.push(path);
				tryPathsImage(path);
			}
		}

		// --- characters_preload → Paths.image + character data path ---
		if(list.characters != null)
		{
			for (c in list.characters)
			{
				if(c == null || c.length < 1) continue;
				var charKey:String = c.trim();
				var img:String = charKey.indexOf('/') >= 0 ? charKey : 'characters/' + charKey;
				if(!imgs.contains(img))
					imgs.push(img);
				tryPathsImage(img);
				tryPathsText('data/characters/' + charKey + '.json');
				tryPathsText('characters/' + charKey + '.json');
			}
		}

		// --- video_cutscene → Paths.video ---
		if(list.video != null && list.video.length > 0)
			tryPathsVideo(list.video);

		// --- notetypes_preload → scripts / images ---
		if(list.noteTypes != null)
		{
			for (nt in list.noteTypes)
			{
				if(nt == null || nt.length < 1) continue;
				var n:String = nt.trim();
				tryPathsText('custom_notetypes/' + n + '.lua');
				tryPathsText('scripts/notetypes/' + n + '.lua');
				tryPathsText('scripts/notes/' + n + '.lua');
				tryPathsImage('notes/' + n);
				tryPathsImage('noteTypes/' + n);
			}
		}

		// --- events_preload ---
		if(list.events != null)
		{
			for (ev in list.events)
			{
				if(ev == null || ev.length < 1) continue;
				var e:String = ev.trim();
				// Allow full relative path or short name
				if(e.indexOf('/') >= 0)
				{
					tryPathsText(e.endsWith('.lua') || e.endsWith('.hx') || e.endsWith('.json') ? e : e + '.lua');
					tryPathsText(e + '.hx');
					tryPathsText(e + '.json');
				}
				else
				{
					tryPathsText('scripts/events/' + e + '.lua');
					tryPathsText('scripts/events/' + e + '.hx');
					tryPathsText('songsEvent/' + e + '.lua');
				}
			}
		}

		// --- script_preload ---
		if(list.scripts != null)
		{
			for (sc in list.scripts)
			{
				if(sc == null || sc.length < 1) continue;
				var s:String = sc.trim();
				if(!(s.endsWith('.lua') || s.endsWith('.hx')))
				{
					tryPathsText(s + '.lua');
					tryPathsText(s + '.hx');
				}
				else
					tryPathsText(s);
			}
		}

		// --- stages (optional) ---
		if(list.stages != null)
		{
			for (st in list.stages)
			{
				if(st == null || st.length < 1) continue;
				tryPathsText('data/stages/' + st + '.json');
				tryPathsImage(st);
			}
		}

		// Queue for LoadingScreen multithreaded image load
		try
		{
			LoadingScreenState.prepare(imgs, [], []);
		}
		catch(e:Dynamic)
		{
			try { LoadingScreenState.prepare(imgs, [], []); } catch(e2:Dynamic) { trace('[PreloadData] applyToLoadingScreenState: ' + e + ' / ' + e2); }
		}
	}

	/** Force Paths.image cache for a key (strips images/ prefix). */
	public static function tryPathsImage(key:String):Void
	{
		var path:String = cleanImageKey(key);
		if(path.length < 1) return;
		try
		{
			Paths.image(path);
		}
		catch(e:Dynamic)
		{
			trace('[PreloadData] Paths.image failed: ' + path + ' → ' + e);
		}
	}

	/** Force Paths.video cache / resolve. */
	public static function tryPathsVideo(key:String):Void
	{
		if(key == null || key.trim().length < 1) return;
		var path:String = key.trim();
		// strip common prefixes / extension
		if(StringTools.startsWith(path, 'videos/'))
			path = path.substr('videos/'.length);
		if(StringTools.startsWith(path, 'video/'))
			path = path.substr('video/'.length);
		for (ext in ['.mp4', '.webm', '.mov', '.avi'])
		{
			if(StringTools.endsWith(path.toLowerCase(), ext))
			{
				path = path.substr(0, path.length - ext.length);
				break;
			}
		}
		try
		{
			// Psych / Pico: Paths.video returns full path string
			var resolved:String = Paths.video(path);
			trace('[PreloadData] Paths.video → ' + resolved);
			#if sys
			if(resolved != null && !sys.FileSystem.exists(resolved))
				trace('[PreloadData] video file missing: ' + resolved);
			#end
		}
		catch(e:Dynamic)
		{
			trace('[PreloadData] Paths.video failed: ' + path + ' → ' + e);
		}
	}

	/** Touch text/script assets so Paths tracks them. */
	public static function tryPathsText(key:String):Void
	{
		if(key == null || key.trim().length < 1) return;
		var path:String = key.trim();
		try
		{
			if(Paths.fileExists(path, TEXT))
			{
				Paths.getTextFromFile(path);
				return;
			}
		}
		catch(e:Dynamic) {}
		try
		{
			var full:String = Paths.getPath(path, TEXT);
			if(full != null)
			{
				#if sys
				if(sys.FileSystem.exists(full))
					sys.io.File.getContent(full);
				#end
			}
		}
		catch(e:Dynamic) {}
	}

	public static function tryPathsSound(key:String):Void
	{
		if(key == null || key.trim().length < 1) return;
		try { Paths.sound(key.trim()); }
		catch(e:Dynamic)
		{
			trace('[PreloadData] Paths.sound failed: ' + key + ' → ' + e);
		}
	}

	public static function tryPathsMusic(key:String):Void
	{
		if(key == null || key.trim().length < 1) return;
		try { Paths.music(key.trim()); }
		catch(e:Dynamic)
		{
			trace('[PreloadData] Paths.music failed: ' + key + ' → ' + e);
		}
	}

	static function cleanImageKey(key:String):String
	{
		if(key == null) return '';
		var path:String = key.trim().split('\\').join('/');
		if(path.length < 1) return '';
		if(StringTools.startsWith(path, 'images/'))
			path = path.substr('images/'.length);
		if(StringTools.startsWith(path, 'assets/images/'))
			path = path.substr('assets/images/'.length);
		for (ext in ['.png', '.xml', '.json'])
		{
			if(StringTools.endsWith(path.toLowerCase(), ext))
			{
				path = path.substr(0, path.length - ext.length);
				break;
			}
		}
		return path;
	}


	public static function prepareSong(?songFolder:String = null):PreloadList
	{
		var list:PreloadList = loadForSong(songFolder);
		applyToLoadingScreenState(list);
		return list;
	}

	/** True if scripts/songs/<song>/preload.lua exists */
	public static function hasPreloadLua(?songFolder:String = null):Bool
	{
		var folder:String = songFolder != null ? Paths.formatToSongPath(songFolder) : lastSongFolder;
		if(folder == null) return false;
		return findPreloadLua(folder) != null;
	}

	public static function getPreloadLuaPath(?songFolder:String = null):String
	{
		var folder:String = songFolder != null ? Paths.formatToSongPath(songFolder) : lastSongFolder;
		if(folder == null) return null;
		return findPreloadLua(folder);
	}

	// ---------- path resolution ----------

	static function readPreloadJson(folder:String):String
	{
		var candidates:Array<String> = [
			SCRIPT_SONGS_ROOT + '/' + folder + '/preload.json',
			'scripts/songs/' + folder + '/preload.json',
			// legacy
			'data/songs/' + folder + '/preload.json',
			'data/' + folder + '/preload.json'
		];

		#if MODS_ALLOWED
		for (mod in tryGetEnabledMods())
		{
			candidates.insert(0, Paths.mods(mod + '/' + SCRIPT_SONGS_ROOT + '/' + folder + '/preload.json'));
			candidates.insert(1, Paths.mods(mod + '/scripts/songs/' + folder + '/preload.json'));
		}
		candidates.insert(0, Paths.mods(SCRIPT_SONGS_ROOT + '/' + folder + '/preload.json'));
		#end

		for (p in candidates)
		{
			if(p == null || p.length < 1) continue;
			var content:String = tryReadText(p);
			if(content != null && content.trim().length > 0)
			{
				lastJsonPath = p;
				return content;
			}
		}
		return null;
	}

	static function findPreloadLua(folder:String):String
	{
		var candidates:Array<String> = [
			SCRIPT_SONGS_ROOT + '/' + folder + '/preload.lua',
			'scripts/songs/' + folder + '/preload.lua'
		];

		#if MODS_ALLOWED
		for (mod in tryGetEnabledMods())
		{
			candidates.insert(0, Paths.mods(mod + '/' + SCRIPT_SONGS_ROOT + '/' + folder + '/preload.lua'));
			candidates.insert(1, Paths.mods(mod + '/scripts/songs/' + folder + '/preload.lua'));
		}
		candidates.insert(0, Paths.mods(SCRIPT_SONGS_ROOT + '/' + folder + '/preload.lua'));
		#end

		for (p in candidates)
		{
			if(p == null || p.length < 1) continue;
			if(fileExists(p))
				return p;
		}
		return null;
	}

	static function tryGetEnabledMods():Array<String>
	{
		try { return Mods.parseList().enabled; }
		catch(e:Dynamic) { return []; }
	}

	static function tryReadText(path:String):String
	{
		#if sys
		try
		{
			if(sys.FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch(e:Dynamic) {}
		#end
		try
		{
			if(Paths.fileExists(path, TEXT))
				return Paths.getTextFromFile(path);
		}
		catch(e:Dynamic) {}
		#if sys
		try
		{
			var full:String = Paths.getPath(path, TEXT, null, true);
			if(full != null && sys.FileSystem.exists(full))
				return sys.io.File.getContent(full);
		}
		catch(e:Dynamic) {}
		#end
		return null;
	}

	static function fileExists(path:String):Bool
	{
		#if sys
		try
		{
			if(sys.FileSystem.exists(path)) return true;
		}
		catch(e:Dynamic) {}
		#end
		try
		{
			if(Paths.fileExists(path, TEXT)) return true;
		}
		catch(e:Dynamic) {}
		#if sys
		try
		{
			var full:String = Paths.getPath(path, TEXT, null, true);
			if(full != null && sys.FileSystem.exists(full)) return true;
		}
		catch(e:Dynamic) {}
		#end
		return false;
	}

	/**
	 * Read array from several possible field names.
	 * Accepts JSON array OR object with numeric/string values as a list of keys.
	 */
	static function flexArray(obj:Dynamic, names:Array<String>):Array<String>
	{
		var out:Array<String> = [];
		if(obj == null) return out;

		for (name in names)
		{
			if(!Reflect.hasField(obj, name)) continue;
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;

			if(Std.isOfType(v, Array))
			{
				for (item in (cast v:Array<Dynamic>))
				{
					if(item == null) continue;
					var s:String = StringTools.trim(Std.string(item));
					if(s.length > 0 && s.toLowerCase() != 'null' && !out.contains(s))
						out.push(s);
				}
				return out;
			}

			// Object used as a set: { "bf": true, "dad": 1 }
			if(Reflect.isObject(v) && !Std.isOfType(v, String))
			{
				for (key in Reflect.fields(v))
				{
					var s:String = StringTools.trim(key);
					if(s.length > 0 && !out.contains(s))
						out.push(s);
				}
				return out;
			}

			if(Std.isOfType(v, String))
			{
				var s:String = StringTools.trim(Std.string(v));
				if(s.length > 0) out.push(s);
				return out;
			}
		}
		return out;
	}
}
