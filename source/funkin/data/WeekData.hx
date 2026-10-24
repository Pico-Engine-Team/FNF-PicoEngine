package funkin.data;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
using StringTools;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Week file (levels/*.json).
 *
 * Song list only identifies which songs belong to the week.
 * Difficulties, freeplay icon and color come from each song's meta.json
 * (assets/songs/<song>/meta.json) — not from the week file.
 *
 * Week title image is independent from the JSON file name:
 *   "week_title_Path": "storyMode/weekTitles/weekend1"
 * falls back to storymenu/titles/<weekFileName> if missing.
 *
 * songs entry formats still accepted for compatibility:
 *   "Bopeebo"
 *   ["Bopeebo"]
 *   ["Bopeebo", "dad", [146, 113, 253]]  // icon/color ignored if meta exists
 */
typedef WeekFile =
{
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	@:optional var hideStorySongs:Array<String>;
	@:optional var section:Dynamic;
	@:optional var sections:Dynamic;
	/** Path to week title image (without images/ and .png), e.g. storyMode/weekTitles/weekend1 */
	@:optional var week_title_Path:String;
	// New Pico week format (normalized into the fields above on load)
	@:optional var week_Songs:Array<Dynamic>;
	@:optional var Background:String;
	@:optional var props:Array<String>;
	@:optional var weekStoryMode_Name:String;
	@:optional var weekStartUnlocked:Bool;
	@:optional var weekHideTo_storyMode:Bool;
	@:optional var weekhideTo_freeplayMenu:Bool;
	@:optional var weekHideTo_freeplayMenu:Bool;
}

class WeekData
{
	public var folder:String = '';
	static var reloadTargetSection:String = 'freeplay';
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var hideStorySongs:Array<String>;
	public var section:Dynamic;
	public var sections:Dynamic;
	public var week_title_Path:String;
	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile =
		{
			songs: [
				"Bopeebo",
				"Fresh",
				"Dad Battle"
			],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: '',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			hideStorySongs: [],
			section: ['storyMode', 'freeplay'],
			week_title_Path: 'storyMode/weekTitles/week1'
		};
		return weekFile;
	}

	public function new(weekFile:WeekFile, fileName:String)
	{
		if (weekFile != null)
		{
			for (field in Reflect.fields(weekFile))
			{
				if (field == null || field.length < 1) continue;
				try
				{
					if (Reflect.hasField(this, field) || Reflect.fields(this).contains(field))
						Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));
				}
				catch (e:Dynamic) {}
			}
		}

		this.fileName = fileName != null ? fileName : '';
		hideStorySongs = parseHiddenStorySongs(hideStorySongs);
		if (hideStorySongs == null) hideStorySongs = [];

		// Ensure title path always resolves for Story Mode menus
		if (week_title_Path == null || Std.string(week_title_Path).trim().length < 1)
			week_title_Path = defaultWeekTitlePath(this.fileName);
	}

	/**
	 * Resolve the week title image path used by Story Mode / Week Editor.
	 * Prefers week_title_Path; falls back to legacy storymenu/titles/<fileName>.
	 */
	public static function getWeekTitlePath(week:Dynamic, ?fileName:String = null):String
	{
		var path:String = null;
		if (week != null)
		{
			var raw:Dynamic = Reflect.field(week, 'week_title_Path');
			if (raw == null) raw = Reflect.field(week, 'weekTitlePath');
			if (raw == null) raw = Reflect.field(week, 'week_title');
			if (raw != null)
			{
				path = Std.string(raw).trim().replace('\\', '/');
				if (path.length > 0)
				{
					if (path.startsWith('images/')) path = path.substr(7);
					if (path.endsWith('.png')) path = path.substr(0, path.length - 4);
					return path;
				}
			}
		}

		var name:String = fileName;
		if ((name == null || name.length < 1) && week != null)
		{
			var fn:Dynamic = Reflect.field(week, 'fileName');
			if (fn != null) name = Std.string(fn);
		}
		return defaultWeekTitlePath(name);
	}

	public static function defaultWeekTitlePath(?fileName:String = null):String
	{
		var name:String = (fileName != null && fileName.length > 0) ? fileName : 'week1';
		return 'storyMode/weekTitles/' + name;
	}

	/** Check whether a week title image exists for the given path (mods + shared). */
	public static function weekTitleExists(titlePath:String):Bool
	{
		if (titlePath == null || titlePath.trim().length < 1) return false;
		var p = titlePath.trim().replace('\\', '/');
		if (p.startsWith('images/')) p = p.substr(7);
		if (p.endsWith('.png')) p = p.substr(0, p.length - 4);

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(Paths.modsImages(p))) return true;
		}
		catch (e:Dynamic)
		{
			try
			{
				if (FileSystem.exists(Paths.mods('images/' + p + '.png'))) return true;
			}
			catch (e2:Dynamic) {}
		}
		#end
		try
		{
			if (OpenFlAssets.exists(Paths.getPath('images/' + p + '.png', IMAGE), IMAGE)) return true;
		}
		catch (e:Dynamic) {}

		// Legacy Psych path fallback when only the short name was stored
		var legacy = 'storymenu/titles/' + haxe.io.Path.withoutDirectory(p);
		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(Paths.modsImages(legacy))) return true;
		}
		catch (e:Dynamic)
		{
			try
			{
				if (FileSystem.exists(Paths.mods('images/' + legacy + '.png'))) return true;
			}
			catch (e2:Dynamic) {}
		}
		#end
		try
		{
			if (OpenFlAssets.exists(Paths.getPath('images/' + legacy + '.png', IMAGE), IMAGE)) return true;
		}
		catch (e:Dynamic) {}
		return false;
	}

	/** Load graphic path candidates for a week title (first existing wins). */
	public static function resolveWeekTitleImage(titlePath:String, ?fileName:String = null):String
	{
		var candidates:Array<String> = [];
		if (titlePath != null && titlePath.trim().length > 0)
		{
			var p = titlePath.trim().replace('\\', '/');
			if (p.startsWith('images/')) p = p.substr(7);
			if (p.endsWith('.png')) p = p.substr(0, p.length - 4);
			candidates.push(p);
			// If user stored only "weekend1", try under weekTitles
			if (!p.contains('/'))
			{
				candidates.push('storyMode/weekTitles/' + p);
				candidates.push('storymenu/titles/' + p);
			}
		}
		if (fileName != null && fileName.length > 0)
		{
			candidates.push('storyMode/weekTitles/' + fileName);
			candidates.push('storymenu/titles/' + fileName);
		}

		for (c in candidates)
		{
			if (c == null || c.length < 1) continue;
			#if MODS_ALLOWED
			try
			{
				if (FileSystem.exists(Paths.modsImages(c))) return c;
			}
			catch (e:Dynamic)
			{
				try
				{
					if (FileSystem.exists(Paths.mods('images/' + c + '.png'))) return c;
				}
				catch (e2:Dynamic) {}
			}
			#end
			try
			{
				if (OpenFlAssets.exists(Paths.getPath('images/' + c + '.png', IMAGE), IMAGE)) return c;
			}
			catch (e:Dynamic) {}
		}
		return candidates.length > 0 ? candidates[0] : defaultWeekTitlePath(fileName);
	}

	public static function getWeekSongName(song:Dynamic):String
	{
		if (song == null) return '';
		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 0 && data[0] != null) return Std.string(data[0]);
		}
		return Std.string(song);
	}

	/** Optional legacy icon from week song entry [name, icon, color] — meta overrides in freeplay */
	public static function getWeekSongIcon(song:Dynamic, ?fallback:String = 'face'):String
	{
		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 1 && data[1] != null)
			{
				var icon:String = Std.string(data[1]).trim();
				if (icon.length > 0) return icon;
			}
		}
		return fallback;
	}

	/** Optional legacy color from week song entry — meta freeplayColor overrides */
	public static function getWeekSongColor(song:Dynamic, ?fallback:Array<Int> = null):Array<Int>
	{
		if (fallback == null) fallback = [146, 113, 253];
		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 2 && data[2] != null && Std.isOfType(data[2], Array))
			{
				var c:Array<Dynamic> = cast data[2];
				if (c.length >= 3)
					return [Std.int(c[0]), Std.int(c[1]), Std.int(c[2])];
			}
		}
		return fallback;
	}

	public static function parseHiddenStorySongs(value:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		if (value == null) return output;

		if (Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			for (item in array)
				addHiddenSongName(output, item);
		}
		else
		{
			for (item in Std.string(value).split(','))
				addHiddenSongName(output, item);
		}
		return output;
	}

	public static function hiddenStorySongsToText(value:Dynamic):String
	{
		return parseHiddenStorySongs(value).join(', ');
	}

	public static function setHiddenStorySongs(week:Dynamic, value:Dynamic):Array<String>
	{
		var hidden:Array<String> = parseHiddenStorySongs(value);
		if (week != null) Reflect.setField(week, 'hideStorySongs', hidden);
		return hidden;
	}

	public static function visibleStorySongs(week:Dynamic):Array<Dynamic>
	{
		var output:Array<Dynamic> = [];
		if (week == null) return output;

		var rawSongs:Dynamic = Reflect.field(week, 'songs');
		if (rawSongs == null || !Std.isOfType(rawSongs, Array)) return output;

		var songs:Array<Dynamic> = cast rawSongs;
		for (song in songs)
			if (!isStorySongHidden(week, song))
				output.push(song);
		return output;
	}

	public static function visibleStorySongNames(week:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		for (song in visibleStorySongs(week))
			output.push(getWeekSongName(song));
		return output;
	}

	public static function isStorySongHidden(week:Dynamic, song:Dynamic):Bool
	{
		var songName:String = getWeekSongName(song);
		var formattedSong:String = Paths.formatToSongPath(songName);
		for (hidden in parseHiddenStorySongs(week != null ? Reflect.field(week, 'hideStorySongs') : null))
		{
			if (Paths.formatToSongPath(hidden) == formattedSong)
				return true;
		}

		if (Std.isOfType(song, Array))
		{
			var data:Array<Dynamic> = cast song;
			if (data.length > 3 && dynamicBool(data[3]))
				return true;
		}
		return false;
	}

	static function addHiddenSongName(list:Array<String>, value:Dynamic)
	{
		if (value == null) return;
		var name:String = Std.string(value).trim();
		if (name.length < 1) return;

		var formatted:String = Paths.formatToSongPath(name);
		for (existing in list)
			if (Paths.formatToSongPath(existing) == formatted)
				return;
		list.push(name);
	}

	static function dynamicBool(value:Dynamic):Bool
	{
		if (value == null) return false;
		if (Std.isOfType(value, Bool)) return value;

		var clean:String = Std.string(value).toLowerCase().trim();
		return clean == 'true' || clean == '1' || clean == 'yes' || clean == 'hide' || clean == 'hidden';
	}

	public static function reloadWeekFiles(section:Dynamic = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		var targetSection:String = normalizeMenuSection(section);
		reloadTargetSection = targetSection;
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;

		try
		{
			var modList = Mods.parseList();
			if (modList != null && modList.enabled != null)
			{
				for (mod in modList.enabled)
					if (mod != null && mod.length > 0)
						directories.push(Paths.mods(mod + '/'));
			}
		}
		catch (e:Dynamic) {}
		#else
		var directories:Array<String> = [Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('levels/WeeksList.txt'));
		if (sexList == null) sexList = [];
		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'data/levels/' + sexList[i] + '.json';
				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if (j >= originalLength)
						{
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end

						if (weekFile != null && weekMatchesSection(weekFile, targetSection))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'data/levels/';
			if (FileSystem.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				if (listOfWeeks == null) listOfWeeks = [];
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if (FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	public static function normalizeMenuSection(value:Dynamic):String
	{
		if (value == null)
			return null;
		if (Std.isOfType(value, Bool))
			return value ? 'storyMode' : 'freeplay';

		var clean:String = Std.string(value).trim();
		if (clean.length < 1)
			return null;

		switch (clean.toLowerCase())
		{
			case 'story', 'storymode', 'story_mode':
				return 'storyMode';
			case 'free', 'freeplay', 'free_play':
				return 'freeplay';
			case 'extra', 'extras', 'extrafreeplay', 'extra_freeplay', 'extra-freeplay':
				return 'extraFreeplay';
		}
		return clean;
	}

	public static function weekMatchesSection(week:WeekData, targetSection:String):Bool
	{
		if (week == null)
			return false;
		if (targetSection == null)
			return true;

		if (targetSection == 'storyMode' && week.hideStoryMode)
			return false;

		if (targetSection == 'freeplay' && week.hideFreeplay)
			return false;

		var sections:Array<String> = getWeekSections(week);
		if (sections.length < 1)
			return targetSection != 'extraFreeplay';

		for (section in sections)
			if (normalizeMenuSection(section) == targetSection)
				return true;
		return false;
	}

	public static function getWeekSections(week:Dynamic):Array<String>
	{
		var output:Array<String> = [];
		addWeekSections(output, week != null ? Reflect.field(week, 'section') : null);
		addWeekSections(output, week != null ? Reflect.field(week, 'sections') : null);
		return output;
	}

	static function addWeekSections(output:Array<String>, value:Dynamic):Void
	{
		if (value == null)
			return;
		if (Std.isOfType(value, Array))
		{
			for (item in (cast value:Array<Dynamic>))
				addWeekSections(output, item);
			return;
		}

		for (part in Std.string(value).split(','))
		{
			var normalized:String = normalizeMenuSection(part);
			if (normalized != null && normalized.length > 0 && !output.contains(normalized))
				output.push(normalized);
		}
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
				if (weekMatchesSection(weekFile, reloadTargetSection))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		#else
		if (OpenFlAssets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		#end

		if (rawJson != null && rawJson.length > 0)
		{
			var week:WeekFile = cast tjson.TJSON.parse(rawJson);
			normalizeWeekFile(week);
			return week;
		}
		return null;
	}

	/**
	 * Map new Pico week JSON → Psych-compatible WeekFile fields.
	 * New: week_Songs, Background, props, weekStoryMode_Name, weekStartUnlocked, weekHideTo_*, week_title_Path
	 */
	public static function normalizeWeekFile(week:WeekFile):Void
	{
		if(week == null) return;

		// week_Songs → songs
		if((week.songs == null || week.songs.length < 1) && Reflect.hasField(week, 'week_Songs'))
		{
			var ws:Dynamic = Reflect.field(week, 'week_Songs');
			if(ws != null && Std.isOfType(ws, Array))
				week.songs = cast ws;
		}

		// Background → weekBackground
		if((week.weekBackground == null || week.weekBackground.length < 1) && Reflect.hasField(week, 'Background'))
		{
			var bg:Dynamic = Reflect.field(week, 'Background');
			if(bg != null) week.weekBackground = Std.string(bg);
		}

		// props → weekCharacters
		if((week.weekCharacters == null || week.weekCharacters.length < 1) && Reflect.hasField(week, 'props'))
		{
			var props:Dynamic = Reflect.field(week, 'props');
			if(props != null && Std.isOfType(props, Array))
			{
				var arr:Array<String> = [];
				for (p in (cast props:Array<Dynamic>))
					if(p != null) arr.push(Std.string(p));
				week.weekCharacters = arr;
			}
		}

		// weekStoryMode_Name → storyName
		if((week.storyName == null || week.storyName.length < 1) && Reflect.hasField(week, 'weekStoryMode_Name'))
		{
			var sn:Dynamic = Reflect.field(week, 'weekStoryMode_Name');
			if(sn != null) week.storyName = Std.string(sn);
		}

		// weekStartUnlocked → startUnlocked
		if(Reflect.hasField(week, 'weekStartUnlocked'))
		{
			var u:Dynamic = Reflect.field(week, 'weekStartUnlocked');
			if(u == true || u == false) week.startUnlocked = u;
		}

		// weekHideTo_storyMode → hideStoryMode
		if(Reflect.hasField(week, 'weekHideTo_storyMode'))
		{
			var h:Dynamic = Reflect.field(week, 'weekHideTo_storyMode');
			if(h == true || h == false) week.hideStoryMode = h;
		}

		// weekhideTo_freeplayMenu / weekHideTo_freeplayMenu → hideFreeplay
		if(Reflect.hasField(week, 'weekhideTo_freeplayMenu'))
		{
			var h2:Dynamic = Reflect.field(week, 'weekhideTo_freeplayMenu');
			if(h2 == true || h2 == false) week.hideFreeplay = h2;
		}
		else if(Reflect.hasField(week, 'weekHideTo_freeplayMenu'))
		{
			var h3:Dynamic = Reflect.field(week, 'weekHideTo_freeplayMenu');
			if(h3 == true || h3 == false) week.hideFreeplay = h3;
		}

		// week_title_Path aliases
		if(week.week_title_Path == null || Std.string(week.week_title_Path).trim().length < 1)
		{
			var alt:Dynamic = null;
			if(Reflect.hasField(week, 'weekTitlePath')) alt = Reflect.field(week, 'weekTitlePath');
			else if(Reflect.hasField(week, 'week_title')) alt = Reflect.field(week, 'week_title');
			if(alt != null)
			{
				var p = Std.string(alt).trim().replace('\\', '/');
				if(p.startsWith('images/')) p = p.substr(7);
				if(p.endsWith('.png')) p = p.substr(0, p.length - 4);
				if(p.length > 0) week.week_title_Path = p;
			}
		}
		else
		{
			var p = Std.string(week.week_title_Path).trim().replace('\\', '/');
			if(p.startsWith('images/')) p = p.substr(7);
			if(p.endsWith('.png')) p = p.substr(0, p.length - 4);
			week.week_title_Path = p;
		}

		// Defaults for fields that might be missing entirely in new format
		if(week.weekCharacters == null) week.weekCharacters = ['dad', 'bf', 'gf'];
		if(week.weekBackground == null) week.weekBackground = 'stage';
		if(week.weekBefore == null) week.weekBefore = '';
		if(week.storyName == null) week.storyName = week.weekName != null ? week.weekName : '';
		if(week.weekName == null) week.weekName = '';
		if(week.songs == null) week.songs = [];
	}

	public static function getWeekFileName():String
	{
		if (weeksList == null || weeksList.length < 1) return '';
		var idx:Int = 0;
		try { idx = PlayState.storyWeek; } catch (e:Dynamic) { idx = 0; }
		if (idx < 0) idx = 0;
		if (idx >= weeksList.length) idx = weeksList.length - 1;
		return weeksList[idx];
	}

	public static function getCurrentWeek():WeekData
	{
		var name:String = getWeekFileName();
		if (name == null || name.length < 1) return null;
		return weeksLoaded.get(name);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null)
	{
		#if MODS_ALLOWED
		Mods.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
		#end
	}
}
