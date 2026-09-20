package funkin.data.objects.story;

import haxe.Json;
import openfl.utils.Assets;

typedef MenuCharacterAnim =
{
	var name:String;
	var prefix:String;
	@:optional var offsets:Array<Float>;
}

/**
 * New menu-character format (Story Mode props).
 * Legacy fields (idle_anim, confirm_anim, image, scale, position, flipX, antialiasing)
 * are still accepted and converted on load.
 */
typedef MenuCharacterFile =
{
	var animations:Array<MenuCharacterAnim>;
	var propScale:Float;
	var propPosition:Array<Float>;
	var propPath:String;
	var prop_disabled_Antialiasing:Bool;
	/** When true, idle alternates danceLeft / danceRight (GF-style). */
	var useAlternative:Bool;

	/** Sprite file name (no extension), resolved under propPath. */
	@:optional var propImage:String;
	/** Alias of propImage for older saves / editor convenience. */
	@:optional var image:String;
	@:optional var flipX:Bool;

	// ---- legacy (auto-migrated) ----
	@:optional var position:Array<Float>;
	@:optional var scale:Float;
	@:optional var idle_anim:String;
	@:optional var confirm_anim:String;
	@:optional var antialiasing:Bool;
	@:optional var use_alternatives:Bool;
	@:optional var no_antialiasing:Bool;
}

class MenuCharacter extends FlxSprite
{
	public var character:String = '';
	public var hasConfirmAnimation:Bool = false;
	/** True when this character uses danceLeft / danceRight instead of a single idle. */
	public var useAlternative:Bool = false;

	var danceLeft:Bool = false;
	var characterFile:MenuCharacterFile = null;

