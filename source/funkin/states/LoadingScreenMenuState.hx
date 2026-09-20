package funkin.states;

import funkin.play.Song;
import funkin.play.SongMeta;
import funkin.stages.StageData;
import funkin.data.objects.game.characters.Character;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.NoteSplash;

import haxe.Json;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.FlxState;
import flash.media.Sound;

import sys.thread.Thread;
import sys.thread.Mutex;
import sys.thread.FixedThreadPool;

import lime.utils.Assets;
import lime.app.Future;

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.FunkinHSProgramming;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

#if cpp
@:headerCode('
#include <iostream>
#include <thread>')
#end

class LoadingScreenMenuState extends MusicBeatState
{
	public static var loaded:Int = 0;
	public static var loadMax:Int = 0;

	static var originalBitmapKeys:Map<String, String> = [];
	static var requestedBitmaps:Map<String, BitmapData> = [];
	static var mutex:Mutex;
	static var threadPool:FixedThreadPool = null;

	function new(target:FlxState, stopMusic:Bool)
	{
		this.target = target;
		this.stopMusic = stopMusic;
		
		super();
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
		MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));
	
	var target:FlxState = null;
	var stopMusic:Bool = false;
	var dontUpdate:Bool = false;

	var barGroup:FlxSpriteGroup;
	var bar:FlxSprite;
	var barWidth:Int = 0;
	var intendedPercent:Float = 0;
	var curPercent:Float = 0;
	var stateChangeDelay:Float = 0;
	var funkay:FlxSprite;
	var rareFunkayLoading:Bool = false;

	#if PSYCH_WATERMARKS
	var logoKey:FlxSprite;
	var pessy:FlxSprite;
	var loadingText:FlxText;

	var timePassed:Float;
	var shakeFl:Float;
	var shakeMult:Float = 0;
	
	var isSpinning:Bool = false;
	var spawnedPessy:Bool = false;
	var pressedTimes:Int = 0;
	#end

	#if !html5
	var pool = new sys.thread.FixedThreadPool(4);
	#end

	#if HSCRIPT_ALLOWED
	var hscript:FunkinHSProgramming;
	#end
	override function create()
	{
		persistentUpdate = true;
		barGroup = new FlxSpriteGroup();
		add(barGroup);

		var barBack:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
		barBack.scale.set(FlxG.width - 300, 25);
		barBack.updateHitbox();
		barBack.screenCenter(X);
		barGroup.add(barBack);

		bar = new FlxSprite(barBack.x + 5, barBack.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(0, 15);
		bar.updateHitbox();
		barGroup.add(bar);
		barWidth = Std.int(barBack.width - 10);

		#if HSCRIPT_ALLOWED
		// scripts/states/loadingScreen/*.hx (shared + mods) — no mod required
		var loadingScriptLoaded:Bool = false;
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/loadingScreen/'))
		{
			if(folder == null || !FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;
			for (file in FileSystem.readDirectory(folder))
			{
				var lower:String = file.toLowerCase();
				if(!(lower.endsWith('.hx') || lower.endsWith('.hxc'))) continue;
				var scriptPath:String = folder;
				if(!scriptPath.endsWith('/') && !scriptPath.endsWith('\\')) scriptPath += '/';
				scriptPath += file;
				if(FileSystem.isDirectory(scriptPath)) continue;
				try
				{
					hscript = new FunkinHSProgramming(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);
					if(hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('initialized hscript interp successfully: $scriptPath');
						loadingScriptLoaded = true;
						return super.create();
					}
					else
					{
						trace('"$scriptPath" contains no "onCreate" function, stopping script.');
					}
				}
				catch(e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
				}
				if(hscript != null) hscript.destroy();
				hscript = null;
			}
			if(loadingScriptLoaded) break;
		}
		// Legacy fallback: mods/<mod>/scripts/LoadingScreen.hx
		if(!loadingScriptLoaded && Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/scripts/LoadingScreen.hx';
			if(FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new FunkinHSProgramming(null, scriptPath);
					hscript.set('getLoaded', function() return loaded);
					hscript.set('getLoadMax', function() return loadMax);
					hscript.set('barBack', barBack);
					hscript.set('bar', bar);
					if(hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('initialized hscript interp successfully: $scriptPath');
						return super.create();
					}
				}
				catch(e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
				}
				if(hscript != null) hscript.destroy();
				hscript = null;
			}
		}
		#end

		rareFunkayLoading = FlxG.random.int(1, 100000) == 1;
		if(rareFunkayLoading)
		{
			var bg = new FlxSprite().makeGraphic(1, 1, 0xFF4A008C);
			bg.scale.set(FlxG.width, FlxG.height);
			bg.updateHitbox();
			bg.screenCenter();
			addBehindBar(bg);

			funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
			funkay.antialiasing = ClientPrefs.data.antialiasing;
			funkay.setGraphicSize(0, FlxG.height);
			funkay.updateHitbox();
			funkay.screenCenter();
			addBehindBar(funkay);
			FlxG.camera.fade(0xFF8A2BE2, 0.6, true);

			#if PSYCH_WATERMARKS
			loadingText = new FlxText(520, 600, 400, Language.getPhrase('now_loading', ' Loading Song', ['...']), 32);
			loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			loadingText.borderSize = 2;
			addBehindBar(loadingText);
			#end
		}
		else
		{
			#if PSYCH_WATERMARKS // PSYCH LOADING SCREEN
			var bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
			bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.setGraphicSize(Std.int(FlxG.width));
			bg.color = 0xFFD16FFF;
			bg.updateHitbox();
			addBehindBar(bg);
		
			loadingText = new FlxText(520, 600, 400, Language.getPhrase('now_loading', ' Loading', ['...']), 32);
			loadingText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			loadingText.borderSize = 2;
			addBehindBar(loadingText);
		
			logoKey = new FlxSprite(0, 0).loadGraphic(Paths.image('loading/icon'));
			logoKey.antialiasing = ClientPrefs.data.antialiasing;
			logoKey.scale.set(0.75, 0.75);
			logoKey.updateHitbox();
			logoKey.screenCenter();
			logoKey.x -= 50;
			logoKey.y -= 40;
			addBehindBar(logoKey);

			#else // BASE GAME LOADING SCREEN
			var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
			bg.scale.set(FlxG.width, FlxG.height);
			bg.updateHitbox();
			bg.screenCenter();
			addBehindBar(bg);

			funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
			funkay.antialiasing = ClientPrefs.data.antialiasing;
			funkay.setGraphicSize(0, FlxG.height);
			funkay.updateHitbox();
			addBehindBar(funkay);
			#end
		}
		super.create();

		if (stateChangeDelay <= 0 && checkLoaded())
		{
			dontUpdate = true;
			onLoad();
		}
	}

	function addBehindBar(obj:flixel.FlxBasic)
	{
		insert(members.indexOf(barGroup), obj);
	}

	var transitioning:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (dontUpdate) return;

		if (!transitioning)
		{
			if (!finishedLoading && checkLoaded())
			{
				if(stateChangeDelay <= 0)
				{
					transitioning = true;
					onLoad();
					return;
				}
				else stateChangeDelay = Math.max(0, stateChangeDelay - elapsed);
			}
			intendedPercent = loaded / loadMax;
		}

		if (curPercent != intendedPercent)
		{
			if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
			else curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

			bar.scale.x = barWidth * curPercent;
			bar.updateHitbox();
		}
		
		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			if(hscript.exists('onUpdate')) hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end

		// PSYCH LOADING SCREEN
		#if PSYCH_WATERMARKS
		timePassed += elapsed;
		shakeFl += elapsed * 3000;
		var dots:String = '';
		switch(Math.floor(timePassed % 1 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		loadingText.text = Language.getPhrase('now_loading', 'Loading Song {1}', [dots]);

		if(rareFunkayLoading) return;

		if(!spawnedPessy)
		{
			if(!transitioning && controls.ACCEPT)
			{
				shakeMult = 1;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				pressedTimes++;
			}
			shakeMult = Math.max(0, shakeMult - elapsed * 5);
			logoKey.offset.x = Math.sin(shakeFl * Math.PI / 180) * shakeMult * 100;

			if(pressedTimes >= 5)
			{
				FlxG.camera.fade(0xAAFFFFFF, 0.5, true);
				logoKey.visible = false;
				spawnedPessy = true;
				stateChangeDelay = 5;
				FlxG.sound.play(Paths.sound('secret'));

				pessy = new FlxSprite(700, 140);
				pessy.frames = Paths.getSparrowAtlas('loading/pessy');
				pessy.animation.addByPrefix('run', 'run', 24, true);
				pessy.animation.addByPrefix('spin', 'spin', 24, true);
				pessy.antialiasing = ClientPrefs.data.antialiasing;
				pessy.flipX = (logoKey.offset.x > 0);
				pessy.visible = false;

				new FlxTimer().start(0.01, function(tmr:FlxTimer) {
					pessy.x = FlxG.width + 200;
					pessy.velocity.x = -1100;
					if(pessy.flipX)
					{
						pessy.x = -pessy.width - 200;
						pessy.velocity.x *= -1;
					}
		
					pessy.visible = true;
					pessy.animation.play('run', true);
					#if ACHIEVEMENTS_ALLOWED Achievements.unlock('pessy_easter_egg'); #end
					
					insert(members.indexOf(loadingText), pessy);
				});
			}
		}
		else if(!isSpinning && (pessy.flipX && pessy.x > FlxG.width) || (!pessy.flipX && pessy.x < -pessy.width))
		{
			isSpinning = true;
			pessy.animation.play('spin', true);
			pessy.flipX = false;
			pessy.x = 500;
			pessy.y = FlxG.height + 500;
			pessy.velocity.x = 0;
			FlxTween.tween(pessy, {y: 10}, 0.65, {ease: FlxEase.quadOut});
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	override function destroy()
	{
		if(hscript != null)
		{
			if(hscript.exists('onDestroy')) hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		super.destroy();
	}
	#end
	
	var finishedLoading:Bool = false;
	function onLoad()
	{
		_loaded();

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.camera.visible = false;
		MusicBeatState.switchState(target);
		transitioning = true;
		finishedLoading = true;
	}

	static function _loaded()
	{
		loaded = 0;
		loadMax = 0;
		initialThreadCompleted = true;
		isIntrusive = false;

		FlxTransitionableState.skipNextTransIn = true;
		if (threadPool != null) threadPool.shutdown(); // kill all workers safely
		threadPool = null;
		mutex = null;
	}

	public static function checkLoaded():Bool
	{
		for (key => bitmap in requestedBitmaps)
		{
			if (bitmap != null && Paths.cacheBitmap(originalBitmapKeys.get(key), bitmap) != null) {} //trace('finished preloading image $key');
			else trace('failed to cache image $key');
		}
		requestedBitmaps.clear();
		originalBitmapKeys.clear();
		// trace('we checked if loaded');
		return (loaded >= loadMax && initialThreadCompleted);
	}

	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	static var isIntrusive:Bool = false;
	static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
	{
		#if !SHOW_LOADING_SCREEN
		intrusive = false;
		#end

		LoadingScreenState.isIntrusive = intrusive;
		_startPool();
		loadNextDirectory();

		if(intrusive)
			return new LoadingScreenState(target, stopMusic);
		
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		while(true)
		{
			if(checkLoaded())
			{
				_loaded();
				break;
			}
			else Sys.sleep(0.001);
		}
		return target;
	}

	static var imagesToPrepare:Array<String> = [];
	static var soundsToPrepare:Array<String> = [];
	static var musicToPrepare:Array<String> = [];
	static var songsToPrepare:Array<String> = [];
	public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
	{
		if (images != null) imagesToPrepare = imagesToPrepare.concat(images);
		if (sounds != null) soundsToPrepare = soundsToPrepare.concat(sounds);
		if (music != null) musicToPrepare = musicToPrepare.concat(music);
	}

	static var initialThreadCompleted:Bool = true;
	static var dontPreloadDefaultVoices:Bool = false;
	static function _startPool()
	{
		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		#else
		var threadCount:Int = 1;
		#end
		threadPool = new FixedThreadPool(threadCount);
	}

	public static function prepareToSong()
	{
		if(PlayState.SONG == null)
		{
			imagesToPrepare = [];
			soundsToPrepare = [];
			musicToPrepare = [];
			songsToPrepare = [];
			loaded = 0;
			loadMax = 0;
			initialThreadCompleted = true;
			isIntrusive = false;
			return;
		}

		_startPool();
		imagesToPrepare = [];
		soundsToPrepare = [];
		musicToPrepare = [];
		songsToPrepare = [];

		// ===== Meta + new song layout support =====
		try
		{
			var metaFolder:String = Paths.formatToSongPath(
				(Song.loadedSongName != null && Song.loadedSongName.length > 0)
					? Song.loadedSongName
					: (PlayState.SONG.song != null ? PlayState.SONG.song : '')
			);
			var variationKey:String = null;
			try
			{
				if(PlayState.SONG.songVariation != null && Std.string(PlayState.SONG.songVariation).trim().length > 0)
					variationKey = Std.string(PlayState.SONG.songVariation).trim();
				else if(PlayState.SONG.variation != null && Std.string(PlayState.SONG.variation).trim().length > 0)
					variationKey = Std.string(PlayState.SONG.variation).trim();
			}
			catch(e:Dynamic) {}

			var isExtra:Bool = false;
			try
			{
				if(Reflect.field(PlayState.SONG, 'extraFreeplay') == true)
					isExtra = true;
			}
			catch(e:Dynamic) {}

			var meta = SongMeta.load(metaFolder, null, isExtra, variationKey);
			if(meta != null)
			{
				SongMeta.applyToSong(PlayState.SONG, meta, false);
				trace('[LoadingScreen] Meta applied: ' + meta.loadedPath + (variationKey != null ? ' (var=' + variationKey + ')' : ''));
			}
			Paths.applyAudioSuffixesFromSong(PlayState.SONG);
		}
		catch(e:Dynamic)
		{
			trace('[LoadingScreen] Meta integrate failed: ' + e);
			try Paths.clearAudioSuffixes() catch(e2:Dynamic) {}
		}

		initialThreadCompleted = false;
		var threadsCompleted:Int = 0;
		var threadsMax:Int = 0;
		function completedThread()
		{
			threadsCompleted++;
			if(threadsCompleted == threadsMax)
			{
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
		}

		var song:SwagSong = PlayState.SONG;
		var folder:String = Paths.formatToSongPath(Song.loadedSongName != null && Song.loadedSongName.length > 0
			? Song.loadedSongName
			: (song.song != null ? song.song : ''));

		new Future<Bool>(() -> {
			// LOAD NOTE IMAGE (noteStyle from meta/chart)
			var addPreloadNoteAsset = function(asset:String)
			{
				if(asset != null && asset.length > 0 && !imagesToPrepare.contains(asset))
					imagesToPrepare.push(asset);
			}

			var noteSkin:String = Note.defaultSongNoteStyle();
			var songNoteStyle:String = Note.songNoteStyle();
			if(songNoteStyle != null && songNoteStyle.length > 1) noteSkin = songNoteStyle;

			var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
			if(Paths.fileExists('images/$customSkin.json', TEXT) || Paths.fileExists('images/$customSkin.png', IMAGE))
				noteSkin = customSkin;

			var noteSkinConfig = Note.getNoteSkinConfig(noteSkin);
			addPreloadNoteAsset(Note.resolveNoteSkinAsset(noteSkin, noteSkinConfig, PlayState.isPixelStage ? 'notePixel' : 'note'));
			addPreloadNoteAsset(Note.resolveNoteSkinAsset(noteSkin, noteSkinConfig, PlayState.isPixelStage ? 'holdNotePixel' : 'holdNote'));
			addPreloadNoteAsset(Note.resolveNoteSkinAsset(noteSkin, noteSkinConfig, PlayState.isPixelStage ? 'noteStrumlinePixel' : 'noteStrumline'));

			// LOAD NOTE SPLASH IMAGE
			if(PlayState.SONG != null && (PlayState.SONG.stage == 'philly_remix' || PlayState.SONG.stage == 'philly-remix'))
			{
				if(PlayState.SONG.noteStyle == null || PlayState.SONG.noteStyle.trim().length < 1)
					PlayState.SONG.noteStyle = 'godot';
			}

			var noteSplash:String = NoteSplash.defaultNoteSplash;
			var songSplash:String = Note.songSplashSkinForMustPress(true);
			if(songSplash != null && songSplash.length > 0) noteSplash = songSplash;
			else noteSplash += NoteSplash.getSplashSkinPostfix();
			imagesToPrepare.push(noteSplash);

			// Preload script: scripts/songs/<folder>/preload.json (not chart path)
			try
			{
				var preloadKey:String = 'scripts/songs/' + folder + '/preload.json';
				var preloadPath:String = Paths.getPath(preloadKey, TEXT, null, true);
				var json:Dynamic = null;
				#if MODS_ALLOWED
				if(FileSystem.exists(preloadPath))
					json = Json.parse(File.getContent(preloadPath));
				else if(OpenFlAssets.exists(preloadPath, TEXT))
					json = Json.parse(OpenFlAssets.getText(preloadPath));
				#else
				if(OpenFlAssets.exists(preloadPath, TEXT))
					json = Json.parse(OpenFlAssets.getText(preloadPath));
				#end

				if(json != null)
				{
					var imgs:Array<String> = [];
					var snds:Array<String> = [];
					var mscs:Array<String> = [];
					for (asset in Reflect.fields(json))
					{
						var filters:Int = Reflect.field(json, asset);
						var assetName:String = asset.trim();
						if(filters < 0 || StageData.validateVisibility(filters))
						{
							if(assetName.startsWith('images/'))
								imgs.push(assetName.substr('images/'.length));
							else if(assetName.startsWith('sounds/'))
								snds.push(assetName.substr('sounds/'.length));
							else if(assetName.startsWith('music/'))
								mscs.push(assetName.substr('music/'.length));
						}
					}
					prepare(imgs, snds, mscs);
				}
			}
			catch(e:Dynamic) {}
			return true;
		}, isIntrusive)
		.then((_) -> new Future<Bool>(() -> {
			if (song.stage == null || song.stage.length < 1)
				song.stage = StageData.vanillaSongStage(folder);

			var stageData:StageFile = StageData.getStageFile(song.stage);
			if (stageData != null)
			{
				var imgs:Array<String> = [];
				var snds:Array<String> = [];
				var mscs:Array<String> = [];
				if(stageData.preload != null)
				{
					for (asset in Reflect.fields(stageData.preload))
					{
						var filters:Int = Reflect.field(stageData.preload, asset);
						var assetName:String = asset.trim();
						if(filters < 0 || StageData.validateVisibility(filters))
						{
							if(assetName.startsWith('images/'))
								imgs.push(assetName.substr('images/'.length));
							else if(assetName.startsWith('sounds/'))
								snds.push(assetName.substr('sounds/'.length));
							else if(assetName.startsWith('music/'))
								mscs.push(assetName.substr('music/'.length));
						}
					}
				}

				if (stageData.objects != null)
				{
					for (sprite in stageData.objects)
					{
						if(sprite.type == 'sprite' || sprite.type == 'animatedSprite')
							if((sprite.filters < 0 || StageData.validateVisibility(sprite.filters)) && !imgs.contains(sprite.image))
								imgs.push(sprite.image);
					}
				}
				prepare(imgs, snds, mscs);
			}
			else stageData = StageData.dummy();

			// ===== Audio: new layout assets/songs/<folder>/song/Inst[.suffix].ogg =====
			var audioLibrary:String = (Paths.songAudioRoot != null && Paths.songAudioRoot.length > 0)
				? Paths.songAudioRoot
				: 'songs';

			function pushSongAudio(relNoExt:String):Void
			{
				if(relNoExt == null || relNoExt.length < 1) return;
				if(!songsToPrepare.contains(relNoExt))
					songsToPrepare.push(relNoExt);
			}

			function audioExists(relNoExt:String):Bool
			{
				var full:String = relNoExt + '.' + Paths.SOUND_EXT;
				#if sys
				var disk:String = Paths.getPath(full, SOUND, audioLibrary, true);
				if(FileSystem.exists(disk)) return true;
				#end
				try return Paths.fileExists(full, SOUND, false, audioLibrary) catch(e:Dynamic) return false;
			}

			// Inst (+ meta instSuffix already applied via Paths.instSuffix)
			var instSuf:String = Paths.instSuffix; // "-pico" or null
			if(instSuf != null && instSuf.length > 0)
			{
				if(audioExists(folder + '/song/Inst' + instSuf))
					pushSongAudio(folder + '/song/Inst' + instSuf);
				else if(audioExists(folder + '/Inst' + instSuf))
					pushSongAudio(folder + '/Inst' + instSuf);
			}
			if(audioExists(folder + '/song/Inst'))
				pushSongAudio(folder + '/song/Inst');
			else
				pushSongAudio(folder + '/Inst'); // legacy fallback always listed; clearInvalid removes missing

			// SwagSong (Pico): player / opponent / girlfriend — legacy player1/player2/gfVersion via Reflect
			var player:String = resolveSongChar(song, ['player', 'player1'], 'bf');
			var opponent:String = resolveSongChar(song, ['opponent', 'player2'], 'dad');
			var girlfriend:String = resolveSongChar(song, ['girlfriend', 'gfVersion', 'gf'], 'gf');
			var needsVoices:Bool = song.needsVoices;

			dontPreloadDefaultVoices = false;
			var prefixNested:String = folder + '/song/Voices';
			var prefixLegacy:String = folder + '/Voices';

			function tryVoiceKeys(suffix:String):Void
			{
				if(suffix == null) suffix = '';
				if(audioExists(prefixNested + suffix))
					pushSongAudio(prefixNested + suffix);
				else if(audioExists(prefixLegacy + suffix))
					pushSongAudio(prefixLegacy + suffix);
			}

			if(needsVoices)
			{
				var vp:String = Paths.vocalPlayerSuffix;
				var vo:String = Paths.vocalOpponentSuffix;
				var vs:String = Paths.vocalsSuffix;

				if(vp != null && vp.length > 0) tryVoiceKeys(vp);
				if(vo != null && vo.length > 0) tryVoiceKeys(vo);
				if(vs != null && vs.length > 0) tryVoiceKeys(vs);

				// Classic Player/Opponent split
				if(audioExists(prefixNested + '-Player') && audioExists(prefixNested + '-Opponent'))
				{
					pushSongAudio(prefixNested + '-Player');
					pushSongAudio(prefixNested + '-Opponent');
				}
				else if(audioExists(prefixLegacy + '-Player') && audioExists(prefixLegacy + '-Opponent'))
				{
					pushSongAudio(prefixLegacy + '-Player');
					pushSongAudio(prefixLegacy + '-Opponent');
				}
				else
				{
					tryVoiceKeys('');
				}
			}

			// pauseSong music preload (from meta/chart)
			try
			{
				var pauseKey:String = song.pauseSong;
				if(pauseKey != null && pauseKey.trim().length > 0)
				{
					var pk:String = pauseKey.trim();
					if(pk.startsWith('music/')) pk = pk.substr(6);
					if(!musicToPrepare.contains(pk))
						musicToPrepare.push(pk);
				}
			}
			catch(e:Dynamic) {}

			preloadCharacter(player, needsVoices ? (audioExists(prefixNested) ? prefixNested : prefixLegacy) : null);
			if (opponent != player)
			{
				threadsMax++;
				threadPool.run(() -> {
					try { preloadCharacter(opponent, needsVoices ? (audioExists(prefixNested) ? prefixNested : prefixLegacy) : null); } catch (e:Dynamic) {}
					completedThread();
				});
			}

			if (stageData != null && !stageData.hide_girlfriend && girlfriend != opponent && girlfriend != player)
			{
				threadsMax++;
				threadPool.run(() -> {
					try { preloadCharacter(girlfriend); } catch (e:Dynamic) {}
					completedThread();
				});
			}

			if(threadsCompleted == threadsMax)
			{
				clearInvalids();
				startThreads();
				initialThreadCompleted = true;
			}
			return true;
		}, isIntrusive))
		.onError((err:Dynamic) -> {
			trace('ERROR! while preparing song: $err');
		});
	}

	public static function clearInvalids()
	{
		clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
		clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(musicToPrepare, 'music', '.${Paths.SOUND_EXT}', SOUND);
		clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

		for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
			while (arr.contains(null))
				arr.remove(null);
	}

	static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentFolder:String = null)
	{
		for (folder in arr.copy())
		{
			var nam:String = folder.trim();
			if(nam.endsWith('/'))
			{
				for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$nam'))
				{
					for (file in FileSystem.readDirectory(subfolder))
					{
						if(file.endsWith(ext))
						{
							var toAdd:String = nam + haxe.io.Path.withoutExtension(file);
							if(!arr.contains(toAdd)) arr.push(toAdd);
						}
					}
				}

				//trace('Folder detected! ' + folder);
			}
		}

		var i:Int = 0;
		while(i < arr.length)
		{

			var member:String = arr[i];
			var myKey = '$prefix/$member$ext';
			if(parentFolder == 'songs') myKey = '$member$ext';

			//trace('attempting on $prefix: $myKey');
			var doTrace:Bool = false;
			if(member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentFolder) && (doTrace = true)))
			{
				arr.remove(member);
				if(doTrace) trace('Removed invalid $prefix: $member');
			}
			else i++;
		}
	}

	public static function startThreads()
	{
		mutex = new Mutex();
		loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
		loaded = 0;

		//then start threads
		_threadFunc();
	}

	static function _threadFunc()
	{
		_startPool();
		for (sound in soundsToPrepare) initThread(() -> preloadSound('sounds/$sound'), 'sound $sound');
		for (music in musicToPrepare) initThread(() -> preloadSound('music/$music'), 'music $music');
		for (song in songsToPrepare) initThread(() -> preloadSound(song, 'songs', true, false), 'song $song');

		// for images, they get to have their own thread
		for (image in imagesToPrepare) initThread(() -> preloadGraphic(image), 'image $image');
	}

	static function initThread(func:Void->Dynamic, traceData:String)
	{
		// trace('scheduled $func in threadPool');
		#if debug
		var threadSchedule = Sys.time();
		#end
		threadPool.run(() -> {
			#if debug
			var threadStart = Sys.time();
			trace('$traceData took ${threadStart - threadSchedule}s to start preloading');
			#end

			try {
				if (func() != null) {
					#if debug
					var diff = Sys.time() - threadStart;
					trace('finished preloading $traceData in ${diff}s');
					#end
				} else trace('ERROR! fail on preloading $traceData ');
			}
			catch(e:Dynamic) {
				trace('ERROR! fail on preloading $traceData: $e');
			}
			// mutex.acquire();
			loaded++;
			// mutex.release();
		});
	}


	/** Read char id from SwagSong whether it uses player/opponent/girlfriend or player1/player2/gfVersion. */
	static function resolveSongChar(song:Dynamic, names:Array<String>, fallback:String):String
	{
		if(song == null) return fallback;
		for (n in names)
		{
			try
			{
				var v:Dynamic = Reflect.field(song, n);
				if(v != null)
				{
					var s:String = Std.string(v).trim();
					if(s.length > 0 && s.toLowerCase() != 'null')
						return s;
				}
			}
			catch(e:Dynamic) {}
		}
		return fallback;
	}

	inline private static function preloadCharacter(char:String, ?prefixVocals:String)
	{
		try
		{
			var path:String = Paths.getPath('data/characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end

			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if(!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					imagesToPrepare.push(file.trim());
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if(i == 0) st = '';
	
					if(Paths.fileExists('images/$img/spritemap$st.png', IMAGE))
					{
						//trace('found Sprite PNG');
						imagesToPrepare.push('$img/spritemap$st');
						break;
					}
				}
			}
			#end
	
			if (prefixVocals != null && character.vocals_file != null && character.vocals_file.length > 0)
			{
				songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
				if(char == resolveSongChar(PlayState.SONG, ['player', 'player1'], 'bf')) dontPreloadDefaultVoices = true;
			}
		}
		catch(e:haxe.Exception)
		{
			trace(e.details());
		}
	}

	// thread safe sound loader
	static function preloadSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Null<Sound>
	{
		var file:String = Paths.getPath(Language.getFileTranslation(key) + '.${Paths.SOUND_EXT}', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!Paths.currentTrackedSounds.exists(file))
		{
			if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, SOUND))
			{
				var sound:Sound = #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file, false) #end;
				mutex.acquire();
				Paths.currentTrackedSounds.set(file, sound);
				mutex.release();
			}
			else if (beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		mutex.acquire();
		Paths.localTrackedAssets.push(file);
		mutex.release();

		return Paths.currentTrackedSounds.get(file);
	}

	// thread safe sound loader
	static function preloadGraphic(key:String):Null<BitmapData>
	{
		try {
			var requestKey:String = 'images/$key';
			#if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
			if(requestKey.lastIndexOf('.') < 0) requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey))
			{
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if sys FileSystem.exists(file) || #end OpenFlAssets.exists(file, IMAGE))
				{
					#if sys
					var bitmap:BitmapData = BitmapData.fromFile(file);
					#else
					var bitmap:BitmapData = OpenFlAssets.getBitmapData(file, false);
					#end

					mutex.acquire();
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					mutex.release();
					return bitmap;
				}
				else trace('no such image $key exists');
			}

			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		}
		catch(e:haxe.Exception)
		{
			trace('ERROR! fail on preloading image $key');
		}

		return null;
	}
	
	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
    	')
	@:noCompletion
    	public static function getCPUThreadsCount():Int
    	{
        	return -1;
    	}
    	#end
}
