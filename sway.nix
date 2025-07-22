{ config, ... }:
{
  enable = true;
  config = {
    modifier = "Mod4";
    terminal = "alacritty";
    startup = [ { command = "qutebrowser"; } ];
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
