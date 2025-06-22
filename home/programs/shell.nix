{config, ...}: {
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

        # Development
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
      };

      initContent = ''
        # Custom prompt
        autoload -U colors && colors
        PS1="%{$fg[cyan]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ "

        # Auto-cd into directory
        setopt AUTO_CD

        # Better history search
        bindkey "^[[A" history-search-backward
        bindkey "^[[B" history-search-forward
      '';
    };

    bash = {
      enable = true;
      enableCompletion = true;

      inherit (config.programs.zsh) shellAliases;

      bashrcExtra = ''
        # Custom prompt
        PS1='\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ '
      '';
    };

    starship = {
      enable = true;
      settings = {
        format = "$all$character";
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
        };

        git_branch = {
          format = "[$symbol$branch]($style) ";
        };

        nix_shell = {
          format = "via [$symbol$state]($style) ";
          symbol = "❄️ ";
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
