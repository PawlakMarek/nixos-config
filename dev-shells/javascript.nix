{pkgs}:
pkgs.mkShell {
  name = "javascript";

  buildInputs = with pkgs; [
    # Node.js
    nodejs_24
    corepack # Package manager manager (pnpm, yarn)

    # Development tools
    typescript
    eslint
    prettier

    # Additional tools
    nodePackages.npm-check-updates
    nodePackages.serve
  ];

  shellHook = ''
    echo "🚀 JavaScript/TypeScript development environment loaded"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"

    # Note: corepack is available but needs to be enabled per-project
    # Run 'corepack enable' in your project directory to use pnpm/yarn

    echo "Available package managers:"
    echo "  npm (default, ready to use)"
    echo "  pnpm (run 'corepack enable && corepack use pnpm@latest')"
    echo "  yarn (run 'corepack enable && corepack use yarn@stable')"
  '';
}
