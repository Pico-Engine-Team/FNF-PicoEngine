package funkin.play;

import funkin.data.WeekData;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, Float> = new Map<String, Float>();
	public static var songMisses:Map<String, Int> = new Map<String, Int>();
	public static var songDeaths:Map<String, Int> = new Map<String, Int>();
	public static inline var OPPONENT_SUFFIX:String = '-opponent'; /** Suffix used in save keys for Opponent Mode scores */

	public static function resetSong(song:String, diff:Int = 0, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Void
	{
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);
		setScore(daSong, 0);
		setRating(daSong, 0);
		setMisses(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0, ?weekData:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Void
	{
		var daWeek:String = formatScore(week, diff, null, weekData, freeplay, opponentMode);
		setWeekScore(daWeek, 0);
	}

	/**
	 * Saves score/rating/misses. Opponent Mode uses a separate key (…-opponent).
	 */
	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false, ?misses:Int = -1):Void
	{
		if(song == null) return;
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);

		var improved:Bool = !songScores.exists(daSong) || songScores.get(daSong) < score;
		if (improved)
		{
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
			if(misses >= 0) setMisses(daSong, misses);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0, ?weekData:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Void
	{
		var daWeek:String = formatScore(week, diff, null, weekData, freeplay, opponentMode);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else setWeekScore(daWeek, score);
	}

	static function setScore(song:String, score:Int):Void
	{
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	static function setMisses(song:String, misses:Int):Void
	{
		songMisses.set(song, misses);
		FlxG.save.data.songMisses = songMisses;
		FlxG.save.flush();
	}

	static function setDeaths(song:String, deaths:Int):Void
	{
		songDeaths.set(song, deaths);
		FlxG.save.data.songDeaths = songDeaths;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):String
	{
		return formatScore(song, diff, variation, week, freeplay, opponentMode);
	}

	/**
	 * Builds the save key. Opponent Mode appends "-opponent" so scores never mix with normal play.
	 * Example: "bopeebo-hard" vs "bopeebo-hard-opponent"
	 */
	public static function formatScore(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):String
	{
		loadDifficultyListForMode(week, freeplay);

		var daSong:String = Paths.formatToSongPath(song);
		var difficultyVariation:String = Difficulty.getDifficultyVariationName(diff);
		if(difficultyVariation.length > 0)
			daSong = appendSuffix(daSong, Difficulty.getVariationFilePath(difficultyVariation));
		else
		{
			daSong = appendSuffix(daSong, Difficulty.getVariationFilePath(variation));
			daSong = appendSuffix(daSong, Difficulty.getFilePath(diff));
		}

		if(opponentMode)
			daSong = appendSuffix(daSong, OPPONENT_SUFFIX);

		return daSong;
	}

	public static function getScore(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Int
	{
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Float
	{
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);
		if (!songRating.exists(daSong))
			setRating(daSong, 0);

		return songRating.get(daSong);
	}

	public static function getMisses(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Int
	{
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);
		if (!songMisses.exists(daSong))
			setMisses(daSong, 0);

		return songMisses.get(daSong);
	}

	public static function getDeaths(song:String, diff:Int, ?variation:String = null, ?week:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Int
	{
		var daSong:String = formatScore(song, diff, variation, week, freeplay, opponentMode);
		if (!songDeaths.exists(daSong))
			setDeaths(daSong, 0);

		return songDeaths.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int, ?weekData:WeekData = null, ?freeplay:Bool = false, ?opponentMode:Bool = false):Int
	{
		var daWeek:String = formatScore(week, diff, null, weekData, freeplay, opponentMode);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	/** Reads current Opponent Mode gameplay setting (same keys as PlayState). */
	public static function isOpponentModeSettingOn():Bool
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

	static function loadDifficultyListForMode(?week:WeekData, ?freeplay:Bool = false):Void
	{
		if(week != null)
			Difficulty.loadFromWeek(week, freeplay);
	}

	static function appendSuffix(value:String, suffix:String):String
	{
		if(value == null) value = '';
		if(suffix == null || suffix.length < 1 || value.endsWith(suffix))
			return value;
		return value + suffix;
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
			weekScores = FlxG.save.data.weekScores;

		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;

		if (FlxG.save.data.songRating != null)
			songRating = FlxG.save.data.songRating;

		if (FlxG.save.data.songMisses != null)
			songMisses = FlxG.save.data.songMisses;

		if (FlxG.save.data.songDeaths != null)
			songDeaths = FlxG.save.data.songDeaths;
	}
}