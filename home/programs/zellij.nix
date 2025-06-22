{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  # Access theming configuration from NixOS config
  themingCfg = osConfig.modules.desktop.theming;

  # Catppuccin color mappings for accents
  accentColors = {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
  };

  # Get the accent color for the current theme
  accentColor = accentColors.${themingCfg.accent} or accentColors.peach;
in {
  programs.zellij = {
    enable = true;
    settings = {
      # Theme configuration - Catppuccin Mocha to match system theme
      theme = "catppuccin-mocha";

      # Default shell
      default_shell = "zsh";

      # Copy command
      copy_command = "wl-copy";

      # Copy clipboard
      copy_clipboard = "primary";

      # Mouse mode
      mouse_mode = true;

      # Scroll buffer size - consistent with other configurations
      scroll_buffer_size = 50000;

      # UI configuration
      ui = {
        pane_frames = {
          rounded_corners = true;
          hide_session_name = false;
        };
      };

      # Keybindings
      keybinds = {
        normal = {
          # Navigation
          "bind \"h\"" = {MoveFocus = "Left";};
          "bind \"l\"" = {MoveFocus = "Right";};
          "bind \"j\"" = {MoveFocus = "Down";};
          "bind \"k\"" = {MoveFocus = "Up";};

          # Pane management
          "bind \"n\"" = {
            NewPane = "Down";
            SwitchToMode = "Normal";
          };
          "bind \"N\"" = {
            NewPane = "Right";
            SwitchToMode = "Normal";
          };
          "bind \"x\"" = {
            CloseFocus = {};
            SwitchToMode = "Normal";
          };

          # Tabs
          "bind \"t\"" = {
            NewTab = {};
            SwitchToMode = "Normal";
          };
          "bind \"1\"" = {
            GoToTab = 1;
            SwitchToMode = "Normal";
          };
          "bind \"2\"" = {
            GoToTab = 2;
            SwitchToMode = "Normal";
          };
          "bind \"3\"" = {
            GoToTab = 3;
            SwitchToMode = "Normal";
          };
          "bind \"4\"" = {
            GoToTab = 4;
            SwitchToMode = "Normal";
          };
          "bind \"5\"" = {
            GoToTab = 5;
            SwitchToMode = "Normal";
          };

          # Sessions
          "bind \"d\"" = {Detach = {};};
          "bind \"w\"" = {SwitchToMode = "Session";}; # Switch to session mode instead
        };

        resize = {
          "bind \"h\"" = {Resize = "Increase Left";};
          "bind \"j\"" = {Resize = "Increase Down";};
          "bind \"k\"" = {Resize = "Increase Up";};
          "bind \"l\"" = {Resize = "Increase Right";};
          "bind \"H\"" = {Resize = "Decrease Left";};
          "bind \"J\"" = {Resize = "Decrease Down";};
          "bind \"K\"" = {Resize = "Decrease Up";};
          "bind \"L\"" = {Resize = "Decrease Right";};
          "bind \"=\" \"+\"" = {Resize = "Increase";};
          "bind \"-\"" = {Resize = "Decrease";};
        };
      };

      # Plugins
      plugins = {
        tab-bar = {path = "tab-bar";};
        status-bar = {path = "status-bar";};
        strider = {path = "strider";};
        compact-bar = {path = "compact-bar";};
      };

      # Layout configuration
      layout_dir = "${pkgs.zellij}/share/zellij/layouts";

      # Session serialization
      session_serialization = true;
      serialize_pane_viewport = true;

      # Auto layout
      auto_layout = true;
    };
  };

  # Custom configurations
  xdg.configFile = {
    # Custom Catppuccin theme for Zellij
    "zellij/themes/catppuccin-mocha.kdl".text = ''
      themes {
        catppuccin-mocha {
          bg "#181825"
          fg "#cdd6f4"
          red "#f38ba8"
          green "${accentColor}"
          blue "#89b4fa"
          yellow "#f9e2af"
          magenta "#f5c2e7"
          orange "${accentColor}"
          cyan "#94e2d5"
          black "#11111b"
          white "#ffffff"
        }
      }
    '';

    # Layouts
    "zellij/layouts/default.kdl".text = ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }
          children
          pane size=2 borderless=true {
            plugin location="zellij:status-bar"
          }
        }

        tab name="main" {
          pane
        }
      }
    '';

    "zellij/layouts/dev.kdl".text = ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
          }
          children
          pane size=2 borderless=true {
            plugin location="zellij:status-bar"
          }
        }

        tab name="editor" {
          pane
        }

        tab name="terminal" {
          pane split_direction="vertical" {
            pane
            pane
          }
        }

        tab name="logs" {
          pane
        }
      }
    '';
  };
}
