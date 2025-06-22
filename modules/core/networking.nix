{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.core.networking;
in {
  options.modules.core.networking = {
    enable = mkEnableOption "core networking configuration";

    dns = {
      providers = mkOption {
        type = types.listOf types.str;
        default = ["1.1.1.1" "9.9.9.9"];
        description = "DNS servers to use (Cloudflare + Quad9 by default)";
        example = ["1.1.1.1" "8.8.8.8"];
      };

      enableResolvconf = mkOption {
        type = types.bool;
        default = true;
        description = "Enable resolvconf for dynamic DNS management";
      };
    };

    networkmanager = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NetworkManager";
      };

      security = {
        randomizeMac = mkOption {
          type = types.bool;
          default = true;
          description = "Randomize MAC addresses for privacy";
        };

        enableIpv6Privacy = mkOption {
          type = types.bool;
          default = true;
          description = "Enable IPv6 privacy extensions";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # DNS configuration
    networking = {
      nameservers = cfg.dns.providers;
      resolvconf.enable = cfg.dns.enableResolvconf;

      # NetworkManager configuration
      networkmanager = mkIf cfg.networkmanager.enable {
        enable = true;

        # Security settings
        wifi = mkIf cfg.networkmanager.security.randomizeMac {
          macAddress = "random";
          powersave = true;
        };

        ethernet = mkIf cfg.networkmanager.security.randomizeMac {
          macAddress = "random";
        };

        # IPv6 privacy
        connectionConfig = mkIf cfg.networkmanager.security.enableIpv6Privacy {
          "ipv6.ip6-privacy" = "2";
        };
      };
    };
  };
}
