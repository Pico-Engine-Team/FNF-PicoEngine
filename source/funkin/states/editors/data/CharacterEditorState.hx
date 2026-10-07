package funkin.states.editors.data;

import funkin.play.Song;
import funkin.data.objects.Bar;
import funkin.data.objects.HealthIcon;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.characters.Character;

import funkin.states.editors.components.Prompt;
import funkin.utils.engines.psych.PsychJsonPrinter;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);
	static inline var CHARACTER_TYPE_PLAYER:String = 'Player';
	static inline var CHARACTER_TYPE_OPPONENT:String = 'Opponent';
	static inline var CHARACTER_TYPE_ADDITIONAL:String = 'Additional';
	static final CHARACTER_TYPES:Array<String> = [CHARACTER_TYPE_PLAYER, CHARACTER_TYPE_OPPONENT, CHARACTER_TYPE_ADDITIONAL];

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/characterEditor/silhouetteDad'));
		dad.antialiasing = Preferences.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/characterEditor/silhouetteBF'));
		boyfriend.antialiasing = Preferences.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);
		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);
		
		animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];
		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		healthIcon.cameras = [camHUD];

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;
		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if(Preferences.data.cacheOnGPU) Paths.clearUnusedMemory();
		super.create();
	}

	function addHelpScreen() {
		var str:Array<String> = ["CAMERA",
		"E/Q - Camera Zoom In/Out",
		"J/K/L/I - Move Camera",
		"R - Reset Camera Zoom",
		"",
		"CHARACTER",
		"Ctrl + R - Reset Current Offset",
		"Ctrl + C - Copy Current Offset",
		"Ctrl + V - Paste Copied Offset on Current Animation",
		"Ctrl + Z - Undo Last Paste or Reset",
		"W/S - Previous/Next Animation",
		"Space - Replay Animation",
		"Arrow Keys/Mouse & Right Click - Move Offset",
		"A/D - Frame Advance (Back/Forward)",
		"",
		"OTHER",
		"F12 - Toggle Silhouettes",
		"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
		"Hold Control - Move camera 4x slower"];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		var requestedType:String = character != null ? getCharacterType() : predictCharacterType(_char);
		if(character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		if(!reload) requestedType = predictCharacterType(_char);
		var isPlayer:Bool = (requestedType == CHARACTER_TYPE_PLAYER);
		character = new Character(0, 0, _char, isPlayer);
		if(!reload)
		{
			if(character.editorCharacterType != null)
				requestedType = normalizeCharacterType(character.editorCharacterType);
			else if(character.editorIsPlayer != null)
				requestedType = character.editorIsPlayer ? CHARACTER_TYPE_PLAYER : CHARACTER_TYPE_OPPONENT;
		}
		applyCharacterType(requestedType);
		character.debugMode = true;
		character.missingCharacter = false;

		if(pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if(healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu()
	{
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 165, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character', 'Extra']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();
		addExtraUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
	{
		var tab_group = UI_box.getTab('Ghost').menu;

		//var hideGhostButton:PsychUIButton = null;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if(!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);
					
					if(myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}
				
				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
				hideGhostButton.alpha = 1;*/
				trace('created ghost image');
			}
		});

		/*hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
			ghost.visible = false;
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6;
		});
		hideGhostButton.active = false;
		hideGhostButton.alpha = 0.6;*/

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float)
		{
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;

		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		//tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var characterTypeDropDown:PsychUIDropDownMenu;
	var renderTypeDropDown:PsychUIDropDownMenu;
	var charDropDown:PsychUIDropDownMenu;
	function addSettingsUI()
	{
		var tab_group = UI_box.getTab('Settings').menu;

		characterTypeDropDown = new PsychUIDropDownMenu(10, 80, CHARACTER_TYPES, function(index:Int, type:String)
		{
			applyCharacterType(type, true);
		});
		characterTypeDropDown.selectedLabel = getCharacterType();

		isPixelCheckBox = new PsychUICheckBox(characterTypeDropDown.x, characterTypeDropDown.y + 40, "Is Pixel", 100);
		isPixelCheckBox.checked = character.noAntialiasing;
		isPixelCheckBox.onClick = function()
		{
			character.noAntialiasing = isPixelCheckBox.checked;
			character.antialiasing = Preferences.data.antialiasing ? !character.noAntialiasing : false;
			unsavedProgress = true;
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				isPixel: false,
				flip_x: false,
				healthicon: 'face',
				assetPath: 'characters/bf/Boyfriend',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				positionOffsets: [0, 0],
				cameraOffsets: [0, 0],
				vocals_file: null
			};

			character.loadCharacterFile(_template);
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;


		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String)
		{
			if(intended == null || intended.length < 1) return;

			var characterPath:String = 'data/characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;


		renderTypeDropDown = new PsychUIDropDownMenu(characterTypeDropDown.x, characterTypeDropDown.y + 70, Character.getSupportedRenderTypes(), function(id:Int, type:String)
		{
			character.setRenderType(type, true);
			if(renderTypeDropDown != null)
				renderTypeDropDown.selectedLabel = character.renderType != null ? character.renderType : 'sparrow';
			unsavedProgress = true;
		});
		var currentRender:String = Character.normalizeRenderType(character.renderType);
		if(currentRender.length < 1)
			currentRender = Character.detectRenderType(character.imageFile, Character.collectAnimationAssetPaths(character.imageFile, character.animationsArray));
		renderTypeDropDown.selectedLabel = currentRender;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(new FlxText(characterTypeDropDown.x, characterTypeDropDown.y - 18, 100, 'Character Type:'));
		tab_group.add(new FlxText(renderTypeDropDown.x, renderTypeDropDown.y - 18, 100, 'Render Type:'));
		tab_group.add(characterTypeDropDown);
		tab_group.add(isPixelCheckBox);
		tab_group.add(renderTypeDropDown);
		var detectRenderBtn:PsychUIButton = new PsychUIButton(renderTypeDropDown.x + 120, renderTypeDropDown.y, "Auto Detect", function()
		{
			var multi:String = Character.collectAnimationAssetPaths(character.imageFile, character.animationsArray);
			var detected:String = Character.detectRenderType(character.imageFile, multi);
			character.setRenderType(detected, true);
			if(renderTypeDropDown != null)
				renderTypeDropDown.selectedLabel = character.renderType;
			unsavedProgress = true;
		}, 90);
		tab_group.add(detectRenderBtn);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationAssetPathInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationAssetPathInputText = new PsychUIInputText(animationIndicesInputText.x, animationIndicesInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Is Loop?", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationAssetPathInputText.text = Character.getAnimationAssetPathInput(anim.assetPath);
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationAssetPathInputText.y + 45, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if(indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if(indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if(ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if(Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if(Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd+1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if(!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastOffsets:Array<Int> = [0, 0];
			var lastPlayerOffsets:Array<Float> = [0, 0];
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(anim.playerOffsets != null && anim.playerOffsets.length > 1)
						lastPlayerOffsets = [anim.playerOffsets[0], anim.playerOffsets[1]];
					else if(anim.offsets != null)
						lastPlayerOffsets = [anim.offsets[0] * 1.0, anim.offsets[1] * 1.0];
					if(character.hasAnimation(animationInputText.text))
					{
						if(!character.isAnimateAtlas) character.animation.remove(animationInputText.text);
						else @:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
					character.animOffsets.remove(animationInputText.text);
					if(character.animPlayerOffsets != null)
						character.animPlayerOffsets.remove(animationInputText.text);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addedAnim.playerOffsets = lastPlayerOffsets;
			addedAnim.assetPath = Character.getAnimationAssetPathInput(animationAssetPathInputText.text);
			character.animationsArray.push(addedAnim);
			character.addOffset(addedAnim.anim, lastOffsets[0], lastOffsets[1]);
			character.addPlayerOffset(addedAnim.anim, lastPlayerOffsets[0], lastPlayerOffsets[1]);

			reloadCharacterImage();
			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationAssetPathInputText.y + 45, "Remove", function() {
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == character.getAnimationName()) resetAnim = true;
					if(character.hasAnimation(anim.anim))
					{
						if(!character.isAnimateAtlas) character.animation.remove(anim.anim);
						else @:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						if(character.animPlayerOffsets != null) character.animPlayerOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if(resetAnim && character.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						character.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Prefix:'));
		tab_group.add(new FlxText(animationAssetPathInputText.x, animationAssetPathInputText.y - 18, 170, 'Animation Asset Path:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'FrameIndices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationAssetPathInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;
	var gameOverSndInputText:PsychUIInputText;
	var gameOverLoopInputText:PsychUIInputText;
	var gameOverRetryInputText:PsychUIInputText;
	var noteStyleDropDown:PsychUIDropDownMenu;
	var gameOverCharDropDown:PsychUIDropDownMenu;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var isPixelCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;
	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile, 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
				character.healthColorArray[0] = coolColor.red;
				character.healthColorArray[1] = coolColor.green;
				character.healthColorArray[2] = coolColor.blue;
				updateHealthBar();
			});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if(character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function() {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 1, character.positionArray[0], -9000, 9000, 2);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 1, character.positionArray[1], -9000, 9000, 2);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 1, character.cameraPosition[0], -9000, 9000, 2);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 1, character.cameraPosition[1], -9000, 9000, 2);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, positionCameraXStepper.y + 40, "Save", function() {
			saveCharacter();
		});

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Asset path:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Offsets:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera Offsets:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health Bar Color:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
	}

	function addExtraUI()
	{
		var tab_group = UI_characterbox.getTab('Extra').menu;
		var objX:Float = 15;
		var objY:Float = 30;

		// Row 1: Game Over Character | Note Style (side by side)
		gameOverCharDropDown = new PsychUIDropDownMenu(objX, objY, [''], function(id:Int, characterName:String)
		{
			character.gameOverChar = characterName;
			unsavedProgress = true;
		});
		reloadGameOverCharacterDropDown();

		noteStyleDropDown = new PsychUIDropDownMenu(objX + 160, objY, getCharacterNoteStyleDropDownList(), function(id:Int, noteStyle:String)
		{
			setCharacterNoteStyle(noteStyle);
			unsavedProgress = true;
		});
		reloadNoteStyleDropDown();

		objY += 40;
		gameOverSndInputText = new PsychUIInputText(objX, objY, 120, character.gameOverSound != null ? character.gameOverSound : '', 8);
		gameOverSndInputText.onChange = function(old:String, cur:String)
		{
			character.gameOverSound = cur;
			unsavedProgress = true;
		};

		objY += 40;
		gameOverLoopInputText = new PsychUIInputText(objX, objY, 120, character.gameOverLoop != null ? character.gameOverLoop : '', 8);
		gameOverLoopInputText.onChange = function(old:String, cur:String)
		{
			character.gameOverLoop = cur;
			unsavedProgress = true;
		};

		objY += 40;
		gameOverRetryInputText = new PsychUIInputText(objX, objY, 120, character.gameOverEnd != null ? character.gameOverEnd : '', 8);
		gameOverRetryInputText.onChange = function(old:String, cur:String)
		{
			character.gameOverEnd = cur;
			unsavedProgress = true;
		};

		tab_group.add(new FlxText(gameOverCharDropDown.x, gameOverCharDropDown.y - 15, 150, 'Game Over Character:'));
		tab_group.add(new FlxText(noteStyleDropDown.x, noteStyleDropDown.y - 15, 150, 'Note Style (pico):'));
		tab_group.add(new FlxText(gameOverSndInputText.x, gameOverSndInputText.y - 15, 200, 'Game Over Death Sound (sounds/):'));
		tab_group.add(new FlxText(gameOverLoopInputText.x, gameOverLoopInputText.y - 15, 200, 'Game Over Loop Music (music/):'));
		tab_group.add(new FlxText(gameOverRetryInputText.x, gameOverRetryInputText.y - 15, 200, 'Game Over Retry Music (music/):'));
		tab_group.add(gameOverSndInputText);
		tab_group.add(gameOverLoopInputText);
		tab_group.add(gameOverRetryInputText);
		tab_group.add(noteStyleDropDown);
		tab_group.add(gameOverCharDropDown);
	}

	function getCharacterNoteStyleDropDownList():Array<String>
	{
		// Character note styles come from pico_assets/game/custom-notes (NOT data/notestyles)
		var list:Array<String> = getPicoCustomNoteStyleList();
		var selected:String = getCharacterNoteStyleLabel(character.noteStyle);
		if(selected.length > 0 && !list.contains(selected))
			list.insert(0, selected);
		if(!list.contains(''))
			list.insert(0, '');
		return list;
	}

	/**
	 * Reads pico_assets/game/custom-notes/list.txt and/or data/*.json
	 */
	function getPicoCustomNoteStyleList():Array<String>
	{
		var list:Array<String> = [];
		#if sys
		try
		{
			var listPath:String = Paths.getPicoFunkinFolder('game/custom-notes/list.txt');
			if(listPath != null && sys.FileSystem.exists(listPath))
			{
				var content:String = sys.io.File.getContent(listPath);
				if(content != null)
				{
					for (line in content.split('\n'))
					{
						var name:String = StringTools.trim(line);
						if(name.length < 1 || name.startsWith('#')) continue;
						if(name.toLowerCase().endsWith('.json'))
							name = name.substr(0, name.length - 5);
						if(!list.contains(name))
							list.push(name);
					}
				}
			}

			var dataDir:String = Paths.getPicoFunkinFolder('game/custom-notes/data');
			if(dataDir != null && sys.FileSystem.exists(dataDir) && sys.FileSystem.isDirectory(dataDir))
			{
				for (file in sys.FileSystem.readDirectory(dataDir))
				{
					if(file == null) continue;
					var lower:String = file.toLowerCase();
					if(!lower.endsWith('.json')) continue;
					var name:String = file.substr(0, file.length - 5);
					if(name.length > 0 && !list.contains(name))
						list.push(name);
				}
			}
		}
		catch(e:Dynamic)
		{
			trace('[CharacterEditor] Failed to list pico custom notes: $e');
		}
		#end
		list.sort(function(a:String, b:String) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return list;
	}

	function reloadNoteStyleDropDown()
	{
		if(noteStyleDropDown == null) return;

		var list:Array<String> = getCharacterNoteStyleDropDownList();
		noteStyleDropDown.list = list;
		noteStyleDropDown.selectedLabel = getCharacterNoteStyleLabel(character.noteStyle);
	}

	function getCharacterNoteStyleLabel(noteStyle:String):String
	{
		if(noteStyle == null || noteStyle.trim().length < 1)
			return '';

		var clean:String = Note.normalizeCharacterNoteStyleName(noteStyle);
		if(clean.length < 1)
			clean = noteStyle.trim();

		var list:Array<String> = getPicoCustomNoteStyleList();
		if(list.contains(clean))
			return clean;
		return clean;
	}

	function setCharacterNoteStyle(noteStyle:String)
	{
		if(noteStyle == null || noteStyle.trim().length < 1)
		{
			character.noteStyle = null;
			return;
		}
		var clean:String = Note.normalizeCharacterNoteStyleName(noteStyle);
		character.noteStyle = clean.length > 0 ? clean : noteStyle.trim();
	}

	public function UIEvent(id:String, sender:Dynamic) {
		//trace(id, sender);
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT)
		{
			if(sender == healthIconInputText) {
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if(lastIcon != healthIcon.getCharacter()) updatePresence();
				unsavedProgress = true;
			}
			else if(sender == vocalsInputText)
			{
				character.vocalsFile = vocalsInputText.text;
				unsavedProgress = true;
			}
			else if(sender == gameOverSndInputText)
			{
				character.gameOverSound = gameOverSndInputText.text;
				unsavedProgress = true;
			}
			else if(sender == gameOverLoopInputText)
			{
				character.gameOverLoop = gameOverLoopInputText.text;
				unsavedProgress = true;
			}
			else if(sender == gameOverRetryInputText)
			{
				character.gameOverEnd = gameOverRetryInputText.text;
				unsavedProgress = true;
			}
			else if(sender == imageInputText)
			{
				character.imageFile = imageInputText.text;
				unsavedProgress = true;
			}
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper)
			{
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
				unsavedProgress = true;
			}
			else if(sender == positionXStepper)
			{
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if(sender == positionYStepper)
			{
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			}
			else if(sender == singDurationStepper)
			{
				character.singDuration = singDurationStepper.value;
				unsavedProgress = true;
			}
			else if(sender == positionCameraXStepper)
			{
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if(sender == positionCameraYStepper)
			{
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperR)
			{
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperG)
			{
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
				unsavedProgress = true;
			}
			else if(sender == healthColorStepperB)
			{
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
				unsavedProgress = true;
			}
		}
	}

	function reloadCharacterImage()
	{
		character.color = FlxColor.WHITE;
		character.alpha = 1;
		var type:String = Character.normalizeRenderType(character.renderType);
		if(type.length < 1)
		{
			var multi:String = Character.collectAnimationAssetPaths(character.imageFile, character.animationsArray);
			type = Character.detectRenderType(character.imageFile, multi);
		}
		character.setRenderType(type, true);
		if(renderTypeDropDown != null)
			renderTypeDropDown.selectedLabel = character.renderType != null ? character.renderType : 'sparrow';
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		if(characterTypeDropDown != null) characterTypeDropDown.selectedLabel = getCharacterType();
		if(isPixelCheckBox != null) isPixelCheckBox.checked = character.noAntialiasing;
		if(renderTypeDropDown != null)
		{
			var rt:String = Character.normalizeRenderType(character.renderType);
			if(rt.length < 1) rt = 'sparrow';
			renderTypeDropDown.selectedLabel = rt;
		}
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		healthIcon.changeIcon(character.healthIcon, false);
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		if(gameOverCharDropDown != null)
		{
			reloadGameOverCharacterDropDown();
			gameOverCharDropDown.selectedLabel = character.gameOverChar != null ? character.gameOverChar : '';
		}
		if(gameOverSndInputText != null) gameOverSndInputText.text = character.gameOverSound != null ? character.gameOverSound : '';
		if(gameOverLoopInputText != null) gameOverLoopInputText.text = character.gameOverLoop != null ? character.gameOverLoop : '';
		if(gameOverRetryInputText != null) gameOverRetryInputText.text = character.gameOverEnd != null ? character.gameOverEnd : '';
		if(noteStyleDropDown != null) reloadNoteStyleDropDown();
		reloadAnimationDropDown();
		updateHealthBar();
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(PsychUIInputText.focusOn != null)
		{
			Preferences.toggleVolumeKeys(false);
			return;
		}
		Preferences.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1)
		{
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.keys.pressed.CONTROL)
		{
			if(FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		if(changedOffset && anim != null)
		{
			// BETADCIU-style: player side writes playerOffsets
			if(character.isPlayer)
			{
				if(anim.playerOffsets == null)
					anim.playerOffsets = [0.0, 0.0];
				anim.playerOffsets[0] = character.offset.x;
				anim.playerOffsets[1] = character.offset.y;
				character.addPlayerOffset(anim.anim, character.offset.x, character.offset.y);
			}
			else
			{
				if(anim.offsets == null)
					anim.offsets = [0, 0];
				anim.offsets[0] = Std.int(character.offset.x);
				anim.offsets[1] = Std.int(character.offset.y);
				character.addOffset(anim.anim, character.offset.x, character.offset.y);
			}
			unsavedProgress = true;
			updateText();
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if(!character.isAnimationNull())
		{
			if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if(FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;
			if(!character.isAnimateAtlas && character.animation.curAnim != null)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			else if(character.isAnimateAtlas && character.atlas.anim != null)
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if(length >= 0)
			{
				if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
				{
					var isLeft = false;
					if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
					character.animPaused = true;
	
					if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
					{
						frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
						if(!character.isAnimateAtlas) character.animation.curAnim.curFrame = frames;
						else character.atlas.anim.curFrame = frames;
						holdingFrameElapsed -= 0.1;
					}
				}
	
				txt = 'Frames: ( $frames / ${length-1} )';
				//if(character.animation.curAnim.paused) txt += ' - PAUSED';
				clr = FlxColor.WHITE;
			}
		}
		if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;

		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if(FlxG.keys.justPressed.ESCAPE)
		{
			if(!_goToPlayState)
			{
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new funkin.states.editors.EditorsMenus());
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'));
				}
				else openSubState(new funkin.states.editors.components.Prompt.ExitConfirmationPrompt());
			}
			else
			{
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new PlayState());
			}
			return;
		}
	}

	final assetFolder = 'week1';
	inline function loadBG()
	{
		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		#if !BASE_GAME_FILES
		camEditor.bgColor = 0xFF666666;
		#else
		var bg:BGSprite = new BGSprite('stages/weeks/week1/stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stages/weeks/week1/stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		#end

		bfPosition.set(770, 100);
		dadPosition.set(100, 100);

		Paths.currentLevel = lastLoaded;
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		if(character == null || cameraFollowPointer == null) return;

		var offX:Float = 0;
		var offY:Float = 0;
		if(!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if(snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width/2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height/2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if(anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		updateText();
		if(animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = 'Offsets:\n';
		for (num => anim in anims)
		{
			if(num > 0) intendText += '\n';

			var line:String = anim.anim + ": " + anim.offsets;
			if(num == curAnim && !character.isPlayer)
			{
				var n:Int = intendText.length;
				intendText += line;
				animsTxt.addFormat(selectedFormat, n, intendText.length);
			}
			else intendText += line;
		}

		// BETADCIU: lista de playerOffsets
		intendText += '\n\nPlayer Offsets:\n';
		for (num => anim in anims)
		{
			if(num > 0) intendText += '\n';

			var pOff:Array<Float> = anim.playerOffsets;
			if(pOff == null && anim.offsets != null)
				pOff = [anim.offsets[0] * 1.0, anim.offsets[1] * 1.0];
			else if(pOff == null)
				pOff = [0.0, 0.0];
			var line:String = anim.anim + ": " + pOff;
			if(num == curAnim && character.isPlayer)
			{
				var n:Int = intendText.length;
				intendText += line;
				animsTxt.addFormat(selectedFormat, n, intendText.length);
			}
			else intendText += line;
		}

		animsTxt.text = intendText;
	}

	inline function updateCharacterPositions()
	{
		if((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return predictCharacterType(name) != CHARACTER_TYPE_PLAYER;
	}

	function normalizeCharacterType(type:String):String
	{
		if(type == null) return CHARACTER_TYPE_OPPONENT;

		var clean:String = Paths.formatToSongPath(type.trim());
		switch(clean)
		{
			case 'player', 'playable', 'bf', 'boyfriend':
				return CHARACTER_TYPE_PLAYER;
			case 'additional', 'addtinal', 'extra', 'gf', 'girlfriend':
				return CHARACTER_TYPE_ADDITIONAL;
			case 'opponent', 'dad':
				return CHARACTER_TYPE_OPPONENT;
		}

		return CHARACTER_TYPE_OPPONENT;
	}

	function getCharacterType():String
	{
		if(character == null) return predictCharacterType(_char);
		if(character.editorCharacterType != null && character.editorCharacterType.trim().length > 0)
			return normalizeCharacterType(character.editorCharacterType);
		if(character.editorIsPlayer != null)
			return character.editorIsPlayer ? CHARACTER_TYPE_PLAYER : CHARACTER_TYPE_OPPONENT;

		return character.isPlayer ? CHARACTER_TYPE_PLAYER : CHARACTER_TYPE_OPPONENT;
	}

	function applyCharacterType(type:String, updateDisplay:Bool = false)
	{
		if(character == null) return;

		var normalizedType:String = normalizeCharacterType(type);
		character.editorCharacterType = normalizedType;
		character.editorIsPlayer = (normalizedType == CHARACTER_TYPE_PLAYER);
		character.isPlayer = (normalizedType == CHARACTER_TYPE_PLAYER);
		character.flipX = (character.originalFlipX != character.isPlayer);

		if(characterTypeDropDown != null)
			characterTypeDropDown.selectedLabel = normalizedType;

		if(updateDisplay)
			updateCharacterPositions();
	}

	function predictCharacterType(name:String):String
	{
		if(name == null || name.length < 1) return CHARACTER_TYPE_OPPONENT;

		var formatted:String = Paths.formatToSongPath(name);
		if(formatted == 'gf' || formatted.startsWith('gf-') || formatted.endsWith('-gf') || formatted.endsWith('-speaker') || formatted == 'none')
			return CHARACTER_TYPE_ADDITIONAL;
		if(formatted.endsWith('-opponent'))
			return CHARACTER_TYPE_OPPONENT;
		if(formatted == 'bf' || formatted.startsWith('bf-') || formatted.endsWith('-player') || formatted.endsWith('-playable') || formatted.endsWith('-dead') || formatted.endsWith('-death'))
			return CHARACTER_TYPE_PLAYER;

		return CHARACTER_TYPE_OPPONENT;
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if(anim == null || anim.trim().length < 1 || name == null || name.trim().length < 1)
			return;

		if(!character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if(indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if(!character.hasAnimation(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			assetPath: '',
			offsets: [0, 0],
			playerOffsets: [0.0, 0.0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
		reloadGameOverCharacterDropDown();
	}

	function reloadGameOverCharacterDropDown()
	{
		if(gameOverCharDropDown == null) return;

		var gameOverList:Array<String> = characterList.filter((name:String) -> name == '' || name.endsWith('-dead') || name.endsWith('-death'));
		if(!gameOverList.contains('')) gameOverList.insert(0, '');
		gameOverList.sort(function(a:String, b:String)
		{
			if(a == '') return -1;
			if(b == '') return 1;
			return Reflect.compare(a.toLowerCase(), b.toLowerCase());
		});

		gameOverCharDropDown.list = gameOverList;
		gameOverCharDropDown.selectedLabel = character != null && character.gameOverChar != null ? character.gameOverChar : '';
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims)
		{
			// BETADCIU: se não tem playerOffsets, copia dos offsets
			if(anim.playerOffsets == null && anim.offsets != null)
				anim.playerOffsets = [anim.offsets[0] * 1.0, anim.offsets[1] * 1.0];
			animList.push(anim.anim);
		}
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
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
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function getCharacterFileAnimations():Array<Dynamic>
	{
		var animations:Array<Dynamic> = [];
		for (anim in character.animationsArray)
		{
			var pOff:Array<Float> = anim.playerOffsets;
			if(pOff == null)
			{
				if(anim.offsets != null)
					pOff = [anim.offsets[0] * 1.0, anim.offsets[1] * 1.0];
				else
					pOff = [0.0, 0.0];
			}

			var off:Array<Dynamic> = anim.offsets != null ? anim.offsets : [0, 0];

			// New Pico format: character_animations_data entry
			var animation:Dynamic = {
				"offsets": off,
				"Offsets-Playable": pOff,
				"name": anim.anim,
				"prefix": anim.name,
				"Framerate": anim.fps,
				"loopd?": anim.loop
			};

			var animAsset:String = Character.getAnimationAssetPathInput(anim.assetPath);
			if(animAsset != null && animAsset.trim().length > 0)
				Reflect.setField(animation, "assetPath", animAsset.trim());

			if(anim.indices != null && anim.indices.length > 0)
				Reflect.setField(animation, "indices", anim.indices);

			animations.push(animation);
		}
		return animations;
	}

	function saveCharacter() {
		if(_file != null) return;

		// New Pico Character JSON Format
		var typeSave:String = getCharacterType();
		// Map editor types to short Type tags used by the new format
		var typeTag:String = switch(typeSave) {
			case 'Player': 'BF';
			case 'Additional': 'GF';
			default: 'DAD';
		};

		var assetOut:String = character.imageFile != null ? character.imageFile : '';
		while(assetOut.indexOf('//') >= 0) assetOut = assetOut.replace('//', '/');

		var json:Dynamic = {
			"character_animations_data": getCharacterFileAnimations(),
			"assetPath": assetOut,
			"characterNoteStyle": (character.noteStyle != null) ? character.noteStyle : '',
			"characterPositionOffsets": character.positionArray,
			"cameraPosition": character.cameraPosition,
			"renderType": 'sparrow',
			"characterIcon": character.healthIcon != null ? character.healthIcon : '',
			"flip_x": character.originalFlipX,
			"characterHealthBarColor": character.healthColorArray,
			"Type": typeTag,
			"isPixel": character.noAntialiasing,
			"characterSingDuration": character.singDuration,
			"characterScale": character.jsonScale
		};

		// Optional fields — only if filled
		setOptionalString(json, "gameOverChar", character.gameOverChar);
		setOptionalString(json, "gameOverSound", character.gameOverSound);
		setOptionalString(json, "gameOverLoop", character.gameOverLoop);
		setOptionalString(json, "gameOverEnd", character.gameOverEnd);

		if(character.vocalsFile != null && character.vocalsFile.trim().length > 0)
			Reflect.setField(json, "vocals_file", character.vocalsFile.trim());

		var rtSave:String = Character.normalizeRenderType(character.renderType);
		if(rtSave.length < 1) rtSave = 'sparrow';
		Reflect.setField(json, "renderType", rtSave);

		var data:String = PsychJsonPrinter.print(json, [
			'characterPositionOffsets', 'cameraPosition', 'characterHealthBarColor',
			'Offsets-Playable', 'offsets', 'indices'
		]);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}

	function setOptionalString(json:Dynamic, field:String, value:String):Void
	{
		if(value != null && value.trim().length > 0)
			Reflect.setField(json, field, value.trim());
	}
}
