# Changelog

All notable changes to the NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Developer tooling: formatter, checks, and dev shells
- Deployment helper script (deploy.sh) for common operations
- Declarative user management module (modules/users.nix)
- Example x86_64 host template (hosts/example-x86/)
- Quick reference guide (QUICKREF.md)
- ISO builder for all hosts
- Common configuration module with shared settings
- Comprehensive documentation (README, CONTRIBUTING, QUICKREF)
- .envrc for direnv integration
- Overlays module for custom packages
- Secrets management documentation

### Changed
- Restructured to hosts-based organization
- Enhanced flake.nix with helper functions (mkSystem, mkISO)
- Updated all documentation with cross-references

### Fixed
- System architecture properly set for ARM64 hosts
- Security warnings properly documented

## Initial Release

### Added
- Basic NixOS configuration for Lenovo ThinkPad T14s X1E
- Integration with kuruczgy/x1e-nixos-config for hardware support
- Module-based configuration structure
