package lucas.states.vslice.util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import openfl.system.System;
import funkin.util.SystemMemory;

#if sys
import sys.FileSystem;
#end

/**
 * Advanced memory management system, especially optimized for Android and low-end PCs.
 * Allows dynamic asset freeing to reduce RAM consumption.
 * 
 * Improved with Codename Engine techniques
 */
class MemoryManager
{
    #if android
    private static var isAndroid:Bool = true;
    #else
    private static var isAndroid:Bool = false;
    #end
    
    /**
     * Whether aggressive memory management is enabled
     * Auto-enabled on low-end devices
     */
    public static var aggressiveMode:Bool = false;
    
    /**
     * Threshold for automatic cleanup (in MB)
     */
    public static var autoCleanupThreshold:Float = 500;
    
    /**
     * Last time automatic cleanup was run
     */
    private static var lastAutoCleanup:Float = 0;
    
    /**
     * Interval between automatic cleanups (in seconds)
     */
    public static var autoCleanupInterval:Float = 30;
    
    /**
     * Initialize memory manager
     * Call this at game startup
     */
    public static function init():Void
    {
        // Get total system RAM (works on all platforms)
        var totalSystemRAM = SystemMemory.getTotalRAM();
        var ramString = SystemMemory.getTotalRAMString();
        var cpuCores = SystemMemory.getCPUCores();
        
        trace('\n\nSystem Info:\nTotal RAM: $ramString ($totalSystemRAM MB)\nCPU Cores: $cpuCores\n');
        
        #if android
        // On Android, also check optimizer tier
        var tier = funkin.mobile.AndroidOptimizer.getCurrentTier();
        trace('  - Android Tier: $tier');
        
        if (tier == 0 || (totalSystemRAM > 0 && totalSystemRAM < 3072))
        {
            trace('Low-end Android device detected');
            enableAggressiveMode();
        }
        #else
        // On desktop/other platforms, use RAM threshold
        if (totalSystemRAM > 0 && totalSystemRAM < 4096)
        {
            trace('Low-end device detected (${totalSystemRAM}MB RAM < 4GB)');
            enableAggressiveMode();
        }
        else if (totalSystemRAM >= 4096)
        {
            trace('High-end device detected (${totalSystemRAM}MB RAM >= 4GB)');
        }
        #end
        
        trace('Initialized (Aggressive: $aggressiveMode)');
    }
    
    /**
     * Enable aggressive memory management
     */
    public static function enableAggressiveMode():Void
    {
        aggressiveMode = true;
        autoCleanupThreshold = 300; // Lower threshold
        autoCleanupInterval = 20; // More frequent cleanups
        trace('[MemoryManager] Aggressive mode ENABLED');
    }
    
    /**
     * Disable aggressive memory management
     */
    public static function disableAggressiveMode():Void
    {
        aggressiveMode = false;
        autoCleanupThreshold = 500;
        autoCleanupInterval = 30;
        trace('[MemoryManager] Aggressive mode DISABLED');
    }
    
    /**
     * Update function - call this in game loop for automatic cleanup
     */
    public static function update(elapsed:Float):Void
    {
        if (!aggressiveMode) return;
        
        lastAutoCleanup += elapsed;
        
        if (lastAutoCleanup >= autoCleanupInterval)
        {
            lastAutoCleanup = 0;
            
            var currentMem = getMemoryUsage();
            if (currentMem > autoCleanupThreshold)
            {
                trace('[MemoryManager] Auto-cleanup triggered (${Math.round(currentMem)}MB > ${autoCleanupThreshold}MB)');
                quickCleanup();
            }
        }
    }

