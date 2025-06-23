# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with this ultra-modular NixOS configuration repository.

## Project Vision & Goals

This is an **ultra-modular, production-ready NixOS configuration** using Lix that emphasizes:

- **Community Shareability**: Each module can be easily adopted by other users
- **Self-Discovery**: Automatic module detection and hardware-based feature enabling
- **Developer-Centric**: Optimized for software development workflows
- **Performance**: Laptop-optimized with battery life and thermal considerations
- **Security**: LUKS encryption, TPM integration, and hardening options
- **Maintainability**: Clear module boundaries and comprehensive documentation

**Target Hardware**: Dell Latitude 7440 (Intel i7, 32GB RAM, 1TB NVMe) dual-booting Windows/NixOS

## Architecture Philosophy

### Ultra-Modular Design Principles

1. **Single Responsibility**: Each module handles one specific concern
2. **Composability**: Modules can be combined without conflicts
3. **Conditional Loading**: Features auto-enable based on hardware/context
4. **Option-Driven**: All behavior controlled through well-defined options
5. **Self-Documenting**: Clear options documentation and usage examples

### Technology Stack

- **Package Manager**: Lix 2.92+ "Bombe glacée" (modern CppNix replacement)
- **NixOS Version**: 25.05 "Warbler" with Linux 6.12 LTS / 6.14 kernels
- **Architecture**: Flake-parts for advanced flake structure
- **Configuration Management**: Home Manager as NixOS module
- **Secrets**: SOPS-Nix for encrypted secrets management
- **Editor**: NixVim for declarative Neovim configuration

## Directory Structure & Module Organization

```
nixos-config/
├── flake.nix                 # Main flake with flake-parts architecture
├── flake.lock
├── README.md
├── CLAUDE.md                 # This file
├── hosts/
│   └── h4wkeye-dev/          # Host-specific configurations
│       ├── default.nix       # Host module imports
│       ├── configuration.nix # Core system config
│       └── hardware-configuration.nix
├── modules/
│   ├── core/                 # Essential system modules
│   │   ├── security/         # Security modules (LUKS, hardening)
│   │   ├── hardware-detection.nix
│   │   └── performance.nix
│   ├── development/          # Development tools and environments
│   │   ├── languages/        # Language-specific dev shells
│   │   ├── editors/          # Editor configurations
│   │   └── containers/       # Docker, Podman, K8s
│   ├── desktop/              # Desktop environments and window managers
│   │   ├── xfce/             # XFCE configuration
│   │   ├── gnome/            # GNOME configuration
│   │   └── hyprland/         # Wayland compositor
│   ├── gaming/               # Gaming-specific configurations
│   └── services/             # System services and daemons
├── home/                     # Home Manager configurations
│   ├── programs/             # Per-program configurations
│   │   ├── shell.nix         # Shell configuration
│   │   └── cli-tools.nix     # CLI tool setup
│   ├── profiles/             # Complete user profiles
│   │   ├── developer.nix     # Developer workstation
│   │   ├── minimal.nix       # Minimal setup
│   │   └── gaming.nix        # Gaming-focused
│   └── modules/              # Custom home-manager modules
├── lib/                      # Helper functions and utilities
│   ├── helpers.nix           # Module discovery and conditional loading
│   ├── hardware.nix          # Hardware detection utilities
│   └── default.nix          # Lib exports
├── overlays/                 # Nixpkgs overlays and package customizations
├── dev-shells/               # Language-specific development environments
│   ├── rust.nix
│   ├── python.nix
│   ├── nix.nix
│   └── javascript.nix
├── secrets/                  # SOPS-encrypted secrets
│   ├── secrets.yaml
│   └── .sops.yaml
└── templates/                # Community-shareable templates
    ├── basic-system/
    ├── developer-workstation/
    └── minimal-server/
```

## Development Workflow

### Daily Commands

```bash
# Quick system rebuild (test locally first)
sudo nixos-rebuild switch --flake .#h4wkeye-dev

# Test build without switching
nixos-rebuild build --flake .#h4wkeye-dev

# Enter development environments (available globally from any directory)
nixos-dev    # NixOS configuration development with quality check commands
rust-dev     # Rust development environment with full toolchain
python-dev   # Python environment with modern uv package manager
js-dev       # JavaScript/TypeScript with Node.js 24 and corepack
nix-dev      # Nix language development with Lix and language servers

# Quality check automation (available in nixos-dev environment)
qc           # Complete quality check pipeline (format, lint, deadnix, flake check, build)
qr           # Quick rebuild (nixos-rebuild switch)

# Manual quality checks
alejandra .  # Format all Nix files
statix check .  # Lint and check for issues
deadnix .    # Find dead code
nix flake check  # Validate flake

# Validate module structure
nix eval .#nixosConfigurations.h4wkeye-dev.config.modules._meta
```

