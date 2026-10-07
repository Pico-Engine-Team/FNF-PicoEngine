package funkin.utils;

#if MODS_ALLOWED
import funkin.modding.Mods;
#end

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;
import haxe.Json;

#if flxanimate
import flxanimate.frames.FlxAnimateFrames;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/menu/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static var tempFramesCache:Map<String, FlxAtlasFrames> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function clearTempFramesCache():Void
	{
		if (tempFramesCache == null) return;
		
		var count = 0;
		for (key => frames in tempFramesCache)
		{
			if (frames != null && frames.parent != null)
			{
				frames.parent.persist = false;
				frames.parent.destroyOnNoUse = true;
				count++;
			}
		}
		
		tempFramesCache.clear();
		
		if (count > 0)
			trace('[Paths] Cleared $count temporary frames from cache');
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	/**
	 * When set (e.g. "data/extra-songs"), inst/voices load from:
	 *   assets/<songAudioRoot>/<song>/song/Inst.ogg
	 * instead of assets/songs/<song>/song/Inst.ogg
	 * Clear with Paths.songAudioRoot = null after leaving extra freeplay.
	 */
	public static var songAudioRoot:String = null;

	/**
	 * Audio suffixes from meta.json (may include leading "-").
	 * Examples: "-pico", "-bf", "-erect"
	 * Inst → song/Inst-pico.ogg
	 * Voices → song/Voices-bf.ogg
	 */
	public static var instSuffix:String = null;
	public static var vocalsSuffix:String = null;
	public static var vocalPlayerSuffix:String = null;
	public static var vocalOpponentSuffix:String = null;

	public static function clearAudioSuffixes():Void
	{
		instSuffix = null;
		vocalsSuffix = null;
		vocalPlayerSuffix = null;
		vocalOpponentSuffix = null;
	}

	public static function applyAudioSuffixesFromMeta(meta:Dynamic):Void
	{
		clearAudioSuffixes();
		if (meta == null) return;
		try
		{
			instSuffix = normalizeAudioSuffix(Reflect.field(meta, 'instSuffix'));
			vocalsSuffix = normalizeAudioSuffix(Reflect.field(meta, 'vocalsSuffix'));
			vocalPlayerSuffix = normalizeAudioSuffix(Reflect.field(meta, 'vocalPlayerSuffix'));
			vocalOpponentSuffix = normalizeAudioSuffix(Reflect.field(meta, 'vocalOpponentSuffix'));
		}
		catch (e:Dynamic) {}
	}

	public static function applyAudioSuffixesFromSong(song:Dynamic):Void
	{
		clearAudioSuffixes();
		if (song == null) return;
		try
		{
			instSuffix = normalizeAudioSuffix(Reflect.field(song, 'instSuffix'));
			vocalsSuffix = normalizeAudioSuffix(Reflect.field(song, 'vocalsSuffix'));
			vocalPlayerSuffix = normalizeAudioSuffix(Reflect.field(song, 'vocalPlayerSuffix'));
			vocalOpponentSuffix = normalizeAudioSuffix(Reflect.field(song, 'vocalOpponentSuffix'));
		}
		catch (e:Dynamic) {}
	}

	/** Accepts "pico", "-pico", "Pico" → "-pico" (always leading dash when non-empty) */
	public static function normalizeAudioSuffix(value:Dynamic):String
	{
		if (value == null) return null;
		var s:String = Std.string(value).trim();
		if (s.length < 1) return null;
		var low:String = s.toLowerCase();
		if (low == 'default' || low == 'none' || low == 'null') return null;
		// strip leading dashes then re-add one
		while (StringTools.startsWith(s, '-'))
			s = s.substr(1);
		s = formatToSongPath(s);
		if (s.length < 1) return null;
		return '-' + s;
	}

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline static public function getPicoFunkinFolder(file:String, folder = "pico_assets")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	static public function normalizeAssetPath(path:String):String
	{
		var clean:String = path == null ? '' : path.trim().split('\\').join('/');
		var colon:Int = clean.indexOf(':');
		if(colon > -1 && clean.substr(0, colon).indexOf('/') < 0)
			clean = clean.substr(colon + 1);

		while (clean.startsWith('/'))
			clean = clean.substr(1);
		while (clean.endsWith('/'))
			clean = clean.substr(0, clean.length - 1);
		return clean;
	}

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	/**
	 * Chart JSON path.
	 * NEW: assets/songs/<song>/charts/<file>.json
	 * key examples: "bopeebo/bopeebo-hard", "bopeebo/bopeebo"
	 * parent library folder is "songs" → assets/songs/...
	 */
	inline static public function chartJson(key:String, ?folder:String)
	{
		var clean:String = key == null ? '' : key.replace('\\', '/');
		while (clean.startsWith('/')) clean = clean.substr(1);
		if (clean.endsWith('.json'))
			clean = clean.substr(0, clean.length - 5);

		var parts:Array<String> = clean.split('/');
		var songFolder:String;
		var chartFile:String;
		if (parts.length >= 2)
		{
			songFolder = formatToSongPath(parts[0]);
			chartFile = formatToSongPath(parts[parts.length - 1]);
		}
		else
		{
			songFolder = formatToSongPath(clean);
			chartFile = songFolder;
		}

		// assets/songs/<song>/charts/<file>.json
		return getPath(songFolder + '/charts/' + chartFile + '.json', TEXT, 'songs', true);
	}

	/** Legacy Psych path: assets/shared/data/songs/<key>.json (fallback helper) */
	inline static public function chartJsonLegacy(key:String, ?folder:String)
		return getPath('data/songs/$key.json', TEXT, folder, true);

	/**
	 * Extra freeplay chart:
	 *   assets/data/extra-songs/<song>/<file>.json
	 * key: "lo-fight/lo-fight-hard-extra" or "lo-fight-hard-extra" (folder inferred)
	 */
	inline static public function extraSongsChartJson(key:String, ?modFolder:String)
	{
		var clean:String = key == null ? '' : key.replace('\\', '/');
		while (clean.startsWith('/')) clean = clean.substr(1);
		if (clean.endsWith('.json'))
			clean = clean.substr(0, clean.length - 5);

		var parts:Array<String> = clean.split('/');
		var songFolder:String;
		var chartFile:String;
		if (parts.length >= 2)
		{
			songFolder = formatToSongPath(parts[0]);
			chartFile = formatToSongPath(parts[parts.length - 1]);
		}
		else
		{
			songFolder = formatToSongPath(clean);
			chartFile = songFolder;
		}

		// assets/data/extra-songs/<song>/<file>.json
		return getPath('extra-songs/' + songFolder + '/' + chartFile + '.json', TEXT, 'data', true);
	}

	inline static public function extraSongsJson(key:String, ?folder:String)
		return chartJson(key, folder);

	inline static public function songMetadataJson(key:String, ?folder:String)
		return chartJson(key, folder);
	
	inline static public function notestyleJson(key:String, ?folder:String)
		return getPath('data/notestyles/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

	/**
	 * Instrumental — assets/songs/<song>/song/Inst.ogg
	 * Falls back to assets/songs/<song>/Inst.ogg (legacy Psych)
	 * If Paths.songAudioRoot is set (extra freeplay): assets/<root>/<song>/song/Inst.ogg
	 */
	/**
	 * Instrumental — assets/songs/<song>/song/Inst.ogg
	 * With meta instSuffix "-pico" → song/Inst-pico.ogg
	 * Falls back to assets/songs/<song>/Inst.ogg (legacy)
	 * Extra freeplay: Paths.songAudioRoot (e.g. data/extra-songs)
	 */
	static public function inst(song:String, ?modsAllowed:Bool = true):Sound
	{
		var key:String = formatToSongPath(song);
		var library:String = (songAudioRoot != null && songAudioRoot.length > 0) ? songAudioRoot : 'songs';
		var suffix:String = instSuffix; // already "-pico" or null

		if (suffix != null && suffix.length > 0)
		{
			var withSuf:String = key + '/song/Inst' + suffix;
			if (soundAssetExists(withSuf, library, modsAllowed))
				return returnSound(withSuf, library, modsAllowed);
			var legacySuf:String = key + '/Inst' + suffix;
			if (soundAssetExists(legacySuf, library, modsAllowed))
				return returnSound(legacySuf, library, modsAllowed);
		}

		var nested:String = key + '/song/Inst';
		if (soundAssetExists(nested, library, modsAllowed))
			return returnSound(nested, library, modsAllowed);
		return returnSound(key + '/Inst', library, modsAllowed);
	}

	/**
	 * Voices — assets/songs/<song>/song/Voices.ogg
	 * Falls back to assets/songs/<song>/Voices.ogg (legacy Psych)
	 * If Paths.songAudioRoot is set: assets/<root>/<song>/song/Voices.ogg
	 */
	/**
	 * Voices — assets/songs/<song>/song/Voices.ogg
	 * postfix / meta suffixes already include or omit "-":
	 *   vocalPlayerSuffix "-bf" → Voices-bf.ogg
	 *   vocalsSuffix "-erect" → Voices-erect.ogg
	 * Call sites may pass "Player"/"Opponent"/"bf"; meta suffixes preferred when set.
	 */
	static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var key:String = formatToSongPath(song);
		var library:String = (songAudioRoot != null && songAudioRoot.length > 0) ? songAudioRoot : 'songs';

		var trySuffixes:Array<String> = [];
		function pushSuf(raw:String)
		{
			var n:String = normalizeAudioSuffix(raw);
			if (n != null && !trySuffixes.contains(n))
				trySuffixes.push(n);
		}

		// Explicit postfix from caller
		if (postfix != null && postfix.length > 0)
		{
			pushSuf(postfix);
			var pl:String = postfix.toLowerCase();
			if (pl == 'player' || pl == 'bf')
				pushSuf(vocalPlayerSuffix);
			else if (pl == 'opponent' || pl == 'dad')
				pushSuf(vocalOpponentSuffix);
		}
		else
		{
			pushSuf(vocalPlayerSuffix);
			pushSuf(vocalOpponentSuffix);
			pushSuf(vocalsSuffix);
		}
		pushSuf(vocalsSuffix);

		for (suf in trySuffixes)
		{
			var nested:String = key + '/song/Voices' + suf;
			if (soundAssetExists(nested, library, modsAllowed))
				return returnSound(nested, library, modsAllowed, false);
			var legacy:String = key + '/Voices' + suf;
			if (soundAssetExists(legacy, library, modsAllowed))
				return returnSound(legacy, library, modsAllowed, false);
		}

		var plain:String = key + '/song/Voices';
		if (soundAssetExists(plain, library, modsAllowed))
			return returnSound(plain, library, modsAllowed, false);
		return returnSound(key + '/Voices', library, modsAllowed, false);
	}

	static function soundAssetExists(keyNoExt:String, library:String, modsAllowed:Bool):Bool
	{
		var path:String = getPath(keyNoExt + '.$SOUND_EXT', SOUND, library, modsAllowed);
		#if sys
		if (FileSystem.exists(path)) return true;
		#end
		try
		{
			return OpenFlAssets.exists(path, SOUND);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = normalizeAssetPath(key);
		key = Language.getFileTranslation('images/$key') + '.png';
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, parentFolder, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if (allowGPU && Preferences.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, null, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		key = normalizeAssetPath(key);
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);

		var myXml:Dynamic = getPath('images/$key.xml', TEXT, parentFolder, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, parentFolder, true);
			if(OpenFlAssets.exists(myJson) #if MODS_ALLOWED || (FileSystem.exists(myJson) && (useMod = true)) #end )
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (useMod ? File.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, myJson);
				#end
			}
		}
		return getPackerAtlas(key, parentFolder);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		key = normalizeAssetPath(key);
		if(key.contains('psychic')) trace(key, parentFolder, allowGPU);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		key = normalizeAssetPath(key);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		key = normalizeAssetPath(key);
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	/** Root folder for user mods: content/mods/<modName>/ (was example_content/example_mods or mods/) */
	public static inline var MODS_ROOT:String = 'content/mods/';

	inline static public function mods(key:String = '')
	{
		if(key == null || key.length < 1)
			return MODS_ROOT;
		return MODS_ROOT + key;
	}

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	/** Path to the enabled/disabled mods list file */
	inline static public function modsListFile():String
		return 'content/modsList.txt';

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return mods(key);
	}
	#end

	#if flxanimate
	public static final animateAtlasSubfolders:Array<String> =
	[
		'basic-animations',
		'playable-animations',
		'death',
		'basic',
		'playable',
		'car',
		'dark'
	];

	public static function getAnimateAtlasFolders(folderOrImg:String):Array<String>
	{
		var folders:Array<String> = [];
		if (folderOrImg == null)
			return folders;

		for (path in folderOrImg.split(','))
		{
			var clean:String = normalizeAssetFolder(path);
			if (clean.length < 1)
				continue;

			addAnimateAtlasFolder(folders, clean);

			for (subfolder in animateAtlasSubfolders)
				addAnimateAtlasFolder(folders, '$clean/$subfolder');
		}

		return folders;
	}

	public static function hasAnimateAtlas(folderOrImg:String):Bool
	{
		return getAnimateAtlasFolders(folderOrImg).length > 0;
	}

	public static function getAnimateAtlasImageKeys(folderOrImg:String):Array<String>
	{
		var keys:Array<String> = [];
		for (folder in getAnimateAtlasFolders(folderOrImg))
		{
			for (i in 0...10)
			{
				var st:String = i == 0 ? '' : '$i';
				var imageKey:String = '$folder/spritemap$st';
				if (fileExists('images/$imageKey.png', IMAGE) && !keys.contains(imageKey))
					keys.push(imageKey);
			}
		}
		return keys;
	}

	static function addAnimateAtlasFolder(folders:Array<String>, folder:String):Void
	{
		if (folder.length > 0 && !folders.contains(folder) && getTextFromFile('images/$folder/Animation.json') != null)
			folders.push(folder);
	}

	static function normalizeAssetFolder(path:String):String
	{
		return normalizeAssetPath(path);
	}

	static function getAnimateAtlasFrames(folder:String):FlxAnimateFrames
	{
		var frames:FlxAnimateFrames = new FlxAnimateFrames();
		return addAnimateAtlasFrames(frames, folder) ? frames : null;
	}

	static function addAnimateAtlasFrames(frames:FlxAnimateFrames, folder:String):Bool
	{
		var found:Bool = false;

		for (i in 0...10)
		{
			var st:String = i == 0 ? '' : '$i';
			var spriteJson:String = getTextFromFile('images/$folder/spritemap$st.json');
			if (spriteJson == null)
				continue;

			var spriteImage:FlxGraphic = image('$folder/spritemap$st');
			if (spriteImage == null)
				continue;

			var spriteFrames = FlxAnimateFrames.fromSpriteMap(spriteJson, spriteImage);
			if (spriteFrames != null && spriteFrames.parent != null)
			{
				frames.addAtlas(spriteFrames, true);
				found = true;
			}
		}

		return found;
	}

	static function mergeAnimateAnimationJson(folders:Array<String>):String
	{
		var base:Dynamic = null;
		var baseSymbols:Array<Dynamic> = null;

		for (folder in folders)
		{
			var text:String = getTextFromFile('images/$folder/Animation.json');
			if (text == null)
				continue;

			var data:Dynamic = Json.parse(text);
			if (base == null)
			{
				base = data;
				baseSymbols = getAnimateSymbols(base);
				continue;
			}

			if (Reflect.hasField(data, 'AN') && Reflect.field(data, 'AN') != null)
				addUniqueAnimateSymbol(baseSymbols, Reflect.field(data, 'AN'));

			for (symbol in getAnimateSymbols(data))
				addUniqueAnimateSymbol(baseSymbols, symbol);
		}

		return base != null ? Json.stringify(base) : null;
	}

	static function getAnimateSymbols(data:Dynamic):Array<Dynamic>
	{
		if (!Reflect.hasField(data, 'SD') || Reflect.field(data, 'SD') == null)
			Reflect.setField(data, 'SD', {S: []});

		var sd:Dynamic = Reflect.field(data, 'SD');
		if (!Reflect.hasField(sd, 'S') || Reflect.field(sd, 'S') == null)
			Reflect.setField(sd, 'S', []);

		return cast Reflect.field(sd, 'S');
	}

	static function addUniqueAnimateSymbol(symbols:Array<Dynamic>, symbol:Dynamic):Void
	{
		if (symbol == null)
			return;

		var name:Dynamic = Reflect.field(symbol, 'SN');
		if (name == null)
			return;

		var symbolName:String = Std.string(name);
		for (existing in symbols)
		{
			var existingName:Dynamic = Reflect.field(existing, 'SN');
			if (existingName != null && Std.string(existingName) == symbolName)
				return;
		}

		symbols.push(symbol);
	}

	public static function loadMultiAnimateAtlas(spr:Dynamic, folderOrImg:Dynamic):Bool
	{
		if (!Std.isOfType(folderOrImg, String))
			return false;

		var folders:Array<String> = getAnimateAtlasFolders(cast folderOrImg);
		if (folders.length < 1)
			return false;

		var frames:FlxAnimateFrames = new FlxAnimateFrames();
		var foundFrames:Bool = false;
		for (folder in folders)
			if (addAnimateAtlasFrames(frames, folder))
				foundFrames = true;

		var animationJson:String = mergeAnimateAnimationJson(folders);
		if (foundFrames && animationJson != null)
		{
			spr.loadSeparateAtlas(animationJson, frames);
			return true;
		}

		return false;
	}

	public static function multiAnimateAtlas(spr:Dynamic, folderOrImg:Dynamic):Bool
	{
		return loadMultiAnimateAtlas(spr, folderOrImg);
	}

	public static function multianimateatlas(spr:Dynamic, folderOrImg:Dynamic):Bool
	{
		return loadMultiAnimateAtlas(spr, folderOrImg);
	}

	public static function loadAnimateAtlas(spr:Dynamic, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = normalizeAssetFolder(folderOrImg);
			var animateFolders:Array<String> = getAnimateAtlasFolders(originalPath);
			if(spriteJson == null && animationJson == null && (animateFolders.length > 1 || (animateFolders.length == 1 && animateFolders[0] != originalPath)))
			{
				if(loadMultiAnimateAtlas(spr, originalPath))
					return;
			}

			var multiFrames:FlxAnimateFrames = (!changedAtlasJson && !changedImage) ? getAnimateAtlasFrames(originalPath) : null;
			if(multiFrames != null && !changedAnimJson)
			{
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
				if(animationJson != null)
				{
					changedAnimJson = true;
					spr.loadSeparateAtlas(animationJson, multiFrames);
					return;
				}
			}

			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}
