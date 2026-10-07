package funkin.data.objects.game.characters;

import funkin.play.Song;
import funkin.stages.objects.levels.week7.TankmenBG;
import funkin.data.objects.game.notes.data.Note;
import funkin.utils.engines.psych.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	@:optional var assetPath:String;
	@:optional var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	@:optional var positionOffsets:Array<Float>;
	@:optional var position:Array<Float>;
	@:optional var offsets:Array<Float>;
	@:optional var cameraOffsets:Array<Float>;
	@:optional var camera_position:Array<Float>;
	// BETADCIU-style player side offsets (quando o char é o player)
	@:optional var player_position:Array<Float>;
	@:optional var playerposition:Array<Float>;
	@:optional var player_camera_position:Array<Float>;
	@:optional var is_player_char:Bool;
	@:optional var isPlayerChar:Bool;

	var flip_x:Bool;
	@:optional var isPixel:Bool;
	@:optional var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var Type:String;
	@:optional var characterType:String;
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	@:optional var noteStyle:String;
	@:optional var renderType:String;
	@:optional var _editor_isPlayer:Null<Bool>;
	// New Pico character format (normalized on load)
	@:optional var character_animations_data:Array<Dynamic>;
	@:optional var characterNoteStyle:String;
	@:optional var characterPositionOffsets:Array<Float>;
	@:optional var cameraPosition:Array<Float>;
	@:optional var characterIcon:String;
	@:optional var characterHealthBarColor:Array<Int>;
	@:optional var characterSingDuration:Float;
	@:optional var characterScale:Float;
}

typedef AnimArray = {
	@:optional var name:String;
	@:optional var prefix:String;
	@:optional var anim:String;
	@:optional var assetPath:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	/** Offsets quando o personagem está no lado do player (BETADCIU-style) */
	@:optional var playerOffsets:Array<Float>;
	// New format aliases
	@:optional var Framerate:Int;
	@:optional var loopd:Bool;
}

/**
 * Pico Engine character — Psych API, V-Slice-inspired render pipeline.
 *
 * Base-game FNF splits this into SparrowCharacter / MultiSparrowCharacter /
 * PackerCharacter / AnimateAtlasCharacter / MultiAnimateAtlasCharacter + BaseCharacter.
 * Porting those as separate classes would break PlayState, editors and mods.
 * Instead this single class implements the same render types:
 *   sparrow | multisparrow | packer | animateatlas | multianimateatlas
 *
 * Gameplay API stays Psych-compatible: playAnim, dance, animationsArray, offsets, etc.
 */
class Character extends FlxSprite
{
	public static final DEFAULT_CHARACTER:String = 'bf-opponent';

