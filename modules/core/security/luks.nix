{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.security.luks;
in {
  options.modules.core.security.luks = {
    enable = mkEnableOption "LUKS full-disk encryption";

    device = mkOption {
      type = types.str;
      default = "/dev/disk/by-uuid/REPLACE_WITH_YOUR_LUKS_UUID";
      description = ''
        LUKS encrypted device path. Recommended approaches:
        - UUID:  /dev/disk/by-uuid/xxx (most reliable for LUKS)
        - Disk ID: /dev/disk/by-id/xxx (hardware-specific)
        - Partition: /dev/nvme0n1p6 (least reliable)
      '';
      example = "/dev/disk/by-uuid/12345678-1234-1234-1234-123456789abc";
    };

    name = mkOption {
      type = types.str;
      default = "cryptroot";
      description = "Name for the LUKS mapping";
    };

    allowDiscards = mkOption {
      type = types.bool;
      default = true;
      description = "Allow TRIM/discard operations (recommended for SSDs)";
    };

    tpm = {
      enable = mkEnableOption ''
        TPM-based automatic unlocking.

        SECURITY WARNING: TPM only protects against drive removal and tampering.
        If your laptop is stolen, the thief can boot normally and TPM will unlock.
        For laptop theft protection, use passphrase-only authentication.
      '';

      device = mkOption {
        type = types.str;
        default = "/dev/tpmrm0";
        description = "TPM device path";
      };

      pcrBanks = mkOption {
        type = types.listOf types.str;
        default = ["sha256"];
        description = "TPM PCR banks to use";
      };

      pcrs = mkOption {
        type = types.listOf types.int;
        default = [0 7];
        description = ''
          PCR registers to seal against. Common values:
          - 0: UEFI firmware
          - 1: UEFI configuration
          - 2: Option ROMs
          - 3: Option ROM configuration
          - 4: Boot manager
          - 5: Boot manager configuration
          - 7: Secure boot state
          - 8: Boot command line
          - 9: Boot files (initrd, kernel)

          NOTE: More PCRs = more secure against tampering but more fragile to updates
        '';
      };

      gracefulFallback = mkOption {
        type = types.bool;
        default = true;
        description = "Fall back to password if TPM unsealing fails";
      };

      measureBootComponents = mkOption {
        type = types.bool;
        default = true;
        description = "Measure kernel and initrd into PCR9";
      };

      useCase = mkOption {
        type = types.enum [
          "convenience"
          "evil-maid-protection"
          "drive-removal-protection"
        ];
        default = "convenience";
        description = ''
          Clarifies your security model:
          - convenience: Faster boots, but no theft protection
          - evil-maid-protection: Detect if someone modified your system
          - drive-removal-protection: Prevent drive from working in other systems

          NONE of these protect against laptop theft with intact hardware.
        '';
      };
    };

    fallbackToPassword = mkOption {
      type = types.bool;
      default = true;
      description = "Fall back to password if primary unlock method fails";
    };

    crypttabExtraOpts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra options for /etc/crypttab";
      example = ["cipher=aes-xts-plain64" "hash=sha512"];
    };

    # Security hardening options moved to modules.core.security.hardening

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose logging for troubleshooting";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tpm.enable -> (cfg.tpm.pcrs != []);
        message = "TPM PCR list cannot be empty when TPM is enabled";
      }
      {
        assertion = cfg.tpm.enable -> config.security.tpm2.enable;
        message = "TPM2 support must be enabled when using TPM-based LUKS";
      }
    ];

    security.tpm2 = mkIf cfg.tpm.enable {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };

    boot = {
      initrd = {
        luks.devices.${cfg.name} = {
          inherit (cfg) device allowDiscards;
          # fallbackToPassword is implied in systemd stage 1

          crypttabExtraOpts =
            cfg.crypttabExtraOpts
            ++ optionals cfg.allowDiscards ["discard"];
        };

        systemd = mkIf cfg.tpm.enable {
          enable = true;

          initrdBin = with pkgs; [
            tpm2-tools
            cryptsetup
          ];

          services."luks-tpm-${cfg.name}" = {
            description = "Unlock LUKS ${cfg.name} with TPM";
            wantedBy = ["cryptsetup.target"];
            after = ["tpm2.target"];
            before = ["cryptsetup-${cfg.name}.service"];

            unitConfig.DefaultDependencies = false;

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeShellScript "luks-tpm-unlock" ''
                set -euo pipefail

                TPM_DEVICE="${cfg.tpm.device}"
                LUKS_DEVICE="${cfg.device}"
                LUKS_NAME="${cfg.name}"
                PCR_SPEC="${concatStringsSep "+" (map toString cfg.tpm.pcrs)}"

                echo "Attempting TPM unlock for $LUKS_NAME..."

                # Check if TPM is available
                if [[ ! -e "$TPM_DEVICE" ]]; then
                  echo "TPM device not found at $TPM_DEVICE"
                  ${optionalString cfg.tpm.gracefulFallback "exit 0"}
                  exit 1
                fi

                # Try to unseal the key from TPM
                if tpm2_unseal -c 0x81000000 -o /tmp/luks-key 2>/dev/null; then
                  echo "Successfully unsealed key from TPM"

                  # Attempt to unlock with TPM key
                  if cryptsetup open --key-file /tmp/luks-key "$LUKS_DEVICE" "$LUKS_NAME"; then
                    echo "Successfully unlocked $LUKS_NAME with TPM"
                    rm -f /tmp/luks-key
                    exit 0
                  else
                    echo "Failed to unlock with TPM key"
                    rm -f /tmp/luks-key
                  fi
                else
                  echo "Failed to unseal key from TPM"
                fi

                ${optionalString cfg.tpm.gracefulFallback ''
                  echo "Falling back to password authentication"
                  exit 0
                ''}

                echo "TPM unlock failed and no fallback configured"
                exit 1
              '';
            };
          };
        };

        kernelModules =
          [
            "dm_crypt"
            "dm_mod"
          ]
          ++ optionals cfg.tpm.enable [
            "tpm"
            "tpm_tis"
            "tpm_crb"
          ];

        availableKernelModules = optionals cfg.tpm.enable [
          "tpm_tis"
          "tpm_crb"
        ];
      };
    };

    environment.systemPackages = with pkgs;
      [
        cryptsetup
        keyutils
      ]
      ++ optionals cfg.tpm.enable [
        tpm2-tools
        tpm2-tss
      ];

    # Kernel hardening moved to modules.core.security.hardening

    services.fstrim = {
      enable = cfg.allowDiscards;
      interval = "weekly";
    };

    boot.initrd.verbose = cfg.debug;
    boot.consoleLogLevel =
      if cfg.debug
      then 7
      else 3;

    boot.loader.systemd-boot.editor = false;

    # RAM wiping moved to modules.core.security.hardening
  };
}
