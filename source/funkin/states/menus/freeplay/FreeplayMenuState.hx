package funkin.states.menus.freeplay;

import funkin.play.Highscore;
import funkin.play.SongMeta;
import funkin.play.Rank;

import funkin.data.WeekData;
import funkin.data.objects.HealthIcon;
import funkin.data.objects.MusicPlayer;

import funkin.substates.ResetScoreSubState;
import funkin.substates.GameplayChangersSubState;
import funkin.utils.engines.pico.EnginePerformance;

import flixel.math.FlxMath;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;
import haxe.Json;

class FreeplayMenuState extends MusicBeatState
{
	var selector:FlxText;
	var allowMouse:Bool = true;
	public static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();
	private static var lastDifficultyByWeek:Map<String, String> = new Map<String, String>();

	public var scoreBG:FlxSprite;
	public var scoreText:FlxText;
	public var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedMisses:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	private var iconArray:Array<HealthIcon> = [];
	public var songs:Array<FreeplaySongData> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public var bottomString:String;
	public var bottomText:FlxText;
	public static var canMove:Bool = true;
	var bottomBG:FlxSprite;
	var freeplayExtraMenu:FlxSprite;
	var player:MusicPlayer;

	var optionShit:Array<String> = [
		'Freeplay Songs',
		'Extra Songs'
	];

	var inSelectMenu:Bool = true;
	var selectCurSelected:Int = 0;
	var menuItems:FlxTypedGroup<Alphabet>;
	var titleText:Alphabet;
	var freeplayBuilt:Bool = false;

	/** Full song list before mod-directory filter (Psych Online style < ALL >) */
	var allSongs:Array<FreeplaySongData> = [];
	/**
	 * Filter entries:
	 *   ALL | BASE GAME | mod folders | CATEGORY:* (from mod_Category)
	 * Supports Pico meta_mod, Psych pack, V-Slice, Codename, Polymod.
	 */
	var modDirectoryList:Array<String> = ['ALL'];
	var curModDirectoryIndex:Int = 0;
	/** UI: < ALL > / < BASE GAME > / < Mod Name [Category] > / < CATEGORY: Gameplay > */
	var modDirectoryTxt:FlxText;
	var modDirectoryBG:FlxSprite;