### Module Development Workflow

```bash
# Create new module from template
cp templates/basic-module.nix modules/category/new-module.nix

# Test module in isolation
nix eval .#nixosConfigurations.h4wkeye-dev.config.modules.category.new-module

# Add module to host configuration
# Edit hosts/h4wkeye-dev/configuration.nix to enable module

# Validate module options
nix eval --json .#nixosConfigurations.h4wkeye-dev.options.modules.category.new-module
```

### Advanced Operations

```bash
# Update specific input
nix flake lock --update-input nixpkgs

# Build for different system
nix build .#nixosConfigurations.h4wkeye-dev.config.system.build.toplevel

# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config

# Debug module evaluation
nix repl
:lf .
:p nixosConfigurations.h4wkeye-dev.config.modules
```

## Module Development Guidelines

### Creating New Modules

1. **Start with clear purpose**: What specific functionality does this module provide?
2. **Define comprehensive options**: Use proper types, defaults, and documentation
3. **Implement conditional logic**: Use `lib.mkIf` and hardware detection where appropriate
4. **Add validation**: Include assertions for invalid configurations
5. **Provide usage examples**: Document common use cases and configurations

### Module Template Pattern

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.category.module-name;
in {
  options.modules.category.module-name = {
    enable = mkEnableOption "brief description";
    
    # Add specific options here
    someOption = mkOption {
      type = types.str;
      default = "sensible-default";
      description = "Clear description of what this option does";
      example = "example-value";
    };
  };

  config = mkIf cfg.enable {
    # Module implementation
    assertions = [
      {
        assertion = condition;
        message = "Helpful error message";
      }
    ];
    
    # Add configuration here
  };
}
```

### Hardware Detection Patterns

```nix
# Detect laptop hardware
services.tlp.enable = lib.mkIf (builtins.pathExists /sys/class/power_supply/BAT0) true;

# Detect specific CPU
boot.kernelModules = lib.optionals (config.hardware.cpu.intel.updateMicrocode) ["intel_pstate"];

# Conditional based on hostname
services.someService.enable = lib.mkIf (lib.hasPrefix "laptop" config.networking.hostName) true;
```

## Configuration Patterns & Best Practices

### Lix-Specific Considerations

- Use Lix module instead of standard Nix: `inputs.lix-module.nixosModules.default`
- Leverage Lix's enhanced features and performance improvements
- Follow Lix community conventions and documentation
- Test compatibility with both Lix and CppNix when possible

### Security Hardening

- LUKS encryption with TPM support for convenience
- Secure boot integration where appropriate
- Firewall and network security by default
- Minimal attack surface through selective service enabling

### Performance Optimization

- SSD-specific optimizations (TRIM, I/O schedulers)
- Memory management (zram, swap optimization)
- CPU scaling and thermal management
- Nix store optimization and garbage collection

### Development Environment Integration

- Language-specific dev shells with consistent tooling
- Editor configuration through NixVim
- Container support (Docker, Podman) when needed
- CI/CD integration and reproducible builds

## SOPS Secrets Management

```bash
# Edit encrypted secrets
sops secrets/secrets.yaml

# Re-encrypt for new keys
sops updatekeys secrets/secrets.yaml

# Validate secrets in configuration
nix eval .#nixosConfigurations.h4wkeye-dev.config.sops.secrets
```

### Secret Usage Pattern

```nix
sops.secrets."service/password" = {
  sopsFile = ../secrets/secrets.yaml;
  owner = "username";
  group = "groupname";
  mode = "0400";
};

