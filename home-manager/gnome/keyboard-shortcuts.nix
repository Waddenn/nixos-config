{ config, pkgs, ... }:

{

  dconf.settings = {

    "org/gnome/desktop/wm/keybindings" = {
      minimize = [ "<Super>h" ];
      show-desktop = [ "<Super>d" ];
      toggle-fullscreen = [ "<Super>f" ];
      close = [ "<Super>q" "<Alt>F4" ];
      switch-to-workspace-left = [ "<Alt>Left" ];
      switch-to-workspace-right = [ "<Alt>Right" ];
      switch-to-workspace-1 = [ "<Alt>1" ];
      switch-to-workspace-2 = [ "<Alt>2" ];
      switch-to-workspace-3 = [ "<Alt>3" ];
      switch-to-workspace-4 = [ "<Alt>4" ];
      switch-to-workspace-5 = [ "<Alt>5" ];
      move-to-workspace-left = [ "<Ctrl><Alt>Left" ];
      move-to-workspace-right = [ "<Ctrl><Alt>Right" ];
      move-to-workspace-1 = [ "<Ctrl><Alt>1" ];
      move-to-workspace-2 = [ "<Ctrl><Alt>2" ];
      move-to-workspace-3 = [ "<Ctrl><Alt>3" ];
      move-to-workspace-4 = [ "<Ctrl><Alt>4" ];
      move-to-workspace-5 = [ "<Ctrl><Alt>5" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
      control-center = [ "<Super>i" ];
      home = [ "<Super>e" ];
      next = [ "<Super>AudioRaiseVolume" ];
      play = [ "<Super>AudioMute" ];
      previous = [ "<Super>AudioLowerVolume" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "kgx";
      name = "open-terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Shift><Control>Escape";
      command = "resources";
      name = "Resources";
    };

  };

}
