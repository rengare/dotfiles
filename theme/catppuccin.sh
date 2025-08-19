mkdir ~/.local/share/themes 2>/dev/null
mkdir ~/.themes 2>/dev/null
mkdir ~/.local/share/fonts 2>/dev/null
mkdir ~/.local/share/icons 2>/dev/null
# theme=Yaru-Lavender-dark

# cp -rf ./catppuccin/* $HOME/.themes/
# cp -rf ./yaru/* ~/.local/share/icons/
cp -rf ./jetbrains/* ~/.local/share/fonts/

fc-cache ~/.local/share/fonts

# flatpak --user override --filesystem=$HOME/.themes
# flatpak override --env=GTK_THEME=$theme --user
# flatpak override --env=GTK_STYLE_OVERRIDE=$theme --user

# sudo flatpak override --filesystem=$HOME/.themes
# sudo flatpak override --env=GTK_THEME=$theme
# sudo flatpak override --env=GTK_STYLE_OVERRIDE=$theme