services.someService = {
  enable = true;
  passwordFile = config.sops.secrets."service/password".path;
};
```

## Current System State

### Active Configuration

- **Host**: h4wkeye-dev (x86_64-linux)
- **Boot**: systemd-boot with Linux 6.12+ kernel
- **Encryption**: LUKS with UUID `a96ce829-b237-435a-9d66-d49fe274dbe2`
- **Desktop**: XFCE on X11 with Catppuccin theming
- **User**: h4wkeye with wheel group membership
- **Home Manager**: Integrated as NixOS module with comprehensive user configuration
- **Module System**: Centralized imports through `modules/default.nix`

### Enabled Modules

- `modules.core.audio`: PipeWire audio system with desktop integration
- `modules.core.bluetooth`: Bluetooth support with audio integration
- `modules.core.hardware-detection`: Automatic hardware optimization
- `modules.core.networking`: Core networking with secure defaults
- `modules.core.performance`: SSD, memory, and power management
- `modules.core.security.firewall`: Advanced firewall with preset configurations
- `modules.core.security.hardening`: System security hardening (NEW)
- `modules.core.security.luks`: Full-disk encryption with TPM support options
- `modules.core.security.sops`: SOPS encrypted secrets management
- `modules.desktop.theming`: System-wide Catppuccin theming
- `modules.desktop.xfce`: XFCE desktop environment with customizations
- Development tools (nixvim, git, firefox, zellij) and enhanced shell configuration
- Global dev shell system with cross-shell compatibility fixes

### Development History & Improvements

#### Latest Improvements (2025-06-23)

1. **Development Environment Overhaul**:
   - **Zellij Integration**: Complete terminal multiplexer setup with Catppuccin Mocha theming
   - **Dev Shell Enhancement**: All environments now show specific names (rust-dev, python-dev, etc.)
   - **Global Accessibility**: Dev shells accessible from any directory via wrapper system
   - **Cross-Shell Compatibility**: Fixed critical bash/zsh prompt formatting issues in dev environments

2. **Zellij Configuration**:
   - Implemented comprehensive Catppuccin Mocha theming with dynamic accent colors
   - Increased scroll buffer to 50000 for consistency with other terminal configurations
   - Added development-focused layouts (editor, terminal, logs)
   - Proper integration with system-wide theming configuration

3. **Dev Shell Infrastructure**:
   - Created global dev shell wrapper system (`lib/dev-shell-wrapper.nix`)
   - Added quality check automation (qc/qr commands) for nixos development
   - Implemented dynamic hostname detection and path resolution
   - Fixed PATH prioritization to use Home Manager shell binaries

4. **Shell Environment Fixes**:
   - **Root Cause Identified**: Dev shells were using nix store binaries instead of Home Manager binaries
   - **Solution Implemented**: Modified PATH to prioritize `/etc/profiles/per-user/$(whoami)/bin`
   - **Impact**: Eliminated bind/complete command errors and escape sequence artifacts
   - **Result**: Consistent shell behavior inside and outside dev environments

5. **Language-Specific Environments**:
   - **Rust**: Enhanced with clippy, rust-analyzer, cargo-watch, and audit tools
   - **Python**: Modern tooling with uv package manager, ruff linter, mypy, pytest
   - **JavaScript**: Node.js 24 with corepack for pnpm/yarn support, TypeScript, ESLint
   - **Nix**: Comprehensive Lix-based development with language servers and tools
   - **NixOS**: Dedicated environment with quality check commands and system rebuild tools

#### Previous Improvements (2025-06-22)

1. **Modular Architecture Cleanup**: 
   - Created centralized `modules/default.nix` for organized imports
   - Eliminated manual module imports in flake.nix
   - Added comprehensive module metadata and introspection

2. **Code Deduplication**:
   - Created shared `lib/theme-helpers.nix` for theme name generation
   - Removed duplicate string manipulation across modules
   - Consolidated theme configuration patterns

3. **Separation of Concerns**:
   - Extracted kernel hardening from LUKS module to `modules.core.security.hardening`
   - Separated desktop-specific logic from core modules
   - Improved option organization and validation

4. **Configuration Improvements**:
   - Fixed hardcoded values in theming (cursor packages, theme names)
   - Replaced magic numbers with named constants in XFCE configuration
   - Added proper assertions and validation throughout modules
   - Fixed typos and improved error messages

### Current Development Environment Features

1. **Terminal Multiplexing**: 
   - Zellij with Catppuccin Mocha theming and 50000 line scroll buffer
   - Pre-configured development layouts (editor, terminal, logs)
   - Dynamic accent color integration with system theming

2. **Development Shells** (Available globally from any directory):
   ```bash
   nixos-dev    # NixOS configuration development with qc/qr commands
   rust-dev     # Rust development with full toolchain
   python-dev   # Python with modern uv package manager  
   js-dev       # JavaScript/TypeScript with Node.js 24
   nix-dev      # Nix language development with Lix
   ```

3. **Quality Automation**:
   ```bash
   # In nixos-dev environment
   qc    # Complete quality check pipeline (format, lint, build)
   qr    # Quick rebuild (nixos-rebuild switch)
   ```

4. **Shell Compatibility**:
   - Seamless switching between bash and zsh within dev environments
   - Proper starship prompt initialization for both shells
   - Home Manager shell configuration takes precedence over nix store binaries

### Next Development Priorities

1. **NixVim configuration**: Comprehensive declarative Neovim setup
2. **Module templates**: Standardized templates for community sharing
3. **Testing framework**: Automated module validation and integration tests
4. **Documentation generation**: Automated option documentation from module definitions
5. **Community templates**: Ready-to-use configuration templates for different use cases

## Troubleshooting Common Issues

### Build Failures

```bash
# Clean build cache
nix-collect-garbage -d

