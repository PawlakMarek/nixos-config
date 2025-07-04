{
  pkgs,
  flakeRoot,
}: let
  # Shell cleanup script for environment switching
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
  # Create a wrapper script that can access dev shells from anywhere
  devShellWrapper = pkgs.writeShellScriptBin "dev-shell" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Configuration
    FLAKE_ROOT="${flakeRoot}"

    # Available dev shells
    AVAILABLE_SHELLS=("rust" "python" "javascript" "nix" "nixos" "default")

    # Help function
    show_help() {
      echo "Usage: dev-shell [SHELL_NAME]"
      echo ""
      echo "Available development shells:"
      for shell in "''${AVAILABLE_SHELLS[@]}"; do
        echo "  $shell"
      done
      echo ""
      echo "Examples:"
      echo "  dev-shell rust      # Enter Rust development environment"
      echo "  dev-shell python    # Enter Python development environment"
      echo "  dev-shell           # Show this help and available shells"
      echo ""
      echo "This command works from any directory and will enter the specified"
      echo "development environment with all required tools and dependencies."
    }

    # Check if flake directory exists
    if [[ ! -d "$FLAKE_ROOT" ]]; then
      echo "Error: Flake directory not found at $FLAKE_ROOT"
      echo "Please ensure your nixos-config is available at the expected location."
      exit 1
    fi

    # If no arguments provided, show help
    if [[ $# -eq 0 ]]; then
      show_help
      exit 0
    fi

    # Get the shell name
    SHELL_NAME="$1"

    # Check if the shell name is valid
    if [[ ! " ''${AVAILABLE_SHELLS[*]} " =~ " $SHELL_NAME " ]]; then
      echo "Error: Unknown shell '$SHELL_NAME'"
      echo ""
      show_help
      exit 1
    fi

    # Store current directory
    ORIGINAL_DIR="$(pwd)"

    # Change to flake directory and enter the dev shell
    echo "🚀 Entering $SHELL_NAME development environment..."
    echo "📁 Current directory: $ORIGINAL_DIR"
    echo "🔧 Using flake from: $FLAKE_ROOT"
    echo ""

    # Export the original directory so scripts inside can use it
    export DEV_SHELL_ORIGINAL_DIR="$ORIGINAL_DIR"

    # Enter the dev shell with the appropriate working directory
    cd "$FLAKE_ROOT"

    # Store the user's current shell before entering dev environment
    ORIGINAL_SHELL="$SHELL"

    # Use shell cleanup script
    SHELL_CLEANUP_SCRIPT='${cleanAllShells}'

    # Shell re-initialization script
    SHELL_INIT_SCRIPT='
      # Re-initialize starship for the target shell
      if command -v starship >/dev/null 2>&1; then
        case "$SHELL" in
          */bash)
            export STARSHIP_SHELL=bash
            eval "$(starship init bash --print-full-init)"
            ;;
          */zsh)
            export STARSHIP_SHELL=zsh
            eval "$(starship init zsh)"
            ;;
        esac
      fi
    '

    # Special handling for nixos dev shell - always start in nixos-config directory
    if [[ "$SHELL_NAME" == "nixos" ]]; then
      echo "🏗️  Starting in NixOS configuration directory"
      exec nix develop ".#$SHELL_NAME" --command bash -c "
        cd '$FLAKE_ROOT'
        $SHELL_CLEANUP_SCRIPT
        $SHELL_INIT_SCRIPT
        exec '$ORIGINAL_SHELL'
      "
    else
      # For other dev shells, preserve the original directory
      exec nix develop ".#$SHELL_NAME" --command bash -c "
        cd '$ORIGINAL_DIR'
        $SHELL_CLEANUP_SCRIPT
        $SHELL_INIT_SCRIPT
        exec '$ORIGINAL_SHELL'
      "
    fi
  '';

  # Create individual shell commands for convenience
  rustShell = pkgs.writeShellScriptBin "rust-dev" ''
    exec ${devShellWrapper}/bin/dev-shell rust "$@"
  '';

  pythonShell = pkgs.writeShellScriptBin "python-dev" ''
    exec ${devShellWrapper}/bin/dev-shell python "$@"
  '';

  jsShell = pkgs.writeShellScriptBin "js-dev" ''
    exec ${devShellWrapper}/bin/dev-shell javascript "$@"
  '';

  nixShell = pkgs.writeShellScriptBin "nix-dev" ''
    exec ${devShellWrapper}/bin/dev-shell nix "$@"
  '';

  nixosShell = pkgs.writeShellScriptBin "nixos-dev" ''
    exec ${devShellWrapper}/bin/dev-shell nixos "$@"
  '';
in {
  # Export the wrapper and convenience commands
  inherit devShellWrapper;
  devShellCommands = [
    devShellWrapper
    rustShell
    pythonShell
    jsShell
    nixShell
    nixosShell
  ];
}
