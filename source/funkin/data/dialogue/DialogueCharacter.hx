package funkin.data.dialogue;

import haxe.Json;
import lime.utils.Assets;

typedef DialogueAnimArray = {
	var anim:String;
	var loop_name:String;
	var loop_offsets:Array<Int>;
	var idle_name:String;
	var idle_offsets:Array<Int>;
	@:optional var fps:Int;
	@:optional var loop:Bool;
}

typedef DialogueCharacterFile = {
	var image:String;
	var dialogue_pos:String;
	var no_antialiasing:Bool;

	var animations:Array<DialogueAnimArray>;
	var position:Array<Float>;
	var scale:Float;

	/** New format fields (optional / normalized into the fields above) */
	@:optional var assetPath:String;
	@:optional var dialogueOffsets:Array<Float>;
	@:optional var dialogueType:String;
	@:optional var flip_x:Bool;
	@:optional var dialogue_animations:Array<Dynamic>;
}

class DialogueCharacter extends FlxSprite
{
	private static var IDLE_POSTFIX:String = '-IDLE';
	public static var DEFAULT_CHARACTER:String = 'bf';
	public static var DEFAULT_SCALE:Float = 0.7;

	public var jsonFile:DialogueCharacterFile = null;
	public var dialogueAnimations:Map<String, DialogueAnimArray> = new Map<String, DialogueAnimArray>();

	public var startingPos:Float = 0; // For center characters, starting Y; otherwise starting X
	public var isGhost:Bool = false; // For the editor
	public var curCharacter:String = 'bf';
	public var skipTimer = 0;
	public var skipping = 0;
	public var flipXFromJson:Bool = false;

	public function new(x:Float = 0, y:Float = 0, character:String = null)
	{
		if(character == null) character = DEFAULT_CHARACTER;
		this.curCharacter = character;

		reloadCharacterJson(character);
		if(jsonFile == null) jsonFile = defaultDialogueCharacterFile(character);

		loadDialogueFrames();
		reloadAnimations();

		antialiasing = Preferences.data.antialiasing;
		if(jsonFile.no_antialiasing == true) antialiasing = false;

		if(flipXFromJson)
			flipX = true;

		super(x, y);
	}

	/** Resolve sprite frames from assetPath / image via Paths (supports mods). */
	public function loadDialogueFrames():Void
	{
		var img:String = resolveImagePath();
		try
		{
			// Prefer sparrow atlas (animated dialogue portraits)
			frames = Paths.getSparrowAtlas(img);
		}
		catch(e:Dynamic)
		{
			try
			{
				// Fallback: plain image
				loadGraphic(Paths.image(img));
			}
			catch(e2:Dynamic)
			{
				try
				{
					frames = Paths.getSparrowAtlas('dialogue/characters/' + DEFAULT_CHARACTER);
				}
				catch(e3:Dynamic)
				{
					try { loadGraphic(Paths.image('dialogue/characters/' + DEFAULT_CHARACTER)); }
					catch(e4:Dynamic) {}
				}
			}
		}
	}

	function resolveImagePath():String
	{
		if(jsonFile == null) return 'dialogue/characters/' + DEFAULT_CHARACTER;

		// New format: assetPath (e.g. "dialogue/characters/bf_dialogue")
		if(jsonFile.assetPath != null)
		{
			var ap:String = Std.string(jsonFile.assetPath).trim().replace('\\', '/');
			if(ap.length > 0)
			{
				if(ap.startsWith('images/')) ap = ap.substr(7);
				if(ap.endsWith('.png') || ap.endsWith('.xml'))
					ap = ap.substr(0, ap.lastIndexOf('.'));
				return ap;
			}
		}

		// Legacy: image field
		if(jsonFile.image != null)
		{
			var img:String = Std.string(jsonFile.image).trim().replace('\\', '/');
			if(img.length > 0)
			{
				if(img.startsWith('images/')) img = img.substr(7);
				if(img.startsWith('dialogue/')) return img;
				// Old relative names lived under dialogue/
				return 'dialogue/' + img;
			}
		}

		return 'dialogue/characters/' + (curCharacter != null ? curCharacter : DEFAULT_CHARACTER);
	}

