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

# Enter development environment
nix develop

# Format all Nix files
alejandra .

# Lint and check for issues
statix check .
deadnix .
nix flake check

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
- Development tools (nixvim, git, firefox) and shell configuration

### Recent Improvements (2025-06-22)

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

### Next Development Priorities

1. **NixVim configuration**: Comprehensive editor setup
2. **Development shells**: Language-specific environments  
3. **Module templates**: Standardized module creation templates
4. **Testing framework**: Module validation and integration tests
5. **Community templates**: Shareable configuration templates

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

## Resources & References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Lix Documentation](https://lix.systems/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [NixVim Configuration](https://nix-community.github.io/nixvim/)
- [SOPS-Nix Documentation](https://github.com/Mic92/sops-nix)
