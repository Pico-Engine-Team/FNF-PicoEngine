package funkin.states.options.data;

import funkin.states.options.config.*;

class PicoEngineSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase("pico_menu", "Pico Engine Settings");
		rpcTitle = "Pico Engine Settings Menu";

		var option:Option = new Option('Characters Note Skins',
			"If checked, Enables NoteSkins In Songs (Character Specific)",
			'useNoteSkins',
			STRING,
			['Disabled', 'Both', 'Player', 'Opponent']);
		addOption(option);

		var option:Option = new Option('Max Combo',
			'Enable/Disable,\nMax Combo on the game screen.',
			'useCombo',
			BOOL);
		addOption(option);

		var option:Option = new Option('V Slice Hub',
			'If checked, uses the V-Slice styled HUD and health bar.',
			'SliceHub',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hold Note Covers',
			'If checked,\nThe Hold Note Covers did not appear.',
			'useHoldCover',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hold Note Animation',
			'If checked,\nDuring a sustained note the character will not play an animation for it.',
			'useHoldAnimation',
			BOOL);
		addOption(option);

		// ===== DEV / PERFORMANCE =====
		var option:Option = new Option('Dev Mode',
			'Shows extra debug info (memory, cache sizes, load times).\nAlso enables developer traces in the console.',
			'devMode',
			BOOL);
		addOption(option);

		var option:Option = new Option('Show Memory',
			'Display current RAM usage next to the FPS counter.',
			'showMemory',
			BOOL);
		addOption(option);

		var option:Option = new Option('Clear Memory On Song Load',
			'Frees unused graphics/sounds when entering a song.\nReduces lag spikes from full RAM, slightly slower first load.',
			'clearMemoryOnSongLoad',
			BOOL);
		addOption(option);

		var option:Option = new Option('Clear Memory On Exit Song',
			'Frees song assets when leaving PlayState.\nHelps prevent Psych-style memory leaks / engine feeling laggy over time.',
			'clearMemoryOnExitSong',
			BOOL);
		addOption(option);

		var option:Option = new Option('Aggressive Memory Cleanup',
			'More aggressive cache dumping (good for low RAM).\nMay cause more reloads of images between menus.',
			'aggressiveMemory',
			BOOL);
		addOption(option);

		var option:Option = new Option('Auto GC Interval (sec)',
			'How often to run a soft garbage collection while in menus (0 = off).\nHelps long sessions without full restart.',
			'autoGcInterval',
			INT);
		option.minValue = 0;
		option.maxValue = 300;
		option.changeValue = 15;
		option.displayFormat = '%vs';
		addOption(option);

		super();
	}
}
