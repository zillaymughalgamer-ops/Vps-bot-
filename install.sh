install_python_stack() {
    step "Installing Python 3, pip, and venv..."
    apt install -y python3 python3-pip python3-venv

    step "Configuring pip overrides (PEP 668 compatibility)..."
    mkdir -p ~/.config/pip
    echo -e "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf

    step "Installing Python dependencies..."
    pip3 install -U discord.py requests --break-system-packages
}
