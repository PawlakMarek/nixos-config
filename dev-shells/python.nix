{pkgs}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python
    python313
    uv # Modern Python package manager

    # Development tools
    ruff # Fast linter and formatter (replaces black, isort, flake8)
    python313Packages.mypy
    python313Packages.pytest

    # Additional tools
    python313Packages.ipython
    python313Packages.jupyter
  ];

  shellHook = ''
    echo "🐍 Python development environment loaded"
    echo "Python version: $(python --version)"
    echo "uv version: $(uv --version)"
    echo "ruff version: $(ruff --version)"

    # Initialize uv project if pyproject.toml doesn't exist
    if [ ! -f "pyproject.toml" ]; then
      echo "To initialize a new project: uv init"
    fi

    echo "To create virtual environment: uv venv"
    echo "To activate virtual environment: source .venv/bin/activate"
    echo "To install dependencies: uv add <package>"
    echo "To run with uv: uv run <command>"
  '';
}
