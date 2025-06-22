{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.theming;
  themeHelpers = config.lib.themeHelpers or (import ../../lib/theme-helpers.nix {inherit lib;});

  # Dynamic theme names using shared helpers
  gtkThemeName = "catppuccin-${cfg.variant}-${cfg.accent}-standard";
  xfwmThemeName = themeHelpers.generateThemeName cfg.variant cfg.accent;
  cursorThemeName = themeHelpers.generateCursorTheme cfg.variant cfg.accent;
  
  # Dynamic cursor package selection
  cursorPackage = pkgs.catppuccin-cursors.${themeHelpers.variantToPackageAttr cfg.variant cfg.accent} or pkgs.catppuccin-cursors.mochaPeach;
in {
  options.modules.desktop.theming = {
    enable = mkEnableOption "system-wide theming with Catppuccin";

    variant = mkOption {
      type = types.enum ["latte" "frappe" "macchiato" "mocha"];
      default = "mocha";
      description = "Catppuccin variant to use";
    };

    accent = mkOption {
      type = types.enum ["blue" "flamingo" "green" "lavender" "maroon" "mauve" "peach" "pink" "red" "rosewater" "sapphire" "sky" "teal" "yellow"];
      default = "peach";
      description = "Catppuccin accent color";
    };

    applications = {
      firefox = mkOption {
        type = types.bool;
        default = true;
        description = "Apply Catppuccin theme to Firefox";
      };

      thunderbird = mkOption {
        type = types.bool;
        default = true;
        description = "Apply Catppuccin theme to Thunderbird";
      };

      kvantum = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Kvantum theming for Qt applications";
      };
    };
  };

  config = mkIf cfg.enable {
    # Validate theme configuration
    assertions = themeHelpers.mkThemeAssertions cfg;
    # Enable Catppuccin globally
    catppuccin = {
      enable = true;
      flavor = cfg.variant;
      accent = cfg.accent;
    };

    # System-wide Catppuccin theming
    environment.systemPackages = with pkgs; [
      # Theme packages - properly configure catppuccin-gtk with variant and accent from config
      (catppuccin-gtk.override {
        variant = cfg.variant;
        accents = [cfg.accent];
        size = "standard";
        tweaks = [];
      })
      cursorPackage
      catppuccin-papirus-folders

      # Icon themes
      papirus-icon-theme

      # Qt theming
      libsForQt5.qtstyleplugin-kvantum
      catppuccin-kvantum

      # Cursor theme (duplicate removed - already included above)

      # Applications with Catppuccin theming (only when enabled)
    ] ++ optionals cfg.applications.firefox [
      firefox
    ] ++ optionals cfg.applications.thunderbird [
      thunderbird
    ] ++ [
      kitty

      # Required for dconf/gsettings theme management
      dconf
    ];

    # GTK and icon theme configuration
    environment.variables = {
      # Prevent icon cache errors by setting a writable location
      GTK_ICON_CACHE_DIR = "/tmp/gtk-icon-cache";
    };

    # Ensure icon theme cache directory exists
    systemd.tmpfiles.rules = [
      "d /tmp/gtk-icon-cache 0755 root root -"
    ];

    # XFCE-specific theming
    environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xfwm4" version="1.0">
          <property name="general" type="empty">
            <property name="theme" type="string" value="${xfwmThemeName}"/>
            <property name="title_font" type="string" value="Inter Bold 11"/>
            <property name="button_layout" type="string" value="O|SHMC"/>
            <property name="placement_ratio" type="int" value="20"/>
            <property name="workspace_count" type="int" value="4"/>
            <property name="wrap_windows" type="bool" value="true"/>
            <property name="wrap_workspaces" type="bool" value="false"/>
            <property name="zoom_desktop" type="bool" value="true"/>
            <property name="use_compositing" type="bool" value="true"/>
            <property name="compositing_mode" type="string" value="automatic"/>
            <property name="focus_delay" type="int" value="250"/>
            <property name="focus_mode" type="string" value="click"/>
            <property name="focus_new" type="bool" value="true"/>
            <property name="raise_on_focus" type="bool" value="false"/>
            <property name="activate_action" type="string" value="bring"/>
          </property>
        </channel>
      '';
    };

    # XFCE panel and desktop theming
    environment.etc."xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" = {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <channel name="xsettings" version="1.0">
          <property name="Net" type="empty">
            <property name="ThemeName" type="string" value="${gtkThemeName}"/>
            <property name="IconThemeName" type="string" value="Papirus-Dark"/>
            <property name="DoubleClickTime" type="empty"/>
            <property name="DoubleClickDistance" type="empty"/>
            <property name="DndDragThreshold" type="empty"/>
            <property name="CursorBlink" type="empty"/>
            <property name="CursorBlinkTime" type="empty"/>
            <property name="SoundThemeName" type="empty"/>
            <property name="EnableEventSounds" type="empty"/>
            <property name="EnableInputFeedbackSounds" type="empty"/>
          </property>
          <property name="Xft" type="empty">
            <property name="DPI" type="int" value="96"/>
            <property name="Antialias" type="int" value="1"/>
            <property name="Hinting" type="int" value="1"/>
            <property name="HintStyle" type="string" value="hintslight"/>
            <property name="RGBA" type="string" value="rgb"/>
          </property>
          <property name="Gtk" type="empty">
            <property name="CanChangeAccels" type="empty"/>
            <property name="ColorPalette" type="empty"/>
            <property name="FontName" type="string" value="Inter 11"/>
            <property name="MonospaceFontName" type="string" value="JetBrainsMono Nerd Font 11"/>
            <property name="IconSizes" type="empty"/>
            <property name="KeyThemeName" type="empty"/>
            <property name="ToolbarStyle" type="empty"/>
            <property name="ToolbarIconSize" type="empty"/>
            <property name="MenuImages" type="empty"/>
            <property name="ButtonImages" type="empty"/>
            <property name="MenuBarAccel" type="empty"/>
            <property name="CursorThemeName" type="string" value="${cursorThemeName}"/>
            <property name="CursorThemeSize" type="int" value="24"/>
            <property name="DecorationLayout" type="string" value="menu:minimize,maximize,close"/>
          </property>
        </channel>
      '';
    };

    # Terminal theming via environment variables
    environment.sessionVariables = {
      # Set cursor theme for all applications
      XCURSOR_THEME = cursorThemeName;
      XCURSOR_SIZE = "24";

      # Qt theming
      QT_STYLE_OVERRIDE = mkIf cfg.applications.kvantum "kvantum";
    };

    # Firefox theming
    programs.firefox = mkIf cfg.applications.firefox {
      enable = true;

      # System-wide Firefox preferences for theming
      preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.theme.dark-private-windows" = true;
        "ui.systemUsesDarkTheme" = true;
      };
    };

    # Thunderbird theming
    programs.thunderbird = mkIf cfg.applications.thunderbird {
      enable = true;

      # System-wide Thunderbird preferences for theming
      preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "ui.systemUsesDarkTheme" = true;
      };
    };

    # Home Manager integration for per-user theming
    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = cfg.variant;
          accent = cfg.accent;
        };

        # GTK configuration
        gtk = {
          enable = true;
          theme = {
            name = gtkThemeName;
            package = pkgs.catppuccin-gtk.override {
              accents = [cfg.accent];
              variant = cfg.variant;
              size = "standard";
              tweaks = [];
            };
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };

          cursorTheme = {
            name = cursorThemeName;
            package = cursorPackage;
            size = 24;
          };

          font = {
            name = "Inter";
            size = 11;
          };

          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = true;
            gtk-decoration-layout = "menu:minimize,maximize,close";
          };

          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = true;
            gtk-decoration-layout = "menu:minimize,maximize,close";
          };
        };

        # Qt theming
        qt = mkIf cfg.applications.kvantum {
          enable = true;
          platformTheme.name = "kvantum";
          style.name = "kvantum";
        };

        # Configure Kvantum
        xdg.configFile = mkIf cfg.applications.kvantum {
          "Kvantum/kvantum.kvconfig".text = ''
            [General]
            theme=Catppuccin-${lib.toUpper (builtins.substring 0 1 cfg.variant)}${builtins.substring 1 (builtins.stringLength cfg.variant) cfg.variant}-${lib.toUpper (builtins.substring 0 1 cfg.accent)}${builtins.substring 1 (builtins.stringLength cfg.accent) cfg.accent}
          '';
        };

        # Cursor theme for X11
        home.pointerCursor = {
          name = cursorThemeName;
          package = cursorPackage;
          size = 24;
          x11.enable = true;
          gtk.enable = true;
        };
      }
    ];

    # Ensure icon cache is built
    environment.pathsToLink = [
      "/share/icons"
      "/share/pixmaps"
    ];

    # Enable dconf for GTK settings
    programs.dconf.enable = true;

    # System-wide dconf settings for themes
    environment.etc."dconf/db/local.d/01-theme".text = ''
      [org/gnome/desktop/interface]
      gtk-theme='${gtkThemeName}'
      icon-theme='Papirus-Dark'
      cursor-theme='${cursorThemeName}'
      font-name='Inter 11'
      monospace-font-name='JetBrainsMono Nerd Font 11'
      color-scheme='prefer-dark'

      [org/gnome/desktop/wm/preferences]
      theme='${gtkThemeName}'
      titlebar-font='Inter Bold 11'
    '';

    environment.etc."dconf/db/local.d/locks/theme".text = ''
      /org/gnome/desktop/interface/gtk-theme
      /org/gnome/desktop/interface/icon-theme
      /org/gnome/desktop/interface/cursor-theme
      /org/gnome/desktop/interface/color-scheme
    '';

    # Update dconf database and apply theme immediately
    system.activationScripts.dconf-update = ''
      ${pkgs.dconf}/bin/dconf update
    '';

    # Additional activation script for theme application
    system.activationScripts.apply-catppuccin-theme = {
      text = ''
        # Ensure theme directories exist
        mkdir -p /etc/gtk-3.0
        mkdir -p /etc/gtk-4.0

        # Create system-wide GTK configuration
        cat > /etc/gtk-3.0/settings.ini << EOF
        [Settings]
        gtk-theme-name=${gtkThemeName}
        gtk-icon-theme-name=Papirus-Dark
        gtk-cursor-theme-name=${cursorThemeName}
        gtk-cursor-theme-size=24
        gtk-font-name=Inter 11
        gtk-application-prefer-dark-theme=true
        EOF

        cat > /etc/gtk-4.0/settings.ini << EOF
        [Settings]
        gtk-theme-name=${gtkThemeName}
        gtk-icon-theme-name=Papirus-Dark
        gtk-cursor-theme-name=${cursorThemeName}
        gtk-cursor-theme-size=24
        gtk-font-name=Inter 11
        gtk-application-prefer-dark-theme=true
        EOF

        # Update icon cache in writable location
        if [ -d "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark" ]; then
          mkdir -p /tmp/gtk-icon-cache/Papirus-Dark
          cp -r "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark"/* /tmp/gtk-icon-cache/Papirus-Dark/ 2>/dev/null || true
          ${pkgs.gtk3}/bin/gtk-update-icon-cache -f /tmp/gtk-icon-cache/Papirus-Dark 2>/dev/null || true
        fi

        # Set correct permissions
        chmod 644 /etc/gtk-3.0/settings.ini /etc/gtk-4.0/settings.ini || true
      '';
      deps = [];
    };

    # Font configuration for better rendering with your preferred fonts
    fonts = {
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = ["Inter" "Liberation Serif" "DejaVu Serif"];
          sansSerif = ["Inter" "Liberation Sans" "DejaVu Sans"];
          monospace = ["JetBrainsMono Nerd Font" "JetBrains Mono" "Liberation Mono" "DejaVu Sans Mono"];
        };

        # Improve font rendering
        subpixel.rgba = "rgb";
        hinting = {
          enable = true;
          style = "slight";
        };
        antialias = true;
      };
    };
  };
}
