package funkin.play;

import haxe.Json;
import funkin.play.Difficulty;

/**
 * Song metadata (meta.json / meta.txt).
 * Highscores stay Psych (Highscore) — meta never saves scores.
 *
 * Preferred location (new layout):
 *   assets/songs/<songFileName>/meta.json
 *   assets/songs/<songFileName>/meta.txt
 *
 * Extra freeplay:
 *   assets/data/extra-songs/<song>/meta.json
 *   assets/data/extra-songs/<song>/meta.txt
 *
 * Legacy still accepted:
 *   data/songs/<song>/meta.json
 *   data/<song>/meta.json
 *
 * Nested JSON example (Pico + FNF-style):
 * {
 *   "characters_data": { "player": "bf", "girlfriend": "gf", "opponent": "dad" },
 *   "playData": {
 *     "difficulties": ["easy", "normal", "hard"],
 *     "songVariations": ["erect", "pico"],
 *     "stage": "stage",
 *     "noteStyle": "funkin",
 *     "songFileName": "bopeebo",
 *     "displayName": "Bopeebo",
 *     "freeplayIcon": "dad",
 *     "freeplayColor": "#AF66CE",
 *     "playerVocals": "bf",
 *     "opponentVocals": "dad",
 *     "useModCharts": false
 *   },
 *   "song_bpm": { "easy": 100, "normal": 100, "hard": 100 },
 *   "scrollSpeed": { "easy": 1, "normal": 1, "hard": 1.3 }
 * }
 * freeplayColor accepts "#AF66CE" or [175, 102, 206].
 * Meta per variation: meta-pico.json overlays base meta.json.
 * Flat legacy keys (player, stage, chart_Difficulties, ...) still load.
 */

class SongMeta
{
	public static inline var FORMAT_AUTO:String = 'auto';
	public static inline var FORMAT_JSON:String = 'json';
	public static inline var FORMAT_TXT:String = 'txt';

	/**
	 * Folder id under assets/songs/<songFileName>/
	 *   song/*.ogg | charts/*.json | meta.json | events.json | events-global.json
	 * Legacy JSON key "songName" is still accepted when reading.
	 */
	public var songFileName:String = null;
	/** @deprecated use songFileName */
	public var songName(get, set):String;
	function get_songName():String return songFileName;
	function set_songName(v:String):String return songFileName = v;

	public var displayName:String = null;
	public var artist:String = null;
	public var charter:String = null;
	public var album:String = null;
	public var stage:String = null;
	public var noteStyle:String = null;
	public var player:String = null;
	public var opponent:String = null;
	public var girlfriend:String = null;
	public var difficulties:Array<String> = null;
	public var variations:Array<String> = null;
	/** Active variation id (e.g. "pico") */
	public var songVariation:String = null;
	public var bpm:Null<Float> = null;
	public var pauseSong:String = null;
	public var enableSongScripts:Null<Bool> = null;
	public var useModcharts:Null<Bool> = null;
	public var needsVoices:Null<Bool> = null;
	public var opponentMode:Null<Bool> = null;
	public var freeplayIcon:String = null;
	/**
	 * Freeplay tint as "#RRGGBB" after load.
	 * JSON accepts "#AF66CE" or [175, 102, 206].
	 */
	public var freeplayColor:String = null;
	/** FNF metadata: player vocal character id (e.g. "bf") */
	public var playerVocals:String = null;
	/** FNF metadata: opponent vocal character id (e.g. "dad") */
	public var opponentVocals:String = null;
	/** e.g. "-pico" → Inst-pico.ogg */
	public var instSuffix:String = null;
	/** e.g. "-erect" when single Voices track */
	public var vocalsSuffix:String = null;
	/** e.g. "-bf" → Voices-bf.ogg */
	public var vocalPlayerSuffix:String = null;
	/** e.g. "-pico" → Voices-pico.ogg */
	public var vocalOpponentSuffix:String = null;
	/** Per-difficulty BPM: { "easy": 100, "normal": 120, "hard": 140 } */
	public var chart_BPM:Map<String, Float> = null;
	/** Per-difficulty scroll speed: { "easy": 1.5, "normal": 2.4 } */
	public var chart_scrollSpeed:Map<String, Float> = null;

	public var loadedFormat:String = null;
	public var loadedPath:String = null;

	public function new() {}

	public static function getPreferredFormat():String
	{
		try
		{
			var value:Dynamic = Reflect.field(Preferences.data, 'songMetaFormat');
			if(value == null && Preferences.data.gameplaySettings != null)
				value = Preferences.data.gameplaySettings.get('songMetaFormat');
			if(value != null)
			{
				var s:String = Std.string(value).trim().toLowerCase();
				if(s == FORMAT_JSON || s == FORMAT_TXT || s == FORMAT_AUTO)
					return s;
			}
		}
		catch(e:Dynamic) {}
		return FORMAT_AUTO;
	}

	/**
	 * Load meta for song folder id (e.g. "bopeebo").
	 * @param variation     optional: loads meta-<variation>.json first (e.g. meta-pico.json)
	 * @param extraFreeplay also search assets/data/extra-songs/<song>/
	 *
	 * Priority:
	 *   1) meta-<variation>.json / meta-<variation>.txt  (if variation set)
	 *   2) meta.json / meta.txt
	 * Variation fields overlay base meta when both exist.
	 */
	public static function load(songFolder:String, ?formatOverride:String = null, ?extraFreeplay:Bool = false, ?variation:String = null):SongMeta
	{
		if(songFolder == null || songFolder.trim().length < 1)
			return null;

		var folder:String = Paths.formatToSongPath(songFolder);
		if(folder == null || folder.length < 1)
			return null;
		var preferred:String = formatOverride != null ? formatOverride.trim().toLowerCase() : getPreferredFormat();
		if(preferred != FORMAT_JSON && preferred != FORMAT_TXT)
			preferred = FORMAT_AUTO;

		var order:Array<String> = (preferred == FORMAT_TXT)
			? [FORMAT_TXT, FORMAT_JSON]
			: [FORMAT_JSON, FORMAT_TXT];

		var variationKey:String = normalizeVariationKey(variation);
		var baseMeta:SongMeta = null;
		var variationMeta:SongMeta = null;

		for (fmt in order)
		{
			if(baseMeta == null)
				baseMeta = (fmt == FORMAT_JSON) ? loadJson(folder, extraFreeplay, null) : loadTxt(folder, extraFreeplay, null);
			if(variationKey != null && variationMeta == null)
				variationMeta = (fmt == FORMAT_JSON) ? loadJson(folder, extraFreeplay, variationKey) : loadTxt(folder, extraFreeplay, variationKey);
		}

		if(variationMeta != null && baseMeta != null)
		{
			overlayMeta(baseMeta, variationMeta);
			baseMeta.loadedPath = variationMeta.loadedPath;
			baseMeta.loadedFormat = variationMeta.loadedFormat;
			return baseMeta;
		}
		if(variationMeta != null)
			return variationMeta;
		return baseMeta;
	}

