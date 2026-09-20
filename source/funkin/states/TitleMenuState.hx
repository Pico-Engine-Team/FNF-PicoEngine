package funkin.states;

import funkin.data.WeekData;
import funkin.data.shaders.ColorSwap;
import funkin.states.menus.StoryMenuState;
import funkin.states.menus.MainMenuState;
import funkin.states.menus.freeplay.FreeplayMenuState;
import funkin.utils.engines.pico.EnginePerformance;
import funkin.utils.engines.pico.AssetBootPreload;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;

import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import haxe.Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

using StringTools;

typedef TitleCharAnim = {
	@:optional var offsets:Array<Float>;
	var name:String;
	var prefix:String;
	@:optional var loop:Null<Bool>;
	@:optional var indices:Array<Int>;
	@:optional var fps:Null<Int>;
}

/**
 * Disk layout (under assets/shared/images/):
 *   menus/title_menu/images/logoBumpin.png + .xml
 *   menus/title_menu/images/titleEnter.png + .xml
 *   menus/title_menu/images/newgrounds_logo.png
 *   menus/title_menu/images/characters/Girlfriend-Title.png + .xml
 *   menus/title_menu/data/characters/girlfriend-title.json
 *   menus/title_menu/data/introText.txt
 *
 * Paths image key = path relative to images/ folder.
 */
typedef TitleCharacterFile = {
	@:optional var animations:Array<TitleCharAnim>;
	@:optional var useAntialiasing:Null<Bool>;
	@:optional var assetPath:String;
	@:optional var renderType:String;
	@:optional var positionOffsets:Array<Float>;
	@:optional var scale:Null<Float>;
	@:optional var backgroundSprite:String;
	@:optional var BPM:Null<Float>;
	@:optional var bpm:Null<Float>;
	@:optional var logoOffsets:Array<Float>;
	@:optional var enterOffsets:Array<Float>;
	@:optional var titlex:Null<Float>;
	@:optional var titley:Null<Float>;
	@:optional var startx:Null<Float>;
	@:optional var starty:Null<Float>;
	@:optional var gfx:Null<Float>;
	@:optional var gfy:Null<Float>;
	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Null<Bool>;
}

