{ pkgs, lib, config, ... }:

{
  # Parallels-specific configuration
  hardware.parallels.enable = true;
  
  # Parallels-specific shell aliases for display management
  programs.bash.shellAliases = {
    desk = "wlr-randr --output Virtual-1 --custom-mode 3840x2160 --scale 2";
    lap = "wlr-randr --output Virtual-1 --mode 2560x1600 --scale 2";
  };
}