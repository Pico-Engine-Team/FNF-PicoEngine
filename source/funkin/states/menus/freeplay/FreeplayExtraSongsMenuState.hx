package funkin.states.menus.freeplay;

import funkin.Paths;
import funkin.play.Song;
import funkin.play.Highscore;
import funkin.play.Difficulty;

import funkin.data.objects.HealthIcon;
import funkin.stages.StageData;

import flixel.text.FlxText.FlxTextBorderStyle;
import haxe.Json;
using StringTools;

/**
 * Extra Freeplay
 *
 * List:
 *   data/freeplayExtraSonglist.txt
 *   data/freeplayExtraSonglist.json
 *
 * Charts:
 *   assets/data/extra-songs/<song>/<file>.json
 *   e.g. assets/data/extra-songs/lo-fight/lo-fight-hard-extra.json
 *
 * Audio:
 *   assets/data/extra-songs/<song>/song/Inst.ogg
 *   assets/data/extra-songs/<song>/song/Voices.ogg
 *
 * Uses Paths.songAudioRoot = "data/extra-songs" while playing.
 */
class FreeplayExtraSongsState extends MusicBeatState
{
	private var songs:Array<ExtraSongData> = [];
	private static var curSelected:Int = 0;
	private static var curDiffSelected:Int = 0;

	var curDifficulty:Int = -1;
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var noSongsText:FlxText;

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedMisses:Int = 0;
	var lerpSelected:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int = 0xFF808080;
	var colorTween:FlxTween;

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	/** Parent folder under assets/ → assets/data/extra-songs/ */
	public static inline var EXTRA_DATA_ROOT:String = 'data/extra-songs';
	public static inline var AUDIO_SUB:String = 'song';

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		// Ensure normal freeplay audio root is cleared when entering this menu
		Paths.songAudioRoot = null;

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		PlayState.storyWeek = 0;
		loadExtraSongs();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Freeplay Extra Song", "Selecting An Extra Song");
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		if (songs.length < 1)
		{
			noSongsText = new FlxText(60, 0, FlxG.width - 120,
				'NO EXTRA SONGS FOUND\n\n'
				+ '1) data/freeplayExtraSonglist.txt (one song per line)\n'
				+ '2) Charts: assets/data/extra-songs/<song>/<song>-<diff>-extra.json\n'
				+ '3) Audio: assets/data/extra-songs/<song>/song/Inst.ogg\n\n'
				+ 'Press BACK to return to Freeplay.',
				22);
			noSongsText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noSongsText.screenCenter(Y);
			add(noSongsText);
			super.create();
			return;
		}

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			songText.changeX = false;
			songText.snapToPosition();
			songText.screenCenter(X);
			songText.x += 60;
			songText.scaleX = Math.min(1, 900 / songText.width);
			songText.visible = songText.active = false;
			grpSongs.add(songText);

