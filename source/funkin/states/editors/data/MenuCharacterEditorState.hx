package funkin.states.editors.data;

import funkin.data.objects.story.MenuCharacter;
import funkin.states.editors.components.Prompt;
import funkin.utils.engines.psych.PsychJsonPrinter;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flash.net.FileFilter;
import haxe.Json;

/**
 * Editor for Story Mode menu characters (props).
 * Saves / loads the new MenuCharacterFile format:
 *  animations[], propScale, propPosition, propPath, propImage,
 *  prop_disabled_Antialiasing, useAlternative, flipX
 */
class MenuCharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;
	var unsavedProgress:Bool = false;

	override function create()
	{
		characterFile = createDefaultFile();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Menu Character Editor", "Editing: " + getImageName());
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 520, FlxG.width,
			"Arrow Keys - Change Offset (Hold SHIFT for 10x)\n" +
			"Space - Play Confirm (Boyfriend) / Force dance tick (Use Alternative)\n" +
			"useAlternative = danceLeft / danceRight (GF-style idle)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharacters();
		super.create();
	}

	static function createDefaultFile():MenuCharacterFile
	{
		return MenuCharacter.normalizeCharacterFile({
			animations: [
				{name: 'idle_anim', prefix: 'M Dad Idle', offsets: [0, 0]},
				{name: 'confirm_anim', prefix: 'M Dad Idle', offsets: [0, 0]}
			],
			propScale: 1,
			propPosition: [0, 0],
			propPath: 'storymenu/props/characters/',
			propImage: 'Menu_Dad',
			prop_disabled_Antialiasing: false,
			useAlternative: false,
			flipX: false
		}, 'Menu_Dad');
	}

	function getImageName():String
	{
		if(characterFile == null) return 'character';
		if(characterFile.propImage != null && characterFile.propImage.length > 0)
			return characterFile.propImage;
		if(characterFile.image != null && characterFile.image.length > 0)
			return characterFile.image;
		return 'character';
	}

	var UI_typebox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	function addEditorBox()
	{
		UI_typebox = new PsychUIBox(100, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		UI_mainbox = new PsychUIBox(FlxG.width - 360, FlxG.height - 300, 280, 250, ['Character', 'Animations']);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		addAnimationUI();
		add(UI_mainbox);

		var loadButton:PsychUIButton = new PsychUIButton(0, 480, "Load", function() {
			loadCharacter();
		});
		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);

		var saveButton:PsychUIButton = new PsychUIButton(0, 480, "Save", function() {
			saveCharacter();
		});
		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	var characterTypeRadio:PsychUIRadioGroup;
	function addTypeUI()
	{
		var tab_group = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new PsychUIRadioGroup(10, 20, ['Opponent', 'Boyfriend', 'Girlfriend'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = updateCharacters;
		tab_group.add(characterTypeRadio);
	}

	// ---------- Animations tab ----------
	var animationTypeDropDown:PsychUIDropDownMenu;
	var animationPrefixInput:PsychUIInputText;
	var animOffsetXStepper:PsychUINumericStepper;
	var animOffsetYStepper:PsychUINumericStepper;
	var useAlternativeCheckbox:PsychUICheckBox;

	static final ANIM_OPTIONS:Array<String> = ['idle_anim', 'confirm_anim', 'danceLeft', 'danceRight'];

	function addAnimationUI()
	{
		var tab_group = UI_mainbox.getTab('Animations').menu;
		var lx:Int = 10;
		var ly:Int = 10;

		useAlternativeCheckbox = new PsychUICheckBox(lx, ly, 'Use Alternative (dance L/R)', 200);
		useAlternativeCheckbox.checked = characterFile.useAlternative == true;
		useAlternativeCheckbox.onClick = function()
		{
			characterFile.useAlternative = useAlternativeCheckbox.checked;
			if(characterFile.useAlternative)
			{
				// Ensure dance anims exist when enabling
				MenuCharacter.setAnimPrefix(characterFile, 'danceLeft', MenuCharacter.getAnimPrefix(characterFile, 'idle_anim'));
				MenuCharacter.setAnimPrefix(characterFile, 'danceRight', MenuCharacter.getAnimPrefix(characterFile, 'idle_anim'));
			}
			reloadSelectedCharacter();
			unsavedProgress = true;
		};
		tab_group.add(useAlternativeCheckbox);

		ly += 30;
		animationTypeDropDown = new PsychUIDropDownMenu(lx, ly, ANIM_OPTIONS, function(id:Int, selected:String)
		{
			refreshAnimationInput();
		});
		animationTypeDropDown.selectedLabel = 'idle_anim';
		tab_group.add(new FlxText(animationTypeDropDown.x, animationTypeDropDown.y - 18, 160, 'Animation:'));
		tab_group.add(animationTypeDropDown);

		ly += 45;
		animationPrefixInput = new PsychUIInputText(lx, ly, 240, MenuCharacter.getAnimPrefix(characterFile, 'idle_anim'), 8);
		animationPrefixInput.name = 'anim_prefix';
		tab_group.add(new FlxText(animationPrefixInput.x, animationPrefixInput.y - 18, 200, 'Prefix (sparrow):'));
		tab_group.add(animationPrefixInput);

		ly += 40;
		animOffsetXStepper = new PsychUINumericStepper(lx, ly, 1, 0, -2000, 2000, 0);
		animOffsetYStepper = new PsychUINumericStepper(lx + 80, ly, 1, 0, -2000, 2000, 0);
		tab_group.add(new FlxText(lx, ly - 18, 160, 'Anim offsets X / Y:'));
		tab_group.add(animOffsetXStepper);
		tab_group.add(animOffsetYStepper);

		ly += 40;
		var addUpdateButton:PsychUIButton = new PsychUIButton(lx, ly, 'Add/Update', function()
		{
			applySelectedAnimation(animationPrefixInput.text.trim());
			applySelectedAnimOffsets();
			reloadSelectedCharacter();
			unsavedProgress = true;
		}, 100);
		tab_group.add(addUpdateButton);

		var removeButton:PsychUIButton = new PsychUIButton(lx + 110, ly, 'Clear Prefix', function()
		{
			applySelectedAnimation('');
			refreshAnimationInput();
			reloadSelectedCharacter();
			unsavedProgress = true;
		}, 100);
		tab_group.add(removeButton);

		ly += 30;
		var playButton:PsychUIButton = new PsychUIButton(lx, ly, 'Play Anim', function()
		{
			playSelectedAnimation();
		}, 100);
		tab_group.add(playButton);
	}

	function getSelectedAnimationName():String
	{
		if(animationTypeDropDown == null || animationTypeDropDown.selectedLabel == null)
			return 'idle_anim';
		return animationTypeDropDown.selectedLabel.trim();
	}

	function applySelectedAnimation(prefix:String)
	{
		MenuCharacter.setAnimPrefix(characterFile, getSelectedAnimationName(), prefix);
	}

	function applySelectedAnimOffsets()
	{
		if(characterFile == null || characterFile.animations == null) return;
		var name:String = getSelectedAnimationName();
		for (a in characterFile.animations)
		{
			if(a != null && a.name == name)
			{
				a.offsets = [animOffsetXStepper.value, animOffsetYStepper.value];
				return;
			}
		}
	}

	function refreshAnimationInput()
	{
		if(animationPrefixInput == null || characterFile == null) return;
		var name:String = getSelectedAnimationName();
		animationPrefixInput.text = MenuCharacter.getAnimPrefix(characterFile, name);
		var off:Array<Float> = MenuCharacter.getAnimOffsets(characterFile, name);
		if(animOffsetXStepper != null) animOffsetXStepper.value = off[0];
		if(animOffsetYStepper != null) animOffsetYStepper.value = off[1];
	}

	function playSelectedAnimation()
	{
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
		if(char == null) return;
		var name:String = getSelectedAnimationName();
		if(name == 'idle_anim')
			char.playIdle();
		else if(name == 'confirm_anim')
			char.playConfirm();
		else if(char.animation.exists(name))
			char.animation.play(name, true);
		else if(name == 'danceLeft' || name == 'danceRight')
			char.playIdle();
	}

	// ---------- Character tab ----------
	var imageInputText:PsychUIInputText;
	var pathInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var flipXCheckbox:PsychUICheckBox;
	var antialiasingCheckbox:PsychUICheckBox;

	function addCharacterUI()
	{
		var tab_group = UI_mainbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(10, 20, 120, getImageName(), 8);
		pathInputText = new PsychUIInputText(10, 60, 200, characterFile.propPath != null ? characterFile.propPath : 'storymenu/props/characters/', 8);

		flipXCheckbox = new PsychUICheckBox(10, 100, "Flip X", 100);
		flipXCheckbox.checked = characterFile.flipX == true;
		flipXCheckbox.onClick = function()
		{
			characterFile.flipX = flipXCheckbox.checked;
			grpWeekCharacters.members[characterTypeRadio.checked].flipX = flipXCheckbox.checked;
			unsavedProgress = true;
		};

		// Checked = antialiasing ON → prop_disabled_Antialiasing = false
		antialiasingCheckbox = new PsychUICheckBox(10, 130, "Antialiasing", 100);
		antialiasingCheckbox.checked = characterFile.prop_disabled_Antialiasing != true;
		antialiasingCheckbox.onClick = function()
		{
			characterFile.prop_disabled_Antialiasing = !antialiasingCheckbox.checked;
			grpWeekCharacters.members[characterTypeRadio.checked].antialiasing =
				!characterFile.prop_disabled_Antialiasing && Preferences.data.antialiasing;
			unsavedProgress = true;
		};

		var reloadImageButton:PsychUIButton = new PsychUIButton(140, 100, "Reload Char", function() {
			characterFile.propImage = imageInputText.text.trim();
			characterFile.image = characterFile.propImage;
			characterFile.propPath = pathInputText.text.trim();
			reloadSelectedCharacter();
			unsavedProgress = true;
		});

		scaleStepper = new PsychUINumericStepper(140, 20, 0.05, characterFile.propScale, 0.1, 30, 2);

		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image (propImage):'));
		tab_group.add(new FlxText(10, pathInputText.y - 18, 0, 'Folder (propPath):'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(antialiasingCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(imageInputText);
		tab_group.add(pathInputText);
		tab_group.add(scaleStepper);
	}

	function updateCharacters()
	{
		for (i in 0...3)
		{
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}
		reloadSelectedCharacter();
	}

	function reloadSelectedCharacter()
	{
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
		char.alpha = 1;

		// Keep file fields in sync with UI before applying
		if(imageInputText != null)
		{
			characterFile.propImage = imageInputText.text.trim();
			characterFile.image = characterFile.propImage;
		}
		if(pathInputText != null)
			characterFile.propPath = pathInputText.text.trim();
		if(scaleStepper != null)
			characterFile.propScale = scaleStepper.value;
		if(useAlternativeCheckbox != null)
			characterFile.useAlternative = useAlternativeCheckbox.checked;
		if(flipXCheckbox != null)
			characterFile.flipX = flipXCheckbox.checked;
		if(antialiasingCheckbox != null)
			characterFile.prop_disabled_Antialiasing = !antialiasingCheckbox.checked;

		// Apply through a temporary path: force re-apply file onto the sprite
		applyFileToSprite(char, characterFile);
		updateOffset();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Menu Character Editor", "Editing: " + getImageName());
		#end
	}

	/** Apply editor file onto a MenuCharacter sprite without going through JSON disk load. */
	function applyFileToSprite(char:MenuCharacter, file:MenuCharacterFile)
	{
		if(char == null || file == null) return;

		char.useAlternative = file.useAlternative == true;
		char.hasConfirmAnimation = false;

		var path:String = file.propPath != null ? file.propPath : 'storymenu/props/characters/';
		if(!path.endsWith('/') && !path.endsWith('\\')) path += '/';
		var img:String = file.propImage != null && file.propImage.length > 0 ? file.propImage : (file.image != null ? file.image : 'Menu_Dad');

		try
		{
			char.frames = Paths.getSparrowAtlas(path + img);
		}
		catch(e:Dynamic)
		{
			try { char.frames = Paths.getSparrowAtlas('storymenu/props/characters/' + img); }
			catch(e2:Dynamic)
			{
				trace('[MenuCharacterEditor] Atlas not found: ' + path + img);
				return;
			}
		}

		char.animation.destroyAnimations();

		var idlePrefix:String = MenuCharacter.getAnimPrefix(file, 'idle_anim');
		var confirmPrefix:String = MenuCharacter.getAnimPrefix(file, 'confirm_anim');
		var danceL:String = MenuCharacter.getAnimPrefix(file, 'danceLeft');
		var danceR:String = MenuCharacter.getAnimPrefix(file, 'danceRight');

		if(file.useAlternative)
		{
			if(danceL.length > 0) char.animation.addByPrefix('danceLeft', danceL, 24, false);
			if(danceR.length > 0) char.animation.addByPrefix('danceRight', danceR, 24, false);
			if(!char.animation.exists('danceLeft') && idlePrefix.length > 0)
				char.animation.addByPrefix('idle', idlePrefix, 24);
		}
		else if(idlePrefix.length > 0)
		{
			char.animation.addByPrefix('idle', idlePrefix, 24);
		}

		if(confirmPrefix != null && confirmPrefix.length > 0)
		{
			char.animation.addByPrefix('confirm', confirmPrefix, 24, false);
			char.hasConfirmAnimation = char.animation.exists('confirm');
		}

		char.flipX = file.flipX == true;
		char.antialiasing = !file.prop_disabled_Antialiasing && Preferences.data.antialiasing;

		var sc:Float = file.propScale;
		if(Math.isNaN(sc) || sc <= 0) sc = 1;
		char.scale.set(sc, sc);
		char.updateHitbox();

		var pos:Array<Float> = file.propPosition != null ? file.propPosition : [0, 0];
		char.offset.set(pos[0], pos[1]);
		char.playIdle();
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText))
		{
			if(sender == imageInputText)
			{
				characterFile.propImage = imageInputText.text;
				characterFile.image = characterFile.propImage;
				unsavedProgress = true;
			}
			else if(sender == pathInputText)
			{
				characterFile.propPath = pathInputText.text;
				unsavedProgress = true;
			}
			else if(sender == animationPrefixInput)
			{
				applySelectedAnimation(animationPrefixInput.text);
				unsavedProgress = true;
			}
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			if(sender == scaleStepper)
			{
				characterFile.propScale = scaleStepper.value;
				reloadSelectedCharacter();
				unsavedProgress = true;
			}
			else if(sender == animOffsetXStepper || sender == animOffsetYStepper)
			{
				applySelectedAnimOffsets();
				unsavedProgress = true;
			}
		}
	}

	override function update(elapsed:Float)
	{
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
				else openSubState(new funkin.states.editors.components.Prompt.ExitConfirmationPrompt());
			}

			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 10;

			if(FlxG.keys.justPressed.LEFT)
			{
				characterFile.propPosition[0] += shiftMult;
				updateOffset();
				unsavedProgress = true;
			}
			if(FlxG.keys.justPressed.RIGHT)
			{
				characterFile.propPosition[0] -= shiftMult;
				updateOffset();
				unsavedProgress = true;
			}
			if(FlxG.keys.justPressed.UP)
			{
				characterFile.propPosition[1] += shiftMult;
				updateOffset();
				unsavedProgress = true;
			}
			if(FlxG.keys.justPressed.DOWN)
			{
				characterFile.propPosition[1] -= shiftMult;
				updateOffset();
				unsavedProgress = true;
			}

			if(FlxG.keys.justPressed.SPACE)
			{
				var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
				if(characterTypeRadio.checked == 1 && char.hasConfirmAnimation)
					char.playConfirm();
				else
					char.playIdle();
			}
		}
		else Preferences.toggleVolumeKeys(false);

		var bf:MenuCharacter = grpWeekCharacters.members[1];
		if(bf != null && bf.animation.curAnim != null && bf.animation.curAnim.name == 'confirm' && bf.animation.curAnim.finished)
			bf.playIdle();

		super.update(elapsed);
	}

	function updateOffset()
	{
		var char:MenuCharacter = grpWeekCharacters.members[characterTypeRadio.checked];
		if(characterFile.propPosition == null || characterFile.propPosition.length < 2)
			characterFile.propPosition = [0, 0];
		char.offset.set(characterFile.propPosition[0], characterFile.propPosition[1]);
		txtOffsets.text = '' + characterFile.propPosition;
	}

	// ---------- Load / Save ----------
	var _file:FileReference = null;
	function loadCharacter()
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null)
			{
				try
				{
					var parsed:Dynamic = Json.parse(rawJson);
					var loadedChar:MenuCharacterFile = MenuCharacter.normalizeCharacterFile(parsed, _file.name.substr(0, _file.name.length - 5));
					// Accept new format (animations) or legacy (idle_anim)
					var hasAnims:Bool = loadedChar.animations != null && loadedChar.animations.length > 0;
					var hasLegacy:Bool = Reflect.hasField(parsed, 'idle_anim');
					if(hasAnims || hasLegacy)
					{
						characterFile = loadedChar;
						reloadSelectedCharacter();
						syncUIFromFile();
						trace("Successfully loaded file: " + _file.name);
						_file = null;
						return;
					}
				}
				catch(e:Dynamic)
				{
					trace('Failed to load character JSON: ' + e);
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	function syncUIFromFile()
	{
		if(imageInputText != null) imageInputText.text = getImageName();
		if(pathInputText != null) pathInputText.text = characterFile.propPath != null ? characterFile.propPath : 'storymenu/props/characters/';
		if(scaleStepper != null) scaleStepper.value = characterFile.propScale;
		if(flipXCheckbox != null) flipXCheckbox.checked = characterFile.flipX == true;
		if(antialiasingCheckbox != null) antialiasingCheckbox.checked = characterFile.prop_disabled_Antialiasing != true;
		if(useAlternativeCheckbox != null) useAlternativeCheckbox.checked = characterFile.useAlternative == true;
		refreshAnimationInput();
		updateOffset();
	}

	function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveCharacter()
	{
		if(animationPrefixInput != null)
			applySelectedAnimation(animationPrefixInput.text.trim());
		applySelectedAnimOffsets();

		if(imageInputText != null)
		{
			characterFile.propImage = imageInputText.text.trim();
			characterFile.image = characterFile.propImage;
		}
		if(pathInputText != null)
			characterFile.propPath = pathInputText.text.trim();
		if(scaleStepper != null)
			characterFile.propScale = scaleStepper.value;
		if(useAlternativeCheckbox != null)
			characterFile.useAlternative = useAlternativeCheckbox.checked;

		var clean:Dynamic = MenuCharacter.toNewFormat(characterFile);
		var data:String = PsychJsonPrinter.print(clean, ['propPosition', 'offsets']);
		if(data.length > 0)
		{
			var fileName:String = getImageName().toLowerCase().replace(' ', '');
			// Menu_Dad → dad
			var splitted:Array<String> = fileName.split('_');
			if(splitted.length > 1) fileName = splitted[splitted.length - 1];
			if(fileName.length < 1) fileName = 'character';

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, fileName + '.json');
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		unsavedProgress = false;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}