	override function create()
	{
		try { EnginePerformance.flushPendingCleanup(); } catch(e:Dynamic) {}
		
		persistentUpdate = true;
		try Paths.songAudioRoot = null catch(e:Dynamic) {}
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the FreePlayer", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new funkin.states.ErrorState("NO LEVELS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new funkin.states.editors.data.WeekEditorState()),
			function() MusicBeatState.switchState(new MainMenuState())));
			return;
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		createSelectMenu();
		super.create();
	}

	function createSelectMenu():Void
	{
		inSelectMenu = true;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Freeplay Select", "Choosing An Option");
		#end

		if (titleText == null)
		{
			titleText = new Alphabet(0, 60, 'CHOOSE AN OPTION', true);
			titleText.screenCenter(X);
			add(titleText);
		}
		else
		{
			titleText.visible = true;
		}

		if (menuItems == null)
		{
			menuItems = new FlxTypedGroup<Alphabet>();
			add(menuItems);

			for (i in 0...optionShit.length)
			{
				var item:Alphabet = new Alphabet(0, 0, optionShit[i], true);
				item.isMenuItem = true;
				item.targetY = i;
				item.changeX = false;
				item.snapToPosition();
				item.screenCenter(X);
				item.y = 200 + (i * 100);
				item.ID = i;
				menuItems.add(item);
			}
		}
		else
		{
			menuItems.visible = true;
			for (item in menuItems)
				if (item != null) item.visible = true;
		}
		changeSelectItem(0, false);
	}

	function hideSelectMenu():Void
	{
		if (titleText != null) titleText.visible = false;
		if (menuItems != null)
		{
			menuItems.visible = false;
			for (item in menuItems)
				if (item != null) item.visible = false;
		}
	}

	function changeSelectItem(change:Int = 0, playSound:Bool = true):Void
	{
		if (menuItems == null || menuItems.length < 1)
			return;

		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		selectCurSelected = FlxMath.wrap(selectCurSelected + change, 0, optionShit.length - 1);

		for (i in 0...menuItems.length)
		{
			var item:Alphabet = menuItems.members[i];
			if (item == null) continue;

			item.targetY = i - selectCurSelected;
			item.alpha = (i == selectCurSelected) ? 1 : 0.6;
		}
	}

	function acceptSelectItem():Void
	{
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		switch (optionShit[selectCurSelected])
		{
			case 'Freeplay Songs':
				hideSelectMenu();
				inSelectMenu = false;
				if (!freeplayBuilt) buildFreeplaySongList();
				else showFreeplaySongList();
			case 'Extra Songs':
				#if PICO_ALLOWED
				MusicBeatState.switchState(new FreeplayExtraSongsState());
				#else
				hideSelectMenu();
				inSelectMenu = false;
				if (!freeplayBuilt) buildFreeplaySongList();
				else showFreeplaySongList();
				#end
		}
	}

	function showFreeplaySongList():Void
	{
		inSelectMenu = false;
		if (grpSongs != null) grpSongs.visible = true;
		if (scoreText != null) scoreText.visible = true;
		if (scoreBG != null) scoreBG.visible = true;
		if (diffText != null) diffText.visible = true;
		if (bottomBG != null) bottomBG.visible = true;
		if (bottomText != null) bottomText.visible = true;
		if (player != null) player.visible = true;
		if (freeplayExtraMenu != null) freeplayExtraMenu.visible = true;
		if (modDirectoryTxt != null) modDirectoryTxt.visible = true;
		if (modDirectoryBG != null) modDirectoryBG.visible = true;
		updateModDirectoryLabel();
		changeSelection(0, false);
		updateTexts();
	}

	function hideFreeplaySongList():Void
	{
		if (grpSongs != null)
		{
			grpSongs.visible = false;
			for (s in grpSongs)
				if (s != null) s.visible = s.active = false;
		}
		for (icon in iconArray)
			if (icon != null) icon.visible = icon.active = false;
		if (scoreText != null) scoreText.visible = false;
		if (scoreBG != null) scoreBG.visible = false;
		if (diffText != null) diffText.visible = false;
		if (bottomBG != null) bottomBG.visible = false;
		if (bottomText != null) bottomText.visible = false;
		if (player != null) player.visible = false;
		if (freeplayExtraMenu != null) freeplayExtraMenu.visible = false;
		if (missingText != null) missingText.visible = false;
		if (missingTextBG != null) missingTextBG.visible = false;
		if (modDirectoryTxt != null) modDirectoryTxt.visible = false;
		if (modDirectoryBG != null) modDirectoryBG.visible = false;
	}

	function buildFreeplaySongList():Void
	{
		freeplayBuilt = true;
		inSelectMenu = false;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the FreePlayer", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in WeekData.visibleStorySongs(leWeek))
			{
				// Name from week; icon/color only as fallback — meta.json overrides in FreeplaySongData
				var songName:String = WeekData.getWeekSongName(song);
				var icon:String = WeekData.getWeekSongIcon(song, 'face');
				var colors:Array<Int> = WeekData.getWeekSongColor(song, [146, 113, 253]);
				addSong(songName, i, icon, FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		// Snapshot + mod directory filter list (Psych Online < ALL > style)
		allSongs = songs.copy();
		rebuildModDirectoryList();
		applyModDirectoryFilter(false);

		if(songs.length < 1) {
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new funkin.states.ErrorState("NO SONGS ADDED FOR FREEPLAY\n\nAll Freeplay songs are hidden or no visible songs were added.\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
			function() MusicBeatState.switchState(new funkin.states.editors.data.WeekEditorState()),
			function() MusicBeatState.switchState(new MainMenuState())));
			return;
		}

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].getDisplayName(), true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = createIconItem(songs[i].songCharacter, songText);

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.borderStyle = FlxTextBorderStyle.OUTLINE;
		scoreText.borderSize = 1.25;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 92, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.visible = false; // difficulty is inside scoreText
		add(diffText);
		add(scoreText);

		// Psych Online-style mod directory indicator: < ALL >
		modDirectoryBG = new FlxSprite(20, 20).makeGraphic(1, 1, 0xFF000000);
		modDirectoryBG.alpha = 0.55;
		add(modDirectoryBG);

		modDirectoryTxt = new FlxText(26, 24, 0, '< ALL >', 28);
		modDirectoryTxt.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modDirectoryTxt.borderSize = 2;
		add(modDirectoryTxt);
		updateModDirectoryLabel();

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		freeplayExtraMenu = new FlxSprite(scoreText.x + 50, 600).loadGraphic(Paths.image('menus/freeplay_extra'), true, 360, 110);
		freeplayExtraMenu.animation.add('idle', [0]);
		freeplayExtraMenu.animation.add('hover', [1]);
		freeplayExtraMenu.scrollFactor.set();
		freeplayExtraMenu.antialiasing = true;
		freeplayExtraMenu.setGraphicSize(Std.int(freeplayExtraMenu.width * 0.8));
		freeplayExtraMenu.updateHitbox();
		add(freeplayExtraMenu);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / CTRL+LEFT/RIGHT to change Mod Directory / Press CTRL to open Gameplay Changers / Press RESET to Reset Score.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		player = new MusicPlayer(this);
		add(player);
		
		changeSelection();
		updateTexts();
	}

	function createIconItem(character:String, tracker:FlxSprite):HealthIcon
	{
		var icon:HealthIcon = new HealthIcon(character);
		icon.sprTracker = tracker;
		iconArray.push(icon);
		add(icon);
		return icon;
	}

	override function closeSubState()
	{
		if (!inSelectMenu && songs.length > 0)
			changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new FreeplaySongData(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	public var holdTime:Float = 0;
	function getFreeplaySongId(?songName:String = null):String
	{
		if(songName == null) songName = songs[curSelected].songName;
		return Paths.formatToSongPath(songName);
	}

	function getFreeplayChartName(?songName:String = null):String
	{
		var candidates:Array<String> = PlayState.getSongLoadCandidates(getFreeplaySongId(songName), null, curDifficulty, false);
		return candidates.length > 0 ? candidates[0] : getFreeplaySongId(songName);
	}

	function loadFreeplaySong(?songName:String = null):Void
	{
		var songId:String = getFreeplaySongId(songName);
		var variation:String = null;
		if(songs.length > 0 && curSelected >= 0 && curSelected < songs.length)
			variation = songs[curSelected].getCurrentVariation();

		// loadSongWithVariationFallback expects SwagSong?, not a String
		var songHint:Dynamic = null;
		var useVariation:Bool = false;
		if(variation != null && variation.length > 0)
		{
			// Minimal object so PlayState can read songVariation / variation
			songHint = { songVariation: variation, variation: variation };
			useVariation = true;
		}
		PlayState.loadSongWithVariationFallback(songId, cast songHint, curDifficulty, useVariation);
	}

	function getLoadedFreeplaySongAssetId(?songName:String = null):String
	{
		var baseId:String = songName == null ? PlayState.SONG.song : songName;
		return PlayState.getSongAssetId(baseId, PlayState.SONG, curDifficulty);
	}

	function getLoadedFreeplaySongAudioId(?songName:String = null):String
	{
		var baseId:String = songName == null ? PlayState.SONG.song : songName;
		return PlayState.getSongAudioId(baseId, PlayState.SONG, curDifficulty);
	}

	function getFreeplayPreviewSongId():String
	{
		return getLoadedFreeplaySongAssetId(songs[curSelected].songName);
	}

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (inSelectMenu)
		{
			if (controls.UI_UP_P) changeSelectItem(-1);
			if (controls.UI_DOWN_P) changeSelectItem(1);
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			if (controls.ACCEPT)
				acceptSelectItem();
			super.update(elapsed);
			return;
		}

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (freeplayExtraMenu != null && freeplayExtraMenu.visible)
		{
			if (FlxG.mouse.overlaps(freeplayExtraMenu))
			{
				freeplayExtraMenu.animation.play('hover');
				if (FlxG.mouse.justPressed && canMove)
				{
					#if PICO_ALLOWED
					MusicBeatState.switchState(new FreeplayExtraSongsState());
					#end
					FlxG.mouse.visible = false;
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
			}
			else
			{
				freeplayExtraMenu.animation.play('idle');
			}
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (player == null || !player.playingMusic)
		{
			var diffLine:String = '';
			if(Difficulty.list != null && Difficulty.list.length > 0)
			{
				var displayDiff:String = Difficulty.getString(curDifficulty);
				if(displayDiff == null) displayDiff = '';
				if(Difficulty.list.length > 1)
					diffLine = '< ' + displayDiff.toUpperCase() + ' >';
				else
					diffLine = displayDiff.toUpperCase();
			}
			// Append variation from meta when present
			if(songs.length > 0 && curSelected >= 0 && curSelected < songs.length && songs[curSelected].hasVariations())
			{
				var vName:String = songs[curSelected].getCurrentVariation();
				var vLabel:String = (vName == null || vName.length < 1) ? 'DEFAULT' : vName.toUpperCase();
				if(diffLine.length > 0) diffLine += ' | ';
				diffLine += (songs[curSelected].variations.length > 1 ? '< ' + vLabel + ' >' : vLabel);
			}
			var scoreBox:String = Rank.formatFreeplayBox(lerpScore, lerpRating, intendedMisses, diffLine);
			if(Highscore.isOpponentModeSettingOn())
				scoreBox = scoreBox.replace('HIGHSCORE:', 'OPP HIGHSCORE:');
			scoreText.text = scoreBox;
			positionHighscore();
			
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS)
					changeModDirectory(-1);
				else if (FlxG.keys.pressed.SHIFT)
					changeVariation(-1);
				else
				{
					changeDiff(-1);
					_updateSongLastDifficulty();
				}
			}
			else if (controls.UI_RIGHT_P)
			{
				if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS)
					changeModDirectory(1);
				else if (FlxG.keys.pressed.SHIFT)
					changeVariation(1);
				else
				{
					changeDiff(1);
					_updateSongLastDifficulty();
				}
			}
			if (FlxG.keys.justPressed.Q)
				changeVariation(-1);
			if (FlxG.keys.justPressed.E)
				changeVariation(1);
			if (FlxG.keys.justPressed.TAB)
				changeModDirectory(FlxG.keys.pressed.SHIFT ? -1 : 1);
		}

		if (controls.BACK)
		{
			if (player != null && player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('menu/freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				hideFreeplaySongList();
				createSelectMenu();
			}
		}

		if(player != null && FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubState());
		}
		else if(player != null && FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				loadFreeplaySong();
				var songAssetId:String = getLoadedFreeplaySongAudioId();
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player);
						var loadedVocals = Paths.voices(songAssetId, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(songAssetId);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.opponent);
						var loadedVocals = Paths.voices(songAssetId, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}

				FlxG.sound.playMusic(Paths.inst(songAssetId), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);

				getFreeplayPreviewSongId();
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (player != null && controls.ACCEPT && !player.playingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = getFreeplaySongId();
			var chartName:String = getFreeplayChartName(songLowercase);

			try
			{
				try Paths.songAudioRoot = null catch(e:Dynamic) {}
				loadFreeplaySong(songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:haxe.Exception)
			{
				trace('ERROR! ${e.message}');

				var errorStr:String = e.message;
				if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + chartName; //Missing chart
				else errorStr += '\n\n' + e.stack;

				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingScreenState.prepareToSong();
			LoadingScreenState.loadAndSwitchState(new PlayState());
			#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
			stopMusicPlay = true;

			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if(player != null && controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter, songs[curSelected].week, true));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('data/characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null)
		{
			vocals.stop();
			FlxG.sound.list.remove(vocals);
			vocals.group = null;
		}
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null)
		{
			opponentVocals.stop();
			FlxG.sound.list.remove(opponentVocals);
			opponentVocals.group = null;
		}
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	/** Override Difficulty.list with per-song meta difficulties when available */
	function applySongMetaDifficultyList(songData:FreeplaySongData):Void
	{
		if(songData == null || !songData.hasMetaDifficulties()) return;
		Difficulty.list = songData.difficulties.copy();
		if(Difficulty.list.length < 1)
			Difficulty.list = Difficulty.defaultList.copy();
	}

	function changeVariation(change:Int = 1):Void
	{
		if(songs.length < 1 || inSelectMenu) return;
		var songData:FreeplaySongData = songs[curSelected];
		if(songData == null || !songData.hasVariations()) return;
		songData.cycleVariation(change);
		songData.applyVariationMeta();
		refreshSongListItem(curSelected);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		// Meta difficulties may change per variation
		applySongMetaDifficultyList(songData);
		if(curDifficulty >= Difficulty.list.length)
			curDifficulty = Difficulty.list.length - 1;
		if(curDifficulty < 0) curDifficulty = 0;
		changeDiff();
	}

	/** Update alphabet text + icon + bg color for one freeplay entry */
	function refreshSongListItem(index:Int):Void
	{
		if(index < 0 || index >= songs.length) return;
		var data:FreeplaySongData = songs[index];
		if(grpSongs != null && index < grpSongs.length && grpSongs.members[index] != null)
		{
			var item:Alphabet = grpSongs.members[index];
			item.text = data.getDisplayName();
			item.scaleX = Math.min(1, 980 / Math.max(item.width, 1));
			item.snapToPosition();
		}
		if(index < iconArray.length && iconArray[index] != null)
		{
			try
			{
				iconArray[index].changeIcon(data.songCharacter);
			}
			catch(e:Dynamic)
			{
				try
				{
					remove(iconArray[index]);
					iconArray[index].destroy();
					var tracker = (grpSongs != null && index < grpSongs.length) ? grpSongs.members[index] : null;
					iconArray[index] = createIconItem(data.songCharacter, tracker);
					iconArray[index].alpha = (index == curSelected) ? 1 : 0.6;
				}
				catch(e2:Dynamic) {}
			}
		}
		if(index == curSelected)
		{
			var newColor:Int = data.color;
			if(newColor != intendedColor)
			{
				intendedColor = newColor;
				FlxTween.cancelTweensOf(bg);
				FlxTween.color(bg, 0.35, bg.color, intendedColor);
			}
		}
	}

	function changeDiff(change:Int = 0)
	{
		if (player != null && player.playingMusic)
			return;

		if (Difficulty.list == null || Difficulty.list.length < 1)
			Difficulty.resetList();

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		#if !switch
		var weekData:WeekData = null;
		if (songs[curSelected].week >= 0 && songs[curSelected].week < WeekData.weeksList.length)
			weekData = WeekData.weeksLoaded.get(WeekData.weeksList[songs[curSelected].week]);
		var oppScores:Bool = Highscore.isOpponentModeSettingOn();
		var scoreVariation:String = songs[curSelected].getCurrentVariation();
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, scoreVariation, weekData, true, oppScores);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, scoreVariation, weekData, true, oppScores);
		intendedMisses = Highscore.getMisses(songs[curSelected].songName, curDifficulty, scoreVariation, weekData, true, oppScores);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (diffText != null)
		{
			// Difficulty is drawn inside scoreText box
			diffText.visible = false;
			diffText.text = '';
		}

		if (scoreText != null) positionHighscore();
		if (missingText != null) missingText.visible = false;
		if (missingTextBG != null) missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player != null && player.playingMusic)
			return;
		if (songs == null || songs.length < 1 || grpSongs == null)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		
		// Keep currentModDirectory in sync with selected song (and active filter when not ALL)
		applyCurrentModDirectoryFromSelection();
		PlayState.storyWeek = songs[curSelected].week;
		// freeplay songs → freeplayDifficulties (true)
		var weekData:WeekData = null;
		if (songs[curSelected].week >= 0 && songs[curSelected].week < WeekData.weeksList.length)
			weekData = WeekData.weeksLoaded.get(WeekData.weeksList[songs[curSelected].week]);
		// Difficulties: meta.json first; else engine default list (week no longer stores diffs)
		if (songs[curSelected].hasMetaDifficulties())
		{
			applySongMetaDifficultyList(songs[curSelected]);
		}
		else
		{
			try Difficulty.loadFromWeek(weekData, true) catch(e:Dynamic) Difficulty.resetList();
			if (Difficulty.list == null || Difficulty.list.length < 1)
				Difficulty.resetList();
		}
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var savedDiffIndex:Int = getDifficultyIndex(savedDiff);
		var weekDiffIndex:Int = getDifficultyIndex(lastDifficultyByWeek.get(getCurrentWeekKey()));
		var lastDiff:Int = getDifficultyIndex(lastDifficultyName);
		if(savedDiffIndex > -1)
			curDifficulty = savedDiffIndex;
		else if(weekDiffIndex > -1)
			curDifficulty = weekDiffIndex;
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(getDifficultyIndex(Difficulty.getDefault()) > -1)
			curDifficulty = getDifficultyIndex(Difficulty.getDefault());
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	function getDifficultyIndex(?name:String):Int
	{
		var cleanName:String = Difficulty.getSuffixName(name);
		if(cleanName.length < 1)
			return -1;

		for (i in 0...Difficulty.list.length)
		{
			if(Difficulty.getSuffixName(Difficulty.list[i]) == cleanName)
				return i;
		}
		return -1;
	}

	inline private function _updateSongLastDifficulty()
	{
		var diff:String = Difficulty.getString(curDifficulty, false);
		songs[curSelected].lastDifficulty = diff;
		lastDifficultyByWeek.set(getCurrentWeekKey(), diff);
	}

	function getCurrentWeekKey():String
	{
		var weekIndex:Int = songs[curSelected].week;
		if(weekIndex >= 0 && weekIndex < WeekData.weeksList.length)
			return WeekData.weeksList[weekIndex];
		return Std.string(weekIndex);
	}

	public function positionHighscore()
	{
		if (scoreText == null || scoreBG == null)
			return;

		// Uma caixa só: HIGHSCORE + Rank, MISSES e dificuldade
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreText.y = 5;

		scoreBG.scale.x = 1;
		scoreBG.scale.y = 1;
		scoreBG.updateHitbox();
		scoreBG.setGraphicSize(Std.int(scoreText.width + 12), Std.int(scoreText.height + 8));
		scoreBG.updateHitbox();
		scoreBG.x = FlxG.width - scoreBG.width;
		scoreBG.y = 0;

		if (diffText != null)
			diffText.visible = false;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		if (inSelectMenu || grpSongs == null || songs.length < 1)
			return;

		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			if (i < 0 || i >= grpSongs.length) continue;
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			if (i < iconArray.length && iconArray[i] != null)
				iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			if (item == null) continue;
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			if (i < iconArray.length && iconArray[i] != null)
			{
				var icon:HealthIcon = iconArray[i];
				icon.visible = icon.active = true;
			}
			_lastVisibles.push(i);
		}
	}

		override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
	}

	// ---------- Mod directory / category filter (Psych Online style) ----------

	static inline var FILTER_ALL:String = 'ALL';
	static inline var FILTER_BASE:String = '(Base Game)';
	static inline var FILTER_CAT_PREFIX:String = 'CATEGORY:';

	function rebuildModDirectoryList():Void
	{
		modDirectoryList = [FILTER_ALL, FILTER_BASE];
		var seenMods:Array<String> = [];
		var source:Array<FreeplaySongData> = (allSongs != null && allSongs.length > 0) ? allSongs : songs;

		// Mods that actually have freeplay songs
		for (s in source)
		{
			var folder:String = (s.folder != null) ? s.folder : '';
			if(folder.length < 1) continue;
			if(!seenMods.contains(folder))
				seenMods.push(folder);
		}

		// Also enabled mods (even without songs listed yet) — V-Slice / Codename / Psych / Pico
		#if MODS_ALLOWED
		try
		{
			for (mod in Mods.getEnabled())
			{
				if(mod != null && mod.length > 0 && !seenMods.contains(mod))
					seenMods.push(mod);
			}
			for (mod in Mods.getModDirectories())
			{
				if(mod != null && mod.length > 0 && !seenMods.contains(mod) && Mods.isEnabled(mod))
					seenMods.push(mod);
			}
		}
		catch(e:Dynamic) {}
		#end

		// Sort mod folders by display name
		seenMods.sort(function(a:String, b:String):Int {
			var na:String = getModDisplayName(a).toLowerCase();
			var nb:String = getModDisplayName(b).toLowerCase();
			return Reflect.compare(na, nb);
		});

		for (mod in seenMods)
			modDirectoryList.push(mod);

		// Category filters from mod_Category (meta_mod / pack / etc.)
		#if MODS_ALLOWED
		try
		{
			var cats:Array<String> = Mods.getModCategories(false);
			cats.sort(function(a:String, b:String):Int {
				return Reflect.compare(a.toLowerCase(), b.toLowerCase());
			});
			for (c in cats)
			{
				var entry:String = FILTER_CAT_PREFIX + c;
				if(!modDirectoryList.contains(entry))
					modDirectoryList.push(entry);
			}
		}
		catch(e:Dynamic) {}
		#end

		if(curModDirectoryIndex < 0 || curModDirectoryIndex >= modDirectoryList.length)
			curModDirectoryIndex = 0;
	}

	function getSelectedModDirectoryKey():String
	{
		if(modDirectoryList == null || modDirectoryList.length < 1)
			return FILTER_ALL;
		if(curModDirectoryIndex < 0 || curModDirectoryIndex >= modDirectoryList.length)
			curModDirectoryIndex = 0;
		return modDirectoryList[curModDirectoryIndex];
	}

	function getModDisplayName(folder:String):String
	{
		if(folder == null || folder.length < 1) return 'Base Game';
		try
		{
			var info = Mods.getPackInfo(folder);
			if(info != null && info.name != null && info.name.length > 0)
				return info.name;
		}
		catch(e:Dynamic) {}
		return folder;
	}

	function getModCategoryLabel(folder:String):String
	{
		try
		{
			var info = Mods.getPackInfo(folder);
			if(info != null && info.category != null && info.category.trim().length > 0)
				return info.category.trim();
		}
		catch(e:Dynamic) {}
		return '';
	}

	/** Label shown in < ... > */
	function getModDirectoryLabel():String
	{
		var key:String = getSelectedModDirectoryKey();
		if(key == FILTER_ALL) return 'ALL';
		if(key == FILTER_BASE) return 'BASE GAME';
		if(StringTools.startsWith(key, FILTER_CAT_PREFIX))
		{
			var cat:String = key.substr(FILTER_CAT_PREFIX.length);
			return 'CATEGORY: ' + cat.toUpperCase();
		}
		// Individual mod: Name + [Category]
		var name:String = getModDisplayName(key);
		var cat:String = getModCategoryLabel(key);
		if(cat.length > 0)
			return name + ' [' + cat + ']';
		return name;
	}

	function updateModDirectoryLabel():Void
	{
		if(modDirectoryTxt == null) return;
		var label:String = getModDirectoryLabel();
		modDirectoryTxt.text = '< ' + label + ' >';
		if(modDirectoryBG != null)
		{
			modDirectoryBG.setGraphicSize(Std.int(modDirectoryTxt.width + 16), Std.int(modDirectoryTxt.height + 10));
			modDirectoryBG.updateHitbox();
			modDirectoryBG.x = modDirectoryTxt.x - 6;
			modDirectoryBG.y = modDirectoryTxt.y - 4;
		}
	}

	function changeModDirectory(change:Int = 0):Void
	{
		if(modDirectoryList == null || modDirectoryList.length < 2)
		{
			updateModDirectoryLabel();
			return;
		}
		curModDirectoryIndex = FlxMath.wrap(curModDirectoryIndex + change, 0, modDirectoryList.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		applyModDirectoryFilter(true);
		updateModDirectoryLabel();
	}

	function songMatchesFilter(s:FreeplaySongData, key:String):Bool
	{
		if(s == null) return false;
		var folder:String = (s.folder != null) ? s.folder : '';

		if(key == FILTER_ALL)
			return true;
		if(key == FILTER_BASE)
			return folder.length < 1;
		if(StringTools.startsWith(key, FILTER_CAT_PREFIX))
		{
			var cat:String = key.substr(FILTER_CAT_PREFIX.length).toLowerCase();
			if(folder.length < 1) return false;
			var modCat:String = getModCategoryLabel(folder).toLowerCase();
			return modCat == cat;
		}
		// Specific mod folder
		return folder == key;
	}

	/**
	 * Filter freeplay songs by:
	 *  ALL | BASE GAME | single mod | CATEGORY:xxx (mod_Category)
	 * Works with Pico / Psych / V-Slice / Codename / Polymod packs.
	 */
	function applyModDirectoryFilter(rebuildUI:Bool = true):Void
	{
		var key:String = getSelectedModDirectoryKey();
		var source:Array<FreeplaySongData> = (allSongs != null && allSongs.length > 0) ? allSongs : songs.copy();
		var filtered:Array<FreeplaySongData> = [];

		for (s in source)
			if(songMatchesFilter(s, key))
				filtered.push(s);

		// Sync Mods.currentModDirectory
		if(key == FILTER_ALL || key == FILTER_BASE || StringTools.startsWith(key, FILTER_CAT_PREFIX))
		{
			try Mods.clearCurrent() catch(e:Dynamic) Mods.currentModDirectory = '';
		}
		else
		{
			Mods.currentModDirectory = key;
		}

		songs = filtered;
		if(songs.length < 1)
		{
			curSelected = 0;
			if(rebuildUI) rebuildSongListUI();
			return;
		}
		if(curSelected >= songs.length) curSelected = songs.length - 1;
		if(curSelected < 0) curSelected = 0;

		if(rebuildUI)
			rebuildSongListUI();
	}

	/** Recreate alphabet + icons after filter change */
	function rebuildSongListUI():Void
	{
		for (icon in iconArray)
		{
			if(icon != null)
			{
				remove(icon);
				icon.destroy();
			}
		}
		iconArray = [];

		if(grpSongs != null)
			grpSongs.clear();
		else
		{
			grpSongs = new FlxTypedGroup<Alphabet>();
			add(grpSongs);
		}

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].getDisplayName(), true);
			songText.targetY = i;
			grpSongs.add(songText);
			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			var prevMod:String = Mods.currentModDirectory;
			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = createIconItem(songs[i].songCharacter, songText);
			Mods.currentModDirectory = prevMod;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;
		}

		if(songs.length > 0)
		{
			changeSelection(0, false);
			updateTexts();
		}
	}

	function applyCurrentModDirectoryFromSelection():Void
	{
		if(songs == null || songs.length < 1 || curSelected < 0 || curSelected >= songs.length)
			return;
		var key:String = getSelectedModDirectoryKey();
		if(key != FILTER_ALL && key != FILTER_BASE && !StringTools.startsWith(key, FILTER_CAT_PREFIX))
		{
			Mods.currentModDirectory = key;
			return;
		}
		var folder:String = songs[curSelected].folder;
		Mods.currentModDirectory = (folder != null) ? folder : '';
	}

}

