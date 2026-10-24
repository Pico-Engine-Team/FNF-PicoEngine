package funkin.translations;

using StringTools;

class Language
{
	public static var defaultLangName:String = 'United States (USA)';
	#if TRANSLATIONS_ALLOWED
	private static var phrases:Map<String, String> = [];
	#end

	public static function reloadPhrases()
	{
		#if TRANSLATIONS_ALLOWED
		var langFile:String = null;
		try
		{
			if (Preferences.data != null)
				langFile = Preferences.data.language;
		}
		catch (e:Dynamic) {}

		if (langFile == null || langFile.length < 1)
		{
			try
			{
				if (Preferences.defaultData != null)
					langFile = Preferences.defaultData.language;
			}
			catch (e:Dynamic) {}
		}
		if (langFile == null || langFile.length < 1)
			langFile = 'en-US';

		var loadedText:Array<String> = [];
		try
		{
			loadedText = Mods.mergeAllTextsNamed('language/' + langFile + '.lang');
		}
		catch (e:Dynamic)
		{
			loadedText = [];
		}
		if (loadedText == null) loadedText = [];

		phrases.clear();
		var hasPhrases:Bool = false;
		for (num => phrase in loadedText)
		{
			if (phrase == null) continue;
			phrase = phrase.trim();
			if (num < 1 && !phrase.contains(':'))
			{
				// First line ignores formatting if the line doesn't have ":" because its language_name
				phrases.set('language_name', phrase);
				continue;
			}

			if (phrase.length < 4 || phrase.startsWith('//')) continue;

			var n:Int = phrase.indexOf(':');
			if (n < 0) continue;

			var key:String = phrase.substr(0, n).trim().toLowerCase();
			if (key.length < 1) continue;

			var value:String = phrase.substr(n);
			n = value.indexOf('"');
			if (n < 0) continue;

			var endQuote:Int = value.lastIndexOf('"');
			if (endQuote <= n) continue;

			phrases.set(key, value.substring(n + 1, endQuote).replace('\\n', '\n'));
			hasPhrases = true;
		}

		if (!hasPhrases)
		{
			try
			{
				if (Preferences.data != null && Preferences.defaultData != null)
					Preferences.data.language = Preferences.defaultData.language;
			}
			catch (e:Dynamic) {}
		}

		var alphaPath:String = getFileTranslation('images/alphabet');
		if (alphaPath == null) alphaPath = '';
		if (alphaPath.startsWith('images/')) alphaPath = alphaPath.substr('images/'.length);
		var pngPos:Int = alphaPath.toLowerCase().indexOf('.png');
		if (pngPos > -1) alphaPath = alphaPath.substring(0, pngPos);
		try
		{
			AlphaCharacter.loadAlphabetData(alphaPath);
		}
		catch (e:Dynamic)
		{
			try { AlphaCharacter.loadAlphabetData(); } catch (e2:Dynamic) {}
		}
		#else
		try { AlphaCharacter.loadAlphabetData(); } catch (e:Dynamic) {}
		#end
	}

	inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
	{
		#if TRANSLATIONS_ALLOWED
		var str:String = null;
		if (key != null && phrases != null)
			str = phrases.get(formatKey(key));
		if (str == null) str = defaultPhrase;
		#else
		var str:String = defaultPhrase;
		#end

		if (str == null)
			str = key != null ? key : '';

		if (values != null)
		{
			for (num => value in values)
			{
				var token:String = '{' + (num + 1) + '}';
				str = str.replace(token, value != null ? Std.string(value) : '');
			}
		}

		return str;
	}

	inline public static function getFileTranslation(key:String)
	{
		if (key == null) return '';
		#if TRANSLATIONS_ALLOWED
		var str:String = null;
		if (phrases != null)
			str = phrases.get(key.trim().toLowerCase());
		if (str != null) key = str;
		#end
		return key;
	}

	#if TRANSLATIONS_ALLOWED
	inline static private function formatKey(key:String)
	{
		if (key == null) return '';
		final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
		return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		if (lua == null) return;
		Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null) {
			return getPhrase(key, defaultPhrase, values);
		});

		Lua_helper.add_callback(lua, "getFileTranslation", function(key:String) {
			return getFileTranslation(key);
		});
	}
	#end
}
