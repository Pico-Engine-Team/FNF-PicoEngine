package funkin.data.objects.game.notes;

import haxe.Json;
import funkin.data.objects.game.notes.data.Note;
import funkin.data.objects.game.notes.data.Note.NoteSkinConfig;
import funkin.data.objects.game.notes.data.Note.NoteSkinAnim;
import funkin.data.objects.game.notes.data.Note.NoteSkinUiAsset;
import funkin.data.objects.game.notes.data.Note.HoldNoteCoverConfig;
import funkin.data.objects.game.notes.data.NoteSplash;
import funkin.data.objects.game.characters.Character;

using StringTools;

/**
 * noteStyle controller — Pico Engine v2 format.
 *
 * Files:
 *   data/notestyles/<name>.json
 *   scripts/states/notestyle.lua        (preferred Lua)
 *   scripts/states/notestyle/<name>.lua
 *   data/notestyles/<name>/notestyle.json
 *   data/notestyles/<name>.lua          (legacy)
 *   pico_assets/.../custom-notes/data/<name>.json  (character styles)
 *
 * JSON v2+:
 *   noteSkin_assets.note_sprite / note_position / note_animations
 *   noteSkin_assets.hold_sprite / hold_animations (optional)
 *   noteSkin_assets.strum_sprite / strum_animations (optional)
 *   Splash_data.splash_sprite / offsets / animations
 *   noteSkin_assets.note_scale + Strumline_assets.strum_scale + Splash_data.splash_scale
 *   countdown / rating / number UI
 * Lua: scripts/states/notestyle/<name>.lua
 * Splash ONLY from notestyle (no noteSplash.json).
 */
typedef PicoNoteAnim = {
	@:optional var prefix:String;
	@:optional var fps:Null<Int>;
	@:optional var loop:Null<Bool>;
	@:optional var indices:Array<Int>;
}

typedef PicoSplashData = {
	@:optional var splash_sprite:String;
	@:optional var splash_offsets:Array<Float>;
	@:optional var splash_animations:Dynamic;
}

typedef PicoNoteSkinAssets = {
	@:optional var note_sprite:String;
	@:optional var note_position:Array<Float>;
	@:optional var note_animations:Dynamic;
}

typedef PicoNoteStyleFile = {
	@:optional var note_Name:String;
	@:optional var author:String;
	@:optional var fallback:Dynamic;
	@:optional var assets:Dynamic;
}

/** Runtime bag used by Note / NoteSplash / StrumNote / Lua */
typedef PicoNoteStyleRuntime = {
	var name:String;
	var author:String;
	var fallback:String;
	var noteSprite:String;
	var holdSprite:String;
	var strumSprite:String;
	var notePosition:Array<Float>;
	var noteAnims:Map<String, PicoNoteAnim>;
	var holdAnims:Map<String, PicoNoteAnim>;
	var strumAnims:Map<String, PicoNoteAnim>;
	var splashSprite:String;
	var splashOffsets:Array<Float>;
	var splashAnims:Map<String, Array<PicoNoteAnim>>;
	var allowRGB:Bool;
	var allowPixel:Bool;
	var noteScale:Float;
	var holdScale:Float;
	var strumScale:Float;
	var splashScale:Float;
	var uiAssets:Map<String, NoteSkinUiAsset>;
	var raw:Dynamic;
	var luaPath:String;
	var jsonPath:String;
	var psychConfig:NoteSkinConfig;
}

class NoteData
{
	public static var noteStyle(default, null):NoteStyleData = new NoteStyleData();
	public static var notestyles(default, null):NoteStyleData = noteStyle;
	public static var noteStyles(default, null):NoteStyleData = noteStyle;

	public static function songStyle(?mustPress:Bool = true):String
		return noteStyle.songStyle(mustPress);

	public static function clearCache():Void
		noteStyle.clearCache();

	/** Active runtime for current song side */
	public static function runtime(?mustPress:Bool = true):PicoNoteStyleRuntime
		return noteStyle.getRuntime(songStyle(mustPress), noteStyle.usesCharacterNoteStyle(mustPress));
}

class NoteStyleData
{
	var runtimeCache:Map<String, PicoNoteStyleRuntime> = new Map();

	public function new() {}

	public function clearCache():Void
	{
		runtimeCache = new Map();
		try
		{
			Note.noteSkinConfigs.clear();
		}
		catch(e:Dynamic) {}
	}

	// ---------- Style name resolution ----------

	public function songStyle(?mustPress:Bool = true):String
	{
		var charStyle:String = characterNoteStyleKey(mustPress);
		if(charStyle != null && charStyle.length > 0)
			return charStyle;
		var song:String = songNoteStyle();
		if(song != null && song.length > 0)
			return song;
		return defaultSongNoteStyle();
	}

	public function usesCharacterNoteStyle(mustPress:Bool):Bool
	{
		var key:String = characterNoteStyleKey(mustPress);
		return key != null && key.length > 0;
	}

	public function characterNoteStyleKey(mustPress:Bool):String
	{
		if(PlayState.instance == null) return null;
		var char:Character = mustPress ? PlayState.instance.boyfriend : PlayState.instance.dad;
		if(char == null) return null;
		var rawStyle:Dynamic = Reflect.field(char, 'noteStyle');
		if(rawStyle == null || Std.string(rawStyle).trim().length < 1)
			return null;
		try
		{
			if(Reflect.field(char, 'useNotestyle') == false)
				return null;
		}
		catch(e:Dynamic) {}
		var raw:String = Std.string(rawStyle).trim();
		var key:String = normalizeCharacterNoteStyleName(raw);
		return (key != null && key.length > 0) ? key : raw;
	}

	public function songNoteStyle():String
	{
		var skin:String = null;
		if(PlayState.SONG != null) skin = PlayState.SONG.noteStyle;
		var clean:String = normalizeSongNoteStyleName(skin);
		if(clean.length < 1 && PlayState.isPixelStage)
			clean = defaultSongNoteStyle();
		return clean;
	}