	/** "Pico" / "pico" / "meta-pico" → "pico" */
	public static function normalizeVariationKey(?variation:String):String
	{
		if(variation == null) return null;
		var v:String = Paths.formatToSongPath(variation.trim());
		if(v.length < 1) return null;
		if(v == 'default' || v == 'none') return null;
		if(StringTools.startsWith(v, 'meta-'))
			v = v.substr(5);
		return v.length > 0 ? v : null;
	}

	/** Copy non-null fields from overlay onto base (variation wins). */
	static function overlayMeta(base:SongMeta, overlay:SongMeta):Void
	{
		if(base == null || overlay == null) return;
		if(overlay.songFileName != null) base.songFileName = overlay.songFileName;
		if(overlay.displayName != null) base.displayName = overlay.displayName;
		if(overlay.artist != null) base.artist = overlay.artist;
		if(overlay.charter != null) base.charter = overlay.charter;
		if(overlay.album != null) base.album = overlay.album;
		if(overlay.stage != null) base.stage = overlay.stage;
		if(overlay.noteStyle != null) base.noteStyle = overlay.noteStyle;
		if(overlay.player != null) base.player = overlay.player;
		if(overlay.opponent != null) base.opponent = overlay.opponent;
		if(overlay.girlfriend != null) base.girlfriend = overlay.girlfriend;
		if(overlay.difficulties != null) base.difficulties = overlay.difficulties;
		// keep base songVariations list unless overlay explicitly sets it
		if(overlay.variations != null) base.variations = overlay.variations;
		if(overlay.songVariation != null) base.songVariation = overlay.songVariation;
		if(overlay.bpm != null) base.bpm = overlay.bpm;
		if(overlay.pauseSong != null) base.pauseSong = overlay.pauseSong;
		if(overlay.enableSongScripts != null) base.enableSongScripts = overlay.enableSongScripts;
		if(overlay.useModcharts != null) base.useModcharts = overlay.useModcharts;
		if(overlay.needsVoices != null) base.needsVoices = overlay.needsVoices;
		if(overlay.opponentMode != null) base.opponentMode = overlay.opponentMode;
		if(overlay.freeplayIcon != null) base.freeplayIcon = overlay.freeplayIcon;
		if(overlay.freeplayColor != null) base.freeplayColor = overlay.freeplayColor;
		if(overlay.playerVocals != null) base.playerVocals = overlay.playerVocals;
		if(overlay.opponentVocals != null) base.opponentVocals = overlay.opponentVocals;
		if(overlay.vocalPlayerSuffix != null) base.vocalPlayerSuffix = overlay.vocalPlayerSuffix;
		if(overlay.vocalOpponentSuffix != null) base.vocalOpponentSuffix = overlay.vocalOpponentSuffix;
		if(overlay.instSuffix != null) base.instSuffix = overlay.instSuffix;
		if(overlay.vocalsSuffix != null) base.vocalsSuffix = overlay.vocalsSuffix;
		if(overlay.vocalPlayerSuffix != null) base.vocalPlayerSuffix = overlay.vocalPlayerSuffix;
		if(overlay.vocalOpponentSuffix != null) base.vocalOpponentSuffix = overlay.vocalOpponentSuffix;
		if(overlay.chart_BPM != null) base.chart_BPM = overlay.chart_BPM;
		if(overlay.chart_scrollSpeed != null) base.chart_scrollSpeed = overlay.chart_scrollSpeed;
	}

	static function loadJson(folder:String, extraFreeplay:Bool, ?variationKey:String):SongMeta
	{
		for (path in jsonPaths(folder, extraFreeplay, variationKey))
		{
			var raw:String = readText(path);
			if(raw == null || raw.trim().length < 1) continue;
			try
			{
				var meta:SongMeta = fromDynamic(Json.parse(raw));
				if(meta != null)
				{
					meta.loadedFormat = FORMAT_JSON;
					meta.loadedPath = path;
					return meta;
				}
			}
			catch(e:Dynamic)
			{
				trace('[SongMeta] Failed to parse $path: $e');
			}
		}
		return null;
	}

	static function loadTxt(folder:String, extraFreeplay:Bool, ?variationKey:String):SongMeta
	{
		for (path in txtPaths(folder, extraFreeplay, variationKey))
		{
			var raw:String = readText(path);
			if(raw == null || raw.trim().length < 1) continue;
			try
			{
				var meta:SongMeta = fromTxt(raw);
				if(meta != null)
				{
					meta.loadedFormat = FORMAT_TXT;
					meta.loadedPath = path;
					return meta;
				}
			}
			catch(e:Dynamic)
			{
				trace('[SongMeta] Failed to parse $path: $e');
			}
		}
		return null;
	}

