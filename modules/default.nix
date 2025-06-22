# Central module export for the entire configuration
{lib, ...}: {
  imports = [
    # Core system modules
    ./core/audio.nix
    ./core/bluetooth.nix
    ./core/hardware-detection.nix
    ./core/networking.nix
    ./core/performance.nix

    # Security modules
    ./core/security/firewall.nix
    ./core/security/hardening.nix
    ./core/security/luks.nix
    ./core/security/sops.nix

    # Desktop modules
    ./desktop/theming.nix
    ./desktop/xfce

    # Development modules (when implemented)
    # ./development

    # Gaming modules (when implemented)
    # ./gaming

    # Services modules (when implemented)
    # ./services
  ];

  # Provide module metadata for introspection
  options.modules._meta = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "Metadata about loaded modules";
    default = {
      version = "1.0.0";
      categories = ["core" "desktop" "development" "gaming" "services"];
      loadedModules = [
        "core.audio"
        "core.bluetooth"
        "core.hardware-detection"
        "core.networking"
        "core.performance"
        "core.security.firewall"
        "core.security.hardening"
        "core.security.luks"
        "core.security.sops"
        "desktop.theming"
        "desktop.xfce"
      ];
    };
  };
}
