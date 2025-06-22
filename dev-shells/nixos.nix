{pkgs}:
pkgs.mkShell {
  name = "nixos";

  buildInputs = with pkgs; [
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
    claude-code # Claude Code CLI

    # Editor (if needed)
    neovim
  ];

  shellHook = ''
    echo "🏗️  NixOS configuration development environment loaded"
    echo "📍 Current directory: $(pwd)"
    echo ""
    echo "Available commands:"
    echo "  alejandra .         - Format all Nix files"
    echo "  statix check .      - Lint Nix files"
    echo "  deadnix .           - Find dead code"
    echo "  nix flake check     - Validate flake"
    echo "  nixos-rebuild build --flake .#h4wkeye-dev - Test build"
    echo "  nixos-rebuild switch --flake .#h4wkeye-dev - Apply changes"
    echo "  claude              - Claude Code CLI"
    echo ""
    echo "Git shortcuts available:"
    echo "  gs, ga, gc, gp, gl, gd, gb, gco, etc."
  '';
}
