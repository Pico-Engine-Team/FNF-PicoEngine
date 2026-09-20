package funkin.states;

import funkin.play.Song;
import funkin.play.SongMeta;
import funkin.play.Rating;
import funkin.play.Highscore;
import funkin.play.Rank;
import funkin.stages.StageData;

import funkin.data.WeekData;
import funkin.data.objects.Bar;
import funkin.data.objects.HealthIcon;
import funkin.data.dialogue.DialogueBoxPsych;
import funkin.data.cutscenes.VideoSprite;
import funkin.data.shaders.ErrorHandledShader;
import funkin.data.objects.game.characters.Character;

import funkin.data.objects.game.notes.NoteData;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.NoteSplash;
import funkin.data.objects.game.notes.data.HoldNoteCover;
import funkin.data.objects.game.notes.data.Note.EventNote;
import funkin.data.objects.game.notes.config.StrumNote;
import funkin.data.objects.game.notes.config.NoteTypesConfig;

import funkin.states.PauseState;
import funkin.states.GameOverState;
import funkin.states.editors.data.ChartingState;
import funkin.states.editors.data.StageEditorState;
import funkin.states.editors.data.CharacterEditorState;
import funkin.states.menus.MainMenuState;
import funkin.states.menus.freeplay.FreeplayMenuState;

import funkin.stages.objects.*;
import funkin.stages.data.levels.*;
import funkin.utils.engines.pico.stages.StagesPicoEnigne;
import funkin.utils.engines.pico.EnginePerformance;
import funkin.utils.engines.vslice.stages.StagesVslice;

import haxe.Json;
import flixel.FlxSprite;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;