	public function new(x:Float, character:String = 'bf')
	{
		super(x);
		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf')
	{
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		antialiasing = ClientPrefs.data.antialiasing;
		useAlternative = false;
		hasConfirmAnimation = false;
		danceLeft = false;

		visible = (character != '' && character != 'none' && character != 'null');
		if(!visible)
		{
			characterFile = null;
			return;
		}

		characterFile = loadCharacterFile(character);
		if(characterFile == null)
		{
			visible = false;
			return;
		}

		applyCharacterFile(characterFile);
	}

	/** Load + migrate JSON from props path. */
	public static function loadCharacterFile(character:String):MenuCharacterFile
	{
		if(character == null || character.length < 1) return null;
		var name:String = character.trim();
		if(name.length < 1) return null;

		var candidates:Array<String> = [
			'storymenu/props/characters/' + name,
			'storymenu/props/' + name,
			'menucharacters/' + name,
			'images/menucharacters/' + name
		];

		var raw:String = null;
		for (base in candidates)
		{
			var path:String = Paths.getPath(base + '.json', TEXT, null, true);
			#if MODS_ALLOWED
			if(path != null && FileSystem.exists(path))
			{
				try { raw = File.getContent(path); } catch(e:Dynamic) {}
			}
			#end
			if(raw == null)
			{
				try
				{
					var assetPath:String = Paths.getPath(base + '.json', TEXT);
					if(Assets.exists(assetPath))
						raw = Assets.getText(assetPath);
				}
				catch(e:Dynamic) {}
			}
			if(raw != null && raw.length > 0) break;
		}

		if(raw == null || raw.length < 1)
			return null;

		try
		{
			var parsed:Dynamic = Json.parse(raw);
			return normalizeCharacterFile(parsed, name);
		}
		catch(e:Dynamic)
		{
			trace('[MenuCharacter] Failed to parse JSON for ' + name + ': ' + e);
			return null;
		}
	}

	/** Convert legacy or partial JSON into the new MenuCharacterFile shape. */
	public static function normalizeCharacterFile(data:Dynamic, ?fallbackImage:String = ''):MenuCharacterFile
	{
		if(data == null) data = {};

		var file:MenuCharacterFile =
		{
			animations: [],
			propScale: 1,
			propPosition: [0.0, 0.0],
			propPath: 'storymenu/props/characters/',
			prop_disabled_Antialiasing: false,
			useAlternative: false,
			propImage: fallbackImage,
			image: fallbackImage,
			flipX: false
		};

		// Paths / image
		if(Reflect.hasField(data, 'propPath') && data.propPath != null)
			file.propPath = Std.string(data.propPath);
		if(Reflect.hasField(data, 'propImage') && data.propImage != null && Std.string(data.propImage).length > 0)
			file.propImage = Std.string(data.propImage);
		else if(Reflect.hasField(data, 'image') && data.image != null && Std.string(data.image).length > 0)
			file.propImage = Std.string(data.image);
		file.image = file.propImage;

		// Scale
		if(Reflect.hasField(data, 'propScale') && data.propScale != null)
			file.propScale = Std.parseFloat(Std.string(data.propScale));
		else if(Reflect.hasField(data, 'scale') && data.scale != null)
			file.propScale = Std.parseFloat(Std.string(data.scale));
		if(Math.isNaN(file.propScale) || file.propScale <= 0)
			file.propScale = 1;

		// Position
		if(Reflect.hasField(data, 'propPosition') && Std.isOfType(data.propPosition, Array))
			file.propPosition = parseFloatArray(data.propPosition);
		else if(Reflect.hasField(data, 'position') && Std.isOfType(data.position, Array))
			file.propPosition = parseFloatArray(data.position);
		if(file.propPosition == null || file.propPosition.length < 2)
			file.propPosition = [0.0, 0.0];

		// Antialiasing (inverted flag in new format)
		if(Reflect.hasField(data, 'prop_disabled_Antialiasing'))
			file.prop_disabled_Antialiasing = data.prop_disabled_Antialiasing == true;
		else if(Reflect.hasField(data, 'no_antialiasing'))
			file.prop_disabled_Antialiasing = data.no_antialiasing == true;
		else if(Reflect.hasField(data, 'antialiasing'))
			file.prop_disabled_Antialiasing = data.antialiasing == false;

		// useAlternative / legacy use_alternatives
		if(Reflect.hasField(data, 'useAlternative'))
			file.useAlternative = data.useAlternative == true;
		else if(Reflect.hasField(data, 'use_alternatives'))
			file.useAlternative = data.use_alternatives == true;

		if(Reflect.hasField(data, 'flipX'))
			file.flipX = data.flipX == true;

		// Animations array (new) or legacy idle_anim / confirm_anim
		if(Reflect.hasField(data, 'animations') && Std.isOfType(data.animations, Array))
		{
			var arr:Array<Dynamic> = cast data.animations;
			for (a in arr)
			{
				if(a == null) continue;
				var anim:MenuCharacterAnim = {
					name: Reflect.hasField(a, 'name') ? Std.string(a.name) : 'idle_anim',
					prefix: Reflect.hasField(a, 'prefix') ? Std.string(a.prefix) : '',
					offsets: parseFloatArray(Reflect.hasField(a, 'offsets') ? a.offsets : null)
				};
				file.animations.push(anim);
			}
		}

		// Ensure idle + confirm exist (from legacy fields if needed)
		ensureAnim(file, 'idle_anim', Reflect.hasField(data, 'idle_anim') ? Std.string(data.idle_anim) : '');
		ensureAnim(file, 'confirm_anim', Reflect.hasField(data, 'confirm_anim') ? Std.string(data.confirm_anim) : '');

		// Optional alternative dances
		if(file.useAlternative)
		{
			ensureAnim(file, 'danceLeft', Reflect.hasField(data, 'danceLeft') ? Std.string(data.danceLeft) : getAnimPrefix(file, 'idle_anim'));
			ensureAnim(file, 'danceRight', Reflect.hasField(data, 'danceRight') ? Std.string(data.danceRight) : getAnimPrefix(file, 'idle_anim'));
		}

		return file;
	}

	static function parseFloatArray(value:Dynamic):Array<Float>
	{
		var out:Array<Float> = [0.0, 0.0];
		if(value == null || !Std.isOfType(value, Array))
			return out;
		var arr:Array<Dynamic> = cast value;
		if(arr.length > 0)
		{
			var x:Float = Std.parseFloat(Std.string(arr[0]));
			out[0] = Math.isNaN(x) ? 0.0 : x;
		}
		if(arr.length > 1)
		{
			var y:Float = Std.parseFloat(Std.string(arr[1]));
			out[1] = Math.isNaN(y) ? 0.0 : y;
		}
		return out;
	}

	static function ensureAnim(file:MenuCharacterFile, name:String, prefix:String):Void
	{
		for (a in file.animations)
		{
			if(a != null && a.name == name)
			{
				if((a.prefix == null || a.prefix.length < 1) && prefix != null && prefix.length > 0)
					a.prefix = prefix;
				return;
			}
		}
		file.animations.push({name: name, prefix: prefix != null ? prefix : '', offsets: [0.0, 0.0]});
	}

	public static function getAnimPrefix(file:MenuCharacterFile, name:String):String
	{
		if(file == null || file.animations == null) return '';
		for (a in file.animations)
			if(a != null && a.name == name)
				return a.prefix != null ? a.prefix : '';
		return '';
	}

	public static function getAnimOffsets(file:MenuCharacterFile, name:String):Array<Float>
	{
		if(file == null || file.animations == null) return [0.0, 0.0];
		for (a in file.animations)
			if(a != null && a.name == name && a.offsets != null && a.offsets.length >= 2)
				return a.offsets;
		return file.propPosition != null ? file.propPosition : [0.0, 0.0];
	}

	public static function setAnimPrefix(file:MenuCharacterFile, name:String, prefix:String):Void
	{
		if(file == null) return;
		for (a in file.animations)
		{
			if(a != null && a.name == name)
			{
				a.prefix = prefix != null ? prefix : '';
				return;
			}
		}
		file.animations.push({name: name, prefix: prefix != null ? prefix : '', offsets: [0.0, 0.0]});
	}

	/** Build a clean new-format object for saving (no legacy fields). */
	public static function toNewFormat(file:MenuCharacterFile):Dynamic
	{
		if(file == null) return {};
		var anims:Array<Dynamic> = [];
		if(file.animations != null)
		{
			for (a in file.animations)
			{
				if(a == null) continue;
				anims.push({
					name: a.name,
					prefix: a.prefix != null ? a.prefix : '',
					offsets: (a.offsets != null && a.offsets.length >= 2) ? a.offsets : [0.0, 0.0]
				});
			}
		}
		return {
			animations: anims,
			propScale: file.propScale,
			propPosition: file.propPosition != null ? file.propPosition : [0.0, 0.0],
			propPath: file.propPath != null ? file.propPath : 'storymenu/props/characters/',
			propImage: file.propImage != null ? file.propImage : (file.image != null ? file.image : ''),
			prop_disabled_Antialiasing: file.prop_disabled_Antialiasing == true,
			useAlternative: file.useAlternative == true,
			flipX: file.flipX == true
		};
	}

	function applyCharacterFile(file:MenuCharacterFile):Void
	{
		useAlternative = file.useAlternative == true;

		var path:String = file.propPath != null ? file.propPath : 'storymenu/props/characters/';
		if(!path.endsWith('/') && !path.endsWith('\\')) path += '/';
		var img:String = file.propImage != null && file.propImage.length > 0 ? file.propImage : (file.image != null ? file.image : character);
		var atlasPath:String = path + img;

		try
		{
			frames = Paths.getSparrowAtlas(atlasPath);
		}
		catch(e:Dynamic)
		{
			try { frames = Paths.getSparrowAtlas('storymenu/props/characters/' + img); }
			catch(e2:Dynamic)
			{
				try { frames = Paths.getSparrowAtlas('menucharacters/' + character); }
				catch(e3:Dynamic)
				{
					visible = false;
					return;
				}
			}
		}

		animation.destroyAnimations();

		var idlePrefix:String = getAnimPrefix(file, 'idle_anim');
		var confirmPrefix:String = getAnimPrefix(file, 'confirm_anim');
		var danceL:String = getAnimPrefix(file, 'danceLeft');
		var danceR:String = getAnimPrefix(file, 'danceRight');

		if(useAlternative)
		{
			if(danceL.length > 0) animation.addByPrefix('danceLeft', danceL, 24, false);
			if(danceR.length > 0) animation.addByPrefix('danceRight', danceR, 24, false);
			// fallback idle if dances missing
			if(!animation.exists('danceLeft') && idlePrefix.length > 0)
				animation.addByPrefix('idle', idlePrefix, 24);
		}
		else if(idlePrefix.length > 0)
		{
			animation.addByPrefix('idle', idlePrefix, 24);
		}

		hasConfirmAnimation = false;
		if(confirmPrefix != null && confirmPrefix.length > 0)
		{
			animation.addByPrefix('confirm', confirmPrefix, 24, false);
			hasConfirmAnimation = animation.exists('confirm');
		}

		flipX = file.flipX == true;
		if(file.prop_disabled_Antialiasing)
			antialiasing = false;
		else
			antialiasing = ClientPrefs.data.antialiasing;

		var sc:Float = file.propScale;
		if(Math.isNaN(sc) || sc <= 0) sc = 1;
		scale.set(sc, sc);
		updateHitbox();

		var pos:Array<Float> = file.propPosition != null ? file.propPosition : [0.0, 0.0];
		offset.set(pos[0], pos[1]);

		playIdle();
	}

	public function playIdle():Void
	{
		if(useAlternative)
		{
			danceLeft = !danceLeft;
			if(danceLeft && animation.exists('danceLeft'))
				animation.play('danceLeft', true);
			else if(animation.exists('danceRight'))
				animation.play('danceRight', true);
			else if(animation.exists('idle'))
				animation.play('idle', true);
		}
		else if(animation.exists('idle'))
		{
			animation.play('idle', true);
		}
	}

	public function playConfirm():Void
	{
		if(hasConfirmAnimation && animation.exists('confirm'))
			animation.play('confirm', true);
	}
}
