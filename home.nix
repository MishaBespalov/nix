{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./home/modules/common
    ./home/modules/desktop
    ./home/modules/git
    ./home/modules/hyprland
    ./home/modules/k9s
    ./home/modules/nixvim
    ./home/modules/shell
    ./home/modules/ssh
    ./home/modules/yazi
  ];

  home.username = "misha";
  home.homeDirectory = "/home/misha";
  home.stateVersion = "25.05";
}