	/**
	 * Search order (variation set):
	 *   assets/songs/<song>/meta-<variation>.json
	 *   assets/data/extra-songs/<song>/meta-<variation>.json
	 *   legacy data/.../meta-<variation>.json
	 * Then base meta.json in the same roots.
	 */
	static function jsonPaths(folder:String, extraFreeplay:Bool, ?variationKey:String):Array<String>
	{
		var list:Array<String> = [];
		var fileName:String = (variationKey != null && variationKey.length > 0)
			? ('meta-' + variationKey + '.json')
			: 'meta.json';

		// NEW layout
		try list.push(Paths.getPath(folder + '/' + fileName, TEXT, 'songs', true)) catch(e:Dynamic) {}
		list.push('assets/songs/' + folder + '/' + fileName);

		// Extra freeplay
		try list.push(Paths.getPath('extra-songs/' + folder + '/' + fileName, TEXT, 'data', true)) catch(e:Dynamic) {}
		list.push('assets/data/extra-songs/' + folder + '/' + fileName);

		// Legacy
		list.push('data/songs/' + folder + '/' + fileName);
		list.push('data/' + folder + '/' + fileName);
		if(variationKey == null)
		{
			list.push('data/songs/' + folder + '/' + folder + '-metadata.json');
			list.push('data/' + folder + '/' + folder + '-metadata.json');
		}

		return uniquePaths(list);
	}

	static function txtPaths(folder:String, extraFreeplay:Bool, ?variationKey:String):Array<String>
	{
		var list:Array<String> = [];
		var fileName:String = (variationKey != null && variationKey.length > 0)
			? ('meta-' + variationKey + '.txt')
			: 'meta.txt';

		try list.push(Paths.getPath(folder + '/' + fileName, TEXT, 'songs', true)) catch(e:Dynamic) {}
		list.push('assets/songs/' + folder + '/' + fileName);

		try list.push(Paths.getPath('extra-songs/' + folder + '/' + fileName, TEXT, 'data', true)) catch(e:Dynamic) {}
		list.push('assets/data/extra-songs/' + folder + '/' + fileName);

		list.push('data/songs/' + folder + '/' + fileName);
		list.push('data/' + folder + '/' + fileName);
		return uniquePaths(list);
	}

	static function uniquePaths(list:Array<String>):Array<String>
	{
		var out:Array<String> = [];
		for (p in list)
		{
			if(p == null || p.length < 1) continue;
			if(!out.contains(p)) out.push(p);
		}
		return out;
	}

