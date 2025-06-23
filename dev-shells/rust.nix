{pkgs}:
pkgs.mkShell {
  name = "rust";

  buildInputs = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    rustPackages.clippy
    rust-analyzer

    # Development tools
    pkg-config
    openssl

    # Additional tools
    cargo-watch
    cargo-edit
    cargo-audit
  ];

  env = {
    RUST_BACKTRACE = "1";
  };

  shellHook = ''
    echo "🦀 Rust development environment loaded"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"

    # Ensure Home Manager shells take priority over nix store shells
    # This fixes the bash/zsh prompt formatting issues in dev shells
    export PATH="/etc/profiles/per-user/$(whoami)/bin:$PATH"
  '';
}
