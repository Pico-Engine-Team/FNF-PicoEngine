package funkin.stages;

import funkin.play.Song;
import funkin.data.objects.CharactersData as Character;
import funkin.modding.scripting.psychlua.ModchartSprite;

import openfl.utils.Assets;
import haxe.Json;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;
	@:optional var isPixelStage:Null<Bool>;
	var stageUI:String;
	@:optional var characters:StageCharactersData;

	var boyfriend:Array<Float>;
	var girlfriend:Array<Float>;
	var opponent:Array<Float>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;

	@:optional var preload:Dynamic;
	@:optional var objects:Array<Dynamic>;
	@:optional var _editorMeta:Dynamic;
	/** Pico new format aliases (mapped on load) */
	@:optional var stage_directory:String;
	@:optional var default_cameraZoom:Float;
	@:optional var camera_ScrollSpeed:Float;
	@:optional var ratingsOffsets:Array<Dynamic>;
	@:optional var ratingsOffset:Array<Dynamic>;
}

typedef StageCharactersData = {
	@:optional var bf:StageCharacterData;
	@:optional var dad:StageCharacterData;
	@:optional var gf:StageCharacterData;
}

typedef StageCharacterData = {
	var zIndex:Int;
	var position:Array<Float>;
	var cameraOffsets:Array<Float>;
	/** New format aliases */
	@:optional var positionOffsets:Array<Float>;
	@:optional var cameraPosition:Array<Float>;
	@:optional var Girlfriend_Hide:Bool;
}

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt
{
	var LOW_QUALITY:Int = (1 << 0);
	var HIGH_QUALITY:Int = (1 << 1);

	var STORY_MODE:Int = (1 << 2);
	var FREEPLAY:Int = (1 << 3);
}

