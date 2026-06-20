{
  pkgs,
  inputs,
  ...
}: let
  hunk = inputs.hunk.packages.${pkgs.system}.default;
in {
  home.packages = [hunk];

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      core.pager = "${hunk}/bin/hunk pager";
    };
  };

  programs.lazygit = {
    enable = true;
  };
}
