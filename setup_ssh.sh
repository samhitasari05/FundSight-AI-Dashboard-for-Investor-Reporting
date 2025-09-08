#!/bin/bash

# AllyInAi Licensing Library - SSH Setup Script
# This script helps team members set up SSH authentication for the private repository

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to copy to clipboard
copy_to_clipboard() {
    local os=$(detect_os)
    local file="$1"
    
    case $os in
        "macos")
            if command_exists pbcopy; then
                pbcopy < "$file"
                print_success "SSH public key copied to clipboard"
            else
                print_warning "pbcopy not found. Please copy the key manually:"
                cat "$file"
            fi
            ;;
        "linux")
            if command_exists xclip; then
                xclip -selection clipboard < "$file"
                print_success "SSH public key copied to clipboard"
            elif command_exists xsel; then
                xsel --clipboard --input < "$file"
                print_success "SSH public key copied to clipboard"
            else
                print_warning "xclip/xsel not found. Please copy the key manually:"
                cat "$file"
            fi
            ;;
        "windows")
            if command_exists clip; then
                clip < "$file"
                print_success "SSH public key copied to clipboard"
            else
                print_warning "clip not found. Please copy the key manually:"
                cat "$file"
            fi
            ;;
        *)
            print_warning "Unknown OS. Please copy the key manually:"
            cat "$file"
            ;;
    esac
}

# Main setup function
setup_ssh() {
    print_status "Starting SSH setup for AllyInAi Licensing Library..."
    echo
    
    # Check if SSH key already exists
    if [ -f ~/.ssh/id_ed25519_allyinai ]; then
        print_warning "SSH key already exists: ~/.ssh/id_ed25519_allyinai"
        read -p "Do you want to generate a new key? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Using existing SSH key"
        else
            print_status "Backing up existing key..."
            mv ~/.ssh/id_ed25519_allyinai ~/.ssh/id_ed25519_allyinai.backup
mv ~/.ssh/id_ed25519_allyinai.pub ~/.ssh/id_ed25519_allyinai.pub.backup
        fi
    fi
    
    # Get user email
    echo
    read -p "Enter your AllyInAi email address: " user_email
    
    if [ -z "$user_email" ]; then
        print_error "Email address is required"
        exit 1
    fi
    
    # Generate SSH key
    print_status "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$user_email" -f ~/.ssh/id_ed25519_allyinai -N ""
    
    if [ $? -eq 0 ]; then
        print_success "SSH key generated successfully"
    else
        print_error "Failed to generate SSH key"
        exit 1
    fi
    
    # Set proper permissions
    chmod 600 ~/.ssh/id_ed25519_allyinai
chmod 644 ~/.ssh/id_ed25519_allyinai.pub
    
    # Start SSH agent
    print_status "Starting SSH agent..."
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    
    # Add key to SSH agent
    print_status "Adding SSH key to agent..."
    ssh-add ~/.ssh/id_ed25519_allyinai
    
    # Configure SSH config
    print_status "Configuring SSH config..."
    mkdir -p ~/.ssh
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
    
    # Add GitHub configuration to SSH config
    if ! grep -q "Host github.com" ~/.ssh/config; then
        cat >> ~/.ssh/config << EOF

# GitHub SSH configuration for AllyInAi
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_allyinai
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
        
        # Add macOS-specific settings
        if [ "$(detect_os)" = "macos" ]; then
            echo "    UseKeychain yes" >> ~/.ssh/config
        fi
        
        print_success "SSH config updated"
    else
        print_warning "GitHub configuration already exists in SSH config"
    fi
    
    # Copy public key to clipboard
    print_status "Copying SSH public key to clipboard..."
    copy_to_clipboard ~/.ssh/id_ed25519_allyinai.pub
    
    echo
    print_success "SSH key setup completed!"
    echo
    print_status "Next steps:"
    echo "1. Go to https://github.com/settings/ssh"
    echo "2. Click 'New SSH key'"
    echo "3. Give it a title: 'AllyInAi Work Laptop'"
    echo "4. Paste the key (already copied to clipboard)"
    echo "5. Click 'Add SSH key'"
    echo
    print_status "After adding the key to GitHub, run:"
    echo "  ssh -T git@github.com"
    echo
    print_status "Then clone the repository:"
    echo "  git clone git@github.com:AllyInAi/allyin-licensing.git"
echo "  cd allyin-licensing"
    echo "  python3 quick_test.py"
}

# Test SSH connection
test_ssh() {
    print_status "Testing SSH connection to GitHub..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "SSH connection successful!"
        return 0
    else
        print_error "SSH connection failed"
        print_status "Please check:"
        echo "1. SSH key is added to GitHub"
        echo "2. You have access to AllyInAi organization"
        echo "3. You have access to the repository"
        return 1
    fi
}

# Clone repository
clone_repo() {
    print_status "Cloning AllyInAi Licensing Library repository..."
    
    if [ -d "allyin-licensing" ]; then
        print_warning "Directory 'allyin-licensing' already exists"
        read -p "Do you want to remove it and clone again? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf allyin-licensing
        else
            print_status "Using existing directory"
            cd allyin-licensing
            return 0
        fi
    fi
    
    if git clone git@github.com:AllyInAi/allyin-licensing.git; then
        print_success "Repository cloned successfully"
        cd allyin-licensing
    else
        print_error "Failed to clone repository"
        return 1
    fi
}

# Test the library
test_library() {
    print_status "Testing the licensing library..."
    
    if [ ! -f "quick_test.py" ]; then
        print_error "quick_test.py not found. Are you in the correct directory?"
        return 1
    fi
    
    if python3 quick_test.py; then
        print_success "Library test completed successfully!"
    else
        print_error "Library test failed"
        return 1
    fi
}

# Main menu
show_menu() {
    echo
    echo "=========================================="
    echo "  AllyInAi Licensing Library - SSH Setup"
    echo "=========================================="
    echo
    echo "1. Setup SSH key (recommended)"
    echo "2. Test SSH connection"
    echo "3. Clone repository"
    echo "4. Test library"
    echo "5. Full setup (1-4 in sequence)"
    echo "6. Exit"
    echo
}

# Main script
main() {
    case "${1:-}" in
        "setup")
            setup_ssh
            ;;
        "test")
            test_ssh
            ;;
        "clone")
            clone_repo
            ;;
        "test-lib")
            test_library
            ;;
        "full")
            setup_ssh
            echo
            read -p "Press Enter after adding the SSH key to GitHub..."
            test_ssh
            clone_repo
            test_library
            ;;
        *)
            while true; do
                show_menu
                read -p "Choose an option (1-6): " -n 1 -r
                echo
                echo
                
                case $REPLY in
                    1) setup_ssh ;;
                    2) test_ssh ;;
                    3) clone_repo ;;
                    4) test_library ;;
                    5) 
                        setup_ssh
                        echo
                        read -p "Press Enter after adding the SSH key to GitHub..."
                        test_ssh
                        clone_repo
                        test_library
                        ;;
                    6) 
                        print_status "Goodbye!"
                        exit 0
                        ;;
                    *) 
                        print_error "Invalid option. Please choose 1-6."
                        ;;
                esac
                
                echo
                read -p "Press Enter to continue..."
            done
            ;;
    esac
}

# Run main function
main "$@" 