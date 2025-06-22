{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.bluetooth;

  # This will be evaluated later to avoid infinite recursion

  # Detect desktop environment
  isGnome = config.services.desktopManager.gnome.enable or false;
  isKde = config.services.xserver.desktopManager.plasma5.enable or config.services.desktopManager.plasma6.enable or false;
  isSway = config.programs.sway.enable or false;
  isHyprland = config.programs.hyprland.enable or false;

  hasDesktop = (config.services.xserver.enable or false) || isSway || isHyprland;
  isWayland = isSway || isHyprland;
in {
  options.modules.core.bluetooth = {
    enable = mkEnableOption "Bluetooth support with audio integration";

    powerOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Power on Bluetooth adapter on boot";
    };

    audio = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bluetooth audio support (A2DP, HSP/HFP)";
      };

      codec = mkOption {
        type = types.enum ["sbc" "aac" "aptx" "ldac" "auto"];
        default = "auto";
        description = "Preferred Bluetooth audio codec";
      };

      lowLatency = mkOption {
        type = types.bool;
        default = false;
        description = "Enable low-latency Bluetooth audio profile";
      };
    };

    discoverability = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Make device discoverable by default";
      };

      timeout = mkOption {
        type = types.int;
        default = 0;
        description = "Discoverability timeout in seconds (0 = infinite)";
      };
    };

    experimental = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable experimental Bluetooth features";
      };

      features = mkOption {
        type = types.listOf types.str;
        default = ["KernelExperimental"];
        description = "List of experimental features to enable";
        example = ["KernelExperimental" "BlueZ5"];
      };
    };

    autoConnect = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically connect to known devices";
      };

      timeout = mkOption {
        type = types.int;
        default = 60;
        description = "Auto-connection timeout in seconds";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.discoverability.enable || cfg.discoverability.timeout >= 0;
        message = "Discoverability timeout must be non-negative";
      }
      {
        assertion = cfg.autoConnect.timeout > 0;
        message = "Auto-connect timeout must be positive";
      }
    ];

    # Enable Bluetooth hardware support
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;

      # Modern Bluetooth configuration
      settings = {
        General =
          {
            # Device discovery and pairing
            Discoverable = cfg.discoverability.enable;
            DiscoverableTimeout = mkIf cfg.discoverability.enable cfg.discoverability.timeout;
            PairableTimeout = 0; # Always pairable

            # Auto-connection settings
            AutoConnectTimeout = cfg.autoConnect.timeout;
            ReconnectAttempts = 3;
            ReconnectIntervals = "1,2,4,8,16";

            # Enable all device classes
            Class = "0x000100"; # Computer/Uncategorized

            # Security and compatibility
            JustWorksRepairing = "always";
            Privacy = "device"; # Use device privacy mode

            # Experimental features
            Experimental = cfg.experimental.enable;
          }
          // optionalAttrs cfg.experimental.enable {
            KernelExperimental = true;
          };

        # Audio-specific configuration
        Policy = mkIf cfg.audio.enable {
          AutoEnable = true;
        };

        # LE (Low Energy) settings
        LE = {
          MinConnectionInterval = 7;
          MaxConnectionInterval = 9;
          ConnectionLatency = 0;
          ConnectionSupervisionTimeout = 720;
        };
      };
    };

    # Bluetooth service configuration
    services.blueman.enable = mkIf (hasDesktop && !isGnome && !isKde) true;

    # Enable bluetooth group for users (they can add themselves manually)
    users.groups.bluetooth = {};

    # Essential Bluetooth packages
    environment.systemPackages = with pkgs;
      [
        # Core Bluetooth tools
        bluez # Bluetooth protocol stack
        bluez-tools # Bluetooth utilities

        # Desktop-specific tools
      ]
      ++ optionals hasDesktop [
        # GUI applications (not for GNOME/KDE as they have built-in)
      ]
      ++ optionals (hasDesktop && !isGnome && !isKde) [
        blueman # Bluetooth manager GUI
      ]
      ++ optionals isWayland [
        # Wayland-specific Bluetooth tools
        blueberry # Alternative Bluetooth manager
      ]
      ++ optionals cfg.audio.enable [
        # Audio-related Bluetooth tools (PipeWire handles this automatically)
      ];

    # PipeWire Bluetooth audio integration
    services.pipewire = mkIf (cfg.audio.enable && config.services.pipewire.enable) {
      # Enable Bluetooth audio modules
      extraConfig.pipewire = {
        "context.modules" = [
          {
            name = "libpipewire-module-bluetooth-policy";
            args = {
              "roles" = ["hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
              "auto-connect" = cfg.autoConnect.enable;
            };
          }
        ];
      };

      # Bluetooth codec configuration
      extraConfig.pipewire-pulse = mkIf (cfg.audio.codec != "auto") {
        "pulse.properties" = {
          "bluez5.codecs" = [cfg.audio.codec];
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
        };
      };
    };

    # Bluetooth systemd configuration
    systemd = {
      # Bluetooth agent service for auto-pairing
      user.services.bluetooth-agent = mkIf cfg.autoConnect.enable {
        description = "Bluetooth authentication agent";
        wantedBy = ["default.target"];
        after = ["graphical-session.target"];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 1;
          ExecStart = "${pkgs.bluez}/bin/bt-agent -c NoInputNoOutput";
        };
      };

      # Bluetooth applet for desktop environments (except GNOME/KDE which have built-in)
      user.services.blueman-applet = mkIf (hasDesktop && !isGnome && !isKde) {
        description = "Bluetooth Manager applet";
        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 3;
          ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        };
      };

      # Systemd target for Bluetooth
      targets.bluetooth = {
        description = "Bluetooth support";
        wantedBy = ["multi-user.target"];
      };
    };

    # Sway/Hyprland: Ensure Bluetooth works in Wayland
    programs.sway = mkIf isSway {
      extraSessionCommands = ''
        # Bluetooth environment variables for Wayland
        export BLUETOOTH_ADAPTER_PATH="/org/bluez/hci0"
      '';
    };

    # Kernel modules for Bluetooth
    boot.kernelModules = [
      "bluetooth"
      "btusb" # USB Bluetooth adapters
      "btintel" # Intel Bluetooth
      "btbcm" # Broadcom Bluetooth
      "btrtl" # Realtek Bluetooth
    ];

    # Bluetooth firmware
    hardware.enableRedistributableFirmware = true;

    # Power management for Bluetooth
    powerManagement = {
      powerUpCommands = mkIf cfg.powerOnBoot ''
        # Power on Bluetooth on system resume
        ${pkgs.bluez}/bin/bluetoothctl power on
      '';

      powerDownCommands = ''
        # Gracefully disconnect devices before suspend
        ${pkgs.bluez}/bin/bluetoothctl disconnect
      '';
    };

    # Security: Limit Bluetooth access
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.bluez") == 0 && subject.isInGroup("bluetooth")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
