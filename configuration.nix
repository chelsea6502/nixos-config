{ pkgs, lib, config, ... }:
let
  patchedDwl = pkgs.dwl.overrideAttrs (oldAttrs: rec {
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.fcft pkgs.pixman pkgs.libdrm ];
    src = pkgs.fetchurl {
      url =
        "https://codeberg.org/chelsea6502/dwl/archive/113e917f44b78b4c67eecdc437f4ae62ff24b87d.tar.gz";
      sha256 = "sha256-y5UC3AVbEFojzTwRx6YmuWyvmRcAMO//Y6QQoZUyqZg=";
    };
    preConfigure = "cp ${./dwl/config.h} config.h ";
  });

  patchedSlstatus = pkgs.slstatus.overrideAttrs
    (old: rec { preConfigure = "cp ${./dwl/slstatus/config.h} config.h"; });

  nixvim = import ./nixvim.nix { inherit config pkgs; };

in {
  # ─────────────────────────────────────────────────────────────────────────────
  # 1. Imports
  # ─────────────────────────────────────────────────────────────────────────────
  imports = [ ./hardware-configuration.nix ];

  # ─────────────────────────────────────────────────────────────────────────────
  # 2. Basic System Settings
  # ─────────────────────────────────────────────────────────────────────────────
  system.stateVersion = "24.11";
  networking.hostName = "nixos";
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";
  networking.firewall.enable = true;

  # ─────────────────────────────────────────────────────────────────────────────
  # 3. Boot Configuration
  # ─────────────────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/nvme0n1";

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "video=3840x2160@60" ];
  hardware.display.outputs.HDMI-A-3.mode = "3840x2160@60";

  # Wait-online optimizations
  boot.initrd.systemd.network.wait-online.enable = false;
  networking.dhcpcd.wait = "background";

  # ─────────────────────────────────────────────────────────────────────────────
  # 4. File Systems & Btrfs Logic
  # ─────────────────────────────────────────────────────────────────────────────
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist/system" = {
    enable = true; # NB: Defaults to true, not needed
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/lib/nixos"
      "/etc/NetworkManager/system-connections"
    ];
    files = [ "/etc/machine-id" ];
    users.chelsea = {
      directories = [
        "nixos-config"
        ".local/share/qutebrowser"
        ".local/share/chromium"
        ".config/Yubico"
        ".config/sops"
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
    };
  };

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  # ─────────────────────────────────────────────────────────────────────────────
  # 5. Security & Authentication
  # ─────────────────────────────────────────────────────────────────────────────
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
  services.udev.packages = [ pkgs.yubikey-personalization ];

  security.polkit.enable = true;

  sops.age.keyFile = "/home/chelsea/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ./keys/secrets.yaml;
  sops.secrets.openai = {
    mode = "0440";
    owner = config.users.users.chelsea.name;
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # 6. Nix Settings
  # ─────────────────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";
  nix.settings.max-jobs = 8;

  # ─────────────────────────────────────────────────────────────────────────────
  # 7. Overlays
  # ─────────────────────────────────────────────────────────────────────────────
  nixpkgs.overlays = [
    (final: prev: {
      wld = final.callPackage ./st-wl/wld/default.nix { };
      st-wl = final.callPackage ./st-wl/default.nix {
        wld = final.wld;
        conf = builtins.readFile ./st-wl/config.h;
      };
    })
  ];

  # ─────────────────────────────────────────────────────────────────────────────
  # 8. Environment Variables & Shell Settings
  # ─────────────────────────────────────────────────────────────────────────────
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = 1;
    EDITOR = "nvim";
    NIXOS_OZONE_WL = 1;
  };

  programs.bash.promptInit = ''
    PS1="\n\[\033[1;32m\][\[\e]0;\u@\h:\w\a\]\w]$\[\033[0m\] "
  '';

  programs.bash.shellAliases = {
    edit = "sudo -E -s nvim";
    Ec = "sudo -E -s nvim /etc/nixos/configuration.nix";
    Ef = "sudo -E -s nvim /etc/nixos/flake.nix";
    En = "sudo -E -s nvim /etc/nixos/nixvim.nix";
    Ew = "sudo -E -s nvim /etc/nixos/dwl/config.h";
    saveconf = "sudo cp -R /etc/nixos/* ~/nixos-config/";
    loadconf = "sudo cp -R ~/nixos-config/* /etc/nixos/";
    switch = "sudo nixos-rebuild switch";
    nix-update = "cd /etc/nixos && sudo nix flake update";
    nix-clean = "sudo nix-collect-garbage -d && sudo nix-store --optimise";
    nix-verify = "sudo nix-store --verify --check-contents";
    nix-full = "nix-update && switch && nix-clean && nix-verify";
    git-auth = "ssh-add -K";
    shell-init-web = "sudo cp -r /etc/nixos/devShells/web/* ./ && direnv allow";
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # 9. Services
  # ─────────────────────────────────────────────────────────────────────────────
  services.openssh.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${patchedSlstatus}/bin/slstatus -s | ${patchedDwl}/bin/dwl";
        user = "chelsea";
      };
    };
  };
  programs.ssh.startAgent = true;
  programs.direnv.enable = true;

  # ─────────────────────────────────────────────────────────────────────────────
  # 10. User Accounts
  # ─────────────────────────────────────────────────────────────────────────────
  users = {
    mutableUsers = false;
    allowNoPasswordLogin = true;

    users.chelsea = {
      isNormalUser = true;
      description = "chelsea";
      extraGroups = [ "networkmanager" "wheel" ];
      hashedPassword = "!";
      packages = with pkgs; [
        qutebrowser
        patchedDwl
        patchedSlstatus
        st-wl
        lynis
        chromium
      ];
    };
  };
  programs.nixvim = nixvim;

  programs.chromium.extensions = [
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
    "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
  ];

  # ─────────────────────────────────────────────────────────────────────────────
  # 11. Home Manager Configuration
  # ─────────────────────────────────────────────────────────────────────────────
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.chelsea = {
      home.username = "chelsea";
      home.homeDirectory = "/home/chelsea";
      home.stateVersion = "24.05";

      programs.home-manager.enable = true;
      programs.btop.enable = true;
      programs.ranger.enable = true;
      programs.feh.enable = true;

      programs.qutebrowser = {
        enable = true;
        settings = {
          tabs.show = "multiple";
          statusbar.show = "in-mode";
          content.javascript.clipboard = "access-paste";
        };
      };

      programs.foot = {
        enable = true;
        settings = {
          # Example foot config
          main.pad = "24x24 center";
        };
      };

      programs.git = {
        enable = true;
        userName = "Chelsea Wilkinson";
        userEmail = "mail@chelseawilkinson.me";
      };

      stylix.autoEnable = true;
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # 12. Stylix (Themes, Fonts, Wallpaper)
  # ─────────────────────────────────────────────────────────────────────────────
  stylix = {
    enable = true;
    image = ./dwl/wallpaper.png;

    base16Scheme =
      "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";

    fonts = {
      serif.package = pkgs.open-sans;
      serif.name = "Open Sans";

      sansSerif.package = pkgs.open-sans;
      sansSerif.name = "Open Sans";

      monospace.package = pkgs.fira-code-nerdfont;
      monospace.name = "Fira Code Nerdfont";

      emoji.package = pkgs.noto-fonts-emoji;
      emoji.name = "Noto Color Emoji";
    };

  };

  # ─────────────────────────────────────────────────────────────────────────────
  # 13. Global System Packages
  # ─────────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    pulseaudio
    swayidle
    wlr-randr
    yubikey-personalization
    yubico-pam
    yubikey-manager
    sops
    wmenu
    swaybg
  ];

  # ─────────────────────────────────────────────────────────────────────────────
  # 14. FUSE Settings
  # ─────────────────────────────────────────────────────────────────────────────
  programs.fuse.userAllowOther = true;
}
