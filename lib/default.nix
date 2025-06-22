{lib}: rec {
  # Import all helpers
  helpers = import ./helpers.nix {inherit lib;};
  moduleLoader = import ./module-loader.nix {inherit lib;};
  themeHelpers = import ./theme-helpers.nix {inherit lib;};

  # Re-export helper functions for easy access
  inherit (helpers) importModules conditionalModules;
  inherit (moduleLoader) autoLoadAllModules loadCoreModules loadDesktopModules;
  inherit (themeHelpers) generateThemeName generateCursorTheme mkThemeAssertions;

  # Additional utility functions
  mkModuleOption = description:
    lib.mkOption {
      type = lib.types.submodule {};
      default = {};
      inherit description;
    };

  # Helper for creating enable options with better defaults
  mkEnableOption' = description: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Whether to enable ${description}.";
    };

  # Helper for hardware detection patterns
  hasHardware = path: lib.pathExists path;
  isLaptop = hasHardware "/sys/class/power_supply/BAT0";
  hasIntelCpu =
    if lib.pathExists "/proc/cpuinfo"
    then
      builtins.any (lib.hasPrefix "GenuineIntel")
      (lib.splitString "\n" (builtins.readFile "/proc/cpuinfo"))
    else false;

  # Helper for conditional module loading based on hostname
  hostnameMatches = pattern: hostname: lib.hasPrefix pattern hostname;
}
