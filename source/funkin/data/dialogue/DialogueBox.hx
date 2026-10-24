package funkin.data.dialogue;

import funkin.play.Song;
import flixel.addons.text.FlxTypeText;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;
	var curCharacter:String = '';
	var dialogueList:Array<String> = [];
	var swagDialogue:FlxTypeText;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var skipText:FlxText;

	var songName:String = Paths.formatToSongPath(Song.loadedSongName != null ? Song.loadedSongName : '');
	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);

		box = new FlxSprite(-20, 45);
		
		var hasDialog = true;
		switch (songName)
		{
			case 'senpai':
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear instance 1', [4], '', 24);
			case 'roses':
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH instance 1', [4], '', 24);
			case 'thorns':
				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn instance 1', [11], '', 24);

				var face:FlxSprite = new FlxSprite(320, 170).loadGraphic(Paths.image('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
			default:
				hasDialog = false;
		}

		this.dialogueList = (dialogueList != null) ? dialogueList : [];
		
		if (!hasDialog)
			return;
		
		portraitLeft = new FlxSprite(-20, 40);
		portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new FlxSprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
		portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		add(portraitRight);
		portraitRight.visible = false;
		
		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		portraitLeft.screenCenter(X);

		handSelect = new FlxSprite(1042, 590).loadGraphic(Paths.image('weeb/pixelUI/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.visible = false;
		add(handSelect);

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), '', 32);
		swagDialogue.font = Paths.font('pixel-latin.ttf');
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		swagDialogue.borderStyle = SHADOW;
		swagDialogue.borderColor = 0xFFD89494;
		swagDialogue.shadowOffset.set(2, 2);
		add(swagDialogue);

		skipText = new FlxText(FlxG.width - 320, FlxG.height - 30, 300, Language.getPhrase('dialogue_skip', 'Press BACK to Skip'), 16);
		skipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		skipText.borderSize = 2;
		add(skipText);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Early-out when this song has no pixel dialogue box
		if (box == null || swagDialogue == null)
			return;

		switch(songName)
		{
			case 'roses':
				if (portraitLeft != null) portraitLeft.visible = false;
			case 'thorns':
				if (portraitLeft != null) portraitLeft.visible = false;
				swagDialogue.color = FlxColor.WHITE;
				swagDialogue.borderStyle = NONE;
		}

		if (box.animation != null && box.animation.curAnim != null
			&& box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
		{
			box.animation.play('normal');
			dialogueOpened = true;
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		var pressedBack:Bool = false;
		var pressedAccept:Bool = false;
		try
		{
			if (Controls.instance != null)
			{
				pressedBack = Controls.instance.BACK;
				pressedAccept = Controls.instance.ACCEPT;
			}
		}
		catch (e:Dynamic) {}

		if (pressedBack)
		{
			if (dialogueStarted && !isEnding)
			{
				dialogueCompleted();
				try FlxG.sound.play(Paths.sound('clickText'), 0.8) catch (e:Dynamic) {}
			}
		}
		else if (pressedAccept)
		{
			if (dialogueEnded)
			{
				if (dialogueList == null || dialogueList.length < 1)
				{
					if (!isEnding) dialogueCompleted();
				}
				else if (dialogueList.length <= 1)
				{
					if (!isEnding)
						dialogueCompleted();
				}
				else
				{
					dialogueList.shift();
					startDialogue();
					try FlxG.sound.play(Paths.sound('clickText'), 0.8) catch (e:Dynamic) {}
				}
			}
			else if (dialogueStarted)
			{
				try FlxG.sound.play(Paths.sound('clickText'), 0.8) catch (e:Dynamic) {}
				swagDialogue.skip();
				if (skipDialogueThing != null)
					skipDialogueThing();
			}
		}
	}

	var isEnding:Bool = false;
	function dialogueCompleted()
	{
		isEnding = true;
		FlxG.sound.play(Paths.sound('clickText'), 0.8);	

		if ((songName == 'senpai' || songName == 'thorns') && FlxG.sound.music != null)
		{
			try FlxG.sound.music.fadeOut(1.5, 0, function(_) {
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
			}) catch (e:Dynamic) {}
		}

		new FlxTimer().start(0.2, function(tmr:FlxTimer)
		{
			if (box != null) box.alpha -= 1 / 5;
			if (bgFade != null) bgFade.alpha -= 1 / 5 * 0.7;
			if (portraitLeft != null) portraitLeft.visible = false;
			if (portraitRight != null) portraitRight.visible = false;
			if (swagDialogue != null) swagDialogue.alpha -= 1 / 5;
			if (handSelect != null) handSelect.alpha -= 1 / 5;
		}, 5);

		if (swagDialogue != null) swagDialogue.skip();
		if (skipText != null) skipText.visible = false;
		new FlxTimer().start(1.5, function(tmr:FlxTimer)
		{
			if (finishThing != null)
			{
				try finishThing() catch (e:Dynamic) {}
			}
			kill();
		});
	}

	function startDialogue():Void
	{
		if (dialogueList == null || dialogueList.length < 1 || swagDialogue == null)
		{
			if (!isEnding) dialogueCompleted();
			return;
		}

		cleanDialog();

		swagDialogue.resetText(dialogueList[0] != null ? dialogueList[0] : ' ');
		swagDialogue.start(0.04, true);
		swagDialogue.completeCallback = function() {
			if (handSelect != null) handSelect.visible = true;
			dialogueEnded = true;
		};

		if (handSelect != null) handSelect.visible = false;
		dialogueEnded = false;
		switch (curCharacter)
		{
			case 'dad':
				if (portraitRight != null) portraitRight.visible = false;
				if (portraitLeft != null && !portraitLeft.visible)
				{
					if (songName == 'senpai') portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf':
				if (portraitLeft != null) portraitLeft.visible = false;
				if (portraitRight != null && !portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
		}
		if (nextDialogueThing != null)
			nextDialogueThing();
	}

	function cleanDialog():Void
	{
		if (dialogueList == null || dialogueList.length < 1 || dialogueList[0] == null)
		{
			curCharacter = '';
			return;
		}

		var line:String = dialogueList[0];
		var splitName:Array<String> = line.split(':');
		if (splitName.length >= 2 && splitName[1] != null)
		{
			curCharacter = splitName[1];
			var cut:Int = splitName[1].length + 2; // ":name:"
			dialogueList[0] = (line.length > cut) ? line.substr(cut).trim() : '';
		}
		else
		{
			curCharacter = '';
			dialogueList[0] = line.trim();
		}
	}
}
