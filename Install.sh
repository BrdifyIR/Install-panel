#!/bin/bash

# ==========================================
# Auto-answers for Pasarguard installation
# ==========================================
AUTO_ANSWERS="4\ny\nn\n\n\nn\n\ny\n\n"

# ==========================================
# Display Functions
# ==========================================
show_banner() {
    clear
    echo -e "\e[36m"
    cat << "EOF"
██████╗ ██████╗ ██████╗ ██╗███████╗██╗   ██╗
██╔══██╗██╔══██╗██╔══██╗██║██╔════╝╚██╗ ██╔╝
██████╔╝██████╔╝██║  ██║██║█████╗   ╚████╔╝ 
██╔══██╗██╔══██╗██║  ██║██║██╔══╝    ╚██╔╝  
██████╔╝██║  ██║██████╔╝██║██║        ██║   
╚══════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝        ╚═╝   
           https://t.me/Brdify
EOF
    echo -e "\e[0m"
}

print_success() { echo -e "\e[1;92m✓ $1\e[0m"; }
print_error() { echo -e "\e[1;31m✗ $1\e[0m"; }
print_info() { echo -e "\e[1;36m! $1\e[0m"; }

# ==========================================
# SSL Functions
# ==========================================
install_dependencies() {
    local pkg_manager
    if command -v apt-get &> /dev/null; then
        pkg_manager="apt-get"
    elif command -v dnf &> /dev/null; then
        pkg_manager="dnf"
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
    else
        print_error "No supported package manager found."
        exit 1
    fi

    print_info "Updating package lists..."
    $pkg_manager update -y > /dev/null 2>&1

    local packages=("curl" "socat" "certbot" "jq")
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            print_info "Installing $pkg..."
            $pkg_manager install -y "$pkg" > /dev/null 2>&1
        fi
    done

    if ! command -v ~/.acme.sh/acme.sh &> /dev/null; then
        print_info "Installing acme.sh..."
        curl -s https://get.acme.sh | sh -s email="$email" > /dev/null 2>&1
        source ~/.bashrc
    fi
}

get_install_certificate_acme() {
    local domain="$1"
    ~/.acme.sh/acme.sh --issue --standalone -d "$domain" --accountemail "$email" --force || return 1

    mkdir -p "$destination"

    ~/.acme.sh/acme.sh --install-cert -d "$domain" \
        --key-file "$destination/privkey.pem" \
        --fullchain-file "$destination/fullchain.pem" || return 1
    return 0
}

get_install_certificate_certbot() {
    local domain="$1"
    certbot certonly --standalone -d "$domain" --non-interactive --agree-tos --email "$email" --force || return 1

    mkdir -p "$destination"

    cat /etc/letsencrypt/live/$domain/privkey.pem > "$destination/privkey.pem"
    cat /etc/letsencrypt/live/$domain/fullchain.pem > "$destination/fullchain.pem"
    return 0
}

install_ssl() {
    show_banner
    echo "========================================="
    echo "          Pasarguard SSL Setup           "
    echo "========================================="
    echo ""
    
    read -p "Enter your Email: " email
    read -p "Enter your Domain: " domain

    if [[ -z "$email" || -z "$domain" ]]; then
        print_error "Email and Domain cannot be empty!"
        sleep 2
        install_pasarguard
        return
    fi

    destination="/var/lib/pasarguard/certs/${domain}/"

    print_info "Installing dependencies..."
    install_dependencies

    print_info "Attempting to get SSL for $domain using acme.sh..."
    if get_install_certificate_acme "$domain"; then
        print_success "SSL certificate successfully installed using acme.sh"
    else
        print_info "acme.sh failed. Trying certbot..."
        if get_install_certificate_certbot "$domain"; then
            print_success "SSL certificate successfully installed using certbot"
        else
            print_error "Failed to obtain SSL certificate with both methods."
        fi
    fi

    echo ""
    read -p "Press Enter to return to menu..."
    install_pasarguard
}

# ==========================================
# Pasarguard Installation Menu
# ==========================================
install_pasarguard() {
    show_banner
    echo "========================================="
    echo "  Select Database for Pasarguard:"
    echo "  1) TimescaleDB"
    echo "  2) SQLite"
    echo "  3) MySQL"
    echo "  4) MariaDB"
    echo "  5) PostgreSQL"
    echo "-----------------------------------------"
    echo "  6) Install SSL Certificate for Panel"
    echo "  7) Generate Temp Key (Token)"
    echo "  8) Backup Panel to Telegram Bot"
    echo "  9) Restore Backup"
    echo "  0) Back to Main Menu"
    echo "========================================="
    echo ""
    read -p "Please select an option [0-9]: " db_choice

    case $db_choice in
        1)
            (printf "$AUTO_ANSWERS"; cat) | sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database timescaledb
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        2)
            (printf "$AUTO_ANSWERS"; cat) | sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        3)
            (printf "$AUTO_ANSWERS"; cat) | sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database mysql
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        4)
            (printf "$AUTO_ANSWERS"; cat) | sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database mariadb
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        5)
            (printf "$AUTO_ANSWERS"; cat) | sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database postgresql
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        6)
            install_ssl
            ;;
        7)
            echo ""
            print_info "Generating Token / Temp Key..."
            pasarguard cli generate-temp-key
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        8)
            echo ""
            print_info "Starting Telegram Bot Backup Service..."
            pasarguard backup-service
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        9)
            echo ""
            print_info "Restoring Backup..."
            pasarguard restore
            echo ""
            read -p "Press Enter to return to menu..."
            install_pasarguard
            ;;
        0)
            show_menu
            ;;
        *)
            echo "Invalid option!"
            sleep 1
            install_pasarguard
            ;;
    esac
}

# ==========================================
# Main Menu
# ==========================================
show_menu() {
    show_banner
    echo "========================================="
    echo "  1) Install Pasarguard"
    echo "  0) Exit"
    echo "========================================="
    echo ""
    read -p "Please select an option [0-1]: " choice

    case $choice in
        1) install_pasarguard ;;
        0) clear; exit 0 ;;
        *)
            echo "Invalid option!"
            sleep 1
            show_menu
            ;;
    esac
}

# Start the script
show_menu
