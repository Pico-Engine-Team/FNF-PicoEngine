package funkin.states.options;

class OptionsMenuState extends MusicBeatState
{
	var options:Array<String> = [
	'Note Colors',
	'Controls',
	'Adjust Delay and Combo',
	'Graphics',
	'Visuals',
	'Gameplay', 
	#if PICO_ALLOWED 'Pico Engine', #end
	#if TRANSLATIONS_ALLOWED  'Language' #end
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String)
	{
		switch(label)
		{
			case 'Note Colors': openSubState(new funkin.states.options.data.NotesColorSubState());
			case 'Controls': openSubState(new funkin.states.options.data.ControlsSubState());
			case 'Graphics': openSubState(new funkin.states.options.data.GraphicsSettingsSubState());
			case 'Visuals': openSubState(new funkin.states.options.data.VisualsSettingsSubState());
			case 'Gameplay': openSubState(new funkin.states.options.data.GameplaySettingsSubState());
			case 'Adjust Delay and Combo': MusicBeatState.switchState(new funkin.states.options.data.NoteOffsetState());
			case 'Language': openSubState(new funkin.translations.options.LanguageSubState());
			case 'Pico Engine': openSubState(new funkin.states.options.data.PicoEngineSubState());
		}
	}
 
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options) {
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.screenCenter();
			optionText.y += (92 * (num - (options.length / 2))) + 45;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		changeSelection();
		ClientPrefs.saveSettings();
		FlxG.sound.playMusic(Paths.music('options/OptionSongMenu'));
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				funkin.stages.StageData.loadDirectory(PlayState.SONG);
				LoadingScreenState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
			{
				// Stop current menu (options) music and play the main menu music
				FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				MusicBeatState.switchState(new funkin.states.menus.MainMenuState());
			}
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy() {
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
