{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = { url = "github:guibou/nixgl"; };

    nix-colors = { url = "github:misterio77/nix-colors"; };

  };
  outputs = { nixgl, nixpkgs, home-manager, ... }@inputs:
    let
      version = "23.11";
      username = "ren";
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
      linux_home = "/home/${username}";
      darwin_home = "/Users/${username}";
      path_to_dotfiles = "/workspace/dotfiles";
    in
    {
      homeConfigurations.ren-linux = home-manager.lib.homeManagerConfiguration {

        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = allowUnfree;
          config.allowUnfreePredicate = allowUnfreePredicate;
          overlays = [ nixgl.overlay ];
        };

        extraSpecialArgs = {
          inherit inputs;
          username = username;
          home = linux_home;
          allowUnfree = allowUnfree;
          allowUnfreePredicate = allowUnfreePredicate;
          version = version;
          path_to_dotfiles = "${linux_home}${path_to_dotfiles}";
        };

        modules = [
          ./linux/home.nix
        ];
      };
      homeConfigurations.ren-linux-arm =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = allowUnfree;
            config.allowUnfreePredicate = allowUnfreePredicate;
            overlays = [ nixgl.overlay ];
          };

          extraSpecialArgs = {
            username = username;
            home = linux_home;
            version = version;
            path_to_dotfiles = "${linux_home}${path_to_dotfiles}";
          };
          modules = [
            ./shared.nix
            ./linux/link.nix
          ];

        };
      homeConfigurations.ren-darwin =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = allowUnfree;
            config.allowBroken = true;
            config.allowUnfreePredicate = allowUnfreePredicate;
          };

          extraSpecialArgs = {
            username = username;
            home = darwin_home;
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
