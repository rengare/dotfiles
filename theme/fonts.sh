mkdir ~/.local/share/themes 2>/dev/null
mkdir ~/.themes 2>/dev/null
mkdir ~/.local/share/fonts 2>/dev/null
mkdir ~/.local/share/icons 2>/dev/null

cp -rf ./jetbrains/* ~/.local/share/fonts/

fc-cache ~/.local/share/fonts
