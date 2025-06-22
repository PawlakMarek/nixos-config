{lib, ...}:
with lib; let
  # Helper function to recursively find all .nix files in a directory
  findNixFiles = dir: let
    # Get directory contents
    contents = builtins.readDir dir;

    # Helper to process each item in directory
    processItem = name: type: let
      path = "${dir}/${name}";
    in
      if type == "directory"
      then
        # Recursively search subdirectories
        findNixFiles path
      else if type == "regular" && hasSuffix ".nix" name
      then
        # Include .nix files (excluding default.nix to avoid conflicts)
        optional (name != "default.nix") path
      else
        # Skip other file types
        [];
  in
    # Flatten the results
    flatten (mapAttrsToList processItem contents);

  # Auto-discover modules in a given directory
  autoLoadModules = moduleDir: let
    modulePath = toString moduleDir;
  in
    if pathExists modulePath
    then findNixFiles modulePath
    else [];

  # Create module imports for a category with auto-discovery
  createModuleCategory = basePath: category: let
    categoryPath = "${basePath}/${category}";
    modules = autoLoadModules categoryPath;
  in {
    imports = modules;
    _meta = {
      inherit category;
      discovered = length modules;
      modules = map baseNameOf modules;
    };
  };

  # Get all categories in modules directory
  getModuleCategories = modulesPath: let
    contents =
      if pathExists modulesPath
      then builtins.readDir modulesPath
      else {};
    directories = filterAttrs (_: type: type == "directory") contents;
  in
    attrNames directories;

  # Main auto-loader function
  autoLoadAllModules = modulesPath: let
    categories = getModuleCategories modulesPath;
    modulesByCategory = map (cat: createModuleCategory modulesPath cat) categories;
  in {
    # Combine all imports
    imports = flatten (map (cat: cat.imports) modulesByCategory);

    # Metadata about discovered modules
    _moduleLoader = {
      basePath = toString modulesPath;
      inherit categories;
      totalModules = foldr (cat: acc: acc + cat._meta.discovered) 0 modulesByCategory;
      byCategory = listToAttrs (map (cat: {
          name = cat._meta.category;
          value = cat._meta;
        })
        modulesByCategory);
    };
  };

  # Alternative: category-specific loaders for more control
  loadCoreModules = modulesPath: autoLoadModules "${modulesPath}/core";
  loadDesktopModules = modulesPath: autoLoadModules "${modulesPath}/desktop";
  loadDevelopmentModules = modulesPath: autoLoadModules "${modulesPath}/development";
  loadGamingModules = modulesPath: autoLoadModules "${modulesPath}/gaming";
  loadServicesModules = modulesPath: autoLoadModules "${modulesPath}/services";

  # Conditional module loading based on hardware/features
  conditionalLoad = condition: modules:
    if condition
    then modules
    else [];

  # Load modules based on hardware detection
  loadHardwareSpecificModules = modulesPath: config: let
    # Hardware detection helpers
    hasWifi = config.hardware.wirelessRegDom or "" != "";
    hasBluetooth = config.hardware.bluetooth.enable or false;
    hasNvidia = any (driver: driver == "nvidia") (config.services.xserver.videoDrivers or []);
    hasAMD = any (driver: driver == "amdgpu") (config.services.xserver.videoDrivers or []);
    isLaptop = config.powerManagement.enable or false;

    # Conditional module loading
    modules =
      conditionalLoad hasWifi (autoLoadModules "${modulesPath}/hardware/wifi")
      ++ conditionalLoad hasBluetooth (autoLoadModules "${modulesPath}/hardware/bluetooth")
      ++ conditionalLoad hasNvidia (autoLoadModules "${modulesPath}/hardware/nvidia")
      ++ conditionalLoad hasAMD (autoLoadModules "${modulesPath}/hardware/amd")
      ++ conditionalLoad isLaptop (autoLoadModules "${modulesPath}/hardware/laptop");
  in
    modules;
in {
  inherit
    findNixFiles
    autoLoadModules
    createModuleCategory
    getModuleCategories
    autoLoadAllModules
    loadCoreModules
    loadDesktopModules
    loadDevelopmentModules
    loadGamingModules
    loadServicesModules
    conditionalLoad
    loadHardwareSpecificModules
    ;
}
