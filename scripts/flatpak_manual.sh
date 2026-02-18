#!/bin/bash

# File with list of Flatpak apps
APP_LIST_FILE="./system_files/etc/ublue-os/system_flatpaks"

# Ensure Flathub is added as user remote
if ! flatpak remotes --user | grep -q flathub; then
  echo "Adding Flathub remote for user..."
  flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
else
  echo "Flathub remote already exists for user."
fi

# Check if the file exists
if [[ ! -f "$APP_LIST_FILE" ]]; then
  echo "Error: File '$APP_LIST_FILE' not found."
  exit 1
fi

# Read the file line by line and install each app
while IFS= read -r app_id; do
  # Skip empty lines and comments
  [[ -z "$app_id" || "$app_id" =~ ^# ]] && continue

  echo "Installing $app_id..."
  flatpak install --user -y "$app_id"
done <"$APP_LIST_FILE"

echo "All Flatpak apps processed."
