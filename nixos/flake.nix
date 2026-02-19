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
      
      # Helper function to create an installer ISO for a host
      mkISO = { system, modules, hostname }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = modules ++ [
            # Base minimal installation ISO
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            
            # ISO-specific configuration
            ./modules/iso.nix
            
            # Set hostname for the ISO
            { networking.hostName = "${hostname}-installer"; }
          ];
          specialArgs = { inherit hostname; };
        };
      
      # Systems we support for building
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Generate packages for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
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
        
        # ISO for Lenovo ThinkPad T14s Gen 6
        lenovo-t14s-x1e-iso = mkISO {
          system = "aarch64-linux";
          hostname = "lenovo-t14s-x1e";
          modules = [
            # Hardware-specific module for the ISO
            x1e-nixos-config.nixosModules.x1e
            
            {
              hardware.lenovo-thinkpad-t14s.enable = true;
              nixpkgs.hostPlatform.system = "aarch64-linux";
              nixpkgs.config.allowUnfree = true;
            }
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
        
        # And corresponding ISOs:
        # example-host-iso = mkISO {
        #   system = "x86_64-linux";
        #   hostname = "example-host";
        #   modules = [
        #     # Any hardware-specific modules needed for the ISO
        #   ];
        # };
      };
      
      # Packages output for building ISOs
      packages = forAllSystems (system: {
        # ISO image for T14s X1E
        lenovo-t14s-x1e-iso = self.nixosConfigurations.lenovo-t14s-x1e-iso.config.system.build.isoImage;
        
        # Add more ISO packages here as you add more hosts
        # example-host-iso = self.nixosConfigurations.example-host-iso.config.system.build.isoImage;
      });

      # Formatter for nix files
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
      
      # Checks for CI/CD
      checks = forAllSystems (system: {
        # Check that all configurations evaluate
        all-systems-build = nixpkgs.legacyPackages.${system}.runCommand "check-all-systems" {} ''
          echo "Checking all NixOS configurations..."
          echo "lenovo-t14s-x1e: ${self.nixosConfigurations.lenovo-t14s-x1e.config.system.name}"
          echo "All systems check passed!" > $out
        '';
      });
      
      # Development shell
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with nixpkgs.legacyPackages.${system}; [
            nixpkgs-fmt
            nil  # Nix language server
          ];
          shellHook = ''
            echo "NixOS configuration development environment"
            echo "Available commands:"
            echo "  nix fmt          - Format all nix files"
            echo "  nix flake check  - Run all checks"
            echo "  nix build .#packages.${system}.lenovo-t14s-x1e-iso - Build ISO"
          '';
        };
      });
    };
}
