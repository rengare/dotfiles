#!/usr/bin/env bash

# Install Homebrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Cross-platform packages (mirrors nix/shared.nix)
brew install \
  bat \
  bottom \
  git-delta \
  duf \
  eza \
  fd \
  ffmpegthumbnailer \
  fzf \
  gh \
  htop \
  jq \
  jj \
  lazydocker \
  lazygit \
  llvm \
  midnight-commander \
  mise \
  nushell \
  poppler \
  ripgrep \
  tealdeer \
  unar \
  yazi \
  zoxide

# lazyjj is not available on Homebrew — install via cargo:
# cargo install lazyjj

# Linux-equivalent packages (optional on macOS, mirrors nix/linux/)
# brew install git zellij ncdu syncthing zola mpd
