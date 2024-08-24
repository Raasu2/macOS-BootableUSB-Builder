#!/bin/bash

# Function to print error messages and exit
error() {
    echo "Error: $1" >&2
    cleanup
    exit 1
}

# Function to clean up temporary files and directories
cleanup() {
    echo "Cleaning up..."
    if [ -d ~/Desktop/Installer ]; then
        rm -rf ~/Desktop/Installer
    fi
    if [ -d /tmp/InstallerScript ]; then
        rm -rf /tmp/InstallerScript
    fi
    if [ -f /tmp/Installer.sparseimage ]; then
        rm -f /tmp/Installer.sparseimage
    fi
    if [ -f /tmp/Installer.dmg ]; then
        rm -f /tmp/Installer.dmg
    fi
    if [ -d /Volumes/"MacOS Boot USB" ]; then
        diskutil eject /Volumes/"MacOS Boot USB"
    fi
}

# Set up a trap to ensure cleanup runs on script exit
trap cleanup EXIT

# Ask for the path to the InstallMacOSX.pkg
read -p "Enter the path to InstallMacOSX.pkg: " PKG_PATH
if [[ ! -f "$PKG_PATH" ]]; then
    error "InstallMacOSX.pkg file not found at $PKG_PATH."
fi

# Ask for the USB volume name
read -p "Enter the volume name of your USB drive (e.g., KEY): " USB_VOLUME

# Find the disk identifier based on the volume name
USB_DISK=$(diskutil info /Volumes/"$USB_VOLUME" | grep "Device Identifier" | awk '{print $3}' | sed 's/s[0-9]*$//')
if [[ -z "$USB_DISK" ]]; then
    error "Could not find the USB drive with volume name $USB_VOLUME."
fi

# Display information about the disk and its partitions
echo "Disk information:"
diskutil info $USB_DISK

# Confirm the disk identifier with the user
echo "Found disk identifier: $USB_DISK"
read -p "Is this correct? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    error "Aborting due to incorrect disk identifier."
fi

# Create directories for temporary files
mkdir -p ~/Desktop/Installer
TMP_DIR=/tmp/InstallerScript
mkdir -p $TMP_DIR

# Expand the InstallMacOSX.pkg
echo "Expanding InstallMacOSX.pkg..."
pkgutil --expand "$PKG_PATH" "$TMP_DIR/Installer" || error "Failed to expand InstallMacOSX.pkg."

# Extract Payload from the expanded package
echo "Extracting Payload..."
cd "$TMP_DIR/Installer/InstallMacOSX.pkg" || error "Failed to change directory."
tar -xvf Payload || error "Failed to extract Payload."

# Move InstallESD.dmg to Desktop
mv InstallESD.dmg ~/Desktop || error "Failed to move InstallESD.dmg to Desktop."

# Format the USB drive with the new name
echo "Formatting the USB drive with name 'MacOS Boot USB'..."
diskutil eraseDisk HFS+ "MacOS Boot USB" GPT $USB_DISK || error "Failed to format USB drive."

# Attach InstallESD.dmg
echo "Attaching InstallESD.dmg..."
hdiutil attach ~/Desktop/InstallESD.dmg -noverify -nobrowse -mountpoint /Volumes/install_app || error "Failed to attach InstallESD.dmg."

# Create and prepare the sparse image
echo "Creating and preparing sparse image..."
# Remove any existing sparse image file
if [ -f /tmp/Installer.sparseimage ]; then
    rm -f /tmp/Installer.sparseimage
fi
hdiutil convert /Volumes/install_app/BaseSystem.dmg -format UDSP -o /tmp/Installer || error "Failed to convert BaseSystem.dmg."
hdiutil resize -size 8g /tmp/Installer.sparseimage || error "Failed to resize sparse image."
hdiutil attach /tmp/Installer.sparseimage -noverify -nobrowse -mountpoint /Volumes/install_build || error "Failed to attach sparse image."

# Copy files to the USB drive
echo "Copying files to the USB drive..."
rm -rf /Volumes/install_build/System/Installation/Packages || error "Failed to remove existing Packages directory."
cp -av /Volumes/install_app/Packages /Volumes/install_build/System/Installation/ || error "Failed to copy Packages directory."
cp -av /Volumes/install_app/BaseSystem.chunklist /Volumes/install_build/ || error "Failed to copy BaseSystem.chunklist."
cp -av /Volumes/install_app/BaseSystem.dmg /Volumes/install_build/ || error "Failed to copy BaseSystem.dmg."

# Detach volumes
echo "Detaching volumes..."
hdiutil detach /Volumes/install_app || error "Failed to detach install_app volume."
hdiutil detach /Volumes/install_build || error "Failed to detach install_build volume."

# Finalize the sparse image
echo "Finalizing the sparse image..."
# Remove any existing final DMG file
if [ -f /tmp/Installer.dmg ]; then
    rm -f /tmp/Installer.dmg
fi
hdiutil resize -size `hdiutil resize -limits /tmp/Installer.sparseimage | tail -n 1 | awk '{print $ 1}'`b /tmp/Installer.sparseimage || error "Failed to finalize sparse image."
hdiutil convert /tmp/Installer.sparseimage -format UDZO -o /tmp/Installer.dmg || error "Failed to convert sparse image to DMG."
mv /tmp/Installer.dmg ~/Desktop || error "Failed to move Installer.dmg to Desktop."

# Restore the image to the USB drive
echo "Restoring image to USB drive..."
sudo asr restore --source ~/Desktop/Installer.dmg --target /Volumes/"MacOS Boot USB" --noprompt --noverify --erase || error "Failed to restore image to USB drive."

# Cleanup is already handled by trap on script exit
