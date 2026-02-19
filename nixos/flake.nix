{
  description = "NixOS configurations for various hosts";

  inputs = {
    # Unstable nixpkgs, required for now
    nixpkgs.url = "github:nixos/nixpkgs";

    # X1E NixOS configuration repository for Snapdragon X Elite hardware support
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
      # NixOS configurations for each host
      nixosConfigurations = {
        # Lenovo ThinkPad T14s Gen 6 (Snapdragon X Elite)
        lenovo-t14s-x1e = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            x1e-nixos-config.nixosModules.x1e
            {
              networking.hostName = "lenovo-t14s-x1e";
              hardware.lenovo-thinkpad-t14s.enable = true;
              nixpkgs.hostPlatform.system = "aarch64-linux";
              nixpkgs.config.allowUnfree = true;
              
              nix = {
                channel.enable = false;
                settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
              };
            }
            ./hosts/lenovo-t14s-x1e/configuration.nix
          ];
        };

        # Add more host configurations here
        # example-host = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./hosts/example-host/configuration.nix
        #   ];
        # };
      };
    };
}
