{
  pkgs,
  lib,
  config,
  ...
}:
{
  # x86_64-linux specific hardware configuration
  boot.kernelParams = [ "video=3840x2160@240" ];
  hardware.display.outputs.DP-3.mode = "3840x2160@240";

  # High-performance settings for x86 hardware
  nix.settings.max-jobs = 32;

  # Security features for x86_64-linux systems
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  services.udev.packages = [ pkgs.yubikey-personalization ];

  sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ../keys/secrets.yaml;
  sops.secrets.openai = {
    mode = "0440";
    owner = config.users.users.chelsea.name;
  };

  # x86-specific packages
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];
}