#if !flash
import openfl.filters.ShaderFilter;
#end

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLuaProgramming;
import funkin.modding.scripting.psychlua.*;
#else
import funkin.modding.scripting.psychlua.LuaUtils;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.FunkinHSProgramming;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.FunkinHSProgramming.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<FunkinHSProgramming> = [];
	#end
	var modchartXmls:Array<Xml> = [];
	var modchartXmlPaths:Array<String> = [];

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var stageObjects:Map<String, FlxSprite> = [];
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	/** Change Rating Skin event */
	public var ratingSkinDirectory:String = "";
	public var ratingSkinSuffix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyHiddenSongs:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static function loadWeekDifficultiesForCurrentMode(?week:WeekData = null):Void
	{
		if(week == null) week = WeekData.getCurrentWeek();
		Difficulty.loadFromWeek(week, !isStoryMode);

		if(storyDifficulty < 0) storyDifficulty = 0;
		if(Difficulty.list.length > 0 && storyDifficulty >= Difficulty.list.length)
			storyDifficulty = Difficulty.list.length - 1;
	}

	public static function buildStoryPlaylist(week:Dynamic):Array<String>
	{
		var songArray:Array<String> = [];
		for (song in WeekData.visibleStorySongs(week))
			songArray.push(WeekData.getWeekSongName(song));
		return songArray;
	}

	public static function removeHiddenStorySongsFromPlaylist():Void
	{
		if(!isStoryMode || storyPlaylist == null || storyPlaylist.length < 1) return;

		reloadStoryHiddenSongsFromCurrentWeek();
		var hidden:Array<String> = WeekData.parseHiddenStorySongs(storyHiddenSongs);
		if(hidden.length < 1) return;

		var currentNames:Array<String> = getCurrentStorySongNames();
		var filtered:Array<String> = [];
		for (song in storyPlaylist)
		{
			if(storySongInList(song, currentNames) || !storySongInList(song, hidden))
				filtered.push(song);
		}
		storyPlaylist = filtered;
	}

	public static function reloadStoryHiddenSongsFromCurrentWeek():Void
	{
		if(!isStoryMode) return;

		var week:WeekData = WeekData.getCurrentWeek();
		if(week != null)
			storyHiddenSongs = WeekData.parseHiddenStorySongs(week.hideStorySongs);
	}

	public static function removeCurrentStorySongFromPlaylist():Void
	{
		if(storyPlaylist == null || storyPlaylist.length < 1) return;

		var currentNames:Array<String> = getCurrentStorySongNames();
		for (name in currentNames)
		{
			var index:Int = getStoryPlaylistIndex(name);
			if(index > -1)
			{
				storyPlaylist.splice(index, 1);
				return;
			}
		}

		storyPlaylist.shift();
	}

	static function getCurrentStorySongNames():Array<String>
	{
		var names:Array<String> = [];
		if(SONG != null)
			addStorySongName(names, SONG.song);
		addStorySongName(names, Song.loadedSongName);
		if(storyPlaylist != null && storyPlaylist.length > 0)
			addStorySongName(names, storyPlaylist[0]);
		return names;
	}

	static function getStoryPlaylistIndex(song:String):Int
	{
		if(song == null || storyPlaylist == null) return -1;

		for (i in 0...storyPlaylist.length)
			if(storySongMatches(storyPlaylist[i], song))
				return i;
		return -1;
	}

	static function addStorySongName(list:Array<String>, song:String):Void
	{
		if(song == null) return;

		var formattedSong:String = Paths.formatToSongPath(song);
		if(formattedSong.length < 1) return;

		for (item in list)
			if(Paths.formatToSongPath(item) == formattedSong)
				return;
		list.push(song);
	}

	static function storySongInList(song:String, list:Array<String>):Bool
	{
		for (item in list)
			if(storySongMatches(song, item))
				return true;
		return false;
	}

	static function storySongMatches(song:String, other:String):Bool
	{
		if(song == null || other == null) return false;
		return Paths.formatToSongPath(song) == Paths.formatToSongPath(other);
	}

	public static function getSongVariationName(?song:SwagSong = null):String
	{
		if(song == null) song = SONG;
		return song != null ? Difficulty.getChartSuffixName(song.songVariation) : '';
	}

	public static function getSongVariationFilePath(?song:SwagSong = null):String
	{
		return Difficulty.getVariationFilePath(getSongVariationName(song));
	}

	public static function getEffectiveSongVariationName(?song:SwagSong = null, ?difficulty:Null<Int>):String
	{
		var difficultyVariation:String = Difficulty.getDifficultyVariationName(difficulty);
		if(difficultyVariation.length > 0)
			return difficultyVariation;

		var variationName:String = getSongVariationName(song);
		if(variationName.length > 0)
			return variationName;
		return '';
	}

	public static function getSongIdWithSuffix(songId:String, ?suffix:String):String
	{
		var baseId:String = Paths.formatToSongPath(songId);
		if(suffix != null && suffix.length > 0 && !baseId.endsWith(suffix))
			return baseId + suffix;
		return baseId;
	}

	public static function getSongVariationSuffixCandidates(?song:SwagSong = null, ?difficulty:Null<Int>, ?useCurrentSongVariation:Bool = true):Array<String> {
		var candidates:Array<String> = [];
		var difficultySuffix:String = Difficulty.getFilePath(difficulty);
		var rawDiffName:String = Difficulty.getString(difficulty, false);
		var rawDiffSuffix:String = Paths.formatToSongPath(rawDiffName) == Paths.formatToSongPath(Difficulty.getDefault()) ? '' : Difficulty.getSuffixFilePath(rawDiffName);
		var effectiveVariation:String = getEffectiveSongVariationName(song, difficulty);
		var effectiveSuffix:String = Difficulty.getVariationAndDifficultyFilePath(effectiveVariation, difficulty);
		var songVariationSuffix:String = useCurrentSongVariation ? getSongVariationFilePath(song) : '';

		addUniqueCandidate(candidates, effectiveSuffix);
		addUniqueCandidate(candidates, songVariationSuffix);
		addUniqueCandidate(candidates, difficultySuffix);
		addUniqueCandidate(candidates, rawDiffSuffix);
		return candidates;
	}

	public static function getCurrentSongBaseId(?song:SwagSong = null):String
	{
		var loadedName:String = Song.loadedSongName;
		if(loadedName != null && loadedName.trim().length > 0)
			return Paths.formatToSongPath(loadedName);

		if(song == null) song = SONG;
		return song != null ? Paths.formatToSongPath(song.song) : '';
	}

	public static function getCurrentSongAssetId(?song:SwagSong = null, ?difficulty:Null<Int>):String
		return getSongAssetId(getCurrentSongBaseId(song), song, difficulty);

	public static function getSongIdWithVariation(songId:String, ?song:SwagSong = null):String
	{
		return getSongIdWithSuffix(songId, getSongVariationFilePath(song));
	}

	public static function getSongAssetId(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>):String
	{
		var suffix:String = '';
		var suffixes:Array<String> = getSongVariationSuffixCandidates(song, difficulty);
		if(suffixes.length > 0) suffix = suffixes[0];
		return getSongIdWithSuffix(songId, suffix);
	}

	public static function songAudioExists(songId:String):Bool
	{
		if(songId == null) return false;
		var id:String = Paths.formatToSongPath(songId);
		if(id.length < 1) return false;
		var library:String = (Paths.songAudioRoot != null && Paths.songAudioRoot.length > 0) ? Paths.songAudioRoot : 'songs';
		// New: assets/songs/<id>/song/Inst.ogg  | Legacy: assets/songs/<id>/Inst.ogg
		if(Paths.fileExists('$id/song/Inst.${Paths.SOUND_EXT}', SOUND, false, library))
			return true;
		if(Paths.fileExists('$id/Inst.${Paths.SOUND_EXT}', SOUND, false, library))
			return true;
		return false;
	}

	public static function getSongAudioId(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>):String
	{
		var baseId:String = songId != null ? Paths.formatToSongPath(songId) : '';
		var displayId:String = (song != null && song.song != null) ? Paths.formatToSongPath(song.song) : '';
		var loadedId:String = (Song.loadedSongName != null && Song.loadedSongName.trim().length > 0) ? Paths.formatToSongPath(Song.loadedSongName) : '';
		var candidates:Array<String> = [];

		addUniqueCandidate(candidates, getSongAssetId(baseId, song, difficulty));
		if(displayId.length > 0)
			addUniqueCandidate(candidates, getSongAssetId(displayId, song, difficulty));
		addUniqueCandidate(candidates, displayId);
		addUniqueCandidate(candidates, loadedId);
		addUniqueCandidate(candidates, baseId);

		for (candidate in candidates)
			if(songAudioExists(candidate))
				return candidate;

		return candidates.length > 0 ? candidates[0] : baseId;
	}

	public static function getSongIdWithVariationAndDifficulty(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>):String
	{
		var suffix:String = Difficulty.getVariationAndDifficultyFilePath(getSongVariationName(song), difficulty);
		return getSongIdWithSuffix(songId, suffix);
	}

	public static function getSongIdVariationCandidates(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>):Array<String>
	{
		var baseId:String = Paths.formatToSongPath(songId);
		var candidates:Array<String> = [];
		for (suffix in getSongVariationSuffixCandidates(song, difficulty))
			addUniqueCandidate(candidates, getSongIdWithSuffix(baseId, suffix));
		addUniqueCandidate(candidates, baseId);
		return candidates;
	}

	public static function getSongLoadCandidates(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>, ?useCurrentSongVariation:Bool = true):Array<String>
	{
		var baseId:String = Paths.formatToSongPath(songId);
		var candidates:Array<String> = [];
		for (suffix in getSongVariationSuffixCandidates(song, difficulty, useCurrentSongVariation))
			addUniqueCandidate(candidates, getSongIdWithSuffix(baseId, suffix));
		addUniqueCandidate(candidates, baseId);
		return candidates;
	}

	public static function getEventsChartCandidates(?song:SwagSong = null, ?difficulty:Null<Int>):Array<String>
	{
		var variationSuffix:String = getSongVariationFilePath(song);
		var diffSuffix:String = Difficulty.getFilePath(difficulty);
		var rawDiffName:String = Difficulty.getString(difficulty, false);
		var rawDiffSuffix:String = Paths.formatToSongPath(rawDiffName) == Paths.formatToSongPath(Difficulty.getDefault()) ? '' : Difficulty.getSuffixFilePath(rawDiffName);
		var candidates:Array<String> = [];
		var isExtraFreeplay:Bool = song != null && Reflect.field(song, 'extraFreeplay') == true;

		if(variationSuffix.length > 0)
		{
			if(isExtraFreeplay)
				addUniqueCandidate(candidates, 'events' + variationSuffix + '-extra');
			addUniqueCandidate(candidates, 'events' + variationSuffix);
		}
		if(diffSuffix.length > 0)
		{
			if(isExtraFreeplay)
				addUniqueCandidate(candidates, 'events' + diffSuffix + '-extra');
			addUniqueCandidate(candidates, 'events' + diffSuffix);
		}
		if(rawDiffSuffix.length > 0)
		{
			if(isExtraFreeplay)
				addUniqueCandidate(candidates, 'events' + rawDiffSuffix + '-extra');
			addUniqueCandidate(candidates, 'events' + rawDiffSuffix);
		}
		if(isExtraFreeplay)
			addUniqueCandidate(candidates, 'events-extra');
		addUniqueCandidate(candidates, 'events');
		return candidates;
	}

	public static function loadSongWithVariationFallback(songId:String, ?song:SwagSong = null, ?difficulty:Null<Int>, ?useCurrentSongVariation:Bool = true):SwagSong
	{
		var baseId:String = Paths.formatToSongPath(songId);
		var lastError:Dynamic = null;
		for (candidate in getSongLoadCandidates(baseId, song, difficulty, useCurrentSongVariation))
		{
			try
			{
				return Song.loadFromJson(candidate, baseId);
			}
			catch(e:Dynamic)
			{
				lastError = e;
			}
		}

		throw lastError;
		return null;
	}

	static function addUniqueCandidate(candidates:Array<String>, candidate:String):Void
	{
		if(candidate != null && candidate.length > 0 && !candidates.contains(candidate))
			candidates.push(candidate);
	}

	public var spawnTime:Float = 2000;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpHoldNoteCovers:FlxTypedGroup<HoldNoteCover> = new FlxTypedGroup<HoldNoteCover>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	/** When true, player controls the opponent side (dad notes/strums). */
	public static var opponentMode:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camCombo:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	/** Base FNF hold bonus: points gained per second while holding a sustain (V-Slice SCORE_HOLD_BONUS_PER_SECOND). */
	public static inline var SCORE_HOLD_BONUS_PER_SECOND:Float = 250.0;
	/** Fractional hold score not yet applied to songScore. */
	var scoreHoldAccum:Float = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	private var singAnimationsMiss:Array<String> = ['singUPmiss','singDOWNmiss', 'singLEFTmiss', 'singRIGHTmiss'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLuaProgramming> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<funkin.modding.scripting.psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;
	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		if(nextReloadAll)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;
		try { EnginePerformance.beginSongLoad(); } catch(e:Dynamic) {}

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		keysArray = ['note_left','note_down','note_up','note_right'];

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		opponentMode = readOpponentModeSetting();
		// Chart flag can force Opponent Mode (Bool or string "true" from older charts)
		if(SONG != null && isSongOpponentModeFlag(SONG))
			opponentMode = true;
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camCombo = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camCombo.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCombo, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		// ===== Meta + audio suffixes (player/opponent/girlfriend → player1/player2/gfVersion) =====
		try
		{
			var metaFolder:String = Paths.formatToSongPath(
				(Song.loadedSongName != null && Song.loadedSongName.length > 0)
					? Song.loadedSongName
					: (SONG.song != null ? SONG.song : '')
			);
			var variationKey:String = null;
			if(SONG.songVariation != null && Std.string(SONG.songVariation).trim().length > 0)
				variationKey = Std.string(SONG.songVariation).trim();
			else if(SONG.variation != null && Std.string(SONG.variation).trim().length > 0)
				variationKey = Std.string(SONG.variation).trim();

			var isExtra:Bool = false;
			try { if(Reflect.field(SONG, 'extraFreeplay') == true) isExtra = true; } catch(e:Dynamic) {}

			var meta = SongMeta.load(metaFolder, null, isExtra, variationKey);
			if(meta != null)
			{
				// Fill empty chart fields from meta (player → player1, etc.)
				SongMeta.applyToSong(SONG, meta, false);
				trace('[PlayState] Meta applied: ' + meta.loadedPath + (variationKey != null ? ' var=' + variationKey : ''));
			}
			Paths.applyAudioSuffixesFromSong(SONG);
		}
		catch(e:Dynamic)
		{
			trace('[PlayState] Meta integrate failed: ' + e);
			try Paths.clearAudioSuffixes() catch(e2:Dynamic) {}
		}

		// Defaults if meta/chart still empty (editor safety)
		if(SONG.player == null || SONG.player.length < 1) SONG.player = 'bf';
		if(SONG.girlfriend == null || SONG.girlfriend.length < 1) SONG.girlfriend = 'gf';
		if(SONG.opponent == null || SONG.opponent.length < 1) SONG.opponent = 'dad';
		if(SONG.bpm <= 0) SONG.bpm = 100;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		loadWeekDifficultiesForCurrentMode();
		reloadStoryHiddenSongsFromCurrentWeek();

		if(SONG.songVariation != null)
		{
			SONG.songVariation = Difficulty.getSuffixName(SONG.songVariation);
			if(SONG.songVariation.length < 1) SONG.songVariation = null;
		}
		var difficultyVariation:String = Difficulty.getDifficultyVariationName(storyDifficulty);
		if(difficultyVariation.length > 0)
		SONG.songVariation = difficultyVariation;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverState.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
		{
			var stageSongName:String = Song.loadedSongName != null ? Song.loadedSongName : SONG.song;
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(stageSongName));
		}

		curStage = SONG.stage;
		if(curStage == 'philly_remix' || curStage == 'philly-remix')
		{
			// noteStyle controls notes + splashes (no splashSkin)
			if(SONG.noteStyle == null || SONG.noteStyle.trim().length < 1)
				SONG.noteStyle = 'godot';
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		applySongNoteStyle();

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		// Pico Engine - Mod Stage
		StagesPicoEnigne.addstage(curStage); // Mod stages In Pico Engine
		#if VSLICE_ALLOWED StagesVslice.addstage(curStage); #end

		// intro SFX suffix from noteStyle.allowPixel (stageUI no longer drives UI)
		introSoundsSuffix = '';
		try
		{
			if(Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel())
				introSoundsSuffix = '-pixel';
		}
		catch(e:Dynamic) {}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.girlfriend == null || SONG.girlfriend.length < 1) SONG.girlfriend = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.girlfriend);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.opponent);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		GameOverState.resetVariables();
		
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
				{
					variables.set(key, spr);
					stageObjects.set(key, spr);
				}
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		startScriptsInFolder('scripts/game/');

		// STATE SCRIPTS — scripts/states/ (.lua + .hx / .hxc)
		startScriptsInFolder('scripts/states/');
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/'))
			startStateScriptsInFolder(folder);

		startWeekScripts();

		startModchartNamed('scripts/songs/modchart');
		startModchartNamed('scripts/stages/$curStage/modchart');
		if(SONG == null || SONG.enableSongScripts != false)
		{
			for (scriptSongName in getSongIdVariationCandidates(songName, SONG, storyDifficulty))
				startModchartNamed('scripts/songs/$scriptSongName/modchart');
		}
		#end
			
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('scripts/stages/' + curStage + '.lua'); #end
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('scripts/stages/' + curStage + '.hx');
		startHScriptsNamed('scripts/stages/' + curStage + '.hxc');
		#end

		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = Song.getDisplayName(SONG, SONG.song);
		else if(ClientPrefs.data.timeBarType == 'Default' || ClientPrefs.data.timeBarType == 'Combined'
			|| ClientPrefs.data.timeBarType == 'Time Left' || ClientPrefs.data.timeBarType == 'Time Elapsed')
			timeTxt.text = '0:00 / 0:00';

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'ui/game/funkin/timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);
		noteGroup.add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'Song Name') {
			timeTxt.size = 24;
			timeTxt.y += 3;
		}
		generateSong();

		noteGroup.add(grpHoldNoteCovers);
		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'ui/game/funkin/healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = opponentMode; // flip fill when playing as opponent
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false, true);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud && !showPlayModeText();
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y + 50, FlxG.width - 800, getPlayModeDisplayText(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.GREEN);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = !ClientPrefs.data.hideHud && showPlayModeText();
		uiGroup.add(botplayTxt);

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		updateComboCamera();
		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('scripts/events/notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('scripts/events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
		{
			startHScriptsNamed('scripts/events/notetypes/' + notetype + '.hx');
			startHScriptsNamed('scripts/events/notetypes/' + notetype + '.hxc');
		}
		for (event in eventsPushed)
		{
			startHScriptsNamed('scripts/events/' + event + '.hx');
			startHScriptsNamed('scripts/events/' + event + '.hxc');
		}
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS (toggle via chart enableSongScripts)
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		if(SONG == null || SONG.enableSongScripts != false)
		{
			for (scriptSongName in getSongIdVariationCandidates(songName, SONG, storyDifficulty))
				startScriptsInFolder('scripts/songs/$scriptSongName/');
		}
		else
			trace('[PlayState] Song scripts disabled (enableSongScripts = false)');
		#end

		// NOTESTYLE LUA: scripts/states/notestyle/<Nome_da_nota>.lua
		startNoteStyleScripts();

		if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		var pauseSong:String = (SONG != null ? SONG.pauseSong : null);
		if (pauseSong != null && pauseSong.trim().length > 0)
		{
			var formattedPauseSong:String = PauseState.resolvePauseMusicKey(pauseSong);
			if(formattedPauseSong != 'none') Paths.music(formattedPauseSong);
		}
		else if (PauseState.songName != null)
			Paths.music(PauseState.resolvePauseMusicKey(PauseState.songName));
		else if(PauseState.resolvePauseMusicKey(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(PauseState.resolvePauseMusicKey(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');
		
		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		super.create();
		Paths.clearUnusedMemory();
		try { EnginePerformance.endSongLoad(); } catch(e:Dynamic) {}

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();
	}

	function applySongNoteStyle():Void
	{
		var style:String = Note.songNoteStyle();
		if(style == null || style.length < 1)
			style = Note.defaultSongNoteStyle();

		SONG.noteStyle = style;
		NoteData.notestyles.config(style);

		#if debug
		trace('[PlayState] NoteStyle: $style');
		#end
	}

	/**
	 * Loads scripts/states/notestyle/<style>.lua for player + opponent styles.
	 */
	function startNoteStyleScripts():Void
	{
		#if LUA_ALLOWED
		var styles:Array<String> = [];
		function addStyle(s:String):Void
		{
			if(s == null || s.length < 1) return;
			var key:String = Note.noteStyleKey(s);
			if(key.length < 1) return;
			if(!styles.contains(key)) styles.push(key);
		}

		try { addStyle(NoteData.songStyle(true)); } catch(e:Dynamic) {}
		try { addStyle(NoteData.songStyle(false)); } catch(e:Dynamic) {}
		try { addStyle(Note.songNoteStyle()); } catch(e:Dynamic) {}
		try
		{
			if(SONG != null && SONG.noteStyle != null)
				addStyle(SONG.noteStyle);
		}
		catch(e:Dynamic) {}

		for (styleKey in styles)
		{
			var luaPath:String = null;
			try { luaPath = NoteData.noteStyle.getLuaPath(styleKey); } catch(e:Dynamic) { luaPath = null; }
			if(luaPath == null || luaPath.length < 1)
				luaPath = 'scripts/states/notestyle/' + styleKey + '.lua';

			// startLuasNamed expects relative path under assets/mods
			var rel:String = 'scripts/states/notestyle/' + styleKey + '.lua';
			if(startLuasNamed(rel))
				trace('[PlayState] Loaded notestyle.lua: ' + rel);
			else if(luaPath != null && luaPath != rel)
			{
				// absolute / full path fallback
				try
				{
					#if sys
					if(FileSystem.exists(luaPath))
					{
						var already:Bool = false;
						for (script in luaArray)
							if(script.scriptName == luaPath) already = true;
						if(!already)
						{
							new FunkinLuaProgramming(luaPath);
							trace('[PlayState] Loaded notestyle.lua (full): ' + luaPath);
						}
					}
					#end
				}
				catch(e:Dynamic)
					trace('[PlayState] notestyle.lua fail: ' + e);
			}
		}
		#end
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if(videoCutscene != null && videoCutscene.videoSprite != null && videoCutscene.videoSprite.bitmap != null) videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor)
	{
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	private function getHealthIconPath(iconName:String):String {
		var icon:String = iconName != null ? iconName.trim() : '';
		if(icon.length < 1) icon = 'face';

		var paths:Array<String> = [
			'icons/' + icon,
			'icons/baseGame/' + icon,
			'icons/baseGame/icon-' + icon,
			'icons/icon-' + icon,
			'icons/icon-face'
		];

		for(path in paths)
			if(Paths.fileExists('images/' + path + '.png', IMAGE))
				return path;

		return 'icons/icon-face';
	}

	private function precacheHealthIcon(iconValue:String):Void {
		var iconName:String = iconValue != null ? iconValue.split(',')[0].trim() : '';
		if(iconName.length > 0)
			Paths.image(getHealthIconPath(iconName));
	}

	private function changeHealthIcon(target:String, iconValue:String):Void {
		var split:Array<String> = iconValue != null ? iconValue.split(',') : [''];
		var iconName:String = split.shift().trim();
		var iconColor:Null<FlxColor> = parseIconColor(split);

		if(iconName.length < 1) iconName = 'face';

		switch(target.toLowerCase().trim()) {
			case 'bf' | 'boyfriend' | 'player' | 'p1' | '0':
				iconP1.changeIcon(iconName, true);
				boyfriend.healthIcon = iconP1.getCharacter();
				if(iconColor != null) setHealthColorArray(boyfriend.healthColorArray, iconColor);

			case 'dad' | 'opponent' | 'enemy' | 'p2' | '1':
				iconP2.changeIcon(iconName, true);
				dad.healthIcon = iconP2.getCharacter();
				if(iconColor != null) setHealthColorArray(dad.healthColorArray, iconColor);

			case 'both':
				iconP1.changeIcon(iconName, true);
				iconP2.changeIcon(iconName, true);
				boyfriend.healthIcon = iconP1.getCharacter();
				dad.healthIcon = iconP2.getCharacter();
				if(iconColor != null) {
					setHealthColorArray(boyfriend.healthColorArray, iconColor);
					setHealthColorArray(dad.healthColorArray, iconColor);
				}

			case 'gf' | 'girlfriend' | '2':
				if(gf != null) {
					gf.healthIcon = iconName;
					if(iconColor != null) setHealthColorArray(gf.healthColorArray, iconColor);
				}

			default:
				#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
				addTextToDebug('Change Icon: invalid target "$target"', FlxColor.RED);
				#else
				FlxG.log.warn('Change Icon: invalid target "$target"');
				#end
		}

		if(iconColor != null) reloadHealthBarColors();
	}

	private function hasEventFlag(flags:String, flag:String):Bool {
		if(flags == null) return false;

		var lowerFlags:String = flags.toLowerCase();
		for(part in lowerFlags.split(','))
			for(value in part.split(' '))
				if(value.trim() == flag)
					return true;

		return false;
	}

	private function isChangeStageEvent(eventName:String):Bool {
		if(eventName == null) return false;
		return eventName.trim() == 'Change Stages';
	}

	private function getChangeStageEventData(value1:String, value2:String):Dynamic {
		var stageName:String = value1 != null ? value1.trim() : '';
		var flags:String = value2 != null ? value2.trim() : '';

		if(stageName.indexOf(',') >= 0) {
			var splitStage:Array<String> = stageName.split(',');
			stageName = splitStage.shift().trim();
			var extraFlags:String = splitStage.join(',').trim();
			if(extraFlags.length > 0)
				flags = flags.length > 0 ? extraFlags + ', ' + flags : extraFlags;
		}

		if(stageName.length < 1 && flags.length > 0) {
			var splitFlags:Array<String> = flags.split(',');
			stageName = splitFlags.shift().trim();
			flags = splitFlags.join(',').trim();
		}

		return {stageName: stageName, flags: flags};
	}

	private function getStageNameFromEventValues(value1:String, value2:String):String {
		var eventData:Dynamic = getChangeStageEventData(value1, value2);
		return eventData.stageName;
	}

	private function runChangeStageEvent(value1:String, value2:String):Void {
		var eventData:Dynamic = getChangeStageEventData(value1, value2);
		var stageName:String = eventData.stageName;
		var flags:String = eventData.flags;

		if(stageName.length < 1) {
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Change Stages: missing stage name', FlxColor.RED);
			#else
			FlxG.log.warn('Change Stages: missing stage name');
			#end
			return;
		}

		changeStage(stageName, !hasEventFlag(flags, 'noscripts') && !hasEventFlag(flags, 'nolua'), !hasEventFlag(flags, 'noposition'));
	}

	private function parseIconColor(values:Array<String>):Null<FlxColor> {
		if(values == null || values.length < 1) return null;

		var colorText:String = values.join(',').trim();
		if(colorText.length < 1) return null;

		if(values.length >= 3) {
			var red:Null<Float> = Std.parseFloat(values[0].trim());
			var green:Null<Float> = Std.parseFloat(values[1].trim());
			var blue:Null<Float> = Std.parseFloat(values[2].trim());
			if(red != null && green != null && blue != null && !Math.isNaN(red) && !Math.isNaN(green) && !Math.isNaN(blue))
				return FlxColor.fromRGB(Math.round(red), Math.round(green), Math.round(blue));
		}

		if(colorText.charAt(0) == '#')
			colorText = '0xFF' + colorText.substr(1);
		else if(colorText.toLowerCase().indexOf('0x') != 0)
			colorText = '0xFF' + colorText;

		var parsed:Null<Int> = Std.parseInt(colorText);
		if(parsed == null) return null;
		return FlxColor.fromInt(parsed);
	}

	private function setHealthColorArray(colorArray:Array<Int>, color:FlxColor):Void {
		colorArray[0] = color.red;
		colorArray[1] = color.green;
		colorArray[2] = color.blue;
	}

	private function applyCurStageData(nextStage:String, stageData:StageFile):Void {
		curStage = nextStage;
		SONG.stage = nextStage;
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;

		stageUI = "normal";
		if(stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if(stageData.isPixelStage == true)
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];
		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];
		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		setOnScripts('curStage', curStage);
		setOnScripts('stageUI', stageUI);
		setOnScripts('isPixelStage', isPixelStage);
	}

	public function changeStage(stageName:String, ?loadLua:Bool = true, ?repositionCharacters:Bool = true):Bool {
		if(stageName == null || stageName.trim().length < 1) {
			FlxG.log.warn('Change Stages: empty stage name');
			return false;
		}

		var nextStage:String = stageName.trim();
		var previousStage:String = curStage;
		var stageData:StageFile = StageData.getStageFile(nextStage);
		if(stageData == null) {
			FlxG.log.warn('Change Stages: stage "$nextStage" could not be loaded');
			return false;
		}

		var ret:Dynamic = callOnScripts('onStageChanging', [previousStage, nextStage], true);
		if(ret == LuaUtils.Function_Stop) return false;
		clearStageObjects();

		applyCurStageData(nextStage, stageData);

		remove(gfGroup, true);
		remove(dadGroup, true);
		remove(boyfriendGroup, true);

		if(repositionCharacters) {
			boyfriendGroup.setPosition(BF_X, BF_Y);
			dadGroup.setPosition(DAD_X, DAD_Y);
			gfGroup.setPosition(GF_X, GF_Y);
		}

		if(gfGroup != null) gfGroup.visible = !stageData.hide_girlfriend;

		if(stageData.objects != null && stageData.objects.length > 0) {
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key)) {
					variables.set(key, spr);
					stageObjects.set(key, spr);
				}
		} else {
			if(!stageData.hide_girlfriend) add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		StagesPicoEnigne.addstage(curStage);
		#if VSLICE_ALLOWED StagesVslice.addstage(curStage); #end

		#if LUA_ALLOWED
		closeStageLua(previousStage);
		if(loadLua) startLuasNamed('scripts/stages/' + curStage + '.lua');
		#end
		#if HSCRIPT_ALLOWED
		if(loadLua) {
			startHScriptsNamed('scripts/stages/' + curStage + '.hx');
			startHScriptsNamed('scripts/stages/' + curStage + '.hxc');
			startModchartNamed('scripts/stages/$curStage/modchart');
		}
		#end

		callOnScripts('onStageChanged', [previousStage, curStage]);
		return true;
	}

	function clearStageObjects():Void {
		var keys:Array<String> = [];
		for (key in stageObjects.keys())
			keys.push(key);

		for (key in keys) {
			var spr:FlxSprite = stageObjects.get(key);
			if(spr != null) {
				remove(spr, true);
				spr.destroy();
			}
			stageObjects.remove(key);
			variables.remove(key);
		}
	}

	#if LUA_ALLOWED
	function closeStageLua(stageName:String):Void {
		if(stageName == null || stageName.length < 1) return;

		var suffix:String = ('scripts/stages/' + stageName + '.lua').toLowerCase();
		for (script in luaArray) {
			var scriptName:String = script.scriptName.replace('\\', '/').toLowerCase();
			if(!script.closed && scriptName.endsWith(suffix)) {
				script.call('onStageDestroy', [stageName]);
				script.stop();
			}
		}
	}
	#end

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'scripts/characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLuaProgramming(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('scripts/characters/' + name + '.hx');
		startHScriptsNamed('scripts/characters/' + name + '.hxc');
		#end
	}

	function startSubstateScripts(name:String) {
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('scripts/substate/' + name + '.hx');
		startHScriptsNamed('scripts/substate/' + name + '.hxc');
		#end
	}

	public function getLuaObject(tag:String):Dynamic {
		return variables.get(tag);
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if(forMidSong && videoCutscene != null && videoCutscene.videoSprite != null && videoCutscene.videoSprite.bitmap != null) videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverState.instance != null && isDead) GameOverState.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAlts:Array<String> = getCountdownImages();
		for (asset in introAlts) Paths.image(asset);

		Paths.sound(Note.resolveNoteStyleUiSound('countdownThree', 'intro3' + introSoundsSuffix));
		Paths.sound(Note.resolveNoteStyleUiSound('countdownTwo', 'intro2' + introSoundsSuffix));
		Paths.sound(Note.resolveNoteStyleUiSound('countdownOne', 'intro1' + introSoundsSuffix));
		Paths.sound(Note.resolveNoteStyleUiSound('countdownGo', 'introGo' + introSoundsSuffix));
	}

	function getCountdownImages():Array<String>
	{
		// Countdown images come from noteStyle (countdownTwo/One/Go). stageUI no longer used.
		var pixelUi:Bool = false;
		try { pixelUi = Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel(); } catch(e:Dynamic) {}
		var introImagesArray:Array<String> = pixelUi
			? ['ui/countdown/pixel/ready-pixel', 'ui/countdown/pixel/set-pixel', 'ui/countdown/pixel/date-pixel']
			: ['ready', 'set', 'go'];

		return [
			Note.resolveNoteStyleUiAsset('countdownTwo', introImagesArray[0]),
			Note.resolveNoteStyleUiAsset('countdownOne', introImagesArray[1]),
			Note.resolveNoteStyleUiAsset('countdownGo', introImagesArray[2])
		];
	}

	inline function noteStyleUiScale(assetName:String, fallback:Float):Float
	{
		return Note.noteStyleUiScale(assetName, fallback);
	}

	inline function noteStyleUiAntialias(assetName:String):Bool
	{
		var stylePixel:Bool = Note.noteStyleUsesPixel() || Note.noteStyleUiIsPixel(assetName, false);
		return ClientPrefs.data.antialiasing && !stylePixel;
	}

	inline function noteStyleUiPixelFallback():Bool
	{
		return Note.noteStyleUsesPixel();
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAlts:Array<String> = getCountdownImages();
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound(Note.resolveNoteStyleUiSound('countdownThree', 'intro3' + introSoundsSuffix)), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], noteStyleUiAntialias('countdownTwo'), noteStyleUiScale('countdownTwo', noteStyleUiPixelFallback() ? daPixelZoom : 1));
						FlxG.sound.play(Paths.sound(Note.resolveNoteStyleUiSound('countdownTwo', 'intro2' + introSoundsSuffix)), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], noteStyleUiAntialias('countdownOne'), noteStyleUiScale('countdownOne', noteStyleUiPixelFallback() ? daPixelZoom : 1));
						FlxG.sound.play(Paths.sound(Note.resolveNoteStyleUiSound('countdownOne', 'intro1' + introSoundsSuffix)), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], noteStyleUiAntialias('countdownGo'), noteStyleUiScale('countdownGo', noteStyleUiPixelFallback() ? daPixelZoom : 1));
						FlxG.sound.play(Paths.sound(Note.resolveNoteStyleUiSound('countdownGo', 'introGo' + introSoundsSuffix)), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				if(!skipArrowStartTween)
				{
					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.data.opponentStrums || isPlayerNote(note))
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.data.middleScroll && !isPlayerNote(note))
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool, scale:Float = 1):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (scale != 1)
			spr.setGraphicSize(Std.int(spr.width * scale));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText()
	{
		// Accuracy (98.5% P+) — rank letter only, no FC
		var accBlock:String = Rank.formatAccuracyWithRank(totalPlayed != 0 ? ratingPercent : 0, songMisses);

		var hideMissesOnScore:Bool = false;
		try
		{
			hideMissesOnScore = Reflect.field(ClientPrefs.data, 'comboEnabled') == true;
		}
		catch(e:Dynamic)
		{
			hideMissesOnScore = false;
		}

		var scoreStr:String = formatSongScore(songScore);
		var tempScore:String;
		if(!instakillOnMiss && !hideMissesOnScore)
		{
			// Score: 1,900 | Misses: 2 | Accuracy (98.5% P+)
			tempScore = 'Score: ' + scoreStr
				+ ' | Misses: ' + songMisses
				+ ' | ' + accBlock;
		}
		else
		{
			// Score: 1,900 | Accuracy (98.5% P+)
			tempScore = 'Score: ' + scoreStr
				+ ' | ' + accBlock;
		}

		scoreTxt.text = tempScore;
	}

	/** Formats score with thousands separators: 1900 → "1,900" */
	public static function formatSongScore(score:Int):String
	{
		var negative:Bool = score < 0;
		var n:Int = negative ? -score : score;
		var s:String = Std.string(n);
		var out:String = '';
		var count:Int = 0;
		var i:Int = s.length;
		while(i > 0)
		{
			out = s.charAt(i - 1) + out;
			count++;
			i--;
			if(count % 3 == 0 && i > 0)
				out = ',' + out;
		}
		return negative ? ('-' + out) : out;
	}

	/**
	 * Base-game style hold score: while the player is holding a hit sustain,
	 * grant SCORE_HOLD_BONUS_PER_SECOND points each second (fractional per frame).
	 */
	function applyScoreHold(elapsed:Float):Void
	{
		if(cpuControlled || practiceMode || endingSong || !generatedMusic)
			return;
		if(elapsed <= 0) return;

		if(!isPlayerHoldingSustain())
			return;

		scoreHoldAccum += SCORE_HOLD_BONUS_PER_SECOND * elapsed * playbackRate;
		var whole:Int = Math.floor(scoreHoldAccum);
		if(whole <= 0) return;
		scoreHoldAccum -= whole;
		songScore += whole;
		updateScoreText();
	}

	/** True if player currently holds at least one active sustain that was hit. */
	function isPlayerHoldingSustain():Bool
	{
		if(notes == null) return false;
		for (n in notes)
		{
			if(n == null || !n.alive) continue;
			if(!isPlayerNote(n)) continue;
			if(!n.isSustainNote) continue;
			if(n.hitCausesMiss || n.ignoreNote) continue;
			// Hit head / previous pieces and still on-screen / holdable
			if(n.wasGoodHit && !n.tooLate)
				return true;
			// Parent was hit and this piece is the active trail
			if(n.parent != null && n.parent.wasGoodHit && !n.tooLate && n.canBeHit)
				return true;
		}
		return false;
	}

	public function setComboOffset(ratingX:Int = 0, ratingY:Int = 0, numbersX:Int = 0, numbersY:Int = 0):Void
	{
		ClientPrefs.data.comboOffset[0] = ratingX;
		ClientPrefs.data.comboOffset[1] = ratingY;
		ClientPrefs.data.comboOffset[2] = numbersX;
		ClientPrefs.data.comboOffset[3] = numbersY;
	}

	public dynamic function fullComboFunction()
	{
		var marvelouss:Int = getRatingHits('marvelous');
		var perfects:Int = getRatingHits('perfect');
		var sicks:Int = getRatingHits('sick');
		var goods:Int = getRatingHits('good');
		var bads:Int = getRatingHits('bad');
		var shits:Int = getRatingHits('shit');

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'Very Bad!';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'FC';
			else if (perfects > 0) ratingFC = 'PFC'
			else if (marvelouss > 0) ratingFC = 'MFC';
		}
		else {
			if (songMisses < 20) ratingFC = 'SDCB';
			else ratingFC = 'What?';
		}
	}

	function getRatingHits(name:String):Int
	{
		for(rating in ratingsData)
			if(rating != null && rating.name == name)
				return rating.hits;
		return 0;
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		}
		else vocals.pause();

		if (Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
			opponentVocals.play();
		}
		else opponentVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns: Int = 4;

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());
		var baseSpeed:Float = 1;
		if(PlayState.SONG != null)
		{
			baseSpeed = PlayState.SONG.speed;
			if(Math.isNaN(baseSpeed) || baseSpeed <= 0)
				baseSpeed = 1;
		}
		songSpeed = baseSpeed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = baseSpeed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		if(songData == null)
		{
			trace('[generateSong] SONG is null — cannot generate chart notes');
			generatedMusic = false;
			return;
		}
		if(!Math.isNaN(songData.bpm) && songData.bpm > 0)
			Conductor.bpm = songData.bpm;

		try Paths.applyAudioSuffixesFromSong(songData) catch(e:Dynamic) {}
		var songAssetId:String = getSongAudioId(songData.song, songData, storyDifficulty);
		curSong = songAssetId;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var bfVocalsFile:String = (boyfriend != null && boyfriend.vocalsFile != null && boyfriend.vocalsFile.length > 0) ? boyfriend.vocalsFile : 'Player';
				var dadVocalsFile:String = (dad != null && dad.vocalsFile != null && dad.vocalsFile.length > 0) ? dad.vocalsFile : 'Opponent';

				var playerVocals = Paths.voices(songAssetId, bfVocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songAssetId));
				
				var oppVocals = Paths.voices(songAssetId, dadVocalsFile);
				if(oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songAssetId));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = null;
			for (eventChartName in getEventsChartCandidates(SONG, storyDifficulty))
			{
				try
				{
					eventsChart = Song.getChart(eventChartName, songName);
					if(eventsChart != null) break;
				}
				catch(e:Dynamic) {}
			}
			if(eventsChart != null && eventsChart.events != null)
			{
				for (event in eventsChart.events) //Event Notes
				{
					if(event == null || event[1] == null) continue;
					for (i in 0...event[1].length)
						makeEvent(event, i);
				}
			}
		}
		catch(e:Dynamic) {}

		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = (PlayState.SONG != null && PlayState.SONG.notes != null) ? PlayState.SONG.notes : [];
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;
	
		for (section in sectionsData)
		{
			if(section == null || section.sectionNotes == null) continue;
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes: Array<Dynamic> = section.sectionNotes[i];
				var spawnTime: Float = songNotes[0];
				var noteColumn: Int = Std.int(songNotes[1] % totalColumns);
				var holdLength: Float = songNotes[2];
				var noteType: String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				if (Math.isNaN(holdLength))
					holdLength = 0.0;

				var gottaHitNote:Bool = (songNotes[1] < totalColumns);

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in unspawnNotes) {
						var matches: Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
							if (evilNote.tail.length > 0)
								for (tail in evilNote.tail)
								{
									tail.destroy();
									unspawnNotes.remove(tail);
								}
							evilNote.destroy();
							unspawnNotes.remove(evilNote);
							ghostNotesCaught++;
							//continue;
						}
					}
				}

				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
				var isAlt: Bool = section.altAnim && !gottaHitNote;
				swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				swagNote.animSuffix = isAlt ? "-alt" : "";
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.reloadNote(Note.songArrowSkinForMustPress(swagNote.mustPress));
				swagNote.noteType = noteType;
	
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
				if(roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.reloadNote(Note.songArrowSkinForMustPress(sustainNote.mustPress));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(noteColumn > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(noteColumn > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);

				oldNote = swagNote;
			}
		}
		var chartName:String = (SONG != null && SONG.song != null) ? SONG.song.toUpperCase() : 'UNKNOWN';
		trace('["$chartName" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		// Chart events may be null after meta split / stripped charts
		if(songData != null && songData.events != null)
		{
			for (event in songData.events)
			{
				if(event == null || event[1] == null) continue;
				for (i in 0...event[1].length)
					makeEvent(event, i);
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound

			case 'Change Icon' | 'change icon':
				precacheHealthIcon(event.value2);

			case 'Change Stages' | 'Change Stage':
				var stageName:String = getStageNameFromEventValues(event.value1, event.value2);
				if(stageName.length > 0) {
					var stageData:StageFile = StageData.getStageFile(stageName);
					if(stageData != null && stageData.objects != null && stageData.objects.length > 0)
						for(data in stageData.objects) {
							var type:Dynamic = Reflect.getProperty(data, 'type');
							var image:Dynamic = Reflect.getProperty(data, 'image');
							if(image != null) {
								if(type == 'animatedSprite') Paths.getAtlas(image);
								else if(type == 'sprite') Paths.image(image);
							}
						}
				}
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onModChartPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
		callOnModchartXmlPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			var playerSide:Bool = (player == 1) == playsAsBF();
			if (!playerSide)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
	}
	#end

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH voc.pitch = playbackRate; #end
				voc.play();
			}
			else voc.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var idleAnim:Bool = (boyfriend.getAnimationName().startsWith('idle') || boyfriend.getAnimationName().startsWith('danceLeft') || boyfriend.getAnimationName().startsWith('danceRight'));
			if(!startingSong && !endingSong && idleAnim) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplayTxt.text = getPlayModeDisplayText();
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openStageEditor();
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			if(songLength > 0)
				songPercent = (curTime / songLength);
			else
				songPercent = 0;

			var elapsedSec:Int = Math.floor(curTime / 1000);
			if(elapsedSec < 0) elapsedSec = 0;
			var totalSec:Int = Math.floor(songLength / 1000);
			if(totalSec < 0) totalSec = 0;
			var leftSec:Int = totalSec - elapsedSec;
			if(leftSec < 0) leftSec = 0;

			// Legacy prefs
			var barType:String = ClientPrefs.data.timeBarType;
			if(barType == 'Time Elapsed')
				barType = 'Default';
			else if(barType == 'Time Left')
				barType = 'Combined';

			switch(barType)
			{
				case 'Song Name':
					timeTxt.text = Song.getDisplayName(SONG, SONG.song);
				case 'Default':
					// Current Combined style: 0:04 / 2:19 (elapsed / total)
					timeTxt.text = FlxStringUtil.formatTime(elapsedSec, false) + ' / ' + FlxStringUtil.formatTime(totalSec, false);
				case 'Combined':
					// Classic: elapsed | time left (Time Elapsed + Time Left)
					timeTxt.text = FlxStringUtil.formatTime(elapsedSec, false) + ' | ' + FlxStringUtil.formatTime(leftSec, false);
				case 'Percentage':
					var percent:Int = Math.floor(FlxMath.bound(songPercent, 0, 1) * 100);
					timeTxt.text = percent + '%';
				default:
					timeTxt.text = FlxStringUtil.formatTime(leftSec, false);
			}
		}

		// Base FNF scoreHold while sustaining
		applyScoreHold(elapsed);

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							if(daNote == null) continue;

							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							var playerNote:Bool = isPlayerNote(daNote);
							if(playerNote)
							{
								// Botplay on the side the player controls (BF or Opponent)
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else
							{
								// CPU side (BF when Opponent Mode) — auto-hit when note reaches strum
								if(!daNote.hitByOpponent && !daNote.ignoreNote && !daNote.blockHit
									&& (daNote.wasGoodHit || daNote.strumTime <= Conductor.songPosition))
								{
									if(!daNote.isSustainNote || daNote.wasGoodHit || (daNote.prevNote != null && daNote.prevNote.wasGoodHit))
										opponentNoteHit(daNote);
								}
							}

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (playerNote && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
							if(daNote.exists) i++;
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('botPlay', cpuControlled);
		setOnScripts('opponentMode', opponentMode);
		setOnScripts('playingAsBF', playsAsBF());
		callOnScripts('onUpdatePost', [elapsed]);
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		if(iconP1 != null) iconP1.updateHealthState(healthBar.percent, false);
		if(iconP2 != null) iconP2.updateHealthState(healthBar.percent, true);
		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in getPlayerStrums())
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	public static function playsAsBF():Bool
		return !opponentMode;

	/** Reads chart opponentMode whether stored as Bool or String */
	public static function isSongOpponentModeFlag(?song:SwagSong = null):Bool
	{
		if(song == null) song = SONG;
		if(song == null) return false;
		var raw:Dynamic = Reflect.field(song, 'opponentMode');
		if(raw == true || raw == false) return raw == true;
		if(raw == null) return false;
		var s:String = Std.string(raw).trim().toLowerCase();
		return s == 'true' || s == '1' || s == 'on' || s == 'yes';
	}

	/** Gameplay Changers: opponentplay / opponentmode / playasopponent */
	public static function readOpponentModeSetting():Bool
	{
		try
		{
			for (key in ['opponentplay', 'opponentmode', 'playasopponent', 'opponent'])
			{
				var value:Dynamic = ClientPrefs.getGameplaySetting(key);
				if(value == true || value == 'true' || value == 1 || value == '1')
					return true;
			}
		}
		catch(e:Dynamic) {}
		return false;
	}

	public static function isPlayerNote(note:Note):Bool
		return note != null && isPlayerNoteSide(note.mustPress);

	public static function isPlayerNoteSide(mustPress:Bool):Bool
		return mustPress == playsAsBF();

	public function getPlayerStrums():FlxTypedGroup<StrumNote>
		return playsAsBF() ? playerStrums : opponentStrums;

	public function getOpponentStrums():FlxTypedGroup<StrumNote>
		return playsAsBF() ? opponentStrums : playerStrums;

	function getPlayerCharacter():Character
		return playsAsBF() ? boyfriend : dad;

	function getOpponentCharacter():Character
		return playsAsBF() ? dad : boyfriend;

	function getPlayerVocals():FlxSound
		return (!playsAsBF() && opponentVocals != null && opponentVocals.length > 0) ? opponentVocals : vocals;

	function getOpponentVocals():FlxSound
		return (playsAsBF() && opponentVocals != null && opponentVocals.length > 0) ? opponentVocals : vocals;

	function getPlayModeText():String
		return Language.getPhrase("Pico Bot").toUpperCase();

	function showPlayModeText():Bool
		return cpuControlled || opponentMode;

	function getPlayModeDisplayText():String
	{
		if(cpuControlled && opponentMode)
			return 'BOTPLAY + OPPONENT';
		if(opponentMode)
			return 'OPPONENT MODE';
		if(cpuControlled)
			return getPlayModeText();
		return '';
	}

	function addPlayerHealth(value:Float):Float
	{
		if(playsAsBF())
			health += value;
		else
			health -= value;
		return health;
	}

	function subtractPlayerHealth(value:Float):Float
	{
		if(playsAsBF())
			health -= value;
		else
			health += value;
		return health;
	}

	function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.opponent));
	}

	function openStageEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new StageEditorState(curStage));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		var maxHealth:Float = (healthBar != null && healthBar.bounds != null && healthBar.bounds.max != null) ? healthBar.bounds.max : 2;
		var playerDead:Bool = skipHealthCheck && instakillOnMiss;
		if(!playerDead)
			playerDead = playsAsBF() ? health <= 0 : health >= maxHealth;

		if (playerDead && !practiceMode && !isDead && gameOverTimer == null)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				var playerCharacter:Character = getPlayerCharacter();
				if(playerCharacter == null) playerCharacter = boyfriend;
				playerCharacter.stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				FlxG.camera.setFilters([]);

				if(GameOverState.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverState.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverState(playerCharacter));
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverState(playerCharacter));
				}

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	function hasEventValueToken(value:String, token:String):Bool
	{
		if(value == null) return false;
		for(part in value.split(','))
		{
			if(part.toLowerCase().trim() == token) return true;
		}
		return false;
	}

	function removePlayAnimationForcedFlags(value:String):String
	{
		if(value == null) return '';

		var parts:Array<String> = [];
		for(part in value.split(','))
		{
			var trimmed:String = part.trim();
			var lower:String = trimmed.toLowerCase();
			if(lower == 'forced' || lower == 'force' || lower == 'true' || lower == 'not forced' || lower == 'no force' || lower == 'unforced' || lower == 'false') continue;
			if(trimmed.length > 0) parts.push(trimmed);
		}
		return parts.join(', ');
	}

	function isPlayAnimationForced(value:String):Bool
	{
		if(hasEventValueToken(value, 'not forced') || hasEventValueToken(value, 'no force') || hasEventValueToken(value, 'unforced') || hasEventValueToken(value, 'false')) return false;
		if(hasEventValueToken(value, 'forced') || hasEventValueToken(value, 'force') || hasEventValueToken(value, 'true')) return true;
		return true;
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				var characterValue:String = removePlayAnimationForcedFlags(value2);
				var forced:Bool = isPlayAnimationForced(value2);
				var animationTargetValue:Null<Float> = Std.parseFloat(characterValue);
				if(Math.isNaN(animationTargetValue)) animationTargetValue = null;
				switch(characterValue.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(animationTargetValue == null) animationTargetValue = 0;
						switch(Math.round(animationTargetValue)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, forced);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon, true);
							GameOverState.resetVariables();
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon, true);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Icon' | 'change icon':
				changeHealthIcon(value1, value2);

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Change Stages' | 'Change Stage':
				runChangeStageEvent(value1, value2);

			case 'Change Notestyle' | 'Change NoteStyle' | 'Change Note Style':
				applyChangeNotestyleEvent(value1, value2);

			case 'Change Rating Skin':
				applyChangeRatingSkinEvent(value1, value2);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}


	/** Chart event: Change Notestyle
	 * Value 1: bf/dad/gf OR song/chart/notes/all
	 * Value 2: style name (funkin, pixel, character style id)
	 */
	function applyChangeNotestyleEvent(value1:String, value2:String):Void
	{
		var target:String = value1 != null ? value1.toLowerCase().trim() : 'song';
		var styleName:String = value2 != null ? value2.trim() : '';
		if(styleName.length < 1)
		{
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Change Notestyle: missing style name (Value 2)', FlxColor.RED);
			#else
			FlxG.log.warn('Change Notestyle: missing style name (Value 2)');
			#end
			return;
		}

		try { NoteData.clearCache(); } catch(e:Dynamic) {}

		switch(target)
		{
			case 'song' | 'chart' | 'notes' | 'all' | 'notestyle' | '':
				if(SONG != null) SONG.noteStyle = styleName;
				try { NoteData.notestyles.reloadStyle(styleName, false); } catch(e:Dynamic) {}
				reloadAllNoteTextures();
				trace('[PlayState] Change Notestyle (song) → ' + styleName);

			case 'bf' | 'boyfriend' | '0' | 'player':
				applyCharacterNoteStyle(boyfriend, styleName, true);
				trace('[PlayState] Change Notestyle (bf) → ' + styleName);

			case 'dad' | 'opponent' | '1':
				applyCharacterNoteStyle(dad, styleName, false);
				trace('[PlayState] Change Notestyle (dad) → ' + styleName);

			case 'gf' | 'girlfriend' | '2':
				applyCharacterNoteStyle(gf, styleName, true);
				trace('[PlayState] Change Notestyle (gf) → ' + styleName);

			default:
				if(SONG != null) SONG.noteStyle = styleName;
				try { NoteData.notestyles.reloadStyle(styleName, false); } catch(e:Dynamic) {}
				reloadAllNoteTextures();
				trace('[PlayState] Change Notestyle (default/song) → ' + styleName);
		}

		setOnScripts('noteStyleName', styleName);
		setOnScripts('noteStyleTarget', target);
	}

	function applyCharacterNoteStyle(char:Character, styleName:String, isPlayerSide:Bool):Void
	{
		if(char == null) return;
		try { Reflect.setField(char, 'noteStyle', styleName); } catch(e:Dynamic) {}
		try { Reflect.setField(char, 'useNotestyle', true); } catch(e:Dynamic) {}
		try { NoteData.notestyles.reloadStyle(styleName, true); } catch(e:Dynamic) {}
		reloadNoteTexturesForSide(isPlayerSide);
	}

	function reloadNoteTexturesForSide(isPlayer:Bool):Void
	{
		var skin:String = Note.songArrowSkinForMustPress(isPlayer);
		if(isPlayer)
		{
			if(playerStrums != null)
				for (strum in playerStrums)
					if(strum != null) strum.texture = skin;
		}
		else
		{
			if(opponentStrums != null)
				for (strum in opponentStrums)
					if(strum != null) strum.texture = skin;
		}

		if(notes != null)
		{
			for (note in notes)
			{
				if(note == null) continue;
				if(note.mustPress == isPlayer)
					note.reloadNote();
			}
		}
		if(unspawnNotes != null)
		{
			for (note in unspawnNotes)
			{
				if(note == null) continue;
				if(note.mustPress == isPlayer)
					note.reloadNote();
			}
		}
	}

	function reloadAllNoteTextures():Void
	{
		reloadNoteTexturesForSide(true);
		reloadNoteTexturesForSide(false);
	}

	/** Chart event: Change Rating Skin
	 * Value 1: directory ending with /
	 * Value 2: suffix e.g. -pixel
	 */
	function applyChangeRatingSkinEvent(value1:String, value2:String):Void
	{
		var dir:String = value1 != null ? value1.trim() : '';
		var suffix:String = value2 != null ? value2.trim() : '';

		if(dir.length > 0 && !StringTools.endsWith(dir, '/'))
			dir += '/';

		ratingSkinDirectory = dir;
		ratingSkinSuffix = suffix;

		if(dir.length < 1 && suffix == '-pixel')
		{
			uiPostfix = '-pixel';
		}
		else if(dir.length > 0)
		{
			uiPrefix = StringTools.endsWith(dir, '/') ? dir.substr(0, dir.length - 1) : dir;
			uiPostfix = suffix;
		}

		setOnScripts('ratingSkinDirectory', ratingSkinDirectory);
		setOnScripts('ratingSkinSuffix', ratingSkinSuffix);
		trace('[PlayState] Change Rating Skin → dir=' + ratingSkinDirectory + ' suffix=' + ratingSkinSuffix);
	}

		public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			moveCameraToGirlfriend();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		if (isDad)
			callOnScripts('onMoveCamera', ['dad']);
		else
			callOnScripts('onMoveCamera', ['boyfriend']);
	}
	
	public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		tweenCamIn();
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if(dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			if(boyfriend == null) return;
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					subtractPlayerHealth(0.05 * healthLoss);
			});
			for (daNote in unspawnNotes)
			{
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					subtractPlayerHealth(0.05 * healthLoss);
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var beatsWeeks:String = WeekData.getWeekFileName() + '-beat';
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([beatsWeeks, weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie' #if BASE_GAME_FILES, 'debugger' #end]);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			var scoreSongName:String = Song.loadedSongName != null ? Song.loadedSongName : SONG.song;
			Highscore.saveScore(scoreSongName, songScore, storyDifficulty, percent, getSongVariationName(SONG), WeekData.getCurrentWeek(), !isStoryMode, opponentMode, songMisses);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				removeCurrentStorySongFromPlaylist();
				removeHiddenStorySongsFromPlaylist();

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					MusicBeatState.switchState(new StoryMenuState());

					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty, WeekData.getCurrentWeek(), false, opponentMode);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var nextSongName:String = Paths.formatToSongPath(PlayState.storyPlaylist[0]);
					var difficulty:String = Difficulty.getVariationAndDifficultyFilePath(getSongVariationName(SONG), storyDifficulty);

					trace('LOADING NEXT SONG');
					trace(nextSongName + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					loadSongWithVariationFallback(nextSongName, SONG, storyDifficulty);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingScreenState.prepareToSong();
					LoadingScreenState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				MusicBeatState.switchState(new FreeplayMenuState());
				FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	function ratingToNoteStyleUiKey(ratingImage:String):String
	{
		// noteStyle JSON uses rating_sick / sick (not stageUI judgement paths)
		if(ratingImage == null || ratingImage.length < 1) return 'rating_sick';
		return 'rating_' + ratingImage.toLowerCase();
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(resolvePopUpRatingAsset(rating.image));
		Paths.image(Note.resolveNoteStyleUiAsset('combo', popUpComboFallback()));
		for (i in 0...10)
			Paths.image(Note.resolveNoteStyleUiAsset('comboNumber$i', popUpNumberFallback(i)));
	}

	function popUpRatingFallback(image:String):String
	{
		// Event Change Rating Skin still allowed; otherwise default paths (noteStyle overrides first)
		if(ratingSkinDirectory != null && ratingSkinDirectory.length > 0)
			return ratingSkinDirectory + image + (ratingSkinSuffix != null ? ratingSkinSuffix : '');
		var pixelUi:Bool = false;
		try { pixelUi = Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel(); } catch(e:Dynamic) {}
		if(pixelUi && image != 'marvelous')
			return 'ui/popup/pixel/$image';
		return image; // Paths.image resolves shared rating sprites
	}

	function resolvePopUpRatingAsset(image:String):String
	{
		return Note.resolveNoteStyleUiAsset(ratingToNoteStyleUiKey(image), popUpRatingFallback(image));
	}

	function popUpComboFallback():String
	{
		if(ratingSkinDirectory != null && ratingSkinDirectory.length > 0)
			return ratingSkinDirectory + 'combo' + (ratingSkinSuffix != null ? ratingSkinSuffix : '');
		var pixelUi:Bool = false;
		try { pixelUi = Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel(); } catch(e:Dynamic) {}
		return pixelUi ? 'ui/popup/pixel/combo' : 'combo';
	}

	function popUpNumberFallback(digit:Int):String
	{
		if(ratingSkinDirectory != null && ratingSkinDirectory.length > 0)
			return ratingSkinDirectory + 'num' + digit + (ratingSkinSuffix != null ? ratingSkinSuffix : '');
		var pixelUi:Bool = false;
		try { pixelUi = Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel(); } catch(e:Dynamic) {}
		return pixelUi ? 'ui/popup/pixel/num$digit' : 'num$digit';
	}

	function comboCameraNormalized():String
	{
		var comboCam:String = Std.string(ClientPrefs.data.comboCam).toLowerCase().trim();
		// New labels
		if(comboCam == 'combo game' || comboCam == 'camgame' || comboCam == 'game')
			return 'game';
		if(comboCam == 'disabled' || comboCam == 'none' || comboCam == 'off')
			return 'disabled';
		// Combo HUD + legacy
		return 'hud';
	}

	function comboCameraUsesGame():Bool
		return comboCameraNormalized() == 'game';

	function comboCameraDisabled():Bool
		return comboCameraNormalized() == 'disabled';

	function updateComboCamera():Void
	{
		if(comboGroup == null) return;
		if(comboCameraDisabled())
		{
			comboGroup.visible = false;
			return;
		}
		comboGroup.visible = true;
		comboGroup.cameras = [comboCameraUsesGame() ? camGame : camHUD];
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		getPlayerVocals().volume = 1;

		// Still score/rate when combo camera is Disabled — only hide visuals later
		var hideComboVisuals:Bool = comboCameraDisabled();

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}
		updateComboCamera();

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var antialias:Bool = ClientPrefs.data.antialiasing;
		try
		{
			if(Note.noteStyleUsesPixel() || NoteData.noteStyle.allowPixel())
				antialias = false;
		}
		catch(e:Dynamic) {}

		var ratingUiAsset:String = ratingToNoteStyleUiKey(daRating.image);
		rating.loadGraphic(Paths.image(resolvePopUpRatingAsset(daRating.image)));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating && !hideComboVisuals);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = noteStyleUiAntialias(ratingUiAsset);
		if(comboCameraUsesGame())
		{
			rating.x = GF_X + 260;
			rating.y = GF_Y + 330;
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(Note.resolveNoteStyleUiAsset('combo', popUpComboFallback())));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo && !hideComboVisuals);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = noteStyleUiAntialias('combo');
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);
		if(comboCameraUsesGame())
		{
			comboSpr.x = rating.x + 40;
			comboSpr.y = rating.y + 80;
		}

		// Scale do combo/rating vem do noteStyle (allowPixel define fallback pixel)
		var popupScale:Float = !Note.noteStyleUsesPixel() ? 0.7 : daPixelZoom * 0.85;
		rating.setGraphicSize(Std.int(rating.width * noteStyleUiScale(ratingUiAsset, popupScale)));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * noteStyleUiScale('combo', popupScale)));

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var digit:Int = Std.parseInt(separatedScore.charAt(i));
			var numberUiAsset:String = 'comboNumber$digit';
			// noteStyle: "hidden": true esconde este dígito (ex.: comboNumber0)
			if(Note.noteStyleUiIsHidden(numberUiAsset))
				continue;

			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(Note.resolveNoteStyleUiAsset(numberUiAsset, popUpNumberFallback(digit))));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			if(comboCameraUsesGame())
			{
				numScore.x = rating.x + (43 * daLoop) - 45;
				numScore.y = rating.y + 140;
			}

			numScore.setGraphicSize(Std.int(numScore.width * noteStyleUiScale(numberUiAsset, !Note.noteStyleUsesPixel() ? 0.5 : daPixelZoom)));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud && !hideComboVisuals;
			numScore.antialiasing = noteStyleUiAntialias(numberUiAsset);

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		var playerStrumGroup:FlxTypedGroup<StrumNote> = getPlayerStrums();
		var playerCharacter:Character = getPlayerCharacter();
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrumGroup.length || !generatedMusic || endingSong || (playerCharacter != null && playerCharacter.stunned)) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && isPlayerNote(n) && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			if (ClientPrefs.data.ghostTapping)
				callOnScripts('onGhostTap', [key]);
			else
				noteMissPress(key);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrumGroup.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.animation != null && spr.animation.curAnim != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		var playerStrumGroup:FlxTypedGroup<StrumNote> = getPlayerStrums();
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrumGroup.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrumGroup.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		var playerCharacter:Character = getPlayerCharacter();
		if (startedCountdown && !inCutscene && (playerCharacter == null || !playerCharacter.stunned) && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& isPlayerNote(n) && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && isPlayerNote(daNote) && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -[REDACTED]
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		subtractPlayerHealth(subtract * healthLoss);
		songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = getPlayerCharacter();
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var postfix:String = '';
			if(note != null) postfix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + postfix;
			char.playAnim(animToPlay, true);

			if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		getPlayerVocals().volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		if (songName != 'tutorial')
			camZooming = true;

		var opponentCharacter:Character = getOpponentCharacter();
		if(note.noteType == 'Hey!' && opponentCharacter != null && opponentCharacter.hasAnimation('hey'))
		{
			opponentCharacter.playAnim('hey', true);
			opponentCharacter.specialAnim = true;
			opponentCharacter.heyTimer = 0.6;
		}
		else if(!note.noAnimation)
		{
			var char:Character = getOpponentCharacter();
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;
			if(note.gfNote) char = gf;

			if(char != null)
			{
				var canPlay:Bool = true;
				if(note.isSustainNote)
				{
					var holdAnim:String = animToPlay + '-hold';
					if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
					if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
				}

				if(canPlay) char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		getOpponentVocals().volume = 1;
		strumPlayAnim(!note.mustPress, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		if(note.isSustainNote)
			spawnHoldNoteCoverOnNote(note);
		note.hitByOpponent = true;
		
		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		note.wasGoodHit = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;

				var char:Character = getPlayerCharacter();
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}

				if(char != null)
				{
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}
	
					if(canPlay) char.playAnim(animToPlay, true);
					char.holdTimer = 0;

					if(note.noteType == 'Hey!')
					{
						if(char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(!cpuControlled)
			{
				var spr = getPlayerStrums().members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(!note.mustPress, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			if(note.isSustainNote)
				spawnHoldNoteCoverOnNote(note);
			getPlayerVocals().volume = 1;

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
			if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
			if (gainHealth) addPlayerHealth(note.hitHealth * healthGain);

		}
		else //Notes that count as a miss if you hit them (Hurt notes for example)
		{
			if(!note.noMissAnimation)
			{
				switch(note.noteType)
				{
					case 'Hurt Note':
						var char:Character = getPlayerCharacter();
						if(char != null && char.hasAnimation('hurt'))
						{
							char.playAnim('hurt', true);
							char.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		}

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = getPlayerStrums().members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	public function spawnHoldNoteCoverOnNote(note:Note) {
		if(note == null || !note.isSustainNote) return;

		var strumGroup:FlxTypedGroup<StrumNote> = isPlayerNote(note) ? getPlayerStrums() : getOpponentStrums();
		var strum:StrumNote = strumGroup.members[note.noteData];
		if(strum == null) return;

		var phase:String = 'hold';
		if(note.parent != null && note.parent.tail != null)
		{
			var index:Int = note.parent.tail.indexOf(note);
			if(index <= 0) phase = 'start';
			else if(index >= note.parent.tail.length - 1) phase = 'end';
		}

		var cover:HoldNoteCover = null;
		for(member in grpHoldNoteCovers.members)
		{
			if(member != null && member.exists && member.babyArrow == strum)
			{
				cover = member;
				break;
			}
		}
		if(cover == null)
			cover = grpHoldNoteCovers.recycle(HoldNoteCover);
		cover.spawnCover(strum, note, phase, Conductor.stepCrochet * 0.001 / playbackRate);
		if(cover.exists && !grpHoldNoteCovers.members.contains(cover))
			grpHoldNoteCovers.add(cover);
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.spawnSplashNote(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (funkin.modding.scripting.psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLuaProgramming.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);

		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		try { EnginePerformance.onExitSong(); } catch(e:Dynamic) {}
		instance = null;
		super.destroy();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
	}

	public function playerDance():Void
	{
		var playerCharacter:Character = getPlayerCharacter();
		if(playerCharacter == null) return;

		var anim:String = playerCharacter.getAnimationName();
		if(playerCharacter.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * playerCharacter.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			playerCharacter.dance();
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('chartMustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection == playsAsBF());
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(!script.closed && script.scriptName == luaToLoad) return false;

			new FunkinLuaProgramming(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	function startWeekScripts()
	{
		var weekFileName:String = WeekData.getWeekFileName();
		if(weekFileName == null || weekFileName.length < 1) return;

		var scriptBase:String = 'scripts/weeks/$weekFileName';
		#if LUA_ALLOWED
		startLuasNamed('$scriptBase.lua');
		#end
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('$scriptBase.hx');
		startHScriptsNamed('$scriptBase.hxc');
		#end
	}

	#if HSCRIPT_ALLOWED
	public function startModchartNamed(scriptBase:String)
	{
		if(!ClientPrefs.data.modcharts) return;
		if(SONG != null && SONG.useModcharts == false) return;

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('$scriptBase.hx');
		startHScriptsNamed('$scriptBase.hxc');
		#end
		startModchartXmlNamed('$scriptBase.xml');
	}

	public function startModchartXmlNamed(scriptFile:String):Bool
	{
		if(!ClientPrefs.data.modcharts) return false;
		if(SONG != null && SONG.useModcharts == false) return false;

		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if(modchartXmlPaths.contains(scriptToLoad)) return false;
			try
			{
				var xml:Xml = Xml.parse(File.getContent(scriptToLoad));
				modchartXmls.push(xml);
				modchartXmlPaths.push(scriptToLoad);
				trace('initialized modchart xml successfully: $scriptToLoad');
				return true;
			}
			catch(e:Dynamic)
			{
				trace('failed to initialize modchart xml: $scriptToLoad - $e');
			}
		}
		return false;
	}

	function callOnModchartXmlPushed(event:EventNote)
	{
		if(!ClientPrefs.data.modcharts) return;
		if(SONG != null && SONG.useModcharts == false) return;
		if(modchartXmls.length < 1) return;

		for (xml in modchartXmls)
		{
			var root:Xml = firstModchartXmlElement(xml);
			if(root == null) continue;

			for (node in root.elements())
			{
				if(node.nodeName != 'onModChartPushed' && node.nodeName != 'event') continue;
				var eventName:String = modchartXmlAttr(node, 'name', '*');
				if(eventName != '*' && eventName != event.event) continue;

				for (action in node.elements())
					runModchartXmlAction(action, event);
			}
		}
	}

	function runModchartXmlAction(action:Xml, event:EventNote)
	{
		switch(action.nodeName)
		{
			case 'precacheSound':
				var path:String = modchartXmlValue(action, event, 'path', '');
				if(path.length > 0) Paths.sound(path);

			case 'precacheImage':
				var path:String = modchartXmlValue(action, event, 'path', '');
				if(path.length > 0) Paths.image(path);

			case 'trace':
				trace(modchartXmlValue(action, event, 'text', ''));
		}
	}

	function firstModchartXmlElement(xml:Xml):Xml
	{
		if(xml.nodeType == Xml.Element) return xml;
		if(xml.nodeType != Xml.Document) return null;

		for (child in xml)
		{
			var found:Xml = firstModchartXmlElement(child);
			if(found != null) return found;
		}
		return null;
	}

	function modchartXmlAttr(xml:Xml, name:String, fallback:String):String
		return xml.exists(name) ? xml.get(name) : fallback;

	function modchartXmlValue(xml:Xml, event:EventNote, attr:String, fallback:String):String
	{
		var value:String = modchartXmlAttr(xml, attr, fallback);
		if(value == 'name' || value == '$' + 'name') return event.event;
		if(value == 'value1' || value == '$' + 'value1') return event.value1 != null ? event.value1 : '';
		if(value == 'value2' || value == '$' + 'value2') return event.value2 != null ? event.value2 : '';
		if(value == 'strumTime' || value == '$' + 'strumTime') return Std.string(event.strumTime);
		return value;
	}

	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function startScriptsInFolder(scriptFolder:String)
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), scriptFolder))
		{
			if(folder == null || !FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;
			for (file in FileSystem.readDirectory(folder))
			{
				var path:String = folder;
				if(!path.endsWith('/') && !path.endsWith('\\')) path += '/';
				path += file;
				if(FileSystem.isDirectory(path)) continue;

				var lower:String = file.toLowerCase();
				#if LUA_ALLOWED
				if(lower.endsWith('.lua'))
					startLuasNamed(scriptFolder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(isHScriptFile(file) && !Iris.instances.exists(path))
					initHScript(path);
				#end
			}
		}
		#end
	}

	inline function isHScriptFile(file:String):Bool
	{
		var lower:String = file.toLowerCase();
		return lower.endsWith('.hx') || lower.endsWith('.hxc');
	}

	function startStateScriptsInFolder(folder:String)
	{
		if(folder == null || !FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) return;

		for (file in FileSystem.readDirectory(folder))
		{
			var path:String = folder;
			if(!path.endsWith('/') && !path.endsWith('\\')) path += '/';
			path += file;

			if(FileSystem.isDirectory(path))
			{
				// notestyle: loaded per-style later; mods: modSettings only (not PlayState scripts)
				var dirName:String = file.toLowerCase();
				if(dirName == 'notestyle' || dirName == 'mods')
					continue;
				startStateScriptsInFolder(path);
				continue;
			}

			var lower:String = file.toLowerCase();
			#if LUA_ALLOWED
			if(lower.endsWith('.lua'))
			{
				var rel:String = StringTools.replace(path, '\\', '/');
				var idx:Int = rel.indexOf('scripts/states/');
				if(idx >= 0) rel = rel.substr(idx);
				else rel = 'scripts/states/' + file;
				startLuasNamed(rel);
			}
			#end

			#if HSCRIPT_ALLOWED
			if(isHScriptFile(file) && !Iris.instances.exists(path))
				initHScript(path);
			#end
		}
	}

	public function initHScript(file:String)
	{
		var newScript:FunkinHSProgramming = null;
		try
		{
			newScript = new FunkinHSProgramming(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:FunkinHSProgramming = cast (Iris.instances.get(file), FunkinHSProgramming);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLuaProgramming> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = 'N/A';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true)
	{
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = 'N/A';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Accuracy (0.0 - 1.0)
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

				// Rank from Accuracy (letter only, no FC)
				ratingName = Rank.applyToPlayState(ratingPercent, songMisses);
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			var weekFileName:String = WeekData.getWeekFileName();
			if(name == weekFileName + '-beat')
			{
				unlock = isStoryMode && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice;
			}
			else if(name == weekFileName + '_nomiss')
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}
			else // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.isLowQuality && !ClientPrefs.data.antialiasing);

					#if BASE_GAME_FILES
					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
					#end
				}
			}
			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		#if (!flash && sys)
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
}
