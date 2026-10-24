package funkin.data.dialogue;

import funkin.states.PauseMenuState;
import funkin.translations.Language;
import haxe.Json;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef DialogueFile = {
	var dialogue:Array<DialogueLine>;
	var style:Null<String>;
}

typedef DialogueLine = {
	var portrait:Null<String>;
	var expression:Null<String>;
	var text:Null<String>;
	var boxState:Null<String>;
	var speed:Null<Float>;
	@:optional var sound:Null<String>;
	/** Pico new format: custom box sprite path */
	@:optional var boxImage:Null<String>;
}

/** Root of songs/<song>/dialogue/dialogueSong.json (Pico format) */
typedef PicoDialogueRoot = {
	@:optional var dialogue_dataAssets:Dynamic;
	@:optional var dialogue_Song:Array<Dynamic>;
	@:optional var dialogue:Array<Dynamic>; // Psych legacy
	@:optional var style:String;
}

private class BaseBoxStyle
{
	public function new() {}
	public var BG_COLOR:Int = FlxColor.BLACK;
	public var FADE_DURATION:Float = 0.5;
	public var visualUpdateThreshold:Float = 0.016;
	public var LEFT_CHAR_X:Float = -60;
	public var RIGHT_CHAR_X:Float = -100;
	public var DEFAULT_CHAR_Y:Float = 60;
	public var offsetXPos:Float = 0;
	public var offsetYPos:Float = 0;
	public var scrollSpeed:Float = 10;
	public var alphaFadeinScale:Float = 1;
	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;
	public var last_position:String = 'left';

	private var lineFinished:Bool = false;
	private var currentText:String = '';
	private var currentSpeed:Float = 0.05;
	private var currentSound:String = 'dialogue';

	public function makeDialogueBox():FlxSprite
	{
		return new FlxSprite();
	}

	public function initText():FlxText
	{
		return new FlxText(0, 0, 0, '', 20);
	}

	public function rowCount():Int
	{
		return 1;
	}

	public function prepareLine(text:String, speed:Float, sound:String)
	{
		currentText = text;
		currentSpeed = speed;
		currentSound = sound;
		lineFinished = false;
	}

	public function isLineFinished():Bool
	{
		return lineFinished;
	}

	public function finishLine():Void
	{
		lineFinished = true;
	}

	public function playBoxAnim(position:String, state:String, type:String):Void
	{
		last_position = position;
	}

	public function advanceBoxLine(callback:Void->Void):Void
	{
		if (callback != null)
			callback();
	}

	public function getCurrentText():String return currentText;
	public function getCurrentSpeed():Float return currentSpeed;
	public function getCurrentSound():String return currentSound;
}

private class PsychBoxStyle extends BaseBoxStyle
{
	public function new() { super(); }
}
private class PixelBoxStyle extends BaseBoxStyle
{
	public function new() { super(); }
}
private class DecayBoxStyle extends BaseBoxStyle
{
	public function new() { super(); }
}

// TO DO: Clean code? Maybe? idk
class DialogueBoxPsych extends FlxSpriteGroup
{
	// Some editors use those lol
	public static var DEFAULT_TEXT_X = 175;
	public static var DEFAULT_TEXT_Y = 460;
	public static var LONG_TEXT_ADD = 24;

	public static var LEFT_CHAR_X:Float = -60;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 60;

	private var activeStyle:Dynamic;

	var dialogueList:DialogueFile = null;

	public var finishThing:Void->Void;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;

	var bgFade:FlxSprite = null;
	var box:FlxSprite;
	var textToType:String = '';

	var arrayCharacters:Array<DialogueCharacter> = [];

	var currentText:Int = 0;
	var skipText:FlxText;

	var textBoxTypes:Array<String> = ['normal', 'angry'];

	var curCharacter:String = "";

	var pauseJustClosed:Bool = false;
	var staticDialList:Array<DialogueLine> = [];

	// var charPositionList:Array<String> = ['left', 'center', 'right'];

