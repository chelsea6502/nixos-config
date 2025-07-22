{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Security features for x86_64-linux systems
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  services.udev.packages = [ pkgs.yubikey-personalization ];
}