    /**
     * Elimina una imagen específica de todos los cachés (OpenFL, FlxG y Paths tracking)
     * @param path Ruta de la imagen sin extensión (ej: "stages/philly/sky")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente. Si es false, lo marca para destrucción posterior
     */
    public static function removeImageFromMemory(path:String, removeInstantly:Bool = true):Void
    {
        if (path == null || path == '') return;

        // Agregar extensión si no la tiene
        var imagePath:String = path;
        if (!imagePath.endsWith('.png'))
            imagePath = 'images/$path.png';

        // Buscar en assets de OpenFL
        var foundPath:String = Paths.getPath(imagePath, IMAGE);
        
        // Limpiar caché de OpenFL Assets
        if (Assets.cache.hasBitmapData(foundPath))
            Assets.cache.removeBitmapData(foundPath);

        // Buscar en caché de FlxG
        var graphic:FlxGraphic = FlxG.bitmap.get(foundPath);
        if (graphic == null)
        {
            // Intentar con ruta de mods
            #if MODS_ALLOWED
            foundPath = Paths.modsImages(path);
            graphic = FlxG.bitmap.get(foundPath);
            #end
        }

        if (graphic != null)
        {
            // Remover de tracking de Paths
            if (Paths.currentTrackedAssets.exists(foundPath))
                Paths.currentTrackedAssets.remove(foundPath);
            
            if (Paths.localTrackedAssets.contains(foundPath))
                Paths.localTrackedAssets.remove(foundPath);

            // Marcar para destrucción
            graphic.persist = false;
            graphic.destroyOnNoUse = true;

            if (removeInstantly)
            {
                FlxG.bitmap.remove(graphic);
                graphic.destroy();
            }
        }
    }

    /**
     * Elimina múltiples imágenes de memoria de una vez
     * @param paths Array de rutas de imágenes
     * @param removeInstantly Si es true, destruye los gráficos inmediatamente
     */
    public static function removeImagesFromMemory(paths:Array<String>, removeInstantly:Bool = true):Void
    {
        if (paths == null) return;
        
        for (path in paths)
            removeImageFromMemory(path, removeInstantly);
    }

    /**
     * Elimina un personaje específico del mapa de personajes y libera su memoria
     * @param characterName Nombre del personaje (ej: "bf", "dad", "gf")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente
     */
    public static function removeCharacterFromMemory(characterName:String, removeInstantly:Bool = true):Void
    {
        if (PlayState.instance == null || characterName == null) return;

        var imageFile:String = null;
        var char:funkin.play.character.Character = null;

        // Buscar en boyfriend map
        if (PlayState.instance.boyfriendMap.exists(characterName))
        {
            char = PlayState.instance.boyfriendMap.get(characterName);
            PlayState.instance.boyfriendGroup.remove(char, true);
            PlayState.instance.boyfriendMap.remove(characterName);
        }
        // Buscar en dad map
        else if (PlayState.instance.dadMap.exists(characterName))
        {
            char = PlayState.instance.dadMap.get(characterName);
            PlayState.instance.dadGroup.remove(char, true);
            PlayState.instance.dadMap.remove(characterName);
        }
        // Buscar en gf map
        else if (PlayState.instance.gfMap.exists(characterName))
        {
            char = PlayState.instance.gfMap.get(characterName);
            PlayState.instance.gfGroup.remove(char, true);
            PlayState.instance.gfMap.remove(characterName);
        }

        // Si encontramos el personaje, destruirlo y liberar su imagen
        if (char != null)
        {
            imageFile = char.imageFile;
            char.kill();
            char.destroy();

            if (imageFile != null && imageFile != '')
                removeImageFromMemory(imageFile, removeInstantly);
        }
    }

    /**
     * Clears unused UI assets (pixel UI vs normal UI)
     * Works on all platforms to save memory
     */
    public static function clearUnusedUI():Void
    {
        if (PlayState.instance == null) return;

        if (!PlayState.isPixelStage)
        {
            // Clear pixel UI if we're on normal stage
            Assets.cache.clear('assets/shared/images/pixelUI');
            removeImageFromMemory('pixelUI/arrows-pixels');
            removeImageFromMemory('pixelUI/arrows-pixels-ends');
            removeImageFromMemory('pixelUI/NOTE_assets');
        }
        else
        {
            // Clear normal UI if we're on pixel stage
            removeImageFromMemory('NOTE_assets');
            removeImageFromMemory('noteSplashes');
        }
    }

    /**
     * Clears preloaded characters that are not in use
     * Useful for low-end devices (mobile and desktop)
     */
    public static function clearPreloadedCharacters():Void
    {
        // Death character rarely used
        removeCharacterFromMemory('bf-dead', true);
        
        // Menu logo
        removeImageFromMemory('logoBumpin', true);
    }

    /**
     * Quick cleanup - lighter than aggressive cleanup
     * Good for periodic automatic cleanup
     */
    public static function quickCleanup():Void
    {
        trace('[MemoryManager] Running quick cleanup...');
        
        // Clear Paths unused memory
        Paths.clearUnusedMemory();
        
        // Clear temp frames cache
        Paths.clearTempFramesCache();
        
        // Minor GC
        System.gc();
        
        #if cpp
        cpp.NativeGc.run(false);
        #end
        
        trace('[MemoryManager] Quick cleanup complete');
    }

