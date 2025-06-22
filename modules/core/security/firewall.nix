{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.security.firewall;
in {
  options.modules.core.security.firewall = {
    enable = mkEnableOption "modern firewall configuration with secure defaults";

    preset = mkOption {
      type = types.enum ["desktop" "laptop" "server"];
      default = "laptop";
      description = "Firewall preset for different use cases";
    };

    allowedServices = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Services to allow through firewall";
      example = ["syncthing" "kdeconnect"];
    };

    allowedPorts = {
      tcp = mkOption {
        type = types.listOf types.port;
        default = [];
        description = "Additional TCP ports to allow";
      };

      udp = mkOption {
        type = types.listOf types.port;
        default = [];
        description = "Additional UDP ports to allow";
      };
    };

    strictMode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable strict mode with deny-all default policy";
    };

    logging = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable firewall logging";
      };

      level = mkOption {
        type = types.enum ["debug" "info" "notice" "warning" "error"];
        default = "info";
        description = "Logging level for firewall events";
      };

      logDropped = mkOption {
        type = types.bool;
        default = false;
        description = "Log dropped packets (can be verbose)";
      };
    };

    bruteForceProtection = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable brute force protection";
      };

      maxAttempts = mkOption {
        type = types.int;
        default = 5;
        description = "Max connection attempts before blocking";
      };

      timeWindow = mkOption {
        type = types.str;
        default = "10m";
        description = "Time window for counting attempts";
      };

      banTime = mkOption {
        type = types.str;
        default = "1h";
        description = "How long to ban offending IPs";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.preset != "server" || !config.services.xserver.enable;
        message = "Server firewall preset should not be used with desktop environment";
      }
    ];

    # Modern nftables-based firewall
    networking.firewall = {
      enable = true;

      # Use iptables with nftables backend
      package = pkgs.iptables-nftables-compat;

      # Basic allowed ports
      allowedTCPPorts =
        cfg.allowedPorts.tcp
        ++ optionals (builtins.elem "syncthing" cfg.allowedServices) [22000];
      allowedUDPPorts =
        cfg.allowedPorts.udp
        ++ optionals (builtins.elem "syncthing" cfg.allowedServices) [22000 21027];

      # Service-specific port ranges
      allowedTCPPortRanges = optionals (builtins.elem "kdeconnect" cfg.allowedServices) [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = optionals (builtins.elem "kdeconnect" cfg.allowedServices) [
        {
          from = 1714;
          to = 1764;
        }
      ];

      # Enable connection tracking
      connectionTrackingModules = [];
      autoLoadConntrackHelpers = false;

      # Let NixOS manage the firewall, just add our custom rules
      extraCommands = ''
        # Rate limiting for ICMP
        ${pkgs.iptables}/bin/iptables -A nixos-fw -p icmp --icmp-type echo-request -m limit --limit 4/sec -j nixos-fw-accept
        ${pkgs.iptables}/bin/ip6tables -A nixos-fw -p icmpv6 --icmpv6-type echo-request -m limit --limit 4/sec -j nixos-fw-accept

        ${optionalString cfg.bruteForceProtection.enable ''
          # Brute force protection for SSH
          ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
          ${pkgs.iptables}/bin/iptables -A nixos-fw -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 600 --hitcount ${toString cfg.bruteForceProtection.maxAttempts} --name SSH -j nixos-fw-refuse
        ''}
      '';
    };

    # Additional security hardening
    boot.kernel.sysctl = {
      # Network security
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;

      # Ignore ICMP ping requests
      "net.ipv4.icmp_echo_ignore_all" = mkIf (cfg.preset == "server") 1;

      # Ignore ICMP redirects
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;

      # Ignore source routing
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;

      # Log martian packets
      "net.ipv4.conf.all.log_martians" = mkIf cfg.logging.enable 1;

      # Ignore bogus ICMP error responses
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

      # Enable reverse path filtering
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # Disable IPv6 router advertisements
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.default.accept_ra" = 0;

      # TCP hardening
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.tcp_fin_timeout" = 15;
      "net.ipv4.tcp_keepalive_time" = 300;
      "net.ipv4.tcp_keepalive_probes" = 5;
      "net.ipv4.tcp_keepalive_intvl" = 15;
    };

    # Network manager security settings
    networking.networkmanager = {
      wifi = {
        powersave = mkIf (cfg.preset != "server") true;
        macAddress = "random";
      };
      ethernet.macAddress = "random";
      connectionConfig."ipv6.ip6-privacy" = "2";
    };
  };
}