	/**
	 * JSON lives in data/dialogue/<name>.json (new).
	 * Falls back to legacy images/dialogue/characters/<name>.json.
	 */
	public function reloadCharacterJson(character:String):Void
	{
		var candidates:Array<String> = [
			'data/dialogue/' + character + '.json',
			'dialogue/' + character + '.json',
			// Legacy Psych path
			'images/dialogue/characters/' + character + '.json'
		];

		// Default character fallbacks
		candidates.push('data/dialogue/' + DEFAULT_CHARACTER + '.json');
		candidates.push('images/dialogue/characters/' + DEFAULT_CHARACTER + '.json');

		var rawJson:String = null;
		for (characterPath in candidates)
		{
			rawJson = tryLoadText(characterPath);
			if(rawJson != null && rawJson.trim().length > 0) break;
		}

		if(rawJson == null || rawJson.trim().length < 1)
		{
			jsonFile = defaultDialogueCharacterFile(character);
			return;
		}

		var parsed:Dynamic = null;
		try { parsed = Json.parse(rawJson); }
		catch(e:Dynamic) { parsed = null; }

		if(parsed == null)
		{
			jsonFile = defaultDialogueCharacterFile(character);
			return;
		}

		jsonFile = normalizeDialogueCharacterFile(parsed, character);
	}

	/** Normalize new + legacy dialogue character JSON into DialogueCharacterFile. */
	function normalizeDialogueCharacterFile(raw:Dynamic, character:String):DialogueCharacterFile
	{
		var out:DialogueCharacterFile = defaultDialogueCharacterFile(character);

		// --- image / assetPath ---
		var assetPath:Dynamic = Reflect.field(raw, 'assetPath');
		if(assetPath == null) assetPath = Reflect.field(raw, 'asset_path');
		if(assetPath != null)
		{
			out.assetPath = Std.string(assetPath);
			out.image = out.assetPath;
		}
		else
		{
			var image:Dynamic = Reflect.field(raw, 'image');
			if(image != null) out.image = Std.string(image);
		}

		// --- position / dialogueOffsets ---
		var offsets:Dynamic = Reflect.field(raw, 'dialogueOffsets');
		if(offsets == null) offsets = Reflect.field(raw, 'dialogue_offsets');
		if(offsets == null) offsets = Reflect.field(raw, 'position');
		out.position = parseFloatPair(offsets, [0, 0]);
		out.dialogueOffsets = out.position;

		// --- dialogue_pos / dialogueType ---
		var dtype:Dynamic = Reflect.field(raw, 'dialogueType');
		if(dtype == null) dtype = Reflect.field(raw, 'dialogue_type');
		if(dtype == null) dtype = Reflect.field(raw, 'dialogue_pos');
		if(dtype != null)
		{
			var pos:String = Std.string(dtype).toLowerCase().trim();
			// New format uses left/right/center; keep as-is
			out.dialogue_pos = pos;
			out.dialogueType = pos;
		}

		// --- scale ---
		var sc:Dynamic = Reflect.field(raw, 'scale');
		if(sc != null)
		{
			var parsedScale = Std.parseFloat(Std.string(sc));
			if(!Math.isNaN(parsedScale) && parsedScale > 0) out.scale = parsedScale;
		}

		// --- antialiasing ---
		if(Reflect.hasField(raw, 'no_antialiasing'))
			out.no_antialiasing = Reflect.field(raw, 'no_antialiasing') == true;
		else if(Reflect.hasField(raw, 'antialiasing'))
			out.no_antialiasing = Reflect.field(raw, 'antialiasing') == false;

		// --- flip_x ---
		var flip:Dynamic = Reflect.field(raw, 'flip_x');
		if(flip == null) flip = Reflect.field(raw, 'flipX');
		out.flip_x = (flip == true);
		flipXFromJson = out.flip_x == true;

		// --- animations (new dialogue_animations or legacy animations) ---
		var animsRaw:Dynamic = Reflect.field(raw, 'dialogue_animations');
		if(animsRaw == null) animsRaw = Reflect.field(raw, 'animations');
		out.animations = normalizeAnimations(animsRaw);
		out.dialogue_animations = cast out.animations;

		return out;
	}

