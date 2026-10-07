package funkin.data.objects.game.notes.data;

import funkin.data.shaders.RGBPalette;
import funkin.data.objects.game.notes.NoteData;
import funkin.data.objects.game.notes.config.StrumNote;
import funkin.data.objects.game.notes.config.NoteTypesConfig;

import funkin.data.objects.game.characters.Character;
import funkin.data.shaders.RGBPalette.RGBShaderReference;
import funkin.utils.engines.psych.PsychAnimationController;

import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool,
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

typedef NoteSkinAnim = {
	@:optional var prefix:String;
	@:optional var fps:Null<Int>;
	@:optional var loop:Null<Bool>;
	@:optional var indices:Array<Int>;
}

typedef NoteSkinUiAsset = {
	@:optional var assetPath:Null<String>;
	@:optional var audioPath:Null<String>;
	@:optional var scale:Null<Float>;
	@:optional var isPixel:Null<Bool>;
	/** If true, hide this UI piece (e.g. comboNumber0) */
	@:optional var hidden:Null<Bool>;
}

typedef HoldNoteCoverConfig = {
	var enabled:Bool;
	var isPixel:Bool;
	var assetPaths:Array<Null<String>>;
	var startAnims:Array<Null<NoteSkinAnim>>;
	var holdAnims:Array<Null<NoteSkinAnim>>;
	var endAnims:Array<Null<NoteSkinAnim>>;
	var offsets:Array<Float>;
	var scale:Float;
	var centerOnStrum:Bool;
	var columns:Int;
	var rows:Int;
}

