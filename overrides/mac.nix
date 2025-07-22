{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Parallels-specific configuration
  hardware.parallels.enable = true;

  # Override PC performance settings for Mac/Parallels
  nix.settings.max-jobs = lib.mkForce 2;

  # Disable PC-specific boot parameters
  boot.kernelParams = lib.mkForce [ ];

  # Remove PC-specific hardware display configuration
  hardware.display = lib.mkForce { };

  # Disable PC-specific security features
  security.pam.services = lib.mkForce { };
  services.udev.packages = lib.mkForce [ ];

  # Disable SOPS configuration for Mac
  sops.age.keyFile = lib.mkForce null;
  sops.defaultSopsFile = lib.mkForce null;
  sops.secrets = lib.mkForce { };

  # Parallels-specific shell aliases for display management and nixos-mac configuration
  programs.bash.shellAliases = {
    desk = "wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2";
    lap = "wlr-randr --output Virtual-1 --mode 2560x1600 --scale 2";
    # Override nixos rebuild commands to use nixos-mac configuration
    switch = lib.mkForce "sudo nixos-rebuild switch --flake .#nixos-mac";
  };
}
