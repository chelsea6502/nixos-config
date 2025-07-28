{ config, ... }:
{
  enable = true;
  config = {
    modifier = "Mod4";
    terminal = "alacritty";
    output = {
      "DP-3" = {
        mode = "3840x2160@240Hz";
        scale = "2";
      };
    };
    gaps = {
      smartGaps = true;
      smartBorders = "no_gaps";
      inner = 10;
      outer = 10;
    };
    floating.criteria = [
      { title = "Parallels Shared Clipboard"; }
    ];
    window.titlebar = false;
    bars = [
      (
        {
          position = "top";
        }
        // config.stylix.targets.sway.exportedBarConfig
      )
    ];

  };
}
