{pkgs, ...}: {
  # SSH configuration
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    includes = ["~/.ssh/tw-config"];
    extraConfig = ''
      AddKeysToAgent yes
      IdentityFile ~/.ssh/main_key
      IdentityFile ~/.ssh/mbespalovTW
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
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
      ExecStart = "${pkgs.writeShellScript "add-ssh-keys" ''
        ${pkgs.openssh}/bin/ssh-add ~/.ssh/mbespalovKTS
        ${pkgs.openssh}/bin/ssh-add ~/.ssh/main_key
        ${pkgs.openssh}/bin/ssh-add ~/.ssh/mbespalovTW
      ''}";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
