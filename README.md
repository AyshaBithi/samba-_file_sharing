# Advanced Samba Management System

## Overview
This script provides a user-friendly way to manage Samba services, users, and shared folders on a Linux system. It leverages the `whiptail` utility to create a graphical menu-driven interface for ease of use.

## Features
1. **Samba Service Management**
   - Start, stop, restart, or check the status of the Samba service.
2. **User Management**
   - Create new Samba users.
   - List existing Samba users.
   - Delete Samba users.
   - Set specific permissions for users on Samba shares.
3. **Shared Folder Management**
   - Create new shared folders.
   - List all configured shared folders with their paths.
   - Delete existing shared folders.
4. **Connection Instructions**
   - Display instructions on how to connect to Samba shares from a Windows system.

## Prerequisites
1. **Samba Installation**
   Ensure Samba is installed on your system. You can install it using:
   ```bash
   sudo apt update && sudo apt install samba
   ```
2. **System Configuration**
   The script assumes standard Samba configurations. Make sure you have root privileges to manage Samba users and shared folders.
3. **Whiptail Utility**
   Whiptail is used for the menu-driven interface. It is typically pre-installed on most Linux distributions.

## Setup
1. Save the script to a file, e.g., `samba_manager.sh`.
2. Make the script executable:
   ```bash
   chmod +x samba_manager.sh
   ```

## Usage
Run the script using:
```bash
sudo ./samba_manager.sh
```

### Main Menu
The main menu provides the following options:
1. **Samba Service Management**: Manage the Samba service (start, stop, restart, check status).
2. **User Management**: Manage Samba users (create, list, set permissions, delete).
3. **Shared Folder Management**: Manage shared folders (create, list, delete).
4. **Connection Instructions**: View instructions for connecting to Samba shares.
5. **Exit**: Exit the script.

### Detailed Feature Usage
#### 1. Samba Service Management
   - Start, stop, or restart the Samba service to ensure smooth operation.
   - Check if the Samba service is running.

#### 2. User Management
   - **Create Samba User**: Add a new system user and enable them for Samba access.
   - **List Samba Users**: Display all users with Samba access.
   - **Set User Permissions**: Assign read-only or read/write permissions for a user on a specific share.
   - **Delete Samba User**: Remove a user from the system and revoke Samba access.

#### 3. Shared Folder Management
   - **Create Shared Folder**: Set up a new directory for Samba sharing. The script automatically configures the folder in Samba.
   - **List Shared Folders**: View all currently shared folders with their network paths.
   - **Delete Shared Folder**: Remove a shared folder and its configuration from Samba.

#### 4. Connection Instructions
   - View a guide to connect to Samba shares from a Windows system, including the network path format.

## Notes
1. **User and Folder Management**
   - Samba users must also exist as system users.
   - Ensure appropriate permissions are set for shared folders.
2. **Samba Configuration File**
   - The script modifies `/etc/samba/smb.conf` to manage shares. Back up this file before running the script.
3. **Clipboard Support**
   - If `xclip` is installed, share paths can be copied to the clipboard for convenience.

## Troubleshooting
- **Samba Not Installed**: If the script detects that Samba is not installed, install it and rerun the script.
- **Permission Issues**: Ensure the script is run with `sudo` for administrative tasks.
- **Service Not Starting**: Check Samba logs in `/var/log/samba` for errors.

## Example
### Creating a Shared Folder:
1. Select `Shared Folder Management` from the main menu.
2. Choose `Create Shared Folder`.
3. Enter the folder name and confirm.
4. View the network path and optionally copy it to the clipboard.

### Connecting from Windows:
1. Open File Explorer.
2. Enter the network path (e.g., `\\192.168.1.10\share_name`) in the address bar.
3. Authenticate if required and access the share.

## License
This script is provided under the MIT License. Feel free to use and modify it to suit your needs.

## Disclaimer
This script modifies system configurations. Use with caution and ensure proper backups are taken before running the script.

