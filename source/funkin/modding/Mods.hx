package funkin.modding;

import openfl.utils.Assets;
import haxe.Json;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

/**
 * Normalized mod metadata.
 * Supports:
 *   - Pico Engine meta_mod.json (preferred)
 *   - Psych pack.json
 *   - V-Slice mod.json / meta.json
 *   - Polymod _polymod_meta.json
 */
typedef ModPackInfo =
{
	var folder:String;
	var name:String;
	var description:String;
	var version:String;
	var color:Array<Int>;
	var runsGlobally:Bool;
	var restart:Bool;
	var apiVersion:String;
	var format:String; // "pico" | "psych" | "vslice" | "polymod" | "unknown"
	@:optional var icon:String;
	@:optional var category:String;
	@:optional var scripts:Array<String>;
	@:optional var mainScript:String;
	@:optional var credits:Array<String>;
	@:optional var discordRichPresence:Bool;
	@:optional var discordAppId:String;
	@:optional var raw:Dynamic;
};

/**
 * Pico Engine Mods API
 *
 * Load priority (highest → lowest) when resolving a file:
 *   1. currentModDirectory
 *   2. other enabled mods (modsList order, top of list = higher priority)
 *   3. global-running mods (runsGlobally)
 *   4. mods/ root loose files
 *   5. base game assets
 *
 * Metadata files (first found wins):
 *   1. meta_mod.json  (Pico format)
 *   2. pack.json      (Psych)
 *   3. mod.json       (V-Slice)
 *   4. _polymod_meta.json
 *   5. meta.json
 *
 * Icon files:
 *   mod_icon.png / mod_icon-pixel.png  (Pico)
 *   pack.png / pack-pixel.png          (Psych legacy)
 */
class Mods
{
	static public var currentModDirectory:String = '';

	/** If true, enabled list order is top-first (index 0 wins). */
	public static var topModHighestPriority:Bool = true;

	public static final ignoreModFolders:Array<String> =
	[
		'characters',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];

	private static var globalMods:Array<String> = [];
	private static var packCache:Map<String, ModPackInfo> = new Map();

	// ---------- Basic API ----------

	inline public static function getGlobalMods():Array<String>
		return globalMods;

	inline public static function getCurrent():String
		return currentModDirectory != null ? currentModDirectory : '';

	inline public static function hasCurrent():Bool
		return getCurrent().length > 0;

	inline public static function setCurrent(mod:String):Void
	{
		currentModDirectory = (mod != null) ? mod : '';
	}

	inline public static function clearCurrent():Void
		currentModDirectory = '';

	/** Temporarily switch current mod, run callback, restore previous. */
	public static function withMod(mod:String, action:Void->Void):Void
	{
		var prev:String = currentModDirectory;
		setCurrent(mod);
		try
		{
			if(action != null) action();
		}
		catch(e:Dynamic)
		{
			setCurrent(prev);
			throw e;
		}
		setCurrent(prev);
	}

	inline public static function isEnabled(mod:String):Bool
	{
		if(mod == null || mod.length < 1) return false;
		return parseList().enabled.contains(mod);
	}

	inline public static function getEnabled():Array<String>
		return parseList().enabled.copy();

	inline public static function getDisabled():Array<String>
		return parseList().disabled.copy();

	/** Unique mod_Category values from enabled mods (and known folders). */
	public static function getModCategories(?includeEmpty:Bool = false):Array<String>
	{
		var cats:Array<String> = [];
		#if MODS_ALLOWED
		var folders:Array<String> = getModDirectories();
		for (mod in getEnabled())
			if(mod != null && mod.length > 0 && !folders.contains(mod))
				folders.push(mod);
		for (folder in folders)
		{
			var info:ModPackInfo = getPackInfo(folder);
			var c:String = (info != null && info.category != null) ? info.category.trim() : '';
			if(c.length < 1)
			{
				if(includeEmpty && !cats.contains('Uncategorized'))
					cats.push('Uncategorized');
				continue;
			}
			// normalize display
			var key:String = c;
			var found:Bool = false;
			for (existing in cats)
			{
				if(existing.toLowerCase() == key.toLowerCase())
				{
					found = true;
					break;
				}
			}
			if(!found) cats.push(key);
		}
		#end
		return cats;
	}

	/** Mods that belong to a category (case-insensitive). Empty category = Uncategorized. */
	public static function getModsInCategory(category:String):Array<String>
	{
		var out:Array<String> = [];
		if(category == null) return out;
		var want:String = category.trim().toLowerCase();
		#if MODS_ALLOWED
		for (folder in getModDirectories())
		{
			var info:ModPackInfo = getPackInfo(folder);
			var c:String = (info != null && info.category != null && info.category.trim().length > 0)
				? info.category.trim().toLowerCase()
				: 'uncategorized';
			if(c == want || (want == 'uncategorized' && c == 'uncategorized'))
				out.push(folder);
		}
		#end
		return out;
	}


