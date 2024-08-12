{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = { url = "github:nix-community/nixGL"; };

    nix-colors = { url = "github:misterio77/nix-colors"; };

  };
  outputs = { nixgl, nixpkgs, home-manager, ... }@inputs:
    let
      version = "24.05";
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
      homeConfigurations.ren-darwin=
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-darwin";
            config.allowUnfree = allowUnfree;
            config.allowUnfreePredicate = allowUnfreePredicate;
          };
          extraSpecialArgs = {
            inherit inputs;
            username = username;
            home = darwin_home;
            allowUnfree = allowUnfree;
            allowUnfreePredicate = allowUnfreePredicate;
            version = version;
            path_to_dotfiles = "${darwin_home}${path_to_dotfiles}";
          };
          modules = [
            ./darwin/home.nix
          ];
        };
    };
}
