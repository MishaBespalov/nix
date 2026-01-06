{
  pkgs,
  ...
}: {
  # SSH configuration
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      AddKeysToAgent yes
      IdentityFile ~/.ssh/mbespalovKTS
      IdentityFile ~/.ssh/main_key
    '';
  };

  # Enable ssh-agent service
  services.ssh-agent.enable = true;

  # Service to automatically add SSH key to agent on login
  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "Add SSH key to agent";
      After = ["ssh-agent.service"];
      Wants = ["ssh-agent.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "add-ssh-keys" ''
        ${pkgs.openssh}/bin/ssh-add ~/.ssh/mbespalovKTS
        ${pkgs.openssh}/bin/ssh-add ~/.ssh/main_key
      ''}";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
