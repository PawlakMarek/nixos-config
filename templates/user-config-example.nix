# Example of how to override user settings in your host configuration
# Add this to your hosts/your-host/configuration.nix file
{
  # ... your other configuration ...

  # Home Manager user configuration overrides
  home-manager.users.YOUR_USERNAME = {
    # Override user details
    home = {
      username = "YOUR_USERNAME";
      homeDirectory = "/home/YOUR_USERNAME";
    };

    # Override git configuration
    programs.git = {
      userName = "Your Full Name";
      userEmail = "your-email@example.com";
    };

    # You can also override any other home-manager options here
    # programs.zsh.shellAliases.myalias = "echo 'Hello World'";
  };

  # System user configuration
  users.users.YOUR_USERNAME = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"]; # Add groups as needed
    # shell = pkgs.zsh; # Uncomment if you want zsh as default shell
  };
}
