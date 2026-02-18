# NixOS Configuration for Lenovo ThinkPad T14s Gen 6 (X1E)

This directory contains NixOS configuration for the Lenovo ThinkPad T14s Gen 6 with Snapdragon X Elite (X1E) processor.

The configuration is based on the excellent work from [kuruczgy/x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config).

## Hardware Support Status

For the Lenovo ThinkPad T14s Gen 6:
- ✅ Battery Charging & Indicator
- ✅ Bluetooth
- ✅ Display
- ✅ GPU Acceleration
- ✅ Keyboard & Touchpad
- ✅ Lid Switch
- ✅ Microphone
- ✅ NVMe
- ✅ USB-A & USB-C DP Alt Mode
- ✅ Wi-Fi
- 🟨 Camera (sometimes upside-down, a bit green)
- 🟨 Speakers (⚠️ High volume can damage speakers - needs testing)
- 🟨 Suspend (spurious wakeups, ~3.8%/hour battery drain)
- ❌ Hardware Video Decoding (kernel module unstable, blacklisted)
- ❌ TPM
- ❔ Fingerprint Reader

**Important Note**: Only 31 GB of RAM works reliably on this device. The OLED version requires a different device tree.

## Prerequisites

- A Lenovo ThinkPad T14s Gen 6 with Snapdragon X Elite processor
- A USB drive (USB-A recommended, USB-C boot does not work on T14s)
- Optional: Windows installation (if dual-booting)
- A build system to compile the NixOS installer ISO

## Building the Minimal ISO

The installer ISO needs to be compiled from the kuruczgy repository. There are two main build options:

### Option 1: Cross-compile from x86_64 (Slow - Several Hours)

On any x86_64 Linux system with Nix installed:

```bash
# Clone the x1e-nixos-config repository
git clone https://github.com/kuruczgy/x1e-nixos-config.git
cd x1e-nixos-config

# Build the ISO for T14s specifically
nix build .#lenovo-thinkpad-t14s-iso --extra-experimental-features 'nix-command flakes'
```

The ISO will be available at `result/iso/nixos-x1e80100-lenovo-thinkpad-t14s.iso`.

### Option 2: Build using WSL on the Device (Fast - ~25 Minutes)

Building directly on the T14s using WSL is much faster since only the kernel needs to be compiled from scratch.

1. **Install WSL on Windows** (if not already installed):
   ```powershell
   wsl --install -d Ubuntu
   ```

2. **Install Nix in WSL**:
   ```bash
   # In WSL Ubuntu terminal
   sh <(curl -L https://nixos.org/nix/install) --daemon
   
   # Restart WSL or open a new terminal
   ```

3. **Modify the build system setting**:
   ```bash
   # Clone the repository
   git clone https://github.com/kuruczgy/x1e-nixos-config.git
   cd x1e-nixos-config
   
   # Edit flake.nix to change buildSystem from x86_64-linux to aarch64-linux
   # Find the line with buildSystem and change it accordingly
   sed -i 's/buildSystem = "x86_64-linux"/buildSystem = "aarch64-linux"/' flake.nix
   ```

4. **Build the ISO**:
   ```bash
   nix build .#lenovo-thinkpad-t14s-iso --extra-experimental-features 'nix-command flakes'
   ```

5. **Copy the ISO to a location accessible from Windows**:
   ```bash
   cp result/iso/nixos-x1e80100-lenovo-thinkpad-t14s.iso /mnt/c/Users/YourUsername/Downloads/
   ```

### Write ISO to USB Drive

From Linux:
```bash
dd if=nixos-x1e80100-lenovo-thinkpad-t14s.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

From Windows (use Rufus or similar tool, or from WSL):
```bash
# From WSL, replace /dev/sdX with your USB drive
sudo dd if=/mnt/c/Users/YourUsername/Downloads/nixos-x1e80100-lenovo-thinkpad-t14s.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

## Installation Guide

### Step 1: Prepare Windows (If Dual-Booting)

1. **Disable BitLocker** (recommended for dual-boot):
   - Search for "Device encryption settings" in Start Menu
   - Turn "Device encryption" off
   - Wait for decryption to complete

2. **Shrink Windows Partition**:
   - Search for "Create and format hard disk partitions" in Start Menu
   - Right-click on C: drive
   - Select "Shrink Volume"
   - Shrink by desired amount (e.g., 200 GB for NixOS)
   - Create a new partition in the free space (this will be formatted later)

### Step 2: Disable Secure Boot

1. Reboot and press **F2** during boot (when "LENOVO" or "ThinkPad" logo shows)
2. Navigate to **Security → Secure Boot**
3. Disable Secure Boot
4. Navigate to **Exit** → **Exit Saving Changes**
5. Optionally: Boot into Windows again to verify it still works

### Step 3: Boot from USB

1. Insert the USB drive with the NixOS installer
2. Reboot and press **F12** during boot
3. Select your USB drive from the boot menu
   - **Note**: Use USB-A port; USB-C booting doesn't work on T14s

### Step 4: Install NixOS

Once booted into the installer:

