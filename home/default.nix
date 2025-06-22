{lib, ...}: {
  # Core programs
  programs = {
    nixvim = {
      enable = true;
    };

    git = {
      enable = true;
      userName = lib.mkDefault "user";
      userEmail = lib.mkDefault "user@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;

        # Better diff and merge tools
        diff.algorithm = "patience";
        merge.conflictstyle = "diff3";

        # Security
        transfer.fsckobjects = true;
        fetch.fsckobjects = true;
        receive.fsckObjects = true;
      };

      aliases = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };

    # Let Home Manager install and manage itself
    home-manager.enable = true;
  };

  imports = [
    ./programs/shell.nix
    ./programs/cli-tools.nix
  ];

  # Home Manager settings
  home = {
    username = lib.mkDefault "user";
    homeDirectory = lib.mkDefault "/home/user";
    stateVersion = "25.05";
  };
}
