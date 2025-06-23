{pkgs}:
pkgs.mkShell {
  name = "nix";

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

    # Additional tools
    cachix
    nix-prefetch-git
    nix-prefetch-github
  ];

  shellHook = ''
    echo "❄️ Nix development environment loaded"
    echo "Lix version: $(nix --version)"
    echo "Alejandra version: $(alejandra --version)"

    echo "Available commands:"
    echo "  alejandra . - Format Nix files"
    echo "  statix check . - Lint Nix files"
    echo "  deadnix . - Find dead code"
    echo "  nix flake check - Validate flake"

    # Ensure Home Manager shells take priority over nix store shells
    # This fixes the bash/zsh prompt formatting issues in dev shells
    export PATH="/etc/profiles/per-user/$(whoami)/bin:$PATH"
  '';
}