typedef NoteSkinConfig = {
	var animations:Map<String, NoteSkinAnim>;
	var uiAssets:Map<String, NoteSkinUiAsset>;
	var scale:Float;
	var noteScale:Float;
	var holdScale:Float;
	var strumScale:Float;
	var pixelNoteScale:Float;
	var pixelHoldScale:Float;
	var pixelStrumScale:Float;
	var allowRGB:Bool;
	var allowPixel:Bool;
	var noteAssetPath:Null<String>;
	var holdAssetPath:Null<String>;
	var strumAssetPath:Null<String>;
	var pixelNoteAssetPath:Null<String>;
	var pixelHoldAssetPath:Null<String>;
	var pixelStrumAssetPath:Null<String>;
	var noteSplashAssetPath:Null<String>;
	var holdNoteCover:HoldNoteCoverConfig;
	var pixelNoteColumns:Int;
	var pixelNoteRows:Int;
	var pixelHoldColumns:Int;
	var pixelHoldRows:Int;
	var pixelStrumColumns:Int;
	var pixelStrumRows:Int;
	/** Other noteStyle to inherit missing assets/UI from (e.g. "funkin") */
	@:optional var fallback:Null<String>;
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public static var noteSkinConfigs:Map<String, NoteSkinConfig> = new Map();
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !noteStyleUsesPixel(),
		useGlobalShader: false,
		useRGBShader: true,
		r: -1,
		g: -1,
		b: -1,
		a: Preferences.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(Preferences.data.hitsoundVolume > 0)
			return Preferences.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var arr:Array<FlxColor> = Preferences.data.arrowRGB[noteData];
		if(PlayState.isPixelStage) arr = Preferences.data.arrowRGBPixel[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String
	{
		noteSplashData.texture = songSplashSkinForMustPress(mustPress);
		defaultRGB();
		if(noteData > -1 && noteType != value)
		{
			switch(value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;

					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
					
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;

				case 'Alt Animation':
					animSuffix = '-Alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	/**
	 * Character noteStyle → pico_assets | Song/Chart noteStyle → data/notestyles
	 */
	public static function songArrowSkinForMustPress(mustPress:Bool):String
		return NoteData.noteStyle.songStyle(mustPress);

	public static function usesCharacterNoteStyle(mustPress:Bool):Bool
		return NoteData.noteStyle.usesCharacterNoteStyle(mustPress);

	public static function characterNoteStyleKey(mustPress:Bool):String
		return NoteData.noteStyle.characterNoteStyleKey(mustPress);

	public static function songNoteStyle():String
		return NoteData.noteStyle.songNoteStyle();

	/** Song/chart noteStyle: data/notestyles only (NOT pico_assets) */
	public static function normalizeSongNoteStyleName(skin:String):String
		return NoteData.noteStyle.normalizeSongNoteStyleName(skin);

	/** Character noteStyle: pico_assets game/custom-notes only */
	public static function normalizeCharacterNoteStyleName(skin:String):String
		return NoteData.noteStyle.normalizeCharacterNoteStyleName(skin);

	/** @deprecated use normalizeSongNoteStyleName / normalizeCharacterNoteStyleName */
	public static function normalizeNoteStyleName(skin:String):String
	{
		// Prefer song (data/notestyles), then character (pico)
		var song:String = normalizeSongNoteStyleName(skin);
		if(song.length > 0 && textAssetExists('data/notestyles/$song.json'))
			return song;
		var char:String = normalizeCharacterNoteStyleName(skin);
		if(char.length > 0)
			return char;
		return song;
	}

	public static function defaultSongNoteStyle():String
		return NoteData.noteStyle.defaultSongNoteStyle();

	public static function songSplashSkinForMustPress(mustPress:Bool):Null<String>
		return NoteData.noteStyle.songSplashSkinForMustPress(mustPress);

	public static function getSongNoteSkinConfig():NoteSkinConfig
	{
		var noteStyle:String = songNoteStyle();
		if(noteStyle == null || noteStyle.length < 1)
			noteStyle = defaultSongNoteStyle();
		return getNoteSkinConfig(noteStyle, false); // data/notestyles only
	}

	public static function resolveNoteStyleUiAsset(assetName:String, fallback:String):String
	{
		return NoteData.noteStyle.ui(assetName, fallback);
	}

	public static function resolveNoteStyleUiSound(assetName:String, fallback:String):String
	{
		return NoteData.noteStyle.uiSound(assetName, fallback);
	}

	public static function noteStyleUiScale(assetName:String, fallback:Float):Float
	{
		return NoteData.noteStyle.uiScale(assetName, fallback);
	}

	public static function noteStyleUiIsPixel(assetName:String, fallback:Bool):Bool
	{
		return NoteData.noteStyle.uiIsPixel(assetName, fallback);
	}

	/** true if this UI asset is marked hidden in the active noteStyle */
	public static function noteStyleUiIsHidden(assetName:String):Bool
	{
		var asset:NoteSkinUiAsset = getNoteStyleUiAsset(assetName);
		if(asset == null) return false;
		return asset.hidden == true;
	}

	static function getNoteStyleUiAsset(assetName:String):NoteSkinUiAsset
	{
		if(assetName == null || assetName.length < 1) return null;
		var config:NoteSkinConfig = getSongNoteSkinConfig();
		if(config == null || config.uiAssets == null) return null;
		return config.uiAssets.get(assetName);
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = Preferences.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (Preferences.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += Preferences.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			// RGB é controlado por noteStyle.allowRGB
			texture = '';

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(Preferences.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!noteStyleUsesPixel()) ? Preferences.data.arrowRGB[noteData] : Preferences.data.arrowRGBPixel[noteData];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	var noteSkinConfig:NoteSkinConfig;
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
public function reloadNote(texture:String = '', postfix:String = '') {
	if(texture == null) texture = '';
	if(postfix == null) postfix = '';

	var fromChar:Bool = (texture.length < 1) && usesCharacterNoteStyle(mustPress);
	var styleName:String = songArrowSkinForMustPress(mustPress);

	// noteSkin_assets.note_sprite (notestyle v2) + Psych fallback
	var skin:String = texture + postfix;
	if(texture.length < 1)
	{
		try
		{
			var sprite:String = NoteData.noteStyle.noteSprite(null, mustPress);
			if(sprite != null && sprite.length > 0)
				skin = sprite;
			else
				skin = NoteData.noteStyle.psychTexture(null, mustPress);
		}
		catch(e:Dynamic)
			skin = psychTextureFallback(mustPress);

		if(skin == null || skin.length < 1)
			skin = defaultSongNoteStyle();
		if(postfix != null && postfix.length > 0 && skin.indexOf(postfix) < 0)
			skin = skin + postfix;
	}

	var animName:String = null;
	if(animation.curAnim != null) {
		animName = animation.curAnim.name;
	}

	var skinPixel:String = skin;
	var lastScaleY:Float = scale.y;
	var skinPostfix:String = getNoteSkinPostfix();
	var customSkin:String = skin + skinPostfix;
	if(customSkin == _lastValidChecked || Paths.fileExists('images/$customSkin.png', IMAGE))
	{
		skin = customSkin;
		_lastValidChecked = customSkin;
	}
	else skinPostfix = '';

	// Prefer NoteData runtime → psychConfig (maps note_sprite + note_animations)
	try
	{
		var rt = NoteData.runtime(mustPress);
		if(rt != null && rt.psychConfig != null)
			noteSkinConfig = rt.psychConfig;
		else
			noteSkinConfig = getNoteSkinConfig(styleName != null ? styleName : skin, fromChar);
	}
	catch(e:Dynamic)
		noteSkinConfig = getNoteSkinConfig(skin, fromChar);

	var usePixelNotes:Bool = noteStyleUsesPixel(noteSkinConfig);
	if(usePixelNotes) {
		var assetType:String = isSustainNote ? 'holdNotePixel' : 'notePixel';
		var pixelAsset:String = resolveNoteSkinAsset(skin, noteSkinConfig, assetType);
		if(noteSkinAtlasExists(pixelAsset))
		{
			frames = getNoteSkinAtlas(pixelAsset);
		}
		else
		{
			if(!noteSkinImageExists(pixelAsset))
			{
				var fallbackAsset:String = fallbackNoteSkinAsset(skin, assetType);
				if(noteSkinImageExists(fallbackAsset))
					pixelAsset = fallbackAsset;
			}

			var graphic = getNoteSkinGraphic(pixelAsset);
			if(graphic == null)
			{
				var defaultPixelAsset:String = isSustainNote ? 'noteSkins/pixel/NOTE_assetsENDS' : 'noteSkins/pixel/NOTE_assets';
				graphic = getNoteSkinGraphic(defaultPixelAsset);
				if(graphic != null)
					pixelAsset = defaultPixelAsset;
			}
			if(graphic == null)
				return;

			var columns:Int = noteSkinColumns(noteSkinConfig, assetType);
			var rows:Int = noteSkinRows(noteSkinConfig, assetType);
			if(columns < 1) columns = 1;
			if(rows < 1) rows = 1;
			loadGraphic(graphic, true, Math.floor(graphic.width / columns), Math.floor(graphic.height / rows));
			if(isSustainNote)
				originalHeight = graphic.height / rows;
		}
		loadNoteAnims(assetType);
		antialiasing = false;
		if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
			rgbShader.enabled = false;

		if(isSustainNote) {
			offsetX += _lastNoteOffX;
			_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
			offsetX -= _lastNoteOffX;
		}
	} else {
		// Prefer noteSkin_assets.note_sprite from skin (already set above)
		var noteAsset:String = skin;
		if(!noteSkinAtlasExists(noteAsset))
			noteAsset = resolveNoteSkinAsset(skin, noteSkinConfig, isSustainNote ? 'sustain' : 'note');
		if(!noteSkinAtlasExists(noteAsset))
			noteAsset = 'noteSkins/NOTE_assets';
		frames = noteSkinAtlasExists(noteAsset) ? getNoteSkinAtlas(noteAsset) : null;
		if(frames == null)
			return;
		var normalType:String = isSustainNote ? 'holdNote' : 'note';
		loadNoteAnims(isSustainNote ? 'sustain' : 'note');
		if(noteSkinConfig != null && !noteSkinConfig.allowRGB)
			rgbShader.enabled = false;
		setGraphicSize(Std.int(width * noteSkinScale(noteSkinConfig, normalType)));
		if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
	}

	if(isSustainNote) {
		scale.y = lastScaleY;
	}
	updateHitbox();

	if(animName != null)
		animation.play(animName, true);

	// noteSkin_assets.note_position → posição na tela (offsetX / offsetY)
	applyNoteStylePosition();
}

	var _noteStylePosX:Float = 0;
	var _noteStylePosY:Float = 0;

	/** noteSkin_assets.note_position — posição extra na tela (não acumula em reload). */
	function applyNoteStylePosition():Void
	{
		// remove last style offset
		offsetX -= _noteStylePosX;
		offsetY -= _noteStylePosY;
		_noteStylePosX = 0;
		_noteStylePosY = 0;
		try
		{
			var rt = NoteData.runtime(mustPress);
			if(rt == null || rt.notePosition == null) return;
			if(rt.notePosition.length > 0 && !Math.isNaN(rt.notePosition[0]))
				_noteStylePosX = rt.notePosition[0];
			if(rt.notePosition.length > 1 && !Math.isNaN(rt.notePosition[1]))
				_noteStylePosY = rt.notePosition[1];
		}
		catch(e:Dynamic) {}
		offsetX += _noteStylePosX;
		offsetY += _noteStylePosY;
	}

	function psychTextureFallback(mustPress:Bool):String
	{
		try
		{
			return NoteData.noteStyle.psychTexture(null, mustPress);
		}
		catch(e:Dynamic)
		{
			return defaultSongNoteStyle();
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(Preferences.data.noteSkin != Preferences.defaultData.noteSkin)
			skin = '-' + Preferences.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims(assetType:String) {
		if (colArray[noteData] == null)
			return;

		// noteSkin_assets.note_animations → left/down/up/right
		var dirNames:Array<String> = ['left', 'down', 'up', 'right'];
		var dirKey:String = dirNames[noteData % dirNames.length];
		var colName:String = colArray[noteData];

		if (isSustainNote)
		{
			if(!tryAddAnimFromNoteStyle(colName + 'holdend', [dirKey + ' holdend', dirKey + 'end', colName + 'holdend']))
				addAnimationFromConfig(animation, colName + 'holdend', noteSkinConfig, colName + 'holdend');
			if(!tryAddAnimFromNoteStyle(colName + 'hold', [dirKey + ' hold', dirKey + 'hold', colName + 'hold']))
				addAnimationFromConfig(animation, colName + 'hold', noteSkinConfig, colName + 'hold');
		}
		else
		{
			if(!tryAddAnimFromNoteStyle(colName + 'Scroll', [dirKey, colName, colName + 'Scroll']))
				addAnimationFromConfig(animation, colName + 'Scroll', noteSkinConfig, colName + 'Scroll');
		}

		var scaleMul:Float = noteSkinScale(noteSkinConfig, assetType);
		try
		{
			var ns:Float = NoteData.noteStyle.noteScale(null, scaleMul);
			if(ns > 0) scaleMul = ns;
		}
		catch(e:Dynamic) {}
		setGraphicSize(Std.int(width * scaleMul));
		updateHitbox();
	}

	/** note_animations from notestyle JSON; true if added. */
	function tryAddAnimFromNoteStyle(animName:String, keys:Array<String>):Bool
	{
		try
		{
			for (k in keys)
			{
				if(k == null || k.length < 1) continue;
				var a = NoteData.noteStyle.noteAnim(k, null, mustPress);
				if(a == null || a.prefix == null || Std.string(a.prefix).length < 1) continue;
				var fps:Int = a.fps != null ? a.fps : 24;
				var loop:Bool = a.loop == true;
				if(a.indices != null && a.indices.length > 0)
					animation.addByIndices(animName, a.prefix, a.indices, '', fps, loop);
				else
					animation.addByPrefix(animName, a.prefix, fps, loop);
				return true;
			}
		}
		catch(e:Dynamic) {}
		return false;
	}

	/**
	 * @param fromCharacter true = load from pico_assets only; false = data/notestyles only; null = auto
	 */
	public static function getNoteSkinConfig(texture:String, ?fromCharacter:Null<Bool> = null):NoteSkinConfig
	{
		if(texture == null || texture.length < 1) return createNoteSkinConfig();

		var styleKey:String = noteStyleKey(texture);
		var styleJsonPath:String = 'data/notestyles/$styleKey.json';
		var picoJsonPath:String = styleKey.length > 0 ? picoCustomNoteJsonPath(styleKey) : null;
		var hasPicoJson:Bool = picoJsonPath != null && textAssetExists(picoJsonPath);
		var hasStyleJson:Bool = styleKey.length > 0 && textAssetExists(styleJsonPath);

		// Separate sources:
		// - Character noteStyle → pico_assets
		// - Chart/Song noteStyle → data/notestyles
		var usePico:Bool = false;
		var useShared:Bool = false;
		if(fromCharacter == true)
		{
			usePico = hasPicoJson;
			useShared = false;
		}
		else if(fromCharacter == false)
		{
			usePico = false;
			useShared = hasStyleJson;
		}
		else
		{
			// auto: prefer matching path that exists
			usePico = hasPicoJson;
			useShared = !usePico && hasStyleJson;
		}

		var cachePath:String = usePico ? picoJsonPath : (useShared ? 'data/notestyles/$styleKey' : 'images/$texture');
		if(noteSkinConfigs.exists(cachePath))
			return noteSkinConfigs.get(cachePath);

		var config:NoteSkinConfig = createNoteSkinConfig();
		var loadedPath:String = null;
		if(usePico)
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(readNoteSkinText(picoJsonPath));
				if(isNoteStyleJson(raw))
				{
					config = parseNoteSkinConfig(raw);
					loadedPath = picoJsonPath;
				}
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse pico $picoJsonPath: $e');
			}
		}

		if(loadedPath == null && useShared)
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(Paths.getTextFromFile(styleJsonPath));
				if(isNoteStyleJson(raw))
				{
					config = parseNoteSkinConfig(raw);
					loadedPath = 'data/notestyles/$styleKey';
				}
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse data/notestyles/$styleKey.json: $e');
			}
		}

		var imagePath:String = 'images/$texture';
		if(loadedPath == null && styleKey.length > 0 && texture.indexOf('/') < 0 && textAssetExists('images/noteSkins/$styleKey.json'))
			imagePath = 'images/noteSkins/$styleKey';
		if(loadedPath == null && textAssetExists('$imagePath.json'))
		{
			try
			{
				var raw:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$imagePath.json'));
				config = parseNoteSkinConfig(raw);
				loadedPath = imagePath;
			}
			catch(e:Dynamic)
			{
				trace('[NoteSkin] Failed to parse $imagePath.json: $e');
			}
		}

		// Inherit missing pieces from "fallback": "otherStyle"
		if(loadedPath != null)
			config = applyNoteStyleFallback(config, config.fallback, fromCharacter);

		noteSkinConfigs.set(loadedPath != null ? loadedPath : cachePath, config);
		return config;
	}

	static var _noteStyleFallbackStack:Array<String> = [];

	/**
	 * Merges missing assets/animations/UI from the fallback noteStyle.
	 * Child values always win; fallback only fills nulls / missing map keys.
	 */
	static function applyNoteStyleFallback(config:NoteSkinConfig, fallbackName:String, fromCharacter:Null<Bool>):NoteSkinConfig
	{
		if(config == null) return createNoteSkinConfig();
		var key:String = noteStyleKey(fallbackName);
		if(key == null || key.length < 1) return config;
		if(_noteStyleFallbackStack.indexOf(key) >= 0)
		{
			trace('[NoteSkin] Fallback loop blocked: $key');
			return config;
		}

		_noteStyleFallbackStack.push(key);
		try
		{
			var parent:NoteSkinConfig = null;
			if(fromCharacter == true)
			{
				parent = getNoteSkinConfig(key, true);
				// Character style can fall back to shared data/notestyles
				if(parent == null || (parent.noteAssetPath == null && parent.noteSplashAssetPath == null))
					parent = getNoteSkinConfig(key, false);
			}
			else if(fromCharacter == false)
			{
				parent = getNoteSkinConfig(key, false);
			}
			else
			{
				parent = getNoteSkinConfig(key, true);
				if(parent == null || parent.noteAssetPath == null)
					parent = getNoteSkinConfig(key, false);
			}

			if(parent != null)
				config = mergeNoteSkinConfig(config, parent);
		}
		catch(e:Dynamic)
		{
			trace('[NoteSkin] Failed fallback "$key": $e');
		}
		_noteStyleFallbackStack.pop();
		return config;
	}

	/** Child overwrites parent only where child already has data. */
	static function mergeNoteSkinConfig(child:NoteSkinConfig, parent:NoteSkinConfig):NoteSkinConfig
	{
		if(child == null) return parent != null ? parent : createNoteSkinConfig();
		if(parent == null) return child;

		if(child.noteAssetPath == null) child.noteAssetPath = parent.noteAssetPath;
		if(child.holdAssetPath == null) child.holdAssetPath = parent.holdAssetPath;
		if(child.strumAssetPath == null) child.strumAssetPath = parent.strumAssetPath;
		if(child.pixelNoteAssetPath == null) child.pixelNoteAssetPath = parent.pixelNoteAssetPath;
		if(child.pixelHoldAssetPath == null) child.pixelHoldAssetPath = parent.pixelHoldAssetPath;
		if(child.pixelStrumAssetPath == null) child.pixelStrumAssetPath = parent.pixelStrumAssetPath;
		if(child.noteSplashAssetPath == null) child.noteSplashAssetPath = parent.noteSplashAssetPath;

		// animations: fill missing keys
		if(parent.animations != null)
		{
			if(child.animations == null) child.animations = new Map();
			for(k in parent.animations.keys())
			{
				if(!child.animations.exists(k))
					child.animations.set(k, parent.animations.get(k));
			}
		}

		// UI assets (combo, countdown, judgements): fill missing / incomplete
		if(parent.uiAssets != null)
		{
			if(child.uiAssets == null) child.uiAssets = new Map();
			for(k in parent.uiAssets.keys())
			{
				if(!child.uiAssets.exists(k))
				{
					child.uiAssets.set(k, parent.uiAssets.get(k));
				}
				else
				{
					var c:NoteSkinUiAsset = child.uiAssets.get(k);
					var p:NoteSkinUiAsset = parent.uiAssets.get(k);
					if(c != null && p != null)
					{
						if(c.assetPath == null) c.assetPath = p.assetPath;
						if(c.audioPath == null) c.audioPath = p.audioPath;
						if(c.scale == null) c.scale = p.scale;
						if(c.isPixel == null) c.isPixel = p.isPixel;
						if(c.hidden == null) c.hidden = p.hidden;
					}
				}
			}
		}

		// hold cover: if child disabled/empty, take parent
		if(child.holdNoteCover == null)
			child.holdNoteCover = parent.holdNoteCover;
		else if(parent.holdNoteCover != null && child.holdNoteCover.enabled != true && parent.holdNoteCover.enabled == true)
			child.holdNoteCover = parent.holdNoteCover;

		return child;
	}

	public static function noteStyleKey(texture:String):String
	{
		if(texture == null) return '';
		var key:String = texture.trim().replace('\\', '/');
		if(key.length < 1) return '';
		if(key.startsWith('images/noteSkins/'))
			key = key.substr('images/noteSkins/'.length);
		else if(key.startsWith('noteSkins/'))
			key = key.substr('noteSkins/'.length);
		else if(key.startsWith('data/notestyles/'))
			key = key.substr('data/notestyles/'.length);
		else if(key.startsWith('notestyles/'))
			key = key.substr('notestyles/'.length);

		for (extension in ['.json', '.png', '.xml'])
		{
			if(key.endsWith(extension))
			{
				key = key.substr(0, key.length - extension.length);
				break;
			}
		}
		return key.indexOf('/') >= 0 ? '' : key;
	}

	static function isNoteStyleJson(raw:Dynamic):Bool
	{
		return raw != null && !Std.isOfType(raw, Array) && (Reflect.hasField(raw, 'assets') || Reflect.hasField(raw, 'animations'));
	}

	public static function createNoteSkinConfig():NoteSkinConfig
	{
		return {
			animations: new Map(),
			uiAssets: new Map(),
			scale: 0.7,
			noteScale: 0.7,
			holdScale: 0.7,
			strumScale: 0.7,
			pixelNoteScale: PlayState.daPixelZoom,
			pixelHoldScale: PlayState.daPixelZoom,
			pixelStrumScale: PlayState.daPixelZoom,
			allowRGB: true,
			allowPixel: false,
			noteAssetPath: null,
			holdAssetPath: null,
			strumAssetPath: null,
			pixelNoteAssetPath: null,
			pixelHoldAssetPath: null,
			pixelStrumAssetPath: null,
			noteSplashAssetPath: null,
			holdNoteCover: createHoldNoteCoverConfig(),
			pixelNoteColumns: 4,
			pixelNoteRows: 5,
			pixelHoldColumns: 4,
			pixelHoldRows: 2,
			pixelStrumColumns: 4,
			pixelStrumRows: 5,
			fallback: null
		};
	}

	static function createHoldNoteCoverConfig():HoldNoteCoverConfig
	{
		return {
			enabled: false,
			isPixel: false,
			assetPaths: [null, null, null, null],
			startAnims: [null, null, null, null],
			holdAnims: [null, null, null, null],
			endAnims: [null, null, null, null],
			offsets: [0, 0],
			scale: 1,
			centerOnStrum: true,
			columns: 1,
			rows: 1
		};
	}

	static function parseNoteSkinConfig(raw:Dynamic):NoteSkinConfig
	{
		var config:NoteSkinConfig = createNoteSkinConfig();
		if(raw == null) return config;

		// "fallback": "funkin" → inherit missing assets/UI from that style
		var fb:Dynamic = firstNoteSkinField(raw, ['fallback', 'inherits', 'parent']);
		if(fb != null)
		{
			var fbName:String = Std.string(fb).trim();
			if(fbName.length > 0 && fbName.toLowerCase() != 'null' && fbName.toLowerCase() != 'none')
				config.fallback = noteStyleKey(fbName);
		}

		config.scale = noteSkinFloat(Reflect.field(raw, 'scale'), config.scale);
		config.noteScale = config.scale;
		config.holdScale = config.scale;
		config.strumScale = config.scale;
		config.pixelNoteScale = PlayState.daPixelZoom;
		config.pixelHoldScale = PlayState.daPixelZoom;
		config.pixelStrumScale = PlayState.daPixelZoom;
		config.allowRGB = noteSkinBool(Reflect.field(raw, 'allowRGB'), config.allowRGB);
		// allowPixel / isPixel no root → pixel mode do estilo (sem stageUI)
		var rootPixel:Bool = noteSkinBool(Reflect.field(raw, 'isPixel'), false);
		config.allowPixel = noteSkinBool(Reflect.field(raw, 'allowPixel'), rootPixel);
		parseNoteSplashAsset(config, firstNoteSkinField(raw, ['noteSplashes', 'noteSplash', 'splashSkin']));

		var assets:Dynamic = Reflect.field(raw, 'assets');
		if(assets != null)
		{
			parseFunkinNoteStyleAsset(config, Reflect.field(assets, 'note'), 'note');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['sustain', 'sustainNote', 'holdNote']), 'sustain');
			parseFunkinNoteStyleAsset(config, Reflect.field(assets, 'noteStrumline'), 'noteStrumline');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['notePixel', 'pixelNote']), 'notePixel');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['holdNotePixel', 'pixelHoldNote', 'sustainPixel', 'pixelSustain', 'sustainNotePixel']), 'holdNotePixel');
			parseFunkinNoteStyleAsset(config, firstNoteSkinField(assets, ['noteStrumlinePixel', 'pixelNoteStrumline']), 'noteStrumlinePixel');
			parseNoteSplashAsset(config, firstNoteSkinField(assets, ['noteSplashes', 'noteSplash', 'splash']));
			var holdNoteCoverPixel:Dynamic = firstNoteSkinField(assets, ['holdNoteCoverPixel', 'pixelHoldNoteCover', 'holdCoverPixel', 'pixelHoldCover']);
			if(holdNoteCoverPixel != null)
				parseHoldNoteCoverAsset(config, holdNoteCoverPixel, true);
			else
				parseHoldNoteCoverAsset(config, firstNoteSkinField(assets, ['holdNoteCover', 'holdCover']));
			parseNoteStyleUiAssets(config, assets);

			if(config.strumAssetPath == null && config.noteAssetPath != null)
				config.strumAssetPath = config.noteAssetPath;
			if(config.strumScale == config.scale)
				config.strumScale = config.noteScale;
			if(config.holdAssetPath == null && config.noteAssetPath != null)
				config.holdAssetPath = config.noteAssetPath;
			if(config.holdScale == config.scale)
				config.holdScale = config.noteScale;
		}

		var animations:Dynamic = Reflect.field(raw, 'animations');
		if(animations != null)
		{
			for (key in Reflect.fields(animations))
			{
				var anim = parseNoteSkinAnim(Reflect.field(animations, key));
				if(anim != null)
					config.animations.set(key, anim);
			}
		}
		return config;
	}

	static function parseNoteStyleUiAssets(config:NoteSkinConfig, assets:Dynamic)
	{
		var keys:Array<String> = [
			'countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo',
			'judgementMarvelous', 'judgementPerfect', 'judgementSick', 'judgementGood', 'judgementBad', 'judgementShit',
			'combo'
		];
		for (i in 0...10)
			keys.push('comboNumber$i');

		for (key in keys)
			parseNoteStyleUiAsset(config, key, Reflect.field(assets, key));
	}

	static function parseNoteStyleUiAsset(config:NoteSkinConfig, key:String, raw:Dynamic)
	{
		if(raw == null) return;

		var assetPath:String = null;
		var audioPath:String = null;
		var scale:Null<Float> = null;
		var isPixel:Null<Bool> = null;
		var hidden:Null<Bool> = null;

		if(Std.isOfType(raw, String))
		{
			assetPath = cleanFunkinAssetPath(raw);
		}
		else
		{
			assetPath = cleanFunkinAssetPath(firstNoteSkinField(raw, ['assetPath', 'path', 'texture']));
			var data:Dynamic = Reflect.field(raw, 'data');
			audioPath = cleanFunkinSoundPath(firstNoteSkinField(raw, ['audioPath', 'soundPath', 'sound']));
			if(audioPath == null && data != null)
				audioPath = cleanFunkinSoundPath(firstNoteSkinField(data, ['audioPath', 'soundPath', 'sound']));

			var rawScale:Dynamic = Reflect.field(raw, 'scale');
			if(rawScale != null)
				scale = noteSkinFloat(rawScale, 1);

			var rawIsPixel:Dynamic = Reflect.field(raw, 'isPixel');
			if(rawIsPixel != null)
				isPixel = noteSkinBool(rawIsPixel, false);

			var rawHidden:Dynamic = firstNoteSkinField(raw, ['hidden', 'hide', 'invisible']);
			if(rawHidden != null)
				hidden = noteSkinBool(rawHidden, false);
			else if(data != null)
			{
				var dataHidden:Dynamic = firstNoteSkinField(data, ['hidden', 'hide', 'invisible']);
				if(dataHidden != null)
					hidden = noteSkinBool(dataHidden, false);
			}
		}

		if(assetPath != null || audioPath != null || scale != null || isPixel != null || hidden != null)
		{
			config.uiAssets.set(key, {
				assetPath: assetPath,
				audioPath: audioPath,
				scale: scale,
				isPixel: isPixel,
				hidden: hidden
			});
		}
	}

	static function parseFunkinNoteStyleAsset(config:NoteSkinConfig, asset:Dynamic, assetType:String)
	{
		if(asset == null) return;
		assetType = normalizeNoteSkinAssetType(assetType);

		var isPixel:Bool = noteSkinBool(Reflect.field(asset, 'isPixel'), false);
		if(isPixel)
		{
			switch(assetType)
			{
				case 'note':
					parseFunkinNoteStyleAsset(config, asset, 'notePixel');
					return;
				case 'holdNote':
					parseFunkinNoteStyleAsset(config, asset, 'holdNotePixel');
					return;
				case 'noteStrumline':
					parseFunkinNoteStyleAsset(config, asset, 'noteStrumlinePixel');
					return;
			}
		}

		var assetPath = cleanFunkinAssetPath(Reflect.field(asset, 'assetPath'));
		var assetScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.scale);
		switch(assetType)
		{
			case 'note':
				config.noteAssetPath = assetPath;
				config.noteScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['left', 'purpleScroll'],
					['down', 'blueScroll'],
					['up', 'greenScroll'],
					['right', 'redScroll'],
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold'],
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'holdNote':
				config.holdAssetPath = assetPath;
				config.holdScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold']
				]);
			case 'noteStrumline':
				config.strumAssetPath = assetPath;
				config.strumScale = assetScale;
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'notePixel':
				config.pixelNoteAssetPath = assetPath;
				config.pixelNoteScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelNoteScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['left', 'purpleScroll'],
					['down', 'blueScroll'],
					['up', 'greenScroll'],
					['right', 'redScroll'],
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
			case 'holdNotePixel':
				config.pixelHoldAssetPath = assetPath;
				config.pixelHoldScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelHoldScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftHoldEnd', 'purpleholdend'],
					['leftHold', 'purplehold'],
					['downHoldEnd', 'blueholdend'],
					['downHold', 'bluehold'],
					['upHoldEnd', 'greenholdend'],
					['upHold', 'greenhold'],
					['rightHoldEnd', 'redholdend'],
					['rightHold', 'redhold']
				]);
			case 'noteStrumlinePixel':
				config.pixelStrumAssetPath = assetPath;
				config.pixelStrumScale = noteSkinFloat(Reflect.field(asset, 'scale'), config.pixelStrumScale);
				readPixelGrid(config, asset, assetType);
				mapFunkinAnimations(config, Reflect.field(asset, 'data'), [
					['leftStatic', 'static0'],
					['leftPress', 'pressed0'],
					['leftConfirm', 'confirm0'],
					['downStatic', 'static1'],
					['downPress', 'pressed1'],
					['downConfirm', 'confirm1'],
					['upStatic', 'static2'],
					['upPress', 'pressed2'],
					['upConfirm', 'confirm2'],
					['rightStatic', 'static3'],
					['rightPress', 'pressed3'],
					['rightConfirm', 'confirm3'],
					['upStatic', 'green'],
					['downStatic', 'blue'],
					['leftStatic', 'purple'],
					['rightStatic', 'red']
				]);
		}
	}

	static function parseNoteSplashAsset(config:NoteSkinConfig, asset:Dynamic)
	{
		if(asset == null) return;

		var path:String = null;
		if(Std.isOfType(asset, String))
			path = cleanFunkinAssetPath(asset);
		else
			path = cleanFunkinAssetPath(firstNoteSkinField(asset, ['assetPath', 'path', 'texture']));

		if(path != null && path.length > 0)
			config.noteSplashAssetPath = path;
	}

	static function parseHoldNoteCoverAsset(config:NoteSkinConfig, asset:Dynamic, defaultIsPixel:Bool = false)
	{
		if(asset == null) return;

		var cover:HoldNoteCoverConfig = createHoldNoteCoverConfig();
		var data:Dynamic = Reflect.field(asset, 'data');
		cover.enabled = noteSkinBool(firstNoteSkinField(asset, ['enabled']), noteSkinBool(data != null ? Reflect.field(data, 'enabled') : null, true));
		cover.isPixel = noteSkinBool(firstNoteSkinField(asset, ['isPixel', 'pixel']), defaultIsPixel);
		cover.scale = noteSkinFloat(Reflect.field(asset, 'scale'), cover.scale);
		cover.offsets = noteSkinFloatArray(firstNoteSkinField(asset, ['offsets', 'offset']), cover.offsets, 2);
		cover.centerOnStrum = noteSkinBool(firstNoteSkinField(asset, ['centerOnStrum', 'centered', 'center']), cover.centerOnStrum);
		cover.columns = noteSkinInt(firstNoteSkinField(asset, ['columns', 'cols', 'frameColumns']), cover.columns);
		cover.rows = noteSkinInt(firstNoteSkinField(asset, ['rows', 'frameRows']), cover.rows);

		var defaultAsset:String = cleanFunkinAssetPath(firstNoteSkinField(asset, ['assetPath', 'path', 'texture']));
		var directionFields:Array<String> = ['left', 'down', 'up', 'right'];
		var fallbackAssets:Array<String> = cover.isPixel ? [null, null, null, null] : ['holdCover/holdCoverPurple', 'holdCover/holdCoverBlue', 'holdCover/holdCoverGreen', 'holdCover/holdCoverRed'];

		for (i in 0...directionFields.length)
		{
			var rawDirection:Dynamic = data != null ? Reflect.field(data, directionFields[i]) : null;
			var directionAsset:String = rawDirection != null ? cleanFunkinAssetPath(firstNoteSkinField(rawDirection, ['assetPath', 'path', 'texture'])) : null;
			cover.assetPaths[i] = directionAsset != null && directionAsset.length > 0 ? directionAsset : (defaultAsset != null && defaultAsset.length > 0 ? defaultAsset : fallbackAssets[i]);

			if(rawDirection != null)
			{
				cover.startAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'start'));
				cover.holdAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'hold'));
				cover.endAnims[i] = parseNoteSkinAnim(Reflect.field(rawDirection, 'end'));
			}
		}

		config.holdNoteCover = cover;
	}

	static function readPixelGrid(config:NoteSkinConfig, asset:Dynamic, assetType:String)
	{
		var columns:Int = noteSkinInt(firstNoteSkinField(asset, ['columns', 'cols', 'frameColumns']), noteSkinColumns(config, assetType));
		var rows:Int = noteSkinInt(firstNoteSkinField(asset, ['rows', 'frameRows']), noteSkinRows(config, assetType));
		switch(assetType)
		{
			case 'notePixel':
				config.pixelNoteColumns = columns;
				config.pixelNoteRows = rows;
			case 'holdNotePixel':
				config.pixelHoldColumns = columns;
				config.pixelHoldRows = rows;
			case 'noteStrumlinePixel':
				config.pixelStrumColumns = columns;
				config.pixelStrumRows = rows;
		}
	}

	static function mapFunkinAnimations(config:NoteSkinConfig, data:Dynamic, keys:Array<Array<String>>)
	{
		if(data == null) return;
		for (pair in keys)
		{
			var raw = Reflect.field(data, pair[0]);
			var anim = parseNoteSkinAnim(raw);
			if(anim != null)
				config.animations.set(pair[1], anim);
		}
	}

	static function parseNoteSkinAnim(raw:Dynamic):NoteSkinAnim
	{
		if(raw == null) return null;

		var prefixValue:Dynamic = Reflect.field(raw, 'prefix');
		var indices:Array<Int> = noteSkinIntArray(firstNoteSkinField(raw, ['indices', 'frameIndices', 'frames']));
		if(prefixValue == null && indices.length < 1) return null;

		var fps:Null<Int> = null;
		var rawFps:Dynamic = firstNoteSkinField(raw, ['fps', 'frameRate', 'framerate']);
		if(rawFps != null)
		{
			if(Std.isOfType(rawFps, Array))
			{
				var fpsArray:Array<Dynamic> = cast rawFps;
				if(fpsArray.length > 0) fps = noteSkinInt(fpsArray[0], 24);
			}
			else fps = noteSkinInt(rawFps, 24);
		}

		return {
			prefix: prefixValue != null ? Std.string(prefixValue) : null,
			fps: fps,
			loop: firstNoteSkinField(raw, ['loop', 'looped']) != null ? noteSkinBool(firstNoteSkinField(raw, ['loop', 'looped']), true) : null,
			indices: indices
		};
	}

	static function firstNoteSkinField(raw:Dynamic, names:Array<String>):Dynamic
	{
		for (name in names)
		{
			var value = Reflect.field(raw, name);
			if(value != null) return value;
		}
		return null;
	}

	public static function resolveNoteSkinAsset(texture:String, config:NoteSkinConfig, assetType:String):String
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config != null)
		{
			var assetPath:String = switch(assetType)
			{
				case 'note': config.noteAssetPath;
				case 'holdNote': config.holdAssetPath != null ? config.holdAssetPath : config.noteAssetPath;
				case 'noteStrumline': config.strumAssetPath != null ? config.strumAssetPath : config.noteAssetPath;
				case 'notePixel': config.pixelNoteAssetPath != null ? config.pixelNoteAssetPath : config.noteAssetPath;
				case 'holdNotePixel': config.pixelHoldAssetPath != null ? config.pixelHoldAssetPath : (config.holdAssetPath != null ? config.holdAssetPath : config.noteAssetPath);
				case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumAssetPath : (config.pixelNoteAssetPath != null ? config.pixelNoteAssetPath : config.strumAssetPath);
				default: null;
			}

			if(imageAssetExists(assetPath))
				return assetPath;

			var relativeAsset:String = resolveStyleRelativeNoteSkinAsset(texture, assetPath, assetType);
			if(relativeAsset != null)
				return relativeAsset;
		}
		var fallbackAsset:String = fallbackNoteSkinAsset(texture, assetType);
		if(fallbackAsset != null)
			return fallbackAsset;
		return texture;
	}

	static function resolveStyleRelativeNoteSkinAsset(texture:String, assetPath:String, assetType:String):String
	{
		if(assetPath == null || assetPath.length < 1)
			return null;

		assetType = normalizeNoteSkinAssetType(assetType);
		var styleKey:String = noteStyleKey(texture);
		var cleanAsset:String = cleanFunkinAssetPath(assetPath);
		if(cleanAsset == null || cleanAsset.length < 1)
			return null;

		var candidates:Array<String> = [];
		if(cleanAsset.indexOf('/') < 0)
		{
			if(styleKey == 'pixel' || assetType == 'notePixel' || assetType == 'holdNotePixel' || assetType == 'noteStrumlinePixel')
				candidates.push('noteSkins/pixel/$cleanAsset');
			if(styleKey.length > 0 && styleKey != 'funkin' && styleKey != 'pixel')
				candidates.push('noteSkins/$styleKey/$cleanAsset');
			candidates.push('noteSkins/$cleanAsset');
		}

		for(candidate in candidates)
		{
			if(imageAssetExists(candidate))
				return candidate;
		}
		return null;
	}

	static function fallbackNoteSkinAsset(texture:String, assetType:String):String
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		var styleKey:String = noteStyleKey(texture);
		var cleanTexture:String = texture == null ? '' : texture.trim().replace('\\', '/');
		var isPixelStyle:Bool = styleKey == 'pixel' || cleanTexture == 'pixel' || cleanTexture.endsWith('/pixel');
		var candidates:Array<String> = [];

		switch(assetType)
		{
			case 'notePixel', 'noteStrumlinePixel':
				if(isPixelStyle)
					candidates = ['noteSkins/pixel/NOTE_assets', 'weeb/pixelUI/arrows-pixels-rgb', 'weeb/pixelUI/arrows-pixels', 'pixelUI/noteSkins/NOTE_assets'];
				else if(styleKey.length > 0)
					candidates = ['noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
			case 'holdNotePixel':
				if(isPixelStyle)
					candidates = ['noteSkins/pixel/NOTE_assetsENDS', 'weeb/pixelUI/arrowEndsNew-rgb', 'weeb/pixelUI/arrowEndsNew', 'pixelUI/noteSkins/NOTE_assetsENDS'];
				else if(styleKey.length > 0)
					candidates = ['noteSkins/$styleKey/NOTE_assetsENDS', 'noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
			case 'note', 'holdNote', 'noteStrumline':
				if(styleKey.length > 0 && styleKey != 'funkin')
					candidates = ['noteSkins/$styleKey/NOTE_assets', 'noteSkins/NOTE_assets'];
				else if(styleKey == 'funkin' || cleanTexture == 'funkin')
					candidates = ['noteSkins/NOTE_assets'];
			default:
		}

		for(candidate in candidates)
		{
			if(imageAssetExists(candidate))
				return candidate;
		}
		return null;
	}

	static function imageAssetExists(assetPath:String):Bool
	{
		if(assetPath == null || assetPath.length < 1)
			return false;

		#if sys
		var picoImage:String = picoNoteSkinAssetPath(assetPath, 'png');
		if(picoImage != null && sys.FileSystem.exists(picoImage))
			return true;
		#end

		var key:String = 'images/$assetPath.png';
		if(Paths.fileExists(key, IMAGE))
			return true;
		#if sys
		if(sys.FileSystem.exists(Paths.getPath(key, IMAGE, null, true)))
			return true;
		#end
		return false;
	}

	public static function noteSkinImageExists(assetPath:String):Bool
	{
		return imageAssetExists(assetPath);
	}

	public static function noteSkinAtlasExists(assetPath:String):Bool
	{
		if(!imageAssetExists(assetPath))
			return false;

		if(textAssetExists('images/$assetPath.xml'))
			return true;

		#if sys
		var picoXml:String = picoNoteSkinAssetPath(assetPath, 'xml');
		if(picoXml != null && sys.FileSystem.exists(picoXml))
			return true;
		#end
		return false;
	}

	static function textAssetExists(key:String):Bool
	{
		if(key == null || key.length < 1)
			return false;

		#if sys
		if(key.startsWith('assets/') && sys.FileSystem.exists(key))
			return true;
		#end

		if(Paths.fileExists(key, TEXT))
			return true;
		#if sys
		if(sys.FileSystem.exists(Paths.getPath(key, TEXT, null, true)))
			return true;
		#end
		return false;
	}

	public static function getNoteSkinGraphic(assetPath:String):FlxGraphic
	{
		#if sys
		var picoImage:String = picoNoteSkinAssetPath(assetPath, 'png');
		if(picoImage != null && sys.FileSystem.exists(picoImage))
		{
			var bitmap:BitmapData = BitmapData.fromFile(picoImage);
			if(bitmap != null)
				return Paths.cacheBitmap(picoImage, null, bitmap);
		}
		#end
		return Paths.image(assetPath);
	}

	public static function getNoteSkinAtlas(assetPath:String):FlxAtlasFrames
	{
		if(assetPath == null || assetPath.length < 1)
			return null;

		#if sys
		var picoXml:String = picoNoteSkinAssetPath(assetPath, 'xml');
		if(picoXml != null && sys.FileSystem.exists(picoXml))
		{
			var graphic:FlxGraphic = getNoteSkinGraphic(assetPath);
			if(graphic != null)
			{
				try
				{
					var xmlData:String = sys.io.File.getContent(picoXml);
					if(xmlData != null && xmlData.length > 0)
						return FlxAtlasFrames.fromSparrow(graphic, xmlData);
				}
				catch(e:Dynamic)
				{
					trace('[NoteSkin] Failed atlas from pico $assetPath: $e');
				}
			}
		}
		#end

		try
		{
			if(Paths.fileExists('images/$assetPath.png', IMAGE) && Paths.fileExists('images/$assetPath.xml', TEXT))
				return Paths.getSparrowAtlas(assetPath);
		}
		catch(e:Dynamic)
		{
			trace('[NoteSkin] Failed atlas $assetPath: $e');
		}
		return null;
	}

	static function picoCustomNoteJsonPath(styleKey:String):String
	{
		if(styleKey == null || styleKey.length < 1)
			return null;

		return Paths.getPicoFunkinFolder('game/custom-notes/data/$styleKey.json');
	}

	static function picoNoteSkinAssetPath(assetPath:String, extension:String):String
	{
		var clean:String = cleanFunkinAssetPath(assetPath);
		if(clean == null || clean.length < 1)
			return null;

		// Explicit pico_assets paths
		if(clean.startsWith('game/'))
			return Paths.getPicoFunkinFolder(clean + '.' + extension);
		if(clean.startsWith('ui/notes/'))
			return Paths.getPicoFunkinFolder('game/' + clean + '.' + extension);

		// Strip known prefixes so we resolve under pico folders
		var rel:String = clean;
		if(rel.startsWith('custom-notes/images/'))
			rel = rel.substr('custom-notes/images/'.length);
		else if(rel.startsWith('custom-notes/'))
			rel = rel.substr('custom-notes/'.length);
		else if(rel.startsWith('custom-splashes/images/'))
			rel = rel.substr('custom-splashes/images/'.length);
		else if(rel.startsWith('custom-splashes/'))
			rel = rel.substr('custom-splashes/'.length);

		var candidates:Array<String> = [
			Paths.getPicoFunkinFolder('game/custom-notes/images/' + rel + '.' + extension),
			Paths.getPicoFunkinFolder('game/custom-notes/' + rel + '.' + extension),
			Paths.getPicoFunkinFolder('game/custom-splashes/images/' + rel + '.' + extension),
			Paths.getPicoFunkinFolder('game/custom-splashes/' + rel + '.' + extension),
			// also try original clean under custom-notes/images
			Paths.getPicoFunkinFolder('game/custom-notes/images/' + clean + '.' + extension),
			Paths.getPicoFunkinFolder('game/custom-splashes/images/' + clean + '.' + extension)
		];
		#if sys
		for (p in candidates)
		{
			if(p != null && sys.FileSystem.exists(p))
				return p;
		}
		#end
		// Prefer notes path when file might not exist yet (callers check existence)
		return candidates[0];
	}

	static function readNoteSkinText(key:String):String
	{
		#if sys
		if(key != null && key.startsWith('assets/') && sys.FileSystem.exists(key))
			return sys.io.File.getContent(key);
		#end
		return Paths.getTextFromFile(key, true);
	}

	public static function holdNoteCoverEnabled(config:NoteSkinConfig):Bool
	{
		return config != null && config.holdNoteCover != null && config.holdNoteCover.enabled;
	}

	public static function resolveHoldNoteCoverAsset(config:NoteSkinConfig, noteData:Int):String
	{
		if(!holdNoteCoverEnabled(config))
			return null;

		var id:Int = FlxMath.wrap(noteData, 0, 3);
		var assetPath:String = config.holdNoteCover.assetPaths[id];
		if(imageAssetExists(assetPath))
			return assetPath;

		var cleanAsset:String = cleanFunkinAssetPath(assetPath);
		if(cleanAsset != null && cleanAsset.indexOf('/') < 0)
		{
			if(config.holdNoteCover.isPixel)
			{
				var pixelCandidate:String = 'noteSkins/pixel/$cleanAsset';
				if(imageAssetExists(pixelCandidate))
					return pixelCandidate;
			}

			var candidate:String = 'holdCover/$cleanAsset';
			if(imageAssetExists(candidate))
				return candidate;
		}

		if(config.holdNoteCover.isPixel)
			return null;

		var fallback:Array<String> = ['holdCover/holdCoverPurple', 'holdCover/holdCoverBlue', 'holdCover/holdCoverGreen', 'holdCover/holdCoverRed'];
		return imageAssetExists(fallback[id]) ? fallback[id] : null;
	}

	public static function holdNoteCoverScale(config:NoteSkinConfig):Float
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.scale : 1;
	}

	public static function holdNoteCoverIsPixel(config:NoteSkinConfig):Bool
	{
		return holdNoteCoverEnabled(config) && config.holdNoteCover.isPixel;
	}

	public static function holdNoteCoverColumns(config:NoteSkinConfig):Int
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.columns : 1;
	}

	public static function holdNoteCoverRows(config:NoteSkinConfig):Int
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.rows : 1;
	}

	public static function holdNoteCoverOffset(config:NoteSkinConfig):Array<Float>
	{
		return holdNoteCoverEnabled(config) ? config.holdNoteCover.offsets : [0, 0];
	}

	public static function holdNoteCoverCenterOnStrum(config:NoteSkinConfig):Bool
	{
		return holdNoteCoverEnabled(config) && config.holdNoteCover.centerOnStrum;
	}

	public static function addHoldNoteCoverAnimation(controller:FlxAnimationController, animName:String, config:NoteSkinConfig, noteData:Int, coverPart:String):Bool
	{
		if(!holdNoteCoverEnabled(config))
			return false;

		var id:Int = FlxMath.wrap(noteData, 0, 3);
		var anim:NoteSkinAnim = switch(coverPart)
		{
			case 'start': config.holdNoteCover.startAnims[id];
			case 'end': config.holdNoteCover.endAnims[id];
			default: config.holdNoteCover.holdAnims[id];
		}

		var fallbackColors:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];
		var fallbackPrefix:String = switch(coverPart)
		{
			case 'start': 'holdCoverStart${fallbackColors[id]}';
			case 'end': 'holdCoverEnd${fallbackColors[id]}';
			default: 'holdCover${fallbackColors[id]}';
		}

		if(anim == null)
			return addAnimationFromConfig(controller, animName, null, '', fallbackPrefix, 24, coverPart == 'hold');

		var tempConfig:NoteSkinConfig = createNoteSkinConfig();
		tempConfig.animations.set(animName, anim);
		return addAnimationFromConfig(controller, animName, tempConfig, animName, fallbackPrefix, 24, coverPart == 'hold');
	}

	/**
	 * Pixel mode from noteStyle.allowPixel / isPixel — does NOT require PlayState.isPixelStage.
	 */
	public static function noteStyleUsesPixel(?config:NoteSkinConfig = null, ?mustPress:Null<Bool> = null):Bool
		return NoteData.noteStyle.noteStyleUsesPixel(config, mustPress);

	/** Scale for notes/strums/holds from the active noteStyle */
	public static function noteStyleScale(assetType:String, ?mustPress:Null<Bool> = null, fallback:Float = 0.7):Float
	{
		var config:NoteSkinConfig = null;
		if(mustPress != null)
			config = getNoteSkinConfig(songArrowSkinForMustPress(mustPress), usesCharacterNoteStyle(mustPress));
		else
			config = getSongNoteSkinConfig();
		if(config == null) return fallback;

		var usePixel:Bool = noteStyleUsesPixel(config);
		var type:String = assetType;
		if(usePixel)
		{
			if(type == 'note' || type == '') type = 'notePixel';
			else if(type == 'holdNote' || type == 'sustain') type = 'holdNotePixel';
			else if(type == 'noteStrumline' || type == 'strum') type = 'noteStrumlinePixel';
		}
		var scale:Float = noteSkinScale(config, type);
		return scale > 0 ? scale : fallback;
	}

	public static function noteSkinScale(config:NoteSkinConfig, assetType:String):Float
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return 0.7;
		return switch(assetType)
		{
			case 'note': config.noteScale;
			case 'holdNote': config.holdScale;
			case 'noteStrumline': config.strumScale;
			case 'notePixel': config.pixelNoteScale;
			case 'holdNotePixel': config.pixelHoldScale;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumScale : config.pixelNoteScale;
			default: config.scale;
		}
	}

	public static function noteSkinColumns(config:NoteSkinConfig, assetType:String):Int
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return assetType == 'holdNotePixel' ? 4 : 4;
		return switch(assetType)
		{
			case 'notePixel': config.pixelNoteColumns;
			case 'holdNotePixel': config.pixelHoldColumns;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumColumns : config.pixelNoteColumns;
			default: 1;
		}
	}

	public static function noteSkinRows(config:NoteSkinConfig, assetType:String):Int
	{
		assetType = normalizeNoteSkinAssetType(assetType);
		if(config == null) return assetType == 'holdNotePixel' ? 2 : 5;
		return switch(assetType)
		{
			case 'notePixel': config.pixelNoteRows;
			case 'holdNotePixel': config.pixelHoldRows;
			case 'noteStrumlinePixel': config.pixelStrumAssetPath != null ? config.pixelStrumRows : config.pixelNoteRows;
			default: 1;
		}
	}

	public static function normalizeNoteSkinAssetType(assetType:String):String
	{
		if(assetType == 'sustain' || assetType == 'sustainNote')
			return 'holdNote';
		if(assetType == 'sustainPixel' || assetType == 'pixelSustain' || assetType == 'sustainNotePixel')
			return 'holdNotePixel';
		return assetType;
	}

	static function cleanFunkinAssetPath(value:Dynamic):String
	{
		if(value == null) return null;
		var path = Std.string(value).trim();
		if(path.length < 1 || path == 'null') return null;

		if(path.contains(':'))
			path = path.substr(path.indexOf(':') + 1);

		if(path.startsWith('images/'))
			path = path.substr('images/'.length);
		if(path.startsWith('assets/images/'))
			path = path.substr('assets/images/'.length);
		for (extension in ['.png', '.xml', '.json'])
		{
			if(path.endsWith(extension))
			{
				path = path.substr(0, path.length - extension.length);
				break;
			}
		}

		return path;
	}

	static function cleanFunkinSoundPath(value:Dynamic):String
	{
		if(value == null) return null;
		var path = Std.string(value).trim();
		if(path.length < 1 || path == 'null') return null;

		if(path.contains(':'))
			path = path.substr(path.indexOf(':') + 1);

		if(path.startsWith('sounds/'))
			path = path.substr('sounds/'.length);
		if(path.startsWith('assets/sounds/'))
			path = path.substr('assets/sounds/'.length);
		for (extension in ['.ogg', '.mp3', '.wav'])
		{
			if(path.endsWith(extension))
			{
				path = path.substr(0, path.length - extension.length);
				break;
			}
		}

		return path;
	}

	public static function addAnimationFromConfig(controller:FlxAnimationController, animName:String, config:NoteSkinConfig, configKey:String, ?fallbackPrefix:String, fallbackFps:Int = 24, fallbackLoop:Bool = true):Bool
	{
		var prefix:String = fallbackPrefix;
		var fps:Int = fallbackFps;
		var loop:Bool = fallbackLoop;
		var indices:Array<Int> = null;

		var anim:NoteSkinAnim = config != null ? config.animations.get(configKey) : null;
		if(anim != null)
		{
			if(anim.prefix != null && anim.prefix.length > 0) prefix = anim.prefix;
			if(anim.fps != null) fps = anim.fps;
			if(anim.loop != null) loop = anim.loop;
			if(anim.indices != null && anim.indices.length > 0) indices = anim.indices;
		}

		if(indices != null && indices.length > 0 && (prefix == null || prefix.length < 1))
			controller.add(animName, indices, fps, loop);
		else if(indices != null && indices.length > 0)
			controller.addByIndices(animName, prefix, indices, '', fps, loop);
		else if(prefix != null && prefix.length > 0)
			controller.addByPrefix(animName, prefix, fps, loop);
		else return false;

		return true;
	}

	static function noteSkinFloat(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function noteSkinFloatArray(value:Dynamic, fallback:Array<Float>, minimumLength:Int = 0):Array<Float>
	{
		var result:Array<Float> = [];
		if(value != null)
		{
			if(Std.isOfType(value, Array))
			{
				var array:Array<Dynamic> = cast value;
				for (item in array)
				{
					var parsed:Float = Std.parseFloat(Std.string(item));
					if(!Math.isNaN(parsed)) result.push(parsed);
				}
			}
			else
			{
				for (item in Std.string(value).split(','))
				{
					var parsed:Float = Std.parseFloat(item.trim());
					if(!Math.isNaN(parsed)) result.push(parsed);
				}
			}
		}

		for (i in result.length...minimumLength)
			result.push(fallback != null && i < fallback.length ? fallback[i] : 0);
		return result.length > 0 ? result : fallback.copy();
	}

	static function noteSkinInt(value:Dynamic, fallback:Int):Int
	{
		if(value == null) return fallback;
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	static function noteSkinBool(value:Dynamic, fallback:Bool):Bool
	{
		if(value == null) return fallback;
		if(Std.isOfType(value, Bool)) return value;

		var text = Std.string(value).trim().toLowerCase();
		if(text == 'true' || text == '1') return true;
		if(text == 'false' || text == '0') return false;
		return fallback;
	}

	static function noteSkinIntArray(value:Dynamic):Array<Int>
	{
		var result:Array<Int> = [];
		if(value == null) return result;

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			for (item in array)
			{
				var parsed:Null<Int> = Std.parseInt(Std.string(item));
				if(parsed != null) result.push(parsed);
			}
		}
		else
		{
			for (item in Std.string(value).split(','))
			{
				var parsed:Null<Int> = Std.parseInt(item.trim());
				if(parsed != null) result.push(parsed);
			}
		}
		return result;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Opponent Mode: player hittable side follows playsAsBF(), not raw mustPress
		var playerSide:Bool = true;
		try { playerSide = PlayState.isPlayerNoteSide(mustPress); } catch(e:Dynamic) { playerSide = mustPress; }

		if (playerSide)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			// CPU side auto-hit (BF notes when Opponent Mode is on)
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote != null && prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		var clipPlayerSide:Bool = true;
		try { clipPlayerSide = PlayState.isPlayerNoteSide(mustPress); } catch(e:Dynamic) { clipPlayerSide = mustPress; }
		if((clipPlayerSide || !ignoreNote) && (wasGoodHit || (prevNote != null && prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}