	public function defaultSongNoteStyle():String
	{
		if(PlayState.isPixelStage && textExists('data/notestyles/pixel.json'))
			return 'pixel';
		if(textExists('data/notestyles/funkin.json'))
			return 'funkin';
		if(folderStyleExists('funkin')) return 'funkin';
		return Note.defaultNoteSkin;
	}

	public function normalizeSongNoteStyleName(skin:String):String
	{
		if(skin == null) return '';
		var clean:String = skin.trim().replace('\\', '/');
		if(clean.length < 1) return '';
		var lower:String = clean.toLowerCase();
		if(lower == 'default' || lower == 'normal') return '';
		if(clean.startsWith('images/')) clean = clean.substr(7);
		if(clean.startsWith('data/notestyles/')) clean = clean.substr(16);
		if(clean.startsWith('notestyles/')) clean = clean.substr(11);
		for (ext in ['.png', '.xml', '.json', '.lua'])
			if(clean.endsWith(ext)) clean = clean.substr(0, clean.length - ext.length);
		var styleKey:String = noteStyleKey(clean);
		if(styleKey.length > 0 && (textExists('data/notestyles/' + styleKey + '.json') || folderStyleExists(styleKey)))
			return styleKey;
		return styleKey.length > 0 ? styleKey : clean;
	}

	public function normalizeCharacterNoteStyleName(skin:String):String
	{
		if(skin == null) return '';
		var clean:String = skin.trim().replace('\\', '/');
		if(clean.length < 1) return '';
		var lower:String = clean.toLowerCase();
		if(lower == 'default' || lower == 'normal') return '';
		if(clean.startsWith('game/custom-notes/data/')) clean = clean.substr(23);
		if(clean.startsWith('custom-notes/data/')) clean = clean.substr(18);
		if(clean.startsWith('data/')) clean = clean.substr(5);
		for (ext in ['.png', '.xml', '.json', '.lua'])
			if(clean.endsWith(ext)) clean = clean.substr(0, clean.length - ext.length);
		return noteStyleKey(clean);
	}

	public function noteStyleKey(value:String):String
	{
		if(value == null) return '';
		var clean:String = value.trim().replace('\\', '/');
		if(clean.indexOf('/') >= 0)
			clean = clean.substring(clean.lastIndexOf('/') + 1);
		return clean;
	}

	public function normalizeStyle(?style:String):String
	{
		if(style == null || style.trim().length < 1)
			return defaultSongNoteStyle();
		var song:String = normalizeSongNoteStyleName(style);
		if(song.length > 0) return song;
		var character:String = normalizeCharacterNoteStyleName(style);
		return character.length > 0 ? character : defaultSongNoteStyle();
	}

	// ---------- Load v2 JSON + optional .lua ----------

	public function getRuntime(style:String, fromCharacter:Bool = false):PicoNoteStyleRuntime
	{
		var key:String = normalizeStyle(style);
		var cacheKey:String = key + (fromCharacter ? '#char' : '#song');
		if(runtimeCache.exists(cacheKey))
			return runtimeCache.get(cacheKey);

		var rt:PicoNoteStyleRuntime = loadRuntime(key, fromCharacter);
		runtimeCache.set(cacheKey, rt);
		return rt;
	}

	function loadRuntime(style:String, fromCharacter:Bool):PicoNoteStyleRuntime
	{
		var rt:PicoNoteStyleRuntime = emptyRuntime(style);
		var paths = findJsonPaths(style, fromCharacter);
		var rawText:String = null;
		for (p in paths)
		{
			rawText = readText(p);
			if(rawText != null && rawText.trim().length > 0)
			{
				rt.jsonPath = p;
				break;
			}
		}

		if(rawText != null)
		{
			try
			{
				var data:Dynamic = Json.parse(rawText);
				applyJsonToRuntime(rt, data);
			}
			catch(e:Dynamic)
			{
				trace('[NoteData] parse failed ' + style + ': ' + e);
			}
		}

		// fallback merge
		if(rt.fallback != null && rt.fallback.length > 0 && rt.fallback != style)
		{
			var parent:PicoNoteStyleRuntime = getRuntime(rt.fallback, false);
			rt = mergeRuntime(parent, rt);
		}

		rt.luaPath = findLuaPath(style, fromCharacter);
		rt.psychConfig = toPsychConfig(rt);

		// Keep Note cache in sync for legacy callers
		try
		{
			if(rt.psychConfig != null)
				Note.noteSkinConfigs.set(style, rt.psychConfig);
		}
		catch(e:Dynamic) {}

		return rt;
	}

	function emptyRuntime(style:String):PicoNoteStyleRuntime
	{
		return {
			name: style,
			author: '',
			fallback: null,
			noteSprite: Note.defaultNoteSkin,
			holdSprite: null,
			strumSprite: null,
			notePosition: [0, 0],
			noteAnims: new Map(),
			holdAnims: new Map(),
			strumAnims: new Map(),
			splashSprite: null,
			splashOffsets: [0, 0],
			splashAnims: new Map(),
			allowRGB: true,
			allowPixel: false,
			noteScale: 0.7,
			holdScale: 0.7,
			strumScale: 0.7,
			splashScale: 1.0,
			uiAssets: new Map(),
			raw: null,
			luaPath: null,
			jsonPath: null,
			psychConfig: null
		};
	}