	/**
	 * Full load order for overrides (highest priority first).
	 * Does not include base game — only mod folders.
	 */
	public static function getLoadOrder(?includeGlobal:Bool = true):Array<String>
	{
		var order:Array<String> = [];
		var enabled:Array<String> = parseList().enabled;

		if(hasCurrent() && !order.contains(currentModDirectory))
			order.push(currentModDirectory);

		var enabledOrder:Array<String> = enabled.copy();
		if(!topModHighestPriority)
			enabledOrder.reverse();

		for (mod in enabledOrder)
		{
			if(mod != null && mod.length > 0 && !order.contains(mod))
				order.push(mod);
		}

		if(includeGlobal)
		{
			for (mod in getGlobalMods())
			{
				if(mod != null && mod.length > 0 && !order.contains(mod))
					order.push(mod);
			}
		}
		return order;
	}

	/** Absolute path to a file inside a mod folder (or mods root if mod empty). */
	public static function modPath(?mod:String = null, relative:String = ''):String
	{
		if(mod == null || mod.length < 1)
			return Paths.mods(relative);
		if(relative == null || relative.length < 1)
			return Paths.mods(mod);
		return Paths.mods(mod + '/' + relative);
	}

	/**
	 * Resolve the first existing path for relativeFile using load priority.
	 * Returns null if not found in mods (caller can fall back to assets).
	 */
	public static function resolvePath(relativeFile:String, ?includeModsRoot:Bool = true):String
	{
		#if MODS_ALLOWED
		for (mod in getLoadOrder(true))
		{
			var p:String = modPath(mod, relativeFile);
			if(FileSystem.exists(p))
				return p;
		}
		if(includeModsRoot)
		{
			var root:String = Paths.mods(relativeFile);
			if(FileSystem.exists(root))
				return root;
		}
		#end
		return null;
	}

	/** Script folders to scan (current + globals + enabled), highest first. */
	public static function getScriptFolders(?subfolder:String = 'scripts'):Array<String>
	{
		var folders:Array<String> = [];
		#if MODS_ALLOWED
		for (mod in getLoadOrder(true))
		{
			var p:String = modPath(mod, subfolder);
			if(FileSystem.exists(p) && FileSystem.isDirectory(p) && !folders.contains(p))
				folders.push(p);
		}
		var rootScripts:String = Paths.mods(subfolder);
		if(FileSystem.exists(rootScripts) && FileSystem.isDirectory(rootScripts) && !folders.contains(rootScripts))
			folders.push(rootScripts);
		#end
		return folders;
	}

	/**
	 * Resolve mod icon file path (absolute).
	 * Tries: mod_Icon from meta, mod_icon.png, mod_icon-pixel.png, pack.png, pack-pixel.png
	 */
	public static function resolveModIconPath(folder:String, ?iconName:String = null):String
	{
		#if MODS_ALLOWED
		if(folder == null || folder.length < 1) return null;
		var candidates:Array<String> = [];
		if(iconName != null && iconName.length > 0)
		{
			var base:String = iconName;
			if(StringTools.endsWith(base.toLowerCase(), '.png'))
				base = base.substr(0, base.length - 4);
			candidates.push(Paths.mods(folder + '/' + base + '.png'));
			candidates.push(Paths.mods(folder + '/' + base + '-pixel.png'));
			candidates.push(Paths.mods(folder + '/images/' + base + '.png'));
		}
		candidates.push(Paths.mods(folder + '/mod_icon.png'));
		candidates.push(Paths.mods(folder + '/mod_icon-pixel.png'));
		candidates.push(Paths.mods(folder + '/pack.png'));
		candidates.push(Paths.mods(folder + '/pack-pixel.png'));
		for (p in candidates)
		{
			if(p != null && FileSystem.exists(p))
				return p;
		}
		#end
		return null;
	}

	// ---------- Global mods ----------

