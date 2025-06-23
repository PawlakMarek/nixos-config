{
  config,
  lib,
  ...
}: let
  # Shell cleanup scripts for cross-shell compatibility
  cleanBashEnv = ''
    # Remove bash-specific starship setup that might interfere
    unset PROMPT_COMMAND 2>/dev/null || true
    unset -f starship_preexec starship_precmd 2>/dev/null || true
    unset -f starship_preexec_all starship_preexec_ps0 2>/dev/null || true
    unset STARSHIP_PROMPT_COMMAND 2>/dev/null || true
    unset STARSHIP_DEBUG_TRAP 2>/dev/null || true
  '';

  cleanAllShells = ''
    # Clear all starship-related variables
    unset STARSHIP_SHELL STARSHIP_SESSION_KEY 2>/dev/null || true
    unset STARSHIP_START_TIME STARSHIP_DURATION STARSHIP_CMD_STATUS 2>/dev/null || true
    unset STARSHIP_PIPE_STATUS STARSHIP_JOBS_COUNT STARSHIP_PROMPT_COMMAND 2>/dev/null || true
    unset STARSHIP_DEBUG_TRAP 2>/dev/null || true

    # Clear all prompt variables
    unset PS1 PS2 PS3 PS4 PROMPT PROMPT_COMMAND 2>/dev/null || true
    unset RPS1 RPROMPT 2>/dev/null || true

    # Remove all starship-related functions
    unset -f starship_preexec starship_precmd 2>/dev/null || true
    unset -f starship_preexec_all starship_preexec_ps0 2>/dev/null || true
    unset -f prompt_starship_precmd prompt_starship_preexec 2>/dev/null || true
    unset -f starship_zle-keymap-select starship_zle-keymap-select-wrapped 2>/dev/null || true
    unset __starship_preserved_zle_keymap_select 2>/dev/null || true

    # Clear completion functions that might conflict
    complete -r 2>/dev/null || true
  '';

  initBash = ''
    # Clean environment first
    ${cleanAllShells}

    # Initialize starship fresh for bash
    if command -v starship >/dev/null 2>&1; then
      export STARSHIP_SHELL=bash
      eval "$(starship init bash --print-full-init)"
    else
      # Fallback prompt without escape sequences
      PS1='[\u@\h \W]\$ '
    fi
  '';