1. **Connect to Wi-Fi**:
   ```bash
   nmtui
   ```

2. **Enter root shell**:
   ```bash
   sudo -i
   ```

3. **Format the partition** (replace X with your partition number):
   ```bash
   # List partitions to find the one you created
   lsblk
   
   # Format it as ext4
   mkfs.ext4 -L root /dev/nvme0n1pX
   ```

4. **Mount filesystems**:
   ```bash
   # Mount root filesystem
   mount /dev/disk/by-label/root /mnt
   
   # Mount EFI partition (shared with Windows)
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/SYSTEM_DRV /mnt/boot
   ```

5. **Install NixOS using this configuration**:
   ```bash
   # If installing from this repository (recommended)
   nixos-install --root /mnt --no-channel-copy --no-root-password \
     --flake github:rengare/dotfiles?dir=nixos/lenovo-t14s-x1e#lenovo-t14s-x1e
   ```
   
   Or use the example configuration from x1e-nixos-config:
   ```bash
   nixos-install --root /mnt --no-channel-copy --no-root-password \
     --flake x1e-nixos-config#lenovo-thinkpad-t14s
   ```

### Step 5: Configure EFI Boot

After installation completes, you need to configure the EFI boot entries.

1. **Reboot into the USB installer again**
2. **Select "EFI Shell" from the boot menu**
   - The shell appears small in the bottom-right corner
   - Keyboard input is slow but usable

3. **Configure boot entry**:
   ```
   Shell> map -r -b
   ```
   Look for an `FS*` entry with path like `PcieRoot(*)/.../NVMe(...)/HD(0x1, ...)`
   This is usually `FS4` or similar. Use that in the following commands:
   
   ```
   Shell> FS4:
   FS4:\> ls EFI\systemd
   ```
   You should see `systemd-bootaa64.efi` listed.
   
   ```
   FS4:\> bcfg boot add 0 EFI\systemd\systemd-bootaa64.efi "NixOS"
   FS4:\> bcfg boot dump
   ```
   Verify "NixOS" appears in the boot list.
   
   ```
   FS4:\> reset
   ```

4. **Boot into NixOS**:
   - You should now see the systemd-boot menu
   - Select NixOS to boot

### Step 6: First Boot Configuration

1. **Log in**:
   - Username: `ren`
   - Password: `nixos`
   - ⚠️ **IMPORTANT**: This is a default password for initial setup only

2. **Change password immediately**:
   ```bash
   passwd
   ```
   **Security Note**: The configuration includes a default password and passwordless sudo for convenience during initial setup. These settings match the upstream x1e-nixos-config example but should be changed for production use. Consider:
   - Changing the password immediately
   - Editing `configuration.nix` to remove the default password
   - Setting `security.sudo.wheelNeedsPassword = true;` after initial setup

3. **Connect to Wi-Fi**:
   ```bash
   nmtui
   ```

4. **Start graphical environment** (optional):
   ```bash
   exec sway
   ```

## Customizing Your Configuration

To customize this configuration:

1. **Clone this repository**:
   ```bash
   git clone https://github.com/rengare/dotfiles.git
   cd dotfiles/nixos/lenovo-t14s-x1e
   ```

2. **Edit `configuration.nix`**:
   - Add packages to `environment.systemPackages`
   - Enable additional services
   - Configure user settings

3. **Apply changes**:
   ```bash
   sudo nixos-rebuild switch --flake .#lenovo-t14s-x1e
   ```

4. **Update system**:
   ```bash
   # Update flake inputs
   nix flake update
   
   # Apply updates
   sudo nixos-rebuild switch --flake .#lenovo-t14s-x1e
   ```

## Troubleshooting

### Random System Lockups

If you experience random lockups, try adding this to your configuration:

```nix
boot.kernelParams = [ "pcie_aspm=off" ];
```

This slightly increases power consumption but resolves SSD ASPM issues for some users.

### Low Memory Available

The T14s has a known issue where only 31 GB of RAM works reliably. This is already configured with:
```nix
boot.kernelParams = [ "mem=31G" ];
```

### Speaker Safety

⚠️ **IMPORTANT**: High volume levels can damage the speakers. Keep volume at moderate levels until further testing confirms safe limits.

## Known Issues

- Hardware video decoding is disabled (unstable kernel module)
- TPM is not supported
- USB-C booting doesn't work (use USB-A)
- Suspend has spurious wakeups and higher battery drain (~3.8%/hour)
- 33 GB of RAM (out of 64 GB total) are not accessible for stability

## Additional Resources

- [Original x1e-nixos-config repository](https://github.com/kuruczgy/x1e-nixos-config)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Ubuntu Concept for Snapdragon X Elite](https://discourse.ubuntu.com/t/ubuntu-24-10-concept-snapdragon-x-elite/48800)

## KVM/Virtualization Support

To enable KVM (requires EL2 privilege level), see the [x1e-nixos-config README](https://github.com/kuruczgy/x1e-nixos-config#running-virtual-machines-with-kvm) for instructions on using `slbounce`.

## License

This configuration inherits the license from the parent repository. The x1e-nixos-config it depends on is available under its own license terms.