	function applyJsonToRuntime(rt:PicoNoteStyleRuntime, data:Dynamic):Void
	{
		if(data == null) return;
		rt.raw = data;

		// Detect v2 (has assets.noteSkin_assets) vs legacy
		var assets:Dynamic = Reflect.field(data, 'assets');
		if(assets != null && Reflect.hasField(assets, 'noteSkin_assets'))
		{
			if(Reflect.hasField(data, 'note_Name'))
				rt.name = Std.string(Reflect.field(data, 'note_Name'));
			if(Reflect.hasField(data, 'author'))
				rt.author = Std.string(Reflect.field(data, 'author'));
			var fb:Dynamic = Reflect.field(data, 'fallback');
			if(fb != null && Std.string(fb) != 'null' && Std.string(fb).trim().length > 0)
				rt.fallback = Std.string(fb).trim();

			parseNoteSkinAssets(rt, Reflect.field(assets, 'noteSkin_assets'));
			parseSplashData(rt, Reflect.field(assets, 'Splash_data'));
			parseUiBlocks(rt, assets);

			// Strum scale from Strumline; keep note_scale if set in noteSkin_assets
			if(rt.strumScale > 0)
			{
				if(rt.noteScale <= 0) rt.noteScale = rt.strumScale;
				if(rt.holdScale <= 0) rt.holdScale = rt.strumScale;
			}

			if(Reflect.hasField(assets, 'allowRGB'))
				rt.allowRGB = Reflect.field(assets, 'allowRGB') != false;
			if(Reflect.hasField(assets, 'allowPixel'))
				rt.allowPixel = Reflect.field(assets, 'allowPixel') == true;
			// Legacy only: top-level note_scale / hold_scale / strum_scale (prefer Strumline_assets.strum_scale)
			if(Reflect.hasField(assets, 'strum_scale'))
			{
				var ss:Float = Std.parseFloat(Std.string(Reflect.field(assets, 'strum_scale')));
				if(!Math.isNaN(ss) && ss > 0) rt.strumScale = ss;
			}
			if(Reflect.hasField(assets, 'splash_scale'))
			{
				var sps:Float = Std.parseFloat(Std.string(Reflect.field(assets, 'splash_scale')));
				if(!Math.isNaN(sps) && sps > 0) rt.splashScale = sps;
			}
			return;
		}

		// Legacy: pass through Note.getNoteSkinConfig fields if present
		try
		{
			var legacy:NoteSkinConfig = Note.getNoteSkinConfig(rt.name, false);
			if(legacy != null)
			{
				rt.psychConfig = legacy;
				if(legacy.noteAssetPath != null) rt.noteSprite = legacy.noteAssetPath;
				if(legacy.noteSplashAssetPath != null) rt.splashSprite = legacy.noteSplashAssetPath;
				rt.allowRGB = legacy.allowRGB != false;
				rt.allowPixel = legacy.allowPixel == true;
				if(legacy.noteScale > 0) rt.noteScale = legacy.noteScale;
			}
		}
		catch(e:Dynamic) {}
	}

	function parseNoteSkinAssets(rt:PicoNoteStyleRuntime, block:Dynamic):Void
	{
		if(block == null) return;

		// --- note sprite / position / animations ---
		var sprite:Dynamic = Reflect.field(block, 'note_sprite');
		if(sprite != null && Std.string(sprite).trim().length > 0)
			rt.noteSprite = cleanAssetPath(Std.string(sprite));

		var pos:Dynamic = Reflect.field(block, 'note_position');
		if(pos != null && Std.isOfType(pos, Array))
		{
			var arr:Array<Dynamic> = cast pos;
			rt.notePosition = [
				arr.length > 0 ? Std.parseFloat(Std.string(arr[0])) : 0,
				arr.length > 1 ? Std.parseFloat(Std.string(arr[1])) : 0
			];
		}

		// note_scale inside noteSkin_assets
		var nsc:Dynamic = Reflect.field(block, 'note_scale');
		if(nsc != null)
		{
			var nf:Float = Std.parseFloat(Std.string(nsc));
			if(!Math.isNaN(nf) && nf > 0)
			{
				rt.noteScale = nf;
				if(rt.holdScale <= 0) rt.holdScale = nf;
			}
		}

		parseAnimMap(rt.noteAnims, Reflect.field(block, 'note_animations'));
		if(!rt.noteAnims.keys().hasNext())
			parseAnimMap(rt.noteAnims, Reflect.field(block, 'animations'));

		// --- holdNote_assets (nested) OR flat hold_sprite / hold_animations ---
		var holdBlock:Dynamic = Reflect.field(block, 'holdNote_assets');
		if(holdBlock == null) holdBlock = Reflect.field(block, 'hold_assets');
		if(holdBlock != null)
		{
			var holdSp:Dynamic = Reflect.field(holdBlock, 'holdNote_sprite');
			if(holdSp == null) holdSp = Reflect.field(holdBlock, 'hold_sprite');
			if(holdSp != null && Std.string(holdSp).trim().length > 0)
				rt.holdSprite = cleanAssetPath(Std.string(holdSp));

			parseAnimMap(rt.holdAnims, Reflect.field(holdBlock, 'holdNote_animations'));
			if(!rt.holdAnims.keys().hasNext())
				parseAnimMap(rt.holdAnims, Reflect.field(holdBlock, 'hold_animations'));
		}
		else
		{
			var holdSp2:Dynamic = Reflect.field(block, 'hold_sprite');
			if(holdSp2 == null) holdSp2 = Reflect.field(block, 'sustain_sprite');
			if(holdSp2 != null && Std.string(holdSp2).trim().length > 0)
				rt.holdSprite = cleanAssetPath(Std.string(holdSp2));

			parseAnimMap(rt.holdAnims, Reflect.field(block, 'hold_animations'));
			if(!rt.holdAnims.keys().hasNext())
				parseAnimMap(rt.holdAnims, Reflect.field(block, 'holdNote_animations'));
		}

		// --- Strumline_assets (nested) OR flat strum_sprite / strum_animations ---
		var strumBlock:Dynamic = Reflect.field(block, 'Strumline_assets');
		if(strumBlock == null) strumBlock = Reflect.field(block, 'strumline_assets');
		if(strumBlock == null) strumBlock = Reflect.field(block, 'strum_assets');
		if(strumBlock != null)
		{
			var strumSp:Dynamic = Reflect.field(strumBlock, 'strum_sprite');
			if(strumSp == null) strumSp = Reflect.field(strumBlock, 'strumline_sprite');
			if(strumSp != null && Std.string(strumSp).trim().length > 0)
				rt.strumSprite = cleanAssetPath(Std.string(strumSp));

			var ssc:Dynamic = Reflect.field(strumBlock, 'strum_scale');
			if(ssc != null)
			{
				var sf:Float = Std.parseFloat(Std.string(ssc));
				if(!Math.isNaN(sf) && sf > 0) rt.strumScale = sf;
			}

			parseAnimMap(rt.strumAnims, Reflect.field(strumBlock, 'strum_animations'));
		}
		else
		{
			var strumSp2:Dynamic = Reflect.field(block, 'strum_sprite');
			if(strumSp2 == null) strumSp2 = Reflect.field(block, 'strumline_sprite');
			if(strumSp2 != null && Std.string(strumSp2).trim().length > 0)
				rt.strumSprite = cleanAssetPath(Std.string(strumSp2));
			parseAnimMap(rt.strumAnims, Reflect.field(block, 'strum_animations'));
		}

		// Map directional strum keys → static0/pressed0/confirm0 used by StrumNote
		normalizeStrumAnimKeys(rt);
	}

