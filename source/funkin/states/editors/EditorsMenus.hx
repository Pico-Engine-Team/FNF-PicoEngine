package funkin.states.editors;

import funkin.data.WeekData;
import funkin.states.menus.freeplay.FreeplayMenuState;
import funkin.data.objects.game.characters.Character;

class EditorsMenus extends MusicBeatState
{
	private var options:Array<String> = ['Chart Editor', 'Character Editor', 'Stage Editor', 'Week Editor', 'Note Splash Editor', 'Dialogue Editor', 'Dialogue Portrait Editor', 'Menu Character Editor', 'Converters'];

	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null);
		#end
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xB7D855;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		
		#if MODS_ALLOWED
		if(controls.UI_LEFT_P)
		{
			changeDirectory(-1);
		}
		if(controls.UI_RIGHT_P)
		{
			changeDirectory(1);
		}
		#end

		if (controls.BACK)
		{
			MusicBeatState.switchState(new funkin.states.menus.MainMenuState());
		}
		if (controls.ACCEPT)
		{
			switch(options[curSelected])
			{
				case 'Chart Editor': LoadingScreenState.loadAndSwitchState(new funkin.states.editors.data.ChartingState(), false);
				case 'Character Editor': LoadingScreenState.loadAndSwitchState(new funkin.states.editors.data.CharacterEditorState(Character.DEFAULT_CHARACTER, false));
				case 'Stage Editor': LoadingScreenState.loadAndSwitchState(new funkin.states.editors.data.StageEditorState());
				case 'Week Editor': MusicBeatState.switchState(new funkin.states.editors.data.WeekEditorState());
				case 'Menu Character Editor': MusicBeatState.switchState(new funkin.states.editors.data.MenuCharacterEditorState());
				case 'Dialogue Editor': LoadingScreenState.loadAndSwitchState(new funkin.states.editors.data.DialogueEditorState(), false);
				case 'Dialogue Portrait Editor': LoadingScreenState.loadAndSwitchState(new funkin.states.editors.data.DialogueCharacterEditorState(), false);
				case 'Note Splash Editor': MusicBeatState.switchState(new funkin.states.editors.data.NoteSplashEditorState());
				case 'Converters': MusicBeatState.switchState(new funkin.states.ConvertersState());
			}
			FlxG.sound.music.volume = 0;
			FreeplayMenuState.destroyFreeplayVocals();
		}
		
		for (num => item in grpTexts.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if(curDirectory < 0)
			curDirectory = directories.length - 1;
		if(curDirectory >= directories.length)
			curDirectory = 0;
	
		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '< No Mod Directory Loaded >';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Mods.currentModDirectory + ' >';
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}
