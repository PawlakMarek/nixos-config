{pkgs}: let
  # Allow unfree packages for this shell
  pkgsUnfree = import pkgs.path {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in
  pkgs.mkShell {
    name = "nixos";

    buildInputs = with pkgs;
      [
        # Nix tools
        lix
        nix-output-monitor
        nix-tree
        nix-du
        nixpkgs-review

        # Formatters and linters
        alejandra
        statix
        deadnix

        # Development tools
        nixd # Nix language server
        nil # Alternative Nix language server

        # Additional tools for NixOS development
        cachix
        nix-prefetch-git
        nix-prefetch-github
        nix-index

        # System tools
        git
        gh # GitHub CLI
        nvd # Nix version diff tool

        # Editor (if needed)
        neovim

        # Custom dev shell commands
        (writeShellScriptBin "qc" ''
          #!/usr/bin/env bash
          set -euo pipefail

          NIXOS_CONFIG_DIR="$HOME/nixos-config"
          HOST_NAME=$(hostname)

          echo "🔍 Running quality checks from $(pwd)..."
          (
            cd "$NIXOS_CONFIG_DIR" || { echo "❌ Could not change to $NIXOS_CONFIG_DIR"; exit 1; }
            echo "📝 Formatting code..."
            alejandra . && \
            echo "🔍 Checking for linting issues..." && \
            statix check . && \
            echo "💀 Checking for dead code..." && \
            deadnix . && \
            echo "✅ Validating flake..." && \
            nix flake check && \
            echo "🏗️  Testing build..." && \
            nixos-rebuild build --flake ".#$HOST_NAME" && \
            echo "✅ All quality checks passed!"
          )
        '')

        (writeShellScriptBin "qr" ''
          #!/usr/bin/env bash
          set -euo pipefail

          NIXOS_CONFIG_DIR="$HOME/nixos-config"
          HOST_NAME=$(hostname)

          echo "🚀 Quick rebuild from $(pwd)..."
          (
            cd "$NIXOS_CONFIG_DIR" || { echo "❌ Could not change to $NIXOS_CONFIG_DIR"; exit 1; }
            echo "🔄 Applying configuration..."
            sudo nixos-rebuild switch --flake ".#$HOST_NAME" && \
            echo "✅ System rebuilt successfully!"
          )
        '')
      ]
      ++ [
        # Unfree packages
        pkgsUnfree.claude-code
      ];

    shellHook = ''
      echo "🏗️  NixOS configuration development environment loaded"
      echo "📍 Current directory: $(pwd)"
      echo ""

      # Dynamically determine paths and hostname
      NIXOS_CONFIG_DIR="$HOME/nixos-config"
      HOST_NAME=$(hostname)

      # Define quality check function
      qc() {
        echo "🔍 Running quality checks from $(pwd)..."
        (
          cd "$NIXOS_CONFIG_DIR" || { echo "❌ Could not change to $NIXOS_CONFIG_DIR"; return 1; }
          echo "📝 Formatting code..."
          alejandra . && \
          echo "🔍 Checking for linting issues..." && \
          statix check . && \
          echo "💀 Checking for dead code..." && \
          deadnix . && \
          echo "✅ Validating flake..." && \
          nix flake check && \
          echo "🏗️  Testing build..." && \
          nixos-rebuild build --flake ".#$HOST_NAME" && \
          echo "✅ All quality checks passed!"
        )
      }

      # Define quick rebuild function
      qr() {
        echo "🚀 Quick rebuild from $(pwd)..."
        (
          cd "$NIXOS_CONFIG_DIR" || { echo "❌ Could not change to $NIXOS_CONFIG_DIR"; return 1; }
          echo "🔄 Applying configuration..."
          sudo nixos-rebuild switch --flake ".#$HOST_NAME" && \
          echo "✅ System rebuilt successfully!"
        )
      }

      echo "Available commands:"
      echo "  qc                  - Run complete quality check pipeline"
      echo "  qr                  - Quick rebuild (nixos-rebuild switch)"
      echo "  alejandra .         - Format all Nix files"
      echo "  statix check .      - Lint Nix files"
      echo "  deadnix .           - Find dead code"
      echo "  nix flake check     - Validate flake"
      echo "  nixos-rebuild build --flake .#$HOST_NAME - Test build"
      echo "  nixos-rebuild switch --flake .#$HOST_NAME - Apply changes"
      echo "  claude              - Claude Code CLI"
      echo ""
      echo "Git shortcuts available:"
      echo "  gs, ga, gc, gp, gl, gd, gb, gco, etc."
    '';
  }