	public function new(dialogueList:DialogueFile, ?song:String = null)
	{
		super();

		// Guard against null / empty dialogue payload
		if (dialogueList == null)
			dialogueList = dummy();
		if (dialogueList.dialogue == null)
			dialogueList.dialogue = dummy().dialogue;

		var styleKey:String = (dialogueList.style != null) ? dialogueList.style : '';
		switch (styleKey)
		{
			case "pixel":
				this.activeStyle = new PixelBoxStyle();
			case "decay":
				this.activeStyle = new DecayBoxStyle();
			default:
				this.activeStyle = new PsychBoxStyle();
		}

		// precache sounds
		try Paths.sound('dialogue') catch (e:Dynamic) {}
		try Paths.sound('dialogueClose') catch (e:Dynamic) {}

		if (song != null && song != '')
		{
			try
			{
				FlxG.sound.playMusic(Paths.music(song), 0);
				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeIn(2, 0, 1);
			}
			catch (e:Dynamic) {}
		}

		bgFade = new FlxSprite(-500, -500).makeGraphic(FlxG.width * 2, FlxG.height * 2, activeStyle.BG_COLOR);
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		add(bgFade);

		this.dialogueList = dialogueList;
		this.staticDialList = dialogueList.dialogue.copy();
		spawnCharacters();

		box = activeStyle.makeDialogueBox();
		add(box);

		daText = activeStyle.initText();
		add(daText);

		var text:String = 'Press BACK to Skip';
		try text = Language.getPhrase('dialogue_skip', 'Press BACK to Skip') catch (e:Dynamic) {}
		skipText = new FlxText(FlxG.width - 320, FlxG.height - 30, 300, text, 16);
		skipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		skipText.borderSize = 2;
		add(skipText);

		FlxTween.tween(bgFade, {alpha: 0.5}, activeStyle.FADE_DURATION, {ease: FlxEase.linear});
		startNextDialog(true);
	}

	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;
	function spawnCharacters()
	{
		var charsMap:Map<String, Bool> = new Map<String, Bool>();
		for (i in 0...dialogueList.dialogue.length)
		{
			if (dialogueList.dialogue[i] != null)
			{
				var charToAdd:String = dialogueList.dialogue[i].portrait;
				if (!charsMap.exists(charToAdd) || !charsMap.get(charToAdd))
				{
					charsMap.set(charToAdd, true);
				}
			}
		}

		for (individualChar in charsMap.keys())
		{
			if(individualChar == null || Std.string(individualChar).trim().length < 1)
				continue;

			var x:Float = activeStyle.LEFT_CHAR_X;
			var y:Float = activeStyle.DEFAULT_CHAR_Y;
			var char:DialogueCharacter = null;
			try
			{
				char = new DialogueCharacter(x + activeStyle.offsetXPos, y, individualChar);
			}
			catch(e:Dynamic)
			{
				trace('[DialogueBoxPsych] Failed to spawn dialogue char "' + individualChar + '": ' + e);
				continue;
			}
			if(char == null || char.jsonFile == null)
				continue;

			var sc:Float = (!Math.isNaN(char.jsonFile.scale) && char.jsonFile.scale > 0) ? char.jsonFile.scale : 1;
			char.setGraphicSize(Std.int(Math.max(1, char.width * DialogueCharacter.DEFAULT_SCALE * sc)));
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = 0.00001;
			add(char);

			var saveY:Bool = false;
			var pos:String = (char.jsonFile.dialogue_pos != null) ? char.jsonFile.dialogue_pos : 'left';
			switch (pos)
			{
				case 'center':
					char.x = FlxG.width / 2;
					char.x -= char.width / 2;
					y = char.y;
					char.y = activeStyle.offsetYPos + 50;
					saveY = true;
				case 'right':
					x = FlxG.width - char.width + activeStyle.RIGHT_CHAR_X;
					char.x = x - activeStyle.offsetXPos;
			}
			var posOff:Array<Float> = (char.jsonFile.position != null && char.jsonFile.position.length >= 2)
				? char.jsonFile.position : [0, 0];
			x += posOff[0];
			y += posOff[1];
			char.x += posOff[0];
			char.y += posOff[1];
			char.startingPos = (saveY ? y : x);
			arrayCharacters.push(char);
		}
	}

