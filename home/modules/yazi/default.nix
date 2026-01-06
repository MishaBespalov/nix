{
  pkgs,
  ...}: {
  programs.yazi = {
    enable = true;
    settings = {
      manager = {
        show_hidden = true;
      };
      opener = {
        edit = [
          {
            run = "nvim \"$@\"";
            block = true;
            desc = "Edit with Neovim";
          }
        ];
        open = [
          {
            run = "xdg-open \"$@\"";
            desc = "Open";
          }
        ];
        zen = [
          {
            run = "zen \"$@\"";
            orphan = true;
            desc = "Open in Zen Browser";
          }
        ];
        pdf = [
          {
            run = "zen \"$@\"";
            orphan = true;
            desc = "Open with Zen Browser";
          }
        ];
      };
      open = {
        rules = [
          {
            name = "*/";
            use = "edit";
          }
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "application/json";
            use = "edit";
          }
          {
            mime = "inode/x-empty";
            use = "edit";
          }

          {
            mime = "text/html";
            use = "zen";
          }
          {
            name = "*.html";
            use = "zen";
          }
          {
            name = "*.htm";
            use = "zen";
          }

          {
            mime = "application/pdf";
            use = "pdf";
          }
          {
            mime = "image/*";
            use = "open";
          }
          {
            mime = "video/*";
            use = "open";
          }
          {
            mime = "audio/*";
            use = "open";
          }

          {
            name = "*";
            use = "open";
          }
        ];
      };
    };
  };
}
