{ config, pkgs, specialArgs, lib, ... }:
{
  # pinentry-mac fetches the passphrase from the macOS Keychain once it was
  # saved there ("Save in Keychain" in the first prompt), so commits get
  # signed without asking again
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program /opt/homebrew/bin/pinentry-mac
    # keep the passphrase for the whole login, so the Keychain is asked at
    # most once per gpg-agent start
    default-cache-ttl 34560000
    max-cache-ttl 34560000
  '';

  home.activation.gpgKeychain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/defaults write org.gpgtools.common UseKeychain -bool true
    /usr/bin/defaults write org.gpgtools.common DisableKeychain -bool false
    /opt/homebrew/bin/gpgconf --kill gpg-agent || true
  '';
}
