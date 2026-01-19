{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    colorschemes.ayu = {
      enable = false;
      settings = {
        mirage = false;
      };
    };

    plugins = {
      obsidian = {
        enable = true;

        # This mirrors `require("obsidian").setup({ ... })"
        settings = {
          ui = {
            enable = true;
          };
          # Pick where your vault(s) live
          workspaces = [
            {
              name = "personal";
              path = "/home/misha/notes"; # create this directory once
            }
            # { name = "work"; path = "/home/misha/vaults/work"; }
          ];

          # Completion source for [[links]] and #tags via nvim-cmp
          completion = {
            nvim_cmp = true;
            min_chars = 2;
          };

          # Where new notes go (choose one)
          new_notes_location = "current_dir"; # or "notes_subdir"
          notes_subdir = "notes"; # used if you pick "notes_subdir"

          # Daily notes layout (optional)
          daily_notes = {
            folder = "notes/dailies";
            date_format = "%Y-%m-%d";
            alias_format = "%B %-d, %Y";
            default_tags = ["daily"];
          };

          # Where pasted images are stored (optional)
          attachments = {
            img_folder = "assets/img";
          };

          # Defaults already include a handy `gf` passthrough on markdown links,
          # smart <CR>, checkbox toggle, etc., so no need to redefine here.
        };
      };

      web-devicons.enable = true;

      yazi.enable = true;

      neo-tree = {
        enable = true;

        # show these sources in the sidebar
        sources = ["filesystem" "buffers" "git_status"];

        # Window & layout
        window = {
          position = "left"; # "right" | "left" | "float" | "top" | "bottom" | "current"
          width = 34;
          # you can also add per-window mappings here if you want to override defaults
          # mappings."<C-h>" = "none";  # example to unmap something
        };

        # Filesystem behavior
        filesystem = {
          bindToCwd = true;
          followCurrentFile = {enabled = true;}; # auto-focus current file in tree
          groupEmptyDirs = true;
          filteredItems = {
            visible = true; # show hidden, but de-emphasized
            hideDotfiles = false; # keep dotfiles visible
            hideGitignored = true; # still hide .gitignore'd files by default
          };
          # When opening `nvim .`, let neo-tree handle the directory instead of netrw:
          hijackNetrwBehavior = "open_default"; # or "open_current", "disabled"
          useLibuvFileWatcher = true; # live updates without manual refresh
        };

        # Little UX tweaks
        popupBorderStyle = "rounded";
        enableGitStatus = true;
        enableDiagnostics = true;
        closeIfLastWindow = true; # close tree when it’s the last window
      };

      lualine.enable = false;
      which-key.enable = false;
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 300;
          };
        };
      };

      bufferline = {
        enable = true;
        settings = {
          options = {
            mode = "buffers"; # show buffers, not actual Vim tabs
            diagnostics = "nvim_lsp"; # little diagnostic badges per buffer
            show_buffer_close_icons = false;
            show_close_icon = false;
            separator_style = "slant"; # "thin" if you prefer
            always_show_bufferline = true;

            # Make space for Neo-tree on the left so the tabs don’t shift
            offsets = [
              {
                filetype = "neo-tree";
                text = "File Explorer";
                highlight = "Directory";
                text_align = "left";
                separator = true;
              }
            ];
          };
        };
      };

      fzf-lua = {
        enable = true;
        settings = {
          defaults = {
            formatter = "path.filename_first";
            file_ignore_patterns = [".git/" "node_modules/"];
          };
          files = {
            prompt = "Files❯ ";
            previewer = "bat";
          };
          grep = {
            prompt = "Rg❯ ";
            input_prompt = "Grep For❯ ";
          };
          buffers = {
            prompt = "Buffers❯ ";
          };
          winopts = {
            height = 0.95;
            width = 0.95;
            row = 0.35;
            col = 0.50;
            border = "rounded";
            preview = {
              default = "bat";
              border = "border";
              wrap = false;
            };
          };
          keymap = {
            fzf = {
              "ctrl-q" = "select-all+accept";
              "ctrl-d" = "preview-page-down";
              "ctrl-u" = "preview-page-up";
            };
          };
        };
      };
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensureInstalled = [
            "lua"
            "nix"
            "vim"
            "vimdoc"
            "bash"
            "javascript"
            "typescript"
            "tsx"
            "json"
            "yaml"
            "toml"
            "proto"
            "sql"
            "python"
            "rust"
            "go"
            "gomod"
            "gosum"
            "gowork"
            "zig"
            "markdown"
            "markdown_inline"
            "dockerfile"
            "helm"
          ];
        };
      };
      treesitter-context.enable = false;
      treesitter-textobjects.enable = true;

      # #- LSP / UI polish #-
      fidget.enable = true;
      lspkind.enable = true;
      trouble.enable = true;
      todo-comments.enable = true;
      aerial.enable = true;
      luasnip.enable = true;
      friendly-snippets.enable = true;
      vim-surround.enable = true;
      indent-blankline.enable = true; # aka ibl
      ts-context-commentstring.enable = true;
      colorizer.enable = true;
      dressing.enable = true; # nicer vim.ui.select/input
      notify.enable = false; # notifications
      noice.enable = true; # commandline/LSP UIs
      zen-mode = {
        enable = false;
        settings = {
          window = {
            width = 120;
            options = {
              number = false;
              relativenumber = false;
              signcolumn = "no";
              cursorline = false;
            };
          };
          plugins = {
            gitsigns = {enabled = false;};
            tmux = {enabled = true;};
          };
        };
      };

      diffview.enable = true;
      git-conflict.enable = true;

      comment.enable = true;
      nvim-autopairs.enable = true;
      lazygit.enable = true;
      toggleterm.enable = true;

      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true; # if no formatter, use LSP
            timeout_ms = 1000;
          };
          formatters_by_ft = {
            nix = ["alejandra"]; # or: [ "nixpkgs_fmt" ]
            go = ["gofumpt" "goimports"];
            yaml = ["prettier"];
            json = ["prettier"];
            zig = ["zigfmt"]; # uses zig fmt
            rust = ["rustfmt"];
            dockerfile = ["hadolint"];
          };
          formatters = {
            rustfmt = {
              prepend_args = ["--config-path" "/home/misha/.config/rustfmt/rustfmt.toml"];
            };
          };
        };
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          mapping = {
            "<S-Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
          sources = [
            # {name = "supermaven";}
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "path";}
            {name = "buffer";}
            # Enhanced snippet sources for DevOps workflows
            {
              name = "luasnip";
              priority = 1000;
              keyword_length = 2;
            }
          ];
        };
      };
      lsp = {
        enable = true;
        inlayHints = true;
        keymaps.lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
          "gr" = "references";
          "gi" = "implementation";
          "K" = "hover";
        };

        servers = {
          protols = {
            enable = false;
          };
          nil_ls.enable = true;
          lua_ls.enable = true;
          ts_ls.enable = true;
          pyright.enable = true;
          rust_analyzer.enable = false;
          # DevOps LSP servers
          yamlls = {
            enable = true;
            settings = {
              yaml = {
                # Kubernetes schema validation
                schemas = {
                  "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.0/all.json" = "/*.k8s.yaml";
                  "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "/*docker-compose*.yml";
                  "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks" = "/ansible/**/*.yml";
                };
                validate = true;
                completion = true;
                hover = true;
              };
            };
          };
          dockerls.enable = true;
          helm_ls.enable = true;
          gopls = {
            enable = true;
            settings = {
              gopls = {
                gofumpt = true; # match our formatter
                staticcheck = true; # deeper checks
                usePlaceholders = true; # nicer completions/signatures
                analyses = {
                  # useful diagnostics
                  unusedparams = true;
                  nilness = true;
                  shadow = true;
                  unusedwrite = true;
                  fieldalignment = true;
                };
                directoryFilters = ["-**/node_modules" "-**/.git"];
              };
            };
          };
        };
      };
    };

    # Core UI + behavior
    globals = {
      omni_sql_no_default_maps = 1;
      mapleader = " ";
    };
    opts = {
      laststatus = 0;
      number = true;
      relativenumber = false;
      ruler = true;
      cursorline = true;
      termguicolors = true;
      expandtab = true;
      conceallevel = 2;
      shiftwidth = 2;
      undofile = true;
      swapfile = false;
      tabstop = 2;
      clipboard = "unnamedplus,unnamed";
    };

    # Put language servers/formatters on PATH the Nix way
    extraPackages = with pkgs; [
      # LSP servers
      nil
      lua-language-server
      typescript-language-server
      pyright
      gopls
      go
      gotools # includes goimports et al.
      gofumpt # strict formatter
      golangci-lint # optional, for heavy linting outside LSP
      lazygit
      wl-clipboard

      # Formatters (used by :LspFormat or plugins like conform/formatter of choice)
      stylua
      alejandra # Nix formatter
      black # Python
      gofumpt
      nodePackages.prettier

      # DevOps LSP servers and tools
      yaml-language-server
      dockerfile-language-server-nodejs
      helm-ls
      hadolint # Dockerfile linter
      ansible-language-server
    ];

    keymaps = [
      {
        mode = "n";
        key = "xx";
        action = "\"+dd";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<leader>ww";
        action = "<C-w>w";
        options.silent = true;
        options.desc = "Focus next window";
      }

      {
        mode = "n";
        key = "<leader>sf";
        action.__raw = ''
          function()
            local root = _G.project_root()
            require("fzf-lua").files({ cwd = root })
          end
        '';
        options = {
          desc = "Find files in project (git root)";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>ow";
        action = ''<cmd>e /home/misha/notes/work.md<CR>'';
        options = {
          desc = "Open notes work";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>ol";
        action = ''<cmd>e /home/misha/notes/life.md<CR>'';
        options = {
          desc = "Open notes life";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>os";
        action = "<cmd>ObsidianSearch<CR>";
        options = {
          desc = "Obsidian: search";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>on";
        action = "<cmd>ObsidianNew<CR>";
        options = {
          desc = "Obsidian: new";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>of";
        action = "<cmd>ObsidianFollowLink<CR>";
        options = {
          desc = "Obsidian: follow link";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>od";
        action = "<cmd>ObsidianToday<CR>";
        options = {
          desc = "Obsidian: today";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tt";
        # Raw Lua function so we stay declarative in Nix
        action.__raw = ''
          function()
            -- directory of current buffer; fall back to CWD for unsaved buffers
            local dir = vim.fn.expand("%:p:h")
            if dir == "" then dir = vim.loop.cwd() end

            -- quote safely for hyprctl's /bin/sh -c
            local cmd = "ghostty --working-directory=" .. vim.fn.shellescape(dir)

            vim.fn.jobstart({ "hyprctl", "dispatch", "exec", cmd }, { detach = true })
          end
        '';
        options = {
          desc = "Spawn Ghostty with Zellij in current buffer directory";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader><leader>";
        action.__raw = ''
          function()
            require("yazi").yazi({ cwd = "/home/misha" })
            vim.defer_fn(function()
              vim.api.nvim_feedkeys("Z", "n", false)
            end, 100)
          end
        '';
        # action = ''<cmd>lua require("yazi").yazi({ cwd = vim.uv.os_homedir() })<CR>'';
        # action = ''<cmd>lua require("yazi").yazi({ cwd = vim.loop.os_homedir() })<CR>'';
        options = {
          desc = "Yazi (cwd)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "L"; # Shift+l
        action = "<cmd>lua vim.diagnostic.open_float(nil, { scope = 'line' })<CR>";
        options = {
          desc = "Show full diagnostic for this line";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "B"; # Shift+b
        action = "<cmd>lua require('toggleterm.terminal').Terminal:new({cmd='bacon clippy', direction='horizontal', size=15}):toggle()<CR>";
        options = {
          desc = "Toggle bacon clippy checker";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>Bdelete<CR>";
        options = {
          desc = "Close buffer (keep layout)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<S-Left>";
        action = "<cmd>BufferLineCyclePrev<CR>";
        options = {
          desc = "Prev buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<S-Right>";
        action = "<cmd>BufferLineCycleNext<CR>";
        options = {
          desc = "Next buffer";
          silent = true;
        };
      }

      {
        mode = "n";
        key = "<leader>sb";
        action = "<cmd>FzfLua blines<CR>";
        options = {
          desc = "Search lines in current buffer";
          silent = true;
        };
      }

      # telescope: project-wide grep (uses ripgrep)
      {
        mode = "n";
        key = "<leader>sg";
        action = "<cmd>FzfLua live_grep<CR>";
        options = {
          desc = "Live grep in project";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua _G.NeoTreeProjectToggle()<CR>";
        options = {
          desc = "Neo-tree (project root of current buffer)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "d";
        action = "\"_d";
      }
      {
        mode = "x";
        key = "d";
        action = "\"_d";
      } # visual
      {
        mode = "n";
        key = "D";
        action = "\"_D";
      }
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<CR>";
        options = {
          desc = "Open LazyGit";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>z";
        action = "<cmd>ZenMode<CR>";
        options = {
          desc = "Toggle Zen Mode";
          silent = true;
        };
      }

      # Visual mode indent/unindent that keeps selection
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options = {
          desc = "Indent left and keep selection";
          silent = true;
        };
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options = {
          desc = "Indent right and keep selection";
          silent = true;
        };
      }

      # Delete all buffers except current
      {
        mode = "n";
        key = "<leader>ba";
        action = "<cmd>%bd|e#|bd#<CR>";
        options = {
          desc = "Delete all buffers except current";
          silent = true;
        };
      }

      # Task cycling functionality for markdown checkboxes
      {
        mode = "n";
        key = "<CR>";
        action = "<cmd>lua CycleMarkdownTask()<CR>";
        options = {
          desc = "Cycle through task states or normal Enter";
          silent = true;
        };
      }
    ];

    extraPlugins = with pkgs.vimPlugins; [
      (pkgs.vimUtils.buildVimPlugin {
        name = "rustheme";
        src = pkgs.fetchFromGitHub {
          owner = "nasccped";
          repo = "rustheme.nvim";
          rev = "2545d6db4ba9932b7a1b815a993901271b6f768b";
          sha256 = "1qd7zcyg07166jmvmcp8mj5wajsnbabf0ika098kx8lc4hrz7dwv";
        };
      })
      # supermaven-nvim
      nvim-lint
      plenary-nvim
      nui-nvim
      bufdelete-nvim
      # Additional snippet sources
      vim-snippets # Contains k8s, ansible, systemd snippets
    ];

    extraConfigLua = ''
      vim.cmd.colorscheme("rustheme")
      vim.api.nvim_set_hl(0, "Normal", { bg = "#222222" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#222222" })

      local lspconfig = require('lspconfig')
                  lspconfig["rust_analyzer"].setup({
                     cmd = { "rust-analyzer" },
                     settings = {
                       ["rust-analyzer"] = {
                         check = {
                           command = "clippy",
                         },
                       },
                     },
                   })

                   -- Configure ZLS to work with Zig from overlay
                   lspconfig.zls.setup({
                     cmd = { "zls" },
                     filetypes = { "zig", "zir" },
                     root_dir = lspconfig.util.root_pattern("build.zig", "zls.json", ".git"),
                     settings = {
                       zls = {
                         -- Enable semantic tokens for better highlighting
                         enable_semantic_tokens = true,
                         -- Enable inlay hints for function parameters and return types
                         enable_inlay_hints = true,
                         inlay_hints_show_builtin = true,
                         -- Enable style warnings
                         warn_style = true,
                         -- Highlight global variable declarations
                         highlight_global_var_declarations = true,
                         -- Enable snippets and autofix
                         enable_snippets = true,
                         enable_autofix = true,
                         -- Better completion
                         completion_label_details = true,
                       }
                     },
                     on_attach = function(client, bufnr)
                       -- Enable inlay hints if supported
                       if client.server_capabilities.inlayHintProvider then
                         vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                       end
                     end,
                   })

                  vim.deprecate = function() end
                  _G.project_root = function()
                    local buf = vim.api.nvim_get_current_buf()
                    local name = vim.api.nvim_buf_get_name(buf)
                    local start = (name ~= "" and vim.fs.dirname(name)) or vim.loop.cwd()
                    -- Only use .git as project root marker
                    local found = vim.fs.find(".git", { path = start, upward = true })[1]
                    return found and vim.fs.dirname(found) or start
                  end

                  _G.NeoTreeProjectToggle = function()
                    local dir = project_root()
                    -- Use Neotree's flags to force cwd to the root and reveal current file there
                    vim.cmd("Neotree toggle reveal_force_cwd dir=" .. vim.fn.fnameescape(dir))
                  end

                        local lint = require("lint")

                        -- Use the built-in 'golangcilint' linter
                        -- (see :h nvim-lint Available Linters)
                        lint.linters_by_ft = {
                          yaml = { "yamllint" },
                          dockerfile = { "hadolint" },
                          -- ansible = { "ansible-lint" },  -- disabled due to dependency conflicts
                        }

                        -- Configure yamllint to ignore line-too-long rule
                        lint.linters.yamllint.args = {
                          '-d',
                          '{extends: default, rules: {line-length: disable}}',
                          '-f', 'parsable',
                          '-'
                        }

                        -- Lint on save (you can also add "BufEnter" or "InsertLeave" if you want)
                        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
                          callback = function()
                            lint.try_lint()
                          end,
                        })
                              vim.diagnostic.config({
                                virtual_text = false,          -- show inline diagnostics
                                signs = {
                                  text = {
                                    [vim.diagnostic.severity.ERROR] = "",
                                    [vim.diagnostic.severity.WARN ] = "",
                                    [vim.diagnostic.severity.INFO ] = "",
                                    [vim.diagnostic.severity.HINT ] = "󰌶",
                                  },
                                },
                                underline = true,
                                update_in_insert = false,
                                severity_sort = true,
                                float = { border = "rounded", source = "if_many", focusable = false },
                              })
      local ST = {
        timer   = nil,   -- uv timer
        buf     = nil,   -- scratch buffer
        win     = nil,   -- floating window
        total   = 0,     -- seconds remaining
        initial = 0,     -- seconds for (re)starts
        running = false, -- is timer ticking?
      }

      local WIDTH = 12

      local function open_win()
        if ST.buf == nil or not vim.api.nvim_buf_is_valid(ST.buf) then
          ST.buf = vim.api.nvim_create_buf(false, true)
        end
        if ST.win == nil or not vim.api.nvim_win_is_valid(ST.win) then
          local ui = vim.api.nvim_list_uis()[1]
          ST.win = vim.api.nvim_open_win(ST.buf, false, {
            relative = "editor",
            row = 1,
            col = ui.width - WIDTH - 2,
            width = WIDTH,
            height = 1,
            style = "minimal",
            border = "rounded",
            noautocmd = true,
          })
        end
      end

      local function close_win()
        if ST.win and vim.api.nvim_win_is_valid(ST.win) then
          pcall(vim.api.nvim_win_close, ST.win, true)
        end
        ST.win = nil
      end

      local function render()
        if not (ST.buf and vim.api.nvim_buf_is_valid(ST.buf)) then return end
        local secs = math.max(ST.total, 0)
        local m = math.floor(secs / 60)
        local s = secs % 60
        vim.api.nvim_buf_set_lines(ST.buf, 0, -1, false, { string.format("⏱ %02d:%02d", m, s) })
      end

      local function stop_timer(silent)
        if ST.timer then
          ST.timer:stop()
          ST.timer:close()
          ST.timer = nil
        end
        ST.running = false
        close_win()
        if not silent then vim.notify("Timer stopped") end
      end

      local function finish()
        -- called when time hits zero
        if ST.timer then
          ST.timer:stop()
          ST.timer:close()
          ST.timer = nil
        end
        ST.running = false
        vim.schedule(function()
          close_win()
          vim.notify("Time's up!")
        end)
      end

      local function tick_callback()
        ST.total = ST.total - 1
        if ST.total < 0 then
          finish()
          return
        end
        vim.schedule(render)
      end

      local function start_timer(minutes)
        stop_timer(true) -- clean previous
        ST.initial = math.floor((tonumber(minutes) or 25) * 60)
        ST.total = ST.initial
        open_win()
        render()
        ST.timer = vim.loop.new_timer()
        ST.timer:start(1000, 1000, tick_callback)
        ST.running = true
      end
      local function pause_timer()
        if ST.timer and ST.running then
          ST.timer:stop()
          ST.running = false
          vim.notify("Timer paused")
        end
      end
      local function resume_timer()
        if ST.timer and not ST.running then
          ST.timer:start(1000, 1000, tick_callback)
          ST.running = true
          vim.notify("Timer resumed")
        end
      end
      local function reset_timer(minutes)
        local m = tonumber(minutes)
        if m then ST.initial = math.floor(m * 60) end
        start_timer(ST.initial / 60)
        vim.notify("Timer reset")
      end
      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          if ST.win and vim.api.nvim_win_is_valid(ST.win) then
            local ui = vim.api.nvim_list_uis()[1]
            vim.api.nvim_win_set_config(ST.win, {
              relative = "editor",
              row = 1,
              col = ui.width - WIDTH - 2,
              width = WIDTH,
              height = 1,
            })
          end
        end,
      })
      vim.api.nvim_create_user_command("SimpleTimer", function(opts)
        start_timer(opts.args ~= "" and tonumber(opts.args) or nil)
      end, { nargs = "?" })
      vim.api.nvim_create_user_command("SimpleTimerStop",   function() stop_timer(false) end, {})
      vim.api.nvim_create_user_command("SimpleTimerPause",  function() pause_timer()      end, {})
      vim.api.nvim_create_user_command("SimpleTimerResume", function() resume_timer()     end, {})
      vim.api.nvim_create_user_command("SimpleTimerReset",  function(opts) reset_timer(opts.args) end, { nargs = "?" })

      -- Enhanced snippet configuration for DevOps workflows
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_snipmate").lazy_load()

      local luasnip = require("luasnip")
      local s = luasnip.snippet
      local t = luasnip.text_node
      local i = luasnip.insert_node
      local f = luasnip.function_node

      -- Custom Kubernetes snippets
      luasnip.add_snippets("yaml", {
        s("k8s-deployment", {
          t({"apiVersion: apps/v1", "kind: Deployment", "metadata:", "  name: "}), i(1, "app-name"),
          t({"", "  namespace: "}), i(2, "default"),
          t({"", "spec:", "  replicas: "}), i(3, "3"),
          t({"", "  selector:", "    matchLabels:", "      app: "}), f(function(args) return args[1][1] end, {1}),
          t({"", "  template:", "    metadata:", "      labels:", "        app: "}), f(function(args) return args[1][1] end, {1}),
          t({"", "    spec:", "      containers:", "      - name: "}), f(function(args) return args[1][1] end, {1}),
          t({"", "        image: "}), i(4, "nginx:latest"),
          t({"", "        ports:", "        - containerPort: "}), i(5, "80"),
        }),

        s("k8s-service", {
          t({"apiVersion: v1", "kind: Service", "metadata:", "  name: "}), i(1, "app-service"),
          t({"", "  namespace: "}), i(2, "default"),
          t({"", "spec:", "  selector:", "    app: "}), i(3, "app-name"),
          t({"", "  ports:", "  - port: "}), i(4, "80"),
          t({"", "    targetPort: "}), i(5, "80"),
          t({"", "    protocol: TCP", "  type: "}), i(6, "ClusterIP"),
        }),

        s("k8s-configmap", {
          t({"apiVersion: v1", "kind: ConfigMap", "metadata:", "  name: "}), i(1, "app-config"),
          t({"", "  namespace: "}), i(2, "default"),
          t({"", "data:", "  "}), i(3, "config.yaml"), t({": |", "    "}), i(4, "# configuration content"),
        }),

        s("k8s-secret", {
          t({"apiVersion: v1", "kind: Secret", "metadata:", "  name: "}), i(1, "app-secret"),
          t({"", "  namespace: "}), i(2, "default"),
          t({"", "type: Opaque", "data:", "  "}), i(3, "password"), t({": "}), i(4, "# base64 encoded value"),
        }),

        s("systemd-service", {
          t({"[Unit]", "Description="}), i(1, "My Service"),
          t({"", "After="}), i(2, "network.target"),
          t({"", "", "[Service]", "Type="}), i(3, "simple"),
          t({"", "User="}), i(4, "root"),
          t({"", "ExecStart="}), i(5, "/usr/bin/myapp"),
          t({"", "Restart="}), i(6, "always"),
          t({"", "RestartSec="}), i(7, "10"),
          t({"", "", "[Install]", "WantedBy="}), i(8, "multi-user.target"),
        }),

        -- Ansible snippets
        s("ansible-playbook", {
          t({"---", "- name: "}), i(1, "Playbook description"),
          t({"", "  hosts: "}), i(2, "all"),
          t({"", "  become: "}), i(3, "yes"),
          t({"", "  vars:", "    "}), i(4, "variable_name"), t({": "}), i(5, "value"),
          t({"", "  tasks:", "    - name: "}), i(6, "Task description"),
          t({"", "      "}), i(7, "module_name"), t({":"}),
          t({"", "        "}), i(8, "parameter"), t({": "}), i(9, "value"),
        }),

        s("ansible-task", {
          t({"- name: "}), i(1, "Task description"),
          t({"", "  "}), i(2, "module_name"), t({":"}),
          t({"", "    "}), i(3, "parameter"), t({": "}), i(4, "value"),
          t({"", "  when: "}), i(5, "condition"),
          t({"", "  notify: "}), i(6, "handler_name"),
        }),
      })

      -- Auto-change working directory to match current buffer
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          local buf_name = vim.api.nvim_buf_get_name(0)
          if buf_name ~= "" and vim.fn.filereadable(buf_name) == 1 then
            local dir = vim.fn.fnamemodify(buf_name, ":p:h")
            if vim.fn.isdirectory(dir) == 1 then
              vim.cmd("cd " .. vim.fn.fnameescape(dir))
            end
          end
        end,
      })

      -- Task cycling function
      function CycleMarkdownTask()
        -- Only work in markdown files
        if vim.bo.filetype ~= "markdown" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
          return
        end

        local line = vim.api.nvim_get_current_line()
        local row = vim.api.nvim_win_get_cursor(0)[1]

        -- Debug: print the current line and filetype
        print("Function called! Filetype: " .. vim.bo.filetype)
        print("Current line: '" .. line .. "'")

        -- Kanban task state cycling patterns
        local task_patterns = {
          { pattern = "^(%s*)- %[ %](.*)$", replacement = "%1- [>]%2" },  -- unchecked -> todo
          { pattern = "^(%s*)- %[>%](.*)$", replacement = "%1- [/]%2" },  -- todo -> in progress
          { pattern = "^(%s*)- %[/%](.*)$", replacement = "%1- [r]%2" },  -- in progress -> review
          { pattern = "^(%s*)- %[r%](.*)$", replacement = "%1- [x]%2" },  -- review -> checked
          { pattern = "^(%s*)- %[x%](.*)$", replacement = "%1- [h]%2" },  -- checked -> hold
          { pattern = "^(%s*)- %[h%](.*)$", replacement = "%1- [b]%2" },  -- hold -> blocked
          { pattern = "^(%s*)- %[b%](.*)$", replacement = "%1- [!]%2" },  -- blocked -> urgent
          { pattern = "^(%s*)- %[!%](.*)$", replacement = "%1- [?]%2" },  -- urgent -> note
          { pattern = "^(%s*)- %[?%](.*)$", replacement = "%1- [~]%2" }, -- note -> cancelled
          { pattern = "^(%s*)- %[~%](.*)$", replacement = "%1- [ ]%2" },  -- cancelled -> unchecked
        }

        local updated = false
        for i, task in ipairs(task_patterns) do
          local new_line = line:gsub(task.pattern, task.replacement)
          print("Pattern " .. i .. ": '" .. task.pattern .. "' -> result: '" .. new_line .. "'")
          if new_line ~= line then
            print("MATCH! Updating line to: '" .. new_line .. "'")
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
            updated = true
            -- Keep cursor position roughly the same
            local col = vim.api.nvim_win_get_cursor(0)[2]
            vim.api.nvim_win_set_cursor(0, {row, math.min(col, #new_line - 1)})
            break
          end
        end

        -- If no task pattern matched, check if we're on a line that could become a task
        if not updated then
          print("No pattern matched, checking for conversion...")
          -- Check if line starts with "- " but isn't a task yet
          local indent, content = line:match("^(%s*)%- (.*)$")
          print("Indent: '" .. (indent or "nil") .. "', Content: '" .. (content or "nil") .. "'")
          if indent and content then
            local new_line = indent .. "- [ ] " .. content
            print("Converting to task: '" .. new_line .. "'")
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
            local col = vim.api.nvim_win_get_cursor(0)[2]
            vim.api.nvim_win_set_cursor(0, {row, math.min(col + 4, #new_line - 1)})
          else
            print("No conversion possible, doing normal Enter")
            -- Normal Enter behavior for non-list items
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
          end
        end
      end

      -- Custom Rust accent colors (only the ones we want to override)
      local rust_colors = {
        muted_red = "#ef6068",
        muted_orange = "#f08e5e",
        soft_orange = "#ffba50",
        muted_yellow = "#ebc245",
        muted_green = "#90b028",
        soft_green = "#c0da45",
        bright_green = "#90fa40",
        muted_aqua = "#50d0ad",
        soft_aqua = "#80ecc0",
        bright_aqua = "#a0f0d0",
        muted_blue = "#40a0e0",
        soft_blue = "#60c0fa",
        bright_blue = "#80d0ff",
        muted_purple = "#b080f0",
        soft_purple = "#d0b0ff",
        bright_purple = "#e0c0ff",
        gray = "#5c6773",
        fg3 = "#cbccc6",
      }

      -- Custom Rust syntax highlighting
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "rust",
        callback = function()
          -- Keywords
          vim.api.nvim_set_hl(0, "@keyword.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.function.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.operator.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.return.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.modifier.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.import.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.conditional.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.repeat.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@keyword.exception.rust", { fg = rust_colors.soft_orange })

          -- Functions
          vim.api.nvim_set_hl(0, "@function.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@function.call.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@function.method.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@function.method.call.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@function.macro.rust", { fg = rust_colors.soft_aqua })
          vim.api.nvim_set_hl(0, "@function.builtin.rust", { fg = rust_colors.bright_aqua })

          -- Types
          vim.api.nvim_set_hl(0, "@type.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@type.builtin.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@type.definition.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@type.qualifier.rust", { fg = rust_colors.soft_orange })

          -- Variables
          vim.api.nvim_set_hl(0, "@variable.rust", { fg = rust_colors.soft_blue })
          vim.api.nvim_set_hl(0, "@variable.builtin.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@variable.member.rust", { fg = rust_colors.bright_blue })

          -- Constants
          vim.api.nvim_set_hl(0, "@constant.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@constant.builtin.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@constant.macro.rust", { fg = rust_colors.soft_aqua })

          -- Strings
          vim.api.nvim_set_hl(0, "@string.rust", { fg = rust_colors.soft_green })
          vim.api.nvim_set_hl(0, "@string.escape.rust", { fg = rust_colors.soft_aqua })
          vim.api.nvim_set_hl(0, "@string.special.rust", { fg = rust_colors.soft_aqua })
          vim.api.nvim_set_hl(0, "@string.regexp.rust", { fg = rust_colors.soft_orange })

          -- Properties/Fields
          vim.api.nvim_set_hl(0, "@property.rust", { fg = rust_colors.bright_blue })
          vim.api.nvim_set_hl(0, "@field.rust", { fg = rust_colors.bright_blue })

          -- Namespaces/Modules (use soft light color)
          vim.api.nvim_set_hl(0, "@module.rust", { fg = "#d5c4a1" })
          vim.api.nvim_set_hl(0, "@namespace.rust", { fg = "#d5c4a1" })

          -- Labels
          vim.api.nvim_set_hl(0, "@label.rust", { fg = rust_colors.bright_blue })

          -- Special punctuation (references, pointers)
          vim.api.nvim_set_hl(0, "@punctuation.special.rust", { fg = rust_colors.soft_orange })

          -- Numbers
          vim.api.nvim_set_hl(0, "@number.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@number.float.rust", { fg = rust_colors.bright_purple })

          -- Booleans
          vim.api.nvim_set_hl(0, "@boolean.rust", { fg = rust_colors.bright_purple })

          -- Characters
          vim.api.nvim_set_hl(0, "@character.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@character.special.rust", { fg = rust_colors.soft_aqua })

          -- Lifetimes
          vim.api.nvim_set_hl(0, "@lifetime.rust", { fg = rust_colors.soft_purple })
          vim.api.nvim_set_hl(0, "@storageclass.lifetime.rust", { fg = rust_colors.soft_purple })

          -- Traits
          vim.api.nvim_set_hl(0, "@type.trait.rust", { fg = rust_colors.muted_yellow, italic = true })

          -- Enums
          vim.api.nvim_set_hl(0, "@type.enum.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@constant.enum.rust", { fg = rust_colors.bright_purple })

          -- Errors
          vim.api.nvim_set_hl(0, "@error.rust", { fg = rust_colors.muted_red })

          -- Constructors
          vim.api.nvim_set_hl(0, "@constructor.rust", { fg = rust_colors.muted_yellow })

          -- Include (use statements)
          vim.api.nvim_set_hl(0, "@include.rust", { fg = rust_colors.soft_orange })

          -- Unsafe
          vim.api.nvim_set_hl(0, "@keyword.unsafe.rust", { fg = rust_colors.soft_orange, bold = true })

          -- References and Pointers
          vim.api.nvim_set_hl(0, "@punctuation.special.reference.rust", { fg = rust_colors.soft_orange })

          -- Generic parameters
          vim.api.nvim_set_hl(0, "@type.parameter.rust", { fg = "#d5c4a1" })

          -- Where clauses
          vim.api.nvim_set_hl(0, "@keyword.where.rust", { fg = rust_colors.soft_orange })

          -- LSP Semantic Token Highlights
          vim.api.nvim_set_hl(0, "@lsp.type.namespace.rust", { fg = "#d5c4a1" })
          vim.api.nvim_set_hl(0, "@lsp.type.type.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.class.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.enum.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.interface.rust", { fg = rust_colors.muted_yellow, italic = true })
          vim.api.nvim_set_hl(0, "@lsp.type.struct.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.typeParameter.rust", { fg = "#d5c4a1" })
          vim.api.nvim_set_hl(0, "@lsp.type.parameter.rust", { fg = rust_colors.soft_blue })
          vim.api.nvim_set_hl(0, "@lsp.type.variable.rust", { fg = rust_colors.soft_blue })
          vim.api.nvim_set_hl(0, "@lsp.type.property.rust", { fg = rust_colors.bright_blue })
          vim.api.nvim_set_hl(0, "@lsp.type.enumMember.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@lsp.type.function.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@lsp.type.method.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@lsp.type.macro.rust", { fg = rust_colors.soft_aqua })
          vim.api.nvim_set_hl(0, "@lsp.type.keyword.rust", { fg = rust_colors.soft_orange })
          vim.api.nvim_set_hl(0, "@lsp.type.comment.rust", { fg = rust_colors.gray, italic = true })
          vim.api.nvim_set_hl(0, "@lsp.type.string.rust", { fg = rust_colors.soft_green })
          vim.api.nvim_set_hl(0, "@lsp.type.number.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@lsp.type.operator.rust", { fg = rust_colors.fg3 })
          vim.api.nvim_set_hl(0, "@lsp.type.lifetime.rust", { fg = rust_colors.soft_purple })
          vim.api.nvim_set_hl(0, "@lsp.type.builtinType.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.selfKeyword.rust", { fg = rust_colors.bright_purple })
          vim.api.nvim_set_hl(0, "@lsp.type.selfTypeKeyword.rust", { fg = rust_colors.muted_yellow })
          vim.api.nvim_set_hl(0, "@lsp.type.deriveHelper.rust", { fg = rust_colors.gray })
          vim.api.nvim_set_hl(0, "@lsp.type.formatSpecifier.rust", { fg = rust_colors.soft_aqua })

          -- LSP Semantic token modifiers (only the ones we want to customize)
          vim.api.nvim_set_hl(0, "@lsp.mod.mutable.rust", { underline = true })
          vim.api.nvim_set_hl(0, "@lsp.mod.unsafe.rust", { bold = true })
          vim.api.nvim_set_hl(0, "@lsp.mod.deprecated.rust", { fg = rust_colors.muted_red, strikethrough = true })

          -- Unused items (pale yellow-orange)
          vim.api.nvim_set_hl(0, "@lsp.typemod.variable.unused.rust", { fg = "#c4a67c", italic = true })
          vim.api.nvim_set_hl(0, "@lsp.typemod.function.unused.rust", { fg = "#c4a67c", italic = true })
          vim.api.nvim_set_hl(0, "@lsp.typemod.parameter.unused.rust", { fg = "#c4a67c", italic = true })
          vim.api.nvim_set_hl(0, "@lsp.typemod.type.unused.rust", { fg = "#c4a67c", italic = true })

          -- Alternative unused patterns (rust-analyzer might use different names)
          vim.api.nvim_set_hl(0, "@lsp.mod.unused.rust", { fg = "#c4a67c", italic = true })
          vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = rust_colors.muted_orange, italic = true })
          vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = rust_colors.muted_orange, strikethrough = true })

          -- Combined type.modifier patterns
          vim.api.nvim_set_hl(0, "@lsp.typemod.function.declaration.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@lsp.typemod.method.declaration.rust", { fg = rust_colors.bright_aqua })
          vim.api.nvim_set_hl(0, "@lsp.typemod.variable.mutable.rust", { underline = true })
          vim.api.nvim_set_hl(0, "@lsp.typemod.parameter.mutable.rust", { underline = true })
          vim.api.nvim_set_hl(0, "@lsp.typemod.selfKeyword.mutable.rust", { fg = rust_colors.bright_purple, underline = true })

          -- Inlay hints (subtle gray)
          vim.api.nvim_set_hl(0, "LspInlayHint", { fg = rust_colors.gray, italic = true })
        end,
      })

      -- Set global diagnostic highlights with delayed application
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
          -- Delay to ensure LSP has fully loaded
          vim.defer_fn(function()
            vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#c4a67c", italic = true })
            vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = "#c4a67c", strikethrough = true })
            vim.cmd("redraw!")
          end, 100)
        end,
      })

      -- Also try after colorscheme loads
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.defer_fn(function()
            vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#c4a67c", italic = true })
            vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = "#c4a67c", strikethrough = true })
          end, 50)
        end,
      })

      -- Also set them immediately
      vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#c4a67c", italic = true })
      vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = "#c4a67c", strikethrough = true })

      -- Create user command to manually fix unused colors
      vim.api.nvim_create_user_command("FixUnusedColors", function()
        vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#c4a67c", italic = true })
        vim.api.nvim_set_hl(0, "DiagnosticDeprecated", { fg = "#c4a67c", strikethrough = true })
        vim.cmd("redraw!")
        print("Unused variable colors fixed!")
      end, {})

    '';
  };
}
