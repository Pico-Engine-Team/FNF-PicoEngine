package funkin.play;

import funkin.modding.Mods;
import funkin.stages.StageData;
import funkin.states.menus.MainMenuState;
import funkin.data.objects.game.notes.data.Note;

import haxe.Json;
import lime.utils.Assets;
using StringTools;

typedef SwagSong = {
	var song:String;
	@:optional var displayName:String;
	@:optional var opponentMode:String;
	@:optional var artist:String;
	@:optional var charter:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player:String;
	var girlfriend:String;
	var opponent:String;
	var stage:String;
	@:optional var format:String;
	@:optional var formatChart:String;
	@:optional var generatedBy:String;

	@:optional var pauseSong:String;
	@:optional var instSuffix:String;
	@:optional var vocalsSuffix:String;
	@:optional var vocalPlayerSuffix:String;
	@:optional var vocalOpponentSuffix:String;
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	/** @deprecated Migrated to noteStyle on load; ignored at runtime */
	@:optional var arrowSkin:String;
	/** @deprecated Migrated to noteStyle on load; ignored at runtime */
	@:optional var splashSkin:String;
	@:optional var variation:String;
	@:optional var songVariation:String;
	@:optional var freeplayDifficulties:Array<String>;
	@:optional var songVariations:Array<String>;
	@:optional var noteStyle:String;
	@:optional var enableSongScripts:Bool;
	@:optional var useModcharts:Bool;
}