class FreeplaySongData
{
	public var songName:String = "";
	/** Shown in Freeplay list (from meta/chart displayName); load path still uses songName */
	public var displayName:String = "";
	public var week:Int = 0;
	/** Week/default icon — overridden by meta freeplayIcon when present */
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	/** From meta: per-song difficulties (overrides week list when set) */
	public var difficulties:Array<String> = null;
	/** From meta: song variations (erect, pico, ...) */
	public var variations:Array<String> = null;
	public var lastVariation:String = null;
	public var curVariationIndex:Int = 0;

	var baseDisplayName:String = "";
	var baseIcon:String = "";
	var baseColor:Int = -7179779;
	var baseDifficulties:Array<String> = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.displayName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.baseIcon = songCharacter;
		this.baseColor = color;
		this.baseDisplayName = song;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
		resolveMeta();
	}

	public function getDisplayName():String
	{
		if(displayName != null && displayName.trim().length > 0)
			return displayName.trim();
		return songName;
	}

	public function hasMetaDifficulties():Bool
		return difficulties != null && difficulties.length > 0;

	public function hasVariations():Bool
		return variations != null && variations.length > 0;

	/** null = default variation (no suffix) */
	public function getCurrentVariation():String
	{
		if(!hasVariations()) return null;
		if(curVariationIndex < 0 || curVariationIndex >= variations.length)
			curVariationIndex = 0;
		var v:String = variations[curVariationIndex];
		if(v == null) return null;
		v = v.trim();
		if(v.length < 1 || v.toLowerCase() == 'default' || v.toLowerCase() == 'none')
			return null;
		return v;
	}

	public function cycleVariation(change:Int = 1):String
	{
		if(!hasVariations()) return null;
		curVariationIndex = FlxMath.wrap(curVariationIndex + change, 0, variations.length - 1);
		lastVariation = getCurrentVariation();
		return lastVariation;
	}

	/**
	 * Base meta.json → list fields + defaults.
	 * Variation list from songVariations; display/icon/color from meta.
	 */
	function resolveMeta():Void
	{
		try
		{
			var folderId:String = Paths.formatToSongPath(songName);
			var meta = SongMeta.load(folderId, null, false, null);
			if(meta == null) return;

			applyMetaFields(meta, true);

			if(meta.variations != null && meta.variations.length > 0)
			{
				variations = meta.variations.copy();
				var hasDefault:Bool = false;
				for (v in variations)
				{
					if(v != null && (v.trim().toLowerCase() == 'default' || v.trim().toLowerCase() == 'none'))
						hasDefault = true;
				}
				if(!hasDefault)
					variations.insert(0, 'default');
			}

			// If already on a non-default variation, overlay that meta
			applyVariationMeta();
		}
		catch(e:Dynamic) {}
	}

	/** Reload meta-<variation>.json overlay when cycling variations in freeplay */
	public function applyVariationMeta():Void
	{
		try
		{
			var folderId:String = Paths.formatToSongPath(songName);
			var variation:String = getCurrentVariation();

			// Reset to base first
			displayName = baseDisplayName;
			songCharacter = baseIcon;
			color = baseColor;
			difficulties = baseDifficulties != null ? baseDifficulties.copy() : null;

			var meta = SongMeta.load(folderId, null, false, variation);
			if(meta == null) return;
			applyMetaFields(meta, variation == null);
		}
		catch(e:Dynamic) {}
	}

	function applyMetaFields(meta:SongMeta, asBase:Bool):Void
	{
		if(meta == null) return;

		if(meta.displayName != null && meta.displayName.trim().length > 0)
			displayName = meta.displayName.trim();
		else if(meta.songName != null && meta.songName.trim().length > 0)
			displayName = meta.songName.trim();

		if(meta.freeplayIcon != null && meta.freeplayIcon.trim().length > 0)
			songCharacter = meta.freeplayIcon.trim();
		else if(meta.opponent != null && meta.opponent.trim().length > 0 && asBase)
			songCharacter = meta.opponent.trim();

		var parsedColor:Null<Int> = parseMetaColor(meta.freeplayColor);
		if(parsedColor != null)
			color = parsedColor;

		if(meta.difficulties != null && meta.difficulties.length > 0)
			difficulties = meta.difficulties.copy();

		if(asBase)
		{
			baseDisplayName = displayName;
			baseIcon = songCharacter;
			baseColor = color;
			baseDifficulties = difficulties != null ? difficulties.copy() : null;
		}
	}

	static function parseMetaColor(value:String):Null<Int>
	{
		if(value == null) return null;
		var s:String = value.trim();
		if(s.length < 1) return null;
		if(StringTools.startsWith(s, '#'))
		{
			var hex:String = s.substr(1);
			if(hex.length == 6) hex = 'FF' + hex;
			var n:Null<Int> = Std.parseInt('0x' + hex);
			return n;
		}
		if(s.indexOf(',') >= 0)
		{
			var rgb:Array<String> = s.split(',');
			if(rgb.length >= 3)
			{
				return FlxColor.fromRGB(
					Std.parseInt(rgb[0].trim()) ?? 128,
					Std.parseInt(rgb[1].trim()) ?? 128,
					Std.parseInt(rgb[2].trim()) ?? 128
				);
			}
		}
		var asInt:Null<Int> = Std.parseInt(s);
		return asInt;
	}
}
