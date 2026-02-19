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
    let
      # Helper function to create a NixOS system configuration
      mkSystem = { system, modules, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit hostname; };
        };
    in
    {
      # NixOS configurations for each host
      nixosConfigurations = {
        # Lenovo ThinkPad T14s Gen 6 (Snapdragon X Elite)
        lenovo-t14s-x1e = mkSystem {
          system = "aarch64-linux";
          hostname = "lenovo-t14s-x1e";
          modules = [
            # Common configuration
            ./modules/common.nix
            
            # Hardware-specific module
            x1e-nixos-config.nixosModules.x1e
            
            # Host-specific configuration
            {
              networking.hostName = "lenovo-t14s-x1e";
              hardware.lenovo-thinkpad-t14s.enable = true;
              nixpkgs.hostPlatform.system = "aarch64-linux";
              nixpkgs.config.allowUnfree = true;
            }
            ./hosts/lenovo-t14s-x1e/configuration.nix
          ];
        };

        # Add more host configurations here
        # example-host = mkSystem {
        #   system = "x86_64-linux";
        #   hostname = "example-host";
        #   modules = [
        #     ./modules/common.nix
        #     ./hosts/example-host/configuration.nix
        #   ];
        # };
      };

      # Formatter for nix files (optional - requires nixpkgs-fmt or nixfmt)
      # formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      # formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
    };
}
