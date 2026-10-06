{ config, pkgs, specialArgs, lib, ... }:
{
  # Passphrase comes from the macOS Keychain with no prompt once logged in
  # ("Save in Keychain" in the first prompt, then "Always Allow"). This needs
  # GPG Suite (brew cask gpg-suite-no-mail; the standalone gpg-suite-pinentry
  # cask lacks the MacGPG2 libs its pinentry loads): it is Developer ID
  # signed, so macOS keeps "Always Allow". Homebrew's pinentry-mac is only
  # ad-hoc signed and gets asked on every use.
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program /usr/local/MacGPG2/libexec/pinentry-mac.app/Contents/MacOS/pinentry-mac
    # also keep it in memory, so the Keychain is read once per gpg-agent start
    default-cache-ttl 34560000
    max-cache-ttl 34560000
  '';

  # Homebrew's current GnuPG does the signing; GPG Suite (GnuPG 2.2, EOL)
  # only provides the pinentry and must not win in PATH-less contexts
  home.file.".config/git/platform.gitconfig".text = ''
    [gpg]
    	program = /opt/homebrew/bin/gpg
  '';

  home.activation.gpgKeychain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write org.gpgtools.common UseKeychain -bool true
    /usr/bin/defaults write org.gpgtools.common DisableKeychain -bool false
    /opt/homebrew/bin/gpgconf --kill gpg-agent || true
    /usr/local/bin/gpgconf --kill gpg-agent 2>/dev/null || true
    # GPG Suite's updater phones home every 3h; Homebrew updates the cask
    /bin/launchctl disable gui/$(id -u)/org.gpgtools.updater || true
    /bin/launchctl bootout gui/$(id -u)/org.gpgtools.updater 2>/dev/null || true
  '';
}
