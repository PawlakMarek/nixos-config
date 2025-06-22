{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # File management
    eza # Better ls
    bat # Better cat
    fd # Better find
    ripgrep # Better grep
    tree
    du-dust # Better du
    duf # Better df

    # Archives
    unzip
    p7zip

    # Network tools
    wget
    curl
    httpie

    # System monitoring
    htop
    btop
    neofetch

    # Development tools
    jq # JSON processor
    yq # YAML processor

    # Git tools
    git-crypt
    github-cli

    # Nix tools
    nix-tree
    nix-du
    nixpkgs-review
  ];

  programs = {
    eza = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    bat = {
      enable = true;
      config = {
        theme = lib.mkDefault "TwoDark";
        pager = "less -FR";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      defaultCommand = "fd --type f";
      defaultOptions = [
        "--height 40%"
        "--border"
        "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      options = [
        "--cmd cd"
      ];
    };

    mcfly = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      keyScheme = "vim";
    };
  };
}
