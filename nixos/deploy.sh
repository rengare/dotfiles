#!/usr/bin/env bash
# Deployment helper script for NixOS configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    switch <host>       Build and switch to configuration for <host>
    test <host>         Build and test configuration (doesn't make it default)
    build <host>        Build configuration without activating
    iso <host>          Build installer ISO for <host>
    check               Run all flake checks
    update              Update flake inputs
    fmt                 Format all nix files
    diff <host>         Show what would change with a rebuild
    list                List available hosts

Options:
    -h, --help          Show this help message

Examples:
    $0 switch lenovo-t14s-x1e
    $0 iso lenovo-t14s-x1e
    $0 check
EOF
}

log() {
    echo -e "${GREEN}==>${NC} $*"
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $*"
}

error() {
    echo -e "${RED}Error:${NC} $*" >&2
}

# List available hosts
list_hosts() {
    log "Available hosts:"
    nix eval --json "$FLAKE_DIR#nixosConfigurations" --apply builtins.attrNames 2>/dev/null | \
        jq -r '.[]' | grep -v '\-iso$' || echo "  lenovo-t14s-x1e"
}

# Check if running as root for system operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This command must be run as root (use sudo)"
        exit 1
    fi
}

case "${1:-}" in
    switch)
        check_root
        HOST="${2:-}"
        if [[ -z "$HOST" ]]; then
            error "Host not specified"
            print_usage
            exit 1
        fi
        log "Switching to configuration: $HOST"
        nixos-rebuild switch --flake "$FLAKE_DIR#$HOST"
        ;;
    
    test)
        check_root
        HOST="${2:-}"
        if [[ -z "$HOST" ]]; then
            error "Host not specified"
            print_usage
            exit 1
        fi
        log "Testing configuration: $HOST"
        nixos-rebuild test --flake "$FLAKE_DIR#$HOST"
        ;;
    
    build)
        HOST="${2:-}"
        if [[ -z "$HOST" ]]; then
            error "Host not specified"
            print_usage
            exit 1
        fi
        log "Building configuration: $HOST"
        nixos-rebuild build --flake "$FLAKE_DIR#$HOST"
        ;;
    
    iso)
        HOST="${2:-}"
        if [[ -z "$HOST" ]]; then
            error "Host not specified"
            print_usage
            exit 1
        fi
        log "Building ISO for: $HOST"
        SYSTEM=$(nix eval --raw "$FLAKE_DIR#nixosConfigurations.$HOST.config.nixpkgs.hostPlatform.system" 2>/dev/null || echo "aarch64-linux")
        nix build "$FLAKE_DIR#packages.$SYSTEM.${HOST}-iso"
        log "ISO built successfully!"
        log "Location: $(readlink -f result)/iso/*.iso"
        ;;
    
    check)
        log "Running flake checks..."
        nix flake check "$FLAKE_DIR"
        log "All checks passed!"
        ;;
    
    update)
        log "Updating flake inputs..."
        nix flake update "$FLAKE_DIR"
        log "Inputs updated!"
        ;;
    
    fmt)
        log "Formatting nix files..."
        nix fmt "$FLAKE_DIR"
        log "Formatting complete!"
        ;;
    
    diff)
        check_root
        HOST="${2:-}"
        if [[ -z "$HOST" ]]; then
            error "Host not specified"
            print_usage
            exit 1
        fi
        log "Showing diff for: $HOST"
        nixos-rebuild dry-activate --flake "$FLAKE_DIR#$HOST"
        ;;
    
    list)
        list_hosts
        ;;
    
    -h|--help)
        print_usage
        ;;
    
    *)
        error "Unknown command: ${1:-}"
        echo
        print_usage
        exit 1
        ;;
esac