typedef SwagSection = {
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song {
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	/** @deprecated use noteStyle — kept only for old chart migration */
	public var arrowSkin:String;
	/** @deprecated use noteStyle — kept only for old chart migration */
	public var splashSkin:String;
	public var variation:String;
	public var songVariation:String;
	public var enableSongScripts:Bool = true;
	public var useModcharts:Bool = true;
	public var artist:String;
	public var charter:String;
	public var speed:Float = 1;
	public var stage:String;
	public var player:String = 'bf';
	public var girlfriend:String = 'bf-opponent';
	public var opponent:String = 'gf';
	public var noteStyle:String = 'funkin';
	public var pauseSong:String = 'pauseMenu/breakfast';
	public var format:String = 'Pico Engine Chart';
	public var formatChart:String = 'Pico Engine Chart';
	public var generatedBy:String = 'Pico Engine v${MainMenuState.PicoVersion}';

	public static inline var FORMAT_PICO_ENGINE:String = 'Pico Engine Chart';
	public static inline var FORMAT_PICO_ENGINE_V2:String = 'Pico Engine Chart v2';
	public static inline var FORMAT_PSYCH_V1:String = 'Psych Engine v1.0';
	public static inline var FORMAT_UNKNOWN:String = 'Unknown';

	public static function convert(songJson:Dynamic) // Convert old charts to Pico Engine v2.0 format
	{
		// Legacy player1/player2/gfVersion → player/opponent/girlfriend
		if((songJson.player == null || songJson.player.length < 1) && Reflect.hasField(songJson, 'player1'))
			songJson.player = Reflect.field(songJson, 'player1');
		if((songJson.opponent == null || songJson.opponent.length < 1) && Reflect.hasField(songJson, 'player2'))
			songJson.opponent = Reflect.field(songJson, 'player2');
		if((songJson.girlfriend == null || songJson.girlfriend.length < 1) && Reflect.hasField(songJson, 'gfVersion'))
			songJson.girlfriend = Reflect.field(songJson, 'gfVersion');
		else if((songJson.girlfriend == null || songJson.girlfriend.length < 1) && Reflect.hasField(songJson, 'player3'))
			songJson.girlfriend = Reflect.field(songJson, 'player3');

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(note[3] != null && !Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static var notestyleListPath:String = 'data/notestyles-list.txt';
	public static var picoCustomNotesPath:String = 'game/custom-notes';

	public static function noteStyleList():Array<String>
	{
		var list:Array<String> = [];
		for (style in Mods.mergeAllTextsNamed(notestyleListPath))
			addNoteStyleToList(list, style);
		#if sys
		addPicoCustomNoteStylesToList(list);
		#end
		return list;
	}

	#if sys
	static function addPicoCustomNoteStylesToList(list:Array<String>)
	{
		var picoCustomNotes:String = Paths.getPicoFunkinFolder(picoCustomNotesPath);
		if(sys.FileSystem.exists(picoCustomNotes))
		{
			var listedStyles:Array<String> = [];
			var picoListPath:String = Paths.getPicoFunkinFolder('$picoCustomNotesPath/list.txt');
			if(sys.FileSystem.exists(picoListPath))
			{
				for (style in sys.io.File.getContent(picoListPath).split('\n'))
				{
					style = style.trim();
					if(style.length > 0 && sys.FileSystem.exists(Paths.getPicoFunkinFolder('$picoCustomNotesPath/$style.json')))
					{
						addNoteStyleToList(list, style);
						listedStyles.push(style);
					}
				}
			}

			for (file in sys.FileSystem.readDirectory(picoCustomNotes))
			{
				if(file.endsWith('.json'))
				{
					var style:String = file.substr(0, file.length - '.json'.length);
					if(!listedStyles.contains(style))
						addNoteStyleToList(list, style);
				}
			}
		}
	}
	#end

	static function addNoteStyleToList(list:Array<String>, value:String)
	{
		var style:String = cleanNoteStyleName(value);
		if(style.length > 0 && style != 'psych' && !list.contains(style))
			list.push(style);
	}

	public static function cleanNoteStyleName(value:String):String
	{
		if(value == null) return '';

		// Chart noteStyle always maps to data/notestyles (not pico_assets)
		var skin:String = Note.normalizeSongNoteStyleName(value);
		var styleKey:String = Note.noteStyleKey(skin);
		return styleKey.length > 0 ? styleKey : '';
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		// NEW: assets/songs/<song>/charts/<file>.json
		// FALLBACK: assets/shared/data/songs/<song>/<file>.json
		_lastPath = resolveChartPath(formattedFolder, formattedSong);

		#if MODS_ALLOWED
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
		{
			try
			{
				rawData = Assets.getText(_lastPath);
			}
			catch (e:Dynamic)
			{
				rawData = null;
			}
		}

		var song:SwagSong = rawData != null ? parseJSON(rawData, jsonInput) : null;
		if (song != null)
			applySongMeta(song, formattedFolder);
		return song;
	}

	/**
	 * Fill empty chart fields from assets/songs/<folder>/meta.json
	 * (displayName, pauseSong, stage, noteStyle, characters, variations, etc.)
	 */
	public static function applySongMeta(song:SwagSong, songFolder:String, ?extraFreeplay:Bool = false, ?variation:String = null):Void
	{
		if (song == null || songFolder == null) return;
		try
		{
			var isExtra:Bool = extraFreeplay;
			try
			{
				if (!isExtra && Reflect.field(song, 'extraFreeplay') == true)
					isExtra = true;
			}
			catch (e:Dynamic) {}

			var variationKey:String = variation;
			if (variationKey == null || variationKey.trim().length < 1)
			{
				try
				{
					if (song.songVariation != null && Std.string(song.songVariation).trim().length > 0)
						variationKey = Std.string(song.songVariation);
					else if (song.variation != null && Std.string(song.variation).trim().length > 0)
						variationKey = Std.string(song.variation);
				}
				catch (e:Dynamic) {}
			}

			// Also detect from chart filename: bopeebo-pico-hard → pico
			if (variationKey == null || variationKey.trim().length < 1)
			{
				try
				{
					var chartFile:String = Paths.formatToSongPath(Song.chartPath != null ? Song.chartPath : '');
					var base:String = Paths.formatToSongPath(songFolder);
					// path may end with .../bopeebo-pico-hard.json
					var slash:Int = chartFile.lastIndexOf('/');
					var name:String = slash >= 0 ? chartFile.substr(slash + 1) : chartFile;
					if (StringTools.endsWith(name, '.json'))
						name = name.substr(0, name.length - 5);
					if (StringTools.startsWith(name, base + '-'))
					{
						var rest:String = name.substr(base.length + 1); // pico-hard or pico
						// strip trailing difficulty-ish tokens is handled by freeplay; keep first segment
						var dash:Int = rest.indexOf('-');
						variationKey = dash > 0 ? rest.substr(0, dash) : rest;
					}
				}
				catch (e:Dynamic) {}
			}

			var meta = SongMeta.load(songFolder, null, isExtra, variationKey);
			if (meta == null) return;
			SongMeta.applyToSong(song, meta, false);
			try Paths.applyAudioSuffixesFromSong(song) catch (e:Dynamic) {}
			trace('[SongMeta] Applied ' + meta.loadedFormat + ' from ' + meta.loadedPath);
		}
		catch (e:Dynamic)
		{
			trace('[SongMeta] Failed for ' + songFolder + ': ' + e);
		}
	}

	/** Prefer songs/<folder>/charts/<file>.json, then legacy data/songs/<folder>/<file>.json */
	static function resolveChartPath(songFolder:String, chartFile:String):String
	{
		var key:String = songFolder + '/' + chartFile;
		var primary:String = Paths.chartJson(key);
		if (chartFileExists(primary))
			return primary;

		var legacy:String = Paths.chartJsonLegacy(key);
		if (chartFileExists(legacy))
			return legacy;

		return primary;
	}

	static function chartFileExists(path:String):Bool
	{
		if (path == null || path.length < 1)
			return false;
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return true;
		#end
		try
		{
			return Assets.exists(path);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	/** UI name: displayName → song → fallback */
	public static function getDisplayName(?songData:SwagSong = null, ?fallback:String = null):String
	{
		if(songData != null)
		{
			if(songData.displayName != null && Std.string(songData.displayName).trim().length > 0)
				return Std.string(songData.displayName).trim();
			if(songData.song != null && Std.string(songData.song).trim().length > 0)
				return Std.string(songData.song).trim();
		}
		if(fallback != null && fallback.trim().length > 0)
			return fallback.trim();
		if(loadedSongName != null && loadedSongName.trim().length > 0)
			return loadedSongName.trim();
		return '';
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var parsed:Dynamic = Json.parse(rawData);

		// Pico Engine Chart v2: { songName, displayName, song_Data: { scrollSpeed, chart_notes, chart_events, chart_notetypes } }
		if(parsed != null && Reflect.hasField(parsed, 'song_Data'))
			parsed = convertSongDataV2ToSwag(parsed, nameForError);

		var songJson:SwagSong = cast parsed;
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:Dynamic = Reflect.field(songJson, 'song');
			// Only unwrap if nested object (legacy Psych { "song": { ... } }), not a string song name
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = cast subSong;
		}

		normalizeChartInfo(songJson);
		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = chartFormatKey(songJson);

			switch(convertTo)
			{
				case 'psych_v1':
					if(!isPsychV1CompatibleFormat(fmt)) //Convert to Psych Engine v1.0 format
					{
						trace('converting chart $nameForError with format ${chartFormatDisplayName(fmt)} to ${FORMAT_PSYCH_V1} format...');
						songJson.format = 'pico_engine_chart';
						songJson.formatChart = FORMAT_PICO_ENGINE;
						songJson.generatedBy = defaultGeneratedBy();
						convert(songJson);
					}
			}
		}
		normalizeChartInfo(songJson);

		// Legacy charts only: arrowSkin → noteStyle (noteStyle owns notes + splashes)
		if(songJson.noteStyle == null || Std.string(songJson.noteStyle).trim().length < 1)
		{
			if(songJson.arrowSkin != null && Std.string(songJson.arrowSkin).trim().length > 0)
				songJson.noteStyle = songJson.arrowSkin;
		}

		if(songJson.noteStyle != null)
			songJson.noteStyle = cleanNoteStyleName(songJson.noteStyle);

		// Deprecated fields cleared — noteStyle controls notes/strums/splashes/UI
		songJson.arrowSkin = null;
		songJson.splashSkin = null;

		if(songJson.songVariation == null && songJson.variation != null)
			songJson.songVariation = songJson.variation;
		if(songJson.variation == null && songJson.songVariation != null)
			songJson.variation = songJson.songVariation;

		if(songJson.enableSongScripts == null)
			songJson.enableSongScripts = true;
		if(songJson.useModcharts == null)
			songJson.useModcharts = true;

		return songJson;
	}

	static function normalizeChartInfo(songJson:SwagSong):Void
	{
		if(songJson == null) return;

		var formatKey:String = chartFormatKey(songJson);
		if(formatKey == 'unknown' || formatKey.length < 1)
			formatKey = 'psych_v1';

		if(songJson.formatChart == null || songJson.formatChart.trim().length < 1)
			songJson.formatChart = chartFormatDisplayName(formatKey);
		else
			songJson.formatChart = chartFormatDisplayName(songJson.formatChart);

		if(songJson.format == null || songJson.format.trim().length < 1)
			songJson.format = chartFormatLegacyKey(songJson.formatChart);

		if(songJson.generatedBy == null || songJson.generatedBy.trim().length < 1)
			songJson.generatedBy = defaultGeneratedBy();
	}

	static function chartFormatKey(songJson:SwagSong):String
	{
		var value:String = null;
		if(songJson != null)
		{
			if(songJson.formatChart != null && songJson.formatChart.trim().length > 0)
				value = songJson.formatChart;
			else value = songJson.format;
		}
		if(value == null) return 'unknown';
		return value.trim().toLowerCase().replace(' ', '_').replace('-', '_');
	}

	static function isPsychV1CompatibleFormat(formatKey:String):Bool
	{
		return formatKey.startsWith('psych_v1')
			|| formatKey == 'psych_engine_v1.0'
			|| formatKey == 'psych_engine_v1'
			|| formatKey == 'pico_engine_chart'
			|| formatKey == 'pico_engine_chart_v2'
			|| formatKey.startsWith('pico_engine_chart_v');
	}

	static function chartFormatDisplayName(formatValue:String):String
	{
		var key:String = formatValue == null ? 'unknown' : formatValue.trim().toLowerCase().replace(' ', '_').replace('-', '_');
		if(key.startsWith('psych_v1') || key == 'psych_engine_v1.0' || key == 'psych_engine_v1')
			return FORMAT_PSYCH_V1;
		if(key == 'pico_engine_chart_v2' || key.startsWith('pico_engine_chart_v2'))
			return FORMAT_PICO_ENGINE_V2;
		if(key == 'pico_engine_chart' || key == 'pico_engine')
			return FORMAT_PICO_ENGINE;
		if(key == 'unknown' || key.length < 1)
			return FORMAT_UNKNOWN;
		return formatValue;
	}

	static function chartFormatLegacyKey(formatValue:String):String
	{
		var display:String = chartFormatDisplayName(formatValue);
		return switch(display)
		{
			case FORMAT_PICO_ENGINE: 'pico_engine_chart';
			case FORMAT_PSYCH_V1: 'psych_v1';
			default: 'unknown';
		}
	}

	public static function defaultGeneratedBy():String
		return 'Pico Engine v${MainMenuState.PicoVersion}';

	/**
	 * Convert Pico Engine Chart v2 (song_Data) → runtime SwagSong.
	 *
	 * songName  = folder / load id of the song (assets/songs/<songName>/)
	 * displayName = label in Story Mode, Freeplay, PauseState
	 *
	 * song_Data.scrollSpeed  → speed
	 * song_Data.chart_notes  → notes (sections)
	 * song_Data.chart_events → events (Psych event array format)
	 * song_Data.chart_notetypes → optional list of note-type names used (metadata only)
	 */
	public static function convertSongDataV2ToSwag(root:Dynamic, ?nameForError:String = null):SwagSong
	{
		var data:Dynamic = Reflect.field(root, 'song_Data');
		if(data == null) data = {};

		var song:SwagSong = cast {};
		song.format = 'pico_engine_chart_v2';
		song.formatChart = FORMAT_PICO_ENGINE_V2;
		song.generatedBy = defaultGeneratedBy();

		// songName = folder path key; displayName = UI name
		var songName:String = '';
		if(Reflect.hasField(root, 'songName') && root.songName != null)
			songName = Std.string(root.songName).trim();
		else if(Reflect.hasField(root, 'song') && root.song != null && Type.typeof(root.song) != TObject)
			songName = Std.string(root.song).trim();
		if(songName.length < 1 && nameForError != null)
			songName = Paths.formatToSongPath(nameForError);
		song.song = songName;

		if(Reflect.hasField(root, 'displayName') && root.displayName != null)
			song.displayName = Std.string(root.displayName).trim();

		// scrollSpeed: number, string, or { "normal": 1.5 } / array
		song.speed = parseScrollSpeed(Reflect.field(data, 'scrollSpeed'));

		// chart_notes → notes
		song.notes = [];
		var chartNotes:Dynamic = Reflect.field(data, 'chart_notes');
		if(chartNotes != null && Std.isOfType(chartNotes, Array))
		{
			var sections:Array<Dynamic> = cast chartNotes;
			for (sec in sections)
			{
				if(sec == null) continue;
				var out:SwagSection = {
					sectionNotes: [],
					sectionBeats: 4,
					mustHitSection: true
				};
				if(Reflect.hasField(sec, 'sectionBeats') && sec.sectionBeats != null)
				{
					var b:Float = Std.parseFloat(Std.string(sec.sectionBeats));
					if(!Math.isNaN(b) && b > 0) out.sectionBeats = b;
				}
				if(Reflect.hasField(sec, 'mustHitSection'))
					out.mustHitSection = sec.mustHitSection != false;
				if(Reflect.hasField(sec, 'gfSection'))
					out.gfSection = sec.gfSection == true;
				if(Reflect.hasField(sec, 'altAnim'))
					out.altAnim = sec.altAnim == true;
				if(Reflect.hasField(sec, 'changeBPM'))
					out.changeBPM = sec.changeBPM == true;
				if(Reflect.hasField(sec, 'bpm') && sec.bpm != null)
				{
					var sb:Float = Std.parseFloat(Std.string(sec.bpm));
					if(!Math.isNaN(sb) && sb > 0) out.bpm = sb;
				}
				if(Reflect.hasField(sec, 'sectionNotes') && Std.isOfType(sec.sectionNotes, Array))
					out.sectionNotes = cast sec.sectionNotes;
				song.notes.push(out);
			}
		}

		// chart_events → events
		song.events = [];
		var chartEvents:Dynamic = Reflect.field(data, 'chart_events');
		if(chartEvents != null && Std.isOfType(chartEvents, Array))
		{
			var evs:Array<Dynamic> = cast chartEvents;
			for (ev in evs)
			{
				if(ev == null) continue;
				// Already Psych format: [time, [[name, v1, v2], ...]]
				if(Std.isOfType(ev, Array))
				{
					song.events.push(ev);
					continue;
				}
				// Object form: { t/strumTime, event/name, value1, value2 }
				var t:Float = 0;
				if(Reflect.hasField(ev, 't')) t = Std.parseFloat(Std.string(ev.t));
				else if(Reflect.hasField(ev, 'strumTime')) t = Std.parseFloat(Std.string(ev.strumTime));
				else if(Reflect.hasField(ev, 'position')) t = Std.parseFloat(Std.string(ev.position));
				if(Math.isNaN(t)) t = 0;
				var name:String = '';
				if(Reflect.hasField(ev, 'event')) name = Std.string(ev.event);
				else if(Reflect.hasField(ev, 'name')) name = Std.string(ev.name);
				var v1:String = Reflect.hasField(ev, 'value1') ? Std.string(ev.value1) : '';
				var v2:String = Reflect.hasField(ev, 'value2') ? Std.string(ev.value2) : '';
				song.events.push([t, [[name, v1, v2]]]);
			}
		}

		// chart_notetypes: optional string list stored for tools (not required at runtime)
		if(Reflect.hasField(data, 'chart_notetypes'))
			Reflect.setField(song, 'chart_notetypes', Reflect.field(data, 'chart_notetypes'));

		// Defaults required by PlayState if meta missing
		// Float/Bool cannot be null on static platforms (C++/HL)
		if(song.events == null) song.events = [];
		if(song.notes == null) song.notes = [];
		if(Math.isNaN(song.bpm) || song.bpm <= 0) song.bpm = 100;
		song.needsVoices = true;
		if(Math.isNaN(song.offset)) song.offset = 0;
		if(song.player == null || song.player.length < 1) song.player = 'bf';
		if(song.opponent == null || song.opponent.length < 1) song.opponent = 'dad';
		if(song.girlfriend == null || song.girlfriend.length < 1) song.girlfriend = 'gf';
		if(song.stage == null || song.stage.length < 1) song.stage = 'stage';

		trace('[Song] Loaded Pico Engine Chart v2' + (nameForError != null ? ' ($nameForError)' : '') +
			' songName=' + song.song + ' displayName=' + song.displayName);
		return song;
	}

	static function parseScrollSpeed(value:Dynamic):Float
	{
		if(value == null) return 1;
		if(Std.isOfType(value, Float) || Std.isOfType(value, Int))
		{
			var n:Float = cast value;
			return (Math.isNaN(n) || n <= 0) ? 1 : n;
		}
		if(Std.isOfType(value, String))
		{
			var p:Float = Std.parseFloat(cast value);
			return (Math.isNaN(p) || p <= 0) ? 1 : p;
		}
		// { "normal": 1.5 } or { "1.5": true } malformed — take first numeric
		if(Type.typeof(value) == TObject)
		{
			for (field in Reflect.fields(value))
			{
				var fv:Dynamic = Reflect.field(value, field);
				if(Std.isOfType(fv, Float) || Std.isOfType(fv, Int))
				{
					var n:Float = cast fv;
					if(!Math.isNaN(n) && n > 0) return n;
				}
				var fromKey:Float = Std.parseFloat(field);
				if(!Math.isNaN(fromKey) && fromKey > 0) return fromKey;
			}
		}
		return 1;
	}

	/**
	 * Build Pico Engine Chart v2 object from runtime SwagSong (for ChartingState save).
	 * Meta-owned fields should already be stripped by the caller.
	 */
	public static function toSongDataV2(song:SwagSong):Dynamic
	{
		if(song == null) return {};
		var sections:Array<Dynamic> = [];
		if(song.notes != null)
		{
			for (sec in song.notes)
			{
				if(sec == null) continue;
				var o:Dynamic = {
					sectionBeats: sec.sectionBeats,
					mustHitSection: sec.mustHitSection,
					sectionNotes: sec.sectionNotes != null ? sec.sectionNotes : []
				};
				if(sec.gfSection == true) o.gfSection = true;
				if(sec.altAnim == true) o.altAnim = true;
				if(sec.changeBPM == true)
				{
					o.changeBPM = true;
					o.bpm = sec.bpm;
				}
				sections.push(o);
			}
		}
		var eventsOut:Array<Dynamic> = song.events != null ? song.events : [];
		var noteTypes:Array<String> = [];
		try
		{
			var existing:Dynamic = Reflect.field(song, 'chart_notetypes');
			if(existing != null && Std.isOfType(existing, Array))
				noteTypes = cast existing;
		}
		catch(e:Dynamic) {}

		return {
			format: 'pico_engine_chart_v2',
			formatChart: FORMAT_PICO_ENGINE_V2,
			generatedBy: defaultGeneratedBy(),
			songName: song.song,
			displayName: (song.displayName != null && song.displayName.length > 0) ? song.displayName : song.song,
			song_Data: {
				scrollSpeed: song.speed,
				chart_notes: sections,
				chart_events: eventsOut,
				chart_notetypes: noteTypes
			}
		};
	}
}