class TitleMenuState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	public static inline var TITLE_ROOT:String = 'menus/title_menu';
	public static inline var TITLE_IMAGES:String = 'menus/title_menu/images';
	public static inline var TITLE_CHARS:String = 'menus/title_menu/images/characters';
	public static inline var TITLE_CHAR_DATA:String = 'menus/title_menu/data/characters';
	public static inline var TITLE_INTRO_TEXT:String = 'menus/title_menu/data/introText.txt';
	public static inline var DEFAULT_TITLE_CHAR:String = 'girlfriend-title';

	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];
	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = ['SHADOW', 'RIVEREN', 'BBPANZU', 'PESSY'];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		if(!initialized)
		{
			ClientPrefs.loadPrefs();
			Language.reloadPhrases();
			try { EnginePerformance.applyBootHints(); } catch(e:Dynamic) {}
			#if !html5
			try { AssetBootPreload.runIfEnabled(); } catch(e:Dynamic) {}
			#end
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());
		if(curWacky == null || curWacky.length < 1)
			curWacky = ['Friday Night', 'Funkin'];
		while(curWacky.length < 2)
			curWacky.push('');
		for (i in 0...curWacky.length)
			if(curWacky[i] == null) curWacky[i] = '';

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayMenuState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
			startIntro();
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	var characterImage:String = 'menus/title_menu/images/characters/Girlfriend-Title';
	var animationName:String = 'gfDance';
	var titleAnims:Array<TitleCharAnim> = null;
	var titleRenderType:String = 'sparrow';
	var titleCharScale:Float = 1;
	var titleUseAntialiasing:Bool = true;
	var animOffsets:Map<String, Array<Float>> = new Map();

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);

	var useIdle:Bool = false;
	var musicBPM:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

	function startIntro()
	{
		persistentUpdate = true;
		if (!initialized && FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('menu/freakyMenu'), 0);

		loadTitleCharacter(DEFAULT_TITLE_CHAR);
		#if TITLE_SCREEN_EASTER_EGG applyEasterEggCharacter(); #end
		Conductor.bpm = musicBPM;

		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		var logoFrames = loadSparrowSafe([
			TITLE_IMAGES + '/logoBumpin',
			'title/logoBumpin',
			'logoBumpin'
		]);
		if(logoFrames != null)
		{
			logoBl.frames = logoFrames;
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();
		}
		else
		{
			logoBl.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			logoBl.visible = false;
			trace('[TitleState] logoBumpin missing');
		}
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		buildTitleCharacter();

		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			if(gfDance != null) gfDance.shader = swagShader.shader;
			if(logoBl != null) logoBl.shader = swagShader.shader;
		}

		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		var enterFrames = loadSparrowSafe([
			TITLE_IMAGES + '/titleEnter',
			'title/titleEnter',
			'titleEnter'
		]);
		newTitle = false;
		if(enterFrames != null)
		{
			titleText.frames = enterFrames;
			var animFrames:Array<FlxFrame> = [];
			try
			{
				@:privateAccess
				{
					titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
					titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
				}
			}
			catch(e:Dynamic) {}

			if (animFrames.length > 0)
			{
				newTitle = true;
				titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
				titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
			}
			else
			{
				titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
				titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
			}
			titleText.animation.play('idle');
			titleText.updateHitbox();
		}
		else
		{
			titleText.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			titleText.visible = false;
			trace('[TitleState] titleEnter missing');
		}

		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52);
		var ngGraphic = loadGraphicSafe([
			TITLE_IMAGES + '/newgrounds_logo',
			'title/newgrounds_logo',
			'newgrounds_logo'
		]);
		if(ngGraphic != null)
			ngSpr.loadGraphic(ngGraphic);
		else
		{
			ngSpr.makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(Math.max(1, ngSpr.width * 0.8)));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		if(gfDance != null) add(gfDance);
		if(logoBl != null) add(logoBl);
		if(titleText != null) add(titleText);
		add(credGroup);
		if(ngSpr != null) add(ngSpr);

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function loadSparrowSafe(keys:Array<String>):FlxAtlasFrames
	{
		if(keys == null) return null;
		for (k in keys)
		{
			if(k == null || k.length < 1) continue;
			try
			{
				var frames:FlxAtlasFrames = Paths.getSparrowAtlas(k);
				if(frames != null)
				{
					trace('[TitleState] loaded sparrow: ' + k);
					return frames;
				}
			}
			catch(e:Dynamic) {}
		}
		return null;
	}

	function loadGraphicSafe(keys:Array<String>):Dynamic
	{
		if(keys == null) return null;
		for (k in keys)
		{
			if(k == null || k.length < 1) continue;
			try
			{
				var g = Paths.image(k);
				if(g != null)
				{
					trace('[TitleState] loaded image: ' + k);
					return g;
				}
			}
			catch(e:Dynamic) {}
		}
		return null;
	}

	function imageAssetExists(key:String):Bool
	{
		if(key == null || key.length < 1) return false;
		key = key.replace('\\', '/');
		if(key.startsWith('images/')) key = key.substr(7);
		try { if(Paths.fileExists('images/' + key + '.png', IMAGE)) return true; } catch(e:Dynamic) {}
		try { if(Paths.fileExists(key + '.png', IMAGE)) return true; } catch(e:Dynamic) {}
		try { if(Paths.fileExists(key, IMAGE)) return true; } catch(e:Dynamic) {}
		#if sys
		try
		{
			var full:String = Paths.getPath('images/' + key + '.png', IMAGE);
			if(full != null && sys.FileSystem.exists(full)) return true;
		}
		catch(e:Dynamic) {}
		#end
		return false;
	}

	function resolveCharAsset(path:String):String
	{
		var keys:Array<String> = [];
		function push(k:String):Void
		{
			if(k == null || k.length < 1) return;
			k = k.replace('\\', '/');
			if(k.startsWith('images/')) k = k.substr(7);
			if(k.endsWith('.png') || k.endsWith('.xml')) k = k.substr(0, k.length - 4);
			if(keys.indexOf(k) < 0) keys.push(k);
		}

		if(path != null && path.trim().length > 0)
		{
			var p:String = path.trim().replace('\\', '/');
			if(p.startsWith('images/')) p = p.substr(7);
			if(p.endsWith('.png') || p.endsWith('.xml')) p = p.substr(0, p.length - 4);
			push(p);

			// menus/title_menu/characters/X → menus/title_menu/images/characters/X
			if(p.startsWith(TITLE_ROOT + '/characters/'))
				push(TITLE_CHARS + '/' + p.substr((TITLE_ROOT + '/characters/').length));
			if(p.indexOf('/') < 0)
			{
				push(TITLE_CHARS + '/' + p);
				push(TITLE_IMAGES + '/characters/' + p);
			}
		}

		push(TITLE_CHARS + '/Girlfriend-Title');
		push(TITLE_IMAGES + '/characters/Girlfriend-Title');
		push('Girlfriend-Title');

		for (c in keys)
			if(imageAssetExists(c))
				return c;
		return keys[0];
	}

	function loadTitleCharacter(charId:String):Void
	{
		var id:String = charId != null ? charId.trim() : DEFAULT_TITLE_CHAR;
		if(id.length < 1) id = DEFAULT_TITLE_CHAR;

		var raw:String = readTitleCharJson(id);
		if(raw == null || raw.trim().length < 1)
		{
			trace('[TitleState] No title character JSON for ' + id + ', using defaults');
			characterImage = resolveCharAsset('Girlfriend-Title');
			return;
		}

		try
		{
			var data:TitleCharacterFile = cast Json.parse(raw);
			applyTitleCharacterFile(data);
		}
		catch(e:Dynamic)
		{
			trace('[TitleState] Failed to parse title character ' + id + ': ' + e);
		}
	}

	function readTitleCharJson(charId:String):String
	{
		// JSON lives at: assets/shared/images/menus/title_menu/data/characters/
		var candidates:Array<String> = [
			'images/' + TITLE_CHAR_DATA + '/' + charId + '.json',
			'images/' + TITLE_CHAR_DATA + '/' + charId.toLowerCase() + '.json',
			TITLE_CHAR_DATA + '/' + charId + '.json',
			TITLE_CHAR_DATA + '/' + charId.toLowerCase() + '.json',
			'data/characters/title/' + charId + '.json',
			'data/characters/title/' + charId.toLowerCase() + '.json'
		];
		for (path in candidates)
		{
			try
			{
				if(Paths.fileExists(path, TEXT))
				{
					var t:String = Paths.getTextFromFile(path);
					if(t != null && t.trim().length > 0)
					{
						trace('[TitleState] character JSON: ' + path);
						return t;
					}
				}
			}
			catch(e:Dynamic) {}
			#if sys
			try
			{
				if(sys.FileSystem.exists(path))
					return sys.io.File.getContent(path);
				var full:String = Paths.getPath(path, TEXT);
				if(full != null && sys.FileSystem.exists(full))
					return sys.io.File.getContent(full);
			}
			catch(e:Dynamic) {}
			#end
		}
		return null;
	}

	function applyTitleCharacterFile(data:TitleCharacterFile):Void
	{
		if(data == null) return;

		if(data.assetPath != null && data.assetPath.trim().length > 0)
			characterImage = resolveCharAsset(data.assetPath);

		if(data.renderType != null && data.renderType.trim().length > 0)
			titleRenderType = data.renderType.trim().toLowerCase();

		if(data.scale != null && data.scale > 0)
			titleCharScale = data.scale;

		if(data.useAntialiasing != null)
			titleUseAntialiasing = data.useAntialiasing == true;
		else
			titleUseAntialiasing = true;

		if(data.BPM != null && data.BPM > 0) musicBPM = data.BPM;
		else if(data.bpm != null && data.bpm > 0) musicBPM = data.bpm;

		if(data.positionOffsets != null && data.positionOffsets.length >= 2)
			gfPosition.set(data.positionOffsets[0], data.positionOffsets[1]);
		else if(data.gfx != null || data.gfy != null)
			gfPosition.set(data.gfx != null ? data.gfx : gfPosition.x, data.gfy != null ? data.gfy : gfPosition.y);

		if(data.logoOffsets != null && data.logoOffsets.length >= 2)
			logoPosition.set(data.logoOffsets[0], data.logoOffsets[1]);
		else if(data.titlex != null || data.titley != null)
			logoPosition.set(data.titlex != null ? data.titlex : logoPosition.x, data.titley != null ? data.titley : logoPosition.y);

		if(data.enterOffsets != null && data.enterOffsets.length >= 2)
			enterPosition.set(data.enterOffsets[0], data.enterOffsets[1]);
		else if(data.startx != null || data.starty != null)
			enterPosition.set(data.startx != null ? data.startx : enterPosition.x, data.starty != null ? data.starty : enterPosition.y);

		titleAnims = null;
		animOffsets = new Map();
		useIdle = false;

		if(data.animations != null && data.animations.length > 0)
		{
			titleAnims = data.animations;
			var hasLeft:Bool = false;
			var hasRight:Bool = false;
			var hasIdle:Bool = false;
			for (a in titleAnims)
			{
				if(a == null || a.name == null) continue;
				var n:String = a.name.toLowerCase();
				if(n == 'danceleft') hasLeft = true;
				else if(n == 'danceright') hasRight = true;
				else if(n == 'idle') hasIdle = true;
				if(a.offsets != null && a.offsets.length >= 2)
					animOffsets.set(a.name, [a.offsets[0], a.offsets[1]]);
			}
			useIdle = hasIdle && !hasLeft && !hasRight;
			if(hasLeft && hasRight) useIdle = false;
		}
		else
		{
			if(data.animation != null && data.animation.length > 0) animationName = data.animation;
			if(data.dance_left != null && data.dance_left.length > 0) danceLeftFrames = data.dance_left;
			if(data.dance_right != null && data.dance_right.length > 0) danceRightFrames = data.dance_right;
			useIdle = (data.idle == true);
		}

		if(data.backgroundSprite != null && data.backgroundSprite.trim().length > 0)
		{
			var bgKey:String = data.backgroundSprite.trim();
			if(bgKey.indexOf('/') < 0)
				bgKey = TITLE_IMAGES + '/' + bgKey;
			var bgG = loadGraphicSafe([bgKey, TITLE_IMAGES + '/' + bgKey]);
			if(bgG != null)
			{
				var bg:FlxSprite = new FlxSprite().loadGraphic(bgG);
				bg.antialiasing = ClientPrefs.data.antialiasing;
				add(bg);
			}
		}
	}

	function buildTitleCharacter():Void
	{
		gfDance = new FlxSprite(gfPosition.x, gfPosition.y);
		gfDance.antialiasing = titleUseAntialiasing && ClientPrefs.data.antialiasing;

		var tryKeys:Array<String> = [
			characterImage,
			TITLE_CHARS + '/Girlfriend-Title',
			TITLE_IMAGES + '/characters/Girlfriend-Title',
			'title/Girlfriend-Title',
			'Girlfriend-Title',
			'gf'
		];

		var frames:FlxAtlasFrames = null;
		if(titleRenderType == 'packer')
		{
			for (k in tryKeys)
			{
				try
				{
					frames = Paths.getPackerAtlas(k);
					if(frames != null) { characterImage = k; break; }
				}
				catch(e:Dynamic) {}
			}
		}
		if(frames == null)
			frames = loadSparrowSafe(tryKeys);

		if(frames == null)
		{
			trace('[TitleState] No title character atlas found — hiding character');
			gfDance.makeGraphic(1, 1, FlxColor.TRANSPARENT);
			gfDance.visible = false;
			return;
		}

		gfDance.frames = frames;
		gfDance.visible = true;

		if(titleAnims != null && titleAnims.length > 0)
		{
			for (a in titleAnims)
			{
				if(a == null || a.name == null || a.prefix == null) continue;
				var fps:Int = a.fps != null ? a.fps : 24;
				var loop:Bool = a.loop == true;
				try
				{
					if(a.indices != null && a.indices.length > 0)
						gfDance.animation.addByIndices(a.name, a.prefix, a.indices, '', fps, loop);
					else
						gfDance.animation.addByPrefix(a.name, a.prefix, fps, loop);
				}
				catch(e:Dynamic)
				{
					trace('[TitleState] anim add failed ' + a.name + ': ' + e);
				}
			}

			if(gfDance.animation.getByName('danceRight') != null)
				gfDance.animation.play('danceRight');
			else if(gfDance.animation.getByName('idle') != null)
			{
				useIdle = true;
				gfDance.animation.play('idle');
			}
			else if(gfDance.animation.getByName('danceLeft') != null)
				gfDance.animation.play('danceLeft');
		}
		else if(!useIdle)
		{
			try
			{
				gfDance.animation.addByIndices('danceLeft', animationName, danceLeftFrames, '', 24, false);
				gfDance.animation.addByIndices('danceRight', animationName, danceRightFrames, '', 24, false);
				gfDance.animation.play('danceRight');
			}
			catch(e:Dynamic)
			{
				try
				{
					gfDance.animation.addByPrefix('idle', animationName, 24, true);
					useIdle = true;
					gfDance.animation.play('idle');
				}
				catch(e2:Dynamic) {}
			}
		}
		else
		{
			try
			{
				gfDance.animation.addByPrefix('idle', animationName, 24, false);
				gfDance.animation.play('idle');
			}
			catch(e:Dynamic) {}
		}

		if(titleCharScale != 1 && titleCharScale > 0)
		{
			gfDance.scale.set(titleCharScale, titleCharScale);
			gfDance.updateHitbox();
		}

		if(gfDance.animation != null && gfDance.animation.name != null)
			applyAnimOffset(gfDance.animation.name);
	}

	function applyAnimOffset(animName:String):Void
	{
		if(gfDance == null || animName == null) return;
		var off:Array<Float> = animOffsets.get(animName);
		if(off == null)
		{
			for (k => v in animOffsets)
			{
				if(k.toLowerCase() == animName.toLowerCase())
				{
					off = v;
					break;
				}
			}
		}
		if(off != null)
			gfDance.offset.set(off[0], off[1]);
		else
			gfDance.offset.set(0, 0);
	}

	#if TITLE_SCREEN_EASTER_EGG
	function applyEasterEggCharacter():Void
	{
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = '';
		var easterEgg:String = Std.string(FlxG.save.data.psychDevsEasterEgg).toUpperCase();
		if(easterEgg.length < 1) return;

		var jsonId:String = switch(easterEgg)
		{
			case 'SHADOW': 'shadow';
			case 'RIVEREN': 'riveren';
			case 'BBPANZU': 'bbpanzu';
			case 'PESSY': 'pessy';
			default: easterEgg.toLowerCase();
		};

		var raw:String = readTitleCharJson(jsonId);
		if(raw != null && raw.trim().length > 0)
		{
			try
			{
				applyTitleCharacterFile(cast Json.parse(raw));
				return;
			}
			catch(e:Dynamic) {}
		}

		// images under menus/title_menu/images/easterEgg/ or characters/
		switch(easterEgg)
		{
			case 'SHADOW':
				characterImage = resolveCharAsset(TITLE_IMAGES + '/easterEgg/ShadowBump');
				if(!imageAssetExists(characterImage))
					characterImage = resolveCharAsset('ShadowBump');
				animationName = 'Shadow Title Bump';
				titleAnims = null;
				useIdle = true;
				gfPosition.x += 210;
				gfPosition.y += 40;
			case 'RIVEREN':
				characterImage = resolveCharAsset(TITLE_IMAGES + '/easterEgg/ZRiverBump');
				if(!imageAssetExists(characterImage))
					characterImage = resolveCharAsset('ZRiverBump');
				animationName = 'River Title Bump';
				titleAnims = null;
				useIdle = true;
				gfPosition.x += 180;
				gfPosition.y += 40;
			case 'BBPANZU':
				characterImage = resolveCharAsset(TITLE_IMAGES + '/easterEgg/BBBump');
				if(!imageAssetExists(characterImage))
					characterImage = resolveCharAsset('BBBump');
				animationName = 'BB Title Bump';
				titleAnims = null;
				useIdle = false;
				danceLeftFrames = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
				danceRightFrames = [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
				gfPosition.x += 45;
				gfPosition.y += 100;
			case 'PESSY':
				characterImage = resolveCharAsset(TITLE_IMAGES + '/easterEgg/PessyBump');
				if(!imageAssetExists(characterImage))
					characterImage = resolveCharAsset('PessyBump');
				animationName = 'Pessy Title Bump';
				titleAnims = null;
				useIdle = false;
				danceLeftFrames = [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
				danceRightFrames = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
				gfPosition.x += 165;
				gfPosition.y += 60;
		}
	}
	#end

	function getIntroTextShit():Array<Array<String>>
	{
		var firstArray:Array<String> = [];
		var introCandidates:Array<String> = [
			'images/' + TITLE_INTRO_TEXT,
			TITLE_INTRO_TEXT,
			'data/introText.txt'
		];
		try
		{
			#if MODS_ALLOWED
			for (ip in introCandidates)
			{
				var merged:Array<String> = Mods.mergeAllTextsNamed(ip);
				if(merged != null && merged.length > 0)
				{
					firstArray = merged;
					break;
				}
			}
			#end
			if(firstArray.length < 1)
			{
				for (ip in introCandidates)
				{
					try
					{
						if(Paths.fileExists(ip, TEXT))
						{
							var full:String = Paths.getTextFromFile(ip);
							if(full != null && full.length > 0)
							{
								firstArray = full.split('\n');
								break;
							}
						}
					}
					catch(e:Dynamic) {}
				}
			}
		}
		catch(e:Dynamic) {}

		if(firstArray.length < 1)
		{
			#if MODS_ALLOWED
			firstArray = Mods.mergeAllTextsNamed('data/introText.txt');
			#else
			try
			{
				var fullText:String = Assets.getText(Paths.txt('introText'));
				firstArray = fullText.split('\n');
			}
			catch(e:Dynamic) {}
			#end
		}

		var swagGoodArray:Array<Array<String>> = [];
		for (i in firstArray)
		{
			if(i == null) continue;
			var line:String = StringTools.trim(Std.string(i));
			if(line.length < 1) continue;
			var parts:Array<String> = line.split('--');
			if(parts.length < 1) continue;
			while(parts.length < 2) parts.push('');
			for (p in 0...parts.length)
				if(parts[p] == null) parts[p] = '';
				else parts[p] = StringTools.trim(parts[p]);
			swagGoodArray.push(parts);
		}
		if(swagGoodArray.length < 1)
			swagGoodArray.push(['Friday Night', 'Funkin']);
		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
			if (touch.justPressed) pressedEnter = true;
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.justPressed.START) pressedEnter = true;
			#if switch
			if (gamepad.justPressed.B) pressedEnter = true;
			#end
		}

		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter && titleText != null)
			{
				var timer:Float = titleTimer;
				if (timer >= 1) timer = (-timer) + 2;
				timer = FlxEase.quadInOut(timer);
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}

			if(pressedEnter)
			{
				if(titleText != null)
				{
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					if(titleText.animation != null && titleText.animation.getByName('press') != null)
						titleText.animation.play('press');
				}

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase();
						if (easterEggKeysBuffer.contains(word))
						{
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();
							FlxG.sound.play(Paths.sound('secret'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
							black.scale.set(FlxG.width, FlxG.height);
							black.updateHitbox();
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							if(FlxG.sound.music != null) FlxG.sound.music.fadeOut();
							try { if(FreeplayMenuState.vocals != null) FreeplayMenuState.vocals.fadeOut(); } catch(e:Dynamic) {}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if(textArray == null) return;
		for (i in 0...textArray.length)
		{
			var txt:String = textArray[i] != null ? textArray[i] : '';
			var money:Alphabet = new Alphabet(0, 0, txt, true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text != null ? text : '', true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0;
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null && logoBl.visible && logoBl.animation != null && logoBl.animation.getByName('bump') != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null && gfDance.visible && gfDance.animation != null)
		{
			danceLeft = !danceLeft;
			try
			{
				if(!useIdle)
				{
					if (danceLeft)
					{
						if(gfDance.animation.getByName('danceRight') != null)
						{
							gfDance.animation.play('danceRight');
							applyAnimOffset('danceRight');
						}
					}
					else if(gfDance.animation.getByName('danceLeft') != null)
					{
						gfDance.animation.play('danceLeft');
						applyAnimOffset('danceLeft');
					}
				}
				else if(curBeat % 2 == 0 && gfDance.animation.getByName('idle') != null)
				{
					gfDance.animation.play('idle', true);
					applyAnimOffset('idle');
				}
			}
			catch(e:Dynamic) {}
		}

		if(!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.playMusic(Paths.music('menu/freakyMenu'), 0);
					if(FlxG.sound.music != null)
						FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Pico Engine by'], 40);
				case 4:
					addMoreText('Lucas-Sanches', 40);
				case 5:
					deleteCoolText();
				case 6:
					createCoolText(['Not associated', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					if(ngSpr != null) ngSpr.visible = true;
				case 9:
					deleteCoolText();
					if(ngSpr != null) ngSpr.visible = false;
				case 10:
					var line0:String = (curWacky != null && curWacky.length > 0 && curWacky[0] != null) ? curWacky[0] : '...';
					createCoolText([line0]);
				case 12:
					var line1:String = (curWacky != null && curWacky.length > 1 && curWacky[1] != null) ? curWacky[1] : '';
					addMoreText(line1);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText("Friday");
				case 15:
					addMoreText("Night");
				case 16:
					addMoreText("Funkin'");
				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if TITLE_SCREEN_EASTER_EGG
			if (playJingle)
			{
				playJingle = false;
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVEREN':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					case 'PESSY':
						sound = FlxG.sound.play(Paths.sound('JinglePessy'));
					default:
						if(ngSpr != null) remove(ngSpr);
						if(credGroup != null) remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						FlxG.sound.playMusic(Paths.music('menu/freakyMenu'), 0);
						if(FlxG.sound.music != null)
							FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						if(ngSpr != null) remove(ngSpr);
						if(credGroup != null) remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else
				{
					if(ngSpr != null) remove(ngSpr);
					if(credGroup != null) remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					if(sound != null)
					{
						sound.onComplete = function() {
							FlxG.sound.playMusic(Paths.music('menu/freakyMenu'), 0);
							if(FlxG.sound.music != null)
								FlxG.sound.music.fadeIn(4, 0, 0.7);
							transitioning = false;
							#if ACHIEVEMENTS_ALLOWED
							if(easteregg == 'PESSY') Achievements.unlock('pessy_easter_egg');
							#end
						};
					}
					else transitioning = false;
				}
			}
			else #end
			{
				if(ngSpr != null) remove(ngSpr);
				if(credGroup != null) remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					if(FlxG.sound.music != null) FlxG.sound.music.fadeOut();
					try { if(FreeplayMenuState.vocals != null) FreeplayMenuState.vocals.fadeOut(); } catch(e:Dynamic) {}
				}
				#end
			}
			skippedIntro = true;
		}
	}
}
