{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.core.hardware-detection;
in {
  options.modules.core.hardware-detection = {
    enable = mkEnableOption "automatic hardware detection and optimization";

    firmware = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable redistributable firmware";
      };
    };

    laptop = {
      autoDetect = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-detect laptop hardware and enable optimizations";
      };
    };

    graphics = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable graphics drivers and 32-bit support";
      };
    };
  };

  config = mkIf cfg.enable {
    # Auto-detect and configure based on hardware
    hardware.enableRedistributableFirmware = mkIf cfg.firmware.enable true;

    # Laptop-specific optimizations
    services.thermald.enable = mkIf (cfg.laptop.autoDetect && config.hardware.cpu.intel.updateMicrocode) true;
    services.auto-cpufreq.enable = mkIf (cfg.laptop.autoDetect && (builtins.pathExists /sys/class/power_supply/BAT0)) true;

    # Graphics detection and configuration
    hardware.graphics = mkIf cfg.graphics.enable {
      enable = true;
      enable32Bit = true;
    };
  };
}
