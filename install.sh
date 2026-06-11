#!/bin/sh
# NVR-Display Installer / Updater / Uninstaller

# Base URL for the raw GitHub files. 
# Note: If your default branch is 'master' instead of 'main', update the URL below.
REPO_URL="https://raw.githubusercontent.com/gpocali/nvr-display/main"

BINS="nvr-display nvr-downloader nvr-forecast"
INITS="nvr-display nvr-downloader nvr-forecast"

# Helper to download files
fetch_file() {
    local remote_path=$1
    local local_path=$2
    local chmod_flags=$3
    
    echo "Downloading $local_path..."
    wget -qO "$local_path" "$REPO_URL/$remote_path"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $remote_path"
        exit 1
    fi
    
    if [ -n "$chmod_flags" ]; then
        chmod "$chmod_flags" "$local_path"
    fi
    
    lbu add "$local_path"
}

install_dependencies() {
    echo "Installing dependencies..."
    wget -qO /tmp/apk-packages.txt "$REPO_URL/apk-packages.txt"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download apk-packages.txt"
        exit 1
    fi
    # Install the packages listed in the text file
    apk update
    apk add $(cat /tmp/apk-packages.txt)
    rm /tmp/apk-packages.txt
}

stop_services() {
    for svc in $INITS; do
        if rc-service "$svc" status 2>/dev/null | grep -q "started"; then
            echo "Stopping $svc..."
            rc-service "$svc" stop
        fi
    done
}

start_services() {
    for svc in $INITS; do
        echo "Starting $svc..."
        rc-service "$svc" start
    done
}

create_default_config() {
    mkdir -p /etc/nvr-display
    if [ ! -f /etc/nvr-display/nvr-display.conf ]; then
        echo "Creating default configuration at /etc/nvr-display/nvr-display.conf..."
        cat << 'EOF' > /etc/nvr-display/nvr-display.conf
# /etc/nvr-display/nvr-display.conf

# General Settings
TIMEZONE="America/New_York"
BACKGROUND="https://192.168.10.90/timelapse.jpg"

# Downloader Settings
DOWNLOADER_INTERVAL="0.25"
DOWNLOADER_INPUT_FLAGS="--no-check-certificate"
DOWNLOADER_INPUT_STREAM="https://192.168.5.90/timelapse.jpg"

# Forecast and Temperature Settings
FORECAST_ENABLE="1"
FORECAST_ADDRESS="http://192.168.10.72:8081/nvr-display.txt"
TEMPERATURE_ADDRESS="http://192.168.10.201/api/v1/plain/temperature/roundFahrenheit"

# Shared Text/Font
FONT_PATH="/usr/share/fonts/dejavu/DejaVuSans.ttf"

# Date Text Settings
DATE_ENABLE="1"
DATE_X="w-text_w-10"
DATE_Y="10"
DATE_FONTSIZE="48"
DATE_FONTCOLOR="gray"
DATE_BOX_ENABLE="1"
DATE_BOX_COLOR="black"
DATE_BOX_BORDER="5"
DATE_BOX_TRANSPARENCY="1"

# Time Text Settings
TIME_ENABLE="1"
TIME_FORMAT="24h"
TIME_X="(w-text_w)/2"
TIME_Y="10"
TIME_FONTSIZE="72"
TIME_FONTCOLOR="gray"
TIME_BOX_ENABLE="1"
TIME_BOX_COLOR="black"
TIME_BOX_BORDER="5"
TIME_BOX_TRANSPARENCY="1"
EOF
    else
        echo "Configuration file already exists. Skipping default config creation."
    fi
}

do_install() {
    echo "Starting NVR-Display Installation..."
    install_dependencies
    create_default_config
    
    for bin in $BINS; do
        fetch_file "root/bin/$bin" "/bin/$bin" "+x"
    done
    
    for init in $INITS; do
        fetch_file "root/etc/init.d/$init" "/etc/init.d/$init" "+x"
        rc-update add "$init" default
    done
    
    start_services
    echo "Installation complete!"
}

do_update() {
    echo "Starting NVR-Display Update..."
    stop_services
    install_dependencies
    
    echo "Updating binaries and services..."
    for bin in $BINS; do
        fetch_file "root/bin/$bin" "/bin/$bin" "+x"
    done
    
    for init in $INITS; do
        fetch_file "root/etc/init.d/$init" "/etc/init.d/$init" "+x"
    done
    
    start_services
    echo "Update complete! Your nvr-display.conf was preserved."
}

do_uninstall() {
    echo "Starting NVR-Display Uninstall..."
    stop_services
    
    for init in $INITS; do
        rc-update del "$init" default 2>/dev/null
        lbu exclude "/etc/init.d/$init"
        rm -f "/etc/init.d/$init"
    done
    
    for bin in $BINS; do
        lbu exclude "/bin/$bin"
        rm -f "/bin/$bin"
    done
    
    #echo "Removing configuration directory..."
    #rm -rf /etc/nvr-display
    
    echo "Uninstall complete!"
    echo "Note: Dependencies (ffmpeg, bc, etc.) were not removed automatically to prevent breaking other system components."
}

# Parse Arguments
case "$1" in
    --update|-u)
        do_update
        ;;
    --uninstall|-r)
        do_uninstall
        ;;
    --help|-h)
        echo "Usage: wget -qO- $REPO_URL/install.sh | sh -s -- [OPTION]"
        echo "Options:"
        echo "  (none)       Install everything and create default config"
        echo "  --update     Update scripts and binaries, preserving config"
        echo "  --uninstall  Stop services, remove scripts, binaries, and config"
        ;;
    *)
        do_install
        ;;
esac