    /**
     * Aggressive cleanup - full memory cleanup
     * Combines all cleanup functions and forces garbage collection
     * Use sparingly as it's expensive
     */
    public static function aggressiveCleanup():Void
    {
        // Clear Paths caches
        Paths.clearUnusedMemory();
        Paths.clearStoredMemory();
        Paths.clearTempFramesCache();
        
        // Clear UI not in use
        clearUnusedUI();
        
        // Clear preloaded characters
        clearPreloadedCharacters();
        
        // Clear shaders
        clearShaders();
        
        // Force multiple GC cycles for thorough cleanup
        System.gc();
        #if cpp
        cpp.NativeGc.run(true);
        cpp.NativeGc.compact();
        #elseif neko
        neko.vm.Gc.run(true);
        #end
        
        // On aggressive mode, do multiple passes
        if (aggressiveMode)
        {
            System.gc();
            #if cpp
            cpp.NativeGc.run(true);
            #end
        }
        
    }
    
    /**
     * Ultra cleanup - nuclear option
     * Clears almost everything possible
     * WARNING: May cause visual glitches temporarily
     */
    public static function ultraCleanup():Void
    {
        // Run aggressive cleanup first
        aggressiveCleanup();
        
        // Clear FlxG bitmap cache (careful!)
        @:privateAccess
        {
            for (key in FlxG.bitmap._cache.keys())
            {
                var graphic = FlxG.bitmap.get(key);
                if (graphic != null && !graphic.persist && graphic.useCount == 0)
                {
                    FlxG.bitmap.remove(graphic);
                    graphic.destroy();
                }
            }
        }
        
        // Clear all sound caches
        Assets.cache.clear();
        
        // Force maximum GC
        for (i in 0...3)
        {
            System.gc();
            #if cpp
            cpp.NativeGc.run(true);
            cpp.NativeGc.compact();
            #end
        }
        
    }
    
    /**
     * Gets total system RAM installed (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     */
    public static function getTotalSystemRAM():Int
    {
        return SystemMemory.getTotalRAM();
    }
    
    /**
     * Gets current memory usage in MB (only on supported systems)
     * This is the RAM currently being used by the application
     */
    public static function getMemoryUsage():Float
    {
        #if cpp
        return System.totalMemory / 1024 / 1024;
        #else
        return 0;
        #end
    }
    
    /**
     * Gets available (free) system RAM in MB
     * Works on Windows, Mac, Linux, iOS, and Android
     */
    public static function getAvailableRAM():Int
    {
        return SystemMemory.getAvailableRAM();
    }

    /**
     * Reports current memory usage to console (useful for debugging)
     * Works on all platforms that support memory reporting
     */
    public static function reportMemoryUsage():Void
    {
        var memoryMB:Float = getMemoryUsage();
        if (memoryMB > 0)
            trace('Current memory usage: ${Math.round(memoryMB)}MB');
        else
            trace('Memory usage reporting not available on this platform');
    }

    /**
     * Clears all loaded shaders (very useful on low-end devices where shaders consume lots of RAM)
     * Works on all platforms - especially helpful for low-end desktop PCs
     */
    public static function clearShaders():Void
    {
        if (PlayState.instance == null) return;
        
        // Clear stage shaders
        if (PlayState.instance.camGame != null && PlayState.instance.camGame.filters != null)
            PlayState.instance.camGame.filters = [];
        
        if (PlayState.instance.camHUD != null && PlayState.instance.camHUD.filters != null)
            PlayState.instance.camHUD.filters = [];
        
        if (PlayState.instance.camOther != null && PlayState.instance.camOther.filters != null)
            PlayState.instance.camOther.filters = [];
        
    }

    /**
     * Automatic memory monitoring for low-end devices (mobile and desktop)
     * Runs automatic cleanup if usage exceeds specified threshold
     * @param thresholdMB Threshold in MB (default 500MB)
     */
    public static function autoMonitor(thresholdMB:Float = 500):Void
    {
        var currentMemory:Float = getMemoryUsage();
        
        if (currentMemory > 0 && currentMemory > thresholdMB)
        {
            if (aggressiveMode)
                aggressiveCleanup();
            else
                quickCleanup();
        }
    }
}
