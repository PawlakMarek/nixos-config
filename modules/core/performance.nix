{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.core.performance;
in {
  options.modules.core.performance = {
    enable = mkEnableOption "system performance optimizations";

    ssd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSD optimizations (TRIM, etc.)";
      };
    };

    memory = {
      zram = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable zram swap compression";
        };

        algorithm = mkOption {
          type = types.str;
          default = "zstd";
          description = "Compression algorithm for zram";
        };

        memoryPercent = mkOption {
          type = types.int;
          default = 50;
          description = "Percentage of RAM to use for zram";
        };
      };
    };

    boot = {
      fastBoot = mkOption {
        type = types.bool;
        default = true;
        description = "Enable fast boot optimizations";
      };
    };

    nix = {
      optimize = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nix store optimizations";
      };
    };

    laptop = {
      powerManagement = mkOption {
        type = types.bool;
        default = true;
        description = "Enable laptop power management (auto-detected)";
      };
    };
  };

  config = mkIf cfg.enable {
    # SSD optimizations
    services.fstrim.enable = mkIf cfg.ssd.enable true;

    # Memory management
    zramSwap = mkIf cfg.memory.zram.enable {
      enable = true;
      inherit (cfg.memory.zram) algorithm memoryPercent;
    };

    # Boot optimization
    boot.loader.timeout = mkIf cfg.boot.fastBoot 1;
    boot.kernelParams = mkIf cfg.boot.fastBoot ["quiet" "splash"];

    # Nix store optimization
    nix.settings = mkIf cfg.nix.optimize {
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0; # Use all cores
    };

    # Laptop power management
    services.tlp = mkIf (cfg.laptop.powerManagement && (builtins.pathExists /sys/class/power_supply/BAT0)) {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };
  };
}
