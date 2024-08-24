# macOS USB Installer Script

This script enables you to create a bootable USB installer for older versions of macOS using full installer files downloaded from Apple's website. It is especially useful for preparing bootable drives for macOS versions that are challenging to set up on newer hardware.

## Introduction

Creating a bootable macOS USB installer for older versions like macOS Yosemite (10.10) can be challenging on newer Macs. This script simplifies the process by automating the creation of a bootable USB installer using the `.pkg` file downloaded from Apple's support page.

This script was created based on instructions posted in a StackExchange post


**Original post:** [Create an El Capitan rescue USB using a modern M1 Mac](https://apple.stackexchange.com/questions/418100/create-an-el-capitan-rescue-usb-using-a-modern-m1-mac)

## Features

- Create bootable macOS USB installers for various macOS versions.
- Works on newer Macs with Apple Silicon or Intel processors.
- Automates the entire process from extracting the installer to preparing the USB drive.

## Prerequisites

- macOS with access to the Terminal.
- The `.pkg` file of the macOS installer you wish to use. This can be downloaded from Apple's [support page](https://support.apple.com/en-gb/102662) or other trusted sources.
- A USB drive with at least 8 GB of space.
- Administrative privileges to execute some commands.

## Installation

1. **Download the Script:**
   Clone this repository or download the script file directly from the [GitHub repository](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME).

   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME.git
2. **Follow the Prompts:**
   - Enter the full path to the InstallMacOSX.pkg file when prompted.
   - Enter the volume name of your USB drive (e.g., KEY).
   
## Usage

1. **Run the Script:**

   ```bash
   ./create_bootable_installer.sh

2. **Follow the Prompts:**
  - Enter the full path to the InstallMacOSX.pkg file when prompted.
  - Enter the volume name of your USB drive (e.g., KEY).

The script will handle the rest, including formatting the USB drive, copying necessary files, and cleaning up temporary files.

## Cleanup

The script automatically handles cleanup of temporary files and directories, ensuring no residual files are left behind.

## Troubleshooting

- Ensure that the path to the `.pkg` file is correct and accessible.
- Make sure your USB drive is properly formatted and mounted.
- Check that you have sufficient administrative privileges to execute the script.

If you encounter issues, refer to the [GitHub Issues page](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME/issues) or the [Stack Exchange post](https://apple.stackexchange.com/questions/418100/create-an-el-capitan-rescue-usb-using-a-modern-m1-mac) for potential solutions.

## Contributing

Feel free to fork the repository and submit pull requests if you have improvements or fixes. Contributions are welcome!

## License

This script is released under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments

This script was inspired by a solution shared on Stack Exchange. Special thanks to the original contributors for their valuable input:

- **Original Stack Exchange Post**: [Create an El Capitan Rescue USB Using a Modern M1 Mac](https://apple.stackexchange.com/questions/418100/create-an-el-capitan-rescue-usb-using-a-modern-m1-mac)
- **Author**: [nohillside](https://apple.stackexchange.com/users/415185)

The approach outlined in the post was instrumental in developing this script, which has been adapted to support creating bootable installers for macOS from full installer files.

