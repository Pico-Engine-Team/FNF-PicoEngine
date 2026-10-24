package funkin.play;

class Difficulty
{
	public static final defaultList:Array<String> = ['Easy', 'Normal', 'Hard'];
	public static final defaultVariationList:Array<String> = ['Erect', 'Nightmare', 'Erect Remix', 'Nightmare Remix', 'Remix', 'Legacy', 'Neo'];
	public static final defaultCharacterVariationList:Array<String> = ['Pico', 'Pico Legacy', 'BF', 'BF Legacy', 'GF', 'GF Legacy', 'Darnell', 'Darnell legacy', 'Nene', 'Nene Legacy', 'Spooky', 'Spooky Legacy', 'Agoti', 'Agoti Legacy'];

	private static final defaultDifficulty:String = 'Normal';
	public static var list:Array<String> = defaultList.copy();
	public static var variationList:Array<String> = defaultVariationList.copy();
	public static var characterVariationList:Array<String> = defaultCharacterVariationList.copy();

	inline public static function getFilePath(?num:Null<Int>):String
	{
		var diff:String = getRaw(num);

		if (sameDifficulty(diff, defaultDifficulty))
			return '';

		return getSuffixFilePath(getChartSuffixName(diff));
	}

	inline public static function getSuffixName(?value:String):String
	{
		if (value == null)
			return '';
		var trimmed:String = value.trim();
		if(trimmed.length < 1)
			return '';

		var clean:String = Paths.formatToSongPath(trimmed);
		while (clean.startsWith('-'))
			clean = clean.substr(1);
		while (clean.endsWith('-'))
			clean = clean.substr(0, clean.length - 1);

		return clean;
	}

	inline public static function getSuffixFilePath(?value:String):String
	{
		var clean:String = getSuffixName(value);
		return clean.length > 0 ? '-$clean' : '';
	}

	/**
	 * Chart variation suffix only (e.g. "pico" → "-pico").
	 * Does NOT strip character-named variations (Pico/BF/…) — valid chart_Variations ids.
	 */
	inline public static function getVariationFilePath(?variation:String):String
	{
		return getSuffixFilePath(variation);
	}

	/**
	 * Combined chart file suffix for variation + difficulty.
	 *
	 * With variation "pico" + difficulty Normal/Easy/Hard:
	 *   → "-pico-normal" / "-pico-easy" / "-pico-hard"
	 *   charts: dad-battle-pico-normal.json, dad-battle-pico-easy.json, …
	 *
	 * Without variation: same as getFilePath (Normal → "", Easy → "-easy", …).
	 */
	public static function getVariationAndDifficultyFilePath(?variation:String, ?num:Null<Int>):String
	{
		var varPart:String = getSuffixName(variation);
		if(varPart == 'default' || varPart == 'none')
			varPart = '';

		if(varPart.length > 0)
		{
			// Always include difficulty name when a variation is active
			var diffPart:String = getSuffixName(getRaw(num));
			if(diffPart.length < 1)
				diffPart = getSuffixName(defaultDifficulty); // "normal"
			if(diffPart.length < 1)
				diffPart = 'normal';
			return '-' + varPart + '-' + diffPart;
		}

		return getFilePath(num);
	}

	public static function getChartSuffixName(?value:String):String
	{
		var clean:String = getSuffixName(value);
		if (clean.length < 1 || sameDifficulty(clean, defaultDifficulty))
			return '';

		if (isCharacterVariation(clean))
			return '';

		var parts:Array<String> = clean.split('-');
		if (parts.length > 1 && isCharacterVariation(parts[0]))
		{
			var suffix:String = getSuffixName(parts.slice(1).join('-'));
			return isVariationSuffix(suffix) ? suffix : '';
		}

		return clean;
	}

	public static function isCharacterVariation(?value:String):Bool
	{
		return isKnownVariation(value, characterVariationList, defaultCharacterVariationList);
	}

	public static function isVariationSuffix(?value:String):Bool
	{
		return isKnownVariation(value, variationList, defaultVariationList);
	}

	public static function isDefaultCharacterVariation(?value:String):Bool
	{
		return isListedVariation(value, defaultCharacterVariationList);
	}

	public static function isDefaultVariationSuffix(?value:String):Bool
	{
		return isListedVariation(value, defaultVariationList);
	}

	static function isKnownVariation(?value:String, list:Array<String>, defaultValues:Array<String>):Bool
	{
		return isListedVariation(value, list) || isListedVariation(value, defaultValues);
	}

	static function isListedVariation(?value:String, list:Array<String>):Bool
	{
		var clean:String = getSuffixName(value);
		if (clean.length < 1)
			return false;

		for (variation in list)
			if (sameDifficulty(clean, variation))
				return true;

		return false;
	}

	/**
	 * Week files no longer store difficulties (meta.json owns that).
	 * Always resets to the engine default list.
	 * Prefer FreeplaySongData / SongMeta difficulties when available.
	 */
	public static function loadFromWeek(?week:funkin.data.WeekData, ?freeplay:Bool = false):Void
	{
		// Legacy week.difficulties / storyDifficulties / freeplayDifficulties removed.
		// Use default list; callers with meta should call Difficulty.copyFrom(metaDiffs).
		resetList();
	}

	inline public static function resetList():Void
	{
		list = defaultList.copy();
	}

	inline public static function copyFrom(diffs:Array<String>):Void
	{
		if(diffs == null || diffs.length < 1)
			list = defaultList.copy();
		else
			list = diffs.copy();
	}

	inline public static function getDifficultyVariationName(?num:Null<Int>):String
	{
		return getChartSuffixName(getRaw(num));
	}

	inline public static function getString(?num:Null<Int>, ?canTranslate:Bool = true):String
	{
		var diff:String = getRaw(num);
		return canTranslate ? Language.getPhrase('difficulty_$diff', diff) : diff;
	}

	inline public static function getDefault():String
	{
		return defaultDifficulty;
	}

	inline private static function getRaw(?num:Null<Int>):String
	{
		if(list == null || list.length < 1)
			return defaultDifficulty;
		var index:Int = num == null ? PlayState.storyDifficulty : num;
		if(index < 0) index = 0;
		if(index >= list.length) index = list.length - 1;
		var diff:String = list[index];

		return diff == null || diff.length < 1 ? defaultDifficulty : diff;
	}

	inline private static function sameDifficulty(a:String, b:String):Bool
	{
		return Paths.formatToSongPath(a) == Paths.formatToSongPath(b);
	}
}