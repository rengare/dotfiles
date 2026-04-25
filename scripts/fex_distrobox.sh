rm ~/.steampid
rm ~/.steampath
rm -rf ~/.steam
rm -rf ~/.local/share/Steam
rm -rf ~/.config/.fex-emu
rm -rf ~/.local/share/.fex-emu
rm -rf ~/.fex-emu

distrobox create \
  --name fex-steam \
  --image ubuntu:24.04 \
  --root \
  --init \
  --additional-packages "systemd libpam-systemd"

#inside container
#sudo apt update
#sudo apt install -y python3-packaging python3-setuptools
#sudo systemctl unmask systemd-binfmt
#curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py | python3
#wget https://repo.steampowered.com/steam/archive/stable/steam-launcher_latest_all.deb
