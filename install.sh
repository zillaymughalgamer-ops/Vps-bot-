#!/bin/bash
# ============================================================
#  Svm Vps V9 — Universal Installer (100% Robust Host Setup)
#  Sets up Python deps and systemd service directly on host VPS
# ============================================================

set -e

# Non-interactive mode for APT (Prevents prompt freezes during updates)
export DEBIAN_FRONTEND=noninteractive

# ---------- Colors ----------
RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; BLU='\033[0;34m'
MAG='\033[0;35m'; CYN='\033[0;36m'; WHT='\033[1;37m'; NC='\033[0m'

rainbow_line() {
    local text="$1"
    local colors=("$RED" "$YEL" "$GRN" "$CYN" "$BLU" "$MAG")
    local i=0
    for (( j=0; j<${#text}; j++ )); do
        c=${colors[$((i % 6))]}
        printf '%b%s%b' "$c" "${text:$j:1}" "$NC"
        i=$((i+1))
    done
    echo ""
}

ascii_banner() {
    rainbow_line ' ######  ##     ## ##     ##    ##     ## ########   ######     ##     ##  #######  '
    rainbow_line '##    ## ##     ## ###   ###    ##     ## ##     ## ##    ##    ##     ## ##     ## '
    rainbow_line '##       ##     ## #### ####    ##     ## ##     ## ##          ##     ## ##     ## '
    rainbow_line ' ######  ##     ## ## ### ##    ##     ## ########   ######     ##     ##  ######## '
    rainbow_line '      ##  ##   ##  ##     ##     ##   ##  ##              ##     ##   ##         ## '
    rainbow_line '##    ##   ## ##   ##     ##      ## ##   ##        ##    ##      ## ##   ##     ## '
    rainbow_line ' ######     ###    ##     ##       ###    ##         ######        ###     #######  '
    echo ""
    rainbow_line ' ___  ___ _____   _   __  _____   ___ ___ ___ _____ ___ ___  _  _ '
    rainbow_line '| _ )/ _ \_   _| | |  \ \/ / __| | __|   \_ _|_   _|_ _/ _ \| \| |'
    rainbow_line '|___/\___/ |_|   |____/_/\_\___| |___|___/___| |_| |___\___/|_|\_|'
    echo ""
    rainbow_line '                    ~ Made by SECTOR_PLAYS ~'
    echo ""
}

banner() {
    clear
    ascii_banner
    echo -e "${WHT}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${CYN}Universal VPS Discord Bot Installer (Direct Host Deployment)${NC}"
    echo -e "  ${CYN}Works on ALL Ubuntu & Debian VPS | Fast Setup${NC}"
    echo -e "  ${MAG}Made by SECTOR_PLAYS${NC}  |  ${BLU}github.com/zillaymughalgamer-ops/Vps-bot-${NC}"
    echo -e "${WHT}  ─────────────────────────────────────────────────────────────${NC}\n"
}

step()  { echo -e "${GRN}[+]${NC} $1"; }
warn()  { echo -e "${YEL}[!]${NC} $1"; }
err()   { echo -e "${RED}[x]${NC} $1"; }

need_root() {
    if [ "$EUID" -ne 0 ]; then
        err "Please run this script as root (sudo ./install.sh)"
        exit 1
    fi
}

update_system() {
    step "Updating package list..."
    apt update -y
    step "Installing essentials (curl, git, wget, build tools)..."
    apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        curl wget git build-essential software-properties-common ca-certificates
}

install_python_stack() {
    step "Installing Python 3, pip, and venv..."
    apt install -y python3 python3-pip python3-venv

    step "Configuring pip overrides (PEP 668 compatibility)..."
    mkdir -p ~/.config/pip
    echo -e "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf

    step "Installing Python dependencies..."
    pip3 install -U discord.py requests --break-system-packages
}

deploy_bot() {
    step "Deploying bot.py to /root ..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/bot.py" ]; then
        cp "$SCRIPT_DIR/bot.py" /root/bot.py
    else
        err "bot.py not found next to install.sh. Place it in the same folder and re-run."
        exit 1
    fi
}

configure_env() {
    echo -e "\n${WHT}────────── Bot Configuration ──────────${NC}"
    read -rp "$(echo -e "${CYN}Enter your Discord Bot Token: ${NC}")" DISCORD_TOKEN
    read -rp "$(echo -e "${CYN}Enter your Main Admin Discord ID: ${NC}")" MAIN_ADMIN_ID

    if [ -z "$DISCORD_TOKEN" ] || [ -z "$MAIN_ADMIN_ID" ]; then
        err "Token and Admin ID cannot be empty."
        exit 1
    fi
}

create_service() {
    # Dynamically find exact python3 binary path
    PYTHON_BIN=$(which python3 || echo "/usr/bin/python3")

    step "Creating systemd service using Python path (${PYTHON_BIN})..."
    cat > /etc/systemd/system/bot.service <<EOF
[Unit]
Description=IPMI SUPERMICRO BOT
After=network.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=${PYTHON_BIN} /root/bot.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
Environment=DISCORD_TOKEN=${DISCORD_TOKEN}
Environment=MAIN_ADMIN_ID=${MAIN_ADMIN_ID}
Environment=BOT_NAME=Svm-v9

[Install]
WantedBy=multi-user.target
EOF

    step "Reloading systemd daemon..."
    systemctl daemon-reload

    step "Starting bot service..."
    systemctl restart bot

    step "Enabling bot service on boot..."
    systemctl enable bot
}

final_message() {
    echo -e "\n${WHT}────────────────────────────────────────${NC}"
    echo -e "${GRN}  Installation complete! Bot deployed successfully.${NC}"
    echo -e "${WHT}────────────────────────────────────────${NC}"
    echo -e "  ${CYN}Service name:${NC} bot.service"
    echo -e "  ${CYN}Check Status:${NC} systemctl status bot"
    echo -e "  ${CYN}View Logs:${NC}    journalctl -u bot -f"
    echo -e "  ${CYN}Restart Bot:${NC}  systemctl restart bot"
    echo -e "${WHT}────────────────────────────────────────${NC}\n"

    # Print live status right after setup
    step "Current Service Status:"
    systemctl status bot --no-pager || true
}

main() {
    banner
    need_root
    update_system
    install_python_stack
    deploy_bot
    configure_env
    create_service
    final_message
}

main "$@"
