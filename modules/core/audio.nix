{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.audio;

  # Audio group will be available for users to join manually

  # Detect desktop environment / window manager
  isXfce = config.services.xserver.desktopManager.xfce.enable or false;
  isGnome = config.services.desktopManager.gnome.enable or false;
  isKde = config.services.xserver.desktopManager.plasma5.enable or config.services.desktopManager.plasma6.enable or false;
  isSway = config.programs.sway.enable or false;
  isHyprland = config.programs.hyprland.enable or false;

  # Determine if we have any desktop environment
  hasDesktop = (config.services.xserver.enable or false) || isSway || isHyprland;

  # Determine if we need manual multimedia key handling
  # GNOME, KDE, Sway, and Hyprland handle keys natively
  needsManualKeys = hasDesktop && !(isGnome || isKde || isSway || isHyprland);

  # Determine if we're using Wayland
  isWayland = isSway || isHyprland;
in {
  options.modules.core.audio = {
    enable = mkEnableOption "modern audio system with PipeWire";

    backend = mkOption {
      type = types.enum ["pipewire" "pulseaudio"];
      default = "pipewire";
      description = "Audio backend to use";
    };

    lowLatency = mkOption {
      type = types.bool;
      default = false;
      description = "Enable low-latency audio configuration for professional audio";
    };

    multimedia = {
      enableKeys = mkOption {
        type = types.bool;
        default = hasDesktop;
        description = "Enable multimedia key support (volume, play/pause, etc.)";
      };

      keyMethod = mkOption {
        type = types.enum ["auto" "actkbd" "wireplumber" "systemd"];
        default = "auto";
        description = "Method for handling multimedia keys";
      };
    };

    defaultVolume = mkOption {
      type = types.int;
      default = 50;
      description = "Default audio volume percentage (0-100)";
      example = 75;
    };

    enableNoiseSuppression = mkOption {
      type = types.bool;
      default = true;
      description = "Enable noise suppression for microphone input";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.defaultVolume >= 0 && cfg.defaultVolume <= 100;
        message = "Default volume must be between 0 and 100";
      }
    ];

    # Audio services configuration
    services = {
      # PipeWire audio system
      pipewire = mkIf (cfg.backend == "pipewire") {
        enable = mkForce true;

        # Enable audio server capabilities
        audio.enable = true;

        # Replace PulseAudio
        pulse.enable = true;

        # JACK support for professional audio applications
        jack.enable = cfg.lowLatency;

        # ALSA support
        alsa = {
          enable = true;
          support32Bit = true; # For Wine and 32-bit applications
        };

        # WirePlumber session manager (better for Wayland)
        wireplumber.enable = true;

        # Low-latency configuration
        extraConfig.pipewire = mkIf cfg.lowLatency {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 32;
          };
        };

        # Noise suppression for microphone
        extraConfig.pipewire-pulse = mkIf cfg.enableNoiseSuppression {
          "pulse.properties" = {
            "pulse.module.args" = {
              "echo-cancel" = {
                "source_name" = "echo-cancel-source";
                "sink_name" = "echo-cancel-sink";
                "aec_method" = "webrtc";
                "aec_args" = "analog_gain_control=0 digital_gain_control=1 noise_suppression=1 voice_detection=1";
              };
            };
          };
        };
      };

      # Fallback PulseAudio configuration
      pulseaudio = mkIf (cfg.backend == "pulseaudio") {
        enable = true;
        support32Bit = true;

        # Better audio quality
        daemon.config = {
          default-sample-format = "s24le";
          default-sample-rate = 48000;
          alternate-sample-rate = 44100;
          default-sample-channels = 2;
          default-fragments = 2;
          default-fragment-size-msec = 125;
          resample-method = "speex-float-5";
          enable-lfe-remixing = "no";
          high-priority = "yes";
          nice-level = -11;
          realtime-scheduling = "yes";
          realtime-priority = 9;
          rlimit-rtprio = 9;
          daemonize = "no";
        };
      };

      # Multimedia key handling based on desktop environment
      # Method 1: actkbd for X11 environments that don't handle keys natively
      actkbd = mkIf (cfg.multimedia.enableKeys
        && (cfg.multimedia.keyMethod
          == "actkbd"
          || (cfg.multimedia.keyMethod == "auto" && needsManualKeys && !isWayland))) {
        enable = true;
        bindings = [
          # Volume controls
          {
            keys = [113];
            events = ["key"];
            command = "${pkgs.pamixer}/bin/pamixer --decrease 5";
          }
          {
            keys = [114];
            events = ["key"];
            command = "${pkgs.pamixer}/bin/pamixer --increase 5";
          }
          {
            keys = [115];
            events = ["key"];
            command = "${pkgs.pamixer}/bin/pamixer --toggle-mute";
          }

          # Media controls
          {
            keys = [164];
            events = ["key"];
            command = "${pkgs.playerctl}/bin/playerctl play-pause";
          }
          {
            keys = [165];
            events = ["key"];
            command = "${pkgs.playerctl}/bin/playerctl previous";
          }
          {
            keys = [163];
            events = ["key"];
            command = "${pkgs.playerctl}/bin/playerctl next";
          }
          {
            keys = [166];
            events = ["key"];
            command = "${pkgs.playerctl}/bin/playerctl stop";
          }
        ];
      };

      # Desktop-specific optimizations
      # XFCE: Disable built-in screensaver conflicts
      xserver.desktopManager.xfce = mkIf isXfce {
        enableScreensaver = false;
      };
    };

    # Method 2: systemd user services for Wayland (fallback if compositor doesn't handle keys)
    systemd.user.services = mkIf (cfg.multimedia.enableKeys
      && isWayland
      && (cfg.multimedia.keyMethod
        == "systemd"
        || (cfg.multimedia.keyMethod == "auto" && needsManualKeys))) {
      audio-keys = {
        description = "Audio multimedia key handler";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 1;
        };

        script = ''
          # This is a fallback - most Wayland compositors handle keys natively
          # Users should configure their compositor directly for better integration
          echo "Audio keys service started - configure your compositor for better integration"
          sleep infinity
        '';
      };
    };

    # Enable audio group for users (PipeWire/PulseAudio handles permissions)
    users.groups.audio = {};

    # Essential audio packages
    environment.systemPackages = with pkgs;
      [
        # Audio control utilities
        pamixer # PulseAudio/PipeWire mixer
        pavucontrol # PulseAudio Volume Control GUI

        # Multimedia key support
        playerctl # Media player control

        # Audio tools
        alsa-utils # ALSA utilities (amixer, aplay, etc.)

        # Wayland-specific audio tools
      ]
      ++ optionals isXfce [
        xfce.xfce4-pulseaudio-plugin # XFCE audio panel plugin (volume control + tray icon)
      ]
      ++ optionals isWayland [
        wl-clipboard # Wayland clipboard for audio apps
      ]
      ++ optionals (cfg.backend == "pipewire") [
        pwvucontrol # PipeWire Volume Control GUI
        helvum # PipeWire patchbay GUI
        qpwgraph # Qt PipeWire graph manager
        wireplumber # WirePlumber CLI tools
      ];

    # Sway: Audio is handled natively, ensure proper session variables
    programs.sway = mkIf isSway {
      extraSessionCommands = ''
        export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse"
      '';
    };

    # Hardware audio optimizations
    boot.kernelModules = ["snd-aloop"]; # Virtual audio loopback

    # Audio-related kernel parameters
    boot.kernelParams = [
      "snd_hda_intel.power_save=0" # Disable power saving for audio (can cause issues)
    ];

    # RealtimeKit for low-latency audio
    security.rtkit.enable = true;

    # Set default volume on boot (users can configure this per-user if needed)
    systemd.services.set-default-volume = {
      description = "Set default audio volume";
      wantedBy = ["multi-user.target"];
      after = ["sound.target"] ++ optional (cfg.backend == "pipewire") "pipewire.service";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Wait for audio system to be ready
        sleep 3

        # Set default volume for the default sink
        ${pkgs.pamixer}/bin/pamixer --set-volume ${toString cfg.defaultVolume} || true

        # Unmute if muted
        ${pkgs.pamixer}/bin/pamixer --unmute || true
      '';
    };

    # ALSA hardware support
    hardware.alsa.enable = true;

    # Hardware audio support
    hardware.enableRedistributableFirmware = true;

    # Session variables for proper audio in all environments
    environment.sessionVariables = mkIf (cfg.backend == "pipewire") {
      PULSE_SERVER = "unix:\${XDG_RUNTIME_DIR}/pulse/native";
    };
  };
}
