package funkin.states;

import funkin.play.Song;
import funkin.play.Highscore;

import funkin.data.WeekData;
import funkin.states.options.OptionsState;
import funkin.states.editors.data.ChartingState;

import funkin.states.menus.freeplay.FreeplayMenuState;
import funkin.utils.engines.pico.LocaleUtils;
import flixel.util.FlxStringUtil;

class PauseMenuState extends MusicBeatSubstate
{
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuItems:Array<String> = [];

	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	var dateTimeText:FlxText;
	
	public static var songName:String = null;

	#if LUA_ALLOWED
	var pauseLuaScripts:Array<funkin.modding.scripting.FunkinLuaProgramming> = [];
	#end
	#if HSCRIPT_ALLOWED
	var pauseHScripts:Array<funkin.modding.scripting.FunkinHSProgramming> = [];
	#end

	override function create()
	{
		menuItems = buildPauseMenuItems();

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var displayNameSong:FlxText = new FlxText(20, 15, 0, Language.getPhrase("playteste_song", "SONG: {1}", [PlayState.SONG.song]), 32);
		displayNameSong.scrollFactor.set();
		displayNameSong.setFormat(Paths.font("vcr.ttf"), 32);
		displayNameSong.updateHitbox();
		add(displayNameSong);

		var difficultyName:String = Difficulty.getString();
		var showDifficulty:Bool = Paths.formatToSongPath(difficultyName) != Paths.formatToSongPath(Difficulty.getDefault());
		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, showDifficulty ? Language.getPhrase("pause_difficulty", "Difficulty: {1}", [difficultyName]) : '', 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		if(showDifficulty) add(levelDifficulty);

		var blueballedY:Float = showDifficulty ? 15 + 64 : 15 + 32;
		var blueballedTxt:FlxText = new FlxText(20, blueballedY, 0, Language.getPhrase("blueballed", "{1} Death", [PlayState.deathCounter]), 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		// Pico Engine and By PlusEngine 
		var now:Date = Date.now();
		var dateTimeStr:String = LocaleUtils.formatDateTimeAccordingToDevice(now);
		dateTimeText = new FlxText(0, 15 + 96, FlxG.width, dateTimeStr, 32);
		dateTimeText.scrollFactor.set();
		dateTimeText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		dateTimeText.updateHitbox();
		dateTimeText.alpha = 0;
		add(dateTimeText);

		practiceText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Practice Mode").toUpperCase(), 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Charting Mode").toUpperCase(), 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		displayNameSong.alpha = 0;

		displayNameSong.x = FlxG.width - (displayNameSong.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(displayNameSong, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		if(showDifficulty)
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		FlxTween.tween(dateTimeText, {alpha: 1, y: dateTimeText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});		

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// Custom scripts: scripts/states/pauseMenu/*.lua | *.hx | *.hxc
		startPauseScripts();

		super.create();
	}

	function buildPauseMenuItems():Array<String>
	{
		var items:Array<String> = menuItemsOG.copy();
		if(Difficulty.list.length < 2) items.remove('Change Difficulty'); //No need to change difficulty if there is only one!
		if(PlayState.chartingMode)
		{
			items.remove('Change Difficulty');
			items.remove('Change Gameplay Settings');
			items.remove('Options');
			items.remove('Exit to menu');
			items.push('Return to Chart Editor');
		}
		else if(PlayState.instance.practiceMode && !PlayState.instance.startingSong)
			items.insert(3, 'Skip Time');

		return items;
	}
	
	function getPauseSong()
	{
		var songPauseMusic:String = (PlayState.SONG != null ? PlayState.SONG.pauseSong : null);
		var formattedSongName:String = '';
		if(songPauseMusic != null && songPauseMusic.trim().length > 0)
			formattedSongName = resolvePauseMusicKey(songPauseMusic);
		else if(songName != null)
			formattedSongName = resolvePauseMusicKey(songName);

		if(formattedSongName == 'none') return null;
		if(formattedSongName != '') return formattedSongName;

		var formattedPauseMusic:String = resolvePauseMusicKey(ClientPrefs.data.pauseMusic);
		if(formattedPauseMusic == 'none') return null;
		return formattedPauseMusic;
	}

	public static function resolvePauseMusicKey(value:String):String
	{
		var formatted:String = Paths.formatToSongPath(value);
		return switch(formatted)
		{
			case 'breakfast': 'pauseMenu/breakfast';
			case 'breakfast-pico': 'pauseMenu/breakfast-pico';
			case 'breakfast-pixel': 'pauseMenu/breakfast-pixel';
			default: formatted;
		}
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		callPauseScripts('onUpdate', [elapsed]);

		// Pico Engine and By PlusEngine 
		if (dateTimeText != null)
		{
            var now:Date = Date.now();

            dateTimeText.text = LocaleUtils.formatDateTimeAccordingToDevice(now);
        }

		if(controls.BACK)
		{
			close();
			return;
		}

		if(FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
		}

		updateSkipTextStuff();
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var poop:String = Highscore.formatSong(songLowercase, curSelected, PlayState.getSongVariationName(PlayState.SONG), WeekData.getCurrentWeek(), !PlayState.isStoryMode);
				try
				{
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
					{
						Song.loadFromJson(poop, songLowercase);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');
	
					var errorStr:String = e.message;
					if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
					else errorStr += '\n\n' + e.stack;

					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					super.update(elapsed);
					return;
				}


				menuItems = buildPauseMenuItems();
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case "Restart Song":
					restartSong();
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Return to Chart Editor':
					returnToChartEditor();
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					PlayState.instance.canResync = false;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(resolvePauseMusicKey(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					PlayState.instance.canResync = false;
					Mods.loadTopMod();
					if(PlayState.isStoryMode)
						MusicBeatState.switchState(new StoryMenuState());
					else
						MusicBeatState.switchState(new FreeplayMenuState());

					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	function returnToChartEditor():Void
	{
		PlayState.instance.paused = true;
		PlayState.instance.canResync = false;
		PlayState.chartingMode = true;
		FlxG.camera.followLerp = 0;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(PlayState.instance.vocals != null)
			PlayState.instance.vocals.pause();
		if(PlayState.instance.opponentVocals != null)
			PlayState.instance.opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	override function destroy()
	{
		callPauseScripts('onDestroy', []);
		#if LUA_ALLOWED
		if(pauseLuaScripts != null)
		{
			for (s in pauseLuaScripts)
				if(s != null) try s.stop() catch(e:Dynamic) {}
			pauseLuaScripts = [];
		}
		#end
		#if HSCRIPT_ALLOWED
		if(pauseHScripts != null)
		{
			for (s in pauseHScripts)
				if(s != null) try s.destroy() catch(e:Dynamic) {}
			pauseHScripts = [];
		}
		#end
		if(pauseMusic != null)
		{
			FlxG.sound.list.remove(pauseMusic);
			pauseMusic.group = null;
			pauseMusic.destroy();
			pauseMusic = null;
		}
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		for (num => item in grpMenuShit.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		missingText.visible = false;
		missingTextBG.visible = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length)
		{
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (num => str in menuItems) {
			var item = new Alphabet(90, 320, Language.getPhrase('pause_$str', str), true);
			item.isMenuItem = true;
			item.targetY = num;
			grpMenuShit.add(item);

			if(str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);

	/** Load scripts from scripts/states/pauseMenu/ (shared + mods). */
	function startPauseScripts():Void
	{
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		var folderKey:String = 'scripts/states/pauseMenu/';
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), folderKey))
		{
			if(folder == null || !FileSystem.exists(folder) || !FileSystem.isDirectory(folder)) continue;
			for (file in FileSystem.readDirectory(folder))
			{
				var lower:String = file.toLowerCase();
				var full:String = folder;
				if(!full.endsWith('/') && !full.endsWith('\\')) full += '/';
				full += file;
				if(FileSystem.isDirectory(full)) continue;

				#if LUA_ALLOWED
				if(lower.endsWith('.lua'))
				{
					var rel:String = folderKey + file;
					try
					{
						var script = new funkin.modding.scripting.FunkinLuaProgramming(rel);
						pauseLuaScripts.push(script);
						trace('[PauseState] Loaded lua: ' + rel);
					}
					catch(e:Dynamic)
					{
						// try absolute via Paths.modFolders style
						try
						{
							var script = new funkin.modding.scripting.FunkinLuaProgramming(full);
							pauseLuaScripts.push(script);
							trace('[PauseState] Loaded lua (full): ' + full);
						}
						catch(e2:Dynamic)
						{
							trace('[PauseState] Failed lua ' + file + ': ' + e2);
						}
					}
				}
				#end

				#if HSCRIPT_ALLOWED
				if(lower.endsWith('.hx') || lower.endsWith('.hxc'))
				{
					try
					{
						var hs = new funkin.modding.scripting.FunkinHSProgramming(null, full);
						if(hs.exists('onCreate')) hs.call('onCreate');
						pauseHScripts.push(hs);
						trace('[PauseState] Loaded hscript: ' + full);
					}
					catch(e:Dynamic)
					{
						trace('[PauseState] Failed hscript ' + file + ': ' + e);
					}
				}
				#end
			}
		}
		callPauseScripts('onCreatePost', []);
		#end
	}

	function callPauseScripts(func:String, args:Array<Dynamic>):Void
	{
		if(args == null) args = [];
		#if LUA_ALLOWED
		if(pauseLuaScripts != null)
		{
			for (s in pauseLuaScripts)
			{
				if(s == null || s.closed) continue;
				try s.call(func, args) catch(e:Dynamic) {}
			}
		}
		#end
		#if HSCRIPT_ALLOWED
		if(pauseHScripts != null)
		{
			for (s in pauseHScripts)
			{
				if(s == null) continue;
				try
				{
					if(s.exists(func)) s.call(func, args);
				}
				catch(e:Dynamic) {}
			}
		}
		#end
	}
}
