#!/bin/bash

TMP_DIR=""
INSTALL_APP_MOUNT=""
INSTALL_BUILD_MOUNT=""
SPARSE_IMAGE=""
FINAL_DMG=""
FORMATTED_USB=0
FINAL_USB_NAME="MacOS Boot USB"

normalize_input() {
    local value=$1
    value=${value#\"}
    value=${value%\"}
    value=${value#\'}
    value=${value%\'}
    value=${value//\\ / }
    value=${value//\\(/(}
    value=${value//\\)/)}
    value=${value//\\&/&}
    printf '%s' "$value"
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Required command not found: $1"
    fi
}

# Function to print error messages and exit
error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to clean up temporary files and directories
cleanup() {
    echo "Cleaning up..."
    if [ -n "$INSTALL_APP_MOUNT" ] && [ -d "$INSTALL_APP_MOUNT" ]; then
        hdiutil detach "$INSTALL_APP_MOUNT" >/dev/null 2>&1 || true
    fi
    if [ -n "$INSTALL_BUILD_MOUNT" ] && [ -d "$INSTALL_BUILD_MOUNT" ]; then
        hdiutil detach "$INSTALL_BUILD_MOUNT" >/dev/null 2>&1 || true
    fi
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
    if [ "$FORMATTED_USB" -eq 1 ] && [ -d "/Volumes/$FINAL_USB_NAME" ]; then
        diskutil eject "/Volumes/$FINAL_USB_NAME"
    fi
}

# Set up a trap to ensure cleanup runs on script exit
trap cleanup EXIT

require_command awk
require_command asr
require_command diskutil
require_command grep
require_command hdiutil
require_command pkgutil
require_command sed
require_command sudo
require_command tar

# Ask for the path to the macOS installer package
read -r -p "Enter the path to the Apple macOS installer .pkg file: " PKG_PATH
PKG_PATH=$(normalize_input "$PKG_PATH")
if [[ "$PKG_PATH" == ~/* ]]; then
    PKG_PATH="$HOME/${PKG_PATH#~/}"
fi
if [[ ! -f "$PKG_PATH" ]]; then
    error "Installer package file not found at $PKG_PATH."
fi

# Ask for the USB volume name
read -r -p "Enter the current mounted USB volume name, exactly as shown in Finder (or /Volumes/Name): " USB_VOLUME
USB_VOLUME=$(normalize_input "$USB_VOLUME")
USB_VOLUME=${USB_VOLUME%/}
USB_VOLUME=${USB_VOLUME#/Volumes/}

if [[ -z "$USB_VOLUME" ]]; then
    error "USB volume name cannot be empty."
fi

if [[ "$USB_VOLUME" =~ ^disk[0-9]+s?[0-9]*$ ]]; then
    error "Enter the mounted USB volume name, not a disk identifier like $USB_VOLUME."
fi

read -r -p "Enter the final USB name after formatting [MacOS Boot USB]: " FINAL_USB_NAME_INPUT
FINAL_USB_NAME_INPUT=$(normalize_input "$FINAL_USB_NAME_INPUT")
if [[ -n "$FINAL_USB_NAME_INPUT" ]]; then
    FINAL_USB_NAME="$FINAL_USB_NAME_INPUT"
fi

if [[ "$FINAL_USB_NAME" == */* ]]; then
    error "Final USB name cannot contain '/'."
fi

if [[ -z "$FINAL_USB_NAME" ]]; then
    error "Final USB name cannot be empty."
fi

# Find the disk identifier based on the volume name
USB_DISK=$(diskutil info /Volumes/"$USB_VOLUME" | grep "Device Identifier" | awk '{print $3}' | sed 's/s[0-9]*$//')
if [[ -z "$USB_DISK" ]]; then
    error "Could not find the USB drive with volume name $USB_VOLUME."
fi

# Display information about the disk and its partitions
echo "Disk information:"
diskutil info "$USB_DISK"

# Show the resolved disk before preparing the installer image
echo "Found USB volume: $USB_VOLUME"
echo "Found physical disk: $USB_DISK"
echo "Final USB name: $FINAL_USB_NAME"
echo "The installer image will be prepared first. The USB will not be erased until final confirmation."

# Create directories for temporary files
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/bootable-installer.XXXXXX") || error "Failed to create temporary directory."
INSTALL_APP_MOUNT="$TMP_DIR/install_app"
INSTALL_BUILD_MOUNT="$TMP_DIR/install_build"
SPARSE_IMAGE="$TMP_DIR/Installer.sparseimage"
FINAL_DMG="$TMP_DIR/Installer.dmg"
INSTALL_ESD="$TMP_DIR/InstallESD.dmg"
mkdir -p "$INSTALL_APP_MOUNT" "$INSTALL_BUILD_MOUNT"

# Expand the installer package
echo "Expanding installer package..."
pkgutil --expand "$PKG_PATH" "$TMP_DIR/Installer" || error "Failed to expand installer package."

EXPANDED_PKG_DIR=""
if [ -f "$TMP_DIR/Installer/InstallMacOSX.pkg/Payload" ]; then
    EXPANDED_PKG_DIR="$TMP_DIR/Installer/InstallMacOSX.pkg"
else
    shopt -s nullglob
    for candidate in "$TMP_DIR"/Installer/*.pkg; do
        if [ -f "$candidate/Payload" ]; then
            EXPANDED_PKG_DIR="$candidate"
            break
        fi
    done
    shopt -u nullglob
fi

if [ -z "$EXPANDED_PKG_DIR" ]; then
    error "Expanded package does not contain the expected legacy installer Payload."
fi

# Extract Payload from the expanded package
echo "Extracting Payload..."
cd "$EXPANDED_PKG_DIR" || error "Failed to change directory."
tar -xvf Payload || error "Failed to extract Payload."

if [ ! -f InstallESD.dmg ]; then
    error "Payload did not contain InstallESD.dmg. This script only supports legacy Apple installer packages with InstallESD.dmg."
fi

# Move InstallESD.dmg into this run's temporary directory
mv InstallESD.dmg "$INSTALL_ESD" || error "Failed to move InstallESD.dmg."

# Attach InstallESD.dmg
echo "Attaching InstallESD.dmg..."
hdiutil attach "$INSTALL_ESD" -noverify -nobrowse -mountpoint "$INSTALL_APP_MOUNT" || error "Failed to attach InstallESD.dmg."

if [ ! -f "$INSTALL_APP_MOUNT/BaseSystem.dmg" ] || [ ! -f "$INSTALL_APP_MOUNT/BaseSystem.chunklist" ] || [ ! -d "$INSTALL_APP_MOUNT/Packages" ]; then
    error "InstallESD.dmg does not contain the expected BaseSystem.dmg, BaseSystem.chunklist, and Packages files."
fi

# Create and prepare the sparse image
echo "Creating and preparing sparse image..."
hdiutil convert "$INSTALL_APP_MOUNT/BaseSystem.dmg" -format UDSP -o "$TMP_DIR/Installer" || error "Failed to convert BaseSystem.dmg."
hdiutil resize -size 8g "$SPARSE_IMAGE" || error "Failed to resize sparse image."
hdiutil attach "$SPARSE_IMAGE" -noverify -nobrowse -mountpoint "$INSTALL_BUILD_MOUNT" || error "Failed to attach sparse image."

# Copy files to the USB drive
echo "Copying files to the USB drive..."
rm -rf "$INSTALL_BUILD_MOUNT/System/Installation/Packages" || error "Failed to remove existing Packages directory."
cp -av "$INSTALL_APP_MOUNT/Packages" "$INSTALL_BUILD_MOUNT/System/Installation/" || error "Failed to copy Packages directory."
cp -av "$INSTALL_APP_MOUNT/BaseSystem.chunklist" "$INSTALL_BUILD_MOUNT/" || error "Failed to copy BaseSystem.chunklist."
cp -av "$INSTALL_APP_MOUNT/BaseSystem.dmg" "$INSTALL_BUILD_MOUNT/" || error "Failed to copy BaseSystem.dmg."

# Detach volumes
echo "Detaching volumes..."
hdiutil detach "$INSTALL_APP_MOUNT" || error "Failed to detach install_app volume."
INSTALL_APP_MOUNT=""
hdiutil detach "$INSTALL_BUILD_MOUNT" || error "Failed to detach install_build volume."
INSTALL_BUILD_MOUNT=""

# Finalize the sparse image
echo "Finalizing the sparse image..."
MIN_SIZE=$(hdiutil resize -limits "$SPARSE_IMAGE" | awk 'END {print $1}') || error "Failed to calculate final image size."
hdiutil resize -size "${MIN_SIZE}b" "$SPARSE_IMAGE" || error "Failed to finalize sparse image."
hdiutil convert "$SPARSE_IMAGE" -format UDZO -o "$FINAL_DMG" || error "Failed to convert sparse image to DMG."

# Confirm the destructive operation with the user after the installer image is ready
echo "Installer image is ready."
CURRENT_USB_DISK=$(diskutil info /Volumes/"$USB_VOLUME" | grep "Device Identifier" | awk '{print $3}' | sed 's/s[0-9]*$//')
if [[ "$CURRENT_USB_DISK" != "$USB_DISK" ]]; then
    error "USB volume $USB_VOLUME no longer maps to $USB_DISK. The USB was not erased."
fi

echo "WARNING: This will now erase the entire physical disk $USB_DISK, including every partition on that disk."
echo "Target USB volume: $USB_VOLUME"
echo "Final USB name: $FINAL_USB_NAME"
read -r -p "Type ERASE to format the USB and restore the installer: " CONFIRM
if [[ "$CONFIRM" != "ERASE" ]]; then
    error "Aborting because ERASE was not typed. The USB was not erased."
fi

# Format the USB drive with the new name
echo "Formatting the USB drive with name '$FINAL_USB_NAME'..."
diskutil eraseDisk HFS+ "$FINAL_USB_NAME" GPT "$USB_DISK" || error "Failed to format USB drive."
FORMATTED_USB=1

# Restore the image to the USB drive
echo "Restoring image to USB drive..."
sudo asr restore --source "$FINAL_DMG" --target "/Volumes/$FINAL_USB_NAME" --noprompt --noverify --erase || error "Failed to restore image to USB drive."

# Cleanup is already handled by trap on script exit