	public var animOffsets:Map<String, Array<Dynamic>>;
	/** Offsets por animação quando isPlayer (BETADCIU playerOffsets) */
	public var animPlayerOffsets:Map<String, Array<Float>> = new Map();
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	public var editorCharacterType:String = null;
	public var gameOverChar:String = null;
	public var gameOverSound:String = null;
	public var gameOverLoop:String = null;
	public var gameOverEnd:String = null;
	public var noteStyle:String = null;
	public var renderType:String = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		animPlayerOffsets = new Map<String, Array<Float>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);
		
		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'data/characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('data/characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;
		// Normalize new Pico character JSON → Psych-compatible fields
		normalizeCharacterJson(json);

		var assetPath:String = getCharacterString(json, ['assetPath', 'image'], DEFAULT_CHARACTER);
		// Clean double slashes (e.g. characters/bf//Boyfriend)
		while(assetPath.indexOf('//') >= 0)
			assetPath = assetPath.replace('//', '/');

		var animsField:Dynamic = Reflect.field(json, 'animations');
		if(animsField == null) animsField = Reflect.field(json, 'character_animations_data');
		var animationAssetPaths:String = collectAnimationAssetPaths(assetPath, cast animsField);

		// renderType: sparrow | multisparrow | animateatlas (V-Slice / Psych-compatible)
		renderType = normalizeRenderType(getCharacterString(json, ['renderType'], null));
		if(renderType == null || renderType.length < 1)
			renderType = detectRenderType(assetPath, animationAssetPaths);

		scale.set(1, 1);
		updateHitbox();

		loadCharacterFrames(assetPath, animationAssetPaths, renderType);

		imageFile = assetPath;
		jsonScale = json.scale != null ? json.scale : 1;
		if(jsonScale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		// position: se isPlayer e tem player_position, usa ele (BETADCIU)
		if(isPlayer)
		{
			var playerPos = getCharacterFloatArray(json, ['player_position', 'playerposition'], null);
			if(playerPos != null)
				positionArray = playerPos;
			else
				positionArray = getCharacterFloatArray(json, ['positionOffsets', 'position', 'offsets'], [0, 0]);

			var playerCam = getCharacterFloatArray(json, ['player_camera_position'], null);
			if(playerCam != null)
				cameraPosition = playerCam;
			else
				cameraPosition = getCharacterFloatArray(json, ['cameraOffsets', 'camera_position'], [0, 0]);
		}
		else
		{
			positionArray = getCharacterFloatArray(json, ['positionOffsets', 'position', 'offsets'], [0, 0]);
			cameraPosition = getCharacterFloatArray(json, ['cameraOffsets', 'camera_position'], [0, 0]);
		}

		// data
		healthIcon = json.healthicon != null ? json.healthicon : 'face';
		singDuration = json.sing_duration != null ? json.sing_duration : 4;
		var jsonFlipX:Bool = json.flip_x == true;
		flipX = (jsonFlipX != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = jsonFlipX;
		editorCharacterType = getCharacterString(json, ['Type', 'characterType'], null);
		editorIsPlayer = characterTypeToIsPlayer(editorCharacterType);
		if(editorIsPlayer == null)
			editorIsPlayer = json._editor_isPlayer;
		gameOverChar = getCharacterString(json, ['gameOverChar'], null);
		gameOverSound = getCharacterString(json, ['gameOverSound'], null);
		gameOverLoop = getCharacterString(json, ['gameOverLoop'], null);
		gameOverEnd = getCharacterString(json, ['gameOverEnd'], null);
		// noteStyle only — enable/disable is Preferences.useCharacterNoteStyle (Gameplay Settings)
		noteStyle = getCharacterString(json, ['noteStyle'], null);
		if(noteStyle != null && noteStyle.trim().length < 1)
			noteStyle = null;
		// renderType already resolved in loadCharacterFrames above

		// Pixel characters keep antialiasing disabled.
		noAntialiasing = (json.isPixel == true || json.no_antialiasing == true);
		antialiasing = Preferences.data.antialiasing ? !noAntialiasing : false;

		// animations (renderType decides sparrow/packer/animate registration)
		animationsArray = cast Reflect.field(json, 'animations');
		if(animationsArray == null) animationsArray = [];
		applyCharacterAnimations(animationsArray, true);
		//trace('Loaded file to character ' + curCharacter);
	}


	/**
	 * Map new Pico character JSON fields onto Psych-compatible ones.
	 * New format uses character_animations_data, characterIcon, characterScale, etc.
	 */
	public static function normalizeCharacterJson(json:Dynamic):Void
	{
		if(json == null) return;

		// character_animations_data → animations
		var animsRaw:Dynamic = Reflect.field(json, 'animations');
		if(animsRaw == null) animsRaw = Reflect.field(json, 'character_animations_data');
		if(animsRaw != null && Std.isOfType(animsRaw, Array))
		{
			var out:Array<Dynamic> = [];
			for (entry in (cast animsRaw:Array<Dynamic>))
			{
				if(entry == null) continue;
				// Normalize each entry to anim/name/fps/loop/offsets/playerOffsets
				var animId:String = '';
				var prefix:String = '';
				if(Reflect.hasField(entry, 'anim') && Reflect.field(entry, 'anim') != null)
					animId = Std.string(Reflect.field(entry, 'anim'));
				else if(Reflect.hasField(entry, 'name'))
					animId = Std.string(Reflect.field(entry, 'name'));

				if(Reflect.hasField(entry, 'prefix') && Reflect.field(entry, 'prefix') != null)
					prefix = Std.string(Reflect.field(entry, 'prefix'));
				else if(Reflect.hasField(entry, 'name') && Reflect.hasField(entry, 'anim'))
					prefix = Std.string(Reflect.field(entry, 'name'));
				else
					prefix = animId;

				var fps:Int = 24;
				if(Reflect.hasField(entry, 'fps'))
				{
					var f = Std.parseFloat(Std.string(Reflect.field(entry, 'fps')));
					if(!Math.isNaN(f) && f > 0) fps = Std.int(f);
				}
				else if(Reflect.hasField(entry, 'Framerate'))
				{
					var f2 = Std.parseFloat(Std.string(Reflect.field(entry, 'Framerate')));
					if(!Math.isNaN(f2) && f2 > 0) fps = Std.int(f2);
				}

				var loop:Bool = false;
				if(Reflect.hasField(entry, 'loop'))
					loop = Reflect.field(entry, 'loop') == true;
				else if(Reflect.hasField(entry, 'loopd?'))
					loop = Reflect.field(entry, 'loopd?') == true;
				else if(Reflect.hasField(entry, 'loopd'))
					loop = Reflect.field(entry, 'loopd') == true;

				var off:Array<Int> = [0, 0];
				var offRaw:Dynamic = Reflect.field(entry, 'offsets');
				if(Std.isOfType(offRaw, Array))
				{
					var oa:Array<Dynamic> = cast offRaw;
					if(oa.length > 0) off[0] = Std.int(Std.parseFloat(Std.string(oa[0])));
					if(oa.length > 1) off[1] = Std.int(Std.parseFloat(Std.string(oa[1])));
				}

				var pOff:Array<Float> = null;
				var poRaw:Dynamic = Reflect.field(entry, 'playerOffsets');
				if(poRaw == null) poRaw = Reflect.field(entry, 'Offsets-Playable');
				if(Std.isOfType(poRaw, Array))
				{
					var pa:Array<Dynamic> = cast poRaw;
					var px:Float = pa.length > 0 ? Std.parseFloat(Std.string(pa[0])) : 0;
					var py:Float = pa.length > 1 ? Std.parseFloat(Std.string(pa[1])) : 0;
					if(Math.isNaN(px)) px = 0;
					if(Math.isNaN(py)) py = 0;
					pOff = [px, py];
				}

				var indices:Array<Int> = [];
				if(Reflect.hasField(entry, 'indices') && Std.isOfType(Reflect.field(entry, 'indices'), Array))
				{
					for (ix in (cast Reflect.field(entry, 'indices'):Array<Dynamic>))
						indices.push(Std.int(Std.parseFloat(Std.string(ix))));
				}

				var animAsset:String = '';
				if(Reflect.hasField(entry, 'assetPath') && Reflect.field(entry, 'assetPath') != null)
					animAsset = Std.string(Reflect.field(entry, 'assetPath'));

				var normalized:Dynamic = {
					anim: animId,
					name: prefix,
					prefix: prefix,
					fps: fps,
					loop: loop,
					offsets: off,
					indices: indices
				};
				if(pOff != null) Reflect.setField(normalized, 'playerOffsets', pOff);
				if(animAsset.length > 0) Reflect.setField(normalized, 'assetPath', animAsset);
				out.push(normalized);
			}
			Reflect.setField(json, 'animations', out);
		}

		// characterNoteStyle → noteStyle
		if(Reflect.field(json, 'noteStyle') == null && Reflect.hasField(json, 'characterNoteStyle'))
			Reflect.setField(json, 'noteStyle', Reflect.field(json, 'characterNoteStyle'));

		// characterPositionOffsets → positionOffsets
		if(Reflect.field(json, 'positionOffsets') == null && Reflect.hasField(json, 'characterPositionOffsets'))
			Reflect.setField(json, 'positionOffsets', Reflect.field(json, 'characterPositionOffsets'));

		// cameraPosition (new) → cameraOffsets (also keep camera_position)
		if(Reflect.field(json, 'cameraOffsets') == null)
		{
			if(Reflect.hasField(json, 'cameraPosition'))
				Reflect.setField(json, 'cameraOffsets', Reflect.field(json, 'cameraPosition'));
			else if(Reflect.hasField(json, 'camera_position'))
				Reflect.setField(json, 'cameraOffsets', Reflect.field(json, 'camera_position'));
		}

		// characterIcon → healthicon
		if(Reflect.field(json, 'healthicon') == null && Reflect.hasField(json, 'characterIcon'))
			Reflect.setField(json, 'healthicon', Reflect.field(json, 'characterIcon'));

		// characterHealthBarColor → healthbar_colors
		if(Reflect.field(json, 'healthbar_colors') == null && Reflect.hasField(json, 'characterHealthBarColor'))
			Reflect.setField(json, 'healthbar_colors', Reflect.field(json, 'characterHealthBarColor'));

		// characterSingDuration → sing_duration
		if(Reflect.field(json, 'sing_duration') == null && Reflect.hasField(json, 'characterSingDuration'))
			Reflect.setField(json, 'sing_duration', Reflect.field(json, 'characterSingDuration'));

		// characterScale → scale
		if(Reflect.field(json, 'scale') == null && Reflect.hasField(json, 'characterScale'))
			Reflect.setField(json, 'scale', Reflect.field(json, 'characterScale'));

		// Type "BF" / "Player" etc.
		if(Reflect.hasField(json, 'Type') && Reflect.field(json, 'characterType') == null)
			Reflect.setField(json, 'characterType', Reflect.field(json, 'Type'));

		// assetPath cleanup
		if(Reflect.hasField(json, 'assetPath'))
		{
			var ap = Std.string(Reflect.field(json, 'assetPath')).trim().replace('\\\\', '/');
			while(ap.indexOf('//') >= 0) ap = ap.replace('//', '/');
			Reflect.setField(json, 'assetPath', ap);
		}
	}

	static function normalizeAnimationData(anim:AnimArray):Void
	{
		var hasLegacyAnim:Bool = Reflect.hasField(anim, 'anim') && Reflect.field(anim, 'anim') != null;
		var animName:String = hasLegacyAnim ? getAnimString(anim, ['anim'], '') : getAnimString(anim, ['name'], '');
		var animPrefix:String = getAnimString(anim, ['prefix'], null);
		if(animPrefix == null || animPrefix.length < 1)
			animPrefix = hasLegacyAnim ? getAnimString(anim, ['name'], '') : animName;

		anim.anim = animName;
		anim.name = animPrefix;
		if(anim.indices == null) anim.indices = [];
		if(anim.offsets == null) anim.offsets = [0, 0];

		// New format: Framerate → fps
		if(Reflect.hasField(anim, 'Framerate'))
		{
			var fr = Std.parseFloat(Std.string(Reflect.field(anim, 'Framerate')));
			if(!Math.isNaN(fr) && fr > 0) anim.fps = Std.int(fr);
		}
		if(anim.fps <= 0) anim.fps = 24;

		// New format: "loopd?" or loopd → loop
		if(Reflect.hasField(anim, 'loopd?'))
			anim.loop = Reflect.field(anim, 'loopd?') == true;
		else if(Reflect.hasField(anim, 'loopd'))
			anim.loop = Reflect.field(anim, 'loopd') == true;

		// New format: Offsets-Playable → playerOffsets
		if((anim.playerOffsets == null || anim.playerOffsets.length < 2) && Reflect.hasField(anim, 'Offsets-Playable'))
		{
			var po:Dynamic = Reflect.field(anim, 'Offsets-Playable');
			if(Std.isOfType(po, Array))
			{
				var arr:Array<Dynamic> = cast po;
				var x:Float = arr.length > 0 ? Std.parseFloat(Std.string(arr[0])) : 0;
				var y:Float = arr.length > 1 ? Std.parseFloat(Std.string(arr[1])) : 0;
				if(Math.isNaN(x)) x = 0;
				if(Math.isNaN(y)) y = 0;
				anim.playerOffsets = [x, y];
			}
		}
	}

	static function getAnimString(anim:Dynamic, names:Array<String>, fallback:String):String
	{
		for(name in names)
		{
			var value:Dynamic = Reflect.field(anim, name);
			if(value != null)
			{
				var text:String = Std.string(value);
				if(text.length > 0)
					return text;
			}
		}
		return fallback;
	}

	static function getCharacterString(json:Dynamic, names:Array<String>, fallback:String):String
	{
		for(name in names)
		{
			var value:Dynamic = Reflect.field(json, name);
			if(value != null)
			{
				var text:String = Std.string(value).trim();
				if(text.length > 0)
					return text;
			}
		}
		return fallback;
	}

	static function getCharacterFloatArray(json:Dynamic, names:Array<String>, fallback:Array<Float>):Array<Float>
	{
		for(name in names)
		{
			var value:Dynamic = Reflect.field(json, name);
			if(value == null) continue;

			var values:Array<Float> = [];
			if(Std.isOfType(value, Array))
			{
				var raw:Array<Dynamic> = cast value;
				for(item in raw)
				{
					var parsed:Float = Std.parseFloat(Std.string(item));
					if(!Math.isNaN(parsed)) values.push(parsed);
				}
			}
			if(values.length > 0)
			{
				while(values.length < 2)
					values.push(0);
				return values;
			}
		}
		if(fallback == null) return null;
		return fallback.copy();
	}

	static function characterTypeToIsPlayer(type:String):Null<Bool>
	{
		if(type == null) return null;
		var clean:String = type.trim().toLowerCase();
		if(clean == 'player' || clean == 'boyfriend' || clean == 'bf') return true;
		if(clean == 'opponent' || clean == 'dad') return false;
		return null;
	}


	/**
	 * Render types aligned with base-game FNF / V-Slice, loaded through one Psych-compatible Character.
	 * sparrow              → single XML atlas (SparrowCharacter)
	 * multisparrow         → multiple XML atlases concatenated (MultiSparrowCharacter)
	 * packer               → single TXT packer atlas (PackerCharacter)
	 * animateatlas         → single Adobe Animate texture atlas (AnimateAtlasCharacter)
	 * multianimateatlas    → multiple Animate atlases / mix with sparrow (MultiAnimateAtlasCharacter)
	 */
	public static final RENDER_SPARROW:String = 'sparrow';
	public static final RENDER_MULTISPARROW:String = 'multisparrow';
	public static final RENDER_PACKER:String = 'packer';
	public static final RENDER_ANIMATE:String = 'animateatlas';
	public static final RENDER_MULTIANIMATE:String = 'multianimateatlas';

	public static function getSupportedRenderTypes():Array<String>
	{
		#if flxanimate
		return [RENDER_SPARROW, RENDER_MULTISPARROW, RENDER_PACKER, RENDER_ANIMATE, RENDER_MULTIANIMATE];
		#else
		return [RENDER_SPARROW, RENDER_MULTISPARROW, RENDER_PACKER];
		#end
	}

	public static function normalizeRenderType(value:String):String
	{
		if(value == null) return '';
		var clean:String = value.trim().toLowerCase().replace(' ', '').replace('_', '').replace('-', '');
		if(clean.length < 1) return '';

		switch(clean)
		{
			case 'sparrow', 'sparrowatlas', 'spritesheet', 'xml':
				return RENDER_SPARROW;
			case 'multisparrow', 'multi', 'multiatlas', 'multiplesparrow':
				return RENDER_MULTISPARROW;
			case 'packer', 'packeratlas', 'libgdx', 'texturepacker':
				return RENDER_PACKER;
			case 'animateatlas', 'animate', 'atlas', 'textureatlas', 'flxanimate', 'adobeanimate':
				return RENDER_ANIMATE;
			case 'multianimateatlas', 'multianimate', 'multiatlasanimate', 'multiplesanimate':
				return RENDER_MULTIANIMATE;
			default:
				return '';
		}
	}

	/**
	 * Auto-detect when renderType is missing.
	 * Priority: animateatlas folder → multiple paths → packer → sparrow.
	 */
	public static function detectRenderType(assetPath:String, animationAssetPaths:String):String
	{
		var primary:String = assetPath != null ? assetPath.trim() : '';
		var paths:String = animationAssetPaths != null ? animationAssetPaths : assetPath;
		var multiPaths:Bool = paths != null && paths.indexOf(',') >= 0;

		#if flxanimate
		var primaryIsAnimate:Bool = false;
		if(primary.length > 0)
		{
			var animToFind:String = Paths.getPath('images/' + primary + '/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				primaryIsAnimate = true;
			#if (sys || MODS_ALLOWED)
			try
			{
				if(Reflect.hasField(Paths, 'hasAnimateAtlas') && Reflect.callMethod(Paths, Reflect.field(Paths, 'hasAnimateAtlas'), [primary]) == true)
					primaryIsAnimate = true;
			}
			catch(e:Dynamic) {}
			#end
		}

		// Multiple paths + any animate folder → multianimateatlas
		if(multiPaths)
		{
			for (part in paths.split(','))
			{
				var p:String = part.trim();
				if(p.length < 1) continue;
				var animCheck:String = Paths.getPath('images/' + p + '/Animation.json', TEXT);
				if (#if MODS_ALLOWED FileSystem.exists(animCheck) || #end Assets.exists(animCheck))
					return RENDER_MULTIANIMATE;
			}
			if(primaryIsAnimate)
				return RENDER_MULTIANIMATE;
			return RENDER_MULTISPARROW;
		}

		if(primaryIsAnimate)
			return RENDER_ANIMATE;
		#end

		if(multiPaths)
			return RENDER_MULTISPARROW;

		if(primary.length > 0)
		{
			try
			{
				var packerTxt:String = Paths.getPath('images/' + primary + '.txt', TEXT);
				if (#if MODS_ALLOWED FileSystem.exists(packerTxt) || #end Assets.exists(packerTxt))
					return RENDER_PACKER;
			}
			catch(e:Dynamic) {}
		}

		return RENDER_SPARROW;
	}

	/** Runtime/editor: change type, reload frames, re-bind animations. */
	public function setRenderType(type:String, reapplyAnims:Bool = true):Void
	{
		var lastAnim:String = getAnimationName();
		var resolved:String = normalizeRenderType(type);
		if(resolved.length < 1)
			resolved = detectRenderType(imageFile, collectAnimationAssetPaths(imageFile, animationsArray));

		#if flxanimate
		atlas = FlxDestroyUtil.destroy(atlas);
		#end
		isAnimateAtlas = false;

		var multi:String = collectAnimationAssetPaths(imageFile, animationsArray);
		loadCharacterFrames(imageFile, multi, resolved);

		if(reapplyAnims)
			applyCharacterAnimations(animationsArray, false);

		if(lastAnim != null && lastAnim.length > 0 && hasAnimation(lastAnim))
			playAnim(lastAnim, true);
		else
			dance();
	}

	/**
	 * Register animations according to current renderType / isAnimateAtlas.
	 * clearOffsets=true resets maps (full character load).
	 */
	public function applyCharacterAnimations(?anims:Array<AnimArray>, clearOffsets:Bool = false):Void
	{
		if(clearOffsets)
		{
			animOffsets = new Map<String, Array<Dynamic>>();
			animPlayerOffsets = new Map<String, Array<Float>>();
		}

		if(anims == null)
			anims = animationsArray;
		if(anims == null || anims.length < 1)
		{
			#if flxanimate
			if(isAnimateAtlas) copyAtlasValues();
			#end
			return;
		}

		if(!isAnimateAtlas && animation != null)
		{
			try { animation.destroyAnimations(); } catch(e:Dynamic) {}
		}

		for (anim in anims)
		{
			if(anim == null) continue;
			normalizeAnimationData(anim);
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop;
			var animIndices:Array<Int> = anim.indices;
			if(animAnim == null || animAnim.length < 1 || animName == null || animName.length < 1)
				continue;

			try
			{
				if(!isAnimateAtlas)
				{
					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else if(atlas != null && atlas.anim != null)
				{
					if(animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Character ' + curCharacter + ': failed anim "' + animAnim + '": ' + e);
			}

			var baseOffX:Float = 0;
			var baseOffY:Float = 0;
			if(anim.offsets != null && anim.offsets.length > 1)
			{
				baseOffX = anim.offsets[0];
				baseOffY = anim.offsets[1];
			}

			var pOff:Array<Float> = null;
			if(Reflect.hasField(anim, 'playerOffsets') && anim.playerOffsets != null && anim.playerOffsets.length > 1)
				pOff = [anim.playerOffsets[0], anim.playerOffsets[1]];

			if(isPlayer && pOff != null)
				addOffset(anim.anim, pOff[0], pOff[1]);
			else
				addOffset(anim.anim, baseOffX, baseOffY);

			if(pOff != null)
				addPlayerOffset(anim.anim, pOff[0], pOff[1]);
			else
				addPlayerOffset(anim.anim, baseOffX, baseOffY);
		}

		#if flxanimate
		if(isAnimateAtlas) copyAtlasValues();
		#end
	}

	/**
	 * Loads frames from renderType.
	 * sparrow / multisparrow / packer / animateatlas
	 */
	/**
	 * Loads frames by renderType (V-Slice style, single Character class for Psych).
	 * - sparrow / multisparrow → Paths.getSparrowAtlas / getMultiAtlas
	 * - packer → Paths.getPackerAtlas
	 * - animateatlas → Paths.loadAnimateAtlas (FlxAnimate)
	 * - multianimateatlas → primary Animate atlas (extra sparrow paths stay available via anim.assetPath on anims)
	 */
	public function loadCharacterFrames(assetPath:String, animationAssetPaths:String, type:String):Void
	{
		isAnimateAtlas = false;
		var resolved:String = normalizeRenderType(type);
		if(resolved.length < 1)
			resolved = detectRenderType(assetPath, animationAssetPaths);
		renderType = resolved;

		var primary:String = assetPath != null ? assetPath.trim() : '';
		var multiSrc:String = (animationAssetPaths != null && animationAssetPaths.trim().length > 0)
			? animationAssetPaths
			: primary;

		switch(resolved)
		{
			#if flxanimate
			case RENDER_ANIMATE | RENDER_MULTIANIMATE:
				atlas = FlxDestroyUtil.destroy(atlas);
				atlas = new FlxAnimate();
				atlas.showPivot = false;
				try
				{
					// Primary Animate atlas (V-Slice AnimateAtlas / MultiAnimate primary)
					Paths.loadAnimateAtlas(atlas, primary);
					isAnimateAtlas = true;
					renderType = resolved;
				}
				catch(e:Dynamic)
				{
					FlxG.log.warn('Could not load animateatlas $primary: $e — falling back');
					isAnimateAtlas = false;
					renderType = (multiSrc.indexOf(',') >= 0) ? RENDER_MULTISPARROW : RENDER_SPARROW;
					loadSparrowOrMulti(multiSrc);
				}

			#end
			case RENDER_PACKER:
				try
				{
					var packFrames = Paths.getPackerAtlas(primary);
					if(packFrames != null)
						frames = packFrames;
					else
					{
						FlxG.log.warn('Packer atlas missing for $primary — falling back to sparrow');
						renderType = RENDER_SPARROW;
						loadSparrowOrMulti(multiSrc);
					}
				}
				catch(e:Dynamic)
				{
					FlxG.log.warn('Packer load failed $primary: $e');
					renderType = RENDER_SPARROW;
					loadSparrowOrMulti(multiSrc);
				}

			case RENDER_MULTISPARROW:
				// Concatenate multiple sparrow sheets (like V-Slice MultiSparrowCharacter)
				loadSparrowOrMulti(multiSrc);
				renderType = RENDER_MULTISPARROW;

			default: // sparrow
				loadSparrowOrMulti(multiSrc);
				if(multiSrc != null && multiSrc.indexOf(',') >= 0)
					renderType = RENDER_MULTISPARROW;
				else
					renderType = RENDER_SPARROW;
		}
	}

	/**
	 * Sparrow / MultiSparrow load.
	 * Splits comma paths, trims empties, prefers Paths.getMultiAtlas when available.
	 */
	function loadSparrowOrMulti(pathList:String):Void
	{
		isAnimateAtlas = false;
		var list:String = pathList != null ? pathList : '';
		try
		{
			if(list.indexOf(',') >= 0)
			{
				var parts:Array<String> = [];
				for (p in list.split(','))
				{
					var c:String = p.trim();
					if(c.length > 0 && !parts.contains(c))
						parts.push(c);
				}
				if(parts.length > 1)
					frames = Paths.getMultiAtlas(parts);
				else if(parts.length == 1)
				{
					var single = Paths.getSparrowAtlas(parts[0]);
					frames = single != null ? single : Paths.getMultiAtlas(parts);
				}
			}
			else if(list.length > 0)
			{
				var single = Paths.getSparrowAtlas(list);
				if(single != null)
					frames = single;
				else
					frames = Paths.getMultiAtlas([list]);
			}
		}
		catch(e:Dynamic)
		{
			FlxG.log.warn('Sparrow/multi load failed ($list): $e');
		}
	}

	public static function collectAnimationAssetPaths(defaultAssetPath:String, animations:Array<AnimArray>):String
	{
		var paths:Array<String> = [];
		addCharacterAssetPath(paths, defaultAssetPath);
		if(animations != null)
		{
			for(anim in animations)
				addAnimationAssetPaths(paths, anim.assetPath);
		}
		return paths.join(',');
	}

	public static function getAnimationAssetPathInput(path:String):String
	{
		if(path == null) return '';

		var paths:Array<String> = [];
		for(part in path.split(','))
		{
			var clean:String = getSingleAnimationAssetPathInput(part);
			if(clean.length > 0)
				paths.push(clean);
		}
		return paths.join(',');
	}

	static function getSingleAnimationAssetPathInput(path:String):String
	{
		var clean:String = path != null ? path.trim() : '';
		if(clean.startsWith('images/characters/'))
			return clean.substr('images/characters/'.length);
		if(clean.startsWith('characters/'))
			return clean.substr('characters/'.length);
		return clean;
	}

	public static function resolveAnimationAssetPath(path:String):String
	{
		var clean:String = getAnimationAssetPathInput(path);
		if(clean.length < 1) return '';

		var characterPath:String = 'characters/$clean';
		if(Paths.image(characterPath) != null)
			return characterPath;
		return clean;
	}

	static function addAnimationAssetPaths(paths:Array<String>, path:String):Void
	{
		if(path == null) return;
		for(part in path.split(','))
			addCharacterAssetPath(paths, resolveAnimationAssetPath(part));
	}

	static function addCharacterAssetPath(paths:Array<String>, path:String):Void
	{
		if(path == null) return;
		for(part in path.split(','))
		{
			var clean:String = part.trim();
			if(clean.length > 0 && !paths.contains(clean))
				paths.push(clean);
		}
	}

	override function update(elapsed:Float)
	{
		if(isAnimateAtlas) atlas.update(elapsed);

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null)))
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.pauseAnimation();
			else atlas.resumeAnimation();
		}

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(hasAnimation('idle' + idleSuffix))
				playAnim('idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if(!isAnimateAtlas)
		{
			animation.play(AnimName, Force, Reversed, Frame);
		}
		else
		{
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.update(0);
		}
		_lastPlayedAnimation = AnimName;

		if (hasAnimation(AnimName))
		{
			var daOffset:Array<Dynamic> = null;
			// BETADCIU: se for player e tiver playerOffsets, usa eles
			if(isPlayer && animPlayerOffsets.exists(AnimName))
				daOffset = animPlayerOffsets.get(AnimName);
			else
				daOffset = animOffsets.get(AnimName);

			if(daOffset != null && daOffset.length > 1)
				offset.set(daOffset[0], daOffset[1]);
		}

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;

			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animPlayerOffsets.set(name, [x, y]);
	}

	public function getAnimPlayerOffset(name:String):Array<Float>
	{
		if(animPlayerOffsets.exists(name))
			return animPlayerOffsets.get(name);
		return [0, 0];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if(isAnimateAtlas)
		{
			if(atlas.anim.curInstance != null)
			{
				copyAtlasValues();
				atlas.draw();
				alpha = lastAlpha;
				color = lastColor;
				if(missingCharacter && visible)
				{
					missingText.x = getMidpoint().x - 150;
					missingText.y = getMidpoint().y - 10;
					missingText.draw();
				}
			}
			return;
		}
		super.draw();
		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy()
	{
		atlas = FlxDestroyUtil.destroy(atlas);
		super.destroy();
	}
	#end
}