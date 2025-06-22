{
  lib,
  pkgs,
  ...
}:
with lib; {
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator " "
          set -g @catppuccin_window_middle_separator " █"
          set -g @catppuccin_window_number_position "right"
          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_status_modules_right "directory user host session"
          set -g @catppuccin_status_left_separator  " "
          set -g @catppuccin_status_right_separator ""
          set -g @catppuccin_status_right_separator_inverse "no"
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"
          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
    ];

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",tmux-256color:RGB"

      # Faster command sequences
      set -s escape-time 10

      # Increase repeat timeout
      set -sg repeat-time 600

      # Increase scrollback buffer size
      set -g history-limit 50000

      # Enable focus events
      set -g focus-events on

      # Rather than constraining window size to the maximum size of any client
      # connected to the *session*, constrain window size to the maximum size of any
      # client connected to *that window*
      setw -g aggressive-resize on

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off

      # Window and pane numbering
      set -g renumber-windows on
      setw -g pane-base-index 1

      # Automatically set window title
      set -g automatic-rename on
      set -g set-titles on

      # Key bindings
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Vim-like pane switching
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with vim keys
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Quick pane cycling
      unbind ^A
      bind ^A select-pane -t :.+

      # Reload config file
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

      # Copy mode improvements
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Window navigation
      bind -n C-S-Left previous-window
      bind -n C-S-Right next-window

      # Session management
      bind C-c new-session
      bind C-f command-prompt -p find-session 'switch-client -t %%'

      # Better window splitting
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Quick window selection
      bind -r C-h select-window -t :-
      bind -r C-l select-window -t :+

      # Continuum auto-save interval
      set -g @continuum-save-interval '15'
      set -g @continuum-restore 'on'

      # Resurrect capture pane contents
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
    '';
  };
}
