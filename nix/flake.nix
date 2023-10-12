{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = { url = "github:guibou/nixgl"; };
  };
  outputs = { nixgl, nixpkgs, home-manager, ... }:
    let
      version = "23.05";
      username = "ren";
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      linux_home = "/home/${username}";
      darwin_home = "/Users/${username}";
      path_to_dotfiles = "/workspace/dotfiles";
    in {
      homeConfigurations.ren-linux = home-manager.lib.homeManagerConfiguration {
        
	pkgs = nixpkgs.legacyPackages.x86_64-linux ;
	
        extraSpecialArgs = {
	  username = username;
          version = version;
	  home = linux_home;
	  nixgl = nixgl;
          path_to_dotfiles = "${linux_home}${path_to_dotfiles}";
        };

        modules = [
          ./linux/home.nix
          ./shared.nix
          ./dev.nix
          ./linux/link.nix
          #./linux/dev.nix
          #./linux/gui.nix
        ];
      };
      homeConfigurations.ren-linux-arm =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.home = linux_home;
            config.allowUnfree = allowUnfree;
            config.allowUnfreePredicate = allowUnfreePredicate;
            config.username = username;
            overlays = [ nixgl.overlay ];
          };

          extraSpecialArgs = {
            version = version;
            path_to_dotfiles = "${linux_home}${path_to_dotfiles}";
          };
          modules = [
            ./shared.nix
            # ./dev.nix
            ./linux/link.nix
            # ./linux/gaming.nix
            # ./linux/sway.nix
            # ./linux/home.nix
            # ./linux/gui.nix
          ];

        };
      homeConfigurations.ren-darwin =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.home = darwin_home;
            config.allowUnfree = allowUnfree;
            config.allowBroken = true;
            config.allowUnfreePredicate = allowUnfreePredicate;
            config.username = username;
          };

          extraSpecialArgs = {
            version = version;
            path_to_dotfiles = "${darwin_home}${path_to_dotfiles}";
          };
          modules = [

            ./shared.nix
            ./darwin/home.nix
            ./darwin/gaming.nix
          ];
        };
    };
}