class StageData
{
	public static function dummy():StageFile
	{
		return {
			directory: "",
			defaultZoom: 0.9,
			stageUI: "normal",
			characters: {
				bf: {
					zIndex: 300,
					position: [989.5, 885],
					cameraOffsets: [-100, -100]
				},
				dad: {
					zIndex: 200,
					position: [335, 885],
					cameraOffsets: [150, -100]
				},
				gf: {
					zIndex: 100,
					cameraOffsets: [0, 0],
					position: [751.5, 787]
				}
			},

			boyfriend: [989.5, 885],
			opponent: [335, 885],
			girlfriend: [751.5, 787],
			hide_girlfriend: false,

			camera_boyfriend: [-100, -100],
			camera_opponent: [150, -100],
			camera_girlfriend: [0, 0],
			camera_speed: 1,

			_editorMeta: {
				boyfriend: "bf",
				dad: "dad",
				gf: "gf",
			}
		};
	}

	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong) {
		var stage:String = '';
		if(SONG.stage != null)
			stage = SONG.stage;
		else if(Song.loadedSongName != null)
			stage = vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));
		else
			stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = (stageFile != null) ? stageFile.directory : ''; //preventing crashes
	}

	public static function getStageFile(stage:String):StageFile {
		try
		{
			var path:String = Paths.getPath('data/stages/' + stage + '.json', TEXT, null, true);
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
				return normalizeStageFile(cast tjson.TJSON.parse(File.getContent(path)));
			#else
			if(Assets.exists(path))
				return normalizeStageFile(cast tjson.TJSON.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('[StageData] Failed to load stage "' + stage + '": ' + e);
		}
		return dummy();
	}

	/**
	 * Normalize stage JSON for runtime (PlayState) and editors.
	 * Accepts Psych StageFile + Pico new format:
	 *   stage_directory, default_cameraZoom, camera_ScrollSpeed, ratingsOffsets,
	 *   characters.{bf|gf|dad}.{positionOffsets, cameraPosition, Girlfriend_Hide},
	 *   preload
	 */
	static function normalizeStageFile(stage:StageFile):StageFile
	{
		if(stage == null) return dummy();

		mapNewStageFormat(stage);

		stage.defaultZoom = floatField(stage.defaultZoom, 0.9);
		stage.camera_speed = stage.camera_speed != null ? floatField(stage.camera_speed, 1) : 1;
		if(stage.stageUI == null || Std.string(stage.stageUI).trim().length < 1)
			stage.stageUI = 'normal';
		normalizeStageCharacters(stage);

		stage.boyfriend = normalizePoint(stage.boyfriend, [770, 100]);
		stage.girlfriend = normalizePoint(stage.girlfriend, [400, 130]);
		stage.opponent = normalizePoint(stage.opponent, [100, 100]);
		stage.camera_boyfriend = normalizePoint(stage.camera_boyfriend, [0, 0]);
		stage.camera_opponent = normalizePoint(stage.camera_opponent, [0, 0]);
		stage.camera_girlfriend = normalizePoint(stage.camera_girlfriend, [0, 0]);

		if(stage.objects != null)
		{
			for(object in stage.objects)
				normalizeStageObject(object);
		}
		return stage;
	}

	/**
	 * Map Pico new stage JSON keys onto Psych StageFile fields (in-place).
	 * Safe to call on already-Psych stages (no-op when fields already set).
	 */
	public static function mapNewStageFormat(json:Dynamic):Void
	{
		if(json == null) return;

		// stage_directory → directory
		var dir:Dynamic = Reflect.field(json, 'directory');
		if((dir == null || Std.string(dir).trim().length < 1) && Reflect.hasField(json, 'stage_directory'))
			Reflect.setField(json, 'directory', Reflect.field(json, 'stage_directory'));

		// default_cameraZoom → defaultZoom
		if(Reflect.field(json, 'defaultZoom') == null && Reflect.hasField(json, 'default_cameraZoom'))
			Reflect.setField(json, 'defaultZoom', Reflect.field(json, 'default_cameraZoom'));

		// camera_ScrollSpeed → camera_speed
		if(Reflect.field(json, 'camera_speed') == null && Reflect.hasField(json, 'camera_ScrollSpeed'))
			Reflect.setField(json, 'camera_speed', Reflect.field(json, 'camera_ScrollSpeed'));

		// ratingsOffsets → ratingsOffset
		if(Reflect.field(json, 'ratingsOffset') == null && Reflect.hasField(json, 'ratingsOffsets'))
			Reflect.setField(json, 'ratingsOffset', Reflect.field(json, 'ratingsOffsets'));

		// characters block (new format)
		var chars:Dynamic = Reflect.field(json, 'characters');
		if(chars != null && Type.typeof(chars) == TObject)
		{
			// Detect Pico-style characters (has positionOffsets / cameraPosition) vs V-Slice StageCharactersData (has position / zIndex)
			function isPicoChar(c:Dynamic):Bool
			{
				if(c == null) return false;
				return Reflect.hasField(c, 'positionOffsets') || Reflect.hasField(c, 'cameraPosition')
					|| Reflect.hasField(c, 'Girlfriend_Hide') || Reflect.hasField(c, 'hide');
			}

			var bf:Dynamic = Reflect.field(chars, 'bf');
			if(bf == null) bf = Reflect.field(chars, 'boyfriend');
			if(bf == null) bf = Reflect.field(chars, 'player');

			var gf:Dynamic = Reflect.field(chars, 'gf');
			if(gf == null) gf = Reflect.field(chars, 'girlfriend');

			var dad:Dynamic = Reflect.field(chars, 'dad');
			if(dad == null) dad = Reflect.field(chars, 'opponent');

			// Only remap when Pico keys present (avoid breaking V-Slice characters.position)
			if(isPicoChar(bf) || isPicoChar(gf) || isPicoChar(dad))
			{
				if(bf != null)
				{
					var pos:Dynamic = Reflect.field(bf, 'positionOffsets');
					if(pos == null) pos = Reflect.field(bf, 'position');
					if(pos != null && Reflect.field(json, 'boyfriend') == null)
						Reflect.setField(json, 'boyfriend', pos);
					var cam:Dynamic = Reflect.field(bf, 'cameraPosition');
					if(cam == null) cam = Reflect.field(bf, 'cameraOffsets');
					if(cam == null) cam = Reflect.field(bf, 'camera');
					if(cam != null && Reflect.field(json, 'camera_boyfriend') == null)
						Reflect.setField(json, 'camera_boyfriend', cam);
					// Also write into characters.bf.position for normalizeStageCharacters
					if(pos != null) Reflect.setField(bf, 'position', pos);
					if(cam != null) Reflect.setField(bf, 'cameraOffsets', cam);
				}
				if(gf != null)
				{
					var posG:Dynamic = Reflect.field(gf, 'positionOffsets');
					if(posG == null) posG = Reflect.field(gf, 'position');
					if(posG != null && Reflect.field(json, 'girlfriend') == null)
						Reflect.setField(json, 'girlfriend', posG);
					var camG:Dynamic = Reflect.field(gf, 'cameraPosition');
					if(camG == null) camG = Reflect.field(gf, 'cameraOffsets');
					if(camG == null) camG = Reflect.field(gf, 'camera');
					if(camG != null && Reflect.field(json, 'camera_girlfriend') == null)
						Reflect.setField(json, 'camera_girlfriend', camG);
					if(posG != null) Reflect.setField(gf, 'position', posG);
					if(camG != null) Reflect.setField(gf, 'cameraOffsets', camG);

					if(Reflect.field(json, 'hide_girlfriend') == null || Reflect.field(json, 'hide_girlfriend') == false)
					{
						if(Reflect.hasField(gf, 'Girlfriend_Hide'))
							Reflect.setField(json, 'hide_girlfriend', Reflect.field(gf, 'Girlfriend_Hide') == true);
						else if(Reflect.hasField(gf, 'hide'))
							Reflect.setField(json, 'hide_girlfriend', Reflect.field(gf, 'hide') == true);
					}
				}
				if(dad != null)
				{
					var posD:Dynamic = Reflect.field(dad, 'positionOffsets');
					if(posD == null) posD = Reflect.field(dad, 'position');
					if(posD != null && Reflect.field(json, 'opponent') == null)
						Reflect.setField(json, 'opponent', posD);
					var camD:Dynamic = Reflect.field(dad, 'cameraPosition');
					if(camD == null) camD = Reflect.field(dad, 'cameraOffsets');
					if(camD == null) camD = Reflect.field(dad, 'camera');
					if(camD != null && Reflect.field(json, 'camera_opponent') == null)
						Reflect.setField(json, 'camera_opponent', camD);
					if(posD != null) Reflect.setField(dad, 'position', posD);
					if(camD != null) Reflect.setField(dad, 'cameraOffsets', camD);
				}
			}

			// preload nested under characters by mistake
			if(Reflect.field(json, 'preload') == null && Reflect.hasField(chars, 'preload'))
				Reflect.setField(json, 'preload', Reflect.field(chars, 'preload'));
		}
	}

	static function normalizeStageCharacters(stage:StageFile):Void
	{
		if(stage.characters == null)
		{
			stage.characters = {
				bf: createStageCharacter(300, stage.boyfriend, stage.camera_boyfriend, [770, 100], [0, 0]),
				dad: createStageCharacter(200, stage.opponent, stage.camera_opponent, [100, 100], [0, 0]),
				gf: createStageCharacter(100, stage.girlfriend, stage.camera_girlfriend, [400, 130], [0, 0])
			};
			return;
		}

		stage.characters.bf = normalizeStageCharacter(stage.characters.bf, 300, [770, 100], [0, 0]);
		stage.characters.dad = normalizeStageCharacter(stage.characters.dad, 200, [100, 100], [0, 0]);
		stage.characters.gf = normalizeStageCharacter(stage.characters.gf, 100, [400, 130], [0, 0]);

		stage.boyfriend = stage.characters.bf.position.copy();
		stage.opponent = stage.characters.dad.position.copy();
		stage.girlfriend = stage.characters.gf.position.copy();
		stage.camera_boyfriend = stage.characters.bf.cameraOffsets.copy();
		stage.camera_opponent = stage.characters.dad.cameraOffsets.copy();
		stage.camera_girlfriend = stage.characters.gf.cameraOffsets.copy();
	}

	static function createStageCharacter(zIndex:Int, position:Dynamic, cameraOffsets:Dynamic, fallbackPosition:Array<Float>, fallbackCamera:Array<Float>):StageCharacterData
	{
		return {
			zIndex: zIndex,
			position: normalizePoint(position, fallbackPosition),
			cameraOffsets: normalizePoint(cameraOffsets, fallbackCamera)
		};
	}

	static function normalizeStageCharacter(character:StageCharacterData, zIndex:Int, fallbackPosition:Array<Float>, fallbackCamera:Array<Float>):StageCharacterData
	{
		if(character == null)
			return createStageCharacter(zIndex, null, null, fallbackPosition, fallbackCamera);

		// Prefer position; fall back to positionOffsets (new Pico format)
		var posRaw:Dynamic = character.position;
		if(posRaw == null && Reflect.hasField(character, 'positionOffsets'))
			posRaw = Reflect.field(character, 'positionOffsets');

		var camRaw:Dynamic = character.cameraOffsets;
		if(camRaw == null && Reflect.hasField(character, 'cameraPosition'))
			camRaw = Reflect.field(character, 'cameraPosition');

		return {
			zIndex: Std.int(floatField(character.zIndex, zIndex)),
			position: normalizePoint(posRaw, fallbackPosition),
			cameraOffsets: normalizePoint(camRaw, fallbackCamera)
		};
	}

	static function normalizeStageObject(object:Dynamic):Void
	{
		if(object == null) return;

		for(field in ['x', 'y', 'alpha', 'angle'])
		{
			var value:Dynamic = Reflect.field(object, field);
			if(value != null)
				Reflect.setField(object, field, floatField(value, field == 'alpha' ? 1 : 0));
		}

		var scale:Dynamic = Reflect.field(object, 'scale');
		Reflect.setField(object, 'scale', normalizePoint(scale, [1, 1]));

		var scroll:Dynamic = Reflect.field(object, 'scroll');
		Reflect.setField(object, 'scroll', normalizePoint(scroll, [1, 1]));

		var filters:Dynamic = Reflect.field(object, 'filters');
		if(filters != null)
		{
			var parsed:Float = floatField(filters, LOW_QUALITY | HIGH_QUALITY);
			Reflect.setField(object, 'filters', Std.int(parsed));
		}
	}

	static function normalizePoint(value:Dynamic, fallback:Array<Float>):Array<Float>
	{
		if(value == null) return fallback.copy();

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			return [
				array.length > 0 ? floatField(array[0], fallback[0]) : fallback[0],
				array.length > 1 ? floatField(array[1], fallback[1]) : fallback[1]
			];
		}

		var text:String = Std.string(value).replace(';', ',').replace('|', ',');
		var split:Array<String> = text.contains(',') ? text.split(',') : text.split(' ');
		if(split.length > 1)
			return [floatField(split[0], fallback[0]), floatField(split[1], fallback[1])];

		return fallback.copy();
	}

	static function floatField(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed:Float = Std.parseFloat(Std.string(value).trim());
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	public static function vanillaSongStage(songName):String
	{
		switch (songName)
		{
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			case 'darnell' | 'lit-up' | '2hot':
				return 'phillyStreets';
			case 'blazin':
				return 'phillyBlazin';
		}
		return 'stage';
	}

	public static var reservedNames:Array<String> = ['gf', 'gfGroup', 'dad', 'dadGroup', 'boyfriend', 'boyfriendGroup']; //blocks these names from being used on stage editor's name input text
	public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, ?group:Dynamic = null, ?ignoreFilters:Bool = false)
	{
		var addedObjects:Map<String, FlxSprite> = [];
		for (num => data in objectList)
		{
			if(data == null) continue;
			// Key by name (string) — exists(data) with object key never worked correctly
			var objName:String = Reflect.hasField(data, 'name') ? Std.string(Reflect.field(data, 'name')) : null;
			if(objName != null && objName.length > 0 && addedObjects.exists(objName)) continue;

			switch(data.type)
			{
				case 'gf', 'gfGroup':
					if(gf != null)
					{
						gf.ID = num; 
						if (group != null) group.add(gf);
						addedObjects.set('gf', gf);
					}
				case 'dad', 'dadGroup':
					if(dad != null)
					{
						dad.ID = num;
						if (group != null) group.add(dad);
						addedObjects.set('dad', dad);
					}
				case 'boyfriend', 'boyfriendGroup':
					if(boyfriend != null)
					{
						boyfriend.ID = num;
						if (group != null) group.add(boyfriend);
						addedObjects.set('boyfriend', boyfriend);
					}

				case 'square', 'sprite', 'animatedSprite':
					if(!ignoreFilters && !validateVisibility(data.filters)) continue;

					var spr:ModchartSprite = new ModchartSprite(data.x, data.y);
					spr.ID = num;
					if(data.type != 'square')
					{
						if(data.type == 'sprite')
							spr.loadGraphic(Paths.image(data.image));
						else
							spr.frames = Paths.getAtlas(data.image);
						
						if(data.type == 'animatedSprite' && data.animations != null)
						{
							var anims:Array<Dynamic> = cast data.animations;
							for (anim in anims)
							{
								if(anim == null) continue;
								var animName:String = anim.anim != null ? Std.string(anim.anim) : null;
								var prefix:String = anim.name != null ? Std.string(anim.name) : animName;
								if(animName == null || animName.length < 1 || prefix == null || prefix.length < 1)
									continue;
								var fps:Int = 24;
								if(anim.fps != null)
								{
									var pf:Null<Int> = Std.parseInt(Std.string(anim.fps));
									if(pf != null && pf > 0) fps = pf;
								}
								var loop:Bool = anim.loop == true;
								if(anim.indices == null || anim.indices.length < 1)
									spr.animation.addByPrefix(animName, prefix, fps, loop);
								else
									spr.animation.addByIndices(animName, prefix, anim.indices, '', fps, loop);

								if(anim.offsets != null && Std.isOfType(anim.offsets, Array))
								{
									var oa:Array<Dynamic> = cast anim.offsets;
									var ox:Float = oa.length > 0 ? Std.parseFloat(Std.string(oa[0])) : 0;
									var oy:Float = oa.length > 1 ? Std.parseFloat(Std.string(oa[1])) : 0;
									if(Math.isNaN(ox)) ox = 0;
									if(Math.isNaN(oy)) oy = 0;
									spr.addOffset(animName, ox, oy);
								}

								if(spr.animation.curAnim == null || data.firstAnimation == animName)
									spr.playAnim(animName, true);
							}
						}
						for (varName in ['antialiasing', 'flipX', 'flipY'])
						{
							var dat:Dynamic = Reflect.getProperty(data, varName);
							if(dat != null) Reflect.setProperty(spr, varName, dat);
						}
						if(!Preferences.data.antialiasing) spr.antialiasing = false;
					}
					else
					{
						spr.makeGraphic(1, 1, FlxColor.WHITE);
						spr.antialiasing = false;
					}

					var scX:Float = 1;
					var scY:Float = 1;
					if(data.scale != null && Std.isOfType(data.scale, Array))
					{
						var sa:Array<Dynamic> = cast data.scale;
						if(sa.length > 0) scX = floatField(sa[0], 1);
						if(sa.length > 1) scY = floatField(sa[1], 1);
					}
					if(scX != 1.0 || scY != 1.0)
					{
						spr.scale.set(scX, scY);
						spr.updateHitbox();
					}
					var scrX:Float = 1;
					var scrY:Float = 1;
					if(data.scroll != null && Std.isOfType(data.scroll, Array))
					{
						var sra:Array<Dynamic> = cast data.scroll;
						if(sra.length > 0) scrX = floatField(sra[0], 1);
						if(sra.length > 1) scrY = floatField(sra[1], 1);
					}
					spr.scrollFactor.set(scrX, scrY);
					spr.color = CoolUtil.colorFromString(data.color != null ? data.color : 'FFFFFF');
					
					for (varName in ['alpha', 'angle'])
					{
						var dat:Dynamic = Reflect.getProperty(data, varName);
						if(dat != null) Reflect.setProperty(spr, varName, dat);
					}

					if (group != null) group.add(spr);
					addedObjects.set(data.name, spr);

				default:
					var err = '[Stage .JSON file] Unknown sprite type detected: ${data.type}';
					trace(err);
					FlxG.log.error(err);
			}
		}
		return addedObjects;
	}

	public static function validateVisibility(filters:LoadFilters)
	{
		// Braces required — without them the else binds to the inner if (dangling else)
		if((filters & STORY_MODE) == STORY_MODE)
		{
			if(!PlayState.isStoryMode) return false;
		}
		else if((filters & FREEPLAY) == FREEPLAY)
		{
			if(PlayState.isStoryMode) return false;
		}

		// filters == 0 → visible in both quality modes
		if(filters == 0 || filters == null)
			return true;

		return ((Preferences.isLowQuality && (filters & LOW_QUALITY) == LOW_QUALITY) ||
			(!Preferences.isLowQuality && (filters & HIGH_QUALITY) == HIGH_QUALITY));
	}
}