# NixOS configuration for h4wkeye-dev host
# Dell Latitude 7440 developer workstation with LUKS encryption
{pkgs, ...}: {
  imports = [
    ../../modules/desktop/xfce
    ../../modules/desktop/theming.nix
  ];

  # Core modules configuration
  modules.core = {
    networking.enable = true;
    audio.enable = true;
    bluetooth.enable = true;

    security = {
      luks = {
        enable = true;
        device = "/dev/disk/by-uuid/a96ce829-b237-435a-9d66-d49fe274dbe2";
        name = "cryptroot";
        allowDiscards = true;

        # TPM-based unlocking (disabled pending tpm2-pytss fixes)
        tpm = {
          enable = false;
          useCase = "evil-maid-protection";
          pcrs = [7]; # Secure Boot state only
          gracefulFallback = true;
          measureBootComponents = false;
        };

        # Security hardening moved to separate module

        debug = false;
      };

      firewall = {
        enable = true;
        preset = "laptop";
        strictMode = true;
        logging.enable = true;
        bruteForceProtection.enable = true;
        allowedServices = [];
      };

      sops = {
        enable = true;
        wifi.enable = true;
      };

      hardening = {
        enable = true;
        kernel = {
          disableKexec = true;
          wipeRamOnShutdown = false;
          requireSecureBoot = true;
        };
      };
    };

    hardware-detection.enable = true;
    performance.enable = true;
  };

  # Desktop environment
  modules.desktop.xfce = {
    enable = true;
    panel = {
      enableAudioPlugin = true;
      enablePowerManagerPlugin = true;
    };
    defaultApplications.enable = true;
  };

  # System theming
  modules.desktop.theming = {
    enable = true;
    variant = "mocha";
    accent = "peach";
    applications = {
      firefox = true;
      thunderbird = true;
      kvantum = true;
    };
  };

  # Boot configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
  };

  # Latest kernel for hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # System identification
  networking.hostName = "h4wkeye-dev";

  # Localization
  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";

  # Services
  services = {
    # SSH server disabled for security (client tools available)
    openssh.enable = false;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # User account configuration
  users.users.h4wkeye = {
    isNormalUser = true;
    extraGroups = ["wheel" "audio" "bluetooth"];
  };

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.h4wkeye = import ../../home/users/h4wkeye.nix;
  };

  programs.firefox.enable = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    lynx
    ranger
    wget
    curl
    htop
    openssh # SSH client
    mosh # Mobile shell for unstable connections
  ];

  # NixOS version for compatibility - do not change after initial install
  system.stateVersion = "25.05";
}
