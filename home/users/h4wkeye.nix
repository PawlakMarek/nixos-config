{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  # Access theming configuration from NixOS config
  themingCfg = osConfig.modules.desktop.theming;
  themeHelpers = osConfig.lib.themeHelpers or (import ../../lib/theme-helpers.nix {inherit lib;});

  # Dynamic theme names using shared helpers
  gtkThemeName = "catppuccin-${themingCfg.variant}-${themingCfg.accent}-standard";
  xfwmThemeName = themeHelpers.generateThemeName themingCfg.variant themingCfg.accent;
  cursorThemeName = themeHelpers.generateCursorTheme themingCfg.variant themingCfg.accent;
in {
  imports = [
    ../programs/cli-tools.nix
    ../programs/shell.nix
  ];

  # Basic user configuration
  home = {
    username = "h4wkeye";
    homeDirectory = "/home/h4wkeye";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # XFCE Configuration
  xfconf.settings = {
    xfwm4 = {
      "general/theme" = xfwmThemeName;
      "general/title_font" = "Inter Bold 11";
      "general/button_layout" = "O|SHMC";
      "general/use_compositing" = true;
      "general/focus_mode" = "click";
      "general/focus_new" = true;
    };

    xsettings = {
      "Net/ThemeName" = gtkThemeName;
      "Net/IconThemeName" = "Papirus-Dark";
      "Gtk/FontName" = "Inter 11";
      "Gtk/MonospaceFontName" = "JetBrainsMono Nerd Font 11";
      "Gtk/CursorThemeName" = cursorThemeName;
      "Gtk/CursorThemeSize" = 24;
      "Gtk/DecorationLayout" = "menu:minimize,maximize,close";
    };

    xfce4-panel = {
      "configver" = 2;
      "panels" = [1];
      "panels/panel-1/autohide-behavior" = 0;
      "panels/panel-1/background-style" = 0;
      "panels/panel-1/length" = 100;
      "panels/panel-1/length-adjust" = true;
      "panels/panel-1/mode" = 0;
      "panels/panel-1/position" = "p=6;x=0;y=0";
      "panels/panel-1/position-locked" = true;
      "panels/panel-1/size" = 28;
    };

    xfce4-desktop = {
      "backdrop/screen0/monitorDisplayPort-0/workspace0/color-style" = 0;
      "backdrop/screen0/monitorDisplayPort-0/workspace0/image-style" = 5;
      "backdrop/screen0/monitorDisplayPort-0/workspace0/rgba1" = [0.1 0.1 0.1 1.0];
      "backdrop/screen0/monitorDisplayPort-0/workspace0/rgba2" = [0.2 0.2 0.2 1.0];
    };
  };

  # Kitty terminal configuration with Catppuccin
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      # Catppuccin Mocha color scheme
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";

      # Cursor colors
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";

      # URL underline color when hovering with mouse
      url_color = "#f5e0dc";

      # Kitty window border colors
      active_border_color = "#b4befe";
      inactive_border_color = "#6c7086";
      bell_border_color = "#f9e2af";

      # OS Window titlebar colors
      wayland_titlebar_color = "system";
      macos_titlebar_color = "system";

      # Tab bar colors
      active_tab_foreground = "#11111b";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#181825";
      tab_bar_background = "#11111b";

      # Colors for marks (marked text in the terminal)
      mark1_foreground = "#1e1e2e";
      mark1_background = "#b4befe";
      mark2_foreground = "#1e1e2e";
      mark2_background = "#cba6f7";
      mark3_foreground = "#1e1e2e";
      mark3_background = "#74c7ec";

      # The 16 terminal colors

      # black
      color0 = "#45475a";
      color8 = "#585b70";

      # red
      color1 = "#f38ba8";
      color9 = "#f38ba8";

      # green
      color2 = "#a6e3a1";
      color10 = "#a6e3a1";

      # yellow
      color3 = "#f9e2af";
      color11 = "#f9e2af";

      # blue
      color4 = "#89b4fa";
      color12 = "#89b4fa";

      # magenta
      color5 = "#f5c2e7";
      color13 = "#f5c2e7";

      # cyan
      color6 = "#94e2d5";
      color14 = "#94e2d5";

      # white
      color7 = "#bac2de";
      color15 = "#a6adc8";

      # Additional Catppuccin colors
      color16 = "#fab387"; # Peach
      color17 = "#f5e0dc"; # Rosewater
    };
  };

  # XFCE Terminal configuration as fallback
  xdg.configFile."xfce4/terminal/terminalrc".text = ''
    [Configuration]
    FontName=JetBrainsMono Nerd Font 12
    MiscAlwaysShowTabs=FALSE
    MiscBell=FALSE
    MiscBellUrgent=FALSE
    MiscBordersDefault=TRUE
    MiscCursorBlinks=FALSE
    MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
    MiscDefaultGeometry=80x24
    MiscInheritGeometry=FALSE
    MiscMenubarDefault=TRUE
    MiscMouseAutohide=FALSE
    MiscMouseWheelZoom=TRUE
    MiscToolbarDefault=FALSE
    MiscConfirmClose=TRUE
    MiscCycleTabs=TRUE
    MiscTabCloseButtons=TRUE
    MiscTabCloseMiddleClick=TRUE
    MiscTabPosition=GTK_POS_TOP
    MiscHighlightUrls=TRUE
    MiscMiddleClickOpensUri=FALSE
    MiscCopyOnSelect=FALSE
    MiscShowRelaunchDialog=TRUE
    MiscRewrapOnResize=TRUE
    MiscUseShiftArrowsToSelect=FALSE
    MiscSlimTabs=FALSE
    MiscNewTabAdjacent=FALSE
    MiscSearchDialogOpacity=100
    MiscShowUnsafePasteDialog=TRUE
    MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU
    BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
    BackgroundDarkness=0.900000
    # Catppuccin Mocha color scheme
    ColorForeground=#cdd6f4
    ColorBackground=#1e1e2e
    ColorCursor=#f5e0dc
    ColorBold=#cdd6f4
    ColorBoldUseDefault=FALSE
    ColorPalette=#45475a;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#bac2de;#585b70;#f38ba8;#a6e3a1;#f9e2af;#89b4fa;#f5c2e7;#94e2d5;#a6adc8
  '';

  # GTK theming with dconf
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = gtkThemeName;
      icon-theme = "Papirus-Dark";
      cursor-theme = cursorThemeName;
      font-name = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font 11";
      color-scheme = "prefer-dark";
    };

    "org/gnome/desktop/wm/preferences" = {
      theme = gtkThemeName;
      titlebar-font = "Inter Bold 11";
    };
  };

  # Enable additional services for proper theming
  services = {
    gnome-keyring.enable = true;
  };

  # Autostart script to force theme application
  xdg.configFile."autostart/apply-catppuccin-theme.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Apply Catppuccin Theme
    Comment=Force apply Catppuccin theme on startup
    Exec=${pkgs.writeShellScript "apply-catppuccin-theme" ''
      #!/bin/bash

      # Wait for XFCE to be ready
      sleep 2

      # Apply GTK theme via gsettings
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme '${gtkThemeName}'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme '${cursorThemeName}'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface font-name 'Inter 11'
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'

      # Apply XFCE settings
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Net/ThemeName -s '${gtkThemeName}'
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Net/IconThemeName -s 'Papirus-Dark'
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Gtk/CursorThemeName -s '${cursorThemeName}'
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Gtk/FontName -s 'Inter 11'
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s 'JetBrainsMono Nerd Font 11'

      # Apply window manager theme
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfwm4 -p /general/theme -s '${xfwmThemeName}'
      ${pkgs.xfce.xfconf}/bin/xfconf-query -c xfwm4 -p /general/title_font -s 'Inter Bold 11'

      # Restart XFCE components to apply changes
      ${pkgs.xfce.xfce4-panel}/bin/xfce4-panel --restart &
      ${pkgs.xfce.xfwm4}/bin/xfwm4 --replace &
    ''}
    Terminal=false
    Hidden=false
    X-GNOME-Autostart-enabled=true
    StartupNotify=false
    OnlyShowIn=XFCE;
  '';

  # Create GTK configuration files directly
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${gtkThemeName}
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=${cursorThemeName}
    gtk-cursor-theme-size=24
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=true
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=${gtkThemeName}
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=${cursorThemeName}
    gtk-cursor-theme-size=24
    gtk-font-name=Inter 11
    gtk-application-prefer-dark-theme=true
  '';

  # Add environment variables for theme
  home.sessionVariables = {
    GTK_THEME = gtkThemeName;
    QT_STYLE_OVERRIDE = "kvantum";
    XCURSOR_THEME = cursorThemeName;
    XCURSOR_SIZE = "24";
  };
}
