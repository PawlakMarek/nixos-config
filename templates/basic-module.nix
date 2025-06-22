{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.category.module-name;
in {
  options.modules.category.module-name = {
    enable = mkEnableOption "brief description";

    # Example string option
    someOption = mkOption {
      type = types.str;
      default = "sensible-default";
      description = "Clear description of what this option does";
      example = "example-value";
    };

    # Example boolean option
    enableFeature = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable some feature";
    };

    # Example list option
    items = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of items to configure";
      example = ["item1" "item2"];
    };

    # Example submodule option
    advanced = mkOption {
      type = types.submodule {
        options = {
          setting1 = mkOption {
            type = types.str;
            default = "default";
            description = "Advanced setting 1";
          };

          setting2 = mkOption {
            type = types.int;
            default = 42;
            description = "Advanced setting 2";
          };
        };
      };
      default = {};
      description = "Advanced configuration options";
    };
  };

  config = mkIf cfg.enable {
    # Assertions for validation
    assertions = [
      {
        assertion = cfg.someOption != "";
        message = "modules.category.module-name.someOption cannot be empty";
      }
      {
        assertion = cfg.advanced.setting2 > 0;
        message = "modules.category.module-name.advanced.setting2 must be positive";
      }
    ];

    # Module implementation goes here
    environment.systemPackages = mkIf cfg.enableFeature (with pkgs; [
      # Add packages when feature is enabled
    ]);

    # Conditional configuration based on options
    services.someService = mkIf cfg.enableFeature {
      enable = true;
      setting = cfg.someOption;
      inherit (cfg) items;
      advancedSetting1 = cfg.advanced.setting1;
      advancedSetting2 = cfg.advanced.setting2;
    };

    # Hardware-conditional configuration
    services.laptopService = mkIf (cfg.enable && (builtins.pathExists /sys/class/power_supply/BAT0)) {
      enable = true;
    };
  };
}
