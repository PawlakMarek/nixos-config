{lib, ...}: {
  # Automatically import all .nix files in a directory
  importModules = path:
    map (file: path + "/${file}")
    (lib.filter (name: lib.hasSuffix ".nix" name && name != "default.nix")
      (lib.attrNames (builtins.readDir path)));

  # Enable modules conditionally based on hostname/hardware
  conditionalModules = hostname: modules:
    lib.optionals (lib.hasPrefix "laptop" hostname) modules.laptop
    ++ lib.optionals (lib.hasPrefix "desktop" hostname) modules.desktop;
}
