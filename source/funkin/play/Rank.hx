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
		var rank:String = 'L';

		for (i in 0...ratingStuff.length)
		{
			var entry:Dynamic = ratingStuff[i];
			if(entry == null) continue;
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
	 * Freeplay score line (Psych-style + Rank):
	 *   Score: 0 (0.00, E)
	 * Difficulty stays on diffText below scoreBG.
	 */
	public static function formatFreeplayBox(score:Int, accuracy:Float, misses:Int, ?difficulty:String = null, ?showOpponentMod:Bool = true):String
	{
		return formatFreeplayScoreLine(score, accuracy, misses);
	}

	/**
	 * Single-line freeplay highscore (Psych PERSONAL BEST layout + Rank).
	 * Example: Score: 12,345 (98.50, P+)
	 */
	public static function formatFreeplayScoreLine(score:Int, accuracy:Float, ?misses:Int = -1):String
	{
		var noPlay:Bool = (score <= 0 && (accuracy <= 0 || Math.isNaN(accuracy)));
		var rank:String = noPlay ? 'E' : getRank(accuracy, misses);
		if (noPlay)
			rank = 'E';

		// Accuracy like Psych: always 2 decimals (0.00)
		var accStr:String = '0.00';
		if (!noPlay && accuracy > 0 && !Math.isNaN(accuracy))
		{
			var pct:Float = Math.max(0, Math.min(1, accuracy)) * 100;
			var factor:Float = 100;
			var value:Float = Math.floor(pct * factor + 0.00001) / factor;
			accStr = Std.string(value);
			// ensure two decimals
			if (accStr.indexOf('.') < 0)
				accStr += '.00';
			else
			{
				var parts = accStr.split('.');
				while (parts[1].length < 2)
					parts[1] += '0';
				if (parts[1].length > 2)
					parts[1] = parts[1].substr(0, 2);
				accStr = parts[0] + '.' + parts[1];
			}
		}

		return 'Score: ' + formatScoreComma(score) + ' (' + accStr + ', ' + rank + ')';
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