	function normalizeAnimations(raw:Dynamic):Array<DialogueAnimArray>
	{
		var result:Array<DialogueAnimArray> = [];
		if(raw == null || !Std.isOfType(raw, Array)) return result;

		var arr:Array<Dynamic> = cast raw;
		for (entry in arr)
		{
			if(entry == null) continue;

			// New format: name, prefix, offsets, fps, loop
			var name:String = fieldString(entry, ['name', 'anim', 'id'], '');
			var prefix:String = fieldString(entry, ['prefix', 'loop_name', 'anim'], name);
			var idlePrefix:String = fieldString(entry, ['idle_name', 'idle', 'idlePrefix'], prefix);
			var fps:Int = Std.int(fieldFloat(entry, ['fps', 'framerate', 'frameRate'], 24));
			var loop:Bool = fieldBool(entry, ['loop', 'looped'], true);

			var offsets = parseIntPair(Reflect.field(entry, 'offsets'), [0, 0]);
			// Legacy separate loop/idle offsets
			var loopOff = parseIntPair(Reflect.field(entry, 'loop_offsets'), offsets);
			var idleOff = parseIntPair(Reflect.field(entry, 'idle_offsets'), offsets);

			if(name.length < 1) name = prefix.length > 0 ? prefix : 'talk';

			var anim:DialogueAnimArray = {
				anim: name,
				loop_name: prefix,
				loop_offsets: loopOff,
				idle_name: idlePrefix,
				idle_offsets: idleOff,
				fps: fps,
				loop: loop
			};
			result.push(anim);
		}
		return result;
	}

	public function reloadAnimations():Void
	{
		dialogueAnimations.clear();
		if(jsonFile == null || jsonFile.animations == null || jsonFile.animations.length < 1)
			return;

		for (anim in jsonFile.animations)
		{
			if(anim == null) continue;
			var fps:Int = 24;
			if(Reflect.hasField(anim, 'fps'))
			{
				var pf = Std.parseFloat(Std.string(Reflect.field(anim, 'fps')));
				if(!Math.isNaN(pf) && pf > 0) fps = Std.int(pf);
			}
			var looped:Bool = isGhost || (Reflect.hasField(anim, 'loop') ? Reflect.field(anim, 'loop') == true : true);

			if(anim.loop_name != null && anim.loop_name.length > 0)
				animation.addByPrefix(anim.anim, anim.loop_name, fps, looped);

			var idleName:String = (anim.idle_name != null && anim.idle_name.length > 0) ? anim.idle_name : anim.loop_name;
			if(idleName != null && idleName.length > 0)
				animation.addByPrefix(anim.anim + IDLE_POSTFIX, idleName, fps, true);

			dialogueAnimations.set(anim.anim, anim);
		}
	}

	public function playAnim(animName:String = null, playIdle:Bool = false):Void
	{
		var leAnim:String = animName;
		if(animName == null || !dialogueAnimations.exists(animName))
		{
			var arrayAnims:Array<String> = [];
			for (anim in dialogueAnimations)
				arrayAnims.push(anim.anim);
			if(arrayAnims.length > 0)
				leAnim = arrayAnims[FlxG.random.int(0, arrayAnims.length - 1)];
		}

		if(dialogueAnimations.exists(leAnim))
		{
			var data = dialogueAnimations.get(leAnim);
			if(data.loop_name == null || data.loop_name.length < 1 || data.loop_name == data.idle_name)
				playIdle = true;
		}

		if(leAnim != null && leAnim.length > 0)
			animation.play(playIdle ? leAnim + IDLE_POSTFIX : leAnim, false);

		if(dialogueAnimations.exists(leAnim))
		{
			var anim:DialogueAnimArray = dialogueAnimations.get(leAnim);
			if(playIdle)
				offset.set(anim.idle_offsets[0], anim.idle_offsets[1]);
			else
				offset.set(anim.loop_offsets[0], anim.loop_offsets[1]);
		}
		else
		{
			offset.set(0, 0);
			trace('Offsets not found! Dialogue character is badly formatted, anim: ' + leAnim + ', ' + (playIdle ? 'idle anim' : 'loop anim'));
		}
	}

