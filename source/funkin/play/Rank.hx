package funkin.play;

/**
 * Accuracy + Rank system.
 *
 * Rank ladder (V-Slice style, highest first):
 *   P+  100%
 *   P    90%
 *   E    80%
 *   G    70%
 *   L    60% and below
 *
 * HUD style:
 *   Accuracy (98.5% P+)
 *
 * Freeplay box:
 *   Score / Accuracy / Rank / Misses
 *   MISSES: 0
 */
class Rank
{
	/**
	 * V-Slice style rank ladder (highest first):
	 *   P+  100%
	 *   P    90%
	 *   E    80%
	 *   G    70%
	 *   L    60% and below (covers 60/50/40/30/20/10)
	 * No FC suffixes — rank letter only.
	 */
	public static var ratingStuff:Array<Dynamic> = [
		['P+', 1.0],
		['P',  0.90],
		['E',  0.80],
		['G',  0.70],
		['L',  0.0]
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
	 * Freeplay score box (multi-line):
	 *   Score: 2,000
	 *   Accuracy: (100%)
	 *   Rank: P+
	 *   Misses: 0
	 *   [Tab] Opponent Mod
	 *   < Hard > (Pico)
	 */
	public static function formatFreeplayBox(score:Int, accuracy:Float, misses:Int, ?difficulty:String = null, ?showOpponentMod:Bool = true):String
	{
		var noPlay:Bool = (score <= 0 && (accuracy <= 0 || Math.isNaN(accuracy)));
		var rank:String = noPlay ? 'N/A' : getRank(accuracy, misses);
		var missStr:String = Std.string(Std.int(Math.max(0, misses)));
		var accStr:String = '0';
		if(!noPlay)
		{
			var pct:Float = Math.max(0, Math.min(1, accuracy)) * 100;
			if(Math.abs(pct - Math.round(pct)) < 0.05)
				accStr = Std.string(Math.round(pct));
			else
				accStr = formatAccuracy(accuracy, 1);
		}

		var text:String = 'Score: ' + formatScoreComma(score) + '\n'
			+ 'Accuracy: (' + accStr + '%)\n'
			+ 'Rank: ' + rank + '\n'
			+ 'Misses: ' + missStr;

		// Opponent Mod hint / status line
		if(showOpponentMod)
			text += '\n[Tab] Opponent Mod';

		if(difficulty != null && difficulty.trim().length > 0)
			text += '\n' + difficulty.trim();

		return text;
	}


	/** 2000 → "2,000" */
	public static function formatScoreComma(score:Int):String
	{
		var n:Int = score;
		var neg:Bool = n < 0;
		if(neg) n = -n;
		var s:String = Std.string(n);
		var out:String = '';
		var i:Int = s.length;
		while(i > 3)
		{
			out = ',' + s.substr(i - 3, 3) + out;
			i -= 3;
		}
		out = s.substr(0, i) + out;
		return neg ? ('-' + out) : out;
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
			case 'P+': 0xFFFF66FF; // Perfect+
			case 'P':  0xFFFF99FF; // Perfect
			case 'E':  0xFFFFFF00; // Excellent
			case 'G':  0xFF00FF88; // Great
			case 'L':  0xFFFF3333; // Low / Loss
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
