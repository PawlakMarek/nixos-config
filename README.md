# Ultra-Modular NixOS Configuration

A production-ready, ultra-modular NixOS configuration designed for shareability, maintainability, and developer productivity. Built with [Lix](https://lix.systems/) and featuring comprehensive hardware detection, security hardening, and elegant theming.

[![NixOS](https://img.shields.io/badge/NixOS-25.05-blue.svg?style=flat&logo=nixos&logoColor=white)](https://nixos.org)
[![Lix](https://img.shields.io/badge/Lix-2.93+-purple.svg?style=flat)](https://lix.systems)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)

## ✨ Features

### 🏗️ **Ultra-Modular Architecture**
- **Self-Contained Modules**: Each module handles a single responsibility
- **Automatic Discovery**: Hardware-based feature detection and conditional loading
- **Community Shareable**: Individual modules can be easily extracted and reused
- **Centralized Management**: Organized imports through `modules/default.nix`

### 🔒 **Security First**
- **LUKS Encryption**: Full-disk encryption with optional TPM unlocking
- **Kernel Hardening**: Comprehensive security hardening options
- **Firewall Management**: Advanced firewall with preset configurations
- **Secrets Management**: SOPS-encrypted secrets with age encryption
- **Secure Boot Ready**: TPM integration and secure boot support

### 🎨 **Beautiful Desktop Experience**
- **XFCE Environment**: Lightweight, customizable desktop
- **Catppuccin Theming**: Consistent system-wide theming
- **Dynamic Configuration**: Theme generation based on preferences
- **Font Optimization**: Carefully selected fonts with proper rendering

### ⚡ **Developer Focused**
- **NixVim Integration**: Declarative Neovim configuration
- **Development Shells**: Language-specific environments (Rust, Python, JS, Nix)
- **Home Manager**: Comprehensive user configuration management
- **Git Integration**: Optimized git configuration with useful aliases

### 🔧 **Hardware Optimized**
- **Laptop-Specific**: Optimized for Dell Latitude 7440
- **Power Management**: Battery optimization and thermal management
- **SSD Optimization**: TRIM support and I/O scheduler tuning
- **Audio/Bluetooth**: PipeWire with seamless device integration

## 🚀 Quick Start

### Prerequisites

- NixOS 25.05+ installed
- [Lix](https://lix.systems/) (optional but recommended)
- Basic familiarity with Nix flakes

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/nixos-config.git
   cd nixos-config
   ```

2. **Generate hardware configuration:**
   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/your-hostname/hardware-configuration.nix
   ```

3. **Create host configuration:**
   ```bash
   cp -r hosts/h4wkeye-dev hosts/your-hostname
   # Edit hosts/your-hostname/configuration.nix to match your setup
   ```

4. **Update flake.nix:**
   ```nix
   nixosConfigurations = {
     your-hostname = inputs.nixpkgs.lib.nixosSystem {
       # ... configuration
       modules = [
         ./hosts/your-hostname
         # ... other modules
       ];
     };
   };
   ```

5. **Build and switch:**
   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

## 📁 Project Structure

```
nixos-config/
├── 📄 flake.nix                 # Main flake configuration with flake-parts
├── 📄 flake.lock                # Dependency lockfile
├── 📄 README.md                 # This file
├── 📄 CLAUDE.md                 # Detailed development documentation
├── 📁 hosts/                    # Host-specific configurations
│   └── 📁 h4wkeye-dev/         # Example host configuration
│       ├── 📄 default.nix       # Host imports and metadata
│       ├── 📄 configuration.nix # Core system configuration
│       └── 📄 hardware-configuration.nix # Hardware-specific settings
├── 📁 modules/                  # NixOS modules organized by category
│   ├── 📄 default.nix           # Central module exports
│   ├── 📁 core/                 # Essential system modules
│   │   ├── 📄 audio.nix         # PipeWire audio system
│   │   ├── 📄 bluetooth.nix     # Bluetooth with audio integration
│   │   ├── 📄 hardware-detection.nix # Automatic hardware optimization
│   │   ├── 📄 networking.nix    # Network configuration
│   │   ├── 📄 performance.nix   # System performance tuning
│   │   └── 📁 security/         # Security-focused modules
│   │       ├── 📄 firewall.nix  # Advanced firewall configuration
│   │       ├── 📄 hardening.nix # Kernel and system hardening
│   │       ├── 📄 luks.nix      # LUKS encryption management
│   │       └── 📄 sops.nix      # Secrets management
│   ├── 📁 desktop/              # Desktop environment modules
│   │   ├── 📄 theming.nix       # System-wide Catppuccin theming
│   │   └── 📁 xfce/             # XFCE desktop environment
│   ├── 📁 development/          # Development tools (planned)
│   ├── 📁 gaming/               # Gaming-specific modules (planned)
│   └── 📁 services/             # System services (planned)
├── 📁 home/                     # Home Manager configurations
│   ├── 📄 default.nix           # Base user configuration
│   ├── 📁 programs/             # Program-specific configurations
│   │   ├── 📄 cli-tools.nix     # Command-line tools
│   │   └── 📄 shell.nix         # Shell configuration (bash/zsh)
│   ├── 📁 users/                # User-specific configurations
│   │   └── 📄 h4wkeye.nix       # Example user configuration
│   └── 📁 modules/              # Custom Home Manager modules
├── 📁 lib/                      # Helper functions and utilities
│   ├── 📄 default.nix           # Library exports
│   ├── 📄 helpers.nix           # General helper functions
│   ├── 📄 module-loader.nix     # Module discovery and loading
│   └── 📄 theme-helpers.nix     # Shared theming utilities
├── 📁 dev-shells/               # Language-specific development environments
│   ├── 📄 rust.nix              # Rust development environment
│   ├── 📄 python.nix            # Python development environment
│   ├── 📄 javascript.nix        # JavaScript/Node.js environment
│   └── 📄 nix.nix               # Nix development tools
├── 📁 overlays/                 # Nixpkgs overlays (planned)
├── 📁 secrets/                  # SOPS-encrypted secrets
│   ├── 📄 .sops.yaml            # SOPS configuration
│   └── 📁 network/              # Network-related secrets
├── └── 📁 templates/            # Community-shareable templates
    ├── 📄 basic-module.nix      # Template for new modules
    └── 📄 user-config-example.nix # User configuration example
```

## 🔧 Configuration

### Host Configuration

Each host requires its own directory under `hosts/` with:

- `default.nix`: Host metadata and module imports
- `configuration.nix`: Host-specific settings
- `hardware-configuration.nix`: Hardware detection output

### Module Configuration

Modules follow a consistent pattern:

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
    enable = mkEnableOption "module description";
    
    # Module-specific options
  };

  config = mkIf cfg.enable {
    # Module implementation
  };
}
```

### User Configuration

Customize user settings in `home/users/your-username.nix`:

```nix
{
  imports = [
    ../programs/cli-tools.nix
    ../programs/shell.nix
  ];

  home = {
    username = "your-username";
    homeDirectory = "/home/your-username";
  };

  programs.git = {
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };
}
```

## 🎛️ Available Modules

### Core Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| `audio` | PipeWire audio system | Low-latency, Bluetooth integration |
| `bluetooth` | Bluetooth management | Audio codecs, device profiles |
| `hardware-detection` | Automatic optimization | CPU, GPU, laptop detection |
| `networking` | Network configuration | Secure defaults, WiFi management |
| `performance` | System optimization | SSD tuning, memory management |

### Security Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| `firewall` | Advanced firewall | Preset configs, brute force protection |
| `hardening` | System hardening | Kernel security, attack surface reduction |
| `luks` | Disk encryption | TPM unlocking, secure boot integration |
| `sops` | Secrets management | Age encryption, automatic deployment |

### Desktop Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| `theming` | Catppuccin theming | Dynamic generation, cursor themes |
| `xfce` | XFCE desktop | Panel customization, application defaults |

## 🛠️ Development

### Daily Commands

```bash
# Quick system rebuild
sudo nixos-rebuild switch --flake .#your-hostname

# Test build without switching
nixos-rebuild build --flake .#your-hostname

# Enter development environment
nix develop

# Format code
alejandra .

# Lint and check
statix check .
deadnix .
nix flake check

# Validate module structure
nix eval .#nixosConfigurations.your-hostname.config.modules._meta
```

### Creating New Modules

1. **Use the template:**
   ```bash
   cp templates/basic-module.nix modules/category/new-module.nix
   ```

2. **Add to central imports:**
   ```nix
   # modules/default.nix
   imports = [
     # ...
     ./category/new-module.nix
   ];
   ```

3. **Test in isolation:**
   ```bash
   nix eval .#nixosConfigurations.your-hostname.config.modules.category.new-module
   ```

### Development Environments

Enter language-specific environments:

```bash
nix develop .#rust      # Rust development
nix develop .#python    # Python development
nix develop .#javascript # JavaScript/Node.js
nix develop .#nix       # Nix tooling
```

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)**: Comprehensive development guide and project philosophy
- **Module Options**: Use `man configuration.nix` for built-in options
- **Custom Options**: Check individual module files for documentation

## 🤝 Contributing

Contributions are welcome! This configuration is designed to be community-driven.

### Guidelines

1. **Follow the modular pattern** - each module should be self-contained
2. **Document thoroughly** - include examples and clear descriptions
3. **Test your changes** - ensure modules work in isolation
4. **Keep it generic** - avoid hardcoded personal preferences
5. **Security first** - follow security best practices

### Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes following the established patterns
4. Test thoroughly
5. Submit a pull request with clear description

## 🔍 Troubleshooting

### Common Issues

**Build Failures:**
```bash
# Clean build cache
nix-collect-garbage -d

# Rebuild with verbose output
nixos-rebuild switch --flake .#your-hostname --show-trace -v
```

**LUKS Issues:**
```bash
# Check device status
sudo cryptsetup status cryptroot

# Verify UUID
sudo blkid /dev/nvme0n1p6
```

**Module Import Issues:**
- Verify module path in imports list
- Check for syntax errors: `nix eval --show-trace`
- Ensure proper option types and defaults

### Getting Help

- Check [CLAUDE.md](CLAUDE.md) for detailed troubleshooting
- Review module assertions and error messages
- Use `nix repl` for interactive debugging
- Join the NixOS community forums

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) community for the amazing ecosystem
- [Lix](https://lix.systems/) team for the improved Nix implementation
- [Catppuccin](https://catppuccin.com/) for the beautiful color palette
- [Home Manager](https://github.com/nix-community/home-manager) for user configuration management
- [SOPS-Nix](https://github.com/Mic92/sops-nix) for secrets management

## 🚧 Roadmap

- [ ] **NixVim Integration**: Complete editor configuration
- [ ] **Development Modules**: Container support, language servers
- [ ] **Gaming Support**: Steam, GPU optimizations
- [ ] **Server Modules**: Web services, monitoring
- [ ] **Testing Framework**: Automated module validation
- [ ] **Documentation**: Video tutorials, migration guides
- [ ] **Templates**: More starter configurations
- [ ] **CI/CD**: Automated building and testing

---

**Built with ❤️ using NixOS and Lix**