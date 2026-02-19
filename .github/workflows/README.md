# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the dotfiles repository.

## Available Workflows

### build-iso.yml

Builds the NixOS installer ISO for the Lenovo ThinkPad T14s Gen 6 (Snapdragon X Elite).

**Triggers:**
- **Manual**: Use "Run workflow" button in GitHub Actions tab
- **Automatic**: On push to main/master branch when nixos/ files change
- **Releases**: Automatically attaches ISO to GitHub releases

**What it does:**
1. Sets up Nix with flakes support
2. Configures QEMU for ARM64 cross-compilation
3. Builds the ISO for aarch64-linux architecture
4. Uploads ISO as GitHub Actions artifact (30 day retention)
5. Optionally uploads to GitHub releases
6. Posts build summary and status

**Usage:**

1. **Manual build**: Go to Actions → Build T14s X1E ISO → Run workflow

2. **Download ISO**: 
   - Go to completed workflow run
   - Click on "Artifacts" section
   - Download `lenovo-t14s-x1e-installer-<commit-sha>`

3. **From release**: ISOs are automatically attached to GitHub releases

**Requirements:**

Optional secrets (for optimization):
- `CACHIX_CACHE_NAME`: Your Cachix cache name
- `CACHIX_AUTH_TOKEN`: Cachix authentication token

**Build time**: ~30-60 minutes (depending on cache hits)

**Disk usage**: ~10-15 GB

## Local Testing

You can test the ISO build locally:

```bash
cd nixos
nix build .#packages.aarch64-linux.lenovo-t14s-x1e-iso
```

Or use the deploy script:

```bash
./deploy.sh iso lenovo-t14s-x1e
```

## Troubleshooting

### Build fails with "out of disk space"

The free disk space step should handle this, but if it still fails:
- The ISO build requires significant disk space
- Consider building less frequently or using Cachix

### Cross-compilation is slow

ARM64 builds on x86_64 runners use QEMU emulation, which is slower than native builds.
Using Cachix can significantly speed up builds by caching packages.

### CACHIX secrets not configured

The Cachix step will be skipped if secrets are not configured. The workflow will still work,
but builds will be slower without caching.

## Adding More Workflows

To add additional checks or builds:

1. See the template: `nixos/docs/github-actions-template.yml`
2. Create new workflow file in `.github/workflows/`
3. Configure triggers and jobs as needed

## See Also

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cachix Documentation](https://docs.cachix.org/)
- [NixOS CI Guide](../nixos/docs/github-actions-template.yml)
