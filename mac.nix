{ lib, ... }:
{
  # Parallels-specific configuration
  hardware.parallels.enable = true;

  nix.settings.max-jobs = lib.mkForce 2;

  boot.kernelParams = lib.mkForce [ "video=2560x1600@60" ];
  hardware.display.outputs.Virtual-1.mode = "2560x1600@60";
  security.pam.services = {
    login.u2fAuth = lib.mkForce false;
    sudo.u2fAuth = lib.mkForce false;
  };
  services.udev.packages = lib.mkForce [ ];

  programs.bash.shellAliases = {
    desk = "wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2";
    lap = "wlr-randr --output Virtual-1 --mode 2560x1600 --scale 2";
    Em = "edit /etc/nixos/mac.nix";
    switch = lib.mkForce "sudo nixos-rebuild switch --flake /etc/nixos/#nixos-mac";
  };
}
