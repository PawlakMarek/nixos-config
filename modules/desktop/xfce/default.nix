{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.xfce;

  # Plugin ID constants to avoid magic numbers
  audioPluginId = 19;
  powerManagerPluginId = 20;
in {
  options.modules.desktop.xfce = {
    enable = mkEnableOption "XFCE desktop environment with customizations";

    panel = {
      enableAudioPlugin = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PulseAudio plugin in XFCE panel";
      };

      enablePowerManagerPlugin = mkOption {
        type = types.bool;
        default = true;
        description = "Enable power manager plugin in XFCE panel";
      };

      audioPluginPosition = mkOption {
        type = types.int;
        default = 7;
        description = "Position of audio plugin in panel (after systray)";
      };
    };

    defaultApplications = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Set XFCE-optimized default applications";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable XFCE desktop environment and required services
    services = {
      xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
          xfce = {
            enable = true;
            enableScreensaver = false; # Use separate screensaver/locker
            noDesktop = false;
            enableXfwm = true;
          };
        };
      };
      displayManager.defaultSession = "xfce";

      # Required services for XFCE
      gvfs.enable = true; # For Thunar
      tumbler.enable = true; # For thumbnails
      upower.enable = true; # Power management
      pipewire.enable = mkForce true;
    };

    # Environment configuration (packages, autostart, etc.)
    environment = {
      # Essential XFCE packages
      systemPackages = with pkgs;
        [
          # Core XFCE applications
          xfce.xfce4-appfinder
          xfce.xfce4-screenshooter
          xfce.xfce4-taskmanager
          xfce.xfce4-settings

          # Panel plugins
          xfce.xfce4-systemload-plugin
          xfce.xfce4-netload-plugin

          # Utilities
          xfce.thunar-archive-plugin
          xfce.thunar-volman

          # Archive support
          file-roller
          unzip
          zip
        ]
        ++ optionals cfg.panel.enableAudioPlugin [
          xfce.xfce4-pulseaudio-plugin
        ]
        ++ optionals cfg.panel.enablePowerManagerPlugin [
          xfce.xfce4-power-manager
        ];

      # XFCE panel configuration via autostart
      etc."xdg/autostart/configure-xfce-panel.desktop" = mkIf (cfg.panel.enableAudioPlugin || cfg.panel.enablePowerManagerPlugin) {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Configure XFCE Panel
          Comment=Add audio and battery plugins to XFCE panel
          Exec=${pkgs.writeShellScript "configure-xfce-panel" ''
            # Wait for XFCE panel to start
            while ! pgrep -x "xfce4-panel" > /dev/null; do
              sleep 1
            done

            # Wait a bit more for panel to be fully initialized
            sleep 3

            PLUGINS_ADDED=false

            ${optionalString cfg.panel.enableAudioPlugin ''
              # Check if audio plugin already exists
              if ! ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-${toString audioPluginId} 2>/dev/null; then
                # Create PulseAudio plugin
                ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-${toString audioPluginId} -t string -s pulseaudio --create
                PLUGINS_ADDED=true
              fi
            ''}

            ${optionalString cfg.panel.enablePowerManagerPlugin ''
              # Check if power manager plugin already exists
              if ! ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-${toString powerManagerPluginId} 2>/dev/null; then
                # Create power manager plugin
                ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-panel -p /plugins/plugin-${toString powerManagerPluginId} -t string -s power-manager-plugin --create
                PLUGINS_ADDED=true
              fi
            ''}

            # Only update panel layout if we added new plugins
            if [ "$PLUGINS_ADDED" = true ]; then
              # Build plugin list dynamically based on what's enabled
              PLUGIN_IDS="1 2 3 4 5 6"
              ${optionalString cfg.panel.enableAudioPlugin ''
              PLUGIN_IDS="$PLUGIN_IDS ${toString audioPluginId}"
            ''}
              ${optionalString cfg.panel.enablePowerManagerPlugin ''
              PLUGIN_IDS="$PLUGIN_IDS ${toString powerManagerPluginId}"
            ''}
              PLUGIN_IDS="$PLUGIN_IDS 7 8 9 10"

              # Convert to xfconf-query arguments
              XFCONF_ARGS=""
              for id in $PLUGIN_IDS; do
                XFCONF_ARGS="$XFCONF_ARGS -t int -s $id"
              done

              # Update panel plugin layout
              ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids $XFCONF_ARGS

              # Restart panel to apply changes
              ${pkgs.xfce.xfce4-panel}/bin/xfce4-panel --restart &
            fi

            # Remove this autostart file after first run
            rm -f "$HOME/.config/autostart/configure-xfce-panel.desktop"
          ''}
          Terminal=false
          Hidden=false
          X-GNOME-Autostart-enabled=true
          StartupNotify=false
        '';
      };

      # Default applications for XFCE
      etc."xdg/mimeapps.list" = mkIf cfg.defaultApplications.enable {
        text = ''
          [Default Applications]
          text/plain=org.xfce.mousepad.desktop
          application/pdf=org.gnome.Evince.desktop
          image/jpeg=org.xfce.ristretto.desktop
          image/png=org.xfce.ristretto.desktop
          image/gif=org.xfce.ristretto.desktop
          video/mp4=org.gnome.Totem.desktop
          audio/mpeg=org.gnome.Rhythmbox3.desktop
          inode/directory=thunar.desktop

          [Added Associations]
          text/plain=org.xfce.mousepad.desktop;
          application/pdf=org.gnome.Evince.desktop;
          image/jpeg=org.xfce.ristretto.desktop;
          image/png=org.xfce.ristretto.desktop;
          image/gif=org.xfce.ristretto.desktop;
          video/mp4=org.gnome.Totem.desktop;
          audio/mpeg=org.gnome.Rhythmbox3.desktop;
          inode/directory=thunar.desktop;
        '';
      };

      # XDG directories
      sessionVariables = {
        XDG_DATA_DIRS =
          [
            "${pkgs.xfce.xfce4-panel}/share"
          ]
          ++ optionals cfg.panel.enableAudioPlugin [
            "${pkgs.xfce.xfce4-pulseaudio-plugin}/share"
          ]
          ++ optionals cfg.panel.enablePowerManagerPlugin [
            "${pkgs.xfce.xfce4-power-manager}/share"
          ];
      };
    };

    # Modern font stack: Inter for UI, JetBrains Mono for code, with Nerd Fonts and emoji
    fonts.packages = with pkgs; [
      # Modern UI font - clean, readable, designed for interfaces
      inter

      # Code fonts with Nerd Font patches
      nerd-fonts.jetbrains-mono
      jetbrains-mono

      # System fallbacks
      liberation_ttf # Good fallback for Times/Arial/Courier
      dejavu_fonts # Excellent Unicode coverage

      # Emoji and symbols
      noto-fonts-emoji
      noto-fonts-color-emoji
      unifont # Free Unicode symbol coverage

      # Additional language support
      noto-fonts-cjk-sans # Chinese, Japanese, Korean
    ];

    # Configure font preferences for the system
    fonts.fontconfig = {
      defaultFonts = {
        serif = ["Inter" "Liberation Serif" "DejaVu Serif"];
        sansSerif = ["Inter" "Liberation Sans" "DejaVu Sans"];
        monospace = ["JetBrainsMono Nerd Font" "JetBrains Mono" "Liberation Mono" "DejaVu Sans Mono"];
        emoji = ["Noto Color Emoji" "Noto Emoji"];
      };
    };
  };
}