	inline public static function pushGlobalMods():Array<String>
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack:ModPackInfo = getPackInfo(mod);
			if(pack != null && pack.runsGlobally)
				globalMods.push(mod);
		}
		return globalMods;
	}

	// ---------- Directories ----------

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if(FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder.toLowerCase()) && !list.contains(folder))
					list.push(folder);
			}
		}
		#end
		return list;
	}

	// ---------- Text merge ----------

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if(defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if(!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if(!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	/**
	 * Collect existing file paths. Order:
	 * base → week → global mods → mods root → enabled (low→high) → current (last = wins if consumer uses last)
	 */
	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		if(FileSystem.exists(path + fileToFind))
			foldersToCheck.push(path + fileToFind);

		if(Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if(!foldersToCheck.contains(pth) && FileSystem.exists(pth))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if(mods)
		{
			for(mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			var folder:String = Paths.mods(fileToFind);
			if(FileSystem.exists(folder) && !foldersToCheck.contains(folder))
				foldersToCheck.push(folder);

			var enabled:Array<String> = parseList().enabled.copy();
			if(topModHighestPriority)
			{
				var i:Int = enabled.length - 1;
				while(i >= 0)
				{
					var mod:String = enabled[i];
					if(mod != null && mod.length > 0 && mod != Mods.currentModDirectory)
					{
						var modFolder:String = Paths.mods(mod + '/' + fileToFind);
						if(FileSystem.exists(modFolder) && !foldersToCheck.contains(modFolder))
							foldersToCheck.push(modFolder);
					}
					i--;
				}
			}
			else
			{
				for (mod in enabled)
				{
					if(mod != null && mod.length > 0 && mod != Mods.currentModDirectory)
					{
						var modFolder:String = Paths.mods(mod + '/' + fileToFind);
						if(FileSystem.exists(modFolder) && !foldersToCheck.contains(modFolder))
							foldersToCheck.push(modFolder);
					}
				}
			}

			if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var curFolder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if(FileSystem.exists(curFolder) && !foldersToCheck.contains(curFolder))
					foldersToCheck.push(curFolder);
			}
		}
		#end
		return foldersToCheck;
	}

	// ---------- Pack / metadata ----------

	/** Raw metadata Dynamic (legacy API). */
	public static function getPack(?folder:String = null):Dynamic
	{
		var info:ModPackInfo = getPackInfo(folder);
		return info != null ? info.raw : null;
	}

	public static function getPackInfo(?folder:String = null):ModPackInfo
	{
		#if MODS_ALLOWED
		if(folder == null) folder = Mods.currentModDirectory;
		if(folder == null || folder.length < 1) return null;

		if(packCache.exists(folder))
			return packCache.get(folder);

		var info:ModPackInfo = loadPackInfo(folder);
		if(info != null)
			packCache.set(folder, info);
		return info;
		#else
		return null;
		#end
	}

	public static function clearPackCache():Void
	{
		packCache = new Map();
	}

	static function loadPackInfo(folder:String):ModPackInfo
	{
		#if MODS_ALLOWED
		// Pico meta_mod.json first, then legacy formats
		var candidates:Array<String> = [
			Paths.mods(folder + '/meta_mod.json'),
			Paths.mods(folder + '/pack.json'),
			Paths.mods(folder + '/mod.json'),
			Paths.mods(folder + '/_polymod_meta.json'),
			Paths.mods(folder + '/meta.json'),
			// Codename Engine style
			Paths.mods(folder + '/data/config.json'),
			Paths.mods(folder + '/config.json'),
			Paths.mods(folder + '/modpack.json')
		];

		for (path in candidates)
		{
			if(!FileSystem.exists(path)) continue;
			try
			{
				#if sys
				var rawJson:String = File.getContent(path);
				#else
				var rawJson:String = Assets.getText(path);
				#end
				if(rawJson == null || rawJson.length < 1) continue;
				var data:Dynamic = null;
				try data = tjson.TJSON.parse(rawJson) catch(e:Dynamic) data = Json.parse(rawJson);
				if(data == null) continue;
				return normalizePack(folder, data, path);
			}
			catch(e:Dynamic)
			{
				trace('[Mods] Failed to parse $path: $e');
			}
		}
		#end
		return {
			folder: folder,
			name: folder,
			description: '',
			version: '',
			color: [255, 255, 255],
			runsGlobally: false,
			restart: false,
			apiVersion: '',
			format: 'unknown',
			icon: null,
			category: null,
			scripts: null,
			mainScript: null,
			credits: null,
			discordRichPresence: false,
			discordAppId: null,
			raw: null
		};
	}

	static function normalizePack(folder:String, data:Dynamic, path:String):ModPackInfo
	{
		var format:String = 'unknown';
		var lowerPath:String = path != null ? path.toLowerCase() : '';
		if(StringTools.endsWith(lowerPath, 'meta_mod.json')) format = 'pico';
		else if(StringTools.endsWith(lowerPath, 'pack.json')) format = 'psych';
		else if(StringTools.endsWith(lowerPath, '_polymod_meta.json')) format = 'polymod';
		else if(StringTools.endsWith(lowerPath, 'mod.json')) format = 'vslice';
		else if(StringTools.endsWith(lowerPath, 'meta.json')) format = 'vslice';
		else if(StringTools.endsWith(lowerPath, 'config.json') || StringTools.endsWith(lowerPath, 'modpack.json')) format = 'codename';

		// Nested Pico sections (objects or arrays-of-pairs tolerated via helpers)
		var assts:Dynamic = Reflect.field(data, 'mod_assts');
		if(assts == null) assts = Reflect.field(data, 'mod_assets');
		var modData:Dynamic = Reflect.field(data, 'mod_data');
		var scriptsRaw:Dynamic = Reflect.field(data, 'mod_scripts');
		var creditsRaw:Dynamic = Reflect.field(data, 'mod_Credits');
		if(creditsRaw == null) creditsRaw = Reflect.field(data, 'mod_credits');

		var name:String = null;
		var description:String = null;
		var mainScript:String = null;
		var version:String = null;
		var apiVersion:String = null;
		var icon:String = null;
		var category:String = null;
		var runsGlobally:Bool = false;
		var restart:Bool = false;
		var discordRP:Bool = false;
		var discordAppId:String = null;
		var color:Array<Int> = [255, 255, 255];
		var scripts:Array<String> = null;
		var credits:Array<String> = null;

		// --- Pico meta_mod.json ---
		if(format == 'pico' || assts != null || modData != null)
		{
			if(format == 'unknown') format = 'pico';

			name = nestedStr(assts, ['mod_Name', 'name', 'title']);
			description = nestedStr(assts, ['mod_Description', 'description', 'desc']);
			mainScript = nestedStr(assts, ['mod_Scripts', 'mod_Script', 'mainScript']);

			version = nestedStr(modData, ['mod_Version', 'version']);
			apiVersion = nestedStr(modData, ['modAPI', 'apiVersion', 'api_version']);
			icon = nestedStr(modData, ['mod_Icon', 'icon']);
			category = nestedStr(modData, ['mod_Category', 'category', 'modCategory', 'type']);
			runsGlobally = nestedBool(modData, ['runsGlobally', 'runs_globally', 'global', 'alwaysActive'], false);
			restart = nestedBool(modData, ['restart', 'requiresRestart'], false);
			discordRP = nestedBool(modData, ['Discord_rich_Presence', 'discordRichPresence', 'discord_rich_presence'], false);
			discordAppId = nestedStr(modData, ['Discord_App_ID', 'discordAppId', 'discord_app_id', 'discordID']);

			var colorRaw:Dynamic = nestedField(modData, ['mod_Color', 'color', 'badgeColor']);
			color = parseColor(colorRaw);

			scripts = parseStringList(scriptsRaw);
			credits = parseStringList(creditsRaw);
		}

		// --- Flat Psych / V-Slice / Polymod fallbacks ---
		if(name == null) name = strField(data, ['name', 'title', 'modName', 'id']);
		if(name == null) name = folder;

		if(description == null)
		{
			description = strField(data, ['description', 'desc']);
			if(description == null)
			{
				var meta:Dynamic = Reflect.field(data, 'meta');
				if(meta != null) description = strField(meta, ['description', 'desc']);
			}
		}
		if(description == null) description = '';

		if(version == null || version.length < 1)
		{
			version = strField(data, ['version', 'modVersion', 'api_version']);
			if(version == null) version = '';
		}

		if(apiVersion == null || apiVersion.length < 1)
		{
			apiVersion = strField(data, ['apiVersion', 'api_version', 'compatibleWith', 'modAPI']);
			if(apiVersion == null) apiVersion = '';
		}

		if(!runsGlobally)
			runsGlobally = boolField(data, ['runsGlobally', 'runs_globally', 'global', 'alwaysActive'], false);
		if(!restart)
			restart = boolField(data, ['restart', 'requiresRestart'], false);

		if(color == null || (color[0] == 255 && color[1] == 255 && color[2] == 255))
		{
			var c:Array<Int> = parseColor(Reflect.field(data, 'color'));
			if(c != null) color = c;
			else
			{
				c = parseColor(Reflect.field(data, 'badgeColor'));
				if(c != null) color = c;
			}
		}
		if(color == null) color = [255, 255, 255];

		if(category == null || category.length < 1)
			category = strField(data, ['mod_Category', 'category', 'modCategory', 'type', 'modType']);

		if(icon == null)
			icon = strField(data, ['mod_Icon', 'icon', 'iconName']);

		if(mainScript == null)
			mainScript = strField(data, ['mod_Scripts', 'mainScript', 'script']);

		if(scripts == null)
			scripts = parseStringList(Reflect.field(data, 'mod_scripts'));
		if(credits == null)
			credits = parseStringList(Reflect.field(data, 'mod_Credits'));

		return {
			folder: folder,
			name: name,
			description: description,
			version: version,
			color: color,
			runsGlobally: runsGlobally,
			restart: restart,
			apiVersion: apiVersion,
			format: format,
			icon: icon,
			category: category,
			scripts: scripts,
			mainScript: mainScript,
			credits: credits,
			discordRichPresence: discordRP,
			discordAppId: discordAppId,
			raw: data
		};
	}

	static function nestedField(obj:Dynamic, names:Array<String>):Dynamic
	{
		if(obj == null) return null;
		// Object style
		for (n in names)
		{
			if(Reflect.hasField(obj, n))
				return Reflect.field(obj, n);
		}
		// Tolerant: if obj is Array of dynamics, skip
		return null;
	}

	static function nestedStr(obj:Dynamic, names:Array<String>):String
	{
		var v:Dynamic = nestedField(obj, names);
		if(v == null) return null;
		var s:String = Std.string(v).trim();
		return (s.length > 0 && s.toLowerCase() != 'null') ? s : null;
	}

	static function nestedBool(obj:Dynamic, names:Array<String>, def:Bool):Bool
	{
		var v:Dynamic = nestedField(obj, names);
		if(v == true || v == false) return v;
		if(v != null)
		{
			var s:String = Std.string(v).toLowerCase();
			if(s == 'true' || s == '1') return true;
			if(s == 'false' || s == '0') return false;
		}
		return def;
	}

	static function parseColor(colorRaw:Dynamic):Array<Int>
	{
		if(colorRaw == null) return null;
		if(Std.isOfType(colorRaw, Array))
		{
			var arr:Array<Dynamic> = cast colorRaw;
			var color:Array<Int> = [];
			for (i in 0...Std.int(Math.min(3, arr.length)))
				color.push(Std.parseInt(Std.string(arr[i])));
			while(color.length < 3) color.push(255);
			return color;
		}
		var s:String = Std.string(colorRaw).trim();
		if(StringTools.startsWith(s, '#'))
		{
			try
			{
				var c:Int = Std.parseInt('0x' + s.substr(1));
				return [(c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF];
			}
			catch(e:Dynamic) {}
		}
		return null;
	}

	static function parseStringList(v:Dynamic):Array<String>
	{
		if(v == null) return null;
		if(Std.isOfType(v, Array))
		{
			var out:Array<String> = [];
			for (item in (cast v:Array<Dynamic>))
			{
				if(item == null) continue;
				var s:String = Std.string(item).trim();
				if(s.length > 0) out.push(s);
			}
			return out.length > 0 ? out : null;
		}
		var asStr:String = Std.string(v).trim();
		if(asStr.length < 1) return null;
		return [asStr];
	}

	static function strField(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return null;
		for (n in names)
		{
			var v:Dynamic = Reflect.field(obj, n);
			if(v == null) continue;
			var s:String = Std.string(v).trim();
			if(s.length > 0 && s.toLowerCase() != 'null') return s;
		}
		return null;
	}

	static function boolField(obj:Dynamic, names:Array<String>, def:Bool):Bool
	{
		if(obj == null) return def;
		for (n in names)
		{
			if(!Reflect.hasField(obj, n)) continue;
			var v:Dynamic = Reflect.field(obj, n);
			if(v == true || v == false) return v;
			if(v != null)
			{
				var s:String = Std.string(v).toLowerCase();
				if(s == 'true' || s == '1') return true;
				if(s == 'false' || s == '0') return false;
			}
		}
		return def;
	}

	// ---------- modsList.txt ----------

	public static var updatedOnState:Bool = false;
	inline public static function parseList():ModsList
	{
		if(!updatedOnState) updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				if(mod.trim().length < 1) continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		}
		catch(e)
		{
			trace(e);
		}
		#end
		return list;
	}

	private static function updateModList()
	{
		#if MODS_ALLOWED
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) && !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		}
		catch(e)
		{
			trace(e);
		}

		for (folder in getModDirectories())
		{
			if(folder.trim().length > 0 && FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder)) &&
			!ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]);
			}
		}

		var fileStr:String = '';
		for (values in list)
		{
			if(fileStr.length > 0) fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		File.saveContent('modsList.txt', fileStr);
		updatedOnState = true;
		clearPackCache();
		#end
	}

	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if(list != null && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end
	}
}
