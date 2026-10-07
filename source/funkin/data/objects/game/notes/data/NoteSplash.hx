package funkin.data.objects.game.notes.data;

import funkin.data.shaders.RGBPalette;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.NoteData;
import funkin.data.objects.game.notes.config.StrumNote;
import funkin.utils.engines.psych.PsychAnimationController;
import flixel.system.FlxAssets.FlxShader;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

typedef NoteSplashAnim = {
	name:String,
	noteData:Int,
	prefix:String,
	indices:Array<Int>,
	offsets:Array<Float>,
	fps:Array<Int>
}

typedef NoteSplashConfig = {
	animations:Map<String, NoteSplashAnim>,
	scale:Float,
	allowRGB:Bool,
	allowPixel:Bool,
	rgb:Array<Null<RGB>>
}

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var texture:String;
	public var config(default, set):NoteSplashConfig;
	public var babyArrow:StrumNote;
	public var noteData:Int = 0;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var inEditor:Bool = false;

	var spawned:Bool = false;
	var noteDataMap:Map<Int, String> = new Map();

	public static var defaultNoteSplash(default, never):String = "splashes/noteSplashes"; // images/splashes/... or data path via NoteData
	public static var configs:Map<String, NoteSplashConfig> = new Map();

	public function new(?x:Float = 0, ?y:Float = 0, ?splash:String)
	{
		super(x, y);

		animation = new PsychAnimationController(this);
		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadSplash(splash);
	}

	public var maxAnims(default, set):Int = 0;
	public function loadSplash(?splash:String)
	{
		config = null;
		maxAnims = 0;

		if(splash == null)
		{
			splash = NoteData.notestyles.noteSplash(null, true);
		}

		var fallbackSplash:String = defaultNoteSplash + getSplashSkinPostfix();
		// Prefer notestyle Splash_data, then data/splashes (images/splashes/...)
		var candidates:Array<String> = [];
		if(splash != null && splash.length > 0) candidates.push(splash);
		candidates.push(fallbackSplash);
		candidates.push(defaultNoteSplash);
		candidates.push('splashes/noteSplashes');
		candidates.push('noteSplashes');
		frames = null;
		for (candidate in candidates)
		{
			if(candidate == null || candidate.length < 1) continue;

			try
			{
				// shared images
				if(Paths.fileExists('images/$candidate.png', IMAGE) && Paths.fileExists('images/$candidate.xml', TEXT))
				{
					var atlas = Paths.getSparrowAtlas(candidate);
					if(atlas != null)
					{
						texture = candidate;
						frames = atlas;
						break;
					}
				}

				// pico_assets (só se o arquivo existir — evita NPE no FlxAtlasFrames)
				if(Note.noteSkinAtlasExists(candidate))
				{
					var picoFrames = Note.getNoteSkinAtlas(candidate);
					if(picoFrames != null)
					{
						texture = candidate;
						frames = picoFrames;
						break;
					}
				}
			}
			catch(e:Dynamic)
			{
				trace('[NoteSplash] Failed to load splash "$candidate": $e');
			}
		}
		if(frames == null) return;

		// Build config from NoteData Splash_data (no noteSplash.json)
		var cacheKey:String = 'notestyle:' + texture;
		if (configs.exists(cacheKey))
		{
			this.config = configs.get(cacheKey);
			for (anim in this.config.animations)
				if (anim.noteData % 4 == 0)
					maxAnims++;
			return;
		}

		var fromStyle:NoteSplashConfig = buildConfigFromNoteStyle(texture);
		if (fromStyle != null)
		{
			this.config = fromStyle;
			for (anim in this.config.animations)
				if (anim.noteData % 4 == 0)
					maxAnims++;
			configs.set(cacheKey, this.config);
			return;
		}

		// Prefix fallback when Splash_data has no anim list (scan atlas)
		var tempConfig:NoteSplashConfig = createConfig();
		var anim:String = 'note splash';
		var fps:Array<Null<Int>> = [22, 26];
		var offsets:Array<Array<Float>> = [[0, 0]];
		var path:String = 'images/' + texture;
		if (Paths.fileExists('$path.txt', TEXT)) // Backwards compatibility with 0.7 splash txts
		{
			var configFile:Array<String> = CoolUtil.listFromString(Paths.getTextFromFile('$path.txt'));
			if (configFile.length > 0)
			{
				anim = configFile[0];
				if (configFile.length > 1)
				{
					var framerates:Array<String> = configFile[1].split(' ');
					fps = [Std.parseInt(framerates[0]), Std.parseInt(framerates[1])];
					if (fps[0] == null) fps[0] = 22;
					if (fps[1] == null) fps[1] = 26;

					if (configFile.length > 2)
					{
						offsets = [];
						for (i in 2...configFile.length)
						{
							if (configFile[i].trim() != '')
							{
								var animOffs:Array<String> = configFile[i].split(' ');
								var x:Float = Std.parseFloat(animOffs[0]);
								var y:Float = Std.parseFloat(animOffs[1]);
								if (Math.isNaN(x)) x = 0;
								if (Math.isNaN(y)) y = 0;
								offsets.push([x, y]);
							}
						}
					}
				}
			}
		}

		var failedToFind:Bool = false;
		while (true)
		{
			for (v in Note.colArray)
			{
				if (!checkForAnim('$anim $v ${maxAnims+1}'))
				{
					failedToFind = true;
					break;
				}
			}
			if (failedToFind) break;
			maxAnims++;
		}

		for (animNum in 0...maxAnims)
		{
			for (i => col in Note.colArray)
			{
				var data:Int = i % Note.colArray.length + (animNum * Note.colArray.length);
				var name:String = animNum > 0 ? '$col' + (animNum + 1) : col;
				var offset:Array<Float> = offsets[FlxMath.wrap(data, 0, Std.int(offsets.length-1))];
				addAnimationToConfig(tempConfig, 1, name, '$anim $col ${animNum + 1}', fps, offset, [], data);
			}
		}

		this.config = tempConfig;
		configs.set(cacheKey, this.config);
	}

	public function spawnSplashNote(?x:Float = 0, ?y:Float = 0, ?noteData:Int = 0, ?note:Note, ?randomize:Bool = true)
	{
		if (note != null && note.noteSplashData.disabled)
			return;

		// noteStyle noteSplash_splashEnabled
		var isPlayerSplash:Bool = note != null ? note.mustPress : true;
		try
		{
			if(!NoteData.notestyles.splashEnabled(null, isPlayerSplash))
				return;
		}
		catch(e:Dynamic) {}

		aliveTime = 0;

		if (!inEditor)
		{
			var isPlayer:Bool = note != null ? note.mustPress : true;
			var loadedTexture:String = NoteData.notestyles.noteSplash(null, isPlayer);
			if (note != null && note.noteSplashData.texture != null && note.noteSplashData.texture.length > 0)
				loadedTexture = note.noteSplashData.texture;
			else
			{
				var songSplash:String = Note.songSplashSkinForMustPress(isPlayer);
				if(songSplash != null && songSplash.length > 0)
					loadedTexture = songSplash;
			}

			if (texture != loadedTexture) loadSplash(loadedTexture);
			// se o splash não carregou, não continua (evita NPE)
			if (frames == null) return;
		}

		setPosition(x, y);

		if (babyArrow != null)
			setPosition(babyArrow.x - Note.swagWidth * 0.95, babyArrow.y - Note.swagWidth); // To prevent it from being misplaced for one game tick

		if (note != null)
			noteData = note.noteData;

		if (randomize && maxAnims > 1)
			noteData = noteData % Note.colArray.length + (FlxG.random.int(0, maxAnims - 1) * Note.colArray.length);

		this.noteData = noteData;
		var anim:String = playDefaultAnim();

		var tempShader:RGBPalette = null;
		if (config != null && config.allowRGB)
		{
			Note.initializeGlobalRGBShader(noteData % Note.colArray.length);
			// RGB via noteStyle.allowRGB / noteSplashData (disableNoteRGB removido)
			if (inEditor || (note == null || note.noteSplashData.useRGBShader))
			{
				tempShader = new RGBPalette();
				// If Note RGB is enabled:
				if ((note == null || !note.noteSplashData.useGlobalShader) || inEditor)
				{
					var colors = config.rgb;
					if (colors != null)
					{
						for (i in 0...colors.length)
						{
							if (i > 2) break;

							var arr:Array<FlxColor> = Preferences.data.arrowRGB[noteData % Note.colArray.length];
							if (PlayState.isPixelStage) arr = Preferences.data.arrowRGBPixel[noteData % Note.colArray.length];

							var rgb = colors[i];
							if (rgb == null)
							{
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						}
					}
					else tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);

					if (note != null)
					{
						if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
						if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
						if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
					}
				}
				else tempShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);
			}
		}
		rgbShader.copyValues(tempShader);
		if (config == null || !config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = 6;

		offset.set(10, 10);
		// Global offsets from notestyle Splash_data.splash_offsets
		try
		{
			var isPlayer:Bool = note != null ? note.mustPress : true;
			var styleOff = NoteData.noteStyle.splashOffsets(null, isPlayer);
			if(styleOff != null && styleOff.length >= 2)
			{
				offset.x += styleOff[0];
				offset.y += styleOff[1];
			}
		}
		catch(e:Dynamic) {}
		var conf:NoteSplashAnim = config != null ? config.animations.get(anim) : null;
		var offsets:Array<Float> = [0, 0];
		if (conf != null && conf.offsets != null) offsets = conf.offsets;
		if (offsets != null)
		{
			offset.x += offsets[0];
			offset.y += offsets[1];
		}

		animation.finishCallback = function(name:String) {
			kill();
			spawned = false;
		}

		alpha = Preferences.data.splashAlpha;
		if (note != null) alpha = note.noteSplashData.a;

		antialiasing = Preferences.data.antialiasing;
		if (note != null) antialiasing = note.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config != null && config.allowPixel) antialiasing = false;

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if (conf != null)
		{
			minFps = conf.fps[0];
			if (minFps < 0) minFps = 0;

			maxFps = conf.fps[1];
			if (maxFps < 0) maxFps = 0;
		}

		if (animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		spawned = true;
	}
	
	public function playDefaultAnim()
	{
		var anim:String = noteDataMap.get(noteData);
		if (anim != null && animation.exists(anim))
			animation.play(anim, true);

		return anim;
	}

	function checkForAnim(anim:String)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

		return animFrames.length > 0;
	}

	var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float)
	{
		if (spawned)
		{
			aliveTime += elapsed;
			if (animation.curAnim == null && aliveTime >= buggedKillTime)
			{
				kill();
				spawned = false;
			}
		}

		if (babyArrow != null)
		{
			if (copyX)
				x = babyArrow.x - Note.swagWidth * 0.95;

			if (copyY)
				y = babyArrow.y - Note.swagWidth;
		}
		super.update(elapsed);
	}

	public static function getSplashSkinPostfix()
	{
		// splashSkin removed — noteStyle Splash_data controls splash texture
		return '';
	}

	function buildConfigFromNoteStyle(texture:String):NoteSplashConfig
	{
		var temp:NoteSplashConfig = createConfig();
		var keys:Array<String> = ['leftSplashes', 'downSplashes', 'upSplashes', 'rightSplashes'];
		var colKeys:Array<String> = ['purple', 'blue', 'green', 'red'];
		var found:Int = 0;

		for (dir in 0...4)
		{
			var list:Array<Dynamic> = null;
			try
			{
				list = cast NoteData.noteStyle.splashAnims(keys[dir], null, true);
			}
			catch(e:Dynamic)
			{
				list = null;
			}
			if(list == null || list.length < 1)
			{
				try
				{
					list = cast NoteData.noteStyle.splashAnims(['left','down','up','right'][dir], null, true);
				}
				catch(e:Dynamic)
				{
					list = null;
				}
			}
			if(list == null || list.length < 1) continue;

			for (i in 0...list.length)
			{
				var a:Dynamic = list[i];
				if(a == null) continue;
				var prefix:String = Reflect.field(a, 'prefix');
				if(prefix == null || Std.string(prefix).length < 1) continue;
				prefix = Std.string(prefix);

				// Prefer JSON "name" for the animation id when present
				var animName:String = null;
				var nameField:Dynamic = Reflect.field(a, 'name');
				if(nameField != null && Std.string(nameField).trim().length > 0)
					animName = Std.string(nameField).trim();
				if(animName == null || animName.length < 1)
					animName = colKeys[dir] + (i > 0 ? Std.string(i + 1) : '');

				var fpsVal:Null<Int> = Reflect.field(a, 'fps');
				var fpsArr:Array<Int> = fpsVal != null ? [fpsVal, fpsVal] : [22, 26];
				var indices:Array<Int> = Reflect.field(a, 'indices');
				if(indices == null) indices = [];
				var data:Int = dir + (i * 4);
				addAnimationToConfig(temp, 1, animName, prefix, fpsArr, [0, 0], indices, data);
				found++;
			}
		}

		if(found < 1) return null;

		try
		{
			var rt = NoteData.runtime(true);
			if(rt != null)
			{
				temp.allowRGB = rt.allowRGB;
				temp.allowPixel = rt.allowPixel;
			}
		}
		catch(e:Dynamic) {}

		return temp;
	}

	public static function createConfig():NoteSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true,
			rgb: null
		}
	}

	public static function addAnimationToConfig(config:NoteSplashConfig, scale:Float, name:String, prefix:String, fps:Array<Int>, offsets:Array<Float>, indices:Array<Int>, noteData:Int):NoteSplashConfig
	{
		if (config == null) config = createConfig();

		config.animations.set(name, {name: name, noteData: noteData, prefix: prefix, indices: indices, offsets: offsets, fps: fps});
		config.scale = scale;
		return config;
	}

	function set_config(value:NoteSplashConfig):NoteSplashConfig 
	{
		if (value == null) value = createConfig();

		@:privateAccess
		animation.clearAnimations();
		noteDataMap.clear();

		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				if (i.indices != null && i.indices.length > 0)
					animation.addByIndices(key, i.prefix, i.indices, "", i.fps[1], false);
				else
					animation.addByPrefix(key, i.prefix, i.fps[1], false);

				noteDataMap.set(i.noteData, key);
			}
		}

		scale.set(value.scale, value.scale);
		return config = value;
	}

	function set_maxAnims(value:Int)
	{
		if (value > 0)
			noteData = Std.int(FlxMath.wrap(noteData, 0, (value * Note.colArray.length) - 1));
		else
			noteData = 0;

		return maxAnims = value;
	}
}

class PixelSplashShaderRef 
{
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var enabled(default, set):Bool = true;
	public var pixelAmount(default, set):Float = 1;

	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else enabled = false;
	}

	public function set_enabled(value:Bool)
	{
		enabled = value;
		shader.mult.value = [value ? 1 : 0];
		return value;
	}

	public function set_pixelAmount(value:Float)
	{
		pixelAmount = value;
		shader.uBlocksize.value = [value, value];
		return value;
	}

	public function reset()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
	}

	public function new()
	{
		reset();
		enabled = true;

		if (!PlayState.isPixelStage) pixelAmount = 1;
		else pixelAmount = PlayState.daPixelZoom;
		//trace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header

		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if (color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;

			color = mix(color, newColor, mult);

			if (color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}
