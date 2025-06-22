# Shared theme utilities to eliminate duplication
{lib, ...}: rec {
  # Generate theme name following Catppuccin conventions
  generateThemeName = variant: accent: let
    capitalizedAccent =
      lib.toUpper (builtins.substring 0 1 accent)
      + builtins.substring 1 (builtins.stringLength accent) accent;
  in "Catppuccin-${lib.toUpper (builtins.substring 0 1 variant)}${builtins.substring 1 (builtins.stringLength variant) variant}-Standard-${capitalizedAccent}-Dark";

  # Generate cursor theme name
  generateCursorTheme = variant: accent: "catppuccin-${variant}-${accent}-cursors";

  # Validate theme variant
  isValidVariant = variant:
    builtins.elem variant ["latte" "frappe" "macchiato" "mocha"];

  # Validate accent color
  isValidAccent = accent:
    builtins.elem accent [
      "rosewater"
      "flamingo"
      "pink"
      "mauve"
      "red"
      "maroon"
      "peach"
      "yellow"
      "green"
      "teal"
      "sky"
      "sapphire"
      "blue"
      "lavender"
    ];

  # Create theme assertions
  mkThemeAssertions = cfg: [
    {
      assertion = isValidVariant cfg.variant;
      message = "modules.desktop.theming.variant must be one of: latte, frappe, macchiato, mocha";
    }
    {
      assertion = isValidAccent cfg.accent;
      message = "modules.desktop.theming.accent must be a valid Catppuccin accent color";
    }
  ];

  # Convert variant to package attribute name
  variantToPackageAttr = variant: accent: "${variant}${lib.toUpper (builtins.substring 0 1 accent)}${builtins.substring 1 (builtins.stringLength accent) accent}";
}