			Mods.currentModDirectory = songs[i].folder ?? '';
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			icon.visible = icon.active = false;
			iconArray.push(icon);
			add(icon);
		}
		Mods.currentModDirectory = '';

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 92, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		add(scoreText);

		if (curSelected >= songs.length) curSelected = songs.length - 1;
		if (curSelected < 0) curSelected = 0;
		lerpSelected = curSelected;

		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		changeSelection(0, false);
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (songs.length < 1)
		{
			if (controls.BACK)
				returnToFreeplay();
			super.update(elapsed);
			return;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var accStr:String = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2));
		scoreText.text = 'BEST SCORE: ' + lerpScore + ' (' + accStr + '%)\nMISSES: ' + intendedMisses;
		positionHighscore();

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);
		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
			returnToFreeplay();

		if (controls.ACCEPT)
			acceptSong();

		updateTexts(elapsed);
		super.update(elapsed);
	}

	function loadExtraSongs():Void
	{
		songs = [];
		if (!loadFromJsonList())
			loadFromTxtList();
		scanExtraSongFolders();
	}

	function loadFromJsonList():Bool
	{
		var raw:String = tryGetText('data/freeplayExtraSonglist.json');
		if (raw == null || raw.trim().length < 2)
			return false;

		try
		{
			var data:Dynamic = Json.parse(raw);
			var arr:Array<Dynamic> = null;
			if (Std.isOfType(data, Array))
				arr = cast data;
			else if (Reflect.hasField(data, 'songs'))
				arr = cast Reflect.field(data, 'songs');
			if (arr == null)
				return false;

			for (entry in arr)
			{
				if (entry == null) continue;
				if (Std.isOfType(entry, String))
				{
					pushSong(Std.string(entry));
					continue;
				}
				var name:String = firstField(entry, ['name', 'song', 'songName']);
				if (name == null) continue;
				var icon:String = firstField(entry, ['icon', 'character', 'songCharacter']);
				var color:Null<Int> = parseColor(entry);
				var diffs:Array<String> = parseDiffs(entry);
				var folder:String = firstField(entry, ['folder', 'mod']);
				pushSong(name, icon, color, diffs, folder);
			}
			return songs.length > 0;
		}
		catch (e:Dynamic)
		{
			trace('[ExtraSongs] freeplayExtraSonglist.json error: ' + e);
			return false;
		}
	}

	function loadFromTxtList():Void
	{
		var raw:String = tryGetText('data/freeplayExtraSonglist.txt');
		if (raw == null)
			return;

		for (line in raw.split('\n'))
		{
			var clean:String = line.trim();
			if (clean.length < 1) continue;
			if (StringTools.startsWith(clean, '#') || StringTools.startsWith(clean, '//'))
				continue;

			if (clean.indexOf('|') < 0)
			{
				pushSong(clean);
				continue;
			}

			var parts:Array<String> = clean.split('|');
			for (i in 0...parts.length)
				parts[i] = parts[i].trim();

			var name:String = parts[0];
			var icon:String = parts.length > 1 ? parts[1] : null;
			var color:Null<Int> = null;
			var diffs:Array<String> = null;

			if (parts.length > 2 && parts[2].length > 0)
			{
				var rgb:Array<String> = parts[2].split(',');
				if (rgb.length >= 3)
				{
					color = FlxColor.fromRGB(
						Std.parseInt(rgb[0].trim()) ?? 128,
						Std.parseInt(rgb[1].trim()) ?? 128,
						Std.parseInt(rgb[2].trim()) ?? 128
					);
				}
			}
			if (parts.length > 3 && parts[3].length > 0)
				diffs = normalizeDiffs(parts[3].split(','));

			pushSong(name, icon, color, diffs, null);
		}
	}

	function scanExtraSongFolders():Void
	{
		#if sys
		try
		{
			var roots:Array<String> = [];
			// assets/data/extra-songs/
			for (candidate in [
				Paths.getPath('extra-songs/', TEXT, 'data', false),
				'assets/data/extra-songs/',
				Paths.getSharedPath('data/extra-songs/')
			])
			{
				if (candidate != null && FileSystem.exists(candidate) && FileSystem.isDirectory(candidate))
					if (!roots.contains(candidate))
						roots.push(candidate);
			}

			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var modPath:String = Paths.mods(Mods.currentModDirectory + '/data/extra-songs/');
				if (FileSystem.exists(modPath) && FileSystem.isDirectory(modPath))
					roots.push(modPath);
			}

			for (root in roots)
			{
				for (dir in FileSystem.readDirectory(root))
				{
					var full:String = root + (StringTools.endsWith(root, '/') ? '' : '/') + dir;
					if (!FileSystem.isDirectory(full)) continue;
					var pathName:String = Paths.formatToSongPath(dir);
					if (pathName.length < 1 || hasSong(pathName)) continue;

					var diffs:Array<String> = discoverDiffsInFolder(full, pathName);
					pushSong(dir, 'face', colorFromPathName(pathName), diffs, null);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[ExtraSongs] folder scan failed: ' + e);
		}
		#end
	}

	#if sys
	function discoverDiffsInFolder(folderPath:String, pathName:String):Array<String>
	{
		var found:Array<String> = [];
		try
		{
			for (file in FileSystem.readDirectory(folderPath))
			{
				if (!StringTools.endsWith(file, '.json')) continue;
				var base:String = file.substr(0, file.length - 5);
				if (!StringTools.startsWith(base, pathName) && base.indexOf('-extra') < 0)
					continue;
				if (!StringTools.startsWith(base, pathName))
					continue;

				var rest:String = base.substr(pathName.length);
				rest = rest.replace('-extra', '');
				if (StringTools.startsWith(rest, '-'))
					rest = rest.substr(1);

				if (rest.length > 0)
					found.push(rest);
				else if (!containsDiff(found, 'pico'))
					found.push('pico');
			}
		}
		catch (e:Dynamic) {}
		return normalizeDiffs(found);
	}
	#end

	function pushSong(name:String, ?icon:String, ?color:Null<Int>, ?diffs:Array<String>, ?folder:String):Void
	{
		if (name == null) return;
		var display:String = name.trim();
		if (display.length < 1) return;

		var pathName:String = Paths.formatToSongPath(display);
		if (pathName.length < 1 || hasSong(pathName)) return;

		var char:String = (icon != null && icon.trim().length > 0) ? icon.trim() : 'face';
		var col:Int = color != null ? color : colorFromPathName(pathName);
		var d:Array<String> = (diffs != null && diffs.length > 0) ? normalizeDiffs(diffs) : ['pico'];
		var modFolder:String = folder ?? (Mods.currentModDirectory ?? '');

		songs.push(new ExtraSongData(display, pathName, char, col, d, modFolder));
	}

	static function firstField(obj:Dynamic, keys:Array<String>):Null<String>
	{
		for (k in keys)
		{
			if (!Reflect.hasField(obj, k)) continue;
			var v:Dynamic = Reflect.field(obj, k);
			if (v == null) continue;
			var s:String = Std.string(v).trim();
			if (s.length > 0) return s;
		}
		return null;
	}

	static function parseColor(entry:Dynamic):Null<Int>
	{
		if (!Reflect.hasField(entry, 'color')) return null;
		var c:Dynamic = Reflect.field(entry, 'color');
		if (Std.isOfType(c, Array))
		{
			var a:Array<Dynamic> = cast c;
			if (a.length >= 3)
				return FlxColor.fromRGB(Std.int(a[0]), Std.int(a[1]), Std.int(a[2]));
		}
		else if (Std.isOfType(c, Int) || Std.isOfType(c, Float))
			return Std.int(c);
		else if (Std.isOfType(c, String))
		{
			var s:String = Std.string(c).trim();
			if (StringTools.startsWith(s, '#'))
				return Std.parseInt('0x' + s.substr(1));
			var rgb:Array<String> = s.split(',');
			if (rgb.length >= 3)
				return FlxColor.fromRGB(Std.parseInt(rgb[0]) ?? 128, Std.parseInt(rgb[1]) ?? 128, Std.parseInt(rgb[2]) ?? 128);
		}
		return null;
	}

	static function parseDiffs(entry:Dynamic):Array<String>
	{
		for (key in ['difficulties', 'diffs', 'difficulty'])
		{
			if (!Reflect.hasField(entry, key)) continue;
			var v:Dynamic = Reflect.field(entry, key);
			if (v == null) continue;
			if (Std.isOfType(v, Array))
			{
				var out:Array<String> = [];
				for (item in (cast v:Array<Dynamic>))
					out.push(Std.string(item));
				return normalizeDiffs(out);
			}
			return normalizeDiffs(Std.string(v).split(','));
		}
		return null;
	}

	function findExtraChartKey(song:ExtraSongData, diff:String):String
	{
		var pathName:String = song.pathName;
		for (candidate in getExtraChartCandidates(pathName, diff))
		{
			// candidate is just the filename stem; path built in extraChartPath
			if (assetTextExists(extraChartPath(pathName, candidate, song.folder)))
				return candidate;
		}
		return null;
	}

	function getExtraChartCandidates(pathName:String, diff:String):Array<String>
	{
		var suffix:String = '';
		try
		{
			suffix = Difficulty.getSuffixFilePath(diff);
		}
		catch (e:Dynamic) {}
		var cleanDiff:String = Paths.formatToSongPath(diff);
		if (suffix.length < 1 && cleanDiff.length > 0)
			suffix = '-' + cleanDiff;

		var candidates:Array<String> = [];
		// files inside assets/data/extra-songs/<song>/
		addChartCandidate(candidates, pathName + suffix + '-extra');
		addChartCandidate(candidates, pathName + '-extra' + suffix);
		addChartCandidate(candidates, pathName + '-extra');
		addChartCandidate(candidates, pathName + suffix);
		addChartCandidate(candidates, pathName);
		return candidates;
	}

	function addChartCandidate(candidates:Array<String>, candidate:String):Void
	{
		if (candidate != null && candidate.length > 0 && !candidates.contains(candidate))
			candidates.push(candidate);
	}

	/**
	 * assets/data/extra-songs/<songPathName>/<chartKey>.json
	 */
	function extraChartPath(songPathName:String, chartKey:String, folder:Null<String>):String
	{
		try
		{
			return Paths.extraSongsChartJson(songPathName + '/' + chartKey, normalizeFolder(folder));
		}
		catch (e:Dynamic) {}

		var relative:String = 'extra-songs/' + songPathName + '/' + chartKey + '.json';
		#if sys
		if (folder != null && folder.length > 0)
		{
			var modPath:String = Paths.mods(folder + '/data/' + relative);
			if (FileSystem.exists(modPath))
				return modPath;
		}
		for (root in [
			Paths.getPath(relative, TEXT, 'data', false),
			'assets/data/' + relative,
			Paths.getSharedPath('data/' + relative)
		])
		{
			if (root != null && FileSystem.exists(root))
				return root;
		}
		#end
		try
		{
			return Paths.getPath(relative, TEXT, 'data', true);
		}
		catch (e:Dynamic)
		{
			return 'assets/data/' + relative;
		}
	}

	static function assetTextExists(path:String):Bool
	{
		if (path == null || path.length < 1) return false;
		#if sys
		if (FileSystem.exists(path)) return true;
		#end
		try
		{
			return openfl.utils.Assets.exists(path);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	function acceptSong():Void
	{
		var song:ExtraSongData = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		var pathName:String = song.pathName;
		var chartKey:String = findExtraChartKey(song, diff);
		var chartPath:String = chartKey != null
			? extraChartPath(pathName, chartKey, song.folder)
			: extraChartPath(pathName, pathName + '-extra', song.folder);
		var raw:String = chartKey != null ? readText(chartPath) : null;

		if (raw == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		try
		{
			PlayState.SONG = Song.parseJSON(raw, chartKey != null ? chartKey : pathName);
			Reflect.setField(PlayState.SONG, 'extraFreeplay', true);
			Song.loadedSongName = pathName;
			try
			{
				Reflect.setField(PlayState.SONG, 'song', pathName);
			}
			catch (e:Dynamic) {}
			Song.chartPath = chartPath;
			// Route Paths.inst / voices to assets/data/extra-songs/<song>/song/
			Paths.songAudioRoot = EXTRA_DATA_ROOT;
			StageData.loadDirectory(PlayState.SONG);
		}
		catch (e:haxe.Exception)
		{
			showChartError(song, diff, e.message);
			return;
		}

		if (PlayState.SONG == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDiffSelected;
		Difficulty.copyFrom(song.diffs);
		Mods.currentModDirectory = song.folder ?? '';

		FlxG.sound.music.volume = 0;
		LoadingScreenState.prepareToSong();
		LoadingScreenState.loadAndSwitchState(new PlayState());
	}

	function changeDiff(change:Int = 0)
	{
		var song = songs[curSelected];
		curDiffSelected = FlxMath.wrap(curDiffSelected + change, 0, song.diffs.length - 1);
		updateDiffText();
		updateScore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (songs.length < 1)
			return;

		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		curDiffSelected = 0;
		var song = songs[curSelected];
		Difficulty.copyFrom(song.diffs);

		intendedColor = song.color;
		if (bg != null)
		{
			if (colorTween != null) colorTween.cancel();
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(_) colorTween = null
			});
		}

		for (i in 0...iconArray.length)
			if (iconArray[i] != null)
				iconArray[i].alpha = 0.6;
		if (iconArray[curSelected] != null)
			iconArray[curSelected].alpha = 1;

		for (i in 0...grpSongs.length)
		{
			var item:Alphabet = grpSongs.members[i];
			if (item == null) continue;
			item.targetY = i - curSelected;
			item.alpha = (i == curSelected) ? 1 : 0.6;
		}

		Mods.currentModDirectory = song.folder ?? '';
		updateDiffText();
		updateScore();
	}

	function updateDiffText()
	{
		var song = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		if (song.diffs.length > 1)
			diffText.text = '< ' + diff.toUpperCase() + ' >';
		else
			diffText.text = diff.toUpperCase();
	}

	function updateScore()
	{
		var song = songs[curSelected];
		curDifficulty = curDiffSelected;

		intendedScore = Highscore.getScore(song.pathName, curDifficulty, null, null, true);
		intendedRating = Highscore.getRating(song.pathName, curDifficulty, null, null, true);
		intendedMisses = Highscore.getMisses(song.pathName, curDifficulty, null, null, true);
	}

	function positionHighscore()
	{
		if (scoreText == null || scoreBG == null || diffText == null)
			return;

		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.setGraphicSize(Std.int(FlxG.width - scoreText.x + 6), Std.int(scoreText.height + 8));
		scoreBG.updateHitbox();
		scoreBG.x = FlxG.width - scoreBG.width;
		scoreBG.y = 0;

		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2));
		diffText.y = scoreText.y + scoreText.height + 2;
	}

	function updateTexts(elapsed:Float = 0.0)
	{
		if (grpSongs == null || songs.length < 1)
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

			item.screenCenter(X);
			item.x += 60;

			if (i < iconArray.length && iconArray[i] != null)
				iconArray[i].visible = iconArray[i].active = true;
			_lastVisibles.push(i);
		}
	}

	function returnToFreeplay():Void
	{
		Paths.songAudioRoot = null;
		Difficulty.resetList();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new FreeplayMenuState());
	}

	function showChartError(song:ExtraSongData, diff:String, expected:String):Void
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		trace('[ExtraSongs] Chart not found: ${song.songName} [$diff] -> $expected');

		var errTxt:FlxText = new FlxText(0, FlxG.height - 66, FlxG.width,
			'Chart not found: ${song.songName} [$diff]\nExpected: assets/data/extra-songs/<song>/<song>-${diff}-extra.json', 16);
		errTxt.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errTxt.scrollFactor.set();
		add(errTxt);
		FlxTween.tween(errTxt, {alpha: 0}, 3, {
			startDelay: 2,
			onComplete: function(_) errTxt.destroy()
		});
	}

	static function tryGetText(relative:String):Null<String>
	{
		try
		{
			#if sys
			var shared:String = Paths.getSharedPath(relative);
			if (FileSystem.exists(shared))
				return File.getContent(shared);
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var modPath:String = Paths.mods(Mods.currentModDirectory + '/' + relative);
				if (FileSystem.exists(modPath))
					return File.getContent(modPath);
			}
			#end
			if (openfl.utils.Assets.exists(relative))
				return openfl.utils.Assets.getText(relative);
		}
		catch (e:Dynamic) {}
		return null;
	}

	static function readText(path:String):Null<String>
	{
		#if sys
		if (FileSystem.exists(path))
			return File.getContent(path);
		#end
		try
		{
			if (openfl.utils.Assets.exists(path))
				return openfl.utils.Assets.getText(path);
		}
		catch (e:Dynamic) {}
		return null;
	}

	static function normalizeDiffs(raw:Array<String>):Array<String>
	{
		var diffs:Array<String> = [];
		for (diff in raw)
		{
			var clean:String = diff.trim();
			if (clean.length > 0 && !containsDiff(diffs, clean))
				diffs.push(clean);
		}
		if (diffs.length < 1)
			diffs.push('pico');
		return diffs;
	}

	static function containsDiff(diffs:Array<String>, diff:String):Bool
	{
		var clean:String = Paths.formatToSongPath(diff);
		for (existing in diffs)
			if (Paths.formatToSongPath(existing) == clean)
				return true;
		return false;
	}

	function hasSong(pathName:String):Bool
	{
		var clean:String = Paths.formatToSongPath(pathName);
		for (song in songs)
			if (song.pathName == clean)
				return true;
		return false;
	}

	static function colorFromPathName(pathName:String):Int
	{
		var hue:Float = 0;
		for (i in 0...pathName.length)
		{
			hue = hue * 31 + pathName.charCodeAt(i);
			hue -= Math.floor(hue / 360) * 360;
		}
		return FlxColor.fromHSB(hue, 0.65, 0.75);
	}

	static function normalizeFolder(folder:Null<String>):Null<String>
	{
		return (folder == null || folder.length < 1) ? null : folder;
	}

	override function destroy():Void
	{
		// Don't clear songAudioRoot here if we just switched to PlayState —
		// PlayState still needs it. Only clear when returning to freeplay menu.
		super.destroy();
	}
}

class ExtraSongData
{
	public var songName:String = "";
	public var pathName:String = "";
	public var songCharacter:String = "";
	public var color:Int = -1;
	public var folder:String = "";
	public var diffs:Array<String> = ["pico"];

	public function new(songName:String, pathName:String, songCharacter:String, color:Int, ?diffs:Array<String>, ?folder:String)
	{
		this.songName = songName;
		this.pathName = pathName;
		this.songCharacter = (songCharacter != null && songCharacter.length > 0) ? songCharacter : 'face';
		this.color = color;
		this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['pico'];
		this.folder = folder ?? (Mods.currentModDirectory ?? '');
	}
}
