package lucas.states.vslice.util.system;

#if windows
import lucas.states.util.windows.WindowsCPP;
#end

#if cpp
import lucas.states.util.cpp.CPPInterface;
#end

/**
 * Cross-platform system memory detection
 * Supports Windows, Mac, Linux, iOS, and Android
 * 
 * Enhanced with Slushi Engine's accurate RAM detection
 */
@:buildXml('
<target id="haxe">
    <lib name="Kernel32.lib" if="windows" />
</target>
')
#if (cpp && !windows)
@:cppInclude("unistd.h")
#end
#if cpp
@:cppInclude("stdio.h")
@:cppInclude("stdlib.h")
@:cppInclude("string.h")
#end
#if (mac || ios)
@:cppInclude("sys/types.h")
@:cppInclude("sys/sysctl.h")
@:cppInclude("mach/mach.h")
@:cppInclude("mach/mach_host.h")
#end
class SystemMemory
{
    /**
     * Gets total system RAM installed (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     * @return Total RAM in megabytes, or 0 if detection fails
     */
    public static function getTotalRAM():Int
    {
        #if cpp
        // Use the new accurate CPPInterface for all CPP platforms
        var ramMB:Float = CPPInterface.getRAM();
        if (ramMB > 0)
            return Std.int(ramMB);
        #end
        
        // Fallback to platform-specific detection
        #if windows
        return WindowsCPP.getTotalSystemRAM();
        #elseif android
        return getAndroidTotalRAM();
        #elseif (mac || ios)
        return getMacTotalRAM();
        #elseif linux
        return getLinuxTotalRAM();
        #else
        return 0;
        #end
    }

    /**
     * Gets available (free) system RAM (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     * @return Available RAM in megabytes, or 0 if detection fails
     */
    public static function getAvailableRAM():Int
    {
        #if windows
        return WindowsCPP.getAvailableSystemRAM();
        #elseif android
        return getAndroidAvailableRAM();
        #elseif (mac || ios)
        return getMacAvailableRAM();
        #elseif linux
        return getLinuxAvailableRAM();
        #else
        return 0;
        #end
    }

    /**
     * Gets the number of CPU cores
     * Works on all platforms
     * @return Number of logical processors
     */
    public static function getCPUCores():Int
    {
        #if windows
        return WindowsCPP.getCPUCoreCount();
        #elseif cpp
        return untyped __cpp__('sysconf(_SC_NPROCESSORS_ONLN)');
        #else
        return 1;
        #end
    }

    /**
     * Gets a human-readable string representation of total system RAM
     * @return String like "16.0 GB" or "8.0 GB"
     */
    public static function getTotalRAMString():String
    {
        var ramMB:Int = getTotalRAM();
        if (ramMB <= 0)
        {
            #if android
            return "W.I.P.";
            #else
            return "Unknown";
            #end
        }
        
        var ramGB:Float = Math.round((ramMB / 1024) * 100) / 100;
        return ramGB + " GB";
    }

    // === Platform-specific implementations ===

    #if android
    /**
     * Gets total RAM on Android
     * Note: RAM detection on Android is currently Work In Progress
     */
    private static function getAndroidTotalRAM():Int
    {
        // W.I.P. - RAM detection on Android needs more testing
        return 0;
    }

    /**
     * Gets available RAM on Android
     * Note: RAM detection on Android is currently Work In Progress
     */
    private static function getAndroidAvailableRAM():Int
    {
        // W.I.P. - RAM detection on Android needs more testing
        return 0;
    }
    #end

    #if (mac || ios)
    /**
     * Gets total RAM on Mac/iOS using sysctl
     */
    @:functionCode('
        int64_t memsize = 0;
        size_t size = sizeof(memsize);
        
        if (sysctlbyname("hw.memsize", &memsize, &size, NULL, 0) == 0) {
            // Convert bytes to MB
            return (int)(memsize / 1024 / 1024);
        }
        
        return 0;
    ')
    private static function getMacTotalRAM():Int
    {
        return 0;
    }

    /**
     * Gets available RAM on Mac/iOS using mach
     */
    @:functionCode('
        mach_port_t host_port = mach_host_self();
        mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
        vm_size_t pagesize;
        vm_statistics_data_t vm_stat;

        host_page_size(host_port, &pagesize);

        if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) == KERN_SUCCESS) {
            // Free memory in bytes
            int64_t free_memory = (int64_t)vm_stat.free_count * (int64_t)pagesize;
            // Convert bytes to MB
            return (int)(free_memory / 1024 / 1024);
        }

        return 0;
    ')
    private static function getMacAvailableRAM():Int
    {
        return 0;
    }
    #end

    #if (linux && !android)
    /**
     * Gets total RAM on Linux by reading /proc/meminfo using C++
     */
    @:functionCode('
        FILE* file = fopen("/proc/meminfo", "r");
        if (file == NULL) return 0;
        
        char line[256];
        long totalKB = 0;
        
        while (fgets(line, sizeof(line), file)) {
            if (sscanf(line, "MemTotal: %ld kB", &totalKB) == 1) {
                fclose(file);
                // Convert KB to MB
                return (int)(totalKB / 1024);
            }
        }
        
        fclose(file);
        return 0;
    ')
    private static function getLinuxTotalRAM():Int
    {
        #if cpp
        return 0; // The C++ code above will be executed
        #else
        return 0;
        #end
    }

    /**
     * Gets available RAM on Linux by reading /proc/meminfo using C++
     */
    @:functionCode('
        FILE* file = fopen("/proc/meminfo", "r");
        if (file == NULL) return 0;
        
        char line[256];
        long availableKB = 0;
        long memFreeKB = 0;
        long buffersKB = 0;
        long cachedKB = 0;
        
        while (fgets(line, sizeof(line), file)) {
            // Try MemAvailable first (available on newer kernels)
            if (sscanf(line, "MemAvailable: %ld kB", &availableKB) == 1) {
                fclose(file);
                return (int)(availableKB / 1024);
            }
            // Fallback for older kernels: calculate from MemFree + Buffers + Cached
            sscanf(line, "MemFree: %ld kB", &memFreeKB);
            sscanf(line, "Buffers: %ld kB", &buffersKB);
            if (strncmp(line, "Cached:", 7) == 0) { // Avoid SwapCached
                sscanf(line, "Cached: %ld kB", &cachedKB);
            }
        }
        
        fclose(file);
        
        // Calculate available memory manually if MemAvailable wasn\'t found
        if (memFreeKB > 0) {
            long totalAvail = memFreeKB + buffersKB + cachedKB;
            return (int)(totalAvail / 1024);
        }
        
        return 0;
    ')
    private static function getLinuxAvailableRAM():Int
    {
        #if cpp
        return 0; // The C++ code above will be executed
        #else
        return 0;
        #end
    }
    #end

    /**
     * Checks if the current device is low-end based on RAM
     * @param threshold RAM threshold in MB (default: 4096 = 4GB)
     * @return True if device has less RAM than threshold
     */
    public static function isLowEndDevice(threshold:Int = 4096):Bool
    {
        var totalRAM = getTotalRAM();
        if (totalRAM <= 0)
        {
            // If detection fails, assume not low-end to be safe
            return false;
        }
        return totalRAM < threshold;
    }
}