{
  inputs = {
    # Unstable nixpkgs, required for now.
    nixpkgs.url = "github:nixos/nixpkgs";

    # X1E NixOS configuration repository
    x1e-nixos-config.url = "github:kuruczgy/x1e-nixos-config";
    x1e-nixos-config.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      x1e-nixos-config,
    }:
    {
      # NixOS configuration for Lenovo ThinkPad T14s Gen 6 (X1E)
      nixosConfigurations.lenovo-t14s-x1e = nixpkgs.lib.nixosSystem {
        modules = [
          x1e-nixos-config.nixosModules.x1e
          {
            networking.hostName = "lenovo-t14s-x1e";
            hardware.lenovo-thinkpad-t14s.enable = true;

            nixpkgs.hostPlatform.system = "aarch64-linux";

            # Allow unfree packages.
            nixpkgs.config.allowUnfree = true;

            nix = {
              channel.enable = false;
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
            };
          }
          ./configuration.nix
        ];
      };
    };
}
