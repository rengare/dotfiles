{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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
        pkgs = import nixpkgs {
          system = "x86_64-linux";
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
        modules = [ ./shared.nix ./linux/home.nix ];
      };
      homeConfigurations.ren-darwin =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.home = darwin_home;
            config.allowUnfree = allowUnfree;
            config.allowUnfreePredicate = allowUnfreePredicate;
            config.username = username;
          };

          extraSpecialArgs = {
            version = version;
            path_to_dotfiles = "${darwin_home}${path_to_dotfiles}";
          };
          modules = [ ./shared.nix ];
        };
    };
}