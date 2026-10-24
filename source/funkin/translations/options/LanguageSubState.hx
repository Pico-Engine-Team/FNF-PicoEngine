package funkin.translations.options;

import openfl.utils.Assets;
using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class LanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
	var grpLanguages:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;
	var changedLanguage:Bool = false;

	public function new()
	{
		super();

		var bg = new FlxSprite();
		try
		{
			bg.loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		}
		catch (e:Dynamic)
		{
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFFea71fd);
		}
		bg.color = 0xFFea71fd;
		try
		{
			if (Preferences.data != null)
				bg.antialiasing = Preferences.data.antialiasing;
		}
		catch (e:Dynamic) {}
		bg.screenCenter();
		add(bg);
		add(grpLanguages);

		var defaultLang:String = 'en-US';
		try
		{
			if (Preferences.defaultData != null && Preferences.defaultData.language != null)
				defaultLang = Preferences.defaultData.language;
		}
		catch (e:Dynamic) {}

		languages.push(defaultLang);
		displayLanguages.set(defaultLang, Language.defaultLangName);

		var directories:Array<String> = [];
		try
		{
			directories = Mods.directoriesWithFile(Paths.getSharedPath(), 'language/');
		}
		catch (e:Dynamic)
		{
			directories = [];
		}
		if (directories == null) directories = [];

		for (directory in directories)
		{
			if (directory == null) continue;
			#if sys
			var files:Array<String> = [];
			try
			{
				if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
					files = FileSystem.readDirectory(directory);
			}
			catch (e:Dynamic)
			{
				files = [];
			}
			for (file in files)
			{
				if (file == null) continue;
				if (file.toLowerCase().endsWith('.lang'))
				{
					var langFile:String = file.substring(0, file.length - '.lang'.length).trim();
					if (langFile.length < 1) continue;
					if (!languages.contains(langFile))
						languages.push(langFile);

					if (!displayLanguages.exists(langFile))
					{
						var path:String = directory + (directory.endsWith('/') || directory.endsWith('\\') ? '' : '/') + file;
						var txt:String = '';
						try
						{
							if (FileSystem.exists(path))
								txt = File.getContent(path);
							else
								txt = Assets.getText(path);
						}
						catch (e:Dynamic)
						{
							try { txt = Assets.getText(path); } catch (e2:Dynamic) { txt = ''; }
						}
						if (txt == null) txt = '';

						var id:Int = txt.indexOf('\n');
						if (id > 0)
						{
							var name:String = txt.substr(0, id).trim();
							if (name.length > 0 && !name.contains(':'))
								displayLanguages.set(langFile, name);
						}
						else if (txt.trim().length > 0 && !txt.contains(':'))
						{
							displayLanguages.set(langFile, txt.trim());
						}
					}
				}
			}
			#end
		}

		languages.sort(function(a:String, b:String)
		{
			var aa:String = (displayLanguages.exists(a) ? displayLanguages.get(a) : a);
			var bb:String = (displayLanguages.exists(b) ? displayLanguages.get(b) : b);
			if (aa == null) aa = '';
			if (bb == null) bb = '';
			aa = aa.toLowerCase();
			bb = bb.toLowerCase();
			if (aa < bb) return -1;
			else if (aa > bb) return 1;
			return 0;
		});

		var currentLang:String = defaultLang;
		try
		{
			if (Preferences.data != null && Preferences.data.language != null)
				currentLang = Preferences.data.language;
		}
		catch (e:Dynamic) {}

		curSelected = languages.indexOf(currentLang);
		if (curSelected < 0)
		{
			try
			{
				if (Preferences.data != null)
					Preferences.data.language = defaultLang;
			}
			catch (e:Dynamic) {}
			curSelected = languages.indexOf(defaultLang);
			if (curSelected < 0) curSelected = 0;
		}

		for (num => lang in languages)
		{
			var name:String = displayLanguages.get(lang);
			if (name == null || name.length < 1) name = lang;
			if (name == null) name = 'Unknown';

			var text:Alphabet = new Alphabet(0, 300, name, true);
			text.isMenuItem = true;
			text.targetY = num;
			text.changeX = false;
			text.distancePerItem.y = 100;
			if (languages.length < 7)
			{
				text.changeY = false;
				text.screenCenter(Y);
				text.y += (100 * (num - (languages.length / 2))) + 45;
			}
			text.screenCenter(X);
			grpLanguages.add(text);
		}
		changeSelected();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls == null) return;

		var mult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
		if (controls.UI_UP_P)
			changeSelected(-1 * mult);
		if (controls.UI_DOWN_P)
			changeSelected(1 * mult);
		if (FlxG.mouse != null && FlxG.mouse.wheel != 0)
			changeSelected(FlxG.mouse.wheel * mult);

		if (controls.BACK)
		{
			if (changedLanguage)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.resetState();
			}
			else close();
			try { FlxG.sound.play(Paths.sound('cancelMenu')); } catch (e:Dynamic) {}
		}

		if (controls.ACCEPT && languages.length > 0)
		{
			try { FlxG.sound.play(Paths.sound('confirmMenu'), 0.6); } catch (e:Dynamic) {}
			if (curSelected >= 0 && curSelected < languages.length)
			{
				try
				{
					if (Preferences.data != null)
						Preferences.data.language = languages[curSelected];
					Preferences.saveSettings();
				}
				catch (e:Dynamic) {}
				Language.reloadPhrases();
				changedLanguage = true;
			}
		}
	}

	function changeSelected(change:Int = 0)
	{
		if (languages == null || languages.length < 1) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);
		for (num => lang in grpLanguages)
		{
			lang.targetY = num - curSelected;
			lang.alpha = 0.6;
			if (num == curSelected) lang.alpha = 1;
		}
		try { FlxG.sound.play(Paths.sound('scrollMenu'), 0.6); } catch (e:Dynamic) {}
	}
	#else
	public function new()
	{
		super();
		close();
	}
	#end
}
