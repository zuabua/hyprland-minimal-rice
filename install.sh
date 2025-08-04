#!/bin/bash

# This installation script is only functional for arch intalls, as it uses pacman

# Ensure the script is running from the same directory as the packages.lst and yay.lst files
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PACKAGE_LIST="$SCRIPT_DIR/packages.lst"
YAY_LIST="$SCRIPT_DIR/yay.lst"
THEME_DIR="$SCRIPT_DIR/themes/minimal"

# Check if packages.lst exists
if [[ ! -f "$PACKAGE_LIST" ]]; then
    echo "Error: packages.lst not found in the same directory as the script."
    exit 1
fi

# Check if yay.lst exists
if [[ ! -f "$YAY_LIST" ]]; then
    echo "Warning: yay.lst not found. Proceeding without AUR package installations."
    YAY_LIST=""
fi

# Check if the themes/minimal folder exists
if [[ ! -d "$THEME_DIR" ]]; then
    echo "Error: The 'themes/minimal' directory does not exist."
    exit 1
fi

echo "updating pacman.."
sudo pacman -Syu

# Read the package list and install each package using pacman
echo "Installing packages from $PACKAGE_LIST..."

while IFS= read -r package; do
    # Skip empty lines and lines starting with '#' (comments)
    if [[ -n "$package" && ! "$package" =~ ^# ]]; then
        echo "Installing $package using pacman..."
        sudo pacman -S --noconfirm "$package"
    fi
done < "$PACKAGE_LIST"

# If yay.lst exists, install packages from yay.lst using yay
if [[ -n "$YAY_LIST" ]]; then
    echo "Installing packages from $YAY_LIST using yay..."

    # Ensure yay is installed, otherwise clone and build it
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed. Installing yay from AUR..."
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si
        cd ..
    fi

    # Read the yay.lst and install each package using yay
    while IFS= read -r package; do
        # Skip empty lines and lines starting with '#' (comments)
        if [[ -n "$package" && ! "$package" =~ ^# ]]; then
            echo "Installing $package using yay..."
            yay -S --noconfirm "$package"
        fi
    done < "$YAY_LIST"
fi


echo "Installing oh my zsh"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing powerlevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Handle the .gtkrc-2.0, .zshrc, p10k and .config files/folders
echo "Moving and replacing .gtkrc-2.0, .zshrc and .config from $THEME_DIR..."

# Move .gtkrc-2.0 (replace if it exists)
if [[ -f "$THEME_DIR/.gtkrc-2.0" ]]; then
    echo "Replacing .gtkrc in home directory..."
    cp -f "$THEME_DIR/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
else
    echo "No .gtkrc-2.0 found in $THEME_DIR to move."
fi

# Move .zshrc (replace if it exists)
if [[ -f "$THEME_DIR/.zshrc" ]]; then
    echo "Replacing .zshrc in home directory..."
    cp -f "$THEME_DIR/.zshrc" "$HOME/.zshrc"
else
    echo "No .zshrc found in $THEME_DIR to move."
fi

# Move powerlevel10k (replace if it exists)
if [[ -f "$THEME_DIR/.p10k.zsh" ]]; then
    echo "Replacing .zshrc in home directory..."
    cp -f "$THEME_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
else
    echo "No .p10k.zsh found in $THEME_DIR to move."
fi


if [[ -d "$THEME_DIR/.config" ]]; then
    echo "Checking .config directory in home directory..."

    # Loop through the files in the themes/minimal/.config directory
    for config_file in "$THEME_DIR/.config"/*; do
        # Get the filename from the path
        file_name=$(basename "$config_file")

        # Check if the file exists in the user's .config directory
        if [[ -f "$HOME/.config/$file_name" ]]; then
            echo "Replacing $file_name in .config..."
            cp -f "$config_file" "$HOME/.config/$file_name"
        else
            echo "Adding new $file_name to .config..."
            cp -r "$config_file" "$HOME/.config/"
        fi
    done
else
    echo "No .config directory found in $THEME_DIR to move."
fi

echo "Enabling bluetooth services..."
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

echo "Removing yay clone..."
rm -rf yay

echo "Installation and file replacement complete!"

