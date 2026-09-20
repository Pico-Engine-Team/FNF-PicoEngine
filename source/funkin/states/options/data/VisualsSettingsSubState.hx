package funkin.states.options.data;

import funkin.states.PauseState;
import funkin.data.objects.Alphabet;

import funkin.utils.windows.Main;
import funkin.states.options.config.*;
import funkin.substates.MusicBeatSubstate;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu';

		// Migrate legacy time bar prefs
		var tb:String = ClientPrefs.data.timeBarType;
		if(tb == 'Time Left' || tb == 'Time Elapsed')
			ClientPrefs.data.timeBarType = 'Combined';

		var option:Option = new Option('Note Splash Opacity',
			'How much transparent should the Note Splashes be.',
			'splashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			BOOL);
		addOption(option);

		// Migrate legacy comboCam values
		var cc:String = Std.string(ClientPrefs.data.comboCam);
		switch(cc)
		{
			case 'camHUD', 'CamHUD', 'HUD', 'hud':
				ClientPrefs.data.comboCam = 'Combo HUD';
			case 'camGame', 'CamGame', 'Game', 'game':
				ClientPrefs.data.comboCam = 'Combo Game';
			case 'none', 'None', 'Off', 'off':
				ClientPrefs.data.comboCam = 'Disabled';
		}

		var option:Option = new Option('Combo Camera:',
			'Where combo / rank popup appears.\nCombo HUD = HUD camera (offsets apply).\nCombo Game = game camera (no HUD offsets).\nDisabled hides combo popup.',
			'comboCam',
			STRING,
			['Combo HUD', 'Combo Game', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Time Bar:',
			'What should the Time Bar display?\nDefault: elapsed / total (0:04 / 2:19).\nCombined: elapsed and time left (0:04 | 2:15).',
			'timeBarType',
			STRING,
			['Disabled', 'Default', 'Combined', 'Song Name', 'Percentage']);
		addOption(option);


		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Grow on Hit',
			"If unchecked, disables the Score text growing\neverytime you hit a note.",
			'scoreZoom',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		#if !mobile
		var option:Option = new Option('FPS Display:',
			"Show some debug info on the top left corner of the screen.\nThis includes FPS, Memory usage, Chart info and more.\nNote: Chart info will only be shown if you have at least the FPS only option enabled.",
			'fpsDisplay',
			STRING,
			['Disabled', 'FPS Only', 'FPS and Memory', 'Everything']);
		addOption(option);
		option.onChange = onChangeDebugDisplay;

		var option:Option = new Option('FPS Display BG',
			'How visible the background behind the FPS display should be.',
			'debugDisplayBG',
			PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		option.onChange = onChangeDebugDisplayBG;
		#end

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		super();
	}

	override function destroy()
	{
		super.destroy();
	}

	#if !mobile
	function onChangeDebugDisplay()
	{
		if(Main.fpsVar != null)
		{
			Main.fpsVar.visible = (ClientPrefs.data.fpsDisplay != 'Disabled');
			Main.fpsVar.updateDebugType(ClientPrefs.data.fpsDisplay);
		}
	}

	function onChangeDebugDisplayBG()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.updateBackgroundAlpha(ClientPrefs.data.debugDisplayBG);
	}
	#end
}