	var daText:FlxSprite = null;
	var ignoreThisFrame:Bool = true; // First frame is reserved for loading dialogue images

	var cumulatedElapsed:Float = 0;

	override function update(elapsed_real:Float)
	{
		var elapsed:Float = 0;
		cumulatedElapsed += elapsed_real;
		if (ignoreThisFrame)
		{
			ignoreThisFrame = false;
			super.update(elapsed_real);
			return;
		}
		if (cumulatedElapsed > activeStyle.visualUpdateThreshold)
		{
			elapsed = cumulatedElapsed;
			cumulatedElapsed = 0;
		}

		if (!dialogueEnded)
		{
			var back:Bool = false;
			#if android
			try { if (FlxG.android != null && FlxG.android.justReleased.BACK) back = true; } catch (e:Dynamic) {}
			#end
			#if TOUCH_CONTROLS_ALLOWED
			try {
				var st = MusicBeatState.getState();
				if (st != null && st.touchPad != null && st.touchPad.buttonP != null && st.touchPad.buttonP.justPressed)
					back = true;
			} catch (e:Dynamic) {}
			#end
			try { if (Controls.instance != null && Controls.instance.BACK) back = true; } catch (e:Dynamic) {}

			var accept:Bool = false;
			try { if (Controls.instance != null && Controls.instance.ACCEPT) accept = true; } catch (e:Dynamic) {}

			if (back && !pauseJustClosed && !dialogueEnded)
			{
				var game = PlayState.instance;
				if (game == null)
				{
					// No PlayState — just skip dialogue entirely
					skipDialogue();
				}
				else
				{
					FlxG.camera.followLerp = 0;
					FlxG.state.persistentUpdate = false;
					FlxG.state.persistentDraw = true;
					if (FlxG.sound.music != null)
					{
						try FlxG.sound.music.pause() catch (e:Dynamic) {}
					}
					#if LEGACY_PSYCH
					var pauseState = new PauseMenuState(0, 0, true, DIALOGUE);
					#else
					var pauseState = new PauseMenuState(true, DIALOGUE);
					#end
					pauseState.cutsceneAllowSkipping = true;
					pauseState.cutsceneHardReset = false;
					game.openSubState(pauseState);

					game.subStateClosed.addOnce(function(_)
					{
						pauseJustClosed = true;
						new FlxTimer().start(0.1, function(__) pauseJustClosed = false);
						switch (pauseState.specialAction)
						{
							case SKIP:
								skipDialogue();
								try FlxG.sound.play(Paths.sound(activeStyle.closeSound), activeStyle.closeVolume) catch (e:Dynamic) {}
								trace('Skip Dialogue');
							case RESUME:
								if (FlxG.sound.music != null)
									try FlxG.sound.music.resume() catch (e:Dynamic) {}
							case NOTHING:
							case RESTART:
								if (FlxG.sound.music != null)
									try FlxG.sound.music.resume() catch (e:Dynamic) {}
								dialogueList.dialogue = staticDialList.copy();
								currentText = 0;
								startNextDialog();
								try FlxG.sound.play(Paths.sound(activeStyle.closeSound), activeStyle.closeVolume) catch (e:Dynamic) {}
						}
					});
				}
			}
			else if ((accept || back) && box != null && box.visible)
			{
				if (!activeStyle.isLineFinished() && !back)
				{
					activeStyle.finishLine();
					activeStyle.playBoxAnim(activeStyle.last_position, 'WAIT', lastBoxType);
					if (skipDialogueThing != null)
					{
						skipDialogueThing();
					}
					FlxG.sound.play(Paths.sound(activeStyle.closeSound), activeStyle.closeVolume);
				}
				else if (currentText >= dialogueList.dialogue.length)
				{
					FlxG.sound.play(Paths.sound(activeStyle.closeSound), activeStyle.closeVolume);
					skipDialogue();
				}
				else
				{
					FlxG.sound.play(Paths.sound(activeStyle.closeSound), activeStyle.closeVolume);
					activeStyle.advanceBoxLine(startNextDialog.bind(false));
				}
			}
			else if (activeStyle.isLineFinished())
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if (char != null && char.animation.curAnim != null && char.animationIsLoop() && char.animation.finished)
				{
					char.playAnim(char.animation.curAnim.name, true);
				}
				activeStyle.playBoxAnim(activeStyle.last_position, 'WAIT', lastBoxType);
			}
			else
			{
				var char:DialogueCharacter = arrayCharacters[lastCharacter];
				if (char != null && char.animation.curAnim != null && char.animation.finished)
				{
					char.animation.curAnim.restart();
				}
			}

			if (lastCharacter != -1 && arrayCharacters.length > 0)
			{
				for (i in 0...arrayCharacters.length)
				{
					var char = arrayCharacters[i];
					if (char != null)
					{
						if (i != lastCharacter)
						{
							var pos:String = (char.jsonFile != null && char.jsonFile.dialogue_pos != null) ? char.jsonFile.dialogue_pos : 'left';
							switch (pos)
							{
								case 'left':
									char.x -= activeStyle.scrollSpeed * elapsed;
									if (char.x < char.startingPos + activeStyle.offsetXPos)
										char.x = char.startingPos + activeStyle.offsetXPos;
								case 'center':
									char.y += activeStyle.scrollSpeed * elapsed;
									if (char.y > char.startingPos + activeStyle.offsetYPos)
										char.y = char.startingPos + activeStyle.offsetYPos;
								case 'right':
									char.x += activeStyle.scrollSpeed * elapsed;
									if (char.x > char.startingPos - activeStyle.offsetXPos)
										char.x = char.startingPos - activeStyle.offsetXPos;
							}
							char.alpha -= activeStyle.alphaFadeinScale * 3 * elapsed;
							if (char.alpha < 0.00001)
								char.alpha = 0.00001;
						}
						else
						{
							var pos2:String = (char.jsonFile != null && char.jsonFile.dialogue_pos != null) ? char.jsonFile.dialogue_pos : 'left';
							switch (pos2)
							{
								case 'left':
									char.x += activeStyle.scrollSpeed * elapsed;
									if (char.x > char.startingPos)
										char.x = char.startingPos;
								case 'center':
									char.y -= activeStyle.scrollSpeed * elapsed;
									if (char.y < char.startingPos)
										char.y = char.startingPos;
								case 'right':
									char.x -= activeStyle.scrollSpeed * elapsed;
									if (char.x < char.startingPos)
										char.x = char.startingPos;
							}
							char.alpha += activeStyle.alphaFadeinScale * 3 * elapsed;
							if (char.alpha > 1)
								char.alpha = 1;
						}
					}
				}
			}
		} else
		{ // Dialogue ending
			if (box != null && (box.animation == null || box.animation.curAnim == null || box.animation.curAnim.curFrame <= 0))
			{
				box.kill();
				remove(box);
				box.destroy();
				box = null;
			}

			if (bgFade != null)
			{
				bgFade.alpha -= 0.5 * elapsed_real;
				if (bgFade.alpha <= 0)
				{
					bgFade.kill();
					remove(bgFade);
					bgFade.destroy();
					bgFade = null;
				}
			}

			for (i in 0...arrayCharacters.length)
			{
				var leChar:DialogueCharacter = arrayCharacters[i];
				if (leChar != null)
				{
					var endPos:String = (leChar.jsonFile != null && leChar.jsonFile.dialogue_pos != null) ? leChar.jsonFile.dialogue_pos : 'left';
					switch (endPos)
					{
						case 'left':
							leChar.x -= activeStyle.scrollSpeed * elapsed;
						case 'center':
							leChar.y += activeStyle.scrollSpeed * elapsed;
						case 'right':
							leChar.x += activeStyle.scrollSpeed * elapsed;
					}
					leChar.alpha -= activeStyle.alphaFadeinScale * elapsed * 10;
				}
			}

			if (box == null && bgFade == null)
			{
				while (arrayCharacters.length > 0)
				{
					var leChar:DialogueCharacter = arrayCharacters.shift();
					if (leChar != null)
					{
						try
						{
							leChar.kill();
							remove(leChar);
							leChar.destroy();
						}
						catch (e:Dynamic) {}
					}
				}
				if (finishThing != null)
				{
					try finishThing() catch (e:Dynamic) {}
				}
				kill();
			}
		}
		super.update(elapsed_real);
	}

	function skipDialogue()
	{
		dialogueEnded = true;
		activeStyle.playBoxAnim(activeStyle.last_position, 'CLOSE_FINISH', lastBoxType);
		if (daText != null)
		{
			daText.kill();
			remove(daText);
			daText.destroy();
		}
		if (skipText != null) skipText.visible = false;
		if (FlxG.sound.music != null)
		{
			try FlxG.sound.music.fadeOut(1, 0, function(_) {
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
			}) catch (e:Dynamic) {}
		}
		#if LEGACY_PSYCH
		var game = PlayState.instance;
		game.camGame.follow(game.camFollowPos, LOCKON, 1);
		PlayState.seenCutscene = true;
		game.psychDialogue = null;
		#end
	}

	var lastCharacter:Int = -1;
	var lastBoxType:String = '';

	function startNextDialog(init:Bool = false):Void
	{
		if (dialogueList == null || dialogueList.dialogue == null)
		{
			skipDialogue();
			return;
		}

		var curDialogue:DialogueLine = null;
		var safety:Int = 0;
		while (currentText < dialogueList.dialogue.length && safety < 999)
		{
			curDialogue = dialogueList.dialogue[currentText];
			if (curDialogue != null) break;
			currentText++;
			safety++;
		}
		if (curDialogue == null)
		{
			skipDialogue();
			return;
		}

		if (curDialogue.text == null || curDialogue.text.length < 1)
			curDialogue.text = ' ';
		if (curDialogue.boxState == null)
			curDialogue.boxState = 'normal';
		if (curDialogue.speed == null || Math.isNaN(curDialogue.speed))
			curDialogue.speed = 0.05;

		var animName:String = curDialogue.boxState;
		var boxType:String = textBoxTypes[0];
		for (i in 0...textBoxTypes.length)
		{
			if (textBoxTypes[i] == animName)
			{
				boxType = animName;
			}
		}

		var character:Int = 0;
		box.visible = true;
		for (i in 0...arrayCharacters.length)
		{
			if (arrayCharacters[i].curCharacter == curDialogue.portrait)
			{
				character = i;
				break;
			}
		}
		var lePos:String = 'right';
		if(arrayCharacters.length > 0 && character >= 0 && character < arrayCharacters.length
			&& arrayCharacters[character] != null && arrayCharacters[character].jsonFile != null
			&& arrayCharacters[character].jsonFile.dialogue_pos != null)
		{
			lePos = switch (arrayCharacters[character].jsonFile.dialogue_pos)
			{
				case "left": "left";
				case "right": "right";
				case "center": "center";
				default: "right";
			};
		}
		var leType:String = 'OPEN';

		if (init)
		{
			leType = 'OPEN_INIT';
		}

		if (character != lastCharacter)
		{
			activeStyle.playBoxAnim(lePos, leType, boxType);
		}
		else
		{
			leType = 'IDLE';
			activeStyle.playBoxAnim(lePos, leType, boxType);
		}
		lastCharacter = character;
		lastBoxType = boxType;

		var dlg_sound = curDialogue.sound;
		if (dlg_sound == null || dlg_sound.trim() == '')
			dlg_sound = 'dialogue';
		activeStyle.prepareLine(curDialogue.text, curDialogue.speed, dlg_sound);

		daText.y = DEFAULT_TEXT_Y;
		if (activeStyle.rowCount() > 2)
			daText.y -= LONG_TEXT_ADD;

		var char:DialogueCharacter = arrayCharacters[character];
		if (char != null)
		{
			char.playAnim(curDialogue.expression, activeStyle.isLineFinished());
			if (char.animation.curAnim != null)
			{
				var rate:Float = 24 - (((curDialogue.speed - 0.05) / 5) * 480);
				if (rate < 12)
					rate = 12;
				else if (rate > 48)
					rate = 48;
				char.animation.curAnim.frameRate = rate;
			}
		}
		currentText++;

		if (nextDialogueThing != null)
		{
			nextDialogueThing();
		}
	}

	/**
	 * Load dialogue for a song folder (songFileName).
	 * Primary: songs/<folder>/dialogue/dialogueSong.json (Pico format)
	 * Fallback: data/<folder>/dialogue.json (Psych)
	 * Returns null if nothing found.
	 */
	public static function loadForSong(songFolder:String, ?locale:String = null):Null<DialogueFile>
	{
		if(songFolder == null) return null;
		var folder:String = Paths.formatToSongPath(songFolder);
		if(folder.length < 1) return null;

		var paths:Array<String> = [];
		// Pico new path
		paths.push('songs/' + folder + '/dialogue/dialogueSong.json');
		paths.push(folder + '/dialogue/dialogueSong.json');
		// Psych-style fallbacks
		paths.push('data/' + folder + '/dialogue.json');
		paths.push('data/' + folder + '/dialogueSong.json');

		for (rel in paths)
		{
			var full:String = resolveDialoguePath(rel);
			if(full == null) continue;
			try
			{
				#if sys
				var raw:Dynamic = Json.parse(File.getContent(full));
				#else
				var raw:Dynamic = Json.parse(Assets.getText(full));
				#end
				var converted:DialogueFile = convertToDialogueFile(raw, locale);
				if(converted != null && converted.dialogue != null && converted.dialogue.length > 0)
				{
					trace('[DialogueBoxPsych] Loaded dialogue: ' + full);
					return converted;
				}
			}
			catch(e:Dynamic)
			{
				trace('[DialogueBoxPsych] Failed to parse ' + full + ': ' + e);
			}
		}
		return null;
	}

	/** Optional BGM key from dialogue_dataAssets.dialogueMusic (folder or track name). */
	public static function getDialogueMusicFromRaw(raw:Dynamic):String
	{
		if(raw == null) return null;
		var assets:Dynamic = Reflect.field(raw, 'dialogue_dataAssets');
		if(assets == null) return null;
		var music:Dynamic = Reflect.field(assets, 'dialogueMusic');
		if(music == null) return null;
		var s:String = Std.string(music).trim();
		if(s.length < 1) return null;
		// If ends with /, treat as folder — leave empty so caller can pick default
		if(StringTools.endsWith(s, '/')) return null;
		return s;
	}

	public static function loadRawForSong(songFolder:String):Dynamic
	{
		if(songFolder == null) return null;
		var folder:String = Paths.formatToSongPath(songFolder);
		var paths:Array<String> = [
			'songs/' + folder + '/dialogue/dialogueSong.json',
			folder + '/dialogue/dialogueSong.json',
			'data/' + folder + '/dialogue.json'
		];
		for (rel in paths)
		{
			var full:String = resolveDialoguePath(rel);
			if(full == null) continue;
			try
			{
				#if sys
				return Json.parse(File.getContent(full));
				#else
				return Json.parse(Assets.getText(full));
				#end
			}
			catch(e:Dynamic) {}
		}
		return null;
	}

	static function resolveDialoguePath(rel:String):String
	{
		if(rel == null) return null;
		#if (MODS_ALLOWED && sys)
		var modPath:String = Paths.modFolders(rel);
		if(FileSystem.exists(modPath)) return modPath;
		#end
		#if sys
		var shared:String = Paths.getSharedPath(rel);
		if(FileSystem.exists(shared)) return shared;
		// Absolute-ish under cwd
		if(FileSystem.exists(rel)) return rel;
		if(FileSystem.exists('assets/' + rel)) return 'assets/' + rel;
		#end
		#if (!sys)
		if(openfl.utils.Assets.exists(rel)) return rel;
		if(openfl.utils.Assets.exists('assets/' + rel)) return 'assets/' + rel;
		#end
		return null;
	}

	/**
	 * Convert Pico dialogueSong.json OR Psych dialogue.json → DialogueFile.
	 * Pico fields: speaker→portrait, text[]→joined string, boxImage, useTranslations.
	 */
	public static function convertToDialogueFile(raw:Dynamic, ?locale:String = null):DialogueFile
	{
		if(raw == null) return null;

		// Already Psych format?
		var psychLines:Dynamic = Reflect.field(raw, 'dialogue');
		if(psychLines != null && Std.isOfType(psychLines, Array))
		{
			var style:String = Reflect.hasField(raw, 'style') ? Std.string(Reflect.field(raw, 'style')) : '';
			var outPsych:Array<DialogueLine> = [];
			for (entry in (cast psychLines:Array<Dynamic>))
			{
				var line = normalizeLine(entry);
				if(line != null) outPsych.push(line);
			}
			return { dialogue: outPsych, style: style };
		}

		// Pico format: dialogue_Song / dialogue_Song_<locale>
		var assets:Dynamic = Reflect.field(raw, 'dialogue_dataAssets');
		var useTranslations:Bool = false;
		if(assets != null && Reflect.hasField(assets, 'useTranslations'))
			useTranslations = Reflect.field(assets, 'useTranslations') == true;

		var linesRaw:Array<Dynamic> = null;
		if(useTranslations)
		{
			var loc:String = locale;
			if(loc == null || loc.length < 1)
				loc = getCurrentLocale();
			if(loc != null && loc.length > 0)
			{
				// dialogue_Song_pt-BR
				var key:String = 'dialogue_Song_' + loc;
				var found:Dynamic = Reflect.field(raw, key);
				if(found == null)
				{
					// try lowercase / underscore variants
					var alt:String = 'dialogue_Song_' + loc.replace('-', '_');
					found = Reflect.field(raw, alt);
				}
				if(found != null && Std.isOfType(found, Array))
					linesRaw = cast found;
			}
		}

		if(linesRaw == null)
		{
			var base:Dynamic = Reflect.field(raw, 'dialogue_Song');
			if(base != null && Std.isOfType(base, Array))
				linesRaw = cast base;
		}

		if(linesRaw == null || linesRaw.length < 1)
			return null;

		var style:String = '';
		if(Reflect.hasField(raw, 'style'))
			style = Std.string(Reflect.field(raw, 'style'));
		// Infer pixel style from first boxImage
		if(style.length < 1 && linesRaw.length > 0)
		{
			var firstBox:Dynamic = Reflect.field(linesRaw[0], 'boxImage');
			if(firstBox != null && Std.string(firstBox).toLowerCase().indexOf('pixel') >= 0)
				style = 'pixel';
		}

		var out:Array<DialogueLine> = [];
		for (entry in linesRaw)
		{
			var line = normalizeLine(entry);
			if(line != null) out.push(line);
		}
		if(out.length < 1) return null;
		return { dialogue: out, style: style };
	}

	static function normalizeLine(entry:Dynamic):DialogueLine
	{
		if(entry == null) return null;

		// speaker (Pico) or portrait (Psych)
		var portrait:String = null;
		if(Reflect.hasField(entry, 'speaker') && Reflect.field(entry, 'speaker') != null)
			portrait = Std.string(Reflect.field(entry, 'speaker'));
		else if(Reflect.hasField(entry, 'portrait') && Reflect.field(entry, 'portrait') != null)
			portrait = Std.string(Reflect.field(entry, 'portrait'));
		if(portrait == null || portrait.trim().length < 1)
			portrait = 'bf';

		var expression:String = 'talk';
		if(Reflect.hasField(entry, 'expression') && Reflect.field(entry, 'expression') != null)
		{
			var ex:String = Std.string(Reflect.field(entry, 'expression')).trim();
			if(ex.length > 0) expression = ex;
		}

		// text: string OR array of strings
		var text:String = ' ';
		var textRaw:Dynamic = Reflect.field(entry, 'text');
		if(textRaw != null)
		{
			if(Std.isOfType(textRaw, Array))
			{
				var parts:Array<String> = [];
				for (p in (cast textRaw:Array<Dynamic>))
					if(p != null) parts.push(Std.string(p));
				text = parts.join('\n');
				if(text.length < 1) text = ' ';
			}
			else
			{
				text = Std.string(textRaw);
				if(text.length < 1) text = ' ';
			}
		}

		var boxState:String = 'normal';
		if(Reflect.hasField(entry, 'boxState') && Reflect.field(entry, 'boxState') != null)
		{
			var bs:String = Std.string(Reflect.field(entry, 'boxState')).trim();
			if(bs.length > 0) boxState = bs;
		}

		var speed:Float = 0.05;
		if(Reflect.hasField(entry, 'speed'))
		{
			var sp:Float = Std.parseFloat(Std.string(Reflect.field(entry, 'speed')));
			if(!Math.isNaN(sp) && sp > 0) speed = sp;
		}

		var sound:String = null;
		if(Reflect.hasField(entry, 'sound') && Reflect.field(entry, 'sound') != null)
		{
			var snd:String = Std.string(Reflect.field(entry, 'sound')).trim();
			if(snd.length > 0) sound = snd;
		}

		var boxImage:String = null;
		if(Reflect.hasField(entry, 'boxImage') && Reflect.field(entry, 'boxImage') != null)
		{
			var bi:String = Std.string(Reflect.field(entry, 'boxImage')).trim();
			if(bi.length > 0) boxImage = bi;
		}

		var line:DialogueLine = {
			portrait: portrait,
			expression: expression,
			text: text,
			boxState: boxState,
			speed: speed,
			sound: sound
		};
		if(boxImage != null)
			Reflect.setField(line, 'boxImage', boxImage);
		return line;
	}

	/**
	 * Current language tag for dialogue_Song_<locale> (e.g. pt-BR).
	 * Uses funkin.translations.Language when available, then Preferences.
	 */
	static function getCurrentLocale():String
	{
		// Language API (Psych / Pico translations)
		try
		{
			// Common field names across Psych forks
			var candidates:Array<String> = ['language', 'lang', 'currentLanguage', 'locale'];
			for (field in candidates)
			{
				if(Reflect.hasField(Language, field))
				{
					var v:Dynamic = Reflect.field(Language, field);
					if(v != null)
					{
						var s:String = Std.string(v).trim();
						if(s.length > 0) return s;
					}
				}
			}
			// Some builds expose Language.getLanguage()
			if(Reflect.hasField(Language, 'getLanguage'))
			{
				var fn:Dynamic = Reflect.field(Language, 'getLanguage');
				if(Reflect.isFunction(fn))
				{
					var got:Dynamic = Reflect.callMethod(Language, fn, []);
					if(got != null)
					{
						var s2:String = Std.string(got).trim();
						if(s2.length > 0) return s2;
					}
				}
			}
		}
		catch(e:Dynamic) {}

		// Preferences.data.language
		try
		{
			if(Reflect.hasField(Preferences, 'data'))
			{
				var d:Dynamic = Reflect.field(Preferences, 'data');
				if(d != null && Reflect.hasField(d, 'language'))
				{
					var l:String = Std.string(Reflect.field(d, 'language')).trim();
					if(l.length > 0) return l;
				}
			}
		}
		catch(e:Dynamic) {}

		return 'en';
	}

	public static function parseDialogue(path:String):DialogueFile
	{
		#if sys
		if(path != null && FileSystem.exists(path))
		{
			try
			{
				var raw:Dynamic = Json.parse(File.getContent(path));
				var converted:DialogueFile = convertToDialogueFile(raw, null);
				if(converted != null)
					return converted;
			}
			catch(e:Dynamic) {}
		}
		#end
		return dummy();
	}

	public static function dummy():DialogueFile
	{
		return {
			dialogue: [
				{
					expression: "talk",
					text: "DIALOGUE NOT FOUND",
					boxState: "normal",
					speed: 0.05,
					portrait: "bf"
				}
			],
			style: ""
		};
	}
}
