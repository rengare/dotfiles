rm ~/.steampid
rm ~/.steampath
rm -rf ~/.steam
rm -rf ~/.local/share/Steam
rm -rf ~/.config/.fex-emu
rm -rf ~/.local/share/.fex-emu
rm -rf ~/.fex-emu

distrobox create --image ubuntu:24.04 --root --init --additional-packages "ubuntu-desktop"

#inside container
#sudo systemctl unmask systemd-binfmt
#curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py | python3
