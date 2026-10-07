package funkin.states.editors.data;

import funkin.data.dialogue.DialogueBoxPsych;
import funkin.data.dialogue.DialogueCharacter;

import funkin.states.editors.components.Prompt;
import funkin.utils.TypedAlphabet;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import flash.net.FileFilter;
import haxe.Json;
import lime.system.Clipboard;

class DialogueCharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var box:FlxSprite;
	var daText:TypedAlphabet = null;

	private static var TIP_TEXT_MAIN:String =
	'JKLI - Move camera (Hold Shift to move 4x faster)
	\nQ/E - Zoom out/in
	\nR - Reset Camera
	\nH - Toggle Speech Bubble
	\nSpace - Reset text';

	private static var TIP_TEXT_OFFSET:String =
	'JKLI - Move camera (Hold Shift to move 4x faster)
	\nQ/E - Zoom out/in
	\nR - Reset Camera
	\nH - Toggle Ghosts
	\nWASD - Move Looping animation offset (Red)
	\nArrow Keys - Move Idle/Finished animation offset (Blue)
	\nHold Shift to move offsets 10x faster';

	var tipText:FlxText;
	var offsetLoopText:FlxText;
	var offsetIdleText:FlxText;
	var animText:FlxText;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var mainGroup:FlxSpriteGroup;
	var hudGroup:FlxSpriteGroup;

	var character:DialogueCharacter;
	var ghostLoop:DialogueCharacter;
	var ghostIdle:DialogueCharacter;

	var curAnim:Int = 0;
	var unsavedProgress:Bool = false;

	override function create() {
		persistentUpdate = persistentDraw = true;
		camGame = initPsychCamera();
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);
		
		mainGroup = new FlxSpriteGroup();
		mainGroup.cameras = [camGame];
		hudGroup = new FlxSpriteGroup();
		hudGroup.cameras = [camGame];
		add(mainGroup);
		add(hudGroup);

		character = new DialogueCharacter();
		character.scrollFactor.set();
		mainGroup.add(character);
		
		ghostLoop = new DialogueCharacter();
		ghostLoop.alpha = 0;
		ghostLoop.color = FlxColor.RED;
		ghostLoop.isGhost = true;
		ghostLoop.jsonFile = character.jsonFile;
		ghostLoop.cameras = [camGame];
		mainGroup.add(ghostLoop);
		
		ghostIdle = new DialogueCharacter();
		ghostIdle.alpha = 0;
		ghostIdle.color = FlxColor.BLUE;
		ghostIdle.isGhost = true;
		ghostIdle.jsonFile = character.jsonFile;
		ghostIdle.cameras = [camGame];
		mainGroup.add(ghostIdle);

		box = new FlxSprite(70, 370);
		box.antialiasing = Preferences.data.antialiasing;
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		hudGroup.add(box);

		tipText = new FlxText(10, 10, FlxG.width - 20, TIP_TEXT_MAIN, 8);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.cameras = [camHUD];
		tipText.scrollFactor.set();
		add(tipText);

		offsetLoopText = new FlxText(10, 10, 0, '', 32);
		offsetLoopText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetLoopText.cameras = [camHUD];
		offsetLoopText.scrollFactor.set();
		add(offsetLoopText);
		offsetLoopText.visible = false;

		offsetIdleText = new FlxText(10, 46, 0, '', 32);
		offsetIdleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetIdleText.cameras = [camHUD];
		offsetIdleText.scrollFactor.set();
		add(offsetIdleText);
		offsetIdleText.visible = false;

		animText = new FlxText(10, 22, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		animText.cameras = [camHUD];
		add(animText);

		reloadCharacter();
		updateTextBox();

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, '', 0.05, false);
		daText.setScale(0.7);
		daText.text = DEFAULT_TEXT;
		hudGroup.add(daText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharTypeBox();
		
		super.create();
	}

	var UI_typebox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	function addEditorBox() {
		UI_typebox = new PsychUIBox(900, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		UI_typebox.cameras = [camHUD];
		addTypeUI();
		add(UI_typebox);

		UI_mainbox = new PsychUIBox(UI_typebox.x + UI_typebox.width + 10, FlxG.height - 300, 200, 250, ['Animations', 'Character']);
		UI_mainbox.scrollFactor.set();
		UI_mainbox.cameras = [camHUD];
		addAnimationsUI();
		addCharacterUI();
		add(UI_mainbox);
		UI_mainbox.selectedName = 'Character';
		lastTab = UI_mainbox.selectedName;
	}

	var characterTypeRadio:PsychUIRadioGroup;
	function addTypeUI() {
		var tab_group = UI_typebox.getTab('Character Type').menu;
		
		characterTypeRadio = new PsychUIRadioGroup(10, 20, ['Left', 'Center', 'Right'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = function() {
			var pos:String = switch(characterTypeRadio.checked)
			{
				case 0: 'left';
				case 1: 'center';
				default: 'right';
			};
			character.jsonFile.dialogue_pos = pos;
			character.jsonFile.dialogueType = pos;
			unsavedProgress = true;
			updateCharTypeBox();
		}
		tab_group.add(characterTypeRadio);
	}

	var curSelectedAnim:String;
	var animationArray:Array<String> = [];
	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var loopInputText:PsychUIInputText;
	var idleInputText:PsychUIInputText;
	function addAnimationsUI() {
		var tab_group = UI_mainbox.getTab('Animations').menu;

		animationDropDown = new PsychUIDropDownMenu(10, 30, [''], function(id:Int, animation:String) {
			if(character.dialogueAnimations.exists(animation)) {
				ghostLoop.playAnim(animation);
				ghostIdle.playAnim(animation, true);

				curSelectedAnim = animation;
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
				offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;

				animationInputText.text = animShit.anim;
				loopInputText.text = animShit.loop_name;
				idleInputText.text = animShit.idle_name;
			}
		});
		
		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		loopInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		idleInputText = new PsychUIInputText(loopInputText.x, loopInputText.y + 40, 150, '', 8);
		
		var addUpdateButton:PsychUIButton = new PsychUIButton(10, idleInputText.y + 30, "Add/Update", function() {
			var theAnim:String = animationInputText.text.trim();
			if(character.dialogueAnimations.exists(theAnim)) //Update
			{
				for (i in 0...character.jsonFile.animations.length) {
					var animArray:DialogueAnimArray = character.jsonFile.animations[i];
					if(animArray.anim.trim() == theAnim) {
						animArray.loop_name = loopInputText.text;
						animArray.idle_name = idleInputText.text;
						break;
					}
				}

				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
				if(curSelectedAnim == theAnim) {
					ghostLoop.playAnim(theAnim);
					ghostIdle.playAnim(theAnim, true);
				}
			}
			else //Add
			{
				var newAnim:DialogueAnimArray = {
					anim: theAnim,
					loop_name: loopInputText.text,
					loop_offsets: [0, 0],
					idle_name: idleInputText.text.length > 0 ? idleInputText.text : loopInputText.text,
					idle_offsets: [0, 0],
					fps: 24,
					loop: true
				};
				if(character.jsonFile.animations == null) character.jsonFile.animations = [];
				character.jsonFile.animations.push(newAnim);

				var lastSelected:String = animationDropDown.selectedLabel;
				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
				reloadAnimationsDropDown();
				animationDropDown.selectedLabel = lastSelected;
			}
		});
		
		var removeUpdateButton:PsychUIButton = new PsychUIButton(100, addUpdateButton.y, "Remove", function() {
			for (i in 0...character.jsonFile.animations.length) {
				var animArray:DialogueAnimArray = character.jsonFile.animations[i];
				if(animArray != null && animArray.anim.trim() == animationInputText.text.trim()) {
					var lastSelected:String = animationDropDown.selectedLabel;
					character.jsonFile.animations.remove(animArray);
					character.reloadAnimations();
					ghostLoop.reloadAnimations();
					ghostIdle.reloadAnimations();
					reloadAnimationsDropDown();
					if(character.jsonFile.animations.length > 0 && lastSelected == animArray.anim.trim()) {
						var animToPlay:String = character.jsonFile.animations[0].anim;
						ghostLoop.playAnim(animToPlay);
						ghostIdle.playAnim(animToPlay, true);
					}
					animationDropDown.selectedLabel = lastSelected;
					animationInputText.text = '';
					loopInputText.text = '';
					idleInputText.text = '';
					break;
				}
			}
		});
		
		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(loopInputText.x, loopInputText.y - 18, 0, 'Prefix on .XML (loop):'));
		tab_group.add(new FlxText(idleInputText.x, idleInputText.y - 18, 0, 'Idle prefix on .XML (optional):'));
		tab_group.add(animationInputText);
		tab_group.add(loopInputText);
		tab_group.add(idleInputText);
		tab_group.add(addUpdateButton);
		tab_group.add(removeUpdateButton);
		tab_group.add(animationDropDown);
		reloadAnimationsDropDown();
	}

	function reloadAnimationsDropDown() {
		animationArray = [];
		if(character.jsonFile.animations != null)
		{
			for (anim in character.jsonFile.animations) {
				if(anim != null && anim.anim != null)
					animationArray.push(anim.anim);
			}
		}

		if(animationArray.length < 1) animationArray = [''];
		animationDropDown.list = animationArray;
	}

	var imageInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var xStepper:PsychUINumericStepper;
	var yStepper:PsychUINumericStepper;
	var flipXCheckbox:PsychUICheckBox;
	function addCharacterUI() {
		var tab_group = UI_mainbox.getTab('Character').menu;

		var initialAsset:String = character.jsonFile.assetPath;
		if(initialAsset == null || initialAsset.length < 1) initialAsset = character.jsonFile.image;
		if(initialAsset == null) initialAsset = '';

		var pos0:Float = 0;
		var pos1:Float = 0;
		if(character.jsonFile.position != null && character.jsonFile.position.length > 0)
			pos0 = character.jsonFile.position[0];
		if(character.jsonFile.position != null && character.jsonFile.position.length > 1)
			pos1 = character.jsonFile.position[1];

		imageInputText = new PsychUIInputText(10, 30, 160, initialAsset, 8);
		xStepper = new PsychUINumericStepper(imageInputText.x, imageInputText.y + 50, 10, pos0, -2000, 2000, 0);
		yStepper = new PsychUINumericStepper(imageInputText.x + 80, xStepper.y, 10, pos1, -2000, 2000, 0);
		scaleStepper = new PsychUINumericStepper(imageInputText.x, xStepper.y + 50, 0.05, character.jsonFile.scale, 0.1, 10, 2);

		var noAntialiasingCheckbox:PsychUICheckBox = new PsychUICheckBox(scaleStepper.x + 80, scaleStepper.y, "No Antialiasing", 100);
		noAntialiasingCheckbox.checked = (character.jsonFile.no_antialiasing == true);
		noAntialiasingCheckbox.onClick = function()
		{
			character.jsonFile.no_antialiasing = noAntialiasingCheckbox.checked;
			character.antialiasing = !character.jsonFile.no_antialiasing;
			unsavedProgress = true;
		};

		flipXCheckbox = new PsychUICheckBox(noAntialiasingCheckbox.x, noAntialiasingCheckbox.y + 25, "Flip X", 100);
		flipXCheckbox.checked = (character.jsonFile.flip_x == true);
		flipXCheckbox.onClick = function()
		{
			character.jsonFile.flip_x = flipXCheckbox.checked;
			character.flipX = flipXCheckbox.checked;
			character.flipXFromJson = flipXCheckbox.checked;
			unsavedProgress = true;
		};
		
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Asset Path (Paths.image):'));
		tab_group.add(new FlxText(10, xStepper.y - 18, 0, 'Dialogue Offsets:'));
		tab_group.add(new FlxText(10, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(imageInputText);
		tab_group.add(xStepper);
		tab_group.add(yStepper);
		tab_group.add(scaleStepper);
		tab_group.add(noAntialiasingCheckbox);
		tab_group.add(flipXCheckbox);

		var reloadImageButton:PsychUIButton = new PsychUIButton(10, scaleStepper.y + 60, "Reload Image", function() {
			reloadCharacter();
		});
		
		var loadButton:PsychUIButton = new PsychUIButton(reloadImageButton.x + 100, reloadImageButton.y, "Load Character", function() {
			loadCharacter();
		});
		var saveButton:PsychUIButton = new PsychUIButton(loadButton.x, reloadImageButton.y - 25, "Save Character", function() {
			saveCharacter();
		});
		tab_group.add(reloadImageButton);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
	}
	
	function updateCharTypeBox()
	{
		var pos:String = character.jsonFile.dialogueType;
		if(pos == null || pos.length < 1) pos = character.jsonFile.dialogue_pos;
		if(pos == null) pos = 'right';
		switch(pos.toLowerCase())
		{
			case 'left':
				characterTypeRadio.checked = 0;
			case 'center':
				characterTypeRadio.checked = 1;
			default:
				characterTypeRadio.checked = 2;
		}
		reloadCharacter();
		updateTextBox();
	}

	private static var DEFAULT_TEXT:String = 'Lorem ipsum dolor sit amet';

	function reloadCharacter() {
		var charsArray:Array<DialogueCharacter> = [character, ghostLoop, ghostIdle];
		// Keep assetPath / image in sync with the text field
		if(imageInputText != null)
		{
			var ap:String = imageInputText.text.trim();
			character.jsonFile.assetPath = ap;
			character.jsonFile.image = ap;
		}
		for (char in charsArray) {
			char.jsonFile = character.jsonFile;
			char.flipXFromJson = character.jsonFile.flip_x == true;
			try { char.loadDialogueFrames(); } catch(e:Dynamic) {}
			char.reloadAnimations();
			var sc:Float = (character.jsonFile != null ? character.jsonFile.scale : 1);
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * sc));
			char.updateHitbox();
			char.flipX = character.jsonFile.flip_x == true;
		}
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		var posType:String = character.jsonFile.dialogueType;
		if(posType == null || posType.length < 1) posType = character.jsonFile.dialogue_pos;
		if(posType == null) posType = 'left';
		switch(posType.toLowerCase()) {
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		var offX:Float = 0;
		var offY:Float = 0;
		if(character.jsonFile.position != null && character.jsonFile.position.length > 0)
			offX = character.jsonFile.position[0];
		if(character.jsonFile.position != null && character.jsonFile.position.length > 1)
			offY = character.jsonFile.position[1];
		character.x += offX + mainGroup.x;
		character.y += offY + mainGroup.y;
		if(character.jsonFile.animations != null && character.jsonFile.animations.length > 0) {
			character.playAnim(character.jsonFile.animations[0].anim);
			curSelectedAnim = character.jsonFile.animations[0].anim;
			var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
			if(animShit != null) {
				ghostLoop.playAnim(animShit.anim);
				ghostIdle.playAnim(animShit.anim, true);
				offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
				offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
			}
		}

		curAnim = 0;
		animText.text = (character.jsonFile.animations != null && character.jsonFile.animations.length > 0)
			? ('Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll')
			: 'Animation: (none)';

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		var editName:String = character.jsonFile.assetPath;
		if(editName == null || editName.length < 1) editName = character.jsonFile.image;
		DiscordClient.changePresence("Dialogue Character Editor", "Editing: " + editName);
		#end
	}

	function updateTextBox() {
		box.flipX = false;
		var anim:String = 'normal';
		var posType:String = character.jsonFile.dialogueType;
		if(posType == null || posType.length < 1) posType = character.jsonFile.dialogue_pos;
		if(posType == null) posType = 'left';
		switch(posType.toLowerCase()) {
			case 'left':
				box.flipX = true;
			case 'center':
				anim = 'center';
		}
		box.animation.play(anim, true);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		//trace(id, sender);
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && sender == imageInputText) {
			var ap:String = imageInputText.text.trim();
			character.jsonFile.assetPath = ap;
			character.jsonFile.image = ap;
			unsavedProgress = true;
		} else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			if(sender == scaleStepper) {
				character.jsonFile.scale = scaleStepper.value;
				reloadCharacter();
			} else if(sender == xStepper) {
				if(character.jsonFile.position == null) character.jsonFile.position = [0, 0];
				character.jsonFile.position[0] = xStepper.value;
				character.jsonFile.dialogueOffsets = character.jsonFile.position;
				reloadCharacter();
			} else if(sender == yStepper) {
				if(character.jsonFile.position == null) character.jsonFile.position = [0, 0];
				character.jsonFile.position[1] = yStepper.value;
				character.jsonFile.dialogueOffsets = character.jsonFile.position;
				reloadCharacter();
			}
			unsavedProgress = true;
		}
	}

	var currentGhosts:Int = 0;
	var lastTab:String = 'Character';
	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		super.update(elapsed);
		if(transitioning)
			return;

		if(character.animation.curAnim != null) {
			if(daText.finishedText) {
				if(character.animationIsLoop()) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			} else if(character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		if(PsychUIInputText.focusOn == null)
		{
			Preferences.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.SPACE && UI_mainbox.selectedName == 'Character') {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
				daText.resetDialogue();
				updateTextBox();
			}

			//lots of Ifs lol get trolled
			var offsetAdd:Int = 1;
			var speed:Float = 300;
			if(FlxG.keys.pressed.SHIFT) {
				speed = 1200;
				offsetAdd = 10;
			}

			var negaMult:Array<Int> = [1, 1, -1, -1];
			var controlArray:Array<Bool> = [FlxG.keys.pressed.J, FlxG.keys.pressed.I, FlxG.keys.pressed.L, FlxG.keys.pressed.K];
			for (i in 0...controlArray.length) {
				if(controlArray[i]) {
					if(i % 2 == 1) {
						mainGroup.y += speed * elapsed * negaMult[i];
					} else {
						mainGroup.x += speed * elapsed * negaMult[i];
					}
				}
			}

			if(UI_mainbox.selectedName == 'Animations' && curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim)) {
				var moved:Bool = false;
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				var controlArrayLoop:Array<Bool> = [FlxG.keys.justPressed.A, FlxG.keys.justPressed.W, FlxG.keys.justPressed.D, FlxG.keys.justPressed.S];
				var controlArrayIdle:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.DOWN];
				for (i in 0...controlArrayLoop.length) {
					if(controlArrayLoop[i]) {
						if(i % 2 == 1) {
							animShit.loop_offsets[1] += offsetAdd * negaMult[i];
						} else {
							animShit.loop_offsets[0] += offsetAdd * negaMult[i];
						}
						moved = true;
					}
				}
				for (i in 0...controlArrayIdle.length) {
					if(controlArrayIdle[i]) {
						if(i % 2 == 1) {
							animShit.idle_offsets[1] += offsetAdd * negaMult[i];
						} else {
							animShit.idle_offsets[0] += offsetAdd * negaMult[i];
						}
						moved = true;
					}
				}

				if(moved) {
					offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
					offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
					ghostLoop.offset.set(animShit.loop_offsets[0], animShit.loop_offsets[1]);
					ghostIdle.offset.set(animShit.idle_offsets[0], animShit.idle_offsets[1]);
				}
			}

			if (FlxG.keys.pressed.Q && camGame.zoom > 0.1) {
				camGame.zoom -= elapsed * camGame.zoom;
				if(camGame.zoom < 0.1) camGame.zoom = 0.1;
			}
			if (FlxG.keys.pressed.E && camGame.zoom < 1) {
				camGame.zoom += elapsed * camGame.zoom;
				if(camGame.zoom > 1) camGame.zoom = 1;
			}
			if(FlxG.keys.justPressed.H) {
				if(UI_mainbox.selectedName == 'Animations') {
					currentGhosts++;
					if(currentGhosts > 2) currentGhosts = 0;

					ghostLoop.visible = (currentGhosts != 1);
					ghostIdle.visible = (currentGhosts != 2);
					ghostLoop.alpha = (currentGhosts == 2 ? 1 : 0.6);
					ghostIdle.alpha = (currentGhosts == 1 ? 1 : 0.6);
				} else {
					hudGroup.visible = !hudGroup.visible;
				}
			}
			if(FlxG.keys.justPressed.R) {
				camGame.zoom = 1;
				mainGroup.setPosition(0, 0);
				hudGroup.visible = true;
			}

			if(UI_mainbox.selectedName != lastTab) {
				if(UI_mainbox.selectedName == 'Animations') {
					hudGroup.alpha = 0;
					mainGroup.alpha = 0;
					ghostLoop.alpha = 0.6;
					ghostIdle.alpha = 0.6;
					tipText.text = TIP_TEXT_OFFSET;
					offsetLoopText.visible = true;
					offsetIdleText.visible = true;
					animText.visible = false;
					currentGhosts = 0;
				} else {
					hudGroup.alpha = 1;
					mainGroup.alpha = 1;
					ghostLoop.alpha = 0;
					ghostIdle.alpha = 0;
					tipText.text = TIP_TEXT_MAIN;
					offsetLoopText.visible = false;
					offsetIdleText.visible = false;
					animText.visible = true;
					updateTextBox();
					daText.resetDialogue();
					
					if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
					else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;
					
					character.playAnim(character.jsonFile.animations[curAnim].anim);
					animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}
				lastTab = UI_mainbox.selectedName;
				currentGhosts = 0;
			}
			
			if(UI_mainbox.selectedName == 'Character')
			{
				var negaMult:Array<Int> = [1, -1];
				var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];

				if(controlAnim.contains(true))
				{
					for (i in 0...controlAnim.length) {
						if(controlAnim[i] && character.jsonFile.animations.length > 0) {
							curAnim -= negaMult[i];
							if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
							else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;

							var animToPlay:String = character.jsonFile.animations[curAnim].anim;
							if(character.dialogueAnimations.exists(animToPlay)) {
								character.playAnim(animToPlay, daText.finishedText);
							}
						}
					}
					animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}
			}

			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
					transitioning = true;
				}
				else openSubState(new funkin.states.editors.components.Prompt.ExitConfirmationPrompt(function() transitioning = true));
			}

			ghostLoop.setPosition(character.x, character.y);
			ghostIdle.setPosition(character.x, character.y);
			hudGroup.x = mainGroup.x;
			hudGroup.y = mainGroup.y;
		}
		else Preferences.toggleVolumeKeys(false);
	}
	
	var _file:FileReference = null;
	function loadCharacter() {
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

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var parsed:Dynamic = Json.parse(rawJson);
				// Accept new format (assetPath / dialogueType / dialogue_animations) or legacy
				var isDialogue:Bool = parsed != null && (
					Reflect.hasField(parsed, 'dialogue_pos') || Reflect.hasField(parsed, 'dialogueType') ||
					Reflect.hasField(parsed, 'assetPath') || Reflect.hasField(parsed, 'dialogue_animations') ||
					Reflect.hasField(parsed, 'animations')
				);
				if(isDialogue)
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					// Re-parse through DialogueCharacter normalizer
					character.curCharacter = cutName;
					// Write temp-style normalize by assigning via reloadCharacterJson path:
					// Use internal normalize by reloading from the raw JSON string fields
					applyLoadedDialogueJson(parsed, cutName);
					reloadCharacter();
					reloadAnimationsDropDown();
					updateCharTypeBox();
					updateTextBox();
					daText.resetDialogue();
					var ap:String = character.jsonFile.assetPath;
					if(ap == null || ap.length < 1) ap = character.jsonFile.image;
					imageInputText.text = ap != null ? ap : '';
					scaleStepper.value = character.jsonFile.scale;
					if(character.jsonFile.position != null && character.jsonFile.position.length > 0)
						xStepper.value = character.jsonFile.position[0];
					if(character.jsonFile.position != null && character.jsonFile.position.length > 1)
						yStepper.value = character.jsonFile.position[1];
					if(flipXCheckbox != null)
						flipXCheckbox.checked = character.jsonFile.flip_x == true;
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
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
	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveCharacter() {
		var exportData:Dynamic = buildExportDialogueJson();
		var data:String = haxe.Json.stringify(exportData, "\t");
		if (data.length > 0)
		{
			var asset:String = imageInputText != null ? imageInputText.text.trim() : '';
			if(asset.length < 1 && character.jsonFile.assetPath != null) asset = character.jsonFile.assetPath;
			var base:String = asset.replace('\\', '/');
			if(base.contains('/')) base = base.substr(base.lastIndexOf('/') + 1);
			base = base.toLowerCase().replace(' ', '');
			if(base.endsWith('.png') || base.endsWith('.xml')) base = base.substr(0, base.lastIndexOf('.'));
			if(base.length < 1) base = character.curCharacter != null ? character.curCharacter : 'character';

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			// Preferred save name matches data/dialogue/<name>.json
			_file.save(data, base + ".json");
		}
	}

	/** Build the new dialogue character JSON format for export. */
	function buildExportDialogueJson():Dynamic
	{
		var anims:Array<Dynamic> = [];
		if(character.jsonFile.animations != null)
		{
			for (a in character.jsonFile.animations)
			{
				if(a == null) continue;
				var off:Array<Int> = a.loop_offsets != null ? a.loop_offsets : [0, 0];
				anims.push({
					offsets: off,
					name: a.anim,
					prefix: a.loop_name,
					fps: Reflect.hasField(a, 'fps') ? Std.int(Std.parseFloat(Std.string(Reflect.field(a, 'fps')))) : 24,
					loop: a.loop != false
				});
			}
		}

		var asset:String = character.jsonFile.assetPath;
		if(asset == null || asset.length < 1) asset = character.jsonFile.image;
		if(asset == null) asset = '';

		var dtype:String = character.jsonFile.dialogueType;
		if(dtype == null || dtype.length < 1) dtype = character.jsonFile.dialogue_pos;
		if(dtype == null || dtype.length < 1) dtype = 'right';

		var offsets:Array<Float> = [0, 0];
		if(character.jsonFile.position != null && character.jsonFile.position.length > 0)
			offsets[0] = character.jsonFile.position[0];
		if(character.jsonFile.position != null && character.jsonFile.position.length > 1)
			offsets[1] = character.jsonFile.position[1];

		return {
			dialogue_animations: anims,
			assetPath: asset,
			dialogueOffsets: offsets,
			flip_x: character.jsonFile.flip_x == true,
			dialogueType: dtype,
			scale: character.jsonFile.scale
		};
	}

	/** Apply a loaded raw JSON (new or legacy) onto character.jsonFile. */
	function applyLoadedDialogueJson(parsed:Dynamic, characterName:String):Void
	{
		// Reuse DialogueCharacter normalization by temporarily writing through reload path
		var dc = character;
		// Store as string and re-parse with the same logic used at runtime
		var tmp:String = haxe.Json.stringify(parsed);
		// Manual normalize mirroring DialogueCharacter.normalizeDialogueCharacterFile
		var file:DialogueCharacterFile = {
			image: '',
			assetPath: '',
			dialogue_pos: 'left',
			dialogueType: 'left',
			no_antialiasing: false,
			animations: [],
			dialogue_animations: [],
			position: [0, 0],
			dialogueOffsets: [0, 0],
			scale: 1,
			flip_x: false
		};

		var assetPath:Dynamic = Reflect.field(parsed, 'assetPath');
		if(assetPath == null) assetPath = Reflect.field(parsed, 'image');
		if(assetPath != null)
		{
			file.assetPath = Std.string(assetPath);
			file.image = file.assetPath;
		}

		var offsets:Dynamic = Reflect.field(parsed, 'dialogueOffsets');
		if(offsets == null) offsets = Reflect.field(parsed, 'position');
		if(Std.isOfType(offsets, Array))
		{
			var arr:Array<Dynamic> = cast offsets;
			file.position = [
				arr.length > 0 ? Std.parseFloat(Std.string(arr[0])) : 0,
				arr.length > 1 ? Std.parseFloat(Std.string(arr[1])) : 0
			];
			file.dialogueOffsets = file.position;
		}

		var dtype:Dynamic = Reflect.field(parsed, 'dialogueType');
		if(dtype == null) dtype = Reflect.field(parsed, 'dialogue_pos');
		if(dtype != null)
		{
			file.dialogueType = Std.string(dtype).toLowerCase();
			file.dialogue_pos = file.dialogueType;
		}

		var sc:Dynamic = Reflect.field(parsed, 'scale');
		if(sc != null)
		{
			var p = Std.parseFloat(Std.string(sc));
			if(!Math.isNaN(p) && p > 0) file.scale = p;
		}

		var flip:Dynamic = Reflect.field(parsed, 'flip_x');
		if(flip == null) flip = Reflect.field(parsed, 'flipX');
		file.flip_x = (flip == true);

		if(Reflect.hasField(parsed, 'no_antialiasing'))
			file.no_antialiasing = Reflect.field(parsed, 'no_antialiasing') == true;

		var animsRaw:Dynamic = Reflect.field(parsed, 'dialogue_animations');
		if(animsRaw == null) animsRaw = Reflect.field(parsed, 'animations');
		var anims:Array<DialogueAnimArray> = [];
		if(Std.isOfType(animsRaw, Array))
		{
			var arr:Array<Dynamic> = cast animsRaw;
			for (entry in arr)
			{
				if(entry == null) continue;
				var name:String = Reflect.hasField(entry, 'name') ? Std.string(Reflect.field(entry, 'name')) :
					(Reflect.hasField(entry, 'anim') ? Std.string(Reflect.field(entry, 'anim')) : 'talk');
				var prefix:String = Reflect.hasField(entry, 'prefix') ? Std.string(Reflect.field(entry, 'prefix')) :
					(Reflect.hasField(entry, 'loop_name') ? Std.string(Reflect.field(entry, 'loop_name')) : name);
				var idle:String = Reflect.hasField(entry, 'idle_name') ? Std.string(Reflect.field(entry, 'idle_name')) : prefix;
				var fps:Int = Reflect.hasField(entry, 'fps') ? Std.int(Std.parseFloat(Std.string(Reflect.field(entry, 'fps')))) : 24;
				var loop:Bool = !Reflect.hasField(entry, 'loop') || Reflect.field(entry, 'loop') == true;
				var off:Array<Int> = [0, 0];
				var offRaw:Dynamic = Reflect.field(entry, 'offsets');
				if(offRaw == null) offRaw = Reflect.field(entry, 'loop_offsets');
				if(Std.isOfType(offRaw, Array))
				{
					var oa:Array<Dynamic> = cast offRaw;
					if(oa.length > 0) off[0] = Std.int(Std.parseFloat(Std.string(oa[0])));
					if(oa.length > 1) off[1] = Std.int(Std.parseFloat(Std.string(oa[1])));
				}
				anims.push({
					anim: name,
					loop_name: prefix,
					loop_offsets: off,
					idle_name: idle,
					idle_offsets: off.copy(),
					fps: fps,
					loop: loop
				});
			}
		}
		file.animations = anims;
		file.dialogue_animations = cast anims;
		character.jsonFile = file;
		character.curCharacter = characterName;
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}