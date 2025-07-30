#!/bin/bash

# Ensure the script is running from the same directory as the packages.lst file
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PACKAGE_LIST="$SCRIPT_DIR/packages.lst"

# Check if packages.lst exists
if [[ ! -f "$PACKAGE_LIST" ]]; then
    echo "Error: packages.lst not found in the same directory as the script."
    exit 1
fi

# Read the package list and install each package using pacman
echo "Installing packages from $PACKAGE_LIST..."

while IFS= read -r package; do
    # Skip empty lines and lines starting with '#' (comments)
    if [[ -n "$package" && ! "$package" =~ ^# ]]; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    fi
done < "$PACKAGE_LIST"

echo "Installation complete!"

