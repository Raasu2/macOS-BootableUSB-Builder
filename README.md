# Create bootable legacy macOS USB installers on Apple Silicon

## What this is

If you’re using a **new Apple Silicon Mac (M1 / M2 / M3)** and need to install macOS on an **older Intel Mac**, Apple makes this surprisingly difficult — sometimes impossible — using official tools.

Older macOS versions are distributed as **`.pkg` installers**, but:

- They don’t produce a bootable USB on modern Macs
- `createinstallmedia` often fails or isn’t accessible
- The installer app can’t be launched on Apple Silicon

This script exists to solve **that exact problem**.

It takes an **official macOS installer `.pkg`**, extracts it correctly, and creates a **bootable USB installer that works on Intel Macs**, even when created on Apple Silicon.

---

## When you need this

Use this script if:

- You only have access to a **modern Apple Silicon Mac**
- You need to reinstall macOS on an **older Intel Mac**
- Internet Recovery doesn’t work or isn’t available
- The macOS installer you downloaded is a **`.pkg`, not an app**

---

## What it does

The script automates a process that normally requires undocumented manual steps:

1. Extracts the hidden **Install macOS.app** from Apple’s `.pkg`
2. Mounts the required disk images
3. Runs Apple’s own `createinstallmedia` in a way that still works on modern macOS
4. Produces a **properly bootable USB installer for Intel Macs**

---

## Requirements

- macOS (Apple Silicon or Intel)
- USB drive (8 GB minimum, 16 GB recommended)
- Official macOS installer `.pkg`
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

Note the **volume name** (example: `InstallUSB`).

⚠️ **All data on this drive will be erased.**

### 4. Run the script

```bash
./create_bootable_installer.sh
```

### 5. Follow the prompts

You’ll be asked for:

- The full path to the macOS installer `.pkg`
- The USB volume name

The script handles the rest.

---

## Booting the Intel Mac

1. Insert the USB into the Intel Mac
2. Power on and hold **Option (⌥)**
3. Select the installer and proceed normally

---

## Notes & safety

- The script only erases the USB volume you specify
- Temporary files are cleaned up automatically
- Double-check the USB name before confirming

---

## Background

This script is based on real recovery steps discussed here:  
https://apple.stackexchange.com/questions/418100/create-an-el-capitan-rescue-usb-using-a-modern-m1-mac

The manual method works — this script makes it repeatable and less error-prone.

---

## License

MIT License