	/** leftStatic → static0, leftPress → pressed0, leftConfirm → confirm0, etc. */
	function normalizeStrumAnimKeys(rt:PicoNoteStyleRuntime):Void
	{
		if(rt == null || rt.strumAnims == null) return;
		var dirMap:Map<String, Int> = [
			'left' => 0, 'down' => 1, 'up' => 2, 'right' => 3,
			'purple' => 0, 'blue' => 1, 'green' => 2, 'red' => 3
		];
		var extra:Map<String, PicoNoteAnim> = new Map();
		for (key => anim in rt.strumAnims)
		{
			var k:String = key.toLowerCase();
			var dir:Int = -1;
			var kind:String = null; // static / pressed / confirm
			for (name => id in dirMap)
			{
				if(StringTools.startsWith(k, name))
				{
					dir = id;
					var rest:String = k.substr(name.length);
					if(rest == 'static' || rest == '') kind = 'static';
					else if(rest == 'press' || rest == 'pressed') kind = 'pressed';
					else if(rest == 'confirm' || rest == 'confirmhold') kind = 'confirm';
					break;
				}
			}
			// also static0 style already present
			if(dir < 0) continue;
			if(kind == null) continue;
			extra.set(kind + dir, anim);
		}
		for (k => v in extra)
			if(!rt.strumAnims.exists(k))
				rt.strumAnims.set(k, v);
	}

	function parseAnimMap(target:Map<String, PicoNoteAnim>, anims:Dynamic):Void
	{
		if(anims == null || target == null) return;
		for (k in Reflect.fields(anims))
		{
			var a:PicoNoteAnim = parseAnim(Reflect.field(anims, k));
			if(a != null)
				target.set(k.toLowerCase(), a);
		}
	}

	function parseSplashData(rt:PicoNoteStyleRuntime, block:Dynamic):Void
	{
		if(block == null) return;
		var sprite:Dynamic = Reflect.field(block, 'splash_sprite');
		if(sprite != null && Std.string(sprite).trim().length > 0)
			rt.splashSprite = cleanAssetPath(Std.string(sprite));

		var off:Dynamic = Reflect.field(block, 'splash_offsets');
		if(off != null && Std.isOfType(off, Array))
		{
			var arr:Array<Dynamic> = cast off;
			rt.splashOffsets = [
				arr.length > 0 ? Std.parseFloat(Std.string(arr[0])) : 0,
				arr.length > 1 ? Std.parseFloat(Std.string(arr[1])) : 0
			];
		}

		var ssc:Dynamic = Reflect.field(block, 'splash_scale');
		if(ssc != null)
		{
			var sf:Float = Std.parseFloat(Std.string(ssc));
			if(!Math.isNaN(sf) && sf > 0) rt.splashScale = sf;
		}

		var anims:Dynamic = Reflect.field(block, 'splash_animations');
		if(anims != null)
		{
			for (k in Reflect.fields(anims))
			{
				var list:Array<PicoNoteAnim> = [];
				var val:Dynamic = Reflect.field(anims, k);
				if(Std.isOfType(val, Array))
				{
					for (item in (cast val:Array<Dynamic>))
					{
						var a:PicoNoteAnim = parseAnim(item);
						if(a != null) list.push(a);
					}
				}
				else
				{
					var a2:PicoNoteAnim = parseAnim(val);
					if(a2 != null) list.push(a2);
				}
				rt.splashAnims.set(k, list);
			}
		}
	}

