# Home Manager Integration

This guide explains how to integrate Home Manager with NixOS system configurations.

## Why Integrate?

While this repository has separate Home Manager configurations in `nix/`, you can also integrate Home Manager directly into your NixOS system configuration for:

- **Unified management**: Single `nixos-rebuild` command for both system and user config
- **Declarative users**: User environments defined alongside system config
- **Consistency**: Ensure system and user packages stay in sync

## Setup

### 1. Add Home Manager Input

Add to `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs";
  
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  
  # ... other inputs
};
```

### 2. Import Home Manager Module

In your host's `nixosConfigurations`:

```nix
nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    # System modules
    ./modules/common.nix
    ./hosts/my-host/configuration.nix
    
    # Home Manager module
    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        
        # Import existing home-manager config from nix/
        users.username = import ../nix/linux/home.nix;
        
        # Or define inline
        users.username = {
          home.stateVersion = "24.11";
          home.packages = with pkgs; [ firefox ];
          # ... more config
        };
      };
    }
  ];
};
```

### 3. Configure Per-User Settings

```nix
# In hosts/my-host/configuration.nix
home-manager.users.alice = { pkgs, ... }: {
  home.stateVersion = "24.11";
  
  programs.git = {
    enable = true;
    userName = "Alice";
    userEmail = "alice@example.com";
  };
  
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
    };
  };
};
```

## Patterns

### Pattern 1: Separate Files

Keep home configurations in separate files:

```nix
# hosts/my-host/home/alice.nix
{ pkgs, ... }: {
  home.stateVersion = "24.11";
  programs.git.enable = true;
  # ... rest of config
}

# In hosts/my-host/configuration.nix
home-manager.users.alice = import ./home/alice.nix;
```

### Pattern 2: Shared Home Modules

Create shared home-manager modules:

```nix
# modules/home/common.nix
{ pkgs, ... }: {
  programs.git.enable = true;
  programs.vim.enable = true;
  home.packages = with pkgs; [ htop wget curl ];
}

# In host configuration
home-manager.users.alice = {
  imports = [ ../../modules/home/common.nix ];
  home.stateVersion = "24.11";
  # Host-specific overrides
};
```

### Pattern 3: Reuse Existing Config

Reference the existing `nix/` folder:

```nix
home-manager.users.ren = { config, pkgs, ... }: {
  imports = [
    # Import from existing nix/ directory
    ../../nix/linux/home.nix
  ];
  
  # Override or extend as needed
  home.packages = with pkgs; [ additional-package ];
};
```

## Example: Full Integration

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.my-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/my-laptop/configuration.nix
        
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.alice = import ./hosts/my-laptop/home.nix;
        }
      ];
    };
  };
}
```

## Advantages & Disadvantages

### Advantages
- ✅ Single rebuild command
- ✅ Atomic updates (system + user)
- ✅ Better integration with system services
- ✅ Easier to maintain consistency

### Disadvantages
- ❌ Requires root for home changes
- ❌ Slower rebuilds (rebuilds everything)
- ❌ Less flexible for multi-user systems
- ❌ Can't test home changes without system rebuild

## Best Practices

1. **Keep home configs modular**: Use separate files and imports
2. **Share common settings**: Use modules for repeated config
3. **Version control together**: Keep system and home config in same repo
4. **Test separately first**: Develop home config standalone, then integrate
5. **Document user-specific config**: Note what's system vs user level

## Keeping Both Approaches

You can maintain both:
- Standalone home-manager in `nix/` for flexibility
- Integrated home-manager in `nixos/` for production

This gives you:
- Quick iterations with standalone home-manager
- Atomic deployments with integrated approach

## Migration Path

From standalone to integrated:

1. Add home-manager input to flake
2. Import home-manager module in host
3. Reference existing `nix/` configs
4. Test that everything works
5. Optionally remove standalone configs if not needed

## See Also

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS + Home Manager Guide](https://nixos.wiki/wiki/Home_Manager)
- Existing home-manager config: `../nix/`
