package lucas.states.vslice.util;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;

import openfl.utils.AssetType;
import openfl.Assets;
import openfl.system.System;
import openfl.media.Sound;

import lime.app.Future;
import lime.app.Promise;
import backend.Paths;
using Lambda;

/**
 * Handles caching of textures and sounds for the game.
 * Manages permanent and temporary caches to optimize memory usage.
 * 
 * Based on FunkinCrew's implementation with Plus Engine optimizations.
 */
class FunkinMemory
{
  static var permanentCachedTextures:Map<String, FlxGraphic> = [];
  static var currentCachedTextures:Map<String, FlxGraphic> = [];
  static var previousCachedTextures:Map<String, FlxGraphic> = [];

  static var permanentCachedSounds:Map<String, Sound> = [];
  static var currentCachedSounds:Map<String, Sound> = [];
  static var previousCachedSounds:Map<String, Sound> = [];

  static var purgeFilter:Array<String> = ["/week", "/characters", "/charSelect", "/results"];

  /**
   * Initializes the memory system by caching essential assets.
   * Call this early in game initialization.
   */
  public static function init():Void
  {
    // Cache all countdown sounds permanently
    var allSounds:Array<String> = Assets.list(AssetType.SOUND);

    for (file in allSounds)
    {
      if (!file.endsWith(".ogg") || file.indexOf("countdown/") == -1) continue;

      file = file.replace(" ", "");

      if (file.indexOf("shared") != -1 || Assets.exists('shared:$file', AssetType.SOUND))
      {
        file = 'shared:$file';
      }

      permanentCacheSound(file);
    }

    // Cache essential menu sounds permanently
    permanentCacheSound("cancelMenu");
    permanentCacheSound("confirmMenu");
    permanentCacheSound("screenshot");
    permanentCacheSound("scrollMenu");
    permanentCacheSound("soundtray/Voldown");
    permanentCacheSound("soundtray/VolMAX");
    permanentCacheSound("soundtray/Volup");
  }

  /**
   * Caches a texture permanently (won't be purged)
   * @param key The key to the texture (e.g., "fonts/bold")
   * @param parentFolder Optional parent folder
   */
  public static function permanentCacheTexture(key:Null<String>, ?parentFolder:String = null):Void
  {
    if (key == null) return;

    var graphic = Paths.image(key, parentFolder);
    if (graphic == null) return;

    graphic.persist = true;
    graphic.destroyOnNoUse = false;
    permanentCachedTextures.set(key, graphic);
  }

  /**
   * Caches a sound permanently (won't be purged)
   * @param key The key/path to the sound (e.g., "cancelMenu" or "sounds/cancelMenu")
   */
  public static function permanentCacheSound(key:Null<String>):Void
  {
    if (key == null) return;

    var sound = Paths.returnSound(key, null, true, false);
    if (sound != null)
    {
      permanentCachedSounds.set(key, sound);
    }
  }

  /**
   * Caches a texture temporarily (will be purged when switching states)
   * @param key The key to the texture (e.g., "fonts/bold")
   * @param parentFolder Optional parent folder
   */
  public static function cacheTexture(key:Null<String>, ?parentFolder:String = null):Void
  {
    if (key == null) return;

    var graphic = Paths.image(key, parentFolder);
    if (graphic == null) return;

    graphic.persist = true;
    currentCachedTextures.set(key, graphic);
  }

  /**
   * Caches a sound temporarily (will be purged when switching states)
   * @param key The key/path to the sound (e.g., "cancelMenu" or "sounds/cancelMenu")
   */
  public static function cacheSound(key:Null<String>):Void
  {
    if (key == null) return;

    var sound = Paths.returnSound(key, null, true, false);
    if (sound != null)
    {
      currentCachedSounds.set(key, sound);
    }
  }

  /**
   * Checks if a texture is currently cached
   * @param key The key to check
   * @return True if cached, false otherwise
   */
  public static function isTextureCached(key:Null<String>):Bool
  {
    if (key == null) return false;
    return currentCachedTextures.exists(key) || permanentCachedTextures.exists(key);
  }

  /**
   * Checks if a sound is currently cached
   * @param key The key to check
   * @return True if cached, false otherwise
   */
  public static function isSoundCached(key:Null<String>):Bool
  {
    if (key == null) return false;
    return currentCachedSounds.exists(key) || permanentCachedSounds.exists(key);
  }

  /**
   * Starts a new cache cycle.
   * Moves current cache to previous, prepares for new assets.
   * Call this when switching between major game states.
   */
  public static function cycle():Void
  {
    // Move current cache to previous
    previousCachedTextures = currentCachedTextures;
    previousCachedSounds = currentCachedSounds;

    // Clear current cache for new state
    currentCachedTextures = [];
    currentCachedSounds = [];

    trace('[FunkinMemory] Cache cycle complete');
  }