	function parseUiBlocks(rt:PicoNoteStyleRuntime, assets:Dynamic):Void
	{
		if(assets == null) return;

		// countdown
		for (name in ['countdownThree', 'countdownTwo', 'countdownOne', 'countdownGo'])
		{
			var block:Dynamic = Reflect.field(assets, name);
			if(block == null) continue;
			var ui:NoteSkinUiAsset = {};
			var sp:Dynamic = Reflect.field(block, 'countdown_sprite');
			if(sp != null && Std.string(sp) != 'null')
				ui.assetPath = cleanAssetPath(Std.string(sp));
			var snd:Dynamic = Reflect.field(block, 'countdown_sound');
			if(snd != null) ui.audioPath = Std.string(snd);
			if(Reflect.hasField(block, 'scale'))
				ui.scale = Std.parseFloat(Std.string(Reflect.field(block, 'scale')));
			rt.uiAssets.set(name, ui);
		}

		// ratings
		for (name in ['rating_marvelous', 'rating_perfect', 'rating_sick', 'rating_good', 'rating_bad', 'rating_shit'])
		{
			var block:Dynamic = Reflect.field(assets, name);
			if(block == null) continue;
			var ui:NoteSkinUiAsset = {};
			var sp:Dynamic = Reflect.field(block, 'rating_sprite');
			if(sp != null) ui.assetPath = cleanAssetPath(Std.string(sp));
			if(Reflect.hasField(block, 'rating_scale'))
				ui.scale = Std.parseFloat(Std.string(Reflect.field(block, 'rating_scale')));
			rt.uiAssets.set(name, ui);
			// also short keys: marvelous, sick...
			var short:String = name.substr('rating_'.length);
			rt.uiAssets.set(short, ui);
		}

		// combo numbers
		for (i in 0...10)
		{
			var name:String = 'number' + i;
			var block:Dynamic = Reflect.field(assets, name);
			if(block == null) continue;
			var ui:NoteSkinUiAsset = {};
			var sp:Dynamic = Reflect.field(block, 'combo_sprite');
			if(sp != null) ui.assetPath = cleanAssetPath(Std.string(sp));
			if(Reflect.hasField(block, 'combo_scale'))
				ui.scale = Std.parseFloat(Std.string(Reflect.field(block, 'combo_scale')));
			if(Reflect.hasField(block, 'combo_hidden'))
				ui.hidden = Reflect.field(block, 'combo_hidden') == true;
			rt.uiAssets.set(name, ui);
			rt.uiAssets.set('comboNumber' + i, ui);
		}
	}

	function parseAnim(v:Dynamic):PicoNoteAnim
	{
		if(v == null) return null;
		if(Std.isOfType(v, String))
			return {prefix: Std.string(v), fps: 24, loop: false};
		var prefix:Dynamic = Reflect.field(v, 'prefix');
		if(prefix == null || Std.string(prefix).trim().length < 1)
			return null;
		var anim:PicoNoteAnim = {prefix: Std.string(prefix)};
		if(Reflect.hasField(v, 'fps'))
			anim.fps = Std.parseInt(Std.string(Reflect.field(v, 'fps')));
		if(Reflect.hasField(v, 'loop'))
			anim.loop = Reflect.field(v, 'loop') == true;
		if(Reflect.hasField(v, 'indices') && Std.isOfType(Reflect.field(v, 'indices'), Array))
			anim.indices = cast Reflect.field(v, 'indices');
		return anim;
	}

	function mergeRuntime(parent:PicoNoteStyleRuntime, child:PicoNoteStyleRuntime):PicoNoteStyleRuntime
	{
		if(parent == null) return child;
		if(child == null) return parent;
		if(child.noteSprite == null || child.noteSprite.length < 1 || child.noteSprite == Note.defaultNoteSkin)
			child.noteSprite = parent.noteSprite;
		if(child.holdSprite == null || child.holdSprite.length < 1)
			child.holdSprite = parent.holdSprite;
		if(child.strumSprite == null || child.strumSprite.length < 1)
			child.strumSprite = parent.strumSprite;
		if(child.splashSprite == null || child.splashSprite.length < 1)
			child.splashSprite = parent.splashSprite;
		for (k => v in parent.noteAnims)
			if(!child.noteAnims.exists(k)) child.noteAnims.set(k, v);
		for (k => v in parent.holdAnims)
			if(!child.holdAnims.exists(k)) child.holdAnims.set(k, v);
		for (k => v in parent.strumAnims)
			if(!child.strumAnims.exists(k)) child.strumAnims.set(k, v);
		for (k => v in parent.splashAnims)
			if(!child.splashAnims.exists(k)) child.splashAnims.set(k, v);
		for (k => v in parent.uiAssets)
			if(!child.uiAssets.exists(k)) child.uiAssets.set(k, v);
		return child;
	}

	/** Map v2 runtime → Psych NoteSkinConfig for Note.reloadNote compatibility */
	function toPsychConfig(rt:PicoNoteStyleRuntime):NoteSkinConfig
	{
		var cfg:Dynamic = {};
		cfg.noteAssetPath = rt.noteSprite;
		cfg.holdAssetPath = (rt.holdSprite != null && rt.holdSprite.length > 0) ? rt.holdSprite : rt.noteSprite;
		cfg.strumAssetPath = (rt.strumSprite != null && rt.strumSprite.length > 0) ? rt.strumSprite : rt.noteSprite;
		cfg.noteSplashAssetPath = rt.splashSprite;
		cfg.allowRGB = rt.allowRGB;
		cfg.allowPixel = rt.allowPixel;
		cfg.scale = rt.noteScale;
		cfg.noteScale = rt.noteScale;
		cfg.holdScale = rt.holdScale > 0 ? rt.holdScale : rt.noteScale;
		cfg.strumScale = rt.strumScale > 0 ? rt.strumScale : rt.noteScale;
		cfg.pixelNoteScale = rt.noteScale;
		cfg.pixelHoldScale = rt.holdScale > 0 ? rt.holdScale : rt.noteScale;
		cfg.pixelStrumScale = rt.strumScale > 0 ? rt.strumScale : rt.noteScale;
		cfg.animations = new Map<String, NoteSkinAnim>();
		cfg.uiAssets = rt.uiAssets;

		var mapDir:Map<String, String> = [
			'left' => 'purple', 'down' => 'blue', 'up' => 'green', 'right' => 'red',
			'purple' => 'purple', 'blue' => 'blue', 'green' => 'green', 'red' => 'red'
		];

		for (dir => anim in rt.noteAnims)
		{
			var base:String = mapDir.exists(dir) ? mapDir.get(dir) : dir;
			var na:NoteSkinAnim = {prefix: anim.prefix, fps: anim.fps, loop: anim.loop, indices: anim.indices};
			cfg.animations.set(base + 'Scroll', na);
			cfg.animations.set(dir + 'Scroll', na);
			cfg.animations.set(base, na);
		}

		// hold / sustain anims
		for (dir => anim in rt.holdAnims)
		{
			var base:String = mapDir.exists(dir) ? mapDir.get(dir) : dir;
			var na:NoteSkinAnim = {prefix: anim.prefix, fps: anim.fps, loop: anim.loop == null ? true : anim.loop, indices: anim.indices};
			var key:String = dir.toLowerCase();
			if(key.indexOf('end') >= 0 || key.indexOf('holdend') >= 0)
			{
				cfg.animations.set(base + 'holdend', na);
				cfg.animations.set(dir, na);
			}
			else
			{
				cfg.animations.set(base + 'hold', na);
				cfg.animations.set(dir, na);
			}
		}

		// strum static / pressed / confirm
		for (key => anim in rt.strumAnims)
		{
			var na:NoteSkinAnim = {prefix: anim.prefix, fps: anim.fps, loop: anim.loop, indices: anim.indices};
			cfg.animations.set(key, na);
			cfg.animations.set(key.toLowerCase(), na);
		}

		return cast cfg;
	}

