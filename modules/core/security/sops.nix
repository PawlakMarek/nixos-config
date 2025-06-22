{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.core.security.sops;
in {
  options.modules.core.security.sops = {
    enable = mkEnableOption "SOPS secrets management";

    wifi = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SOPS-managed Wi-Fi networks";
      };

      secretsFile = mkOption {
        type = types.path;
        default = ../../../secrets/network/wifi.yaml;
        description = "Path to encrypted Wi-Fi secrets file";
      };
    };

    ageKeyFile = mkOption {
      type = types.path;
      default = "/etc/nixos/age-key.txt";
      description = "Path to age private key for decryption";
    };
  };

  imports = [inputs.sops-nix.nixosModules.sops];

  config = mkIf cfg.enable {
    # Basic SOPS configuration
    sops = {
      defaultSopsFile = cfg.wifi.secretsFile;
      defaultSopsFormat = "yaml";

      # Age key for decryption
      age.keyFile = cfg.ageKeyFile;

      # Define secrets
      secrets = mkIf cfg.wifi.enable {
        "networks/home_network/ssid" = {
          sopsFile = cfg.wifi.secretsFile;
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
        "networks/home_network/psk" = {
          sopsFile = cfg.wifi.secretsFile;
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
        "networks/mobile_hotspot/ssid" = {
          sopsFile = cfg.wifi.secretsFile;
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
        "networks/mobile_hotspot/psk" = {
          sopsFile = cfg.wifi.secretsFile;
          mode = "0440";
          owner = "root";
          group = "networkmanager";
        };
      };
    };

    # NetworkManager configuration with SOPS-managed networks
    networking.networkmanager = mkIf cfg.wifi.enable {
      enable = true;

      # Enhanced Wi-Fi security
      wifi = {
        powersave = true;
        macAddress = "random";
        backend = "wpa_supplicant";
      };

      # Connection configuration using new settings format
      settings = {
        main = {
          dns = "default";
          rc-manager = "unmanaged";
        };

        connection = {
          "wifi.powersave" = 3;
          "wifi.cloned-mac-address" = "random";
          "ethernet.cloned-mac-address" = "random";
          "ipv6.ip6-privacy" = 2;
        };

        device = {
          "wifi.scan-rand-mac-address" = "yes";
        };
      };
    };

    # Systemd service to create NetworkManager connections from SOPS secrets
    systemd.services.networkmanager-sops-wifi = mkIf cfg.wifi.enable {
      description = "Configure NetworkManager Wi-Fi from SOPS secrets";
      wantedBy = ["multi-user.target"];
      after = ["NetworkManager.service" "sops-nix.service"];
      wants = ["NetworkManager.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };

      script = ''
        set -euo pipefail

        # Wait for NetworkManager to be ready
        while ! ${pkgs.networkmanager}/bin/nmcli general status >/dev/null 2>&1; do
          sleep 1
        done

        # Function to create Wi-Fi connection if secrets exist
        create_wifi_connection() {
          local name="$1"
          local ssid_file="/run/secrets/networks/$name/ssid"
          local psk_file="/run/secrets/networks/$name/psk"

          if [[ -f "$ssid_file" && -f "$psk_file" ]]; then
            local ssid=$(cat "$ssid_file")
            local psk=$(cat "$psk_file")

            # Check if connection already exists
            if ! ${pkgs.networkmanager}/bin/nmcli connection show "$name" >/dev/null 2>&1; then
              echo "Creating Wi-Fi connection: $name"
              ${pkgs.networkmanager}/bin/nmcli connection add \
                type wifi \
                con-name "$name" \
                ssid "$ssid" \
                wifi-sec.key-mgmt wpa-psk \
                wifi-sec.psk "$psk" \
                connection.autoconnect yes \
                wifi.cloned-mac-address random
            else
              echo "Wi-Fi connection $name already exists"
            fi
          else
            echo "Secrets for $name not found, skipping"
          fi
        }

        # Create connections for defined networks
        create_wifi_connection "home_network"
        create_wifi_connection "mobile_hotspot"

        echo "Wi-Fi configuration completed"
      '';
    };

    # Packages needed for SOPS
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    # User groups for secret access
    users.groups.networkmanager = {};
    users.users.networkmanager = {
      isSystemUser = true;
      group = "networkmanager";
    };
  };
}