	static function readText(path:String):String
	{
		if(path == null) return null;
		#if MODS_ALLOWED
		try
		{
			var full:String = Paths.modFolders(path);
			if(full != null && sys.FileSystem.exists(full))
				return sys.io.File.getContent(full);
		}
		catch(e:Dynamic) {}
		try
		{
			if(sys.FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch(e:Dynamic) {}
		#end
		try
		{
			if(openfl.utils.Assets.exists(path))
				return openfl.utils.Assets.getText(path);
		}
		catch(e:Dynamic) {}
		try
		{
			return Paths.getTextFromFile(path);
		}
		catch(e:Dynamic) {}
		return null;
	}

	/** Parse flat Pico meta.json or V-Slice-like nested JSON. */
	public static function fromDynamic(data:Dynamic):SongMeta
	{
		if(data == null) return null;
		var meta:SongMeta = new SongMeta();

		meta.songFileName = strField(data, ['songFileName', 'songName', 'song', 'name']);
		meta.displayName = strField(data, ['displayName', 'display', 'title']);
		meta.artist = joinStringOrArray(data, ['artist', 'composer', 'composers']);
		meta.charter = joinStringOrArray(data, ['charter', 'chartAuthor', 'author']);
		meta.album = strField(data, ['album']);
		meta.bpm = floatField(data, ['bpm']);
		meta.pauseSong = strField(data, ['pauseSong', 'pauseMusic']);
		meta.enableSongScripts = boolField(data, ['enableSongScripts']);
		meta.useModcharts = boolField(data, ['useModcharts', 'useModCharts']);
		meta.needsVoices = boolField(data, ['needsVoices']);
		meta.opponentMode = boolField(data, ['opponentMod', 'opponentMode']);
		meta.freeplayIcon = strField(data, ['freeplayIcon', 'icon']);
		meta.freeplayColor = freeplayColorField(data, ['freeplayColor', 'color']);
		meta.instSuffix = strField(data, ['instSuffix', 'instrumentalSuffix']);
		meta.vocalsSuffix = strField(data, ['vocalsSuffix', 'voicesSuffix']);
		meta.vocalPlayerSuffix = strField(data, ['vocalPlayerSuffix', 'playerVocalsSuffix']);
		meta.vocalOpponentSuffix = strField(data, ['vocalOpponentSuffix', 'opponentVocalsSuffix']);
		meta.playerVocals = strField(data, ['playerVocals', 'playerVocal']);
		meta.opponentVocals = strField(data, ['opponentVocals', 'opponentVocal']);

		// characters_data { player, girlfriend, opponent }
		var charsData:Dynamic = Reflect.field(data, 'characters_data');
		if(charsData == null) charsData = Reflect.field(data, 'charactersData');
		if(charsData == null) charsData = Reflect.field(data, 'characters');
		if(charsData != null)
		{
			if(meta.player == null) meta.player = strField(charsData, ['player', 'bf', 'player1']);
			if(meta.opponent == null) meta.opponent = strField(charsData, ['opponent', 'dad', 'player2']);
			if(meta.girlfriend == null) meta.girlfriend = strField(charsData, ['girlfriend', 'gf', 'gfVersion']);
		}

		// Nested playData (V-Slice + new Pico)
		var playData:Dynamic = Reflect.field(data, 'playData');
		if(playData != null)
		{
			if(meta.stage == null) meta.stage = strField(playData, ['stage']);
			if(meta.noteStyle == null) meta.noteStyle = strField(playData, ['noteStyle', 'noteSkin']);
			if(meta.difficulties == null) meta.difficulties = stringArrayField(playData, ['chart_Difficulties', 'difficulties']);
			if(meta.variations == null) meta.variations = stringArrayField(playData, ['chart_Variations', 'songVariations', 'variations']);
			if(meta.album == null) meta.album = strField(playData, ['album']);
			if(meta.songFileName == null) meta.songFileName = strField(playData, ['songFileName', 'songName', 'song']);
			if(meta.displayName == null) meta.displayName = strField(playData, ['displayName', 'display', 'title']);
			if(meta.freeplayIcon == null) meta.freeplayIcon = strField(playData, ['freeplayIcon', 'icon']);
			if(meta.freeplayColor == null) meta.freeplayColor = freeplayColorField(playData, ['freeplayColor', 'color']);
			if(meta.useModcharts == null) meta.useModcharts = boolField(playData, ['useModcharts', 'useModCharts']);
			if(meta.needsVoices == null) meta.needsVoices = boolField(playData, ['needsVoices']);
			if(meta.opponentMode == null) meta.opponentMode = boolField(playData, ['opponentMod', 'opponentMode']);
			if(meta.pauseSong == null) meta.pauseSong = strField(playData, ['pauseSong', 'pauseMusic']);
			if(meta.playerVocals == null) meta.playerVocals = strField(playData, ['playerVocals', 'playerVocal']);
			if(meta.opponentVocals == null) meta.opponentVocals = strField(playData, ['opponentVocals', 'opponentVocal']);
			if(meta.vocalPlayerSuffix == null) meta.vocalPlayerSuffix = strField(playData, ['vocalPlayerSuffix', 'playerVocalsSuffix']);
			if(meta.vocalOpponentSuffix == null) meta.vocalOpponentSuffix = strField(playData, ['vocalOpponentSuffix', 'opponentVocalsSuffix']);

			var chars:Dynamic = Reflect.field(playData, 'characters');
			if(chars == null) chars = Reflect.field(playData, 'characters_data');
			if(chars != null)
			{
				if(meta.player == null) meta.player = strField(chars, ['player', 'bf', 'player1']);
				if(meta.opponent == null) meta.opponent = strField(chars, ['opponent', 'dad', 'player2']);
				if(meta.girlfriend == null) meta.girlfriend = strField(chars, ['girlfriend', 'gf', 'gfVersion']);
			}
		}

		// Flat keys
		if(meta.stage == null) meta.stage = strField(data, ['stage']);
		if(meta.noteStyle == null) meta.noteStyle = strField(data, ['noteStyle', 'noteSkin']);
		if(meta.player == null) meta.player = strField(data, ['player', 'player1', 'bf']);
		if(meta.opponent == null) meta.opponent = strField(data, ['opponent', 'player2', 'dad']);
		if(meta.girlfriend == null) meta.girlfriend = strField(data, ['girlfriend', 'gfVersion', 'gf']);
		if(meta.difficulties == null) meta.difficulties = stringArrayField(data, ['chart_Difficulties', 'difficulties']);
		if(meta.variations == null) meta.variations = stringArrayField(data, ['chart_Variations', 'songVariations', 'variations']);
		if(meta.songVariation == null) meta.songVariation = strField(data, ['songVariation', 'variation']);

		// playerVocals / opponentVocals → vocal*Suffix for Paths.voices
		if(meta.vocalPlayerSuffix == null && meta.playerVocals != null && meta.playerVocals.length > 0)
			meta.vocalPlayerSuffix = normalizeVocalToken(meta.playerVocals);
		if(meta.vocalOpponentSuffix == null && meta.opponentVocals != null && meta.opponentVocals.length > 0)
			meta.vocalOpponentSuffix = normalizeVocalToken(meta.opponentVocals);

		if(meta.bpm == null)
		{
			var timeChanges:Dynamic = Reflect.field(data, 'timeChanges');
			if(Std.isOfType(timeChanges, Array))
			{
				var arr:Array<Dynamic> = cast timeChanges;
				if(arr.length > 0)
					meta.bpm = floatField(arr[0], ['bpm', 'b']);
			}
		}

		// song_bpm / scrollSpeed (new) + chart_BPM / chart_scrollSpeed (legacy)
		meta.chart_BPM = floatMapField(data, ['song_bpm', 'songBpm', 'chart_BPM', 'chartBpm', 'bpmByDifficulty']);
		meta.chart_scrollSpeed = floatMapField(data, ['scrollSpeed', 'chart_scrollSpeed', 'chartScrollSpeed', 'scrollSpeedByDifficulty']);
		if(playData != null)
		{
			if(meta.chart_BPM == null)
				meta.chart_BPM = floatMapField(playData, ['song_bpm', 'songBpm', 'chart_BPM']);
			if(meta.chart_scrollSpeed == null)
				meta.chart_scrollSpeed = floatMapField(playData, ['scrollSpeed', 'chart_scrollSpeed']);
		}
		if(meta.bpm == null && meta.chart_BPM != null)
		{
			for (k in meta.chart_BPM.keys())
			{
				meta.bpm = meta.chart_BPM.get(k);
				break;
			}
		}

		return meta;
	}

	public static function fromTxt(raw:String):SongMeta
	{
		if(raw == null) return null;
		var map:Map<String, String> = new Map();
		for (line in raw.split('\n'))
		{
			var text:String = StringTools.trim(line);
			if(text.length < 1 || text.startsWith('#') || text.startsWith('//'))
				continue;
			var eq:Int = text.indexOf('=');
			if(eq < 1) continue;
			var key:String = StringTools.trim(text.substr(0, eq)).toLowerCase();
			var value:String = StringTools.trim(text.substr(eq + 1));
			if(key.length > 0)
				map.set(key, value);
		}
		if(!map.keys().hasNext())
			return null;

		var meta:SongMeta = new SongMeta();
		meta.songFileName = mapGet(map, ['songfilename', 'songname', 'song', 'name']);
		meta.displayName = mapGet(map, ['displayname', 'display', 'title']);
		meta.artist = mapGet(map, ['artist', 'composer', 'composers']);
		meta.charter = mapGet(map, ['charter', 'chartauthor', 'author']);
		meta.album = mapGet(map, ['album']);
		meta.stage = mapGet(map, ['stage']);
		meta.noteStyle = mapGet(map, ['notestyle', 'noteskin']);
		meta.player = mapGet(map, ['player', 'player1', 'bf']);
		meta.opponent = mapGet(map, ['opponent', 'player2', 'dad']);
		meta.girlfriend = mapGet(map, ['girlfriend', 'gfversion', 'gf']);
		meta.songVariation = mapGet(map, ['songvariation', 'variation']);
		meta.pauseSong = mapGet(map, ['pausesong', 'pausemusic']);
		meta.freeplayIcon = mapGet(map, ['freeplayicon', 'icon']);
		meta.freeplayColor = mapGet(map, ['freeplaycolor', 'color']);
		meta.instSuffix = mapGet(map, ['instsuffix']);
		meta.vocalsSuffix = mapGet(map, ['vocalssuffix', 'voicessuffix']);
		meta.vocalPlayerSuffix = mapGet(map, ['vocalplayersuffix']);
		meta.vocalOpponentSuffix = mapGet(map, ['vocalopponentsuffix']);

		var bpmStr:String = mapGet(map, ['bpm']);
		if(bpmStr != null)
		{
			var bpm:Float = Std.parseFloat(bpmStr);
			if(!Math.isNaN(bpm)) meta.bpm = bpm;
		}

		var diffStr:String = mapGet(map, ['chart_difficulties', 'difficulties', 'difficulty']);
		if(diffStr != null) meta.difficulties = splitList(diffStr);
		var varStr:String = mapGet(map, ['chart_variations', 'variations', 'songvariations']);
		if(varStr != null) meta.variations = splitList(varStr);

		var scripts:String = mapGet(map, ['enablesongscripts']);
		if(scripts != null) meta.enableSongScripts = (scripts.toLowerCase() == 'true' || scripts == '1');
		var mods:String = mapGet(map, ['usemodcharts', 'usemodcharts']);
		if(mods != null) meta.useModcharts = (mods.toLowerCase() == 'true' || mods == '1');
		var voices:String = mapGet(map, ['needsvoices']);
		if(voices != null) meta.needsVoices = (voices.toLowerCase() == 'true' || voices == '1');
		var opp:String = mapGet(map, ['opponentmod', 'opponentmode']);
		if(opp != null) meta.opponentMode = (opp.toLowerCase() == 'true' || opp == '1');

		return meta;
	}

	public static function fromSong(song:Dynamic):SongMeta
	{
		if(song == null) return new SongMeta();
		var meta:SongMeta = new SongMeta();
		meta.songFileName = strVal(Reflect.field(song, 'songFileName'));
		if(meta.songFileName == null) meta.songFileName = strVal(Reflect.field(song, 'song'));
		meta.displayName = strVal(Reflect.field(song, 'displayName'));
		meta.artist = strVal(Reflect.field(song, 'artist'));
		meta.charter = strVal(Reflect.field(song, 'charter'));
		meta.stage = strVal(Reflect.field(song, 'stage'));
		meta.noteStyle = strVal(Reflect.field(song, 'noteStyle'));
		meta.player = strVal(Reflect.field(song, 'player'));
		if(meta.player == null) meta.player = strVal(Reflect.field(song, 'player1'));
		meta.opponent = strVal(Reflect.field(song, 'opponent'));
		if(meta.opponent == null) meta.opponent = strVal(Reflect.field(song, 'player2'));
		meta.girlfriend = strVal(Reflect.field(song, 'girlfriend'));
		if(meta.girlfriend == null) meta.girlfriend = strVal(Reflect.field(song, 'gfVersion'));
		meta.pauseSong = strVal(Reflect.field(song, 'pauseSong'));
		meta.bpm = floatField(song, ['bpm']);
		meta.enableSongScripts = boolField(song, ['enableSongScripts']);
		meta.useModcharts = boolField(song, ['useModcharts', 'useModCharts']);
		meta.needsVoices = boolField(song, ['needsVoices']);
		meta.difficulties = stringArrayField(song, ['freeplayDifficulties', 'difficulties']);
		meta.variations = stringArrayField(song, ['songVariations', 'variations']);
		meta.songVariation = strVal(Reflect.field(song, 'songVariation'));
		if(meta.songVariation == null) meta.songVariation = strVal(Reflect.field(song, 'variation'));
		meta.instSuffix = strVal(Reflect.field(song, 'instSuffix'));
		meta.vocalsSuffix = strVal(Reflect.field(song, 'vocalsSuffix'));
		meta.vocalPlayerSuffix = strVal(Reflect.field(song, 'vocalPlayerSuffix'));
		meta.vocalOpponentSuffix = strVal(Reflect.field(song, 'vocalOpponentSuffix'));
		return meta;
	}

	/**
	 * Apply meta onto Psych chart fields.
	 * overwriteExisting = false keeps values already set on the chart.
	 */
	public static function applyToSong(song:Dynamic, meta:SongMeta, overwriteExisting:Bool = false):Void
	{
		if(song == null || meta == null) return;

		// songFileName drives folder paths; mirror onto SONG.song for Psych loaders
		if(meta.songFileName != null && meta.songFileName.length > 0)
		{
			var folderId:String = Paths.formatToSongPath(meta.songFileName);
			if(overwriteExisting || emptyField(Reflect.field(song, 'songFileName')))
				Reflect.setField(song, 'songFileName', folderId);
			if(overwriteExisting || emptyField(Reflect.field(song, 'song')))
				Reflect.setField(song, 'song', folderId);
		}
		setIf(song, 'displayName', meta.displayName, overwriteExisting);
		setIf(song, 'artist', meta.artist, overwriteExisting);
		setIf(song, 'charter', meta.charter, overwriteExisting);
		setIf(song, 'stage', meta.stage, overwriteExisting);
		if(meta.noteStyle != null && meta.noteStyle.length > 0)
		{
			if(overwriteExisting || emptyField(Reflect.field(song, 'noteStyle')))
				Reflect.setField(song, 'noteStyle', Song.cleanNoteStyleName(meta.noteStyle));
		}
		// Pico names + Psych legacy aliases
		setIf(song, 'player', meta.player, overwriteExisting);
		setIf(song, 'opponent', meta.opponent, overwriteExisting);
		setIf(song, 'girlfriend', meta.girlfriend, overwriteExisting);
		setIf(song, 'player1', meta.player, overwriteExisting);
		setIf(song, 'player2', meta.opponent, overwriteExisting);
		setIf(song, 'gfVersion', meta.girlfriend, overwriteExisting);
		setIf(song, 'pauseSong', meta.pauseSong, overwriteExisting);

		// BPM: chart_BPM[difficulty] > meta.bpm
		var bpmVal:Null<Float> = null;
		if(meta.chart_BPM != null)
		{
			var diffKey:String = resolveDifficultyKey();
			if(diffKey != null && meta.chart_BPM.exists(diffKey))
				bpmVal = meta.chart_BPM.get(diffKey);
			else if(meta.chart_BPM.exists('normal'))
				bpmVal = meta.chart_BPM.get('normal');
			else
			{
				for (k in meta.chart_BPM.keys()) { bpmVal = meta.chart_BPM.get(k); break; }
			}
		}
		if(bpmVal == null) bpmVal = meta.bpm;
		if(bpmVal != null && !Math.isNaN(bpmVal) && bpmVal > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'bpm') == null || Math.isNaN(Reflect.field(song, 'bpm')) || Reflect.field(song, 'bpm') <= 0)
				Reflect.setField(song, 'bpm', bpmVal);
		}

		// Scroll speed from meta chart_scrollSpeed (replaces chart-owned speed)
		if(meta.chart_scrollSpeed != null)
		{
			var speedVal:Null<Float> = null;
			var diffKey2:String = resolveDifficultyKey();
			if(diffKey2 != null && meta.chart_scrollSpeed.exists(diffKey2))
				speedVal = meta.chart_scrollSpeed.get(diffKey2);
			else if(meta.chart_scrollSpeed.exists('normal'))
				speedVal = meta.chart_scrollSpeed.get('normal');
			else
			{
				for (k in meta.chart_scrollSpeed.keys()) { speedVal = meta.chart_scrollSpeed.get(k); break; }
			}
			if(speedVal != null && !Math.isNaN(speedVal) && speedVal > 0)
			{
				if(overwriteExisting || Reflect.field(song, 'speed') == null || Math.isNaN(Reflect.field(song, 'speed')) || Reflect.field(song, 'speed') <= 0)
					Reflect.setField(song, 'speed', speedVal);
			}
		}
		if(meta.enableSongScripts != null)
		{
			if(overwriteExisting || Reflect.field(song, 'enableSongScripts') == null)
				Reflect.setField(song, 'enableSongScripts', meta.enableSongScripts);
		}
		if(meta.useModcharts != null)
		{
			if(overwriteExisting || Reflect.field(song, 'useModcharts') == null)
				Reflect.setField(song, 'useModcharts', meta.useModcharts);
		}
		if(meta.needsVoices != null)
		{
			if(overwriteExisting || Reflect.field(song, 'needsVoices') == null)
				Reflect.setField(song, 'needsVoices', meta.needsVoices);
		}
		if(meta.difficulties != null && meta.difficulties.length > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'freeplayDifficulties') == null)
				Reflect.setField(song, 'freeplayDifficulties', meta.difficulties.copy());
		}
		if(meta.variations != null && meta.variations.length > 0)
		{
			if(overwriteExisting || Reflect.field(song, 'songVariations') == null)
				Reflect.setField(song, 'songVariations', meta.variations.copy());
			if(overwriteExisting || Reflect.field(song, 'variations') == null)
				Reflect.setField(song, 'variations', meta.variations.copy());
		}
		if(meta.songVariation != null && meta.songVariation.length > 0)
		{
			if(overwriteExisting || emptyField(Reflect.field(song, 'songVariation')))
			{
				Reflect.setField(song, 'songVariation', meta.songVariation);
				Reflect.setField(song, 'variation', meta.songVariation);
			}
		}

		// Audio suffixes (keep leading "-" if provided: "-pico")
		setIf(song, 'instSuffix', meta.instSuffix, overwriteExisting);
		setIf(song, 'vocalsSuffix', meta.vocalsSuffix, overwriteExisting);
		setIf(song, 'vocalPlayerSuffix', meta.vocalPlayerSuffix, overwriteExisting);
		setIf(song, 'vocalOpponentSuffix', meta.vocalOpponentSuffix, overwriteExisting);
		setIf(song, 'playerVocals', meta.playerVocals, overwriteExisting);
		setIf(song, 'opponentVocals', meta.opponentVocals, overwriteExisting);
		// Push vocal tokens into Paths so Paths.voices picks them up
		try
		{
			if(meta.vocalPlayerSuffix != null && meta.vocalPlayerSuffix.length > 0)
				Paths.vocalPlayerSuffix = meta.vocalPlayerSuffix;
			if(meta.vocalOpponentSuffix != null && meta.vocalOpponentSuffix.length > 0)
				Paths.vocalOpponentSuffix = meta.vocalOpponentSuffix;
			if(meta.vocalsSuffix != null && meta.vocalsSuffix.length > 0)
				Paths.vocalsSuffix = meta.vocalsSuffix;
			if(meta.instSuffix != null && meta.instSuffix.length > 0)
				Paths.instSuffix = meta.instSuffix;
		}
		catch(e:Dynamic) {}
		try Paths.applyAudioSuffixesFromMeta(meta) catch(e:Dynamic) {}
	}

	public function getDisplayName(?fallback:String = null):String
	{
		if(displayName != null && displayName.trim().length > 0)
			return displayName.trim();
		if(songFileName != null && songFileName.trim().length > 0)
			return songFileName.trim();
		if(fallback != null) return fallback;
		return '';
	}

	public function getDifficulties(?fallback:Array<String> = null):Array<String>
	{
		if(difficulties != null && difficulties.length > 0)
			return difficulties.copy();
		return fallback != null ? fallback.copy() : [];
	}

	public function getVariations():Array<String>
	{
		if(variations != null && variations.length > 0)
			return variations.copy();
		return [];
	}

	/** Pico flat meta.json matching your format */
	public function toJsonString():String
	{
		var root:Dynamic = {};
		if(player != null) Reflect.setField(root, 'player', player);
		if(girlfriend != null) Reflect.setField(root, 'girlfriend', girlfriend);
		if(opponent != null) Reflect.setField(root, 'opponent', opponent);
		if(stage != null) Reflect.setField(root, 'stage', stage);
		if(noteStyle != null) Reflect.setField(root, 'noteStyle', noteStyle);
		if(songFileName != null) Reflect.setField(root, 'songFileName', songFileName);
		if(displayName != null) Reflect.setField(root, 'displayName', displayName);
		if(difficulties != null) Reflect.setField(root, 'chart_Difficulties', difficulties);
		if(variations != null) Reflect.setField(root, 'chart_Variations', variations);
		if(songVariation != null) Reflect.setField(root, 'songVariation', songVariation);
		Reflect.setField(root, 'charter', charter != null && charter.length > 0 ? [charter] : []);
		Reflect.setField(root, 'composers', artist != null && artist.length > 0 ? [artist] : []);
		if(freeplayIcon != null) Reflect.setField(root, 'freeplayIcon', freeplayIcon);
		if(freeplayColor != null) Reflect.setField(root, 'freeplayColor', freeplayColor);
		if(playerVocals != null) Reflect.setField(root, 'playerVocals', playerVocals);
		if(opponentVocals != null) Reflect.setField(root, 'opponentVocals', opponentVocals);
		if(needsVoices != null) Reflect.setField(root, 'needsVoices', needsVoices);
		if(useModcharts != null) Reflect.setField(root, 'useModCharts', useModcharts);
		if(opponentMode != null) Reflect.setField(root, 'opponentMod', opponentMode);
		if(bpm != null) Reflect.setField(root, 'bpm', bpm);
		if(pauseSong != null) Reflect.setField(root, 'pauseSong', pauseSong);
		if(instSuffix != null) Reflect.setField(root, 'instSuffix', instSuffix);
		if(vocalsSuffix != null) Reflect.setField(root, 'vocalsSuffix', vocalsSuffix);
		if(vocalPlayerSuffix != null) Reflect.setField(root, 'vocalPlayerSuffix', vocalPlayerSuffix);
		if(vocalOpponentSuffix != null) Reflect.setField(root, 'vocalOpponentSuffix', vocalOpponentSuffix);
		if(enableSongScripts != null) Reflect.setField(root, 'enableSongScripts', enableSongScripts);
		if(chart_BPM != null)
		{
			var bpmObj:Dynamic = {};
			for (k in chart_BPM.keys()) Reflect.setField(bpmObj, k, chart_BPM.get(k));
			Reflect.setField(root, 'chart_BPM', bpmObj);
		}
		if(chart_scrollSpeed != null)
		{
			var spdObj:Dynamic = {};
			for (k in chart_scrollSpeed.keys()) Reflect.setField(spdObj, k, chart_scrollSpeed.get(k));
			Reflect.setField(root, 'chart_scrollSpeed', spdObj);
		}
		return Json.stringify(root, null, '\t');
	}

	public function toTxtString():String
	{
		var lines:Array<String> = ['# Song meta (txt)'];
		function add(key:String, value:String)
		{
			if(value != null && value.trim().length > 0)
				lines.push(key + '=' + value.trim());
		}
		add('songFileName', songFileName);
		add('displayName', displayName);
		add('artist', artist);
		add('charter', charter);
		add('album', album);
		add('stage', stage);
		add('noteStyle', noteStyle);
		add('player', player);
		add('opponent', opponent);
		add('girlfriend', girlfriend);
		add('songVariation', songVariation);
		if(difficulties != null) add('difficulties', difficulties.join(','));
		if(variations != null) add('variations', variations.join(','));
		if(bpm != null) add('bpm', Std.string(bpm));
		add('pauseSong', pauseSong);
		add('freeplayIcon', freeplayIcon);
		add('freeplayColor', freeplayColor);
		if(enableSongScripts != null) add('enableSongScripts', enableSongScripts ? 'true' : 'false');
		if(useModcharts != null) add('useModCharts', useModcharts ? 'true' : 'false');
		if(needsVoices != null) add('needsVoices', needsVoices ? 'true' : 'false');
		if(opponentMode != null) add('opponentMod', opponentMode ? 'true' : 'false');
		add('instSuffix', instSuffix);
		add('vocalsSuffix', vocalsSuffix);
		add('vocalPlayerSuffix', vocalPlayerSuffix);
		add('vocalOpponentSuffix', vocalOpponentSuffix);
		return lines.join('\n') + '\n';
	}

	// ---- helpers ----

	static function setIf(song:Dynamic, field:String, value:String, overwrite:Bool):Void
	{
		if(value == null || value.length < 1) return;
		if(overwrite || emptyField(Reflect.field(song, field)))
			Reflect.setField(song, field, value);
	}

	static function emptyField(current:Dynamic):Bool
	{
		if(current == null) return true;
		return Std.string(current).trim().length < 1;
	}

	static function strVal(v:Dynamic):String
	{
		if(v == null) return null;
		var s:String = Std.string(v).trim();
		return (s.length > 0 && s.toLowerCase() != 'null') ? s : null;
	}

	static function strField(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			var s:String = strVal(v);
			if(s != null) return s;
		}
		return null;
	}

	/** Accept string or array of strings (charter / composers). */
	static function joinStringOrArray(obj:Dynamic, names:Array<String>):String
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			if(Std.isOfType(v, Array))
			{
				var parts:Array<String> = [];
				for (item in (cast v:Array<Dynamic>))
				{
					var s:String = strVal(item);
					if(s != null) parts.push(s);
				}
				if(parts.length > 0) return parts.join(', ');
				continue;
			}
			var s:String = strVal(v);
			if(s != null) return s;
		}
		return null;
	}

	static function floatField(obj:Dynamic, names:Array<String>):Null<Float>
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			var f:Float = Std.parseFloat(Std.string(v));
			if(!Math.isNaN(f)) return f;
		}
		return null;
	}

	static function boolField(obj:Dynamic, names:Array<String>):Null<Bool>
	{
		if(obj == null) return null;
		for (name in names)
		{
			if(!Reflect.hasField(obj, name)) continue;
			var v:Dynamic = Reflect.field(obj, name);
			if(v == true || v == false) return v;
			if(v != null)
			{
				var s:String = Std.string(v).toLowerCase();
				if(s == 'true' || s == '1') return true;
				if(s == 'false' || s == '0') return false;
			}
		}
		return null;
	}

	static function stringArrayField(obj:Dynamic, names:Array<String>):Array<String>
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			if(Std.isOfType(v, Array))
			{
				var out:Array<String> = [];
				for (item in (cast v:Array<Dynamic>))
				{
					var s:String = strVal(item);
					if(s != null) out.push(s);
				}
				return out.length > 0 ? out : null;
			}
			var asStr:String = strVal(v);
			if(asStr != null) return splitList(asStr);
		}
		return null;
	}

	static function mapGet(map:Map<String, String>, keys:Array<String>):String
	{
		for (k in keys)
		{
			if(map.exists(k))
			{
				var v:String = map.get(k);
				if(v != null && v.trim().length > 0)
					return v.trim();
			}
		}
		return null;
	}

	static function splitList(value:String):Array<String>
	{
		var out:Array<String> = [];
		for (part in value.split(','))
		{
			var s:String = StringTools.trim(part);
			if(s.length > 0) out.push(s);
		}
		return out.length > 0 ? out : null;
	}

	/** Parse { "easy": 1.5, "normal": 2.4 } style maps (not JSON arrays). */
	/** "bf" → "-bf"; already "-bf" stays */
	public static function normalizeVocalToken(value:String):String
	{
		if(value == null) return null;
		var v:String = value.trim();
		if(v.length < 1) return null;
		if(StringTools.startsWith(v, '-')) return v;
		return '-' + Paths.formatToSongPath(v);
	}

	/**
	 * freeplayColor from JSON:
	 *   "#AF66CE" / "AF66CE" / "0xFFAF66CE"
	 *   [175, 102, 206] (Psych RGB)
	 */
	public static function freeplayColorField(data:Dynamic, names:Array<String>):String
	{
		if(data == null) return null;
		for (name in names)
		{
			if(!Reflect.hasField(data, name)) continue;
			var parsed:String = normalizeFreeplayColor(Reflect.field(data, name));
			if(parsed != null) return parsed;
		}
		return null;
	}

	public static function normalizeFreeplayColor(raw:Dynamic):String
	{
		if(raw == null) return null;
		if(Std.isOfType(raw, Array))
		{
			var arr:Array<Dynamic> = cast raw;
			if(arr.length < 3) return null;
			var r:Int = Std.int(Std.parseFloat(Std.string(arr[0])));
			var g:Int = Std.int(Std.parseFloat(Std.string(arr[1])));
			var b:Int = Std.int(Std.parseFloat(Std.string(arr[2])));
			if(Math.isNaN(r)) r = 128;
			if(Math.isNaN(g)) g = 128;
			if(Math.isNaN(b)) b = 128;
			r = Std.int(Math.max(0, Math.min(255, r)));
			g = Std.int(Math.max(0, Math.min(255, g)));
			b = Std.int(Math.max(0, Math.min(255, b)));
			return ('#' + StringTools.hex(r, 2) + StringTools.hex(g, 2) + StringTools.hex(b, 2)).toUpperCase();
		}
		var s:String = Std.string(raw).trim();
		if(s.length < 1) return null;
		if(StringTools.startsWith(s, '#'))
		{
			var hex:String = s.substr(1);
			if(hex.length == 8) hex = hex.substr(2);
			if(hex.length == 6) return ('#' + hex).toUpperCase();
			return s;
		}
		if(StringTools.startsWith(s.toLowerCase(), '0x'))
		{
			var h:String = s.substr(2);
			if(h.length == 8) h = h.substr(2);
			if(h.length == 6) return ('#' + h).toUpperCase();
		}
		if(s.length == 6)
		{
			var ok:Bool = true;
			for (i in 0...6)
			{
				var c:Int = s.charCodeAt(i);
				var isHex:Bool = (c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102);
				if(!isHex) { ok = false; break; }
			}
			if(ok) return ('#' + s).toUpperCase();
		}
		if(s.indexOf(',') >= 0)
		{
			var parts:Array<String> = s.split(',');
			if(parts.length >= 3)
			{
				var rr:Int = Std.int(Std.parseFloat(parts[0].trim()));
				var gg:Int = Std.int(Std.parseFloat(parts[1].trim()));
				var bb:Int = Std.int(Std.parseFloat(parts[2].trim()));
				return ('#' + StringTools.hex(rr, 2) + StringTools.hex(gg, 2) + StringTools.hex(bb, 2)).toUpperCase();
			}
		}
		return s;
	}

	/** 0xAARRGGBB for Freeplay / UI */
	public static function parseFreeplayColor(value:Dynamic, ?fallback:Int = 0xFF9271FD):Int
	{
		var norm:String = normalizeFreeplayColor(value);
		if(norm == null || norm.length < 1) return fallback;
		var hex:String = StringTools.startsWith(norm, '#') ? norm.substr(1) : norm;
		if(hex.length == 6) hex = 'FF' + hex;
		var n:Null<Int> = Std.parseInt('0x' + hex);
		return n != null ? n : fallback;
	}

	static function floatMapField(obj:Dynamic, names:Array<String>):Map<String, Float>
	{
		if(obj == null) return null;
		for (name in names)
		{
			var v:Dynamic = Reflect.field(obj, name);
			if(v == null) continue;
			if(Std.isOfType(v, Array)) continue; // invalid form in some drafts
			if(Type.typeof(v) != TObject) continue;
			var map:Map<String, Float> = new Map();
			for (k in Reflect.fields(v))
			{
				var n:Float = Std.parseFloat(Std.string(Reflect.field(v, k)));
				if(!Math.isNaN(n) && n > 0)
					map.set(k.toLowerCase(), n);
			}
			if(map.keys().hasNext()) return map;
		}
		return null;
	}

	static function resolveDifficultyKey():String
	{
		try
		{
			var d:String = Difficulty.getString(null, false);
			if(d != null && d.trim().length > 0)
				return Paths.formatToSongPath(d);
		}
		catch(e:Dynamic) {}
		return 'normal';
	}
}
