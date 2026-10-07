package funkin.states.editors.data;

import funkin.play.Difficulty;
import funkin.data.WeekData;
import funkin.data.objects.HealthIcon;

import funkin.states.editors.components.Prompt;
import funkin.data.objects.story.MenuItem;
import funkin.data.objects.story.MenuCharacter;

import openfl.utils.Assets;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flash.net.FileFilter;
import lime.system.Clipboard;
import haxe.Json;

class WeekEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var lock:FlxSprite;
	var txtTracklist:FlxText;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekThing:MenuItem;
	var missingFileText:FlxText;

	public static var unsavedProgress:Bool = false;
	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
		else weekFileName = 'week1';
	}

	override function create() {
		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		
		var ui_tex = Paths.getSparrowAtlas('storyMode/ui/Menu_UI');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = Preferences.data.antialiasing;

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = Preferences.data.antialiasing;
		add(weekThing);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);
		
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		
		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = Preferences.data.antialiasing;
		add(lock);
		
		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText); 
		
		var charArray:Array<String> = weekFile.weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435).loadGraphic(Paths.image('storyMode/ui/song_tracks_menu'));
		tracksSprite.antialiasing = Preferences.data.antialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(txtWeekTitle);

		addEditorBox();
		reloadAllShit();

		FlxG.mouse.visible = true;
		super.create();
	}

	var UI_box:PsychUIBox;
	function addEditorBox() {
		UI_box = new PsychUIBox(FlxG.width, FlxG.height, 250, 375, ['Other', 'Week Data', 'Extra']);
		UI_box.x -= UI_box.width;
		UI_box.y -= UI_box.height;
		UI_box.scrollFactor.set();
		add(UI_box);
		addOtherUI();
		addWeekUI();
		addExtraUI();
		
		UI_box.selectedName = 'Week Data';
		add(UI_box);

		var loadWeekButton:PsychUIButton = new PsychUIButton(0, 650, "Load", function() loadWeek());
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var freeplayButton:PsychUIButton = new PsychUIButton(0, 650, "Freeplay Menu", function() MusicBeatState.switchState(new WeekEditorFreeplayState(weekFile)));
		freeplayButton.screenCenter(X);
		add(freeplayButton);
	
		var saveWeekButton:PsychUIButton = new PsychUIButton(0, 650, "Save", function() saveWeek(weekFile));
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	var songsInputText:PsychUIInputText;
	var backgroundInputText:PsychUIInputText;
	var displayNameInputText:PsychUIInputText;
	var weekNameInputText:PsychUIInputText;
	var weekFileInputText:PsychUIInputText;
	var weekTitlePathInputText:PsychUIInputText;
	
	var opponentInputText:PsychUIInputText;
	var boyfriendInputText:PsychUIInputText;
	var girlfriendInputText:PsychUIInputText;
	var hideCheckbox:PsychUICheckBox;
	var hiddenStorySongsInputText:PsychUIInputText;
	var sectionInputText:PsychUIInputText;

	public static var weekFileName:String = 'week1';
	
	function addWeekUI() {
		var tab_group = UI_box.getTab('Week Data').menu;

		songsInputText = new PsychUIInputText(10, 30, 200, '', 8);

		opponentInputText = new PsychUIInputText(10, songsInputText.y + 40, 70, '', 8);
		boyfriendInputText = new PsychUIInputText(opponentInputText.x + 75, opponentInputText.y, 70, '', 8);
		girlfriendInputText = new PsychUIInputText(boyfriendInputText.x + 75, opponentInputText.y, 70, '', 8);

		backgroundInputText = new PsychUIInputText(10, opponentInputText.y + 40, 120, '', 8);
		displayNameInputText = new PsychUIInputText(10, backgroundInputText.y + 60, 200, '', 8);
		weekNameInputText = new PsychUIInputText(10, displayNameInputText.y + 60, 150, '', 8);
		weekFileInputText = new PsychUIInputText(10, weekNameInputText.y + 40, 100, '', 8);
		weekTitlePathInputText = new PsychUIInputText(10, weekFileInputText.y + 40, 200, '', 8);
		reloadWeekThing();

		hideCheckbox = new PsychUICheckBox(10, weekTitlePathInputText.y + 40, "Hide Week from Story Mode?", 100);
		hideCheckbox.onClick = function()
		{
			weekFile.hideStoryMode = hideCheckbox.checked;
			unsavedProgress = true;
		};

		tab_group.add(new FlxText(songsInputText.x, songsInputText.y - 18, 0, 'Songs:'));
		tab_group.add(new FlxText(opponentInputText.x, opponentInputText.y - 18, 0, 'Characters:'));
		tab_group.add(new FlxText(backgroundInputText.x, backgroundInputText.y - 18, 0, 'Background Asset:'));
		tab_group.add(new FlxText(displayNameInputText.x, displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(weekNameInputText.x, weekNameInputText.y - 18, 0, 'Week Name (for Reset Score Menu):'));
		tab_group.add(new FlxText(weekFileInputText.x, weekFileInputText.y - 18, 0, 'Week File (JSON name):'));
		tab_group.add(new FlxText(weekTitlePathInputText.x, weekTitlePathInputText.y - 18, 0, 'Week Title Path (image):'));

		tab_group.add(songsInputText);
		tab_group.add(opponentInputText);
		tab_group.add(boyfriendInputText);
		tab_group.add(girlfriendInputText);
		tab_group.add(backgroundInputText);

		tab_group.add(displayNameInputText);
		tab_group.add(weekNameInputText);
		tab_group.add(weekFileInputText);
		tab_group.add(weekTitlePathInputText);
		tab_group.add(hideCheckbox);
	}

	function addExtraUI() {
		var tab_group = UI_box.getTab('Extra').menu;

		hiddenStorySongsInputText = new PsychUIInputText(10, 55, 215, '', 8);
		sectionInputText = new PsychUIInputText(10, 155, 215, '', 8);

		tab_group.add(new FlxText(10, 30, 220, 'Hide songs in Story/Freeplay:'));
		tab_group.add(new FlxText(10, hiddenStorySongsInputText.y + 25, 220, 'Use song names separated by ",".\nExample: Bopeebo, Fresh'));
		tab_group.add(hiddenStorySongsInputText);
		tab_group.add(new FlxText(10, sectionInputText.y - 20, 220, 'Section:'));
		tab_group.add(new FlxText(10, sectionInputText.y + 25, 220, 'Use: storyMode, freeplay, extraFreeplay'));
		tab_group.add(sectionInputText);
	}

	var weekBeforeInputText:PsychUIInputText;
	var lockedCheckbox:PsychUICheckBox;
	var hiddenUntilUnlockCheckbox:PsychUICheckBox;

	function addOtherUI() {
		var tab_group = UI_box.getTab('Other').menu;

		lockedCheckbox = new PsychUICheckBox(10, 30, "Week starts Locked", 100);
		lockedCheckbox.onClick = function()
		{
			weekFile.startUnlocked = !lockedCheckbox.checked;
			lock.visible = lockedCheckbox.checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);
			unsavedProgress = true;
		};

		hiddenUntilUnlockCheckbox = new PsychUICheckBox(10, lockedCheckbox.y + 25, "Hidden until Unlocked", 110);
		hiddenUntilUnlockCheckbox.onClick = function()
		{
			weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
			unsavedProgress = true;
		};
		hiddenUntilUnlockCheckbox.alpha = 0.4;

		weekBeforeInputText = new PsychUIInputText(10, hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);

		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y + 30, 220, 'Song difficulties/icons/colors: use each song meta.json'));
		tab_group.add(weekBeforeInputText);
		tab_group.add(hiddenUntilUnlockCheckbox);
		tab_group.add(lockedCheckbox);
	}

	//Used on onCreate and when you load a week
	function reloadAllShit() {
		var weekString:String = weekFile.songs[0][0];
		for (i in 1...weekFile.songs.length) {
			weekString += ', ' + weekFile.songs[i][0];
		}
		songsInputText.text = weekString;
		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekNameInputText.text = weekFile.weekName;
		weekFileInputText.text = weekFileName;
		var titlePath:String = WeekData.getWeekTitlePath(weekFile, weekFileName);
		if(weekTitlePathInputText != null) weekTitlePathInputText.text = titlePath;
		
		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];

		hideCheckbox.checked = weekFile.hideStoryMode;
		hiddenStorySongsInputText.text = WeekData.hiddenStorySongsToText(weekFile.hideStorySongs);
		sectionInputText.text = getSectionText(weekFile.section, weekFile.sections);

		weekBeforeInputText.text = weekFile.weekBefore;

		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;
		
		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText()
	{
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);
		}

		var stringThing:Array<String> = [];
		stringThing = WeekData.visibleStorySongNames(weekFile);

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
		
		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}

	function reloadBG() {
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;

		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/backgrounds/menu_' + assetName)) || #end
			Assets.exists(Paths.getPath('images/storymenu/backgrounds/menu_' + assetName + '.png', IMAGE), IMAGE)) {
				bgSprite.loadGraphic(Paths.image('storymenu/backgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			bgSprite.visible = false;
		}
	}

	function reloadWeekThing() {
		weekThing.visible = true;
		missingFileText.visible = false;

		// Title image path is independent from the JSON file name
		var titlePath:String = '';
		if(weekTitlePathInputText != null && weekTitlePathInputText.text != null)
			titlePath = weekTitlePathInputText.text.trim();
		if(titlePath.length < 1 && weekFile != null)
			titlePath = WeekData.getWeekTitlePath(weekFile, weekFileName);
		if(titlePath.length < 1)
			titlePath = WeekData.defaultWeekTitlePath(weekFileName);

		var resolved:String = WeekData.resolveWeekTitleImage(titlePath, weekFileName);
		var isMissing:Bool = true;
		try
		{
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modsImages(resolved)) ||
			Assets.exists(Paths.getPath('images/' + resolved + '.png', IMAGE), IMAGE))
			#else
			if(Assets.exists(Paths.getPath('images/' + resolved + '.png', IMAGE), IMAGE))
			#end
			{
				weekThing.loadGraphic(Paths.image(resolved));
				isMissing = false;
			}
		}
		catch(e:Dynamic) { isMissing = true; }

		if(isMissing) {
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/' + resolved + '.png\n(also tried storymenu/titles/ and storyMode/weekTitles/)';
		}
		recalculateStuffPosition();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Week Editor", "Editing: " + weekFileName);
		#end
	}
	
	public function UIEvent(id:String, sender:Dynamic) {
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if(sender == weekFileInputText) {
				weekFileName = weekFileInputText.text.trim();
				// File name is only the JSON name — do not force title image to match
				unsavedProgress = true;
			} else if(sender == weekTitlePathInputText) {
				var p:String = weekTitlePathInputText.text.trim().replace('\\', '/');
				if(p.startsWith('images/')) p = p.substr(7);
				if(p.endsWith('.png')) p = p.substr(0, p.length - 4);
				weekFile.week_title_Path = p;
				unsavedProgress = true;
				reloadWeekThing();
			} else if(sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText) {
				weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekFile.weekCharacters[2] = girlfriendInputText.text.trim();
				unsavedProgress = true;
				updateText();
			} else if(sender == backgroundInputText) {
				weekFile.weekBackground = backgroundInputText.text.trim();
				unsavedProgress = true;
				reloadBG();
			} else if(sender == displayNameInputText) {
				weekFile.storyName = displayNameInputText.text.trim();
				unsavedProgress = true;
				updateText();
			} else if(sender == weekNameInputText) {
				weekFile.weekName = weekNameInputText.text.trim();
				unsavedProgress = true;
			} else if(sender == songsInputText) {
				var splittedText:Array<String> = songsInputText.text.trim().split(',');
				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				while(splittedText.length < weekFile.songs.length) {
					weekFile.songs.pop();
				}

				for (i in 0...splittedText.length) {
					if(i >= weekFile.songs.length) { //Add new song
						weekFile.songs.push([splittedText[i], 'face', [146, 113, 253]]);
					} else { //Edit song
						weekFile.songs[i][0] = splittedText[i];
						if(weekFile.songs[i][1] == null || weekFile.songs[i][1]) {
							weekFile.songs[i][1] = 'face';
							weekFile.songs[i][2] = [146, 113, 253];
						}
					}
				}
				updateText();
				unsavedProgress = true;
			} else if(sender == hiddenStorySongsInputText) {
				weekFile.hideStorySongs = WeekData.setHiddenStorySongs(weekFile, hiddenStorySongsInputText.text);
				updateText();
				unsavedProgress = true;
			} else if(sender == sectionInputText) {
				weekFile.section = normalizeSectionText(sectionInputText.text);
				if(sectionInputText.text != weekFile.section)
					sectionInputText.text = Std.string(weekFile.section);
				unsavedProgress = true;
			} else if(sender == weekBeforeInputText) {
				weekFile.weekBefore = weekBeforeInputText.text.trim();
				unsavedProgress = true;
			}
		}
	}

	public static function normalizeDifficultiesText(value:String):String
	{
		if(value == null) return '';

		var output:Array<String> = [];
		var known:Array<String> = [];
		for (diff in value.split(','))
		{
			var clean:String = diff.trim();
			if(clean.length < 1) continue;

			var key:String = Difficulty.getSuffixName(clean);
			if(key.length < 1 || known.contains(key)) continue;

			known.push(key);
			output.push(clean);
		}
		return output.join(', ');
	}

	static function getSectionText(section:Dynamic, sections:Dynamic):String
	{
		var list:Array<String> = WeekData.getWeekSections({section: section, sections: sections});
		return list.join(', ');
	}

	public static function normalizeSectionText(value:String):String
	{
		if(value == null) return '';

		var output:Array<String> = [];
		for(section in value.split(','))
		{
			var clean:String = WeekData.normalizeMenuSection(section);
			if(clean != null && clean.length > 0 && !output.contains(clean))
				output.push(clean);
		}
		return output.join(', ');
	}
	
	override function update(elapsed:Float)
	{
		if(loadedWeek != null) {
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
		}

		if(PsychUIInputText.focusOn == null)
		{
			Preferences.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE)
			{
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				}
				else openSubState(new funkin.states.editors.components.Prompt.ExitConfirmationPrompt(function() unsavedProgress = false));
			}
		}
		else Preferences.toggleVolumeKeys(false);

		super.update(elapsed);

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	function recalculateStuffPosition() {
		weekThing.screenCenter(X);
		lock.x = weekThing.width + 10 + weekThing.x;
	}

	private static var _file:FileReference;
	public static function loadWeek() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}
	
	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;
	private static function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				loadedWeek = cast Json.parse(rawJson);
				// Accept Psych weeks and Pico new-format weeks
				var looksLikeWeek:Bool = loadedWeek != null && (
					loadedWeek.weekCharacters != null || Reflect.hasField(loadedWeek, 'props') ||
					loadedWeek.songs != null || Reflect.hasField(loadedWeek, 'week_Songs')
				);
				if(looksLikeWeek)
				{
					WeekData.normalizeWeekFile(loadedWeek);
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;

					weekFileName = cutName;
					if(loadedWeek.week_title_Path == null || Std.string(loadedWeek.week_title_Path).trim().length < 1)
						loadedWeek.week_title_Path = WeekData.defaultWeekTitlePath(cutName);
					_file = null;
					unsavedProgress = false;
					return;
				}
			}
		}
		loadError = true;
		loadedWeek = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile) {
		if(weekFile.section == null)
			weekFile.section = '';
		// Persist customized title path (independent from JSON file name)
		if(weekFile.week_title_Path == null || Std.string(weekFile.week_title_Path).trim().length < 1)
			weekFile.week_title_Path = WeekData.defaultWeekTitlePath(weekFileName);
		var data:String = haxe.Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFileName + ".json");
		}
	}
	
	private static function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
		unsavedProgress = false;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace("Cancelled file saving.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
	}

	var bg:FlxSprite;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];
	var freeplayDifficultiesInputText:PsychUIInputText;

	var curSelected = 0;

	override function create() {
		bg = new FlxSprite().loadGraphic(Paths.image('menus/backgrounds/menuDesat'));
		bg.antialiasing = Preferences.data.antialiasing;
		bg.color = FlxColor.WHITE;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...weekFile.songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, weekFile.songs[i][0], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(weekFile.songs[i][1]);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		addEditorBox();
		changeSelection();
		super.create();
	}
	
	var UI_box:PsychUIBox;
	function addEditorBox() {
		UI_box = new PsychUIBox(FlxG.width, FlxG.height, 250, 240, ['Freeplay', 'Difficulties']);
		UI_box.x -= UI_box.width + 100;
		UI_box.y -= UI_box.height + 60;
		UI_box.scrollFactor.set();
		addFreeplayUI();
		addDifficultiesUI();
		add(UI_box);

		var blackBlack:FlxSprite = new FlxSprite(0, 670).makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:PsychUIButton = new PsychUIButton(0, 685, "Load Week", function() {
			WeekEditorState.loadWeek();
		});
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var storyModeButton:PsychUIButton = new PsychUIButton(0, 685, "Story Mode", function() {
			MusicBeatState.switchState(new WeekEditorState(weekFile));
			
		});
		storyModeButton.screenCenter(X);
		add(storyModeButton);
	
		var saveWeekButton:PsychUIButton = new PsychUIButton(0, 685, "Save Week", function() {
			WeekEditorState.saveWeek(weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}
	
	public function UIEvent(id:String, sender:Dynamic)
	{
		if(id == PsychUICheckBox.CLICK_EVENT)
			WeekEditorState.unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText))
		{
			if(sender == iconInputText)
			{
				weekFile.songs[curSelected][1] = iconInputText.text;
				iconArray[curSelected].changeIcon(iconInputText.text);
				WeekEditorState.unsavedProgress = true;
			}
			else if(sender == freeplayDifficultiesInputText)
			{
				// Difficulties moved to per-song meta.json — field kept only as UI note
			}
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			if(sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB)
				updateBG();
		}
	}

	var bgColorStepperR:PsychUINumericStepper;
	var bgColorStepperG:PsychUINumericStepper;
	var bgColorStepperB:PsychUINumericStepper;
	var iconInputText:PsychUIInputText;
	function addFreeplayUI() {
		var tab_group = UI_box.getTab('Freeplay').menu;

		bgColorStepperR = new PsychUINumericStepper(10, 40, 20, 255, 0, 255, 0);
		bgColorStepperG = new PsychUINumericStepper(80, 40, 20, 255, 0, 255, 0);
		bgColorStepperB = new PsychUINumericStepper(150, 40, 20, 255, 0, 255, 0);

		var copyColor:PsychUIButton = new PsychUIButton(10, bgColorStepperR.y + 25, "Copy Color", function() Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue);

		var pasteColor:PsychUIButton = new PsychUIButton(140, copyColor.y, "Paste Color", function()
		{
			if(Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);
					if(!Math.isNaN(toPush))
					{
						if(toPush > 255) toPush = 255;
						else if(toPush < 0) toPush *= -1;
						leColor.push(toPush);
					}
				}

				if(leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];
					updateBG();
				}
			}
		});

		iconInputText = new PsychUIInputText(10, bgColorStepperR.y + 70, 100, '', 8);

		var hideFreeplayCheckbox:PsychUICheckBox = new PsychUICheckBox(10, iconInputText.y + 30, "Hide Week from Freeplay?", 100);
		hideFreeplayCheckbox.checked = weekFile.hideFreeplay;
		hideFreeplayCheckbox.onClick = function()
		{
			weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
			WeekEditorState.unsavedProgress = true;
		};
		
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(iconInputText);
		tab_group.add(hideFreeplayCheckbox);
	}

	function addDifficultiesUI() {
		var tab_group = UI_box.getTab('Difficulties').menu;

		freeplayDifficultiesInputText = new PsychUIInputText(10, 45, 210, '', 8);
		freeplayDifficultiesInputText.text = '';

		tab_group.add(new FlxText(10, 20, 220, 'Difficulties (info):'));
		tab_group.add(new FlxText(10, 45, 220, 'Per-song difficulties, icons and colors\nare defined in assets/songs/<song>/meta.json\n(not in the week file).'));
		// keep input for layout compatibility (disabled usage)
		tab_group.add(freeplayDifficultiesInputText);
		freeplayDifficultiesInputText.visible = false;
	}

	function updateBG() {
		weekFile.songs[curSelected][2][0] = Math.round(bgColorStepperR.value);
		weekFile.songs[curSelected][2][1] = Math.round(bgColorStepperG.value);
		weekFile.songs[curSelected][2][2] = Math.round(bgColorStepperB.value);
		bg.color = FlxColor.fromRGB(weekFile.songs[curSelected][2][0], weekFile.songs[curSelected][2][1], weekFile.songs[curSelected][2][2]);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, weekFile.songs.length - 1);
		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		//trace(weekFile.songs[curSelected]);
		iconInputText.text = weekFile.songs[curSelected][1];

		var colors = weekFile.songs[curSelected][2];
		bgColorStepperR.value = Math.round(colors[0]);
		bgColorStepperG.value = Math.round(colors[1]);
		bgColorStepperB.value = Math.round(colors[2]);
		updateBG();
	}

	override function update(elapsed:Float) {
		if(WeekEditorState.loadedWeek != null) {
			super.update(elapsed);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;
			return;
		}
		
		if(PsychUIInputText.focusOn != null)
			Preferences.toggleVolumeKeys(false);
		else
		{
			Preferences.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!WeekEditorState.unsavedProgress)
				{
					MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				}
				else openSubState(new funkin.states.editors.components.Prompt.ExitConfirmationPrompt());
			}

			if(controls.UI_UP_P) changeSelection(-1);
			if(controls.UI_DOWN_P) changeSelection(1);
		}
		super.update(elapsed);
	}
}