# Rebuild with verbose output
nixos-rebuild switch --flake .#h4wkeye-dev --show-trace -v

# Check specific module evaluation
nix eval --show-trace .#nixosConfigurations.h4wkeye-dev.config.modules.category.module
```

### LUKS/Encryption Issues

```bash
# Check LUKS device status
sudo cryptsetup status cryptroot

# Verify device UUID
sudo blkid /dev/nvme0n1p6

# TPM debugging
sudo tpm2_getcap properties-variable
```

### Module Import Issues

- Verify module path in imports list
- Check for syntax errors with `nix eval`
- Ensure proper option types and defaults
- Validate assertions and conditions

### Dev Shell and Terminal Issues

**Problem**: Shell prompt formatting errors when switching shells in dev environments
```
bash: bind: command not found
bash: complete: not a shell builtin
\[\]\[\]\[\]
```

**Root Cause**: Dev shells were using nix store shell binaries instead of Home Manager binaries

**Solution**: 
- All dev shells now modify PATH to prioritize Home Manager binaries
- Use `/etc/profiles/per-user/$(whoami)/bin/bash` instead of `/nix/store/.../bash`
- Ensures proper starship configuration and cross-shell compatibility

**Testing**:
```bash
# Enter any dev shell
nixos-dev

# Test shell switching (should work without errors)
bash
zsh

# Verify correct binary is used
which bash  # Should show /etc/profiles/per-user/h4wkeye/bin/bash
```

**Zellij Issues**:
- If text is hard to read, check accent color configuration in `modules.desktop.theming`
- Scroll buffer size can be adjusted in `home/programs/zellij.nix`
- Theme changes require system rebuild: `sudo nixos-rebuild switch --flake .`

### Recent Code Quality Improvements

**Modularity Enhancements:**
- All modules now follow consistent option/config patterns
- Centralized imports eliminate maintenance burden
- Shared utilities prevent code duplication
- Clear separation of concerns between modules

**Security Improvements:**
- Dedicated hardening module with comprehensive options
- Proper validation and assertions throughout
- Removal of hardcoded security-related values
- Better organization of security-related configurations

**Theme System Overhaul:**
- Dynamic theme generation using shared helpers
- Elimination of theme name duplication
- Proper cursor package selection based on configuration
- Consistent theme application across system and user levels

### Known Warnings

- `warning: unknown flake output 'homeModules'` during `nix flake check` is expected
  - This is generated by the home-manager flakeModules integration with flake-parts
  - It's a harmless warning that doesn't affect functionality
  - Can be safely ignored

## Community & Sharing

This configuration is designed to be:

- **Forkable**: Easy to adapt for different hardware/preferences
- **Educational**: Clear examples of NixOS/Lix best practices
- **Modular**: Individual modules can be extracted and reused
- **Documented**: Comprehensive documentation and usage examples

When adding new features, always consider:
- Will this be useful to other NixOS users?
- Is the module self-contained and reusable?
- Are the options clearly documented?
- Does it follow established patterns and conventions?
- Have you run the complete quality check pipeline?
- Is the commit message descriptive and follows conventions?
- Does the change work in a clean build environment?

### Development Best Practices

#### Git Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): short description

Longer description explaining what changed and why.
Include breaking changes, new features, bug fixes.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or fixing tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(audio): add support for Pro Audio profile

Add specialized audio configuration for low-latency recording:
- Enable RT kernel modules when Pro Audio is detected
- Configure PipeWire for minimal latency
- Add JACK compatibility layer
- Include audio group permissions

Breaking change: Removes deprecated audio.pulseaudio option

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
"

git commit -m "fix(luks): resolve TPM unsealing timeout issue

Increase TPM operation timeout from 30s to 60s:
- Addresses slow TPM chips in older hardware
- Add retry logic for transient TPM failures
- Improve error messages for troubleshooting

Fixes #42

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
"

git commit -m "refactor(theming): extract theme helpers to shared library

Move theme generation logic to lib/theme-helpers.nix:
- Eliminates code duplication between modules
- Provides consistent theme naming across system
- Adds validation for theme variants and accents
- Improves maintainability

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
"
```