  /**
   * Purges old cached assets based on filter rules.
   * Removes assets from previous cache that match purge filter.
   * @param force If true, ignores filter and purges all previous cache
   */
  public static function purgeCache(force:Bool = false):Void
  {
    trace('[FunkinMemory] Purging cache... (force: $force)');

    var texturesPurged:Int = 0;
    var soundsPurged:Int = 0;

    // Purge textures
    for (key => texture in previousCachedTextures)
    {
      if (force || shouldPurge(key))
      {
        if (texture != null)
        {
          texture.persist = false;
          texture.destroyOnNoUse = true;
        }
        
        // Remove from Paths tracking
        var fullKey = 'images/$key.png';
        if (Paths.currentTrackedAssets.exists(fullKey))
        {
          Paths.currentTrackedAssets.remove(fullKey);
        }
        
        previousCachedTextures.remove(key);
        texturesPurged++;
      }
    }

    // Purge sounds
    for (key => sound in previousCachedSounds)
    {
      if (force || shouldPurge(key))
      {
        // Remove from Paths tracking
        for (trackedKey in Paths.currentTrackedSounds.keys())
        {
          if (trackedKey.indexOf(key) != -1)
          {
            Paths.currentTrackedSounds.remove(trackedKey);
          }
        }
        previousCachedSounds.remove(key);
        soundsPurged++;
      }
    }

    trace('[FunkinMemory] Purged $texturesPurged textures and $soundsPurged sounds');

    // Force garbage collection after purge
    #if cpp
    cpp.vm.Gc.run(true);
    #elseif hl
    hl.Gc.major();
    #end
  }

  /**
   * Checks if an asset path should be purged based on filter rules
   * @param path The asset path to check
   * @return True if should be purged, false otherwise
   */
  static function shouldPurge(path:String):Bool
  {
    for (filter in purgeFilter)
    {
      if (path.indexOf(filter) != -1) return true;
    }
    return false;
  }

  /**
   * Completely clears all non-permanent caches.
   * Use this for major state transitions or memory emergencies.
   */
  public static function clearCache():Void
  {
    trace('[FunkinMemory] Clearing all non-permanent caches...');

    // Clear current textures
    for (key => texture in currentCachedTextures)
    {
      if (texture != null)
      {
        texture.persist = false;
        texture.destroyOnNoUse = true;
      }
      
      // Remove from Paths tracking
      var fullKey = 'images/$key.png';
      if (Paths.currentTrackedAssets.exists(fullKey))
      {
        Paths.currentTrackedAssets.remove(fullKey);
      }
    }
    currentCachedTextures = [];

    // Clear previous textures
    for (key => texture in previousCachedTextures)
    {
      if (texture != null)
      {
        texture.persist = false;
        texture.destroyOnNoUse = true;
      }
      
      // Remove from Paths tracking
      var fullKey = 'images/$key.png';
      if (Paths.currentTrackedAssets.exists(fullKey))
      {
        Paths.currentTrackedAssets.remove(fullKey);
      }
    }
    previousCachedTextures = [];

    // Clear current sounds
    for (key => sound in currentCachedSounds)
    {
      // Remove from Paths tracking
      for (trackedKey in Paths.currentTrackedSounds.keys())
      {
        if (trackedKey.indexOf(key) != -1)
        {
          Paths.currentTrackedSounds.remove(trackedKey);
        }
      }
    }
    currentCachedSounds = [];

    // Clear previous sounds
    for (key => sound in previousCachedSounds)
    {
      // Remove from Paths tracking
      for (trackedKey in Paths.currentTrackedSounds.keys())
      {
        if (trackedKey.indexOf(key) != -1)
        {
          Paths.currentTrackedSounds.remove(trackedKey);
        }
      }
    }
    previousCachedSounds = [];

    trace('[FunkinMemory] Cache cleared');

    // Force garbage collection
    #if cpp
    cpp.vm.Gc.run(true);
    #elseif hl
    hl.Gc.major();
    #end
  }

  /**
   * Gets current memory usage statistics
   * @return Object with texture and sound cache statistics
   */
  public static function getStats():FunkinMemoryStats
  {
    var permTexCount = Lambda.count(permanentCachedTextures);
    var currTexCount = Lambda.count(currentCachedTextures);
    var prevTexCount = Lambda.count(previousCachedTextures);
    var permSndCount = Lambda.count(permanentCachedSounds);
    var currSndCount = Lambda.count(currentCachedSounds);
    var prevSndCount = Lambda.count(previousCachedSounds);
    
    return {
      permanentTextures: permTexCount,
      currentTextures: currTexCount,
      previousTextures: prevTexCount,
      permanentSounds: permSndCount,
      currentSounds: currSndCount,
      previousSounds: prevSndCount,
      totalTextures: permTexCount + currTexCount + prevTexCount,
      totalSounds: permSndCount + currSndCount + prevSndCount
    };
  }

  /**
   * Logs current cache statistics to trace
   */
  public static function logStats():Void
  {
    var stats = getStats();
    trace('[FunkinMemory] Cache Statistics:');
    trace('  Textures: ${stats.totalTextures} (Permanent: ${stats.permanentTextures}, Current: ${stats.currentTextures}, Previous: ${stats.previousTextures})');
    trace('  Sounds: ${stats.totalSounds} (Permanent: ${stats.permanentSounds}, Current: ${stats.currentSounds}, Previous: ${stats.previousSounds})');
  }
}

/**
 * Statistics object for FunkinMemory
 */
typedef FunkinMemoryStats =
{
  var permanentTextures:Int;
  var currentTextures:Int;
  var previousTextures:Int;
  var permanentSounds:Int;
  var currentSounds:Int;
  var previousSounds:Int;
  var totalTextures:Int;
  var totalSounds:Int;
}
