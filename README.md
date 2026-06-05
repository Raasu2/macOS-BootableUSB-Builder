# Create bootable legacy macOS USB installers from InstallMacOSX.pkg

## What this is

If you’re using a **new Apple Silicon Mac (M1 / M2 / M3)** and need to install macOS on an **older Intel Mac**, Apple makes this surprisingly difficult — sometimes impossible — using official tools.

Older macOS versions are distributed as **`.pkg` installers**, but:

- They don’t produce a bootable USB on modern Macs
- `createinstallmedia` often fails or isn’t accessible
- The installer app can’t be launched on Apple Silicon

This script exists to solve **that exact problem** for legacy Apple installer packages that contain `InstallESD.dmg`.

It takes an **official legacy macOS installer `.pkg`**, rebuilds the installer image, and restores it to a USB drive for use on compatible Intel Macs.

---

## When you need this

Use this script if:

- You only have access to a **modern Apple Silicon Mac** or another newer Mac
- You need to reinstall macOS on an **older Intel Mac**
- Internet Recovery doesn’t work or isn’t available
- The macOS installer you downloaded is a legacy **`.pkg`, not an app**
- The package contains `InstallESD.dmg`, such as Apple's older `InstallMacOSX.pkg` format

---

## What it does

The script automates a process that normally requires undocumented manual steps:

1. Expands Apple’s legacy installer `.pkg`
2. Extracts and mounts `InstallESD.dmg`
3. Rebuilds the installer BaseSystem image with the required packages
4. Validates the expected installer files before erasing the USB
5. Restores that image to the selected USB disk with Apple’s `asr` tool

---

## Requirements

- macOS (Apple Silicon or Intel)
- USB drive (8 GB minimum, 16 GB recommended)
- Official legacy macOS installer `.pkg` containing `InstallESD.dmg`
- Administrator (sudo) access

Legacy macOS installers can be downloaded from Apple:  
https://support.apple.com/102662

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/Raasu2/macOS-BootableUSB-Builder.git
cd macOS-BootableUSB-Builder
```

### 2. Make the script executable

```bash
chmod +x create_bootable_installer.sh
```

### 3. Insert your USB drive

Note the current mounted **volume name** shown in Finder under Locations, for example `InstallUSB`.

You can also see mounted USB volumes in Terminal with:

```bash
ls /Volumes
```

⚠️ **All data on the selected physical USB disk will be erased, including every partition on that disk.**

### 4. Run the script

```bash
./create_bootable_installer.sh
```

### 5. Follow the prompts

You’ll be asked for:

- The full path to the Apple macOS installer `.pkg` file
- The current mounted USB volume name, such as `InstallUSB` or `/Volumes/InstallUSB`
- The final USB name after formatting, or press Enter to use `MacOS Boot USB`
- A final destructive confirmation by typing `ERASE`

Paths pasted from Finder are supported, including spaces escaped with backslashes, for example:

```bash
/Users/name/Downloads/Install\ MacOSX.pkg
```

Do not enter a disk identifier like `disk4` or `disk4s1` when asked for the USB volume name. The script resolves the physical disk from the mounted volume and shows it before erasing anything.

The script handles the rest.

---

## Booting the Intel Mac

1. Insert the USB into the Intel Mac
2. Power on and hold **Option (⌥)**
3. Select the installer and proceed normally

---

## Notes & safety

- The script uses the USB volume name to find the physical disk, then erases that entire disk
- The USB is renamed during formatting; the default final name is `MacOS Boot USB`
- The installer package is expanded and checked before the USB erase confirmation appears
- Temporary files are created in a private temporary directory and cleaned up automatically
- Double-check the USB name before confirming

---

## Known limitations

- This is intended for legacy Apple packages that contain `InstallESD.dmg`; it is not a universal converter for every macOS `.pkg`.
- The smoke test verifies script flow and safety checks, but it cannot prove that a USB boots a real Mac.
- Final bootability depends on the exact macOS installer, the target Intel Mac, and Apple's compatibility rules.

---

## Testing

Run the non-destructive smoke test with:

```bash
bash tests/smoke_test.sh
```

The test replaces `diskutil`, `hdiutil`, `asr`, `sudo`, and related tools with local mocks, so it verifies the script flow without touching real disks.

For a full end-to-end test, use a sacrificial USB drive, a real supported Apple legacy installer package, and a compatible Intel Mac to verify booting.

---

## Background

This script is based on real recovery steps discussed here:  
https://apple.stackexchange.com/questions/418100/create-an-el-capitan-rescue-usb-using-a-modern-m1-mac

The manual method works — this script makes it repeatable and less error-prone.

---

## License

MIT License
