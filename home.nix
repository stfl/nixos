{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "stefan";
  home.homeDirectory = "/home/stefan";

  home.packages = with pkgs; [
    emacs
    firefox
    chromium
    neovim
    ripgrep
    httpie
    plex-media-player

    fd
    fasd

    xsel
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  programs = {
    home-manager.enable = true;  # Let Home Manager install and manage itself.
    git = {
      enable = true;
      lfs.enable = true;
      difftastic.enable = true;
      # diff-so-fancy.enable = true;
    };
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      changeDirWidgetCommand = "fd --type d";  # ALT-C
      changeDirWidgetOptions = [ "--preview 'tree -C {} | head -200'" ];
      defaultCommand = "fd --type f";
      fileWidgetCommand = "fd --type f";   # CTRL-T
      fileWidgetOptions = [ "--preview 'head {}'" ];
      tmux.enableShellIntegration = true;
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    lsd = {
      enable = true;
      enableAliases = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      stdlib = ''
layout_anaconda() {
  local ACTIVATE="$HOME/.anaconda3/bin/activate"

  if [ -n "$1" ]; then
    # Explicit environment name from layout command.
    local env_name="$1"
    source $ACTIVATE $env_name
  elif (grep -q name: environment.yml); then
    # Detect environment name from `environment.yml` file in `.envrc` directory
    source $ACTIVATE `grep name: environment.yml | sed -e 's/name: //' | cut -d "'" -f 2 | cut -d '"' -f 2`
  else
    (>&2 echo No environment specified);
    exit 1;
  fi;
}
'';
    };
  };


  programs.ssh = {
    enable = true;
    forwardAgent = false;
    controlMaster = "auto";
    controlPersist = "10m";
    includes = [ "${config.xdg.configHome}/ssh/*" ];
  };
  xdg.configFile."ssh/" = {
    recursive = true;
    source = ./ssh/config.d;
  };

  programs.zsh = {
    enable = true;
    profileExtra = ''
if [[ $TERM == dumb || -n $INSIDE_EMACS ]]; then
  unsetopt zle prompt_cr prompt_subst
  whence -w precmd >/dev/null && unfunction precmd
  whence -w preexec >/dev/null && unfunction preexec
  PS1='$ '
  break
fi
'';
    prezto = {
      enable = true;
      pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "history-substring-search"
          "directory"
          "spectrum"
          "syntax-highlighting"
          "utility"
          "completion"
          "autosuggestions"
          "archive"
          "fasd"
          "git"
          "rsync"
          # "prompt"  > starship instead
          # "ssh"
          # "gpg"
        ];
      editor = {
        keymap = "vi";
        dotExpansion = true;
      };
    };
    initExtra = ''
      # overwriting prezto's fasd alias j
      unalias j
      j() {
        local dir
        dir="$(fasd -Rdl "$1" | fzf-tmux -1 -0 --no-sort +m)" \
           && cd "$dir" \
           || return 1
      }
    '';
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    shortcut = "a";
    historyLimit = 300000;
    newSession = true;
    customPaneNavigationAndResize = true;
    resizeAmount = 10;
    escapeTime = 0;
    terminal = "screen-256color";
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs; [
      tmuxPlugins.yank
    ];

    extraConfig = ''
      set-option -g -q mouse on

      # emacs-like split
      bind-key v split-window -h
      bind-key s split-window -v

      # cycle pane selection
      bind C-a select-pane -t :.+

      bind-key p paste-buffer
      bind-key -T copy-mode-vi 'v' send-keys -X begin-selection

      # reorder windows in status bar by drag & drop
      bind-key -n MouseDrag1Status swap-window -t=

      bind-key W choose-session
      bind-key -n C-l send-keys 'C-l' \; clear-history


      # This tmux statusbar config was (originally) created by tmuxline.vim
      # on Mon, 08 Aug 2016
      setw -g monitor-activity on
      set-window-option -g clock-mode-colour colour11

      set -g status "on"
      # set -g status-utf8 "on"
      set -g status-style bg="colour0"
      set -g status-style "none"
      set -g status-justify "left"
      set -g status-left-length "100"
      set -g status-right-length "100"
      set -g status-left-style "none"
      set -g status-right-style "none"
      set -g message-style bg="colour11"
      set -g message-style fg="colour7"
      set -g message-command-style bg="colour11"
      set -g message-command-style fg="colour7"
      set -g pane-border-style fg="colour11"
      # set -g pane-active-border-style fg="colour14"
      set-option -g pane-active-border fg="colour166"
      setw -g window-status-style fg="colour10"
      setw -g window-status-style bg="colour0"
      setw -g window-status-style "none"
      setw -g window-status-activity-style bg="colour0"
      setw -g window-status-activity-style "none"
      setw -g window-status-activity-style fg="colour14"
      setw -g window-status-separator ""

      set -g status-left "#[fg=colour15,bg=colour14,bold] #S #[fg=colour14,bg=colour11,nobold,nounderscore,noitalics]#[fg=colour7,bg=colour11] #F #[fg=colour11,bg=colour0,nobold,nounderscore,noitalics]"

      # TODO > i can't be botherd to make this work...
      # if-shell "[[ #{client_width} > 180 ]]" \
      # "set -g status-right \"#[fg=colour0,bg=colour0,nobold,nounderscore,noitalics]#[fg=colour10,bg=colour0]  %a #[fg=colour11,bg=colour0,nobold,nounderscore,noitalics]#[fg=colour7,bg=colour11] %d. %h  %H:%M #[fg=colour14,bg=colour11,nobold,nounderscore,noitalics]#[fg=colour15,bg=colour14] #H \"" \
      # "set -g status-right \"#[fg=colour11,bg=colour0,nobold,nounderscore,noitalics]#[fg=colour7,bg=colour11] %d. %h  %H:%M #[fg=colour14,bg=colour11,nobold,nounderscore,noitalics]#[fg=colour15,bg=colour14] #H \""

      setw -g window-status-format "#[fg=colour0,bg=colour0,nobold,nounderscore,noitalics]#[default] #I #W #[fg=colour0,bg=colour0,nobold,nounderscore,noitalics]"

      setw -g window-status-current-format "#[fg=colour0,bg=colour11,nobold,nounderscore,noitalics]#[fg=colour7,bg=colour11] #I  #W #[fg=colour11,bg=colour0,nobold,nounderscore,noitalics]"
    '';
  };

  programs.alacritty.enable = true;
  xdg.configFile."alacritty/alacritty.yml" = {
    source = ./alacritty.yml;
  };
}
