# Secrets Management Guide

This guide explains how to manage secrets in NixOS configurations.

## The Problem

NixOS configurations are typically stored in Git and built in `/nix/store`, which is world-readable. This means you cannot include sensitive data like passwords, API keys, or private keys directly in your configuration files.

## Solutions

### 1. sops-nix (Recommended)

[sops-nix](https://github.com/Mic92/sops-nix) uses Mozilla's SOPS (Secrets OPerationS) to encrypt secrets.

**Setup:**

1. Add to `flake.nix`:
```nix
inputs.sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Import the module:
```nix
# In your host configuration
imports = [
  inputs.sops-nix.nixosModules.sops
];
```

3. Create a `.sops.yaml` file:
```yaml
keys:
  - &admin_key age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
    - age:
      - *admin_key
```

4. Store secrets:
```bash
# Create a secrets file
sops secrets/production.yaml

# Access in configuration
sops.secrets.database-password = {
  sopsFile = ./secrets/production.yaml;
};
```

5. Use in configuration:
```nix
services.postgresql = {
  enable = true;
  passwordFile = config.sops.secrets.database-password.path;
};
```

### 2. agenix

[agenix](https://github.com/ryantm/agenix) is a simpler alternative using age encryption.

**Setup:**

1. Add to `flake.nix`:
```nix
inputs.agenix.url = "github:ryantm/agenix";
```

2. Import and configure:
```nix
imports = [ inputs.agenix.nixosModules.default ];

age.secrets.secret1.file = ./secrets/secret1.age;
```

### 3. Simple File-Based (Quick & Dirty)

For non-critical secrets or development:

1. Keep secrets in a separate file outside the Nix store:
```nix
# /etc/nixos/secrets.nix (not in Git)
{
  apiKey = "secret-key-here";
  password = "password-here";
}
```

2. Import and use:
```nix
let
  secrets = import /etc/nixos/secrets.nix;
in {
  environment.variables.API_KEY = secrets.apiKey;
}
```

**⚠️ Warning:** This is less secure and harder to manage at scale.

## Best Practices

1. **Never commit secrets in plain text**
2. **Use age keys** stored securely (hardware keys, password manager)
3. **Rotate secrets regularly**
4. **Audit secret access** (who/what can access which secrets)
5. **Backup encryption keys** securely
6. **Test secret decryption** during deployment
7. **Use different secrets** for different environments (dev/staging/prod)

## Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [agenix Documentation](https://github.com/ryantm/agenix)
- [NixOS Wiki: Secrets](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
