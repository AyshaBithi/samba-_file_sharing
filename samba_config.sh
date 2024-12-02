#!/bin/bash

# Function to check if Samba is installed
check_samba_installed() {
    if ! command -v samba &>/dev/null; then
        whiptail --title "Installation Error" --backtitle "Samba Server Management" --msgbox "Samba is not installed. Please install Samba before using this tool." 8 50 --ok-button "Got it!"
        exit 1
    fi
}

# Function to start Samba service
start_samba_service() {
    systemctl start smbd
    systemctl enable smbd
    whiptail --title "Samba Service Started" --backtitle "Samba Server Management" --msgbox "The Samba service has been successfully started and enabled to start on boot." 8 50 --ok-button "Ok"
}

# Function to stop Samba service
stop_samba_service() {
    systemctl stop smbd
    whiptail --title "Samba Service Stopped" --backtitle "Samba Server Management" --msgbox "The Samba service has been stopped." 8 50 --ok-button "Ok"
}

# Function to restart Samba service
restart_samba_service() {
    systemctl restart smbd
    whiptail --title "Samba Service Restarted" --backtitle "Samba Server Management" --msgbox "The Samba service has been successfully restarted." 8 50 --ok-button "Ok"
}

# Function to check Samba service status
check_samba_status() {
    service_status=$(systemctl is-active smbd)
    if [[ "$service_status" == "active" ]]; then
        whiptail --title "Samba Service Status" --backtitle "Samba Server Management" --msgbox "The Samba service is currently running." 8 50 --ok-button "Ok"
    else
        whiptail --title "Samba Service Status" --backtitle "Samba Server Management" --msgbox "The Samba service is not running. Please start the service." 8 50 --ok-button "Ok"
    fi
}

