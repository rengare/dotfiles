git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd ..

bash ./brew.sh
bash ./cli.sh
bash ./hyprland.sh
bash ./dotfiles.sh
bash ./rustlang.sh
bash ./flatpak_manual.sh
bash ./omf.sh
