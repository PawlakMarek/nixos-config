{
  lib,
  osConfig,
  ...
}:
with lib; let
  themingCfg = osConfig.modules.desktop.theming or {};

  # Catppuccin color schemes
  catppuccinColors = {
    mocha = {
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";
      url_color = "#f5e0dc";
      active_border_color = "#b4befe";
      inactive_border_color = "#6c7086";
      bell_border_color = "#f9e2af";
      active_tab_foreground = "#11111b";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#181825";
      tab_bar_background = "#11111b";
      mark1_foreground = "#1e1e2e";
      mark1_background = "#b4befe";
      mark2_foreground = "#1e1e2e";
      mark2_background = "#cba6f7";
      mark3_foreground = "#1e1e2e";
      mark3_background = "#74c7ec";
      color0 = "#45475a";
      color8 = "#585b70";
      color1 = "#f38ba8";
      color9 = "#f38ba8";
      color2 = "#a6e3a1";
      color10 = "#a6e3a1";
      color3 = "#f9e2af";
      color11 = "#f9e2af";
      color4 = "#89b4fa";
      color12 = "#89b4fa";
      color5 = "#f5c2e7";
      color13 = "#f5c2e7";
      color6 = "#94e2d5";
      color14 = "#94e2d5";
      color7 = "#bac2de";
      color15 = "#a6adc8";
      color16 = "#fab387";
      color17 = "#f5e0dc";
    };
  };

  selectedColors = catppuccinColors.${themingCfg.variant or "mocha"} or catppuccinColors.mocha;
in {
  programs.kitty = {
    enable = mkDefault true;

    font = {
      name = mkDefault "JetBrainsMono Nerd Font";
      size = mkDefault 12;
    };

    keybindings = {
      # Tab management
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+q" = "close_os_window";

      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+b" = "move_window_backward";

      # Layout management
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+alt+t" = "goto_layout tall";
      "ctrl+shift+alt+s" = "goto_layout stack";
      "ctrl+shift+alt+p" = "last_used_layout";
      "ctrl+shift+alt+z" = "toggle_layout stack";

      # Window resizing
      "ctrl+shift+r" = "start_resizing_window";
      "ctrl+shift+home" = "resize_window reset";

      # Scrolling
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";

      # Search
      "ctrl+shift+f" = "show_scrollback";

      # Font sizing
      "ctrl+shift+equal" = "change_font_size all +2.0";
      "ctrl+shift+minus" = "change_font_size all -2.0";
      "ctrl+shift+backspace" = "change_font_size all 0";

      # Clipboard
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "shift+insert" = "paste_from_selection";

      # Miscellaneous
      "ctrl+shift+f10" = "toggle_fullscreen";
      "ctrl+shift+f11" = "toggle_maximized";
      "ctrl+shift+u" = "kitten unicode_input";
      "ctrl+shift+f2" = "edit_config_file";
      "ctrl+shift+escape" = "kitty_shell window";
      "ctrl+shift+a>m" = "set_background_opacity +0.1";
      "ctrl+shift+a>l" = "set_background_opacity -0.1";
      "ctrl+shift+a>1" = "set_background_opacity 1";
      "ctrl+shift+a>d" = "set_background_opacity default";
    };

    settings = mkMerge [
      # Performance and basic settings
      {
        scrollback_lines = 50000;
        enable_audio_bell = false;
        visual_bell_duration = "0.0";
        window_alert_on_bell = false;
        remember_window_size = true;
        initial_window_width = 1200;
        initial_window_height = 800;

        # Advanced features
        allow_remote_control = true;
        shell_integration = "enabled";
        clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";

        # Tab and window management
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";

        # Window layout
        enabled_layouts = "tall:bias=50;full_size=1;mirrored=false,fat:bias=50;full_size=1;mirrored=false,horizontal,vertical,stack,grid";
        window_border_width = "1pt";
        draw_minimal_borders = true;
        window_margin_width = 2;
        window_padding_width = 4;

        # URL handling
        url_style = "curly";
        open_url_with = "default";
        detect_urls = true;

        # Performance optimizations
        repaint_delay = 10;
        input_delay = 3;
        sync_to_monitor = true;

        # OS integration
        wayland_titlebar_color = "system";
        macos_titlebar_color = "system";
        linux_display_server = "auto";

        # Cursor
        cursor_shape = "block";
        cursor_blink_interval = 0;
        cursor_stop_blinking_after = 15;

        # Mouse
        mouse_hide_wait = 3;
        focus_follows_mouse = false;

        # Terminal features
        term = "xterm-kitty";
        shell = ".";
        close_on_child_death = false;

        # Background
        background_opacity = "1.0";
        dynamic_background_opacity = true;
      }

      # Color scheme
      selectedColors
    ];
  };
}
