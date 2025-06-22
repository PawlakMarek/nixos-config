# System security hardening module
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.security.hardening;
in {
  options.modules.core.security.hardening = {
    enable = mkEnableOption "system security hardening";

    kernel = {
      disableKexec = mkOption {
        type = types.bool;
        default = true;
        description = "Disable kexec system call to prevent kernel replacement attacks";
      };

      wipeRamOnShutdown = mkOption {
        type = types.bool;
        default = false;
        description = "Wipe RAM contents on shutdown (may cause slow shutdown)";
      };

      requireSecureBoot = mkOption {
        type = types.bool;
        default = false;
        description = "Require secure boot for enhanced security";
      };

      enableKASLR = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Kernel Address Space Layout Randomization";
      };

      disableUnusedNetworkProtocols = mkOption {
        type = types.bool;
        default = true;
        description = "Disable unused network protocols to reduce attack surface";
      };
    };

    userspace = {
      enableAppArmor = mkOption {
        type = types.bool;
        default = false;
        description = "Enable AppArmor mandatory access control";
      };

      disableCoreDumps = mkOption {
        type = types.bool;
        default = true;
        description = "Disable core dumps that might leak sensitive information";
      };

      secureSharedMemory = mkOption {
        type = types.bool;
        default = true;
        description = "Secure shared memory to prevent privilege escalation";
      };
    };

    network = {
      disableIPv6 = mkOption {
        type = types.bool;
        default = false;
        description = "Disable IPv6 if not needed";
      };

      enableSynCookies = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SYN cookies to prevent SYN flood attacks";
      };

      disableICMPRedirects = mkOption {
        type = types.bool;
        default = true;
        description = "Disable ICMP redirects to prevent routing attacks";
      };
    };
  };

  config = mkIf cfg.enable {
    # Kernel hardening
    boot.kernel.sysctl = mkMerge [
      (mkIf cfg.kernel.disableKexec {
        "kernel.kexec_load_disabled" = 1;
      })

      (mkIf cfg.kernel.enableKASLR {
        "kernel.randomize_va_space" = 2;
      })

      (mkIf cfg.userspace.disableCoreDumps {
        "kernel.core_pattern" = "|/bin/false";
        "fs.suid_dumpable" = 0;
      })

      (mkIf cfg.userspace.secureSharedMemory {
        "kernel.shm_rmid_forced" = 1;
      })

      (mkIf cfg.network.enableSynCookies {
        "net.ipv4.tcp_syncookies" = lib.mkDefault 1;
      })

      (mkIf cfg.network.disableICMPRedirects {
        "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
        "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
        "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
        "net.ipv6.conf.default.accept_redirects" = lib.mkDefault 0;
        "net.ipv4.conf.all.send_redirects" = lib.mkDefault 0;
        "net.ipv4.conf.default.send_redirects" = lib.mkDefault 0;
      })

      (mkIf cfg.network.disableIPv6 {
        "net.ipv6.conf.all.disable_ipv6" = 1;
        "net.ipv6.conf.default.disable_ipv6" = 1;
      })

      # Additional general hardening
      {
        # Prevent privilege escalation
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;

        # Network security
        "net.ipv4.conf.all.log_martians" = lib.mkDefault 1;
        "net.ipv4.conf.default.log_martians" = lib.mkDefault 1;
        "net.ipv4.conf.all.rp_filter" = lib.mkDefault 1;
        "net.ipv4.conf.default.rp_filter" = lib.mkDefault 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = lib.mkDefault 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = lib.mkDefault 1;

        # Memory protection
        "vm.mmap_rnd_bits" = 32;
        "vm.mmap_rnd_compat_bits" = 16;
      }
    ];

    # Kernel module blacklist for unused/dangerous protocols
    boot.blacklistedKernelModules = mkIf cfg.kernel.disableUnusedNetworkProtocols [
      "dccp" # Datagram Congestion Control Protocol
      "sctp" # Stream Control Transmission Protocol
      "rds" # Reliable Datagram Sockets
      "tipc" # Transparent Inter Process Communication
      "n-hdlc" # New High-level Data Link Control
      "ax25" # Amateur Radio AX.25
      "netrom" # NET/ROM
      "x25" # X.25
      "rose" # ROSE
      "decnet" # DECnet
      "econet" # Econet
      "af_802154" # IEEE 802.15.4
      "ipx" # IPX
      "appletalk" # AppleTalk
      "psnap" # SubNetwork Access Protocol
      "p8023" # 802.3
      "p8022" # 802.2
      "can" # Controller Area Network
      "atm" # Asynchronous Transfer Mode
    ];

    # AppArmor support
    security.apparmor = mkIf cfg.userspace.enableAppArmor {
      enable = true;
      killUnconfinedConfinables = true;
    };

    # Secure boot enforcement (when enabled)
    assertions = [
      {
        assertion = !cfg.kernel.requireSecureBoot || config.boot.loader.systemd-boot.enable;
        message = "Secure boot requirement needs systemd-boot loader";
      }
    ];

    # RAM wiping service
    systemd.services.wipe-ram = mkIf cfg.kernel.wipeRamOnShutdown {
      description = "Wipe RAM on shutdown";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = "${pkgs.coreutils}/bin/dd if=/dev/zero of=/dev/mem bs=1M || true";
        TimeoutStopSec = "30s";
      };
      wantedBy = ["multi-user.target"];
      before = ["shutdown.target" "reboot.target"];
    };

    # Additional security packages
    environment.systemPackages = with pkgs;
      mkIf cfg.enable [
        lynis # Security auditing tool
        chkrootkit # Rootkit checker
      ];
  };
}