in {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        save = 10000;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
      };

      shellAliases = {
        ll = "ls -la";
        la = "ls -la";
        l = "ls -l";
        ".." = "cd ..";
        "..." = "cd ../..";

        # Nix shortcuts
        nrs = "sudo nixos-rebuild switch --flake .";
        nrb = "nixos-rebuild build --flake .";
        nfu = "nix flake update";
        nfc = "nix flake check";

        # Git shortcuts
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        gd = "git diff";
        gb = "git branch";
        gco = "git checkout";
        gcb = "git checkout -b";
        gm = "git merge";
        gr = "git rebase";
        gst = "git stash";
        gsp = "git stash pop";
        gf = "git fetch";
        gpl = "git pull";

        # Terminal productivity
        t = "tmux";
        ta = "tmux attach";
        tl = "tmux list-sessions";
        tn = "tmux new-session -s";
        tk = "tmux kill-session -t";

        # File operations
        cp = "cp -i";
        mv = "mv -i";
        rm = "rm -i";
        mkdir = "mkdir -pv";

        # Directory shortcuts
        dl = "cd ~/Downloads";
        dt = "cd ~/Desktop";
        doc = "cd ~/Documents";
        devdir = "cd ~/dev";

        # System shortcuts
        ports = "ss -tuln";
        path = "echo $PATH | tr ':' '\n'";
        reload = "exec $SHELL";
        cls = "clear";

        # Development environment shortcuts
        dev = "dev-shell";
        rust-env = "rust-dev";
        py-env = "python-dev";
        js-env = "js-dev";
        nix-env = "nix-dev";
        nixos-env = "nixos-dev";
      };

      initContent = ''
        # Clean shell environment for zsh
        ${cleanBashEnv}

        # Auto-cd into directory
        setopt AUTO_CD

        # Better history search
        bindkey "^[[A" history-search-backward
        bindkey "^[[B" history-search-forward

        # Terminal productivity functions
        # Quick directory navigation with fuzzy finding
        cdg() {
          local dir
          dir=$(find ~/dev ~/Documents ~/Downloads -type d -maxdepth 3 2>/dev/null | fzf --height 40% --reverse)
          [ -n "$dir" ] && cd "$dir"
        }

        # Quick file editing with fuzzy finding
        fe() {
          local file
          file=$(fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --color=always {}' --height 60%)
          [ -n "$file" ] && $EDITOR "$file"
        }

        # Enhanced grep with ripgrep and fzf
        rgg() {
          rg --color=always --line-number --no-heading --smart-case "''${1:-}" |
            fzf --ansi \
                --color "hl:-1:underline,hl+:-1:underline:reverse" \
                --delimiter : \
                --preview 'bat --color=always {1} --highlight-line {2}' \
                --bind 'enter:become($EDITOR {1} +{2})'
        }

        # Git log with fzf preview
        gll() {
          git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
            fzf --ansi --no-sort --reverse --tiebreak=index \
                --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
                --bind 'enter:become(sh -c "f() { set -- \$(echo -- \"\$@\" | grep -o \"[a-f0-9]\\{7\\}\"); [ \$# -eq 0 ] || git show \$1; }; f {}")'
        }

        # Process finder with kill option
        pk() {
          local pid
          pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
          if [ -n "$pid" ]; then
            echo "$pid" | xargs kill "''${1:-9}"
          fi
        }

        # Quick tmux session switcher
        ts() {
          local session
          session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height 40% --reverse)
          if [ -n "$session" ]; then
            tmux attach-session -t "$session"
          else
            tmux new-session
          fi
        }
      '';
    };

    bash = {
      enable = true;
      enableCompletion = true;

      inherit (config.programs.zsh) shellAliases;

      bashrcExtra = ''
        # Use shell cleanup for consistent bash environment setup
        ${initBash}

        # Terminal productivity functions
        # Quick directory navigation with fuzzy finding
        cdg() {
          local dir
          dir=$(find ~/dev ~/Documents ~/Downloads -type d -maxdepth 3 2>/dev/null | fzf --height 40% --reverse)
          [ -n "$dir" ] && cd "$dir"
        }

        # Quick file editing with fuzzy finding
        fe() {
          local file
          file=$(fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --color=always {}' --height 60%)
          [ -n "$file" ] && $EDITOR "$file"
        }

        # Enhanced grep with ripgrep and fzf
        rgg() {
          rg --color=always --line-number --no-heading --smart-case "''${1:-}" |
            fzf --ansi \
                --color "hl:-1:underline,hl+:-1:underline:reverse" \
                --delimiter : \
                --preview 'bat --color=always {1} --highlight-line {2}' \
                --bind 'enter:become($EDITOR {1} +{2})'
        }

        # Git log with fzf preview
        gll() {
          git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
            fzf --ansi --no-sort --reverse --tiebreak=index \
                --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\\{7\\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' \
                --bind 'enter:become(sh -c "f() { set -- \\$(echo -- \\"\\$@\\" | grep -o \\"[a-f0-9]\\\\{7\\\\}\\"); [ \\$# -eq 0 ] || git show \\$1; }; f {}")'
        }

        # Process finder with kill option
        pk() {
          local pid
          pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
          if [ -n "$pid" ]; then
            echo "$pid" | xargs kill "''${1:-9}"
          fi
        }

        # Quick tmux session switcher
        ts() {
          local session
          session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height 40% --reverse)
          if [ -n "$session" ]; then
            tmux attach-session -t "$session"
          else
            tmux new-session
          fi
        }
      '';
    };

    starship = {
      enable = true;
      settings = {
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$cmd_duration"
          "$line_break"
          "$nix_shell"
          "$character"
        ];

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
          vimcmd_symbol = "[❮](bold green)";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
          format = "[$path]($style)[$read_only]($read_only_style) ";
          style = "bold cyan";
          read_only = "🔒";
          read_only_style = "red";
        };

        git_branch = {
          format = "[$symbol$branch(:$remote_branch)]($style) ";
          symbol = "🌱 ";
          style = "bold purple";
        };

        git_status = {
          format = "([$all_status$ahead_behind]($style))";
          style = "bold red";
          conflicted = "⚔️ ";
          ahead = "🏎️ 💨 ×$count ";
          behind = "🐌 ×$count ";
          diverged = "🔱 🏎️ 💨 ×$ahead_count 🐌 ×$behind_count ";
          untracked = "🛤️  ×$count ";
          stashed = "📦 ";
          modified = "📝 ×$count ";
          staged = "🗃️  ×$count ";
          renamed = "📛 ×$count ";
          deleted = "🗑️  ×$count ";
        };

        git_state = {
          format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
          style = "bright-black";
        };

        cmd_duration = {
          format = " ⏱️  [$duration]($style)";
          style = "yellow";
          min_time = 2000;
        };

        nix_shell = {
          format = "via [$symbol$name]($style) ";
          symbol = "❄️ ";
          style = "bold blue";
          heuristic = true;
        };

        username = {
          format = "[$user]($style)@";
          style_user = "bold blue";
          show_always = true;
        };

        hostname = {
          format = "[$hostname]($style) in ";
          style = "bold green";
          ssh_only = false;
        };
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
