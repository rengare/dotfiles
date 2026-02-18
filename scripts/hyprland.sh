# Use dark mode for QT apps too (like kdenlive)
# sudo pacman -S --noconfirm kvantum-qt5
paru -S --noconfirm --needed \
  hyprland hyprshot hyprpicker hyprlock hypridle hyprpolkitagent hyprland-qtutils \
  wofi waybar mako swaybg nwg-display nwg-look \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# Prefer dark mode everything
sudo pacman -S --noconfirm gnome-themes-extra # Adds Adwaita-dark theme
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
