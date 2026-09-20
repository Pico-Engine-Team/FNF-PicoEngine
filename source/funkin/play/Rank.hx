package funkin.play;

/**
 * Accuracy + Rank system.
 *
 * Rank ladder (highest first):
 *   P+  100%
 *   P   97%
 *   S   95%
 *   A   90%
 *   B   80%
 *   C   70%
 *   E   0%
 *
 * HUD style:
 *   Accuracy (98.5% P+)
 *
 * Freeplay box:
 *   HIGHSCORE: 12345 [P+]
 *   MISSES: 0
 */
class Rank
{
	/**
	 * [rankName, minAccuracy]  (0.0 - 1.0, highest first)
	 * No FC suffixes — rank letter only.
	 */
	public static var ratingStuff:Array<Dynamic> = [
		['P+', 1.0],
		['P',  0.97],
		['S',  0.95],
		['A',  0.90],
		['B',  0.80],
		['C',  0.70],
		['E',  0.0]
	];

	/** Letter rank from accuracy (0.0 - 1.0). Empty/invalid → N/A */
	public static function getRank(accuracy:Float, ?misses:Int = -1, ?fullCombo:Bool = false):String
	{
		if (accuracy < 0 || Math.isNaN(accuracy))
			return 'N/A';

		if (accuracy <= 0)
			return 'N/A';

		var clamped:Float = Math.max(0, Math.min(1, accuracy));
		var rank:String = 'E';

		for (i in 0...ratingStuff.length)
		{
			var entry:Dynamic = ratingStuff[i];
			var name:String = Std.string(entry[0]);
			var minAcc:Float = Std.parseFloat(Std.string(entry[1]));
			if (Math.isNaN(minAcc)) minAcc = 0;
			if (clamped >= minAcc)
			{
				rank = name;
				break;
			}
		}

		// FC removed — only the rank letter
		return rank;
	}

	public static function getRatingName(accuracy:Float):String
	{
		return getRank(accuracy);
	}

	public static function formatAccuracy(accuracy:Float, decimals:Int = 2):String
	{
		if (accuracy < 0 || Math.isNaN(accuracy))
			return '0';

		var percent:Float = Math.max(0, Math.min(1, accuracy)) * 100;
		var factor:Float = Math.pow(10, decimals);
		var value:Float = Math.floor(percent * factor) / factor;
		return Std.string(value);
	}

	/**
	 * HUD Accuracy block: Accuracy (98.5% P+)
	 */
	public static function formatAccuracyWithRank(accuracy:Float, ?misses:Int = -1):String
	{
		var accStr:String = formatAccuracy(accuracy);
		var rank:String = getRank(accuracy, misses);
		return 'Accuracy (' + accStr + '% ' + rank + ')';
	}

	/**
	 * Freeplay score box:
	 * HIGHSCORE: 12345 [P+]
	 * MISSES: 0
	 */
	public static function formatFreeplayBox(score:Int, accuracy:Float, misses:Int, ?difficulty:String = null):String
	{
		var rank:String = (score <= 0 && (accuracy <= 0 || Math.isNaN(accuracy))) ? 'N/A' : getRank(accuracy, misses);
		var missStr:String = Std.string(Std.int(Math.max(0, misses)));

		var text:String = 'HIGHSCORE: ' + score + ' [' + rank + ']\n'
			+ 'MISSES: ' + missStr;

		if(difficulty != null && difficulty.trim().length > 0)
			text += '\n' + difficulty.trim();

		return text;
	}

	public static function formatShort(accuracy:Float, ?misses:Int = -1):String
	{
		return formatAccuracy(accuracy) + '% ' + getRank(accuracy, misses);
	}

	public static function getRankColor(rank:String):Int
	{
		var clean:String = rank;
		if (clean.indexOf(' ') > -1)
			clean = clean.split(' ')[0];
		// strip accidental (FC) if old data remains
		if (clean.indexOf('(') > -1)
			clean = clean.split('(')[0].trim();

		return switch (clean)
		{
			case 'P+': 0xFFFF66FF;
			case 'P':  0xFFFF99FF;
			case 'S':  0xFFFFFF00;
			case 'A':  0xFF00FF88;
			case 'B':  0xFF66B2FF;
			case 'C':  0xFFFFAA00;
			case 'E':  0xFFFF3333;
			case 'N/A': 0xFFAAAAAA;
			default:   0xFFFFFFFF;
		};
	}

	/**
	 * PlayState.RecalculateRating → ratingName
	 * Rank letter only (no FC).
	 */
	public static function applyToPlayState(accuracy:Float, songMisses:Int = 0):String
	{
		return getRank(accuracy, songMisses, false);
	}
}