# Function to create a Samba user
create_samba_user() {
    username=$(whiptail --title "Create Samba User" --backtitle "Samba Server Management" --inputbox "Enter the username for the new Samba user:" 8 50 "" 3>&1 1>&2 2>&3)
    if [[ -z "$username" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must provide a valid username." 8 50 --ok-button "Ok"
        return
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "The user '$username' already exists." 8 50 --ok-button "Ok"
        return
    fi

    # Add the user to the system and enable Samba access
    sudo useradd -m "$username"
    sudo smbpasswd -a "$username"
    sudo smbpasswd -e "$username"
    whiptail --title "User Created" --backtitle "Samba Server Management" --msgbox "The Samba user '$username' has been successfully created." 8 50 --ok-button "Ok"
}

# Function to list all Samba users
list_samba_users() {
    users=$(pdbedit -L)
    if [[ -z "$users" ]]; then
        whiptail --title "No Samba Users" --backtitle "Samba Server Management" --msgbox "There are no Samba users configured." 8 50 --ok-button "Ok"
    else
        whiptail --title "Samba Users" --backtitle "Samba Server Management" --msgbox "List of Samba Users:\n\n$users" 15 60 --ok-button "Ok"
    fi
}

# Function to set permissions for a Samba user
set_samba_user_permissions() {
    username=$(whiptail --title "Set Samba User Permissions" --backtitle "Samba Server Management" --inputbox "Enter the username for permission management:" 8 50 "" 3>&1 1>&2 2>&3)
    if [[ -z "$username" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "Username cannot be empty." 8 50 --ok-button "Ok"
        return
    fi

    # Check if the user exists
    if ! pdbedit -L | grep -q "$username"; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "User '$username' does not exist." 8 50 --ok-button "Ok"
        return
    fi

    share_name=$(whiptail --title "Set Permissions" --backtitle "Samba Server Management" --inputbox "Enter the share name to set permissions:" 8 50 "" 3>&1 1>&2 2>&3)
    permission_type=$(whiptail --title "Permission Type" --backtitle "Samba Server Management" --menu "Select the permission type:" 15 60 2 \
        "1" "Read-Only" \
        "2" "Read/Write" 3>&1 1>&2 2>&3)

    case "$permission_type" in
        1) permission="read only = yes" ;;
        2) permission="read only = no" ;;
    esac

    # Apply the permission settings to the Samba share
    sudo sed -i "/^\[$share_name\]/,/^\[.*\]/s/^$/   $permission/" /etc/samba/smb.conf
    sudo systemctl restart smbd
    whiptail --title "Permissions Set" --backtitle "Samba Server Management" --msgbox "Permissions for user '$username' on share '$share_name' have been successfully set." 8 50 --ok-button "Ok"
}

# Function to create a shared folder
create_shared_folder() {
    folder_name=$(whiptail --title "Create Shared Folder" --backtitle "Samba Server Management" --inputbox "Enter the folder name to create:" 8 50 "" 3>&1 1>&2 2>&3)
    if [[ -z "$folder_name" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must provide a folder name." 8 50 --ok-button "Ok"
        return
    fi

    folder_path="/srv/samba/$folder_name"
    if [[ -d "$folder_path" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "The folder '$folder_path' already exists." 8 50 --ok-button "Ok"
        return
    fi

    # Create the folder and set permissions
    sudo mkdir -p "$folder_path"
    sudo chmod -R 0777 "$folder_path"

    # Display connection info
    ip_address=$(hostname -I | awk '{print $1}')
    share_command="\\\\$ip_address\\$folder_name"
    whiptail --title "Folder Created" --backtitle "Samba Server Management" --msgbox "Folder '$folder_name' has been created at '$folder_path'.\n\nYou can access it from Windows using this path:\n\n$share_command" 15 60 --ok-button "Ok"

    # Option to copy the command to clipboard
    if whiptail --title "Copy Command" --backtitle "Samba Server Management" --yesno "Do you want to copy this connection path to the clipboard?" 8 50; then
        echo -n "$share_command" | xclip -selection clipboard
        whiptail --title "Copied" --backtitle "Samba Server Management" --msgbox "The connection path has been copied to your clipboard." 8 50 --ok-button "Ok"
    fi
}

# Function to delete a shared folder
delete_shared_folder() {
    folder_name=$(whiptail --title "Delete Shared Folder" --backtitle "Samba Server Management" --inputbox "Enter the folder name to delete:" 8 50 "" 3>&1 1>&2 2>&3)
    if [[ -z "$folder_name" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must provide a folder name." 8 50 --ok-button "Ok"
        return
    fi

    folder_path="/srv/samba/$folder_name"
    if [[ ! -d "$folder_path" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "The folder '$folder_path' does not exist." 8 50 --ok-button "Ok"
        return
    fi

    # Delete the folder
    sudo rm -rf "$folder_path"
    whiptail --title "Folder Deleted" --backtitle "Samba Server Management" --msgbox "The folder '$folder_name' has been successfully deleted." 8 50 --ok-button "Ok"
}

# Function to list all shared folders
list_shared_folders() {
    shared_folders=$(ls /srv/samba/)
    if [[ -z "$shared_folders" ]]; then
        whiptail --title "No Shared Folders" --backtitle "Samba Server Management" --msgbox "There are no shared folders available." 8 50 --ok-button "Ok"
    else
        folder_list=""
        for folder in $shared_folders; do
            ip_address=$(hostname -I | awk '{print $1}')
            folder_list+="$folder - \\$ip_address\\$folder\n"
        done
        whiptail --title "Shared Folders" --backtitle "Samba Server Management" --msgbox "Here are the available shared folders and their corresponding Windows paths:\n\n$folder_list" 15 60 --ok-button "Ok"
    fi
}

# Function to show connection instructions
show_connection_instructions() {
    ip_address=$(hostname -I | awk '{print $1}')
    message="To access Samba shares from Windows, open File Explorer and enter the following path:\n\n\\\\$ip_address\\\n\nReplace 'share' with the specific share name to access individual folders."
    whiptail --title "Windows Connection Instructions" --backtitle "Samba Server Management" --msgbox "$message" 15 60 --ok-button "Ok"
}

#!/bin/bash

# Function to check if Samba is installed
check_samba_installed() {
    if ! command -v samba &>/dev/null; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "Samba is not installed. Please install Samba first." 8 45 --ok-button "Got it!"
        exit 1
    fi
}

# Function to start Samba service
start_samba_service() {
    systemctl start smbd
    systemctl enable smbd
    whiptail --title "Samba Service" --backtitle "Samba Server Management" --msgbox "Samba service started and enabled." 8 45 --ok-button "Ok"
}

# Function to stop Samba service
stop_samba_service() {
    systemctl stop smbd
    whiptail --title "Samba Service" --backtitle "Samba Server Management" --msgbox "Samba service stopped." 8 45 --ok-button "Ok"
}

# Function to restart Samba service
restart_samba_service() {
    systemctl restart smbd
    whiptail --title "Samba Service" --backtitle "Samba Server Management" --msgbox "Samba service restarted." 8 45 --ok-button "Ok"
}

# Function to check Samba service status
check_samba_status() {
    service_status=$(systemctl is-active smbd)
    if [[ "$service_status" == "active" ]]; then
        whiptail --title "Samba Service Status" --backtitle "Samba Server Management" --msgbox "Samba service is running." 8 45 --ok-button "Ok"
    else
        whiptail --title "Samba Service Status" --backtitle "Samba Server Management" --msgbox "Samba service is not running." 8 45 --ok-button "Ok"
    fi
}

# Function to create a Samba user
create_samba_user() {
    username=$(whiptail --title "Create Samba User" --backtitle "Samba Server Management" --inputbox "Enter the username:" 8 45 "" 3>&1 1>&2 2>&3)
    if [[ -z "$username" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must enter a username." 8 45 --ok-button "Ok"
        return
    fi

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "User '$username' already exists." 8 45 --ok-button "Ok"
        return
    fi

    # Add the user to the system
    sudo useradd -m "$username"
    sudo smbpasswd -a "$username"
    sudo smbpasswd -e "$username"
    whiptail --title "Success" --backtitle "Samba Server Management" --msgbox "Samba user '$username' has been created." 8 45 --ok-button "Ok"
}

# Function to list all Samba users
list_samba_users() {
    users=$(pdbedit -L)
    if [[ -z "$users" ]]; then
        whiptail --title "No Samba Users" --backtitle "Samba Server Management" --msgbox "No Samba users found." 8 45 --ok-button "Ok"
    else
        whiptail --title "Samba Users" --backtitle "Samba Server Management" --msgbox "List of Samba Users:\n$users" 15 60 --ok-button "Ok"
    fi
}
# Function to delete a Samba user
delete_samba_user() {
    username=$(whiptail --title "Delete Samba User" --backtitle "Samba Server Management" --inputbox "Enter the username to delete:" 8 45 "" 3>&1 1>&2 2>&3)
    if [[ -z "$username" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must enter a username." 8 45 --ok-button "Ok"
        return
    fi

    # Check if the user exists
    if ! id "$username" &>/dev/null; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "User '$username' does not exist." 8 45 --ok-button "Ok"
        return
    fi

    # Delete the Samba user
    sudo smbpasswd -x "$username"  # Remove the Samba user
    sudo userdel -r "$username"     # Remove the system user (optional: removes home directory too)

    whiptail --title "Success" --backtitle "Samba Server Management" --msgbox "The Samba user '$username' has been deleted." 8 45 --ok-button "Ok"
}


# Function to set permissions for a Samba user
set_samba_user_permissions() {
    username=$(whiptail --title "Set Samba User Permissions" --backtitle "Samba Server Management" --inputbox "Enter the username:" 8 45 "" 3>&1 1>&2 2>&3)
    if [[ -z "$username" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must enter a username." 8 45 --ok-button "Ok"
        return
    fi

    # Check if the user exists
    if ! pdbedit -L | grep -q "$username"; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "User '$username' does not exist." 8 45 --ok-button "Ok"
        return
    fi

    share_name=$(whiptail --title "Set Samba User Permissions" --backtitle "Samba Server Management" --inputbox "Enter the share name to set permissions:" 8 45 "" 3>&1 1>&2 2>&3)
    permission_type=$(whiptail --title "Set Samba User Permissions" --backtitle "Samba Server Management" --menu "Choose the permission type" 15 60 2 \
        "1" "Read-only" \
        "2" "Read/Write" 3>&1 1>&2 2>&3)

    case "$permission_type" in
        1) permission="read only = yes" ;;
        2) permission="read only = no" ;;
    esac

    # Add the user permission to the share
    sudo sed -i "/^\[$share_name\]/,/^\[.*\]/s/^$/   $permission/" /etc/samba/smb.conf
    sudo systemctl restart smbd
    whiptail --title "Success" --backtitle "Samba Server Management" --msgbox "Permissions for user '$username' on share '$share_name' have been set." 8 45 --ok-button "Ok"
}


# Function to create a shared folder
create_shared_folder() {
    folder_name=$(whiptail --title "Create Shared Folder" --backtitle "Samba Server Management" --inputbox "Enter the folder name to share:" 8 45 "" 3>&1 1>&2 2>&3)
    if [[ -z "$folder_name" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must enter a folder name." 8 45 --ok-button "Ok"
        return
    fi

    folder_path="/srv/samba/$folder_name"
    if [[ -d "$folder_path" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "Folder '$folder_path' already exists." 8 45 --ok-button "Ok"
        return
    fi

    # Create the folder
    sudo mkdir -p "$folder_path"
    sudo chmod -R 0777 "$folder_path"

    # Get the IP address
    ip_address=$(hostname -I | awk '{print $1}')
    share_command="\\\\$ip_address\\$folder_name"

    # Display folder creation info
    whiptail --title "Success" --backtitle "Samba Server Management" --msgbox "Folder '$folder_name' created at '$folder_path'.\n\nTo access this folder from Windows, use the following path:\n\n$share_command\n\nClick OK to copy the command to clipboard." 15 60 --ok-button "Ok"

    # Option to copy command to clipboard
    if whiptail --title "Copy Command" --backtitle "Samba Server Management" --yesno "Do you want to copy the connection command to clipboard?" 8 45; then
        echo -n "$share_command" | xclip -selection clipboard
        whiptail --title "Copied" --backtitle "Samba Server Management" --msgbox "The command has been copied to your clipboard. You can now paste it into Windows Explorer." 8 45 --ok-button "Ok"
    fi
}

# Function to delete a shared folder
delete_shared_folder() {
    folder_name=$(whiptail --title "Delete Shared Folder" --backtitle "Samba Server Management" --inputbox "Enter the folder name to delete:" 8 45 "" 3>&1 1>&2 2>&3)
    if [[ -z "$folder_name" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "You must enter a folder name." 8 45 --ok-button "Ok"
        return
    fi

    folder_path="/srv/samba/$folder_name"
    if [[ ! -d "$folder_path" ]]; then
        whiptail --title "Error" --backtitle "Samba Server Management" --msgbox "Folder '$folder_path' does not exist." 8 45 --ok-button "Ok"
        return
    fi

    # Delete the folder
    sudo rm -rf "$folder_path"
    whiptail --title "Success" --backtitle "Samba Server Management" --msgbox "Folder '$folder_name' has been deleted." 8 45 --ok-button "Ok"
}

# Function to list all shared folders
list_shared_folders() {
    shared_folders=$(ls /srv/samba/)
    if [[ -z "$shared_folders" ]]; then
        whiptail --title "No Shares" --backtitle "Samba Server Management" --msgbox "No shared folders found." 8 45 --ok-button "Ok"
    else
        folder_list=""
        for folder in $shared_folders; do
            ip_address=$(hostname -I | awk '{print $1}')
            folder_list+="$folder - \\$ip_address\\$folder\n"
        done
        whiptail --title "Shared Folders" --backtitle "Samba Server Management" --msgbox "List of shared folders and Windows access paths:\n$folder_list" 15 60 --ok-button "Ok"
    fi
}

# Function to show the IP and instructions on how to connect from Windows
show_connection_instructions() {
    ip_address=$(hostname -I | awk '{print $1}')
    message="To access Samba shares from Windows, use the following path in File Explorer:\n\n"
    message+="\\$ip_address\samba\n\nYou can replace 'samba' with the actual share name to access specific folders."
    whiptail --title "Connection Instructions" --backtitle "Samba Server Management" --msgbox "$message" 15 60 --ok-button "Ok"
}
# Function to exit the script
exit_program() {
    whiptail --title "Goodbye" --msgbox "Exiting the Samba management tool." 8 45 --ok-button "Ok"
    exit 0  # Exit the script gracefully
}
main_menu() {
    while true; do
        option=$(whiptail --title "Samba Server Management" --backtitle "Advanced Samba Management System" --menu "Main Menu: Select an Option" 18 70 10 \
            "1" "Samba Service Management" \
            "2" "User Management" \
            "3" "Shared Folder Management" \
            "4" "Help & Instructions" \
            "5" "Exit" 3>&1 1>&2 2>&3)

        case "$option" in
            1) samba_service_menu ;;
            2) user_management_menu ;;
            3) shared_folder_menu ;;
            4) show_help_instructions ;;
            5) exit_program ;;  # Calls the exit function here
            *) whiptail --title "Error" --backtitle "Samba Management System" --msgbox "Invalid option. Please try again." 8 45 ;;
        esac
    done
}
# Samba Service Management Submenu
samba_service_menu() {
    while true; do
        option=$(whiptail --title "Samba Service Management" --backtitle "Manage Samba Services" --menu "Choose a Service Action" 18 70 6 \
            "1" "Start Samba Service" \
            "2" "Stop Samba Service" \
            "3" "Restart Samba Service" \
            "4" "Check Samba Status" \
            "5" "Back to Main Menu" 3>&1 1>&2 2>&3)

        case "$option" in
            1) start_samba_service ;;
            2) stop_samba_service ;;
            3) restart_samba_service ;;
            4) check_samba_status ;;
            5) return ;;
            *) whiptail --title "Error" --msgbox "Invalid option. Please try again." 8 45 ;;
        esac
    done
}

# User Management Submenu
user_management_menu() {
    while true; do
        option=$(whiptail --title "Samba User Management" --backtitle "Manage Samba Users" --menu "Choose a User Action" 18 70 7 \
            "1" "Create Samba User" \
            "2" "List Samba Users" \
            "3" "Set User Permissions" \
            "4" "Delete Samba User" \
            "5" "Back to Main Menu" 3>&1 1>&2 2>&3)

        case "$option" in
            1) create_samba_user ;;
            2) list_samba_users ;;
            3) set_samba_user_permissions ;;
            4) delete_samba_user ;;  # Added delete user option
            5) return ;;
            *) whiptail --title "Error" --msgbox "Invalid option. Please try again." 8 45 ;;
        esac
    done
}


# Shared Folder Management Submenu
shared_folder_menu() {
    while true; do
        option=$(whiptail --title "Samba Shared Folder Management" --backtitle "Manage Shared Folders" --menu "Choose a Folder Action" 18 70 6 \
            "1" "Create Shared Folder" \
            "2" "Delete Shared Folder" \
            "3" "List Shared Folders" \
            "4" "Back to Main Menu" 3>&1 1>&2 2>&3)

        case "$option" in
            1) create_shared_folder ;;
            2) delete_shared_folder ;;
            3) list_shared_folders ;;
            4) return ;;
            *) whiptail --title "Error" --msgbox "Invalid option. Please try again." 8 45 ;;
        esac
    done
}

# Help Instructions
show_help_instructions() {
    whiptail --title "Help & Instructions" --backtitle "Samba Server Management" --msgbox "Use this menu to manage Samba services, users, and shared folders. \n\nFor further help, refer to the Samba documentation." 15 60 --ok-button "Ok"
}

# Ensure Samba is installed
check_samba_installed

# Run Main Menu
main_menu