	public function animationIsLoop():Bool
	{
		if(animation.curAnim == null) return false;
		return !animation.curAnim.name.endsWith(IDLE_POSTFIX);
	}

	// ---------- helpers ----------

	static function tryLoadText(relativePath:String):String
	{
		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders(relativePath);
		if(FileSystem.exists(modPath) && !FileSystem.isDirectory(modPath))
		{
			try { return File.getContent(modPath); } catch(e:Dynamic) {}
		}
		#end

		var shared:String = Paths.getSharedPath(relativePath);
		#if MODS_ALLOWED
		if(FileSystem.exists(shared) && !FileSystem.isDirectory(shared))
		{
			try { return File.getContent(shared); } catch(e:Dynamic) {}
		}
		#end

		try
		{
			#if MODS_ALLOWED
			if(Assets.exists(shared)) return Assets.getText(shared);
			#else
			return Assets.getText(shared);
			#end
		}
		catch(e:Dynamic) {}

		// Paths-style open without images/ prefix variants already covered above
		return null;
	}

	static function defaultDialogueCharacterFile(character:String):DialogueCharacterFile
	{
		return {
			image: character != null ? character : DEFAULT_CHARACTER,
			assetPath: 'dialogue/characters/' + (character != null ? character : DEFAULT_CHARACTER),
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
	}

	static function fieldString(data:Dynamic, names:Array<String>, fallback:String):String
	{
		if(data == null) return fallback;
		for (n in names)
		{
			var v:Dynamic = Reflect.field(data, n);
			if(v != null)
			{
				var s = Std.string(v).trim();
				if(s.length > 0) return s;
			}
		}
		return fallback;
	}

	static function fieldFloat(data:Dynamic, names:Array<String>, fallback:Float):Float
	{
		if(data == null) return fallback;
		for (n in names)
		{
			var v:Dynamic = Reflect.field(data, n);
			if(v == null) continue;
			var p = Std.parseFloat(Std.string(v));
			if(!Math.isNaN(p)) return p;
		}
		return fallback;
	}

	static function fieldBool(data:Dynamic, names:Array<String>, fallback:Bool):Bool
	{
		if(data == null) return fallback;
		for (n in names)
		{
			var v:Dynamic = Reflect.field(data, n);
			if(v == null) continue;
			if(Std.isOfType(v, Bool)) return cast v;
			var s = Std.string(v).toLowerCase().trim();
			if(s == 'true' || s == '1' || s == 'yes') return true;
			if(s == 'false' || s == '0' || s == 'no') return false;
		}
		return fallback;
	}

	static function parseFloatPair(value:Dynamic, fallback:Array<Float>):Array<Float>
	{
		if(value == null) return fallback.copy();
		if(Std.isOfType(value, Array))
		{
			var arr:Array<Dynamic> = cast value;
			var x = arr.length > 0 ? Std.parseFloat(Std.string(arr[0])) : fallback[0];
			var y = arr.length > 1 ? Std.parseFloat(Std.string(arr[1])) : fallback[1];
			if(Math.isNaN(x)) x = fallback[0];
			if(Math.isNaN(y)) y = fallback[1];
			return [x, y];
		}
		return fallback.copy();
	}

	static function parseIntPair(value:Dynamic, fallback:Array<Int>):Array<Int>
	{
		var f = parseFloatPair(value, [fallback[0], fallback[1]]);
		return [Std.int(f[0]), Std.int(f[1])];
	}
}
