systemctl --user enable --now podman.socket
distrobox create -n arch -i ghcr.io/ublue-os/bazzite-arch:latest --init-hooks "install -o 1000 -g 1000 -d /tmp/.X11-unix-new; mount --bind /tmp/.X11-unix-new /tmp/.X11-unix"

RUSTICL_ENABLE=radeonsi

#distrobox create --name arch --image docker.io/ogarcia/archlinux:latest

#distrobox create --image ubuntu:24.04 --root --init --additional-packages "ubuntu-desktop
