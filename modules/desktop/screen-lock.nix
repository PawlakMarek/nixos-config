# Screen locking module for desktop environments
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.screen-lock;
in {
  options.modules.desktop.screen-lock = {
    enable = mkEnableOption "screen locking functionality";

    locker = mkOption {
      type = types.enum ["xfce4-screensaver" "light-locker" "i3lock"];
      default = "xfce4-screensaver";
      description = "Screen locker to use";
    };

    lockOnSuspend = mkOption {
      type = types.bool;
      default = true;
      description = "Lock screen when system suspends";
    };

    lockOnLidClose = mkOption {
      type = types.bool;
      default = true;
      description = "Lock screen when laptop lid is closed";
    };

    inactivityTimeout = mkOption {
      type = types.int;
      default = 10;
      description = "Minutes of inactivity before locking screen (0 = disabled)";
    };

    shortcut = mkOption {
      type = types.str;
      default = "<Super>l";
      description = "Keyboard shortcut to lock screen";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.xserver.enable;
        message = "Screen lock module requires X11 to be enabled";
      }
    ];

    # Install the selected screen locker
    environment.systemPackages = with pkgs;
      [
        (mkIf (cfg.locker == "xfce4-screensaver") xfce.xfce4-screensaver)
        (mkIf (cfg.locker == "light-locker") lightlocker)
        (mkIf (cfg.locker == "i3lock") i3lock)
      ]
      ++ [
        # Always include xss-lock for proper session management
        xss-lock
      ];

    # Configure the selected locker
    services = mkMerge [
      # XFCE4 Screensaver configuration
      (mkIf (cfg.locker == "xfce4-screensaver") {
        xserver.desktopManager.xfce.enableScreensaver = mkForce true;
      })

      # Light Locker configuration (alternative for XFCE)
      (mkIf (cfg.locker == "light-locker") {
        xserver.displayManager.sessionCommands = ''
          ${pkgs.lightlocker}/bin/light-locker --lock-on-suspend --lock-on-lid &
        '';
      })

      # Configure power management integration
      (mkIf cfg.lockOnLidClose {
        logind = {
          lidSwitch = "suspend";
          extraConfig = ''
            HandleLidSwitchExternalPower=suspend
            HandleLidSwitchDocked=ignore
          '';
        };
      })
    ];

    # System-wide lock command script
    environment.etc."lock-screen.sh" = {
      text = ''
        #!/bin/bash
        case "${cfg.locker}" in
          "xfce4-screensaver")
            ${pkgs.xfce.xfce4-screensaver}/bin/xfce4-screensaver-command --lock
            ;;
          "light-locker")
            ${pkgs.lightlocker}/bin/light-locker-command --lock
            ;;
          "i3lock")
            ${pkgs.i3lock}/bin/i3lock -c 1e1e2e
            ;;
        esac
      '';
      mode = "0755";
    };

    # Configure xss-lock for proper session management
    systemd.user.services.xss-lock = mkIf (cfg.lockOnSuspend || cfg.lockOnLidClose) {
      description = "X session screen lock";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = let
          lockCommand = "/etc/lock-screen.sh";
        in "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${lockCommand}";
        Restart = "on-failure";
      };
    };

    # Home Manager integration for per-user settings
    home-manager.sharedModules = [
      {
        # XFCE keyboard shortcuts
        xfconf.settings = mkIf config.services.xserver.desktopManager.xfce.enable {
          "xfce4-keyboard-shortcuts" = {
            "commands/custom/${cfg.shortcut}" = "/etc/lock-screen.sh";
            "commands/custom/<Alt>F4" = "xfce4-session-logout";
          };
        };

        # Autostart the locker service
        xdg.configFile = mkMerge [
          (mkIf (cfg.locker == "xfce4-screensaver") {
            "autostart/xfce4-screensaver.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=XFCE4 Screensaver
              Comment=Start XFCE4 screensaver daemon
              Exec=${pkgs.xfce.xfce4-screensaver}/bin/xfce4-screensaver
              Terminal=false
              Hidden=false
              X-GNOME-Autostart-enabled=true
              StartupNotify=false
              OnlyShowIn=XFCE;
            '';
          })

          (mkIf (cfg.locker == "light-locker") {
            "autostart/light-locker.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Light Locker
              Comment=Light weight X11 locker
              Exec=${pkgs.lightlocker}/bin/light-locker --lock-on-suspend=${
                if cfg.lockOnSuspend
                then "true"
                else "false"
              } --lock-on-lid=${
                if cfg.lockOnLidClose
                then "true"
                else "false"
              }
              Terminal=false
              Hidden=false
              X-GNOME-Autostart-enabled=true
              StartupNotify=false
              OnlyShowIn=XFCE;GNOME;
            '';
          })
        ];

        # Screen timeout configuration
        services = mkIf (cfg.inactivityTimeout > 0) {
          screen-locker = {
            enable = true;
            lockCmd = "/etc/lock-screen.sh";
            inactiveInterval = cfg.inactivityTimeout;
          };
        };
      }
    ];
  };
}
