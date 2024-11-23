# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix <home-manager/nixos> ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

	# TODO: bluetooth, wifi, dwl, st
	# TODO: homemanager for sway, nvim, dwl, st

  networking.hostName = "nixos"; # Define your hostname.
	#networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

	# sway 
  programs.sway.enable = true;
  services.displayManager.defaultSession = "sway";

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.chelsea = {
    isNormalUser = true;
    description = "chelsea";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      qutebrowser
      alacritty
      git
    ];
  };

  services.getty.autologinUser = "chelsea";

  environment.systemPackages = with pkgs; [ gcc ];

  networking.firewall.enable = false;

  services.openssh.enable = true;

  system.stateVersion = "24.05";
	services.greetd = {
		enable = true;
			settings = rec {
			initial_session = { command = "${pkgs.sway}/bin/sway"; user = "chelsea"; };
			default_session = initial_session;
		};
	};

	home-manager.users.chelsea = { pkgs, ...}: {
		home.packages = [ ];
		home.stateVersion = "24.05";
	};

	# sound
  security.rtkit.enable = true;
  services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
	};

}
