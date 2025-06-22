{
  description = "Nixos Configuration with Lix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";

    catppuccin.url = "github:catppuccin/nix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];

      perSystem = {pkgs, ...}: let
        # Allow unfree packages for development shell
        pkgsUnfree = import inputs.nixpkgs {
          inherit (pkgs) system;
          config.allowUnfree = true;
        };
      in {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              lix # Modern CppNix replacement
              alejandra # Nix formatter
              statix # Nix linter
              deadnix # Dead code detection
              pkgsUnfree.claude-code # Unfree package
            ];
          };

          # Language-specific development shells
          rust = import ./dev-shells/rust.nix {inherit pkgs;};
          python = import ./dev-shells/python.nix {inherit pkgs;};
          javascript = import ./dev-shells/javascript.nix {inherit pkgs;};
          nix = import ./dev-shells/nix.nix {inherit pkgs;};
          nixos = import ./dev-shells/nixos.nix {inherit pkgs;};
        };
      };

      flake = {
        nixosConfigurations = {
          h4wkeye-dev = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
              lib = inputs.nixpkgs.lib.extend (final: _: import ./lib {lib = final;});
            };
            modules =
              [
                # Lix integration
                inputs.lix-module.nixosModules.default

                # Core system configuration
                ./hosts/h4wkeye-dev

                # Home Manager as NixOS module for unified management
                inputs.home-manager.nixosModules.home-manager

                # Catppuccin theming
                inputs.catppuccin.nixosModules.catppuccin

                # Centralized module imports
                ./modules
              ]
              ++ [
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;

                    # Pass inputs to home-manager modules
                    extraSpecialArgs = {inherit inputs;};

                    # User configurations
                    users.h4wkeye = {
                      imports = [./home];

                      # Override defaults for this specific user
                      home = {
                        username = "h4wkeye";
                        homeDirectory = "/home/h4wkeye";
                      };

                      programs.git = {
                        userName = "PawlakMarek";
                        userEmail = "26022173+PawlakMarek@users.noreply.github.com";
                      };
                    };

                    # Shared modules available to all users
                    sharedModules = [
                      inputs.nixvim.homeManagerModules.nixvim
                      # ./home/modules # Uncomment when you add custom home modules
                    ];
                  };
                }
              ];
          };
        };

        # Export lib for use in other flakes
        lib = inputs.nixpkgs.lib.extend (final: _: import ./lib {lib = final;});

        # Templates for sharing
        templates = {
          basic-module = {
            path = ./templates/basic-module.nix;
            description = "Template for creating new NixOS modules";
          };
          user-config = {
            path = ./templates/user-config-example.nix;
            description = "Example of user configuration overrides";
          };
        };
      };
    };
}