	// ---------- Public API used by Note / NoteSplash / Lua ----------

	public function getNoteSkinConfig(style:String, fromCharacter:Bool = false):NoteSkinConfig
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style, fromCharacter);
		return rt != null ? rt.psychConfig : null;
	}

	public function getSongNoteSkinConfig():NoteSkinConfig
		return getNoteSkinConfig(songNoteStyle().length > 0 ? songNoteStyle() : defaultSongNoteStyle(), false);

	public function config(?style:String, ?fromCharacter:Null<Bool> = null):NoteSkinConfig
		return getNoteSkinConfig(normalizeStyle(style), fromCharacter == true);

	public function psychTexture(?texture:String, ?mustPress:Bool = true):String
	{
		if(texture != null && texture.trim().length > 0)
			return texture.trim();
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(mustPress), usesCharacterNoteStyle(mustPress));
		if(rt != null && rt.noteSprite != null && rt.noteSprite.length > 0)
			return rt.noteSprite;
		return songStyle(mustPress);
	}

	public function noteSprite(?style:String, ?mustPress:Bool = true):String
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		return rt != null ? rt.noteSprite : Note.defaultNoteSkin;
	}

	public function noteAnim(direction:String, ?style:String, ?mustPress:Bool = true):PicoNoteAnim
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt == null) return null;
		var key:String = direction.toLowerCase();
		if(rt.noteAnims.exists(key)) return rt.noteAnims.get(key);
		// Psych color alias
		var aliases:Map<String, String> = [
			'purple' => 'left', 'blue' => 'down', 'green' => 'up', 'red' => 'right',
			'0' => 'left', '1' => 'down', '2' => 'up', '3' => 'right'
		];
		if(aliases.exists(key) && rt.noteAnims.exists(aliases.get(key)))
			return rt.noteAnims.get(aliases.get(key));
		return null;
	}

	public function noteSplash(?style:String, ?mustPress:Bool = true):String
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt != null && rt.splashSprite != null && rt.splashSprite.length > 0)
			return rt.splashSprite;
		// NO noteSplash.json — fallback default atlas name only
		try
		{
			return NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		}
		catch(e:Dynamic)
		{
			return 'noteSplashes';
		}
	}

	public function splashOffsets(?style:String, ?mustPress:Bool = true):Array<Float>
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		return (rt != null && rt.splashOffsets != null) ? rt.splashOffsets : [0, 0];
	}

	public function splashAnims(directionKey:String, ?style:String, ?mustPress:Bool = true):Array<PicoNoteAnim>
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt == null) return [];
		if(rt.splashAnims.exists(directionKey))
			return rt.splashAnims.get(directionKey);
		// try upSplashes from "up"
		var alt:String = directionKey;
		if(!StringTools.endsWith(alt.toLowerCase(), 'splashes'))
			alt = directionKey + 'Splashes';
		if(rt.splashAnims.exists(alt))
			return rt.splashAnims.get(alt);
		return [];
	}

	public function songSplashSkinForMustPress(mustPress:Bool):Null<String>
		return noteSplash(null, mustPress);

	public function allowRGB(?style:String):Bool
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(true));
		return rt == null || rt.allowRGB;
	}

	public function allowPixel(?style:String):Bool
	{
		var rt:PicoNoteStyleRuntime = getRuntime(style != null ? style : songStyle(true));
		return rt != null && rt.allowPixel;
	}

	public function noteStyleUsesPixel(?cfg:NoteSkinConfig = null, ?mustPress:Null<Bool> = null):Bool
	{
		if(cfg != null) return cfg.allowPixel == true;
		return allowPixel(mustPress != null ? songStyle(mustPress) : null);
	}

	public function noteScale(?style:String, fallback:Float = 0.7):Float
	{
		// Prefer noteSkin_assets.note_scale, then strum_scale
		var rt = getRuntime(style != null ? style : songStyle(true));
		if(rt == null) return fallback;
		if(rt.noteScale > 0) return rt.noteScale;
		if(rt.strumScale > 0) return rt.strumScale;
		return fallback;
	}

	public function ui(assetName:String, fallback:String):String
	{
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(true));
		if(rt != null && rt.uiAssets.exists(assetName))
		{
			var a:NoteSkinUiAsset = rt.uiAssets.get(assetName);
			if(a != null && a.assetPath != null && a.assetPath.length > 0)
				return a.assetPath;
		}
		return fallback;
	}

	public function uiSound(assetName:String, fallback:String):String
	{
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(true));
		if(rt != null && rt.uiAssets.exists(assetName))
		{
			var a:NoteSkinUiAsset = rt.uiAssets.get(assetName);
			if(a != null && a.audioPath != null && a.audioPath.length > 0)
				return a.audioPath;
		}
		return fallback;
	}

	public function uiScale(assetName:String, fallback:Float):Float
	{
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(true));
		if(rt != null && rt.uiAssets.exists(assetName))
		{
			var a:NoteSkinUiAsset = rt.uiAssets.get(assetName);
			if(a != null && a.scale != null) return a.scale;
		}
		return fallback;
	}

	public function uiIsPixel(assetName:String, fallback:Bool):Bool
	{
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(true));
		if(rt != null && rt.uiAssets.exists(assetName))
		{
			var a:NoteSkinUiAsset = rt.uiAssets.get(assetName);
			if(a != null && a.isPixel != null) return a.isPixel;
		}
		return fallback;
	}

	public function uiHidden(assetName:String):Bool
	{
		var rt:PicoNoteStyleRuntime = getRuntime(songStyle(true));
		if(rt != null && rt.uiAssets.exists(assetName))
		{
			var a:NoteSkinUiAsset = rt.uiAssets.get(assetName);
			return a != null && a.hidden == true;
		}
		return false;
	}

	public function getLuaPath(?style:String, ?mustPress:Bool = true):String
	{
		var name:String = style != null ? normalizeStyle(style) : songStyle(mustPress);
		return findLuaPath(name, style == null && usesCharacterNoteStyle(mustPress));
	}

	public function hasLua(?style:String, ?mustPress:Bool = true):Bool
		return getLuaPath(style, mustPress) != null;

	// ---------- Note / Strum / Hold assets ----------

	public function note(?style:String, ?pixel:Bool = false):String
	{
		var rt = getRuntime(normalizeStyle(style));
		if(rt != null && rt.noteSprite != null && rt.noteSprite.length > 0)
			return rt.noteSprite;
		return asset(style, pixel ? 'notePixel' : 'note');
	}

	public function holdNote(?style:String, ?pixel:Bool = false):String
	{
		var rt = getRuntime(normalizeStyle(style));
		if(rt != null && rt.holdSprite != null && rt.holdSprite.length > 0)
			return rt.holdSprite;
		if(rt != null && rt.noteSprite != null && rt.noteSprite.length > 0)
			return rt.noteSprite;
		return asset(style, pixel ? 'holdNotePixel' : 'holdNote');
	}

	public function noteStrumline(?style:String, ?pixel:Bool = false):String
	{
		var rt = getRuntime(normalizeStyle(style));
		if(rt != null && rt.strumSprite != null && rt.strumSprite.length > 0)
			return rt.strumSprite;
		if(rt != null && rt.noteSprite != null && rt.noteSprite.length > 0)
			return rt.noteSprite;
		return asset(style, pixel ? 'noteStrumlinePixel' : 'noteStrumline');
	}

	public function strumAnim(key:String, ?style:String, ?mustPress:Bool = true):PicoNoteAnim
	{
		var rt = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt == null || key == null) return null;
		var k:String = key.toLowerCase();
		if(rt.strumAnims.exists(k)) return rt.strumAnims.get(k);
		return null;
	}

	public function holdAnim(key:String, ?style:String, ?mustPress:Bool = true):PicoNoteAnim
	{
		var rt = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt == null || key == null) return null;
		var k:String = key.toLowerCase();
		if(rt.holdAnims.exists(k)) return rt.holdAnims.get(k);
		return null;
	}

	public function holdScale(?style:String, fallback:Float = 0.7):Float
	{
		var rt = getRuntime(style != null ? style : songStyle(true));
		if(rt != null && rt.holdScale > 0) return rt.holdScale;
		return noteScale(style, fallback);
	}

	public function strumScale(?style:String, fallback:Float = 0.7):Float
	{
		var rt = getRuntime(style != null ? style : songStyle(true));
		return (rt != null && rt.strumScale > 0) ? rt.strumScale : fallback;
	}

	public function splashScale(?style:String, fallback:Float = 1.0):Float
	{
		var rt = getRuntime(style != null ? style : songStyle(true));
		return (rt != null && rt.splashScale > 0) ? rt.splashScale : fallback;
	}

	/** Force reload a style from disk (editors / hot reload). */
	public function reloadStyle(style:String, fromCharacter:Bool = false):PicoNoteStyleRuntime
	{
		var key:String = normalizeStyle(style);
		var cacheKey:String = key + (fromCharacter ? '#char' : '#song');
		runtimeCache.remove(cacheKey);
		return getRuntime(key, fromCharacter);
	}

	/** Debug helper: summarize loaded style. */
	public function describeStyle(?style:String, ?mustPress:Bool = true):String
	{
		var rt = getRuntime(style != null ? style : songStyle(mustPress),
			style == null && usesCharacterNoteStyle(mustPress));
		if(rt == null) return 'null';
		var animN:Int = 0;
		for (k in rt.noteAnims.keys()) animN++;
		var splashN:Int = 0;
		for (k in rt.splashAnims.keys()) splashN++;
		return '[style=${rt.name} sprite=${rt.noteSprite} hold=${rt.holdSprite} strum=${rt.strumSprite} '
			+ 'splash=${rt.splashSprite} anims=$animN splashDirs=$splashN rgb=${rt.allowRGB} pixel=${rt.allowPixel} '
			+ 'scale=${rt.noteScale} lua=${rt.luaPath} json=${rt.jsonPath}]';
	}

	public function asset(?style:String, assetType:String):String
	{
		var resolvedStyle:String = normalizeStyle(style);
		var cfg:NoteSkinConfig = getNoteSkinConfig(resolvedStyle, false);
		try
		{
			var r:String = Note.resolveNoteSkinAsset(resolvedStyle, cfg, assetType);
			if(r != null && r.length > 0) return r;
		}
		catch(e:Dynamic) {}
		if(assetType != null && assetType.indexOf('Pixel') >= 0)
			return 'noteSkins/pixel/NOTE_assets';
		return Note.defaultNoteSkin;
	}

	public function holdNoteCover(?style:String, noteData:Int = 0):String
	{
		try
		{
			return Note.resolveHoldNoteCoverAsset(config(style), noteData);
		}
		catch(e:Dynamic)
		{
			return null;
		}
	}

	public function holdNoteCoverEnabled(?style:String):Bool
	{
		try
		{
			return Note.holdNoteCoverEnabled(config(style));
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	public function holdNoteCoverScale(?style:String):Float
	{
		try
		{
			return Note.holdNoteCoverScale(config(style));
		}
		catch(e:Dynamic)
		{
			return 1;
		}
	}

	public function holdNoteCoverIsPixel(?style:String):Bool
	{
		try
		{
			return Note.holdNoteCoverIsPixel(config(style));
		}
		catch(e:Dynamic)
		{
			return false;
		}
	}

	public function holdNoteCoverColumns(?style:String):Int
	{
		try
		{
			return Note.holdNoteCoverColumns(config(style));
		}
		catch(e:Dynamic)
		{
			return 4;
		}
	}

	public function holdNoteCoverRows(?style:String):Int
	{
		try
		{
			return Note.holdNoteCoverRows(config(style));
		}
		catch(e:Dynamic)
		{
			return 2;
		}
	}

	public function holdNoteCoverOffset(?style:String):Array<Float>
	{
		try
		{
			return Note.holdNoteCoverOffset(config(style));
		}
		catch(e:Dynamic)
		{
			return [0, 0];
		}
	}

	public function holdNoteCoverCenterOnStrum(?style:String):Bool
	{
		try
		{
			return Note.holdNoteCoverCenterOnStrum(config(style));
		}
		catch(e:Dynamic)
		{
			return true;
		}
	}

	// ---------- path helpers ----------

	function findJsonPaths(style:String, fromCharacter:Bool):Array<String>
	{
		var list:Array<String> = [];
		if(fromCharacter)
		{
			try
			{
				list.push(Paths.getPicoFunkinFolder('game/custom-notes/data/' + style + '.json'));
			}
			catch(e:Dynamic) {}
			list.push('pico_assets/game/custom-notes/data/' + style + '.json');
			list.push('custom-notes/data/' + style + '.json');
		}
		list.push('data/notestyles/' + style + '.json');
		list.push('data/notestyles/' + style + '/notestyle.json');
		list.push('data/notestyles/' + style + '/notes.json');
		list.push('shared/data/notestyles/' + style + '.json');
		return list;
	}

	/**
	 * notestyle.lua load order:
	 *   1) scripts/states/notestyle/<style>.lua   ← Nome_da_nota (principal)
	 *   2) mods/.../scripts/states/notestyle/<style>.lua
	 *   3) data/notestyles/<style>.lua            (legacy)
	 *   4) character custom-notes .lua
	 */
	function findLuaPath(style:String, fromCharacter:Bool):String
	{
		if(style == null || style.length < 1)
			return null;

		var styleKey:String = noteStyleKey(style);
		var ordered:Array<String> = [];

		// 1) Principal: scripts/states/notestyle/Nome_da_nota.lua
		ordered.push('scripts/states/notestyle/' + styleKey + '.lua');

		#if MODS_ALLOWED
		try
		{
			var mod:String = Mods.currentModDirectory;
			if(mod != null && mod.length > 0)
				ordered.push(Paths.mods(mod + '/scripts/states/notestyle/' + styleKey + '.lua'));
			for (m in Mods.parseList().enabled)
				ordered.push(Paths.mods(m + '/scripts/states/notestyle/' + styleKey + '.lua'));
		}
		catch(e:Dynamic) {}
		#end

		// 2) Legacy next to JSON
		ordered.push('data/notestyles/' + styleKey + '.lua');
		ordered.push('data/notestyles/' + styleKey + '/notestyle.lua');
		ordered.push('data/notestyles/' + styleKey + '/script.lua');

		// 3) Character pico custom-notes
		if(fromCharacter)
		{
			ordered.push('pico_assets/game/custom-notes/data/' + styleKey + '.lua');
			ordered.push('custom-notes/data/' + styleKey + '.lua');
		}

		for (p in ordered)
		{
			if(p == null || p.length < 1) continue;
			if(textExists(p)) return p;
		}
		#if sys
		for (p in ordered)
		{
			if(p == null) continue;
			try
			{
				if(sys.FileSystem.exists(p))
					return p;
			}
			catch(e:Dynamic) {}
			try
			{
				var full:String = Paths.getPath(p, TEXT);
				if(full != null && sys.FileSystem.exists(full)) return full;
			}
			catch(e:Dynamic) {}
		}
		#end
		return null;
	}

	function folderStyleExists(style:String):Bool
		return textExists('data/notestyles/' + style + '/notestyle.json');

	function cleanAssetPath(path:String):String
	{
		if(path == null) return '';
		var p:String = path.trim().replace('\\', '/');
		if(p.startsWith('images/')) p = p.substr(7);
		if(p.startsWith('assets/images/')) p = p.substr(14);
		for (ext in ['.png', '.xml'])
			if(p.toLowerCase().endsWith(ext))
				p = p.substr(0, p.length - ext.length);
		return p;
	}

	function textExists(key:String):Bool
	{
		try
		{
			if(Paths.fileExists(key, TEXT))
				return true;
		}
		catch(e:Dynamic) {}
		#if sys
		try
		{
			if(sys.FileSystem.exists(key))
				return true;
		}
		catch(e:Dynamic) {}
		#end
		return false;
	}

	function readText(path:String):String
	{
		if(path == null) return null;
		#if sys
		try
		{
			if(sys.FileSystem.exists(path))
				return sys.io.File.getContent(path);
		}
		catch(e:Dynamic) {}
		#end
		try
		{
			if(Paths.fileExists(path, TEXT))
				return Paths.getTextFromFile(path);
		}
		catch(e:Dynamic) {}
		#if sys
		try
		{
			var full:String = Paths.getPath(path, TEXT);
			if(full != null && sys.FileSystem.exists(full))
				return sys.io.File.getContent(full);
		}
		catch(e:Dynamic) {}
		#end
		return null;
	}
}