#### Code Review Checklist

Before merging any changes:

- [ ] **Functionality**: Does the code work as intended?
- [ ] **Quality**: Passes alejandra, statix, deadnix, and nix flake check
- [ ] **Testing**: Builds successfully and doesn't break existing functionality
- [ ] **Documentation**: Options are documented with types, defaults, and examples
- [ ] **Patterns**: Follows established module patterns and conventions
- [ ] **Security**: No hardcoded secrets or security anti-patterns
- [ ] **Performance**: No obvious performance regressions
- [ ] **Compatibility**: Works with target NixOS versions
- [ ] **Commit**: Proper commit message and git history

## Resources & References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Lix Documentation](https://lix.systems/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [NixVim Configuration](https://nix-community.github.io/nixvim/)
- [SOPS-Nix Documentation](https://github.com/Mic92/sops-nix)

---

# Claude Code Development Standards (MANDATORY)

## Git Workflow Requirements

**CRITICAL**: Claude Code must follow these development practices for all work:

### 1. Feature Branch Workflow (MANDATORY)
- **NEVER commit directly to main branch**
- **ALWAYS create feature branches** for any development work
- Use descriptive branch names: `feature/module-name`, `fix/issue-description`, `refactor/component-name`

### 2. Code Quality Pipeline (REQUIRED BEFORE EVERY COMMIT)

Claude Code MUST run this complete pipeline before any commit:

```bash
# 1. Format code (MANDATORY)
alejandra .

# 2. Fix linting issues (MANDATORY) 
statix check .  # Must show no warnings or errors

# 3. Remove dead code (MANDATORY)
deadnix .       # Must show no dead code

# 4. Validate flake (MANDATORY)
nix flake check # Must pass without errors

# 5. Test build (MANDATORY)
nixos-rebuild build --flake .#h4wkeye-dev  # Must build successfully
```

### 3. Commit Standards (REQUIRED)

Every commit must:
- Follow Conventional Commits format
- Include Claude Code attribution
- Have descriptive commit messages explaining what and why
- Be made only after the complete quality pipeline passes

### 4. Error Handling Protocol

If ANY step in the quality pipeline fails:
1. **STOP immediately** - do not proceed with commit
2. **Fix the issue completely** - address all errors and warnings
3. **Re-run the complete pipeline** to ensure all checks pass
4. **Only then proceed** with commits and further development

### 5. Development Rules (NON-NEGOTIABLE)

1. **Always use feature branches** for any development work
2. **Run complete quality pipeline** before every commit
3. **Test builds** before considering work complete  
4. **Follow established module patterns** and conventions
5. **Never create files unless absolutely necessary** for the goal
6. **Always prefer editing existing files** to creating new ones
7. **Never proactively create documentation** unless explicitly requested

### 6. Branch Management

```bash
# Starting new work
git checkout main
git pull origin main
git checkout -b feature/descriptive-name

# During development - commit frequently
# (after running quality pipeline)
git add .
git commit -m "type(scope): description

Detailed explanation...

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Finishing work
git push origin feature/descriptive-name
# Create PR or merge to main
git checkout main
git merge feature/descriptive-name
git push origin main
git branch -d feature/descriptive-name
```

## Quality Assurance

### Code Formatting
- **alejandra** must pass without changes needed
- All Nix code must follow consistent formatting

### Linting 
- **statix** must show zero warnings or errors
- Common fixes: remove unnecessary `with`, fix deprecated syntax, optimize patterns

### Dead Code Removal
- **deadnix** must show no dead code
- Remove unused variables, functions, imports

### Flake Validation
- **nix flake check** must pass completely
- All configurations must evaluate without errors

### Build Testing
- **nixos-rebuild build** must succeed
- No breaking changes to existing functionality

These standards are NON-NEGOTIABLE and must be followed for every change, no matter how small.
