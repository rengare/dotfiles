gui=$1

if [ -d "$gui" ]; then
    bash $gui/theme.sh
fi
